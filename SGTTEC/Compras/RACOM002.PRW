#INCLUDE "PROTHEUS.CH"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ RACOM002  ³ Autor ³Sinval Gedolin        ³ Data ³ 01/2022  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ relação de Pedidos de Compras no Período                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³                                                           ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Generico                                                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
user Function RACOM002()
Local oReport

AjustaSX1("RACOM02")
oReport:= ReportDef()
oReport:PrintDialog()
                                               
Return

Static Function ReportDef()
Local aOrdem   	:= {} 
Local cTitle   	:= "Relatório de Pedidos de Compras - Período: "
Local oReport 
Local oSection1
Local cAliasZAJ := "SC7"

Pergunte("RACOM02",.T.)

oReport:= TReport():New("RACOM002",cTitle+" "+dtoc(MV_PAR01)+" à "+dToc(MV_PAR02),"RACOM002", {|oReport| ReportPrint(oReport,aOrdem,cAliasZAJ)},"Relação dos Pedidos de Compras")
oReport:SetTotalInLine(.F.)
oReport:SetLandscape() 
oReport:oPage:setPaperSize(10)

//oReport:ShowHeader()

oSection1:=TRSection():New(oReport,"Relação de Pedidos de Compras",{"SC7"},{})
//oSection1:=TRSection():New(oReport,"Gastos Geral - Referência: "+dToc(MV_PAR01),{"ST9","STL","STJ","TQN","SZ1","CTT"},,,,,.F.,.T.,.F.,.T.)

oSection1:SetTotalInLine(.F.)
//Filial      	Descricao   	Prc Unitario	Razao Social	Desc.CC     	DT Emissao  	Num OS	Placa	Vlr Mês	Gasto Total	Cotação 1	Cotação 2	Contação 3
TRCell():New(oSection1,"QBC"  		,"   ",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"C7_FILIAL"  ,"   ","Fil."    ,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"C7_NUM"     ,"   ","Pedido"  ,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"B1_COD"     ,"SB1",          ,/*Picture*/,           ,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"B1_DESC"    ,"SB1",          ,/*Picture*/,           ,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"B1_UM"      ,"   ","U M"     ,/*Picture*/,           ,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"BM_DESC"    ,"   ","Descrição Grupo"     ,/*Picture*/,           ,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"C7_PRECO"   ,"SC7",/*Titulo*/,"@E 9999,999.999",/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"C7_TOTAL"   ,"SC7",/*Titulo*/,"@E 9999,999.99",/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"A2_NOME"    ,"SA2",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"C7_CONTRA"  ,"SC7",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"CTT_DESC01" ,"CTT","Desc. Centro Custo",/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"C7_EMISSAO" ,"SC7",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"TJ_ORDEM"   ,"STJ",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"TJ_CODBEM"  ,"STJ",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"ULTVLR"		,"   ","Ult.Valor","@E 9999,999.999",/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"ULTDATA"	,"   ","Ult.Data" ,                  , 11       ,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"VLRMES"		,"   ","Vlr Mês"  ,"@E 9999,999.999",/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"VLRTOT"		,"   ","Vlr Total","@E 9999,999.999",/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"COTACAO1"	,"   ","Cotacao 1","@E 999,999.999",           ,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"COTACAO2"	,"   ","Cotacao 2","@E 999,999.999",           ,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"COTACAO3"	,"   ","Cotacao 3","@E 999,999.999",           ,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"USUARIO"	,"   ","Aprovador",                ,           ,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"ULTTROCA"	,"   ","Últimas Trocas",           , 50       ,/*lPixel*/,/*{|| code-block de impressao }*/)

//oSection1:Cell("F1_FILIAL"):SetHeaderAlign("LEFT")
//oSection1:Cell("F1_DOC"):SetHeaderAlign("LEFT")

oBreak1 := TRBreak():New( oSection1, oSection1:Cell("C7_FILIAL"), "Sub.Total",.F. )
TRFunction():New(oSection1:Cell("C7_TOTAL"),"C7_TOTALF"	,"SUM", oBreak1, , , ,.F.,.F.)

oBreak2 := TRBreak():New( oSection1, oSection1:Cell("QBC"), "Total Geral",.F. )
TRFunction():New(oSection1:Cell("C7_TOTAL"),"C7_TOTALT"	,"SUM", oBreak2, , , ,.F.,.F.)

