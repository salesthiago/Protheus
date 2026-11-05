#include 'protheus.ch'
#include 'Restful.ch'
#include "TBICONN.CH"

WSRESTFUL APIAterro DESCRIPTION "API GRAVAR PESAGENS ATERRO" FORMAT "application/json,text/html" 
	WSDATA cFilUsr 	as String Optional

	WSMETHOD POST recMovNJH 			DESCRIPTION 'Recebe Movimento NJH dos Projetos'	;	
										WSSYNTAX '/APIAterro/recMovNJH' ;
										PATH '/APIAterro/recMovNJH' ;
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

//Inclusão da Abertura de Turno
WSMETHOD POST recMovNJH WSRECEIVE WSSERVICE APIAterro
	Local lRet 		:= .T.
	Local cJson		:= ::getContent()
	Local oResponse, oJson
    Local aTables   := {"NJH", "SB1", "NJ0", "DA3" } 

    if cEmpAnt = "02"
        cFilref := "0201"
    else
        cFilRef := "0101"
    endif

	cFilAnt := cFilref
    //RpcClearEnv()
    //RpcSetType(3)
    //RpcSetEnv(cEmpAnt, cFilref,,,,GetEnvServer(),aTables)

	::SetContentType('application/json')
	
	oResponse	:= JsonObject():New()
	oJson		:= JsonObject():New()
	
	oJson:FromJson(cJson)
	
	conout("Gravando Movimento dos Projetos APIAterro - recMovNJH --> "+oJson['NJH_XCLVL'])

	NJH->(DbSetOrder(3))
	if !NJH->(DbSeek(xfilial("NJH")+oJson['NJH_XCLVL']+oJson['NJH_CODPAV']))

		NJH->(RecLock("NJH",.T.))
		NJH->NJH_FILIAL := XFILIAL("NJH")
		NJH->NJH_CODPAV	:= oJson['NJH_CODPAV']
		NJH->NJH_DATA  	:= stod(oJson['NJH_DATA'])
		NJH->NJH_CODENT := oJson['NJH_CODENT']
		NJH->NJH_LOJENT := oJson['NJH_LOJENT']
		NJH->NJH_NOMENT	:= oJson['NJH_NOMENT']
		NJH->NJH_NLJENT	:= oJson['NJH_NLJENT']
		NJH->NJH_CODPRO	:= oJson['NJH_CODPRO']
		NJH->NJH_DESPRO	:= oJson['NJH_DESPRO']
		NJH->NJH_UM1PRO	:= oJson['NJH_UM1PRO']
		NJH->NJH_PLACA 	:= oJson['NJH_PLACA']
		NJH->NJH_NOMMOT	:= oJson['NJH_NOMMOT']
		NJH->NJH_DATPS1	:= stod(oJson['NJH_DATPS1'])
		NJH->NJH_HORPS1	:= oJson['NJH_HORPS1']
		NJH->NJH_PESO1 	:= oJson['NJH_PESO1']
		NJH->NJH_MODPS1	:= oJson['NJH_MODPS1']
		NJH->NJH_DATPS2	:= stod(oJson['NJH_DATPS2'])
		NJH->NJH_HORPS2	:= oJson['NJH_HORPS2']
		NJH->NJH_PESO2 	:= oJson['NJH_PESO2']
		NJH->NJH_MODPS2	:= oJson['NJH_MODPS2']
		NJH->NJH_PSSUBT	:= oJson['NJH_PSSUBT']
		NJH->NJH_OBS   	:= oJson['NJH_OBS']
		NJH->NJH_STATUS	:= oJson['NJH_STATUS']
		NJH->NJH_XCLVL 	:= oJson['NJH_XCLVL']
		NJH->NJH_XROTA 	:= oJson['NJH_XROTA']
		NJH->NJH_XCLIEN	:= oJson['NJH_XCLIEN']
		NJH->NJH_XDTSIN	:= dDatabase
		NJH->NJH_XSINC  := "S"
		NJH->(msUnlock())

		oResponse['status'] 		:= 200
		oResponse['message']		:= EncodeUTF8("Ticket Gravado com Sucesso")

		::SetResponse(oResponse:toJson())
		lRet := .T.

	else
		lRet := .F.
		SetRestFault(400, EncodeUTF8("Ticket já Gravado"))
	endif
    
	//RpcClearEnv()

Return lRet
