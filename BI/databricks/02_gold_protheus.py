# Databricks notebook source
# MAGIC %md
# MAGIC # Gold - visoes analiticas para o dashboard
# MAGIC Cria as views em `<catalogo>.gold` a partir das tabelas bronze carregadas pelo notebook `01_bronze_protheus`.
# MAGIC As views sao recalculadas a cada consulta: depois de recarregar a bronze, o dashboard ja mostra os dados novos.
# MAGIC
# MAGIC **Filial:** toda view tem a coluna `filial` ("codigo - nome"). As agregadas trazem uma linha por filial e outra com
# MAGIC `filial = 'Todas'`; o dashboard filtra `filial = :filial` (padrao `Todas`). As de detalhe trazem so a filial da linha.
# MAGIC
# MAGIC **Centro de custo:** as views de detalhe de financeiro, compras, frota, pessoas e contratos tem a coluna `centro_custo`
# MAGIC (descricao do CTT, ou o codigo); os dashboards dessas areas filtram por ela e pelo periodo direto nas views de detalhe.
# MAGIC
# MAGIC | Area | Analises |
# MAGIC |---|---|
# MAGIC | Financeiro | aging, fluxo de vencimentos, Pareto/HHI de fornecedores, pagamentos com media movel, prazo e pontualidade |
# MAGIC | Compras | fila de aprovacao (so aprovadores da SAL, dentro da alcada) por aprovador, nivel e idade, lead time SC -> pedido (mediana e P90), status das SCs |
# MAGIC | Frota | custo por bem (pecas, pneus, terceiros e combustivel) com detalhamento, custo por dia e por km, OS por mes e tipo, OS com custo atipico (z-score) |
# MAGIC | Estoque | curva ABC, estoque parado, saldo negativo, evolucao dos fechamentos, ajustes |
# MAGIC | Pessoas | headcount, turnover, folha por mes, atestados e acidentes (agregados, sem nomes) |
# MAGIC | Contratos | so contratos de compra: valor contratado x consumido, crescimento por revisoes, revisados em 30 dias, medicoes por mes/CC/fornecedor/projeto, alertas |
# MAGIC | Usuarios | ultimo acesso, faixa de inatividade, modulos liberados e usados, historico de acesso por dia/hora (licencas) |
# MAGIC | Diretoria (schema `diretoria`) | mapa de resultado: receita, custo de frota, administrativo, pessoal, processos judiciais, demais custos e saldo |

# COMMAND ----------

CATALOGO = "quebec"
B = f"{CATALOGO}.bronze"
G = f"{CATALOGO}.gold"
spark.sql(f"CREATE SCHEMA IF NOT EXISTS {G}")

def DT(c):
    """Data do Protheus (texto AAAAMMDD) -> DATE. Vazio ou invalido vira NULL."""
    return f"to_date(try_to_timestamp(nullif(trim({c}), ''), 'yyyyMMdd'))"

def YM(c):
    """Competencia (texto AAAAMM) -> DATE no dia 1."""
    return f"to_date(try_to_timestamp(nullif(trim({c}), ''), 'yyyyMM'))"

def FIL(c):
    """Codigo de filial -> rotulo 'codigo - nome' (coluna `filial` de todas as views)."""
    # as colunas de vw_filiais tem prefixo fil_ para nao colidir com a coluna FILIAL da tabela de origem
    return f"coalesce((SELECT max(f.fil_rotulo) FROM {G}.vw_filiais f WHERE f.fil_cod = trim({c})), trim({c}))"

def TODAS(src):
    """Duplica cada linha de src: uma na propria filial e outra em 'Todas'.
    As views agregadas agrupam/particionam por `filial`, entao o dashboard filtra
    `filial = :filial` e os percentis, rankings e percentuais saem certos em cada filial."""
    return f"""(SELECT b.* EXCEPT (filial), x.filial_x AS filial
  FROM {src} b LATERAL VIEW explode(array(b.filial, 'Todas')) x AS filial_x)"""

def CC(cod, desc=None):
    """Centro de custo -> rotulo da coluna `centro_custo`: descricao (CTT) ou, sem ela, o codigo.
    Mesmo padrao de vw_ctr_medicoes, para o filtro de centro de custo ser igual em todos os dashboards."""
    d = f"nullif(trim({desc}), ''), " if desc else ""
    return (f"coalesce({d}(SELECT max(cc.cc_desc) FROM {G}.vw_centros_custo cc WHERE cc.cc_cod = trim({cod})), "
            f"nullif(trim({cod}), ''), 'Sem centro de custo')")

def COL(tabela, coluna, sem="CAST(NULL AS STRING)"):
    """A coluna, se ela ja existe na bronze; senao `sem`. Evita quebrar a view enquanto a API nova
    (ex.: CC nos titulos) nao foi compilada e a bronze recarregada."""
    try:
        existe = coluna.upper() in (c.upper() for c in spark.table(f"{B}.{tabela}").columns)
    except Exception:
        existe = False
    return coluna if existe else sem

VIEWS = {}
def view(nome, sql):
    VIEWS[nome] = sql

# COMMAND ----------

# MAGIC %md
# MAGIC ## Filiais
# MAGIC Codigos encontrados nos dados + nome do cadastro de empresas (endpoint `/bi/geral/filiais`).
# MAGIC Sem o cadastro, o rotulo fica so com o codigo.

# COMMAND ----------

_tem_nomes = spark.catalog.tableExists(f"{B}.geral_filiais")
_nomes = (f"SELECT trim(FILIAL) AS cod, max(nullif(trim(NOME), '')) AS nome FROM {B}.geral_filiais GROUP BY 1"
          if _tem_nomes else "SELECT CAST(NULL AS STRING) AS cod, CAST(NULL AS STRING) AS nome WHERE false")
view("vw_filiais", f"""
WITH n AS ({_nomes}),
c AS (
  SELECT trim(FILIAL) AS cod FROM {B}.fin_titulos_abertos UNION
  SELECT trim(FILIAL) FROM {B}.apr_pendencias UNION
  SELECT trim(FILIAL) FROM {B}.com_solicitacoes UNION
  SELECT trim(FILIAL) FROM {B}.est_saldos UNION
  SELECT trim(FIL)    FROM {B}.mnt_ordens UNION
  SELECT trim(FILIAL) FROM {B}.fol_quadro UNION
  SELECT trim(FILIAL) FROM {B}.ctr_contratos
  UNION SELECT cod FROM n
)
SELECT c.cod AS fil_cod, n.nome AS fil_nome,
       CASE WHEN n.nome IS NULL THEN c.cod ELSE concat(c.cod, ' - ', n.nome) END AS fil_rotulo
FROM c LEFT JOIN n ON n.cod = c.cod
WHERE c.cod IS NOT NULL AND c.cod <> ''
""")

# Cadastro de centros de custo (CTT, endpoint /bi/financeiro/centros-custo): codigo -> descricao. Usado por CC().
_tem_cc = spark.catalog.tableExists(f"{B}.fin_centros_custo")
view("vw_centros_custo", f"""
SELECT trim(CC) AS cc_cod, max(nullif(trim(DESCR), '')) AS cc_desc FROM {B}.fin_centros_custo GROUP BY 1
""" if _tem_cc else "SELECT CAST(NULL AS STRING) AS cc_cod, CAST(NULL AS STRING) AS cc_desc WHERE false")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Financeiro

# COMMAND ----------

# centro_custo: CC principal do titulo (o de maior valor no rateio, calculado na API).
view("vw_fin_titulos", f"""
SELECT {FIL('FILIAL')} AS filial, {CC(COL('fin_titulos_abertos', 'CC'), COL('fin_titulos_abertos', 'CC_DESC'))} AS centro_custo,
       PREFIXO, NUM, PARCELA, TIPO, FORNECEDOR, NATUREZA_DESC AS natureza,
       VALOR AS valor, SALDO AS saldo,
       {DT('EMISSAO')} AS dt_emissao,
       {DT('VENCREA')} AS dt_vencimento,
       datediff(current_date(), {DT('VENCREA')}) AS dias_atraso,
       CASE WHEN TIPO = 'PR' THEN 'Provisorio (PR)' ELSE 'Efetivo' END AS grupo,
       CASE
         WHEN {DT('VENCREA')} IS NULL                                   THEN '0. Sem vencimento'
         WHEN datediff(current_date(), {DT('VENCREA')}) < -30           THEN '1. A vencer > 30 dias'
         WHEN datediff(current_date(), {DT('VENCREA')}) <= 0            THEN '2. A vencer 0-30 dias'
         WHEN datediff(current_date(), {DT('VENCREA')}) <= 30           THEN '3. Vencido 1-30 dias'
         WHEN datediff(current_date(), {DT('VENCREA')}) <= 90           THEN '4. Vencido 31-90 dias'
         WHEN datediff(current_date(), {DT('VENCREA')}) <= 180          THEN '5. Vencido 91-180 dias'
         ELSE '6. Vencido > 180 dias'
       END AS faixa
FROM {B}.fin_titulos_abertos
""")

view("vw_fin_kpi", f"""
WITH t AS (SELECT * FROM {TODAS(f'{G}.vw_fin_titulos')}),
     f AS (SELECT filial, FORNECEDOR, sum(saldo) AS s FROM t WHERE grupo = 'Efetivo' GROUP BY filial, FORNECEDOR),
     -- Indice Herfindahl-Hirschman (0-10000): > 1500 = concentracao moderada, > 2500 = alta
     h AS (SELECT filial, round(sum(power(try_divide(s, tot), 2)) * 10000, 0) AS hhi_fornecedores
           FROM (SELECT *, sum(s) OVER (PARTITION BY filial) AS tot FROM f) GROUP BY filial)
SELECT t.filial,
  sum(saldo)                                                         AS saldo_total,
  sum(CASE WHEN grupo = 'Efetivo' THEN saldo END)                    AS saldo_efetivo,
  sum(CASE WHEN grupo = 'Efetivo' AND dias_atraso > 0 THEN saldo END) AS saldo_vencido,
  try_divide(sum(CASE WHEN grupo = 'Efetivo' AND dias_atraso > 0 THEN saldo END),
             sum(CASE WHEN grupo = 'Efetivo' THEN saldo END))        AS pct_vencido,
  sum(CASE WHEN grupo = 'Provisorio (PR)' THEN saldo END)            AS saldo_provisorio,
  count(*)                                                           AS qtd_titulos,
  max(h.hhi_fornecedores)                                            AS hhi_fornecedores
FROM t LEFT JOIN h ON h.filial = t.filial
GROUP BY t.filial
""")

