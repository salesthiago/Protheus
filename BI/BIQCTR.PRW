#include 'protheus.ch'

/*/{Protheus.doc} BIQCTR
Consultas do BI - 9. Contratos de compra e medicoes (Gestao de Contratos - SIGAGCT).
Chamado por APIBI.PRW. Retorna {cSql, cOrdem} ou uma string com a mensagem de erro.

So entram contratos de COMPRA: especie do contrato = '1' (CN9_ESPCTR; se vazio,
a especie do tipo de contrato CN1_ESPCTR). Contratos de venda ficam de fora,
inclusive as medicoes deles.

Cadastros (SB1, CTT, SA2, CTH, CN1, CN0) sao lidos na filial do contrato:
o codigo de filial do cadastro e comparado com o inicio da filial do
movimento, o que serve para cadastro exclusivo, parcial ou compartilhado.

@author Thiago Sales - Quebec Ambiental
@since 2026-11-12
/*/
User Function BIQCTR(cId, oPar)

	Do Case
	Case cId == "CTR01" ; Return qCTR01(oPar)
	Case cId == "CTR02" ; Return qCTR02(oPar)
	EndCase

Return Nil

Static Function xT(cAlias)
Return RetSqlName(cAlias)

Static Function xQ(cVal)
Return "'" + cVal + "'"

// Condicao "cadastro da filial do movimento" (mesmo criterio do relatorio de medicoes)
Static Function xFilCad(cCampoFil, cFilMov)
Return cCampoFil + " = SUBSTRING(" + cFilMov + ", 1, LEN(" + cCampoFil + "))"

//-----------------------------------------------------------------------------
// Expressao da especie do contrato (1 = compra, 2 = venda) para o alias cA da CN9.
// Devolve Nil se o ambiente nao tiver nenhum dos dois campos.
//-----------------------------------------------------------------------------
Static Function xEspecie(cA)
	Local lCN9 := U_BIHASCOL(xT("CN9"), "CN9_ESPCTR")
	Local lCN1 := U_BIHASCOL(xT("CN1"), "CN1_ESPCTR")
	Local cE9  := iif(lCN9, "NULLIF(" + cA + ".CN9_ESPCTR, '')", "NULL")
	Local cE1  := "NULL"

	If !lCN9 .And. !lCN1
		Return Nil
	EndIf
	If lCN1
		cE1 := "(SELECT MAX(C1.CN1_ESPCTR) FROM " + xT("CN1") + " C1 WHERE C1.D_E_L_E_T_ = ' ' " + ;
		       "AND C1.CN1_CODIGO = " + cA + ".CN9_TPCTO AND " + xFilCad("C1.CN1_FILIAL", cA + ".CN9_FILIAL") + ")"
	EndIf

Return "COALESCE(" + cE9 + ", " + cE1 + ")"

