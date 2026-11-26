# Databricks notebook source
# MAGIC %md
# MAGIC # Bronze - ingestao da API BI do Protheus
# MAGIC Le os endpoints da API `APIBI` (GET /rest/APIBI/bi/...) e grava cada um em uma tabela Delta da camada bronze.
# MAGIC
# MAGIC **Na primeira vez**, rode a celula "Configuracao dos secrets". Depois, comece pela celula de configuracao (imports).

# COMMAND ----------

# MAGIC %md
# MAGIC ## Configuracao dos secrets (rodar UMA vez)
# MAGIC 1. Digite a senha em `SENHA` na celula abaixo e rode.
# MAGIC 2. Confira a mensagem `Secrets gravados`.
# MAGIC 3. **Apague a senha da celula** (deixe `SENHA = ""`). Ela fica guardada so no cofre de secrets do Databricks.
# MAGIC Nas proximas execucoes, pule esta celula.

# COMMAND ----------

USUARIO = "apibalanca"
SENHA   = "Balanca@213;"          # digite a senha aqui, rode a celula e depois APAGUE

from databricks.sdk import WorkspaceClient

dbutils.widgets.removeAll()     # remove os campos da versao anterior, se existirem
if not SENHA:
    raise ValueError("Preencha SENHA nesta celula antes de rodar.")

w = WorkspaceClient()
if "protheus" not in [sc.name for sc in w.secrets.list_scopes()]:
    w.secrets.create_scope(scope="protheus")
w.secrets.put_secret(scope="protheus", key="api_user", string_value=USUARIO)
w.secrets.put_secret(scope="protheus", key="api_password", string_value=SENHA)
print("Secrets gravados no scope 'protheus'. Agora apague a senha desta celula.")

# COMMAND ----------

import time
import requests
import pandas as pd
from datetime import datetime, timezone
from pyspark.sql import functions as F

# Endpoints: http://<servidor>:8086/rest/APIBI/bi/...  (autenticacao Basic, igual ao Postman)
BASE_URL  = "http://177.136.201.210:8086/rest/APIBI"
USER      = dbutils.secrets.get("protheus", "api_user")
PASSWORD  = dbutils.secrets.get("protheus", "api_password")
PAGE_SIZE = 5000

# Destino no Unity Catalog. Confira o nome do catalogo em Catalog (menu lateral).
CATALOGO  = "quebec"
SCHEMA    = f"{CATALOGO}.bronze"

spark.sql(f"CREATE SCHEMA IF NOT EXISTS {SCHEMA}")

# COMMAND ----------

class ProtheusAPI:
    """Cliente da API BI: autenticacao Basic, nova tentativa em erro 5xx e paginacao."""

    def __init__(self, base_url, user, password):
        self.base = base_url.rstrip("/")
        self.s = requests.Session()
        self.s.auth = (user, password)               # gera o header Authorization: Basic ...
        self.s.headers.update({"Accept": "application/json"})

    def get(self, path, params=None, tentativas=3):
        for i in range(tentativas):
            r = self.s.get(f"{self.base}{path}", params=params, timeout=600)
            if r.status_code >= 500 and i < tentativas - 1:
                time.sleep(5 * (i + 1))
                continue
            if not r.ok:
                raise RuntimeError(f"GET {path} -> {r.status_code}: {r.text[:500]}")
            return r.json()

    def get_all(self, path, params=None, page_size=5000):
        """Le todas as paginas de um endpoint e devolve a lista de items."""
        params = dict(params or {})
        itens, page = [], 1
        while True:
            params.update({"page": page, "pageSize": page_size})
            resp = self.get(path, params)
            itens.extend(resp.get("items", []))
            if not resp.get("hasNext"):
                return itens
            page += 1


api = ProtheusAPI(BASE_URL, USER, PASSWORD)   # usa BASE_URL, USER e PASSWORD da celula de configuracao

# COMMAND ----------

# MAGIC %md
# MAGIC ## Teste de conexao
# MAGIC Deve devolver algo como `{"YM": "202609"}`. Se der 401, confira usuario/senha (a senha termina com `;`); se der 404, confira a URL.

# COMMAND ----------

print(api.get("/bi/rh/ultima-competencia"))

# COMMAND ----------

def gravar_bronze(tabela, path, params=None, modo="overwrite"):
    """Le o endpoint e grava em <SCHEMA>.<tabela> com colunas de controle."""
    itens = api.get_all(path, params)
    if not itens:
        print(f"{tabela}: 0 linhas (nada gravado)")
        return 0
    # pandas mantem os tipos do JSON (texto continua texto, numero continua numero)
    df = spark.createDataFrame(pd.DataFrame(itens))
    df = (df.withColumn("_endpoint", F.lit(path))
            .withColumn("_params", F.lit(str(params or {})))
            .withColumn("_ingestao", F.lit(datetime.now(timezone.utc))))
    (df.write.format("delta").mode(modo)
       .option("overwriteSchema", "true" if modo == "overwrite" else "false")
       .saveAsTable(f"{SCHEMA}.{tabela}"))
    print(f"{tabela}: {len(itens)} linhas")
    return len(itens)

# COMMAND ----------

# MAGIC %md
# MAGIC ## Carga
# MAGIC Endpoints sem parametro obrigatorio usam os padroes da API (janelas de 12/24 meses etc.).
# MAGIC Os que dependem de codigos de verba (RH/medicina) estao comentados ate definirmos as verbas.

# COMMAND ----------

