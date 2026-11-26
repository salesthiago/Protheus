#include 'protheus.ch'

/*/{Protheus.doc} BIQCOM
Consultas do BI - 3. Pedidos de compra, todos os status (PED) e
4. Compras: solicitacoes, cotacoes, custos e notas (COM).
Chamado por APIBI.PRW. Retorna {cSql, cOrdem} ou uma string com a mensagem de erro.

Recorte incremental (PED02..PED05): se "desde" for informado, filtra
S_T_A_M_P_ > desde. A coluna S_T_A_M_P_ so existe quando o DBAccess esta
configurado para gera-la; sem ela o recorte devolve erro 400.

@author Thiago Sales - Quebec Ambiental
@since 2026-11-11
/*/
User Function BIQCOM(cId, oPar)

	Do Case
	Case cId == "PED01" ; Return qPED01(oPar)
	Case cId == "PED02" ; Return qPED02(oPar)
	Case cId == "PED03" ; Return qPED03(oPar)
	Case cId == "PED04" ; Return qPED04(oPar)
	Case cId == "PED05" ; Return qPED05(oPar)
	Case cId == "PED06" ; Return qPED06(oPar)
	Case cId == "COM01" ; Return qCOM01(oPar)
	Case cId == "COM02" ; Return qCOM02(oPar)
	Case cId == "COM03" ; Return qCOM03(oPar)
	Case cId == "COM04" ; Return qCOM04(oPar)
	Case cId == "COM05" ; Return qCOM05(oPar)
	Case cId == "COM06" ; Return qCOM06(oPar)
	EndCase

Return Nil

Static Function xT(cAlias)
Return RetSqlName(cAlias)

Static Function xQ(cVal)
Return "'" + cVal + "'"

//-----------------------------------------------------------------------------
// Data-hora UTC no formato do original (AAAA-MM-DDTHH:MM:SSZ) ou NULL
// se a coluna nao existir na tabela.
//-----------------------------------------------------------------------------
Static Function xIso(cTab, cAliasSql, cCampo)
Return U_BICOL(cTab, cCampo, "CONVERT(VARCHAR(19), " + cAliasSql + "." + cCampo + ", 126) + 'Z'")

//-----------------------------------------------------------------------------
// Recorte incremental por S_T_A_M_P_. Retorna "" (sem filtro), o filtro,
// ou Nil quando o parametro veio mas a coluna nao existe.
//-----------------------------------------------------------------------------
Static Function xIncr(oPar, cTab, cAliasSql)

	If Empty(oPar["desde"])
		Return ""
	EndIf
	If !U_BIHASCOL(xT(cTab), "S_T_A_M_P_")
		Return Nil
	EndIf

Return " AND " + cAliasSql + ".S_T_A_M_P_ > CONVERT(DATETIME2, " + xQ(oPar["desde"]) + ", 120)"

Static Function xSemStamp(cTab)
Return "Recorte incremental indisponivel: a tabela " + xT(cTab) + " nao possui a coluna S_T_A_M_P_"

//-----------------------------------------------------------------------------
// OUTER APPLYs de fornecedor, centro de custo e condicao do pedido
//-----------------------------------------------------------------------------
Static Function xAplC7()
	Local cQ := ""

	cQ += "OUTER APPLY (SELECT TOP 1 TRIM(A2_NOME) NOME, TRIM(A2_CGC) CNPJ FROM " + xT("SA2") + " "
	cQ += "  WHERE D_E_L_E_T_ = ' ' AND A2_COD = C7.C7_FORNECE AND A2_LOJA = C7.C7_LOJA) A2 "
	cQ += "OUTER APPLY (SELECT TOP 1 TRIM(CTT_DESC01) DESCR FROM " + xT("CTT") + " "
	cQ += "  WHERE D_E_L_E_T_ = ' ' AND CTT_CUSTO = C7.C7_CC) CTT "
	cQ += "OUTER APPLY (SELECT TOP 1 TRIM(E4_DESCRI) DESCR FROM " + xT("SE4") + " "
	cQ += "  WHERE D_E_L_E_T_ = ' ' AND E4_CODIGO = C7.C7_COND) E4 "
	cQ += "LEFT JOIN SYS_USR UC ON UC.USR_ID = C7.C7_USER AND UC.D_E_L_E_T_ = ' ' "

