/* =============================================================================
   Base da DRE de custos 2026 - pagamentos de titulos com pedido de CONTRATO e/ou OS
   Banco: SQL Server (2017+), empresa 01 (tabelas com sufixo 010).
   Uma linha por baixa (pagamento) feita em 2026.

   Filtros aplicados (todos obrigatorios):
     1. Titulo -> nota de entrada -> pedido de compra com contrato (C7_CONTRA) e/ou
        OS da manutencao (C7_OP / C1_OP = numero da OS + 'OS001'), igual a API BI.
     2. Sem financiamentos e emprestimos: naturezas de capital de giro, emprestimo,
        FCO, consorcio, BNDES, mutuo, juros/encargos de credito, leasing, FINAME, e
        compras de veiculos/caminhoes/maquinas/equipamentos pagas a bancos e financeiras.
     3. So saida de caixa: sem baixa por liquidacao (LIQ), fatura (FAT) e compensacao (CP/CMP),
        sem baixas estornadas e sem baixas canceladas.
     4. Pagamento entre 01/01/2026 e 31/12/2026.

   Exportar (SSMS): execute, clique com o botao direito na grade > "Save Results As..." > CSV.
   Para sair com cabecalho: Tools > Options > Query Results > SQL Server > Results to Grid >
   marque "Include column headers when copying or saving the results" e abra uma nova janela de query.
   Os textos ja saem sem virgula e sem ponto e virgula, para o CSV nao quebrar.
   ============================================================================= */
SET NOCOUNT ON;

DECLARE @INI CHAR(8) = '20260101';
DECLARE @FIM CHAR(8) = '20261231';

SELECT
    E2.R_E_C_N_O_                                          AS REC,
    TRIM(E2.E2_FILIAL)                                     AS FILIAL,
    TRIM(E2.E2_PREFIXO)                                    AS PREFIXO,
    TRIM(E2.E2_NUM)                                        AS NUM,
    TRIM(E2.E2_PARCELA)                                    AS PARCELA,
    TRIM(E2.E2_TIPO)                                       AS TIPO,
    TRIM(E2.E2_FORNECE)                                    AS FORNECE,
    TRIM(E2.E2_LOJA)                                       AS LOJA,
    REPLACE(REPLACE(COALESCE(NULLIF(F.NOME, ''), TRIM(E2.E2_NOMFOR)), ',', ' '), ';', ' ') AS FORNECEDOR,
    TRIM(E2.E2_NATUREZ)                                    AS NATUREZA,
    REPLACE(REPLACE(N.DESCR, ',', ' '), ';', ' ')          AS NATUREZA_DESC,
    E2.E2_EMISSAO                                          AS EMISSAO,
    E2.E2_VENCREA                                          AS VENCREA,
    E5.E5_DATA                                             AS PAGO_EM,
    E5.E5_VALOR                                            AS PAGO,
    E5.E5_VLJUROS                                          AS JUROS,
    E5.E5_VLMULTA                                          AS MULTA,
    E5.E5_VLDESCO                                          AS DESCONTO,
    TRIM(E5.E5_TIPODOC)                                    AS TIPODOC,
    TRIM(E5.E5_MOTBX)                                      AS MOTBX,
    PC.PEDIDO                                              AS PEDIDO,
    PC.CONTRATO                                            AS CONTRATO,
    PC.OS                                                  AS OS,
    CASE WHEN PC.CONTRATO IS NOT NULL AND PC.OS IS NOT NULL THEN 'CONTRATO+OS'
         WHEN PC.CONTRATO IS NOT NULL THEN 'CONTRATO' ELSE 'OS' END AS VINCULO
FROM SE5010 E5
JOIN SE2010 E2
  ON E2.D_E_L_E_T_ = ' ' AND E2.E2_FILIAL = E5.E5_FILIAL AND E2.E2_PREFIXO = E5.E5_PREFIXO
 AND E2.E2_NUM = E5.E5_NUMERO AND E2.E2_PARCELA = E5.E5_PARCELA AND E2.E2_TIPO = E5.E5_TIPO
 AND E2.E2_FORNECE = E5.E5_CLIFOR AND E2.E2_LOJA = E5.E5_LOJA