Return(oReport)

Static Function ReportPrint(oReport,aOrdem,cAliasZAJ)
Local oSection1 := oReport:Section(1)
Local cQuery    := ""
Local cAliasTOP := GetNextAlias()
Local dDtIni	:= MV_PAR01
Local dDtFin	:= MV_PAR02

cQuery := "SELECT SC7.C7_FILIAL, SC7.C7_NUM, SC7.C7_ITEM, SC7.C7_PRODUTO, SC7.C7_UM, SC7.C7_DESCRI, SBM.BM_DESC, SC7.C7_PRECO, SC7.C7_TOTAL, SA2.A2_NOME, CTT.CTT_DESC01, SC7.C7_EMISSAO, SC7.C7_CONTRA,STJ.TJ_ORDEM, STJ.TJ_CODBEM,  "
cQuery += "SC7.C7_CONTRA, SC7.C7_USER, "
cQuery += "(SELECT TOP 1 SC7U.C7_PRECO FROM SC7010 SC7U WHERE SC7U.D_E_L_E_T_ = ' ' AND SC7U.C7_FILIAL = SC7.C7_FILIAL AND SC7U.C7_PRODUTO = SC7.C7_PRODUTO AND SC7U.C7_NUM <> SC7.C7_NUM ORDER BY SC7U.C7_EMISSAO DESC) ULTIMO_VALOR, "
cQuery += "(SELECT TOP 1 SC7U.C7_EMISSAO FROM SC7010 SC7U WHERE SC7U.D_E_L_E_T_ = ' ' AND SC7U.C7_FILIAL = SC7.C7_FILIAL AND SC7U.C7_PRODUTO = SC7.C7_PRODUTO AND SC7U.C7_NUM <> SC7.C7_NUM ORDER BY SC7U.C7_EMISSAO DESC) ULTIMO_DATA, "
cQuery += "(SELECT SC8.C8_PRECO FROM SC8010 SC8 WHERE SC8.D_E_L_E_T_ = ' ' AND SC8.C8_FILIAL = SC7.C7_FILIAL AND SC8.C8_NUMPED = SC7.C7_NUM AND SC8.C8_ITEMPED = SC7.C7_ITEM) VLR_COTACAO, "
cQuery += "(SELECT SC8.C8_NUM   FROM SC8010 SC8 WHERE SC8.D_E_L_E_T_ = ' ' AND SC8.C8_FILIAL = SC7.C7_FILIAL AND SC8.C8_NUMPED = SC7.C7_NUM AND SC8.C8_ITEMPED = SC7.C7_ITEM) NUMCOT, "
cQuery += "(SELECT SCR.CR_LIBAPRO   FROM SCR010 SCR WHERE SCR.D_E_L_E_T_ = ' ' AND SCR.CR_NUM = SC7.C7_NUM AND SCR.CR_STATUS = '03' AND SCR.CR_FILIAL = SC7.C7_FILIAL) USRAPROV "
cQuery += "FROM "+retSqlName("SC7") + " SC7 " 
cQuery += "INNER JOIN "+retSqlName("SA2") + " SA2 ON (SA2.D_E_L_E_T_ = ' ' AND SA2.A2_COD = SC7.C7_FORNECE AND SA2.A2_LOJA = SC7.C7_LOJA ) "
cQuery += "INNER JOIN "+retSqlName("CTT") + " CTT ON (CTT.D_E_L_E_T_ = ' ' AND CTT.CTT_CUSTO = SC7.C7_CC) "
cQuery += "INNER JOIN "+retSqlName("SB1") + " SB1 ON (SB1.D_E_L_E_T_ = ' ' AND SB1.B1_COD = SC7.C7_PRODUTO) "
cQuery += "INNER JOIN "+retSqlName("SBM") + " SBM ON (SBM.D_E_L_E_T_ = ' ' AND SBM.BM_GRUPO = SB1.B1_GRUPO)"
cQuery += "LEFT JOIN "+retSqlName("SC1") + " SC1 ON (SC1.D_E_L_E_T_ = ' ' AND SC1.C1_FILIAL = SC7.C7_FILIAL AND SC1.C1_NUM = SC7.C7_NUMSC AND SC1.C1_ITEM = SC7.C7_ITEMSC) "
cQuery += "LEFT JOIN "+retSqlName("STJ") + " STJ ON (STJ.D_E_L_E_T_ = ' ' AND STJ.TJ_ORDEM = SUBSTRING(SC1.C1_OP,1,6) AND STJ.TJ_FILIAL = SC7.C7_FILIAL) "
cQuery += "WHERE SC7.D_E_L_E_T_ = ' '  "
cQuery += "AND SC7.C7_EMISSAO BETWEEN '"+dtos(dDtIni)+"' AND '"+dtos(dDtFin)+"' "
cQuery += "AND SC7.C7_CONAPRO = 'L' "
cQuery += "ORDER BY SC7.C7_FILIAL, SC7.C7_DESCRI, CTT.CTT_DESC01 "
dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasTop,.T.,.T.)

