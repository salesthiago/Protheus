#INCLUDE "FIVEWIN.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "APWIZARD.CH"
#INCLUDE "FILEIO.CH"
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"
#INCLUDE "TOTVS.CH"
#INCLUDE "PARMTYPE.CH"
#Include "RWMAKE.CH"
#INCLUDE "REPORT.CH"

/*/{Protheus.doc} QPES002
Reimpressao de Tickets de Pesagem (tabela NJH), em lote, por faixa de Centro
de Custo (NJH_XCLVL), Data (NJH_DATA) e Status (NJH_STATUS).

Todos os tickets encontrados no filtro sao impressos em um unico arquivo,
repetindo cada ticket "Copias" vezes (parametro mv_par07), no mesmo layout
usado pelo QPES001. O cabecalho impresso (titulo/CNPJ/endereco) muda de
acordo com o Centro de Custo (NJH_XCLVL) de cada ticket.

Alem da impressao/PDF do ticket (layout fixo, via FWMSPrinter), o usuario
pode optar por gerar uma planilha (parametro Tipo de Saida = Excel), que
lista os tickets encontrados em formato tabular via TReport, cuja tela
padrao de impressao (PrintDialog) ja oferece exportacao para Excel/PDF/HTML.

Parametros: Centro de Custo De/Ate, Data De/Ate, Status De/Ate, Copias e
Tipo de Saida (Ticket ou Excel).
@type User Function
/*/
//=============================================================================
user Function QPES002()
//=============================================================================

Local oPrinter 	:= Nil
Local lEnd		:= .T.

Private oFont8 	:= TFont():New('Arial',,08,.T.,.F.)
Private oFont9 	:= TFont():New('Arial',,09,.T.,.F.)
Private oFontT 	:= TFont():New('Arial',,10,.T.)
Private oFontTN	:= TFont():New('Arial',,10,.T.,.T.)
Private oFontC 	:= TFont():New('Arial',,12,.T.,.F.)
Private oFontCN := TFont():New('Arial',,12,.T.,.T.)
Private oFontT_	:= TFont():New('Arial',,10,.T.,.F.)

Private aArray	:= {}
Private li		:= 15
Private nMaxLin	:= 1800
Private nMaxCol	:= 2500
Private lItemNeg:= .F.
Private nPagina := 1

AjustaSX1(Padr("QPES002", 10))
Pergunte("QPES002", .T.)

If mv_par08 == 2 // Excel

	xExpQPES002Excel()

Else // Ticket (Impressao/PDF)

	cCaminho    := GetTempPath()
	cFile       := cCaminho+"/"+"QPES002"+".rel"

	oPrinter := tNewMSPrinter():New("Reimpressao de Tickets de Pesagem")
	oPrinter:SetPortrait()
	oPrinter:SetPaperSize(10)
	oPrinter:setup()

	RptStatus({|lEnd| QPES002I(@lEnd, cFile, @oPrinter)},"Imprimindo Relatorio...")

	FreeObj(oPrinter)
	oPrinter := Nil

EndIf

Return Nil

