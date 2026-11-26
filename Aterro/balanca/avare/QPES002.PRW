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
de Custo (NJH_XCLVL), Data (NJH_DATA), Status (NJH_STATUS) e, opcionalmente,
por Produto (NJH_CODPRO).

Todos os tickets encontrados no filtro sao impressos em um unico arquivo,
no mesmo layout em blocos do QPES001 (DADOS DA OPERAÇÃO / PESOS / HORARIOS /
FORNECEDOR / TIPO DE CARGA / CLIENTE / OBSERVAÇÃO), com moldura por via e ate
4 vias por folha A4. Com Copias (mv_par07) igual a 0 ou 1 os tickets sao
agrupados por folha (varios tickets na mesma pagina); com Copias maior que 1
cada ticket comeca em uma folha propria, repetido "Copias" vezes. O cabecalho
impresso (titulo/CNPJ/endereco) muda de acordo com o Centro de Custo
(NJH_XCLVL) de cada ticket.

Alem da impressao/PDF do ticket (layout fixo), o usuario pode optar por gerar
uma planilha (parametro Tipo de Saida = Excel), que lista os tickets
encontrados em formato tabular via TReport, cuja tela padrao de impressao
(PrintDialog) ja oferece exportacao para Excel/PDF/HTML.

Parametros: Centro de Custo De/Ate, Data De/Ate, Status De/Ate, Copias,
Tipo de Saida (Ticket ou Excel), Unidade p/ Cabecalho, Produto e
Ticket De/Ate (NJH_CODPAV; limite vazio = sem limite). A Unidade p/
Cabecalho so e usada quando o ticket nao tem Centro de Custo (NJH_XCLVL vazio),
o que acontece nas bases locais de cada unidade, ja que o campo so e preenchido
na base de producao apos a sincronizacao. O Produto e opcional (consulta
padrao SB1 via F3): se informado, filtra os tickets pelo produto; se vazio,
o filtro e ignorado.
@type User Function
/*/
//=============================================================================
user Function QPES002()
//=============================================================================

Local oPrinter 	:= Nil
Local lEnd		:= .T.

Private li		:= 15

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
	Local nTPro := TamSX3("NJH_CODPRO")[1]
	Local nTTk  := TamSX3("NJH_CODPAV")[1]

	// {X1_GRUPO,X1_ORDEM,X1_PERGUNTE,X1_PERSPA,X1_PERENG,X1_VARIAVL,X1_TIPO,X1_TAM,X1_DEC,X1_PRESEL,X1_GSC,X1_VALID,X1_VAR01,X1_DEF01,X1_DEF02,X1_DEF03,X1_F3,X1_DEF04}
	aAdd(aRegs, {cPerg,"01","Centro Custo De    ","Centro Custo De    ","Centro Custo De    ","mv_ch1","C",15,0,0,"G","","mv_par01","","","","",""})
	aAdd(aRegs, {cPerg,"02","Centro Custo Ate   ","Centro Custo Ate   ","Centro Custo Ate   ","mv_ch2","C",15,0,0,"G","","mv_par02","ZZZZZZZZZZZZZZZ","","","",""})
	aAdd(aRegs, {cPerg,"03","Data De            ","Data De            ","Data De            ","mv_ch3","D", 8,0,0,"G","","mv_par03","","","","",""})
	aAdd(aRegs, {cPerg,"04","Data Ate           ","Data Ate           ","Data Ate           ","mv_ch4","D", 8,0,0,"G","","mv_par04","","","","",""})
	aAdd(aRegs, {cPerg,"05","Status De          ","Status De          ","Status De          ","mv_ch5","C", 1,0,0,"G","","mv_par05","0","","","",""})
	aAdd(aRegs, {cPerg,"06","Status Ate         ","Status Ate         ","Status Ate         ","mv_ch6","C", 1,0,0,"G","","mv_par06","4","","","",""})
	aAdd(aRegs, {cPerg,"07","Copias             ","Copias             ","Copias             ","mv_ch7","N", 2,0,0,"G","","mv_par07","1","","","",""})
	aAdd(aRegs, {cPerg,"08","Tipo de Saida      ","Tipo de Saida      ","Tipo de Saida      ","mv_ch8","N", 1,0,1,"C","","mv_par08","Ticket (Impressao/PDF)","Planilha (Excel)","","",""})
	aAdd(aRegs, {cPerg,"09","Unidade p/ Cabecalho","Unidade p/ Cabecalho","Unidade p/ Cabecalho","mv_ch9","N", 1,0,3,"C","","mv_par09","Aparecida de Goiania","Trindade","Paracatu","","Ituiutaba"})
	// Produto opcional: vazio = todos. F3 SB1 = lupa da consulta padrao de produtos
	aAdd(aRegs, {cPerg,"10","Produto            ","Produto            ","Produto            ","mv_cha","C",nTPro,0,0,"G","Vazio() .Or. ExistCpo('SB1')","mv_par10","","","","SB1",""})
	// Numero do Ticket (NJH_CODPAV) De/Ate: vazio = sem limite
	aAdd(aRegs, {cPerg,"11","Ticket De          ","Ticket De          ","Ticket De          ","mv_chb","C",nTTk,0,0,"G","","mv_par11","","","","",""})
	aAdd(aRegs, {cPerg,"12","Ticket Ate         ","Ticket Ate         ","Ticket Ate         ","mv_chc","C",nTTk,0,0,"G","","mv_par12",Replicate("Z",nTTk),"","","",""})

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
			Replace SX1->X1_DEF04    With aRegs[nX][18]
			Replace SX1->X1_F3       With aRegs[nX][17]
			MsUnlock("SX1")
		EndIf
	Next nX

Return

/*/{Protheus.doc} xMontaQryQPES002
Monta a query (somente o RECNO do NJH) de acordo com os filtros informados
pelo usuario (Centro de Custo, Data, Status e Produto), reutilizada tanto pela
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
	Local cProd   := xParProd()
	Local aTk     := xParTicket()
	Local cQuery  := ""

	cQuery := "SELECT NJH.R_E_C_N_O_ NJHRECNO "
	cQuery += "FROM " + RetSqlName("NJH") + " NJH "
	cQuery += "WHERE NJH.D_E_L_E_T_ = ' ' "
	//cQuery += "AND NJH.NJH_FILIAL = '" + xFilial("NJH") + "' "
	cQuery += "AND NJH.NJH_XCLVL BETWEEN '" + cCCDe + "' AND '" + cCCAte + "' "
	cQuery += "AND NJH.NJH_STATUS BETWEEN '" + cStDe + "' AND '" + cStAte + "' "
	cQuery += "AND NJH.NJH_DATA BETWEEN '" + DTOS(dDtDe) + "' AND '" + DTOS(dDtAte) + "' "
	// Produto: so filtra quando informado; vazio = todos os produtos
	If !Empty(cProd)
		cQuery += "AND NJH.NJH_CODPRO = '" + StrTran(cProd, "'", "''") + "' "
	EndIf
	// Numero do Ticket: so filtra o limite que foi informado
	If !Empty(aTk[1])
		cQuery += "AND NJH.NJH_CODPAV >= '" + StrTran(aTk[1], "'", "''") + "' "
	EndIf
	If !Empty(aTk[2])
		cQuery += "AND NJH.NJH_CODPAV <= '" + StrTran(aTk[2], "'", "''") + "' "
	EndIf
	cQuery += "ORDER BY NJH.NJH_DATA, NJH.NJH_CODPAV "

