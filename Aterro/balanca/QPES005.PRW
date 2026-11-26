#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "PARMTYPE.CH"
#INCLUDE "REPORT.CH"

/*/{Protheus.doc} QPES005
Relatorio de Pesagens (tabela NJH) por Periodo, agrupadas por Produto e
Centro de Custo.

Para cada combinacao Centro de Custo (NJH_XCLVL) x Produto (NJH_CODPRO)
encontrada no filtro, imprime:
  - Quantidade de pesagens
  - Peso de Entrada  (somatoria de NJH_PESO1)
  - Peso de Saida    (somatoria de NJH_PESO2)
  - Total Recolhido  (Entrada - Saida)

O parametro "Agrupar por" define a quebra do relatorio:
  1 - Centro de Custo : CC -> Produtos, com subtotal por Centro de Custo
  2 - Produto         : Produto -> Centros de Custo, com subtotal por Produto
Ao final imprime a linha de TOTAL GERAL.

Regras:
  - Pesagens canceladas (NJH_STATUS = '4') nunca sao consideradas.
  - Parametro "Somente c/ 2 Pesagens" = Sim (padrao) considera apenas as
    pesagens com Peso de Entrada e Peso de Saida informados, evitando que
    pesagens incompletas (sem a segunda pesagem) inflem o Total Recolhido.

Codigos de Centro de Custo (NJH_XCLVL) conhecidos:
  0102 = Aparecida de Goiania
  0121 = Trindade
  0606 = Paracatu
  9001 = Ituiutaba

A saida usa a tela padrao do TReport (PrintDialog), que ja oferece exportacao
para Excel, visualizacao do PDF em tela e opcao de download.

Parametros: Centro de Custo De/Ate, Data De/Ate, Produto De/Ate,
Agrupar por e Somente c/ 2 Pesagens.
@type User Function
@author Thiago Sales - Quebec Ambiental
@since 2026-11-11
/*/
//=============================================================================
User Function QPES005()
//=============================================================================
	Local oReport := Nil

	AjustaSX1(Padr("QPES005", 10))

	If !Pergunte("QPES005", .T.)
		Return Nil
	EndIf

	oReport := xRelProdCC()

	If oReport <> Nil
		oReport:PrintDialog()
	EndIf

Return Nil

/*/{Protheus.doc} AjustaSX1
Registra as perguntas do relatorio na tabela SX1, caso ainda nao existam.
@type Static Function
@param cPerg Character, identificador do grupo de perguntas
/*/
//=============================================================================
Static Function AjustaSX1(cPerg)
//=============================================================================
	Local aRegs := {}
	Local nX    := 0

	// {X1_GRUPO,X1_ORDEM,X1_PERGUNTE,X1_PERSPA,X1_PERENG,X1_VARIAVL,X1_TIPO,X1_TAM,X1_DEC,X1_PRESEL,X1_GSC,X1_VALID,X1_VAR01,X1_DEF01,X1_DEF02,X1_DEF03,X1_F3}
	aAdd(aRegs, {cPerg,"01","Centro Custo De    ","Centro Custo De    ","Centro Custo De    ","mv_ch1","C",15,0,0,"G","","mv_par01","","","",""})
	aAdd(aRegs, {cPerg,"02","Centro Custo Ate   ","Centro Custo Ate   ","Centro Custo Ate   ","mv_ch2","C",15,0,0,"G","","mv_par02","ZZZZZZZZZZZZZZZ","","",""})
	aAdd(aRegs, {cPerg,"03","Data De            ","Data De            ","Data De            ","mv_ch3","D", 8,0,0,"G","","mv_par03","","","",""})
	aAdd(aRegs, {cPerg,"04","Data Ate           ","Data Ate           ","Data Ate           ","mv_ch4","D", 8,0,0,"G","","mv_par04","","","",""})
	aAdd(aRegs, {cPerg,"05","Produto De         ","Produto De         ","Produto De         ","mv_ch5","C",15,0,0,"G","","mv_par05","","","","SB1"})
	aAdd(aRegs, {cPerg,"06","Produto Ate        ","Produto Ate        ","Produto Ate        ","mv_ch6","C",15,0,0,"G","","mv_par06","ZZZZZZZZZZZZZZZ","","","SB1"})
	aAdd(aRegs, {cPerg,"07","Agrupar por        ","Agrupar por        ","Agrupar por        ","mv_ch7","N", 1,0,1,"C","","mv_par07","Centro de Custo","Produto","",""})
	aAdd(aRegs, {cPerg,"08","Somente c/2 Pesagens","Somente c/2 Pesagens","Somente c/2 Pesagens","mv_ch8","N", 1,0,1,"C","","mv_par08","Sim","Nao","",""})

	DbSelectArea("SX1")
	SX1->(DbSetOrder(1))

	For nX := 1 To Len(aRegs)
		If !SX1->(DbSeek(aRegs[nX][01] + aRegs[nX][02]))
			RecLock("SX1", .T.)
			Replace SX1->X1_GRUPO    With aRegs[nX][01]
			Replace SX1->X1_ORDEM    With aRegs[nX][02]
			Replace SX1->X1_PERGUNTE With aRegs[nX][03]
			Replace SX1->X1_PERSPA   With aRegs[nX][04]
			Replace SX1->X1_PERENG   With aRegs[nX][05]
			Replace SX1->X1_VARIAVL  With aRegs[nX][06]
			Replace SX1->X1_TIPO     With aRegs[nX][07]
			Replace SX1->X1_TAMANHO  With aRegs[nX][08]
			Replace SX1->X1_DECIMAL  With aRegs[nX][09]
			Replace SX1->X1_PRESEL   With aRegs[nX][10]
			Replace SX1->X1_GSC      With aRegs[nX][11]
			Replace SX1->X1_VALID    With aRegs[nX][12]
			Replace SX1->X1_VAR01    With aRegs[nX][13]
			Replace SX1->X1_DEF01    With aRegs[nX][14]
			Replace SX1->X1_DEF02    With aRegs[nX][15]
			Replace SX1->X1_DEF03    With aRegs[nX][16]
			Replace SX1->X1_F3       With aRegs[nX][17]
			MsUnlock("SX1")
		EndIf
	Next nX

