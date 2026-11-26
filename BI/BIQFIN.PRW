#include 'protheus.ch'

/*/{Protheus.doc} BIQFIN
Consultas do BI - 1. Contas a pagar / pagamentos (FIN) e 2. Fila de aprovacao (APR).
Chamado por APIBI.PRW. Retorna {cSql, cOrdem} ou uma string com a mensagem de erro.

Conversao Oracle -> SQL Server aplicada:
  FETCH FIRST 1 ROWS ONLY -> TOP 1 | NVL -> COALESCE(NULLIF(x,''),y) | FROM DUAL -> SELECT sem FROM
  LISTAGG(DISTINCT) -> STRING_AGG sobre DISTINCT | DBMS_LOB/UTL_RAW -> CAST VARBINARY/VARCHAR
  ROWNUM = 1 -> TOP 1 | TO_CHAR(timestamp) -> CONVERT(VARCHAR(19), x, 126) | WITH -> tabela derivada
  TRIM(x) IS NULL -> TRIM(x) = '' (no SQL Server TRIM de campo vazio e '' e nao NULL)

@author Thiago Sales - Quebec Ambiental
@since 2026-11-11
/*/
User Function BIQFIN(cId, oPar)

	Do Case
	Case cId == "FIN01" ; Return qFIN01(oPar)
	Case cId == "FIN02" ; Return qFIN02(oPar)
	Case cId == "FIN03" ; Return qFIN03(oPar)
	Case cId == "FIN04" ; Return qFIN04(oPar)
	Case cId == "FIN05" ; Return qFIN05(oPar)
	Case cId == "FIN06" ; Return qFIN06(oPar)
	Case cId == "APR01" ; Return qAPR01(oPar)
	Case cId == "APR02" ; Return qAPR02(oPar)
	Case cId == "APR03" ; Return qAPR03(oPar)
	EndCase

Return Nil

Static Function xT(cAlias)
Return RetSqlName(cAlias)

Static Function xQ(cVal)
Return "'" + cVal + "'"

//-----------------------------------------------------------------------------
// Colunas e OUTER APPLYs comuns as consultas de titulo (FIN01 e FIN02)
//-----------------------------------------------------------------------------
Static Function xColE2()
	Local cQ := ""

	cQ += "E2.R_E_C_N_O_ REC, TRIM(E2.E2_FILIAL) FILIAL, TRIM(E2.E2_PREFIXO) PREFIXO, TRIM(E2.E2_NUM) NUM, "
	cQ += "TRIM(E2.E2_PARCELA) PARCELA, TRIM(E2.E2_TIPO) TIPO, TRIM(E2.E2_FORNECE) FORNECE, TRIM(E2.E2_LOJA) LOJA, "
	cQ += "COALESCE(NULLIF(F.NOME, ''), TRIM(E2.E2_NOMFOR)) FORNECEDOR, F.CNPJ, "
	cQ += "TRIM(E2.E2_NATUREZ) NATUREZA, N.DESCR NATDESC, "
	cQ += "E2.E2_EMISSAO EMISSAO, E2.E2_EMIS1 EMIS1, E2.E2_VENCTO VENCTO, E2.E2_VENCREA VENCREA, E2.E2_VALOR VALOR, E2.E2_SALDO SALDO, "
	cQ += "TRIM(E2.E2_HIST) HIST, TRIM(E2.E2_NUMBOR) NUMBOR, B.MODELO, "
	cQ += "COALESCE(NULLIF(TRIM(E2.E2_LINDIG), ''), TRIM(E2.E2_CODBAR)) LINDIG, TRIM(E2.E2_ORIGEM) ORIGEM, "
	// titulo gerado direto pela medicao do contrato (sem pedido/NF): liga o titulo a medicao
	cQ += U_BICOL("SE2", "E2_MDCONTR", "TRIM(E2.E2_MDCONTR)") + " MDCONTR, "
	cQ += U_BICOL("SE2", "E2_MEDNUME", "TRIM(E2.E2_MEDNUME)") + " MEDNUME, "
	cQ += "CCP.CC CC, (SELECT MAX(TRIM(CT.CTT_DESC01)) FROM " + xT("CTT") + " CT "
	cQ += "  WHERE CT.D_E_L_E_T_ = ' ' AND TRIM(CT.CTT_CUSTO) = CCP.CC) CC_DESC "

Return cQ

