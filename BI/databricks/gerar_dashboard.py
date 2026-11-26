"""Gera um AI/BI Dashboard do Databricks por area (pasta dashboards/) a partir das views gold.

Uso:  python gerar_dashboard.py [catalogo]      (padrao: quebec)
Saida: dashboards/Dashboard_<Area>.lvdash.json (Financeiro, Compras, Frota, Estoque, Pessoas, Contratos, Usuarios, Diretoria).
Diretoria: le o schema <catalogo>.diretoria; compartilhe o dashboard so com o grupo da diretoria.
Depois, no Databricks: Dashboards > seta ao lado de "Create dashboard" > Import dashboard from file,
um arquivo por vez. Cada area vira um dashboard separado, com permissao de acesso propria.

Filtro de filial: todo dataset recebe o parametro :filial (padrao 'Todas') e cada pagina ganha um
filtro "Filial" ligado a esse parametro em todos os datasets da pagina.
  - views agregadas (tem linha 'Todas'):  WHERE filial = :filial
  - views de detalhe (uma linha por item): WHERE (:filial = 'Todas' OR filial = :filial)

Filtros de centro de custo e periodo (Financeiro, Compras, Frota, Pessoas e Contratos): parametros
:centro_custo (padrao 'Todos') e :data_inicio/:data_fim (DATE), em linha de filtros em cada pagina (filtros()).
Como os indicadores precisam ser recalculados para o periodo/CC, esses datasets agregam direto das views de
detalhe (ds_sql) em vez de ler views ja agregadas. Periodo padrao: ano corrente; no Financeiro e na
Aprovacao (posicao em aberto) o padrao e largo (2000-2099), para abrir com tudo.
  - Financeiro: vencimento do titulo / data do pagamento; CC principal do titulo (maior valor no rateio).
  - Compras: emissao do pedido (aprovacao e lead time), da SC e digitacao da NF; CC do item.
  - Frota: abertura da OS / data do abastecimento; CC da OS / do abastecimento.  Pessoas: competencia / data do atestado ou acidente; o quadro so filtra CC.
  - Contratos: entrega da medicao, data da revisao e vigencia; CC do item medido.
Estoque e Diretoria seguem como estavam.
"""
import json
import sys
from datetime import date
from pathlib import Path

CAT = sys.argv[1] if len(sys.argv) > 1 else "quebec"
G = f"{CAT}.gold"
DIR = f"{CAT}.diretoria"      # schema com acesso so da diretoria

datasets, pages = [], []
_seq = [0]
_views_area = []          # views da area, para montar a lista de filiais do filtro
SAIDA = Path(__file__).with_name("dashboards")
gerados = []

def _param_texto(nome, valor):
    return {"displayName": nome, "keyword": nome, "dataType": "STRING",
            "defaultSelection": {"values": {"dataType": "STRING", "values": [{"value": valor}]}}}


PARAM_FILIAL = _param_texto("filial", "Todas")
PARAM_CC = _param_texto("centro_custo", "Todos")


def _param_data(nome, valor):
    return {"displayName": nome, "keyword": nome, "dataType": "DATE",
            "defaultSelection": {"values": {"dataType": "DATE", "values": [{"value": f"{valor}T00:00:00.000"}]}}}


# padrao bem largo: o dashboard abre com todas as pendencias e o usuario estreita o periodo
PARAMS_DATA = [_param_data("data_inicio", "2000-01-01"), _param_data("data_fim", "2099-12-31")]


def _id(prefix):
    _seq[0] += 1
    return f"{prefix}_{_seq[0]:03d}"


def ds(nome, titulo, view, detalhe=False, where=None, order=None, limit=None):
    """Dataset sobre uma view gold, ja filtrado pela filial escolhida no dashboard."""
    filtro = "(:filial = 'Todas' OR filial = :filial)" if detalhe else "filial = :filial"
    sql = f"SELECT * FROM {G}.{view} WHERE {filtro}"
    if where:
        sql += f" AND ({where})"
    if order:
        sql += f" ORDER BY {order}"
    if limit:
        sql += f" LIMIT {limit}"
    datasets.append({"name": nome, "displayName": titulo, "queryLines": [sql], "parameters": [PARAM_FILIAL]})
    _views_area.append(view)
    return nome


def ds_sql(nome, titulo, sql, views, datas=False, cc=False):
    """Dataset com SQL proprio. O SQL ja deve usar :filial (e :data_inicio/:data_fim se datas,
    :centro_custo se cc). datas: True (padrao largo) ou (inicio, fim) em AAAA-MM-DD.
    views: nomes no gold ou com schema."""
    if isinstance(datas, tuple):
        params = [PARAM_FILIAL, _param_data("data_inicio", datas[0]), _param_data("data_fim", datas[1])]
    else:
        params = [PARAM_FILIAL] + (PARAMS_DATA if datas else [])
    if cc:
        params.append(PARAM_CC)
    datasets.append({"name": nome, "displayName": titulo, "queryLines": [" ".join(sql.split())], "parameters": params})
    _views_area.extend(views)
    return nome


def ds_livre(nome, titulo, sql, datas=None):
    """Dataset sem filial (ex.: usuarios do sistema). datas: (inicio, fim) para :data_inicio/:data_fim, ou None."""
    params = [_param_data("data_inicio", datas[0]), _param_data("data_fim", datas[1])] if datas else []
    d = {"name": nome, "displayName": titulo, "queryLines": [" ".join(sql.split())]}
    if params:
        d["parameters"] = params
    datasets.append(d)
    return nome


def _ds_filiais():
    """Opcoes do filtro: 'Todas' + filiais que aparecem nas views da area."""
    unioes = " UNION ".join(f"SELECT filial FROM {v if '.' in v else f'{G}.{v}'}" for v in dict.fromkeys(_views_area))
    sql = (f"SELECT filial FROM (SELECT 'Todas' AS filial UNION {unioes}) "
           f"WHERE filial IS NOT NULL ORDER BY CASE WHEN filial = 'Todas' THEN 0 ELSE 1 END, filial")
    nome = "filiais"
    datasets.append({"name": nome, "displayName": "Filiais (opções do filtro)", "queryLines": [sql]})
    return nome


def salvar(area):
    """Grava o dashboard da area com os datasets/paginas acumulados e recomeca do zero."""
    opcoes = _ds_filiais() if _views_area else None      # area sem filial (ex.: usuarios) nao tem o filtro
    for p in pages:
        for item in p["layout"]:
            if "_filtro" in item:
                item.update(_filtro_filial(opcoes, item.pop("_filtro")))
            elif "_filtro_data" in item:
                param, titulo = item.pop("_filtro_data")
                item.update(_filtro_data(param, titulo, item.pop("_dsets")))
    SAIDA.mkdir(exist_ok=True)
    arq = SAIDA / f"Dashboard_{area}.lvdash.json"
    arq.write_text(json.dumps({"datasets": datasets, "pages": pages}, ensure_ascii=False, indent=2), encoding="utf-8")
    gerados.append(f"{arq.name}: {len(pages)} pagina(s), {len(datasets)} datasets, "
                   f"{sum(len(p['layout']) for p in pages)} widgets")
    datasets.clear()
    pages.clear()
    _views_area.clear()


# ---------------------------------------------------------------- formatos
BRL = {"type": "number-currency", "currencyCode": "BRL", "abbreviation": "compact",
       "decimalPlaces": {"type": "max", "places": 1}}
PCT = {"type": "number-percent", "decimalPlaces": {"type": "max", "places": 1}}
NUM = {"type": "number-plain", "abbreviation": "compact", "decimalPlaces": {"type": "max", "places": 1}}


# ---------------------------------------------------------------- widgets
def _query(dataset, cols):
    return [{"name": "main_query", "query": {
        "datasetName": dataset, "disaggregated": True,
        "fields": [{"name": c, "expression": f"`{c}`"} for c in cols]}}]


def _frame(titulo, descricao=None):
    f = {"showTitle": True, "title": titulo}
    if descricao:
        f.update({"showDescription": True, "description": descricao})
    return f


def _filtro_lista(opcoes, param, titulo, dsets):
    """Filtro de selecao unica: lista os valores do campo `param` do dataset de opcoes e grava no
    parametro :param de cada dataset da pagina."""
    q_opcoes = f"dashboards_{opcoes}_{param}"
    queries = [{"name": q_opcoes, "query": {
        "datasetName": opcoes, "disaggregated": False,
        "fields": [{"name": param, "expression": f"`{param}`"}]}}]
    campos = [{"fieldName": param, "displayName": titulo, "queryName": q_opcoes}]
    for d in dsets:
        q = f"parameter_{d}_{param}"
        queries.append({"name": q, "query": {"datasetName": d, "disaggregated": False,
                                             "parameters": [{"name": param, "keyword": param}]}})
        campos.append({"parameterName": param, "queryName": q})
    return {"widget": {"name": _id("filtro"), "queries": queries,
                       "spec": {"version": 2, "widgetType": "filter-single-select",
                                "encodings": {"fields": campos}, "frame": _frame(titulo)}}}


def _filtro_filial(opcoes, dsets):
    return _filtro_lista(opcoes, "filial", "Filial", dsets)


def _filtro_data(param, titulo, dsets):
    """Seletor de data ligado ao parametro `param` de cada dataset da pagina que o declara."""
    queries, campos = [], []
    for d in dsets:
        q = f"parameter_{d}_{param}"
        queries.append({"name": q, "query": {"datasetName": d, "disaggregated": False,
                                             "parameters": [{"name": param, "keyword": param}]}})
        campos.append({"parameterName": param, "queryName": q})
    return {"widget": {"name": _id("filtro"), "queries": queries,
                       "spec": {"version": 2, "widgetType": "filter-date-picker",
                                "encodings": {"fields": campos}, "frame": _frame(titulo)}}}


def filtro():
    """Marca a posicao do filtro de filial; os datasets da pagina sao ligados em pagina()/salvar()."""
    return {"_filtro": None}


def filtro_data(param, titulo):
    """Marca a posicao de um filtro de data (:data_inicio ou :data_fim)."""
    return {"_filtro_data": (param, titulo)}


def filtro_lista(opcoes, param, titulo):
    """Marca a posicao de um filtro de selecao unica sobre :param (ex.: centro de custo), com as opcoes
    vindas do dataset `opcoes` (coluna de mesmo nome do parametro). Liga nos datasets da pagina que
    declaram o parametro."""
    return {"_filtro_lista": (opcoes, param, titulo)}


def texto(md):
    return {"widget": {"name": _id("txt"), "multilineTextboxSpec": {"lines": md.strip().split("\n")}}}


def contador(dataset, campo, titulo, fmt=None):
    enc = {"fieldName": campo, "displayName": titulo}
    if fmt:
        enc["format"] = fmt
    return {"widget": {"name": _id("kpi"), "queries": _query(dataset, [campo]),
                       "spec": {"version": 2, "widgetType": "counter", "encodings": {"value": enc},
                                "frame": _frame(titulo)}}}


def _eixo(campo, tipo, nome, fmt=None, sort=None):
    e = {"fieldName": campo, "scale": {"type": tipo}, "displayName": nome}
    if sort:
        e["scale"]["sort"] = {"by": sort}
    if fmt:
        e["format"] = fmt
    return e


def grafico(tipo, dataset, titulo, x, y, cor=None, descricao=None, horizontal=False, fmt_y=None, tipo_x="categorical"):
    """x/y: (campo, nome). y tambem aceita lista [(campo, nome), ...] para varias series."""
    cols = [x[0]] + ([c for c, _ in y] if isinstance(y, list) else [y[0]]) + ([cor[0]] if cor else [])
    if isinstance(y, list):
        y_enc = {"scale": {"type": "quantitative"}, "fields": [{"fieldName": c, "displayName": n} for c, n in y]}
        if fmt_y:
            y_enc["format"] = fmt_y
    else:
        y_enc = _eixo(y[0], "quantitative", y[1], fmt_y)
    if horizontal:   # categoria no eixo Y, valor no eixo X, maior no topo
        enc = {"x": y_enc, "y": _eixo(x[0], "categorical", x[1], sort="x-reversed")}
    else:
        enc = {"x": _eixo(x[0], tipo_x, x[1]), "y": y_enc}
    if cor:
        enc["color"] = {"fieldName": cor[0], "scale": {"type": "categorical"}, "displayName": cor[1]}
    return {"widget": {"name": _id(tipo), "queries": _query(dataset, cols),
                       "spec": {"version": 3, "widgetType": tipo, "encodings": enc,
                                "frame": _frame(titulo, descricao)}}}