Return cQ

//-----------------------------------------------------------------------------
// PED01 - deteccao das colunas de hora (ALL_TAB_COLUMNS -> INFORMATION_SCHEMA)
//-----------------------------------------------------------------------------
Static Function qPED01(oPar)
	Local cQ := ""

	cQ += "SELECT TABLE_NAME T, COLUMN_NAME C FROM INFORMATION_SCHEMA.COLUMNS "
	cQ += "WHERE TABLE_NAME IN (" + xQ(xT("SC7")) + ", " + xQ(xT("SC1")) + ", " + xQ(xT("SD1")) + ", "
	cQ += xQ(xT("SF1")) + ", " + xQ(xT("SCR")) + ") "
	cQ += "AND COLUMN_NAME IN ('I_N_S_D_T_', 'S_T_A_M_P_', 'F1_HORA', 'CR_HORALIB', 'CR_HRLIB')"

Return {cQ, "1, 2"}

//-----------------------------------------------------------------------------
// PED02 - itens de pedido (le tambem os excluidos, D_E_L_E_T_ = '*')
//-----------------------------------------------------------------------------
Static Function qPED02(oPar)
	Local cQ   := ""
	Local cInc := xIncr(oPar, "SC7", "C7")

	If cInc == Nil
		Return xSemStamp("SC7")
	EndIf

	cQ += "SELECT TRIM(C7.C7_FILIAL) FILIAL, TRIM(C7.C7_NUM) NUM, TRIM(C7.C7_ITEM) ITEM, C7.D_E_L_E_T_ DEL, "
	cQ += "TRIM(C7.C7_CONAPRO) CONAPRO, TRIM(C7.C7_RESIDUO) RESIDUO, TRIM(C7.C7_ENCER) ENCER, "
	cQ += "C7.C7_QUANT QUANT, C7.C7_QUJE QUJE, C7.C7_PRECO PRECO, C7.C7_TOTAL TOTAL, "
	cQ += "C7.C7_VALIPI IPI, C7.C7_VALFRE FRETE, C7.C7_VLDESC DESCONTO, "
	cQ += "TRIM(C7.C7_PRODUTO) PRODUTO, TRIM(C7.C7_DESCRI) DESCRI, TRIM(C7.C7_UM) UM, "
	cQ += "TRIM(C7.C7_CC) CC, CTT.DESCR CC_DESC, TRIM(C7.C7_DATPRF) ENTREGA, "
	cQ += "TRIM(C7.C7_NUMSC) NUMSC, TRIM(C7.C7_NUMCOT) NUMCOT, TRIM(C7.C7_CONTRA) CONTRATO, TRIM(C7.C7_OBS) OBS, "
	cQ += "TRIM(C7.C7_EMISSAO) EMISSAO, TRIM(C7.C7_FORNECE) FORNECE, TRIM(C7.C7_LOJA) LOJA, A2.NOME FORN_NOME, A2.CNPJ, "
	cQ += "TRIM(UC.USR_NOME) COMPRADOR, TRIM(C7.C7_COND) COND, E4.DESCR COND_DESC, "
	cQ += xIso("SC7", "C7", "S_T_A_M_P_") + " STAMP, "
	cQ += xIso("SC7", "C7", "I_N_S_D_T_") + " CRIADO "
	cQ += "FROM " + xT("SC7") + " C7 "
	cQ += xAplC7()
	cQ += "WHERE C7.D_E_L_E_T_ IN (' ', '*')" + cInc

