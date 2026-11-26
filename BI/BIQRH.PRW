#include 'protheus.ch'

/*/{Protheus.doc} BIQRH
Consultas do BI - 5. Folha agregada (FOL), 6. RH por pessoa (RHU) e
7. Medicina do trabalho (MED).
Chamado por APIBI.PRW. Retorna {cSql, cOrdem} ou uma string com a mensagem de erro.

Nao le CPF/PIS/RG/endereco/contato/nascimento.

@author Thiago Sales - Quebec Ambiental
@since 2026-11-11
/*/

// Verbas de rescisao usadas em MED05 (codigos do ambiente de origem - conferir
// no cadastro SRV desta empresa antes de usar)
#define BI_RES_EXCL  "'253', '354'"   // nao somam no valor pago
#define BI_RES_AVISO "'107'"          // aviso previo
#define BI_RES_MULTA "'877'"          // multa FGTS

User Function BIQRH(cId, oPar)

	Do Case
	Case cId == "FOL01" ; Return qFOL01(oPar)
	Case cId == "FOL02" ; Return qFOL02(oPar)
	Case cId == "FOL03" ; Return qFOL03(oPar)
	Case cId == "FOL04" ; Return qFOL04(oPar)
	Case cId == "FOL05" ; Return qFOL05(oPar)
	Case cId == "FOL06" ; Return qFOL06(oPar)
	Case cId == "FOL07" ; Return qFOL07(oPar)
	Case cId == "FOL08" ; Return qFOL08(oPar)
	Case cId == "FOL09" ; Return qFOL09(oPar)
	Case cId == "RHU01" ; Return qRHU01(oPar)
	Case cId == "RHU02" ; Return qRHU02(oPar)
	Case cId == "RHU03" ; Return qRHU03(oPar)
	Case cId == "RHU04" ; Return qRHU04(oPar)
	Case cId == "RHU05" ; Return qRHU05(oPar)
	Case cId == "RHU06" ; Return qRHU06(oPar)
	Case cId == "RHU07" ; Return qRHU07(oPar)
	Case cId == "RHU08" ; Return qRHU08(oPar)
	Case cId == "RHU09" ; Return qRHU09(oPar)
	Case cId == "MED01" ; Return qMED01(oPar)
	Case cId == "MED02" ; Return qMED02(oPar)
	Case cId == "MED03" ; Return qMED03(oPar)
	Case cId == "MED04" ; Return qMED04(oPar)
	Case cId == "MED05" ; Return qMED05(oPar)
	Case cId == "MED06" ; Return qMED06(oPar)
	EndCase

Return Nil

Static Function xT(cAlias)
Return RetSqlName(cAlias)

Static Function xQ(cVal)
Return "'" + cVal + "'"

// Lista opcional: sem codigos vira '' (o IN nao encontra nada, como lista vazia)
Static Function xLst(cLista)
Return iif(Empty(cLista), "''", cLista)

//=============================================================================
// 5. FOLHA (agregados)
//=============================================================================

