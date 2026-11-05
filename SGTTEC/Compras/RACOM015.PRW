#INCLUDE "PROTHEUS.CH"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ RACOM004  ³ Autor ³Sinval Gedolin        ³ Data ³ 01/2022  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Histórico Condição de Pagamento                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³                                                           ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Generico                                                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
user Function RACOM015()
Local oReport

AjustaSX1("RACOM15")
oReport:= ReportDef()
oReport:PrintDialog()
                                               
Return

Static Function ReportDef()
Local aOrdem   	:= {} 
Local cTitle   	:= "Histórico de Compras Condição de Pagamento - Período: "
Local oReport 
Local oSection1
Local cAliasZAJ := "SD1"

Pergunte("RACOM15",.T.)

oReport:= TReport():New("RACOM015",cTitle+" "+dtoc(MV_PAR01)+" à "+dToc(MV_PAR02),"RACOM015", {|oReport| ReportPrint(oReport,aOrdem,cAliasZAJ)},"Histórico Condição Pagamento")
oReport:SetTotalInLine(.F.)
oReport:SetLandscape() 
oReport:oPage:setPaperSize(10)

//oReport:ShowHeader()

oSection1:=TRSection():New(oReport,"Histórico de Condição de Pagamento",{"SC7","SE2"},{})
//oSection1:=TRSection():New(oReport,"Gastos Geral - Referência: "+dToc(MV_PAR01),{"ST9","STL","STJ","TQN","SZ1","CTT"},,,,,.F.,.T.,.F.,.T.)

oSection1:SetTotalInLine(.F.)
TRCell():New(oSection1,"F1_DOC"  	,"SF1",     , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"F1_SERIE"   ,"SF1", 	, /*Picture*/		,           ,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"F1_FORNECE" ,"SF1", 	, /*Picture*/		,           ,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"F1_LOJA"    ,"SF1", 	, 				    ,     		,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"A2_NOME"    ,"SA2", 	, 					,     		,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"F1_COND"    ,"SF1",     ,                   ,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"E4_DESCRI"  ,"SE4",     , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"F1_EMISSAO" ,"SF1", 	,   				,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"F1_VALBRUT" ,"SF1", 	,    				,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"F1_ESPECIE" ,"SF1",     ,                   ,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"F1_PREFIXO" ,"SF1",     , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"E2_EMISSAO" ,"SE2",     , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"E2_VENCREA" ,"SE2",     , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"E2_VALOR"   ,"SE2",     , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)

Return(oReport)