Return

/*/{Protheus.doc} xMontaQry5
Monta a query agregada (GROUP BY Centro de Custo + Produto) conforme os
filtros informados. A ordenacao segue o parametro "Agrupar por".
@type Static Function
@return cQ Character, query SQL
/*/
//=============================================================================
Static Function xMontaQry5()
//=============================================================================
	Local cCCDe   := AllTrim(mv_par01)
	Local cCCAte  := If(Empty(AllTrim(mv_par02)), "ZZZZZZZZZZZZZZZ", AllTrim(mv_par02))
	Local dDtDe   := If(Empty(mv_par03), CTOD("01/01/1900"), mv_par03)
	Local dDtAte  := If(Empty(mv_par04), Date(), mv_par04)
	Local cPrdDe  := AllTrim(mv_par05)
	Local cPrdAte := If(Empty(AllTrim(mv_par06)), "ZZZZZZZZZZZZZZZ", AllTrim(mv_par06))
	Local cNJH    := RetSqlName("NJH")
	Local cQ      := ""

	cQ += "SELECT NJH.NJH_XCLVL XCLVL, "
	cQ += "NJH.NJH_CODPRO CODPRO, "
	cQ += "MAX(NJH.NJH_DESPRO) DESPRO, "
	cQ += "COUNT(*) QTDTOT, "
	cQ += "SUM(NJH.NJH_PESO1) SPESO1, "
	cQ += "SUM(NJH.NJH_PESO2) SPESO2 "
	cQ += "FROM " + cNJH + " NJH "
	cQ += "WHERE NJH.D_E_L_E_T_ = ' ' "
	//cQ += "AND NJH.NJH_FILIAL = '" + xFilial("NJH") + "' "
	cQ += "AND NJH.NJH_STATUS <> '4' "
	cQ += "AND NJH.NJH_XCLVL BETWEEN '" + cCCDe + "' AND '" + cCCAte + "' "
	cQ += "AND NJH.NJH_DATA BETWEEN '" + DTOS(dDtDe) + "' AND '" + DTOS(dDtAte) + "' "
	cQ += "AND NJH.NJH_CODPRO BETWEEN '" + cPrdDe + "' AND '" + cPrdAte + "' "

	If mv_par08 <> 2 // Somente pesagens com entrada e saida
		cQ += "AND NJH.NJH_PESO1 > 0 AND NJH.NJH_PESO2 > 0 "
	EndIf

	cQ += "GROUP BY NJH.NJH_XCLVL, NJH.NJH_CODPRO "

	If mv_par07 == 2 // Produto -> Centro de Custo
		cQ += "ORDER BY NJH.NJH_CODPRO, NJH.NJH_XCLVL "
	Else             // Centro de Custo -> Produto
		cQ += "ORDER BY NJH.NJH_XCLVL, NJH.NJH_CODPRO "
	EndIf

Return cQ

