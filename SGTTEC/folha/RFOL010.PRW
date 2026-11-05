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
user Function RACOM010()
Local oReport

AjustaSX1("RACOM10")
oReport:= ReportDef()
oReport:PrintDialog()
                                               
Return

Static Function ReportDef()
Local aOrdem   	:= {} 
Local cTitle   	:= "Lancçamentos Acumulados Folha"
Local oReport 
Local oSection1
Local cAliasZAJ := "SRD"

Pergunte("RACOM10",.T.)

oReport:= TReport():New("RACOM010",cTitle+" "+dtoc(MV_PAR01)+" à "+dToc(MV_PAR02),"RACOM010", {|oReport| ReportPrint(oReport,aOrdem,cAliasZAJ)},"Lançamentos Acumulados Folha")
oReport:SetTotalInLine(.F.)
oReport:SetLandscape() 
oReport:oPage:setPaperSize(10)

//oReport:ShowHeader()

oSection1:=TRSection():New(oReport,"Lançamentos Acumulado Folha",{"SRD","SRA","CTT","SRV"},{})

oSection1:SetTotalInLine(.F.)
TRCell():New(oSection1,"RD_FILIAL"  ,"SRD",     , /*Picture*/	,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"RD_MAT"     ,"SRD", 	, /*Picture*/	,           ,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"RA_NOME"   	,"SRA", 	, /*Picture*/	,           ,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"RD_PD"    	,"SRD", 	, 				,     		,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"RV_DESC"    ,"SRV",  	, 				,     		,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"RD_TIPO1"   ,"SRD", 	, 				,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"RD_HORAS"   ,"SRD", 	, 				,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"RD_VALOR"  	,"SRD", 	, 				,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"RD_DATARQ"  ,"SRD", 	, 				,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"RD_DATPGT" 	,"SRD", 	, /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"RD_CC" 		,"SRD", 	, /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"CTT_DESC01" ,"CTT", 	, /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"RD_ROTEIR" 	,"SRD", 	, /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"ANO" 		,"   ","Ano" , /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"RD_MES" 	,"SRD", 	, /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"RD_VALORBA" ,"SRD", 	, /*Picture*/		,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)

Return(oReport)