/*/{Protheus.doc} AjustaSX1
Registra as perguntas do relatorio na tabela SX1, caso ainda nao existam.
@type Static Function
@param cPerg Character, identificador do grupo de perguntas
/*/
//=============================================================================
Static Function AjustaSX1(cPerg)
//=============================================================================
	Local aRegs := {}
	Local nX    := 0

	// {X1_GRUPO,X1_ORDEM,X1_PERGUNTE,X1_PERSPA,X1_PERENG,X1_VARIAVL,X1_TIPO,X1_TAM,X1_DEC,X1_PRESEL,X1_GSC,X1_VALID,X1_VAR01,X1_DEF01,X1_DEF02,X1_DEF03,X1_F3}
	aAdd(aRegs, {cPerg,"01","Centro Custo De    ","Centro Custo De    ","Centro Custo De    ","mv_ch1","C",15,0,0,"G","","mv_par01","","","",""})
	aAdd(aRegs, {cPerg,"02","Centro Custo Ate   ","Centro Custo Ate   ","Centro Custo Ate   ","mv_ch2","C",15,0,0,"G","","mv_par02","ZZZZZZZZZZZZZZZ","","",""})
	aAdd(aRegs, {cPerg,"03","Data De            ","Data De            ","Data De            ","mv_ch3","D", 8,0,0,"G","","mv_par03","","","",""})
	aAdd(aRegs, {cPerg,"04","Data Ate           ","Data Ate           ","Data Ate           ","mv_ch4","D", 8,0,0,"G","","mv_par04","","","",""})
	aAdd(aRegs, {cPerg,"05","Status De          ","Status De          ","Status De          ","mv_ch5","C", 1,0,0,"G","","mv_par05","0","","",""})
	aAdd(aRegs, {cPerg,"06","Status Ate         ","Status Ate         ","Status Ate         ","mv_ch6","C", 1,0,0,"G","","mv_par06","4","","",""})
	aAdd(aRegs, {cPerg,"07","Copias             ","Copias             ","Copias             ","mv_ch7","N", 2,0,0,"G","","mv_par07","1","","",""})
	aAdd(aRegs, {cPerg,"08","Tipo de Saida      ","Tipo de Saida      ","Tipo de Saida      ","mv_ch8","N", 1,0,1,"C","","mv_par08","Ticket (Impressao/PDF)","Planilha (Excel)","",""})

	DbSelectArea("SX1")
	SX1->(DbSetOrder(1))

	For nX := 1 To Len(aRegs)
		If !SX1->(DbSeek(aRegs[nX][01] + aRegs[nX][02]))
			RecLock("SX1", .T.)
			Replace SX1->X1_GRUPO    With aRegs[nX][01]
			Replace SX1->X1_ORDEM    With aRegs[nX][02]
			Replace SX1->X1_PERGUNTE With aRegs[nX][03]
			Replace SX1->X1_PERSPA   With aRegs[nX][04]
			Replace SX1->X1_PERENG   With aRegs[nX][05]
			Replace SX1->X1_VARIAVL  With aRegs[nX][06]
			Replace SX1->X1_TIPO     With aRegs[nX][07]
			Replace SX1->X1_TAMANHO  With aRegs[nX][08]
			Replace SX1->X1_DECIMAL  With aRegs[nX][09]
			Replace SX1->X1_PRESEL   With aRegs[nX][10]
			Replace SX1->X1_GSC      With aRegs[nX][11]
			Replace SX1->X1_VALID    With aRegs[nX][12]
			Replace SX1->X1_VAR01    With aRegs[nX][13]
			Replace SX1->X1_DEF01    With aRegs[nX][14]
			Replace SX1->X1_DEF02    With aRegs[nX][15]
			Replace SX1->X1_DEF03    With aRegs[nX][16]
			Replace SX1->X1_F3       With aRegs[nX][17]
			MsUnlock("SX1")
		EndIf
	Next nX

Return

/*/{Protheus.doc} xMontaQryQPES002
Monta a query (somente o RECNO do NJH) de acordo com os filtros informados
pelo usuario (Centro de Custo, Data e Status), reutilizada tanto pela
impressao dos tickets quanto pela exportacao para Excel.
@type Static Function
@return cQuery Character, query SQL
/*/
//=============================================================================
Static Function xMontaQryQPES002()
//=============================================================================
	Local cCCDe   := AllTrim(mv_par01)
	Local cCCAte  := AllTrim(mv_par02)
	Local dDtDe   := If(Empty(mv_par03), CTOD("01/01/1900"), mv_par03)
	Local dDtAte  := If(Empty(mv_par04), Date(), mv_par04)
	Local cStDe   := mv_par05
	Local cStAte  := mv_par06
	Local cQuery  := ""

	cQuery := "SELECT NJH.R_E_C_N_O_ NJHRECNO "
	cQuery += "FROM " + RetSqlName("NJH") + " NJH "
	cQuery += "WHERE NJH.D_E_L_E_T_ = ' ' "
	//cQuery += "AND NJH.NJH_FILIAL = '" + xFilial("NJH") + "' "
	cQuery += "AND NJH.NJH_XCLVL BETWEEN '" + cCCDe + "' AND '" + cCCAte + "' "
	cQuery += "AND NJH.NJH_STATUS BETWEEN '" + cStDe + "' AND '" + cStAte + "' "
	cQuery += "AND NJH.NJH_DATA BETWEEN '" + DTOS(dDtDe) + "' AND '" + DTOS(dDtAte) + "' "
	cQuery += "ORDER BY NJH.NJH_DATA, NJH.NJH_CODPAV "

