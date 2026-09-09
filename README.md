# TAPRA_2026


Alunos: Laís Philippi Lessa, Maria Fernanda de Jesus e Tiago Machado Fermiano.
Turma: 144 6AN


import azure.functions as func
import logging
import datetime
import requests
import os

# Inicializa o aplicativo do Azure Functions
app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)

# =========================================================================
# Requisito 1: Timer Trigger - Imprimir apenas um log no terminal
# Configurado para rodar a cada 1 minuto
# =========================================================================
@app.timer_trigger(schedule="0 */1 * * * *", arg_name="myTimer", run_on_startup=False, use_monitor=False) 
def TimerLogFunction(myTimer: func.TimerRequest) -> None:
    if myTimer.past_due:
        logging.info('O timer está atrasado!')

    logging.info(f'[LOG SIMPLES] Timer executado com sucesso em: {datetime.datetime.now()}')


# =========================================================================
# Requisito 2: HTTP trigger - Recebe parâmetro via URL (GET) e imprime na tela
# =========================================================================
@app.route(route="HttpGetFunction", methods=["GET"])
def HttpGetFunction(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('HttpGetFunction processando uma requisição.')

    # Tenta obter o parâmetro "nome" da URL (Query String)
    param_value = req.params.get('nome')

    if not param_value:
        return func.HttpResponse(
            "Por favor, passe o parâmetro 'nome' na URL. Exemplo: ?nome=Equipe2026",
            status_code=400
        )

    # Devolve o texto com o identificador exigido
    texto_identificado = f"[Resposta da HttpGetFunction] -> Olá, {param_value}! Recebi seu parâmetro com sucesso."
    
    return func.HttpResponse(texto_identificado, status_code=200, mimetype="text/plain")


# =========================================================================
# Requisito 3: Timer trigger - Faz chamada HTTP para a outra Azure Function
# Configurado para rodar a cada 2 minutos
# =========================================================================
@app.timer_trigger(schedule="0 */2 * * * *", arg_name="myTimer", run_on_startup=False, use_monitor=False)
def TimerHttpFunction(myTimer: func.TimerRequest) -> None:
    logging.info(f'TimerHttpFunction disparada em: {datetime.datetime.now()}')

    meu_parametro = "DadosDoTimerPython"
    
    # Busca a URL dinamicamente das configurações locais ou da nuvem
    base_url = os.environ.get("HttpGetFunctionUrl", "http://localhost:7071/api/HttpGetFunction")
    url_da_outra_function = f"{base_url}?nome={meu_parametro}"

    try:
        logging.info(f"Chamando a URL: {url_da_outra_function}")
        response = requests.get(url_da_outra_function)

        if response.status_code == 200:
            logging.info("[SUCESSO] Chamada HTTP concluída entre as funções!")
            logging.info(f"Resultado final recebido: {response.text}")
        else:
            logging.error(f"Falha ao chamar a função HTTP. Status Code: {response.status_code}")
            
    except Exception as e:
        logging.error(f"Erro ao tentar realizar a comunicação entre as funções: {str(e)}")