def grafico_soma(tipo, dataset, titulo, x, y, cor=None, extra=None, descricao=None, horizontal=False,
                 fmt_y=None, tipo_x="categorical"):
    """Grafico agregado no proprio widget: soma `y` por `x` (e `cor`). Como os outros widgets do mesmo
    dataset, clicar numa barra/ponto filtra os demais widgets da pagina que usam esse dataset (cross-filter).
    extra: [(campo, nome, fmt), ...] somados e mostrados so no tooltip."""
    def soma(c):
        return {"name": f"sum({c})", "expression": f"SUM(`{c}`)"}
    fields = [{"name": x[0], "expression": f"`{x[0]}`"}, soma(y[0])]
    if cor:
        fields.append({"name": cor[0], "expression": f"`{cor[0]}`"})
    for c, _, _ in (extra or []):
        fields.append(soma(c))
    y_enc = _eixo(f"sum({y[0]})", "quantitative", y[1], fmt_y)
    if horizontal:
        enc = {"x": y_enc, "y": _eixo(x[0], "categorical", x[1], sort="x-reversed")}
    else:
        enc = {"x": _eixo(x[0], tipo_x, x[1]), "y": y_enc}
    if cor:
        enc["color"] = {"fieldName": cor[0], "scale": {"type": "categorical"}, "displayName": cor[1]}
    if extra:
        enc["extra"] = [dict({"fieldName": f"sum({c})", "displayName": n}, **({"format": f} if f else {}))
                        for c, n, f in extra]
    return {"widget": {"name": _id(tipo), "queries": [{"name": "main_query", "query": {
        "datasetName": dataset, "disaggregated": False, "fields": fields}}],
        "spec": {"version": 3, "widgetType": tipo, "encodings": enc, "frame": _frame(titulo, descricao)}}}


def filtro_campo(campo, titulo, dsets, multi=True):
    """Filtro sobre a coluna `campo` (mesmo nome em todos os datasets de dsets); as opcoes vem do 1o dataset."""
    queries, campos = [], []
    for d in dsets:
        q = f"campo_{d}_{campo}"
        queries.append({"name": q, "query": {"datasetName": d, "disaggregated": False,
                                             "fields": [{"name": campo, "expression": f"`{campo}`"}]}})
        campos.append({"fieldName": campo, "displayName": titulo, "queryName": q})
    tipo = "filter-multi-select" if multi else "filter-single-select"
    return {"widget": {"name": _id("filtro"), "queries": queries,
                       "spec": {"version": 2, "widgetType": tipo, "encodings": {"fields": campos},
                                "frame": _frame(titulo)}}}


def tabela(dataset, titulo, colunas, descricao=None):
    """colunas: [(campo, nome), ...]"""
    return {"widget": {"name": _id("tbl"), "queries": _query(dataset, [c for c, _ in colunas]),
                       "spec": {"version": 2, "widgetType": "table",
                                "encodings": {"columns": [{"fieldName": c, "displayName": n} for c, n in colunas]},
                                "frame": _frame(titulo, descricao)}}}


def pagina(nome, linhas):
    """linhas: lista de linhas do grid; cada linha = (altura, [(widget, largura), ...]). Grid de 6 colunas."""
    layout, y = [], 0
    for altura, itens in linhas:
        x = 0
        for w, largura in itens:
            w["position"] = {"x": x, "y": y, "width": largura, "height": altura}
            layout.append(w)
            x += largura
        assert x <= 6, f"linha com largura {x} em {nome}"
        y += altura
    usados = list(dict.fromkeys(q["query"]["datasetName"] for w in layout if "widget" in w
                                for q in w["widget"].get("queries", [])))
    com_datas = [d["name"] for d in datasets if d["name"] in usados
                 and any(p["keyword"] == "data_inicio" for p in d.get("parameters", []))]
    for w in layout:
        if "_filtro" in w:
            w["_filtro"] = usados
        elif "_filtro_data" in w:
            w["_dsets"] = com_datas
        elif "_filtro_lista" in w:
            opcoes, param, titulo = w.pop("_filtro_lista")
            com_param = [d["name"] for d in datasets if d["name"] in usados
                         and any(p["keyword"] == param for p in d.get("parameters", []))]
            w.update(_filtro_lista(opcoes, param, titulo, com_param))
    pages.append({"name": _id("pg"), "displayName": nome, "pageType": "PAGE_TYPE_CANVAS", "layout": layout})


# ---------------------------------------------------------------- filtros filial + CC + periodo
# Padrao de todas as areas (igual ao Contratos): datasets com SQL proprio sobre as views de detalhe,
# recalculados para a filial, o centro de custo e o periodo escolhidos.
_ano_atual = date.today().year
ANO = (f"{_ano_atual}-01-01", f"{_ano_atual}-12-31")     # padrao: ano corrente
LARGO = ("2000-01-01", "2099-12-31")                     # padrao: tudo (posicao em aberto)
F_FIL = "(:filial = 'Todas' OR filial = :filial)"
F_CC = "(:centro_custo = 'Todos' OR centro_custo = :centro_custo)"


def F_PER(col):
    """Data `col` dentro do periodo escolhido."""
    return f"{col} BETWEEN :data_inicio AND :data_fim"


def F_MES(col="mes"):
    """Mes (dia 1) dentro do periodo escolhido."""
    return f"{col} BETWEEN date_trunc('MONTH', :data_inicio) AND :data_fim"


def ds_ccs(nome, views):
    """Opcoes do filtro de centro de custo: 'Todos' + centros de custo das views (sem parametros)."""
    unioes = " UNION ".join(f"SELECT centro_custo FROM {v if '.' in v else f'{G}.{v}'}" for v in dict.fromkeys(views))
    datasets.append({"name": nome, "displayName": "Centros de custo (opções do filtro)", "queryLines": [
        f"SELECT centro_custo FROM (SELECT 'Todos' AS centro_custo UNION {unioes}) "
        f"WHERE centro_custo IS NOT NULL ORDER BY CASE WHEN centro_custo = 'Todos' THEN 0 ELSE 1 END, centro_custo"]})
    return nome


def filtros(ccs, de="Período de", ate="Período até"):
    """Linha de filtros: filial, centro de custo e periodo (data inicial e final)."""
    return (2, [(filtro(), 2), (filtro_lista(ccs, "centro_custo", "Centro de custo"), 2),
                (filtro_data("data_inicio", de), 1), (filtro_data("data_fim", ate), 1)])


# ================================================================= FINANCEIRO
# Filtros: filial, centro de custo (CC principal do titulo, o de maior valor no rateio) e periodo
# (padrao: tudo). Titulos em aberto: vencimento no periodo. Pagamentos: data do pagamento no periodo.
_VT, _VP = f"{G}.vw_fin_titulos", f"{G}.vw_fin_pagamentos"
F_TIT = f"{F_FIL} AND {F_CC} AND {F_PER('coalesce(dt_vencimento, dt_emissao)')}"
F_PAG = f"{F_FIL} AND {F_CC} AND {F_PER('dt_pagamento')}"


def ds_fin(nome, titulo, sql, views):
    return ds_sql(nome, titulo, sql, views, datas=LARGO, cc=True)


d_kpi = ds_fin("fin_kpi", "Financeiro - KPIs", f"""
WITH t AS (SELECT * FROM {_VT} WHERE {F_TIT}),
     f AS (SELECT FORNECEDOR, sum(saldo) AS s FROM t WHERE grupo = 'Efetivo' GROUP BY FORNECEDOR),
     -- Indice Herfindahl-Hirschman (0-10000): > 1500 = concentracao moderada, > 2500 = alta
     h AS (SELECT round(sum(power(try_divide(s, tot), 2)) * 10000, 0) AS hhi
           FROM (SELECT s, sum(s) OVER () AS tot FROM f))
SELECT sum(saldo) AS saldo_total,
       sum(CASE WHEN grupo = 'Efetivo' THEN saldo END) AS saldo_efetivo,
       sum(CASE WHEN grupo = 'Efetivo' AND dias_atraso > 0 THEN saldo END) AS saldo_vencido,
       try_divide(sum(CASE WHEN grupo = 'Efetivo' AND dias_atraso > 0 THEN saldo END),
                  sum(CASE WHEN grupo = 'Efetivo' THEN saldo END)) AS pct_vencido,
       sum(CASE WHEN grupo = 'Provisorio (PR)' THEN saldo END) AS saldo_provisorio,
       count(*) AS qtd_titulos,
       (SELECT hhi FROM h) AS hhi_fornecedores
FROM t""", [_VT])
d_aging = ds_fin("fin_aging", "Financeiro - aging", f"""
SELECT faixa, grupo, sum(saldo) AS saldo, count(*) AS qtd_titulos
FROM {_VT} WHERE {F_TIT} GROUP BY faixa, grupo ORDER BY faixa""", [_VT])
d_fluxo = ds_fin("fin_fluxo", "Financeiro - fluxo semanal", f"""
SELECT date_trunc('WEEK', dt_vencimento) AS semana, grupo, sum(saldo) AS saldo
FROM {_VT} WHERE {F_TIT} AND dt_vencimento BETWEEN current_date() AND date_add(current_date(), 84)
GROUP BY 1, 2 ORDER BY 1""", [_VT])
d_par = ds_fin("fin_pareto", "Financeiro - Pareto fornecedores", f"""
WITH f AS (SELECT FORNECEDOR AS fornecedor, sum(saldo) AS saldo, count(*) AS titulos
           FROM {_VT} WHERE {F_TIT} AND grupo = 'Efetivo' GROUP BY FORNECEDOR),
r AS (SELECT *, row_number() OVER (ORDER BY saldo DESC) AS ranking,
             try_divide(saldo, sum(saldo) OVER ()) AS pct,
             try_divide(sum(saldo) OVER (ORDER BY saldo DESC ROWS UNBOUNDED PRECEDING), sum(saldo) OVER ()) AS pct_acumulado
      FROM f)
SELECT *, CASE WHEN pct_acumulado <= 0.8 THEN 'A' WHEN pct_acumulado <= 0.95 THEN 'B' ELSE 'C' END AS classe
FROM r WHERE ranking <= 30 ORDER BY ranking""", [_VT])
# media movel calculada sobre todos os meses e so depois recortada no periodo
d_pag = ds_fin("fin_pag", "Financeiro - pagamentos por mês", f"""
WITH m AS (
  SELECT mes, sum(PAGO) AS valor_pago, count(DISTINCT REC) AS titulos,
         percentile_approx(prazo_dias, 0.5) AS prazo_mediano_dias,
         try_divide(sum(pago_atraso), sum(PAGO)) AS pct_pago_em_atraso,
         sum(JUROS + MULTA) AS juros_multa
  FROM {_VP} WHERE {F_FIL} AND {F_CC} AND mes IS NOT NULL GROUP BY mes),
mm AS (SELECT *, avg(valor_pago) OVER (ORDER BY mes ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS media_movel_3m FROM m)
SELECT * FROM mm WHERE {F_MES()} ORDER BY mes""", [_VP])
d_fcc = ds_fin("fin_cc", "Financeiro - saldo por CC", f"""
SELECT centro_custo, sum(saldo) AS saldo, count(*) AS titulos
FROM {_VT} WHERE {F_TIT} AND grupo = 'Efetivo' GROUP BY centro_custo ORDER BY saldo DESC LIMIT 15""", [_VT])
d_fpcc = ds_fin("fin_pag_cc", "Financeiro - pago por CC", f"""
SELECT centro_custo, sum(PAGO) AS valor_pago, count(DISTINCT REC) AS titulos
FROM {_VP} WHERE {F_PAG} GROUP BY centro_custo ORDER BY valor_pago DESC LIMIT 15""", [_VP])
d_fccs = ds_ccs("fin_ccs", [_VT, _VP])

