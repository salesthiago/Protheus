#INCLUDE "PROTHEUS.CH"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ RACOM004  ³ Autor ³Sinval Gedolin        ³ Data ³ 01/2022  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ F|Relação de itens de NF Marcos                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³                                                           ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Generico                                                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
user Function RACOM016()
	Local oReport

	AjustaSX1("RACOM16")
	oReport:= ReportDef()
	oReport:PrintDialog()

Return

Static Function ReportDef()
	Local aOrdem   	:= {}
	Local cTitle   	:= "Itens das Notas Fiscais - Período: "
	Local oReport
	Local oSection1
	Local cAliasZAJ := "SD1"

	Pergunte("RACOM16",.T.)

	oReport:= TReport():New("RACOM016",cTitle+" "+dtoc(MV_PAR01)+" à "+dToc(MV_PAR02),"RACOM016", {|oReport| ReportPrint(oReport,aOrdem,cAliasZAJ)},"Itens das Notas Fiscais")
	oReport:SetTotalInLine(.F.)
	oReport:SetLandscape()
	oReport:oPage:setPaperSize(10)

//oReport:ShowHeader()

	oSection1:=TRSection():New(oReport,"Itens das Notas Fiscais",{"SB1","SF1","SD1","SA2"},{})
//oSection1:=TRSection():New(oReport,"Gastos Geral - Referência: "+dToc(MV_PAR01),{"ST9","STL","STJ","TQN","SZ1","CTT"},,,,,.F.,.T.,.F.,.T.)

	oSection1:SetTotalInLine(.F.)
	TRCell():New(oSection1,"D1_DOC"  	,"SD1",     , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_SERIE"   ,"SD1", 	, /*Picture*/		,           ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_FORNECE" ,"SD1", 	, /*Picture*/		,           ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_LOJA"    ,"SD1", 	, 				    ,     		,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"A2_NOME"    ,"SA2", 	, 					,     		,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"A2_CGC"     ,"SA2",     ,                   ,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_COD"  	,"SD1",     , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"B1_DESC" 	,"SB1", 	,   				,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_EMISSAO" ,"SD1", 	,    				,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_DTDIGIT" ,"SD1",     ,                   ,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"F1_ESPECIE" ,"SF1",     ,                   ,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_TES" 	,"SD1",     , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_CF" 		,"SD1",     , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_TOTAL" 	,"SD1",     , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"VLRLIQ" 	,"","Vlr.Liq"     , PesqPict('SD1',"D1_TOTAL")	,14 ,.f.		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_CONTA"   ,"SD1",     , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"CT1_DESC01" ,"CT1",     , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"CODNAT"     ,,          , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"DESCNAT"    ,,          , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_VALIRR"  ,"SD1",     , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_VALISS"  ,"SD1",     , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_VALINS"  ,"SD1",     , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_VALPIS"  ,"SD1",     , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_VALCOF"  ,"SD1",     , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_VALCSL"  ,"SD1",     , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"F1_VALICM"  ,"SF1",     , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"F1_VALIPI"  ,"SF1",     , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_ALIQIRR" ,"SD1",     , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_BASEIRR" ,"SD1",     , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_ALIQISS" ,"SD1",     , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_BASEISS" ,"SD1",     , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_BASEINS" ,"SD1",     , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_ALIQINS" ,"SD1",     , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_BASEPIS" ,"SD1",     , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_ALQPIS"  ,"SD1",     , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_BASECOF" ,"SD1",     , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_ALQCOF"  ,"SD1",     , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_ALQCSL"  ,"SD1",     , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,"D1_BASECSL" ,"SD1",     , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	
	

Return(oReport)

Static Function ReportPrint(oReport,aOrdem,cAliasZAJ)
	Local oSection1 := oReport:Section(1)
	Local cQuery    := ""
	Local cAliasTOP := GetNextAlias()
	Local dDtIni	:= MV_PAR01
	Local dDtFin	:= MV_PAR02
	Local cCodNat   := ""
	Local cDesNat   := ""

	cQuery := "SELECT SD1.D1_DOC NOTAFISCAL, SD1.D1_SERIE SERIE, SD1.D1_FORNECE CODFORN, SD1.D1_LOJA LOJAFORN, SA2.A2_CGC CNPJ, SD1.D1_LOJA LOJA, SA2.A2_NOME NOMEFOR, SF1.F1_DESPESA,		"
	cQuery += "SD1.D1_COD CODPRODUTO, SB1.B1_DESC DESCRICAO, SD1.D1_EMISSAO EMISSAONF, SD1.D1_DTDIGIT DATADIGITACAO, SD1.D1_TES, SD1.D1_CF,		 		"
	cQuery += "SD1.D1_TOTAL VLTOTAL,(SD1.D1_TOTAL - SD1.D1_VALPIS - SD1.D1_VALCOF - SD1.D1_VALINS - SD1.D1_VALIRR - SD1.D1_VALCSL - SD1.D1_VALISS + SD1.D1_DESPESA - D1_VALDESC) VLRLIQ, SD1.D1_CONTA CONTACONTABIL, CT1.CT1_DESC01 DESCRICAOCONTA, SF1.F1_VALICM ICMTOTAL, SF1.F1_VALIPI VALIPITOTAL,  	"
	cQuery += "SF1.F1_VALPIS VALPISTOTAL, SF1.F1_VALCOFI VALCOFINSTOTAL, SF1.F1_VALCSLL VALCSLLTOTAL, SF1.F1_INSS VALTOTINSS, SF1.F1_IRRF VALIRRFTOTAL, "
	cQuery += "SD1.D1_ALIQIRR, SD1.D1_BASEIRR, SD1.D1_VALIRR, SD1.D1_ALIQISS, SD1.D1_VALISS, SD1.D1_BASEISS, SF1.F1_ESPECIE, 							"
	cQuery += "SD1.D1_BASEINS, SD1.D1_ALIQINS, SD1.D1_VALINS, SD1.D1_BASEPIS, SD1.D1_ALQPIS, SD1.D1_VALPIS, SD1.D1_BASECOF, SD1.D1_ALQCOF, SD1.D1_VALCOF, "
	cQuery += "SD1.D1_ALQCSL, SD1.D1_BASECSL, SD1.D1_VALCSL   "
	cQuery += "FROM "+retSqlName("SD1") + " SD1 "
	cQuery += "INNER JOIN "+retSqlName("SF1") + " SF1 ON (SF1.D_E_L_E_T_ = ' ' AND SF1.F1_FILIAL = SD1.D1_FILIAL AND SF1.F1_DOC = SD1.D1_DOC "
	cQuery += "                 AND SD1.D1_SERIE = SF1.F1_SERIE AND SD1.D1_FORNECE = SF1.F1_FORNECE) "
	cQuery += "INNER JOIN "+retSqlName("SA2") + " SA2 ON (SA2.D_E_L_E_T_ = ' ' AND SA2.A2_COD = SD1.D1_FORNECE AND SA2.A2_LOJA = SD1.D1_LOJA) "
	cQuery += "INNER JOIN "+retSqlName("SB1") + " SB1 ON (SB1.D_E_L_E_T_ = ' ' AND SB1.B1_COD = SD1.D1_COD)  "
	cQuery += "LEFT JOIN "+retSqlName("CT1") + " CT1 ON (CT1.D_E_L_E_T_ = ' ' AND CT1.CT1_CONTA = SD1.D1_CONTA)  "
	cQuery += "WHERE SD1.D_E_L_E_T_ = ' ' AND SD1.D1_EMISSAO BETWEEN '"+dtos(dDtIni)+"' AND '"+dtos(dDtFin)+"' "
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasTop,.T.,.T.)



	oSection1:Init()

	dbSelectArea(cAliasTOP)
	dbgotop()
	do while (cAliasTOP)->(!Eof())

		oReport:IncMeter()
		If oReport:Cancel()
			Exit
		EndIf

		cCodNat := POSICIONE("SE2",6,XFILIAL("SE2")+(cAliasTOP)->CODFORN+(cAliasTOP)->LOJAFORN+(cAliasTOP)->SERIE+(cAliasTOP)->NOTAFISCAL,"E2_NATUREZ")
		cDesNat := POSICIONE("SED",1,XFILIAL("SED")+cCodNat,"ED_DESCRIC")

		oSection1:Cell("D1_DOC"):SetValue((cAliasTop)->NOTAFISCAL)
		oSection1:Cell("D1_DOC"):SetAlign("LEFT")

		oSection1:Cell("D1_SERIE"):SetValue((cAliasTop)->SERIE)
		oSection1:Cell("D1_SERIE"):SetAlign("LEFT")

		oSection1:Cell("D1_FORNECE"):SetValue((cAliasTop)->CODFORN)
		oSection1:Cell("D1_FORNECE"):SetAlign("LEFT")

		oSection1:Cell("D1_LOJA"):SetValue((cAliasTop)->LOJA)
		oSection1:Cell("D1_LOJA"):SetAlign("RIGHT")

		oSection1:Cell("A2_NOME"):SetValue((cAliasTop)->NOMEFOR)
		oSection1:Cell("A2_NOME"):SetAlign("RIGHT")

		oSection1:Cell("A2_CGC"):SetValue((cAliasTop)->CNPJ)
		oSection1:Cell("A2_CGC"):SetAlign("RIGHT")

		oSection1:Cell("D1_COD"):SetValue((cAliasTop)->CODPRODUTO)
		oSection1:Cell("D1_COD"):SetAlign("RIGHT")

		oSection1:Cell("B1_DESC"):SetValue((cAliasTop)->DESCRICAO)
		oSection1:Cell("B1_DESC"):SetAlign("LEFT")

		oSection1:Cell("D1_EMISSAO"):SetValue(stod((cAliasTop)->EMISSAONF))
		oSection1:Cell("D1_EMISSAO"):SetAlign("RIGHT")

		oSection1:Cell("D1_DTDIGIT"):SetValue(stod((cAliasTop)->DATADIGITACAO))
		oSection1:Cell("D1_DTDIGIT"):SetAlign("LEFT")

		oSection1:Cell("F1_ESPECIE"):SetValue((cAliasTop)->F1_ESPECIE)
		oSection1:Cell("F1_ESPECIE"):SetAlign("LEFT")

		oSection1:Cell("D1_TES"):SetValue((cAliasTop)->D1_TES)
		oSection1:Cell("D1_TES"):SetAlign("LEFT")

		oSection1:Cell("D1_CF"):SetValue((cAliasTop)->D1_CF)
		oSection1:Cell("D1_CF"):SetAlign("LEFT")

		oSection1:Cell("F1_VALICM"):SetValue((cAliasTop)->ICMTOTAL)
		oSection1:Cell("F1_VALICM"):SetAlign("RIGHT")

		oSection1:Cell("F1_VALIPI"):SetValue((cAliasTop)->VALIPITOTAL)
		oSection1:Cell("F1_VALIPI"):SetAlign("RIGHT")

		oSection1:Cell("D1_TOTAL"):SetValue((cAliasTop)->VLTOTAL)
		oSection1:Cell("D1_TOTAL"):SetAlign("RIGHT")
       
		oSection1:Cell("VLRLIQ"):SetValue((cAliasTop)->VLRLIQ)
		oSection1:Cell("VLRLIQ"):SetAlign("RIGHT")

		oSection1:Cell("D1_CONTA"):SetValue((cAliasTop)->CONTACONTABIL)
		oSection1:Cell("D1_CONTA"):SetAlign("LEFT")

		oSection1:Cell("CT1_DESC01"):SetValue((cAliasTop)->DESCRICAOCONTA)
		oSection1:Cell("CT1_DESC01"):SetAlign("RIGHT")

		oSection1:Cell("CODNAT"):SetValue(cCodNat)
		oSection1:Cell("CODNAT"):SetAlign("RIGHT")

		oSection1:Cell("DESCNAT"):SetValue(cDesNat)
		oSection1:Cell("DESCNAT"):SetAlign("RIGHT")

		oSection1:Cell("D1_ALIQIRR"):SetValue((cAliasTop)->D1_ALIQIRR)
		oSection1:Cell("D1_ALIQIRR"):SetAlign("RIGHT")

		oSection1:Cell("D1_BASEIRR"):SetValue((cAliasTop)->D1_BASEIRR)
		oSection1:Cell("D1_BASEIRR"):SetAlign("RIGHT")
	
		oSection1:Cell("D1_ALIQISS"):SetValue((cAliasTop)->D1_ALIQISS)
		oSection1:Cell("D1_ALIQISS"):SetAlign("RIGHT")

		oSection1:Cell("D1_VALISS"):SetValue((cAliasTop)->D1_VALISS)
		oSection1:Cell("D1_VALISS"):SetAlign("RIGHT")

		oSection1:Cell("D1_BASEISS"):SetValue((cAliasTop)->D1_BASEISS)
		oSection1:Cell("D1_BASEISS"):SetAlign("RIGHT")

		oSection1:Cell("D1_BASEINS"):SetValue((cAliasTop)->D1_BASEINS)
		oSection1:Cell("D1_BASEINS"):SetAlign("RIGHT")

		oSection1:Cell("D1_ALIQINS"):SetValue((cAliasTop)->D1_ALIQINS)
		oSection1:Cell("D1_ALIQINS"):SetAlign("RIGHT")

		oSection1:Cell("D1_VALINS"):SetValue((cAliasTop)->D1_VALINS)
		oSection1:Cell("D1_VALINS"):SetAlign("RIGHT")

		oSection1:Cell("D1_BASEPIS"):SetValue((cAliasTop)->D1_BASEPIS)
		oSection1:Cell("D1_BASEPIS"):SetAlign("RIGHT")

		oSection1:Cell("D1_ALQPIS"):SetValue((cAliasTop)->D1_ALQPIS)
		oSection1:Cell("D1_ALQPIS"):SetAlign("RIGHT")

		oSection1:Cell("D1_VALPIS"):SetValue((cAliasTop)->D1_VALPIS)
		oSection1:Cell("D1_VALPIS"):SetAlign("RIGHT")

		oSection1:Cell("D1_BASECOF"):SetValue((cAliasTop)->D1_BASECOF)
		oSection1:Cell("D1_BASECOF"):SetAlign("RIGHT")

		oSection1:Cell("D1_ALQCOF"):SetValue((cAliasTop)->D1_ALQCOF)
		oSection1:Cell("D1_ALQCOF"):SetAlign("RIGHT")

		oSection1:Cell("D1_VALCOF"):SetValue((cAliasTop)->D1_VALCOF)
		oSection1:Cell("D1_VALCOF"):SetAlign("RIGHT")

		oSection1:Cell("D1_ALQCSL"):SetValue((cAliasTop)->D1_ALQCSL)
		oSection1:Cell("D1_ALQCSL"):SetAlign("RIGHT")

		oSection1:Cell("D1_BASECSL"):SetValue((cAliasTop)->D1_BASECSL)
		oSection1:Cell("D1_BASECSL"):SetAlign("RIGHT")

		oSection1:Cell("D1_VALCSL"):SetValue((cAliasTop)->D1_VALCSL)
		oSection1:Cell("D1_VALCSL"):SetAlign("RIGHT")

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

