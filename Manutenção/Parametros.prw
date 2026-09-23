#INCLUDE "TOTVS.CH"
#INCLUDE "PROTHEUS.CH"

// Tela hibrida (POUI/manut) de manutencao generica de parametros (SX6).
// Acesso liberado para usuarios do grupo Administrador (000000) ou para
// usuarios cujo codigo esteja listado no parametro MV_XMANUT (separados por "|").

USER FUNCTION ManutApp()
	FWCallApp("manut")
Return

// Cria (se ainda nao existir) o parametro MV_XMANUT que controla o acesso
// a esta tela. Rotina de instalacao, executar uma unica vez (idempotente).
USER FUNCTION ManutTab()
	Local cFilPar := xFilial("SX6")
	Local lCriou  := .F.

	dbSelectArea("SX6")
	SX6->(dbSetOrder(1))

	If !SX6->(dbSeek(cFilPar + "MV_XMANUT"))
		Begin Transaction
			RecLock("SX6", .T.)
			SX6->X6_FIL     := cFilPar
			SX6->X6_VAR     := "MV_XMANUT"
			SX6->X6_TIPO    := "C"
			SX6->X6_CONTEUD := ""
			SX6->X6_DESCRIC := "Usuarios com acesso a manutencao de parametros"
			SX6->X6_DSC01   := "Codigos de usuario separados por | (ex: 000010|000015)"
			SX6->X6_DSC02   := "Usuarios do grupo Administrador (000000) sempre tem acesso"
			SX6->X6_DSC03   := ""
			SX6->(MsUnlock())
		End Transaction
		lCriou := .T.
		MsgInfo("Parametro MV_XMANUT criado com sucesso.", "Manutencao de Parametros")
	Else
		MsgInfo("Parametro MV_XMANUT ja existe. Nada foi alterado.", "Manutencao de Parametros")
	EndIf

Return lCriou

Static Function JsToAdvpl(oWebChannel, cType, cContent)
	Local oReq       := JsonObject():New()
	Local oResp      := JsonObject():New()
	Local cReceiveId := ""

	oReq:fromJson(cContent)
	cReceiveId := oReq["receiveId"]

	Do Case
	Case cType == "manutPermissao"
		oResp := ZmnPerm(oReq)
	Case cType == "manutListar"
		oResp := ZmnList(oReq)
	Case cType == "manutDetalhe"
		oResp := ZmnDet(oReq)
	Case cType == "manutSalvar"
		oResp := ZmnSalva(oReq)
	Case cType == "manutExcluir"
		oResp := ZmnDel(oReq)
	OtherWise
		oResp["success"] := .F.
		oResp["message"] := "Operacao nao reconhecida: " + cType
	EndCase

	If !Empty(cReceiveId)
		oWebChannel:AdvplToJs(cReceiveId, oResp:toJson())
	EndIf
Return .T.

// Verifica se o usuario informado pode acessar a manutencao de parametros:
// administrador (grupo 000000) ou codigo presente em MV_XMANUT.
Static Function ZmnPode(cUserId)
	Local lPode   := .F.
	Local cFilPar := xFilial("SX6")
	Local cLista  := ""

	Default cUserId := ""

	If Empty(cUserId)
		Return .F.
	EndIf

	If UsrRetGrupo(cUserId) == "000000"
		Return .T.
	EndIf

	dbSelectArea("SX6")
	SX6->(dbSetOrder(1))
	If SX6->(dbSeek(cFilPar + "MV_XMANUT"))
		cLista := "|" + AllTrim(SX6->X6_CONTEUD) + "|"
		lPode  := "|" + cUserId + "|" $ cLista
	EndIf

Return lPode

Static Function ZmnPerm(oReq)
	Local oResp    := JsonObject():New()
	Local cUserId  := RetCodUsr()

	oResp["success"]    := .T.
	oResp["usuario"]    := cUserId
	oResp["autorizado"] := ZmnPode(cUserId)
Return oResp

Static Function ZmnList(oReq)
	Local oResp    := JsonObject():New()
	Local aParam   := {}
	Local oItem
	Local cBusca   := ""
	Local cFilPar  := xFilial("SX6")
	Local cUserId  := RetCodUsr()

	If !ZmnPode(cUserId)
		oResp["success"] := .F.
		oResp["message"] := "Usuario sem permissao para acessar a manutencao de parametros."
		Return oResp
	EndIf

	If ValType(oReq["busca"]) == "C"
		cBusca := Upper(AllTrim(oReq["busca"]))
	EndIf

	dbSelectArea("SX6")
	SX6->(dbSetOrder(1))
	SX6->(dbSeek(cFilPar))
	While SX6->(!Eof()) .And. AllTrim(SX6->X6_FIL) == AllTrim(cFilPar)
		If Empty(cBusca) .Or. cBusca $ Upper(AllTrim(SX6->X6_VAR)) .Or. cBusca $ Upper(AllTrim(SX6->X6_DESCRIC))
			oItem := JsonObject():New()
			oItem["filial"]    := AllTrim(SX6->X6_FIL)
			oItem["variavel"]  := AllTrim(SX6->X6_VAR)
			oItem["tipo"]      := AllTrim(SX6->X6_TIPO)
			oItem["conteudo"]  := AllTrim(SX6->X6_CONTEUD)
			oItem["descricao"] := AllTrim(SX6->X6_DESCRIC)
			aAdd(aParam, oItem)
		EndIf
		SX6->(dbSkip())
	EndDo

	oResp["success"]    := .T.
	oResp["parametros"] := aParam
Return oResp