Return cQuery

/*/{Protheus.doc} xDescStatus
Traduz o codigo de NJH_STATUS para a descricao textual correspondente.
@type Static Function
@param cStatus Character, codigo do status (0 a 4)
@return cDesc Character, descricao do status
/*/
//=============================================================================
Static Function xDescStatus(cStatus)
//=============================================================================
	Local cDesc := ""

	Do Case
		Case cStatus == "0" ; cDesc := "Sem Pesagem"
		Case cStatus == "1" ; cDesc := "Primeira Pesagem"
		Case cStatus == "2" ; cDesc := "Segunda Pesagem"
		Case cStatus == "3" ; cDesc := "Finalizada"
		Case cStatus == "4" ; cDesc := "Cancelada"
		Otherwise           ; cDesc := "Nao Identificado"
	EndCase

Return cDesc

/*/{Protheus.doc} QPES002I
Percorre os tickets encontrados no filtro e imprime cada um "Copias" vezes,
no mesmo layout do QPES001, em um unico arquivo de impressao/PDF.
@type Static Function
/*/
//=============================================================================
static Function QPES002I(lEnd, cIdent, oPrinter)
//=============================================================================
    Local nVezes     := 1
    Local nCopias    := Max(1, mv_par07)
    Local cCodUsr    := ""
    Local cNomComUsr := ""
#IFDEF TOP
    Local cAliasTop  := GetNextAlias()
    Local cQuery     := xMontaQryQPES002()
#ENDIF

    if lEnd
		oPrinter:StartPage()
		oPrinter:Say(li,5,"Cancelado pelo Operador")
		oPrinter:EndPage()
		oPrinter:Print()
		return
	endIF

