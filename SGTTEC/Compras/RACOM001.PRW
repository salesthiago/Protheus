#INCLUDE "PROTHEUS.CH"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ RACOM001  ³ Autor ³Sinval Gedolin        ³ Data ³ 01/2022  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ relação de Notas Fiscais                                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³                                                           ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Generico                                                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
user Function RACOM001()
Local oReport

AjustaSX1("RACOM01")
oReport:= ReportDef()
oReport:PrintDialog()
                                               
Return

Static Function ReportDef()
Local aOrdem   	:= {} 
Local cTitle   	:= "Relatório de Notas Fiscais Compras - Período: "
Local oReport 
Local oSection1
Local cAliasZAJ := "SF1"

Pergunte("RACOM01",.T.)

oReport:= TReport():New("RACOM001",cTitle+" "+StrZero(day(firstday(MV_PAR01)),2)+" à "+dToc(lastday(MV_PAR01)),"RACOM001", {|oReport| ReportPrint(oReport,aOrdem,cAliasZAJ)},"Relação de Notas Fiscais")
oReport:SetTotalInLine(.F.)
oReport:SetLandscape() 
oReport:oPage:setPaperSize(10)

//oReport:ShowHeader()

oSection1:=TRSection():New(oReport,"Relação de Notas Fiscais",{"ST9","STL","STJ","TQN","SZ1","CTT"},{})
//oSection1:=TRSection():New(oReport,"Gastos Geral - Referência: "+dToc(MV_PAR01),{"ST9","STL","STJ","TQN","SZ1","CTT"},,,,,.F.,.T.,.F.,.T.)

oSection1:SetTotalInLine(.F.)

TRCell():New(oSection1,"F1_FILIAL","SF1",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/,,,,,,.F.)
TRCell():New(oSection1,"F1_DOC","SF1",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/,,,,,,.F.)
TRCell():New(oSection1,SerieNfId("SF1",3,"F1_SERIE"),"SF1",SerieNfId("SF1",7,"F1_SERIE"),/*Picture*/,SerieNfId("SF1",6,"F1_SERIE"),/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"F1_EMISSAO","SF1",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"F1_DTDIGIT","SF1",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"F1_FORNECE","SF1",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"F1_LOJA","SD1",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"A2_NOME","   ",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"A2_MUN","   ",/*STR0068*/,"@!",15,/*lPixel*/,/*{|| code-block de impressao }*/) //"Praca"
TRCell():New(oSection1,"F1_COND","SF1","Cond.",/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"E4_DESCRI","SE4",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"F1_VALBRUT","SF1",/*"Tot.Geral"*/,,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"VENCIMENTO","   ","Vencimentos",,100,/*lPixel*/,/*{|| code-block de impressao }*/)

oSection1:Cell("A2_NOME"):GetFieldInfo("A2_NOME")
oSection1:Cell("A2_NOME"):SetSize(50)

oSection1:Cell("E4_DESCRI"):GetFieldInfo("E4_DESCRI")
oSection1:Cell("E4_DESCRI"):SetSize(15)

oSection1:Cell("F1_FILIAL"):SetHeaderAlign("LEFT")
oSection1:Cell("F1_DOC"):SetHeaderAlign("LEFT")
oSection1:Cell("F1_SERIE"):SetHeaderAlign("LEFT")
oSection1:Cell("F1_EMISSAO"):SetHeaderAlign("LEFT")
oSection1:Cell("F1_DTDIGIT"):SetHeaderAlign("LEFT")
oSection1:Cell("F1_FORNECE"):SetHeaderAlign("LEFT")
oSection1:Cell("F1_LOJA"):SetHeaderAlign("LEFT")
oSection1:Cell("A2_NOME"):SetHeaderAlign("LEFT")
oSection1:Cell("A2_MUN"):SetHeaderAlign("LEFT")
oSection1:Cell("F1_COND"):SetHeaderAlign("LEFT")
oSection1:Cell("F1_VALBRUT"):SetHeaderAlign("RIGHT")

oBreak1 := TRBreak():New( oSection1, oSection1:Cell("F1_DTDIGIT"), "Total",.F. )	//"                    T O T A L :"
TRFunction():New(oSection1:Cell("F1_VALBRUT"),"F1_VALBRUT"	,"SUM",oBreak1, , , ,.F., .F. )

Return(oReport)

Static Function ReportPrint(oReport,aOrdem,cAliasZAJ)
Local oSection1 := oReport:Section(1)
Local cQuery    := ""
Local cAliasTOP := GetNextAlias()
Local dDtIni	:= MV_PAR01
Local dDtFin	:= MV_PAR02