//-----------------------------------------------------------------------------
// Rateio do titulo (alias E2) por centro de custo, na ordem de prioridade:
// E2_CCUSTO > itens da NF (SD1) > folha (RC1) > medicao (CNE) > planilha do contrato (CNB).
// Devolve linhas (CC, V). Usado no FIN03 e no CC principal do FIN01/FIN02.
//-----------------------------------------------------------------------------
Static Function xRatCC()
	Local cQ := ""

	cQ += "  SELECT E2.E2_CCUSTO CC, E2.E2_VALOR V WHERE E2.E2_CCUSTO <> ' ' "
	cQ += "  UNION ALL "
	cQ += "  SELECT D.D1_CC, D.D1_TOTAL FROM " + xT("SD1") + " D "
	cQ += "   WHERE E2.E2_CCUSTO = ' ' AND D.D_E_L_E_T_ = ' ' AND D.D1_CC <> ' ' "
	cQ += "     AND D.D1_FILIAL = E2.E2_FILIAL AND D.D1_DOC = E2.E2_NUM AND D.D1_SERIE = E2.E2_PREFIXO "
	cQ += "     AND D.D1_FORNECE = E2.E2_FORNECE AND D.D1_LOJA = E2.E2_LOJA "
	cQ += "  UNION ALL "
	cQ += "  SELECT R.RC1_CC, R.RC1_VALOR FROM " + xT("RC1") + " R "
	cQ += "   WHERE E2.E2_CCUSTO = ' ' AND E2.E2_PREFIXO = 'GPE' AND R.D_E_L_E_T_ = ' ' AND R.RC1_CC <> ' ' "
	cQ += "     AND R.RC1_FILTIT = E2.E2_FILIAL AND R.RC1_PREFIX = E2.E2_PREFIXO AND R.RC1_NUMTIT = E2.E2_NUM "
	cQ += "     AND R.RC1_TIPO = E2.E2_TIPO AND R.RC1_PARC = E2.E2_PARCELA "
	cQ += "  UNION ALL "
	cQ += "  SELECT C.CNE_CC, C.CNE_VLTOT FROM " + xT("CNE") + " C "
	cQ += "   WHERE E2.E2_CCUSTO = ' ' AND E2.E2_MEDNUME <> ' ' AND C.D_E_L_E_T_ = ' ' AND C.CNE_CC <> ' ' "
	cQ += "     AND C.CNE_CONTRA = E2.E2_MDCONTR AND C.CNE_NUMMED = E2.E2_MEDNUME "
	cQ += "  UNION ALL "
	cQ += "  SELECT P.CNB_CC, P.CNB_VLTOT FROM " + xT("CNB") + " P "
	cQ += "   WHERE E2.E2_CCUSTO = ' ' AND E2.E2_MEDNUME = ' ' AND E2.E2_MDCONTR <> ' ' AND P.D_E_L_E_T_ = ' ' "
	cQ += "     AND P.CNB_CC <> ' ' AND P.CNB_CONTRA = E2.E2_MDCONTR AND P.CNB_NUMERO = E2.E2_MDPLANI "
	cQ += "     AND P.CNB_REVISA = E2.E2_MDREVIS "

Return cQ

Static Function xAplE2()
	Local cQ := ""

	cQ += " OUTER APPLY (SELECT TOP 1 TRIM(A2.A2_NOME) NOME, TRIM(A2.A2_CGC) CNPJ FROM " + xT("SA2") + " A2 "
	cQ += "   WHERE A2.D_E_L_E_T_ = ' ' AND A2.A2_COD = E2.E2_FORNECE AND A2.A2_LOJA = E2.E2_LOJA) F "
	cQ += " OUTER APPLY (SELECT TOP 1 TRIM(ED.ED_DESCRIC) DESCR FROM " + xT("SED") + " ED "
	cQ += "   WHERE ED.D_E_L_E_T_ = ' ' AND ED.ED_CODIGO = E2.E2_NATUREZ) N "
	cQ += " OUTER APPLY (SELECT TOP 1 TRIM(EA.EA_MODELO) MODELO FROM " + xT("SEA") + " EA "
	cQ += "   WHERE EA.D_E_L_E_T_ = ' ' AND EA.EA_CART = 'P' AND E2.E2_NUMBOR <> ' ' "
	cQ += "     AND EA.EA_NUMBOR = E2.E2_NUMBOR AND EA.EA_FILIAL = E2.E2_FILIAL "
	cQ += "     AND EA.EA_PREFIXO = E2.E2_PREFIXO AND EA.EA_NUM = E2.E2_NUM AND EA.EA_PARCELA = E2.E2_PARCELA "
	cQ += "     AND EA.EA_TIPO = E2.E2_TIPO AND EA.EA_FORNECE = E2.E2_FORNECE AND EA.EA_LOJA = E2.E2_LOJA) B "
	// CC principal do titulo: o de maior valor no rateio (o titulo inteiro fica nesse CC no BI)
	cQ += " OUTER APPLY (SELECT TOP 1 TRIM(X.CC) CC FROM ( " + xRatCC() + ") X "
	cQ += "   GROUP BY TRIM(X.CC) ORDER BY SUM(X.V) DESC, TRIM(X.CC)) CCP "

Return cQ

