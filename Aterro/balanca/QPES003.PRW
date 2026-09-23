#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "PARMTYPE.CH"
#INCLUDE "REPORT.CH"

/*/{Protheus.doc} QPES003
Relatorio de Pesagens (tabela NJH) por Periodo e por Centro de Custo (codigo).

Duas visoes, escolhidas no parametro "Tipo de Relatorio":

  1 - Sintetico : uma linha por Centro de Custo (NJH_XCLVL), com:
        - Quantidade Total de pesagens
        - Somatoria do Peso 1  (peso de entrada  - NJH_PESO1)
        - Somatoria do Peso 2  (peso de saida    - NJH_PESO2)
        - Somatoria do Peso Liquido              (NJH_PSSUBT)
        - Quantidade de Finalizados  (NJH_STATUS = '2')
        - Quantidade de Cancelados   (NJH_STATUS = '4')
        - Quantidade de Incompletos  (demais status: '0', '1', '3')
      Ao final imprime uma linha de TOTAL GERAL.

  2 - Analitico : uma linha por pesagem, com toda a relacao encontrada no
      filtro (ticket, unidade, datas, placa, motorista, pesos, status...).

Codigos de Centro de Custo (NJH_XCLVL) conhecidos:
  0102 = Aparecida de Goiania
  0121 = Trindade
  0606 = Paracatu
  9001 = Ituiutaba

A saida usa a tela padrao do TReport (PrintDialog), que ja oferece exportacao
para Excel, visualizacao do PDF em tela e opcao de download.

Parametros: Centro de Custo De/Ate, Data De/Ate e Tipo de Relatorio.
@type User Function
/*/
//=============================================================================
User Function QPES003()
//=============================================================================
	Local oReport := Nil

	AjustaSX1(Padr("QPES003", 10))
	Pergunte("QPES003", .T.)

	If mv_par05 == 2 // Analitico
		oReport := xRelAnalit()
	Else            // Sintetico
		oReport := xRelSintet()
	EndIf

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
	aAdd(aRegs, {cPerg,"05","Tipo de Relatorio  ","Tipo de Relatorio  ","Tipo de Relatorio  ","mv_ch5","N", 1,0,1,"C","","mv_par05","Sintetico","Analitico","",""})

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

/*/{Protheus.doc} xMontaQry3
Monta a query conforme os filtros (Centro de Custo e Data). Quando lSint = .T.
retorna a consulta agregada (GROUP BY NJH_XCLVL) usada pela visao sintetica;
caso contrario retorna a lista de RECNOs do NJH usada pela visao analitica.
@type Static Function
@param lSint Logical, .T. = query sintetica (agregada)
@return cQ Character, query SQL
/*/
//=============================================================================
Static Function xMontaQry3(lSint)
//=============================================================================
	Local cCCDe  := AllTrim(mv_par01)
	Local cCCAte := If(Empty(AllTrim(mv_par02)), "ZZZZZZZZZZZZZZZ", AllTrim(mv_par02))
	Local dDtDe  := If(Empty(mv_par03), CTOD("01/01/1900"), mv_par03)
	Local dDtAte := If(Empty(mv_par04), Date(), mv_par04)
	Local cNJH   := RetSqlName("NJH")
	Local cQ     := ""

	Default lSint := .T.

	If lSint
		cQ += "SELECT NJH.NJH_XCLVL XCLVL, "
		cQ += "COUNT(*) QTDTOT, "
		cQ += "SUM(NJH.NJH_PESO1) SPESO1, "
		cQ += "SUM(NJH.NJH_PESO2) SPESO2, "
		cQ += "SUM(NJH.NJH_PSSUBT) SPSLIQ, "
		cQ += "SUM(CASE WHEN NJH.NJH_STATUS = '2' THEN 1 ELSE 0 END) QTDFIN, "
		cQ += "SUM(CASE WHEN NJH.NJH_STATUS = '4' THEN 1 ELSE 0 END) QTDCAN, "
		cQ += "SUM(CASE WHEN NJH.NJH_STATUS NOT IN ('2','4') THEN 1 ELSE 0 END) QTDINC "
		cQ += "FROM " + cNJH + " NJH "
		cQ += "WHERE NJH.D_E_L_E_T_ = ' ' "
		//cQ += "AND NJH.NJH_FILIAL = '" + xFilial("NJH") + "' "
		cQ += "AND NJH.NJH_XCLVL BETWEEN '" + cCCDe + "' AND '" + cCCAte + "' "
		cQ += "AND NJH.NJH_DATA BETWEEN '" + DTOS(dDtDe) + "' AND '" + DTOS(dDtAte) + "' "
		cQ += "GROUP BY NJH.NJH_XCLVL "
		cQ += "ORDER BY NJH.NJH_XCLVL "
	Else
		cQ += "SELECT NJH.R_E_C_N_O_ NJHRECNO "
		cQ += "FROM " + cNJH + " NJH "
		cQ += "WHERE NJH.D_E_L_E_T_ = ' ' "
		//cQ += "AND NJH.NJH_FILIAL = '" + xFilial("NJH") + "' "
		cQ += "AND NJH.NJH_XCLVL BETWEEN '" + cCCDe + "' AND '" + cCCAte + "' "
		cQ += "AND NJH.NJH_DATA BETWEEN '" + DTOS(dDtDe) + "' AND '" + DTOS(dDtAte) + "' "
		cQ += "ORDER BY NJH.NJH_XCLVL, NJH.NJH_DATA, NJH.NJH_CODPAV "
	EndIf

