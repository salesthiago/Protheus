#INCLUDE "PROTHEUS.CH"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ RACOM004  ³ Autor ³Sinval Gedolin        ³ Data ³ 01/2022  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Histórico por código do bem                                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³                                                           ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Generico                                                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
user Function RACOM004()
Local oReport

AjustaSX1("RACOM04")
oReport:= ReportDef()
oReport:PrintDialog()
                                               
Return

Static Function ReportDef()
Local aOrdem   	:= {} 
Local cTitle   	:= "Histórico de Bem (NF, PC, SC) - Período: "
Local oReport 
Local oSection1
Local cAliasZAJ := "SD1"

Pergunte("RACOM04",.T.)

oReport:= TReport():New("RACOM004",cTitle+" "+dtoc(MV_PAR01)+" à "+dToc(MV_PAR02),"RACOM004", {|oReport| ReportPrint(oReport,aOrdem,cAliasZAJ)},"Histórico do Bem")
oReport:SetTotalInLine(.F.)
oReport:SetLandscape() 
oReport:oPage:setPaperSize(10)

//oReport:ShowHeader()

oSection1:=TRSection():New(oReport,"Histórico de Bem (NF, PC, SC)",{"SC7","SD1","SC1"},{})
//oSection1:=TRSection():New(oReport,"Gastos Geral - Referência: "+dToc(MV_PAR01),{"ST9","STL","STJ","TQN","SZ1","CTT"},,,,,.F.,.T.,.F.,.T.)

oSection1:SetTotalInLine(.F.)
//Filial      	Descricao   	Prc Unitario	Razao Social	Desc.CC     	DT Emissao  	Num OS	Placa	Vlr Mês	Gasto Total	Cotação 1	Cotação 2	Contação 3
TRCell():New(oSection1,"TIPO"  		,"   ", "Tipo"	 		, /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"FILIAL"  	,"   ", "Fil."    		, /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"PRODUTO"    ,"   ", "Produto" 		, /*Picture*/		,           ,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"DESCPROD"   ,"   ", "Decrição"		, /*Picture*/		,           ,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"QTDE"       ,"   ", "Quantidade"	, "@E 999,999.9999"	,     		,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"VLRUNIT"    ,"   ", "Vlr Unit." 	, "@E 9999,999.999"	,     		,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"VLRTOTAL"   ,"   ", "Vlr Total" 	, "@E 9999,999.99"	,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"CONTADOR"   ,"   ", "Contrador" 	, "@E 9999,999"		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"CFOP"    	,"   ", "CFOP"			, /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"CC"  		,"   ", "Cod. C.C."		, /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"DESC_CC" 	,"   ", "Desc. C.C."	, /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"TJ_ORDEM"   ,"STJ", /*Titulo*/		, /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"TJ_CODBEM"  ,"STJ", /*Titulo*/		, /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"NOME_BEM"   ,"   ", "Nome do Bem"	, /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"FAMILIA"	,"   ", "Família"	 	, "@!"				,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"PEDIDO"		,"   ", "Num.Ped." 		,                   ,        	,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"ITEMPC"		,"   ", "Iem PC"  		, "@!"				,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"NUMSC"		,"   ", "Num SC"		, "@!"				,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"ITEMSC"		,"   ", "Item SC"		, "@!"				,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"EMISSAO_SC" ,"   ", "Emissao SC"	, 					,           ,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"EMISSAO_PED","   ", "Emissao PEd"	, 					,           ,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"FORNECE"	,"   ", "Fornecedor"	,                 	, 60        ,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"NUMNF"		,"   ", "Número NF"		,           		,        	,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"SERIE"		,"   ", "Série NF"		,           		,        	,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"EMISSAONF"	,"   ", "Emissão NF"	,           		,        	,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"DTADIGIT"	,"   ", "Dta Dig NF"	,           		,        	,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"BM_DESC"	,"   ", "Desc Grupo"	,           		,        	,/*lPixel*/,/*{|| code-block de impressao }*/)