Return {cQ, "C7.C7_FILIAL, C7.C7_NUM, C7.C7_ITEM, C7.R_E_C_N_O_"}

//-----------------------------------------------------------------------------
// PED03 - alcadas (SCR). ENVIADO_TS e HORA_LIB vem nulos como no original.
//-----------------------------------------------------------------------------
Static Function qPED03(oPar)
	Local cQ   := ""
	Local cInc := xIncr(oPar, "SCR", "CR")

	If cInc == Nil
		Return xSemStamp("SCR")
	EndIf

	cQ += "SELECT TRIM(CR.CR_FILIAL) FILIAL, TRIM(CR.CR_NUM) NUM, TRIM(CR.CR_TIPO) TIPO, TRIM(CR.CR_GRUPO) GRUPO, "
	cQ += "(SELECT MAX(TRIM(AL.AL_DESC)) FROM " + xT("SAL") + " AL WHERE AL.D_E_L_E_T_ = ' ' AND AL.AL_COD = CR.CR_GRUPO) GRUPO_DESC, "
	cQ += "TRIM(CR.CR_NIVEL) NIVEL, TRIM(CR.CR_STATUS) STATUS, TRIM(CR.CR_EMISSAO) EMISSAO, TRIM(CR.CR_DATALIB) DATALIB, "
	cQ += "TRIM(U.USR_NOME) APROVADOR, TRIM(UL.USR_NOME) LIBER_POR, CR.CR_TOTAL TOTAL, TRIM(CR.CR_OBS) OBS, "
	cQ += "CAST(NULL AS VARCHAR(20)) ENVIADO_TS, "
	cQ += "CAST(NULL AS VARCHAR(8)) HORA_LIB "
	cQ += "FROM " + xT("SCR") + " CR "
	cQ += "LEFT JOIN SYS_USR U ON U.USR_ID = CR.CR_USER AND U.D_E_L_E_T_ = ' ' "
	cQ += "LEFT JOIN SYS_USR UL ON UL.USR_ID = CR.CR_USERLIB AND UL.D_E_L_E_T_ = ' ' "
	cQ += "WHERE CR.D_E_L_E_T_ = ' ' AND CR.CR_TIPO IN ('PC', 'IP')" + cInc

Return {cQ, "CR.CR_FILIAL, CR.CR_NUM, CR.CR_GRUPO, CR.CR_NIVEL, CR.R_E_C_N_O_"}

//-----------------------------------------------------------------------------
// PED04 - notas de entrada vinculadas a pedido
//-----------------------------------------------------------------------------
Static Function qPED04(oPar)
	Local cQ   := ""
	Local cInc := xIncr(oPar, "SD1", "D1")

	If cInc == Nil
		Return xSemStamp("SD1")
	EndIf

	cQ += "SELECT TRIM(D1.D1_FILIAL) FILIAL, TRIM(D1.D1_PEDIDO) NUM, TRIM(D1.D1_ITEMPC) ITEM, TRIM(D1.D1_DOC) DOC, "
	cQ += "TRIM(D1.D1_SERIE) SERIE, F1.ESPECIE, TRIM(D1.D1_EMISSAO) EMISSAO, TRIM(D1.D1_DTDIGIT) ENTRADA, "
	cQ += "D1.D1_QUANT QUANT, D1.D1_TOTAL TOTAL, "
	cQ += "F1.HORA HORA "
	cQ += "FROM " + xT("SD1") + " D1 "
	cQ += "OUTER APPLY (SELECT TOP 1 TRIM(F1_ESPECIE) ESPECIE, TRIM(F1_HORA) HORA FROM " + xT("SF1") + " "
	cQ += "  WHERE D_E_L_E_T_ = ' ' AND F1_FILIAL = D1.D1_FILIAL AND F1_DOC = D1.D1_DOC AND F1_SERIE = D1.D1_SERIE "
	cQ += "    AND F1_FORNECE = D1.D1_FORNECE AND F1_LOJA = D1.D1_LOJA) F1 "
	cQ += "WHERE D1.D_E_L_E_T_ = ' ' AND D1.D1_PEDIDO <> ' '" + cInc

