#include 'protheus.ch'

/*/{Protheus.doc} BIQEST
Consultas do BI - 9. Suprimentos / almoxarifado (EST) e EPI (EPI).
Saldos, movimentos, fechamentos, solicitacoes, prazos, saldo negativo,
EPI, inventario e ajustes.
Chamado por APIBI.PRW. Retorna {cSql, cOrdem} ou uma string com a mensagem de erro.

@author Thiago Sales - Quebec Ambiental
@since 2026-11-11
/*/

// Produtos fora do almoxarifado (codigos do ambiente de origem - conferir nesta empresa):
// mao de obra (MOD*), grupos iniciados por 2, grupo 0002 e combustivel 4009
#define BI_PRD_EXCL "'0002', '4009'"

User Function BIQEST(cId, oPar)

	Do Case
	Case cId == "EST01" ; Return qEST01(oPar)
	Case cId == "EST02" ; Return qEST02(oPar)
	Case cId == "EST03" ; Return qEST03(oPar)
	Case cId == "EST04" ; Return qEST04(oPar)
	Case cId == "EST05" ; Return qEST05(oPar)
	Case cId == "EST06" ; Return qEST06(oPar)
	Case cId == "EST07" ; Return qEST07(oPar)
	Case cId == "EST08" ; Return qEST08(oPar)
	Case cId == "EST09" ; Return qEST09(oPar)
	Case cId == "EST10" ; Return qEST10(oPar)
	Case cId == "EST11" ; Return qEST11(oPar)
	Case cId == "EST12" ; Return qEST12(oPar)
	Case cId == "EST13" ; Return qEST13(oPar)
	Case cId == "EST14" ; Return qEST14(oPar)
	Case cId == "EST15" ; Return qEST15(oPar)
	Case cId == "EST16" ; Return qEST16(oPar)
	Case cId == "EST17" ; Return qEST17(oPar)
	Case cId == "EST18" ; Return qEST18(oPar)
	Case cId == "EST19" ; Return qEST19(oPar)
	Case cId == "EST20" ; Return qEST20(oPar)
	Case cId == "EST21" ; Return qEST21(oPar)
	Case cId == "EST22" ; Return qEST22(oPar)
	Case cId == "EST23" ; Return qEST23(oPar)
	Case cId == "EPI01" ; Return qEPI01(oPar)
	Case cId == "EPI02" ; Return qEPI02(oPar)
	Case cId == "EPI03" ; Return qEPI03(oPar)
	Case cId == "EPI04" ; Return qEPI04(oPar)
	Case cId == "EPI05" ; Return qEPI05(oPar)
	Case cId == "EPI06" ; Return qEPI06(oPar)
	Case cId == "EPI07" ; Return qEPI07(oPar)
	Case cId == "EPI08" ; Return qEPI08(oPar)
	EndCase

Return Nil

Static Function xT(cAlias)
Return RetSqlName(cAlias)

Static Function xQ(cVal)
Return "'" + cVal + "'"

// Filtro de produto do almoxarifado sobre o alias SQL da SB1.
// NVL(TRIM(grupo), ' ') do Oracle nao e necessario: no SQL Server o vazio e ''.
Static Function xFPrd(cA)
Return "(" + cA + ".B1_COD NOT LIKE 'MOD%' AND TRIM(" + cA + ".B1_GRUPO) NOT LIKE '2%' AND TRIM(" + cA + ".B1_GRUPO) NOT IN (" + BI_PRD_EXCL + "))"

//-----------------------------------------------------------------------------
// Le um cadastro (SB1, SBM, NNR, SF5...) na filial do movimento cFilMov.
// Serve para cadastro exclusivo, parcialmente compartilhado ou compartilhado:
// a filial do cadastro e comparada por prefixo e vale a mais especifica.
// Sem isso, cadastro exclusivo multiplica cada linha pelo numero de filiais.
//   cTipo   CROSS (obrigatorio) ou OUTER (opcional)
//   cTab    alias Protheus do cadastro    cA  alias SQL interno
//   cCampos colunas devolvidas            cFiltro  chave do cadastro
//   cRes    alias do resultado no SELECT externo
//-----------------------------------------------------------------------------
Static Function xCad(cTipo, cTab, cA, cCampos, cFiltro, cFilMov, cRes)
	Local cF := cA + "." + iif(Left(cTab, 1) == "S", SubStr(cTab, 2), cTab) + "_FILIAL"

