# Register this blueprint by adding the following line of code
# to your entry point file.
# app.register_functions(function)
#
# Please refer to https://aka.ms/azure-functions-python-blueprints

import base64
import datetime as dt
import decimal
import io
import json
import logging
import os
import uuid
from typing import Any

import azure.functions as func
import pyodbc
from azure.storage.filedatalake import DataLakeServiceClient

app = func.FunctionApp()

SOURCE_NAME = "itsm"
SOURCE_SCHEMA = "itsm"
BRONZE_CONTAINER = "bronze"
FETCH_BATCH_SIZE = 5000

# Ordem de carga no banco de destino respeitando as chaves estrangeiras:
# primeiro os cadastros ("pais"), depois as tabelas que dependem deles.
LOAD_ORDER = [
    "categoria",
    "cliente_organizacao",
    "fila",
    "sla",
    "analista",  # -> fila
    "solicitante",  # -> cliente_organizacao
    "chamado",  # -> analista, solicitante, categoria, cliente_organizacao, fila
    "chamado_sla",  # -> chamado, sla
    "chamado_status_historico",  # -> chamado, analista, fila
    "csat_avaliacao",  # -> chamado, analista
]


def get_connection_string() -> str:
    sql_server = os.getenv("HOST")
    sql_database = os.getenv("DATABASE")
    sql_user = os.getenv("USER")
    sql_pass = os.getenv("PASSWORD")

    logging.info("servidor=%s, banco de dados=%s", sql_server, sql_database)

    return (
        "DRIVER={ODBC Driver 18 for SQL Server};"
        f"SERVER={sql_server};"
        f"DATABASE={sql_database};"
        f"UID={sql_user};"
        f"PWD={sql_pass};"
        "Encrypt=yes;"
        "TrustServerCertificate=no;"
        "Connection Timeout=30;"
    )


def get_connection_string_destino() -> str:
    sql_server = os.getenv("HOST_DESTINO")
    sql_database = os.getenv("DB_DESTINO")
    sql_user = os.getenv("USER_DESTINO")
    sql_pass = os.getenv("PASSWORD_DESTINO")

    logging.info("destino: servidor=%s, banco de dados=%s", sql_server, sql_database)

    return (
        "DRIVER={ODBC Driver 18 for SQL Server};"
        f"SERVER={sql_server};"
        f"DATABASE={sql_database};"
        f"UID={sql_user};"
        f"PWD={sql_pass};"
        "Encrypt=yes;"
        "TrustServerCertificate=no;"
        "Connection Timeout=30;"
    )


def build_file_path(source: str, entity: str, extracted_at: dt.datetime) -> str:
    """Monta o caminho no formato:
    <fonte>/<entidade>/ano=YYYY/mes=MM/dia=DD/<entidade>_YYYYMMDDTHHMMSSZ.json
    """
    return (
        f"{source}/{entity}/"
        f"ano={extracted_at:%Y}/mes={extracted_at:%m}/dia={extracted_at:%d}/"
        f"{entity}_{extracted_at:%Y%m%dT%H%M%SZ}.json"
    )


def json_default(value: Any) -> Any:
    """Serializa tipos que o json padrao nao suporta."""
    if isinstance(value, (dt.datetime, dt.date, dt.time)):
        return value.isoformat()
    if isinstance(value, decimal.Decimal):
        return str(value)  # string preserva a precisao original
    if isinstance(value, (bytes, bytearray, memoryview)):
        return base64.b64encode(bytes(value)).decode("ascii")
    if isinstance(value, uuid.UUID):
        return str(value)
    return str(value)


def rows_to_json_stream(cursor: pyodbc.Cursor) -> tuple[io.BytesIO, int]:
    """Le o cursor em lotes e escreve um array JSON em memoria."""
    columns = [column[0] for column in cursor.description]
    buffer = io.BytesIO()
    buffer.write(b"[")

    total = 0
    while True:
        batch = cursor.fetchmany(FETCH_BATCH_SIZE)
        if not batch:
            break
        for row in batch:
            if total:
                buffer.write(b",")
            record = dict(zip(columns, row))
            buffer.write(
                json.dumps(record, default=json_default, ensure_ascii=False).encode(
                    "utf-8"
                )
            )
            total += 1

    buffer.write(b"]")
    buffer.seek(0)
    return buffer, total