Return {cQ, "D1.R_E_C_N_O_"}

//-----------------------------------------------------------------------------
// PED05 - solicitacoes de compra dos pedidos
//-----------------------------------------------------------------------------
Static Function qPED05(oPar)
	Local cQ   := ""
	Local cInc := xIncr(oPar, "SC7", "C7")

	If cInc == Nil
		Return xSemStamp("SC7")
	EndIf

	cQ += "SELECT TRIM(C7.C7_FILIAL) FILIAL, TRIM(C7.C7_NUM) NUM, TRIM(C7.C7_ITEM) ITEM, TRIM(C1.C1_NUM) SC, "
	cQ += "TRIM(C1.C1_EMISSAO) EMISSAO, TRIM(C1.C1_SOLICIT) SOLICITANT, "
	cQ += xIso("SC1", "C1", "I_N_S_D_T_") + " CRIADO "
	cQ += "FROM " + xT("SC7") + " C7 "
	cQ += "JOIN " + xT("SC1") + " C1 ON C1.D_E_L_E_T_ = ' ' AND C1.C1_FILIAL = C7.C7_FILIAL AND C1.C1_NUM = C7.C7_NUMSC "
	cQ += "  AND C1.C1_ITEM = C7.C7_ITEMSC "
	cQ += "WHERE C7.D_E_L_E_T_ IN (' ', '*') AND C7.C7_NUMSC <> ' '" + cInc

Return {cQ, "C7.C7_FILIAL, C7.C7_NUM, C7.C7_ITEM, C7.R_E_C_N_O_"}

//-----------------------------------------------------------------------------
// PED06 - chaves FILIAL|PEDIDO alteradas desde o ultimo recorte
//-----------------------------------------------------------------------------
Static Function qPED06(oPar)
	Local cQ := ""

	If !U_BIHASCOL(xT("SC7"), "S_T_A_M_P_")
		Return xSemStamp("SC7")
	EndIf

	cQ += "SELECT DISTINCT CONCAT(TRIM(C7_FILIAL), '|', TRIM(C7_NUM)) K FROM " + xT("SC7") + " "
	cQ += "WHERE D_E_L_E_T_ IN (' ', '*') "
	cQ += "  AND (S_T_A_M_P_ > CONVERT(DATETIME2, " + xQ(oPar["desde"]) + ", 120) OR (C7_CONAPRO = 'B' AND D_E_L_E_T_ = ' ')) "
	cQ += "UNION "
	cQ += "SELECT DISTINCT CONCAT(TRIM(CR_FILIAL), '|', TRIM(CR_NUM)) K FROM " + xT("SCR") + " "
	cQ += "WHERE D_E_L_E_T_ = ' ' AND CR_TIPO IN ('PC', 'IP') "
	cQ += "  AND (CR_DATALIB >= " + xQ(oPar["dia"]) + " OR CR_EMISSAO >= " + xQ(oPar["dia"]) + ")"

Return {cQ, "1"}

//-----------------------------------------------------------------------------
// COM01 - deteccao de tabelas opcionais (ALL_TABLES -> INFORMATION_SCHEMA)
//-----------------------------------------------------------------------------
Static Function qCOM01(oPar)
	Local cQ := ""

	cQ += "SELECT TABLE_NAME T FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME IN (" + xQ(xT("SY1")) + ")"

Return {cQ, "1"}

//-----------------------------------------------------------------------------
// COM02 - deteccao de colunas opcionais da SC1
//-----------------------------------------------------------------------------
Static Function qCOM02(oPar)
	Local cQ := ""

	cQ += "SELECT COLUMN_NAME C FROM INFORMATION_SCHEMA.COLUMNS "
	cQ += "WHERE TABLE_NAME = " + xQ(xT("SC1")) + " "
	cQ += "AND COLUMN_NAME IN ('C1_CODCOMP', 'I_N_S_D_T_', 'C1_XTIPOSC', 'C1_XURGEN', 'C1_URGEN', 'C1_XPRIOR', 'C1_PRIORID')"

