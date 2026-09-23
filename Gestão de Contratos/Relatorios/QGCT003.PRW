#INCLUDE "PROTHEUS.CH"
#INCLUDE "COLORS.CH"

/*
Programa   QGCT003
Descricao  	Relatorio de contratos ativos ha muito tempo sem medicao.
			Traz apenas a ultima revisao de cada contrato (evita duplicidade).
			A data e a competencia da ultima medicao vem do historico real de
			medicoes (tabela CND, campos CND_DTINIC/CND_COMPET); se o contrato
			nunca teve medicao, usa a data de elaboracao (CN9_DTINIC) como
			referencia para o calculo de dias sem medir. Filtros: filial, tipo
			de contrato (compra/venda), status (selecao multipla via modal),
			quantidade minima de dias sem medir e faixa de saldo financeiro
			pendente (CNF_SALDO).
Uso        	Gestao de Contratos
Author		Thiago Sales
Data		16/07/2026
*/

User Function QGCT003()
Local oReport

AjustaSX1("QGCT003")

oReport := ReportDef()
oReport:PrintDialog()

Return

Static Function ReportDef()
Local oReport
Local oSection1

Pergunte("QGCT003",.T.)

oReport := TReport():New("QGCT003","Contratos sem Medicao","QGCT003",{|oReport| ReportPrint(oReport)},"Contratos ativos ha muito tempo sem medicao")
oReport:SetLandscape()
oReport:SetTotalInLine(.F.)

oSection1 := TRSection():New(oReport,"Contratos sem Medicao",{"CN9"},{})
oSection1:SetTotalInLine(.F.)

TRCell():New(oSection1,"CN9_FILIAL" ,"CN9","Filial")
TRCell():New(oSection1,"FILNAME"    ,,"Nome Filial")
TRCell():New(oSection1,"CN9_NUMERO" ,"CN9","Contrato")
TRCell():New(oSection1,"CN9_REVISA" ,"CN9","Revisao")
TRCell():New(oSection1,"TIPODESC"   ,,"Tipo")
TRCell():New(oSection1,"SITDESC"    ,,"Situacao")
TRCell():New(oSection1,"CN9_DTINIC" ,"CN9","Dt.Elaboracao")
TRCell():New(oSection1,"ULTMED"     ,,"Dt.Ultima Medicao")
TRCell():New(oSection1,"ULTCOMPET"  ,,"Competencia")
TRCell():New(oSection1,"DIASSEMED"  ,,"Dias sem Medir")
TRCell():New(oSection1,"SALDOCTR"   ,,"Saldo",PesqPict("CNF","CNF_SALDO"))

oSection1:Cell("CN9_FILIAL"):SetHeaderAlign("LEFT")
oSection1:Cell("FILNAME"):SetHeaderAlign("LEFT")
oSection1:Cell("CN9_NUMERO"):SetHeaderAlign("LEFT")
oSection1:Cell("CN9_REVISA"):SetHeaderAlign("LEFT")
oSection1:Cell("TIPODESC"):SetHeaderAlign("LEFT")
oSection1:Cell("SITDESC"):SetHeaderAlign("LEFT")
oSection1:Cell("CN9_DTINIC"):SetHeaderAlign("LEFT")
oSection1:Cell("ULTMED"):SetHeaderAlign("LEFT")
oSection1:Cell("ULTCOMPET"):SetHeaderAlign("LEFT")
oSection1:Cell("DIASSEMED"):SetHeaderAlign("RIGHT")
oSection1:Cell("SALDOCTR"):SetHeaderAlign("RIGHT")

Return oReport

Static Function ReportPrint(oReport)
Local oSection1  := oReport:Section(1)
Local cQuery     := ""
Local cAliasTop  := GetNextAlias()
Local cSitPar    := AllTrim(mv_par03)
Local aStatus    := {}
Local dUltMed
Local nDias
Local nSaldo
Local cSitDesc
Local cTipoDesc
Local cCompet
Local nX