Return cQ

/*/{Protheus.doc} xDescCC3
Traduz o codigo do Centro de Custo (NJH_XCLVL) para o nome da unidade.
@type Static Function
@param cCC Character, codigo do centro de custo
@return cD Character, descricao
/*/
//=============================================================================
Static Function xDescCC3(cCC)
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

/*/{Protheus.doc} xDescStat3
Traduz o codigo de NJH_STATUS para a descricao textual correspondente.
@type Static Function
@param cSt Character, codigo do status ('0' a '4')
@return cD Character, descricao do status
/*/
//=============================================================================
Static Function xDescStat3(cSt)
//=============================================================================
	Local cD := ""

	Do Case
		Case cSt == "0" ; cD := "Sem Pesagem"
		Case cSt == "1" ; cD := "Primeira Pesagem"
		Case cSt == "2" ; cD := "Segunda Pesagem"
		Case cSt == "3" ; cD := "Finalizada"
		Case cSt == "4" ; cD := "Cancelada"
		Otherwise       ; cD := "Nao Identificado"
	EndCase

Return cD

/*/{Protheus.doc} xTitPer
Monta o texto de subtitulo do relatorio com o periodo e a faixa de Centro
de Custo informados nos parametros.
@type Static Function
@return cP Character, texto do subtitulo
/*/
//=============================================================================
Static Function xTitPer()
//=============================================================================
	Local cP := " - Periodo: "

	cP += If(Empty(mv_par03), "Inicio", DtoC(mv_par03))
	cP += " a "
	cP += If(Empty(mv_par04), DtoC(Date()), DtoC(mv_par04))

	If !Empty(AllTrim(mv_par01)) .Or. (!Empty(AllTrim(mv_par02)) .And. AllTrim(mv_par02) <> "ZZZZZZZZZZZZZZZ")
		cP += " - CC: " + AllTrim(mv_par01) + " a " + AllTrim(mv_par02)
	EndIf

Return cP

