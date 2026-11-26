#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} QMATR107
Termo de Retirada de Material - cópia customizada do relatório padrão MATR107,
descontinuado pela TOTVS (bloqueado pela VldDescRel na release 12.1.2510+).

Impressão gráfica (TMSPrinter), no mesmo modelo do RACOM003: folha A4 retrato,
direto para o preview, sem a tela de opções do TReport (planilha/Excel etc.).

Dois modos de uso:
 - U_QMATR107(cNumSA): imprime o termo da S.A. informada (usado no menu
   da MATA185 via PE MTA185MNU, com a S.A. posicionada). Não abre perguntas.
 - U_QMATR107(cNumSA, aBaixa): chamado logo após a baixa (U_QA185Bx no
   MTA185MNU). Lista só os itens baixados nessa operação, com a quantidade
   baixada agora. aBaixa = {{cItem, nQtdBaixada}, ...}
 - U_QMATR107():       usa as perguntas padrão "MATR107" (SX1), como o original:
       mv_par01 - Número da S.A. (range)
       mv_par02 - Emissão de
       mv_par03 - Emissão até
       mv_par04 - Solicitante (código do usuário)
       mv_par05 - Status (1=Todos / 2=Baix/Ence / 3=Baixar / 4=Gerar / 5=Parcial)

Antes de imprimir, abre uma tela para marcar os itens efetivamente retirados
(nem sempre todos os itens da S.A. são recolhidos).
Um termo por solicitante, cada um em página própria, com o armazém da requisição.