If !Empty(cSitPar)
	aStatus := hb_ATokens(cSitPar,",")
Endif

cQuery := "SELECT CN9.CN9_FILIAL, CN9.CN9_NUMERO, CN9.CN9_REVISA, CN9.CN9_SITUAC, CN9.CN9_ESPCTR, CN9.CN9_DTINIC, "
cQuery += "SUM(COALESCE(CNF.CNF_SALDO,0)) SALDO, "
cQuery += "(SELECT TOP 1 CNDX.CND_DTINIC FROM "+RetSqlName("CND")+" CNDX WHERE CNDX.D_E_L_E_T_ = ' ' "
cQuery += "AND CNDX.CND_FILCTR = CN9.CN9_FILCTR AND CNDX.CND_CONTRA = CN9.CN9_NUMERO ORDER BY CNDX.CND_DTINIC DESC) ULTMED, "
cQuery += "(SELECT TOP 1 CNDX.CND_COMPET FROM "+RetSqlName("CND")+" CNDX WHERE CNDX.D_E_L_E_T_ = ' ' "
cQuery += "AND CNDX.CND_FILCTR = CN9.CN9_FILCTR AND CNDX.CND_CONTRA = CN9.CN9_NUMERO ORDER BY CNDX.CND_DTINIC DESC) ULTCOMPET "
cQuery += "FROM "+RetSqlName("CN9")+" CN9 "
cQuery += "INNER JOIN "+RetSqlName("CNA")+" CNA ON ( CNA.D_E_L_E_T_ = ' ' "
cQuery += "AND CNA.CNA_FILIAL = CN9.CN9_FILIAL AND CNA.CNA_CONTRA = CN9.CN9_NUMERO AND CNA.CNA_REVISA = CN9.CN9_REVISA ) "
cQuery += "LEFT JOIN "+RetSqlName("CNF")+" CNF ON ( CNF.D_E_L_E_T_ = ' ' "
cQuery += "AND CNF.CNF_FILIAL = CN9.CN9_FILIAL AND CNF.CNF_CONTRA = CN9.CN9_NUMERO AND CNF.CNF_REVISA = CN9.CN9_REVISA AND CNF.CNF_NUMPLA = CNA.CNA_NUMERO ) "
cQuery += "WHERE CN9.D_E_L_E_T_ = ' ' "
cQuery += "AND CN9.CN9_REVISA = ( SELECT MAX(CN92.CN9_REVISA) FROM "+RetSqlName("CN9")+" CN92 "
cQuery += "WHERE CN92.D_E_L_E_T_ = ' ' AND CN92.CN9_FILCTR = CN9.CN9_FILCTR AND CN92.CN9_NUMERO = CN9.CN9_NUMERO ) "
cQuery += "AND CN9.CN9_FILCTR BETWEEN '"+mv_par01+"' AND '"+mv_par02+"' "

If mv_par07 == 1
	cQuery += "AND CN9.CN9_ESPCTR = '1' "
ElseIf mv_par07 == 2
	cQuery += "AND CN9.CN9_ESPCTR = '2' "
Endif

If Len(aStatus) > 0
	cQuery += "AND CN9.CN9_SITUAC IN ("
	For nX := 1 To Len(aStatus)
		cQuery += "'"+AllTrim(aStatus[nX])+"'"
		If nX < Len(aStatus)
			cQuery += ","
		Endif
	Next nX
	cQuery += ") "
Endif

cQuery += "GROUP BY CN9.CN9_FILIAL, CN9.CN9_NUMERO, CN9.CN9_REVISA, CN9.CN9_SITUAC, CN9.CN9_ESPCTR, CN9.CN9_DTINIC, CN9.CN9_FILCTR "
cQuery += "ORDER BY CN9.CN9_FILIAL, CN9.CN9_NUMERO "

