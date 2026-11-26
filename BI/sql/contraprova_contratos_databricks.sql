-- =============================================================================
-- Contraprova do dashboard de Contratos - lado DATABRICKS (SQL Editor)
-- Rode bloco a bloco. Janela: ultimos 30 dias (igual ao filtro "30 dias atras").
-- Compare cada resultado com o mesmo bloco de contraprova_contratos_protheus.sql.
-- =============================================================================

-- 1) Reproduz o tile "Medido no periodo" com o filtro do print (30 dias atras ate 31/12/2026)
--    e separa o que e passado, o que e data futura, o que nao esta encerrado e o que nao gerou pedido.
SELECT
  sum(valor)                                                         AS medido_tile,
  sum(CASE WHEN dt_entrega <= current_date() THEN valor END)          AS medido_ate_hoje,
  sum(CASE WHEN dt_entrega >  current_date() THEN valor END)          AS medido_data_futura,
  sum(CASE WHEN encerrada THEN valor END)                             AS medido_encerradas,
  sum(CASE WHEN NOT encerrada THEN valor END)                         AS medido_nao_encerradas,
  sum(CASE WHEN nullif(trim(pedido), '') IS NULL THEN valor END)      AS medido_sem_pedido,
  sum(CASE WHEN encerrada AND dt_entrega <= current_date()
            AND nullif(trim(pedido), '') IS NOT NULL THEN valor END)  AS medido_encerr_c_pedido_ate_hoje,
  count(*)                                                           AS linhas
FROM quebec.gold.vw_ctr_medicoes
WHERE dt_entrega BETWEEN date_sub(current_date(), 30) AND DATE'2026-12-31';

-- 2) Duplicidade na bronze: o mesmo item de medicao nao pode aparecer mais de uma vez.
--    Se voltar linha aqui, algum JOIN da API (CND, CNA, SB1, CTT, SA2, CTH) esta multiplicando o valor.
SELECT FILIAL, CONTRATO, REVISAO, MEDICAO, ITEM, count(*) AS vezes, sum(CAST(VL_TOTAL AS DOUBLE)) AS valor_somado
FROM quebec.bronze.ctr_medicoes
GROUP BY ALL
HAVING count(*) > 1
ORDER BY valor_somado DESC
LIMIT 50;

-- 2b) Mesmo item de medicao em mais de uma REVISAO do contrato (duplicidade por revisao)
SELECT FILIAL, CONTRATO, MEDICAO, ITEM, count(DISTINCT REVISAO) AS revisoes, sum(CAST(VL_TOTAL AS DOUBLE)) AS valor_somado
FROM quebec.bronze.ctr_medicoes
GROUP BY ALL
HAVING count(DISTINCT REVISAO) > 1
ORDER BY valor_somado DESC
LIMIT 50;

-- 3) Total dos ultimos 30 dias (ate hoje), sem JOIN nenhum - numero a bater com o bloco 3 do Protheus
SELECT trim(FILIAL) AS filial, count(*) AS itens, count(DISTINCT CONTRATO, MEDICAO) AS medicoes,
       sum(CAST(VL_TOTAL AS DOUBLE)) AS valor
FROM quebec.bronze.ctr_medicoes
WHERE DT_ENTREGA BETWEEN date_format(date_sub(current_date(), 30), 'yyyyMMdd') AND date_format(current_date(), 'yyyyMMdd')
GROUP BY ROLLUP (trim(FILIAL))
ORDER BY filial NULLS FIRST;

-- 4) As 30 maiores medicoes da janela, para conferir uma a uma no Protheus (CNTA121 / medicoes do contrato)
SELECT FILIAL, CONTRATO, REVISAO, MEDICAO, DT_ENTREGA, DT_ENCERR, PEDIDO, FORN_NOME,
       count(*) AS itens, sum(CAST(VL_TOTAL AS DOUBLE)) AS valor
FROM quebec.bronze.ctr_medicoes
WHERE DT_ENTREGA BETWEEN date_format(date_sub(current_date(), 30), 'yyyyMMdd') AND DATE_FORMAT(DATE'2026-12-31', 'yyyyMMdd')
GROUP BY ALL
ORDER BY valor DESC
LIMIT 30;

-- 5) Distribuicao das datas de entrega: picos em datas futuras ou num unico dia indicam data prevista, nao realizada
SELECT DT_ENTREGA, count(*) AS itens, sum(CAST(VL_TOTAL AS DOUBLE)) AS valor
FROM quebec.bronze.ctr_medicoes
WHERE DT_ENTREGA >= date_format(date_sub(current_date(), 30), 'yyyyMMdd')
GROUP BY DT_ENTREGA
ORDER BY DT_ENTREGA;

-- 6) Data da ultima carga da bronze (se for antiga, o dashboard mostra foto velha)
SELECT max(_ingestao) AS ultima_carga, count(*) AS linhas FROM quebec.bronze.ctr_medicoes;