pagina("Financeiro", [
    (2, [(texto("""## Contas a pagar
**Como ler:** os títulos **provisórios (PR)** são previsões e ficam separados do saldo **efetivo**. O *aging* mostra quanto do saldo está vencido e há quanto tempo.
O **HHI** mede a concentração da dívida por fornecedor (0 a 10.000; acima de 2.500 = alta). O **Pareto** mostra quantos fornecedores somam 80% do saldo (classe A).
**Filtros:** o período vale para o vencimento dos títulos em aberto e para a data dos pagamentos. O centro de custo é o principal do título (o de maior valor no rateio)."""), 6)]),
    filtros(d_fccs, "Vencimento/pagamento de", "Vencimento/pagamento até"),
    (3, [(contador(d_kpi, "saldo_efetivo", "Saldo efetivo a pagar", BRL), 1),
         (contador(d_kpi, "saldo_vencido", "Saldo vencido", BRL), 1),
         (contador(d_kpi, "pct_vencido", "% vencido", PCT), 1),
         (contador(d_kpi, "saldo_provisorio", "Provisórios (PR)", BRL), 1),
         (contador(d_kpi, "qtd_titulos", "Títulos em aberto", NUM), 1),
         (contador(d_kpi, "hhi_fornecedores", "HHI fornecedores", NUM), 1)]),
    (7, [(grafico("bar", d_aging, "Aging do saldo", ("faixa", "Faixa"), ("saldo", "Saldo"), cor=("grupo", "Grupo"), fmt_y=BRL,
                  descricao="Saldo por faixa de vencimento, separando provisórios"), 3),
         (grafico("bar", d_fluxo, "Vencimentos das próximas 12 semanas", ("semana", "Semana"), ("saldo", "Saldo"),
                  cor=("grupo", "Grupo"), fmt_y=BRL, tipo_x="temporal"), 3)]),
    (8, [(grafico("bar", d_par, "Top 30 fornecedores (saldo efetivo)", ("fornecedor", "Fornecedor"), ("saldo", "Saldo"),
                  cor=("classe", "Classe ABC"), horizontal=True, fmt_y=BRL), 3),
         (tabela(d_par, "Pareto de fornecedores", [("ranking", "#"), ("fornecedor", "Fornecedor"), ("saldo", "Saldo"),
                                                    ("pct", "% do total"), ("pct_acumulado", "% acumulado"), ("classe", "Classe")]), 3)]),
    (7, [(grafico("line", d_pag, "Pagamentos por mês e média móvel de 3 meses", ("mes", "Mês"),
                  [("valor_pago", "Pago no mês"), ("media_movel_3m", "Média móvel 3m")], fmt_y=BRL, tipo_x="temporal"), 3),
         (grafico("line", d_pag, "% pago após o vencimento", ("mes", "Mês"), ("pct_pago_em_atraso", "% em atraso"),
                  fmt_y=PCT, tipo_x="temporal", descricao="Parcela do valor pago depois do vencimento real"), 3)]),
    (7, [(grafico("bar", d_fcc, "Saldo efetivo a pagar por centro de custo (top 15)", ("centro_custo", "Centro de custo"),
                  ("saldo", "Saldo"), horizontal=True, fmt_y=BRL), 3),
         (grafico("bar", d_fpcc, "Pago no período por centro de custo (top 15)", ("centro_custo", "Centro de custo"),
                  ("valor_pago", "Pago"), horizontal=True, fmt_y=BRL), 3)]),
])
salvar("Financeiro")

# ================================================================= COMPRAS
# Aprovacao: filial, centro de custo (o pedido entra quando tem item naquele CC) e emissao do pedido
# entre :data_inicio e :data_fim (padrao: tudo, para mostrar todas as pendencias).
_VPCC = f"{G}.vw_apr_pedido_cc"
F_APR = (f"{F_FIL} "
         f"AND (:centro_custo = 'Todos' OR concat(cod_filial, '|', pedido) IN "
         f"(SELECT chave FROM {_VPCC} WHERE centro_custo = :centro_custo)) "
         "AND (dt_emissao_pedido IS NULL OR dt_emissao_pedido BETWEEN :data_inicio AND :data_fim)")


def ds_apr(nome, titulo, sql, views):
    return ds_sql(nome, titulo, sql, views, datas=LARGO, cc=True)


d_akpi = ds_apr("apr_kpi", "Aprovação - KPIs", f"""
SELECT count(*) AS pedidos_pendentes, coalesce(sum(valor), 0) AS valor_pendente,
       percentile_approx(idade_dias, 0.5) AS idade_mediana_dias,
       count_if(idade_dias > 7) AS pendentes_mais_7_dias,
       (SELECT count(*) FROM {G}.vw_apr_desconsideradas WHERE {F_APR}) AS linhas_desconsideradas
FROM {G}.vw_apr_pedidos WHERE {F_APR}""", ["vw_apr_pedidos"])
d_afila = ds_apr("apr_fila", "Aprovação - por aprovador", f"""
SELECT aprovador, concat_ws(', ', array_sort(collect_set(papel))) AS papel,
       concat_ws(', ', array_sort(collect_set(nivel))) AS niveis,
       count(DISTINCT cod_filial, PEDIDO) AS pedidos, sum(valor) AS valor,
       round(avg(idade_dias), 1) AS idade_media_dias, max(idade_dias) AS idade_max_dias
FROM {G}.vw_apr_fila WHERE {F_APR}
GROUP BY aprovador ORDER BY pedidos DESC, valor DESC""", ["vw_apr_fila"])
d_anivel = ds_apr("apr_nivel", "Aprovação - alçada por nível", f"""
SELECT aprovador, concat('Nível ', nivel) AS nivel, count(DISTINCT cod_filial, PEDIDO) AS pedidos, sum(valor) AS valor,
       round(avg(idade_dias), 1) AS idade_media_dias, max(idade_dias) AS idade_max_dias
FROM {G}.vw_apr_fila WHERE {F_APR}
GROUP BY aprovador, nivel ORDER BY aprovador, nivel""", ["vw_apr_fila"])
d_aped = ds_apr("apr_ped", "Aprovação - pedidos na alçada", f"""
SELECT * FROM {G}.vw_apr_pedidos_alcada WHERE {F_APR} ORDER BY idade_dias DESC""", ["vw_apr_pedidos_alcada"])
d_adesc = ds_apr("apr_desc", "Aprovação - desconsideradas", f"""
SELECT * FROM {G}.vw_apr_desconsideradas WHERE {F_APR} ORDER BY situacao, valor DESC""", ["vw_apr_desconsideradas"])
# Um pedido por linha: quem ainda precisa aprovar, em que nivel e de quais centros de custo sao os itens.
d_apend = ds_apr("apr_pendentes", "Aprovação - pedidos pendentes", f"""
SELECT f.filial, f.ped AS pedido, max(f.valor) AS valor, min(f.dt_emissao_pedido) AS dt_emissao,
       min(f.dt_entrada_alcada) AS dt_entrada_alcada,
       datediff(current_date(), min(f.dt_entrada_alcada)) AS dias_parado,
       concat_ws(', ', array_sort(collect_set(f.aprovador))) AS aprovadores,
       concat_ws(', ', array_sort(collect_set(concat('Nível ', f.nivel)))) AS niveis,
       concat_ws(', ', array_sort(collect_set(f.GRUPO_DESC))) AS grupos,
       concat_ws(', ', array_sort(collect_set(cc.centro_custo))) AS centros_custo
FROM (SELECT *, trim(PEDIDO) AS ped FROM {G}.vw_apr_fila) f
LEFT JOIN {_VPCC} cc ON cc.chave = concat(f.cod_filial, '|', f.ped)
WHERE (:filial = 'Todas' OR f.filial = :filial)
  AND (:centro_custo = 'Todos' OR concat(f.cod_filial, '|', f.ped) IN
       (SELECT chave FROM {_VPCC} WHERE centro_custo = :centro_custo))
  AND (f.dt_emissao_pedido IS NULL OR f.dt_emissao_pedido BETWEEN :data_inicio AND :data_fim)
GROUP BY f.filial, f.ped ORDER BY dias_parado DESC, valor DESC""", ["vw_apr_fila", "vw_apr_pedido_cc"])
d_aidade = ds_apr("apr_idade", "Aprovação - idade", f"""
SELECT CASE WHEN idade_dias <= 2 THEN '1. 0-2 dias' WHEN idade_dias <= 7 THEN '2. 3-7 dias'
            WHEN idade_dias <= 15 THEN '3. 8-15 dias' WHEN idade_dias <= 30 THEN '4. 16-30 dias'
            ELSE '5. > 30 dias' END AS faixa_idade,
       count(*) AS pedidos, sum(valor) AS valor
FROM {G}.vw_apr_pedidos WHERE {F_APR}
GROUP BY 1 ORDER BY 1""", ["vw_apr_pedidos"])

# Solicitacoes e pedidos: filial, CC e periodo (padrao: ano corrente) sobre as views de detalhe.
_VSC, _VLT, _VNF = f"{G}.vw_com_sc", f"{G}.vw_com_leadtime", f"{G}.vw_com_notas"


def ds_com(nome, titulo, sql, views):
    return ds_sql(nome, titulo, sql, views, datas=ANO, cc=True)


d_lt = ds_com("com_lt", "Compras - lead time", f"""
SELECT mes, count(*) AS itens, percentile_approx(dias, 0.5) AS mediana_dias, percentile_approx(dias, 0.9) AS p90_dias
FROM {_VLT} WHERE {F_FIL} AND {F_CC} AND {F_PER('dt_pedido')} GROUP BY mes ORDER BY mes""", [_VLT])
d_sc = ds_com("com_sc", "Compras - SCs por mês", f"""
SELECT mes, status, count(*) AS itens
FROM {_VSC} WHERE {F_FIL} AND {F_CC} AND {F_PER('dt_emissao')} GROUP BY mes, status ORDER BY mes""", [_VSC])
d_nf = ds_com("com_nf", "Compras - notas por mês", f"""
SELECT mes, sum(valor) AS valor, count(*) AS notas, try_divide(count_if(sem_pedido), count(*)) AS pct_sem_pedido
FROM {_VNF} WHERE {F_FIL} AND {F_CC} AND {F_PER('dt_digitacao')} GROUP BY mes ORDER BY mes""", [_VNF])
d_nfcc = ds_com("com_nf_cc", "Compras - notas por CC", f"""
SELECT centro_custo, sum(valor) AS valor, count(*) AS notas
FROM {_VNF} WHERE {F_FIL} AND {F_CC} AND {F_PER('dt_digitacao')}
GROUP BY centro_custo ORDER BY valor DESC LIMIT 15""", [_VNF])
d_sccc = ds_com("com_sc_cc", "Compras - SCs por CC", f"""
SELECT centro_custo, count(*) AS itens
FROM {_VSC} WHERE {F_FIL} AND {F_CC} AND {F_PER('dt_emissao')}
GROUP BY centro_custo ORDER BY itens DESC LIMIT 15""", [_VSC])
d_cccs = ds_ccs("com_ccs", [_VPCC, _VSC, _VLT, _VNF])

