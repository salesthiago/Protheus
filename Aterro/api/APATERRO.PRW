#include 'protheus.ch'
#include 'Restful.ch'
#include "TBICONN.CH"

WSRESTFUL APIAterro DESCRIPTION "API GRAVAR PESAGENS ATERRO" FORMAT "application/json,text/html"
	WSDATA cFilUsr 	as String Optional

	WSMETHOD POST recMovNJH 			DESCRIPTION 'Recebe Movimento NJH dos Projetos'	;
										WSSYNTAX '/APIAterro/recMovNJH' ;
										PATH '/APIAterro/recMovNJH' ;
										PRODUCES APPLICATION_JSON

	WSMETHOD POST updMovNJH 			DESCRIPTION 'Atualiza Movimento NJH ja sincronizado (inclui se nao existir)'	;
										WSSYNTAX '/APIAterro/updMovNJH' ;
										PATH '/APIAterro/updMovNJH' ;
										PRODUCES APPLICATION_JSON

	//WSMETHOD POST recDA3Cad 			DESCRIPTION 'Cadastro de Veículos'	;
	//									WSSYNTAX '/APIAterro/recCadDA3';
	//									PATH '/APIAterro/recCadDA3';
	//									PRODUCES APPLICATION_JSON

	//WSMETHOD POST recNJ0Cad 			DESCRIPTION 'Consulta de Fornecedores/Entidade'	;
	//									WSSYNTAX '/APIAterro/recCADNJ0';
	//									PATH '/APIAterro/recCADNJ0';
	//									PRODUCES APPLICATION_JSON

END WSRESTFUL

//-------------------------------------------------------------------
// Inclusao de Movimento NJH (pesagem) vindo das balancas locais
//-------------------------------------------------------------------
WSMETHOD POST recMovNJH WSRECEIVE WSSERVICE APIAterro
	Local lRet 		:= .T.
	Local cJson		:= ::getContent()
	Local oResponse, oJson
	Local cErro		:= ""

	xFilRefNJH()

	::SetContentType('application/json')

	oResponse	:= JsonObject():New()
	oJson		:= JsonObject():New()

	cErro := oJson:FromJson(cJson)
	if ValType(cErro) == "C" .Or. Empty(xJStr(oJson, 'NJH_CODPAV'))
		SetRestFault(400, EncodeUTF8("JSON invalido ou NJH_CODPAV nao informado"))
		Return .F.
	endif

	conout("Gravando Movimento dos Projetos APIAterro - recMovNJH --> "+xJStr(oJson, 'NJH_XCLVL')+" / "+xJStr(oJson, 'NJH_CODPAV'))

	if !xSeekNJH(oJson)

		xGravaNJH(oJson, .T.)

		oResponse['status'] 		:= 200
		oResponse['message']		:= EncodeUTF8("Ticket Gravado com Sucesso")

		::SetResponse(oResponse:toJson())
		lRet := .T.

	else
		lRet := .F.
		SetRestFault(400, EncodeUTF8("Ticket já Gravado"))
	endif

Return lRet

//-------------------------------------------------------------------
// Atualizacao de Movimento NJH ja sincronizado.
// Usado quando a pesagem muda na balanca local depois do primeiro
// envio (2a pesagem, finalizacao, cancelamento, correcao de peso/obs)
// ou quando o sincronizador forca o reenvio de um periodo.
// Se o ticket ainda nao existir em producao, ele e incluido (upsert).
//-------------------------------------------------------------------
WSMETHOD POST updMovNJH WSRECEIVE WSSERVICE APIAterro
	Local cJson		:= ::getContent()
	Local oResponse, oJson
	Local cErro		:= ""
	Local lExiste	:= .F.

	xFilRefNJH()

	::SetContentType('application/json')

	oResponse	:= JsonObject():New()
	oJson		:= JsonObject():New()

	cErro := oJson:FromJson(cJson)
	if ValType(cErro) == "C" .Or. Empty(xJStr(oJson, 'NJH_CODPAV'))
		SetRestFault(400, EncodeUTF8("JSON invalido ou NJH_CODPAV nao informado"))
		Return .F.
	endif

	conout("Atualizando Movimento dos Projetos APIAterro - updMovNJH --> "+xJStr(oJson, 'NJH_XCLVL')+" / "+xJStr(oJson, 'NJH_CODPAV')+" status "+xJStr(oJson, 'NJH_STATUS'))

	lExiste := xSeekNJH(oJson)

	// lExiste = .T. -> NJH posicionada, altera o registro
	// lExiste = .F. -> inclui novo registro
	xGravaNJH(oJson, !lExiste)

	oResponse['status'] 		:= 200
	oResponse['acao']			:= iif(lExiste, "alterado", "incluido")
	oResponse['message']		:= EncodeUTF8(iif(lExiste, "Ticket Atualizado com Sucesso", "Ticket nao existia - Incluido com Sucesso"))

	::SetResponse(oResponse:toJson())

Return .T.