//-----------------------------------------------------------------------------
// CTR01 - contratos de compra (CN9), uma linha por revisao.
// VL_INICIAL x VL_ATUAL mostra quanto o contrato cresceu com aditivos e reajustes;
// SALDO e o que ainda falta medir. DT_REVISAO / TIPO_REV so vem se o campo existir.
//-----------------------------------------------------------------------------
Static Function qCTR01(oPar)
	Local cQ   := ""
	Local cEsp := xEspecie("C")
	Local cRev := "CAST(NULL AS VARCHAR(250))"

	If cEsp == Nil
		Return "Nao foi possivel separar contratos de compra: CN9_ESPCTR e CN1_ESPCTR nao existem."
	EndIf
	If U_BIHASCOL(xT("CN9"), "CN9_TIPREV") .And. U_BIHASCOL(xT("CN0"), "CN0_DESCRI")
		cRev := "(SELECT MAX(TRIM(C0.CN0_DESCRI)) FROM " + xT("CN0") + " C0 WHERE C0.D_E_L_E_T_ = ' ' " + ;
		        "AND C0.CN0_CODIGO = C.CN9_TIPREV AND " + xFilCad("C0.CN0_FILIAL", "C.CN9_FILIAL") + ")"
	EndIf

	cQ += "SELECT TRIM(C.CN9_FILIAL) FILIAL, TRIM(C.CN9_NUMERO) CONTRATO, TRIM(C.CN9_REVISA) REVISAO, "
	cQ += "TRIM(C.CN9_SITUAC) SITUACAO, TRIM(C.CN9_TPCTO) TIPO, "
	cQ += "(SELECT MAX(TRIM(C1.CN1_DESCRI)) FROM " + xT("CN1") + " C1 WHERE C1.D_E_L_E_T_ = ' ' "
	cQ += "   AND C1.CN1_CODIGO = C.CN9_TPCTO AND " + xFilCad("C1.CN1_FILIAL", "C.CN9_FILIAL") + ") TIPO_DESC, "
	cQ += "TRIM(C.CN9_DTINIC) DT_INICIO, TRIM(C.CN9_DTFIM) DT_FIM, "
	cQ += U_BICOL("CN9", "CN9_DTASSI", "TRIM(C.CN9_DTASSI)") + " DT_ASSIN, "
	cQ += U_BICOL("CN9", "CN9_DTREV", "TRIM(C.CN9_DTREV)") + " DT_REVISAO, "
	cQ += U_BICOL("CN9", "CN9_TIPREV", "TRIM(C.CN9_TIPREV)") + " TIPO_REV, "
	cQ += cRev + " TPREV_DESC, "
	cQ += "C.CN9_VLINI VL_INICIAL, C.CN9_VLATU VL_ATUAL, C.CN9_SALDO SALDO, "
	cQ += "TRIM(F.FORN) FORNECEDOR, TRIM(F.LOJA) LOJA, TRIM(A2.A2_NOME) FORN_NOME, "
	cQ += cEsp + " ESPECIE "
	cQ += "FROM " + xT("CN9") + " C "
	// fornecedor: primeira planilha da revisao
	cQ += "OUTER APPLY (SELECT TOP 1 CNA.CNA_FORNEC FORN, CNA.CNA_LJFORN LOJA FROM " + xT("CNA") + " CNA "
	cQ += "  WHERE CNA.D_E_L_E_T_ = ' ' AND CNA.CNA_FILIAL = C.CN9_FILIAL AND CNA.CNA_CONTRA = C.CN9_NUMERO "
	cQ += "    AND CNA.CNA_REVISA = C.CN9_REVISA AND CNA.CNA_FORNEC <> '' ORDER BY CNA.CNA_NUMERO) F "
	cQ += "LEFT JOIN " + xT("SA2") + " A2 ON A2.D_E_L_E_T_ = ' ' AND " + xFilCad("A2.A2_FILIAL", "C.CN9_FILIAL")
	cQ += "  AND A2.A2_COD = F.FORN AND A2.A2_LOJA = F.LOJA "
	cQ += "WHERE C.D_E_L_E_T_ = ' ' AND " + cEsp + " = '1'"

Return {cQ, "C.CN9_FILIAL, C.CN9_NUMERO, C.CN9_REVISA, C.R_E_C_N_O_"}