cQuery := ChangeQuery(cQuery)
dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasTop,.T.,.T.)

oSection1:Init()

(cAliasTop)->(dbGoTop())
Do While (cAliasTop)->(!Eof())

	oReport:IncMeter()
	If oReport:Cancel()
		Exit
	Endif

	If Empty((cAliasTop)->CN9_DTINIC)
		(cAliasTop)->(dbSkip())
		Loop
	Endif

	dUltMed := IIf(Empty((cAliasTop)->ULTMED),CTOD(""),STOD((cAliasTop)->ULTMED))
	nDias   := IIf(Empty(dUltMed),dDataBase-STOD((cAliasTop)->CN9_DTINIC),dDataBase-dUltMed)
	nSaldo  := (cAliasTop)->SALDO

	//Filtro de dias sem medir (minimo)
	If nDias < mv_par04
		(cAliasTop)->(dbSkip())
		Loop
	Endif

	//Filtro de faixa de saldo
	If nSaldo < mv_par05 .Or. nSaldo > mv_par06
		(cAliasTop)->(dbSkip())
		Loop
	Endif

	cSitDesc  := QG3SitDesc((cAliasTop)->CN9_SITUAC)
	cTipoDesc := IIf((cAliasTop)->CN9_ESPCTR == "2","Venda","Compra")
	cCompet   := AllTrim((cAliasTop)->ULTCOMPET)

	oSection1:Cell("CN9_FILIAL"):SetValue((cAliasTop)->CN9_FILIAL)
	oSection1:Cell("FILNAME"):SetValue(AllTrim(FWFilialName(,(cAliasTop)->CN9_FILIAL)))
	oSection1:Cell("CN9_NUMERO"):SetValue((cAliasTop)->CN9_NUMERO)
	oSection1:Cell("CN9_REVISA"):SetValue((cAliasTop)->CN9_REVISA)
	oSection1:Cell("TIPODESC"):SetValue(cTipoDesc)
	oSection1:Cell("SITDESC"):SetValue(cSitDesc)
	oSection1:Cell("CN9_DTINIC"):SetValue(STOD((cAliasTop)->CN9_DTINIC))
	oSection1:Cell("ULTMED"):SetValue(dUltMed)
	oSection1:Cell("ULTCOMPET"):SetValue(cCompet)
	oSection1:Cell("DIASSEMED"):SetValue(nDias)
	oSection1:Cell("SALDOCTR"):SetValue(nSaldo)

	oSection1:PrintLine()

	(cAliasTop)->(dbSkip())
Enddo

(cAliasTop)->(dbCloseArea())
oSection1:Finish()

Return Nil

/*
Lista fixa de status de contrato (CN9_SITUAC), conforme legenda informada:
01=Cancel. / 02=Elaboracao / 03=Emitido / 04=Aprov. / 05=Vigente /
06=Paralisa / 07=Sol.Finali / 08=Finali / 09=Revisao / 10=Revisado /
A=Aprov Rev
*/
Static Function QG3ListaSit()
Local aLista := {}

aAdd(aLista,{"01","Cancel."})
aAdd(aLista,{"02","Elaboracao"})
aAdd(aLista,{"03","Emitido"})
aAdd(aLista,{"04","Aprov."})
aAdd(aLista,{"05","Vigente"})
aAdd(aLista,{"06","Paralisa"})
aAdd(aLista,{"07","Sol.Finali"})
aAdd(aLista,{"08","Finali"})
aAdd(aLista,{"09","Revisao"})
aAdd(aLista,{"10","Revisado"})
aAdd(aLista,{"A" ,"Aprov Rev"})

Return aLista

Static Function QG3SitDesc(cValor)
Local aLista := QG3ListaSit()
Local nPos   := Ascan(aLista,{|aItem| AllTrim(aItem[1]) == AllTrim(cValor)})

Return IIf(nPos>0,aLista[nPos][2],cValor)