/*/{Protheus.doc} xRelSintet
Monta o objeto TReport da visao SINTETICA (resumo por Centro de Custo).
@type Static Function
@return oReport Object, instancia do TReport
/*/
//=============================================================================
Static Function xRelSintet()
//=============================================================================
	Local oReport   := Nil
	Local oSection1 := Nil
	Local cSub      := xTitPer()

	oReport := TReport():New("QPES003S", "Pesagens - Sintetico por Centro de Custo" + cSub, "QPES003", {|oReport| xImpSintet(oReport)}, "Resumo de pesagens por Centro de Custo e periodo")
	oReport:SetTotalInLine(.F.)
	oReport:SetLandscape()
	oReport:oPage:SetPaperSize(10)

	oSection1 := TRSection():New(oReport, "Resumo NJH", {"NJH"}, {})
	oSection1:SetTotalInLine(.F.)

	TRCell():New(oSection1, "XCLVL" , "   ", "Centro Custo"      ,                  , 12)
	TRCell():New(oSection1, "DESCR" , "   ", "Unidade"           ,                  , 24)
	TRCell():New(oSection1, "QTDTOT", "   ", "Qtd Total"         , "@E 999,999"     , 10)
	TRCell():New(oSection1, "SPESO1", "   ", "Peso Entrada (KG)" , "@E 999,999,999" , 16)
	TRCell():New(oSection1, "SPESO2", "   ", "Peso Saida (KG)"   , "@E 999,999,999" , 16)
	TRCell():New(oSection1, "SPSLIQ", "   ", "Peso Liquido (KG)" , "@E 999,999,999" , 16)
	TRCell():New(oSection1, "QTDFIN", "   ", "Finalizados"       , "@E 999,999"     , 11)
	TRCell():New(oSection1, "QTDCAN", "   ", "Cancelados"        , "@E 999,999"     , 11)
	TRCell():New(oSection1, "QTDINC", "   ", "Incompletos"       , "@E 999,999"     , 11)

	oSection1:Cell("QTDTOT"):SetHeaderAlign("RIGHT")
	oSection1:Cell("SPESO1"):SetHeaderAlign("RIGHT")
	oSection1:Cell("SPESO2"):SetHeaderAlign("RIGHT")
	oSection1:Cell("SPSLIQ"):SetHeaderAlign("RIGHT")
	oSection1:Cell("QTDFIN"):SetHeaderAlign("RIGHT")
	oSection1:Cell("QTDCAN"):SetHeaderAlign("RIGHT")
	oSection1:Cell("QTDINC"):SetHeaderAlign("RIGHT")

Return oReport

/*/{Protheus.doc} xImpSintet
Executa a consulta agregada e preenche a secao do TReport com uma linha por
Centro de Custo, acrescentando ao final a linha de TOTAL GERAL.
@type Static Function
@param oReport Object, instancia do TReport em execucao
/*/
//=============================================================================
Static Function xImpSintet(oReport)
//=============================================================================
#IFDEF TOP
	Local oSection1 := oReport:Section(1)
	Local cAlias    := GetNextAlias()
	Local cQuery    := xMontaQry3(.T.)
	Local nTQtd     := 0
	Local nTP1      := 0
	Local nTP2      := 0
	Local nTPL      := 0
	Local nTFin     := 0
	Local nTCan     := 0
	Local nTInc     := 0

	dbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAlias, .T., .T.)

	oSection1:Init()

	dbSelectArea(cAlias)
	dbGoTop()
	Do While !(cAlias)->(Eof())

		oReport:IncMeter()
		If oReport:Cancel()
			Exit
		EndIf

		oSection1:Cell("XCLVL") :SetValue((cAlias)->XCLVL)
		oSection1:Cell("DESCR") :SetValue(xDescCC3((cAlias)->XCLVL))
		oSection1:Cell("QTDTOT"):SetValue((cAlias)->QTDTOT)
		oSection1:Cell("SPESO1"):SetValue((cAlias)->SPESO1)
		oSection1:Cell("SPESO2"):SetValue((cAlias)->SPESO2)
		oSection1:Cell("SPSLIQ"):SetValue((cAlias)->SPSLIQ)
		oSection1:Cell("QTDFIN"):SetValue((cAlias)->QTDFIN)
		oSection1:Cell("QTDCAN"):SetValue((cAlias)->QTDCAN)
		oSection1:Cell("QTDINC"):SetValue((cAlias)->QTDINC)
		oSection1:PrintLine()

		nTQtd += (cAlias)->QTDTOT
		nTP1  += (cAlias)->SPESO1
		nTP2  += (cAlias)->SPESO2
		nTPL  += (cAlias)->SPSLIQ
		nTFin += (cAlias)->QTDFIN
		nTCan += (cAlias)->QTDCAN
		nTInc += (cAlias)->QTDINC

		(cAlias)->(dbSkip())
	EndDo

	(cAlias)->(dbCloseArea())

	oReport:SkipLine()
	oSection1:Cell("XCLVL") :SetValue("TOTAL")
	oSection1:Cell("DESCR") :SetValue("GERAL")
	oSection1:Cell("QTDTOT"):SetValue(nTQtd)
	oSection1:Cell("SPESO1"):SetValue(nTP1)
	oSection1:Cell("SPESO2"):SetValue(nTP2)
	oSection1:Cell("SPSLIQ"):SetValue(nTPL)
	oSection1:Cell("QTDFIN"):SetValue(nTFin)
	oSection1:Cell("QTDCAN"):SetValue(nTCan)
	oSection1:Cell("QTDINC"):SetValue(nTInc)
	oSection1:PrintLine()

	oSection1:Finish()