view("vw_fin_aging", f"""
SELECT filial, faixa, grupo, sum(saldo) AS saldo, count(*) AS qtd_titulos
FROM {TODAS(f'{G}.vw_fin_titulos')}
GROUP BY filial, faixa, grupo
""")

view("vw_fin_fluxo_semanal", f"""
SELECT filial, date_trunc('WEEK', dt_vencimento) AS semana, grupo, sum(saldo) AS saldo
FROM {TODAS(f'{G}.vw_fin_titulos')}
WHERE dt_vencimento BETWEEN current_date() AND date_add(current_date(), 84)
GROUP BY 1, 2, 3
""")

view("vw_fin_pareto_fornecedor", f"""
WITH f AS (
  SELECT filial, FORNECEDOR AS fornecedor, sum(saldo) AS saldo, count(*) AS titulos
  FROM {TODAS(f'{G}.vw_fin_titulos')} WHERE grupo = 'Efetivo' GROUP BY filial, FORNECEDOR
), r AS (
  SELECT *, row_number() OVER (PARTITION BY filial ORDER BY saldo DESC) AS ranking,
         try_divide(saldo, sum(saldo) OVER (PARTITION BY filial)) AS pct,
         try_divide(sum(saldo) OVER (PARTITION BY filial ORDER BY saldo DESC ROWS UNBOUNDED PRECEDING),
                    sum(saldo) OVER (PARTITION BY filial)) AS pct_acumulado
  FROM f
)
SELECT filial, ranking, fornecedor, saldo, titulos, pct, pct_acumulado,
       CASE WHEN pct_acumulado <= 0.8 THEN 'A' WHEN pct_acumulado <= 0.95 THEN 'B' ELSE 'C' END AS classe
FROM r WHERE ranking <= 30
""")

view("vw_fin_pagamentos", f"""
SELECT {FIL('FILIAL')} AS filial, {CC(COL('fin_pagamentos', 'CC'), COL('fin_pagamentos', 'CC_DESC'))} AS centro_custo,
       REC, PAGO, JUROS, MULTA, FORNECEDOR AS fornecedor,
       {DT('PAGO_EM')} AS dt_pagamento, date_trunc('MONTH', {DT('PAGO_EM')}) AS mes,
       datediff({DT('PAGO_EM')}, {DT('EMISSAO')}) AS prazo_dias,
       CASE WHEN {DT('PAGO_EM')} > {DT('VENCREA')} THEN PAGO ELSE 0 END AS pago_atraso
FROM {B}.fin_pagamentos
""")

view("vw_fin_pagamentos_mes", f"""
WITH m AS (
  SELECT filial, mes, sum(PAGO) AS valor_pago, count(DISTINCT REC) AS titulos,
         percentile_approx(prazo_dias, 0.5) AS prazo_mediano_dias,
         try_divide(sum(pago_atraso), sum(PAGO)) AS pct_pago_em_atraso,
         sum(JUROS + MULTA) AS juros_multa
  FROM {TODAS(f'{G}.vw_fin_pagamentos')} WHERE mes IS NOT NULL GROUP BY filial, mes
)
SELECT *, avg(valor_pago) OVER (PARTITION BY filial ORDER BY mes ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS media_movel_3m
FROM m
""")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Compras e aprovacao

# COMMAND ----------

# Regras da fila de aprovacao (campos trazidos pela API do cadastro de alcadas do Protheus):
#   - so aprovador de fato: a pessoa precisa estar no grupo de aprovacao (SAL) do pedido, no mesmo nivel,
#     como Aprovador (AL_LIBAPR = 'A'). Vistador (AL_LIBAPR = 'V') so acompanha e fica fora da fila;
#   - so dentro da alcada: quando o grupo considera os limites (AL_AUTOLIM = 'S', o padrao do Protheus), o valor
#     do pedido precisa estar entre o limite minimo e o maximo do perfil (DHL) ou, sem perfil, do aprovador (SAK).
#     Fora da faixa o Protheus nao exige a aprovacao dele. Limite maximo zerado = sem teto.
#     Com AL_AUTOLIM = 'N' o aprovador aprova qualquer valor e a pendencia entra na fila;
#   - so o nivel atual: o pedido so esta pendente para o aprovador quando ja chegou no nivel dele. Nivel atual =
#     menor nivel do grupo que ainda tem aprovador valido pendente; os niveis acima ficam desconsiderados.
# dt_emissao_pedido (C7_EMISSAO) alimenta o filtro de data inicio/fim do dashboard.
# O que nao passa nas regras fica em vw_apr_desconsideradas, para conferencia.
view("vw_apr_pendencias", f"""
WITH p AS (
  SELECT {FIL('FILIAL')} AS filial, trim(FILIAL) AS cod_filial, trim(PEDIDO) AS PEDIDO, trim(GRUPO) AS GRUPO, GRUPO_DESC, trim(NIVEL) AS nivel,
         CAST(TOTAL AS DOUBLE) AS valor,
         {DT('EMISSAO')} AS dt_entrada_alcada,
         coalesce({DT('EMISSAO_PEDIDO')}, {DT('EMISSAO')}) AS dt_emissao_pedido,
         datediff(current_date(), {DT('EMISSAO')}) AS idade_dias,
         APROVADOR_NOME AS aprovador,
         CASE upper(trim(TIPO_APROVADOR)) WHEN 'A' THEN 'Aprovador' WHEN 'V' THEN 'Vistador'
              ELSE 'Fora do grupo' END AS tipo_aprovador,
         CASE upper(trim(TIPO_LIBERACAO)) WHEN 'N' THEN 'Por nível' WHEN 'U' THEN 'Por usuário'
              WHEN 'P' THEN 'Por pedido' ELSE 'Não informado' END AS papel,
         try_cast(LIMITE_MIN AS DOUBLE) AS limite_min,
         nullif(try_cast(LIMITE_MAX AS DOUBLE), 0) AS limite_max,
         upper(coalesce(nullif(trim(CONSIDERA_LIMITE), ''), 'S')) <> 'N' AS considera_limite
  FROM {B}.apr_pendencias
), v AS (
SELECT *,
       valor >= coalesce(limite_min, 0) AND (limite_max IS NULL OR valor <= limite_max) AS dentro_alcada,
       CASE WHEN tipo_aprovador = 'Vistador'      THEN 'Desconsiderada: vistador (só visualiza)'
            WHEN tipo_aprovador = 'Fora do grupo' THEN 'Desconsiderada: não está no grupo de aprovação (SAL)'
            WHEN considera_limite AND valor < coalesce(limite_min, 0) THEN 'Desconsiderada: abaixo do limite mínimo da alçada'
            WHEN considera_limite AND valor > limite_max              THEN 'Desconsiderada: acima do limite máximo da alçada'
            ELSE 'Pendente' END AS situacao_alcada
FROM p
), n AS (
-- nivel atual = menor nivel ainda pendente (com aprovador valido) do pedido no grupo
SELECT *, min(CASE WHEN situacao_alcada = 'Pendente' THEN nivel END)
            OVER (PARTITION BY cod_filial, PEDIDO, GRUPO) AS nivel_atual
FROM v
)
SELECT * EXCEPT (situacao_alcada),
       CASE WHEN situacao_alcada = 'Pendente' AND nivel > nivel_atual
            THEN concat('Desconsiderada: pedido ainda no nível ', nivel_atual, ' (não chegou neste nível)')
            ELSE situacao_alcada END AS situacao
FROM n
""")

# So as pendencias validas (aprovador de fato, valor dentro da alcada). Base de todos os indicadores da fila.
view("vw_apr_fila", f"""
SELECT * FROM {G}.vw_apr_pendencias WHERE situacao = 'Pendente'
""")

view("vw_apr_desconsideradas", f"""
SELECT filial, cod_filial, PEDIDO AS pedido, GRUPO_DESC AS grupo, concat('Nível ', nivel) AS nivel, aprovador,
       situacao, valor, limite_min, limite_max, considera_limite, dt_emissao_pedido, idade_dias
FROM {G}.vw_apr_pendencias WHERE situacao <> 'Pendente'
""")

# Centros de custo de cada pedido pendente (itens da SC7). Um pedido pode ter itens em mais de um CC:
# no filtro de CC o pedido entra quando tem algum item naquele CC (chave = 'filial|pedido').
view("vw_apr_pedido_cc", f"""
SELECT DISTINCT * FROM (
  SELECT concat(trim(FILIAL), '|', trim(PEDIDO)) AS chave, {FIL('FILIAL')} AS filial,
         {CC('CC', 'CC_DESC')} AS centro_custo
  FROM {B}.apr_itens)
""")

view("vw_apr_pedidos", f"""
SELECT filial, cod_filial, PEDIDO, max(valor) AS valor, min(dt_entrada_alcada) AS dt_entrada_alcada,
       min(dt_emissao_pedido) AS dt_emissao_pedido,
       datediff(current_date(), min(dt_entrada_alcada)) AS idade_dias,
       count(DISTINCT aprovador) AS aprovadores
FROM {G}.vw_apr_fila
GROUP BY filial, cod_filial, PEDIDO
""")

