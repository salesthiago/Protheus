#include 'protheus.ch'

/*/{Protheus.doc} BIQMNT
Consultas do BI - 8. Manutencao de frota / SIGAMNT (MNT).
Bens, OS, insumos, combustivel, hodometro, pecas, precos e abastecimentos por bem.
Chamado por APIBI.PRW. Retorna {cSql, cOrdem} ou uma string com a mensagem de erro.

@author Thiago Sales - Quebec Ambiental
@since 2026-11-11
/*/

// Codigos do ambiente de origem - conferir nesta empresa antes de usar
#define BI_CC_FROTA  "'3001', '3002', '1010', '3'"   // centros de custo da frota (MNT04)
#define BI_GRP_COMB  "'4009'"                         // grupo de produto do combustivel
#define BI_GRP_PECA  "'40%'"                          // grupos de pecas (MNT09), exceto combustivel

User Function BIQMNT(cId, oPar)

	Do Case
	Case cId == "MNT01" ; Return qMNT01(oPar)
	Case cId == "MNT02" ; Return qMNT02(oPar)
	Case cId == "MNT03" ; Return qMNT03(oPar)
	Case cId == "MNT04" ; Return qMNT04(oPar)
	Case cId == "MNT05" ; Return qMNT05(oPar)
	Case cId == "MNT06" ; Return qMNT06(oPar)
	Case cId == "MNT07" ; Return qMNT07(oPar)
	Case cId == "MNT08" ; Return qMNT08(oPar)
	Case cId == "MNT09" ; Return qMNT09(oPar)
	Case cId == "MNT10" ; Return qMNT10(oPar)
	EndCase

Return Nil

Static Function xT(cAlias)
Return RetSqlName(cAlias)

Static Function xQ(cVal)
Return "'" + cVal + "'"