#ENDIF
Return Nil

/*/{Protheus.doc} xRelAnalit
Monta o objeto TReport da visao ANALITICA (relacao completa de pesagens).
@type Static Function
@return oReport Object, instancia do TReport
/*/
//=============================================================================
Static Function xRelAnalit()
//=============================================================================
	Local oReport   := Nil
	Local oSection1 := Nil
	Local cSub      := xTitPer()

	oReport := TReport():New("QPES003A", "Pesagens - Analitico" + cSub, "QPES003", {|oReport| xImpAnalit(oReport)}, "Relacao completa de pesagens por periodo e Centro de Custo")
	oReport:SetTotalInLine(.F.)
	oReport:SetLandscape()
	oReport:oPage:SetPaperSize(10)

	oSection1 := TRSection():New(oReport, "Pesagens NJH", {"NJH"}, {})
	oSection1:SetTotalInLine(.F.)

	TRCell():New(oSection1, "TICKET"    , "   ", "Ticket"           ,             , 12)
	TRCell():New(oSection1, "XCLVL"     , "   ", "CCusto"           ,             , 08)
	TRCell():New(oSection1, "DESCC"     , "   ", "Unidade"          ,             , 20)
	TRCell():New(oSection1, "DATA"      , "   ", "Data"             ,             , 10)
	TRCell():New(oSection1, "PLACA"     , "   ", "Placa"            ,             , 10)
	TRCell():New(oSection1, "DATENT"    , "   ", "Data Entrada"     ,             , 10)
	TRCell():New(oSection1, "HORENT"    , "   ", "Hora Ent"         ,             , 08)
	TRCell():New(oSection1, "DATSAI"    , "   ", "Data Saida"       ,             , 10)
	TRCell():New(oSection1, "HORSAI"    , "   ", "Hora Sai"         ,             , 08)
	TRCell():New(oSection1, "MOTORISTA" , "   ", "Motorista"        ,             , 26)
	TRCell():New(oSection1, "PRODUTO"   , "   ", "Produto"          ,             , 22)
	TRCell():New(oSection1, "FORNECEDOR", "   ", "Fornecedor"       ,             , 26)
	TRCell():New(oSection1, "CLIENTE"   , "   ", "Cliente"          ,             , 26)
	TRCell():New(oSection1, "PESO1"     , "   ", "Peso Entrada (KG)", "@E 999,999", 14)
	TRCell():New(oSection1, "PESO2"     , "   ", "Peso Saida (KG)"  , "@E 999,999", 14)
	TRCell():New(oSection1, "PSLIQ"     , "   ", "Peso Liquido (KG)", "@E 999,999", 14)
	TRCell():New(oSection1, "STATUS"    , "   ", "Status"           ,             , 18)
	TRCell():New(oSection1, "OBS"       , "   ", "Observacao"       ,             , 30)
	TRCell():New(oSection1, "ROTA"      , "   ", "Rota"             ,             , 15)

	oSection1:Cell("PESO1"):SetHeaderAlign("RIGHT")
	oSection1:Cell("PESO2"):SetHeaderAlign("RIGHT")
	oSection1:Cell("PSLIQ"):SetHeaderAlign("RIGHT")

Return oReport