Return {cQ, "1"}

//-----------------------------------------------------------------------------
// COM03 - solicitacoes de compra (janela "desde" + tudo que esta em aberto)
// C1_CODCOMP, C1_XTIPOSC e I_N_S_D_T_ sao opcionais: sem a coluna vem vazio.
//-----------------------------------------------------------------------------
Static Function qCOM03(oPar)
	Local cQ   := ""
	Local cCmp := "CAST(NULL AS VARCHAR(250))"

	If U_BIHASCOL(xT("SC1"), "C1_CODCOMP")
		cCmp := "(SELECT MAX(TRIM(Y1.Y1_NOME)) FROM " + xT("SY1") + " Y1 WHERE Y1.D_E_L_E_T_ = ' ' AND Y1.Y1_COD = C1.C1_CODCOMP)"
	EndIf

	cQ += "SELECT TRIM(C1.C1_FILIAL) FILIAL, TRIM(C1.C1_NUM) NUM, TRIM(C1.C1_ITEM) ITEM, TRIM(C1.C1_PRODUTO) PRODUTO, "
	cQ += "TRIM(C1.C1_DESCRI) DESCRI, TRIM(C1.C1_UM) UM, C1.C1_QUANT QUANT, C1.C1_QUJE QUJE, "
	cQ += "TRIM(C1.C1_CC) CC, (SELECT MAX(TRIM(CTT_DESC01)) FROM " + xT("CTT") + " WHERE D_E_L_E_T_ = ' ' AND CTT_CUSTO = C1.C1_CC) CC_DESC, "
	cQ += "TRIM(C1.C1_APROV) APROV, TRIM(C1.C1_RESIDUO) RESIDUO, TRIM(C1.C1_PEDIDO) PEDIDO, TRIM(C1.C1_COTACAO) COTACAO, "
	cQ += "COALESCE(NULLIF(TRIM(U.USR_NOME), ''), TRIM(C1.C1_SOLICIT)) SOLICITANT, " + cCmp + " COMPRADOR, "
	cQ += "TRIM(C1.C1_EMISSAO) EMISSAO, TRIM(C1.C1_DATPRF) DATPRF, "
	cQ += U_BICOL("SC1", "C1_XTIPOSC", "TRIM(C1.C1_XTIPOSC)") + " CLASSIF, "
	cQ += xIso("SC1", "C1", "I_N_S_D_T_") + " CRIADO "
	cQ += "FROM " + xT("SC1") + " C1 "
	cQ += "LEFT JOIN SYS_USR U ON U.USR_ID = C1.C1_USER AND U.D_E_L_E_T_ = ' ' "
	cQ += "WHERE C1.D_E_L_E_T_ = ' ' "
	cQ += "AND (C1.C1_EMISSAO >= " + xQ(oPar["desde"]) + " OR (C1.C1_QUJE < C1.C1_QUANT AND TRIM(C1.C1_RESIDUO) = ''))"

Return {cQ, "C1.C1_FILIAL, C1.C1_NUM, C1.C1_ITEM, C1.R_E_C_N_O_"}

