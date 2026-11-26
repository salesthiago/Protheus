#INCLUDE "FIVEWIN.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "APWIZARD.CH"
#INCLUDE "FILEIO.CH"
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"
#INCLUDE "TOTVS.CH"
#INCLUDE "PARMTYPE.CH"
#Include "RWMAKE.CH"

/*/{Protheus.doc} QPES001
Ticket de Pesagem (tabela NJH) - unidade Paracatu / MG.

Layout em blocos (DADOS DA OPERAÇÃO / PESOS / HORARIOS / FORNECEDOR /
TIPO DE CARGA / CLIENTE / OBSERVAÇÃO), com moldura por via.

As 4 vias sao impressas na MESMA folha A4 (uma pagina), empilhadas.
A NJH deve estar posicionada pelo chamador (browse de pesagens).
@type User Function
/*/
//=============================================================================
User Function QPES001()
//=============================================================================

    Local oPrinter := Nil
    Local lEnd     := .T.

    cCaminho := GetTempPath()
    cFile    := cCaminho + "/" + "QPES001" + ".rel"

    oPrinter := tNewMSPrinter():New("Ticket de Pesagem")
    oPrinter:SetPortrait()
    oPrinter:SetPaperSize(10)
    oPrinter:setup()

    RptStatus({|lEnd| QPES001I(@lEnd, cFile, @oPrinter)}, "Imprimindo Relatorio...")

    FreeObj(oPrinter)
    oPrinter := Nil

Return Nil

/*/{Protheus.doc} QPES001I
Monta a pagina unica com as 4 vias do ticket.
@type Static Function
/*/
//=============================================================================
Static Function QPES001I(lEnd, cIdent, oPrinter)
//=============================================================================
    Local nVia  := 0
    Local nVias := 4
    Local nBase := 20
    Local nStep := 832
    Local cOper := AllTrim(NJH->NJH_XUSER)
    Local cCli  := If(NJH->NJH_CODENT $ '001575-001587', 'PREFEITURA', AllTrim(NJH->NJH_XCLIEN))

    Private oFTit := TFont():New('Arial',,15,.T.,.T.)
    Private oFCab := TFont():New('Arial',,09,.T.)
    Private oFTk  := TFont():New('Arial',,21,.T.,.T.)
    Private oFSc  := TFont():New('Arial',,10,.T.,.T.)
    Private oFLb  := TFont():New('Arial',,13,.T.)
    Private oFVl  := TFont():New('Arial',,13,.T.,.T.)
    Private oFPs  := TFont():New('Arial',,17,.T.,.T.)
    Private oFPl  := TFont():New('Arial',,09,.T.)
    Private oFAs  := TFont():New('Arial',,12,.T.,.T.)

    If lEnd
        oPrinter:StartPage()
        oPrinter:Say(120, 120, "Cancelado pelo Operador", oFVl)
        oPrinter:EndPage()
        oPrinter:Print()
        Return
    EndIf

    oPrinter:StartPage()

    For nVia := 1 To nVias
        QP1Via(oPrinter, nBase + (nVia - 1) * nStep, cOper, cCli)
    Next nVia

    oPrinter:EndPage()

    oPrinter:Preview()
    oPrinter:end()

Return