//-----------------------------------------------------------------------------
// Vinculo titulo -> nota de entrada -> pedido de compra com contrato e/ou OS
// Titulo (SE2) -> NF (SF1: filial, numero, prefixo/serie, fornecedor) -> itens (SD1)
// -> pedido (SC7 pelo D1_PEDIDO/D1_ITEMPC). O pedido conta se tiver:
//   contrato: C7_CONTRA preenchido (pedido gerado por medicao do GCT)
//   OS      : C7_OP (ou C1_OP da solicitacao) = TJ_ORDEM + 'OS' + '001' (padrao MNT)
// Titulos sem pedido (financiamentos, emprestimos, impostos, provisorios,
// medicoes direto no financeiro) ficam de fora.
//-----------------------------------------------------------------------------
Static Function xPedE2()
	Local cQ := ""

	cQ += " OUTER APPLY (SELECT MIN(TRIM(C7.C7_NUM)) PEDIDO, MAX(NULLIF(TRIM(C7.C7_CONTRA), '')) CONTRATO, MAX(OX.OS) OS "
	cQ += "   FROM " + xT("SF1") + " F1 "
	cQ += "   JOIN " + xT("SD1") + " D ON D.D_E_L_E_T_ = ' ' AND D.D1_FILIAL = F1.F1_FILIAL AND D.D1_DOC = F1.F1_DOC "
	cQ += "    AND D.D1_SERIE = F1.F1_SERIE AND D.D1_FORNECE = F1.F1_FORNECE AND D.D1_LOJA = F1.F1_LOJA AND D.D1_PEDIDO <> ' ' "
	cQ += "   JOIN " + xT("SC7") + " C7 ON C7.D_E_L_E_T_ = ' ' AND C7.C7_FILIAL = D.D1_FILIAL "
	cQ += "    AND C7.C7_NUM = D.D1_PEDIDO AND C7.C7_ITEM = D.D1_ITEMPC "
	cQ += "   LEFT JOIN " + xT("SC1") + " C1 ON C1.D_E_L_E_T_ = ' ' AND C1.C1_FILIAL = C7.C7_FILIAL "
	cQ += "    AND C1.C1_NUM = C7.C7_NUMSC AND C1.C1_ITEM = C7.C7_ITEMSC AND C7.C7_NUMSC <> ' ' "
	cQ += "   CROSS APPLY (SELECT CASE "
	cQ += "     WHEN SUBSTRING(C7.C7_OP, 7, 2) = 'OS' THEN LEFT(C7.C7_OP, 6) "
	cQ += "     WHEN SUBSTRING(C1.C1_OP, 7, 2) = 'OS' THEN LEFT(C1.C1_OP, 6) END ORD) OP "
	cQ += "   OUTER APPLY (SELECT TOP 1 TRIM(J.TJ_ORDEM) OS FROM " + xT("STJ") + " J "
	cQ += "     WHERE J.D_E_L_E_T_ = ' ' AND J.TJ_FILIAL = C7.C7_FILIAL AND J.TJ_ORDEM = OP.ORD) OX "
	cQ += "   WHERE F1.D_E_L_E_T_ = ' ' AND F1.F1_FILIAL = E2.E2_FILIAL AND F1.F1_DOC = E2.E2_NUM "
	cQ += "     AND (F1.F1_PREFIXO = E2.E2_PREFIXO OR F1.F1_SERIE = E2.E2_PREFIXO) "
	cQ += "     AND F1.F1_FORNECE = E2.E2_FORNECE AND F1.F1_LOJA = E2.E2_LOJA "
	cQ += "     AND (C7.C7_CONTRA <> ' ' OR OX.OS IS NOT NULL)) PC "

Return cQ

Static Function xColPC()
	Local cQ := ""

	cQ += ", PC.PEDIDO, PC.CONTRATO, PC.OS, "
	cQ += "CASE WHEN PC.CONTRATO IS NOT NULL AND PC.OS IS NOT NULL THEN 'CONTRATO+OS' "
	cQ += "WHEN PC.CONTRATO IS NOT NULL THEN 'CONTRATO' WHEN PC.OS IS NOT NULL THEN 'OS' ELSE '' END VINCULO "

Return cQ

// Filtro do escopo: CONTRATO_OS (padrao) so titulos com pedido de contrato e/ou OS; TODOS sem filtro
// de pedido. Em qualquer escopo os financiamentos, emprestimos e multas ficam de fora (xFilFin).
Static Function xFilPC(oPar)
	Local cQ := ""

	If !(oPar["escopo"] == "TODOS")
		cQ += "AND PC.PEDIDO IS NOT NULL "
	EndIf
	cQ += xFilFin()

Return cQ

//-----------------------------------------------------------------------------
// Exclui do FIN01/FIN02 (sempre, independente do escopo):
//  1. financiamentos e emprestimos - mesmas regras de BI/scripts/mapa_dre.py
//     (NAT_FIN, RE_FIN, NAT_BEM + RE_BANCO); manter as tres listas iguais:
//     a) natureza da lista de financiamento/emprestimo;
//     b) descricao da natureza com EMPREST, FINANCIAMENT, CAPITAL DE GIRO, CONSORCIO...;
//     c) natureza de compra de bem (veiculo, caminhao, maquina) paga a banco/financeira.
//  2. multas: natureza com MULTA na descricao (ex.: MULTAS DE TRANSITO). A multa rescisoria
//     do FGTS e encargo trabalhista e continua no endpoint.
// Usa os OUTER APPLY N (descricao da natureza) e F (nome do fornecedor) de xAplE2().
//-----------------------------------------------------------------------------
Static Function xFilFin()
	Local cNat   := "RTRIM(E2.E2_NATUREZ)"
	Local cDesc  := "(' ' + UPPER(COALESCE(N.DESCR, '')) + ' ')"
	Local cForn  := "(' ' + UPPER(COALESCE(NULLIF(F.NOME, ''), TRIM(E2.E2_NOMFOR), '')) + ' ')"
	Local aNatFin := {"111006", "268002", "268003", "268006", "311103", "350001", "350002", "350003", ;
	                  "351001", "352001", "353001", "353003"}
	Local aNatBem := {"341002", "341003", "342001", "342002"}
	Local aReFin  := {"EMPREST", "FINANCIAMENT", "CAPITAL DE GIRO", "CONSORCIO", "LEASING", "FINAME", ;
	                  " FCO ", "MUTUO", "BNDES", "LIMITE DE CREDITO", "OPERACOES FINANCEIRAS", "ABERTURA CREDITO"}
	Local aBanco  := {" BANCO ", " BANK ", "FINANCIAMENTOS", "LEASING", "CAIXA ECONOMICA", "SANTANDER", "ITAU", ;
	                  "BRADESCO S", "BNDES", "SICOOB", "SICREDI", "ADMINISTRADORA DE CONSORCIOS", "CREDITO", ;
	                  "DAYCOVAL", "SOFISA"}
	Local cQ := ""

	cQ += "AND NOT ( "
	cQ += cNat + " IN (" + xLista(aNatFin) + ") "
	cQ += "OR " + xLike(cDesc, aReFin) + " "
	cQ += "OR (" + cNat + " IN (" + xLista(aNatBem) + ") AND " + xLike(cForn, aBanco) + ") "
	cQ += "OR (" + cDesc + " LIKE '%MULTA%' AND " + cDesc + " NOT LIKE '%FGTS%' "
	cQ += "    AND " + cDesc + " NOT LIKE '%RESCIS%' AND " + cDesc + " NOT LIKE '%RECIS%') "
	cQ += ") "

