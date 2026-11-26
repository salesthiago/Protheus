/* =============================================================================
   Titulos a pagar com pedido de compra de CONTRATO e/ou ORDEM DE SERVICO - 2026
   Banco: SQL Server (2017+), empresa 01 (tabelas com sufixo 010).

   Regra (a mesma da API BI /bi/financeiro/titulos-abertos e /pagamentos):
     titulo (SE2) -> nota de entrada (SF1/SD1) -> pedido de compra (SC7)
     o pedido conta quando tem contrato (C7_CONTRA) e/ou OS da manutencao
     (C7_OP ou C1_OP = numero da OS + 'OS001', padrao do modulo MNT).
     Financiamentos, emprestimos, impostos, provisorios (PR) e medicoes lancadas
     direto no financeiro nao tem pedido e ficam de fora.

   "Relacionado a 2026": titulo emitido em 2026, OU com vencimento real em 2026,
   OU com pagamento (baixa) em 2026. Os valores pagos sao so os de 2026.

   Uma linha por titulo (parcela). Numeros com virgula decimal e datas dd/mm/aaaa,
   prontos para abrir no Excel em portugues.

   Para gerar o CSV no SSMS: Query > Results To > Results To File (Ctrl+Shift+F),
   execute e salve como .csv. Ou, com o resultado em grade: botao direito >
   "Save Results As..." > CSV. Para sair com cabecalho, marque em
   Tools > Options > Query Results > SQL Server > Results to Grid >
   "Include column headers when copying or saving the results".
   ============================================================================= */
SET NOCOUNT ON;

DECLARE @INI CHAR(8) = '20260101';
DECLARE @FIM CHAR(8) = '20261231';