CARGAS = [
    # tabela bronze                       endpoint                                 parametros
    ("fin_titulos_abertos",               "/bi/financeiro/titulos-abertos",        None),
    ("fin_pagamentos",                    "/bi/financeiro/pagamentos",             {"de": "20250101"}),
    ("fin_centros_custo",                 "/bi/financeiro/centros-custo",          None),
    ("fin_faturamento",                   "/bi/financeiro/faturamento",            {"de": "20250101"}),
    ("geral_filiais",                     "/bi/geral/filiais",                     None),
    ("apr_pendencias",                    "/bi/aprovacao/pendencias",              None),
    ("apr_itens",                         "/bi/aprovacao/itens",                   None),
    ("apr_cotacoes",                      "/bi/aprovacao/cotacoes",                None),
    ("ped_itens",                         "/bi/pedidos/itens",                     None),
    ("ped_alcadas",                       "/bi/pedidos/alcadas",                   None),
    ("ped_notas",                         "/bi/pedidos/notas",                     None),
    ("ped_solicitacoes",                  "/bi/pedidos/solicitacoes",              None),
    ("com_solicitacoes",                  "/bi/compras/solicitacoes",              None),
    ("com_cotacoes",                      "/bi/compras/cotacoes",                  None),
    ("com_custos",                        "/bi/compras/custos",                    None),
    ("com_notas_entrada",                 "/bi/compras/notas-entrada",             None),
    ("ctr_contratos",                     "/bi/contratos/contratos",               None),
    ("ctr_medicoes",                      "/bi/contratos/medicoes",                {"desde": "20250101"}),
    ("fol_lancamentos",                   "/bi/folha/lancamentos",                 None),
    ("fol_lancamentos_previa",            "/bi/folha/lancamentos-previa",          None),
    ("fol_verbas",                        "/bi/folha/verbas",                      None),
    ("fol_quadro",                        "/bi/folha/quadro",                      None),
    ("fol_admissoes_demissoes",           "/bi/folha/admissoes-demissoes",         None),
    ("rh_pessoas_ativas",                 "/bi/rh/pessoas-ativas",                 None),
    ("rh_ferias_vencidas",                "/bi/rh/ferias-vencidas",                None),
    ("rh_ferias_gozadas",                 "/bi/rh/ferias-gozadas",                 None),
    ("rh_afastamentos",                   "/bi/rh/afastamentos",                   None),
    # ("rh_hora_extra",                   "/bi/rh/hora-extra",                     {"lista": "<verbas>"}),
    # ("med_custo_pessoa",                "/bi/medicina/custo-pessoa",             {"vbruto": "...", "vencargo": "..."}),
    ("med_atestados",                     "/bi/medicina/atestados",                None),
    ("med_acidentes",                     "/bi/medicina/acidentes",                None),
    ("mnt_bens",                          "/bi/frota/bens",                        None),
    ("mnt_ordens",                        "/bi/frota/ordens",                      None),
    ("mnt_pecas",                         "/bi/frota/pecas",                       None),
    ("mnt_combustivel_nf",                "/bi/frota/combustivel-nf",              None),
    ("mnt_combustivel_requisicao",        "/bi/frota/combustivel-requisicao",      None),
    ("mnt_hodometro",                     "/bi/frota/hodometro",                   None),
    ("mnt_abastecimentos",                "/bi/frota/abastecimentos",              None),
    ("est_saldos",                        "/bi/estoque/saldos",                    None),
    ("est_fechamentos",                   "/bi/estoque/fechamentos",               None),
    ("est_ajustes",                       "/bi/estoque/ajustes",                   None),
    ("est_tipos_movimento",               "/bi/estoque/tipos-movimento",           None),
    ("epi_pessoas",                       "/bi/epi/pessoas",                       None),
    ("epi_validade_ca",                   "/bi/epi/validade-ca",                   None),
    ("epi_por_funcao",                    "/bi/epi/por-funcao",                    None),
    ("usr_colunas",                       "/bi/usuarios/colunas",                  None),
    ("usr_usuarios",                      "/bi/usuarios/cadastro",                 None),
    ("usr_modulos",                       "/bi/usuarios/modulos",                  None),
    ("usr_acessos",                       "/bi/usuarios/acessos",                  None),
]

resultado = []
for tabela, path, params in CARGAS:
    try:
        resultado.append((tabela, gravar_bronze(tabela, path, params), "ok"))
    except Exception as e:
        resultado.append((tabela, 0, str(e)[:300]))

display(spark.createDataFrame(resultado, "tabela string, linhas long, status string"))

# COMMAND ----------

# MAGIC %md
# MAGIC ## Consultas mensais (uma chamada por mes)
# MAGIC Movimentos de estoque e entregas de EPI sao lidos mes a mes, a partir da lista de meses da propria API.

# COMMAND ----------

def carga_mensal(tabela, path_meses, path_dados, params_meses=None):
    meses = [m["M"] for m in api.get_all(path_meses, params_meses)]
    spark.sql(f"DROP TABLE IF EXISTS {SCHEMA}.{tabela}")
    for i, mes in enumerate(meses):
        gravar_bronze(tabela, path_dados, {"mes": mes}, modo="overwrite" if i == 0 else "append")

carga_mensal("est_movimentos",    "/bi/estoque/meses-movimento",    "/bi/estoque/movimentos")
carga_mensal("est_solicitacoes",  "/bi/estoque/meses-solicitacao",  "/bi/estoque/solicitacoes")
carga_mensal("epi_entregas",      "/bi/epi/meses-entrega",          "/bi/epi/entregas")
