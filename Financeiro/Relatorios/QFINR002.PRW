#INCLUDE "PROTHEUS.CH"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ QFINR001 ³ Autor ³Sinval Gedolin       ³ Data ³ 01/2022    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Relação Faturamento                                        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Generico                                                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
user Function QFINR002()
Local oReport

AjustaSX1("QFINR001")
oReport:= ReportDef()
oReport:PrintDialog()
                                               
Return

Static Function ReportDef()
Local aOrdem   	:= {} 
Local cTitle   	:= "Faturamento por Cliente-Estado X Baixa Financeiro no Período: "
Local oReport 
Local oSection1
Local cAliasZAJ := "SD2"

Pergunte("QFINR001",.T.)

oReport:= TReport():New("QFINR002",cTitle+" "+dToC(MV_PAR01)+" à "+dToc(MV_PAR01),"QFINR002", {|oReport| ReportPrint(oReport,aOrdem,cAliasZAJ)},"Faturamento Por Cliente")
oReport:SetTotalInLine(.F.)
oReport:SetLandscape() 
oReport:oPage:setPaperSize(10)

//oReport:ShowHeader()

oSection1:=TRSection():New(oReport,"Faturamento por Cliente-Estado",{"SD2","SA1","SF4"},{})
//oSection1:=TRSection():New(oReport,"Gastos Geral - Referência: "+dToc(MV_PAR01),{"ST9","STL","STJ","TQN","SZ1","CTT"},,,,,.F.,.T.,.F.,.T.)

oSection1:SetTotalInLine(.F.)