Return cQuery

/*/{Protheus.doc} xParProd
Retorna o codigo do produto informado na pergunta 10 (mv_par10), sem
espacos. Retorna vazio se a pergunta nao foi preenchida.
@type Static Function
@return cProd Character, codigo do produto ou vazio
/*/
//=============================================================================
Static Function xParProd()
//=============================================================================
	Local cProd := ""

	If Type("mv_par10") == "C"
		cProd := AllTrim(mv_par10)
	EndIf

Return cProd

/*/{Protheus.doc} xParTicket
Retorna a faixa de numero de ticket (NJH_CODPAV) informada nas perguntas
11 (Ticket De) e 12 (Ticket Ate). Limite vazio = sem limite.
@type Static Function
@return aTk Array, {cTicketDe, cTicketAte}
/*/
//=============================================================================
Static Function xParTicket()
//=============================================================================
	Local cDe  := ""
	Local cAte := ""

	If Type("mv_par11") == "C"
		cDe := AllTrim(mv_par11)
	EndIf
	If Type("mv_par12") == "C"
		cAte := AllTrim(mv_par12)
	EndIf

Return {cDe, cAte}

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
Percorre os tickets encontrados no filtro e imprime em um unico arquivo de
impressao/PDF, no mesmo layout em blocos do QPES001 (ate 4 vias por folha).

