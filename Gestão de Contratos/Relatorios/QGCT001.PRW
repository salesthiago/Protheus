#INCLUDE "PROTHEUS.CH"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ QGCT001 ³ Autor ³Sinval Gedolin       ³ Data ³ 01/2022  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ relação de Medições realizadas - Itens                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³                                                           ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Generico                                                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
user Function QGCT001()
Local oReport

AjustaSX1("QGCT001")
oReport:= ReportDef()
oReport:PrintDialog()
                                               
Return

Static Function ReportDef()
Local aOrdem   	:= {} 
Local cTitle   	:= "Relatório de Medições Realizadas por Item - Período: "
Local oReport 
Local oSection1
Local cAliasZAJ := "CNE"

Pergunte("RACOM01",.T.)

oReport:= TReport():New("QGCT001",cTitle+" "+StrZero(day(firstday(MV_PAR01)),2)+" à "+dToc(lastday(MV_PAR01)),"QGCT001", {|oReport| ReportPrint(oReport,aOrdem,cAliasZAJ)},"Relação de Notas Fiscais")
oReport:SetTotalInLine(.F.)
oReport:SetLandscape() 
oReport:oPage:setPaperSize(10)

//oReport:ShowHeader()

oSection1:=TRSection():New(oReport,"Relação das Medições",{"CNE","CTT","SB1","SA2"},{})
//oSection1:=TRSection():New(oReport,"Gastos Geral - Referência: "+dToc(MV_PAR01),{"ST9","STL","STJ","TQN","SZ1","CTT"},,,,,.F.,.T.,.F.,.T.)

oSection1:SetTotalInLine(.F.)