/*/{Protheus.doc} QP1Via
Desenha uma via completa do ticket a partir da linha nT0.
@type Static Function
/*/
//=============================================================================
Static Function QP1Via(oPrinter, nT0, cOper, cCli)
//=============================================================================
    Local nAX0  := 40
    Local nAX1  := 1080
    Local nBX0  := 1105
    Local nBX1  := 1740
    Local nCX0  := 1765
    Local nCX1  := 2460
    Local nSub  := 211
    Local nPT   := nT0 + 210
    Local nBcol := nPT + 370
    Local nY    := 0
    Local cDtHrE := DtoC(NJH->NJH_DATPS1) + "  " + AllTrim(NJH->NJH_HORPS1)
    Local cDtHrS := DtoC(NJH->NJH_DATPS2) + "  " + AllTrim(NJH->NJH_HORPS2)

    // -------- moldura externa da via --------
    oPrinter:Box(nT0, 15, nT0 + 820, 2485)

    // -------- cabecalho da unidade --------
    oPrinter:Say(nT0+15,  nAX0, "ATERRO SANITÁRIO MUNICIPAL DE PARACATU - MG", oFTit)
    oPrinter:Say(nT0+17,  2005, "PARACATU / MG",                               oFCab)
    oPrinter:Say(nT0+58,  nAX0, "CNPJ: 18.278.051/0001-45",                    oFCab)
    oPrinter:Say(nT0+92,  nAX0, "Fazenda Varzea do Moinho, Rodovia de acesso a Entre Ribeiros, nº S/N", oFCab)
    oPrinter:Line(nT0+128, nAX0, nT0+128, nCX1,, "-1")
    QP1Cen(oPrinter, nT0+144, nAX0, nCX1, "Ticket de Pesagem Nº " + AllTrim(NJH->NJH_CODPAV), oFTk, 44)

    // ============ PAINEL A - DADOS DA OPERAÇÃO ============
    QP1Sec(oPrinter, oFSc, nPT, nAX0, nBcol, nAX1, "DADOS DA OPERAÇÃO")
    nY := nPT + 58
    QP1Kv(oPrinter, oFLb, oFVl, nY, nAX0+22, nAX0+320, "Placa:",     AllTrim(NJH->NJH_PLACA))  ; nY += 60
    QP1Kv(oPrinter, oFLb, oFVl, nY, nAX0+22, nAX0+320, "Operador:",  cOper)                    ; nY += 60
    QP1Kv(oPrinter, oFLb, oFVl, nY, nAX0+22, nAX0+320, "Motorista:", AllTrim(NJH->NJH_NOMMOT)) ; nY += 60
    QP1Kv(oPrinter, oFLb, oFVl, nY, nAX0+22, nAX0+320, "Produto:",   AllTrim(NJH->NJH_DESPRO)) ; nY += 60
    QP1Kv(oPrinter, oFLb, oFVl, nY, nAX0+22, nAX0+320, "Rota:",      AllTrim(NJH->NJH_XROTA))

    // ============ PAINEL B1 - PESOS ============
    QP1Sec(oPrinter, oFSc, nPT, nBX0, nPT+168, nBX1, "PESOS")
    oPrinter:Line(nPT+40, nBX0+nSub,   nPT+168, nBX0+nSub,,   "-1")
    oPrinter:Line(nPT+40, nBX0+nSub*2, nPT+168, nBX0+nSub*2,, "-1")
    oPrinter:Say(nPT+52, nBX0+20,        "Peso Entrada", oFPl)
    oPrinter:Say(nPT+52, nBX0+nSub+20,   "Peso Saída",   oFPl)
    oPrinter:Say(nPT+52, nBX0+nSub*2+20, "Peso Líquido", oFPl)
    QP1Cen(oPrinter, nPT+86,  nBX0,        nBX0+nSub,   Transform(NJH->NJH_PESO1,  "@E 999,999,999"), oFPs, 34)
    QP1Cen(oPrinter, nPT+86,  nBX0+nSub,   nBX0+nSub*2, Transform(NJH->NJH_PESO2,  "@E 999,999,999"), oFPs, 34)
    QP1Cen(oPrinter, nPT+86,  nBX0+nSub*2, nBX0+nSub*3, Transform(NJH->NJH_PSSUBT, "@E 999,999,999"), oFPs, 34)
    QP1Cen(oPrinter, nPT+132, nBX0,        nBX0+nSub,   "KG", oFPl, 16)
    QP1Cen(oPrinter, nPT+132, nBX0+nSub,   nBX0+nSub*2, "KG", oFPl, 16)
    QP1Cen(oPrinter, nPT+132, nBX0+nSub*2, nBX0+nSub*3, "KG", oFPl, 16)

    // ============ PAINEL B2 - FORNECEDOR ============
    QP1Sec(oPrinter, oFSc, nPT+188, nBX0, nBcol, nBX1, "FORNECEDOR")
    QP1Cen(oPrinter, nPT+268, nBX0, nBX1, AllTrim(NJH->NJH_NOMENT), oFVl, 24)

    // ============ PAINEL C1 - HORARIOS ============
    QP1Sec(oPrinter, oFSc, nPT, nCX0, nPT+148, nCX1, "HORÁRIOS")
    QP1Kv(oPrinter, oFSc, oFVl, nPT+54, nCX0+18, nCX0+200, "Entrada:", cDtHrE)
    QP1Kv(oPrinter, oFSc, oFVl, nPT+98, nCX0+18, nCX0+200, "Saída:",   cDtHrS)

    // ============ PAINEL C2 - TIPO DE CARGA ============
    QP1Sec(oPrinter, oFSc, nPT+168, nCX0, nPT+262, nCX1, "TIPO DE CARGA")
    QP1Cen(oPrinter, nPT+214, nCX0, nCX1, AllTrim(NJH->NJH_OBS), oFLb, 18)

    // ============ PAINEL C3 - CLIENTE ============
    QP1Sec(oPrinter, oFSc, nPT+282, nCX0, nBcol, nCX1, "CLIENTE")
    QP1Cen(oPrinter, nPT+330, nCX0, nCX1, cCli, oFLb, 18)

    // ============ OBSERVAÇÃO (largura total) ============
    QP1Sec(oPrinter, oFSc, nBcol, nAX0, nBcol+120, nCX1, "OBSERVAÇÃO")
    QP1Cen(oPrinter, nBcol+68, nAX0, nCX1, AllTrim(NJH->NJH_OBS), oFVl, 24)

    // ============ ASSINATURAS ============
    nY := nBcol + 120 + 56
    oPrinter:Line(nY, 180,  nY, 760,,  "-1")
    oPrinter:Line(nY, 980,  nY, 1560,, "-1")
    oPrinter:Line(nY, 1800, nY, 2380,, "-1")
    QP1Cen(oPrinter, nY+30, 180,  760,  "Operador",  oFAs, 18)
    QP1Cen(oPrinter, nY+30, 980,  1560, "Fiscal",    oFAs, 18)
    QP1Cen(oPrinter, nY+30, 1800, 2380, "Motorista", oFAs, 18)