pagina("Aprovação", [
    (2, [(texto("""## Fila de aprovação de pedidos
Entram na fila só os **aprovadores de fato**: quem está no **grupo de aprovação (SAL)** do pedido como aprovador (vistador fica de fora) e, quando o grupo **considera os limites** (AL_AUTOLIM = Sim), só com o **valor do pedido dentro da alçada** dele.
Só conta o **nível atual** do pedido: enquanto o nível anterior não libera, o pedido não aparece para o aprovador do nível acima. O que fica de fora aparece na tabela de conferência no fim da página. **Datas:** filtram pela emissão do pedido. **Centro de custo:** o pedido entra quando tem algum item naquele CC."""), 6)]),
    filtros(d_cccs, "Emissão de", "Emissão até"),
    (3, [(contador(d_akpi, "pedidos_pendentes", "Pedidos aguardando aprovação", NUM), 2),
         (contador(d_akpi, "valor_pendente", "Valor aguardando aprovação", BRL), 1),
         (contador(d_akpi, "idade_mediana_dias", "Idade mediana (dias)", NUM), 1),
         (contador(d_akpi, "pendentes_mais_7_dias", "Parados > 7 dias", NUM), 1),
         (contador(d_akpi, "linhas_desconsideradas", "Pendências desconsideradas", NUM), 1)]),
    (9, [(tabela(d_apend, "Pedidos pendentes de aprovação (um por pedido, mais antigos primeiro)",
                 [("filial", "Filial"), ("pedido", "Pedido"), ("valor", "Valor"), ("aprovadores", "Aguardando"),
                  ("niveis", "Níveis"), ("grupos", "Grupo"), ("centros_custo", "Centros de custo"),
                  ("dt_emissao", "Emissão"), ("dt_entrada_alcada", "Entrou na alçada"), ("dias_parado", "Dias parado")],
                 descricao="Cada pedido aparece uma vez; o valor é o total do pedido. 'Aguardando' lista os aprovadores da SAL que ainda precisam liberar"), 6)]),
    (7, [(grafico("bar", d_afila, "Pedidos pendentes por aprovador", ("aprovador", "Aprovador"), ("pedidos", "Pedidos"),
                  horizontal=True, fmt_y=NUM,
                  descricao="Pedidos que já chegaram no nível do aprovador (aprovador da SAL, valor dentro da alçada). Pedido com mais de um aprovador aparece em cada um"), 3),
         (tabela(d_afila, "Fila por aprovador", [("aprovador", "Aprovador"), ("papel", "Liberação"), ("niveis", "Níveis"),
                                                  ("pedidos", "Pedidos"), ("valor", "Valor"),
                                                  ("idade_media_dias", "Idade média (dias)"), ("idade_max_dias", "Mais antigo (dias)")]), 3)]),
    (7, [(grafico("bar", d_anivel, "Valor parado por nível da alçada", ("aprovador", "Aprovador"), ("valor", "Valor"),
                  cor=("nivel", "Nível"), horizontal=True, fmt_y=BRL,
                  descricao="Nível do grupo de aprovação em que o pedido aguarda cada aprovador"), 3),
         (tabela(d_anivel, "Fila por nível", [("aprovador", "Aprovador"), ("nivel", "Nível"), ("pedidos", "Pedidos"),
                                               ("valor", "Valor"), ("idade_media_dias", "Idade média (dias)"),
                                               ("idade_max_dias", "Mais antigo (dias)")]), 3)]),
    (8, [(grafico("bar", d_aidade, "Pedidos pendentes por idade", ("faixa_idade", "Idade"), ("pedidos", "Pedidos")), 2),
         (tabela(d_aped, "Pedidos parados na alçada (mais antigos primeiro)",
                 [("filial", "Filial"), ("pedido", "Pedido"), ("grupo", "Grupo"), ("nivel", "Nível"), ("aprovador", "Aprovador"),
                  ("valor", "Valor"), ("limite_min", "Alçada de"), ("limite_max", "Alçada até"),
                  ("dt_emissao_pedido", "Emissão"), ("dt_entrada_alcada", "Entrou na alçada"), ("idade_dias", "Dias")]), 4)]),
    (7, [(tabela(d_adesc, "Conferência: pendências desconsideradas",
                 [("situacao", "Motivo"), ("aprovador", "Aprovador"), ("filial", "Filial"), ("pedido", "Pedido"),
                  ("grupo", "Grupo"), ("nivel", "Nível"), ("valor", "Valor"), ("limite_min", "Alçada de"),
                  ("limite_max", "Alçada até"), ("dt_emissao_pedido", "Emissão"), ("idade_dias", "Dias")],
                 descricao="Linhas da SCR com status 02 que não entram na fila: vistador, fora do grupo (SAL) ou valor fora da alçada com AL_AUTOLIM = Sim"), 6)]),
])

pagina("Solicitações e pedidos", [
    (2, [(texto("""## Solicitações, pedidos e notas
**Lead time:** dias entre a solicitação de compra e o pedido. A **mediana** mostra o caso típico; o **P90**, os 10% mais lentos. Se o P90 se afasta da mediana, há gargalo em casos específicos.
**Filtros:** o período vale para a emissão da SC, a emissão do pedido (lead time) e a digitação da nota. O centro de custo é o do item (na nota, o do documento)."""), 6)]),
    filtros(d_cccs),
    (7, [(grafico("line", d_lt, "Lead time SC → pedido (dias)", ("mes", "Mês"),
                  [("mediana_dias", "Mediana"), ("p90_dias", "P90")], tipo_x="temporal"), 6)]),
    (6, [(grafico("bar", d_sc, "Itens de solicitação por mês e status", ("mes", "Mês"), ("itens", "Itens"), cor=("status", "Status"), tipo_x="temporal"), 3),
         (grafico("bar", d_nf, "Notas de entrada por mês", ("mes", "Mês"), ("valor", "Valor"), fmt_y=BRL, tipo_x="temporal"), 3)]),
    (7, [(grafico("bar", d_sccc, "Itens de solicitação por centro de custo (top 15)", ("centro_custo", "Centro de custo"),
                  ("itens", "Itens"), horizontal=True), 3),
         (grafico("bar", d_nfcc, "Notas de entrada por centro de custo (top 15)", ("centro_custo", "Centro de custo"),
                  ("valor", "Valor"), horizontal=True, fmt_y=BRL), 3)]),
])
salvar("Compras")

# ================================================================= FROTA
# Filtros: filial, centro de custo e periodo (padrao: ano corrente).
# Custo da frota = pecas + pneus + servicos de terceiros (OS, pela abertura) + combustivel (abastecimentos, pela
# data do abastecimento), da view vw_mnt_custos. Custo por dia = custo / dias do periodo (ate hoje).
_VOS, _VKM, _VAT, _VCU = f"{G}.vw_mnt_os", f"{G}.vw_mnt_km_mes", f"{G}.vw_mnt_os_atipicas", f"{G}.vw_mnt_custos"
F_OS = f"{F_FIL} AND {F_CC} AND {F_PER('dt_abertura')}"
F_CU = f"{F_FIL} AND {F_CC} AND {F_PER('data')}"
TOP_BENS = 50
# dias do periodo escolhido, contando so ate hoje (o periodo padrao vai ate 31/12)
_DIAS = "greatest(datediff(least(:data_fim, current_date()), :data_inicio) + 1, 1)"
_BEM_DESC = "CASE WHEN bem_nome LIKE concat(bem, '%') THEN bem_nome ELSE concat_ws(' - ', bem, bem_nome) END"


def ds_mnt(nome, titulo, sql, views):
    return ds_sql(nome, titulo, sql, views, datas=ANO, cc=True)


def _sql_bens(top):
    """Custo por bem no periodo, aberto por origem, com custo por dia e por km; so os `top` maiores."""
    return f"""
WITH c AS (SELECT bem, max({_BEM_DESC}) AS bem_desc, max(familia) AS familia, sum(valor) AS custo,
                  sum(CASE WHEN origem = 'Peças' THEN valor ELSE 0 END) AS custo_pecas,
                  sum(CASE WHEN origem = 'Serviços de terceiros' THEN valor ELSE 0 END) AS custo_terceiros,
                  sum(CASE WHEN origem = 'Pneus' THEN valor ELSE 0 END) AS custo_pneus,
                  sum(CASE WHEN origem = 'Combustível' THEN valor ELSE 0 END) AS custo_combustivel,
                  sum(CASE WHEN origem = 'Combustível' THEN quantidade ELSE 0 END) AS litros
           FROM {_VCU} WHERE {F_CU} GROUP BY bem),
o AS (SELECT bem, count(*) AS qtd_os FROM {_VOS} WHERE {F_OS} GROUP BY bem),
k AS (SELECT bem, sum(km_rodados) AS km_rodados FROM {_VKM} WHERE {F_MES()} GROUP BY bem),
r AS (SELECT c.*, coalesce(o.qtd_os, 0) AS qtd_os, k.km_rodados,
             try_divide(c.custo, {_DIAS}) AS custo_dia, try_divide(c.custo, k.km_rodados) AS custo_por_km,
             row_number() OVER (ORDER BY c.custo DESC) AS ranking
      FROM c LEFT JOIN o ON o.bem = c.bem LEFT JOIN k ON k.bem = c.bem)
SELECT * FROM r WHERE ranking <= {top} ORDER BY ranking"""


d_mkpi = ds_mnt("mnt_kpi", "Frota - KPIs", f"""
WITH c AS (SELECT * FROM {_VCU} WHERE {F_CU})
SELECT (SELECT count(*) FROM {_VOS} WHERE {F_OS}) AS os_periodo,
       (SELECT count_if(NOT terminada) FROM {_VOS} WHERE {F_OS}) AS os_abertas,
       sum(valor) AS custo_total, try_divide(sum(valor), {_DIAS}) AS custo_dia,
       sum(CASE WHEN origem IN ('Peças', 'Serviços de terceiros') THEN valor ELSE 0 END) AS custo_manutencao,
       sum(CASE WHEN origem = 'Pneus' THEN valor ELSE 0 END) AS custo_pneus,
       sum(CASE WHEN origem = 'Combustível' THEN valor ELSE 0 END) AS custo_combustivel,
       count(DISTINCT bem) AS bens_com_custo
FROM c""", [_VOS, _VCU])
d_mmes = ds_mnt("mnt_mes", "Frota - OS por mês", f"""
SELECT date_trunc('MONTH', dt_abertura) AS mes, tipo_manutencao, count(*) AS qtd_os
FROM {_VOS} WHERE {F_OS} GROUP BY 1, 2 ORDER BY 1""", [_VOS])
d_mcmes = ds_mnt("mnt_custo_mes", "Frota - custo por mês e origem", f"""
SELECT date_trunc('MONTH', data) AS mes, origem, sum(valor) AS custo
FROM {_VCU} WHERE {F_CU} GROUP BY 1, 2 ORDER BY 1""", [_VCU])
d_mfam = ds_mnt("mnt_fam", "Frota - custo por família", f"""
WITH f AS (SELECT coalesce(familia, 'Sem familia') AS familia, origem, sum(valor) AS custo FROM {_VCU} WHERE {F_CU} GROUP BY 1, 2),
t AS (SELECT familia FROM f GROUP BY 1 ORDER BY sum(custo) DESC LIMIT 15)
SELECT f.* FROM f JOIN t USING (familia)""", [_VCU])
d_mcc = ds_mnt("mnt_cc", "Frota - custo por CC", f"""
WITH f AS (SELECT centro_custo, origem, sum(valor) AS custo FROM {_VCU} WHERE {F_CU} GROUP BY 1, 2),
t AS (SELECT centro_custo FROM f GROUP BY 1 ORDER BY sum(custo) DESC LIMIT 15)
SELECT f.* FROM f JOIN t USING (centro_custo)""", [_VCU])
d_mbem = ds_mnt("mnt_bem", "Frota - custo por bem", _sql_bens(TOP_BENS), [_VCU, _VOS])
# lancamentos dos maiores bens: grafico de ranking, composicao, evolucao mensal e tabela de detalhe no MESMO
# dataset, para o clique numa barra do ranking filtrar o detalhamento (cross-filter)
d_mdet = ds_mnt("mnt_detalhe", "Frota - detalhamento do custo por bem", f"""
WITH d AS (SELECT *, {_BEM_DESC} AS bem_desc FROM {_VCU} WHERE {F_CU}),
r AS (SELECT bem, row_number() OVER (ORDER BY sum(valor) DESC) AS ranking FROM d GROUP BY bem)
SELECT d.filial, d.centro_custo, d.bem, d.bem_desc, d.familia, d.data, date_trunc('MONTH', d.data) AS mes,
       d.origem, d.documento, d.descricao, d.quantidade, d.valor,
       try_divide(d.valor, {_DIAS}) AS valor_dia, r.ranking
FROM d JOIN r ON r.bem = d.bem WHERE r.ranking <= {TOP_BENS}
ORDER BY r.ranking, d.data, d.documento""", [_VCU])
d_matp = ds_mnt("mnt_atip", "Frota - OS atípicas", f"""
SELECT * FROM {_VAT} WHERE {F_OS} ORDER BY z_score DESC LIMIT 100""", [_VAT])
d_mccs = ds_ccs("mnt_ccs", [_VOS, _VCU])