WITH PAG AS (               -- pagamentos validos de 2026 por titulo
    SELECT E5.E5_FILIAL, E5.E5_PREFIXO, E5.E5_NUMERO, E5.E5_PARCELA, E5.E5_TIPO, E5.E5_CLIFOR, E5.E5_LOJA,
           SUM(E5.E5_VALOR)   PAGO,
           SUM(E5.E5_VLJUROS) JUROS,
           SUM(E5.E5_VLMULTA) MULTA,
           SUM(E5.E5_VLDESCO) DESCONTO,
           MIN(E5.E5_DATA)    PRIM_PAG,
           MAX(E5.E5_DATA)    ULT_PAG,
           COUNT(*)           QTD_BAIXAS
    FROM SE5010 E5
    WHERE E5.D_E_L_E_T_ = ' ' AND E5.E5_RECPAG = 'P' AND E5.E5_SITUACA <> 'C'
      AND E5.E5_TIPODOC IN ('VL', 'BA', 'CP')
      AND E5.E5_DATA BETWEEN @INI AND @FIM
      AND NOT EXISTS (SELECT 1 FROM SE5010 X                    -- baixa estornada
                      WHERE X.D_E_L_E_T_ = ' ' AND X.E5_TIPODOC = 'ES'
                        AND X.E5_FILIAL = E5.E5_FILIAL AND X.E5_PREFIXO = E5.E5_PREFIXO
                        AND X.E5_NUMERO = E5.E5_NUMERO AND X.E5_PARCELA = E5.E5_PARCELA
                        AND X.E5_TIPO = E5.E5_TIPO AND X.E5_CLIFOR = E5.E5_CLIFOR
                        AND X.E5_LOJA = E5.E5_LOJA AND X.E5_SEQ = E5.E5_SEQ)
    GROUP BY E5.E5_FILIAL, E5.E5_PREFIXO, E5.E5_NUMERO, E5.E5_PARCELA, E5.E5_TIPO, E5.E5_CLIFOR, E5.E5_LOJA
),
BASE AS (
    SELECT E2.R_E_C_N_O_ REC, E2.E2_FILIAL, E2.E2_PREFIXO, E2.E2_NUM, E2.E2_PARCELA, E2.E2_TIPO,
           E2.E2_FORNECE, E2.E2_LOJA, E2.E2_NOMFOR, E2.E2_NATUREZ, E2.E2_HIST, E2.E2_ORIGEM,
           E2.E2_EMISSAO, E2.E2_VENCREA, E2.E2_BAIXA, E2.E2_VALOR, E2.E2_SALDO,
           PC.PEDIDO, PC.QTD_PED, PC.EMIS_PED, PC.CONTRATO, PC.OS,
           P.PAGO, P.JUROS, P.MULTA, P.DESCONTO, P.PRIM_PAG, P.ULT_PAG, P.QTD_BAIXAS
    FROM SE2010 E2
    OUTER APPLY (SELECT MIN(TRIM(C7.C7_NUM)) PEDIDO,
                        COUNT(DISTINCT C7.C7_NUM) QTD_PED,
                        MIN(C7.C7_EMISSAO) EMIS_PED,
                        MAX(NULLIF(TRIM(C7.C7_CONTRA), '')) CONTRATO,
                        MAX(OX.OS) OS
                 FROM SF1010 F1
                 JOIN SD1010 D  ON D.D_E_L_E_T_ = ' ' AND D.D1_FILIAL = F1.F1_FILIAL AND D.D1_DOC = F1.F1_DOC
                               AND D.D1_SERIE = F1.F1_SERIE AND D.D1_FORNECE = F1.F1_FORNECE
                               AND D.D1_LOJA = F1.F1_LOJA AND D.D1_PEDIDO <> ' '
                 JOIN SC7010 C7 ON C7.D_E_L_E_T_ = ' ' AND C7.C7_FILIAL = D.D1_FILIAL
                               AND C7.C7_NUM = D.D1_PEDIDO AND C7.C7_ITEM = D.D1_ITEMPC
                 LEFT JOIN SC1010 C1 ON C1.D_E_L_E_T_ = ' ' AND C1.C1_FILIAL = C7.C7_FILIAL
                               AND C1.C1_NUM = C7.C7_NUMSC AND C1.C1_ITEM = C7.C7_ITEMSC AND C7.C7_NUMSC <> ' '
                 CROSS APPLY (SELECT CASE WHEN SUBSTRING(C7.C7_OP, 7, 2) = 'OS' THEN LEFT(C7.C7_OP, 6)
                                          WHEN SUBSTRING(C1.C1_OP, 7, 2) = 'OS' THEN LEFT(C1.C1_OP, 6) END ORD) OP
                 OUTER APPLY (SELECT TOP 1 TRIM(J.TJ_ORDEM) OS FROM STJ010 J
                              WHERE J.D_E_L_E_T_ = ' ' AND J.TJ_FILIAL = C7.C7_FILIAL AND J.TJ_ORDEM = OP.ORD) OX
                 WHERE F1.D_E_L_E_T_ = ' ' AND F1.F1_FILIAL = E2.E2_FILIAL AND F1.F1_DOC = E2.E2_NUM
                   AND (F1.F1_PREFIXO = E2.E2_PREFIXO OR F1.F1_SERIE = E2.E2_PREFIXO)
                   AND F1.F1_FORNECE = E2.E2_FORNECE AND F1.F1_LOJA = E2.E2_LOJA
                   AND (C7.C7_CONTRA <> ' ' OR OX.OS IS NOT NULL)) PC
    LEFT JOIN PAG P ON P.E5_FILIAL = E2.E2_FILIAL AND P.E5_PREFIXO = E2.E2_PREFIXO AND P.E5_NUMERO = E2.E2_NUM
                   AND P.E5_PARCELA = E2.E2_PARCELA AND P.E5_TIPO = E2.E2_TIPO
                   AND P.E5_CLIFOR = E2.E2_FORNECE AND P.E5_LOJA = E2.E2_LOJA
    WHERE E2.D_E_L_E_T_ = ' '
      AND E2.E2_TIPO NOT LIKE '%-' AND E2.E2_TIPO NOT IN ('PA ', 'NDF', 'PR ')
      AND PC.PEDIDO IS NOT NULL
      AND (E2.E2_EMISSAO BETWEEN @INI AND @FIM
           OR E2.E2_VENCREA BETWEEN @INI AND @FIM
           OR P.PAGO IS NOT NULL)
)
SELECT
    TRIM(B.E2_FILIAL)                                              AS FILIAL,
    TRIM(B.E2_PREFIXO)                                             AS PREFIXO,
    TRIM(B.E2_NUM)                                                 AS NUMERO,
    TRIM(B.E2_PARCELA)                                             AS PARCELA,
    TRIM(B.E2_TIPO)                                                AS TIPO,
    TRIM(B.E2_FORNECE)                                             AS COD_FORNECEDOR,
    TRIM(B.E2_LOJA)                                                AS LOJA,
    COALESCE(NULLIF(F.NOME, ''), TRIM(B.E2_NOMFOR))                AS FORNECEDOR,
    F.CNPJ                                                         AS CNPJ,
    TRIM(B.E2_NATUREZ)                                             AS NATUREZA,
    N.DESCR                                                        AS NATUREZA_DESC,
    CASE WHEN B.CONTRATO IS NOT NULL AND B.OS IS NOT NULL THEN 'CONTRATO+OS'
         WHEN B.CONTRATO IS NOT NULL THEN 'CONTRATO' ELSE 'OS' END AS VINCULO,
    B.PEDIDO                                                       AS PEDIDO,
    B.QTD_PED                                                      AS QTD_PEDIDOS,
    CONVERT(VARCHAR(10), TRY_CONVERT(DATE, NULLIF(TRIM(B.EMIS_PED), '')), 103)   AS EMISSAO_PEDIDO,
    B.CONTRATO                                                     AS CONTRATO,
    B.OS                                                           AS OS,
    OSB.BEM                                                        AS OS_BEM,
    OSB.BEM_NOME                                                   AS OS_BEM_NOME,
    CONVERT(VARCHAR(10), TRY_CONVERT(DATE, NULLIF(TRIM(B.E2_EMISSAO), '')), 103) AS EMISSAO,
    CONVERT(VARCHAR(10), TRY_CONVERT(DATE, NULLIF(TRIM(B.E2_VENCREA), '')), 103) AS VENCIMENTO,
    CONVERT(VARCHAR(10), TRY_CONVERT(DATE, NULLIF(TRIM(B.PRIM_PAG), '')), 103)   AS PRIMEIRO_PAGTO_2026,
    CONVERT(VARCHAR(10), TRY_CONVERT(DATE, NULLIF(TRIM(B.ULT_PAG), '')), 103)    AS ULTIMO_PAGTO_2026,
    REPLACE(CONVERT(VARCHAR(30), CAST(B.E2_VALOR AS DECIMAL(18, 2))), '.', ',')               AS VALOR,
    REPLACE(CONVERT(VARCHAR(30), CAST(COALESCE(B.PAGO, 0) AS DECIMAL(18, 2))), '.', ',')      AS PAGO_2026,
    REPLACE(CONVERT(VARCHAR(30), CAST(COALESCE(B.JUROS, 0) + COALESCE(B.MULTA, 0) AS DECIMAL(18, 2))), '.', ',') AS JUROS_MULTA_2026,
    REPLACE(CONVERT(VARCHAR(30), CAST(COALESCE(B.DESCONTO, 0) AS DECIMAL(18, 2))), '.', ',')  AS DESCONTO_2026,
    REPLACE(CONVERT(VARCHAR(30), CAST(B.E2_SALDO AS DECIMAL(18, 2))), '.', ',')               AS SALDO_ATUAL,
    CASE WHEN B.E2_SALDO = 0 THEN 'PAGO'
         WHEN B.E2_SALDO < B.E2_VALOR THEN 'PARCIAL'
         WHEN B.E2_VENCREA < CONVERT(CHAR(8), GETDATE(), 112) THEN 'VENCIDO'
         ELSE 'A VENCER' END                                       AS SITUACAO,
    CASE WHEN B.E2_SALDO > 0 AND B.E2_VENCREA < CONVERT(CHAR(8), GETDATE(), 112)
         THEN DATEDIFF(DAY, TRY_CONVERT(DATE, B.E2_VENCREA), CAST(GETDATE() AS DATE)) END AS DIAS_ATRASO,
    TRIM(B.E2_HIST)                                                AS HISTORICO,
    TRIM(B.E2_ORIGEM)                                              AS ORIGEM,
    B.REC                                                          AS RECNO_SE2
