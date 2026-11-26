#Include "Protheus.ch"
#Include "TopConn.ch"

/*/{Protheus.doc} MT140SAI
Ponto de entrada executado na saida da rotina MATA140 (Pre-Nota de Entrada).
Usado para DIAGNOSTICO: quando o usuario confirma uma EXCLUSAO e o cabecalho
(SF1) continua existindo na base, dispara o diagnostico U_DIAGP140 mostrando
o motivo provavel da exclusao nao ter sido efetivada.

PARAMIXB (conferir no TDN da release):
  [1] nOpcao   - opcao do aRotina (5 = Excluir)
  [2] F1_DOC
  [3] F1_SERIE
  [4] F1_FORNECE
  [5] F1_LOJA
  [6] F1_TIPO
  [7] nOpcA    - 1 = usuario confirmou

@type User Function
@author Thiago Sales
@since 18/11/2026
/*/
User Function MT140SAI()

	Local aArea    := GetArea()
	Local aAreaSF1 := SF1->(GetArea())
	Local nOpc     := 0
	Local nConf    := 1
	Local cDoc     := ""
	Local cSerie   := ""
	Local cFornece := ""
	Local cLoja    := ""
	Local nI       := 0
	Local cParams  := ""

	If Type("PARAMIXB") <> "A" .Or. Len(PARAMIXB) < 5
		Return Nil
	EndIf

	// Log dos parametros recebidos no console do AppServer (valida a ordem do PARAMIXB)
	For nI := 1 To Len(PARAMIXB)
		cParams += "[" + cValToChar(nI) + "]=" + AllTrim(cValToChar(PARAMIXB[nI])) + " "
	Next nI
	ConOut("MT140SAI | " + DtoC(Date()) + " " + Time() + " | Fil " + cFilAnt + " | " + cParams)

	nOpc     := IIf(ValType(PARAMIXB[1]) == "N", PARAMIXB[1], 0)
	cDoc     := PARAMIXB[2]
	cSerie   := PARAMIXB[3]
	cFornece := PARAMIXB[4]
	cLoja    := PARAMIXB[5]
	If Len(PARAMIXB) >= 7 .And. ValType(PARAMIXB[7]) == "N"
		nConf := PARAMIXB[7]
	EndIf

	// Exclusao confirmada: o documento ainda existe?
	If nOpc == 5 .And. nConf == 1
		SF1->(DbSetOrder(1)) // F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO
		If SF1->(MsSeek(xFilial("SF1") + cDoc + cSerie + cFornece + cLoja))
			FWAlertWarning("A pre-nota " + AllTrim(cDoc) + " / serie '" + AllTrim(cSerie) + "'" + ;
				" NAO foi excluida, embora a rotina tenha finalizado." + CRLF + ;
				"Sera exibido o diagnostico do registro.", "Exclusao nao efetivada")
			U_DIAGP140()
		EndIf
	EndIf

	RestArea(aAreaSF1)
	RestArea(aArea)

Return Nil