def extract_table(table_name: str, entity: str | None = None) -> None:
    """Extrai itsm.<table_name> e grava em bronze/itsm/<entity>/...

    Se `entity` nao for informado, usa o proprio nome da tabela.
    """
    entity = entity or table_name
    extracted_at = dt.datetime.now(dt.timezone.utc)
    logging.info("Iniciando extracao da tabela %s.%s", SOURCE_SCHEMA, table_name)

    try:
        with pyodbc.connect(get_connection_string()) as conn:
            cursor = conn.cursor()
            cursor.execute(f"SELECT * FROM {SOURCE_SCHEMA}.{table_name}")
            payload, total = rows_to_json_stream(cursor)
        logging.info("Tabela %s retornou %s registros", table_name, total)
    except Exception as exc:
        logging.error("Erro ao ler %s.%s: %s", SOURCE_SCHEMA, table_name, exc)
        raise

    file_path = build_file_path(SOURCE_NAME, entity, extracted_at)

    try:
        # Cria o cliente do Data Lake e grava o arquivo no container bronze
        datalake = DataLakeServiceClient.from_connection_string(
            os.getenv("DATALAKE_CONNECTION_STRING")
        )
        file_system = datalake.get_file_system_client(BRONZE_CONTAINER)
        file_client = file_system.get_file_client(file_path)
        file_client.upload_data(payload, overwrite=True)
        logging.info("Arquivo gravado em %s/%s", BRONZE_CONTAINER, file_path)
    except Exception as exc:
        logging.error("Erro ao gravar %s/%s: %s", BRONZE_CONTAINER, file_path, exc)
        raise


def get_destination_columns(cursor: pyodbc.Cursor, table_name: str) -> set[str]:
    """Retorna as colunas (em minusculo) da tabela no banco de destino."""
    cursor.execute(
        "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS "
        "WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?",
        SOURCE_SCHEMA,
        table_name,
    )
    return {row[0].lower() for row in cursor.fetchall()}


def table_has_identity(cursor: pyodbc.Cursor, table_name: str) -> bool:
    cursor.execute(
        "SELECT OBJECTPROPERTY(OBJECT_ID(?), 'TableHasIdentity')",
        f"{SOURCE_SCHEMA}.{table_name}",
    )
    return cursor.fetchone()[0] == 1


def copy_table(
    src_conn: pyodbc.Connection, dst_conn: pyodbc.Connection, table_name: str
) -> int:
    """Copia itsm.<table_name> da origem para o destino, mantendo os IDs."""
    full_name = f"{SOURCE_SCHEMA}.{table_name}"
    src_cursor = src_conn.cursor()
    dst_cursor = dst_conn.cursor()
    dst_cursor.fast_executemany = True

    dst_columns = get_destination_columns(dst_cursor, table_name)
    if not dst_columns:
        raise RuntimeError(f"Tabela {full_name} nao existe no destino")
    has_identity = table_has_identity(dst_cursor, table_name)

    src_cursor.execute(f"SELECT * FROM {full_name}")
    columns = [column[0] for column in src_cursor.description]
    # So copia as colunas que existem nos dois bancos
    keep = [i for i, name in enumerate(columns) if name.lower() in dst_columns]

    columns_sql = ", ".join(f"[{columns[i]}]" for i in keep)
    params_sql = ", ".join(["?"] * len(keep))
    insert_sql = f"INSERT INTO {full_name} ({columns_sql}) VALUES ({params_sql})"

    # IDENTITY_INSERT permite gravar os mesmos IDs da origem,
    # mantendo os relacionamentos (FKs) entre as tabelas
    if has_identity:
        dst_cursor.execute(f"SET IDENTITY_INSERT {full_name} ON")

    total = 0
    while True:
        batch = src_cursor.fetchmany(FETCH_BATCH_SIZE)
        if not batch:
            break
        rows = [tuple(row[i] for i in keep) for row in batch]
        dst_cursor.executemany(insert_sql, rows)
        total += len(rows)

    if has_identity:
        dst_cursor.execute(f"SET IDENTITY_INSERT {full_name} OFF")

    return total