//oBreak1 := TRBreak():New( oSection1, oSection1:Cell("C7_FILIAL"), "Sub.Total",.F. )
//TRFunction():New(oSection1:Cell("C7_TOTAL"),"C7_TOTALF"	,"SUM", oBreak1, , , ,.F.,.F.)

//oBreak2 := TRBreak():New( oSection1, oSection1:Cell("QBC"), "Total Geral",.F. )
//TRFunction():New(oSection1:Cell("C7_TOTAL"),"C7_TOTALT"	,"SUM", oBreak2, , , ,.F.,.F.)

Return(oReport)

Static Function ReportPrint(oReport,aOrdem,cAliasZAJ)
	Local oSection1 := oReport:Section(1)
	Local cQuery    := ""
	Local cAliasTOP := GetNextAlias()
	Local dDtIni	:= MV_PAR01
	Local dDtFin	:= MV_PAR02
	Local cBemDe 	:= MV_PAR03
	Local cBemAte   := MV_PAR04

	ST9->(DbSetOrder(14))
	if ST9->(DbSeek(cBemDe))
		cBemDe := ST9->T9_CODBEM
	endif

	ST9->(DbSetOrder(14))
	if ST9->(DbSeek(cBemAte))
		cBemAte := ST9->T9_CODBEM
	endif

	cQuery := "SELECT 'NF' AS TIPO, SD1.D1_FILIAL FILIAL, SD1.D1_COD PRODUTO, SB1.B1_DESC DESCPROD, SD1.D1_QUANT QTDE, SD1.D1_VUNIT VLRUNIT, SD1.D1_TOTAL VLRTOTAL, SD1.D1_CF CFOP, SD1.D1_CC CC, CTT.CTT_DESC01 DESC_CC, "
	cQuery += "SC1.C1_OP OS, STJ.TJ_ORDEM, STJ.TJ_CODBEM, ST9.T9_NOME NOME_BEM, ST9.T9_CODFAMI MOD_FAMILIA, ST6.T6_NOME NOME_FAMILIA, SD1.D1_PEDIDO PEDIDO, SD1.D1_ITEMPC ITEMPC, SC7.C7_NUMSC NUMSC, SC7.C7_ITEMSC ITEMSC,  "
	cQuery += "SC7.C7_EMISSAO EMISSAO_PED, SC1.C1_EMISSAO EMISSAO_SC, STJ.TJ_POSCONT CONTADOR, "
	cQuery += "SD1.D1_FORNECE FORNEC, SD1.D1_LOJA LOJA, SA2.A2_NOME NOME_FOR, SD1.D1_DOC NUMNF, SD1.D1_SERIE SERIE, SD1.D1_EMISSAO EMISSAONF, SD1.D1_DTDIGIT DTADIGIT, SD1.D1_GRUPO GRUPOPROD, SBM.BM_DESC "
	cQuery += "FROM "+retSqlName("SD1") + " SD1  "
	cQuery += "INNER JOIN "+retSqlName("SB1") + " SB1 ON (SB1.D_E_L_E_T_ = ' ' AND SB1.B1_COD = SD1.D1_COD) "
	cQuery += "INNER JOIN "+retSqlName("SA2") + " SA2 ON (SA2.D_E_L_E_T_ = ' ' AND SA2.A2_COD = SD1.D1_FORNECE AND SA2.A2_LOJA = SD1.D1_LOJA) "
	cQuery += "INNER JOIN "+retSqlName("SBM") + " SBM ON (SBM.D_E_L_E_T_ = ' ' AND SBM.BM_GRUPO = SD1.D1_GRUPO) "
	cQuery += "INNER JOIN "+retSqlName("SC7") + " SC7 ON (SC7.D_E_L_E_T_ = ' ' AND SC7.C7_FILIAL = SD1.D1_FILIAL AND SC7.C7_NUM = SD1.D1_PEDIDO AND SC7.C7_ITEM = SD1.D1_ITEMPC) "
	cQuery += "INNER JOIN "+retSqlName("SC1") + " SC1 ON (SC1.D_E_L_E_T_ = ' ' AND SC1.C1_FILIAL = SD1.D1_FILIAL AND SC1.C1_NUM = SC7.C7_NUMSC AND SC1.C1_ITEM = SC7.C7_ITEMSC) "
	cQuery += "LEFT JOIN "+retSqlName("CTT") + " CTT ON (CTT.D_E_L_E_T_ = ' ' AND CTT.CTT_CUSTO = SD1.D1_CC) "
	cQuery += "INNER JOIN "+retSqlname("STJ") + " STJ ON (STJ.D_E_L_E_T_ = ' ' AND STJ.TJ_ORDEM = SUBSTRING(SC1.C1_OP,1,6) AND STJ.TJ_FILIAL = SC1.C1_FILIAL) "
	cQuery += "INNER JOIN "+retSqlName("ST9") + " ST9 ON (ST9.D_E_L_E_T_ = ' ' AND ST9.T9_CODBEM = STJ.TJ_CODBEM AND ST9.T9_FILIAL = STJ.TJ_FILIAL AND ST9.T9_CATBEM IN ('1','4')) "
	cQuery += "INNER JOIN "+retSqlName("ST6") + " ST6 ON (ST6.D_E_L_E_T_ = ' ' AND ST6.T6_CODFAMI = ST9.T9_CODFAMI ) "
	cQuery += "WHERE SD1.D_E_L_E_T_ = ' ' AND SD1.D1_EMISSAO BETWEEN '"+dtos(dDtIni)+"' AND '"+dtos(dDtFin)+"' AND SC1.C1_OP <> ' ' AND STJ.TJ_CODBEM BETWEEN '"+cBemDe+"' AND '"+cBemAte+"' "
	cQuery += " UNION "
	cQuery += "SELECT 'PC' AS TIPO, SC7.C7_FILIAL FILIAL, SC7.C7_PRODUTO PRODUTO, SB1.B1_DESC DESCPROD, SC7.C7_QUANT QTDE, SC7.C7_PRECO VLRUNIT, SC7.C7_TOTAL VLRTOTAL, '    ' AS CFOP, SC7.C7_CC CC, CTT.CTT_DESC01 DESC_CC, "
	cQuery += "SC1.C1_OP OS, STJ.TJ_ORDEM, STJ.TJ_CODBEM, ST9.T9_NOME NOME_BEM, ST9.T9_CODFAMI MOD_FAMILIA, ST6.T6_NOME NOME_FAMILIA, SC7.C7_NUM PEDIDO, SC7.C7_ITEM ITEMPC, SC7.C7_NUMSC NUMSC, SC7.C7_ITEMSC ITEMSC,  "
	cQuery += "SC7.C7_EMISSAO EMISSAO_PED, SC1.C1_EMISSAO EMISSAO_SC,  STJ.TJ_POSCONT CONTADOR, "
	cQuery += "SC7.C7_FORNECE FORNEC, SC7.C7_LOJA LOJA, SA2.A2_NOME NOME_FOR, '         ' AS NUMNF, '   ' AS  SERIE, '        ' AS EMISSAONF, '         ' AS DTADIGIT, SB1.B1_GRUPO GRUPOPROD, SBM.BM_DESC "
	cQuery += "FROM "+retSqlName("SC7") + " SC7 "
	cQuery += "INNER JOIN "+retSqlName("SB1") + " SB1 ON (SB1.D_E_L_E_T_ = ' ' AND SB1.B1_COD = SC7.C7_PRODUTO) "
	cQuery += "INNER JOIN "+retSqlName("SA2") + " SA2 ON (SA2.D_E_L_E_T_ = ' ' AND SA2.A2_COD = SC7.C7_FORNECE AND SA2.A2_LOJA = SC7.C7_LOJA) "
	cQuery += "INNER JOIN "+retSqlName("SBM") + " SBM ON (SBM.D_E_L_E_T_ = ' ' AND SBM.BM_GRUPO = SB1.B1_GRUPO) "
	cQuery += "INNER JOIN "+retSqlName("SC1") + " SC1 ON (SC1.D_E_L_E_T_ = ' ' AND SC1.C1_FILIAL = SC7.C7_FILIAL AND SC1.C1_NUM = SC7.C7_NUMSC AND SC1.C1_ITEM = SC7.C7_ITEMSC AND SC1.C1_OP <> ' ') "
	cQuery += "LEFT JOIN "+retSqlName("CTT") + " CTT ON (CTT.D_E_L_E_T_ = ' ' AND CTT.CTT_CUSTO = SC7.C7_CC) "
	cQuery += "INNER JOIN "+retSqlName("STJ") + " STJ ON (STJ.D_E_L_E_T_ = ' ' AND STJ.TJ_ORDEM = SUBSTRING(SC1.C1_OP,1,6) AND STJ.TJ_FILIAL = SC1.C1_FILIAL) "
	cQuery += "INNER JOIN "+retSqlName("ST9") + " ST9 ON (ST9.D_E_L_E_T_ = ' ' AND ST9.T9_CODBEM = STJ.TJ_CODBEM AND ST9.T9_FILIAL = STJ.TJ_FILIAL AND ST9.T9_CATBEM IN ('1','4') ) "
	cQuery += "INNER JOIN "+retSqlName("ST6") + " ST6 ON (ST6.D_E_L_E_T_ = ' ' AND ST6.T6_CODFAMI = ST9.T9_CODFAMI ) "
	cQuery += "WHERE SC7.D_E_L_E_T_ = ' ' AND SC7.C7_EMISSAO BETWEEN '"+dtos(dDtIni)+"' AND '"+dtos(dDtFin)+"' AND SC7.C7_QUJE = 0 AND STJ.TJ_CODBEM BETWEEN '"+cBemDe+"' AND '"+cBemAte+"' "
	cQuery += "UNION "
	cQuery += "SELECT 'SC' AS TIPO, SC1.C1_FILIAL FILIAL, SC1.C1_PRODUTO PRODUTO, SB1.B1_DESC DESCPROD, SC1.C1_QUANT QTDE, 0 AS VLRUNIT, 0 AS VLRTOTAL, '    ' AS CFOP, SC1.C1_CC CC, CTT.CTT_DESC01 DESC_CC,  "
	cQuery += "SC1.C1_OP OS, STJ.TJ_ORDEM, STJ.TJ_CODBEM, ST9.T9_NOME NOME_BEM, ST9.T9_CODFAMI MOD_FAMILIA, ST6.T6_NOME NOME_FAMILIA, '      ' AS PEDIDO, '   ' AS ITEMPC, SC1.C1_NUM NUMSC, SC1.C1_ITEM ITEMSC,  "
	cQuery += "'      ' AS EMISSAO_PED, SC1.C1_EMISSAO EMISSAO_SC,  STJ.TJ_POSCONT CONTADOR, "
	cQuery += "'      ' AS FORNEC, '    ' AS LOJA, '          ' AS NOME_FOR, '         ' AS NUMNF, '   ' AS  SERIE, '        ' AS EMISSAONF, '         ' AS DTADIGIT, SB1.B1_GRUPO GRUPOPROD, SBM.BM_DESC "
	cQuery += "FROM "+retSqlName("SC1") + " SC1 "
	cQuery += "INNER JOIN "+retSqlName("SB1") + " SB1 ON (SB1.D_E_L_E_T_ = ' ' AND SB1.B1_COD = SC1.C1_PRODUTO) "
	cQuery += "INNER JOIN "+retSqlName("SBM") + " SBM ON (SBM.D_E_L_E_T_ = ' ' AND SBM.BM_GRUPO = SB1.B1_GRUPO) "
	cQuery += "LEFT JOIN "+retSqlName("CTT") + " CTT ON (CTT.D_E_L_E_T_ = ' ' AND CTT.CTT_CUSTO = SC1.C1_CC) "
	cQuery += "INNER JOIN "+retSqlName("STJ") + " STJ ON (STJ.D_E_L_E_T_ = ' ' AND STJ.TJ_ORDEM = SUBSTRING(SC1.C1_OP,1,6) AND STJ.TJ_FILIAL = SC1.C1_FILIAL) "
	cQuery += "INNER JOIN "+retSqlName("ST9") + " ST9 ON (ST9.D_E_L_E_T_ = ' ' AND ST9.T9_CODBEM = STJ.TJ_CODBEM AND ST9.T9_FILIAL = STJ.TJ_FILIAL AND ST9.T9_CATBEM IN ('1','4') ) "
	cQuery += "INNER JOIN "+retSqlName("ST6") + " ST6 ON (ST6.D_E_L_E_T_ = ' ' AND ST6.T6_CODFAMI = ST9.T9_CODFAMI ) "
	cQuery += "WHERE SC1.D_E_L_E_T_ = ' ' AND SC1.C1_EMISSAO BETWEEN '"+dtos(dDtIni)+"' AND '"+dtos(dDtFin)+"' AND SC1.C1_PEDIDO = ' ' AND SC1.C1_OP <> ' ' AND STJ.TJ_CODBEM BETWEEN '"+cBemDe+"' AND '"+cBemAte+"' "
	cQuery += "ORDER BY TIPO, EMISSAONF, EMISSAO_PED, EMISSAO_SC "
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasTop,.T.,.T.)

	oSection1:Init()

	dbSelectArea(cAliasTOP)
	dbgotop()
	do while (cAliasTOP)->(!Eof())

		oReport:IncMeter()
		If oReport:Cancel()
			Exit
		EndIf

		oSection1:Cell("TIPO"):SetValue((cAliasTop)->TIPO)
		oSection1:Cell("TIPO"):SetAlign("LEFT")
		
		oSection1:Cell("FILIAL"):SetValue((cAliasTop)->FILIAL)
		oSection1:Cell("FILIAL"):SetAlign("LEFT")

		oSection1:Cell("PRODUTO"):SetValue((cAliasTop)->PRODUTO)
		oSection1:Cell("PRODUTO"):SetAlign("LEFT")

		oSection1:Cell("DESCPROD"):SetValue((cAliasTop)->DESCPROD)
		oSection1:Cell("DESCPROD"):SetAlign("LEFT")

		oSection1:Cell("QTDE"):SetValue((cAliasTop)->QTDE)
		oSection1:Cell("QTDE"):SetAlign("RIGHT")
		
		oSection1:Cell("VLRUNIT"):SetValue((cAliasTop)->VLRUNIT)
		oSection1:Cell("VLRUNIT"):SetAlign("RIGHT")

		oSection1:Cell("VLRTOTAL"):SetValue((cAliasTop)->VLRTOTAL)
		oSection1:Cell("VLRTOTAL"):SetAlign("RIGHT")

		oSection1:Cell("CONTADOR"):SetValue((cAliasTop)->CONTADOR)
		oSection1:Cell("CONTADOR"):SetAlign("RIGHT")

		oSection1:Cell("CFOP"):SetValue((cAliasTop)->CFOP)
		oSection1:Cell("CFOP"):SetAlign("RIGHT")

		oSection1:Cell("CC"):SetValue((cAliasTop)->CC)
		oSection1:Cell("CC"):SetAlign("LEFT")

		oSection1:Cell("DESC_CC"):SetValue((cAliasTop)->DESC_CC)
		oSection1:Cell("DESC_CC"):SetAlign("LEFT")

		oSection1:Cell("TJ_ORDEM"):SetValue((cAliasTop)->TJ_ORDEM)
		oSection1:Cell("TJ_ORDEM"):SetAlign("LEFT")
		
		oSection1:Cell("TJ_CODBEM"):SetValue((cAliasTop)->TJ_CODBEM)
		oSection1:Cell("TJ_CODBEM"):SetAlign("LEFT")

		oSection1:Cell("NOME_BEM"):SetValue((cAliasTop)->NOME_BEM)
		oSection1:Cell("NOME_BEM"):SetAlign("LEFT")

		oSection1:Cell("FAMILIA"):SetValue((cAliasTop)->NOME_FAMILIA)
		oSection1:Cell("FAMILIA"):SetAlign("LEFT")

		oSection1:Cell("PEDIDO"):SetValue((cAliasTop)->PEDIDO)
		oSection1:Cell("PEDIDO"):SetAlign("LEFT")

		oSection1:Cell("ITEMPC"):SetValue((cAliasTop)->ITEMPC)
		oSection1:Cell("ITEMPC"):SetAlign("LEFT")

		oSection1:Cell("NUMSC"):SetValue((cAliasTop)->NUMSC)
		oSection1:Cell("NUMSC"):SetAlign("LEFT")

		oSection1:Cell("ITEMSC"):SetValue((cAliasTop)->ITEMSC)
		oSection1:Cell("ITEMSC"):SetAlign("LEFT")

		oSection1:Cell("EMISSAO_SC"):SetValue(dtoc(stod((cAliasTop)->EMISSAO_SC)))
		oSection1:Cell("EMISSAO_SC"):SetAlign("RIGHT")

		oSection1:Cell("EMISSAO_PED"):SetValue(dtoc(stod((cAliasTop)->EMISSAO_PED)))
		oSection1:Cell("EMISSAO_PED"):SetAlign("RIGHT")

		oSection1:Cell("FORNECE"):SetValue((cAliasTop)->(FORNEC+"-"+LOJA+"-"+NOME_FOR))
		oSection1:Cell("FORNECE"):SetAlign("LEFT")

		oSection1:Cell("NUMNF"):SetValue((cAliasTop)->NUMNF)
		oSection1:Cell("NUMNF"):SetAlign("RIGHT")

		oSection1:Cell("SERIE"):SetValue((cAliasTop)->SERIE)
		oSection1:Cell("SERIE"):SetAlign("RIGHT")

		oSection1:Cell("EMISSAONF"):SetValue(dtoc(stod((cAliasTop)->EMISSAONF)))
		oSection1:Cell("EMISSAONF"):SetAlign("RIGHT")

		oSection1:Cell("DTADIGIT"):SetValue(dtoc(stod((cAliasTop)->DTADIGIT)))
		oSection1:Cell("DTADIGIT"):SetAlign("RIGHT")

		oSection1:Cell("BM_DESC"):SetValue((cAliasTop)->BM_DESC)
		oSection1:Cell("BM_DESC"):SetAlign("LEFT")

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
aAdd(aRegs,{cPerg,"03","Bem de ?"   ,"","","mv_ch3","C", 16,0,0,"G","","mv_par03","","","","","","","","","","","","","","","","","","","","","","","","","",""})
aAdd(aRegs,{cPerg,"04","Bem Até?"   ,"","","mv_ch4","C", 16,0,0,"G","","mv_par04","","","","","","","","","","","","","","","","","","","","","","","","","",""})


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