Static Function ReportPrint(oReport,aOrdem,cAliasZAJ)
	Local oSection1 := oReport:Section(1)
	Local cQuery    := ""
	Local cAliasTOP := GetNextAlias()
	Local dDtIni	:= MV_PAR01
	Local dDtFin	:= MV_PAR02

    cQuery := "SELECT SF1.F1_DOC, SF1.F1_SERIE, SF1.F1_FORNECE, SF1.F1_LOJA, SA2.A2_NOME, SF1.F1_EMISSAO, SF1.F1_VALBRUT, SF1.F1_ESPECIE, "
    cQuery += "SF1.F1_PREFIXO, SF1.F1_COND, SE4.E4_DESCRI, SE2.E2_EMISSAO EMISSAO_TIT, SE2.E2_VENCREA VENC_TIT, SE2.E2_VALOR " 
    cQuery += "FROM "+retSqlName("SF1") + " SF1 "
    cQuery += "INNER JOIN "+retSqlName("SA2") + " SA2 ON (SA2.D_E_L_E_T_ = ' ' AND SA2.A2_COD = SF1.F1_FORNECE AND SA2.A2_LOJA = SF1.F1_LOJA) "
    cQuery += "INNER JOIN "+retSqlName("SE4") + " SE4 ON (SE4.D_E_L_E_T_ = ' ' AND SE4.E4_CODIGO = SF1.F1_COND) "
    cQuery += "INNER JOIN "+retSqlName("SE2") + " SE2 ON (SE2.D_E_L_E_T_ = ' ' AND SE2.E2_PREFIXO = SF1.F1_SERIE AND SE2.E2_NUM = SF1.F1_DOC AND "
    cQuery += "                                           SE2.E2_FORNECE = SF1.F1_FORNECE AND SE2.E2_LOJA = SF1.F1_LOJA) "
    cQuery += "WHERE SF1.D_E_L_E_T_ = ' ' AND SF1.F1_EMISSAO BETWEEN '"+dtos(dDtIni)+"' AND '"+dtos(dDtFin)+"' "
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasTop,.T.,.T.)

	oSection1:Init()

	dbSelectArea(cAliasTOP)
	dbgotop()
	do while (cAliasTOP)->(!Eof())

		oReport:IncMeter()
		If oReport:Cancel()
			Exit
		EndIf

		oSection1:Cell("F1_DOC"):SetValue((cAliasTop)->F1_DOC)
		oSection1:Cell("F1_DOC"):SetAlign("LEFT")

		oSection1:Cell("F1_SERIE"):SetValue((cAliasTop)->F1_SERIE)
		oSection1:Cell("F1_SERIE"):SetAlign("LEFT")

		oSection1:Cell("F1_FORNECE"):SetValue((cAliasTop)->F1_FORNECE)
		oSection1:Cell("F1_FORNECE"):SetAlign("LEFT")

		oSection1:Cell("F1_LOJA"):SetValue((cAliasTop)->F1_LOJA)
		oSection1:Cell("F1_LOJA"):SetAlign("RIGHT")
		
		oSection1:Cell("A2_NOME"):SetValue((cAliasTop)->A2_NOME)
		oSection1:Cell("A2_NOME"):SetAlign("RIGHT")

		oSection1:Cell("F1_COND"):SetValue((cAliasTop)->F1_COND)
		oSection1:Cell("F1_COND"):SetAlign("RIGHT")

		oSection1:Cell("E4_DESCRI"):SetValue((cAliasTop)->E4_DESCRI)
		oSection1:Cell("E4_DESCRI"):SetAlign("RIGHT")

		oSection1:Cell("F1_EMISSAO"):SetValue(stod((cAliasTop)->F1_EMISSAO))
		oSection1:Cell("F1_EMISSAO"):SetAlign("LEFT")

		oSection1:Cell("F1_VALBRUT"):SetValue((cAliasTop)->F1_VALBRUT)
		oSection1:Cell("F1_VALBRUT"):SetAlign("RIGHT")

		oSection1:Cell("F1_ESPECIE"):SetValue((cAliasTop)->F1_ESPECIE)
		oSection1:Cell("F1_ESPECIE"):SetAlign("LEFT")
		
		oSection1:Cell("F1_PREFIXO"):SetValue((cAliasTop)->F1_PREFIXO)
		oSection1:Cell("F1_PREFIXO"):SetAlign("LEFT")

		oSection1:Cell("E2_EMISSAO"):SetValue(stod((cAliasTop)->EMISSAO_TIT))
		oSection1:Cell("E2_EMISSAO"):SetAlign("LEFT")        

		oSection1:Cell("E2_VENCREA"):SetValue(stod((cAliasTop)->VENC_TIT))
		oSection1:Cell("E2_VENCREA"):SetAlign("LEFT")        

		oSection1:Cell("E2_VALOR"):SetValue((cAliasTop)->E2_VALOR)
		oSection1:Cell("E2_VALOR"):SetAlign("RIGHT")

		oSection1:PrintLine()

		(cAliasTOP)->(DbSkip())
	enddo

	(cAliasTOP)->(dbCloseArea())
	oSection1:Finish()

Return Nil 

//===============
// AjustaSX1 
//
Static Function AjustaSX1(cPerg)
Local _sAlias 	:= Alias()
Local aRegs 	:= {}
Local i,j

dbSelectArea("SX1")
dbSetOrder(1)
cPerg := PADR(cPerg,10)

//(sx1) Grupo/Ordem/Pergunta/Variavel/Tipo/Tamanho/Decimal/Presel/GSC/Valid/Var01/Def01/Cnt01/Var02/Def02/Cnt02/Var03/Def03/Cnt03/Var04/Def04/Cnt04/Var05/Def05/Cnt05
aAdd(aRegs,{cPerg,"01","Data De ?"   ,"","","mv_ch1","D", 08,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","",""})
aAdd(aRegs,{cPerg,"02","Data Até?"   ,"","","mv_ch2","D", 08,0,0,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","","","",""})

For i:=1 to Len(aRegs)
	If !dbSeek(cPerg+aRegs[i,2])
		RecLock("SX1",.T.)
		For j:=1 to FCount()
			If j <= Len(aRegs[i])
				FieldPut(j,aRegs[i,j])
			Endif
		Next
		MsUnlock()
	Endif
Next
dbSelectArea(_sAlias)
Return