Return cQ

// 'a', 'b', 'c'
Static Function xLista(aVal)
	Local cRet := ""
	Local nI   := 0

	For nI := 1 To Len(aVal)
		cRet += iif(nI > 1, ", ", "") + xQ(aVal[nI])
	Next nI

Return cRet

// (cExp LIKE '%a%' OR cExp LIKE '%b%' ...)
Static Function xLike(cExp, aVal)
	Local cRet := ""
	Local nI   := 0

	For nI := 1 To Len(aVal)
		cRet += iif(nI > 1, " OR ", "") + cExp + " LIKE " + xQ("%" + aVal[nI] + "%")
	Next nI

Return "(" + cRet + ")"

//-----------------------------------------------------------------------------
// FIN01 - titulos a pagar em aberto (escopo=CONTRATO_OS: so com pedido de contrato e/ou OS)
//-----------------------------------------------------------------------------
Static Function qFIN01(oPar)
	Local cQ := ""

	cQ += "SELECT " + xColE2() + xColPC()
	cQ += "FROM " + xT("SE2") + " E2 " + xAplE2() + xPedE2()
	cQ += "WHERE E2.D_E_L_E_T_ = ' ' AND E2.E2_SALDO > 0 " + xFilPC(oPar)
	cQ += "AND E2.E2_TIPO NOT LIKE '%-' "
	cQ += "AND E2.E2_TIPO NOT IN ('PA ', 'NDF')"

Return {cQ, "E2.R_E_C_N_O_"}

//-----------------------------------------------------------------------------
// FIN02 - pagamentos (baixas SE5) no periodo
//-----------------------------------------------------------------------------
Static Function qFIN02(oPar)
	Local cQ := ""

	cQ += "SELECT " + xColE2() + ", "
	cQ += "E5.R_E_C_N_O_ E5_REC, TRIM(E5.E5_SEQ) SEQ, E5.E5_DATA PAGO_EM, E5.E5_VALOR PAGO, "
	cQ += "TRIM(E5.E5_TIPODOC) TIPODOC, TRIM(E5.E5_MOTBX) MOTBX, "
	cQ += "TRIM(E5.E5_BANCO) BANCO, TRIM(E5.E5_AGENCIA) AGENCIA, TRIM(E5.E5_CONTA) CONTA, BC.NOME BANCO_NOME, "
	cQ += "E5.E5_VLJUROS JUROS, E5.E5_VLMULTA MULTA, E5.E5_VLDESCO DESCONTO" + xColPC()
	cQ += "FROM " + xT("SE5") + " E5 "
	cQ += "JOIN " + xT("SE2") + " E2 "
	cQ += "  ON E2.D_E_L_E_T_ = ' ' AND E2.E2_FILIAL = E5.E5_FILIAL AND E2.E2_PREFIXO = E5.E5_PREFIXO "
	cQ += " AND E2.E2_NUM = E5.E5_NUMERO AND E2.E2_PARCELA = E5.E5_PARCELA AND E2.E2_TIPO = E5.E5_TIPO "
	cQ += " AND E2.E2_FORNECE = E5.E5_CLIFOR AND E2.E2_LOJA = E5.E5_LOJA "
	cQ += xAplE2() + xPedE2()
	cQ += " OUTER APPLY (SELECT TOP 1 TRIM(A6.A6_NOME) NOME FROM " + xT("SA6") + " A6 "
	cQ += "   WHERE A6.D_E_L_E_T_ = ' ' AND A6.A6_COD = E5.E5_BANCO AND A6.A6_AGENCIA = E5.E5_AGENCIA "
	cQ += "     AND A6.A6_NUMCON = E5.E5_CONTA) BC "
	cQ += "WHERE E5.D_E_L_E_T_ = ' ' AND E5.E5_RECPAG = 'P' AND E5.E5_SITUACA <> 'C' " + xFilPC(oPar)
	cQ += "AND E5.E5_TIPODOC IN ('VL', 'BA', 'CP', 'PA') "
	cQ += "AND E5.E5_DATA BETWEEN " + xQ(oPar["de"]) + " AND " + xQ(oPar["ate"]) + " "
	cQ += "AND E2.E2_TIPO NOT LIKE '%-' AND E2.E2_TIPO <> 'PR ' "
	// compensacao: so o lado da divida (a NDF/PA compensada grava a mesma baixa)
	cQ += "AND NOT (E2.E2_TIPO IN ('NDF', 'PA ') AND (E5.E5_MOTBX = 'CMP' OR E5.E5_TIPODOC = 'CP')) "
	cQ += "AND NOT EXISTS (SELECT 1 FROM " + xT("SE5") + " X "
	cQ += "  WHERE X.D_E_L_E_T_ = ' ' AND X.E5_TIPODOC = 'ES' "
	cQ += "    AND X.E5_FILIAL = E5.E5_FILIAL AND X.E5_PREFIXO = E5.E5_PREFIXO "
	cQ += "    AND X.E5_NUMERO = E5.E5_NUMERO AND X.E5_PARCELA = E5.E5_PARCELA "
	cQ += "    AND X.E5_TIPO = E5.E5_TIPO AND X.E5_CLIFOR = E5.E5_CLIFOR "
	cQ += "    AND X.E5_LOJA = E5.E5_LOJA AND X.E5_SEQ = E5.E5_SEQ)"

Return {cQ, "E5.E5_DATA, E5.R_E_C_N_O_"}