//-----------------------------------------------------------------------------
// CTR02 - itens das medicoes (CNE) de contratos de compra, a partir de "desde"
// (data de entrega CNE_DTENT, como no relatorio de medicoes).
//-----------------------------------------------------------------------------
Static Function qCTR02(oPar)
	Local cQ   := ""
	Local cEsp := xEspecie("C9")

	If cEsp == Nil
		Return "Nao foi possivel separar contratos de compra: CN9_ESPCTR e CN1_ESPCTR nao existem."
	EndIf

	cQ += "SELECT TRIM(CNE.CNE_FILIAL) FILIAL, TRIM(CNE.CNE_CONTRA) CONTRATO, TRIM(CNE.CNE_REVISA) REVISAO, "
	cQ += "TRIM(CNE.CNE_NUMMED) MEDICAO, TRIM(CNE.CNE_ITEM) ITEM, "
	cQ += "TRIM(CNE.CNE_PRODUT) PRODUTO, COALESCE(TRIM(SB1.B1_DESC), '') PROD_DESC, "
	cQ += "CNE.CNE_QUANT QUANT, CNE.CNE_VLUNIT VL_UNIT, CNE.CNE_VLTOT VL_TOTAL, "
	cQ += "TRIM(CNE.CNE_DTENT) DT_ENTREGA, TRIM(CND.CND_COMPET) COMPET, TRIM(CND.CND_DTFIM) DT_ENCERR, "
	cQ += "TRIM(CNE.CNE_PEDIDO) PEDIDO, TRIM(CNE.CNE_CC) CC, COALESCE(TRIM(CTT.CTT_DESC01), '') CC_DESC, "
	cQ += "TRIM(COALESCE(CNA.CNA_FORNEC, CND.CND_FORNEC, '')) FORNECEDOR, "
	cQ += "TRIM(COALESCE(CNA.CNA_LJFORN, CND.CND_LJFORN, '')) LOJA, COALESCE(TRIM(SA2.A2_NOME), '') FORN_NOME, "
	cQ += "TRIM(CNE.CNE_CLVL) PROJETO, COALESCE(TRIM(CTH.CTH_DESC01), '') PROJ_DESC "
	cQ += "FROM " + xT("CNE") + " CNE "
	// contrato (so compra)
	cQ += "JOIN " + xT("CN9") + " C9 ON C9.D_E_L_E_T_ = ' ' AND C9.CN9_FILIAL = CNE.CNE_FILIAL "
	cQ += "  AND C9.CN9_NUMERO = CNE.CNE_CONTRA AND C9.CN9_REVISA = CNE.CNE_REVISA "
	// cabecalho da medicao
	cQ += "LEFT JOIN " + xT("CND") + " CND ON CND.D_E_L_E_T_ = ' ' AND CND.CND_FILIAL = CNE.CNE_FILIAL "
	cQ += "  AND CND.CND_CONTRA = CNE.CNE_CONTRA AND CND.CND_REVISA = CNE.CNE_REVISA AND CND.CND_NUMMED = CNE.CNE_NUMMED "
	// planilha do contrato
	cQ += "LEFT JOIN " + xT("CNA") + " CNA ON CNA.D_E_L_E_T_ = ' ' AND CNA.CNA_FILIAL = CNE.CNE_FILIAL "
	cQ += "  AND CNA.CNA_CONTRA = CNE.CNE_CONTRA AND CNA.CNA_REVISA = CNE.CNE_REVISA "
	cQ += "  AND CNA.CNA_NUMERO = COALESCE(NULLIF(CNE.CNE_NUMERO, ''), CND.CND_NUMERO) "
	// cadastros na filial da medicao
	cQ += "LEFT JOIN " + xT("SB1") + " SB1 ON SB1.D_E_L_E_T_ = ' ' AND " + xFilCad("SB1.B1_FILIAL", "CNE.CNE_FILIAL")
	cQ += "  AND SB1.B1_COD = CNE.CNE_PRODUT "
	cQ += "LEFT JOIN " + xT("CTT") + " CTT ON CTT.D_E_L_E_T_ = ' ' AND " + xFilCad("CTT.CTT_FILIAL", "CNE.CNE_FILIAL")
	cQ += "  AND CTT.CTT_CUSTO = CNE.CNE_CC "
	cQ += "LEFT JOIN " + xT("SA2") + " SA2 ON SA2.D_E_L_E_T_ = ' ' AND " + xFilCad("SA2.A2_FILIAL", "CNE.CNE_FILIAL")
	cQ += "  AND SA2.A2_COD = COALESCE(CNA.CNA_FORNEC, CND.CND_FORNEC) AND SA2.A2_LOJA = COALESCE(CNA.CNA_LJFORN, CND.CND_LJFORN) "
	cQ += "LEFT JOIN " + xT("CTH") + " CTH ON CTH.D_E_L_E_T_ = ' ' AND " + xFilCad("CTH.CTH_FILIAL", "CNE.CNE_FILIAL")
	cQ += "  AND CTH.CTH_CLVL = CNE.CNE_CLVL "
	cQ += "WHERE CNE.D_E_L_E_T_ = ' ' AND CNE.CNE_DTENT >= " + xQ(oPar["desde"]) + " "
	cQ += "AND " + cEsp + " = '1'"

Return {cQ, "CNE.CNE_FILIAL, CNE.CNE_CONTRA, CNE.CNE_NUMMED, CNE.CNE_ITEM, CNE.R_E_C_N_O_"}