OUTER APPLY (SELECT TOP 1 TRIM(A2.A2_NOME) NOME FROM SA2010 A2
             WHERE A2.D_E_L_E_T_ = ' ' AND A2.A2_COD = E2.E2_FORNECE AND A2.A2_LOJA = E2.E2_LOJA) F
OUTER APPLY (SELECT TOP 1 UPPER(TRIM(ED.ED_DESCRIC)) DESCR FROM SED010 ED
             WHERE ED.D_E_L_E_T_ = ' ' AND ED.ED_CODIGO = E2.E2_NATUREZ) N
-- 1. vinculo titulo -> nota -> pedido com contrato e/ou OS
OUTER APPLY (SELECT MIN(TRIM(C7.C7_NUM)) PEDIDO, MAX(NULLIF(TRIM(C7.C7_CONTRA), '')) CONTRATO, MAX(OX.OS) OS
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
WHERE E5.D_E_L_E_T_ = ' ' AND E5.E5_RECPAG = 'P' AND E5.E5_SITUACA <> 'C'
  AND E5.E5_DATA BETWEEN @INI AND @FIM
  AND PC.PEDIDO IS NOT NULL
  -- 3. so saida de caixa
  AND E5.E5_TIPODOC IN ('VL', 'BA', 'PA')
  AND E5.E5_MOTBX NOT IN ('LIQ', 'FAT', 'CMP')
  AND E2.E2_TIPO NOT LIKE '%-' AND E2.E2_TIPO NOT IN ('PR ', 'NDF')
  AND NOT EXISTS (SELECT 1 FROM SE5010 X
                  WHERE X.D_E_L_E_T_ = ' ' AND X.E5_TIPODOC = 'ES'
                    AND X.E5_FILIAL = E5.E5_FILIAL AND X.E5_PREFIXO = E5.E5_PREFIXO
                    AND X.E5_NUMERO = E5.E5_NUMERO AND X.E5_PARCELA = E5.E5_PARCELA
                    AND X.E5_TIPO = E5.E5_TIPO AND X.E5_CLIFOR = E5.E5_CLIFOR
                    AND X.E5_LOJA = E5.E5_LOJA AND X.E5_SEQ = E5.E5_SEQ)
  -- 2. sem financiamentos e emprestimos
  AND E2.E2_NATUREZ NOT IN ('311103', '268002', '268006', '350001', '350002', '350003', '351001',
                            '352001', '353001', '353003', '268003', '111006')
  AND COALESCE(N.DESCR, '') NOT LIKE '%EMPREST%'
  AND COALESCE(N.DESCR, '') NOT LIKE '%FINANCIAMENT%'
  AND COALESCE(N.DESCR, '') NOT LIKE '%CAPITAL DE GIRO%'
  AND COALESCE(N.DESCR, '') NOT LIKE '%CONSORCIO%'
  AND COALESCE(N.DESCR, '') NOT LIKE '%LEASING%'
  AND COALESCE(N.DESCR, '') NOT LIKE '%FINAME%'
  AND COALESCE(N.DESCR, '') NOT LIKE '%FCO %'
  AND COALESCE(N.DESCR, '') NOT LIKE '%MUTUO%'
  AND COALESCE(N.DESCR, '') NOT LIKE '%BNDES%'
  AND COALESCE(N.DESCR, '') NOT LIKE '%LIMITE DE CREDITO%'
  AND COALESCE(N.DESCR, '') NOT LIKE '%OPERACOES FINANCEIRAS%'
  AND NOT (E2.E2_NATUREZ IN ('342001', '342002', '341002', '341003')
           AND (UPPER(COALESCE(F.NOME, E2.E2_NOMFOR)) LIKE '%BANCO%'
             OR UPPER(COALESCE(F.NOME, E2.E2_NOMFOR)) LIKE '%FINANCIAMENTO%'
             OR UPPER(COALESCE(F.NOME, E2.E2_NOMFOR)) LIKE '%LEASING%'
             OR UPPER(COALESCE(F.NOME, E2.E2_NOMFOR)) LIKE '%CREDITO%'))
ORDER BY E5.E5_DATA, E2.E2_FILIAL, E2.E2_NUM;