def load_destination() -> None:
    """Recarga completa do banco de destino em uma unica transacao.

    1. Apaga os dados das tabelas filhas para as pais (nao viola FKs).
    2. Insere das tabelas pais para as filhas (LOAD_ORDER).
    Se algo falhar, faz rollback e o destino continua com os dados anteriores.
    """
    logging.info("Iniciando carga do banco de destino")
    src_conn = pyodbc.connect(get_connection_string())
    dst_conn = pyodbc.connect(get_connection_string_destino(), autocommit=False)

    try:
        dst_cursor = dst_conn.cursor()
        for table_name in reversed(LOAD_ORDER):
            dst_cursor.execute(f"DELETE FROM {SOURCE_SCHEMA}.{table_name}")
            logging.info("Destino %s limpo", table_name)

        for table_name in LOAD_ORDER:
            total = copy_table(src_conn, dst_conn, table_name)
            logging.info("Destino %s: %s registros inseridos", table_name, total)

        dst_conn.commit()
        logging.info("Carga do banco de destino concluida")
    except Exception:
        dst_conn.rollback()
        logging.exception("Erro na carga do destino; alteracoes desfeitas")
        raise
    finally:
        src_conn.close()
        dst_conn.close()


@app.timer_trigger(
    schedule="0 * * * * *",
    arg_name="myTimer",
    run_on_startup=False,
    use_monitor=False,
)
def extract_chamado(myTimer: func.TimerRequest) -> None:
    extract_table("chamado", entity="chamados")


@app.timer_trigger(
    schedule="0 * * * * *",
    arg_name="myTimer",
    run_on_startup=False,
    use_monitor=False,
)
def extract_analista(myTimer: func.TimerRequest) -> None:
    extract_table("analista")


@app.timer_trigger(
    schedule="0 * * * * *",
    arg_name="myTimer",
    run_on_startup=False,
    use_monitor=False,
)
def extract_categoria(myTimer: func.TimerRequest) -> None:
    extract_table("categoria")


@app.timer_trigger(
    schedule="0 * * * * *",
    arg_name="myTimer",
    run_on_startup=False,
    use_monitor=False,
)
def extract_chamado_sla(myTimer: func.TimerRequest) -> None:
    extract_table("chamado_sla")


@app.timer_trigger(
    schedule="0 * * * * *",
    arg_name="myTimer",
    run_on_startup=False,
    use_monitor=False,
)
def extract_chamado_status_historico(myTimer: func.TimerRequest) -> None:
    extract_table("chamado_status_historico")


@app.timer_trigger(
    schedule="0 * * * * *",
    arg_name="myTimer",
    run_on_startup=False,
    use_monitor=False,
)
def extract_cliente_organizacao(myTimer: func.TimerRequest) -> None:
    extract_table("cliente_organizacao")


@app.timer_trigger(
    schedule="0 * * * * *",
    arg_name="myTimer",
    run_on_startup=False,
    use_monitor=False,
)
def extract_csat_avaliacao(myTimer: func.TimerRequest) -> None:
    extract_table("csat_avaliacao")


@app.timer_trigger(
    schedule="0 * * * * *",
    arg_name="myTimer",
    run_on_startup=False,
    use_monitor=False,
)
def extract_fila(myTimer: func.TimerRequest) -> None:
    extract_table("fila")


@app.timer_trigger(
    schedule="0 * * * * *",
    arg_name="myTimer",
    run_on_startup=False,
    use_monitor=False,
)
def extract_sla(myTimer: func.TimerRequest) -> None:
    extract_table("sla")


@app.timer_trigger(
    schedule="0 * * * * *",
    arg_name="myTimer",
    run_on_startup=False,
    use_monitor=False,
)
def extract_solicitante(myTimer: func.TimerRequest) -> None:
    extract_table("solicitante")


# Atualiza o banco de destino uma vez por dia.
# CRON (seg min hora dia mes dia_semana) em UTC: 06:00 UTC = 03:00 de Brasilia.
@app.timer_trigger(
    schedule="0 0 6 * * *",
    arg_name="myTimer",
    run_on_startup=False,
    use_monitor=True,
)
def load_banco_destino(myTimer: func.TimerRequest) -> None:
    load_destination()