#IFDEF TOP
    dbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAliasTop, .T., .T.)

    dbSelectArea(cAliasTop)
    dbGoTop()
    Do While !(cAliasTop)->(Eof())

        NJH->(dbGoTo((cAliasTop)->NJHRECNO))

        cCodUsr    := alltrim(NJH->NJH_XUSER)
        cNomComUsr := cCodUsr

        oPrinter:StartPage()
        li := 15

        for nVezes := 1 to nCopias
            cabecOp(nPagina,@li,oPrinter)

            oPrinter:Say(li,0010,"Placa:"               ,oFontC)
            oPrinter:Say(li,0350,NJH->NJH_PLACA         ,oFontCN)
            li+= 42

            oPrinter:Say(li,0010,"Data Entrada:"        ,oFontC)
            oPrinter:Say(li,0350,dToc(NJH->NJH_DATPS1)  ,oFontCN)
            oPrinter:Say(li,0900,"Hora Entrada:"        ,oFontC)
            oPrinter:Say(li,1300,NJH->NJH_HORPS1        ,oFontCN)
            li+= 42

            oPrinter:Say(li,0010,"Data Saída:"          ,oFontC)
            oPrinter:Say(li,0350,dtoc(NJH->NJH_DATPS2)  ,oFontCN)
            oPrinter:Say(li,0900,"Hora Saída:"          ,oFontC)
            oPrinter:Say(li,1300,NJH->NJH_HORPS2        ,oFontCN)
            li+= 42

            oPrinter:Say(li,0010,"Operador:"            ,oFontC)
            oPrinter:Say(li,0350,cNomComUsr              ,oFontCN)
            li+= 42

            oPrinter:Say(li,0010,"Motorista:"           ,oFontC)
            oPrinter:Say(li,0350,NJH->NJH_NOMMOT        ,oFontCN)
            li+= 42

            oPrinter:Say(li,0010,"Produto:"             ,oFontC)
            oPrinter:Say(li,0350,NJH->NJH_DESPRO        ,oFontCN)
            li+= 42

            oPrinter:Say(li,0010,"Fornecedor:"          ,oFontC)
            oPrinter:Say(li,0350,NJH->NJH_NOMENT        ,oFontCN)
            li+= 42

            oPrinter:Say(li,0010,"Cliente:"             ,oFontC)
            if NJH->NJH_CODENT $ '001575-001587'
                oPrinter:Say(li,0350,'PREFEITURA'          ,oFontCN)
            else
                oPrinter:Say(li,0350,NJH->NJH_XCLIEN       ,oFontCN)
            endif
            li+= 42

            oPrinter:Say(li,0010,"Peso Entrada:"                ,oFontC)
            oPrinter:Say(li,0350,Transform(NJH->NJH_PESO1, "@E 999,999")+ " KG"  ,oFontCN)
            li+= 42

            oPrinter:Say(li,0010,"Peso Saída:"                  ,oFontC)
            oPrinter:Say(li,0350,Transform(NJH->NJH_PESO2, "@E 999,999")+ " KG"  ,oFontCN)
            li+= 42

            oPrinter:Say(li,0010,"Peso Líquido:"                ,oFontC)
            oPrinter:Say(li,0350,Transform(NJH->NJH_PSSUBT, "@E 999,999")+ " KG"  ,oFontCN)
            li+= 42

            oPrinter:Say(li,0010,"Observação:"                  ,oFontC)
            oPrinter:Say(li,0350,NJH->NJH_OBS                   ,oFontCN)
            li+= 42
            oPrinter:Say(li,0010,"ROTA:"                        ,oFontC)
            oPrinter:Say(li,0350,NJH->NJH_XROTA                 ,oFontCN)
            li+= 50


            oPrinter:Say(li,0010,"_______________________________",oFontCN)
            oPrinter:Say(li,0800,"_______________________________",oFontCN)
            oPrinter:Say(li,1500,"_______________________________",oFontCN)

            li+= 35
            oPrinter:Say(li,0250,"Operador",oFontCN)
            oPrinter:Say(li,1050,"Fiscal",oFontCN)
            oPrinter:Say(li,1700,"Motorista",oFontCN)
            li+= 35

            oPrinter:Line( li,0020, li, nMaxCol-10,, "-1")
            li += 35
        next

        oPrinter:EndPage()

        (cAliasTop)->(dbSkip())
    EndDo

    (cAliasTop)->(dbCloseArea())
#ENDIF

	Li := 15

    oPrinter:Preview()
    oPrinter:end()

Return

/*/{Protheus.doc} CabecOp
Imprime o cabecalho do ticket. O titulo/CNPJ/endereco impressos mudam de
acordo com o Centro de Custo (NJH_XCLVL) do ticket atual.
@type Static Function
/*/
//=============================================================================
Static Function CabecOp(nPagOp, li, oPrinter)
//=============================================================================
Local cXclvl    := AllTrim(NJH->NJH_XCLVL)
Local cTitulo   := ""
Local cCabec1   := ""
Local cCabec2   := ""
Local cCabec3   := ""
Private oFontC
Private oFontT

Do Case
Case cXclvl == "0102"
	cTitulo   := "PREFEITURA MUNICIPAL DE AP. DE GOIÂNIA - GO"
	cCabec1   := "CNPJ: 01.005.727/0001-24"
	cCabec2   := "Rua Gervásio Pinheiro S/N - Res. Village Garavelo"
	cCabec3   := "Aparecida de Goiânia / GO"