/*/{Protheus.doc} xImpAnalit
Executa a consulta e preenche a secao do TReport com um registro por pesagem
encontrada no filtro, acrescentando ao final a linha de totais dos pesos.
@type Static Function
@param oReport Object, instancia do TReport em execucao
/*/
//=============================================================================
Static Function xImpAnalit(oReport)
//=============================================================================
#IFDEF TOP
	Local oSection1 := oReport:Section(1)
	Local cAlias    := GetNextAlias()
	Local cQuery    := xMontaQry3(.F.)
	Local nQtd      := 0
	Local nTP1      := 0
	Local nTP2      := 0
	Local nTPL      := 0

	dbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAlias, .T., .T.)

	oSection1:Init()

	dbSelectArea(cAlias)
	dbGoTop()
	Do While !(cAlias)->(Eof())

		oReport:IncMeter()
		If oReport:Cancel()
			Exit
		EndIf

		NJH->(dbGoTo((cAlias)->NJHRECNO))

		oSection1:Cell("TICKET")    :SetValue(NJH->NJH_CODPAV)
		oSection1:Cell("XCLVL")     :SetValue(NJH->NJH_XCLVL)
		oSection1:Cell("DESCC")     :SetValue(xDescCC3(NJH->NJH_XCLVL))
		oSection1:Cell("DATA")      :SetValue(DtoC(NJH->NJH_DATA))
		oSection1:Cell("PLACA")     :SetValue(NJH->NJH_PLACA)
		oSection1:Cell("DATENT")    :SetValue(DtoC(NJH->NJH_DATPS1))
		oSection1:Cell("HORENT")    :SetValue(NJH->NJH_HORPS1)
		oSection1:Cell("DATSAI")    :SetValue(DtoC(NJH->NJH_DATPS2))
		oSection1:Cell("HORSAI")    :SetValue(NJH->NJH_HORPS2)
		oSection1:Cell("MOTORISTA") :SetValue(NJH->NJH_NOMMOT)
		oSection1:Cell("PRODUTO")   :SetValue(NJH->NJH_DESPRO)
		oSection1:Cell("FORNECEDOR"):SetValue(NJH->NJH_NOMENT)
		oSection1:Cell("CLIENTE")   :SetValue(If(NJH->NJH_CODENT $ '001575-001587', 'PREFEITURA', NJH->NJH_XCLIEN))
		oSection1:Cell("PESO1")     :SetValue(NJH->NJH_PESO1)
		oSection1:Cell("PESO2")     :SetValue(NJH->NJH_PESO2)
		oSection1:Cell("PSLIQ")     :SetValue(NJH->NJH_PSSUBT)
		oSection1:Cell("STATUS")    :SetValue(xDescStat3(AllTrim(NJH->NJH_STATUS)))
		oSection1:Cell("OBS")       :SetValue(NJH->NJH_OBS)
		oSection1:Cell("ROTA")      :SetValue(NJH->NJH_XROTA)
		oSection1:PrintLine()

		nQtd++
		nTP1 += NJH->NJH_PESO1
		nTP2 += NJH->NJH_PESO2
		nTPL += NJH->NJH_PSSUBT

		(cAlias)->(dbSkip())
	EndDo

	(cAlias)->(dbCloseArea())

	oReport:SkipLine()
	oSection1:Cell("TICKET")    :SetValue("TOTAL")
	oSection1:Cell("XCLVL")     :SetValue("")
	oSection1:Cell("DESCC")     :SetValue("Registros: " + cValToChar(nQtd))
	oSection1:Cell("DATA")      :SetValue("")
	oSection1:Cell("PLACA")     :SetValue("")
	oSection1:Cell("DATENT")    :SetValue("")
	oSection1:Cell("HORENT")    :SetValue("")
	oSection1:Cell("DATSAI")    :SetValue("")
	oSection1:Cell("HORSAI")    :SetValue("")
	oSection1:Cell("MOTORISTA") :SetValue("")
	oSection1:Cell("PRODUTO")   :SetValue("")
	oSection1:Cell("FORNECEDOR"):SetValue("")
	oSection1:Cell("CLIENTE")   :SetValue("")
	oSection1:Cell("PESO1")     :SetValue(nTP1)
	oSection1:Cell("PESO2")     :SetValue(nTP2)
	oSection1:Cell("PSLIQ")     :SetValue(nTPL)
	oSection1:Cell("STATUS")    :SetValue("")
	oSection1:Cell("OBS")       :SetValue("")
	oSection1:Cell("ROTA")      :SetValue("")
	oSection1:PrintLine()

	oSection1:Finish()
#ENDIF
Return Nil