// MNT01 - bens / veiculos (ST9)
Static Function qMNT01(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(B.T9_CODBEM) COD, TRIM(B.T9_NOME) NOME, TRIM(B.T9_PLACA) PLACA, TRIM(B.T9_CODFAMI) FAM, "
	cQ += "(SELECT MAX(TRIM(F.T6_NOME)) FROM " + xT("ST6") + " F WHERE F.D_E_L_E_T_ = ' ' AND F.T6_CODFAMI = B.T9_CODFAMI) FAMD, "
	cQ += "TRIM(B.T9_CCUSTO) CC, TRIM(B.T9_SITBEM) SIT "
	cQ += "FROM " + xT("ST9") + " B WHERE B.D_E_L_E_T_ = ' '"

Return {cQ, "B.T9_CODBEM, B.R_E_C_N_O_"}

// MNT02 - ordens de servico (STJ) com custo de pecas, terceiros e horas
Static Function qMNT02(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(J.TJ_FILIAL) FIL, TRIM(J.TJ_ORDEM) OS, TRIM(J.TJ_CODBEM) BEM, TRIM(J.TJ_SERVICO) SERV, TRIM(S.T4_NOME) SERVD, TRIM(S.T4_TIPOMAN) TMAN, "
	cQ += "TRIM(J.TJ_DTORIGI) ABE, TRIM(J.TJ_DTMRINI) INI, TRIM(J.TJ_DTMRFIM) FIM, TRIM(J.TJ_TERMINO) TERM, TRIM(J.TJ_CCUSTO) CC, "
	cQ += "ISNULL(L.P, 0) P, ISNULL(L.TR, 0) TR, ISNULL(L.H, 0) H, CAST(CAST(J.TJ_OBSERVA AS VARBINARY(200)) AS VARCHAR(200)) OBS "
	cQ += "FROM " + xT("STJ") + " J "
	cQ += "LEFT JOIN " + xT("ST4") + " S ON S.D_E_L_E_T_ = ' ' AND S.T4_SERVICO = J.TJ_SERVICO "
	cQ += "LEFT JOIN (SELECT TL_FILIAL, TL_ORDEM, "
	cQ += "                  SUM(CASE WHEN TRIM(TL_TIPOREG) = 'P' THEN TL_CUSTO ELSE 0 END) P, "
	cQ += "                  SUM(CASE WHEN TRIM(TL_TIPOREG) = 'T' THEN TL_CUSTO ELSE 0 END) TR, "
	cQ += "                  SUM(CASE WHEN TRIM(TL_TIPOREG) = 'M' AND TRIM(TL_UNIDADE) = 'H' THEN TL_QUANTID ELSE 0 END) H "
	cQ += "             FROM " + xT("STL") + " WHERE D_E_L_E_T_ = ' ' GROUP BY TL_FILIAL, TL_ORDEM) L "
	cQ += "  ON L.TL_FILIAL = J.TJ_FILIAL AND L.TL_ORDEM = J.TJ_ORDEM "
	cQ += "WHERE J.D_E_L_E_T_ = ' ' AND J.TJ_DTORIGI >= " + xQ(oPar["desde"]) + " "
	cQ += "AND J.TJ_DTORIGI <= CONVERT(VARCHAR(8), GETDATE(), 112)"

Return {cQ, "J.TJ_FILIAL, J.TJ_ORDEM, J.R_E_C_N_O_"}

// MNT03 - insumos das OS por grupo de produto
Static Function qMNT03(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(L.TL_FILIAL) FIL, TRIM(L.TL_ORDEM) OS, TRIM(P.B1_GRUPO) GRP, MAX(TRIM(G.BM_DESC)) GRPD, SUM(L.TL_CUSTO) V, SUM(L.TL_QUANTID) Q "
	cQ += "FROM " + xT("STL") + " L "
	cQ += "JOIN " + xT("STJ") + " J ON J.D_E_L_E_T_ = ' ' AND J.TJ_FILIAL = L.TL_FILIAL AND J.TJ_ORDEM = L.TL_ORDEM "
	cQ += "LEFT JOIN " + xT("SB1") + " P ON P.D_E_L_E_T_ = ' ' AND P.B1_COD = L.TL_CODIGO "
	cQ += "LEFT JOIN " + xT("SBM") + " G ON G.D_E_L_E_T_ = ' ' AND G.BM_GRUPO = P.B1_GRUPO "
	cQ += "WHERE L.D_E_L_E_T_ = ' ' AND TRIM(L.TL_TIPOREG) = 'P' AND J.TJ_DTORIGI >= " + xQ(oPar["desde"]) + " "
	cQ += "GROUP BY TRIM(L.TL_FILIAL), TRIM(L.TL_ORDEM), TRIM(P.B1_GRUPO)"

Return {cQ, "1, 2, 3"}

// MNT04 - compras dos CC de frota
Static Function qMNT04(oPar)
	Local cQ := ""

	cQ += "SELECT SUBSTRING(D.D1_DTDIGIT, 1, 6) YM, TRIM(D.D1_CC) CC, TRIM(P.B1_GRUPO) GRP, MAX(TRIM(G.BM_DESC)) GRPD, TRIM(D.D1_FORNECE) FORN, "
	cQ += "MAX(TRIM(A.A2_NOME)) FORND, SUM(D.D1_TOTAL) V, COUNT(*) N, SUM(CASE WHEN TRIM(D.D1_ORDEM) <> '' THEN D.D1_TOTAL ELSE 0 END) VO "
	cQ += "FROM " + xT("SD1") + " D "
	cQ += "LEFT JOIN " + xT("SB1") + " P ON P.D_E_L_E_T_ = ' ' AND P.B1_COD = D.D1_COD "
	cQ += "LEFT JOIN " + xT("SBM") + " G ON G.D_E_L_E_T_ = ' ' AND G.BM_GRUPO = P.B1_GRUPO "
	cQ += "LEFT JOIN " + xT("SA2") + " A ON A.D_E_L_E_T_ = ' ' AND A.A2_COD = D.D1_FORNECE AND A.A2_LOJA = D.D1_LOJA "
	cQ += "WHERE D.D_E_L_E_T_ = ' ' AND D.D1_TIPO = 'N' AND D.D1_DTDIGIT >= " + xQ(oPar["desde"]) + " "
	cQ += "AND TRIM(D.D1_CC) IN (" + BI_CC_FROTA + ") "
	cQ += "GROUP BY SUBSTRING(D.D1_DTDIGIT, 1, 6), TRIM(D.D1_CC), TRIM(P.B1_GRUPO), TRIM(D.D1_FORNECE)"

Return {cQ, "1, 2, 3, 5"}

// MNT05 - combustivel comprado (SD1, unidade litro)
Static Function qMNT05(oPar)
	Local cQ := ""

	cQ += "SELECT SUBSTRING(D.D1_DTDIGIT, 1, 6) YM, TRIM(D.D1_CC) CC, TRIM(P.B1_DESC) PROD, SUM(D.D1_QUANT) L, SUM(D.D1_TOTAL) V "
	cQ += "FROM " + xT("SD1") + " D JOIN " + xT("SB1") + " P ON P.D_E_L_E_T_ = ' ' AND P.B1_COD = D.D1_COD "
	cQ += "WHERE D.D_E_L_E_T_ = ' ' AND D.D1_TIPO = 'N' AND D.D1_DTDIGIT >= " + xQ(oPar["desde"]) + " "
	cQ += "AND TRIM(P.B1_GRUPO) IN (" + BI_GRP_COMB + ") AND TRIM(D.D1_UM) = 'L' "
	cQ += "GROUP BY SUBSTRING(D.D1_DTDIGIT, 1, 6), TRIM(D.D1_CC), TRIM(P.B1_DESC)"

Return {cQ, "1, 2, 3"}

// MNT06 - combustivel requisitado do estoque (SD3)
Static Function qMNT06(oPar)
	Local cQ := ""

	cQ += "SELECT SUBSTRING(D.D3_EMISSAO, 1, 6) YM, TRIM(D.D3_CC) CC, TRIM(P.B1_DESC) PROD, "
	cQ += "SUM(CASE WHEN D.D3_TM > '500' THEN D.D3_QUANT ELSE -D.D3_QUANT END) L, "
	cQ += "SUM(CASE WHEN D.D3_TM > '500' THEN D.D3_CUSTO1 ELSE -D.D3_CUSTO1 END) V "
	cQ += "FROM " + xT("SD3") + " D JOIN " + xT("SB1") + " P ON P.D_E_L_E_T_ = ' ' AND P.B1_COD = D.D3_COD "
	cQ += "WHERE D.D_E_L_E_T_ = ' ' AND D.D3_EMISSAO >= " + xQ(oPar["desde"]) + " "
	cQ += "AND TRIM(P.B1_GRUPO) IN (" + BI_GRP_COMB + ") AND D.D3_ESTORNO <> 'S' AND TRIM(D.D3_CC) <> '' "
	cQ += "GROUP BY SUBSTRING(D.D3_EMISSAO, 1, 6), TRIM(D.D3_CC), TRIM(P.B1_DESC)"

Return {cQ, "1, 2, 3"}

// MNT07 - hodometro por bem/mes
Static Function qMNT07(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(TP_FILIAL) FILIAL, TRIM(TP_CODBEM) BEM, SUBSTRING(TP_DTLEITU, 1, 6) YM, MAX(TP_POSCONT) MX, MIN(TP_POSCONT) MN, COUNT(*) N "
	cQ += "FROM " + xT("STP") + " WHERE D_E_L_E_T_ = ' ' AND TP_DTLEITU >= " + xQ(oPar["desde"]) + " AND TP_POSCONT > 0 "
	cQ += "GROUP BY TRIM(TP_FILIAL), TRIM(TP_CODBEM), SUBSTRING(TP_DTLEITU, 1, 6)"

Return {cQ, "1, 2, 3"}

// MNT08 - pecas aplicadas nas OS
Static Function qMNT08(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(L.TL_FILIAL) FIL, TRIM(L.TL_ORDEM) OS, TRIM(L.TL_CODIGO) PROD, MAX(TRIM(P.B1_DESC)) DESCR, MAX(TRIM(P.B1_GRUPO)) GRP, MAX(TRIM(G.BM_DESC)) GRPD, "
	cQ += "SUM(L.TL_QUANTID) Q, SUM(L.TL_CUSTO) V "
	cQ += "FROM " + xT("STL") + " L "
	cQ += "JOIN " + xT("STJ") + " J ON J.D_E_L_E_T_ = ' ' AND J.TJ_FILIAL = L.TL_FILIAL AND J.TJ_ORDEM = L.TL_ORDEM "
	cQ += "LEFT JOIN " + xT("SB1") + " P ON P.D_E_L_E_T_ = ' ' AND P.B1_COD = L.TL_CODIGO "
	cQ += "LEFT JOIN " + xT("SBM") + " G ON G.D_E_L_E_T_ = ' ' AND G.BM_GRUPO = P.B1_GRUPO "
	cQ += "WHERE L.D_E_L_E_T_ = ' ' AND TRIM(L.TL_TIPOREG) = 'P' AND J.TJ_DTORIGI >= " + xQ(oPar["desde"]) + " "
	cQ += "GROUP BY TRIM(L.TL_FILIAL), TRIM(L.TL_ORDEM), TRIM(L.TL_CODIGO)"

Return {cQ, "1, 2, 3"}

// MNT09 - precos de referencia de pecas
Static Function qMNT09(oPar)
	Local cQ := ""

	cQ += "SELECT SUBSTRING(D.D1_DTDIGIT, 1, 6) YM, TRIM(D.D1_COD) PROD, MAX(TRIM(P.B1_DESC)) DESCR, MAX(TRIM(P.B1_GRUPO)) GRP, MAX(TRIM(G.BM_DESC)) GRPD, MAX(TRIM(D.D1_UM)) UM, "
	cQ += "TRIM(D.D1_FORNECE) FORN, MAX(TRIM(A.A2_NOME)) FORND, SUM(D.D1_QUANT) Q, SUM(D.D1_TOTAL) V, COUNT(*) N "
	cQ += "FROM " + xT("SD1") + " D "
	cQ += "JOIN " + xT("SB1") + " P ON P.D_E_L_E_T_ = ' ' AND P.B1_COD = D.D1_COD "
	cQ += "LEFT JOIN " + xT("SBM") + " G ON G.D_E_L_E_T_ = ' ' AND G.BM_GRUPO = P.B1_GRUPO "
	cQ += "LEFT JOIN " + xT("SA2") + " A ON A.D_E_L_E_T_ = ' ' AND A.A2_COD = D.D1_FORNECE AND A.A2_LOJA = D.D1_LOJA "
	cQ += "WHERE D.D_E_L_E_T_ = ' ' AND D.D1_TIPO = 'N' AND D.D1_DTDIGIT >= " + xQ(oPar["desde"]) + " "
	cQ += "AND TRIM(P.B1_GRUPO) LIKE " + BI_GRP_PECA + " AND TRIM(P.B1_GRUPO) NOT IN (" + BI_GRP_COMB + ") AND D.D1_QUANT > 0 "
	cQ += "GROUP BY SUBSTRING(D.D1_DTDIGIT, 1, 6), TRIM(D.D1_COD), TRIM(D.D1_FORNECE)"

Return {cQ, "1, 2, 7"}

// MNT10 - abastecimentos por bem (TQN), para o custo de combustivel de cada bem
// Valor: TQN_VALTOT; se vier zerado, quantidade x preco unitario.
Static Function qMNT10(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(A.TQN_FILIAL) FIL, TRIM(A.TQN_FROTA) BEM, TRIM(A.TQN_DTABAS) DT, TRIM(A.TQN_CCUSTO) CC, "
	cQ += "TRIM(A.TQN_CODCOM) COMB, MAX(TRIM(C.TQM_NOMCOM)) COMBD, COUNT(*) N, SUM(A.TQN_QUANT) L, "
	cQ += "SUM(CASE WHEN A.TQN_VALTOT > 0 THEN A.TQN_VALTOT ELSE A.TQN_QUANT * A.TQN_VALUNI END) V "
	cQ += "FROM " + xT("TQN") + " A "
	cQ += "LEFT JOIN " + xT("TQM") + " C ON C.D_E_L_E_T_ = ' ' AND C.TQM_CODCOM = A.TQN_CODCOM "
	cQ += "WHERE A.D_E_L_E_T_ = ' ' AND A.TQN_DTABAS >= " + xQ(oPar["desde"]) + " "
	cQ += "GROUP BY TRIM(A.TQN_FILIAL), TRIM(A.TQN_FROTA), TRIM(A.TQN_DTABAS), TRIM(A.TQN_CCUSTO), TRIM(A.TQN_CODCOM)"

Return {cQ, "1, 2, 3, 4, 5"}