Static Function ReportPrint(oReport,aOrdem,cAliasZAJ)
	Local oSection1 := oReport:Section(1)
	Local cQuery    := ""
	Local cAliasTOP := GetNextAlias()
	Local dDtIni	:= MV_PAR01
	Local dDtFin	:= MV_PAR02
	Local cVerbaDe 	:= MV_PAR03
	Local cVerbaAte := MV_PAR04

	cQuery += "SELECT SRD.RD_FILIAL, SRD.RD_MAT, SRA.RA_NOME, SRD.RD_PD, SRV.RV_DESC, SRD.RD_TIPO1, SRD.RD_HORAS, SRD.RD_VALOR, SRD.RD_DATARQ, "
	cQuery += "SRD.RD_DATPGT, SRD.RD_CC, CTT.CTT_DESC01, SRD.RD_ROTEIR, SRD.RD_MES, SUBSTRING(SRD.RD_DATARQ,1,4) ANO, SRD.RD_VALORBA  "
	cQuery += "FROM "+retSqlName("SRD") + " SRD "
	cQuery += "INNER JOIN "+retSqlName("SRA") + " SRA ON (SRA.D_E_L_E_T_ = ' ' AND SRA.RA_FILIAL = SRD.RD_FILIAL AND SRA.RA_MAT = SRD.RD_MAT) "
	cQuery += "INNER JOIN "+retSqlName("SRV") + " SRV ON (SRV.D_E_L_E_T_ = ' ' AND SRV.RV_COD = SRD.RD_PD) "
	cQuery += "INNER JOIN "+retSqlName("CTT") + " CTT ON (CTT.D_E_L_E_T_ = ' ' AND CTT.CTT_CUSTO = SRD.RD_CC) "
	cQuery += "WHERE SRD.D_E_L_E_T_ = ' '  "
	cQuery += "AND SRD.RD_DTREF BETWEEN '"+dtos(dDtIni)+"' AND '"+dtos(dDtFin)+"' "
	cQuery += "AND SRD.RD_PD BETWEEN '"+cVerbaDe+"' AND '"+cVerbaAte+"' "
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasTop,.T.,.T.)

	oSection1:Init()

	dbSelectArea(cAliasTOP)
	dbgotop()
	do while (cAliasTOP)->(!Eof())

		oReport:IncMeter()
		If oReport:Cancel()
			Exit
		EndIf

		oSection1:Cell("RD_FILIAL"):SetValue((cAliasTop)->RD_FILIAL)
		oSection1:Cell("RD_FILIAL"):SetAlign("LEFT")

		oSection1:Cell("RD_MAT"):SetValue((cAliasTop)->RD_MAT)
		oSection1:Cell("RD_MAT"):SetAlign("LEFT")

		oSection1:Cell("RA_NOME"):SetValue((cAliasTop)->RA_NOME)
		oSection1:Cell("RA_NOME"):SetAlign("LEFT")

		oSection1:Cell("RD_PD"):SetValue((cAliasTop)->RD_PD)
		oSection1:Cell("RD_PD"):SetAlign("RIGHT")
		
		oSection1:Cell("RV_DESC"):SetValue((cAliasTop)->RV_DESC)
		oSection1:Cell("RV_DESC"):SetAlign("RIGHT")

		oSection1:Cell("RD_TIPO1"):SetValue((cAliasTop)->RD_TIPO1)
		oSection1:Cell("RD_TIPO1"):SetAlign("RIGHT")

		oSection1:Cell("RD_HORAS"):SetValue((cAliasTop)->RD_HORAS)
		oSection1:Cell("RD_HORAS"):SetAlign("RIGHT")

		oSection1:Cell("RD_VALOR"):SetValue((cAliasTop)->RD_VALOR)
		oSection1:Cell("RD_VALOR"):SetAlign("LEFT")

		oSection1:Cell("RD_DATARQ"):SetValue((cAliasTop)->RD_DATARQ)
		oSection1:Cell("RD_DATARQ"):SetAlign("LEFT")

		oSection1:Cell("RD_DATPGT"):SetValue(stod((cAliasTop)->RD_DATPGT))
		oSection1:Cell("RD_DATPGT"):SetAlign("LEFT")
		
		oSection1:Cell("RD_CC"):SetValue(stod((cAliasTop)->RD_CC))
		oSection1:Cell("RD_CC"):SetAlign("LEFT")

		oSection1:Cell("CTT_DESC01"):SetValue((cAliasTop)->CTT_DESC01)
		oSection1:Cell("CTT_DESC01"):SetAlign("LEFT")

		oSection1:Cell("RD_ROTEIR"):SetValue((cAliasTop)->RD_ROTEIR)
		oSection1:Cell("RD_ROTEIR"):SetAlign("LEFT")

		oSection1:Cell("RD_MES"):SetValue((cAliasTop)->RD_MES)
		oSection1:Cell("RD_MES"):SetAlign("LEFT")

		oSection1:Cell("ANO"):SetValue((cAliasTop)->ANO)
		oSection1:Cell("ANO"):SetAlign("LEFT")

		oSection1:Cell("RD_VALORBA"):SetValue((cAliasTop)->RD_VALORBA)
		oSection1:Cell("RD_VALORBA"):SetAlign("LEFT")		

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
aAdd(aRegs,{cPerg,"03","Verba De ?"   ,"","","mv_ch3","C", 03,0,0,"G","","mv_par03","","","","","","","","","","","","","","","","","","","","","","","","","",""})
aAdd(aRegs,{cPerg,"04","Verba Até?"   ,"","","mv_ch4","C", 03,0,0,"G","","mv_par04","","","","","","","","","","","","","","","","","","","","","","","","","",""})

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