view("vw_apr_kpi", f"""
WITH k AS (
  SELECT filial, count(*) AS pedidos_pendentes, sum(valor) AS valor_pendente,
         percentile_approx(idade_dias, 0.5) AS idade_mediana_dias,
         sum(CASE WHEN idade_dias > 7 THEN 1 ELSE 0 END) AS pendentes_mais_7_dias
  FROM {TODAS(f'{G}.vw_apr_pedidos')} GROUP BY filial
), d AS (
  SELECT filial, count(*) AS linhas_desconsideradas
  FROM {TODAS(f'{G}.vw_apr_desconsideradas')} GROUP BY filial
)
SELECT coalesce(k.filial, d.filial) AS filial,
       coalesce(pedidos_pendentes, 0) AS pedidos_pendentes, coalesce(valor_pendente, 0) AS valor_pendente,
       idade_mediana_dias, coalesce(pendentes_mais_7_dias, 0) AS pendentes_mais_7_dias,
       coalesce(linhas_desconsideradas, 0) AS linhas_desconsideradas
FROM k FULL OUTER JOIN d ON d.filial = k.filial
""")

view("vw_apr_fila_aprovador", f"""
SELECT filial, aprovador, concat_ws(', ', array_sort(collect_set(papel))) AS papel,
       concat_ws(', ', array_sort(collect_set(nivel))) AS niveis,
       count(DISTINCT cod_filial, PEDIDO) AS pedidos, sum(valor) AS valor,
       round(avg(idade_dias), 1) AS idade_media_dias,
       max(idade_dias) AS idade_max_dias
FROM {TODAS(f'{G}.vw_apr_fila')}
GROUP BY filial, aprovador
""")

# Em que nivel da alcada o valor esta parado, por aprovador.
view("vw_apr_fila_nivel", f"""
SELECT filial, aprovador, concat('Nível ', nivel) AS nivel, count(DISTINCT cod_filial, PEDIDO) AS pedidos, sum(valor) AS valor,
       round(avg(idade_dias), 1) AS idade_media_dias, max(idade_dias) AS idade_max_dias
FROM {TODAS(f'{G}.vw_apr_fila')}
GROUP BY filial, aprovador, nivel
""")

# Pedidos parados na alcada, um por linha (aprovador x nivel).
view("vw_apr_pedidos_alcada", f"""
SELECT filial, cod_filial, PEDIDO AS pedido, GRUPO_DESC AS grupo, concat('Nível ', nivel) AS nivel,
       aprovador, papel, valor, limite_min, limite_max, dt_emissao_pedido, dt_entrada_alcada, idade_dias
FROM {G}.vw_apr_fila
""")

view("vw_apr_idade", f"""
SELECT filial,
       CASE WHEN idade_dias <= 2 THEN '1. 0-2 dias' WHEN idade_dias <= 7 THEN '2. 3-7 dias'
            WHEN idade_dias <= 15 THEN '3. 8-15 dias' WHEN idade_dias <= 30 THEN '4. 16-30 dias'
            ELSE '5. > 30 dias' END AS faixa_idade,
       count(*) AS pedidos, sum(valor) AS valor
FROM {TODAS(f'{G}.vw_apr_pedidos')} GROUP BY 1, 2
""")

# Detalhe (uma linha por item) com centro de custo e data, para os filtros de periodo/CC do dashboard.
view("vw_com_sc", f"""
SELECT {FIL('FILIAL')} AS filial, {CC('CC', 'CC_DESC')} AS centro_custo, NUM AS sc, ITEM AS item,
       {DT('EMISSAO')} AS dt_emissao, date_trunc('MONTH', {DT('EMISSAO')}) AS mes,
       CASE APROV WHEN 'L' THEN 'Liberada' WHEN 'B' THEN 'Bloqueada' WHEN 'R' THEN 'Rejeitada' ELSE 'Outros' END AS status
FROM {B}.com_solicitacoes
""")

# Lead time SC -> pedido por item; CC e data do pedido (C7_EMISSAO).
view("vw_com_leadtime", f"""
SELECT {FIL('p.FILIAL')} AS filial, {CC('p.CC', 'p.CC_DESC')} AS centro_custo,
       {DT('p.EMISSAO')} AS dt_pedido, date_trunc('MONTH', {DT('p.EMISSAO')}) AS mes,
       datediff({DT('p.EMISSAO')}, {DT('s.EMISSAO')}) AS dias
FROM {B}.ped_solicitacoes s
JOIN {B}.ped_itens p ON p.FILIAL = s.FILIAL AND p.NUM = s.NUM AND p.ITEM = s.ITEM AND p.DEL = ''
WHERE datediff({DT('p.EMISSAO')}, {DT('s.EMISSAO')}) >= 0
""")

# Notas de entrada (uma linha por documento); CC = maior D1_CC do documento (vem da API).
view("vw_com_notas", f"""
SELECT {FIL('FIL')} AS filial, {CC('CC', 'CC_DESC')} AS centro_custo,
       {DT('DIG')} AS dt_digitacao, date_trunc('MONTH', {DT('DIG')}) AS mes, V AS valor, PED = '' AS sem_pedido
FROM {B}.com_notas_entrada WHERE {DT('DIG')} IS NOT NULL
""")

view("vw_com_sc_mes", f"""
SELECT filial, mes, status, count(*) AS itens
FROM {TODAS(f'''(SELECT {FIL('FILIAL')} AS filial, date_trunc('MONTH', {DT('EMISSAO')}) AS mes,
       CASE APROV WHEN 'L' THEN 'Liberada' WHEN 'B' THEN 'Bloqueada' WHEN 'R' THEN 'Rejeitada' ELSE 'Outros' END AS status
  FROM {B}.com_solicitacoes WHERE {DT('EMISSAO')} >= add_months(current_date(), -12))''')}
GROUP BY 1, 2, 3
""")

view("vw_com_leadtime_mes", f"""
SELECT filial, mes, count(*) AS itens,
       percentile_approx(dias, 0.5) AS mediana_dias,
       percentile_approx(dias, 0.9) AS p90_dias
FROM {TODAS(f'''(SELECT {FIL('p.FILIAL')} AS filial, date_trunc('MONTH', {DT('p.EMISSAO')}) AS mes,
         datediff({DT('p.EMISSAO')}, {DT('s.EMISSAO')}) AS dias
  FROM {B}.ped_solicitacoes s
  JOIN {B}.ped_itens p ON p.FILIAL = s.FILIAL AND p.NUM = s.NUM AND p.ITEM = s.ITEM AND p.DEL = '')''')}
WHERE dias >= 0 AND mes >= add_months(current_date(), -24)
GROUP BY filial, mes
""")

view("vw_com_notas_mes", f"""
SELECT filial, mes, sum(V) AS valor, count(*) AS notas,
       try_divide(sum(CASE WHEN PED = '' THEN 1 ELSE 0 END), count(*)) AS pct_sem_pedido
FROM {TODAS(f'''(SELECT {FIL('FIL')} AS filial, date_trunc('MONTH', {DT('DIG')}) AS mes, V, PED
  FROM {B}.com_notas_entrada WHERE {DT('DIG')} IS NOT NULL)''')}
GROUP BY filial, mes
""")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Frota
# MAGIC O tipo de manutencao vem como codigo (T4_TIPOMAN). Ajuste o `CASE` de `tipo_manutencao` com os nomes usados no cadastro de servicos (ST4).

# COMMAND ----------

view("vw_mnt_os", f"""
SELECT {FIL('o.FIL')} AS filial, trim(o.FIL) AS cod_filial, {CC('o.CC')} AS centro_custo,
       o.OS, o.BEM AS bem, b.NOME AS bem_nome, b.FAMD AS familia, o.SERVD AS servico,
       CASE o.TMAN WHEN '' THEN 'Sem tipo' ELSE concat('Tipo ', o.TMAN) END AS tipo_manutencao,
       {DT('o.ABE')} AS dt_abertura, {DT('o.INI')} AS dt_inicio, {DT('o.FIM')} AS dt_fim,
       o.TERM = 'S' AS terminada,
       o.P AS custo_pecas, o.TR AS custo_terceiros, o.P + o.TR AS custo, o.H AS horas,
       datediff({DT('o.FIM')}, {DT('o.ABE')}) AS dias_ate_fim
FROM {B}.mnt_ordens o
-- o mesmo codigo de bem existe em mais de uma filial: agrupa para nao duplicar as OS
LEFT JOIN (SELECT COD, max(NOME) AS NOME, max(FAMD) AS FAMD FROM {B}.mnt_bens GROUP BY COD) b ON b.COD = o.BEM
""")

view("vw_mnt_kpi", f"""
SELECT filial, count(*) AS os_12m, sum(custo) AS custo_12m,
       sum(CASE WHEN NOT terminada THEN 1 ELSE 0 END) AS os_abertas,
       percentile_approx(dias_ate_fim, 0.5) AS mttr_mediano_dias,
       count(DISTINCT bem) AS bens_atendidos
FROM {TODAS(f'{G}.vw_mnt_os')}
WHERE dt_abertura >= add_months(current_date(), -12)
GROUP BY filial
""")

view("vw_mnt_os_mes", f"""
SELECT filial, date_trunc('MONTH', dt_abertura) AS mes, tipo_manutencao, count(*) AS qtd_os, sum(custo) AS custo
FROM {TODAS(f'{G}.vw_mnt_os')} GROUP BY 1, 2, 3
""")

view("vw_mnt_custo_familia", f"""
SELECT filial, coalesce(familia, 'Sem familia') AS familia, count(DISTINCT bem) AS bens, count(*) AS qtd_os,
       sum(custo) AS custo, try_divide(sum(custo), count(DISTINCT bem)) AS custo_medio_por_bem
FROM {TODAS(f'{G}.vw_mnt_os')}
WHERE dt_abertura >= add_months(current_date(), -12)
GROUP BY 1, 2
""")