pagina("Frota", [
    (2, [(texto(f"""## Custo da frota
**Custo da frota** = peças + pneus + serviços de terceiros das OS + combustível dos abastecimentos. **Custo/dia** = custo ÷ dias do período (contados até hoje).
**Detalhamento:** clique numa barra do ranking **{TOP_BENS} bens com maior custo** (ou escolha no filtro *Bem*) e a composição, a evolução mensal e a tabela de lançamentos mostram só aquele bem. Clique de novo para limpar.
**OS atípicas:** custo mais de 3 desvios-padrão acima da média do mesmo serviço (z-score > 3). **Filtros:** o período vale para a abertura da OS e a data do abastecimento; o centro de custo é o da OS / do abastecimento."""), 6)]),
    filtros(d_mccs, "Período de", "Período até"),
    (3, [(contador(d_mkpi, "custo_total", "Custo total da frota", BRL), 1),
         (contador(d_mkpi, "custo_dia", "Custo por dia", BRL), 1),
         (contador(d_mkpi, "custo_manutencao", "Manutenção (peças + terceiros)", BRL), 1),
         (contador(d_mkpi, "custo_pneus", "Pneus", BRL), 1),
         (contador(d_mkpi, "custo_combustivel", "Combustível", BRL), 1),
         (contador(d_mkpi, "os_abertas", "OS não terminadas", NUM), 1)]),
    (2, [(filtro_campo("bem_desc", "Bem", [d_mdet, d_mbem]), 3)]),
    (10, [(grafico_soma("bar", d_mdet, f"{TOP_BENS} bens com maior custo (clique para detalhar)", ("bem_desc", "Bem"),
                        ("valor", "Custo no período"), horizontal=True, fmt_y=BRL,
                        extra=[("valor_dia", "Custo por dia", BRL)],
                        descricao="Passe o mouse para ver o custo no período e o custo por dia"), 3),
          (grafico_soma("bar", d_mdet, "Composição do custo", ("origem", "Origem"), ("valor", "Custo"),
                        horizontal=True, fmt_y=BRL, extra=[("valor_dia", "Custo por dia", BRL)],
                        descricao="Do bem clicado no ranking (ou de todos os bens do ranking)"), 3)]),
    (7, [(grafico_soma("line", d_mdet, "Custo por mês do bem selecionado", ("mes", "Mês"), ("valor", "Custo"),
                       cor=("origem", "Origem"), fmt_y=BRL, tipo_x="temporal",
                       extra=[("valor_dia", "Custo por dia", BRL)]), 6)]),
    (9, [(tabela(d_mdet, "Detalhamento: como se chegou ao custo do bem",
                 [("bem_desc", "Bem"), ("data", "Data"), ("origem", "Origem"), ("documento", "OS / abastecimento"),
                  ("descricao", "Item"), ("quantidade", "Qtd / litros"), ("valor", "Valor"), ("filial", "Filial"),
                  ("centro_custo", "Centro de custo")],
                 descricao="Cada linha é uma peça/pneu aplicado na OS, o serviço de terceiros da OS ou um abastecimento. A soma dá o custo do bem"), 6)]),
    (8, [(tabela(d_mbem, "Bens com maior custo", [("ranking", "#"), ("bem_desc", "Bem"), ("familia", "Família"),
                                                   ("custo", "Custo total"), ("custo_dia", "Custo/dia"),
                                                   ("custo_pecas", "Peças"), ("custo_terceiros", "Terceiros"),
                                                   ("custo_pneus", "Pneus"), ("custo_combustivel", "Combustível"),
                                                   ("litros", "Litros"), ("qtd_os", "OS"), ("km_rodados", "Km"),
                                                   ("custo_por_km", "R$/km")]), 6)]),
    (7, [(grafico("line", d_mcmes, "Custo da frota por mês e origem", ("mes", "Mês"), ("custo", "Custo"),
                  cor=("origem", "Origem"), fmt_y=BRL, tipo_x="temporal"), 3),
         (grafico("bar", d_mmes, "OS por mês e tipo de manutenção", ("mes", "Mês"), ("qtd_os", "OS"),
                  cor=("tipo_manutencao", "Tipo"), tipo_x="temporal"), 3)]),
    (7, [(grafico("bar", d_mfam, "Custo por família de bem (top 15)", ("familia", "Família"), ("custo", "Custo"),
                  cor=("origem", "Origem"), horizontal=True, fmt_y=BRL), 3),
         (grafico("bar", d_mcc, "Custo por centro de custo (top 15)", ("centro_custo", "Centro de custo"), ("custo", "Custo"),
                  cor=("origem", "Origem"), horizontal=True, fmt_y=BRL), 3)]),
    (8, [(tabela(d_matp, "OS com custo atípico (z-score > 3)", [("filial", "Filial"), ("OS", "OS"), ("bem_nome", "Bem"), ("servico", "Serviço"),
                                                               ("centro_custo", "Centro de custo"), ("custo", "Custo"),
                                                               ("media_servico", "Média do serviço"), ("z_score", "z")]), 6)]),
])
salvar("Frota")

# ================================================================= ESTOQUE
d_ekpi = ds("est_kpi", "Estoque - KPIs", "vw_est_kpi")
d_abc = ds("est_abc", "Estoque - curva ABC", "vw_est_abc", order="classe")
d_fech = ds("est_fech", "Estoque - fechamentos", "vw_est_fechamentos", order="mes")
d_aj = ds("est_aj", "Estoque - ajustes", "vw_est_ajustes_mes", order="mes")
d_par2 = ds("est_par", "Estoque - itens parados", "vw_est_parados", detalhe=True, order="valor DESC", limit=200)

pagina("Estoque", [
    (2, [(texto("""## Almoxarifado
**Curva ABC:** poucos itens (classe A) concentram 80% do valor e merecem controle mais rígido. **Parado:** item com saldo e sem saída há mais de 180 dias (ou nunca); é capital imobilizado.
**Saldo negativo** indica movimento fora de ordem ou erro de lançamento, e distorce o custo médio."""), 4),
         (filtro(), 2)]),
    (3, [(contador(d_ekpi, "valor_estoque", "Valor em estoque", BRL), 2),
         (contador(d_ekpi, "valor_parado_180d", "Parado > 180 dias", BRL), 1),
         (contador(d_ekpi, "pct_parado", "% parado", PCT), 1),
         (contador(d_ekpi, "itens_saldo_negativo", "Saldos negativos", NUM), 1),
         (contador(d_ekpi, "produtos", "Produtos", NUM), 1)]),
    (6, [(grafico("bar", d_abc, "Curva ABC: valor por classe", ("classe", "Classe"), ("valor", "Valor"), fmt_y=BRL), 2),
         (tabela(d_abc, "Curva ABC", [("classe", "Classe"), ("produtos", "Produtos"), ("valor", "Valor"), ("pct_valor", "% do valor")]), 2),
         (grafico("line", d_fech, "Valor do estoque nos fechamentos", ("mes", "Mês"), ("valor", "Valor"), fmt_y=BRL, tipo_x="temporal"), 2)]),
    (8, [(grafico("bar", d_aj, "Ajustes de estoque por mês", ("mes", "Mês"), ("valor", "Valor"),
                  cor=("tipo", "Tipo"), fmt_y=BRL, tipo_x="temporal"), 2),
         (tabela(d_par2, "Itens parados de maior valor", [("filial", "Filial"), ("produto", "Produto"), ("descricao", "Descrição"),
                                                          ("grupo", "Grupo"), ("armazem", "Armazém"), ("quantidade", "Qtd"),
                                                          ("valor", "Valor"), ("sem_saida", "Dias sem saída")],
                 descricao="Um registro por filial + produto + armazém. 'Nunca' = sem saída registrada"), 4)]),
])
salvar("Estoque")

# ================================================================= PESSOAS
# Filtros: filial, centro de custo e periodo (padrao: ano corrente). O quadro e a situacao de hoje:
# segue filial e CC, mas nao o periodo. Movimento e folha pela competencia; saude pela data do atestado/acidente.
_VQ, _VAD, _VFO = f"{G}.vw_rh_quadro", f"{G}.vw_rh_adm_dem", f"{G}.vw_rh_folha"
_VMA, _VMC = f"{G}.vw_med_atestados", f"{G}.vw_med_acidentes"
F_FC = f"{F_FIL} AND {F_CC}"


def ds_rh(nome, titulo, sql, views, datas=True):
    return ds_sql(nome, titulo, sql, views, datas=ANO if datas else False, cc=True)


d_rkpi = ds_rh("rh_kpi", "Pessoas - KPIs", f"""
WITH q AS (SELECT sum(N) AS headcount,
                  sum(CASE WHEN SIT = 'A' THEN N ELSE 0 END) AS afastados,
                  sum(CASE WHEN SIT = 'F' THEN N ELSE 0 END) AS em_ferias
           FROM {_VQ} WHERE {F_FC}),
     d AS (SELECT sum(ADM) AS adm_periodo, sum(DEM) AS dem_periodo FROM {_VAD} WHERE {F_FC} AND {F_MES()})
SELECT q.*, d.*, try_divide(d.dem_periodo, q.headcount) AS turnover_periodo,
       try_divide(q.afastados, q.headcount) AS pct_afastados
FROM q CROSS JOIN d""", [_VQ, _VAD])
d_mov = ds_rh("rh_mov", "Pessoas - movimento", f"""
SELECT mes, 'Admissões' AS tipo, sum(ADM) AS pessoas FROM {_VAD} WHERE {F_FC} AND {F_MES()} GROUP BY mes
UNION ALL
SELECT mes, 'Demissões' AS tipo, sum(DEM) AS pessoas FROM {_VAD} WHERE {F_FC} AND {F_MES()} GROUP BY mes
ORDER BY mes""", [_VAD])
d_fol = ds_rh("rh_fol", "Pessoas - folha", f"""
SELECT mes, sum(proventos) AS proventos, sum(descontos) AS descontos, sum(proventos) - sum(descontos) AS liquido
FROM {_VFO} WHERE {F_FC} AND {F_MES()} GROUP BY mes ORDER BY mes""", [_VFO])
d_qcc = ds_rh("rh_qcc", "Pessoas - quadro por CC", f"""
SELECT centro_custo, sum(N) AS pessoas, sum(CASE WHEN SIT = 'A' THEN N ELSE 0 END) AS afastados
FROM {_VQ} WHERE {F_FC} GROUP BY centro_custo ORDER BY pessoas DESC LIMIT 15""", [_VQ], datas=False)
d_med = ds_rh("med_mes", "Saúde - por mês", f"""
WITH a AS (SELECT date_trunc('MONTH', dt_inicio) AS mes, count(*) AS atestados,
                  sum(coalesce(datediff(dt_fim, dt_inicio) + 1, 1)) AS dias_atestado
           FROM {_VMA} WHERE {F_FC} AND {F_PER('dt_inicio')} GROUP BY 1),
     c AS (SELECT date_trunc('MONTH', dt_acidente) AS mes, count(*) AS acidentes,
                  count_if(com_afastamento) AS acidentes_com_afastamento
           FROM {_VMC} WHERE {F_FC} AND {F_PER('dt_acidente')} GROUP BY 1)
SELECT coalesce(a.mes, c.mes) AS mes,
       coalesce(atestados, 0) AS atestados, coalesce(dias_atestado, 0) AS dias_atestado,
       coalesce(acidentes, 0) AS acidentes, coalesce(acidentes_com_afastamento, 0) AS acidentes_com_afastamento
FROM a FULL OUTER JOIN c ON a.mes = c.mes ORDER BY mes""", [_VMA, _VMC])
d_cid = ds_rh("med_cid", "Saúde - diagnósticos", f"""
SELECT diagnostico, count(*) AS atestados, sum(coalesce(datediff(dt_fim, dt_inicio) + 1, 1)) AS dias
FROM {_VMA} WHERE {F_FC} AND {F_PER('dt_inicio')}
GROUP BY diagnostico ORDER BY atestados DESC LIMIT 10""", [_VMA])
d_rccs = ds_ccs("rh_ccs", [_VQ, _VAD, _VFO, _VMA, _VMC])