// FOL01 - lancamentos fechados (SRD) por competencia/roteiro/CC/verba
Static Function qFOL01(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(RD_FILIAL) FILIAL, TRIM(RD_DATARQ) YM, TRIM(RD_ROTEIR) ROT, TRIM(RD_CC) CC, TRIM(RD_PD) PD, "
	cQ += "SUM(RD_VALOR) V, SUM(RD_HORAS) H, COUNT(DISTINCT RD_FILIAL + RD_MAT) P "
	cQ += "FROM " + xT("SRD") + " "
	cQ += "WHERE D_E_L_E_T_ = ' ' AND RD_DATARQ >= " + xQ(oPar["desde"]) + " AND TRIM(RD_ROTEIR) <> 'ADI' "
	cQ += "GROUP BY TRIM(RD_FILIAL), TRIM(RD_DATARQ), TRIM(RD_ROTEIR), TRIM(RD_CC), TRIM(RD_PD)"

Return {cQ, "1, 2, 3, 4, 5"}

// FOL02 - previa do mes em calculo (SRC)
Static Function qFOL02(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(RC_PERIODO) YM, TRIM(RC_ROTEIR) ROT, TRIM(RC_CC) CC, TRIM(RC_PD) PD, "
	cQ += "SUM(RC_VALOR) V, SUM(RC_HORAS) H, COUNT(DISTINCT RC_FILIAL + RC_MAT) P "
	cQ += "FROM " + xT("SRC") + " "
	cQ += "WHERE D_E_L_E_T_ = ' ' AND RC_PERIODO > " + xQ(oPar["ultima"]) + " AND TRIM(RC_ROTEIR) <> 'ADI' "
	cQ += "GROUP BY TRIM(RC_PERIODO), TRIM(RC_ROTEIR), TRIM(RC_CC), TRIM(RC_PD)"

Return {cQ, "1, 2, 3, 4"}

// FOL03 - pessoas distintas por competencia (SRD)
Static Function qFOL03(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(RD_DATARQ) YM, COUNT(DISTINCT RD_FILIAL + RD_MAT) P "
	cQ += "FROM " + xT("SRD") + " WHERE D_E_L_E_T_ = ' ' AND RD_DATARQ >= " + xQ(oPar["desde"]) + " AND TRIM(RD_ROTEIR) <> 'ADI' "
	cQ += "GROUP BY TRIM(RD_DATARQ)"

Return {cQ, "1"}

// FOL04 - pessoas distintas por competencia (SRC)
Static Function qFOL04(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(RC_PERIODO) YM, COUNT(DISTINCT RC_FILIAL + RC_MAT) P "
	cQ += "FROM " + xT("SRC") + " WHERE D_E_L_E_T_ = ' ' AND RC_PERIODO > " + xQ(oPar["ultima"]) + " AND TRIM(RC_ROTEIR) <> 'ADI' "
	cQ += "GROUP BY TRIM(RC_PERIODO)"

Return {cQ, "1"}

// FOL05 - pessoas distintas por competencia e CC (SRD)
Static Function qFOL05(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(RD_DATARQ) YM, TRIM(RD_CC) CC, COUNT(DISTINCT RD_FILIAL + RD_MAT) P "
	cQ += "FROM " + xT("SRD") + " WHERE D_E_L_E_T_ = ' ' AND RD_DATARQ >= " + xQ(oPar["desde"]) + " AND TRIM(RD_ROTEIR) <> 'ADI' "
	cQ += "GROUP BY TRIM(RD_DATARQ), TRIM(RD_CC)"

Return {cQ, "1, 2"}

// FOL06 - pessoas distintas por competencia e CC (SRC)
Static Function qFOL06(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(RC_PERIODO) YM, TRIM(RC_CC) CC, COUNT(DISTINCT RC_FILIAL + RC_MAT) P "
	cQ += "FROM " + xT("SRC") + " WHERE D_E_L_E_T_ = ' ' AND RC_PERIODO > " + xQ(oPar["ultima"]) + " AND TRIM(RC_ROTEIR) <> 'ADI' "
	cQ += "GROUP BY TRIM(RC_PERIODO), TRIM(RC_CC)"

Return {cQ, "1, 2"}

// FOL07 - cadastro de verbas (colunas PD, D, TIPO, ID)
Static Function qFOL07(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(RV_COD) PD, MAX(TRIM(RV_DESC)) D, MAX(TRIM(RV_TIPOCOD)) TIPO, MAX(TRIM(RV_CODFOL)) ID "
	cQ += "FROM " + xT("SRV") + " WHERE D_E_L_E_T_ = ' ' GROUP BY TRIM(RV_COD)"

Return {cQ, "1"}

// FOL08 - quadro de hoje por CC e situacao.
// O original usava MAX((SELECT ...)), que o SQL Server nao aceita
// (agregacao sobre subconsulta); a descricao e buscada apos agrupar.
Static Function qFOL08(oPar)
	Local cQ := ""

	cQ += "SELECT Q.FILIAL, Q.CC, (SELECT MAX(TRIM(CTT_DESC01)) FROM " + xT("CTT") + " WHERE D_E_L_E_T_ = ' ' AND CTT_CUSTO = Q.CC) CC_DESC, "
	cQ += "Q.SIT, Q.N "
	cQ += "FROM (SELECT TRIM(RA.RA_FILIAL) FILIAL, TRIM(RA.RA_CC) CC, TRIM(RA.RA_SITFOLH) SIT, COUNT(*) N "
	cQ += "        FROM " + xT("SRA") + " RA "
	cQ += "       WHERE RA.D_E_L_E_T_ = ' ' AND TRIM(RA.RA_DEMISSA) = '' "
	cQ += "       GROUP BY TRIM(RA.RA_FILIAL), TRIM(RA.RA_CC), TRIM(RA.RA_SITFOLH)) Q"

Return {cQ, "1, 2, 4"}

// FOL09 - admissoes e demissoes por mes e CC
Static Function qFOL09(oPar)
	Local cQ := ""

	cQ += "SELECT FILIAL, YM, CC, SUM(ADM) ADM, SUM(DEM) DEM FROM ( "
	cQ += "  SELECT TRIM(RA_FILIAL) FILIAL, SUBSTRING(RA_ADMISSA, 1, 6) YM, TRIM(RA_CC) CC, 1 ADM, 0 DEM FROM " + xT("SRA") + " "
	cQ += "   WHERE D_E_L_E_T_ = ' ' AND SUBSTRING(RA_ADMISSA, 1, 6) >= " + xQ(oPar["desde"]) + " "
	cQ += "  UNION ALL "
	cQ += "  SELECT TRIM(RA_FILIAL) FILIAL, SUBSTRING(RA_DEMISSA, 1, 6) YM, TRIM(RA_CC) CC, 0 ADM, 1 DEM FROM " + xT("SRA") + " "
	cQ += "   WHERE D_E_L_E_T_ = ' ' AND TRIM(RA_DEMISSA) <> '' AND SUBSTRING(RA_DEMISSA, 1, 6) >= " + xQ(oPar["desde"]) + " "
	cQ += ") X GROUP BY FILIAL, YM, CC"

Return {cQ, "1, 2, 3"}

//=============================================================================
// 6. RH - pessoas, ferias, afastamentos, hora extra
//=============================================================================

// RHU01 - pessoas ativas
Static Function qRHU01(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(A.RA_FILIAL) FIL, TRIM(A.RA_MAT) MAT, TRIM(A.RA_NOME) NOME, TRIM(A.RA_CC) CC, "
	cQ += "(SELECT MAX(TRIM(C.CTT_DESC01)) FROM " + xT("CTT") + " C WHERE C.D_E_L_E_T_ = ' ' AND C.CTT_CUSTO = A.RA_CC) CCD, "
	cQ += "TRIM(A.RA_CODFUNC) FUNC, (SELECT MAX(TRIM(J.RJ_DESC)) FROM " + xT("SRJ") + " J WHERE J.D_E_L_E_T_ = ' ' AND J.RJ_FUNCAO = A.RA_CODFUNC) FUNCD, "
	cQ += "TRIM(A.RA_CARGO) CARGO, (SELECT MAX(TRIM(Q.Q3_DESCSUM)) FROM " + xT("SQ3") + " Q WHERE Q.D_E_L_E_T_ = ' ' AND Q.Q3_CARGO = A.RA_CARGO) CARGOD, "
	cQ += "TRIM(A.RA_DEPTO) DEPTO, (SELECT MAX(TRIM(B.QB_DESCRIC)) FROM " + xT("SQB") + " B WHERE B.D_E_L_E_T_ = ' ' AND B.QB_DEPTO = A.RA_DEPTO) DEPTOD, "
	cQ += "TRIM(A.RA_ADMISSA) ADM, A.RA_SALARIO SAL, A.RA_HRSMES HRS, TRIM(A.RA_SITFOLH) SIT "
	cQ += "FROM " + xT("SRA") + " A "
	cQ += "WHERE A.D_E_L_E_T_ = ' ' AND A.RA_SITFOLH <> 'D' AND TRIM(A.RA_DEMISSA) = ''"

Return {cQ, "A.RA_FILIAL, A.RA_MAT"}

// RHU02 - ultima competencia fechada
Static Function qRHU02(oPar)
	Local cQ := ""

	cQ += "SELECT MAX(RD_DATARQ) YM FROM " + xT("SRD") + " WHERE D_E_L_E_T_ = ' '"

Return {cQ, ""}

// RHU03 - cadastro de verbas (colunas PD, DESCR, TIPO, IDFOL)
Static Function qRHU03(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(RV_COD) PD, MAX(TRIM(RV_DESC)) DESCR, MAX(TRIM(RV_TIPOCOD)) TIPO, MAX(TRIM(RV_CODFOL)) IDFOL "
	cQ += "FROM " + xT("SRV") + " WHERE D_E_L_E_T_ = ' ' GROUP BY RV_COD"

Return {cQ, "1"}

// RHU04 - matriculas com folha no periodo
Static Function qRHU04(oPar)
	Local cQ := ""

	cQ += "SELECT DISTINCT CONCAT(TRIM(RD_FILIAL), '|', TRIM(RD_MAT)) K FROM " + xT("SRD") + " "
	cQ += "WHERE D_E_L_E_T_ = ' ' AND RD_DATARQ BETWEEN " + xQ(oPar["de"]) + " AND " + xQ(oPar["ate"])

Return {cQ, "1"}

// RHU05 - valor por matricula das verbas da lista
Static Function qRHU05(oPar)
	Local cQ := ""

	cQ += "SELECT CONCAT(TRIM(RD_FILIAL), '|', TRIM(RD_MAT)) K, SUM(RD_VALOR) V FROM " + xT("SRD") + " "
	cQ += "WHERE D_E_L_E_T_ = ' ' AND RD_DATARQ BETWEEN " + xQ(oPar["de"]) + " AND " + xQ(oPar["ate"]) + " "
	cQ += "AND TRIM(RD_PD) IN (" + oPar["lista"] + ") "
	cQ += "GROUP BY RD_FILIAL, RD_MAT"

Return {cQ, "1"}

// RHU06 - ferias vencidas / a vencer (SRF)
Static Function qRHU06(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(RF_FILIAL) FIL, TRIM(RF_MAT) MAT, TRIM(RF_DATABAS) INI, TRIM(RF_DATAFIM) FIM, RF_DIASDIR DIR, "
	cQ += "TRIM(RF_DATAINI) PROG, RF_DFEPRO1 PDIAS "
	cQ += "FROM " + xT("SRF") + " "
	cQ += "WHERE D_E_L_E_T_ = ' ' AND (RF_STATUS = '1' OR TRIM(RF_STATUS) = '') AND TRIM(RF_DATAFIM) <> '' "
	cQ += "AND RF_DATAFIM < " + xQ(oPar["hoje"])

Return {cQ, "1, 2, 3"}

// RHU07 - dias de ferias gozados por periodo aquisitivo (SRH)
Static Function qRHU07(oPar)
	Local cQ := ""

	cQ += "SELECT CONCAT(TRIM(RH_FILIAL), '|', TRIM(RH_MAT), '|', TRIM(RH_DATABAS)) K, SUM(RH_DFERIAS + RH_DABONPE) D "
	cQ += "FROM " + xT("SRH") + " WHERE D_E_L_E_T_ = ' ' GROUP BY RH_FILIAL, RH_MAT, RH_DATABAS"

Return {cQ, "1"}

// RHU08 - afastamentos em aberto (SR8/RCM)
Static Function qRHU08(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(R.R8_FILIAL) FIL, TRIM(R.R8_MAT) MAT, TRIM(R.R8_TIPOAFA) TIPO, "
	cQ += "(SELECT MAX(TRIM(M.RCM_DESCRI)) FROM " + xT("RCM") + " M WHERE M.D_E_L_E_T_ = ' ' AND M.RCM_TIPO = R.R8_TIPOAFA) DESCR, "
	cQ += "TRIM(R.R8_DATAINI) INI, TRIM(R.R8_DATAFIM) FIM "
	cQ += "FROM " + xT("SR8") + " R "
	cQ += "WHERE R.D_E_L_E_T_ = ' ' AND TRIM(R.R8_DATAINI) <= " + xQ(oPar["hoje"]) + " "
	cQ += "AND (TRIM(R.R8_DATAFIM) = '' OR TRIM(R.R8_DATAFIM) >= " + xQ(oPar["hoje"]) + ")"

Return {cQ, "R.R8_FILIAL, R.R8_MAT, R.R8_DATAINI, R.R_E_C_N_O_"}

// RHU09 - hora extra por matricula/competencia (verbas da lista)
Static Function qRHU09(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(RD_FILIAL) FIL, TRIM(RD_MAT) MAT, TRIM(RD_DATARQ) YM, SUM(RD_VALOR) V, SUM(RD_HORAS) H "
	cQ += "FROM " + xT("SRD") + " "
	cQ += "WHERE D_E_L_E_T_ = ' ' AND RD_DATARQ BETWEEN " + xQ(oPar["de"]) + " AND " + xQ(oPar["ate"]) + " "
	cQ += "AND TRIM(RD_PD) IN (" + oPar["lista"] + ") "
	cQ += "GROUP BY TRIM(RD_FILIAL), TRIM(RD_MAT), TRIM(RD_DATARQ)"

Return {cQ, "1, 2, 3"}

//=============================================================================
// 7. MEDICINA DO TRABALHO
//=============================================================================

// MED01 - atestados (TNY). TNY_XLOCAT e campo customizado: sem ele vem vazio.
Static Function qMED01(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(A.RA_FILIAL) FIL, TRIM(A.RA_MAT) MAT, TRIM(A.RA_NOME) NOME, TRIM(N.TNY_NUMFIC) FIC, TRIM(A.RA_CC) CC, "
	cQ += "(SELECT MAX(TRIM(C.CTT_DESC01)) FROM " + xT("CTT") + " C WHERE C.D_E_L_E_T_ = ' ' AND C.CTT_CUSTO = A.RA_CC) CCD, "
	cQ += "(SELECT MAX(TRIM(J.RJ_DESC)) FROM " + xT("SRJ") + " J WHERE J.D_E_L_E_T_ = ' ' AND J.RJ_FUNCAO = A.RA_CODFUNC) FUNCD, "
	cQ += "TRIM(A.RA_SITFOLH) SIT, TRIM(A.RA_DEMISSA) DEM, "
	cQ += "TRIM(N.TNY_DTINIC) INI, TRIM(N.TNY_HRINIC) HI, TRIM(N.TNY_DTFIM) FIM, TRIM(N.TNY_HRFIM) HF, TRIM(N.TNY_CID) CID, "
	cQ += "(SELECT MAX(TRIM(R.TMR_DOENCA)) FROM " + xT("TMR") + " R WHERE R.D_E_L_E_T_ = ' ' AND TRIM(R.TMR_CID) = TRIM(N.TNY_CID)) CIDD, "
	cQ += "(SELECT MAX(TRIM(P.TNP_NOME)) FROM " + xT("TNP") + " P WHERE P.D_E_L_E_T_ = ' ' AND P.TNP_EMITEN = N.TNY_EMITEN) MED, "
	cQ += U_BICOL("TNY", "TNY_XLOCAT", "TRIM(N.TNY_XLOCAT)") + " UPA, TRIM(N.TNY_ACIDEN) ACID "
	cQ += "FROM " + xT("TNY") + " N "
	cQ += "JOIN " + xT("TM0") + " M ON M.D_E_L_E_T_ = ' ' AND M.TM0_NUMFIC = N.TNY_NUMFIC "
	cQ += "JOIN " + xT("SRA") + " A ON A.D_E_L_E_T_ = ' ' AND A.RA_MAT = M.TM0_MAT AND A.RA_FILIAL = M.TM0_FILFUN "
	cQ += "WHERE N.D_E_L_E_T_ = ' ' AND N.TNY_DTINIC >= " + xQ(oPar["desde"])

Return {cQ, "N.TNY_DTINIC, N.R_E_C_N_O_"}

// MED02 - custo por pessoa/competencia (bruto, encargo, extra, atestado, falta)
Static Function qMED02(oPar)
	Local cQ := ""

	cQ += "SELECT G.FIL, G.MAT, G.YM, G.CC, G.B, G.E, G.X, G.AT, G.AD, G.FA, "
	cQ += "(SELECT MAX(TRIM(C.CTT_DESC01)) FROM " + xT("CTT") + " C WHERE C.D_E_L_E_T_ = ' ' AND TRIM(C.CTT_CUSTO) = G.CC) CCD, "
	cQ += "(SELECT MAX(TRIM(J.RJ_DESC)) FROM " + xT("SRA") + " A JOIN " + xT("SRJ") + " J ON J.D_E_L_E_T_ = ' ' AND J.RJ_FUNCAO = A.RA_CODFUNC "
	cQ += "  WHERE A.D_E_L_E_T_ = ' ' AND A.RA_FILIAL = G.RFIL AND A.RA_MAT = G.RMAT) FUNCD "
	cQ += "FROM (SELECT D.RD_FILIAL RFIL, D.RD_MAT RMAT, TRIM(D.RD_FILIAL) FIL, TRIM(D.RD_MAT) MAT, TRIM(D.RD_DATARQ) YM, MAX(TRIM(D.RD_CC)) CC, "
	cQ += "        SUM(CASE WHEN TRIM(D.RD_PD) IN (" + xLst(oPar["vbruto"])   + ") THEN D.RD_VALOR ELSE 0 END) B, "
	cQ += "        SUM(CASE WHEN TRIM(D.RD_PD) IN (" + xLst(oPar["vencargo"]) + ") THEN D.RD_VALOR ELSE 0 END) E, "
	cQ += "        SUM(CASE WHEN TRIM(D.RD_PD) IN (" + xLst(oPar["vextra"])   + ") THEN D.RD_VALOR ELSE 0 END) X, "
	cQ += "        SUM(CASE WHEN TRIM(D.RD_PD) IN (" + xLst(oPar["vatest"])   + ") THEN D.RD_VALOR ELSE 0 END) AT, "
	cQ += "        SUM(CASE WHEN TRIM(D.RD_PD) IN (" + xLst(oPar["vatest"])   + ") THEN D.RD_HORAS ELSE 0 END) AD, "
	cQ += "        SUM(CASE WHEN TRIM(D.RD_PD) IN (" + xLst(oPar["vfalta"])   + ") THEN D.RD_VALOR ELSE 0 END) FA "
	cQ += "       FROM " + xT("SRD") + " D "
	cQ += "      WHERE D.D_E_L_E_T_ = ' ' AND D.RD_DATARQ >= " + xQ(oPar["desde"]) + " AND TRIM(D.RD_ROTEIR) <> 'ADI' "
	cQ += "      GROUP BY D.RD_FILIAL, D.RD_MAT, TRIM(D.RD_DATARQ)) G"

Return {cQ, "G.FIL, G.MAT, G.YM"}

// MED03 - ferias iniciadas no periodo
Static Function qMED03(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(RH_FILIAL) FIL, TRIM(RH_MAT) MAT, TRIM(RH_DATAINI) INI, SUM(RH_DFERIAS) D FROM " + xT("SRH") + " "
	cQ += "WHERE D_E_L_E_T_ = ' ' AND RH_DATAINI >= " + xQ(oPar["desde"]) + " AND RH_DFERIAS > 0 "
	cQ += "GROUP BY TRIM(RH_FILIAL), TRIM(RH_MAT), TRIM(RH_DATAINI)"

Return {cQ, "1, 2, 3"}

// MED04 - pessoas ativas ou demitidas no periodo
Static Function qMED04(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(A.RA_FILIAL) FIL, TRIM(A.RA_MAT) MAT, TRIM(A.RA_NOME) NOME, TRIM(A.RA_ADMISSA) ADM, TRIM(A.RA_DEMISSA) DEM, "
	cQ += "(SELECT MAX(TRIM(J.RJ_DESC)) FROM " + xT("SRJ") + " J WHERE J.D_E_L_E_T_ = ' ' AND J.RJ_FUNCAO = A.RA_CODFUNC) FUNCD, "
	cQ += "TRIM(A.RA_CC) CC, (SELECT MAX(TRIM(C.CTT_DESC01)) FROM " + xT("CTT") + " C WHERE C.D_E_L_E_T_ = ' ' AND C.CTT_CUSTO = A.RA_CC) CCD, "
	cQ += "TRIM(A.RA_DEPTO) DEP, (SELECT MAX(TRIM(B.QB_DESCRIC)) FROM " + xT("SQB") + " B WHERE B.D_E_L_E_T_ = ' ' AND B.QB_DEPTO = A.RA_DEPTO) DEPD, "
	cQ += "TRIM(A.RA_TNOTRAB) TUR, (SELECT MAX(TRIM(R.R6_DESC)) FROM " + xT("SR6") + " R WHERE R.D_E_L_E_T_ = ' ' AND R.R6_TURNO = A.RA_TNOTRAB) TURD, "
	cQ += "TRIM(A.RA_RESCRAI) RES "
	cQ += "FROM " + xT("SRA") + " A "
	cQ += "WHERE A.D_E_L_E_T_ = ' ' AND (TRIM(A.RA_DEMISSA) = '' OR A.RA_DEMISSA >= " + xQ(oPar["desde"]) + ")"

Return {cQ, "A.RA_FILIAL, A.RA_MAT"}

// MED05 - rescisoes no periodo
Static Function qMED05(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(R.RR_FILIAL) FIL, TRIM(R.RR_MAT) MAT, TRIM(R.RR_DATA) DT, "
	cQ += "SUM(CASE WHEN V.RV_TIPOCOD = '1' AND TRIM(R.RR_PD) NOT IN (" + BI_RES_EXCL + ") THEN R.RR_VALOR ELSE 0 END) PG, "
	cQ += "SUM(CASE WHEN TRIM(R.RR_PD) IN (" + BI_RES_AVISO + ") THEN R.RR_VALOR ELSE 0 END) AV, "
	cQ += "SUM(CASE WHEN TRIM(R.RR_PD) IN (" + BI_RES_MULTA + ") THEN R.RR_VALOR ELSE 0 END) MU "
	cQ += "FROM " + xT("SRR") + " R JOIN " + xT("SRV") + " V ON V.D_E_L_E_T_ = ' ' AND V.RV_COD = R.RR_PD "
	cQ += "WHERE R.D_E_L_E_T_ = ' ' AND TRIM(R.RR_ROTEIR) = 'RES' AND R.RR_DATA >= " + xQ(oPar["desde"]) + " "
	cQ += "GROUP BY TRIM(R.RR_FILIAL), TRIM(R.RR_MAT), TRIM(R.RR_DATA)"

Return {cQ, "1, 2, 3"}

// MED06 - acidentes / CAT (TNC)
// GREATEST(1, TO_DATE(fim) - TO_DATE(ini)) -> CASE com DATEDIFF; memo TNC_DETALH via CAST.
Static Function qMED06(oPar)
	Local cQ   := ""
	Local cDif := "DATEDIFF(DAY, TRY_CONVERT(DATE, N.TNY_DTINIC, 112), TRY_CONVERT(DATE, N.TNY_DTFIM, 112))"

	cQ += "SELECT TRIM(C.TNC_ACIDEN) ID, TRIM(A.RA_FILIAL) FIL, TRIM(A.RA_MAT) MAT, TRIM(A.RA_NOME) NOME, TRIM(C.TNC_DTACID) DT, TRIM(C.TNC_HRACID) HR, "
	cQ += "TRIM(C.TNC_INDACI) IND, TRIM(C.TNC_TIPCAT) TCAT, TRIM(C.TNC_AFASTA) AFA, TRIM(C.TNC_INTERN) [INT], TRIM(C.TNC_MORTE) MOR, "
	cQ += "(SELECT MAX(TRIM(G.TNG_DESTIP)) FROM " + xT("TNG") + " G WHERE G.D_E_L_E_T_ = ' ' AND G.TNG_TIPACI = C.TNC_TIPACI) CAUSA, "
	cQ += "(SELECT MAX(TRIM(J.TOJ_NOMLES)) FROM " + xT("TOJ") + " J WHERE J.D_E_L_E_T_ = ' ' AND J.TOJ_CODLES = C.TNC_CODLES) LES, "
	cQ += "TRIM(C.TNC_CID) CID, "
	cQ += "(SELECT MAX(TRIM(R.TMR_DOENCA)) FROM " + xT("TMR") + " R WHERE R.D_E_L_E_T_ = ' ' AND TRIM(R.TMR_CID) = TRIM(C.TNC_CID)) CIDD, "
	cQ += "TRIM(C.TNC_LOCAL) LOC, CAST(CAST(C.TNC_DETALH AS VARBINARY(400)) AS VARCHAR(400)) DET, TRIM(C.TNC_HRTRAB) HTRAB, "
	cQ += "TRIM(C.TNC_CC) CC, (SELECT MAX(TRIM(K.CTT_DESC01)) FROM " + xT("CTT") + " K WHERE K.D_E_L_E_T_ = ' ' AND TRIM(K.CTT_CUSTO) = TRIM(C.TNC_CC)) CCD, "
	cQ += "TRIM(A.RA_CC) CC2, (SELECT MAX(TRIM(K.CTT_DESC01)) FROM " + xT("CTT") + " K WHERE K.D_E_L_E_T_ = ' ' AND TRIM(K.CTT_CUSTO) = TRIM(A.RA_CC)) CCD2, "
	cQ += "(SELECT MAX(TRIM(F.RJ_DESC)) FROM " + xT("SRJ") + " F WHERE F.D_E_L_E_T_ = ' ' "
	cQ += "   AND TRIM(F.RJ_FUNCAO) = COALESCE(NULLIF(TRIM(C.TNC_CODFUN), ''), TRIM(A.RA_CODFUNC))) FUNCD, "
	cQ += "(SELECT COUNT(*) FROM " + xT("TNY") + " N WHERE N.D_E_L_E_T_ = ' ' AND N.TNY_ACIDEN = C.TNC_ACIDEN AND N.TNY_NUMFIC = C.TNC_NUMFIC) NAT, "
	cQ += "(SELECT ISNULL(SUM(CASE WHEN TRIM(N.TNY_DTFIM) = '' THEN 1 "
	cQ += "                        WHEN " + cDif + " > 1 THEN " + cDif + " ELSE 1 END), 0) "
	cQ += "   FROM " + xT("TNY") + " N WHERE N.D_E_L_E_T_ = ' ' AND N.TNY_ACIDEN = C.TNC_ACIDEN AND N.TNY_NUMFIC = C.TNC_NUMFIC) DAT, "
	cQ += "ISNULL(C.TNC_QTAFAS, 0) QTA, TRIM(C.TNC_CATINS) CAT "
	cQ += "FROM " + xT("TNC") + " C "
	cQ += "LEFT JOIN " + xT("TM0") + " M ON M.D_E_L_E_T_ = ' ' AND M.TM0_NUMFIC = C.TNC_NUMFIC "
	cQ += "LEFT JOIN " + xT("SRA") + " A ON A.D_E_L_E_T_ = ' ' AND A.RA_MAT = M.TM0_MAT AND A.RA_FILIAL = M.TM0_FILFUN "
	cQ += "WHERE C.D_E_L_E_T_ = ' '"

Return {cQ, "C.TNC_DTACID, C.R_E_C_N_O_"}