oSection1:Init()

dbSelectArea(cAliasTOP)
dbgotop()
do while (cAliasTOP)->(!Eof())

	oReport:IncMeter()
	If oReport:Cancel()
		Exit
	EndIf

	oSection1:Cell("C7_FILIAL"):SetValue((cAliasTop)->C7_FILIAL)
	oSection1:Cell("C7_FILIAL"):SetAlign("LEFT")
	
	oSection1:Cell("C7_NUM"):SetValue((cAliasTop)->C7_NUM)
	oSection1:Cell("C7_NUM"):SetAlign("LEFT")

	oSection1:Cell("B1_COD"):SetValue((cAliasTop)->C7_PRODUTO)
	oSection1:Cell("B1_COD"):SetAlign("LEFT")

	oSection1:Cell("B1_DESC"):SetValue((cAliasTop)->C7_DESCRI)
	oSection1:Cell("B1_DESC"):SetAlign("LEFT")

	oSection1:Cell("B1_UM"):SetValue((cAliasTop)->C7_UM)
	oSection1:Cell("B1_UM"):SetAlign("LEFT")
	
	oSection1:Cell("BM_DESC"):SetValue((cAliasTop)->BM_DESC)
	oSection1:Cell("BM_DESC"):SetAlign("LEFT")

	oSection1:Cell("C7_PRECO"):SetValue((cAliasTop)->C7_PRECO)
	oSection1:Cell("C7_PRECO"):SetAlign("RIGHT")

	oSection1:Cell("C7_TOTAL"):SetValue((cAliasTop)->C7_TOTAL)
	oSection1:Cell("C7_TOTAL"):SetAlign("RIGHT")

	oSection1:Cell("A2_NOME"):SetValue((cAliasTop)->A2_NOME)
	oSection1:Cell("A2_NOME"):SetAlign("LEFT")

	oSection1:Cell("C7_CONTRA"):SetValue((cAliasTop)->C7_CONTRA)
	oSection1:Cell("C7_CONTRA"):SetAlign("LEFT")

	oSection1:Cell("CTT_DESC01"):SetValue((cAliasTop)->CTT_DESC01)
	oSection1:Cell("CTT_DESC01"):SetAlign("LEFT")
	
	oSection1:Cell("C7_EMISSAO"):SetValue(dtoc(stod((cAliasTop)->C7_EMISSAO)))
	oSection1:Cell("C7_EMISSAO"):SetAlign("CENTER")

	oSection1:Cell("TJ_ORDEM"):SetValue((cAliasTop)->TJ_ORDEM)
	oSection1:Cell("TJ_ORDEM"):SetAlign("LEFT")

	oSection1:Cell("TJ_CODBEM"):SetValue((cAliasTop)->TJ_CODBEM)
	oSection1:Cell("TJ_CODBEM"):SetAlign("LEFT")

	oSection1:Cell("ULTVLR"):SetValue((cAliasTop)->ULTIMO_VALOR)
	oSection1:Cell("ULTVLR"):SetAlign("RIGHT")

	oSection1:Cell("ULTDATA"):SetValue(dtoc(stod((cAliasTop)->ULTIMO_DATA)))
	oSection1:Cell("ULTDATA"):SetAlign("CENTER")

	aVlrbem := U_fBuscaSt9((cAliasTop)->TJ_CODBEM)

	oSection1:Cell("VLRMES"):SetValue(aVlrBem[1])
	oSection1:Cell("VLRMES"):SetAlign("RIGHT")

	oSection1:Cell("VLRTOT"):SetValue(aVlrBem[2])
	oSection1:Cell("VLRTOT"):SetAlign("RIGHT")

	oSection1:Cell("COTACAO1"):SetValue((cAliasTop)->VLR_COTACAO)
	oSection1:Cell("COTACAO1"):SetAlign("RIGHT")

	aCotacao := U_FBUSCOT((cAliasTop)->C7_FILIAL, (cAliasTop)->NUMCOT, (cAliasTop)->C7_PRODUTO)

	oSection1:Cell("COTACAO2"):SetValue(aCotacao[1])
	oSection1:Cell("COTACAO2"):SetAlign("RIGHT")

	oSection1:Cell("COTACAO3"):SetValue(aCotacao[2])
	oSection1:Cell("COTACAO3"):SetAlign("RIGHT")

	oSection1:Cell("USUARIO"):SetValue(alltrim(Posicione("SAK",1,(cAliasTop)->C7_FILIAL+(cAliasTop)->USRAPROV,"AK_NOME")))
	oSection1:Cell("USUARIO"):SetAlign("RIGHT")

	cQtdeMnt := fBusMnt((cAliasTop)->TJ_CODBEM, (cAliasTop)->C7_PRODUTO)

	oSection1:Cell("ULTTROCA"):SetValue(alltrim(cQtdeMnt))
	oSection1:Cell("ULTTROCA"):SetAlign("RIGHT")

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