TRCell():New(oSection1,"CNE_FILIAL" ,"CNE",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/,,,,,,.F.)
TRCell():New(oSection1,"CNE_PRODUT" ,"CNE",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/,,,,,,.F.)
TRCell():New(oSection1,"B1_DESC"    ,"SB1",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"A2_NOME"    ,"SA2",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"CNE_VLTOT"  ,"CNE",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"CNE_DTENT"  ,"CNE",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"CNE_CONTRA" ,"CNE",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"CNE_REVISA" ,"CNE",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"CNE_NUMMED" ,"CNE",/*STR0068*/,,,/*lPixel*/,/*{|| code-block de impressao }*/) //"Praca"
TRCell():New(oSection1,"CNE_CC"     ,"CNE",/* */,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"CTT_DESC01" ,"CTT",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"TIPOCTR" 	,"   ","Operação" /*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)

oSection1:Cell("CNE_FILIAL"):SetHeaderAlign("LEFT")
oSection1:Cell("CNE_PRODUT"):SetHeaderAlign("LEFT")
oSection1:Cell("B1_DESC"):SetHeaderAlign("LEFT")
oSection1:Cell("A2_NOME"):SetHeaderAlign("LEFT")
oSection1:Cell("CNE_VLTOT"):SetHeaderAlign("RIGHT")
oSection1:Cell("CNE_DTENT"):SetHeaderAlign("LEFT")
oSection1:Cell("CNE_CONTRA"):SetHeaderAlign("LEFT")
oSection1:Cell("CNE_REVISA"):SetHeaderAlign("LEFT")
oSection1:Cell("CNE_NUMMED"):SetHeaderAlign("LEFT")
oSection1:Cell("CNE_CC"):SetHeaderAlign("LEFT")
oSection1:Cell("CTT_DESC01"):SetHeaderAlign("LEFT")

oBreak1 := TRBreak():New( oSection1, oSection1:Cell("CNE_FILIAL"), "Total",.F. )	//"                    T O T A L :"
TRFunction():New(oSection1:Cell("CNE_VLTOT"),"CNE_VLTOT"	,"SUM",oBreak1, , , ,.F., .F. )

Return(oReport)

Static Function ReportPrint(oReport,aOrdem,cAliasZAJ)
Local oSection1 := oReport:Section(1)
Local cQuery    := ""
Local cAliasTOP := GetNextAlias()
Local dDtIni	:= MV_PAR01
Local dDtFin	:= MV_PAR02

cQuery := "SELECT CNE.CNE_FILIAL, CNE.CNE_PRODUT, SB1.B1_DESC, CNE.CNE_VLTOT, CNE.CNE_DTENT, CNE.CNE_CONTRA, CNE.CNE_REVISA, CNE.CNE_NUMMED, "
cQuery += "CNE.CNE_PEDIDO, CNE.CNE_CC, CTT.CTT_DESC01, CNA.CNA_FORNEC, CNA.CNA_LJFORN, SA2.A2_NOME, CNE.CNE_FLGCMS, CNA.CNA_CLIENT, CNA.CNA_LOJACL, SA1.A1_NOME "
cQuery += "FROM "+retSqlName("CNE") + " CNE "
cQuery += "INNER JOIN "+retSqlName("SB1") + " SB1 ON (SB1.D_E_L_E_T_ = ' ' AND SB1.B1_COD = CNE.CNE_PRODUT) "
cQuery += "INNER JOIN CNA010 CNA ON (CNA.D_E_L_E_T_ = ' ' AND CNA.CNA_FILIAL = CNE.CNE_FILIAL AND CNA.CNA_CONTRA = CNE.CNE_CONTRA AND CNA.CNA_NUMERO = CNE.CNE_NUMERO AND CNA.CNA_REVISA  = CNE.CNE_REVISA) "
cQuery += "LEFT JOIN SA2010 SA2 ON (SA2.D_E_L_E_T_ = ' ' AND SA2.A2_COD = CNA.CNA_FORNEC AND SA2.A2_LOJA = CNA.CNA_LJFORN) "
cQuery += "LEFT JOIN SA1010 SA1 ON (SA1.D_E_L_E_T_ = ' ' AND SA1.A1_COD = CNA.CNA_CLIENT AND SA1.A1_LOJA = CNA.CNA_LOJACL) "
cQuery += "LEFT JOIN "+retSqlName("CTT") + " CTT ON (CTT.D_E_L_E_T_ = ' ' AND CTT.CTT_CUSTO = CNE.CNE_CC) "
cQuery += "WHERE CNE.D_E_L_E_T_ = ' ' "
cQuery += "AND CNE.CNE_DTENT BETWEEN '"+dtos(dDtIni)+ "' AND '"+dtos(dDtFin)+"' "
//cQuery += "AND CNE.CNE_FLGCMS = '2' "
dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasTop,.T.,.T.)

oSection1:Init()

dbSelectArea(cAliasTOP)
dbgotop()
do while (cAliasTOP)->(!Eof())

	oReport:IncMeter()
	If oReport:Cancel()
		Exit
	EndIf

	oSection1:Cell("CNE_FILIAL"):SetValue((cAliasTop)->CNE_FILIAL)
	oSection1:Cell("CNE_FILIAL"):SetAlign("LEFT")
	
	oSection1:Cell("CNE_PRODUT"):SetValue((cAliasTop)->CNE_PRODUT)
	oSection1:Cell("CNE_PRODUT"):SetAlign("LEFT")
	
	oSection1:Cell("B1_DESC"):SetValue((cAliasTop)->B1_DESC)
	oSection1:Cell("B1_DESC"):SetAlign("LEFT")

		oSection1:Cell("A2_NOME"):SetValue((cAliasTop)->A2_NOME)
		oSection1:Cell("A2_NOME"):SetAlign("LEFT")

		oSection1:Cell("CNE_VLTOT"):SetValue((cAliasTop)->CNE_VLTOT)
		oSection1:Cell("CNE_VLTOT"):SetAlign("RIGHT")
	
		oSection1:Cell("CNE_DTENT"):SetValue(stoD((cAliasTop)->CNE_DTENT))
		oSection1:Cell("CNE_DTENT"):SetAlign("LEFT")

		oSection1:Cell("CNE_CONTRA"):SetValue((cAliasTop)->CNE_CONTRA)
		oSection1:Cell("CNE_CONTRA"):SetAlign("LEFT")
	
		oSection1:Cell("CNE_REVISA"):SetValue((cAliasTop)->CNE_REVISA)
		oSection1:Cell("CNE_REVISA"):SetAlign("LEFT")
	
		oSection1:Cell("CNE_NUMMED"):SetValue((cAliasTop)->CNE_NUMMED)
		oSection1:Cell("CNE_NUMMED"):SetAlign("LEFT")
		
		oSection1:Cell("CNE_CC"):SetValue((cAliasTop)->CNE_CC)
		oSection1:Cell("CNE_CC"):SetAlign("LEFT")
	
		oSection1:Cell("CTT_DESC01"):SetValue((cAliasTop)->CTT_DESC01)
		oSection1:Cell("CTT_DESC01"):SetAlign("LEFT")

		if (cAliasTOP)->CNE_FLGCMS = '1'
			cTipo := "VENDAS"
		else
			cTipo := "COMPRAS"
		endif
		oSection1:Cell("TIPOCTR"):SetValue(cTipo)
		oSection1:Cell("TIPOCTR"):SetAlign("LEFT")

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