//-----------------------------------------------------------------------------
// COM04 - cotacoes (janela "desde" + as que ainda nao viraram pedido)
//-----------------------------------------------------------------------------
Static Function qCOM04(oPar)
	Local cQ   := ""
	Local cCmp := "CAST(NULL AS VARCHAR(250))"

	If U_BIHASCOL(xT("SC1"), "C1_CODCOMP")
		cCmp := "(SELECT MAX(TRIM(Y1.Y1_NOME)) FROM " + xT("SC1") + " C1 JOIN " + xT("SY1") + " Y1 ON Y1.D_E_L_E_T_ = ' ' AND Y1.Y1_COD = C1.C1_CODCOMP "
		cCmp += "  WHERE C1.D_E_L_E_T_ = ' ' AND C1.C1_FILIAL = C8.C8_FILIAL AND C1.C1_NUM = C8.C8_NUMSC AND C1.C1_ITEM = C8.C8_ITEMSC)"
	EndIf

	cQ += "SELECT TRIM(C8.C8_FILIAL) FILIAL, TRIM(C8.C8_NUM) NUM, TRIM(C8.C8_ITEM) ITEM, TRIM(C8.C8_NUMPRO) PROPOSTA, "
	cQ += "CONCAT(TRIM(C8.C8_FORNECE), '/', TRIM(C8.C8_LOJA)) FORNECEDOR, "
	cQ += "COALESCE(NULLIF((SELECT MAX(TRIM(A2_NOME)) FROM " + xT("SA2") + " WHERE D_E_L_E_T_ = ' ' AND A2_COD = C8.C8_FORNECE AND A2_LOJA = C8.C8_LOJA), ''), TRIM(C8.C8_FORNOME)) FORN_NOME, "
	cQ += "TRIM(C8.C8_PRODUTO) PRODUTO, (SELECT MAX(TRIM(B1_DESC)) FROM " + xT("SB1") + " WHERE D_E_L_E_T_ = ' ' AND B1_COD = C8.C8_PRODUTO) DESCRI, "
	cQ += "C8.C8_QUANT QUANT, C8.C8_PRECO PRECO, C8.C8_TOTAL TOTAL, TRIM(C8.C8_EMISSAO) EMISSAO, TRIM(C8.C8_VALIDA) VALIDA, "
	cQ += "TRIM(C8.C8_NUMPED) PEDIDO, TRIM(C8.C8_NUMSC) SC, "
	cQ += cCmp + " COMPRADOR "
	cQ += "FROM " + xT("SC8") + " C8 "
	cQ += "WHERE C8.D_E_L_E_T_ = ' ' AND (C8.C8_EMISSAO >= " + xQ(oPar["desde"]) + " OR TRIM(C8.C8_NUMPED) = '')"

Return {cQ, "C8.C8_FILIAL, C8.C8_NUM, C8.C8_ITEM, C8.R_E_C_N_O_"}