//-------------------------------------------------------------------
// Define a filial de referencia da empresa logada
//-------------------------------------------------------------------
Static Function xFilRefNJH()

	if cEmpAnt = "02"
		cFilAnt := "0201"
	else
		cFilAnt := "0101"
	endif

Return

//-------------------------------------------------------------------
// Posiciona a NJH pelo indice 3 (FILIAL + XCLVL + CODPAV).
// As chaves sao completadas com espacos ate o tamanho do campo, senao
// o DbSeek nao encontra o registro quando o valor do JSON vem sem os
// espacos a direita (ex.: XCLVL "0102" em campo de tamanho maior).
//-------------------------------------------------------------------
Static Function xSeekNJH(oJson)
	Local cChave := ""

	cChave := xFilial("NJH")
	cChave += PadR(xJStr(oJson, 'NJH_XCLVL') , TamSX3("NJH_XCLVL")[1])
	cChave += PadR(xJStr(oJson, 'NJH_CODPAV'), TamSX3("NJH_CODPAV")[1])

	NJH->(DbSetOrder(3))

Return NJH->(DbSeek(cChave))

//-------------------------------------------------------------------
// Grava os campos da NJH a partir do JSON recebido.
// lInclui = .T. inclui registro novo; .F. altera o registro posicionado
// (as chaves FILIAL/XCLVL/CODPAV nao sao alteradas).
//-------------------------------------------------------------------
Static Function xGravaNJH(oJson, lInclui)

	NJH->(RecLock("NJH", lInclui))

	if lInclui
		NJH->NJH_FILIAL := xFilial("NJH")
		NJH->NJH_CODPAV	:= xJStr(oJson, 'NJH_CODPAV')
		NJH->NJH_XCLVL 	:= xJStr(oJson, 'NJH_XCLVL')
	endif

	NJH->NJH_DATA  	:= StoD(xJStr(oJson, 'NJH_DATA'))
	NJH->NJH_CODENT := xJStr(oJson, 'NJH_CODENT')
	NJH->NJH_LOJENT := xJStr(oJson, 'NJH_LOJENT')
	NJH->NJH_NOMENT	:= xJStr(oJson, 'NJH_NOMENT')
	NJH->NJH_NLJENT	:= xJStr(oJson, 'NJH_NLJENT')
	NJH->NJH_CODPRO	:= xJStr(oJson, 'NJH_CODPRO')
	NJH->NJH_DESPRO	:= xJStr(oJson, 'NJH_DESPRO')
	NJH->NJH_UM1PRO	:= xJStr(oJson, 'NJH_UM1PRO')
	NJH->NJH_PLACA 	:= xJStr(oJson, 'NJH_PLACA')
	NJH->NJH_NOMMOT	:= xJStr(oJson, 'NJH_NOMMOT')
	NJH->NJH_DATPS1	:= StoD(xJStr(oJson, 'NJH_DATPS1'))
	NJH->NJH_HORPS1	:= xJStr(oJson, 'NJH_HORPS1')
	NJH->NJH_PESO1 	:= xJNum(oJson, 'NJH_PESO1')
	NJH->NJH_MODPS1	:= xJStr(oJson, 'NJH_MODPS1')
	NJH->NJH_DATPS2	:= StoD(xJStr(oJson, 'NJH_DATPS2'))
	NJH->NJH_HORPS2	:= xJStr(oJson, 'NJH_HORPS2')
	NJH->NJH_PESO2 	:= xJNum(oJson, 'NJH_PESO2')
	NJH->NJH_MODPS2	:= xJStr(oJson, 'NJH_MODPS2')
	NJH->NJH_PSSUBT	:= xJNum(oJson, 'NJH_PSSUBT')
	NJH->NJH_OBS   	:= xJStr(oJson, 'NJH_OBS')
	NJH->NJH_STATUS	:= xJStr(oJson, 'NJH_STATUS')
	NJH->NJH_XROTA 	:= xJStr(oJson, 'NJH_XROTA')
	NJH->NJH_XCLIEN	:= xJStr(oJson, 'NJH_XCLIEN')
	NJH->NJH_XDTSIN	:= dDatabase
	NJH->NJH_XSINC  := "S"

	NJH->(MsUnlock())

Return

//-------------------------------------------------------------------
// Le uma propriedade caractere do JSON (vazio se nao vier)
//-------------------------------------------------------------------
Static Function xJStr(oJson, cProp)
	Local xVal := oJson[cProp]

	if ValType(xVal) == "N"
		Return cValToChar(xVal)
	elseif ValType(xVal) != "C"
		Return ""
	endif

Return xVal

//-------------------------------------------------------------------
// Le uma propriedade numerica do JSON (zero se nao vier)
//-------------------------------------------------------------------
Static Function xJNum(oJson, cProp)
	Local xVal := oJson[cProp]

	if ValType(xVal) == "C"
		Return Val(StrTran(xVal, ",", "."))
	elseif ValType(xVal) != "N"
		Return 0
	endif

Return xVal
