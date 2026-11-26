#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"

// Ação original da opção "Baixar" da MATA185 (guardada para o U_QA185Bx chamá-la)
Static cA185Bx := ""

/*/{Protheus.doc} MTA185MNU
Ponto de Entrada do menu funcional da MATA185 (Baixa de Pré-Requisições).

1) A TOTVS descontinuou o relatório padrão MATR107 (Termo de Retirada) - ele é
   bloqueado pela VldDescRel a partir da release 12.1.2510.
   A opção "Termo de Retirada" do menu passa a chamar a cópia customizada
   U_QMATR107, imprimindo o termo da S.A. posicionada no browse.

2) A opção "Baixar" passa a chamar U_QA185Bx, que executa a baixa padrão e,
   ao final, pergunta se deseja imprimir o Termo de Retirada dos itens baixados.

aRotina é Private, criada pela MenuDef da MATA185.

@type User Function
@author Thiago Sales - Quebec Ambiental
@since 2026-11-18
/*/
//=============================================================================================================================
User Function MTA185MNU()
    Local cAcao  := "U_QMATR107(SCP->CP_NUM)"
    Local nPos   := 0

    If Type("aRotina") <> "A"
        Return
    EndIf

    // Procura a opção padrão "Termo de Retirada" para substituir a ação.
    // Na release atual a ação padrão é "A185Termo" (que chama o MATR107); em releases antigas, "MATR107".
    nPos := aScan(aRotina, {|x| ValType(x[2]) == "C" .And. ;
        ("A185TERMO" $ Upper(x[2]) .Or. "MATR107" $ Upper(x[2]))})

    If nPos > 0
        aRotina[nPos][1] := "Imp Termo de Ret"
        aRotina[nPos][2] := cAcao
    Else
        aAdd(aRotina, {"Imp Termo de Ret", cAcao, 0, 2, 0, NIL})
    EndIf

    // Opção "Baixar": guarda a ação padrão e troca pelo envelope U_QA185Bx.
    // ATENÇÃO: localizada pelo texto da opção. Se não funcionar, confira no debug
    // o aRotina[n][1]/[2] da opção de baixa e ajuste a condição abaixo.
    nPos := aScan(aRotina, {|x| ValType(x[1]) == "C" .And. ValType(x[2]) == "C" .And. ;
        "BAIX" $ Upper(x[1]) .And. !("ESTOR" $ Upper(x[1]))})

    If nPos > 0 .And. !("QA185BX" $ Upper(aRotina[nPos][2]))
        cA185Bx := AllTrim(aRotina[nPos][2])
        aRotina[nPos][2] := "U_QA185Bx"     // sem parênteses: o browse repassa cAlias, nReg, nOpc
    EndIf

Return

/*/{Protheus.doc} QA185Bx
Envelope da baixa de pré-requisição: executa a baixa padrão e, se algum item
da S.A. foi baixado, pergunta se deseja imprimir o Termo de Retirada.
O termo lista só os itens baixados nessa operação, com a quantidade baixada agora
(diferença do CP_QUJE antes x depois da baixa).

Roda fora da transação da baixa (depois que a rotina padrão terminou), então
a pergunta e o preview não prendem registros.

@type User Function
@author Thiago Sales - Quebec Ambiental
@since 2026-11-25
/*/
//=============================================================================================================================
User Function QA185Bx(cAlias, nReg, nOpc)
    Local aArea   := GetArea()
    Local cNumSA  := ""
    Local aAntes  := {}
    Local aDepois := {}
    Local aBaixa  := {}
    Local bBaixa  := NIL
    Local nX      := 0
    Local nPos    := 0
    Local nDif    := 0

    If Empty(cA185Bx)
        Help(NIL, NIL, "QA185BX", NIL, "Ação padrão de baixa não identificada no menu da MATA185.", 1, 0)
        Return
    EndIf

    If ValType(nReg) == "N" .And. nReg > 0
        SCP->(DbGoTo(nReg))
    EndIf
    cNumSA := SCP->CP_NUM

    // Quantidade já atendida de cada item, antes da baixa
    aAntes := QQujeSA(cNumSA)

    // Executa a baixa padrão com os mesmos parâmetros recebidos do browse
    If "(" $ cA185Bx
        &(cA185Bx)
    Else
        bBaixa := &("{|a, b, c| " + cA185Bx + "(a, b, c)}")
        Eval(bBaixa, cAlias, nReg, nOpc)
    EndIf

    // Compara depois da baixa: o que aumentou foi baixado agora
    aDepois := QQujeSA(cNumSA)
    For nX := 1 To Len(aDepois)
        nPos := aScan(aAntes, {|x| x[1] == aDepois[nX][1]})
        nDif := aDepois[nX][2] - IIf(nPos > 0, aAntes[nPos][2], 0)
        If nDif > 0
            aAdd(aBaixa, {aDepois[nX][1], nDif})
        EndIf
    Next nX

    // Nada baixado (cancelou ou não confirmou): não pergunta
    If !Empty(aBaixa) .And. MsgYesNo("Deseja imprimir o Termo de Retirada dos itens baixados?", "Termo de Retirada")
        U_QMATR107(cNumSA, aBaixa)
    EndIf

    RestArea(aArea)
Return

/*/{Protheus.doc} QQujeSA
Retorna a quantidade atendida (CP_QUJE) de cada item da S.A.
@return array, {{cItem, nQuje}, ...}
/*/
//-------------------------------------------------------------------
Static Function QQujeSA(cNumSA)
    Local aRet     := {}
    Local aAreaSCP := SCP->(GetArea())

    SCP->(DbSetOrder(1)) // CP_FILIAL + CP_NUM + CP_ITEM
    SCP->(DbSeek(xFilial("SCP") + cNumSA))
    While !SCP->(EOF()) .And. SCP->CP_FILIAL == xFilial("SCP") .And. SCP->CP_NUM == cNumSA
        aAdd(aRet, {SCP->CP_ITEM, SCP->CP_QUJE})
        SCP->(DbSkip())
    EndDo

    RestArea(aAreaSCP)
Return aRet
