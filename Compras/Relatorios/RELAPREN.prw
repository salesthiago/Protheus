//Bibliotecas
#Include "Totvs.ch"

/*/{Protheus.doc} User Function zRelPre
Relatório de Pré-Notas
@author Felipe Moraes Camargo
@since 18/11/2021
@version 1.0
@type function
@obs Codigo gerado automaticamente pelo Autumn Code Maker
@see http://autumncodemaker.com
/*/

User Function zRelPre()
	Local aArea := GetArea()
	Local oReport
	
	//Cria as definicoes do relatorio
	oReport := fReportDef()
	oReport:PrintDialog()
	
	RestArea(aArea)
Return

/*/{Protheus.doc} fReportDef
Definicoes do relatorio zRelPre
@author Felipe Moraes Camargo
@since 18/11/2021
@version 1.0
@type function
@obs Codigo gerado automaticamente pelo Autumn Code Maker
@see http://autumncodemaker.com
/*/

Static Function fReportDef()
	Local oReport
	Local oSection := Nil
	
	//Criacao do componente de impressao
	oReport := TReport():New( "zRelPre",;
		"Pedidos em Pre Nota",;
		,;
		{|oReport| fRepPrint(oReport),};
		)
	oReport:SetTotalInLine(.F.)
	oReport:lParamPage := .F.
	oReport:oPage:SetPaperSize(9)
	
	//Orientacao do Relatorio
	oReport:SetPortrait()
	
	//Definicoes da fonte utilizada
	oReport:cFontBody := "Andale Mono"
	oReport:SetLineHeight(50)
	oReport:nFontBody := 12
	
	//Criando a secao de dados
	oSection := TRSection():New( oReport,;
		"Dados",;
		{"QRY_REP"})
	oSection:SetTotalInLine(.F.)
	
	//Colunas do relatorio
	TRCell():New(oSection, "F1_FILIAL", "QRY_REP", "FILIAL", /*cPicture*/, 4, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSection, "F1_DOC", "QRY_REP", "NUM DOC", /*cPicture*/, 9, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSection, "F1_EMISSAO", "QRY_REP", "EMISSAO", "@D", 10, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSection, "F1_DTDIGIT", "QRY_REP", "DIGIT", "@D", 10, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSection, "C7_NUM", "QRY_REP", "NUM PC", /*cPicture*/, 6, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSection, "C7_EMISSAO", "QRY_REP", "EMISSAO", "@D", 10, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSection, "C7_CC", "QRY_REP", "CC", /*cPicture*/, 6, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	
Return oReport

/*/{Protheus.doc} fRepPrint
Impressao do relatorio zRelPre
@author Felipe Moraes Camargo
@since 18/11/2021
@version 1.0
@type function
@obs Codigo gerado automaticamente pelo Autumn Code Maker
@see http://autumncodemaker.com
/*/

Static Function fRepPrint(oReport)
	Local aArea    := GetArea()
	Local cQryReport  := ""
	Local oSectDad := Nil
	Local nAtual   := 0
	Local nTotal   := 0
	
	//Pegando as secoes do relatorio
	oSectDad := oReport:Section(1)
	
	//Montando consulta de dados
	cQryReport += "SELECT "		+ CRLF
	cQryReport += "/* "		+ CRLF
	cQryReport += "1.01 "		+ CRLF
	cQryReport += " ♥♣♦♠ ♥♣♦♠ ♥♣♦♠ ♥♣♦♠ ♥♣♦♠ ♥♣♦♠ ♥♣♦♠ "		+ CRLF
	cQryReport += " RELATORIO DE PRE NOTAS "		+ CRLF
	cQryReport += " ♥♣♦♠ ♥♣♦♠ ♥♣♦♠ ♥♣♦♠ ♥♣♦♠ ♥♣♦♠ ♥♣♦♠ "		+ CRLF
	cQryReport += " CAMPOS FILIAL, DOCUMENTO DE ENTRADA, EMISSAO DA NOTA FISCAL, DATA DA DIGITACAO DA NOTA FISCAL "		+ CRLF
	cQryReport += " NUMERO DO PEDIDO DE COMPRA, EMISSAO DO PEDIDO DE COMPRA "		+ CRLF
	cQryReport += " "		+ CRLF
	cQryReport += " POR ENQUANTO A LIMITACAO E QUE SO COMPARA O PRIMEIRO ITEM DA NF COM O PRIMEIRO DO PC "		+ CRLF
	cQryReport += " ♥♣♦♠ ♥♣♦♠ ♥♣♦♠ ♥♣♦♠ ♥♣♦♠ ♥♣♦♠ ♥♣♦♠ "		+ CRLF
	cQryReport += " 20211118 FELIPE ALICE "		+ CRLF
	cQryReport += "*/ "		+ CRLF
	cQryReport += " SF1.F1_FILIAL, "		+ CRLF
	cQryReport += " SF1.F1_DOC, "		+ CRLF
	cQryReport += " SF1.F1_EMISSAO, "		+ CRLF
	cQryReport += " SF1.F1_DTDIGIT, "		+ CRLF
	cQryReport += " SC7.C7_NUM, "		+ CRLF
	cQryReport += " SC7.C7_EMISSAO, "		+ CRLF
	cQryReport += " SC7.C7_CC "		+ CRLF
	cQryReport += " "		+ CRLF
	cQryReport += "FROM "		+ CRLF
	cQryReport += " SF1010 SF1 "		+ CRLF
	cQryReport += " LEFT JOIN SD1010 SD1 ON SD1.D_E_L_E_T_ = '' "		+ CRLF
	cQryReport += " AND SD1.D1_FILIAL = SF1.F1_FILIAL AND SD1.D1_DOC = SF1.F1_DOC AND SD1.D1_ITEM = '0001' AND SD1.D1_FORNECE = SF1.F1_FORNECE "		+ CRLF
	cQryReport += " LEFT JOIN SC7010 SC7 ON SC7.D_E_L_E_T_ = '' "		+ CRLF
	cQryReport += " AND SC7.C7_FILIAL = SF1.F1_FILIAL AND SC7.C7_NUM = SD1.D1_PEDIDO AND SC7.C7_ITEM = '0001' AND SC7.C7_RESIDUO = '' "		+ CRLF
	cQryReport += " "		+ CRLF
	cQryReport += "WHERE "		+ CRLF
	cQryReport += " SF1.D_E_L_E_T_ = '' AND SF1.F1_STATUS = '' "		+ CRLF
	cQryReport += " "		+ CRLF
	cQryReport += "ORDER BY "		+ CRLF
	cQryReport += " F1_FILIAL, F1_DTDIGIT "		+ CRLF

	//cQryReport += " F1_FILIAL, F1_DOC, D1_PEDIDO"		+ CRLF
	
	//Executando consulta e setando o total da regua
	PlsQuery(cQryReport, "QRY_REP")
	DbSelectArea("QRY_REP")
	Count to nTotal
	oReport:SetMeter(nTotal)
	
	//Enquanto houver dados
	oSectDad:Init()
	QRY_REP->(DbGoTop())
	While ! QRY_REP->(Eof())
	
		//Incrementando a regua
		nAtual++
		oReport:SetMsgPrint("Imprimindo registro " + cValToChar(nAtual) + " de " + cValToChar(nTotal) + "...")
		oReport:IncMeter()
		
		//Imprimindo a linha atual
		oSectDad:PrintLine()
		
		QRY_REP->(DbSkip())
	EndDo
	oSectDad:Finish()
	QRY_REP->(DbCloseArea())
	
	RestArea(aArea)
Return