FROM BASE B
OUTER APPLY (SELECT TOP 1 TRIM(A2.A2_NOME) NOME, TRIM(A2.A2_CGC) CNPJ FROM SA2010 A2
             WHERE A2.D_E_L_E_T_ = ' ' AND A2.A2_COD = B.E2_FORNECE AND A2.A2_LOJA = B.E2_LOJA) F
OUTER APPLY (SELECT TOP 1 TRIM(ED.ED_DESCRIC) DESCR FROM SED010 ED
             WHERE ED.D_E_L_E_T_ = ' ' AND ED.ED_CODIGO = B.E2_NATUREZ) N
OUTER APPLY (SELECT TOP 1 TRIM(J.TJ_CODBEM) BEM,
                    (SELECT TOP 1 TRIM(T9.T9_NOME) FROM ST9010 T9
                     WHERE T9.D_E_L_E_T_ = ' ' AND T9.T9_CODBEM = J.TJ_CODBEM) BEM_NOME
             FROM STJ010 J
             WHERE J.D_E_L_E_T_ = ' ' AND J.TJ_FILIAL = B.E2_FILIAL AND J.TJ_ORDEM = B.OS) OSB
ORDER BY B.E2_VENCREA, B.E2_FILIAL, B.E2_NUM, B.E2_PARCELA;
