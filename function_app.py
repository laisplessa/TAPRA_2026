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