TRCell():New(oSection1,"D2_FILIAL"  ,"SD2",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/,,,,,,.F.)
TRCell():New(oSection1,"D2_CLIENTE" ,"SD2",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/,,,,,,.F.)
TRCell():New(oSection1,"D2_LOJA" 	,"SD2",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/,,,,,,.F.)
TRCell():New(oSection1,"A1_NOME"    ,"SA1",/*Titulo*/,/*Picture*/,70,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"A1_EST"    	,"SA1",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"D2_VALBRUT" ,"SD2","Faturamento Bruto",/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"VALIMPOSTO" ,"   ","Valor Impostos","@E 999,999,999,999.99",18 /*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"VALLIQUIDO" ,"   ","Valor Liquido" ,"@E 999,999,999,999.99",18 /*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"VALORBAIXA" ,"   ","Valor Baixado" ,"@E 999,999,999,999.99",18 /*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"SALDORECEB" ,"   ","Saldo a receber","@E 999,999,999,999.99",18 /*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)

oSection1:Cell("D2_CLIENTE"):SetHeaderAlign("LEFT")
oSection1:Cell("D2_LOJA"):SetHeaderAlign("LEFT")
oSection1:Cell("A1_NOME"):SetHeaderAlign("LEFT")
oSection1:Cell("A1_EST"):SetHeaderAlign("LEFT")
oSection1:Cell("D2_VALBRUT"):SetHeaderAlign("RIGHT")
oSection1:Cell("VALIMPOSTO"):SetHeaderAlign("RIGHT")
oSection1:Cell("VALLIQUIDO"):SetHeaderAlign("RIGHT")
oSection1:Cell("SALDORECEB"):SetHeaderAlign("RIGHT")

oBreak1 := TRBreak():New( oSection1, oSection1:Cell("D2_FILIAL"), "Total",.F. )	//"                    T O T A L :"
TRFunction():New(oSection1:Cell("D2_VALBRUT"),"D2_VALBRUT"	,"SUM",oBreak1, , , ,.F., .F. )
TRFunction():New(oSection1:Cell("VALIMPOSTO"),"VALIMPOSTO"	,"SUM",oBreak1, , , ,.F., .F. )
TRFunction():New(oSection1:Cell("VALLIQUIDO"),"VALLIQUIDO"	,"SUM",oBreak1, , , ,.F., .F. )
TRFunction():New(oSection1:Cell("VALORBAIXA"),"VALORBAIXA"	,"SUM",oBreak1, , , ,.F., .F. )
TRFunction():New(oSection1:Cell("SALDORECEB"),"SALDORECEB"	,"SUM",oBreak1, , , ,.F., .F. )

Return(oReport)

Static Function ReportPrint(oReport,aOrdem,cAliasZAJ)
Local oSection1 := oReport:Section(1)
Local cQuery    := ""
Local cAliasTOP := GetNextAlias()
Local dDtIni	:= MV_PAR01
Local dDtFin	:= MV_PAR02

cQuery := "SELECT SD2.D2_FILIAL, SD2.D2_CLIENTE, SD2.D2_LOJA, SA1.A1_NOME, SA1.A1_EST,  SUM(SD2.D2_VALBRUT) VALBRUTO, SUM(SD2.D2_VALISS) VALISS,   "
cQuery += "SUM(SD2.D2_VALINS) VALINSS, SUM(SD2.D2_VALIRRF) VALIRRF, SUM(SD2.D2_VALCSL) VALCSL,										"
cQuery += "SUM(SD2.D2_VALCOF) VALCOF, SUM(SD2.D2_VALPIS) VALPIS																		"
cQuery += "FROM "+retSqlName("SD2") + " SD2 "
cQuery += "INNER JOIN "+retSqlName("SF4") + " SF4 ON (SF4.D_E_L_E_T_ = ' ' AND SF4.F4_CODIGO = SD2.D2_TES AND SF4.F4_ESTOQUE = 'N' AND SF4.F4_DUPLIC = 'S') "
cQuery += "INNER JOIN "+retSqlName("SA1") + " SA1 ON (SA1.D_E_L_E_T_= ' ' AND SA1.A1_COD = SD2.D2_CLIENTE AND SA1.A1_LOJA = SD2.D2_LOJA) "
cQuery += "WHERE SD2.D_E_L_E_T_ = ' '  "
cQuery += "AND SD2.D2_EMISSAO BETWEEN '"+dtos(dDtIni)+ "' AND '"+dtos(dDtFin)+"' "
cQuery += "AND SD2.D2_TIPO = 'N' AND SD2.D2_SERIE IN ('U','R','6') "
cQuery += "GROUP BY SD2.D2_FILIAL, SD2.D2_CLIENTE, SD2.D2_LOJA, SA1.A1_NOME, SA1.A1_EST "
cQuery += "ORDER BY SA1.A1_EST, SA1.A1_NOME "
dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasTop,.T.,.T.)

oSection1:Init()

dbSelectArea(cAliasTOP)
dbgotop()
do while (cAliasTOP)->(!Eof())

	oReport:IncMeter()
	If oReport:Cancel()
		Exit
	EndIf

	oSection1:Cell("D2_FILIAL"):SetValue((cAliasTop)->D2_FILIAL)
	
	oSection1:Cell("D2_CLIENTE"):SetValue((cAliasTop)->D2_CLIENTE)
	
	oSection1:Cell("D2_LOJA"):SetValue((cAliasTop)->D2_LOJA)

	oSection1:Cell("A1_NOME"):SetValue((cAliasTop)->A1_NOME)

	oSection1:Cell("A1_EST"):SetValue((cAliasTop)->A1_EST)

	oSection1:Cell("D2_VALBRUT"):SetValue((cAliasTop)->VALBRUTO)
	
	nTotimp := (cAliasTop)->(VALISS + VALINSS + VALIRRF + VALCSL + VALCOF + VALPIS)
	oSection1:Cell("VALIMPOSTO"):SetValue(nTotimp)

	nVlrLiq := (cAliasTop)->VALBRUTO - nTotimp

	nSaldoTit := fVerBaixa( (cAliasTop)->D2_FILIAL, (cAliasTop)->D2_CLIENTE, (cAliasTop)->D2_LOJA, dDtIni, dDtFin )	

	oSection1:Cell("VALLIQUIDO"):SetValue(nVlrLiq)

	oSection1:Cell("VALORBAIXA"):SetValue(nVlrLiq - nSaldoTit)

	oSection1:Cell("SALDORECEB"):SetValue(nSaldoTit)

	oSection1:PrintLine()

	(cAliasTOP)->(DbSkip())
enddo

(cAliasTOP)->(dbCloseArea())
oSection1:Finish()

Return(Nil )

//===============
// AjustaSX1 
//
Static Function AjustaSX1(cPerg)
Local _sAlias := Alias()
Local aRegs := {}
Local i,j

dbSelectArea("SX1")
dbSetOrder(1)
cPerg := PADR(cPerg,10)

//(sx1) Grupo/Ordem/Pergunta/Variavel/Tipo/Tamanho/Decimal/Presel/GSC/Valid/Var01/Def01/Cnt01/Var02/Def02/Cnt02/Var03/Def03/Cnt03/Var04/Def04/Cnt04/Var05/Def05/Cnt05
aAdd(aRegs,{cPerg,"01","Data De ?"   ,"","","mv_ch1","D", 08,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","",""})
aAdd(aRegs,{cPerg,"02","Data Até?"   ,"","","mv_ch2","D", 16,0,0,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","","","",""})

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

static function fVerBaixa(cFilSF2, cCliente, cLoja, dDataini, dDataFin)
	Local nValor 	:= 0
	Local cQryF2 	:= ""
	Local _cAreas 	:= getArea()
	Local cAliasF2  := GetNextAlias()

	cQryF2 := "SELECT SF2.F2_DOC, SF2.F2_SERIE, SF2.F2_CLIENTE, SF2.F2_LOJA, SF2.F2_VALBRUT, SE1.E1_SALDO,  "
	cQryF2 += "SE1.E1_IRRF, SE1.E1_ISS, SE1.E1_INSS, SE1.E1_CSLL, SE1.E1_COFINS, SE1.E1_PIS                 "
	cQryF2 += "FROM "+retSqlName("SF2") + " SF2 "
	cQryF2 += "INNER JOIN SE1010 SE1 ON (SE1.D_E_L_E_T_ = ' ' AND SE1.E1_FILIAL = SF2.F2_FILIAL AND SE1.E1_NUM = SF2.F2_DOC                   "
	cQryF2 += "AND SE1.E1_PREFIXO = SF2.F2_SERIE  AND SF2.F2_CLIENTE = SE1.E1_CLIENTE AND SF2.F2_LOJA = SE1.E1_LOJA AND SE1.E1_TIPO = 'NF')   "
	cQryF2 += "WHERE SF2.D_E_L_E_T_ = ' ' AND SF2.F2_FILIAL = '"+cFilSF2+"' AND SF2.F2_CLIENTE = '"+cCliente+"' AND SF2.F2_LOJA = '"+cLoja+"' "
	cQryF2 += "AND SF2.F2_EMISSAO BETWEEN '"+dtos(dDataini)+"' AND '"+dtos(dDataFin)+"' AND SF2.F2_TIPO = 'N' AND SF2.F2_SERIE IN ('U','R','6')   "
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQryF2),cAliasF2,.T.,.T.)

	(cAliasF2)->(dbgotop())
	do while (cAliasF2)->(!Eof())
		if (cAliasF2)->E1_SALDO > 0 

			nValor += (cAliasF2)->(E1_SALDO - E1_IRRF - E1_ISS - E1_INSS - E1_CSLL - E1_COFINS - E1_PIS)
		
		endif
		
		(cAliasF2)->(DbSkip())
	enddo
	(cAliasF2)->(dbCloseArea())

	restarea(_cAreas)

return(nValor)





/*

SELECT SD2.D2_FILIAL, SD2.D2_CLIENTE, SD2.D2_LOJA, SA1.A1_NOME, SA1.A1_EST,  SUM(SD2.D2_VALBRUT) VALBRUTO, SUM(SD2.D2_VALISS) VALISS,   
SUM(SD2.D2_VALINS) VALINSS, SUM(SD2.D2_VALIRRF) VALIRRF, SUM(SD2.D2_VALCSL) VALCSL,										
SUM(SD2.D2_VALCOF) VALCOF, SUM(SD2.D2_VALPIS) VALPIS																		
FROM SD2010 SD2 
INNER JOIN SF4010 SF4 ON (SF4.D_E_L_E_T_ = ' ' AND SF4.F4_CODIGO = SD2.D2_TES AND SF4.F4_ESTOQUE = 'N' AND SF4.F4_DUPLIC = 'S') 
INNER JOIN SA1010 SA1 ON (SA1.D_E_L_E_T_= ' ' AND SA1.A1_COD = SD2.D2_CLIENTE AND SA1.A1_LOJA = SD2.D2_LOJA) 
WHERE SD2.D_E_L_E_T_ = ' '  
AND SD2.D2_EMISSAO BETWEEN '20240301' AND '20240326'
AND SD2.D2_TIPO = 'N' AND SD2.D2_SERIE = 'U' 
GROUP BY SD2.D2_FILIAL, SD2.D2_CLIENTE, SD2.D2_LOJA, SA1.A1_NOME, SA1.A1_EST 
ORDER BY SA1.A1_EST, SA1.A1_NOME 

*/