cQuery := "SELECT F1_FILIAL, F1_DOC, F1_SERIE, F1_EMISSAO, F1_DTDIGIT,F1_TIPO,F1_COND,F1_VALICM,F1_VALIPI,F1_VALIMP1, "
cQuery += "F1_FRETE,F1_DESPESA,F1_SEGURO,F1_DESCONT,F1_VALMERC,F1_FORNECE,F1_LOJA,F1_VALBRUT, "
cQuery += "A2_NOME, A2_MUN "
cQuery += "FROM "+retSqlName("SF1") + " SF1 "
cQuery += "INNER JOIN "+retSqlName("SA2") + " SA2 ON "
cQuery += "(SA2.D_E_L_E_T_ = ' ' AND SA2.A2_COD = SF1.F1_FORNECE AND SA2.A2_LOJA = SF1.F1_LOJA) "
cQuery += " WHERE SF1.D_E_L_E_T_ = ' ' "
cQuery += "AND SF1.F1_DTDIGIT BETWEEN '"+dtos(dDtIni)+ "' AND '"+dtos(dDtFin)+"' "
cQuery += "ORDER BY F1_FILIAL, F1_DOC "
dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasTop,.T.,.T.)

oSection1:Init()

dbSelectArea(cAliasTOP)
dbgotop()
do while (cAliasTOP)->(!Eof())

	oReport:IncMeter()
	If oReport:Cancel()
		Exit
	EndIf

    SD1->(DbSetOrder(1))
    if SD1->(dbSeek((cAliasTop)->(F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA)))
        if empty(SD1->D1_TES)
            (cAliasTop)->(dbSkip())
            loop
        endif
    else
        (cAliasTop)->(DbSkip())
        loop
    endif

	oSection1:Cell("F1_FILIAL"):SetValue((cAliasTop)->F1_FILIAL)
	oSection1:Cell("F1_FILIAL"):SetAlign("LEFT")
	
	oSection1:Cell("F1_DOC"):SetValue((cAliasTop)->F1_DOC)
	oSection1:Cell("F1_DOC"):SetAlign("LEFT")
	
		//oSection1:Cell("F1_SERIE"):SetValue((cAliasTop)->F1_SERIE)
		//oSection1:Cell("F1_SERIE"):SetAlign("LEFT")

		oSection1:Cell("F1_EMISSAO"):SetValue(stoD((cAliasTop)->F1_EMISSAO))
		oSection1:Cell("F1_EMISSAO"):SetAlign("LEFT")
	
		oSection1:Cell("F1_DTDIGIT"):SetValue(stoD((cAliasTop)->F1_DTDIGIT))
		oSection1:Cell("F1_DTDIGIT"):SetAlign("LEFT")

		//oSection1:Cell("F1_FORNECE"):SetValue((cAliasTop)->F1_FORNECE)
		//oSection1:Cell("F1_FORNECE"):SetAlign("LEFT")
	
		//oSection1:Cell("F1_LOJA"):SetValue((cAliasTop)->F1_LOJA)
		//oSection1:Cell("F1_LOJA"):SetAlign("LEFT")
	
		oSection1:Cell("A2_NOME"):SetValue((cAliasTop)->A2_NOME)
		oSection1:Cell("A2_NOME"):SetAlign("LEFT")
		
		//oSection1:Cell("A2_MUN"):SetValue((cAliasTop)->A2_MUN)
		//oSection1:Cell("A2_MUN"):SetAlign("LEFT")
	
		oSection1:Cell("F1_COND"):SetValue((cAliasTop)->F1_COND)
		oSection1:Cell("F1_COND"):SetAlign("LEFT")

		oSection1:Cell("E4_DESCRI"):SetValue(Posicione("SE4",1,xFilial("SE4")+(cAliasTop)->F1_COND,"E4_DESCRI"))
		oSection1:Cell("E4_DESCRI"):SetAlign("LEFT")

		oSection1:Cell("F1_VALBRUT"):SetValue((cAliasTop)->F1_VALBRUT)
		oSection1:Cell("F1_VALBRUT"):SetAlign("RIGHT")

		oSection1:Cell("VENCIMENTO"):SetValue(fbsucaFin((cAliasTop)->F1_FILIAL, (cAliasTop)->F1_FORNECE,;
                                                        (cAliasTop)->F1_LOJA, (cAliasTop)->F1_SERIE, (cAliasTop)->F1_DOC ))
		oSection1:Cell("VENCIMENTO"):SetAlign("LEFT")

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

static function fbsucaFin(_cFilial, _cFornece, _cLoja, _cSerie, _cDoc )
    Local cRet      := ""
    Local cChaveSE2 := _cFilial+_cFornece+_cLoja+_cSerie+_cDoc
    Local _cAreas   := getArea()

    SE2->(DbSetOrder(6)) //E2_FILIAL+E2_FORNECE+E2_LOJA+E2_PREFIXO+E2_NUM
    if SE2->(DbSeek(cChaveSE2))
        do while SE2->(!Eof()) .and. SE2->(E2_FILIAL+E2_FORNECE+E2_LOJA+E2_PREFIXO+E2_NUM) == cChaveSE2
            
            cRet += dToC(SE2->E2_VENCREA) + " - "+alltrim(Transform(SE2->E2_VALOR,"@E 99999,999.99")) + " "

            SE2->(DbSkip())
        enddo
    endif

    RestArea(_cAreas)

return(cRet)
