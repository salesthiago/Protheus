#include 'protheus.ch'
#include 'topconn.ch'

/*
-------------------------------------------------------------------------------
Ponto Ent. : MT131FOR         Autor : Customizacao        Data : 16/07/2026
Desc.      : Filtra/ordena fornecedores sugeridos na Geracao de Cotacao
             (MATA131). Trabalha em conjunto com MT131GRV, que grava a
             justificativa de nao cotacao em C8_OBSFOR.
Uso        : Compras - MATA131
-------------------------------------------------------------------------------

Contrato assumido para PARAMIXB (documentacao publica da TDN, nao controlavel
via fetch automatico durante o desenvolvimento - validar no primeiro teste):
	PARAMIXB[1] = aFornece sugerido pelo sistema, onde cada linha e:
		[1] A2_COD (fornecedor) [2] A2_LOJA [3] Criterio [4] Alias [5] Recno

MT131FOR e MT131GRV ficam no mesmo fonte porque precisam compartilhar estado
(Static) entre a sugestao de fornecedores e a gravacao de cada item de SC8.
*/

Static cProdPend  := ""	// produto com pendencia de justificativa de nao cotacao
Static cJustPend  := ""	// texto a gravar em C8_OBSFOR
Static lJustUsada := .T.	// controla gravacao unica por produto (1o item do produto)

User Function MT131FOR()

	Local aFornSug	:= PARAMIXB[1]
	Local aFornRet	:= {}
	Local aAux		:= {}
	Local aUltFor	:= {}
	Local cFilAtu	:= ""
	Local cProduto	:= ""
	Local cMotivo	:= ""
	Local lNaSug	:= .F.
	Local nX		:= 0

	cProduto := If(!Empty(SC7->C7_PRODUTO), SC7->C7_PRODUTO, SB1->B1_COD)
	cFilAtu  := If(!Empty(SC7->C7_FILIAL) , SC7->C7_FILIAL , xFilial("SA2"))

	// 1) mantem somente os fornecedores sugeridos que pertencem a filial corrente
	For nX := 1 To Len(aFornSug)
		If Posicione("SA2", 1, cFilAtu + aFornSug[nX][1] + aFornSug[nX][2], "A2_FILIAL") == cFilAtu
			AAdd(aFornRet, aFornSug[nX])
		EndIf
	Next nX

	// 2) verifica se o ultimo fornecedor que vendeu o produto ficou de fora da cotacao
	aUltFor := xUltFor(cProduto, cFilAtu)

	cProdPend  := ""
	cJustPend  := ""
	lJustUsada := .T.

	If !Empty(aUltFor[1])

		If Ascan(aFornRet, {|x| x[1] == aUltFor[1] .And. x[2] == aUltFor[2]}) == 0

			lNaSug := Ascan(aFornSug, {|x| x[1] == aUltFor[1] .And. x[2] == aUltFor[2]}) > 0
			cMotivo := If(lNaSug, "fornecedor de outra filial", "fornecedor fora da sugestao do sistema")

			cProdPend  := cProduto
			cJustPend  := "Nao cotado o fornecedor da ultima compra (" + AllTrim(aUltFor[3]) + " - " + ;
							AllTrim(aUltFor[1]) + "/" + AllTrim(aUltFor[2]) + ", em " + DToC(aUltFor[4]) + "): " + cMotivo + "."
			lJustUsada := .F.

		EndIf

	EndIf

	// 3) ordena pelo menor preco de referencia (ultima compra) - o mais barato fica na 1a coluna
	For nX := 1 To Len(aFornRet)
		AAdd(aAux, {xPrcFor(cProduto, aFornRet[nX][1], aFornRet[nX][2]), aFornRet[nX]})
	Next nX

	aAux := ASort(aAux, , , {|x, y| x[1] < y[1]})

	aFornRet := {}
	For nX := 1 To Len(aAux)
		AAdd(aFornRet, aAux[nX][2])
	Next nX