user function FBUSCOT(cFilC7, cNumCot, cProdPed)
	Local aValores 	:= {0,0}
	Local cAliasCOT := GetNextAlias()
	Local nPos

	cQuery := "SELECT SC8.C8_PRECO, SC8.C8_NUMPED, SC8.C8_ITEMPED "
	cQuery += "FROM "+retSqlName("SC8") + " SC8 " 
	cQuery += "WHERE SC8.D_E_L_E_T_ = ' '  "
	cQuery += "AND SC8.C8_FILIAL = '"+cFilC7+"' AND SC8.C8_NUM = '"+cNumCot+"' AND SC8.C8_PRODUTO = '"+cProdPed+"' "
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasCOT,.T.,.T.)

	nPos := 1
	(cAliasCOT)->(dbGoTop())
	do while (cAliasCOT)->(!eof())
		if nPos <= 2
			if (cAliasCOT)->C8_NUMPED = "XXXXXX"
				aValores[nPos] := (cAliasCOT)->C8_PRECO
				nPos++
			endif
		endif

		(cAliasCOT)->(DbSkip())
	enddo

	(cAliasCOT)->(dbCloseArea())

return(aValores)


static function fBusMnt(cCodBem, cCodPro)
	Local cRet 		:= ""
	Local cQuery	:= ""
	Local cAliasTop	:= getNextAlias()
	Local dDataIni	:= firstday(firstday(dDataBase) - 360)

	cQuery := "SELECT TJ_DTORIGI "
	cQuery += "FROM "+retSqlName("STJ") + " STJ "
	cQuery += "INNER JOIN "+retSqlname("STL") + " STL ON (STL.D_E_L_E_T_ = ' ' AND STL.TL_ORDEM = STJ.TJ_ORDEM AND STL.TL_FILIAL = STJ.TJ_FILIAL "
	cQuery += "AND STL.TL_CODIGO = '"+cCodpro+"' ) "
	cQuery += "WHERE STJ.D_E_L_E_T_ = ' ' AND STJ.TJ_CODBEM = '"+cCodBem+"' AND STJ.TJ_TERMINO = 'S' AND "
	cQuery += "STJ.TJ_DTPRINI BETWEEN '"+dtos(dDataIni)+"' AND '"+dtos(ddatabase)+"' "
	cQuery += "ORDER BY STJ.TJ_DTORIGI DESC "
    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasTop,.T.,.T.)    

	(cAliasTop)->(DbGoTop())
	do while (cAliasTop)->(!Eof())

		cRet += dToc(stod((cAliasTop)->TJ_DTORIGI)) + "  "

		(cAliasTop)->(DbSkip())
	enddo

	(cAliasTop)->(DbCloseArea())

return(cRet)