@type User Function
@author Thiago Sales - Quebec Ambiental (baseado no MATR107 - TOTVS)
@since 2026-11-18
@param cNumSA, character, Número da S.A. (opcional)
@param aBaixa, array, Itens/quantidades baixados agora (opcional)
/*/
//=============================================================================================================================

// Layout da folha (A4 retrato - unidades do TMSPrinter)
#DEFINE COL_INI     0100    // margem esquerda
#DEFINE COL_FIM     2300    // margem direita
#DEFINE LIN_ITENS   2450    // limite para impressão de itens (abaixo ficam as assinaturas)
#DEFINE LIN_DATA    2600    // local e data
#DEFINE LIN_NOME    2780    // linhas para o nome (entregou / recebeu)
#DEFINE LIN_ASSIN   2980    // linhas de assinatura
#DEFINE TAM_TEXTO   125     // caracteres por linha da declaração (aumente/diminua para ajustar à largura)
#DEFINE LIN_RODAPE  3150    // rodapé

// Colunas da grade de itens
#DEFINE C_ITEM      0110
#DEFINE C_PROD      0230
#DEFINE C_DESC      0560
#DEFINE C_UM        1480
#DEFINE C_QTD       1830    // alinhado à direita
#DEFINE C_STATUS    1860

// Posições do array de itens (aItens)
#DEFINE I_MARCA     01
#DEFINE I_NUM       02
#DEFINE I_ITEM      03
#DEFINE I_EMISSAO   04
#DEFINE I_SOLICIT   05
#DEFINE I_PRODUTO   06
#DEFINE I_DESCRI    07
#DEFINE I_UM        08
#DEFINE I_QUJE      09
#DEFINE I_STATUS    10
#DEFINE I_LOCAL     11
#DEFINE I_DESCLOC   12

User Function QMATR107(cNumSA, aBaixa)
    Local aArea  := GetArea()
    Local aItens := {}

    Default cNumSA := ""
    Default aBaixa := {}

    cNumSA := AllTrim(cNumSA)

    If Empty(cNumSA)
        If !Pergunte("MATR107", .T.)
            RestArea(aArea)
            Return
        EndIf
    EndIf

    aItens := QCarrega(cNumSA, aBaixa)

    If Empty(aItens)
        Help(NIL, NIL, "QMATR107", NIL, "Nenhuma solicitação ao armazém encontrada.", 1, 0)
    ElseIf QSeleciona(aItens)
        Processa({|| QImprime(aItens)}, "Termo de Retirada", "Gerando o termo...")
    EndIf

    RestArea(aArea)
Return

/*/{Protheus.doc} QCarrega
Busca os itens da(s) S.A.(s) e monta o array usado na seleção e na impressão.
@return array, itens (ver #DEFINE I_*)
/*/
//-------------------------------------------------------------------
Static Function QCarrega(cNumSA, aBaixa)
    Local aItens    := {}
    Local cAliasSCP := GetNextAlias()
    Local cWhere    := ""
    Local aStatus   := {}
    Local nQtd      := 0
    Local nPos      := 0

    If !Empty(cNumSA)
        cWhere := " SCP.CP_NUM = '" + cNumSA + "' "
    Else
        MakeSqlExpr("MATR107")
        If !Empty(mv_par01)
            cWhere += mv_par01 + " AND "
        EndIf
        If !Empty(mv_par04)
            cWhere += " SCP.CP_SOLICIT = '" + UsrRetName(mv_par04) + "' AND "
        EndIf
        cWhere += " SCP.CP_EMISSAO BETWEEN '" + DtoS(mv_par02) + "' AND '" + DtoS(mv_par03) + "' "
    EndIf
    cWhere := "%" + cWhere + "%"

    BeginSql Alias cAliasSCP
        SELECT SCP.CP_NUM, SCP.CP_ITEM, SCP.CP_EMISSAO, SCP.CP_SOLICIT, SCP.CP_PRODUTO,
               SCP.CP_DESCRI, SCP.CP_UM, SCP.CP_LOCAL, SCP.CP_PREREQU, SCP.CP_STATUS,
               SCP.CP_QUANT, SCP.CP_QUJE
          FROM %Table:SCP% SCP
         WHERE SCP.%NotDel%
           AND SCP.CP_FILIAL = %xFilial:SCP%
           AND %Exp:cWhere%
         ORDER BY SCP.CP_SOLICIT, SCP.CP_NUM, SCP.CP_ITEM
    EndSql

    While !(cAliasSCP)->(EOF())
        aStatus := QStatusSA(cAliasSCP)
        nQtd    := (cAliasSCP)->CP_QUJE

        // Chamado após a baixa: só os itens baixados agora, com a quantidade baixada
        If !Empty(aBaixa)
            nPos := aScan(aBaixa, {|x| x[1] == (cAliasSCP)->CP_ITEM})
            If nPos == 0
                (cAliasSCP)->(DbSkip())
                Loop
            EndIf
            nQtd := aBaixa[nPos][2]
        EndIf

        // Filtro de status só se aplica no modo por perguntas
        If !Empty(cNumSA) .Or. Empty(aStatus) .Or. mv_par05 == 1 .Or. mv_par05 == aStatus[2]
            aAdd(aItens, { ;
                .T.                                , ; // I_MARCA
                (cAliasSCP)->CP_NUM                , ; // I_NUM
                (cAliasSCP)->CP_ITEM               , ; // I_ITEM
                StoD((cAliasSCP)->CP_EMISSAO)      , ; // I_EMISSAO
                AllTrim((cAliasSCP)->CP_SOLICIT)   , ; // I_SOLICIT
                AllTrim((cAliasSCP)->CP_PRODUTO)   , ; // I_PRODUTO
                AllTrim((cAliasSCP)->CP_DESCRI)    , ; // I_DESCRI
                (cAliasSCP)->CP_UM                 , ; // I_UM
                nQtd                               , ; // I_QUJE
                IIf(Empty(aStatus), "", aStatus[1]), ; // I_STATUS
                (cAliasSCP)->CP_LOCAL              , ; // I_LOCAL
                AllTrim(Posicione("NNR", 1, xFilial("NNR") + (cAliasSCP)->CP_LOCAL, "NNR_DESCRI")) }) // I_DESCLOC
        EndIf

        (cAliasSCP)->(DbSkip())
    EndDo

    (cAliasSCP)->(DbCloseArea())
Return aItens

/*/{Protheus.doc} QSeleciona
Tela para marcar os itens que estão sendo retirados (todos vêm marcados).
Duplo clique marca/desmarca o item; clique no cabeçalho da 1ª coluna inverte todos.
@return logical, .T. se confirmou com ao menos um item marcado
/*/
//-------------------------------------------------------------------
Static Function QSeleciona(aItens)
    Local oDlg    := NIL
    Local oBrw    := NIL
    Local oOk     := LoadBitmap(GetResources(), "LBOK")
    Local oNo     := LoadBitmap(GetResources(), "LBNO")
    Local lOk     := .F.
    Local aCab    := {" ", "S.A.", "Item", "Produto", "Descrição", "UM", "Qtd. Entregue", "Armazém"}
    Local aTam    := {10, 35, 20, 45, 150, 20, 45, 90}
    Local cPicQtd := PesqPict("SCP", "CP_QUJE")

    DEFINE MSDIALOG oDlg TITLE "Termo de Retirada - marque os itens retirados" FROM 0, 0 TO 500, 1000 PIXEL

    oBrw := TWBrowse():New(5, 5, 490, 210, , aCab, aTam, oDlg, , , , , , , , , , , , .F., , .T., , .F., , , )
    oBrw:SetArray(aItens)
    oBrw:bLine := {|| { ;
        IIf(aItens[oBrw:nAt][I_MARCA], oOk, oNo), ;
        aItens[oBrw:nAt][I_NUM]      , ;
        aItens[oBrw:nAt][I_ITEM]     , ;
        aItens[oBrw:nAt][I_PRODUTO]  , ;
        aItens[oBrw:nAt][I_DESCRI]   , ;
        aItens[oBrw:nAt][I_UM]       , ;
        Transform(aItens[oBrw:nAt][I_QUJE], cPicQtd), ;
        aItens[oBrw:nAt][I_LOCAL] + " - " + aItens[oBrw:nAt][I_DESCLOC] }}
    oBrw:bLDblClick   := {|| aItens[oBrw:nAt][I_MARCA] := !aItens[oBrw:nAt][I_MARCA], oBrw:Refresh()}
    oBrw:bHeaderClick := {|o, nCol| IIf(nCol == 1, QMarcaTodos(aItens, oBrw), NIL)}

    @ 222, 005 BUTTON "Marcar todos"    SIZE 55, 14 PIXEL OF oDlg ACTION QMarcaTodos(aItens, oBrw, .T.)
    @ 222, 065 BUTTON "Desmarcar todos" SIZE 55, 14 PIXEL OF oDlg ACTION QMarcaTodos(aItens, oBrw, .F.)
    @ 222, 380 BUTTON "Imprimir"        SIZE 55, 14 PIXEL OF oDlg ACTION ;
        IIf(aScan(aItens, {|x| x[I_MARCA]}) > 0, (lOk := .T., oDlg:End()), ;
            MsgAlert("Marque ao menos um item para imprimir o termo.", "Termo de Retirada"))
    @ 222, 440 BUTTON "Cancelar"        SIZE 55, 14 PIXEL OF oDlg ACTION oDlg:End()

    ACTIVATE MSDIALOG oDlg CENTERED
Return lOk

//-------------------------------------------------------------------
// Marca (lMarca = .T.), desmarca (.F.) ou inverte (NIL) todos os itens
Static Function QMarcaTodos(aItens, oBrw, lMarca)
    aEval(aItens, {|x| x[I_MARCA] := IIf(lMarca == NIL, !x[I_MARCA], lMarca)})
    oBrw:Refresh()
Return

//-------------------------------------------------------------------
Static Function QImprime(aItens)
    Local cSolic := ""
    Local aTermo := {}
    Local nLin   := 0
    Local nX     := 0
    Local nY     := 0

    Private oPrint   := NIL
    Private cLogo    := ""
    Private oFont10  := TFont():New("Tahoma", 10, 10, , .F., , , , .T., .F.)
    Private oFont11  := TFont():New("Tahoma", 11, 11, , .F., , , , .T., .F.)
    Private oFont12  := TFont():New("Tahoma", 12, 12, , .F., , , , .T., .F.)
    Private oFont12n := TFont():New("Tahoma", 12, 12, , .T., , , , .T., .F.)
    Private oFont13n := TFont():New("Tahoma", 13, 13, , .T., , , , .T., .F.)
    Private oFont14  := TFont():New("Tahoma", 14, 14, , .F., , , , .T., .F.)
    Private oFont14n := TFont():New("Tahoma", 14, 14, , .T., , , , .T., .F.)
    Private oFont20n := TFont():New("Arial" , 20, 20, , .T., , , , .T., .F.)

    ProcRegua(Len(aItens))

    oPrint := TMSPrinter():New("Termo de Retirada")
    oPrint:SetPortrait()
    oPrint:Setup()

    // Logo da empresa (mesma regra do RACOM003)
    cLogo := "lgrl" + cEmpAnt + ".bmp"
    If !File(cLogo)
        cLogo := "lgrl" + cEmpAnt + cFilAnt + ".bmp"
    EndIf

    SM0->(DbSetOrder(1))
    SM0->(DbSeek(cEmpAnt + cFilAnt))

    // Um termo por solicitante (aItens já vem ordenado por solicitante), só com os itens marcados
    nX := 1
    While nX <= Len(aItens)
        cSolic := aItens[nX][I_SOLICIT]
        aTermo := {}
        While nX <= Len(aItens) .And. aItens[nX][I_SOLICIT] == cSolic
            IncProc()
            If aItens[nX][I_MARCA]
                aAdd(aTermo, aItens[nX])
            EndIf
            nX++
        EndDo

        If Empty(aTermo)
            Loop
        EndIf

        nLin := QNovaPag(aTermo, .T.)

        For nY := 1 To Len(aTermo)
            If nLin > LIN_ITENS
                QRodape()
                oPrint:EndPage()
                nLin := QNovaPag(aTermo, .F.)
            EndIf

            oPrint:Say(nLin, C_ITEM  , aTermo[nY][I_ITEM]               , oFont12)
            oPrint:Say(nLin, C_PROD  , aTermo[nY][I_PRODUTO]            , oFont12)
            oPrint:Say(nLin, C_DESC  , Left(aTermo[nY][I_DESCRI], 40)   , oFont11)
            oPrint:Say(nLin, C_UM    , aTermo[nY][I_UM]                 , oFont12)
            oPrint:Say(nLin, C_QTD   , AllTrim(Transform(aTermo[nY][I_QUJE], PesqPict("SCP", "CP_QUJE"))), oFont12, , , , 1)
            oPrint:Say(nLin, C_STATUS, aTermo[nY][I_STATUS]             , oFont10)

            nLin += 60
            oPrint:Line(nLin, COL_INI, nLin, COL_FIM)
            nLin += 20
        Next nY

        // Assinaturas sempre na página final do termo
        If nLin > LIN_ITENS
            QRodape()
            oPrint:EndPage()
            QNovaPag(aTermo, .F., .F.)
        EndIf
        QAssinaturas()
        QRodape()
        oPrint:EndPage()
    EndDo

    oPrint:Preview()
Return

/*/{Protheus.doc} QNovaPag
Inicia uma página: cabeçalho, dados da S.A./armazém e declaração (só na primeira
página do termo) e cabeçalho da grade de itens.
@return numeric, linha onde começam os itens
/*/
//-------------------------------------------------------------------
Static Function QNovaPag(aTermo, lDeclara, lGrade)
    Local nLin    := 0
    Local cTexto  := ""
    Local cArmaz  := ""
    Local nLinhas := 0
    Local nX      := 0

    Default lGrade := .T.

    oPrint:StartPage()
    nLin := QCabec()

    If lDeclara
        // Dados da S.A.
        oPrint:Say(nLin, COL_INI, "S.A. Nº: "     + aTermo[1][I_NUM], oFont14n)
        oPrint:Say(nLin, 0750   , "Emissão: "     + DtoC(aTermo[1][I_EMISSAO]), oFont14)
        oPrint:Say(nLin, 1400   , "Solicitante: " + aTermo[1][I_SOLICIT], oFont14)
        nLin += 90

        // Armazém(ns) da requisição - normalmente um só; se houver mais de um, lista todos
        For nX := 1 To Len(aTermo)
            If !(aTermo[nX][I_LOCAL] $ cArmaz)
                cArmaz += IIf(Empty(cArmaz), "", "  /  ") + aTermo[nX][I_LOCAL] + " - " + aTermo[nX][I_DESCLOC]
            EndIf
        Next nX
        oPrint:Say(nLin, COL_INI, "Armazém: " + cArmaz, oFont14)
        nLin += 130

        // Declaração
        cTexto := "Declaro, para os devidos fins, que recebi os itens discriminados abaixo na presente " + ;
                  "data, em condições adequadas para utilização."
        nLinhas := MlCount(cTexto, TAM_TEXTO)
        For nX := 1 To nLinhas
            oPrint:Say(nLin, COL_INI, MemoLine(cTexto, TAM_TEXTO, nX), oFont14)
            nLin += 75
        Next nX
        nLin += 60
    EndIf

    If lGrade
        oPrint:Box(nLin, COL_INI, nLin + 80, COL_FIM)
        oPrint:Say(nLin + 15, C_ITEM  , "Item"       , oFont12n)
        oPrint:Say(nLin + 15, C_PROD  , "Produto"    , oFont12n)
        oPrint:Say(nLin + 15, C_DESC  , "Descrição"  , oFont12n)
        oPrint:Say(nLin + 15, C_UM    , "UM"         , oFont12n)
        oPrint:Say(nLin + 15, C_QTD   , "Quantidade", oFont12n, , , , 1)
        oPrint:Say(nLin + 15, C_STATUS, "Status"     , oFont12n)
        nLin += 110
    EndIf
Return nLin

/*/{Protheus.doc} QCabec
Cabeçalho com logo e dados da empresa.
@return numeric, próxima linha livre
/*/
//-------------------------------------------------------------------
Static Function QCabec()
    oPrint:SayBitmap(050, COL_INI, cLogo, 500, 250)

    oPrint:Say(060, 0700, AllTrim(Upper(SM0->M0_NOMECOM)), oFont13n)
    oPrint:Say(130, 0700, AllTrim(SM0->M0_ENDCOB), oFont11)
    oPrint:Say(180, 0700, Capital(AllTrim(SM0->M0_CIDCOB)) + "/" + AllTrim(SM0->M0_ESTCOB) + "  -  " + ;
        AllTrim(Transform(SM0->M0_CEPCOB, "@R 99.999-999")), oFont11)
    oPrint:Say(230, 0700, "CNPJ: " + Transform(SM0->M0_CGC, "@R 99.999.999/9999-99") + ;
        "     I.E.: " + AllTrim(SM0->M0_INSC), oFont11)

    oPrint:Line(330, COL_INI, 330, COL_FIM)
    oPrint:Say(370, (COL_INI + COL_FIM) / 2, "TERMO DE RETIRADA DE MATERIAL", oFont20n, , , , 2)
    oPrint:Line(470, COL_INI, 470, COL_FIM)
Return 530

/*/{Protheus.doc} QAssinaturas
Local/data e campos de assinatura, fixos no pé da folha.
/*/
//-------------------------------------------------------------------
Static Function QAssinaturas()
    oPrint:Say(LIN_DATA, COL_INI, Capital(AllTrim(SM0->M0_CIDENT)) + ", " + cValToChar(Day(dDataBase)) + ;
        " de " + MesExtenso(dDataBase) + " de " + cValToChar(Year(dDataBase)) + ".", oFont14)

    // Esquerda: quem entregou / Direita: quem recebeu
    oPrint:Say(LIN_NOME - 90, 0150, "ENTREGUE POR:", oFont14n)
    oPrint:Say(LIN_NOME - 90, 1350, "RECEBIDO POR:", oFont14n)

    oPrint:Line(LIN_NOME, 0150, LIN_NOME, 1050)
    oPrint:Line(LIN_NOME, 1350, LIN_NOME, 2250)
    oPrint:Say(LIN_NOME + 20, 0600, "Nome", oFont12, , , , 2)
    oPrint:Say(LIN_NOME + 20, 1800, "Nome", oFont12, , , , 2)

    oPrint:Line(LIN_ASSIN, 0150, LIN_ASSIN, 1050)
    oPrint:Line(LIN_ASSIN, 1350, LIN_ASSIN, 2250)
    oPrint:Say(LIN_ASSIN + 20, 0600, "Assinatura", oFont12, , , , 2)
    oPrint:Say(LIN_ASSIN + 20, 1800, "Assinatura", oFont12, , , , 2)
Return

/*/{Protheus.doc} QRodape
Rodapé com data/hora de emissão.
/*/
//-------------------------------------------------------------------
Static Function QRodape()
    oPrint:Line(LIN_RODAPE, COL_INI, LIN_RODAPE, COL_FIM)
    oPrint:Say(LIN_RODAPE + 20, COL_INI, "QMATR107", oFont10)
    oPrint:Say(LIN_RODAPE + 20, (COL_INI + COL_FIM) / 2, "Microsiga Protheus", oFont10, , , , 2)
    oPrint:Say(LIN_RODAPE + 20, COL_FIM, DtoC(Date()) + " " + Time(), oFont10, , , , 1)
Return

/*/{Protheus.doc} QStatusSA
Retorna o status da S.A. (cópia da ScPStatus do MATR107).
@return array, {cDescricao, nCodigo} ou {} se não identificado
/*/
//-------------------------------------------------------------------
Static Function QStatusSA(cAli)
    Local lStatus := !Empty((cAli)->CP_STATUS)
    Local lPreReq := (cAli)->CP_PREREQU == "S"
    Local nQuant  := QtdComp((cAli)->CP_QUANT)
    Local nQuje   := QtdComp((cAli)->CP_QUJE)

    If lStatus .And. lPreReq .And. nQuant >= nQuje
        Return {"Pré Req. Baix/Ence", 2}
    ElseIf !lStatus .And. lPreReq .And. nQuje == QtdComp(0)
        Return {"Baixar Pré Req", 3}
    ElseIf !lStatus .And. Empty((cAli)->CP_PREREQU)
        Return {"Gerar Pré Req", 4}
    ElseIf !lStatus .And. lPreReq .And. nQuje > QtdComp(0)
        Return {"Parc. Baixada", 5}
    EndIf
Return {}