//-----------------------------------------------------------------------------
// FIN03 - rateio por centro de custo dos titulos (recs = R_E_C_N_O_ da SE2)
//-----------------------------------------------------------------------------
Static Function qFIN03(oPar)
	Local cQ := ""

	cQ += "SELECT E2.R_E_C_N_O_ REC, TRIM(X.CC) CC, SUM(X.V) V "
	cQ += "FROM " + xT("SE2") + " E2 "
	cQ += "CROSS APPLY ( " + xRatCC() + ") X "
	cQ += "WHERE E2.R_E_C_N_O_ IN (" + oPar["recs"] + ") "
	cQ += "GROUP BY E2.R_E_C_N_O_, TRIM(X.CC)"

Return {cQ, "1, 2"}

//-----------------------------------------------------------------------------
// FIN04 - centros de custo
//-----------------------------------------------------------------------------
Static Function qFIN04(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(CTT_CUSTO) CC, MAX(TRIM(CTT_DESC01)) DESCR FROM " + xT("CTT") + " "
	cQ += "WHERE D_E_L_E_T_ = ' ' GROUP BY TRIM(CTT_CUSTO)"

Return {cQ, "1"}

//-----------------------------------------------------------------------------
// FIN05 - faturamento mensal por filial (receita para a DRE)
// VENDA    : itens de nota de saida normal (SD2 tipo N) com TES que gera duplicata
// DEVOLUCAO: devolucoes de venda (SD1 tipo D) com TES que gera duplicata, pela data de digitacao
// Impostos destacados na nota: ICMS, ISS, PIS (VALIMP6), COFINS (VALIMP5) e IPI.
//-----------------------------------------------------------------------------
Static Function qFIN05(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(D2.D2_FILIAL) FIL, LEFT(D2.D2_EMISSAO, 6) MES, 'VENDA' TIPO, "
	cQ += "SUM(D2.D2_VALBRUT) BRUTO, SUM(D2.D2_VALICM) ICMS, SUM(D2.D2_VALISS) ISS, "
	cQ += "SUM(D2.D2_VALIMP6) PIS, SUM(D2.D2_VALIMP5) COFINS, SUM(D2.D2_VALIPI) IPI, "
	cQ += "COUNT(DISTINCT CONCAT(D2.D2_SERIE, D2.D2_DOC)) NOTAS "
	cQ += "FROM " + xT("SD2") + " D2 "
	cQ += "WHERE D2.D_E_L_E_T_ = ' ' AND D2.D2_TIPO = 'N' "
	cQ += "AND D2.D2_EMISSAO BETWEEN " + xQ(oPar["de"]) + " AND " + xQ(oPar["ate"]) + " "
	cQ += "AND EXISTS (SELECT 1 FROM " + xT("SF4") + " F4 WHERE F4.D_E_L_E_T_ = ' ' "
	cQ += "  AND F4.F4_CODIGO = D2.D2_TES AND F4.F4_DUPLIC = 'S') "
	cQ += "GROUP BY TRIM(D2.D2_FILIAL), LEFT(D2.D2_EMISSAO, 6) "
	cQ += "UNION ALL "
	cQ += "SELECT TRIM(D1.D1_FILIAL), LEFT(D1.D1_DTDIGIT, 6), 'DEVOLUCAO', "
	cQ += "SUM(D1.D1_TOTAL + D1.D1_VALIPI - D1.D1_VALDESC), SUM(D1.D1_VALICM), SUM(D1.D1_VALISS), "
	cQ += "SUM(D1.D1_VALIMP6), SUM(D1.D1_VALIMP5), SUM(D1.D1_VALIPI), "
	cQ += "COUNT(DISTINCT CONCAT(D1.D1_SERIE, D1.D1_DOC)) "
	cQ += "FROM " + xT("SD1") + " D1 "
	cQ += "WHERE D1.D_E_L_E_T_ = ' ' AND D1.D1_TIPO = 'D' "
	cQ += "AND D1.D1_DTDIGIT BETWEEN " + xQ(oPar["de"]) + " AND " + xQ(oPar["ate"]) + " "
	cQ += "AND EXISTS (SELECT 1 FROM " + xT("SF4") + " F4 WHERE F4.D_E_L_E_T_ = ' ' "
	cQ += "  AND F4.F4_CODIGO = D1.D1_TES AND F4.F4_DUPLIC = 'S') "
	cQ += "GROUP BY TRIM(D1.D1_FILIAL), LEFT(D1.D1_DTDIGIT, 6)"

Return {cQ, "2, 1, 3"}

//-----------------------------------------------------------------------------
// FIN06 - filiais do grupo de empresas logado, com o nome (cadastro de empresas).
// O cadastro nao fica numa tabela do banco, entao a lista e montada aqui e
// devolvida como VALUES. Se a leitura falhar, devolve vazio (o BI usa o codigo).
//-----------------------------------------------------------------------------
Static Function qFIN06(oPar)
	Local aFil  := {}
	Local cVal  := ""
	Local cNome := ""
	Local nI    := 0
	Local bOld  := ErrorBlock({|oErr| Break(oErr)})

	Begin Sequence
		aFil := FWAllFilial(,, cEmpAnt, .F.)
		For nI := 1 To Len(aFil)
			cNome := AllTrim(FWFilialName(cEmpAnt, aFil[nI], 1))
			cVal  += iif(Empty(cVal), "", ", ") + "(" + xQ(AllTrim(aFil[nI])) + ", " + xQ(StrTran(cNome, "'", "''")) + ")"
		Next nI
	Recover
		cVal := ""
	End Sequence
	ErrorBlock(bOld)

	If Empty(cVal)
		Return {"SELECT CAST('' AS VARCHAR(20)) FILIAL, CAST('' AS VARCHAR(60)) NOME WHERE 1 = 0", "1"}
	EndIf

Return {"SELECT FILIAL, NOME FROM (VALUES " + cVal + ") T(FILIAL, NOME)", "1"}

//-----------------------------------------------------------------------------
// Filtro "pedido com alcada pendente" (SCR status 02) usado em APR02 e APR03
//-----------------------------------------------------------------------------
Static Function xPendSCR()
	Local cQ := ""

	cQ += "EXISTS (SELECT 1 FROM " + xT("SCR") + " CR "
	cQ += "  WHERE CR.D_E_L_E_T_ = ' ' AND CR.CR_STATUS = '02' AND CR.CR_TIPO IN ('PC', 'IP') "
	cQ += "    AND CR.CR_FILIAL = C7.C7_FILIAL AND TRIM(CR.CR_NUM) = C7.C7_NUM) "

Return cQ

//-----------------------------------------------------------------------------
// APR01 - pendencias da alcada
// Cada linha da SCR (status 02) vem com o cadastro do aprovador no grupo (SAL):
//   LIBAPR  = AL_LIBAPR  (A = aprovador, V = vistador / so visualiza)
//   TPLIBER = AL_TPLIBER (U = usuario, N = nivel, P = pedido)
//   AUTOLIM = AL_AUTOLIM (S = considera os limites: fora da faixa do
//             aprovador o pedido nao exige a aprovacao dele)
// EMISS_PED = data de emissao do pedido (C7_EMISSAO), para o filtro de datas.
// e com os limites da alcada: perfil (DHL, via AL_PERFIL) quando existir,
// senao o cadastro do aprovador (SAK). O BI usa esses campos para manter na
// fila so aprovadores de fato com o valor do pedido dentro da alcada.
// A filial da SAL/SAK/DHL e comparada por prefixo (exclusiva, parcial ou
// compartilhada); havendo mais de uma, vale a mais especifica.
//-----------------------------------------------------------------------------
Static Function qAPR01(oPar)
	Local cQ      := ""
	Local lPerfil := U_BIHASCOL(xT("SAL"), "AL_PERFIL") .And. U_BIHASCOL(xT("DHL"), "DHL_COD") .And. ;
	                 U_BIHASCOL(xT("DHL"), "DHL_LIMMIN") .And. U_BIHASCOL(xT("DHL"), "DHL_LIMMAX")
	Local cBlq    := iif(U_BIHASCOL(xT("SAL"), "AL_MSBLQL"), "AND SA.AL_MSBLQL <> '1' ", "")
	Local cMin    := iif(lPerfil, "COALESCE(PF.LMIN, AK.LMIN)", "AK.LMIN")
	Local cMax    := iif(lPerfil, "COALESCE(PF.LMAX, AK.LMAX)", "AK.LMAX")

	cQ += "SELECT TRIM(CR.CR_FILIAL) FILIAL, TRIM(CR.CR_NUM) PEDIDO, TRIM(CR.CR_TIPO) TIPO, "
	cQ += "TRIM(CR.CR_GRUPO) GRUPO, TRIM(CR.CR_NIVEL) NIVEL, CR.CR_TOTAL TOTAL, "
	cQ += "TRIM(CR.CR_EMISSAO) EMISSAO, TRIM(CR.CR_USER) APROV_ID, TRIM(CR.CR_APROV) APROV_COD, "
	cQ += "TRIM(U.USR_CODIGO) APROV_LOG, TRIM(U.USR_NOME) APROV_NOM, "
	cQ += "(SELECT MAX(TRIM(AL.AL_DESC)) FROM " + xT("SAL") + " AL "
	cQ += "  WHERE AL.D_E_L_E_T_ = ' ' AND AL.AL_COD = CR.CR_GRUPO) GRUPO_DESC, "
	cQ += "AL.LIBAPR LIBAPR, AL.TPLIBER TPLIBER, AL.AUTOLIM AUTOLIM, "
	cQ += iif(lPerfil, "AL.PERFIL", "CAST(NULL AS VARCHAR(250))") + " PERFIL, "
	cQ += "(SELECT MIN(TRIM(CE.C7_EMISSAO)) FROM " + xT("SC7") + " CE WHERE CE.D_E_L_E_T_ = ' ' "
	cQ += "  AND CE.C7_FILIAL = CR.CR_FILIAL AND CE.C7_NUM = TRIM(CR.CR_NUM)) EMISS_PED, "
	cQ += cMin + " LIM_MIN, " + cMax + " LIM_MAX "
	cQ += "FROM " + xT("SCR") + " CR "
	cQ += "LEFT JOIN SYS_USR U ON U.USR_ID = CR.CR_USER AND U.D_E_L_E_T_ = ' ' "
	// aprovador no grupo, no mesmo nivel da pendencia
	cQ += "OUTER APPLY (SELECT TOP 1 TRIM(SA.AL_LIBAPR) LIBAPR, "
	cQ += U_BICOL("SAL", "AL_TPLIBER", "TRIM(SA.AL_TPLIBER)") + " TPLIBER, "
	cQ += U_BICOL("SAL", "AL_AUTOLIM", "TRIM(SA.AL_AUTOLIM)") + " AUTOLIM"
	cQ += iif(lPerfil, ", TRIM(SA.AL_PERFIL) PERFIL ", " ")
	cQ += "  FROM " + xT("SAL") + " SA "
	cQ += "  WHERE SA.D_E_L_E_T_ = ' ' AND SA.AL_COD = CR.CR_GRUPO AND SA.AL_APROV = CR.CR_APROV "
	cQ += "    AND SA.AL_NIVEL = CR.CR_NIVEL AND CR.CR_FILIAL LIKE RTRIM(SA.AL_FILIAL) + '%' " + cBlq
	cQ += "  ORDER BY LEN(RTRIM(SA.AL_FILIAL)) DESC) AL "
	// limites do aprovador (SAK)
	cQ += "OUTER APPLY (SELECT TOP 1 SK.AK_LIMMIN LMIN, SK.AK_LIMMAX LMAX FROM " + xT("SAK") + " SK "
	cQ += "  WHERE SK.D_E_L_E_T_ = ' ' AND SK.AK_COD = CR.CR_APROV "
	cQ += "    AND CR.CR_FILIAL LIKE RTRIM(SK.AK_FILIAL) + '%' "
	cQ += "  ORDER BY LEN(RTRIM(SK.AK_FILIAL)) DESC) AK "
	// limites do perfil de aprovacao (DHL), quando o grupo usa perfil
	If lPerfil
		cQ += "OUTER APPLY (SELECT TOP 1 DH.DHL_LIMMIN LMIN, DH.DHL_LIMMAX LMAX FROM " + xT("DHL") + " DH "
		cQ += "  WHERE DH.D_E_L_E_T_ = ' ' AND AL.PERFIL <> '' AND DH.DHL_COD = AL.PERFIL "
		cQ += "    AND CR.CR_FILIAL LIKE RTRIM(DH.DHL_FILIAL) + '%' "
		cQ += "  ORDER BY LEN(RTRIM(DH.DHL_FILIAL)) DESC) PF "
	EndIf
	cQ += "WHERE CR.D_E_L_E_T_ = ' ' "
	cQ += "AND CR.CR_STATUS = '02' "
	cQ += "AND CR.CR_TIPO IN ('PC', 'IP') "
	cQ += "AND EXISTS ( "
	cQ += "  SELECT 1 FROM " + xT("SC7") + " C7 "
	cQ += "   WHERE C7.D_E_L_E_T_ = ' ' "
	cQ += "     AND C7.C7_FILIAL = CR.CR_FILIAL "
	cQ += "     AND C7.C7_NUM = TRIM(CR.CR_NUM) "
	cQ += "     AND C7.C7_CONAPRO = 'B' "
	cQ += "     AND (CR.CR_TIPO = 'PC' OR EXISTS ( "
	cQ += "       SELECT 1 FROM " + xT("DBM") + " DBM "
	cQ += "        WHERE DBM.D_E_L_E_T_ = ' ' "
	cQ += "          AND DBM.DBM_FILIAL = C7.C7_FILIAL "
	cQ += "          AND DBM.DBM_TIPO = CR.CR_TIPO "
	cQ += "          AND TRIM(DBM.DBM_NUM) = TRIM(C7.C7_NUM) "
	cQ += "          AND DBM.DBM_ITEM = C7.C7_ITEM "
	cQ += "          AND DBM.DBM_GRUPO = CR.CR_GRUPO "
	cQ += "          AND DBM.DBM_USER = CR.CR_USER "
	cQ += "          AND DBM.DBM_APROV = '2')))"

Return {cQ, "CR.CR_FILIAL, CR.CR_NUM, CR.CR_GRUPO, CR.CR_NIVEL, CR.R_E_C_N_O_"}

//-----------------------------------------------------------------------------
// APR02 - itens dos pedidos pendentes
//-----------------------------------------------------------------------------
Static Function qAPR02(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(C7.C7_FILIAL) FILIAL, TRIM(C7.C7_NUM) PEDIDO, TRIM(C7.C7_ITEM) ITEM, "
	cQ += "TRIM(C7.C7_PRODUTO) PRODUTO, TRIM(C7.C7_DESCRI) DESCRICAO, TRIM(C7.C7_UM) UM, "
	cQ += "C7.C7_QUANT QUANT, C7.C7_PRECO PRECO, C7.C7_TOTAL TOTAL, C7.C7_CONAPRO CONAPRO, "
	cQ += "TRIM(C7.C7_CC) CC, CTT.DESCR CC_DESC, "
	cQ += "TRIM(C7.C7_FORNECE) FORNECEDOR, TRIM(C7.C7_LOJA) LOJA, A2.NOME FORNEC_NOM, A2.CNPJ FORNEC_CGC, "
	cQ += "TRIM(UC.USR_NOME) COMPRADOR, TRIM(C7.C7_EMISSAO) EMISSAO, TRIM(C7.C7_DATPRF) ENTREGA, "
	cQ += "TRIM(C7.C7_COND) COND, E4.DESCR COND_DESC, TRIM(C7.C7_OBS) OBS, "
	cQ += "TRIM(C7.C7_NUMCOT) COTACAO, TRIM(C7.C7_NUMSC) SOLICITAC, TRIM(C7.C7_CONTRA) CONTRATO, "
	cQ += U_BICOL("SC7", "S_T_A_M_P_", "CONVERT(VARCHAR(19), C7.S_T_A_M_P_, 126) + 'Z'") + " ALTER_UTC, "
	cQ += "(SELECT CAST(STRING_AGG(G.GRP, ',') WITHIN GROUP (ORDER BY G.GRP) AS VARCHAR(250)) "
	cQ += "   FROM (SELECT DISTINCT TRIM(DBM.DBM_GRUPO) GRP FROM " + xT("DBM") + " DBM "
	cQ += "          WHERE DBM.D_E_L_E_T_ = ' ' AND DBM.DBM_FILIAL = C7.C7_FILIAL "
	cQ += "            AND TRIM(DBM.DBM_NUM) = TRIM(C7.C7_NUM) AND DBM.DBM_ITEM = C7.C7_ITEM) G) GRUPOS "
	cQ += "FROM " + xT("SC7") + " C7 "
	cQ += "OUTER APPLY (SELECT TOP 1 TRIM(A2_NOME) NOME, TRIM(A2_CGC) CNPJ FROM " + xT("SA2") + " "
	cQ += "  WHERE D_E_L_E_T_ = ' ' AND A2_COD = C7.C7_FORNECE AND A2_LOJA = C7.C7_LOJA) A2 "
	cQ += "OUTER APPLY (SELECT TOP 1 TRIM(CTT_DESC01) DESCR FROM " + xT("CTT") + " "
	cQ += "  WHERE D_E_L_E_T_ = ' ' AND CTT_CUSTO = C7.C7_CC) CTT "
	cQ += "OUTER APPLY (SELECT TOP 1 TRIM(E4_DESCRI) DESCR FROM " + xT("SE4") + " "
	cQ += "  WHERE D_E_L_E_T_ = ' ' AND E4_CODIGO = C7.C7_COND) E4 "
	cQ += "LEFT JOIN SYS_USR UC ON UC.USR_ID = C7.C7_USER AND UC.D_E_L_E_T_ = ' ' "
	cQ += "WHERE C7.D_E_L_E_T_ = ' ' "
	cQ += "AND " + xPendSCR()

Return {cQ, "C7.C7_FILIAL, C7.C7_NUM, C7.C7_ITEM"}

//-----------------------------------------------------------------------------
// APR03 - cotacoes dos itens pendentes (o WITH PEND/VENC virou tabela derivada)
//-----------------------------------------------------------------------------
Static Function qAPR03(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(V.C8_FILIAL) FILIAL, TRIM(V.PEDIDO) PEDIDO, TRIM(V.ITEMPED) ITEM, TRIM(C8.C8_NUM) COTACAO, "
	cQ += "TRIM(C8.C8_NUMPRO) PROPOSTA, TRIM(C8.C8_FORNECE) FORNECEDOR, TRIM(C8.C8_LOJA) LOJA, "
	cQ += "COALESCE(NULLIF(A2.NOME, ''), TRIM(C8.C8_FORNOME)) FORNEC_NOM, "
	cQ += "C8.C8_PRECO PRECO, C8.C8_PRECOOR PRECO_INI, C8.C8_TOTAL TOTAL, C8.C8_VALIPI IPI, "
	cQ += "C8.C8_VALFRE FRETE, C8.C8_TPFRETE TIPO_FRETE, C8.C8_PRAZO PRAZO, "
	cQ += "TRIM(C8.C8_CONTATO) CONTATO, TRIM(C8.C8_ORCFOR) ORC_FORNEC, "
	cQ += "TRIM(C8.C8_EMISSAO) EMISSAO, TRIM(C8.C8_VALIDA) VALIDADE, E4.DESCR CONDICAO, TRIM(C8.C8_OBS) OBS, "
	cQ += "CASE WHEN C8.C8_NUMPED = V.PEDIDO AND C8.C8_ITEMPED = V.ITEMPED THEN 1 ELSE 0 END VENCEDOR, "
	cQ += "(SELECT TOP 1 CAST(CAST(CE.CE_MOTVENC AS VARBINARY(2000)) AS VARCHAR(2000)) FROM " + xT("SCE") + " CE "
	cQ += "  WHERE CE.D_E_L_E_T_ = ' ' AND CE.CE_FILIAL = V.C8_FILIAL AND CE.CE_NUMCOT = V.C8_NUM "
	cQ += "    AND CE.CE_ITEMCOT = V.C8_ITEM AND CE.CE_NUMPED = V.PEDIDO AND CE.CE_ITEMPED = V.ITEMPED) JUSTIFIC "
	cQ += "FROM (SELECT W.C8_FILIAL, W.C8_NUM, W.C8_ITEM, P.C7_NUM PEDIDO, P.C7_ITEM ITEMPED "
	cQ += "        FROM " + xT("SC8") + " W "
	cQ += "        JOIN (SELECT C7.C7_FILIAL, C7.C7_NUM, C7.C7_ITEM, C7.C7_NUMCOT FROM " + xT("SC7") + " C7 "
	cQ += "               WHERE C7.D_E_L_E_T_ = ' ' AND TRIM(C7.C7_NUMCOT) <> '' "
	cQ += "                 AND " + xPendSCR() + ") P "
	cQ += "          ON W.C8_FILIAL = P.C7_FILIAL AND W.C8_NUM = P.C7_NUMCOT "
	cQ += "         AND W.C8_NUMPED = P.C7_NUM AND W.C8_ITEMPED = P.C7_ITEM "
	cQ += "       WHERE W.D_E_L_E_T_ = ' ') V "
	cQ += "JOIN " + xT("SC8") + " C8 ON C8.C8_FILIAL = V.C8_FILIAL AND C8.C8_NUM = V.C8_NUM "
	cQ += "  AND C8.C8_ITEM = V.C8_ITEM AND C8.D_E_L_E_T_ = ' ' "
	cQ += "OUTER APPLY (SELECT TOP 1 TRIM(A2_NOME) NOME FROM " + xT("SA2") + " "
	cQ += "  WHERE D_E_L_E_T_ = ' ' AND A2_COD = C8.C8_FORNECE AND A2_LOJA = C8.C8_LOJA) A2 "
	cQ += "OUTER APPLY (SELECT TOP 1 TRIM(E4_DESCRI) DESCR FROM " + xT("SE4") + " "
	cQ += "  WHERE D_E_L_E_T_ = ' ' AND E4_CODIGO = C8.C8_COND) E4"

Return {cQ, "V.C8_FILIAL, V.PEDIDO, V.ITEMPED, C8.C8_FORNECE, C8.C8_LOJA, C8.C8_NUMPRO"}