/*/{Protheus.doc} xDescCC5
Traduz o codigo do Centro de Custo (NJH_XCLVL) para o nome da unidade.
@type Static Function
@param cCC Character, codigo do centro de custo
@return cD Character, descricao
/*/
//=============================================================================
Static Function xDescCC5(cCC)
//=============================================================================
	Local cD := ""

	cCC := AllTrim(cCC)

	Do Case
		Case cCC == "0102" ; cD := "APARECIDA DE GOIANIA"
		Case cCC == "0121" ; cD := "TRINDADE"
		Case cCC == "0606" ; cD := "PARACATU"
		Case cCC == "9001" ; cD := "ITUIUTABA"
		Otherwise          ; cD := "CENTRO DE CUSTO " + cCC
	EndCase

Return cD

/*/{Protheus.doc} xTitPer5
Monta o texto de subtitulo do relatorio com o periodo e as faixas de
Centro de Custo / Produto informadas nos parametros.
@type Static Function
@return cP Character, texto do subtitulo
/*/
//=============================================================================
Static Function xTitPer5()
//=============================================================================
	Local cP := " - Periodo: "

	cP += If(Empty(mv_par03), "Inicio", DtoC(mv_par03))
	cP += " a "
	cP += If(Empty(mv_par04), DtoC(Date()), DtoC(mv_par04))

	If !Empty(AllTrim(mv_par01)) .Or. (!Empty(AllTrim(mv_par02)) .And. AllTrim(mv_par02) <> "ZZZZZZZZZZZZZZZ")
		cP += " - CC: " + AllTrim(mv_par01) + " a " + AllTrim(mv_par02)
	EndIf

	If !Empty(AllTrim(mv_par05)) .Or. (!Empty(AllTrim(mv_par06)) .And. AllTrim(mv_par06) <> "ZZZZZZZZZZZZZZZ")
		cP += " - Produto: " + AllTrim(mv_par05) + " a " + AllTrim(mv_par06)
	EndIf

Return cP

/*/{Protheus.doc} xRelProdCC
Monta o objeto TReport do resumo de pesagens por Produto e Centro de Custo.
@type Static Function
@return oReport Object, instancia do TReport
/*/
//=============================================================================
Static Function xRelProdCC()
//=============================================================================
	Local oReport   := Nil
	Local oSection1 := Nil
	Local cSub      := xTitPer5()
	Local cTit      := If(mv_par07 == 2, "Pesagens por Produto e Centro de Custo", "Pesagens por Centro de Custo e Produto")

	oReport := TReport():New("QPES005", cTit + cSub, "QPES005", {|oReport| xImpProdCC(oReport)}, "Resumo de pesagens (entrada, saida e total recolhido) por Produto e Centro de Custo")
	oReport:SetTotalInLine(.F.)
	oReport:SetLandscape()
	oReport:oPage:SetPaperSize(10)

	oSection1 := TRSection():New(oReport, "Resumo NJH", {"NJH"}, {})
	oSection1:SetTotalInLine(.F.)

	If mv_par07 == 2 // Produto -> Centro de Custo
		TRCell():New(oSection1, "CODPRO", "   ", "Produto"              ,                  , 15)
		TRCell():New(oSection1, "DESPRO", "   ", "Descricao"            ,                  , 30)
		TRCell():New(oSection1, "XCLVL" , "   ", "Centro Custo"         ,                  , 12)
		TRCell():New(oSection1, "DESCC" , "   ", "Unidade"              ,                  , 24)
	Else             // Centro de Custo -> Produto
		TRCell():New(oSection1, "XCLVL" , "   ", "Centro Custo"         ,                  , 12)
		TRCell():New(oSection1, "DESCC" , "   ", "Unidade"              ,                  , 24)
		TRCell():New(oSection1, "CODPRO", "   ", "Produto"              ,                  , 15)
		TRCell():New(oSection1, "DESPRO", "   ", "Descricao"            ,                  , 30)
	EndIf
	TRCell():New(oSection1, "QTDTOT", "   ", "Qtd Pesagens"         , "@E 999,999"     , 12)
	TRCell():New(oSection1, "SPESO1", "   ", "Entrada (KG)"         , "@E 999,999,999" , 16)
	TRCell():New(oSection1, "SPESO2", "   ", "Saida (KG)"           , "@E 999,999,999" , 16)
	TRCell():New(oSection1, "RECOL" , "   ", "Total Recolhido (KG)" , "@E 999,999,999" , 20)

	oSection1:Cell("QTDTOT"):SetHeaderAlign("RIGHT")
	oSection1:Cell("SPESO1"):SetHeaderAlign("RIGHT")
	oSection1:Cell("SPESO2"):SetHeaderAlign("RIGHT")
	oSection1:Cell("RECOL") :SetHeaderAlign("RIGHT")

Return oReport