view("vw_mnt_custo_bem", f"""
WITH c AS (
  SELECT filial, bem, max(bem_nome) AS bem_nome, max(familia) AS familia, count(*) AS qtd_os, sum(custo) AS custo
  FROM {TODAS(f'{G}.vw_mnt_os')} WHERE dt_abertura >= add_months(current_date(), -12) GROUP BY filial, bem
), k AS (
  -- km rodados do bem (todas as leituras do hodometro, em qualquer filial)
  SELECT BEM AS bem, sum(greatest(MX - MN, 0)) AS km_rodados
  FROM {B}.mnt_hodometro WHERE {YM('YM')} >= add_months(current_date(), -12) GROUP BY BEM
)
SELECT c.*, k.km_rodados, try_divide(c.custo, k.km_rodados) AS custo_por_km
FROM c LEFT JOIN k ON k.bem = c.bem
""")

view("vw_mnt_os_atipicas", f"""
-- OS com custo muito acima do normal para o mesmo servico (z-score > 3, servicos com 10+ OS na empresa toda)
WITH s AS (
  SELECT *, avg(custo) OVER (PARTITION BY servico) AS media_servico,
            stddev(custo) OVER (PARTITION BY servico) AS desvio_servico,
            count(*) OVER (PARTITION BY servico) AS qtd_servico
  FROM {G}.vw_mnt_os WHERE custo > 0
)
SELECT filial, centro_custo, OS, bem, bem_nome, servico, dt_abertura, custo, round(media_servico, 2) AS media_servico,
       round(try_divide(custo - media_servico, desvio_servico), 1) AS z_score
FROM s
WHERE qtd_servico >= 10 AND try_divide(custo - media_servico, desvio_servico) > 3
""")

# km rodados por bem e mes (todas as leituras do hodometro, em qualquer filial), para o custo x km no periodo
view("vw_mnt_km_mes", f"""
SELECT BEM AS bem, {YM('YM')} AS mes, sum(greatest(MX - MN, 0)) AS km_rodados
FROM {B}.mnt_hodometro WHERE {YM('YM')} IS NOT NULL GROUP BY 1, 2
""")

# Detalhamento do custo de cada bem: uma linha por lancamento (OS x produto, OS x terceiros, abastecimento).
# origem: Peças | Pneus | Serviços de terceiros | Combustível
#  - Pneus: peca aplicada na OS cujo produto ou grupo tem "PNEU" na descricao, e servico de terceiros em OS
#    cujo servico tem "PNEU", "RECAP" ou "BORRACH" no nome. Ajuste PNEU_PECA / PNEU_SERV se o cadastro usar outro nome.
#  - Combustivel: abastecimentos do SIGAMNT (TQN, endpoint /bi/frota/abastecimentos). Sem a tabela bronze, fica vazio.
PNEU_PECA = "(upper(coalesce(p.DESCR, '')) LIKE '%PNEU%' OR upper(coalesce(p.GRPD, '')) LIKE '%PNEU%')"
PNEU_SERV = "(upper(coalesce(o.servico, '')) RLIKE 'PNEU|RECAP|BORRACH')"
_tem_abast = spark.catalog.tableExists(f"{B}.mnt_abastecimentos")
_abast = f"""
  UNION ALL
  SELECT {FIL('a.FIL')}, {CC('a.CC')}, trim(a.BEM), b.NOME, b.FAMD, {DT('a.DT')}, 'Combustível',
         concat('Abastecimento ', date_format({DT('a.DT')}, 'dd/MM/yyyy')),
         coalesce(nullif(trim(a.COMBD), ''), trim(a.COMB), 'Combustível'),
         CAST(a.L AS DOUBLE), CAST(a.V AS DOUBLE)
  FROM {B}.mnt_abastecimentos a
  LEFT JOIN (SELECT COD, max(NOME) AS NOME, max(FAMD) AS FAMD FROM {B}.mnt_bens GROUP BY COD) b ON b.COD = trim(a.BEM)
  WHERE trim(coalesce(a.BEM, '')) <> ''""" if _tem_abast else ""
view("vw_mnt_custos", f"""
WITH o AS (SELECT * FROM {G}.vw_mnt_os)
SELECT filial, centro_custo, bem, bem_nome, familia, data, origem, documento, descricao, quantidade, valor
FROM (
  SELECT o.filial, o.centro_custo, o.bem, o.bem_nome, o.familia, o.dt_abertura AS data,
         CASE WHEN {PNEU_PECA} THEN 'Pneus' ELSE 'Peças' END AS origem,
         concat('OS ', o.OS, ' - ', coalesce(o.servico, '')) AS documento,
         concat_ws(' - ', p.PROD, p.DESCR) AS descricao, CAST(p.Q AS DOUBLE) AS quantidade, CAST(p.V AS DOUBLE) AS valor
  FROM {B}.mnt_pecas p JOIN o ON o.cod_filial = trim(p.FIL) AND o.OS = trim(p.OS)
  UNION ALL
  SELECT o.filial, o.centro_custo, o.bem, o.bem_nome, o.familia, o.dt_abertura,
         CASE WHEN {PNEU_SERV} THEN 'Pneus' ELSE 'Serviços de terceiros' END,
         concat('OS ', o.OS, ' - ', coalesce(o.servico, '')), 'Serviço de terceiros', CAST(NULL AS DOUBLE),
         CAST(o.custo_terceiros AS DOUBLE)
  FROM o WHERE o.custo_terceiros <> 0{_abast}
) WHERE valor <> 0
""")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Estoque

# COMMAND ----------

view("vw_est_itens", f"""
SELECT {FIL('FILIAL')} AS filial, COD AS produto, DESCR AS descricao, GRPD AS grupo, LOC AS armazem,
       Q AS quantidade, V AS valor,
       {DT('US')} AS dt_ultima_saida, {DT('UE')} AS dt_ultima_entrada,
       datediff(current_date(), {DT('US')}) AS dias_sem_saida,
       ({DT('US')} IS NULL OR datediff(current_date(), {DT('US')}) > 180) AND V > 0 AS parado_180d
FROM {B}.est_saldos
""")

view("vw_est_kpi", f"""
SELECT filial,
       sum(CASE WHEN valor > 0 THEN valor END) AS valor_estoque,
       sum(CASE WHEN parado_180d THEN valor END) AS valor_parado_180d,
       try_divide(sum(CASE WHEN parado_180d THEN valor END), sum(CASE WHEN valor > 0 THEN valor END)) AS pct_parado,
       sum(CASE WHEN quantidade < 0 THEN 1 ELSE 0 END) AS itens_saldo_negativo,
       count(DISTINCT produto) AS produtos
FROM {TODAS(f'{G}.vw_est_itens')}
GROUP BY filial
""")

view("vw_est_abc", f"""
WITH p AS (SELECT filial, produto, sum(valor) AS valor FROM {TODAS(f'{G}.vw_est_itens')} WHERE valor > 0 GROUP BY filial, produto),
     r AS (SELECT *, try_divide(sum(valor) OVER (PARTITION BY filial ORDER BY valor DESC ROWS UNBOUNDED PRECEDING),
                                sum(valor) OVER (PARTITION BY filial)) AS acum,
                     sum(valor) OVER (PARTITION BY filial) AS total
           FROM p)
SELECT filial, CASE WHEN acum <= 0.8 THEN 'A' WHEN acum <= 0.95 THEN 'B' ELSE 'C' END AS classe,
       count(*) AS produtos, sum(valor) AS valor, try_divide(sum(valor), max(total)) AS pct_valor
FROM r GROUP BY 1, 2
""")

view("vw_est_parados", f"""
SELECT filial, produto, descricao, grupo, armazem, quantidade, valor, dt_ultima_saida,
       dias_sem_saida, CASE WHEN dt_ultima_saida IS NULL THEN 'Nunca' ELSE CAST(dias_sem_saida AS STRING) END AS sem_saida
FROM {G}.vw_est_itens
WHERE parado_180d
""")

view("vw_est_fechamentos", f"""
SELECT filial, mes, sum(V) AS valor
FROM {TODAS(f"(SELECT {FIL('FILIAL')} AS filial, {DT('DT')} AS mes, V FROM {B}.est_fechamentos)")}
GROUP BY 1, 2
""")

# formato longo (mes, tipo, valor): um campo de cor no grafico em vez de duas series
view("vw_est_ajustes_mes", f"""
WITH a AS (
  SELECT filial, date_trunc('MONTH', {DT('DT')}) AS mes, V, USR
  FROM {TODAS(f"(SELECT {FIL('FILIAL')} AS filial, DT, V, USR FROM {B}.est_ajustes)")}
)
SELECT filial, mes, 'Entrada (sobra)' AS tipo, sum(CASE WHEN V > 0 THEN V ELSE 0 END) AS valor, count(*) AS ajustes
FROM a GROUP BY 1, 2
UNION ALL
SELECT filial, mes, 'Saída (perda)' AS tipo, sum(CASE WHEN V < 0 THEN -V ELSE 0 END) AS valor, count(*) AS ajustes
FROM a GROUP BY 1, 2
""")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Pessoas (somente agregados)

# COMMAND ----------

view("vw_rh_quadro", f"""
SELECT {FIL('FILIAL')} AS filial, CC, CC_DESC, {CC('CC', 'CC_DESC')} AS centro_custo, SIT, N FROM {B}.fol_quadro
""")

view("vw_rh_adm_dem", f"""
SELECT {FIL('FILIAL')} AS filial, {YM('YM')} AS mes, CC, {CC('CC')} AS centro_custo, ADM, DEM
FROM {B}.fol_admissoes_demissoes
""")

