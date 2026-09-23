#Include "Protheus.ch"

/*----------------------------------------------------------------------
- Programa: M185GRV
- Autor: Adriano Costa
- Data: 02/12/2020
- Descrição: Ponto de Entrada apos a baixa da requisição ao armazem
------------------------------------------------------------------------*/

User Function M185GRV()

Local aArea 	:= GetArea()
Local aAreaSCP 	:= SCP->(GetArea())
Local aItensSA  :=  {}


If !Empty(SCP->CP_OP)
    AADD(aItensSA,{SubStr(SCP->CP_OP,1,6),SCP->CP_PRODUTO,Posicione("SB1",1,xFilial("SB1")+SCP->CP_PRODUTO,"B1_DESC"),SD3->D3_QUANT})
EndIf

// Envia e-mail quando houver OS
If Len(aItensSA) > 0
    //U_WfMailOS(aItensSA,"SA")
EndIf

RestArea(aAreaSCP)
RestArea(aArea)

Return()