/*/{Protheus.doc} xLinha5
Preenche e imprime uma linha da secao.
@type Static Function
/*/
//=============================================================================
Static Function xLinha5(oSection1, cCC, cDescCC, cPrd, cDesPrd, nQtd, nP1, nP2)
//=============================================================================
	oSection1:Cell("XCLVL") :SetValue(cCC)
	oSection1:Cell("DESCC") :SetValue(cDescCC)
	oSection1:Cell("CODPRO"):SetValue(cPrd)
	oSection1:Cell("DESPRO"):SetValue(cDesPrd)
	oSection1:Cell("QTDTOT"):SetValue(nQtd)
	oSection1:Cell("SPESO1"):SetValue(nP1)
	oSection1:Cell("SPESO2"):SetValue(nP2)
	oSection1:Cell("RECOL") :SetValue(nP1 - nP2)
	oSection1:PrintLine()
Return Nil

/*/{Protheus.doc} xSubTot5
Imprime a linha de subtotal do grupo atual (Centro de Custo ou Produto).
@type Static Function
/*/
//=============================================================================
Static Function xSubTot5(oReport, oSection1, lPorPrd, cChave, cDesc, nQtd, nP1, nP2)
//=============================================================================
	If lPorPrd
		xLinha5(oSection1, "", "", "SUBTOTAL", AllTrim(cChave) + " - " + AllTrim(cDesc), nQtd, nP1, nP2)
	Else
		xLinha5(oSection1, "SUBTOTAL", AllTrim(cChave) + " - " + AllTrim(cDesc), "", "", nQtd, nP1, nP2)
	EndIf
	oReport:SkipLine()
Return Nil

/*/{Protheus.doc} xImpProdCC
Executa a consulta agregada e preenche a secao do TReport com uma linha por
Centro de Custo x Produto, com subtotal a cada quebra do agrupamento
escolhido e a linha de TOTAL GERAL ao final.
@type Static Function
@param oReport Object, instancia do TReport em execucao
/*/
//=============================================================================
Static Function xImpProdCC(oReport)
//=============================================================================
#IFDEF TOP
	Local oSection1 := oReport:Section(1)
	Local cAlias    := GetNextAlias()
	Local cQuery    := xMontaQry5()
	Local lPorPrd   := (mv_par07 == 2)
	Local cChave    := ""
	Local cChvAnt   := Nil
	Local cDscAnt   := ""
	Local nSQtd     := 0
	Local nSP1      := 0
	Local nSP2      := 0
	Local nTQtd     := 0
	Local nTP1      := 0
	Local nTP2      := 0

	dbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAlias, .T., .T.)

	oSection1:Init()

	dbSelectArea(cAlias)
	dbGoTop()
	Do While !(cAlias)->(Eof())

		oReport:IncMeter()
		If oReport:Cancel()
			Exit
		EndIf

		cChave := If(lPorPrd, (cAlias)->CODPRO, (cAlias)->XCLVL)

		// Quebra do agrupamento: imprime o subtotal do grupo anterior
		If cChvAnt <> Nil .And. cChave <> cChvAnt
			xSubTot5(oReport, oSection1, lPorPrd, cChvAnt, cDscAnt, nSQtd, nSP1, nSP2)
			nSQtd := 0
			nSP1  := 0
			nSP2  := 0
		EndIf

		xLinha5(oSection1, (cAlias)->XCLVL, xDescCC5((cAlias)->XCLVL), ;
			(cAlias)->CODPRO, (cAlias)->DESPRO, ;
			(cAlias)->QTDTOT, (cAlias)->SPESO1, (cAlias)->SPESO2)

		cChvAnt := cChave
		cDscAnt := If(lPorPrd, (cAlias)->DESPRO, xDescCC5((cAlias)->XCLVL))

		nSQtd += (cAlias)->QTDTOT
		nSP1  += (cAlias)->SPESO1
		nSP2  += (cAlias)->SPESO2

		nTQtd += (cAlias)->QTDTOT
		nTP1  += (cAlias)->SPESO1
		nTP2  += (cAlias)->SPESO2

		(cAlias)->(dbSkip())
	EndDo

	(cAlias)->(dbCloseArea())

	// Subtotal do ultimo grupo
	If cChvAnt <> Nil
		xSubTot5(oReport, oSection1, lPorPrd, cChvAnt, cDscAnt, nSQtd, nSP1, nSP2)
	EndIf

	// Total geral
	xLinha5(oSection1, If(lPorPrd, "", "TOTAL"), If(lPorPrd, "", "GERAL"), ;
		If(lPorPrd, "TOTAL", ""), If(lPorPrd, "GERAL", ""), nTQtd, nTP1, nTP2)

	oSection1:Finish()
#ENDIF
Return Nil
