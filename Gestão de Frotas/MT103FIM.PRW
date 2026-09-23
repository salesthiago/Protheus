#Include "Protheus.ch"

/*----------------------------------------------------------------------
- Programa: MT103FIM
- Autor: Adriano Costa, Rafael Brito
- Data: 02/12/2020
- Descrição: Operação após gravação da NFE, rotina MATA103.
            Chama a rotina  de impressão apos a classificação da Nf.
------------------------------------------------------------------------*/

User Function MT103FIM()

Local aArea 	:= GetArea()
Local aAreaSD1 	:= SD1->(GetArea())
Local aAreaSA2 	:= SA2->(GetArea())
Local aAreaSB1 	:= SB1->(GetArea())
Local aAreaSC7 	:= SC7->(GetArea())
Local aAreaSC1 	:= SC1->(GetArea())
Local nOpcao 	:= PARAMIXB[1]   // Opção Escolhida pelo usuario no aRotina 
Local nConfirma := PARAMIXB[2]   // Se o usuario confirmou a operação de gravação da NFECODIGO DE APLICAÇÃO DO USUARIO
Local aItensNF  :=  {}

// se foi confirmada a operação
if nConfirma == 1
    SC7->(DbSetOrder(1))
    SC1->(DbSetOrder(1))
	// apenas na operação de inclusão ou classificação
	if Alltrim(funName()) == "MATA103" .And. (nOpcao == 3 .OR. nOpcao == 4)
		SD1->(DbSetOrder(1)) 
        If SD1->(DbSeek(xFilial("SD1")+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA)) 
            While SD1->(!Eof()) .and. SD1->(D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA) == ;
                                xFilial("SD1")+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA

                If SC7->(DbSeek(xFilial("SC7")+SD1->D1_PEDIDO+SD1->D1_ITEMPC))
                    If SC1->(DbSeek(xFilial("SC1")+SC7->C7_NUMSC+SC7->C7_ITEMSC))
                        If !Empty(SC1->C1_OP)
                            AADD(aItensNF,{SubStr(SC1->C1_OP,1,6),SD1->D1_COD,Posicione("SB1",1,xFilial("SB1")+SD1->D1_COD,"B1_DESC"),SD1->D1_QUANT})
                        EndIf
                    EndIf
                EndIf
                SD1->(DbSkip())
            EndDo
        EndIf
        
        // Envia e-mail quando houver OS
		If Len(aItensNF) > 0
            //U_WfMailOS(aItensNF,"SC")
        EndIf
	
	endif

endif

RestArea(aAreaSD1)
RestArea(aAreaSA2)
RestArea(aAreaSB1)
RestArea(aAreaSC7)
RestArea(aAreaSC1)
RestArea(aArea)

Return()
