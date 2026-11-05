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
user Function RACOM005()
Local oReport

AjustaSX1("RACOM05")
oReport:= ReportDef()
oReport:PrintDialog()
                                               
Return

Static Function ReportDef()
Local aOrdem   	:= {} 
Local cTitle   	:= "Histórico de Aprovação de Pedidos - Período: "
Local oReport 
Local oSection1
Local cAliasZAJ := "SD1"

Pergunte("RACOM05",.T.)

oReport:= TReport():New("RACOM005",cTitle+" "+dtoc(MV_PAR01)+" à "+dToc(MV_PAR02),"RACOM004", {|oReport| ReportPrint(oReport,aOrdem,cAliasZAJ)},"Histórico de Aprovação de Pedidos")
oReport:SetTotalInLine(.F.)
oReport:SetLandscape() 
oReport:oPage:setPaperSize(10)

//oReport:ShowHeader()

oSection1:=TRSection():New(oReport,"Histórico de Aprovação",{"SC7","SCR"},{})
//oSection1:=TRSection():New(oReport,"Gastos Geral - Referência: "+dToc(MV_PAR01),{"ST9","STL","STJ","TQN","SZ1","CTT"},,,,,.F.,.T.,.F.,.T.)

oSection1:SetTotalInLine(.F.)
TRCell():New(oSection1,"FILIAL"  	,"   ", "Filial"    	, /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"NUMPED"     ,"   ", "Num.Pedido" 	, /*Picture*/		,           ,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"USRINC"   	,"   ", "Usr Inclusão"	, /*Picture*/		,           ,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"NOMEINC"    ,"   ", "Nome Inclusão"	, "@!"				,     		,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"EMISSAO"    ,"   ", "Dt.Emissão" 	, 					,     		,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"VLRTOTAL"   ,"   ", "Vlr Total" 	, "@E 99,999,999.99",/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"USRAPROV"   ,"   ", "Usr Aprov." 	, "@!"				,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"NOMEAPROV"  ,"   ", "Nome Aprova."	, "@!" 				,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"VLRLIB"  	,"   ", "Vlr Liberado"	, "@E 99,999,999.99",/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"DTALIB" 	,"   ", "Data Liberação", /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)

Return(oReport)

Static Function ReportPrint(oReport,aOrdem,cAliasZAJ)
	Local oSection1 := oReport:Section(1)
	Local cQuery    := ""
	Local cAliasTOP := GetNextAlias()
	Local dDtIni	:= MV_PAR01
	Local dDtFin	:= MV_PAR02
	//Local cAprovDe 	:= MV_PAR03
	//Local cAprovAte := MV_PAR04

	cQuery := "SELECT SCR.CR_FILIAL, SCR.CR_NUM, SC7.C7_EMISSAO, SC7.C7_USER USRINCLUIU, SCR.CR_TOTAL, SCR.CR_LIBAPRO USR_APROV, "
	cQuery += "SAK.AK_NOME NOMEAPROV, SCR.CR_VALLIB VLRLIBERADO, SCR.CR_DATALIB "
	cQuery += "FROM "+retSqlName("SCR") + " SCR "
	cQuery += "INNER JOIN "+retSqlName("SAK") + " SAK ON (SAK.D_E_L_E_T_ = ' ' AND SAK.AK_COD = SCR.CR_LIBAPRO) "
	cQuery += "INNER JOIN "+retSqlname("SC7") + " SC7 ON (SC7.D_E_L_E_T_ = ' ' AND SC7.C7_NUM = SCR.CR_NUM ) "
	cQuery += "WHERE  SCR.D_E_L_E_T_ = ' ' AND SCR.CR_LIBAPRO <> '      ' "
	cQuery += "AND SCR.CR_EMISSAO BETWEEN '"+dtos(dDtIni)+"' AND '"+dtos(dDtFin)+"' "
	//cQuery += "AND SCR.CR_LIBAPRO BETWEEN '"+cAprovDe+"' AND '"+cAprovAte+"' "
	cQuery += "ORDER BY SCR.CR_LIBAPRO, SCR.CR_EMISSAO "
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasTop,.T.,.T.)

	oSection1:Init()

	dbSelectArea(cAliasTOP)
	dbgotop()
	do while (cAliasTOP)->(!Eof())

		oReport:IncMeter()
		If oReport:Cancel()
			Exit
		EndIf

		oSection1:Cell("FILIAL"):SetValue((cAliasTop)->CR_FILIAL)
		oSection1:Cell("FILIAL"):SetAlign("LEFT")

		oSection1:Cell("NUMPED"):SetValue((cAliasTop)->CR_NUM)
		oSection1:Cell("NUMPED"):SetAlign("LEFT")

		oSection1:Cell("USRINC"):SetValue((cAliasTop)->USRINCLUIU)
		oSection1:Cell("USRINC"):SetAlign("LEFT")

		oSection1:Cell("NOMEINC"):SetValue(UsrRetName((cAliasTop)->USRINCLUIU))
		oSection1:Cell("NOMEINC"):SetAlign("RIGHT")
		
		oSection1:Cell("EMISSAO"):SetValue(stod((cAliasTop)->C7_EMISSAO))
		oSection1:Cell("EMISSAO"):SetAlign("RIGHT")

		oSection1:Cell("VLRTOTAL"):SetValue((cAliasTop)->CR_TOTAL)
		oSection1:Cell("VLRTOTAL"):SetAlign("RIGHT")

		oSection1:Cell("USRAPROV"):SetValue((cAliasTop)->USR_APROV)
		oSection1:Cell("USRAPROV"):SetAlign("RIGHT")

		oSection1:Cell("NOMEAPROV"):SetValue((cAliasTop)->NOMEAPROV)
		oSection1:Cell("NOMEAPROV"):SetAlign("LEFT")

		oSection1:Cell("VLRLIB"):SetValue((cAliasTop)->VLRLIBERADO)
		oSection1:Cell("VLRLIB"):SetAlign("LEFT")

		oSection1:Cell("DTALIB"):SetValue(stod((cAliasTop)->CR_DATALIB))
		oSection1:Cell("DTALIB"):SetAlign("LEFT")
		
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
//aAdd(aRegs,{cPerg,"03","Aprov de ?"   ,"","","mv_ch3","C", 16,0,0,"G","","mv_par03","","","","","","","","","","","","","","","","","","","","","","","","","",""})
//aAdd(aRegs,{cPerg,"04","Aprov Até?"   ,"","","mv_ch4","C", 16,0,0,"G","","mv_par04","","","","","","","","","","","","","","","","","","","","","","","","","",""})

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
