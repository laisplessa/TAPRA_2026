# TAPRA_2026


### Alunos: Laís Philippi Lessa, Maria Fernanda de Jesus e Tiago Machado Fermiano.
### Turma: 144 6AN



import datetime
import logging
import azure.functions as func
import requests  # Adicionado para fazer a chamada HTTP
import os        # Adicionado para ler as configurações da URL

app = func.FunctionApp()

@app.function_name(name="mytimer")
@app.timer_trigger(schedule="0 * * * * *", arg_name="myTimer", run_on_startup=False,
              use_monitor=False) 
def timer_trigger_tapra(myTimer: func.TimerRequest) -> None:
    if myTimer.past_due:
        logging.info('The timer is past due!')
    logging.info('Python timer trigger function executed.')

@app.route(route="http_trigger_trabalho", auth_level=func.AuthLevel.FUNCTION)
def http_trigger_trabalho(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')
    name = req.params.get('name')
    if not name:
        try:
            req_body = req.get_json()
        except ValueError:
            pass
        else:
            name = req_body.get('name')

    if name:
        return func.HttpResponse(f"Hello, {name}. This HTTP triggered function executed successfully.")
    else:
        return func.HttpResponse(
             "This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response.",
             status_code=200
        )

@app.route(route="Funcao_Recebe", auth_level=func.AuthLevel.FUNCTION)
def Funcao_Recebe(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')
    name = req.params.get('name')
    if not name:
        try:
            req_body = req.get_json()
        except ValueError:
            pass
        else:
            name = req_body.get('name')

    if name:
        # Modificado para retornar a informação recebida mais um texto identificador
        return func.HttpResponse(f"[Processado por Funcao_Recebe] -> Informação recebida: {name}", status_code=200)
    else:
        return func.HttpResponse(
             "[Processado por Funcao_Recebe] -> Nenhuma informação foi passada no parâmetro 'name'.",
             status_code=200
        )

@app.timer_trigger(schedule="0 */2 * * * *", arg_name="myTimer", run_on_startup=False,
              use_monitor=False) 
def Funcao_Dispara(myTimer: func.TimerRequest) -> None:
    if myTimer.past_due:
        logging.info('The timer is past due!')
    logging.info('Python timer trigger function executed.')

    # Modificado para fazer a chamada HTTP para a Funcao_Recebe
    texto_para_enviar = "DadosDoTimerTrabalho"
    
    # Busca a URL da nuvem. Se não existir (rodando local no VS Code), usa a do localhost
    base_url = os.environ.get("FuncaoRecebeUrl", "http://localhost:7071/api/Funcao_Recebe")
    url_completa = f"{base_url}?name={texto_para_enviar}"

    try:
        logging.info(f"Disparando chamada HTTP para: {url_completa}")
        resposta = requests.get(url_completa)
        
        if resposta.status_code == 200:
            logging.info("[SUCESSO] Chamada executada!")
            logging.info(f"Resposta final recebida da outra função: {resposta.text}")
        else:
            logging.error(f"Erro na chamada HTTP. Status: {resposta.status_code}")
    except Exception as e:
        logging.error(f"Falha na comunicação entre as funções: {str(e)}")