# Folha por filial x competencia x CC (proventos e descontos), base dos filtros de periodo/CC
view("vw_rh_folha", f"""
SELECT filial, mes, centro_custo,
       sum(CASE WHEN TIPO = '1' THEN V ELSE 0 END) AS proventos,
       sum(CASE WHEN TIPO = '2' THEN V ELSE 0 END) AS descontos
FROM (SELECT {FIL('l.FILIAL')} AS filial, {YM('l.YM')} AS mes, {CC('l.CC')} AS centro_custo, v.TIPO, l.V
      FROM {B}.fol_lancamentos l LEFT JOIN {B}.fol_verbas v ON v.PD = l.PD)
GROUP BY 1, 2, 3
""")

view("vw_rh_kpi", f"""
WITH q AS (SELECT filial, sum(N) AS headcount,
                  sum(CASE WHEN SIT = 'A' THEN N ELSE 0 END) AS afastados,
                  sum(CASE WHEN SIT = 'F' THEN N ELSE 0 END) AS em_ferias
           FROM {TODAS(f'{G}.vw_rh_quadro')} GROUP BY filial),
     d AS (SELECT filial, sum(DEM) AS dem_12m, sum(ADM) AS adm_12m FROM {TODAS(f'{G}.vw_rh_adm_dem')}
           WHERE mes >= add_months(date_trunc('MONTH', current_date()), -12) GROUP BY filial)
SELECT q.*, d.adm_12m, d.dem_12m,
       try_divide(d.dem_12m, q.headcount) AS turnover_12m,
       try_divide(q.afastados, q.headcount) AS pct_afastados
FROM q LEFT JOIN d ON d.filial = q.filial
""")

view("vw_rh_movimento_mes", f"""
WITH m AS (SELECT filial, mes, sum(ADM) AS admissoes, sum(DEM) AS demissoes
           FROM {TODAS(f'{G}.vw_rh_adm_dem')} GROUP BY 1, 2),
     q AS (SELECT filial, sum(N) AS headcount FROM {TODAS(f'{G}.vw_rh_quadro')} GROUP BY 1)
SELECT m.*, admissoes - demissoes AS saldo, try_divide(demissoes, q.headcount) AS turnover_mes
FROM m LEFT JOIN q ON q.filial = m.filial
""")

# formato longo para o grafico de barras (tipo = Admissoes / Demissoes)
view("vw_rh_movimento_tipo", f"""
SELECT filial, mes, 'Admissões' AS tipo, admissoes AS pessoas FROM {G}.vw_rh_movimento_mes
UNION ALL
SELECT filial, mes, 'Demissões' AS tipo, demissoes AS pessoas FROM {G}.vw_rh_movimento_mes
""")

view("vw_rh_folha_mes", f"""
SELECT filial, mes,
       sum(CASE WHEN TIPO = '1' THEN V ELSE 0 END) AS proventos,
       sum(CASE WHEN TIPO = '2' THEN V ELSE 0 END) AS descontos,
       sum(CASE WHEN TIPO = '1' THEN V ELSE 0 END) - sum(CASE WHEN TIPO = '2' THEN V ELSE 0 END) AS liquido
FROM {TODAS(f'''(SELECT {FIL('l.FILIAL')} AS filial, {YM('l.YM')} AS mes, v.TIPO, l.V
  FROM {B}.fol_lancamentos l LEFT JOIN {B}.fol_verbas v ON v.PD = l.PD)''')}
GROUP BY 1, 2
""")

view("vw_rh_quadro_cc", f"""
SELECT filial, centro_custo, sum(N) AS pessoas,
       sum(CASE WHEN SIT = 'A' THEN N ELSE 0 END) AS afastados
FROM {TODAS(f'{G}.vw_rh_quadro')} GROUP BY 1, 2
""")

view("vw_med_atestados", f"""
SELECT {FIL('FIL')} AS filial, {CC('CC', 'CCD')} AS centro_custo, {DT('INI')} AS dt_inicio, {DT('FIM')} AS dt_fim,
       coalesce(nullif(CIDD, ''), nullif(CID, ''), 'Sem CID') AS diagnostico
FROM {B}.med_atestados
""")

# Acidentes (sem dados pessoais): CC do acidente (TNC_CC) ou, sem ele, o CC do funcionario
view("vw_med_acidentes", f"""
SELECT {FIL('FIL')} AS filial,
       {CC("coalesce(nullif(trim(CC), ''), CC2)", "CASE WHEN trim(CC) <> '' THEN CCD ELSE CCD2 END")} AS centro_custo,
       {DT('DT')} AS dt_acidente, AFA = 'S' AS com_afastamento
FROM {B}.med_acidentes
""")

view("vw_med_mes", f"""
WITH a AS (SELECT filial, date_trunc('MONTH', dt_inicio) AS mes, count(*) AS atestados,
                  sum(coalesce(datediff(dt_fim, dt_inicio) + 1, 1)) AS dias_atestado
           FROM {TODAS(f'{G}.vw_med_atestados')} GROUP BY 1, 2),
     c AS (SELECT filial, date_trunc('MONTH', dt) AS mes, count(*) AS acidentes,
                  sum(CASE WHEN AFA = 'S' THEN 1 ELSE 0 END) AS acidentes_com_afastamento
           FROM {TODAS(f"(SELECT {FIL('FIL')} AS filial, {DT('DT')} AS dt, AFA FROM {B}.med_acidentes)")} GROUP BY 1, 2)
SELECT coalesce(a.filial, c.filial) AS filial, coalesce(a.mes, c.mes) AS mes,
       coalesce(atestados, 0) AS atestados, coalesce(dias_atestado, 0) AS dias_atestado,
       coalesce(acidentes, 0) AS acidentes, coalesce(acidentes_com_afastamento, 0) AS acidentes_com_afastamento
FROM a FULL OUTER JOIN c ON a.filial = c.filial AND a.mes = c.mes
""")

view("vw_med_cid", f"""
SELECT filial, diagnostico, count(*) AS atestados,
       sum(coalesce(datediff(dt_fim, dt_inicio) + 1, 1)) AS dias
FROM {TODAS(f'{G}.vw_med_atestados')} GROUP BY 1, 2
""")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Contratos de compra (Gestao de Contratos)
# MAGIC A API ja filtra so contratos de **compra** (especie 1). Uma linha por revisao em `ctr_contratos`;
# MAGIC a revisao atual e a de maior numero que nao esta "em revisao" (09) nem "revisada" (10).

# COMMAND ----------

view("vw_ctr_revisoes", f"""
WITH c AS (
  SELECT {FIL('FILIAL')} AS filial, trim(FILIAL) AS cod_filial, CONTRATO AS contrato, REVISAO AS revisao,
         SITUACAO AS cod_situacao,
         CASE SITUACAO WHEN '01' THEN 'Cancelado' WHEN '02' THEN 'Em elaboração' WHEN '03' THEN 'Emitido'
              WHEN '04' THEN 'Em aprovação' WHEN '05' THEN 'Vigente' WHEN '06' THEN 'Paralisado'
              WHEN '07' THEN 'Sol. finalização' WHEN '08' THEN 'Finalizado' WHEN '09' THEN 'Em revisão'
              WHEN '10' THEN 'Revisado' ELSE SITUACAO END AS situacao,
         coalesce(nullif(TIPO_DESC, ''), TIPO) AS tipo_contrato,
         {DT('DT_INICIO')} AS dt_inicio, {DT('DT_FIM')} AS dt_fim, {DT('DT_REVISAO')} AS dt_revisao,
         coalesce(nullif(TPREV_DESC, ''), nullif(TIPO_REV, ''), 'Não informado') AS tipo_revisao,
         CAST(VL_INICIAL AS DOUBLE) AS vl_inicial, CAST(VL_ATUAL AS DOUBLE) AS vl_atual, CAST(SALDO AS DOUBLE) AS saldo,
         coalesce(nullif(FORN_NOME, ''), FORNECEDOR) AS fornecedor
  FROM {B}.ctr_contratos
)
SELECT *,
       -- impacto da revisao no valor do contrato (aditivo/reajuste/supressao)
       vl_atual - lag(vl_atual) OVER (PARTITION BY cod_filial, contrato ORDER BY revisao) AS impacto,
       first_value(vl_inicial) OVER (PARTITION BY cod_filial, contrato ORDER BY revisao) AS vl_original,
       row_number() OVER (PARTITION BY cod_filial, contrato
                          ORDER BY CASE WHEN cod_situacao IN ('09', '10') THEN 1 ELSE 0 END, revisao DESC) = 1 AS revisao_atual
FROM c
""")

# Contratos (revisao atual) com consumo, crescimento e alertas
view("vw_ctr_contratos", f"""
SELECT filial, cod_filial, contrato, revisao, situacao, cod_situacao, tipo_contrato, fornecedor,
       dt_inicio, dt_fim, vl_original, vl_atual, saldo,
       vl_atual - saldo AS consumido,
       try_divide(vl_atual - saldo, vl_atual) AS pct_consumido,
       vl_atual - vl_original AS crescimento,
       try_divide(vl_atual - vl_original, vl_original) AS pct_crescimento,
       datediff(dt_fim, current_date()) AS dias_para_vencer,
       cod_situacao = '05' AS vigente,
       CASE WHEN cod_situacao <> '05' THEN NULL
            WHEN dt_fim < current_date() THEN 'Vigente com prazo vencido'
            WHEN try_divide(vl_atual - saldo, vl_atual) >= 0.9 THEN 'Saldo quase esgotado (>= 90%)'
            WHEN datediff(dt_fim, current_date()) <= 60 THEN 'Vence em até 60 dias'
            WHEN try_divide(vl_atual - vl_original, vl_original) >= 0.25 THEN 'Cresceu 25% ou mais'
       END AS alerta
FROM {G}.vw_ctr_revisoes
WHERE revisao_atual
""")

