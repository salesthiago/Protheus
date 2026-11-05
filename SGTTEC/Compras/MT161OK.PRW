/*
Ponto de Entrada para validar os preços antes de confirmar a cotação e gerar o pedido

*/

#INCLUDE "PROTHEUS.CH"

User Function MT161OK()

    Local lRetorno  := .F.
    Local aPropPE   := PARAMIXB[1]
   // Local cTpDocPE  := PARAMIXB[2]
    Local nIt       := 1

    for nIt := 1 to len(aPropPE)
                    
        if aPropPE[nIt][1][2][1][1]
            cProduto    := aPropPE[nIt][1][2][1][03]
            nValor      := aPropPE[nIt][1][2][1][13]
            nRegSC8     := aPropPE[nIt][1][2][1][9]
            nRegAtua    :=  SC8->(Recno())

            SC8->(DbGoTo(nRegSC8))
            if SC1->(dbSeek(SC8->(C8_FILIAL+C8_NUMSC+C8_ITEMSC)))
                cCC := SC1->C1_CC
            else
                cCC := ""
            endif

            SC8->(DbGoTo(nRegAtua))

            if SZB->(DbSeek(xfilial("SZB")+cProduto + cCC))
                if (nValor >= SZB->ZB_VALORI  .and. nValor <= SZB->ZB_VALORF) .or. nValor < SZB->ZB_VALORI
                    lRetorno := .T.
                else
                    MSGINFO( "Valor da Cotação divergente do Cadastrado como Referência", "Atenção" )
                    lRetorno := .F.
                endif
            else
                MSGINFO( "Valor de referência não Cadastrado", "Atenção" )
                lRetorno := .F.

            endif

        endif

    next 

Return( lRetorno)

//CABEÇALHO DA PROPOSTA//
//aArray[n]         : Número da página
//aArray[n,p]       : Posição do pedido na página (1,2)
//aArray[n,p,1,x]   : Dados do cabeçalho da proposta 
//aArray[n,p,1,1 ]  : Cod Fornecedor 
//aArray[n,p,1,2 ]  : Loja 
//aArray[n,p,1,3 ]  : Nome 
//aArray[n,p,1,4 ]  : Proposta 
//aArray[n,p,1,5 ]  : Condição de pagamento 
//aArray[n,p,1,6 ]  : Frete 
//aArray[n,p,1,7 ]  : Valor total da proposta

//ITENS DA PROPOSTA// 
//aArray[n,p,2,x]       : Itens da proposta 
//aArray[n,p,2,x,1]     : Flag vencedor normal
//aArray[n,p,2,x,2]     : Item da cotação (C8_ITEM)
//aArray[n,p,2,x,3]     : Código do produto 
//aArray[n,p,2,x,4]     : Valor total
//aArray[n,p,2,x,5]     : Data de entrega
//aArray[n,p,2,x,6]     : Observações (C8_OBS)
//aArray[n,p,2,x,7]     : Filial Entrega (C8_FILENT)
//aArray[n,p,2,x,8]     : Flag finalizado 
//aArray[n,p,2,x,9]     : Recno SC8 
//aArray[n,p,2,x,10]    : Identificador (C8_IDENT)
//aArray[n,p,2,x,11]    : Total de Itens da Cotação
//aArray[n,p,2,x,12]    : Numero da Proposta (SC8->C8_NUMPRO)
//aArray[n,p,2,x,13]    : Preco Unitario (SC8->C8_PRECO)
//aArray[n,p,2,x,14]    : Flag vencedor auditoria