pagina("Pessoas", [
    (2, [(texto("""## Pessoas (somente agregados, sem dados individuais)
**Turnover no período** = desligamentos no período ÷ quadro atual. **Folha:** proventos e descontos das competências fechadas.
**Saúde:** atestados e acidentes por mês, e os diagnósticos mais frequentes (pelo CID).
**Filtros:** o período vale para movimento e folha (competência) e para atestados/acidentes (data). O **quadro** é a situação de hoje e segue só filial e centro de custo."""), 6)]),
    filtros(d_rccs),
    (3, [(contador(d_rkpi, "headcount", "Quadro atual", NUM), 1),
         (contador(d_rkpi, "afastados", "Afastados", NUM), 1),
         (contador(d_rkpi, "em_ferias", "Em férias", NUM), 1),
         (contador(d_rkpi, "pct_afastados", "% afastados", PCT), 1),
         (contador(d_rkpi, "turnover_periodo", "Turnover no período", PCT), 2)]),
    (6, [(grafico("bar", d_mov, "Admissões × demissões por mês", ("mes", "Mês"), ("pessoas", "Pessoas"),
                  cor=("tipo", "Movimento"), tipo_x="temporal"), 3),
         (grafico("line", d_fol, "Folha por competência", ("mes", "Mês"),
                  [("proventos", "Proventos"), ("descontos", "Descontos")], fmt_y=BRL, tipo_x="temporal"), 3)]),
    (7, [(grafico("bar", d_qcc, "Quadro por centro de custo (top 15)", ("centro_custo", "Centro de custo"), ("pessoas", "Pessoas"), horizontal=True), 3),
         (grafico("line", d_med, "Atestados e acidentes por mês", ("mes", "Mês"),
                  [("atestados", "Atestados"), ("acidentes", "Acidentes")], tipo_x="temporal"), 3)]),
    (6, [(grafico("bar", d_cid, "Diagnósticos mais frequentes nos atestados", ("diagnostico", "Diagnóstico"), ("atestados", "Atestados"), horizontal=True), 6)]),
])
salvar("Pessoas")

# ================================================================= CONTRATOS (so compra)
# Filtros (todas as paginas): filial, centro de custo e periodo :data_inicio..:data_fim (padrao: ano corrente).
#  - medicoes: data de entrega no periodo e centro de custo do item medido;
#  - revisoes: data da revisao no periodo;
#  - contratos: vigencia (inicio..fim) cruzando o periodo.
# O contrato (CN9) nao tem centro de custo; ele entra no filtro de CC quando tem medicao com aquele CC.
# Como tudo precisa ser recalculado para o periodo/CC escolhidos, os datasets agregam direto das views de detalhe.
PER_CTR = ANO
_VC, _VR, _VM = f"{G}.vw_ctr_contratos", f"{G}.vw_ctr_revisoes_feitas", f"{G}.vw_ctr_medicoes"
# medicoes (alias livre): filial + CC + entrega no periodo
F_MED = f"{F_FIL} AND (:centro_custo = 'Todos' OR centro_custo = :centro_custo) AND dt_entrega BETWEEN :data_inicio AND :data_fim"
# contrato/revisao com alias c: tem medicao no CC escolhido
F_CC_CTR = (f"(:centro_custo = 'Todos' OR EXISTS (SELECT 1 FROM {_VM} cm WHERE cm.cod_filial = c.cod_filial "
            f"AND cm.contrato = c.contrato AND cm.centro_custo = :centro_custo))")
F_VIG = (f"{F_FIL} AND {F_CC_CTR} AND (c.dt_inicio IS NULL OR c.dt_inicio <= :data_fim) "
         f"AND (c.dt_fim IS NULL OR c.dt_fim >= :data_inicio)")
F_REV = f"{F_FIL} AND {F_CC_CTR} AND c.dt_revisao BETWEEN :data_inicio AND :data_fim"
# meses do periodo ate hoje (para a media mensal)
_MESES = ("greatest(1, months_between(date_trunc('MONTH', least(:data_fim, current_date())), "
          "date_trunc('MONTH', :data_inicio)) + 1)")


def ds_ctr(nome, titulo, sql, views):
    return ds_sql(nome, titulo, sql, views, datas=PER_CTR, cc=True)


d_ckpi = ds_ctr("ctr_kpi", "Contratos - KPIs", f"""
WITH c AS (SELECT * FROM {_VC} c WHERE vigente AND {F_VIG}),
     r AS (SELECT * FROM {_VR} c WHERE {F_REV}),
     m AS (SELECT * FROM {_VM} WHERE {F_MED})
SELECT (SELECT count(*) FROM c) AS contratos_vigentes,
       (SELECT sum(vl_atual) FROM c) AS valor_contratado,
       (SELECT sum(saldo) FROM c) AS saldo_a_medir,
       (SELECT try_divide(sum(vl_atual - saldo), sum(vl_atual)) FROM c) AS pct_consumido,
       (SELECT sum(crescimento) FROM c) AS crescimento_valor,
       (SELECT try_divide(sum(crescimento), sum(vl_original)) FROM c) AS pct_crescimento,
       (SELECT count(alerta) FROM c) AS contratos_em_alerta,
       (SELECT count(DISTINCT cod_filial, contrato) FROM r) AS revisados_periodo,
       (SELECT coalesce(sum(impacto), 0) FROM r) AS impacto_revisoes_periodo,
       (SELECT sum(valor) FROM m) AS medido_periodo,
       (SELECT try_divide(sum(valor), {_MESES}) FROM m) AS media_mensal_periodo,
       (SELECT count(DISTINCT cod_filial, contrato) FROM m) AS contratos_com_medicao""",
                [_VC, _VR, _VM])
# media movel calculada sobre todos os meses e so depois recortada no periodo (o 1o mes nao fica sem historico)
d_cmes = ds_ctr("ctr_mes", "Contratos - medição por mês", f"""
WITH m AS (
  SELECT mes, sum(valor) AS valor, count(DISTINCT cod_filial, contrato, medicao) AS medicoes,
         count(DISTINCT cod_filial, contrato) AS contratos
  FROM {_VM}
  WHERE {F_FIL} AND (:centro_custo = 'Todos' OR centro_custo = :centro_custo) AND mes IS NOT NULL
  GROUP BY mes),
mm AS (SELECT *, avg(valor) OVER (ORDER BY mes ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS media_movel_3m FROM m)
SELECT * FROM mm WHERE mes BETWEEN date_trunc('MONTH', :data_inicio) AND :data_fim ORDER BY mes""", [_VM])
d_crev = ds_ctr("ctr_rev_tipo", "Contratos - impacto por tipo de revisão", f"""
SELECT tipo_revisao, count(*) AS revisoes, count(DISTINCT cod_filial, contrato) AS contratos, sum(impacto) AS impacto
FROM {_VR} c WHERE {F_REV}
GROUP BY tipo_revisao ORDER BY impacto DESC""", [_VR])
d_cforn = ds_ctr("ctr_forn", "Contratos - Pareto de fornecedores", f"""
WITH f AS (SELECT fornecedor, sum(valor) AS valor, count(DISTINCT cod_filial, contrato) AS contratos
           FROM {_VM} WHERE {F_MED} GROUP BY fornecedor),
r AS (SELECT *, row_number() OVER (ORDER BY valor DESC) AS ranking,
             try_divide(valor, sum(valor) OVER ()) AS pct,
             try_divide(sum(valor) OVER (ORDER BY valor DESC ROWS UNBOUNDED PRECEDING), sum(valor) OVER ()) AS pct_acumulado
      FROM f)
SELECT *, CASE WHEN pct_acumulado <= 0.8 THEN 'A' WHEN pct_acumulado <= 0.95 THEN 'B' ELSE 'C' END AS classe
FROM r WHERE ranking <= 15 ORDER BY ranking""", [_VM])
d_ccc = ds_ctr("ctr_cc", "Contratos - medido por CC", f"""
SELECT centro_custo, sum(valor) AS valor, count(DISTINCT cod_filial, contrato) AS contratos
FROM {_VM} WHERE {F_MED} GROUP BY centro_custo ORDER BY valor DESC LIMIT 15""", [_VM])
d_cproj = ds_ctr("ctr_proj", "Contratos - medido por projeto", f"""
SELECT projeto, sum(valor) AS valor, count(DISTINCT cod_filial, contrato) AS contratos
FROM {_VM} WHERE {F_MED} GROUP BY projeto ORDER BY valor DESC LIMIT 15""", [_VM])
# alertas sao a situacao de hoje: o periodo nao se aplica, so filial e CC
d_calert = ds_sql("ctr_alertas", "Contratos - alertas", f"""
SELECT filial, contrato, fornecedor, tipo_contrato, alerta, dt_fim, dias_para_vencer,
       vl_original, vl_atual, saldo, pct_consumido, pct_crescimento
FROM {_VC} c WHERE alerta IS NOT NULL AND {F_FIL} AND {F_CC_CTR} ORDER BY alerta, saldo""", [_VC], cc=True)
d_c30 = ds_ctr("ctr_rev_periodo", "Contratos - revisados no período", f"""
SELECT filial, contrato, revisao, dt_revisao, tipo_revisao, fornecedor, vl_atual, impacto
FROM {_VR} c WHERE {F_REV} ORDER BY dt_revisao DESC""", [_VR])
d_cvig = ds_ctr("ctr_vig", "Contratos - vigentes", f"""
SELECT * FROM {_VC} c WHERE vigente AND {F_VIG} ORDER BY vl_atual DESC""", [_VC])
d_cccs_ctr = ds_ccs("ctr_ccs", [_VM])


def _filtros_ctr():
    return filtros(d_cccs_ctr)