# Revisoes concluidas (nao conta a revisao 0/original nem as que ainda estao em elaboracao)
view("vw_ctr_revisoes_feitas", f"""
SELECT filial, cod_filial, contrato, revisao, dt_revisao, tipo_revisao, fornecedor, tipo_contrato,
       vl_atual, impacto
FROM {G}.vw_ctr_revisoes
WHERE cod_situacao <> '09' AND trim(revisao) <> '' AND try_cast(revisao AS INT) > 0
""")

view("vw_ctr_medicoes", f"""
SELECT {FIL('FILIAL')} AS filial, trim(FILIAL) AS cod_filial, CONTRATO AS contrato, MEDICAO AS medicao,
       PRODUTO AS produto, PROD_DESC AS produto_desc, CAST(VL_TOTAL AS DOUBLE) AS valor,
       {DT('DT_ENTREGA')} AS dt_entrega, date_trunc('MONTH', {DT('DT_ENTREGA')}) AS mes, COMPET AS competencia,
       nullif(trim(DT_ENCERR), '') IS NOT NULL AS encerrada, PEDIDO AS pedido,
       coalesce(nullif(CC_DESC, ''), nullif(CC, ''), 'Sem centro de custo') AS centro_custo,
       coalesce(nullif(FORN_NOME, ''), nullif(FORNECEDOR, ''), 'Sem fornecedor') AS fornecedor,
       coalesce(nullif(PROJ_DESC, ''), nullif(PROJETO, ''), 'Sem projeto') AS projeto
FROM {B}.ctr_medicoes
""")

view("vw_ctr_kpi", f"""
WITH f AS (SELECT DISTINCT filial FROM {TODAS(f'{G}.vw_ctr_contratos')}),
     c AS (SELECT filial,
                  count(CASE WHEN vigente THEN 1 END) AS contratos_vigentes,
                  sum(CASE WHEN vigente THEN vl_atual END) AS valor_contratado,
                  sum(CASE WHEN vigente THEN saldo END) AS saldo_a_medir,
                  try_divide(sum(CASE WHEN vigente THEN vl_atual - saldo END), sum(CASE WHEN vigente THEN vl_atual END)) AS pct_consumido,
                  sum(CASE WHEN vigente THEN crescimento END) AS crescimento_valor,
                  try_divide(sum(CASE WHEN vigente THEN crescimento END), sum(CASE WHEN vigente THEN vl_original END)) AS pct_crescimento,
                  count(alerta) AS contratos_em_alerta
           FROM {TODAS(f'{G}.vw_ctr_contratos')} GROUP BY filial),
     r AS (SELECT filial, count(DISTINCT cod_filial, contrato) AS revisados_30d, sum(impacto) AS impacto_revisoes_30d
           FROM {TODAS(f'{G}.vw_ctr_revisoes_feitas')}
           WHERE dt_revisao >= date_sub(current_date(), 30) GROUP BY filial),
     m AS (SELECT filial,
                  sum(CASE WHEN mes >= add_months(date_trunc('MONTH', current_date()), -12)
                            AND mes < date_trunc('MONTH', current_date()) THEN valor END) AS medido_12m,
                  sum(CASE WHEN mes = date_trunc('MONTH', current_date()) THEN valor END) AS medido_mes_atual
           FROM {TODAS(f'{G}.vw_ctr_medicoes')} GROUP BY filial)
SELECT f.filial, c.contratos_vigentes, c.valor_contratado, c.saldo_a_medir, c.pct_consumido,
       c.crescimento_valor, c.pct_crescimento, c.contratos_em_alerta,
       coalesce(r.revisados_30d, 0) AS revisados_30d, coalesce(r.impacto_revisoes_30d, 0) AS impacto_revisoes_30d,
       m.medido_12m, m.medido_mes_atual, try_divide(m.medido_12m, 12) AS media_mensal_12m
FROM f LEFT JOIN c ON c.filial = f.filial LEFT JOIN r ON r.filial = f.filial LEFT JOIN m ON m.filial = f.filial
""")

view("vw_ctr_medicao_mes", f"""
WITH m AS (
  SELECT filial, mes, sum(valor) AS valor, count(DISTINCT cod_filial, contrato, medicao) AS medicoes,
         count(DISTINCT cod_filial, contrato) AS contratos
  FROM {TODAS(f'{G}.vw_ctr_medicoes')} WHERE mes IS NOT NULL GROUP BY filial, mes
)
SELECT *, avg(valor) OVER (PARTITION BY filial ORDER BY mes ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS media_movel_3m
FROM m
""")

def _ctr_12m(dim, nome):
    return f"""
SELECT filial, {dim} AS {nome}, sum(valor) AS valor, count(DISTINCT cod_filial, contrato) AS contratos
FROM {TODAS(f'{G}.vw_ctr_medicoes')}
WHERE mes >= add_months(date_trunc('MONTH', current_date()), -12)
GROUP BY 1, 2
"""
view("vw_ctr_medicao_cc", _ctr_12m("centro_custo", "centro_custo"))
view("vw_ctr_medicao_projeto", _ctr_12m("projeto", "projeto"))

view("vw_ctr_medicao_fornecedor", f"""
WITH f AS ({_ctr_12m("fornecedor", "fornecedor")}),
r AS (
  SELECT *, row_number() OVER (PARTITION BY filial ORDER BY valor DESC) AS ranking,
         try_divide(valor, sum(valor) OVER (PARTITION BY filial)) AS pct,
         try_divide(sum(valor) OVER (PARTITION BY filial ORDER BY valor DESC ROWS UNBOUNDED PRECEDING),
                    sum(valor) OVER (PARTITION BY filial)) AS pct_acumulado
  FROM f
)
SELECT *, CASE WHEN pct_acumulado <= 0.8 THEN 'A' WHEN pct_acumulado <= 0.95 THEN 'B' ELSE 'C' END AS classe
FROM r
""")

# Quanto cada tipo de revisao (reajuste, aditivo de valor, prazo...) acrescentou nos ultimos 12 meses
view("vw_ctr_revisoes_tipo", f"""
SELECT filial, tipo_revisao, count(*) AS revisoes, count(DISTINCT cod_filial, contrato) AS contratos,
       sum(impacto) AS impacto
FROM {TODAS(f'{G}.vw_ctr_revisoes_feitas')}
WHERE dt_revisao >= add_months(current_date(), -12)
GROUP BY 1, 2
""")

view("vw_ctr_revisoes_30d", f"""
SELECT filial, contrato, revisao, dt_revisao, tipo_revisao, fornecedor, vl_atual, impacto
FROM {G}.vw_ctr_revisoes_feitas
WHERE dt_revisao >= date_sub(current_date(), 30)
""")

view("vw_ctr_alertas", f"""
SELECT filial, contrato, fornecedor, tipo_contrato, alerta, dt_fim, dias_para_vencer,
       vl_original, vl_atual, saldo, pct_consumido, pct_crescimento
FROM {G}.vw_ctr_contratos
WHERE alerta IS NOT NULL
""")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Usuarios do sistema e licencas
# MAGIC Cadastro (SYS_USR), modulos (SYS_USR_MODULE) e historico de acesso (TOTVS_AUDIT agregado por usuario, dia e hora).
# MAGIC Nao tem filial: usuario e licenca valem para o grupo todo.
# MAGIC **Acesso** = existir registro do usuario na TOTVS_AUDIT naquele dia/hora (mesmo criterio da consulta de ultimo acesso).
# MAGIC **Pico na mesma hora** = maximo de usuarios distintos com registro na mesma hora: aproxima o uso simultaneo
# MAGIC (o numero exato de conexoes simultaneas fica no License Server / monitor do AppServer).

# COMMAND ----------

# Numero do modulo (USR_MODULO) -> nome. Codigos padrao do Protheus; os que nao estao aqui aparecem como "Modulo NN".
MODULOS = {
    1: "SIGAATF - Ativo Fixo", 2: "SIGACOM - Compras", 3: "SIGACON - Contabilidade", 4: "SIGAEST - Estoque/Custos",
    5: "SIGAFAT - Faturamento", 6: "SIGAFIN - Financeiro", 7: "SIGAGPE - Gestão de Pessoal",
    8: "SIGAFAS - Faturamento de Serviços", 9: "SIGAFIS - Livros Fiscais", 10: "SIGAPCP - Planejamento da Produção",
    11: "SIGAVEI - Veículos", 12: "SIGALOJA - Controle de Lojas", 13: "SIGATMK - Call Center", 14: "SIGAOFI - Oficina",
    15: "SIGARPM - Gerador de Relatórios", 16: "SIGAPON - Ponto Eletrônico", 17: "SIGAEIC - Importação",
    18: "SIGATCF - Terminal do Funcionário", 19: "SIGAMNT - Manutenção de Ativos", 20: "SIGARSP - Recrutamento e Seleção",
    21: "SIGAQIE - Inspeção de Entradas", 22: "SIGAQMT - Metrologia", 23: "SIGAFRT - Front Loja",
    24: "SIGAQDO - Controle de Documentos", 25: "SIGAQIP - Inspeção de Processos", 26: "SIGATRM - Treinamento",
    28: "SIGATEC - Gestão de Serviços", 29: "SIGAEEC - Exportação", 33: "SIGAPLS - Planos de Saúde",
    34: "SIGACTB - Contabilidade Gerencial", 35: "SIGAMDT - Medicina e Segurança do Trabalho",
    36: "SIGAQNC - Não Conformidades", 39: "SIGAOMS - Gestão de Distribuição", 40: "SIGACSA - Cargos e Salários",
    42: "SIGAWMS - Gestão de Armazenagem", 43: "SIGATMS - Gestão de Transportes", 44: "SIGAPMS - Gestão de Projetos",
    46: "SIGAACD - Coleta de Dados", 53: "SIGAAPD - Avaliação de Desempenho", 56: "SIGASGA - Gestão Ambiental",
    57: "SIGAPCO - Planejamento Orçamentário", 69: "SIGAGCT - Gestão de Contratos", 76: "SIGAJURI - Jurídico",
    78: "SIGAGFE - Gestão de Frete Embarcador", 84: "SIGATAF - TOTVS Automação Fiscal", 97: "SIGAESP - Específicos",
    99: "SIGACFG - Configurador",
}