Case cXclvl == "0121"
	cTitulo   := "PREFEITURA MUNICIPAL DE TRINDADE - GO"
	cCabec1   := "CNPJ: 01.217.538/0001-15"
	cCabec2   := "Zona Rural Trindade - Barro Branco"
	cCabec3   := "TRINDADE / GO"
Case cXclvl == "0606"
	cTitulo   := "PREFEITURA MUNICIPAL DE PARACATU - MG"
	cCabec1   := "CNPJ: 18.278.051/0001-45"
	cCabec2   := "Zona Rural  de Paracatu - MG"
	cCabec3   := "PARACATU / MG"
Otherwise
	// Centro de Custo sem cabecalho especifico cadastrado
	cTitulo   := "CENTRO DE CUSTO: " + cXclvl
	cCabec1   := ""
	cCabec2   := ""
	cCabec3   := ""
EndCase

oFontCB	:= TFont():New('Arial',,06,.T.)
oFontT 	:= TFont():New('Arial',,08,.T.)
oFontTN := TFont():New('Arial',,08,.T.,.T.)
oFontC 	:= TFont():New('Arial',,09,.T.)
oFontCN := TFont():New('Arial',,09,.T.,.T.)
oFont16 := TFont():New('Arial',,11,.T.,.T.)
oFont14 := TFont():New('Arial',,09,.T.)

li+= 10

oPrinter:Say(li,0020,cTitulo,oFont16)
li += 35
oPrinter:Say(li,0020,cCabec1,oFont14)
li += 25
oPrinter:Say(li,0020,cCabec2,oFont14)
oPrinter:Say(li,1400,cCabec3,oFont14)
li += 25
oPrinter:Line( li,0020, li, nMaxCol-10,, "-1")
li += 18

oPrinter:Say(li,0900,"Ticket de Pesagem N° "+NJH->NJH_CODPAV,oFont16)
li+= 30

return

/*/{Protheus.doc} xExpQPES002Excel
Monta o objeto TReport com a listagem tabular dos tickets encontrados no
filtro e abre o PrintDialog padrao (Excel/PDF/HTML).
@type Static Function
/*/
//=============================================================================
Static Function xExpQPES002Excel()
//=============================================================================
	Local oReport   := Nil
	Local oSection1 := Nil
	Local cCCusto   := "CC: "+AllTrim(mv_par01)+" a "+AllTrim(mv_par02)
	Local cPeriodo  := "Periodo: "+If(Empty(mv_par03),"",DtoC(mv_par03))+" a "+If(Empty(mv_par04),"",DtoC(mv_par04))

	oReport := TReport():New("QPES002", "Reimpressao de Tickets - " + cPeriodo + " - " + cCCusto, "QPES002", {|oReport| xImpQPES002XLS(oReport)}, "Tickets de Pesagem")
	oReport:SetTotalInLine(.F.)
	oReport:SetLandscape()
	oReport:oPage:SetPaperSize(10)

	oSection1 := TRSection():New(oReport, "Tickets NJH", {"NJH"}, {})
	oSection1:SetTotalInLine(.F.)

	TRCell():New(oSection1, "TICKET"     , "   ", "Ticket"            , , 12)
	TRCell():New(oSection1, "CCUSTO"     , "   ", "Centro de Custo"   , , 15)
	TRCell():New(oSection1, "PLACA"      , "   ", "Placa"             , , 10)
	TRCell():New(oSection1, "DATENT"     , "   ", "Data Entrada"      , , 10)
	TRCell():New(oSection1, "HORENT"     , "   ", "Hora Entrada"      , , 08)
	TRCell():New(oSection1, "DATSAI"     , "   ", "Data Saida"        , , 10)
	TRCell():New(oSection1, "HORSAI"     , "   ", "Hora Saida"        , , 08)
	TRCell():New(oSection1, "MOTORISTA"  , "   ", "Motorista"         , , 30)
	TRCell():New(oSection1, "PRODUTO"    , "   ", "Produto"           , , 25)
	TRCell():New(oSection1, "FORNECEDOR" , "   ", "Fornecedor"        , , 30)
	TRCell():New(oSection1, "CLIENTE"    , "   ", "Cliente"           , , 30)
	TRCell():New(oSection1, "PESO1"      , "   ", "Peso Entrada (KG)" , "@E 999,999", 14)
	TRCell():New(oSection1, "PESO2"      , "   ", "Peso Saida (KG)"   , "@E 999,999", 14)
	TRCell():New(oSection1, "PSLIQ"      , "   ", "Peso Liquido (KG)" , "@E 999,999", 14)
	TRCell():New(oSection1, "STATUS"     , "   ", "Status"            , , 18)
	TRCell():New(oSection1, "OBS"        , "   ", "Observacao"        , , 30)
	TRCell():New(oSection1, "ROTA"       , "   ", "Rota"              , , 15)

	oSection1:Cell("PESO1"):SetHeaderAlign("RIGHT")
	oSection1:Cell("PESO2"):SetHeaderAlign("RIGHT")
	oSection1:Cell("PSLIQ"):SetHeaderAlign("RIGHT")

	oReport:PrintDialog()