/*/{Protheus.doc} DIAGP140
Diagnostico do documento de entrada posicionado no SF1.
Pode ser chamado pelo MT140SAI ou pelo menu (MTA140MNU -> "Diag. Exclusao").
Grava o resultado em \temp\diagp140_<doc>_<data><hora>.txt.
@type User Function
@author Thiago Sales
@since 18/11/2026
/*/
User Function DIAGP140()

	Local aArea    := GetArea()
	Local aAreaSF1 := SF1->(GetArea())
	Local aAreaSD1 := SD1->(GetArea())
	Local cLog     := ""
	Local cChave   := ""
	Local nRecSF1  := 0
	Local nItens   := 0
	Local nProbl   := 0
	Local cQry     := ""
	Local cAli     := ""
	Local cArq     := ""

	If SF1->(Eof()) .Or. SF1->(Bof())
		FWAlertError("Nenhum documento posicionado no SF1.", "DIAGP140")
		Return Nil
	EndIf

	nRecSF1 := SF1->(Recno())
	cChave  := SF1->(F1_DOC + F1_SERIE + F1_FORNECE + F1_LOJA)

	cLog += "DIAGNOSTICO DE EXCLUSAO - PRE-NOTA DE ENTRADA" + CRLF
	cLog += Replicate("=", 70) + CRLF
	cLog += "Data/Hora ......: " + DtoC(Date()) + " " + Time() + CRLF
	cLog += "Usuario ........: " + cUserName + CRLF
	cLog += "Empresa/Filial  : " + cEmpAnt + " / " + cFilAnt + CRLF
	cLog += "xFilial(SF1) ...: '" + xFilial("SF1") + "'   xFilial(SD1): '" + xFilial("SD1") + "'" + CRLF
	cLog += "Rotina .........: " + FunName() + CRLF
	cLog += Replicate("-", 70) + CRLF
	cLog += "SF1 R_E_C_N_O_ .: " + cValToChar(nRecSF1) + CRLF
	cLog += "F1_FILIAL ......: '" + SF1->F1_FILIAL + "'" + CRLF
	cLog += "F1_DOC .........: '" + SF1->F1_DOC + "'" + CRLF
	cLog += "F1_SERIE .......: '" + SF1->F1_SERIE + "'" + CRLF
	If SF1->(FieldPos("F1_SDOC")) > 0
		cLog += "F1_SDOC ........: '" + SF1->F1_SDOC + "'" + CRLF
	EndIf
	cLog += "F1_FORNECE/LOJA : '" + SF1->F1_FORNECE + "' / '" + SF1->F1_LOJA + "'" + CRLF
	cLog += "F1_TIPO ........: '" + SF1->F1_TIPO + "'" + CRLF
	cLog += "F1_ESPECIE .....: '" + SF1->F1_ESPECIE + "'" + CRLF
	cLog += "F1_STATUS ......: '" + SF1->F1_STATUS + "'" + CRLF
	If SF1->(FieldPos("F1_ORIGEM")) > 0
		cLog += "F1_ORIGEM ......: '" + SF1->F1_ORIGEM + "'" + CRLF
	EndIf
	cLog += "F1_DTDIGIT .....: " + DtoC(SF1->F1_DTDIGIT) + CRLF
	cLog += Replicate("-", 70) + CRLF

	// ------------------------------------------------------------------
	// 1) Filial logada x filial do documento
	// ------------------------------------------------------------------
	If SF1->F1_FILIAL <> xFilial("SF1")
		nProbl++
		cLog += "[PROBLEMA] Documento pertence a filial '" + SF1->F1_FILIAL + ;
			"', mas o usuario esta logado na '" + cFilAnt + "'." + CRLF + ;
			"           O MATA140 busca SF1/SD1 com xFilial() da filial logada e nao" + CRLF + ;
			"           encontra o documento: termina 'sem erro' e nada e excluido." + CRLF
	Else
		cLog += "[OK] Filial logada corresponde a filial do documento." + CRLF
	EndIf

	// ------------------------------------------------------------------
	// 2) Status: documento classificado nao se exclui pelo MATA140
	// ------------------------------------------------------------------
	If !Empty(SF1->F1_STATUS)
		nProbl++
		cLog += "[PROBLEMA] F1_STATUS = '" + SF1->F1_STATUS + "' (documento classificado)." + CRLF + ;
			"           A exclusao deve ser feita pelo Documento de Entrada (MATA103)." + CRLF
	Else
		cLog += "[OK] F1_STATUS em branco (pre-nota nao classificada)." + CRLF
	EndIf

	// ------------------------------------------------------------------
	// 3) Itens SD1 pela chave exata (mesma busca que o padrao faz)
	// ------------------------------------------------------------------
	SD1->(DbSetOrder(1)) // D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA+D1_COD+D1_ITEM
	If SD1->(MsSeek(SF1->F1_FILIAL + cChave))
		While SD1->(!Eof()) .And. SD1->(D1_FILIAL + D1_DOC + D1_SERIE + D1_FORNECE + D1_LOJA) == SF1->F1_FILIAL + cChave
			nItens++
			cLog += "     Item " + SD1->D1_ITEM + " | Cod '" + AllTrim(SD1->D1_COD) + "'" + ;
				" | Qtd " + cValToChar(SD1->D1_QUANT) + " | TES '" + SD1->D1_TES + "'" + ;
				" | Recno " + cValToChar(SD1->(Recno())) + CRLF
			SD1->(DbSkip())
		EndDo
	EndIf

	If nItens == 0
		nProbl++
		cLog += "[PROBLEMA] Nenhum item SD1 ativo para a chave do cabecalho (SF1 ORFAO)." + CRLF + ;
			"           A tela mostra uma linha 'vazia' (so com inicializadores) e a" + CRLF + ;
			"           exclusao padrao, que percorre os itens, nao remove o cabecalho." + CRLF
	Else
		cLog += "[OK] " + cValToChar(nItens) + " item(ns) SD1 ativo(s) para a chave do cabecalho." + CRLF
	EndIf
	cLog += Replicate("-", 70) + CRLF

	// ------------------------------------------------------------------
	// 4) SD1 do mesmo DOC/FORNECEDOR por serie (itens "perdidos")
	// ------------------------------------------------------------------
	cLog += "SD1 do mesmo DOC/FORNECEDOR/LOJA por serie (inclui deletados):" + CRLF
	cQry := "SELECT D1_SERIE, D_E_L_E_T_ DEL, COUNT(*) QTD, " + ;
		"SUM(CASE WHEN D1_TES <> ' ' THEN 1 ELSE 0 END) COMTES " + ;
		"FROM " + RetSqlName("SD1") + " " + ;
		"WHERE D1_FILIAL = '" + SF1->F1_FILIAL + "' " + ;
		"AND D1_DOC = '" + SF1->F1_DOC + "' " + ;
		"AND D1_FORNECE = '" + SF1->F1_FORNECE + "' " + ;
		"AND D1_LOJA = '" + SF1->F1_LOJA + "' " + ;
		"GROUP BY D1_SERIE, D_E_L_E_T_ ORDER BY D1_SERIE, D_E_L_E_T_"
	cAli := GetNextAlias()
	DbUseArea(.T., "TOPCONN", TcGenQry(,, ChangeQuery(cQry)), cAli, .F., .T.)
	While (cAli)->(!Eof())
		cLog += "     Serie '" + (cAli)->D1_SERIE + "' | " + ;
			IIf((cAli)->DEL == "*", "DELETADO", "ATIVO   ") + ;
			" | Itens: " + cValToChar((cAli)->QTD) + ;
			" | Com TES: " + cValToChar((cAli)->COMTES) + CRLF
		(cAli)->(DbSkip())
	EndDo
	(cAli)->(DbCloseArea())
	cLog += Replicate("-", 70) + CRLF

	// ------------------------------------------------------------------
	// 5) SF1 com o mesmo DOC/FORNECEDOR (duplicidades / outras series)
	// ------------------------------------------------------------------
	cLog += "SF1 do mesmo DOC/FORNECEDOR/LOJA (inclui deletados):" + CRLF
	cQry := "SELECT F1_SERIE, F1_TIPO, F1_STATUS, D_E_L_E_T_ DEL, R_E_C_N_O_ REC " + ;
		"FROM " + RetSqlName("SF1") + " " + ;
		"WHERE F1_FILIAL = '" + SF1->F1_FILIAL + "' " + ;
		"AND F1_DOC = '" + SF1->F1_DOC + "' " + ;
		"AND F1_FORNECE = '" + SF1->F1_FORNECE + "' " + ;
		"AND F1_LOJA = '" + SF1->F1_LOJA + "' " + ;
		"ORDER BY R_E_C_N_O_"
	cAli := GetNextAlias()
	DbUseArea(.T., "TOPCONN", TcGenQry(,, ChangeQuery(cQry)), cAli, .F., .T.)
	While (cAli)->(!Eof())
		cLog += "     Recno " + PadL(cValToChar((cAli)->REC), 8) + ;
			" | Serie '" + (cAli)->F1_SERIE + "'" + ;
			" | Tipo '" + (cAli)->F1_TIPO + "'" + ;
			" | Status '" + (cAli)->F1_STATUS + "'" + ;
			" | " + IIf((cAli)->DEL == "*", "DELETADO", "ATIVO") + ;
			IIf((cAli)->REC == nRecSF1, "  <-- registro posicionado", "") + CRLF
		(cAli)->(DbSkip())
	EndDo
	(cAli)->(DbCloseArea())
	cLog += Replicate("-", 70) + CRLF

	// ------------------------------------------------------------------
	// 6) Lock: outro usuario/processo segurando o registro?
	// ------------------------------------------------------------------
	SF1->(DbGoTo(nRecSF1))
	If SF1->(SimpleLock())
		SF1->(MsUnlock())
		cLog += "[OK] Registro SF1 nao esta bloqueado por outro usuario." + CRLF
	Else
		nProbl++
		cLog += "[PROBLEMA] Registro SF1 esta bloqueado (lock) por outro usuario/processo." + CRLF
	EndIf

	// ------------------------------------------------------------------
	// 7) Origem integracao (TOTVS Colaboracao / importador)
	// ------------------------------------------------------------------
	If SF1->(FieldPos("F1_ORIGEM")) > 0 .And. !Empty(SF1->F1_ORIGEM)
		cLog += "[ATENCAO] Documento gerado por '" + AllTrim(SF1->F1_ORIGEM) + "'." + CRLF + ;
			"          Verifique se o importador possui PE de validacao de exclusao" + CRLF + ;
			"          compilado no RPO (Central de Diagnostico > Ponto de entrada)." + CRLF
	EndIf

	cLog += Replicate("=", 70) + CRLF
	cLog += "Problemas encontrados: " + cValToChar(nProbl) + CRLF

	// Grava log no servidor
	MakeDir("\temp")
	cArq := "\temp\diagp140_" + AllTrim(SF1->F1_DOC) + "_" + DtoS(Date()) + StrTran(Time(), ":", "") + ".txt"
	MemoWrite(cArq, cLog)
	cLog += "Log gravado em: " + cArq + CRLF
	ConOut(cLog)

	ShowLog(cLog)

	RestArea(aAreaSD1)
	RestArea(aAreaSF1)
	RestArea(aArea)

Return Nil


/*/{Protheus.doc} ShowLog
Exibe o texto do diagnostico em tela.
@type Static Function
/*/
Static Function ShowLog(cTexto)

	Local oDlg
	Local oMemo
	Local oFont := TFont():New("Courier New",, -12)

	DEFINE MSDIALOG oDlg TITLE "Diagnostico Pre-Nota (DIAGP140)" FROM 000, 000 TO 500, 800 PIXEL

	@ 005, 005 GET oMemo VAR cTexto MEMO SIZE 390, 225 OF oDlg PIXEL READONLY
	oMemo:oFont := oFont

	@ 235, 345 BUTTON "Fechar" SIZE 050, 012 OF oDlg PIXEL ACTION oDlg:End()

	ACTIVATE MSDIALOG oDlg CENTERED

Return Nil