def MOD(c):
    """Codigo do modulo -> nome. Texto nao numerico (ex.: 'SIGAFIN') fica como veio; vazio vira NULL."""
    casos = " ".join(f"WHEN {k} THEN '{v}'" for k, v in MODULOS.items())
    return (f"CASE WHEN nullif(trim({c}), '') IS NULL THEN NULL "
            f"WHEN try_cast(trim({c}) AS INT) IS NULL THEN upper(trim({c})) "
            f"ELSE CASE try_cast(trim({c}) AS INT) {casos} "
            f"ELSE concat('Módulo ', lpad(trim({c}), 2, '0')) END END")


def TS(c):
    """ADT_DATA (AAAAMMDDHHMMSS) -> TIMESTAMP."""
    return f"try_to_timestamp(left(regexp_replace({c}, '[^0-9]', ''), 14), 'yyyyMMddHHmmss')"


# liberado: a flag USR_ACESSO, quando existe; sem ela, toda linha da SYS_USR_MODULE conta como liberada
view("vw_usr_modulos", f"""
SELECT trim(ID) AS usuario_id, try_cast(trim(MODULO) AS INT) AS cod_modulo, {MOD('MODULO')} AS modulo,
       upper(coalesce(nullif(trim(ACESSO), ''), 'T')) NOT IN ('F', 'N', '0', '2') AS liberado,
       nullif(trim(NIVEL), '') AS nivel, nullif(trim(MENU), '') AS menu
FROM {B}.usr_modulos WHERE nullif(trim(MODULO), '') IS NOT NULL
""")

view("vw_usr_acessos", f"""
SELECT trim(a.ID) AS usuario_id, u.NOME AS nome, u.LOGIN AS login,
       to_date(a.DIA, 'yyyyMMdd') AS dia, date_trunc('MONTH', to_date(a.DIA, 'yyyyMMdd')) AS mes,
       try_cast(a.HORA AS INT) AS hora, {MOD('a.MODULO')} AS modulo, CAST(a.N AS BIGINT) AS eventos,
       {TS('a.PRI')} AS primeiro_registro, {TS('a.ULT')} AS ultimo_registro
FROM {B}.usr_acessos a
LEFT JOIN {B}.usr_usuarios u ON trim(u.ID) = trim(a.ID)
WHERE to_date(a.DIA, 'yyyyMMdd') IS NOT NULL
""")

view("vw_usr_usuarios", f"""
WITH m AS (SELECT usuario_id, concat_ws(', ', array_sort(collect_set(modulo))) AS modulos_liberados,
                  count(DISTINCT modulo) AS qtd_modulos_liberados
           FROM {G}.vw_usr_modulos WHERE liberado GROUP BY 1),
a AS (SELECT usuario_id, count(DISTINCT dia) AS dias_acesso_90d,
             concat_ws(', ', array_sort(collect_set(modulo))) AS modulos_usados_90d
      FROM {G}.vw_usr_acessos WHERE dia >= date_sub(current_date(), 90) GROUP BY 1),
u AS (SELECT trim(ID) AS usuario_id, trim(LOGIN) AS login, trim(NOME) AS nome, nullif(trim(EMAIL), '') AS email,
             trim(BLOQ) = '1' AS bloqueado, nullif(trim(DEPTO), '') AS departamento, nullif(trim(CARGO), '') AS cargo,
             {TS('ULT')} AS ultimo_acesso
      FROM {B}.usr_usuarios)
SELECT u.*, CASE WHEN u.bloqueado THEN 'Bloqueado' ELSE 'Ativo' END AS situacao,
       datediff(current_date(), CAST(u.ultimo_acesso AS DATE)) AS dias_sem_acesso,
       CASE WHEN u.bloqueado THEN '7. Bloqueado'
            WHEN u.ultimo_acesso IS NULL THEN '6. Nunca acessou'
            WHEN datediff(current_date(), CAST(u.ultimo_acesso AS DATE)) <= 7 THEN '1. Até 7 dias'
            WHEN datediff(current_date(), CAST(u.ultimo_acesso AS DATE)) <= 30 THEN '2. 8 a 30 dias'
            WHEN datediff(current_date(), CAST(u.ultimo_acesso AS DATE)) <= 60 THEN '3. 31 a 60 dias'
            WHEN datediff(current_date(), CAST(u.ultimo_acesso AS DATE)) <= 90 THEN '4. 61 a 90 dias'
            ELSE '5. Mais de 90 dias' END AS faixa_ultimo_acesso,
       NOT u.bloqueado AND (u.ultimo_acesso IS NULL
                            OR datediff(current_date(), CAST(u.ultimo_acesso AS DATE)) > 30) AS sem_acesso_30d,
       coalesce(m.modulos_liberados, 'Sem módulo na SYS_USR_MODULE') AS modulos_liberados,
       coalesce(m.qtd_modulos_liberados, 0) AS qtd_modulos_liberados,
       coalesce(a.dias_acesso_90d, 0) AS dias_acesso_90d, nullif(a.modulos_usados_90d, '') AS modulos_usados_90d
FROM u LEFT JOIN m ON m.usuario_id = u.usuario_id LEFT JOIN a ON a.usuario_id = u.usuario_id
""")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Diretoria - mapa de resultado
# MAGIC Views no schema **`<catalogo>.diretoria`**, separado do gold, para o acesso ficar restrito ao grupo da diretoria.
# MAGIC
# MAGIC | Linha | Origem |
# MAGIC |---|---|
# MAGIC | Receita (entrou) | faturamento: notas de saída que geram duplicata, menos devoluções, pelo mês de emissão |
# MAGIC | Frota | pagamentos com natureza de combustível, manutenção de frota/equipamentos e locação de máquinas e veículos |
# MAGIC | Pessoal | salários, férias, 13º, rescisões, encargos, benefícios e saúde/segurança do trabalho |
# MAGIC | Administrativo | despesas gerais, aluguéis e utilidades, TI, seguros, viagens, marketing, tributos e tarifas |
# MAGIC | Processos judiciais | naturezas de jurídico, processos e acordos |
# MAGIC | Demais custos da operação | terceirizados, materiais, resíduos, retenções e impostos sobre faturamento/lucro |
# MAGIC | Saldo | receita - todos os custos acima |
# MAGIC
# MAGIC Custos = pagamentos (baixas do contas a pagar) pelo mês do pagamento, classificados pela natureza
# MAGIC (mesma tabela de `scripts/mapa_dre.py`). **Ficam fora do saldo** e aparecem na conferência: empréstimos e
# MAGIC financiamentos, compra de bens (investimento), parcelamento de tributos, adiantamentos/transferências e
# MAGIC baixas sem saída de caixa (liquidação, fatura, compensação).

# COMMAND ----------

D = f"{CATALOGO}.diretoria"
GRUPO_DIRETORIA = "diretoria"          # grupo do Databricks (Settings > Identity and access) que pode ver o mapa
spark.sql(f"CREATE SCHEMA IF NOT EXISTS {D}")

# natureza -> grupo de custo (copia de scripts/mapa_dre.py; manter as duas iguais)
NAT_GRUPO = {
    "DED": "210014 210015 210001",
    "TER": "310002 311064 311031 311008 311038 311003 311006 311015 311048 311014 311061 311007 311107"
            " 311105 311001 311032 311025 260003 311090 311023 311054 311009 310009 242001 311056 311104"
            " 110003 110006",
    "LOC": "310001 311002 311017 311018 311042 311019 311026 311046 311057 311082 311106 311110 311043"
            " 311012 290001 311034 311111 311010 310011 311033 311091",
    "COMB": "311096 311095 290002 311094 311037",
    "MAN": "290003 290004 280001 290011 290014 290012 290015 311100 311108 311022 311053 311097 290010"
            " 311092",
    "MAT": "230003 230001 310007 311060 344003 310003 231001 231004 230002 230004 410032 410079 112009",
    "RES": "311070 311035 311059 311011 311049 311045 411113",
    "RET": "210004 210005 210006 210007 210008 210010 410060 240004",
    "SAL": "260001 262001 263001 264001 260005 267001 261002 260002 410039 260006 260008 410063",
    "ENC": "269001 269002 264002 269003 269005 269006 269007 311051",
    "BEN": "261003 261006 261004 261012 261007 261013 261017 311030 311029 311028 311081 311020 311024"
            " 410071 410045 260007 261001 302002",
    "SST": "265003 265002 266001 265005 311021 410062 311101 311083 411104",
    "ADM": "271006 271007 271012 420000 420001 420002 410033 271014 270001 270002 270003 271002 311047"
            " 311109 311074 272002 410035 410093 273002 311076 311080 410052 280005 311086",
    "JUR": "311044 272003 311013 271009 271008 210013 271005 311050 410058 210018",
    "ALU": "240003 240005 240001 240002 311016 311040 311077 250001 250002 330001 330002 311004 330003"
            " 280002 280003 280004 281001 311068 410034 311069 311084 311079",
    "TI": "341004 263003 272004 311071 311072 410057 311005 311075 311073 311052",
    "TRIB": "241003 344002 290008 410069 241001 241002 241004 311102 311085 411114 271011 271001 290009"
            " 410067 290007 211003",
    "SEG": "261011 290005 290016 242002 310005",
    "VIA": "410048 301001 300001 300002 301003 302001 301005 310006 410047 271003 290013",
    "MKT": "410054 410100 321003 321002 311027 410099 321004 410061 311041 320001 410092",
    "TAR": "360003 360005 360006",
    "IR": "210016 210017",
    "CAPEX": "341002 342001 342002 341003 340002 343001 410053 341001 343002 410070 344001",
    "PARC": "351002",
    "MOV": "271013 380001 380002 411111 112006 112002 311093 271010",
}
PREFIXO_GRUPO = {"29": "MAN", "31": "TER", "27": "ADM", "28": "ALU", "26": "SAL", "41": "ADM", "42": "ADM", "23": "MAT",
                 "24": "TRIB", "21": "RET", "30": "VIA", "33": "ALU", "34": "CAPEX", "36": "TAR", "38": "MOV", "11": "MOV"}