pagina("Visão estratégica", [
    (2, [(texto("""## Contratos de compra: custo contratado, consumido e crescimento
**Contratado × consumido:** contratos vigentes cuja vigência cruza o período, e quanto já foi medido. **Crescimento:** quanto o valor atual passou do valor original (aditivos e reajustes); é custo que não estava no orçamento inicial.
**Filtros:** o período vale para medições (data de entrega), revisões (data da revisão) e vigência dos contratos. O centro de custo vem dos itens medidos: um contrato entra no CC quando tem medição nele. Os alertas são a situação de hoje e não seguem o período."""), 6)]),
    _filtros_ctr(),
    (3, [(contador(d_ckpi, "valor_contratado", "Valor contratado (vigentes)", BRL), 1),
         (contador(d_ckpi, "saldo_a_medir", "Saldo a medir", BRL), 1),
         (contador(d_ckpi, "pct_consumido", "% consumido", PCT), 1),
         (contador(d_ckpi, "crescimento_valor", "Crescimento vs. valor original", BRL), 1),
         (contador(d_ckpi, "pct_crescimento", "% de crescimento", PCT), 1),
         (contador(d_ckpi, "medido_periodo", "Medido no período", BRL), 1)]),
    (3, [(contador(d_ckpi, "contratos_vigentes", "Contratos vigentes", NUM), 1),
         (contador(d_ckpi, "revisados_periodo", "Contratos revisados no período", NUM), 1),
         (contador(d_ckpi, "impacto_revisoes_periodo", "Impacto das revisões no período", BRL), 1),
         (contador(d_ckpi, "media_mensal_periodo", "Média mensal medida", BRL), 1),
         (contador(d_ckpi, "contratos_com_medicao", "Contratos com medição no período", NUM), 1),
         (contador(d_ckpi, "contratos_em_alerta", "Contratos em alerta", NUM), 1)]),
    (7, [(grafico("line", d_cmes, "Valor medido por mês e média móvel de 3 meses", ("mes", "Mês"),
                  [("valor", "Medido no mês"), ("media_movel_3m", "Média móvel 3m")], fmt_y=BRL, tipo_x="temporal"), 4),
         (grafico("bar", d_crev, "Quanto as revisões acrescentaram no período", ("tipo_revisao", "Tipo de revisão"), ("impacto", "Impacto"),
                  horizontal=True, fmt_y=BRL, descricao="Variação no valor do contrato a cada revisão, por tipo"), 2)]),
    (8, [(grafico("bar", d_cforn, "Top 15 fornecedores por valor medido no período", ("fornecedor", "Fornecedor"), ("valor", "Valor"),
                  cor=("classe", "Classe ABC"), horizontal=True, fmt_y=BRL), 3),
         (grafico("bar", d_ccc, "Valor medido por centro de custo no período", ("centro_custo", "Centro de custo"), ("valor", "Valor"),
                  horizontal=True, fmt_y=BRL), 3)]),
    (8, [(tabela(d_calert, "Contratos que pedem ação",
                 [("alerta", "Alerta"), ("filial", "Filial"), ("contrato", "Contrato"), ("fornecedor", "Fornecedor"),
                  ("dt_fim", "Fim"), ("dias_para_vencer", "Dias p/ vencer"), ("vl_original", "Valor original"),
                  ("vl_atual", "Valor atual"), ("saldo", "Saldo"), ("pct_consumido", "% consumido"),
                  ("pct_crescimento", "% crescimento")],
                 descricao="Vigentes com saldo quase esgotado, prazo vencido ou próximo, ou crescimento de 25% ou mais (situação de hoje)"), 6)]),
])

pagina("Revisões e medições", [
    (2, [(texto("""## Revisões e medições
**Revisados no período:** cada revisão concluída entre as datas escolhidas, com o tipo e o impacto no valor do contrato.
**Projetos:** valor medido por classe de valor (projeto) no período. A tabela final lista os contratos vigentes no período com o consumo de cada um."""), 6)]),
    _filtros_ctr(),
    (7, [(tabela(d_c30, "Contratos revisados no período",
                 [("filial", "Filial"), ("contrato", "Contrato"), ("revisao", "Revisão"), ("dt_revisao", "Data"),
                  ("tipo_revisao", "Tipo"), ("fornecedor", "Fornecedor"), ("vl_atual", "Valor após revisão"),
                  ("impacto", "Impacto")]), 4),
         (grafico("bar", d_cproj, "Valor medido por projeto no período", ("projeto", "Projeto"), ("valor", "Valor"),
                  horizontal=True, fmt_y=BRL), 2)]),
    (6, [(grafico("bar", d_cmes, "Contratos com medição no mês", ("mes", "Mês"), ("contratos", "Contratos"), tipo_x="temporal"), 3),
         (tabela(d_cforn, "Pareto de fornecedores no período", [("ranking", "#"), ("fornecedor", "Fornecedor"), ("valor", "Valor"),
                                                                ("contratos", "Contratos"), ("pct", "% do total"),
                                                                ("pct_acumulado", "% acumulado"), ("classe", "Classe")]), 3)]),
    (8, [(tabela(d_cvig, "Contratos vigentes no período",
                 [("filial", "Filial"), ("contrato", "Contrato"), ("revisao", "Revisão"), ("tipo_contrato", "Tipo"),
                  ("fornecedor", "Fornecedor"), ("dt_inicio", "Início"), ("dt_fim", "Fim"), ("vl_original", "Valor original"),
                  ("vl_atual", "Valor atual"), ("consumido", "Consumido"), ("saldo", "Saldo"), ("pct_consumido", "% consumido")]), 6)]),
])
salvar("Contratos")

# ================================================================= USUARIOS E LICENCAS
# Sem filial (usuario vale para o grupo todo). Periodo (padrao: ultimos 12 meses) so para o historico de acesso;
# ultimo acesso, faixa de inatividade e modulos liberados sao sempre a posicao de hoje.
_VUU, _VUA, _VUM = f"{G}.vw_usr_usuarios", f"{G}.vw_usr_acessos", f"{G}.vw_usr_modulos"
_hoje = date.today()
DOZE_MESES = (f"{_hoje.year - 1}-{_hoje.month:02d}-01", f"{_hoje.year}-12-31")
F_UA = "dia BETWEEN :data_inicio AND :data_fim"


def ds_usr(nome, titulo, sql, datas=True):
    return ds_livre(nome, titulo, sql, DOZE_MESES if datas else None)


d_ukpi = ds_usr("usr_kpi", "Usuários - KPIs", f"""
WITH h AS (SELECT dia, hora, count(DISTINCT usuario_id) AS n FROM {_VUA} WHERE {F_UA} GROUP BY 1, 2),
d AS (SELECT dia, count(DISTINCT usuario_id) AS n FROM {_VUA} WHERE {F_UA} GROUP BY 1)
SELECT count_if(NOT bloqueado) AS ativos,
       count_if(NOT bloqueado AND dias_sem_acesso <= 30) AS acessaram_30d,
       count_if(sem_acesso_30d) AS sem_acesso_30d,
       count_if(NOT bloqueado AND ultimo_acesso IS NULL) AS nunca_acessaram,
       count_if(bloqueado) AS bloqueados,
       (SELECT max(n) FROM h) AS pico_hora,
       (SELECT max(n) FROM d) AS pico_dia,
       (SELECT round(avg(n), 1) FROM d WHERE dayofweek(dia) BETWEEN 2 AND 6) AS media_dia_util,
       (SELECT count(DISTINCT usuario_id) FROM {_VUA} WHERE {F_UA}) AS usuarios_no_periodo
FROM {_VUU}""")
d_udia = ds_usr("usr_dia", "Usuários - acessos por dia", f"""
WITH h AS (SELECT dia, hora, count(DISTINCT usuario_id) AS n FROM {_VUA} WHERE {F_UA} GROUP BY 1, 2)
SELECT a.dia, count(DISTINCT a.usuario_id) AS usuarios, (SELECT max(n) FROM h WHERE h.dia = a.dia) AS pico_hora
FROM {_VUA} a WHERE {F_UA} GROUP BY a.dia ORDER BY a.dia""")
d_umes = ds_usr("usr_mes", "Usuários - acessos por mês", f"""
WITH d AS (SELECT mes, dia, count(DISTINCT usuario_id) AS n FROM {_VUA} WHERE {F_UA} GROUP BY 1, 2),
h AS (SELECT mes, dia, hora, count(DISTINCT usuario_id) AS n FROM {_VUA} WHERE {F_UA} GROUP BY 1, 2, 3)
SELECT m.mes, m.usuarios, d.media_dia_util, d.pico_dia, h.pico_hora
FROM (SELECT mes, count(DISTINCT usuario_id) AS usuarios FROM {_VUA} WHERE {F_UA} GROUP BY 1) m
LEFT JOIN (SELECT mes, round(avg(CASE WHEN dayofweek(dia) BETWEEN 2 AND 6 THEN n END), 1) AS media_dia_util,
                  max(n) AS pico_dia FROM d GROUP BY 1) d ON d.mes = m.mes
LEFT JOIN (SELECT mes, max(n) AS pico_hora FROM h GROUP BY 1) h ON h.mes = m.mes
ORDER BY m.mes""")
d_uhora = ds_usr("usr_hora", "Usuários - perfil por hora", f"""
WITH h AS (SELECT dia, hora, count(DISTINCT usuario_id) AS n FROM {_VUA}
           WHERE {F_UA} AND dayofweek(dia) BETWEEN 2 AND 6 GROUP BY 1, 2)
SELECT lpad(CAST(hora AS STRING), 2, '0') AS hora, round(avg(n), 1) AS media_usuarios, max(n) AS pico_usuarios
FROM h GROUP BY 1 ORDER BY 1""")
# uma linha por usuario: o grafico de faixas e a tabela usam o mesmo dataset (clicar na faixa filtra a tabela)
d_ulista = ds_usr("usr_lista", "Usuários - cadastro e uso", f"""
WITH p AS (SELECT usuario_id, count(DISTINCT dia) AS dias_acesso_periodo, sum(eventos) AS registros_periodo,
                  min(primeiro_registro) AS primeiro_acesso_periodo,
                  concat_ws(', ', array_sort(collect_set(modulo))) AS modulos_usados_periodo
           FROM {_VUA} WHERE {F_UA} GROUP BY 1)
SELECT u.usuario_id, u.login, u.nome, u.email, u.departamento, u.cargo, u.situacao, u.ultimo_acesso,
       u.dias_sem_acesso, u.faixa_ultimo_acesso, CASE WHEN u.sem_acesso_30d THEN 'Sim' ELSE 'Não' END AS sem_acesso_30d,
       u.modulos_liberados, u.qtd_modulos_liberados, nullif(p.modulos_usados_periodo, '') AS modulos_usados_periodo,
       coalesce(p.dias_acesso_periodo, 0) AS dias_acesso_periodo, coalesce(p.registros_periodo, 0) AS registros_periodo,
       p.primeiro_acesso_periodo, 1 AS usuarios
FROM {_VUU} u LEFT JOIN p ON p.usuario_id = u.usuario_id
ORDER BY u.bloqueado, u.ultimo_acesso NULLS FIRST""")
# uma linha por usuario x modulo liberado (usuarios ativos): clicar no modulo filtra a tabela de usuarios do modulo
d_umod = ds_usr("usr_modulo", "Usuários - módulos", f"""
WITH p AS (SELECT DISTINCT usuario_id, modulo FROM {_VUA} WHERE {F_UA} AND modulo IS NOT NULL)
SELECT m.modulo, u.nome, u.login, u.ultimo_acesso, u.dias_sem_acesso, u.faixa_ultimo_acesso,
       1 AS usuarios, CASE WHEN u.sem_acesso_30d THEN 1 ELSE 0 END AS usuarios_sem_acesso_30d,
       CASE WHEN p.usuario_id IS NOT NULL THEN 1 ELSE 0 END AS usou_no_periodo
FROM {_VUM} m JOIN {_VUU} u ON u.usuario_id = m.usuario_id AND NOT u.bloqueado
LEFT JOIN p ON p.usuario_id = m.usuario_id AND p.modulo = m.modulo
WHERE m.liberado""")
# historico mensal por usuario (para levar para a TOTVS)
d_uhist = ds_usr("usr_hist", "Usuários - histórico mensal", f"""
SELECT mes, nome, login, count(DISTINCT dia) AS dias_com_acesso, count(DISTINCT dia, hora) AS horas_com_acesso,
       sum(eventos) AS registros, min(primeiro_registro) AS primeiro_acesso, max(ultimo_registro) AS ultimo_acesso,
       concat_ws(', ', array_sort(collect_set(modulo))) AS modulos_usados
FROM {_VUA} WHERE {F_UA} GROUP BY mes, nome, login ORDER BY mes DESC, dias_com_acesso DESC""")

