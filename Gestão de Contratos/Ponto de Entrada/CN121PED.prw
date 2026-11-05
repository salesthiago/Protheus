#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE 'PROTHEUS.CH'

//------------------------------------------------------------
/*/{Protheus.doc} CN121PED
Ponto de Entrada CN121PED
O ponto de entrada poder� ser utilizado para tratamentos espec�ficos 
antes da gera��o do pedido de compra/titulo, podendo manipular o cabe�alho, 
itens e rateio se necess�rio.
https://tdn.totvs.com/pages/releaseview.action?pageId=271385565

@author Adriano COsta

@history
23/08/2020 - Programa��o inicial

/*/
//------------------------------------------------------------

/*
{Protheus.doc} CN121PED()
Atualiza��o de campos de Armazem e Observa��es
@author fernando.valadares
@since 23/08/2021
@version 1.0
@type class
*/

User Function CN121PED()

	Local nPosAux, nX
	Local aCab 		:= PARAMIXB[1]
	Local aItens 	:= PARAMIXB[2]
	Local cLocal
	Local cOBSM
	Local oModel    := Nil
	Local cContra   := ""
	Local cRevisa   := ""
	Local cNumMed   := ""

//cLocal 	:= CND->CND_XLOCAL
//cOBSM	:= CND->CND_OBS

//tratamento para pedido de compra
	if !empty(aCab) .AND. SubStr(aCab[1][1],1,2)=="C7"
		oModel := FwModelActive()//Modelo do CNTA121

		// CND_XLOCAL/CND_OBS protegidos com Begin Sequence: em ambientes onde o campo
		// customizado CND_XLOCAL nao existe no CNDMASTER, GetValue() lanca erro fatal
		// ("id de formulario nao e valido") e derrubava todo o encerramento da medicao.
		Begin Sequence
			cLocal := oModel:GetValue("CNDMASTER", "CND_XLOCAL")
		Recover
			cLocal := ""
		End Sequence

		Begin Sequence
			cOBSM := oModel:GetValue("CNDMASTER", "CND_OBS")
		Recover
			cOBSM := ""
		End Sequence

		// Registra na timeline do contrato (ZLG) que um pedido de compra esta sendo
		// gerado para esta medicao. Aqui e ANTES da geracao (o numero do pedido C7
		// ainda nao existe nesse ponto), por isso a acao nao traz o numero do pedido.
		cContra := AllTrim(oModel:GetValue("CNDMASTER", "CND_CONTRA"))
		cRevisa := AllTrim(oModel:GetValue("CNDMASTER", "CND_REVISA"))
		cNumMed := AllTrim(oModel:GetValue("CNDMASTER", "CND_NUMMED"))
		If !Empty(cContra)
			U_SCTGrvZLG(cContra, cRevisa, "", cNumMed, "PEDIDO_COMPRA_GERADO", "CN121PED", "", "",;
				"Pedido de compra em geracao para a medicao " + cNumMed)
		EndIf

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
				nPosAux := aScan(aItens[nX], {|x| x[1] == 'C7_OBS' })
				if nPosAux == 0
					aadd(aItens[nX], {'C7_OBS', cOBSM, Nil} )
				else
					aItens[nX][nPosAux][2] := cOBSM
				endif
			next nX
		endif

	endif

Return {aCab,aItens}