GRUPO_DESC = {
    "DED": "Impostos sobre o faturamento", "TER": "Serviços terceirizados",
    "LOC": "Locação de máquinas, veículos e equipamentos", "COMB": "Combustíveis e lubrificantes",
    "MAN": "Manutenção de frota e equipamentos", "MAT": "Materiais e insumos operacionais",
    "RES": "Tratamento e destinação de resíduos", "RET": "Retenções de terceiros recolhidas",
    "SAL": "Salários, férias, 13º e rescisões", "ENC": "Encargos sociais", "BEN": "Benefícios",
    "SST": "Saúde e segurança do trabalho", "ADM": "Administrativas gerais", "JUR": "Jurídico, processos e acordos",
    "ALU": "Aluguéis, condomínio e utilidades", "TI": "TI e sistemas", "TRIB": "Tributos, taxas e licenças",
    "SEG": "Seguros", "VIA": "Viagens e deslocamentos", "MKT": "Marketing, comissões e doações",
    "OUT": "Outras despesas", "TAR": "Tarifas bancárias", "IR": "IRPJ e CSLL",
    "CAPEX": "Investimentos (bens comprados sem financiamento)", "PARC": "Parcelamento de tributos",
    "MOV": "Adiantamentos, aportes e outras movimentações",
}
# grupo de custo -> linha do mapa (a ordem define a ordem das linhas; a Receita e a 0, o Saldo a 9)
LINHA_GRUPO = {
    "Frota": ["COMB", "MAN", "LOC"],
    "Pessoal": ["SAL", "ENC", "BEN", "SST"],
    "Administrativo": ["ADM", "ALU", "TI", "SEG", "VIA", "MKT", "TRIB", "TAR", "OUT"],
    "Processos judiciais": ["JUR"],
    "Demais custos da operação": ["TER", "MAT", "RES", "RET", "DED", "IR"],
    "Fora do saldo": ["CAPEX", "PARC", "MOV"],
}
# pagamentos de financiamento/emprestimo (regras de scripts/mapa_dre.py)
NAT_FIN = ["111006", "268002", "268003", "268006", "311103", "350001", "350002", "350003", "351001", "352001",
           "353001", "353003"]
NAT_BEM = ["341002", "341003", "342001", "342002"]
RE_FIN = (r"EMPREST|FINANCIAMENT|CAPITAL DE GIRO|CONSORCIO|LEASING|FINAME|\bFCO\b|MUTUO|BNDES|LIMITE DE CREDITO|"
          r"OPERACOES FINANCEIRAS|ABERTURA CREDITO")
RE_BANCO = (r"\bBANCO\b|\bBANK\b|FINANCIAMENTOS|LEASING|CAIXA ECONOMICA|SANTANDER|ITAU|BRADESCO S|BNDES|SICOOB|SICREDI|"
            r"ADMINISTRADORA DE CONSORCIOS|CREDITO|DAYCOVAL|SOFISA")

def _lista(xs):
    return ", ".join(f"'{x}'" for x in xs)

def _rx(r):
    """Regex para literal do Spark SQL (a barra invertida precisa ser dobrada)."""
    return r.replace("\\", "\\\\")

_v_nat = ", ".join(f"('{c}', '{g}')" for g, s in NAT_GRUPO.items() for c in s.split())
_v_pre = ", ".join(f"('{p}', '{g}')" for p, g in PREFIXO_GRUPO.items())
_v_lin = ", ".join(f"('{g}', '{GRUPO_DESC[g]}', '{l}', {i})"
                   for i, (l, gs) in enumerate(LINHA_GRUPO.items(), start=1) for g in gs)

# Um pagamento por linha, ja com a linha do mapa (ou 'Fora do saldo' e o motivo).
view(f"{D}.vw_dir_pagamentos", f"""
WITH p AS (
  SELECT {FIL('FILIAL')} AS filial, trim(FILIAL) AS cod_filial,
         {DT('PAGO_EM')} AS dt_pagamento, date_trunc('MONTH', {DT('PAGO_EM')}) AS mes,
         trim(NATUREZA) AS natureza, trim(NATUREZA_DESC) AS natureza_desc, trim(FORNECEDOR) AS fornecedor,
         CAST(PAGO AS DOUBLE) AS valor, upper(trim(MOTBX)) AS motbx, upper(trim(TIPODOC)) AS tipodoc
  FROM {B}.fin_pagamentos
),
nat AS (SELECT * FROM VALUES {_v_nat} AS t(cod, grp)),
pre AS (SELECT * FROM VALUES {_v_pre} AS t(prefixo, grp)),
lin AS (SELECT * FROM VALUES {_v_lin} AS t(grp, grupo, linha, ordem)),
c AS (
  SELECT p.*, coalesce(n.grp, pr.grp, 'OUT') AS grp,
         p.motbx IN ('LIQ', 'FAT', 'CMP') OR p.tipodoc = 'CP' AS sem_caixa,
         p.natureza IN ({_lista(NAT_FIN)})
           OR upper(coalesce(p.natureza_desc, '')) RLIKE '{_rx(RE_FIN)}'
           OR (p.natureza IN ({_lista(NAT_BEM)}) AND upper(coalesce(p.fornecedor, '')) RLIKE '{_rx(RE_BANCO)}')
           AS financiamento
  FROM p
  LEFT JOIN nat n ON n.cod = p.natureza
  LEFT JOIN pre pr ON pr.prefixo = left(p.natureza, 2)
)
SELECT c.filial, c.cod_filial, c.dt_pagamento, c.mes, c.natureza, c.natureza_desc, c.fornecedor, c.valor,
       l.grupo,
       CASE WHEN c.sem_caixa OR c.financiamento THEN 'Fora do saldo' ELSE l.linha END AS linha,
       CASE WHEN c.sem_caixa OR c.financiamento THEN 99 ELSE l.ordem END AS ordem,
       CASE WHEN c.sem_caixa      THEN 'Baixa sem saída de caixa (liquidação, fatura ou compensação)'
            WHEN c.financiamento  THEN 'Empréstimo / financiamento'
            WHEN l.linha = 'Fora do saldo' THEN l.grupo END AS motivo_fora
FROM c JOIN lin l ON l.grp = c.grp
WHERE c.mes IS NOT NULL
""")

view(f"{D}.vw_dir_receita", f"""
SELECT {FIL('FIL')} AS filial, {YM('MES')} AS mes,
       sum(CASE WHEN upper(trim(TIPO)) = 'DEVOLUCAO' THEN 0 ELSE CAST(BRUTO AS DOUBLE) END) AS faturado,
       sum(CASE WHEN upper(trim(TIPO)) = 'DEVOLUCAO' THEN CAST(BRUTO AS DOUBLE) ELSE 0 END) AS devolucoes,
       sum(CASE WHEN upper(trim(TIPO)) = 'DEVOLUCAO' THEN -1 ELSE 1 END * CAST(BRUTO AS DOUBLE)) AS receita
FROM {B}.fin_faturamento
WHERE {YM('MES')} IS NOT NULL
GROUP BY 1, 2
""")

# Mapa em formato longo: filial x mes x linha. Receita positiva, custos positivos (o dashboard calcula o saldo).
view(f"{D}.vw_dir_mapa", f"""
SELECT filial, mes, 'Receita' AS linha, 0 AS ordem, receita AS valor FROM {D}.vw_dir_receita
UNION ALL
SELECT filial, mes, linha, ordem, sum(valor) FROM {D}.vw_dir_pagamentos
WHERE linha <> 'Fora do saldo' GROUP BY filial, mes, linha, ordem
""")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Cria as views
# MAGIC A ordem importa: algumas views usam outras (por isso a criacao segue a ordem em que foram declaradas).

# COMMAND ----------

resultado = []
for nome, sql in VIEWS.items():
    try:
        alvo = nome if "." in nome else f"{G}.{nome}"      # nome com schema = fora do gold (ex.: diretoria)
        spark.sql(f"CREATE OR REPLACE VIEW {alvo} AS {sql}")
        linhas = spark.sql(f"SELECT count(*) AS n FROM {alvo}").first().n
        resultado.append((nome, linhas, "ok"))
    except Exception as e:
        resultado.append((nome, 0, str(e).split("\n")[0][:300]))

display(spark.createDataFrame(resultado, "view string, linhas long, status string"))

# COMMAND ----------

# MAGIC %md
# MAGIC ## Acesso da diretoria
# MAGIC Libera o schema `diretoria` so para o grupo `GRUPO_DIRETORIA`. Nao revoga nada: se o catalogo inteiro
# MAGIC estiver liberado para todos (grant em `quebec`), retire esse grant, senao o schema herda o acesso.

# COMMAND ----------

for cmd in (f"GRANT USE SCHEMA ON SCHEMA {D} TO `{GRUPO_DIRETORIA}`",
            f"GRANT SELECT ON SCHEMA {D} TO `{GRUPO_DIRETORIA}`"):
    try:
        spark.sql(cmd)
        print("ok:", cmd)
    except Exception as e:
        print("ERRO:", cmd, "->", str(e).split("\n")[0][:200])
display(spark.sql(f"SHOW GRANTS ON SCHEMA {D}"))