pagina("Usuários e licenças", [
    (2, [(texto("""## Usuários do sistema e licenças
**Último acesso** = último registro do usuário na auditoria (TOTVS_AUDIT), em todo o histórico. **Sem acesso há 30+ dias** = ativos (não bloqueados) que não acessam há mais de 30 dias ou nunca acessaram: candidatos a bloquear e liberar a licença.
**Pico na mesma hora** = máximo de usuários distintos com registro na mesma hora; é a melhor aproximação do uso simultâneo que a auditoria permite (o número exato de conexões fica no License Server).
**Período:** vale só para o histórico (dias, meses, perfil por hora e módulos usados). Clique numa faixa ou num módulo para filtrar a tabela ao lado."""), 6)]),
    (2, [(filtro_data("data_inicio", "Acesso de"), 1), (filtro_data("data_fim", "Acesso até"), 1),
         (filtro_campo("nome", "Usuário", [d_ulista, d_uhist]), 2),
         (filtro_campo("situacao", "Situação", [d_ulista]), 2)]),
    (3, [(contador(d_ukpi, "ativos", "Usuários ativos", NUM), 1),
         (contador(d_ukpi, "acessaram_30d", "Acessaram nos últimos 30 dias", NUM), 1),
         (contador(d_ukpi, "sem_acesso_30d", "Ativos sem acesso há 30+ dias", NUM), 1),
         (contador(d_ukpi, "nunca_acessaram", "Ativos que nunca acessaram", NUM), 1),
         (contador(d_ukpi, "pico_hora", "Pico na mesma hora (período)", NUM), 1),
         (contador(d_ukpi, "media_dia_util", "Média de usuários por dia útil", NUM), 1)]),
    (8, [(grafico_soma("bar", d_ulista, "Usuários por tempo desde o último acesso", ("faixa_ultimo_acesso", "Último acesso"),
                       ("usuarios", "Usuários"), descricao="Clique numa faixa para ver os usuários na tabela abaixo"), 2),
         (grafico("line", d_udia, "Usuários por dia", ("dia", "Dia"),
                  [("usuarios", "Usuários distintos no dia"), ("pico_hora", "Pico na mesma hora")], tipo_x="temporal"), 4)]),
    (10, [(tabela(d_ulista, "Usuários: último acesso, módulos e uso no período",
                  [("nome", "Nome"), ("login", "Usuário"), ("usuario_id", "Código"), ("situacao", "Situação"),
                   ("ultimo_acesso", "Último acesso"), ("dias_sem_acesso", "Dias sem acesso"),
                   ("faixa_ultimo_acesso", "Faixa"), ("sem_acesso_30d", "Sem acesso 30+ dias"),
                   ("dias_acesso_periodo", "Dias com acesso no período"), ("modulos_liberados", "Módulos liberados"),
                   ("qtd_modulos_liberados", "Qtd módulos"), ("modulos_usados_periodo", "Módulos usados no período"),
                   ("email", "E-mail"), ("departamento", "Departamento"), ("cargo", "Cargo")]), 6)]),
    (7, [(grafico("bar", d_umes, "Usuários por mês", ("mes", "Mês"),
                  [("usuarios", "Usuários distintos"), ("pico_dia", "Pico em um dia"), ("pico_hora", "Pico na mesma hora")],
                  tipo_x="temporal"), 3),
         (grafico("bar", d_uhora, "Usuários por hora do dia (dias úteis)", ("hora", "Hora"),
                  [("media_usuarios", "Média"), ("pico_usuarios", "Pico")]), 3)]),
    (9, [(grafico_soma("bar", d_umod, "Usuários ativos por módulo liberado", ("modulo", "Módulo"), ("usuarios", "Usuários"),
                       horizontal=True, extra=[("usuarios_sem_acesso_30d", "Sem acesso há 30+ dias", None),
                                               ("usou_no_periodo", "Usaram o módulo no período", None)],
                       descricao="Clique num módulo para ver quem tem acesso a ele"), 3),
         (tabela(d_umod, "Usuários por módulo", [("modulo", "Módulo"), ("nome", "Nome"), ("login", "Usuário"),
                                                 ("ultimo_acesso", "Último acesso"), ("dias_sem_acesso", "Dias sem acesso"),
                                                 ("faixa_ultimo_acesso", "Faixa")]), 3)]),
    (9, [(tabela(d_uhist, "Histórico mensal de acesso por usuário",
                 [("mes", "Mês"), ("nome", "Nome"), ("login", "Usuário"), ("dias_com_acesso", "Dias com acesso"),
                  ("horas_com_acesso", "Horas com acesso"), ("registros", "Registros de auditoria"),
                  ("primeiro_acesso", "Primeiro acesso"), ("ultimo_acesso", "Último acesso"),
                  ("modulos_usados", "Módulos usados")],
                 descricao="Base para conferir com a TOTVS: dias e horas em que cada usuário teve registro no sistema"), 6)]),
])
salvar("Usuarios")

# ================================================================= DIRETORIA (acesso restrito)
# Filtros: filial + mes entre :data_inicio e :data_fim (padrao: ano corrente).
_ano = date.today().year
PERIODO = (f"{_ano}-01-01", f"{_ano}-12-31")
F_DIR = "(:filial = 'Todas' OR filial = :filial) AND mes BETWEEN date_trunc('MONTH', :data_inicio) AND :data_fim"
_M = f"{DIR}.vw_dir_mapa"
_LINHAS = [("receita", "Receita"), ("frota", "Frota"), ("pessoal", "Pessoal"), ("administrativo", "Administrativo"),
           ("judicial", "Processos judiciais"), ("demais", "Demais custos da operação")]
_SOMAS = ", ".join(f"coalesce(sum(CASE WHEN linha = '{l}' THEN valor END), 0) AS {c}" for c, l in _LINHAS)
_RES = """, frota + pessoal + administrativo + judicial + demais AS custo_total,
       receita - (frota + pessoal + administrativo + judicial + demais) AS saldo,
       try_divide(receita - (frota + pessoal + administrativo + judicial + demais), receita) AS margem"""

d_dkpi = ds_sql("dir_kpi", "Diretoria - totais", f"SELECT *{_RES} FROM (SELECT {_SOMAS} FROM {_M} WHERE {F_DIR})",
                [_M], datas=PERIODO)
d_dmapa = ds_sql("dir_mapa", "Diretoria - mapa", f"""
WITH l AS (SELECT linha, ordem, sum(valor) AS valor FROM {_M} WHERE {F_DIR} GROUP BY linha, ordem),
s AS (SELECT 'Saldo' AS linha, 9 AS ordem,
             sum(CASE WHEN linha = 'Receita' THEN valor ELSE -valor END) AS valor FROM l)
SELECT concat(ordem, '. ', linha) AS linha,
       CASE WHEN linha = 'Receita' THEN 'Entrou' WHEN linha = 'Saldo' THEN 'Saldo' ELSE 'Saiu' END AS tipo,
       CASE WHEN linha IN ('Receita', 'Saldo') THEN valor ELSE -valor END AS valor,
       abs(valor) AS valor_abs,
       try_divide(valor, (SELECT sum(valor) FROM l WHERE linha = 'Receita')) AS pct_receita
FROM (SELECT * FROM l UNION ALL SELECT * FROM s)
ORDER BY ordem""", [_M], datas=PERIODO)
d_dmes = ds_sql("dir_mes", "Diretoria - mês a mês", f"""
SELECT *{_RES} FROM (SELECT mes, {_SOMAS} FROM {_M} WHERE {F_DIR} GROUP BY mes)
ORDER BY mes""", [_M], datas=PERIODO)
d_dmesc = ds_sql("dir_mes_custo", "Diretoria - custos por mês", f"""
SELECT mes, linha, sum(valor) AS valor FROM {_M} WHERE {F_DIR} AND linha <> 'Receita'
GROUP BY mes, linha ORDER BY mes""", [_M], datas=PERIODO)
d_dnat = ds_sql("dir_nat", "Diretoria - maiores naturezas", f"""
SELECT linha, grupo, natureza, natureza_desc, sum(valor) AS valor, count(*) AS pagamentos
FROM {DIR}.vw_dir_pagamentos WHERE {F_DIR} AND linha <> 'Fora do saldo'
GROUP BY linha, grupo, natureza, natureza_desc ORDER BY valor DESC LIMIT 100""",
                [f"{DIR}.vw_dir_pagamentos"], datas=PERIODO)
d_dfora = ds_sql("dir_fora", "Diretoria - fora do saldo", f"""
SELECT motivo_fora AS motivo, sum(valor) AS valor, count(*) AS pagamentos
FROM {DIR}.vw_dir_pagamentos WHERE {F_DIR} AND linha = 'Fora do saldo'
GROUP BY motivo_fora ORDER BY valor DESC""", [f"{DIR}.vw_dir_pagamentos"], datas=PERIODO)

pagina("Mapa de resultado", [
    (2, [(texto("""## Mapa de resultado — o que entrou, o que saiu e o saldo
**Entrou:** faturamento (notas de saída com duplicata) menos devoluções, pelo mês de emissão. **Saiu:** pagamentos feitos no mês, separados pela natureza financeira.
Empréstimos, financiamentos, compra de bens, parcelamentos e baixas sem saída de caixa **não entram no saldo** (ver conferência no fim). **Margem** = saldo ÷ receita."""), 3),
         (filtro(), 1), (filtro_data("data_inicio", "Mês de"), 1), (filtro_data("data_fim", "Mês até"), 1)]),
    (3, [(contador(d_dkpi, "receita", "Receita (entrou)", BRL), 2),
         (contador(d_dkpi, "custo_total", "Custos (saiu)", BRL), 2),
         (contador(d_dkpi, "saldo", "Saldo", BRL), 1),
         (contador(d_dkpi, "margem", "Margem", PCT), 1)]),
    (3, [(contador(d_dkpi, "frota", "Custo de frota", BRL), 1),
         (contador(d_dkpi, "pessoal", "Custo com pessoal", BRL), 1),
         (contador(d_dkpi, "administrativo", "Custo administrativo", BRL), 1),
         (contador(d_dkpi, "judicial", "Processos judiciais", BRL), 1),
         (contador(d_dkpi, "demais", "Demais custos da operação", BRL), 2)]),
    (8, [(grafico("bar", d_dmapa, "Mapa: receita, custos e saldo", ("linha", "Linha"), ("valor", "Valor"),
                  cor=("tipo", "Tipo"), fmt_y=BRL,
                  descricao="Receita positiva, custos negativos; o Saldo é a soma das barras"), 4),
         (tabela(d_dmapa, "Mapa do período", [("linha", "Linha"), ("valor_abs", "Valor"), ("pct_receita", "% da receita")]), 2)]),
    (7, [(grafico("line", d_dmes, "Receita, custos e saldo por mês", ("mes", "Mês"),
                  [("receita", "Receita"), ("custo_total", "Custos"), ("saldo", "Saldo")], fmt_y=BRL, tipo_x="temporal"), 3),
         (grafico("bar", d_dmesc, "Composição dos custos por mês", ("mes", "Mês"), ("valor", "Valor"),
                  cor=("linha", "Linha"), fmt_y=BRL, tipo_x="temporal"), 3)]),
    (7, [(tabela(d_dmes, "Mapa mês a mês",
                 [("mes", "Mês"), ("receita", "Receita"), ("frota", "Frota"), ("pessoal", "Pessoal"),
                  ("administrativo", "Administrativo"), ("judicial", "Proc. judiciais"),
                  ("demais", "Demais custos"), ("custo_total", "Custos"), ("saldo", "Saldo"), ("margem", "Margem")]), 6)]),
    (8, [(tabela(d_dnat, "Maiores custos por natureza",
                 [("linha", "Linha"), ("grupo", "Grupo"), ("natureza", "Natureza"), ("natureza_desc", "Descrição"),
                  ("valor", "Valor"), ("pagamentos", "Pagamentos")]), 4),
         (tabela(d_dfora, "Conferência: pagamentos fora do saldo", [("motivo", "Motivo"), ("valor", "Valor"),
                                                                    ("pagamentos", "Pagamentos")],
                 descricao="Saídas do período que não são custo da operação"), 2)]),
])
salvar("Diretoria")

print("\n".join(gerados))