Return aFornRet

/*
Grava em C8_OBSFOR a justificativa calculada em MT131FOR, quando o ultimo
fornecedor que comprou o produto nao entrou nesta cotacao. Assume-se que o
registro de SC8 ja foi gravado quando este P.E. dispara (por isso o
RecLock/MsUnlock aqui) - validar esse comportamento no ambiente antes de
subir para producao, pois nao foi possivel confirmar via TDN (bloqueio de
acesso automatico durante o desenvolvimento).
*/
User Function MT131GRV()

	Local nTamCpo := 0

	If !Empty(cProdPend) .And. !lJustUsada .And. SC8->C8_PRODUTO == cProdPend

		nTamCpo := TamSX3("C8_OBSFOR")[1]

		RecLock("SC8", .F.)
		SC8->C8_OBSFOR := SubStr(cJustPend, 1, nTamCpo)
		MsUnlock()

		lJustUsada := .T.

	EndIf

Return

/*
Retorna {fornecedor, loja, nome, data} da ultima compra do produto na filial
corrente, com base nos itens de NF de entrada (SD1), no mesmo padrao ja
utilizado em RACOM003.prw (funcao U_fultVlr).
*/
Static Function xUltFor(cProduto, cFilRef)

	Local aRet		:= {"", "", "", CToD("")}
	Local cAliasTop	:= GetNextAlias()
	Local cQuery	:= ""

	cQuery := "SELECT TOP 1 D1_FORNECE, D1_LOJA, D1_DTDIGIT "
	cQuery += "FROM " + RetSqlName("SD1") + " SD1 "
	cQuery += "WHERE SD1.D_E_L_E_T_ = ' ' "
	cQuery += "AND SD1.D1_COD = '" + cProduto + "' "
	cQuery += "AND SD1.D1_FILIAL = '" + cFilRef + "' "
	cQuery += "AND SD1.D1_TES <> '   ' "
	cQuery += "ORDER BY SD1.D1_DTDIGIT DESC "

	dbUseArea(.T., "TOPCONN", TcGenQry(, , cQuery), cAliasTop, .T., .T.)

	If !(cAliasTop)->(Eof())
		aRet[1] := (cAliasTop)->D1_FORNECE
		aRet[2] := (cAliasTop)->D1_LOJA
		aRet[4] := StoD((cAliasTop)->D1_DTDIGIT)
		aRet[3] := Posicione("SA2", 1, xFilial("SA2") + aRet[1] + aRet[2], "A2_NOME")
	EndIf

	(cAliasTop)->(DbCloseArea())

Return aRet

/*
Preco de referencia (ultima compra) do fornecedor para o produto - usado
apenas para ordenacao. Sem historico, devolve um valor alto para que o
fornecedor sem referencia de preco va para o final da lista.
*/
Static Function xPrcFor(cProduto, cForn, cLoja)

	Local nPrc		:= 999999999
	Local cAliasTop	:= GetNextAlias()
	Local cQuery	:= ""

	cQuery := "SELECT TOP 1 D1_VUNIT "
	cQuery += "FROM " + RetSqlName("SD1") + " SD1 "
	cQuery += "WHERE SD1.D_E_L_E_T_ = ' ' "
	cQuery += "AND SD1.D1_COD = '" + cProduto + "' "
	cQuery += "AND SD1.D1_FORNECE = '" + cForn + "' "
	cQuery += "AND SD1.D1_LOJA = '" + cLoja + "' "
	cQuery += "AND SD1.D1_TES <> '   ' "
	cQuery += "ORDER BY SD1.D1_DTDIGIT DESC "

	dbUseArea(.T., "TOPCONN", TcGenQry(, , cQuery), cAliasTop, .T., .T.)

	If !(cAliasTop)->(Eof())
		nPrc := (cAliasTop)->D1_VUNIT
	EndIf

	(cAliasTop)->(DbCloseArea())

Return nPrc