Return cTipo + " APPLY (SELECT TOP 1 " + cCampos + " FROM " + xT(cTab) + " " + cA + " " + ;
	"WHERE " + cA + ".D_E_L_E_T_ = ' ' AND " + cFiltro + " AND " + cFilMov + " LIKE RTRIM(" + cF + ") + '%' " + ;
	"ORDER BY LEN(RTRIM(" + cF + ")) DESC) " + cRes + " "

// Produto (SB1) da filial do movimento, com as colunas usadas por xFPrd()
Static Function xPrd(cFilMov, cCod)
Return xCad("CROSS", "SB1", "PR", "PR.B1_COD, PR.B1_GRUPO, TRIM(PR.B1_DESC) DESCR, TRIM(PR.B1_GRUPO) GRP, TRIM(PR.B1_UM) UM", ;
	"PR.B1_COD = " + cCod, cFilMov, "P")

// Grupo de produto (SBM) da filial do movimento
Static Function xGrp(cFilMov)
Return xCad("OUTER", "SBM", "BM", "TRIM(BM.BM_DESC) GRPD", "BM.BM_GRUPO = P.B1_GRUPO", cFilMov, "G")

//=============================================================================
// Movimentos de estoque (SD3) e referencias de preco
//=============================================================================

// EST01 - produtos com movimento interno
Static Function qEST01(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(P.B1_COD) COD, TRIM(P.B1_DESC) DESCR, TRIM(P.B1_GRUPO) GRP, TRIM(G.BM_DESC) GRPD "
	cQ += "FROM " + xT("SB1") + " P LEFT JOIN " + xT("SBM") + " G ON G.D_E_L_E_T_ = ' ' AND G.BM_GRUPO = P.B1_GRUPO "
	cQ += "WHERE P.D_E_L_E_T_ = ' ' AND " + xFPrd("P") + " "
	cQ += "AND EXISTS (SELECT 1 FROM " + xT("SD3") + " D WHERE D.D_E_L_E_T_ = ' ' AND D.D3_COD = P.B1_COD)"

Return {cQ, "P.B1_COD, P.R_E_C_N_O_"}

// EST02 - centros de custo (colunas CC, D)
Static Function qEST02(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(CTT_CUSTO) CC, TRIM(CTT_DESC01) D FROM " + xT("CTT") + " WHERE D_E_L_E_T_ = ' '"

Return {cQ, "CTT_CUSTO, R_E_C_N_O_"}

// EST03 - tipos de movimento
Static Function qEST03(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(F5_CODIGO) TM, TRIM(F5_TEXTO) D FROM " + xT("SF5") + " WHERE D_E_L_E_T_ = ' '"

Return {cQ, "F5_CODIGO, R_E_C_N_O_"}

// EST04 - precos unitarios de entrada (mesma unidade do cadastro)
Static Function qEST04(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(N.D1_COD) COD, N.D1_VUNIT VU FROM " + xT("SD1") + " N "
	cQ += "JOIN " + xT("SB1") + " P ON P.D_E_L_E_T_ = ' ' AND P.B1_COD = N.D1_COD AND TRIM(P.B1_UM) = TRIM(N.D1_UM) "
	cQ += "WHERE N.D_E_L_E_T_ = ' ' AND N.D1_TIPO = 'N' AND N.D1_QUANT > 0 AND N.D1_VUNIT > 0 "
	cQ += "AND N.D1_DTDIGIT >= " + xQ(oPar["desde"])

Return {cQ, "N.R_E_C_N_O_"}

// EST05 - meses com movimento interno valido
Static Function qEST05(oPar)
	Local cQ := ""

	cQ += "SELECT DISTINCT SUBSTRING(D3_EMISSAO, 1, 6) M FROM " + xT("SD3") + " WHERE D_E_L_E_T_ = ' ' AND D3_ESTORNO <> 'S'"

Return {cQ, "1"}

// EST06 - movimentos internos do mes (exceto transferencias e producao)
Static Function qEST06(oPar)
	Local cQ := ""

	cQ += "SELECT D.R_E_C_N_O_ RID, D.D3_EMISSAO EMI, TRIM(D.D3_TM) TM, TRIM(D.D3_CF) CF, TRIM(D.D3_COD) COD, TRIM(D.D3_LOCAL) LOC, "
	cQ += "TRIM(D.D3_CC) CC, TRIM(D.D3_DOC) DOC, TRIM(D.D3_USUARIO) USR, D.D3_QUANT Q, D.D3_CUSTO1 V "
	cQ += "FROM " + xT("SD3") + " D "
	cQ += "WHERE D.D_E_L_E_T_ = ' ' AND D.D3_ESTORNO <> 'S' AND D.D3_EMISSAO LIKE " + xQ(oPar["mes"] + "%") + " "
	cQ += "AND TRIM(D.D3_CF) NOT IN ('RE4', 'DE4') AND TRIM(D.D3_CF) NOT LIKE 'PR%'"

Return {cQ, "D.R_E_C_N_O_"}

//=============================================================================
// Saldos e fechamentos
//=============================================================================

// EST07 - saldos com data da ultima saida (US) e ultima entrada (UE)
Static Function qEST07(oPar)
	Local cQ := ""
	Local cH := xQ(oPar["hoje"])

	cQ += "SELECT TRIM(B2.B2_FILIAL) FILIAL, TRIM(B2.B2_COD) COD, P.DESCR, P.GRP, G.GRPD, P.UM, "
	cQ += "TRIM(B2.B2_LOCAL) LOC, N.LOCD, B2.B2_QATU Q, B2.B2_VATU1 V, US.ULT US, UE.ULT UE "
	cQ += "FROM " + xT("SB2") + " B2 "
	cQ += xPrd("B2.B2_FILIAL", "B2.B2_COD") + xGrp("B2.B2_FILIAL")
	cQ += xCad("OUTER", "NNR", "NR", "TRIM(NR.NNR_DESCRI) LOCD", "NR.NNR_CODIGO = B2.B2_LOCAL", "B2.B2_FILIAL", "N")
	cQ += "LEFT JOIN (SELECT D3_FILIAL, D3_COD, D3_LOCAL, MAX(D3_EMISSAO) ULT FROM " + xT("SD3") + " "
	cQ += "            WHERE D_E_L_E_T_ = ' ' AND D3_ESTORNO <> 'S' AND D3_CF LIKE 'RE%' AND D3_CF <> 'RE4' AND D3_EMISSAO <= " + cH + " "
	cQ += "            GROUP BY D3_FILIAL, D3_COD, D3_LOCAL) US "
	cQ += "       ON US.D3_FILIAL = B2.B2_FILIAL AND US.D3_COD = B2.B2_COD AND US.D3_LOCAL = B2.B2_LOCAL "
	cQ += "LEFT JOIN (SELECT FIL, COD, LOC, MAX(DT) ULT FROM ( "
	cQ += "             SELECT D1_FILIAL FIL, D1_COD COD, D1_LOCAL LOC, D1_DTDIGIT DT FROM " + xT("SD1") + " WHERE D_E_L_E_T_ = ' ' AND D1_TIPO = 'N' AND D1_DTDIGIT <= " + cH + " "
	cQ += "             UNION ALL "
	cQ += "             SELECT D3_FILIAL, D3_COD, D3_LOCAL, D3_EMISSAO FROM " + xT("SD3") + " WHERE D_E_L_E_T_ = ' ' AND D3_ESTORNO <> 'S' AND D3_CF LIKE 'DE%' AND D3_EMISSAO <= " + cH + " "
	cQ += "           ) E GROUP BY FIL, COD, LOC) UE ON UE.FIL = B2.B2_FILIAL AND UE.COD = B2.B2_COD AND UE.LOC = B2.B2_LOCAL "
	cQ += "WHERE B2.D_E_L_E_T_ = ' ' AND (B2.B2_QATU <> 0 OR B2.B2_VATU1 <> 0) AND " + xFPrd("P")

Return {cQ, "B2.B2_FILIAL, B2.B2_COD, B2.B2_LOCAL, B2.R_E_C_N_O_"}

// EST08 - fechamentos mensais (SB9)
Static Function qEST08(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(B9.B9_FILIAL) FILIAL, TRIM(B9.B9_DATA) DT, TRIM(B9.B9_LOCAL) LOC, P.GRP, MAX(G.GRPD) GRPD, SUM(B9.B9_VINI1) V, "
	cQ += "SUM(CASE WHEN B9.B9_QINI > 0 THEN 1 ELSE 0 END) N "
	cQ += "FROM " + xT("SB9") + " B9 "
	cQ += xPrd("B9.B9_FILIAL", "B9.B9_COD") + xGrp("B9.B9_FILIAL")
	cQ += "WHERE B9.D_E_L_E_T_ = ' ' AND B9.B9_DATA >= " + xQ(oPar["desde"]) + " AND " + xFPrd("P") + " "
	cQ += "GROUP BY TRIM(B9.B9_FILIAL), TRIM(B9.B9_DATA), TRIM(B9.B9_LOCAL), P.GRP"

Return {cQ, "1, 2, 3, 4"}

//=============================================================================
// Solicitacoes ao almoxarifado e prazo de atendimento
//=============================================================================

// EST09 - produtos com solicitacao ao armazem
Static Function qEST09(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(P.B1_COD) COD, TRIM(P.B1_DESC) DESCR, TRIM(P.B1_GRUPO) GRP, TRIM(G.BM_DESC) GRPD "
	cQ += "FROM " + xT("SB1") + " P LEFT JOIN " + xT("SBM") + " G ON G.D_E_L_E_T_ = ' ' AND G.BM_GRUPO = P.B1_GRUPO "
	cQ += "WHERE P.D_E_L_E_T_ = ' ' AND " + xFPrd("P") + " "
	cQ += "AND EXISTS (SELECT 1 FROM " + xT("SCP") + " C WHERE C.D_E_L_E_T_ = ' ' AND C.CP_PRODUTO = P.B1_COD)"

Return {cQ, "P.B1_COD, P.R_E_C_N_O_"}

// EST10 - primeiro/ultimo atendimento de cada item de SA
Static Function qEST10(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(D3_FILIAL) FIL, TRIM(D3_NUMSA) SA, TRIM(D3_ITEMSA) ITEM, MIN(D3_EMISSAO) PRI, MAX(D3_EMISSAO) ULT FROM " + xT("SD3") + " "
	cQ += "WHERE D_E_L_E_T_ = ' ' AND D3_ESTORNO <> 'S' AND TRIM(D3_NUMSA) <> '' AND D3_CF LIKE 'RE%' AND D3_CF <> 'RE4' "
	cQ += "GROUP BY TRIM(D3_FILIAL), TRIM(D3_NUMSA), TRIM(D3_ITEMSA)"

Return {cQ, "1, 2, 3"}

// EST11 - meses com solicitacao ao armazem
Static Function qEST11(oPar)
	Local cQ := ""

	cQ += "SELECT DISTINCT SUBSTRING(CP_EMISSAO, 1, 6) M FROM " + xT("SCP") + " "
	cQ += "WHERE D_E_L_E_T_ = ' ' AND CP_EMISSAO >= " + xQ(oPar["desde"]) + " AND CP_EMISSAO <= " + xQ(oPar["hoje"])

Return {cQ, "1"}

// EST12 - solicitacoes ao armazem do mes
Static Function qEST12(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(CP_FILIAL) FIL, TRIM(CP_NUM) NUM, TRIM(CP_ITEM) ITEM, CP_EMISSAO EMI, TRIM(CP_DATPRF) PRF, TRIM(CP_PRODUTO) COD, TRIM(CP_LOCAL) LOC, "
	cQ += "TRIM(CP_CC) CC, TRIM(CP_SOLICIT) SOL, CP_QUANT Q, CP_QUJE QJ, TRIM(CP_STATUS) ST "
	cQ += "FROM " + xT("SCP") + " WHERE D_E_L_E_T_ = ' ' AND CP_EMISSAO LIKE " + xQ(oPar["mes"] + "%")

Return {cQ, "CP_FILIAL, CP_NUM, CP_ITEM, R_E_C_N_O_"}

// EST13 - prazo: solicitacao -> pedido -> entrada
Static Function qEST13(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(N.D1_COD) COD, TRIM(P.B1_GRUPO) GRP, N.D1_DTDIGIT ENT, C7.C7_EMISSAO PED, C1.C1_EMISSAO SOL "
	cQ += "FROM " + xT("SD1") + " N "
	cQ += "JOIN " + xT("SB1") + " P ON P.D_E_L_E_T_ = ' ' AND P.B1_COD = N.D1_COD "
	cQ += "JOIN " + xT("SC7") + " C7 ON C7.D_E_L_E_T_ = ' ' AND C7.C7_FILIAL = N.D1_FILIAL AND C7.C7_NUM = N.D1_PEDIDO AND C7.C7_ITEM = N.D1_ITEMPC "
	cQ += "LEFT JOIN " + xT("SC1") + " C1 ON C1.D_E_L_E_T_ = ' ' AND C1.C1_FILIAL = C7.C7_FILIAL AND C1.C1_NUM = C7.C7_NUMSC AND C1.C1_ITEM = C7.C7_ITEMSC "
	cQ += "WHERE N.D_E_L_E_T_ = ' ' AND N.D1_TIPO = 'N' AND N.D1_DTDIGIT >= " + xQ(oPar["desde"]) + " AND " + xFPrd("P")

Return {cQ, "N.R_E_C_N_O_"}

//=============================================================================
// Saldo negativo e regularizacao
//=============================================================================

// EST14 - entradas por nota que movimentam estoque
Static Function qEST14(oPar)
	Local cQ := ""

	cQ += "SELECT CONCAT(TRIM(N.D1_COD), '|', TRIM(N.D1_LOCAL)) K, TRIM(N.D1_NUMSEQ) SEQ, N.D1_DTDIGIT DT, 'SD1' FONTE, TRIM(N.D1_TIPO) TIPO, "
	cQ += "CAST(NULL AS VARCHAR(3)) TM, TRIM(N.D1_DOC) DOC, CAST(NULL AS VARCHAR(20)) NFORI, CAST(NULL AS VARCHAR(25)) USR, N.D1_QUANT Q "
	cQ += "FROM " + xT("SD1") + " N JOIN " + xT("SF4") + " F ON F.D_E_L_E_T_ = ' ' AND F.F4_CODIGO = N.D1_TES "
	cQ += "JOIN " + xT("SB1") + " P ON P.D_E_L_E_T_ = ' ' AND P.B1_COD = N.D1_COD "
	cQ += "WHERE N.D_E_L_E_T_ = ' ' AND F.F4_ESTOQUE = 'S' AND " + xFPrd("P")

Return {cQ, "N.R_E_C_N_O_"}

// EST15 - saidas por nota que movimentam estoque
Static Function qEST15(oPar)
	Local cQ := ""

	cQ += "SELECT CONCAT(TRIM(N.D2_COD), '|', TRIM(N.D2_LOCAL)) K, TRIM(N.D2_NUMSEQ) SEQ, N.D2_EMISSAO DT, 'SD2' FONTE, TRIM(N.D2_TIPO) TIPO, "
	cQ += "CAST(NULL AS VARCHAR(3)) TM, TRIM(N.D2_DOC) DOC, TRIM(N.D2_NFORI) NFORI, CAST(NULL AS VARCHAR(25)) USR, -N.D2_QUANT Q "
	cQ += "FROM " + xT("SD2") + " N JOIN " + xT("SF4") + " F ON F.D_E_L_E_T_ = ' ' AND F.F4_CODIGO = N.D2_TES "
	cQ += "JOIN " + xT("SB1") + " P ON P.D_E_L_E_T_ = ' ' AND P.B1_COD = N.D2_COD "
	cQ += "WHERE N.D_E_L_E_T_ = ' ' AND F.F4_ESTOQUE = 'S' AND " + xFPrd("P")

Return {cQ, "N.R_E_C_N_O_"}

// EST16 - produtos com saldo cadastrado
Static Function qEST16(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(P.B1_COD) COD, TRIM(P.B1_DESC) DESCR, TRIM(G.BM_DESC) GRPD "
	cQ += "FROM " + xT("SB1") + " P LEFT JOIN " + xT("SBM") + " G ON G.D_E_L_E_T_ = ' ' AND G.BM_GRUPO = P.B1_GRUPO "
	cQ += "WHERE P.D_E_L_E_T_ = ' ' AND " + xFPrd("P") + " "
	cQ += "AND EXISTS (SELECT 1 FROM " + xT("SB2") + " B WHERE B.D_E_L_E_T_ = ' ' AND B.B2_COD = P.B1_COD)"

Return {cQ, "P.B1_COD, P.R_E_C_N_O_"}

// EST17 - saldo atual por produto|armazem
Static Function qEST17(oPar)
	Local cQ := ""

	cQ += "SELECT CONCAT(TRIM(B2.B2_COD), '|', TRIM(B2.B2_LOCAL)) K, B2.B2_QATU Q FROM " + xT("SB2") + " B2 "
	cQ += "JOIN " + xT("SB1") + " P ON P.D_E_L_E_T_ = ' ' AND P.B1_COD = B2.B2_COD "
	cQ += "WHERE B2.D_E_L_E_T_ = ' ' AND " + xFPrd("P")

Return {cQ, "B2.R_E_C_N_O_"}

// EST18 - meses com movimento interno (sem filtro de estorno, como no original)
Static Function qEST18(oPar)
	Local cQ := ""

	cQ += "SELECT DISTINCT SUBSTRING(D3_EMISSAO, 1, 6) M FROM " + xT("SD3") + " WHERE D_E_L_E_T_ = ' '"

Return {cQ, "1"}

// EST19 - movimentos internos do mes para o calculo de saldo negativo
Static Function qEST19(oPar)
	Local cQ := ""

	cQ += "SELECT CONCAT(TRIM(D.D3_COD), '|', TRIM(D.D3_LOCAL)) K, TRIM(D.D3_NUMSEQ) SEQ, D.D3_EMISSAO DT, 'SD3' FONTE, TRIM(D.D3_CF) TIPO, TRIM(D.D3_TM) TM, "
	cQ += "TRIM(D.D3_DOC) DOC, CAST(NULL AS VARCHAR(20)) NFORI, TRIM(D.D3_USUARIO) USR, CASE WHEN D.D3_TM > '500' THEN -D.D3_QUANT ELSE D.D3_QUANT END Q "
	cQ += "FROM " + xT("SD3") + " D JOIN " + xT("SB1") + " P ON P.D_E_L_E_T_ = ' ' AND P.B1_COD = D.D3_COD "
	cQ += "WHERE D.D_E_L_E_T_ = ' ' AND D.D3_ESTORNO <> 'S' AND D.D3_EMISSAO LIKE " + xQ(oPar["mes"] + "%") + " AND " + xFPrd("P")

Return {cQ, "D.R_E_C_N_O_"}

//=============================================================================
// Inventarios e ajustes
//=============================================================================

// EST20 - contagens de inventario (SB7)
Static Function qEST20(oPar)
	Local cQ := ""

	cQ += "SELECT B7.B7_DATA DT, TRIM(B7.B7_COD) COD, TRIM(B7.B7_LOCAL) LOC, SUM(B7.B7_QUANT) Q FROM " + xT("SB7") + " B7 "
	cQ += "JOIN " + xT("SB1") + " P ON P.D_E_L_E_T_ = ' ' AND P.B1_COD = B7.B7_COD "
	cQ += "WHERE B7.D_E_L_E_T_ = ' ' AND B7.B7_DATA >= " + xQ(oPar["desde"]) + " AND B7.B7_DATA <= " + xQ(oPar["hoje"]) + " AND " + xFPrd("P") + " "
	cQ += "GROUP BY B7.B7_DATA, TRIM(B7.B7_COD), TRIM(B7.B7_LOCAL)"

Return {cQ, "1, 2, 3"}

// EST21 - ajustes gerados pelo inventario (SD3 doc INVENT)
Static Function qEST21(oPar)
	Local cQ := ""

	cQ += "SELECT D3_EMISSAO DT, TRIM(D3_COD) COD, TRIM(D3_LOCAL) LOC, SUM(CASE WHEN D3_TM <= '500' THEN D3_QUANT ELSE -D3_QUANT END) Q, "
	cQ += "SUM(CASE WHEN D3_TM <= '500' THEN D3_CUSTO1 ELSE -D3_CUSTO1 END) V "
	cQ += "FROM " + xT("SD3") + " WHERE D_E_L_E_T_ = ' ' AND D3_ESTORNO <> 'S' AND TRIM(D3_DOC) = 'INVENT' "
	cQ += "AND D3_EMISSAO >= " + xQ(oPar["desde"]) + " AND D3_COD NOT LIKE 'MOD%' "
	cQ += "GROUP BY D3_EMISSAO, TRIM(D3_COD), TRIM(D3_LOCAL)"

Return {cQ, "1, 2, 3"}

// EST22 - ajustes manuais de estoque
Static Function qEST22(oPar)
	Local cQ := ""

	cQ += "SELECT D.R_E_C_N_O_ RID, TRIM(D.D3_FILIAL) FILIAL, D.D3_EMISSAO DT, TRIM(D.D3_COD) COD, P.DESCR DS, TRIM(D.D3_LOCAL) LOC, TRIM(D.D3_TM) TM, F.TP, "
	cQ += "TRIM(D.D3_DOC) DOC, TRIM(D.D3_USUARIO) USR, CASE WHEN D.D3_TM <= '500' THEN D.D3_QUANT ELSE -D.D3_QUANT END Q, "
	cQ += "CASE WHEN D.D3_TM <= '500' THEN D.D3_CUSTO1 ELSE -D.D3_CUSTO1 END V "
	cQ += "FROM " + xT("SD3") + " D "
	cQ += xPrd("D.D3_FILIAL", "D.D3_COD")
	cQ += xCad("OUTER", "SF5", "F5", "TRIM(F5.F5_TEXTO) TP", "F5.F5_CODIGO = D.D3_TM", "D.D3_FILIAL", "F")
	cQ += "WHERE D.D_E_L_E_T_ = ' ' AND D.D3_ESTORNO <> 'S' AND D.D3_EMISSAO >= " + xQ(oPar["desde"]) + " AND D.D3_EMISSAO <= " + xQ(oPar["hoje"]) + " "
	cQ += "AND " + xFPrd("P") + " "
	cQ += "AND TRIM(D.D3_DOC) <> 'INVENT' AND (D.D3_TM IN ('001', '002', '005') OR TRIM(D.D3_DOC) LIKE 'AJ%')"

Return {cQ, "D.R_E_C_N_O_"}

// EST23 - entradas e saidas por dia/produto/armazem (NF entrada, NF saida e SD3)
Static Function qEST23(oPar)
	Local cQ := ""
	Local cDe := xQ(oPar["de"])
	Local cAte := xQ(oPar["hoje"])

	cQ += "SELECT M.DT, M.COD, MAX(TRIM(P.B1_DESC)) DS, M.LOC, SUM(CASE WHEN M.Q > 0 THEN M.Q ELSE 0 END) E, "
	cQ += "SUM(CASE WHEN M.Q < 0 THEN -M.Q ELSE 0 END) S, COUNT(*) N "
	cQ += "FROM ( "
	cQ += "  SELECT N.D1_DTDIGIT DT, TRIM(N.D1_COD) COD, TRIM(N.D1_LOCAL) LOC, N.D1_QUANT Q FROM " + xT("SD1") + " N "
	cQ += "    JOIN " + xT("SF4") + " F ON F.D_E_L_E_T_ = ' ' AND F.F4_CODIGO = N.D1_TES "
	cQ += "   WHERE N.D_E_L_E_T_ = ' ' AND F.F4_ESTOQUE = 'S' AND N.D1_DTDIGIT BETWEEN " + cDe + " AND " + cAte + " "
	cQ += "  UNION ALL "
	cQ += "  SELECT N.D2_EMISSAO, TRIM(N.D2_COD), TRIM(N.D2_LOCAL), -N.D2_QUANT FROM " + xT("SD2") + " N "
	cQ += "    JOIN " + xT("SF4") + " F ON F.D_E_L_E_T_ = ' ' AND F.F4_CODIGO = N.D2_TES "
	cQ += "   WHERE N.D_E_L_E_T_ = ' ' AND F.F4_ESTOQUE = 'S' AND N.D2_EMISSAO BETWEEN " + cDe + " AND " + cAte + " "
	cQ += "  UNION ALL "
	cQ += "  SELECT D3_EMISSAO, TRIM(D3_COD), TRIM(D3_LOCAL), CASE WHEN D3_TM > '500' THEN -D3_QUANT ELSE D3_QUANT END FROM " + xT("SD3") + " "
	cQ += "   WHERE D_E_L_E_T_ = ' ' AND D3_ESTORNO <> 'S' AND D3_EMISSAO BETWEEN " + cDe + " AND " + cAte + " "
	cQ += ") M JOIN " + xT("SB1") + " P ON P.D_E_L_E_T_ = ' ' AND TRIM(P.B1_COD) = M.COD "
	cQ += "WHERE " + xFPrd("P") + " "
	cQ += "GROUP BY M.DT, M.COD, M.LOC"

Return {cQ, "1, 2, 4"}

//=============================================================================
// EPI
//=============================================================================

// EPI01 - validade do CA por EPI/fornecedor/loja/CA
Static Function qEPI01(oPar)
	Local cQ := ""

	cQ += "SELECT CONCAT(TRIM(TN3_CODEPI), '|', TRIM(TN3_FORNEC), '|', TRIM(TN3_LOJA), '|', TRIM(TN3_NUMCAP)) K, TRIM(TN3_DTVENC) VENC "
	cQ += "FROM " + xT("TN3") + " WHERE D_E_L_E_T_ = ' '"

Return {cQ, "R_E_C_N_O_"}

// EPI02 - meses com entrega de EPI
Static Function qEPI02(oPar)
	Local cQ := ""

	cQ += "SELECT DISTINCT SUBSTRING(TNF_DTENTR, 1, 6) M FROM " + xT("TNF") + " "
	cQ += "WHERE D_E_L_E_T_ = ' ' AND TNF_DTENTR >= " + xQ(oPar["desde"]) + " AND TNF_DTENTR <= " + xQ(oPar["hoje"])

Return {cQ, "1"}

// EPI03 - entregas de EPI do mes
Static Function qEPI03(oPar)
	Local cQ := ""

	cQ += "SELECT R_E_C_N_O_ RID, TRIM(TNF_FILIAL) FIL, TRIM(TNF_MAT) MAT, TRIM(TNF_CODEPI) EPI, TNF_DTENTR DT, TNF_QTDENT Q, TNF_QTDEVO DEV, TNF_CUSTO C, "
	cQ += "TRIM(TNF_MOTIVO) MOT, TRIM(TNF_CODFUN) FUN, CONCAT(TRIM(TNF_CODEPI), '|', TRIM(TNF_FORNEC), '|', TRIM(TNF_LOJA), '|', TRIM(TNF_NUMCAP)) K "
	cQ += "FROM " + xT("TNF") + " WHERE D_E_L_E_T_ = ' ' AND TNF_DTENTR LIKE " + xQ(oPar["mes"] + "%") + " AND TNF_DTENTR <= " + xQ(oPar["hoje"])

Return {cQ, "R_E_C_N_O_"}

// EPI04 - funcionarios com funcao
Static Function qEPI04(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(R.RA_FILIAL) FIL, TRIM(R.RA_MAT) MAT, TRIM(R.RA_NOME) NOME, TRIM(R.RA_CODFUNC) FUN, TRIM(J.RJ_DESC) FUND, TRIM(R.RA_CC) CC, "
	cQ += "TRIM(R.RA_ADMISSA) ADM, TRIM(R.RA_DEMISSA) DEM "
	cQ += "FROM " + xT("SRA") + " R LEFT JOIN " + xT("SRJ") + " J ON J.D_E_L_E_T_ = ' ' AND J.RJ_FUNCAO = R.RA_CODFUNC "
	cQ += "WHERE R.D_E_L_E_T_ = ' '"

Return {cQ, "R.RA_FILIAL, R.RA_MAT, R.R_E_C_N_O_"}

// EPI05 - produtos usados como EPI (entregue ou generico)
Static Function qEPI05(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(P.B1_COD) COD, TRIM(P.B1_DESC) DS FROM " + xT("SB1") + " P "
	cQ += "WHERE P.D_E_L_E_T_ = ' ' AND (EXISTS (SELECT 1 FROM " + xT("TNF") + " F WHERE F.D_E_L_E_T_ = ' ' AND F.TNF_CODEPI = P.B1_COD) "
	cQ += "   OR EXISTS (SELECT 1 FROM " + xT("TL0") + " G WHERE G.D_E_L_E_T_ = ' ' AND G.TL0_EPIGEN = P.B1_COD))"

Return {cQ, "P.B1_COD, P.R_E_C_N_O_"}

// EPI06 - EPI generico x filho
Static Function qEPI06(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(TL0_EPIGEN) GEN, TRIM(TL0_EPIFIL) FIL FROM " + xT("TL0") + " WHERE D_E_L_E_T_ = ' '"

Return {cQ, "R_E_C_N_O_"}

// EPI07 - durabilidade por EPI
Static Function qEPI07(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(TN3_CODEPI) COD, MAX(TN3_DURABI) D FROM " + xT("TN3") + " WHERE D_E_L_E_T_ = ' ' GROUP BY TRIM(TN3_CODEPI)"

Return {cQ, "1"}

// EPI08 - EPI por funcao
Static Function qEPI08(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(TNB_CODFUN) FUN, TRIM(TNB_CODEPI) EPI, TRIM(TNB_COMBO) C FROM " + xT("TNB") + " WHERE D_E_L_E_T_ = ' '"

Return {cQ, "R_E_C_N_O_"}