Return

/*/{Protheus.doc} QP1Sec
Desenha o quadro de um painel: moldura + titulo (sem fundo, sem linha).
@type Static Function
/*/
//=============================================================================
Static Function QP1Sec(oPrinter, oFSc, nT, nL, nB, nR, cTit)
//=============================================================================
    oPrinter:Box(nT, nL, nB, nR)
    oPrinter:Say(nT+9, nL+16, cTit, oFSc)
Return

/*/{Protheus.doc} QP1Kv
Desenha um par rotulo/valor numa linha.
@type Static Function
/*/
//=============================================================================
Static Function QP1Kv(oPrinter, oFLb, oFVl, nY, nLbX, nVlX, cLb, cVl)
//=============================================================================
    oPrinter:Say(nY, nLbX, cLb, oFLb)
    oPrinter:Say(nY, nVlX, cVl, oFVl)
Return

/*/{Protheus.doc} QP1Cen
Escreve um texto horizontalmente centralizado entre nL e nR (largura de
caractere estimada em nCw, especifica da fonte usada).
@type Static Function
/*/
//=============================================================================
Static Function QP1Cen(oPrinter, nY, nL, nR, cTx, oFo, nCw)
//=============================================================================
    Local nW := Len(AllTrim(cTx)) * nCw
    Local nX := nL + Max(0, Int(((nR - nL) - nW) / 2))
    oPrinter:Say(nY, nX, AllTrim(cTx), oFo)
Return