//-----------------------------------------------------------------------------
// COM05 - custo medio ponderado dos itens (SB2)
//-----------------------------------------------------------------------------
Static Function qCOM05(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(B2_FILIAL) FILIAL, TRIM(B2_COD) PRODUTO, "
	cQ += "CASE WHEN SUM(CASE WHEN B2_QATU > 0 THEN B2_QATU ELSE 0 END) > 0 "
	cQ += "     THEN SUM(CASE WHEN B2_QATU > 0 THEN B2_QATU * B2_CM1 ELSE 0 END) / SUM(CASE WHEN B2_QATU > 0 THEN B2_QATU ELSE 0 END) "
	cQ += "     ELSE MAX(B2_CM1) END CM, "
	cQ += "SUM(B2_QATU) SALDO "
	cQ += "FROM " + xT("SB2") + " "
	cQ += "WHERE D_E_L_E_T_ = ' ' AND B2_CM1 > 0 "
	cQ += "GROUP BY B2_FILIAL, B2_COD"

Return {cQ, "1, 2"}

//-----------------------------------------------------------------------------
// COM06 - notas de entrada agrupadas por documento
//-----------------------------------------------------------------------------
Static Function qCOM06(oPar)
	Local cQ := ""

	cQ += "SELECT N.*, P.PEMI, P.CONTRA, (SELECT MAX(TRIM(U.USR_NOME)) FROM SYS_USR U WHERE U.D_E_L_E_T_ = ' ' AND U.USR_ID = P.USR) COMPRADOR, "
	cQ += "(SELECT MAX(TRIM(F4_TEXTO)) FROM " + xT("SF4") + " WHERE D_E_L_E_T_ = ' ' AND TRIM(F4_CODIGO) = N.TES) TES_TXT, "
	cQ += "(SELECT MAX(TRIM(F4_ESTOQUE)) FROM " + xT("SF4") + " WHERE D_E_L_E_T_ = ' ' AND TRIM(F4_CODIGO) = N.TES) EST, "
	cQ += "(SELECT MAX(TRIM(A2_NOME)) FROM " + xT("SA2") + " WHERE D_E_L_E_T_ = ' ' AND A2_COD = N.FORN AND A2_LOJA = N.LOJA) NOME, "
	cQ += "(SELECT MAX(TRIM(CTT_DESC01)) FROM " + xT("CTT") + " WHERE D_E_L_E_T_ = ' ' AND TRIM(CTT_CUSTO) = N.CC) CC_DESC, "
	cQ += "(SELECT MAX(TRIM(F1_ESPECIE)) FROM " + xT("SF1") + " F WHERE F.D_E_L_E_T_ = ' ' AND F.F1_FILIAL = N.FIL AND F.F1_DOC = N.DOC_RAW "
	cQ += "   AND F.F1_SERIE = N.SER_RAW AND F.F1_FORNECE = N.FORN AND F.F1_LOJA = N.LOJA) ESP, "
	cQ += "(SELECT MAX(TRIM(F1_STATUS)) FROM " + xT("SF1") + " F WHERE F.D_E_L_E_T_ = ' ' AND F.F1_FILIAL = N.FIL AND F.F1_DOC = N.DOC_RAW "
	cQ += "   AND F.F1_SERIE = N.SER_RAW AND F.F1_FORNECE = N.FORN AND F.F1_LOJA = N.LOJA) STATUS "
	cQ += "FROM (SELECT D.D1_FILIAL FIL, D.D1_DOC DOC_RAW, D.D1_SERIE SER_RAW, TRIM(D.D1_DOC) DOC, TRIM(D.D1_SERIE) SER, D.D1_FORNECE FORN, D.D1_LOJA LOJA, "
	cQ += "        MAX(TRIM(D.D1_TIPO)) TIPO, TRIM(D.D1_PEDIDO) PED, MIN(TRIM(D.D1_EMISSAO)) EMI, MIN(TRIM(D.D1_DTDIGIT)) DIG, "
	cQ += "        MAX(TRIM(D.D1_TES)) TES, MAX(TRIM(D.D1_CF)) CF, MAX(TRIM(D.D1_CC)) CC, SUM(D.D1_TOTAL) V, COUNT(*) ITENS "
	cQ += "       FROM " + xT("SD1") + " D "
	cQ += "      WHERE D.D_E_L_E_T_ = ' ' AND D.D1_DTDIGIT >= " + xQ(oPar["desde"]) + " "
	cQ += "      GROUP BY D.D1_FILIAL, D.D1_DOC, D.D1_SERIE, D.D1_FORNECE, D.D1_LOJA, TRIM(D.D1_PEDIDO)) N "
	cQ += "LEFT JOIN (SELECT C7_FILIAL FIL, TRIM(C7_NUM) NUM, MIN(TRIM(C7_EMISSAO)) PEMI, MAX(C7_USER) USR, "
	cQ += "                  MAX(CASE WHEN TRIM(C7_CONTRA) <> '' THEN 'S' ELSE 'N' END) CONTRA "
	cQ += "             FROM " + xT("SC7") + " WHERE D_E_L_E_T_ = ' ' GROUP BY C7_FILIAL, TRIM(C7_NUM)) P "
	cQ += "  ON P.FIL = N.FIL AND P.NUM = N.PED"

Return {cQ, "N.FIL, N.DOC_RAW, N.SER_RAW, N.FORN, N.LOJA, N.PED"}
