#include "Protheus.ch"

/*
=============================================================================
Programa  : M110STTS - Ponto de entrada apos a gravacao da SC
Descricao : Libera automaticamente a Solicitacao de Compra (C1_APROV = L)
            apos a validacao do MT110TOK (Centro de Custo informado).
=============================================================================
*/
User Function M110STTS()
	Local cNumSC  := ParamIXB[1] // Numero da SC
	Local nOpc    := ParamIXB[2] // 1=Inclusao, 2=Alteracao, 3=Exclusao
	Local aArea   := GetArea()
	Local aAreaC1 := SC1->(GetArea())

	// Executa apenas na Inclusao ou Alteracao
	If nOpc == 1 .Or. nOpc == 2
		DbSelectArea("SC1")
		SC1->(DbSetOrder(1)) // C1_FILIAL + C1_NUM + C1_ITEM
		If SC1->(DbSeek(xFilial("SC1") + cNumSC))
			While !SC1->(Eof()) .And. SC1->C1_FILIAL == xFilial("SC1") .And. SC1->C1_NUM == cNumSC
				// Condicao: so libera o item validado (com Centro de Custo) e que ainda nao esteja liberado
				If !Empty(SC1->C1_CC) .And. SC1->C1_APROV <> "L"
					RecLock("SC1", .F.)
					SC1->C1_APROV := "L" // L = Liberada | B = Bloqueada | R = Rejeitada
					SC1->(MsUnlock())
				EndIf
				SC1->(DbSkip())
			EndDo
		EndIf
	EndIf

	RestArea(aAreaC1)
	RestArea(aArea)
Return Nil