/*
SELECT 'NF' AS TIPO, SD1.D1_FILIAL FILIAL, SD1.D1_COD PRODUTO, SB1.B1_DESC DESCPROD, SD1.D1_QUANT QTDE, SD1.D1_VUNIT VLRUNIT, SD1.D1_TOTAL VLRTOTAL, SD1.D1_CF CFOP, SD1.D1_CC CC, CTT.CTT_DESC01 DESC_CC, 
SC1.C1_OP OS, STJ.TJ_ORDEM, STJ.TJ_CODBEM, ST9.T9_NOME NOME_BEM, ST9.T9_MODELO MOD_VEICULO, SD1.D1_PEDIDO PEDIDO, SD1.D1_ITEMPC ITEMPC, SC7.C7_NUMSC NUMSC, SC7.C7_ITEMSC ITEMSC,  
SC7.C7_EMISSAO EMISSAO_PED, SC1.C1_EMISSAO EMISSAO_SC, 
SD1.D1_FORNECE FORNEC, SD1.D1_LOJA LOJA, SA2.A2_NOME NOME_FOR, SD1.D1_DOC NUMNF, SD1.D1_SERIE SERIE, SD1.D1_EMISSAO EMISSAONF, SD1.D1_DTDIGIT DTADIGIT, SD1.D1_GRUPO GRUPOPROD, SBM.BM_DESC 
FROM SD1010 SD1  
INNER JOIN SB1010 SB1 ON (SB1.D_E_L_E_T_ = ' ' AND SB1.B1_COD = SD1.D1_COD) 
INNER JOIN SA2010 SA2 ON (SA2.D_E_L_E_T_ = ' ' AND SA2.A2_COD = SD1.D1_FORNECE AND SA2.A2_LOJA = SD1.D1_LOJA) 
INNER JOIN SBM010 SBM ON (SBM.D_E_L_E_T_ = ' ' AND SBM.BM_GRUPO = SD1.D1_GRUPO) 
INNER JOIN SC7010 SC7 ON (SC7.D_E_L_E_T_ = ' ' AND SC7.C7_FILIAL = SD1.D1_FILIAL AND SC7.C7_NUM = SD1.D1_PEDIDO AND SC7.C7_ITEM = SD1.D1_ITEMPC) 
INNER JOIN SC1010 SC1 ON (SC1.D_E_L_E_T_ = ' ' AND SC1.C1_FILIAL = SD1.D1_FILIAL AND SC1.C1_NUM = SC7.C7_NUMSC AND SC1.C1_ITEM = SC7.C7_ITEMSC) 
LEFT JOIN CTT010 CTT ON (CTT.D_E_L_E_T_ = ' ' AND CTT.CTT_CUSTO = SD1.D1_CC) 
INNER JOIN STJ010 STJ ON (STJ.D_E_L_E_T_ = ' ' AND STJ.TJ_ORDEM = SUBSTRING(SC1.C1_OP,1,6) AND STJ.TJ_FILIAL = SC1.C1_FILIAL) 
INNER JOIN ST9010 ST9 ON (ST9.D_E_L_E_T_ = ' ' AND ST9.T9_CODBEM = STJ.TJ_CODBEM AND ST9.T9_FILIAL = STJ.TJ_FILIAL) 
WHERE SD1.D_E_L_E_T_ = ' ' AND SD1.D1_EMISSAO BETWEEN '20240501' AND '20240723' AND SC1.C1_OP <> ' ' AND STJ.TJ_CODBEM BETWEEN 'PRM9028' AND 'PRM9028' 
UNION 
SELECT 'PC' AS TIPO, SC7.C7_FILIAL FILIAL, SC7.C7_PRODUTO PRODUTO, SB1.B1_DESC DESCPROD, SC7.C7_QUANT QTDE, SC7.C7_PRECO VLRUNIT, SC7.C7_TOTAL VLRTOTAL, '    ' AS CFOP, SC7.C7_CC CC, CTT.CTT_DESC01 DESC_CC, 
SC1.C1_OP OS, STJ.TJ_ORDEM, STJ.TJ_CODBEM, ST9.T9_NOME NOME_BEM, ST9.T9_MODELO MOD_VEICULO, SC7.C7_NUM PEDIDO, SC7.C7_ITEM ITEMPC, SC7.C7_NUMSC NUMSC, SC7.C7_ITEMSC ITEMSC,  
SC7.C7_EMISSAO EMISSAO_PED, SC1.C1_EMISSAO EMISSAO_SC, 
SC7.C7_FORNECE FORNEC, SC7.C7_LOJA LOJA, SA2.A2_NOME NOME_FOR, '         ' AS NUMNF, '   ' AS  SERIE, '        ' AS EMISSAONF, '         ' AS DTADIGIT, SB1.B1_GRUPO GRUPOPROD, SBM.BM_DESC 
FROM SC7010 SC7 
INNER JOIN SB1010 SB1 ON (SB1.D_E_L_E_T_ = ' ' AND SB1.B1_COD = SC7.C7_PRODUTO) 
INNER JOIN SA2010 SA2 ON (SA2.D_E_L_E_T_ = ' ' AND SA2.A2_COD = SC7.C7_FORNECE AND SA2.A2_LOJA = SC7.C7_LOJA) 
INNER JOIN SBM010 SBM ON (SBM.D_E_L_E_T_ = ' ' AND SBM.BM_GRUPO = SB1.B1_GRUPO) 
INNER JOIN SC1010 SC1 ON (SC1.D_E_L_E_T_ = ' ' AND SC1.C1_FILIAL = SC7.C7_FILIAL AND SC1.C1_NUM = SC7.C7_NUMSC AND SC1.C1_ITEM = SC7.C7_ITEMSC AND SC1.C1_OP <> ' ') 
LEFT JOIN CTT010 CTT ON (CTT.D_E_L_E_T_ = ' ' AND CTT.CTT_CUSTO = SC7.C7_CC) 
INNER JOIN STJ010 STJ ON (STJ.D_E_L_E_T_ = ' ' AND STJ.TJ_ORDEM = SUBSTRING(SC1.C1_OP,1,6) AND STJ.TJ_FILIAL = SC1.C1_FILIAL) 
INNER JOIN ST9010 ST9 ON (ST9.D_E_L_E_T_ = ' ' AND ST9.T9_CODBEM = STJ.TJ_CODBEM AND ST9.T9_FILIAL = STJ.TJ_FILIAL ) 
WHERE SC7.D_E_L_E_T_ = ' ' AND SC7.C7_EMISSAO BETWEEN '20240501' AND '20240723' AND SC7.C7_QUJE = 0 AND STJ.TJ_CODBEM BETWEEN 'PRM9028' AND 'PRM9028' 
UNION 
SELECT 'SC' AS TIPO, SC1.C1_FILIAL FILIAL, SC1.C1_PRODUTO PRODUTO, SB1.B1_DESC DESCPROD, SC1.C1_QUANT QTDE, 0 AS VLRUNIT, 0 AS VLRTOTAL, '    ' AS CFOP, SC1.C1_CC CC, CTT.CTT_DESC01 DESC_CC,  
SC1.C1_OP OS, STJ.TJ_ORDEM, STJ.TJ_CODBEM, ST9.T9_NOME NOME_BEM, ST9.T9_MODELO MOD_VEICULO, '      ' AS PEDIDO, '   ' AS ITEMPC, SC1.C1_NUM NUMSC, SC1.C1_ITEM ITEMSC,  
'      ' AS EMISSAO_PED, SC1.C1_EMISSAO EMISSAO_SC, 
'      ' AS FORNEC, '    ' AS LOJA, '          ' AS NOME_FOR, '         ' AS NUMNF, '   ' AS  SERIE, '        ' AS EMISSAONF, '         ' AS DTADIGIT, SB1.B1_GRUPO GRUPOPROD, SBM.BM_DESC 
FROM SC1010 SC1 
INNER JOIN SB1010 SB1 ON (SB1.D_E_L_E_T_ = ' ' AND SB1.B1_COD = SC1.C1_PRODUTO) 
INNER JOIN SBM010 SBM ON (SBM.D_E_L_E_T_ = ' ' AND SBM.BM_GRUPO = SB1.B1_GRUPO) 
LEFT JOIN CTT010 CTT ON (CTT.D_E_L_E_T_ = ' ' AND CTT.CTT_CUSTO = SC1.C1_CC) 
INNER JOIN STJ010 STJ ON (STJ.D_E_L_E_T_ = ' ' AND STJ.TJ_ORDEM = SUBSTRING(SC1.C1_OP,1,6) AND STJ.TJ_FILIAL = SC1.C1_FILIAL) 
INNER JOIN ST9010 ST9 ON (ST9.D_E_L_E_T_ = ' ' AND ST9.T9_CODBEM = STJ.TJ_CODBEM AND ST9.T9_FILIAL = STJ.TJ_FILIAL ) 
WHERE SC1.D_E_L_E_T_ = ' ' AND SC1.C1_EMISSAO BETWEEN '20240501' AND '20240723' AND SC1.C1_PEDIDO = ' ' AND SC1.C1_OP <> ' ' AND STJ.TJ_CODBEM BETWEEN 'PRM9028' AND 'PRM9028' 
ORDER BY TIPO, EMISSAONF, EMISSAO_PED, EMISSAO_SC 
*/