Static Function ZmnDet(oReq)
	Local oResp   := JsonObject():New()
	Local cVar    := ""
	Local cFilPar := xFilial("SX6")
	Local cUserId := RetCodUsr()

	If !ZmnPode(cUserId)
		oResp["success"] := .F.
		oResp["message"] := "Usuario sem permissao para acessar a manutencao de parametros."
		Return oResp
	EndIf

	If ValType(oReq["variavel"]) == "C"
		cVar := Upper(AllTrim(oReq["variavel"]))
	EndIf

	dbSelectArea("SX6")
	SX6->(dbSetOrder(1))
	If Empty(cVar) .Or. !SX6->(dbSeek(cFilPar + cVar))
		oResp["success"] := .F.
		oResp["message"] := "Parametro nao encontrado."
		Return oResp
	EndIf

	oResp["success"]     := .T.
	oResp["filial"]      := AllTrim(SX6->X6_FIL)
	oResp["variavel"]    := AllTrim(SX6->X6_VAR)
	oResp["tipo"]        := AllTrim(SX6->X6_TIPO)
	oResp["conteudo"]    := AllTrim(SX6->X6_CONTEUD)
	oResp["descricao"]   := AllTrim(SX6->X6_DESCRIC)
	oResp["descricao1"]  := AllTrim(SX6->X6_DSC01)
	oResp["descricao2"]  := AllTrim(SX6->X6_DSC02)
	oResp["descricao3"]  := AllTrim(SX6->X6_DSC03)
Return oResp

Static Function ZmnSalva(oReq)
	Local oResp    := JsonObject():New()
	Local cVar     := ""
	Local cTipo    := ""
	Local cConteud := ""
	Local cDescric := ""
	Local cDsc1    := ""
	Local cDsc2    := ""
	Local cDsc3    := ""
	Local cFilPar  := xFilial("SX6")
	Local cUserId  := RetCodUsr()
	Local lNovo    := .T.

	If !ZmnPode(cUserId)
		oResp["success"] := .F.
		oResp["message"] := "Usuario sem permissao para alterar parametros."
		Return oResp
	EndIf

	If ValType(oReq["variavel"]) == "C"
		cVar := Upper(AllTrim(oReq["variavel"]))
	EndIf
	If ValType(oReq["tipo"]) == "C"
		cTipo := Upper(AllTrim(oReq["tipo"]))
	EndIf
	If ValType(oReq["conteudo"]) == "C"
		cConteud := oReq["conteudo"]
	EndIf
	If ValType(oReq["descricao"]) == "C"
		cDescric := oReq["descricao"]
	EndIf
	If ValType(oReq["descricao1"]) == "C"
		cDsc1 := oReq["descricao1"]
	EndIf
	If ValType(oReq["descricao2"]) == "C"
		cDsc2 := oReq["descricao2"]
	EndIf
	If ValType(oReq["descricao3"]) == "C"
		cDsc3 := oReq["descricao3"]
	EndIf

	If Left(cVar, 3) != "MV_" .Or. Len(cVar) < 4 .Or. Len(cVar) > 10
		oResp["success"] := .F.
		oResp["message"] := "Nome do parametro deve comecar com MV_ e ter ate 10 caracteres."
		Return oResp
	EndIf

	If !(cTipo $ "C|N|D|L")
		oResp["success"] := .F.
		oResp["message"] := "Tipo invalido. Use C (texto), N (numero), D (data) ou L (sim/nao)."
		Return oResp
	EndIf

	dbSelectArea("SX6")
	SX6->(dbSetOrder(1))

	Begin Transaction

		If SX6->(dbSeek(cFilPar + cVar))
			lNovo := .F.
			RecLock("SX6", .F.)
		Else
			RecLock("SX6", .T.)
			SX6->X6_FIL := cFilPar
			SX6->X6_VAR := cVar
		EndIf

		SX6->X6_TIPO    := cTipo
		SX6->X6_CONTEUD := cConteud
		SX6->X6_DESCRIC := cDescric
		SX6->X6_DSC01   := cDsc1
		SX6->X6_DSC02   := cDsc2
		SX6->X6_DSC03   := cDsc3
		SX6->(MsUnlock())

	End Transaction

	oResp["success"]  := .T.
	oResp["message"]  := IIf(lNovo, "Parametro criado com sucesso.", "Parametro atualizado com sucesso.")
	oResp["variavel"] := cVar
Return oResp

Static Function ZmnDel(oReq)
	Local oResp   := JsonObject():New()
	Local cVar    := ""
	Local cFilPar := xFilial("SX6")
	Local cUserId := RetCodUsr()

	If !ZmnPode(cUserId)
		oResp["success"] := .F.
		oResp["message"] := "Usuario sem permissao para excluir parametros."
		Return oResp
	EndIf

	If ValType(oReq["variavel"]) == "C"
		cVar := Upper(AllTrim(oReq["variavel"]))
	EndIf

	If cVar == "MV_XMANUT"
		oResp["success"] := .F.
		oResp["message"] := "O parametro MV_XMANUT controla o acesso a esta tela e nao pode ser excluido. Edite o conteudo se necessario."
		Return oResp
	EndIf

	dbSelectArea("SX6")
	SX6->(dbSetOrder(1))
	If Empty(cVar) .Or. !SX6->(dbSeek(cFilPar + cVar))
		oResp["success"] := .F.
		oResp["message"] := "Parametro nao encontrado."
		Return oResp
	EndIf

	Begin Transaction
		RecLock("SX6", .F.)
		SX6->(dbDelete())
		SX6->(MsUnlock())
	End Transaction

	oResp["success"] := .T.
	oResp["message"] := "Parametro excluido com sucesso."
Return oResp