/*
Funcao F3 customizada do parametro de Status (mv_par03).
Abre um modal com um grid de marcacao (coluna logica = checkbox) listando
todos os status de contrato cadastrados no combo de CN9_SITUAC, permitindo
selecionar um ou mais itens. Ao clicar em Ok, monta uma lista dos codigos
marcados separados por virgula e grava direto na variavel do parametro
(padrao classico de F3 customizado via ReadVar()/macro).
*/
User Function QG3F3ST()
Local nAltura   := 300
Local nLargura  := 400
Local cVarF3    := ReadVar()
Local cAtual    := &(cVarF3)
Local aLista    := QG3ListaSit()
Local aSelec    := {}
Local cRet      := ""
Local oDlg
Local oGeTD
Local oBtn1
Local nX
Private aHeader := {}
Private aCols   := {}

If !Empty(cAtual)
	aSelec := hb_ATokens(cAtual,",")
Endif

aAdd(aHeader,{"Sel"       ,"MARCA"  ,"@"  ,03,0,".F.","","L","CN9"})
aAdd(aHeader,{"Codigo"    ,"CODSIT" ,"@!" ,02,0,".F.","","C","CN9"})
aAdd(aHeader,{"Descricao" ,"DESSIT" ,"@!" ,30,0,".F.","","C","CN9"})

For nX := 1 To Len(aLista)
	aAdd(aCols,{ Ascan(aSelec,{|cCod| AllTrim(cCod) == AllTrim(aLista[nX][1])}) > 0, aLista[nX][1], aLista[nX][2] })
Next nX

oDlg := MsDialog():New(0,0,nAltura,nLargura,"Selecione o(s) Status do Contrato",,,,,CLR_BLACK,CLR_WHITE,,,.T.)

oGeTD := MsGetDados():New( 10              ,;
						   05              ,;
						   (nAltura/2)-15  ,;
						   (nLargura/2)-05 ,;
						   4               ,;
						   "AllwaysTrue"   ,;
						   "AllwaysTrue"   ,;
						   ""              ,;
						   .F.             ,;
						   .F.             ,;
						   nil             ,;
						   .F.             ,;
						   Len(aCols)      ,;
						   nil             ,;
						   "AllwaysTrue()" ,;
						   nil             ,;
						   "AllwaysTrue()" ,;
						   oDlg             )

oBtn1 := tButton():New((nAltura/2)-8,(nLargura/2)-45,"Ok",oDlg,{||oDlg:End()},40,10,,,,.T.)

oDlg:Activate(,,,.T.,{||.T.},,{||})

For nX := 1 To Len(aCols)
	If aCols[nX][1]
		cRet += aCols[nX][2] + ","
	Endif
Next nX
If !Empty(cRet)
	cRet := SubStr(cRet,1,Len(cRet)-1)
Endif

&(cVarF3) := cRet

Return .T.

Static Function AjustaSX1(cPerg)
Local _sAlias  := Alias()
Local aRegs    := {}
Local nTamFil  := TamSX3("CN9_FILCTR")[1]
Local nX

dbSelectArea("SX1")
dbSetOrder(1)
cPerg := PADR(cPerg,10)

//aRegs[nX][01] - X1_GRUPO
//aRegs[nX][02] - X1_ORDEM
//aRegs[nX][03] - X1_PERGUNT
//aRegs[nX][04] - X1_PERSPA
//aRegs[nX][05] - X1_PERENG
//aRegs[nX][06] - X1_VARIAVL
//aRegs[nX][07] - X1_TIPO
//aRegs[nX][08] - X1_TAMANHO
//aRegs[nX][09] - X1_DECIMAL
//aRegs[nX][10] - X1_PRESEL
//aRegs[nX][11] - X1_GSC
//aRegs[nX][12] - X1_VALID
//aRegs[nX][13] - X1_VAR01
//aRegs[nX][14] - X1_DEF01
//aRegs[nX][15] - X1_DEF02
//aRegs[nX][16] - X1_DEF03
//aRegs[nX][17] - X1_DEF04
//aRegs[nX][18] - X1_DEF05
//aRegs[nX][19] - X1_F3