Return Nil

/*/{Protheus.doc} xImpQPES002XLS
Executa a consulta e preenche a secao do TReport com um registro por ticket
encontrado no filtro.
@type Static Function
@param oReport Object, instancia do TReport em execucao
/*/
//=============================================================================
Static Function xImpQPES002XLS(oReport)
//=============================================================================
#IFDEF TOP
	Local oSection1  := oReport:Section(1)
	Local cAliasTop  := GetNextAlias()
	Local cQuery     := xMontaQryQPES002()

	dbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAliasTop, .T., .T.)

	oSection1:Init()

	dbSelectArea(cAliasTop)
	dbGoTop()
	Do While !(cAliasTop)->(Eof())

		oReport:IncMeter()
		If oReport:Cancel()
			Exit
		EndIf

		NJH->(dbGoTo((cAliasTop)->NJHRECNO))

		oSection1:Cell("TICKET")    :SetValue(NJH->NJH_CODPAV)
		oSection1:Cell("CCUSTO")    :SetValue(NJH->NJH_XCLVL)
		oSection1:Cell("PLACA")     :SetValue(NJH->NJH_PLACA)
		oSection1:Cell("DATENT")    :SetValue(DtoC(NJH->NJH_DATPS1))
		oSection1:Cell("HORENT")    :SetValue(NJH->NJH_HORPS1)
		oSection1:Cell("DATSAI")    :SetValue(DtoC(NJH->NJH_DATPS2))
		oSection1:Cell("HORSAI")    :SetValue(NJH->NJH_HORPS2)
		oSection1:Cell("MOTORISTA") :SetValue(NJH->NJH_NOMMOT)
		oSection1:Cell("PRODUTO")   :SetValue(NJH->NJH_DESPRO)
		oSection1:Cell("FORNECEDOR"):SetValue(NJH->NJH_NOMENT)
		oSection1:Cell("CLIENTE")   :SetValue(If(NJH->NJH_CODENT $ '001575-001587', 'PREFEITURA', NJH->NJH_XCLIEN))
		oSection1:Cell("PESO1")     :SetValue(NJH->NJH_PESO1)
		oSection1:Cell("PESO2")     :SetValue(NJH->NJH_PESO2)
		oSection1:Cell("PSLIQ")     :SetValue(NJH->NJH_PSSUBT)
		oSection1:Cell("STATUS")    :SetValue(xDescStatus(AllTrim(NJH->NJH_STATUS)))
		oSection1:Cell("OBS")       :SetValue(NJH->NJH_OBS)
		oSection1:Cell("ROTA")      :SetValue(NJH->NJH_XROTA)

		oSection1:PrintLine()

		(cAliasTop)->(dbSkip())
	EndDo

	(cAliasTop)->(dbCloseArea())
	oSection1:Finish()
#ENDIF
Return Nil