- Copias = 0 ou 1: os tickets sao AGRUPADOS por folha (varios tickets
  diferentes na mesma pagina, ate nTkPag por folha), uma via de cada.
- Copias > 1: cada ticket comeca em uma folha propria, repetido "Copias"
  vezes (se passar de nTkPag vias, continua na folha seguinte).
@type Static Function
/*/
//=============================================================================
static Function QPES002I(lEnd, cIdent, oPrinter)
//=============================================================================
    Local nVezes     := 1
    Local nCopias    := Max(1, mv_par07)
    Local lAgrupa    := (mv_par07 <= 1)
    Local nTkPag     := 4    // vias por folha (mesmo layout do QPES001)
    Local nBase      := 20   // linha inicial da primeira via
    Local nStep      := 832  // altura de cada via (moldura de 820 + espaco)
    Local nNaPag     := 0    // vias ja impressas na folha atual
#IFDEF TOP
    Local cAliasTop  := GetNextAlias()
    Local cQuery     := xMontaQryQPES002()
#ENDIF

    Private oFTit := TFont():New('Arial',,15,.T.,.T.)
    Private oFCab := TFont():New('Arial',,09,.T.)
    Private oFTk  := TFont():New('Arial',,21,.T.,.T.)
    Private oFSc  := TFont():New('Arial',,10,.T.,.T.)
    Private oFLb  := TFont():New('Arial',,13,.T.)
    Private oFVl  := TFont():New('Arial',,13,.T.,.T.)
    Private oFPs  := TFont():New('Arial',,17,.T.,.T.)
    Private oFPl  := TFont():New('Arial',,09,.T.)
    Private oFAs  := TFont():New('Arial',,12,.T.,.T.)

    if lEnd
		oPrinter:StartPage()
		oPrinter:Say(120, 120, "Cancelado pelo Operador", oFVl)
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

        // Modo "Copias > 1": cada ticket comeca numa folha nova
        If !lAgrupa .And. nNaPag > 0
            oPrinter:EndPage()
            nNaPag := 0
        EndIf

        For nVezes := 1 To If(lAgrupa, 1, nCopias)

            If nNaPag == 0
                oPrinter:StartPage()
            EndIf

            QP2Via(oPrinter, nBase + nNaPag * nStep)
            nNaPag++

            If nNaPag >= nTkPag
                oPrinter:EndPage()
                nNaPag := 0
            EndIf

        Next nVezes

        (cAliasTop)->(dbSkip())
    EndDo

    // Fecha a ultima folha, se ficou incompleta
    If nNaPag > 0
        oPrinter:EndPage()
    EndIf

    (cAliasTop)->(dbCloseArea())
#ENDIF

	Li := 15

    oPrinter:Preview()
    oPrinter:end()

Return

/*/{Protheus.doc} QP2Cabec
Retorna o cabecalho (titulo/CNPJ/endereco/cidade) do ticket de acordo com o
Centro de Custo (NJH_XCLVL) do NJH posicionado. Se o ticket estiver sem
Centro de Custo (bases locais, antes da sincronizacao com a producao), usa a
unidade escolhida na pergunta "Unidade p/ Cabecalho" (mv_par09).
@type Static Function
@return aCab Array, {cTitulo, cCNPJ, cEndereco, cCidade}
/*/
//=============================================================================
Static Function QP2Cabec()
//=============================================================================
	Local cXclvl := AllTrim(NJH->NJH_XCLVL)
	Local aCab   := {}

	// Base local de Avare: ticket sem Centro de Custo usa o cabecalho de Avare
	// (a pergunta "Unidade p/ Cabecalho" - mv_par09 - nao e usada nesta unidade)
	If Empty(cXclvl)
		aCab := {"Aterro Municipal", ;
		         "CNPJ: 46.634.168/0001-50", ;
		         "Rua Benedito Ferreira da Silva, 174 - Conjunto Habitacional", ;
		         "Avaré - SP"}
		Return aCab
	EndIf

	Do Case
	Case cXclvl == "0102"
		aCab := {"PREFEITURA MUNICIPAL DE AP. DE GOIÂNIA - GO", ;
		         "CNPJ: 01.005.727/0001-24", ;
		         "Rua Gervásio Pinheiro S/N - Res. Village Garavelo", ;
		         "Aparecida de Goiânia / GO"}
	Case cXclvl == "0121"
		aCab := {"PREFEITURA MUNICIPAL DE TRINDADE - GO", ;
		         "CNPJ: 01.217.538/0001-15", ;
		         "Zona Rural Trindade - Barro Branco", ;
		         "TRINDADE / GO"}
	Case cXclvl == "0606"
		// Mesmo cabecalho do QPES001 de Paracatu
		aCab := {"ATERRO SANITÁRIO MUNICIPAL DE PARACATU - MG", ;
		         "CNPJ: 18.278.051/0001-45", ;
		         "Fazenda Varzea do Moinho, Rodovia de acesso a Entre Ribeiros, nº S/N", ;
		         "PARACATU / MG"}
	Case cXclvl == "9001"
		// Mesmo cabecalho do QPES001 de Ituiutaba
		aCab := {"CTC QUEBEC AMBIENTAL SPE ITUIUTABA", ;
		         "CNPJ: 66.729.172/0001-09", ;
		         "Rua Aloisio Andrade Chaves SN", ;
		         "Ituiutaba / MG"}
	Otherwise
		// Centro de Custo sem cabecalho especifico cadastrado
		aCab := {"CENTRO DE CUSTO: " + cXclvl, "", "", ""}
	EndCase

Return aCab

/*/{Protheus.doc} QP2Via
Desenha uma via completa do ticket do NJH posicionado a partir da linha nT0,
no mesmo layout em blocos do QPES001 (Aparecida).
@type Static Function
/*/
//=============================================================================
Static Function QP2Via(oPrinter, nT0)
//=============================================================================
    Local nAX0   := 40
    Local nAX1   := 1080
    Local nBX0   := 1105
    Local nBX1   := 1740
    Local nCX0   := 1765
    Local nCX1   := 2460
    Local nSub   := 211
    Local nPT    := nT0 + 210
    Local nBcol  := nPT + 370
    Local nY     := 0
    Local aCab   := QP2Cabec()
    Local cOper  := AllTrim(NJH->NJH_XUSER)
    Local cCli   := If(NJH->NJH_CODENT $ '001575-001587', 'PREFEITURA', AllTrim(NJH->NJH_XCLIEN))
    Local cDtHrE := DtoC(NJH->NJH_DATPS1) + "  " + AllTrim(NJH->NJH_HORPS1)
    Local cDtHrS := DtoC(NJH->NJH_DATPS2) + "  " + AllTrim(NJH->NJH_HORPS2)

    // -------- moldura externa da via --------
    oPrinter:Box(nT0, 15, nT0 + 820, 2485)

    // -------- cabecalho da unidade (conforme Centro de Custo) --------
    oPrinter:Say(nT0+15,  nAX0, aCab[1], oFTit)
    oPrinter:Say(nT0+17,  2005, aCab[4], oFCab)
    oPrinter:Say(nT0+58,  nAX0, aCab[2], oFCab)
    oPrinter:Say(nT0+92,  nAX0, aCab[3], oFCab)
    oPrinter:Line(nT0+128, nAX0, nT0+128, nCX1,, "-1")
    QP2Cen(oPrinter, nT0+144, nAX0, nCX1, "Ticket de Pesagem Nº " + AllTrim(NJH->NJH_CODPAV), oFTk, 44)

    // ============ PAINEL A - DADOS DA OPERAÇÃO ============
    QP2Sec(oPrinter, oFSc, nPT, nAX0, nBcol, nAX1, "DADOS DA OPERAÇÃO")
    nY := nPT + 58
    QP2Kv(oPrinter, oFLb, oFVl, nY, nAX0+22, nAX0+320, "Placa:",     AllTrim(NJH->NJH_PLACA))  ; nY += 60
    QP2Kv(oPrinter, oFLb, oFVl, nY, nAX0+22, nAX0+320, "Operador:",  cOper)                    ; nY += 60
    QP2Kv(oPrinter, oFLb, oFVl, nY, nAX0+22, nAX0+320, "Motorista:", AllTrim(NJH->NJH_NOMMOT)) ; nY += 60
    QP2Kv(oPrinter, oFLb, oFVl, nY, nAX0+22, nAX0+320, "Produto:",   AllTrim(NJH->NJH_DESPRO)) ; nY += 60
    QP2Kv(oPrinter, oFLb, oFVl, nY, nAX0+22, nAX0+320, "Rota:",      AllTrim(NJH->NJH_XROTA))

    // ============ PAINEL B1 - PESOS ============
    QP2Sec(oPrinter, oFSc, nPT, nBX0, nPT+168, nBX1, "PESOS")
    oPrinter:Line(nPT+40, nBX0+nSub,   nPT+168, nBX0+nSub,,   "-1")
    oPrinter:Line(nPT+40, nBX0+nSub*2, nPT+168, nBX0+nSub*2,, "-1")
    oPrinter:Say(nPT+52, nBX0+20,        "Peso Entrada", oFPl)
    oPrinter:Say(nPT+52, nBX0+nSub+20,   "Peso Saída",   oFPl)
    oPrinter:Say(nPT+52, nBX0+nSub*2+20, "Peso Líquido", oFPl)
    QP2Cen(oPrinter, nPT+86,  nBX0,        nBX0+nSub,   Transform(NJH->NJH_PESO1,  "@E 999,999,999"), oFPs, 34)
    QP2Cen(oPrinter, nPT+86,  nBX0+nSub,   nBX0+nSub*2, Transform(NJH->NJH_PESO2,  "@E 999,999,999"), oFPs, 34)
    QP2Cen(oPrinter, nPT+86,  nBX0+nSub*2, nBX0+nSub*3, Transform(NJH->NJH_PSSUBT, "@E 999,999,999"), oFPs, 34)
    QP2Cen(oPrinter, nPT+132, nBX0,        nBX0+nSub,   "KG", oFPl, 16)
    QP2Cen(oPrinter, nPT+132, nBX0+nSub,   nBX0+nSub*2, "KG", oFPl, 16)
    QP2Cen(oPrinter, nPT+132, nBX0+nSub*2, nBX0+nSub*3, "KG", oFPl, 16)

    // ============ PAINEL B2 - FORNECEDOR ============
    QP2Sec(oPrinter, oFSc, nPT+188, nBX0, nBcol, nBX1, "FORNECEDOR")
    QP2Cen(oPrinter, nPT+268, nBX0, nBX1, AllTrim(NJH->NJH_NOMENT), oFVl, 24)

    // ============ PAINEL C1 - HORARIOS ============
    QP2Sec(oPrinter, oFSc, nPT, nCX0, nPT+148, nCX1, "HORÁRIOS")
    QP2Kv(oPrinter, oFSc, oFVl, nPT+54, nCX0+18, nCX0+200, "Entrada:", cDtHrE)
    QP2Kv(oPrinter, oFSc, oFVl, nPT+98, nCX0+18, nCX0+200, "Saída:",   cDtHrS)

    // ============ PAINEL C2 - TIPO DE CARGA ============
    QP2Sec(oPrinter, oFSc, nPT+168, nCX0, nPT+262, nCX1, "TIPO DE CARGA")
    QP2Cen(oPrinter, nPT+214, nCX0, nCX1, AllTrim(NJH->NJH_OBS), oFLb, 18)

    // ============ PAINEL C3 - CLIENTE ============
    QP2Sec(oPrinter, oFSc, nPT+282, nCX0, nBcol, nCX1, "CLIENTE")
    QP2Cen(oPrinter, nPT+330, nCX0, nCX1, cCli, oFLb, 18)

    // ============ OBSERVAÇÃO (largura total) ============
    QP2Sec(oPrinter, oFSc, nBcol, nAX0, nBcol+120, nCX1, "OBSERVAÇÃO")
    QP2Cen(oPrinter, nBcol+68, nAX0, nCX1, AllTrim(NJH->NJH_OBS), oFVl, 24)

    // ============ ASSINATURAS ============
    nY := nBcol + 120 + 56
    oPrinter:Line(nY, 180,  nY, 760,,  "-1")
    oPrinter:Line(nY, 980,  nY, 1560,, "-1")
    oPrinter:Line(nY, 1800, nY, 2380,, "-1")
    QP2Cen(oPrinter, nY+30, 180,  760,  "Operador",  oFAs, 18)
    QP2Cen(oPrinter, nY+30, 980,  1560, "Fiscal",    oFAs, 18)
    QP2Cen(oPrinter, nY+30, 1800, 2380, "Motorista", oFAs, 18)

Return

/*/{Protheus.doc} QP2Sec
Desenha o quadro de um painel: moldura + titulo (sem fundo, sem linha).
@type Static Function
/*/
//=============================================================================
Static Function QP2Sec(oPrinter, oFSc, nT, nL, nB, nR, cTit)
//=============================================================================
    oPrinter:Box(nT, nL, nB, nR)
    oPrinter:Say(nT+9, nL+16, cTit, oFSc)
Return

/*/{Protheus.doc} QP2Kv
Desenha um par rotulo/valor numa linha.
@type Static Function
/*/
//=============================================================================
Static Function QP2Kv(oPrinter, oFLb, oFVl, nY, nLbX, nVlX, cLb, cVl)
//=============================================================================
    oPrinter:Say(nY, nLbX, cLb, oFLb)
    oPrinter:Say(nY, nVlX, cVl, oFVl)
Return

/*/{Protheus.doc} QP2Cen
Escreve um texto horizontalmente centralizado entre nL e nR (largura de
caractere estimada em nCw, especifica da fonte usada).
@type Static Function
/*/
//=============================================================================
Static Function QP2Cen(oPrinter, nY, nL, nR, cTx, oFo, nCw)
//=============================================================================
    Local nW := Len(AllTrim(cTx)) * nCw
    Local nX := nL + Max(0, Int(((nR - nL) - nW) / 2))
    oPrinter:Say(nY, nX, AllTrim(cTx), oFo)
Return

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
	Local cProd     := xParProd()
	Local aTk       := xParTicket()
	Local cTitulo   := "Reimpressao de Tickets - " + cPeriodo + " - " + cCCusto

	If !Empty(cProd)
		cTitulo += " - Produto: " + cProd
	EndIf
	If !Empty(aTk[1]) .Or. (!Empty(aTk[2]) .And. !("ZZZ" $ Upper(aTk[2])))
		cTitulo += " - Ticket: " + aTk[1] + " a " + aTk[2]
	EndIf

	oReport := TReport():New("QPES002", cTitulo, "QPES002", {|oReport| xImpQPES002XLS(oReport)}, "Tickets de Pesagem")
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