aAdd(aRegs,{cPerg,"01","Filial De ?"              ,"Filial De ?"              ,"Filial De ?"              ,"mv_ch1","C",nTamFil,0,0,"G","","mv_par01",Space(nTamFil)         ,"","","",""       ,""})
aAdd(aRegs,{cPerg,"02","Filial Ate ?"              ,"Filial Ate ?"              ,"Filial Ate ?"              ,"mv_ch2","C",nTamFil,0,0,"G","","mv_par02",Replicate("Z",nTamFil) ,"","","",""       ,""})
aAdd(aRegs,{cPerg,"03","Status (F3=Selecionar) ?"  ,"Status (F3=Selecionar) ?"  ,"Status (F3=Selecionar) ?"  ,"mv_ch3","C",40,0,0,"G","","mv_par03",""                     ,"","","",""       ,"QG3F3ST"})
aAdd(aRegs,{cPerg,"04","Dias sem medir (minimo) ?" ,"Dias sem medir (minimo) ?" ,"Dias sem medir (minimo) ?" ,"mv_ch4","N",05,0,0,"G","","mv_par04","0"                    ,"","","",""       ,""})
aAdd(aRegs,{cPerg,"05","Saldo De ?"                ,"Saldo De ?"                ,"Saldo De ?"                ,"mv_ch5","N",17,2,0,"G","","mv_par05","-999999999999.99"     ,"","","",""       ,""})
aAdd(aRegs,{cPerg,"06","Saldo Ate ?"               ,"Saldo Ate ?"               ,"Saldo Ate ?"               ,"mv_ch6","N",17,2,0,"G","","mv_par06","999999999999.99"      ,"","","",""       ,""})
aAdd(aRegs,{cPerg,"07","Tipo de Contrato ?"        ,"Tipo de Contrato ?"        ,"Tipo de Contrato ?"        ,"mv_ch7","N",01,0,3,"C","","mv_par07","Compra"               ,"Venda","Ambos",""  ,"",""})

For nX := 1 To Len(aRegs)
	If dbSeek(cPerg+aRegs[nX,2])
		RecLock("SX1",.F.)
	Else
		RecLock("SX1",.T.)
	Endif
	Replace SX1->X1_GRUPO   With aRegs[nX][01]
	Replace SX1->X1_ORDEM   With aRegs[nX][02]
	Replace SX1->X1_PERGUNT With aRegs[nX][03]
	Replace SX1->X1_PERSPA  With aRegs[nX][04]
	Replace SX1->X1_PERENG  With aRegs[nX][05]
	Replace SX1->X1_VARIAVL With aRegs[nX][06]
	Replace SX1->X1_TIPO    With aRegs[nX][07]
	Replace SX1->X1_TAMANHO With aRegs[nX][08]
	Replace SX1->X1_DECIMAL With aRegs[nX][09]
	Replace SX1->X1_PRESEL  With aRegs[nX][10]
	Replace SX1->X1_GSC     With aRegs[nX][11]
	Replace SX1->X1_VALID   With aRegs[nX][12]
	Replace SX1->X1_VAR01   With aRegs[nX][13]
	Replace SX1->X1_DEF01   With aRegs[nX][14]
	Replace SX1->X1_DEF02   With aRegs[nX][15]
	Replace SX1->X1_DEF03   With aRegs[nX][16]
	Replace SX1->X1_DEF04   With aRegs[nX][17]
	Replace SX1->X1_DEF05   With aRegs[nX][18]
	Replace SX1->X1_F3      With aRegs[nX][19]
	SX1->(MsUnlock())
Next nX
dbSelectArea(_sAlias)

Return
