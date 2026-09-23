#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE 'PROTHEUS.CH'

//------------------------------------------------------------
/*/{Protheus.doc} CN120ITM
Ponto de Entrada CN120ITM

Localizado na função CN120PED, responsável por gerar Pedido de Compras ou Vendas por meio de rotina automática.
Este ponto de entrada é executado no encerramento da medição, no momento em que é gerado o Pedido de Compras, 
por meio da rotina automática MATA120 ou Pedido de Vendas, por meio da rotina automática MATA410. 
É executado logo após o preenchimento dos arrays com os itens da medição do contrato. 
Tem por objetivo permitir o preenchimento dos campos específicos do SC7 para Pedidos de Compras ou SC6 para 
Pedidos de Vendas por itens da Medição do Contrato. 

@author Pablo Cavalcante

@history
23/11/2015 - Programação inicial

/*/
//------------------------------------------------------------

/*
{Protheus.doc} CN120ITM()
Atualização de campos de Armazem e Observações
@author fernando.valadares
@since 23/08/2021
@version 1.0
@type class
*/

User Function CN120ITM()

Local nPosAux, nX
Local aCab 		:= PARAMIXB[1]
Local aItens 	:= PARAMIXB[2]
Local cLocal
Local cOBSM

cLocal 	:= CND->CND_XLOCAL
cOBSM	:= CND->CND_OBS

//tratamento para pedido de compra
if !empty(aCab) .AND. SubStr(aCab[1][1],1,2)=="C7"

    if !empty(cLocal)
		for nX := 1 to len(aItens)
			nPosAux := aScan(aItens[nX], {|x| x[1] == 'C7_LOCAL' })  
			if nPosAux == 0
				aadd(aItens[nX], {'C7_LOCAL', cLocal, Nil} )
			else
				aItens[nX][nPosAux][2] := cLocal
			endif
	
		next nX
    endif

	if !empty(cOBSM)
		for nX := 1 to len(aItens)
			nPosAux := aScan(aItens[nX], {|x| x[1] == 'C7_OBSM' })  
			if nPosAux == 0
				aadd(aItens[nX], {'C7_OBSM', cOBSM, Nil} )
			else
				aItens[nX][nPosAux][2] := cOBSM
			endif
		next nX
    endif

endif

Return {aCab,aItens}
