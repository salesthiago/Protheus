#INCLUDE "TOTVS.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "RESTFUL.ch"

/*/{Protheus.doc} AprovCT
Abre a tela hibrida (Angular/PO-UI) de Aprovadores de Contratos (ZAP) e
Solicitacoes de Contrato (ZSC), empacotada em resource/sct001.app e carregada
via FWCallApp.
@type User Function
@author Thiago Sales - Quebec Ambiental
@since 2026-07-29
/*/
//=============================================================================================================================
USER FUNCTION AprovCT()

    FWCallApp("sct001")

RETURN

/*/{Protheus.doc} JsToAdvpl
Recebe mensagens da tela Angular (sct001) pelo canal AdvplToJs/JsToAdvpl
(TWebEngine/TWebChannel), substituindo RESTZAP.PRW/RESTSCT.PRW como transporte
-- mesmo padrao de Estoque/Armazem/src/EstMinMax.prw. Reaproveita a mesma
logica de consulta/gravacao dos dois arquivos REST; so muda o transporte
(SetRestFault/Self:SetResponse -> oWebChannel:AdvplToJs) e a identificacao do
usuario (Self:GetUserID(), que dependia do token Bearer do REST -> RetCodUsr(),
que le o usuario da propria sessao do SmartClient, ja que agora roda na thread
do usuario logado, nao mais num contexto headless REST).

IMPORTANTE: o receiveId nao viaja automatico entre o cliente e o ADVPL -- o
lado Angular (AdvplBridgeService) embute o receiveId dentro do JSON de
cContent, e aqui extraimos e devolvemos a resposta chamando
AdvplToJs(cReceiveId, ...), nao AdvplToJs(cType, ...).
@type Function
@author Thiago Sales - Quebec Ambiental
@since 2026-08-07
/*/
//=============================================================================================================================
Static Function JsToAdvpl(oWebChannel, cType, cContent)

    Local oReq       := JsonObject():New()
    Local oResp      := JsonObject():New()
    Local cReceiveId := ""

    oReq:fromJson(cContent)
    cReceiveId := oReq["receiveId"]

    Do Case
    Case cType == "zapListar"
        oResp := ZapList(oReq)
    Case cType == "zapDetalhe"
        oResp := ZapDetal(oReq)
    Case cType == "zapCriar"
        oResp := ZapCria(oReq)
    Case cType == "zapAtualizar"
        oResp := ZapAtual(oReq)
    Case cType == "zapRemover"
        oResp := ZapRemov(oReq)
    Case cType == "zapLookupCC"
        oResp := ZapLkpCC(oReq)
    Case cType == "zapLookupUsuario"
        oResp := ZapLkpUs(oReq)
    Case cType == "zapPermissao"
        oResp := ZapPerm(oReq)
    Case cType == "zscListar"
        oResp := ZscList(oReq)
    Case cType == "zscDetalhe"
        oResp := ZscDetal(oReq)
    Case cType == "zscCriar"
        oResp := ZscCria(oReq)
    Case cType == "zscAtualizar"
        oResp := ZscAtual(oReq)
    Case cType == "zscCotacaoCriar"
        oResp := ZscCtCri(oReq)
    Case cType == "zscCotacaoAtualizar"
        oResp := ZscCtAtu(oReq)
    Case cType == "zscCotacaoRemover"
        oResp := ZscCtRem(oReq)
    Case cType == "zscVencedorDefinir"
        oResp := ZscVenDf(oReq)
    Case cType == "zscAnexoCriar"
        oResp := ZscAnCri(oReq)
    Case cType == "zscAnexoBaixar"
        oResp := ZscAnBax(oReq)
    Case cType == "zscAnexoRemover"
        oResp := ZscAnRem(oReq)
    Case cType == "zscEnviar"
        oResp := ZscEnvia(oReq)
    Case cType == "zscAprovar"
        oResp := ZscAprov(oReq)
    Case cType == "zscReprovar"
        oResp := ZscRepro(oReq)
    Case cType == "zscPendentes"
        oResp := ZscPend(oReq)
    Case cType == "zscLookupCC"
        oResp := ZscLkpCC(oReq)
    OtherWise
        oResp["success"] := .F.
        oResp["message"] := "Operacao nao reconhecida: " + cType
    EndCase

    If !Empty(cReceiveId)
        oWebChannel:AdvplToJs(cReceiveId, oResp:toJson())
    EndIf

Return .T.

/*/{Protheus.doc} ZapPode
Verifica se o usuario logado pode gerenciar o cadastro de Aprovadores (ZAP):
precisa ter registro ativo (ZAP_SITUAC='1') na propria ZAP, OU estar na lista
de administradores do parametro MV_XSCTADM (codigos separados por "|"). Mesma
regra de RESTZAP.PRW::ZapPode.
@type Static Function
@param cUserId caractere, codigo do usuario logado (RetCodUsr())
@return logical
/*/
//=============================================================================================================================
Static Function ZapPode(cUserId)

    Local lPode := .F.

    Default cUserId := ""

    If !Empty(cUserId) .And. cUserId $ GetMv("MV_XSCTADM")
        lPode := .T.
    ElseIf !Empty(cUserId)
        If SeekZap(cUserId)
            lPode := (AllTrim(ZAP->ZAP_SITUAC) == "1")
        EndIf
    EndIf

Return lPode

/*/{Protheus.doc} SeekZap
Posiciona o alias ZAP no registro do usuario informado (DbSeek com fallback
para varredura linear). Mesma logica de RESTZAP.PRW::SeekZap.
@type Static Function
@param cUserId caractere, codigo do usuario (ZAP_USER)
@return logical, .T. se encontrou e o alias ZAP esta posicionado no registro
/*/
//=============================================================================================================================
Static Function SeekZap(cUserId)

    Local lAchou  := .F.
    Local cFilAtu := xFilial("ZAP")

    DbSelectArea("ZAP")
    ZAP->(DbSetOrder(1)) // ZAP_FILIAL+ZAP_USER
    lAchou := ZAP->(DbSeek(cFilAtu + PadR(Alltrim(cUserId), TamSX3("ZAP_USER")[1])))

    If !lAchou
        ZAP->(DbGoTop())
        Do While !ZAP->(Eof())
            If Alltrim(ZAP->ZAP_FILIAL) == Alltrim(cFilAtu) .And. Alltrim(ZAP->ZAP_USER) == Alltrim(cUserId)
                lAchou := .T.
                Exit
            EndIf
            ZAP->(DbSkip())
        EndDo
    EndIf

Return lAchou

/*/{Protheus.doc} SituacDB
Converte a situacao de API ("A"/"I") para o codigo gravado em ZAP_SITUAC
("1"/"2"). Mesma logica de RESTZAP.PRW::SituacDB.
@type Static Function
/*/
//=============================================================================================================================
Static Function SituacDB(cSituacApi)

    Local cRet := ""

    Do Case
    Case cSituacApi == "A" ; cRet := "1"
    Case cSituacApi == "I" ; cRet := "2"
    EndCase

Return cRet

/*/{Protheus.doc} SituApi
Converte a situacao gravada em ZAP_SITUAC ("1"/"2") para o contrato externo da
API ("A"/"I"). Inverso de SituacDB().
@type Static Function
/*/
//=============================================================================================================================
Static Function SituApi(cSituacDb)

    Local cRet := ""

    Do Case
    Case cSituacDb == "1" ; cRet := "A"
    Case cSituacDb == "2" ; cRet := "I"
    EndCase

Return cRet

/*/{Protheus.doc} ZapList
Lista os registros de ZAP (com descricao do centro de custo via CTT), aceitando
filtros opcionais por cUser/cSituac/cNivel/cCC. Mesma consulta de
RESTZAP::ListarZap.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZapList(oReq)

    Local oResp    := JsonObject():New()
    Local aItens   := {}
    Local oItem    := Nil
    Local cAliasQ  := GetNextAlias()
    Local cUserF   := ""
    Local cSituacF := ""
    Local cNivelF  := ""
    Local cCCF     := ""
    Local cWhere   := ""

    If !ZapPode(RetCodUsr())
        oResp["success"] := .F.
        oResp["message"] := "Acesso restrito a administradores ou aprovadores"
        Return oResp
    EndIf

    If ValType(oReq["cUser"]) == "C"   ; cUserF   := AllTrim(oReq["cUser"])   ; EndIf
    If ValType(oReq["cSituac"]) == "C" ; cSituacF := AllTrim(oReq["cSituac"]) ; EndIf
    If ValType(oReq["cNivel"]) == "C"  ; cNivelF  := AllTrim(oReq["cNivel"])  ; EndIf
    If ValType(oReq["cCC"]) == "C"     ; cCCF     := AllTrim(oReq["cCC"])     ; EndIf

    If !Empty(cUserF)
        cWhere += " AND ZAP.ZAP_USER LIKE '" + cUserF + "%'"
    EndIf
    If !Empty(cSituacF)
        cWhere += " AND ZAP.ZAP_SITUAC = '" + SituacDB(cSituacF) + "'"
    EndIf
    If !Empty(cNivelF)
        cWhere += " AND ZAP.ZAP_NIVEL = '" + cNivelF + "'"
    EndIf
    If !Empty(cCCF)
        cWhere += " AND ZAP.ZAP_CC = '" + cCCF + "'"
    EndIf
    cWhere := "%" + cWhere + "%"

    BeginSql Alias cAliasQ
        SELECT ZAP.ZAP_USER, ZAP.ZAP_NUSER, ZAP.ZAP_SITUAC, ZAP.ZAP_CC, ZAP.ZAP_NIVEL,
               ISNULL(CTT.CTT_DESC01, '') AS CTT_DESC
          FROM %table:ZAP% ZAP
          LEFT JOIN %table:CTT% CTT
            ON  CTT.D_E_L_E_T_ = ' '
            AND CTT.CTT_FILIAL = %xfilial:CTT%
            AND CTT.CTT_CUSTO  = ZAP.ZAP_CC
         WHERE ZAP.%notDel%
           AND ZAP.ZAP_FILIAL = %xfilial:ZAP%
           %exp:cWhere%
         ORDER BY ZAP.ZAP_USER
    EndSql

    While (cAliasQ)->(!Eof())
        oItem := JsonObject():New()
        oItem["user"]   := AllTrim((cAliasQ)->ZAP_USER)
        oItem["nuser"]  := AllTrim((cAliasQ)->ZAP_NUSER)
        oItem["situac"] := SituApi(AllTrim((cAliasQ)->ZAP_SITUAC))
        oItem["cc"]     := AllTrim((cAliasQ)->ZAP_CC)
        oItem["ccDesc"] := AllTrim((cAliasQ)->CTT_DESC)
        oItem["nivel"]  := AllTrim((cAliasQ)->ZAP_NIVEL)
        aAdd(aItens, oItem)
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

    oResp["success"] := .T.
    oResp["items"]   := aItens

Return oResp

/*/{Protheus.doc} ZapDetal
Obtem um registro especifico de ZAP pelo codigo do usuario. Mesma consulta de
RESTZAP::ObterZap.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZapDetal(oReq)

    Local oResp   := JsonObject():New()
    Local cAliasQ := GetNextAlias()
    Local cUserP  := ""

    If !ZapPode(RetCodUsr())
        oResp["success"] := .F.
        oResp["message"] := "Acesso restrito a administradores ou aprovadores"
        Return oResp
    EndIf

    If ValType(oReq["cUser"]) == "C" ; cUserP := AllTrim(oReq["cUser"]) ; EndIf

    If Empty(cUserP)
        oResp["success"] := .F.
        oResp["message"] := "Parametro 'cUser' e obrigatorio"
        Return oResp
    EndIf

    BeginSql Alias cAliasQ
        SELECT ZAP.ZAP_USER, ZAP.ZAP_NUSER, ZAP.ZAP_SITUAC, ZAP.ZAP_CC, ZAP.ZAP_NIVEL,
               ISNULL(CTT.CTT_DESC01, '') AS CTT_DESC
          FROM %table:ZAP% ZAP
          LEFT JOIN %table:CTT% CTT
            ON  CTT.D_E_L_E_T_ = ' '
            AND CTT.CTT_FILIAL = %xfilial:CTT%
            AND CTT.CTT_CUSTO  = ZAP.ZAP_CC
         WHERE ZAP.%notDel%
           AND ZAP.ZAP_FILIAL = %xfilial:ZAP%
           AND ZAP.ZAP_USER   = %exp:cUserP%
    EndSql

    If (cAliasQ)->(!Eof())
        oResp["success"] := .T.
        oResp["user"]    := AllTrim((cAliasQ)->ZAP_USER)
        oResp["nuser"]   := AllTrim((cAliasQ)->ZAP_NUSER)
        oResp["situac"]  := SituApi(AllTrim((cAliasQ)->ZAP_SITUAC))
        oResp["cc"]      := AllTrim((cAliasQ)->ZAP_CC)
        oResp["ccDesc"]  := AllTrim((cAliasQ)->CTT_DESC)
        oResp["nivel"]   := AllTrim((cAliasQ)->ZAP_NIVEL)
    Else
        oResp["success"] := .F.
        oResp["message"] := "Registro nao encontrado"
    EndIf
    (cAliasQ)->(DbCloseArea())

Return oResp

/*/{Protheus.doc} ZapCria
Inclui um registro na tabela ZAP via modelo MVC do SCT001.PRW, com as mesmas
validacoes de RESTZAP::IncluirZap (Situacao A/I, Nivel 1/2).
@type Static Function
/*/
//=============================================================================================================================
Static Function ZapCria(oReq)

    Local oResp    := JsonObject():New()
    Local oModel   := Nil
    Local cMsg     := ""
    Local lAtivado := .F.
    Local lFalha   := .F.
    Local cSituac  := ""
    Local cNivel   := ""

    If !ZapPode(RetCodUsr())
        oResp["success"] := .F.
        oResp["message"] := "Acesso restrito a administradores ou aprovadores"
        Return oResp
    EndIf

    If Empty(oReq["user"])
        oResp["success"] := .F.
        oResp["message"] := "Campo 'user' e obrigatorio"
        Return oResp
    EndIf

    cSituac := AllTrim(cValToChar(oReq["situac"]))
    cNivel  := AllTrim(cValToChar(oReq["nivel"]))

    If Empty(cSituac) .Or. !Pertence("AI", cSituac)
        oResp["success"] := .F.
        oResp["message"] := "Situacao invalida. Informe A - Ativo ou I - Inativo."
        Return oResp
    EndIf

    If Empty(cNivel) .Or. !Pertence("12", cNivel)
        oResp["success"] := .F.
        oResp["message"] := "Nivel de aprovacao invalido. Informe 1 ou 2."
        Return oResp
    EndIf

    oModel := FWLoadModel("SCT001")
    oModel:SetOperation(MODEL_OPERATION_INSERT)

    If oModel:Activate()
        lAtivado := .T.

        oModel:SetValue("ZAPMASTER", "ZAP_USER",   AllTrim(cValToChar(oReq["user"])))
        oModel:SetValue("ZAPMASTER", "ZAP_NUSER",  AllTrim(cValToChar(oReq["nuser"])))
        oModel:SetValue("ZAPMASTER", "ZAP_SITUAC", SituacDB(cSituac))
        oModel:SetValue("ZAPMASTER", "ZAP_CC",     AllTrim(cValToChar(oReq["cc"])))
        oModel:SetValue("ZAPMASTER", "ZAP_NIVEL",  cNivel)

        If oModel:VldData()
            oModel:CommitData()
            oResp["success"] := .T.
            oResp["message"] := "Registro incluido com sucesso"
        Else
            cMsg := AllTrim(oModel:GetErrorMessage()[6])
            If Empty(cMsg) ; cMsg := AllTrim(oModel:GetErrorMessage()[3]) ; EndIf
            If Empty(cMsg) ; cMsg := "Falha ao validar os dados" ; EndIf
            lFalha := .T.
        EndIf
    Else
        cMsg := AllTrim(AllTrim(oModel:GetErrorMessage()[3]) + " " + AllTrim(oModel:GetErrorMessage()[6]))
        If Empty(cMsg) ; cMsg := "Falha ao ativar o modelo" ; EndIf
        lFalha := .T.
    EndIf

    If lAtivado
        oModel:DeActivate()
    EndIf

    If lFalha
        oResp["success"] := .F.
        oResp["message"] := cMsg
    EndIf

Return oResp

/*/{Protheus.doc} ZapAtual
Altera um registro existente de ZAP via modelo MVC do SCT001.PRW. Alteracao
parcial: campos nao informados mantem o valor gravado. Mesma logica de
RESTZAP::AlterarZap.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZapAtual(oReq)

    Local oResp    := JsonObject():New()
    Local oModel   := Nil
    Local cUserP   := ""
    Local cMsg     := ""
    Local lAtivado := .F.
    Local lFalha   := .F.
    Local cSituac  := ""
    Local cNivel   := ""

    If !ZapPode(RetCodUsr())
        oResp["success"] := .F.
        oResp["message"] := "Acesso restrito a administradores ou aprovadores"
        Return oResp
    EndIf

    If ValType(oReq["cUser"]) == "C" ; cUserP := AllTrim(oReq["cUser"]) ; EndIf

    If Empty(cUserP)
        oResp["success"] := .F.
        oResp["message"] := "Parametro 'cUser' e obrigatorio"
        Return oResp
    EndIf

    If !SeekZap(cUserP)
        oResp["success"] := .F.
        oResp["message"] := "Registro nao encontrado"
        Return oResp
    EndIf

    cSituac := AllTrim(oReq["situac"])
    If Empty(cSituac)
        cSituac := SituApi(AllTrim(ZAP->ZAP_SITUAC))
    EndIf

    cNivel := AllTrim(oReq["nivel"])
    If Empty(cNivel)
        cNivel := AllTrim(ZAP->ZAP_NIVEL)
    EndIf

    If Empty(cSituac) .Or. !Pertence("AI", cSituac)
        oResp["success"] := .F.
        oResp["message"] := "Situacao invalida. Informe A - Ativo ou I - Inativo."
        Return oResp
    EndIf

    If Empty(cNivel) .Or. !Pertence("12", cNivel)
        oResp["success"] := .F.
        oResp["message"] := "Nivel de aprovacao invalido. Informe 1 ou 2."
        Return oResp
    EndIf

    oModel := FWLoadModel("SCT001")
    oModel:SetOperation(MODEL_OPERATION_UPDATE)

    If oModel:Activate()
        lAtivado := .T.

        If !Empty(oReq["nuser"])
            oModel:SetValue("ZAPMASTER", "ZAP_NUSER", AllTrim(cValToChar(oReq["nuser"])))
        EndIf
        If !Empty(oReq["situac"])
            oModel:SetValue("ZAPMASTER", "ZAP_SITUAC", SituacDB(cSituac))
        EndIf
        If !Empty(oReq["cc"])
            oModel:SetValue("ZAPMASTER", "ZAP_CC", AllTrim(cValToChar(oReq["cc"])))
        EndIf
        If !Empty(oReq["nivel"])
            oModel:SetValue("ZAPMASTER", "ZAP_NIVEL", cNivel)
        EndIf

        If oModel:VldData()
            oModel:CommitData()
            oResp["success"] := .T.
            oResp["message"] := "Registro alterado com sucesso"
        Else
            cMsg := AllTrim(oModel:GetErrorMessage()[6])
            If Empty(cMsg) ; cMsg := AllTrim(oModel:GetErrorMessage()[3]) ; EndIf
            If Empty(cMsg) ; cMsg := "Falha ao validar os dados" ; EndIf
            lFalha := .T.
        EndIf
    Else
        cMsg := AllTrim(AllTrim(oModel:GetErrorMessage()[3]) + " " + AllTrim(oModel:GetErrorMessage()[6]))
        If Empty(cMsg) ; cMsg := "Falha ao ativar o modelo" ; EndIf
        lFalha := .T.
    EndIf

    If lAtivado
        oModel:DeActivate()
    EndIf

    If lFalha
        oResp["success"] := .F.
        oResp["message"] := cMsg
    EndIf

Return oResp

/*/{Protheus.doc} ZapRemov
Exclui um registro de ZAP via modelo MVC do SCT001.PRW. Mesma logica de
RESTZAP::ExcluirZap.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZapRemov(oReq)

    Local oResp    := JsonObject():New()
    Local oModel   := Nil
    Local cUserP   := ""
    Local cMsg     := ""
    Local lAtivado := .F.
    Local lFalha   := .F.

    If !ZapPode(RetCodUsr())
        oResp["success"] := .F.
        oResp["message"] := "Acesso restrito a administradores ou aprovadores"
        Return oResp
    EndIf

    If ValType(oReq["cUser"]) == "C" ; cUserP := AllTrim(oReq["cUser"]) ; EndIf

    If Empty(cUserP)
        oResp["success"] := .F.
        oResp["message"] := "Parametro 'cUser' e obrigatorio"
        Return oResp
    EndIf

    If !SeekZap(cUserP)
        oResp["success"] := .F.
        oResp["message"] := "Registro nao encontrado"
        Return oResp
    EndIf

    oModel := FWLoadModel("SCT001")
    oModel:SetOperation(MODEL_OPERATION_DELETE)

    If oModel:Activate()
        lAtivado := .T.

        If oModel:VldData()
            oModel:CommitData()
            oResp["success"] := .T.
            oResp["message"] := "Registro excluido com sucesso"
        Else
            cMsg := AllTrim(oModel:GetErrorMessage()[6])
            If Empty(cMsg) ; cMsg := AllTrim(oModel:GetErrorMessage()[3]) ; EndIf
            If Empty(cMsg) ; cMsg := "Falha ao validar os dados" ; EndIf
            lFalha := .T.
        EndIf
    Else
        cMsg := AllTrim(AllTrim(oModel:GetErrorMessage()[3]) + " " + AllTrim(oModel:GetErrorMessage()[6]))
        If Empty(cMsg) ; cMsg := "Falha ao ativar o modelo" ; EndIf
        lFalha := .T.
    EndIf

    If lAtivado
        oModel:DeActivate()
    EndIf

    If lFalha
        oResp["success"] := .F.
        oResp["message"] := cMsg
    EndIf

Return oResp

/*/{Protheus.doc} ZapLkpCC
Lookup de centro de custo (CTT). Mesma logica de RESTZAP::ListaCC.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZapLkpCC(oReq)

    Local oResp     := JsonObject():New()
    Local aItens    := {}
    Local oItem     := Nil
    Local cAliasQ   := GetNextAlias()
    Local cFiltroF  := ""
    Local cLikeCod  := ""
    Local cLikeDesc := ""
    Local nCount    := 0

    If !ZapPode(RetCodUsr())
        oResp["success"] := .F.
        oResp["message"] := "Acesso restrito a administradores ou aprovadores"
        Return oResp
    EndIf

    If ValType(oReq["cFiltro"]) == "C"
        cFiltroF := AllTrim(oReq["cFiltro"])
    EndIf
    cLikeCod  := "%'%" + cFiltroF + "%'%"
    cLikeDesc := cLikeCod

    BeginSql Alias cAliasQ
        SELECT CTT.CTT_CUSTO, CTT.CTT_DESC01 AS CTT_DESC
          FROM %table:CTT% CTT
         WHERE CTT.%notDel%
           AND CTT.CTT_FILIAL = %xfilial:CTT%
           AND (CTT.CTT_CUSTO LIKE %exp:cLikeCod% OR CTT.CTT_DESC01 LIKE %exp:cLikeDesc%)
         ORDER BY CTT.CTT_CUSTO
    EndSql

    While (cAliasQ)->(!Eof()) .And. nCount < 20
        oItem := JsonObject():New()
        oItem["value"] := AllTrim((cAliasQ)->CTT_CUSTO)
        oItem["label"] := AllTrim((cAliasQ)->CTT_DESC)
        aAdd(aItens, oItem)
        nCount++
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

    oResp["success"] := .T.
    oResp["items"]   := aItens
    oResp["hasNext"] := .F.

Return oResp

/*/{Protheus.doc} ZapLkpUs
Lookup de usuarios cadastrados no Protheus (FWSFAllUsers()). Mesma logica de
RESTZAP::LookupUsr.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZapLkpUs(oReq)

    Local oResp    := JsonObject():New()
    Local aItens   := {}
    Local oItem    := Nil
    Local aUsers   := {}
    Local cFiltroF := ""
    Local cCod     := ""
    Local cNome    := ""
    Local nI       := 0
    Local nCount   := 0

    If !ZapPode(RetCodUsr())
        oResp["success"] := .F.
        oResp["message"] := "Acesso restrito a administradores ou aprovadores"
        Return oResp
    EndIf

    If ValType(oReq["cFiltro"]) == "C"
        cFiltroF := Upper(AllTrim(oReq["cFiltro"]))
    EndIf

    aUsers := FWSFAllUsers()

    For nI := 1 To Len(aUsers)
        // FWSFAllUsers() traz [1]=sequencial (nao usar), [2]=codigo, [3]/[4]=nome.
        cCod  := AllTrim(cValToChar(aUsers[nI][2]))
        cNome := AllTrim(cValToChar(aUsers[nI][3]))
        If Empty(cNome)
            cNome := AllTrim(cValToChar(aUsers[nI][4]))
        EndIf

        If Empty(cFiltroF) .Or. cFiltroF $ Upper(cCod) .Or. cFiltroF $ Upper(cNome)
            oItem := JsonObject():New()
            oItem["value"] := cCod
            oItem["label"] := cCod + " - " + cNome
            aAdd(aItens, oItem)
            nCount++
        EndIf

        If nCount >= 20
            Exit
        EndIf
    Next nI

    oResp["success"] := .T.
    oResp["items"]   := aItens
    oResp["hasNext"] := .F.

Return oResp

/*/{Protheus.doc} ZapPerm
Verifica se o usuario logado possui registro ativo em ZAP e/ou consta no
parametro MV_XSCTADM, devolvendo tambem nivel/cc do aprovador. Mesma logica de
RESTZAP::Permissao, mas identificando o usuario via RetCodUsr() (sessao do
SmartClient) em vez de Self:GetUserID() (token Bearer do REST).
@type Static Function
/*/
//=============================================================================================================================
Static Function ZapPerm(oReq)

    Local oResp   := JsonObject():New()
    Local cUserId := RetCodUsr()

    oResp["success"]     := .T.
    oResp["user"]        := cUserId
    oResp["isAprovador"] := .F.
    oResp["isAdmin"]     := !Empty(cUserId) .And. cUserId $ GetMv("MV_XSCTADM")
    oResp["nivel"]       := ""
    oResp["cc"]          := ""

    If !Empty(cUserId)
        If SeekZap(cUserId)
            oResp["isAprovador"] := (AllTrim(ZAP->ZAP_SITUAC) == "1")
            oResp["nivel"]       := AllTrim(ZAP->ZAP_NIVEL)
            oResp["cc"]          := AllTrim(ZAP->ZAP_CC)
        EndIf
    EndIf

Return oResp

/*/{Protheus.doc} StatDesc
Traduz o codigo de status (ZSC_STATUS) para descricao legivel. Mesma logica de
RESTSCT.PRW::StatDesc.
@type Static Function
/*/
//=============================================================================================================================
Static Function StatDesc(cStatus)

    Local cDesc := "Desconhecido"

    Do Case
    Case cStatus == "1" ; cDesc := "Rascunho"
    Case cStatus == "2" ; cDesc := "Aguardando Aprovacao N1"
    Case cStatus == "3" ; cDesc := "Aguardando Aprovacao N2"
    Case cStatus == "4" ; cDesc := "Aprovado"
    Case cStatus == "5" ; cDesc := "Reprovado"
    EndCase

Return cDesc

/*/{Protheus.doc} DtoSNull
Converte data para AAAA-MM-DD, tolerando NIL/vazio/Character. Mesma logica de
RESTSCT.PRW::DtoSNull.
@type Static Function
/*/
//=============================================================================================================================
Static Function DtoSNull(dData)

    Local cRet := ""
    Local cAux := ""

    If ValType(dData) == "D" .And. !Empty(dData)
        cAux := DtoS(dData)
    ElseIf ValType(dData) == "C" .And. !Empty(AllTrim(dData))
        cAux := AllTrim(dData)
    EndIf

    If Len(cAux) == 8
        cRet := SubStr(cAux, 1, 4) + "-" + SubStr(cAux, 5, 2) + "-" + SubStr(cAux, 7, 2)
    EndIf

Return cRet

/*/{Protheus.doc} SToDNull
Converte data no formato AAAA-MM-DD (recebida do Angular) para Date, tolerando
NIL/vazio/formato invalido. Inversa de DtoSNull.
@type Static Function
/*/
//=============================================================================================================================
Static Function SToDNull(cData)

    Local dRet := CtoD("")
    Local cAux := ""

    If ValType(cData) == "C" .And. !Empty(AllTrim(cData))
        cAux := StrTran(AllTrim(cData), "-", "")
        If Len(cAux) == 8
            dRet := STOD(cAux)
        EndIf
    EndIf

Return dRet

/*/{Protheus.doc} AssinDig
Monta a frase de assinatura digital do comprovante ("Aprovado digitalmente por
[Nome] em [Data/Hora]"). Mesma logica de RESTSCT.PRW::AssinDig.
@type Static Function
/*/
//=============================================================================================================================
Static Function AssinDig(cNome, dData, cHora)

    Local cRet := ""

    If !Empty(AllTrim(cNome)) .And. ValType(dData) == "D" .And. !Empty(dData)
        cRet := "Aprovado digitalmente por " + AllTrim(cNome) + " em " + DToC(dData)
        If !Empty(AllTrim(cHora))
            cRet += " " + AllTrim(cHora)
        EndIf
    EndIf

Return cRet

/*/{Protheus.doc} LerMemo
Le o conteudo de um campo Memo lido de um alias real. Mesma logica de
RESTSCT.PRW::LerMemo.
@type Static Function
/*/
//=============================================================================================================================
Static Function LerMemo(xValor)

    Local cRet := ""

    If ValType(xValor) == "C"
        cRet := AllTrim(xValor)
    EndIf

Return cRet

/*/{Protheus.doc} NecesZsc
Le o conteudo do campo Memo ZSC_NECES posicionando no alias real. Mesma logica
de RESTSCT.PRW::NecesZsc.
@type Static Function
/*/
//=============================================================================================================================
Static Function NecesZsc(cNum, nTam)

    Local cNeces   := ""
    Local aArea    := FWGetArea()
    Local aAreaZSC := {}
    Local nPos     := 0

    Default cNum := ""
    Default nTam := 0

    DbSelectArea("ZSC")
    aAreaZSC := ZSC->(FWGetArea())

    ZSC->(DbSetOrder(1))

    nPos := TamSX3("ZSC_NUM")[1]

    If ZSC->(DbSeek(xFilial("ZSC") + PadR(AllTrim(cNum), nPos)))

        cNeces := LerMemo(ZSC->ZSC_NECES)

        If nTam > 0 .And. Len(cNeces) > nTam
            cNeces := Left(cNeces, nTam)
        EndIf

    EndIf

    FWRestArea(aAreaZSC)
    FWRestArea(aArea)

Return cNeces

/*/{Protheus.doc} ObsZsd
Le o conteudo do campo Memo ZSD_OBS. Mesma logica de RESTSCT.PRW::ObsZsd.
@type Static Function
/*/
//=============================================================================================================================
Static Function ObsZsd(cNum, cItem)

    Local cObs := ""

    DbSelectArea("ZSD")
    ZSD->(DbSetOrder(1)) // ZSD_FILIAL+ZSD_NUM+ZSD_ITEM
    If ZSD->(DbSeek(xFilial("ZSD") + PadR(cNum, TamSX3("ZSD_NUM")[1]) + PadR(cItem, TamSX3("ZSD_ITEM")[1])))
        cObs := LerMemo(ZSD->ZSD_OBS)
    EndIf

Return cObs

/*/{Protheus.doc} ProxItCT
Calcula o proximo item (sequencial de 2 digitos) de cotacao (ZSD). Mesma logica
de RESTSCT.PRW::ProxItCT.
@type Static Function
/*/
//=============================================================================================================================
Static Function ProxItCT(cNum)

    Local cAliasQ := GetNextAlias()
    Local nMaior  := 0

    BeginSql Alias cAliasQ
        SELECT MAX(CAST(ZSD.ZSD_ITEM AS INT)) AS MAIOR
          FROM %table:ZSD% ZSD
         WHERE ZSD.%notDel%
           AND ZSD.ZSD_FILIAL = %xfilial:ZSD%
           AND ZSD.ZSD_NUM    = %exp:Alltrim(cNum)%
    EndSql

    If (cAliasQ)->(!Eof()) .And. !Empty((cAliasQ)->MAIOR)
        nMaior := (cAliasQ)->MAIOR
    EndIf
    (cAliasQ)->(DbCloseArea())

Return StrZero(nMaior + 1, TamSX3("ZSD_ITEM")[1])

/*/{Protheus.doc} ProxItAn
Calcula o proximo item (sequencial de 2 digitos) de anexo (ZSE). Mesma logica
de RESTSCT.PRW::ProxItAn.
@type Static Function
/*/
//=============================================================================================================================
Static Function ProxItAn(cNum)

    Local cAliasQ := GetNextAlias()
    Local nMaior  := 0

    BeginSql Alias cAliasQ
        SELECT MAX(CAST(ZSE.ZSE_ITEM AS INT)) AS MAIOR
          FROM %table:ZSE% ZSE
         WHERE ZSE.%notDel%
           AND ZSE.ZSE_FILIAL = %xfilial:ZSE%
           AND ZSE.ZSE_NUM    = %exp:Alltrim(cNum)%
    EndSql

    If (cAliasQ)->(!Eof()) .And. !Empty((cAliasQ)->MAIOR)
        nMaior := (cAliasQ)->MAIOR
    EndIf
    (cAliasQ)->(DbCloseArea())

Return StrZero(nMaior + 1, TamSX3("ZSE_ITEM")[1])

/*/{Protheus.doc} SituAtu
Le ZSC_STATUS e ZSC_CC gravados em disco para o numero de solicitacao
informado. Mesma logica de RESTSCT.PRW::SituAtu.
@type Static Function
@return array, {lEncontrado, cStatus, cCC}
/*/
//=============================================================================================================================
Static Function SituAtu(cNum)

    Local cAliasQ := GetNextAlias()
    Local lAchou  := .F.
    Local cStatus := ""
    Local cCC     := ""

    BeginSql Alias cAliasQ
        SELECT ZSC.ZSC_STATUS, ZSC.ZSC_CC
          FROM %table:ZSC% ZSC
         WHERE ZSC.%notDel%
           AND ZSC.ZSC_FILIAL = %xfilial:ZSC%
           AND ZSC.ZSC_NUM    = %exp:Alltrim(cNum)%
    EndSql

    If (cAliasQ)->(!Eof())
        lAchou  := .T.
        cStatus := Alltrim((cAliasQ)->ZSC_STATUS)
        cCC     := Alltrim((cAliasQ)->ZSC_CC)
    EndIf
    (cAliasQ)->(DbCloseArea())

Return {lAchou, cStatus, cCC}

/*/{Protheus.doc} DadosApr
Le o registro do usuario logado na tabela ZAP (aprovadores). Mesma logica de
RESTSCT.PRW::DadosApr.
@type Static Function
@return array, {lAtivo, cNivel, cCC}
/*/
//=============================================================================================================================
Static Function DadosApr(cUserId)

    Local lAtivo   := .F.
    Local cNivel   := ""
    Local cCC      := ""
    Local cAliasQ  := GetNextAlias()

    BeginSql Alias cAliasQ
        SELECT ZAP.ZAP_SITUAC, ZAP.ZAP_NIVEL, ZAP.ZAP_CC
          FROM %table:ZAP% ZAP
         WHERE ZAP.%notDel%
           AND ZAP.ZAP_FILIAL = %xfilial:ZAP%
           AND ZAP.ZAP_USER   = %exp:Alltrim(cUserId)%
    EndSql

    If !(cAliasQ)->(Eof())
        lAtivo := (Alltrim((cAliasQ)->ZAP_SITUAC) == "1")
        cNivel := Alltrim((cAliasQ)->ZAP_NIVEL)
        cCC    := Alltrim((cAliasQ)->ZAP_CC)
    EndIf
    (cAliasQ)->(DbCloseArea())

Return {lAtivo, cNivel, cCC}

/*/{Protheus.doc} ValidApr
Confirma se o usuario logado pode aprovar/reprovar no nivel exigido pelo status
atual da solicitacao. Mesma logica de RESTSCT.PRW::ValidApr.
@type Static Function
@return array, {lPodeAprovar, cMsgErro}
/*/
//=============================================================================================================================
Static Function ValidApr(cUserId, cNivelExigido, cCCSolic)

    Local aDados  := DadosApr(cUserId)
    Local lAtivo  := aDados[1]
    Local cNivel  := aDados[2]
    Local cCC     := aDados[3]

    If !lAtivo
        Return {.F., "Usuario nao e um aprovador ativo."}
    EndIf

    If cNivel != cNivelExigido
        Return {.F., "Usuario nao e aprovador do Nivel " + cNivelExigido + " exigido para esta etapa."}
    EndIf

    If !Empty(cCC) .And. cCC != Alltrim(cCCSolic)
        Return {.F., "Usuario so aprova solicitacoes do centro de custo " + cCC + "."}
    EndIf

Return {.T., ""}

/*/{Protheus.doc} CotacSol
Le as linhas de cotacao (ZSD) de uma solicitacao. Mesma logica de
RESTSCT.PRW::CotacSol.
@type Static Function
@return array de subarrays {item, fornec, valor, venced ("S"/"N"), obs}
/*/
//=============================================================================================================================
Static Function CotacSol(cNum)

    Local cAliasQ  := GetNextAlias()
    Local aCotac   := {}

    BeginSql Alias cAliasQ
        SELECT ZSD.ZSD_ITEM, ZSD.ZSD_FORNEC, ZSD.ZSD_VALOR, ZSD.ZSD_VENCED
          FROM %table:ZSD% ZSD
         WHERE ZSD.%notDel%
           AND ZSD.ZSD_FILIAL = %xfilial:ZSD%
           AND ZSD.ZSD_NUM    = %exp:Alltrim(cNum)%
         ORDER BY ZSD.ZSD_ITEM
    EndSql

    While (cAliasQ)->(!Eof())
        aAdd(aCotac, {Alltrim((cAliasQ)->ZSD_ITEM), Alltrim((cAliasQ)->ZSD_FORNEC), (cAliasQ)->ZSD_VALOR, Alltrim((cAliasQ)->ZSD_VENCED), ObsZsd(Alltrim(cNum), Alltrim((cAliasQ)->ZSD_ITEM))})
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

Return aCotac

/*/{Protheus.doc} MenorVal
Retorna o menor valor entre as cotacoes informadas. Mesma logica de
RESTSCT.PRW::MenorVal.
@type Static Function
/*/
//=============================================================================================================================
Static Function MenorVal(aCotac)

    Local nMenor := 0
    Local nI      := 0

    For nI := 1 To Len(aCotac)
        If nMenor == 0 .Or. aCotac[nI][3] < nMenor
            nMenor := aCotac[nI][3]
        EndIf
    Next nI

Return nMenor

/*/{Protheus.doc} ValidEnv
Confirma se a solicitacao atende todos os requisitos para ser enviada para
aprovacao. Mesma logica de RESTSCT.PRW::ValidEnv.
@type Static Function
@return array, {lPodeEnviar, cMsgErro}
/*/
//=============================================================================================================================
Static Function ValidEnv(cNum)

    Local cNeces     := ""
    Local cCC        := ""
    Local cVenced    := ""
    Local cJustif    := ""
    Local aCotac     := CotacSol(cNum)
    Local nValidas   := 0
    Local nVencedCnt := 0
    Local nValorVenc := 0
    Local nMenor     := 0
    Local nAnexos    := 0
    Local nI         := 0
    Local cAliasQ    := ""

    DbSelectArea("ZSC")
    ZSC->(DbSetOrder(1)) // ZSC_FILIAL+ZSC_NUM
    If !ZSC->(DbSeek(xFilial("ZSC") + PadR(Alltrim(cNum), TamSX3("ZSC_NUM")[1])))
        Return {.F., "Solicitacao nao encontrada."}
    EndIf

    cNeces  := LerMemo(ZSC->ZSC_NECES)
    cCC     := Alltrim(ZSC->ZSC_CC)
    cVenced := Alltrim(ZSC->ZSC_VENCED)
    cJustif := LerMemo(ZSC->ZSC_JUSTIF)

    If Empty(cNeces)
        Return {.F., "Descreva a necessidade do contrato antes de enviar para aprovacao."}
    EndIf

    If Empty(cCC)
        Return {.F., "Informe o centro de custo antes de enviar para aprovacao."}
    EndIf

    For nI := 1 To Len(aCotac)
        If !Empty(aCotac[nI][2]) .And. aCotac[nI][3] > 0
            nValidas++
        EndIf
        If aCotac[nI][4] == "S"
            nVencedCnt++
            nValorVenc := aCotac[nI][3]
        EndIf
    Next nI

    If nValidas < 3
        Return {.F., "Sao necessarias no minimo 3 cotacoes com fornecedor e valor preenchidos."}
    EndIf

    If Empty(cVenced) .Or. nVencedCnt != 1
        Return {.F., "Selecione uma (e somente uma) cotacao vencedora."}
    EndIf

    nMenor := MenorVal(aCotac)
    If nValorVenc > nMenor .And. Empty(cJustif)
        Return {.F., "A cotacao vencedora nao e a de menor valor -- informe a justificativa da escolha."}
    EndIf

    cAliasQ := GetNextAlias()
    BeginSql Alias cAliasQ
        SELECT COUNT(*) AS QTD
          FROM %table:ZSE% ZSE
         WHERE ZSE.%notDel%
           AND ZSE.ZSE_FILIAL = %xfilial:ZSE%
           AND ZSE.ZSE_NUM    = %exp:Alltrim(cNum)%
    EndSql
    nAnexos := (cAliasQ)->QTD
    (cAliasQ)->(DbCloseArea())

    If nAnexos < 1
        Return {.F., "Anexe pelo menos um arquivo (cotacao/orcamento) antes de enviar para aprovacao."}
    EndIf

Return {.T., ""}

/*/{Protheus.doc} ZscList
Lista as solicitacoes, aceitando filtros opcionais cStatus/cSolici/cCC. Mesma
consulta de RESTSCT::ListaZ.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZscList(oReq)

    Local oResp    := JsonObject():New()
    Local aItens   := {}
    Local oItem    := Nil
    Local cAliasQ  := GetNextAlias()
    Local cStatusF := ""
    Local cSoliciF := ""
    Local cCCF     := ""
    Local cWhere   := ""

    If ValType(oReq["cStatus"]) == "C" ; cStatusF := AllTrim(oReq["cStatus"]) ; EndIf
    If ValType(oReq["cSolici"]) == "C" ; cSoliciF := AllTrim(oReq["cSolici"]) ; EndIf
    If ValType(oReq["cCC"]) == "C"     ; cCCF     := AllTrim(oReq["cCC"])     ; EndIf

    If !Empty(cStatusF)
        cWhere += " AND ZSC.ZSC_STATUS = '" + cStatusF + "'"
    EndIf
    If !Empty(cSoliciF)
        cWhere += " AND ZSC.ZSC_SOLICI = '" + cSoliciF + "'"
    EndIf
    If !Empty(cCCF)
        cWhere += " AND ZSC.ZSC_CC = '" + cCCF + "'"
    EndIf
    cWhere := "%" + cWhere + "%"

    BeginSql Alias cAliasQ
        SELECT ZSC.ZSC_NUM, ZSC.ZSC_CC, ZSC.ZSC_NECES,
               ZSC.ZSC_SOLICI, ZSC.ZSC_NSOLIC,
               ZSC.ZSC_DTSOLI, ZSC.ZSC_STATUS, ZSC.ZSC_VENCED,
               ISNULL(CTT.CTT_DESC01, '') AS CTT_DESC
          FROM %table:ZSC% ZSC
          LEFT JOIN %table:CTT% CTT
            ON  CTT.D_E_L_E_T_ = ' '
            AND CTT.CTT_FILIAL = %xfilial:CTT%
            AND CTT.CTT_CUSTO  = ZSC.ZSC_CC
         WHERE ZSC.%notDel%
           AND ZSC.ZSC_FILIAL = %xfilial:ZSC%
           %exp:cWhere%
         ORDER BY ZSC.ZSC_NUM DESC
    EndSql

    While (cAliasQ)->(!Eof())
        oItem := JsonObject():New()
        oItem["num"]        := AllTrim((cAliasQ)->ZSC_NUM)
        oItem["cc"]         := AllTrim((cAliasQ)->ZSC_CC)
        oItem["ccDesc"]     := AllTrim((cAliasQ)->CTT_DESC)
        oItem["necessidade"]:= NecesZsc(Alltrim((cAliasQ)->ZSC_NUM), 100)
        oItem["solicitante"]:= AllTrim((cAliasQ)->ZSC_SOLICI)
        oItem["nomeSolic"]  := AllTrim((cAliasQ)->ZSC_NSOLIC)
        oItem["dataSolic"]  := DtoSNull((cAliasQ)->ZSC_DTSOLI)
        oItem["status"]     := AllTrim((cAliasQ)->ZSC_STATUS)
        oItem["statusDesc"] := StatDesc(AllTrim((cAliasQ)->ZSC_STATUS))
        oItem["vencedor"]   := AllTrim((cAliasQ)->ZSC_VENCED)
        aAdd(aItens, oItem)
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

    oResp["success"] := .T.
    oResp["items"]   := aItens

Return oResp

/*/{Protheus.doc} ZscDetal
Obtem uma solicitacao completa: cabecalho + cotacoes[] + anexos[]. Mesma logica
de RESTSCT::ObtZsc.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZscDetal(oReq)

    Local oResp    := JsonObject():New()
    Local aCotJson := {}
    Local aAneJson := {}
    Local oLinha   := Nil
    Local cAliasQ  := Nil
    Local cNumP    := ""

    If ValType(oReq["cNum"]) == "C" ; cNumP := AllTrim(oReq["cNum"]) ; EndIf

    If Empty(cNumP)
        oResp["success"] := .F.
        oResp["message"] := "Parametro 'cNum' e obrigatorio"
        Return oResp
    EndIf

    DbSelectArea("ZSC")
    ZSC->(DbSetOrder(1)) // ZSC_FILIAL+ZSC_NUM
    If !ZSC->(DbSeek(xFilial("ZSC") + PadR(cNumP, TamSX3("ZSC_NUM")[1])))
        oResp["success"] := .F.
        oResp["message"] := "Solicitacao nao encontrada"
        Return oResp
    EndIf

    oResp["success"]      := .T.
    oResp["num"]          := AllTrim(ZSC->ZSC_NUM)
    oResp["cc"]           := AllTrim(ZSC->ZSC_CC)
    oResp["ccDesc"]       := AllTrim(Posicione("CTT", 1, xFilial("CTT") + ZSC->ZSC_CC, "CTT_DESC01"))
    oResp["necessidade"]  := LerMemo(ZSC->ZSC_NECES)
    oResp["solicitante"]  := AllTrim(ZSC->ZSC_SOLICI)
    oResp["nomeSolic"]    := AllTrim(ZSC->ZSC_NSOLIC)
    oResp["dataSolic"]    := DtoSNull(ZSC->ZSC_DTSOLI)
    oResp["status"]       := AllTrim(ZSC->ZSC_STATUS)
    oResp["statusDesc"]   := StatDesc(AllTrim(ZSC->ZSC_STATUS))
    oResp["vencedor"]     := AllTrim(ZSC->ZSC_VENCED)
    oResp["dataInicio"]          := DtoSNull(ZSC->ZSC_DTINI)
    oResp["vigencia"]            := ZSC->ZSC_VIGEN
    oResp["substituicao"]        := (AllTrim(ZSC->ZSC_SUBST) == "S")
    oResp["contratoSubstituido"] := AllTrim(ZSC->ZSC_CTSUB)
    oResp["justificativa"]:= LerMemo(ZSC->ZSC_JUSTIF)
    oResp["motivoReprov"] := LerMemo(ZSC->ZSC_MOTREP)
    oResp["nomeAprovN1"]  := AllTrim(ZSC->ZSC_NUSAP1)
    oResp["dataAprovN1"]  := DtoSNull(ZSC->ZSC_DTAPR1)
    oResp["horaAprovN1"]  := AllTrim(ZSC->ZSC_HRAPR1)
    oResp["assinaturaN1"] := AssinDig(ZSC->ZSC_NUSAP1, ZSC->ZSC_DTAPR1, ZSC->ZSC_HRAPR1)
    oResp["nomeAprovN2"]  := AllTrim(ZSC->ZSC_NUSAP2)
    oResp["dataAprovN2"]  := DtoSNull(ZSC->ZSC_DTAPR2)
    oResp["horaAprovN2"]  := AllTrim(ZSC->ZSC_HRAPR2)
    oResp["assinaturaN2"] := AssinDig(ZSC->ZSC_NUSAP2, ZSC->ZSC_DTAPR2, ZSC->ZSC_HRAPR2)

    cAliasQ := GetNextAlias()
    BeginSql Alias cAliasQ
        SELECT ZSD.ZSD_ITEM, ZSD.ZSD_FORNEC, ZSD.ZSD_VALOR, ZSD.ZSD_VENCED
          FROM %table:ZSD% ZSD
         WHERE ZSD.%notDel%
           AND ZSD.ZSD_FILIAL = %xfilial:ZSD%
           AND ZSD.ZSD_NUM    = %exp:cNumP%
         ORDER BY ZSD.ZSD_ITEM
    EndSql
    While (cAliasQ)->(!Eof())
        oLinha := JsonObject():New()
        oLinha["item"]      := AllTrim((cAliasQ)->ZSD_ITEM)
        oLinha["fornecedor"]:= AllTrim((cAliasQ)->ZSD_FORNEC)
        oLinha["valor"]     := (cAliasQ)->ZSD_VALOR
        oLinha["vencedor"]  := (Alltrim((cAliasQ)->ZSD_VENCED) == "S")
        oLinha["obs"]       := ObsZsd(cNumP, Alltrim((cAliasQ)->ZSD_ITEM))
        aAdd(aCotJson, oLinha)
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())
    oResp["cotacoes"] := aCotJson

    cAliasQ := GetNextAlias()
    BeginSql Alias cAliasQ
        SELECT ZSE.ZSE_ITEM, ZSE.ZSE_ARQUIV, ZSE.ZSE_TAMANH, ZSE.ZSE_DTANEX, ZSE.ZSE_USUANE
          FROM %table:ZSE% ZSE
         WHERE ZSE.%notDel%
           AND ZSE.ZSE_FILIAL = %xfilial:ZSE%
           AND ZSE.ZSE_NUM    = %exp:cNumP%
         ORDER BY ZSE.ZSE_ITEM
    EndSql
    While (cAliasQ)->(!Eof())
        oLinha := JsonObject():New()
        oLinha["item"]     := AllTrim((cAliasQ)->ZSE_ITEM)
        oLinha["nome"]     := AllTrim((cAliasQ)->ZSE_ARQUIV)
        oLinha["tamanho"]  := (cAliasQ)->ZSE_TAMANH
        oLinha["data"]     := DtoSNull((cAliasQ)->ZSE_DTANEX)
        oLinha["usuario"]  := AllTrim((cAliasQ)->ZSE_USUANE)
        aAdd(aAneJson, oLinha)
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())
    oResp["anexos"] := aAneJson

Return oResp

/*/{Protheus.doc} ZscCria
Cria uma solicitacao em Rascunho. Solicitante/data vem do usuario logado
(RetCodUsr()), nao do payload. Mesma logica de RESTSCT::IncZsc.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZscCria(oReq)

    Local oResp      := JsonObject():New()
    Local cUserId    := RetCodUsr()
    Local cNum       := ""
    Local nVigencia  := 0
    Local lSubst     := .F.
    Local cCtSub     := ""

    If Empty(AllTrim(cValToChar(oReq["necessidade"])))
        oResp["success"] := .F.
        oResp["message"] := "Informe a descricao da necessidade do contrato"
        Return oResp
    EndIf

    lSubst := (ValType(oReq["substituicao"]) == "L" .And. oReq["substituicao"])
    cCtSub := AllTrim(cValToChar(oReq["contratoSubstituido"]))

    If lSubst .And. Empty(cCtSub)
        oResp["success"] := .F.
        oResp["message"] := "Informe o numero do contrato substituido"
        Return oResp
    EndIf

    If ValType(oReq["vigencia"]) == "N"
        nVigencia := oReq["vigencia"]
    EndIf

    cNum := GetSxeNum("ZSC", "ZSC_NUM")

    DbSelectArea("ZSC")
    RecLock("ZSC", .T.)
        ZSC->ZSC_FILIAL := xFilial("ZSC")
        ZSC->ZSC_NUM    := cNum
        ZSC->ZSC_CC     := oReq["cc"]
        ZSC->ZSC_NECES  := oReq["necessidade"]
        ZSC->ZSC_SOLICI := cUserId
        ZSC->ZSC_NSOLIC := UsrRetName(cUserId)
        ZSC->ZSC_DTSOLI := Date()
        ZSC->ZSC_STATUS := "1"
        ZSC->ZSC_DTINI  := SToDNull(oReq["dataInicio"])
        ZSC->ZSC_VIGEN  := nVigencia
        ZSC->ZSC_SUBST  := If(lSubst, "S", "N")
        ZSC->ZSC_CTSUB  := If(lSubst, cCtSub, "")
    MsUnlock()
    ConfirmSX8()

    oResp["success"] := .T.
    oResp["num"]     := AllTrim(cNum)
    oResp["message"] := "Solicitacao criada com sucesso"

Return oResp

/*/{Protheus.doc} ZscAtual
Altera necessidade/centro de custo/dados do contrato (data de inicio,
vigencia, substituicao e contrato substituido). Permitido apenas em
Rascunho (1) ou Reprovado (5). Mesma logica de RESTSCT::AltZsc.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZscAtual(oReq)

    Local oResp    := JsonObject():New()
    Local cNumP    := ""
    Local aSituac  := Nil
    Local lSubst   := .F.
    Local cCtSub   := ""

    If ValType(oReq["cNum"]) == "C" ; cNumP := AllTrim(oReq["cNum"]) ; EndIf

    If Empty(cNumP)
        oResp["success"] := .F.
        oResp["message"] := "Parametro 'cNum' e obrigatorio"
        Return oResp
    EndIf

    aSituac := SituAtu(cNumP)
    If !aSituac[1]
        oResp["success"] := .F.
        oResp["message"] := "Solicitacao nao encontrada"
        Return oResp
    EndIf
    If !(aSituac[2] $ "15")
        oResp["success"] := .F.
        oResp["message"] := "So e possivel alterar a solicitacao em Rascunho ou Reprovado"
        Return oResp
    EndIf

    If ValType(oReq["substituicao"]) == "L"
        lSubst := oReq["substituicao"]
        cCtSub := AllTrim(cValToChar(oReq["contratoSubstituido"]))
        If lSubst .And. Empty(cCtSub)
            oResp["success"] := .F.
            oResp["message"] := "Informe o numero do contrato substituido"
            Return oResp
        EndIf
    EndIf

    DbSelectArea("ZSC")
    ZSC->(DbSetOrder(1)) // ZSC_FILIAL+ZSC_NUM
    ZSC->(DbSeek(xFilial("ZSC") + PadR(cNumP, TamSX3("ZSC_NUM")[1])))
    RecLock("ZSC", .F.)
        If !Empty(oReq["necessidade"])
            ZSC->ZSC_NECES := oReq["necessidade"]
        EndIf
        If !Empty(oReq["cc"])
            ZSC->ZSC_CC := oReq["cc"]
        EndIf
        If !Empty(oReq["dataInicio"])
            ZSC->ZSC_DTINI := SToDNull(oReq["dataInicio"])
        EndIf
        If ValType(oReq["vigencia"]) == "N"
            ZSC->ZSC_VIGEN := oReq["vigencia"]
        EndIf
        If ValType(oReq["substituicao"]) == "L"
            ZSC->ZSC_SUBST := If(lSubst, "S", "N")
            ZSC->ZSC_CTSUB := If(lSubst, cCtSub, "")
        EndIf
    MsUnlock()

    oResp["success"] := .T.
    oResp["message"] := "Solicitacao alterada com sucesso"

Return oResp

/*/{Protheus.doc} ZscCtCri
Inclui uma linha de cotacao. Permitido apenas em Rascunho ou Reprovado. Mesma
logica de RESTSCT::IncCT.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZscCtCri(oReq)

    Local oResp    := JsonObject():New()
    Local cNumP    := ""
    Local cItem    := ""
    Local aSituac  := Nil

    If ValType(oReq["cNum"]) == "C" ; cNumP := AllTrim(oReq["cNum"]) ; EndIf

    If Empty(cNumP)
        oResp["success"] := .F.
        oResp["message"] := "Parametro 'cNum' e obrigatorio"
        Return oResp
    EndIf

    aSituac := SituAtu(cNumP)
    If !aSituac[1]
        oResp["success"] := .F.
        oResp["message"] := "Solicitacao nao encontrada"
        Return oResp
    EndIf
    If !(aSituac[2] $ "15")
        oResp["success"] := .F.
        oResp["message"] := "So e possivel incluir cotacao com a solicitacao em Rascunho ou Reprovado"
        Return oResp
    EndIf

    If Empty(AllTrim(cValToChar(oReq["fornecedor"])))
        oResp["success"] := .F.
        oResp["message"] := "Informe o nome do fornecedor"
        Return oResp
    EndIf

    If ValType(oReq["valor"]) != "N" .Or. oReq["valor"] <= 0
        oResp["success"] := .F.
        oResp["message"] := "Informe um valor de cotacao maior que zero"
        Return oResp
    EndIf

    cItem := ProxItCT(cNumP)

    DbSelectArea("ZSD")
    RecLock("ZSD", .T.)
        ZSD->ZSD_FILIAL := xFilial("ZSD")
        ZSD->ZSD_NUM    := PadR(cNumP, TamSX3("ZSD_NUM")[1])
        ZSD->ZSD_ITEM   := cItem
        ZSD->ZSD_FORNEC := oReq["fornecedor"]
        ZSD->ZSD_VALOR  := oReq["valor"]
        ZSD->ZSD_VENCED := "N"
        ZSD->ZSD_OBS    := oReq["obs"]
    MsUnlock()

    oResp["success"] := .T.
    oResp["item"]    := cItem
    oResp["message"] := "Cotacao incluida com sucesso"

Return oResp

/*/{Protheus.doc} ZscCtAtu
Altera uma linha de cotacao existente. Permitido apenas em Rascunho ou
Reprovado. Mesma logica de RESTSCT::AltCT.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZscCtAtu(oReq)

    Local oResp    := JsonObject():New()
    Local cNumP    := ""
    Local cItemP   := ""
    Local aSituac  := Nil

    If ValType(oReq["cNum"]) == "C"  ; cNumP  := AllTrim(oReq["cNum"])  ; EndIf
    If ValType(oReq["cItem"]) == "C" ; cItemP := AllTrim(oReq["cItem"]) ; EndIf

    If Empty(cNumP) .Or. Empty(cItemP)
        oResp["success"] := .F.
        oResp["message"] := "Parametros 'cNum' e 'cItem' sao obrigatorios"
        Return oResp
    EndIf

    aSituac := SituAtu(cNumP)
    If !aSituac[1]
        oResp["success"] := .F.
        oResp["message"] := "Solicitacao nao encontrada"
        Return oResp
    EndIf
    If !(aSituac[2] $ "15")
        oResp["success"] := .F.
        oResp["message"] := "So e possivel alterar cotacao com a solicitacao em Rascunho ou Reprovado"
        Return oResp
    EndIf

    DbSelectArea("ZSD")
    ZSD->(DbSetOrder(1)) // ZSD_FILIAL+ZSD_NUM+ZSD_ITEM
    If !ZSD->(DbSeek(xFilial("ZSD") + PadR(cNumP, TamSX3("ZSD_NUM")[1]) + PadR(cItemP, TamSX3("ZSD_ITEM")[1])))
        oResp["success"] := .F.
        oResp["message"] := "Cotacao nao encontrada"
        Return oResp
    EndIf

    RecLock("ZSD", .F.)
        If !Empty(oReq["fornecedor"])
            ZSD->ZSD_FORNEC := oReq["fornecedor"]
        EndIf
        If ValType(oReq["valor"]) == "N" .And. oReq["valor"] > 0
            ZSD->ZSD_VALOR := oReq["valor"]
        EndIf
        If !Empty(oReq["obs"])
            ZSD->ZSD_OBS := oReq["obs"]
        EndIf
    MsUnlock()

    oResp["success"] := .T.
    oResp["message"] := "Cotacao alterada com sucesso"

Return oResp

/*/{Protheus.doc} ZscCtRem
Exclui uma linha de cotacao. Se era a vencedora, limpa o vencedor da
solicitacao. Mesma logica de RESTSCT::CTDel.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZscCtRem(oReq)

    Local oResp    := JsonObject():New()
    Local cNumP    := ""
    Local cItemP   := ""
    Local aSituac  := Nil
    Local lEraVenc := .F.

    If ValType(oReq["cNum"]) == "C"  ; cNumP  := AllTrim(oReq["cNum"])  ; EndIf
    If ValType(oReq["cItem"]) == "C" ; cItemP := AllTrim(oReq["cItem"]) ; EndIf

    If Empty(cNumP) .Or. Empty(cItemP)
        oResp["success"] := .F.
        oResp["message"] := "Parametros 'cNum' e 'cItem' sao obrigatorios"
        Return oResp
    EndIf

    aSituac := SituAtu(cNumP)
    If !aSituac[1]
        oResp["success"] := .F.
        oResp["message"] := "Solicitacao nao encontrada"
        Return oResp
    EndIf
    If !(aSituac[2] $ "15")
        oResp["success"] := .F.
        oResp["message"] := "So e possivel excluir cotacao com a solicitacao em Rascunho ou Reprovado"
        Return oResp
    EndIf

    DbSelectArea("ZSD")
    ZSD->(DbSetOrder(1)) // ZSD_FILIAL+ZSD_NUM+ZSD_ITEM
    If !ZSD->(DbSeek(xFilial("ZSD") + PadR(cNumP, TamSX3("ZSD_NUM")[1]) + PadR(cItemP, TamSX3("ZSD_ITEM")[1])))
        oResp["success"] := .F.
        oResp["message"] := "Cotacao nao encontrada"
        Return oResp
    EndIf

    lEraVenc := (Alltrim(ZSD->ZSD_VENCED) == "S")

    RecLock("ZSD", .F.)
        ZSD->(DbDelete())
    MsUnlock()

    If lEraVenc
        DbSelectArea("ZSC")
        ZSC->(DbSetOrder(1)) // ZSC_FILIAL+ZSC_NUM
        If ZSC->(DbSeek(xFilial("ZSC") + PadR(cNumP, TamSX3("ZSC_NUM")[1])))
            RecLock("ZSC", .F.)
                ZSC->ZSC_VENCED := ""
                ZSC->ZSC_JUSTIF := ""
            MsUnlock()
        EndIf
    EndIf

    oResp["success"] := .T.
    oResp["message"] := "Cotacao excluida com sucesso"

Return oResp

/*/{Protheus.doc} ZscVenDf
Define a cotacao vencedora, exigindo justificativa se nao for a de menor
valor. Mesma logica de RESTSCT::DefVen.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZscVenDf(oReq)

    Local oResp      := JsonObject():New()
    Local cNumP      := ""
    Local cItemVenc  := ""
    Local cJustif    := ""
    Local aSituac    := Nil
    Local aCotac     := Nil
    Local nValorVenc := 0
    Local nMenor     := 0
    Local lAchouItem := .F.
    Local nI         := 0

    If ValType(oReq["cNum"]) == "C" ; cNumP := AllTrim(oReq["cNum"]) ; EndIf

    If Empty(cNumP)
        oResp["success"] := .F.
        oResp["message"] := "Parametro 'cNum' e obrigatorio"
        Return oResp
    EndIf

    aSituac := SituAtu(cNumP)
    If !aSituac[1]
        oResp["success"] := .F.
        oResp["message"] := "Solicitacao nao encontrada"
        Return oResp
    EndIf
    If !(aSituac[2] $ "15")
        oResp["success"] := .F.
        oResp["message"] := "So e possivel definir o vencedor com a solicitacao em Rascunho ou Reprovado"
        Return oResp
    EndIf

    cItemVenc := AllTrim(cValToChar(oReq["item"]))
    cJustif   := AllTrim(cValToChar(oReq["justificativa"]))

    If Empty(cItemVenc)
        oResp["success"] := .F.
        oResp["message"] := "Informe o item da cotacao vencedora"
        Return oResp
    EndIf

    aCotac := CotacSol(cNumP)
    For nI := 1 To Len(aCotac)
        If aCotac[nI][1] == cItemVenc
            lAchouItem := .T.
            nValorVenc := aCotac[nI][3]
        EndIf
    Next nI

    If !lAchouItem
        oResp["success"] := .F.
        oResp["message"] := "Cotacao informada nao pertence a esta solicitacao"
        Return oResp
    EndIf

    nMenor := MenorVal(aCotac)
    If nValorVenc > nMenor .And. Empty(cJustif)
        oResp["success"] := .F.
        oResp["message"] := "A cotacao escolhida nao e a de menor valor -- informe a justificativa da escolha"
        Return oResp
    EndIf

    DbSelectArea("ZSD")
    ZSD->(DbSetOrder(1)) // ZSD_FILIAL+ZSD_NUM+ZSD_ITEM
    For nI := 1 To Len(aCotac)
        If ZSD->(DbSeek(xFilial("ZSD") + PadR(cNumP, TamSX3("ZSD_NUM")[1]) + PadR(aCotac[nI][1], TamSX3("ZSD_ITEM")[1])))
            RecLock("ZSD", .F.)
                ZSD->ZSD_VENCED := IIf(aCotac[nI][1] == cItemVenc, "S", "N")
            MsUnlock()
        EndIf
    Next nI

    DbSelectArea("ZSC")
    ZSC->(DbSetOrder(1))
    ZSC->(DbSeek(xFilial("ZSC") + PadR(cNumP, TamSX3("ZSC_NUM")[1])))
    RecLock("ZSC", .F.)
        ZSC->ZSC_VENCED := cItemVenc
        ZSC->ZSC_JUSTIF := cJustif
    MsUnlock()

    oResp["success"] := .T.
    oResp["message"] := "Vencedor definido com sucesso"

Return oResp

/*/{Protheus.doc} ZscAnCri
Anexa um arquivo PDF recebido em base64, gravando em
"\anexos_zsc\"+cNum+"\" e registrando os metadados em ZSE. Mesma logica de
RESTSCT::AnxArq (validacao de extensao + assinatura "%PDF", sanitizacao do
nome, path relativo ao RootPath).

IMPORTANTE: o payload trafega inteiro dentro do JSON do canal
AdvplToJs/JsToAdvpl (nao ha streaming/multipart nesse transporte, igual ao
REST anterior) -- anexos muito grandes (dezenas de MB) podem ser lentos ou
esbarrar em limite de mensagem do TWebChannel. Nao identificado um teto
especifico nesta build; se anexos grandes passarem a falhar, investigar
paginação/chunking do envio no lado Angular.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZscAnCri(oReq)

    Local oResp      := JsonObject():New()
    Local cNumP      := ""
    Local cNomeArq   := ""
    Local cBase64    := ""
    Local cBinario   := ""
    Local cItem      := ""
    Local cDirBase   := ""
    Local cDir       := ""
    Local cCaminho   := ""
    Local nHandle    := 0
    Local nPosBase64 := 0
    Local aSituac    := Nil

    If ValType(oReq["cNum"]) == "C" ; cNumP := AllTrim(oReq["cNum"]) ; EndIf

    If Empty(cNumP)
        oResp["success"] := .F.
        oResp["message"] := "Parametro 'cNum' e obrigatorio"
        Return oResp
    EndIf

    aSituac := SituAtu(cNumP)
    If !aSituac[1]
        oResp["success"] := .F.
        oResp["message"] := "Solicitacao nao encontrada"
        Return oResp
    EndIf
    If aSituac[2] != "1" .And. aSituac[2] != "5"
        oResp["success"] := .F.
        oResp["message"] := "So e possivel anexar arquivo com a solicitacao em Rascunho ou Reprovado"
        Return oResp
    EndIf

    cNomeArq := AllTrim(cValToChar(oReq["nome"]))
    cBase64  := oReq["conteudoBase64"]

    If Empty(cNomeArq) .Or. Empty(cBase64)
        oResp["success"] := .F.
        oResp["message"] := "Informe 'nome' e 'conteudoBase64' do arquivo"
        Return oResp
    EndIf

    If Lower(Right(cNomeArq, 4)) != ".pdf"
        oResp["success"] := .F.
        oResp["message"] := "Somente arquivos PDF sao permitidos"
        Return oResp
    EndIf

    cNomeArq := StrTran(cNomeArq, "\", "_")
    cNomeArq := StrTran(cNomeArq, "/", "_")
    cNomeArq := StrTran(cNomeArq, ":", "_")
    cNomeArq := StrTran(cNomeArq, "*", "_")
    cNomeArq := StrTran(cNomeArq, "?", "_")
    cNomeArq := StrTran(cNomeArq, '"', "_")
    cNomeArq := StrTran(cNomeArq, "<", "_")
    cNomeArq := StrTran(cNomeArq, ">", "_")
    cNomeArq := StrTran(cNomeArq, "|", "_")
    cNomeArq := StrTran(cNomeArq, "..", "_")

    nPosBase64 := At("base64,", cBase64)
    If nPosBase64 > 0
        cBase64 := SubStr(cBase64, nPosBase64 + Len("base64,"))
    EndIf

    cBinario := Decode64(cBase64)
    If Empty(cBinario)
        oResp["success"] := .F.
        oResp["message"] := "Conteudo Base64 invalido ou arquivo vazio"
        Return oResp
    EndIf

    If Left(cBinario, 4) != "%PDF"
        oResp["success"] := .F.
        oResp["message"] := "O conteudo enviado nao e um arquivo PDF valido"
        Return oResp
    EndIf

    cItem    := ProxItAn(cNumP)
    cDirBase := "\anexos_zsc\"
    cDir     := cDirBase + AllTrim(cNumP) + "\"

    If !ExistDir(cDirBase)
        If MakeDir(cDirBase) != 0
            oResp["success"] := .F.
            oResp["message"] := "Falha ao criar o diretorio principal de anexos"
            Return oResp
        EndIf
    EndIf

    If !ExistDir(cDir)
        If MakeDir(cDir) != 0
            oResp["success"] := .F.
            oResp["message"] := "Falha ao criar o diretorio da solicitacao"
            Return oResp
        EndIf
    EndIf

    cCaminho := cDir + cItem + "_" + cNomeArq

    nHandle := fCreate(cCaminho)
    If nHandle == -1
        oResp["success"] := .F.
        oResp["message"] := "Falha ao criar o arquivo no servidor"
        Return oResp
    EndIf

    If fWrite(nHandle, cBinario, Len(cBinario)) != Len(cBinario)
        fClose(nHandle)
        FErase(cCaminho)
        oResp["success"] := .F.
        oResp["message"] := "Falha ao gravar todo o conteudo do arquivo"
        Return oResp
    EndIf

    fClose(nHandle)

    DbSelectArea("ZSE")
    RecLock("ZSE", .T.)
        ZSE->ZSE_FILIAL := xFilial("ZSE")
        ZSE->ZSE_NUM    := PadR(cNumP, TamSX3("ZSE_NUM")[1])
        ZSE->ZSE_ITEM   := cItem
        ZSE->ZSE_ARQUIV := cNomeArq
        ZSE->ZSE_CAMINH := cCaminho
        ZSE->ZSE_TAMANH := Len(cBinario)
        ZSE->ZSE_DTANEX := Date()
        ZSE->ZSE_USUANE := RetCodUsr()
    MsUnlock()

    oResp["success"] := .T.
    oResp["item"]    := cItem
    oResp["message"] := "Anexo incluido com sucesso"

Return oResp

/*/{Protheus.doc} ZscAnBax
Baixa um arquivo anexado (conteudo em base64). Mesma logica de
RESTSCT::BaxArq -- ver nota de tamanho de payload em ZscAnCri.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZscAnBax(oReq)

    Local oResp    := JsonObject():New()
    Local cNumP    := ""
    Local cItemP   := ""
    Local cCaminho := ""
    Local cNomeArq := ""
    Local nHandle  := 0
    Local nTam     := 0
    Local cBuffer  := ""

    If ValType(oReq["cNum"]) == "C"  ; cNumP  := AllTrim(oReq["cNum"])  ; EndIf
    If ValType(oReq["cItem"]) == "C" ; cItemP := AllTrim(oReq["cItem"]) ; EndIf

    If Empty(cNumP) .Or. Empty(cItemP)
        oResp["success"] := .F.
        oResp["message"] := "Parametros 'cNum' e 'cItem' sao obrigatorios"
        Return oResp
    EndIf

    DbSelectArea("ZSE")
    ZSE->(DbSetOrder(1)) // ZSE_FILIAL+ZSE_NUM+ZSE_ITEM
    If !ZSE->(DbSeek(xFilial("ZSE") + PadR(cNumP, TamSX3("ZSE_NUM")[1]) + PadR(cItemP, TamSX3("ZSE_ITEM")[1])))
        oResp["success"] := .F.
        oResp["message"] := "Anexo nao encontrado"
        Return oResp
    EndIf

    cCaminho := Alltrim(ZSE->ZSE_CAMINH)
    cNomeArq := Alltrim(ZSE->ZSE_ARQUIV)

    nHandle := fOpen(cCaminho, 0)
    If nHandle == -1
        oResp["success"] := .F.
        oResp["message"] := "Arquivo nao encontrado no servidor"
        Return oResp
    EndIf

    nTam    := fSeek(nHandle, 0, 2)
    fSeek(nHandle, 0, 0)
    cBuffer := Space(nTam)
    fRead(nHandle, @cBuffer, nTam)
    fClose(nHandle)

    oResp["success"]        := .T.
    oResp["nome"]           := cNomeArq
    oResp["conteudoBase64"] := Encode64(cBuffer)

Return oResp

/*/{Protheus.doc} ZscAnRem
Remove um anexo (registro ZSE + arquivo em disco). Mesma logica de
RESTSCT::ArqDel.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZscAnRem(oReq)

    Local oResp    := JsonObject():New()
    Local cNumP    := ""
    Local cItemP   := ""
    Local cCaminho := ""
    Local aSituac  := Nil

    If ValType(oReq["cNum"]) == "C"  ; cNumP  := AllTrim(oReq["cNum"])  ; EndIf
    If ValType(oReq["cItem"]) == "C" ; cItemP := AllTrim(oReq["cItem"]) ; EndIf

    If Empty(cNumP) .Or. Empty(cItemP)
        oResp["success"] := .F.
        oResp["message"] := "Parametros 'cNum' e 'cItem' sao obrigatorios"
        Return oResp
    EndIf

    aSituac := SituAtu(cNumP)
    If !aSituac[1]
        oResp["success"] := .F.
        oResp["message"] := "Solicitacao nao encontrada"
        Return oResp
    EndIf
    If !(aSituac[2] $ "15")
        oResp["success"] := .F.
        oResp["message"] := "So e possivel remover anexo com a solicitacao em Rascunho ou Reprovado"
        Return oResp
    EndIf

    DbSelectArea("ZSE")
    ZSE->(DbSetOrder(1))
    If !ZSE->(DbSeek(xFilial("ZSE") + PadR(cNumP, TamSX3("ZSE_NUM")[1]) + PadR(cItemP, TamSX3("ZSE_ITEM")[1])))
        oResp["success"] := .F.
        oResp["message"] := "Anexo nao encontrado"
        Return oResp
    EndIf

    cCaminho := Alltrim(ZSE->ZSE_CAMINH)

    RecLock("ZSE", .F.)
        ZSE->(DbDelete())
    MsUnlock()

    If !Empty(cCaminho) .And. File(cCaminho)
        FErase(cCaminho)
    EndIf

    oResp["success"] := .T.
    oResp["message"] := "Anexo removido com sucesso"

Return oResp

/*/{Protheus.doc} ZscEnvia
Envia a solicitacao para aprovacao (Rascunho/Reprovado -> Aguardando N1),
validando os requisitos em ValidEnv(). Mesma logica de RESTSCT::Enviar.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZscEnvia(oReq)

    Local oResp     := JsonObject():New()
    Local cNumP     := ""
    Local aSituac   := Nil
    Local aValidEnv := Nil

    If ValType(oReq["cNum"]) == "C" ; cNumP := AllTrim(oReq["cNum"]) ; EndIf

    If Empty(cNumP)
        oResp["success"] := .F.
        oResp["message"] := "Parametro 'cNum' e obrigatorio"
        Return oResp
    EndIf

    aSituac := SituAtu(cNumP)
    If !aSituac[1]
        oResp["success"] := .F.
        oResp["message"] := "Solicitacao nao encontrada"
        Return oResp
    EndIf
    If !(aSituac[2] $ "15")
        oResp["success"] := .F.
        oResp["message"] := "Esta solicitacao ja esta em fluxo de aprovacao ou ja foi aprovada"
        Return oResp
    EndIf

    aValidEnv := ValidEnv(cNumP)
    If !aValidEnv[1]
        oResp["success"] := .F.
        oResp["message"] := aValidEnv[2]
        Return oResp
    EndIf

    DbSelectArea("ZSC")
    ZSC->(DbSetOrder(1))
    ZSC->(DbSeek(xFilial("ZSC") + PadR(cNumP, TamSX3("ZSC_NUM")[1])))
    RecLock("ZSC", .F.)
        ZSC->ZSC_STATUS := "2"
        ZSC->ZSC_USUAP1 := ""
        ZSC->ZSC_NUSAP1 := ""
        ZSC->ZSC_DTAPR1 := CtoD("")
        ZSC->ZSC_HRAPR1 := ""
        ZSC->ZSC_USUAP2 := ""
        ZSC->ZSC_NUSAP2 := ""
        ZSC->ZSC_DTAPR2 := CtoD("")
        ZSC->ZSC_HRAPR2 := ""
        ZSC->ZSC_MOTREP := ""
    MsUnlock()

    oResp["success"] := .T.
    oResp["message"] := "Solicitacao enviada para aprovacao (Nivel 1)"

Return oResp

/*/{Protheus.doc} ZscAprov
Aprova a solicitacao no nivel exigido pelo status atual, usando o usuario
logado (RetCodUsr()). Status 2 -> 3 (aguardando N2); status 3 -> 4 (Aprovado).
Mesma logica de RESTSCT::Aprova.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZscAprov(oReq)

    Local oResp        := JsonObject():New()
    Local cNumP        := ""
    Local cUserId      := RetCodUsr()
    Local aSituac      := Nil
    Local cNivelExig   := ""
    Local aValidAprov  := Nil

    If ValType(oReq["cNum"]) == "C" ; cNumP := AllTrim(oReq["cNum"]) ; EndIf

    If Empty(cNumP)
        oResp["success"] := .F.
        oResp["message"] := "Parametro 'cNum' e obrigatorio"
        Return oResp
    EndIf

    If Empty(cUserId)
        oResp["success"] := .F.
        oResp["message"] := "Usuario nao autenticado"
        Return oResp
    EndIf

    aSituac := SituAtu(cNumP)
    If !aSituac[1]
        oResp["success"] := .F.
        oResp["message"] := "Solicitacao nao encontrada"
        Return oResp
    EndIf

    Do Case
    Case aSituac[2] == "2" ; cNivelExig := "1"
    Case aSituac[2] == "3" ; cNivelExig := "2"
    OtherWise
        oResp["success"] := .F.
        oResp["message"] := "Esta solicitacao nao esta aguardando aprovacao"
        Return oResp
    EndCase

    aValidAprov := ValidApr(cUserId, cNivelExig, aSituac[3])
    If !aValidAprov[1]
        oResp["success"] := .F.
        oResp["message"] := aValidAprov[2]
        Return oResp
    EndIf

    DbSelectArea("ZSC")
    ZSC->(DbSetOrder(1))
    If !ZSC->(DbSeek(xFilial("ZSC") + PadR(cNumP, TamSX3("ZSC_NUM")[1])))
        oResp["success"] := .F.
        oResp["message"] := "Solicitacao nao encontrada"
        Return oResp
    EndIf

    If !RecLock("ZSC", .F.)
        oResp["success"] := .F.
        oResp["message"] := "Registro em uso por outro usuario ou processo. Tente novamente em instantes."
        Return oResp
    EndIf

        If cNivelExig == "1"
            ZSC->ZSC_STATUS := "3"
            ZSC->ZSC_USUAP1 := cUserId
            ZSC->ZSC_NUSAP1 := UsrRetName(cUserId)
            ZSC->ZSC_DTAPR1 := Date()
            ZSC->ZSC_HRAPR1 := Left(Time(), 5)
        Else
            ZSC->ZSC_STATUS := "4"
            ZSC->ZSC_USUAP2 := cUserId
            ZSC->ZSC_NUSAP2 := UsrRetName(cUserId)
            ZSC->ZSC_DTAPR2 := Date()
            ZSC->ZSC_HRAPR2 := Left(Time(), 5)
        EndIf
    MsUnlock()

    oResp["success"] := .T.
    oResp["status"]  := IIf(cNivelExig == "1", "3", "4")
    oResp["message"] := IIf(cNivelExig == "1", "Aprovado no Nivel 1 -- aguardando Nivel 2", "Solicitacao aprovada")

Return oResp

/*/{Protheus.doc} ZscRepro
Reprova a solicitacao (status 2 ou 3 -> 5), exigindo motivo. Mesma logica de
RESTSCT::Reprov.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZscRepro(oReq)

    Local oResp        := JsonObject():New()
    Local cNumP        := ""
    Local cUserId      := RetCodUsr()
    Local cMotivo      := ""
    Local aSituac      := Nil
    Local cNivelExig   := ""
    Local aValidAprov  := Nil

    If ValType(oReq["cNum"]) == "C" ; cNumP := AllTrim(oReq["cNum"]) ; EndIf

    If Empty(cNumP)
        oResp["success"] := .F.
        oResp["message"] := "Parametro 'cNum' e obrigatorio"
        Return oResp
    EndIf

    If Empty(cUserId)
        oResp["success"] := .F.
        oResp["message"] := "Usuario nao autenticado"
        Return oResp
    EndIf

    cMotivo := AllTrim(cValToChar(oReq["motivo"]))

    If Empty(cMotivo)
        oResp["success"] := .F.
        oResp["message"] := "Informe o motivo da reprovacao"
        Return oResp
    EndIf

    aSituac := SituAtu(cNumP)
    If !aSituac[1]
        oResp["success"] := .F.
        oResp["message"] := "Solicitacao nao encontrada"
        Return oResp
    EndIf

    Do Case
    Case aSituac[2] == "2" ; cNivelExig := "1"
    Case aSituac[2] == "3" ; cNivelExig := "2"
    OtherWise
        oResp["success"] := .F.
        oResp["message"] := "Esta solicitacao nao esta aguardando aprovacao"
        Return oResp
    EndCase

    aValidAprov := ValidApr(cUserId, cNivelExig, aSituac[3])
    If !aValidAprov[1]
        oResp["success"] := .F.
        oResp["message"] := aValidAprov[2]
        Return oResp
    EndIf

    DbSelectArea("ZSC")
    ZSC->(DbSetOrder(1))
    ZSC->(DbSeek(xFilial("ZSC") + PadR(cNumP, TamSX3("ZSC_NUM")[1])))
    RecLock("ZSC", .F.)
        ZSC->ZSC_STATUS := "5"
        ZSC->ZSC_MOTREP := cMotivo
        If cNivelExig == "1"
            ZSC->ZSC_USUAP1 := cUserId
            ZSC->ZSC_NUSAP1 := UsrRetName(cUserId)
            ZSC->ZSC_DTAPR1 := Date()
        Else
            ZSC->ZSC_USUAP2 := cUserId
            ZSC->ZSC_NUSAP2 := UsrRetName(cUserId)
            ZSC->ZSC_DTAPR2 := Date()
        EndIf
    MsUnlock()

    oResp["success"] := .T.
    oResp["message"] := "Solicitacao reprovada"

Return oResp

/*/{Protheus.doc} ZscPend
Lista as solicitacoes pendentes de aprovacao para o usuario logado (nivel/CC
via ZAP). Mesma logica de RESTSCT::Pendnt.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZscPend(oReq)

    Local oResp     := JsonObject():New()
    Local aItens    := {}
    Local oItem     := Nil
    Local cUserId   := RetCodUsr()
    Local aDados    := Nil
    Local cStatusF  := ""
    Local cCC       := ""
    Local cWhere    := ""
    Local cAliasQ   := Nil

    If Empty(cUserId)
        oResp["success"] := .F.
        oResp["message"] := "Usuario nao autenticado"
        Return oResp
    EndIf

    aDados := DadosApr(cUserId)
    oResp["success"] := .T.
    oResp["nivel"]    := aDados[2]

    If !aDados[1] .Or. Empty(aDados[2])
        oResp["items"] := aItens
        Return oResp
    EndIf

    cStatusF := IIf(aDados[2] == "1", "2", "3")
    cCC      := aDados[3]

    cWhere := " AND ZSC.ZSC_STATUS = '" + cStatusF + "'"
    If !Empty(cCC)
        cWhere += " AND ZSC.ZSC_CC = '" + cCC + "'"
    EndIf
    cWhere := "%" + cWhere + "%"

    cAliasQ := GetNextAlias()
    BeginSql Alias cAliasQ
        SELECT ZSC.ZSC_NUM, ZSC.ZSC_CC,
               ZSC.ZSC_SOLICI, ZSC.ZSC_NSOLIC,
               ZSC.ZSC_DTSOLI, ZSC.ZSC_STATUS, ZSC.ZSC_VENCED,
               ISNULL(CTT.CTT_DESC01, '') AS CTT_DESC
          FROM %table:ZSC% ZSC
          LEFT JOIN %table:CTT% CTT
            ON  CTT.D_E_L_E_T_ = ' '
            AND CTT.CTT_FILIAL = %xfilial:CTT%
            AND CTT.CTT_CUSTO  = ZSC.ZSC_CC
         WHERE ZSC.%notDel%
           AND ZSC.ZSC_FILIAL = %xfilial:ZSC%
           %exp:cWhere%
         ORDER BY ZSC.ZSC_DTSOLI, ZSC.ZSC_NUM
    EndSql

    While (cAliasQ)->(!Eof())
        oItem := JsonObject():New()
        oItem["num"]        := AllTrim((cAliasQ)->ZSC_NUM)
        oItem["cc"]         := AllTrim((cAliasQ)->ZSC_CC)
        oItem["ccDesc"]     := AllTrim((cAliasQ)->CTT_DESC)
        oItem["necessidade"]:= NecesZsc(Alltrim((cAliasQ)->ZSC_NUM), 0)
        oItem["solicitante"]:= AllTrim((cAliasQ)->ZSC_SOLICI)
        oItem["nomeSolic"]  := AllTrim((cAliasQ)->ZSC_NSOLIC)
        oItem["dataSolic"]  := DtoSNull((cAliasQ)->ZSC_DTSOLI)
        oItem["status"]     := AllTrim((cAliasQ)->ZSC_STATUS)
        oItem["statusDesc"] := StatDesc(AllTrim((cAliasQ)->ZSC_STATUS))
        oItem["vencedor"]   := AllTrim((cAliasQ)->ZSC_VENCED)
        aAdd(aItens, oItem)
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

    oResp["items"] := aItens

Return oResp

/*/{Protheus.doc} ZscLkpCC
Lookup de centro de custo (CTT). Mesma logica de RESTSCT::ListCC.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZscLkpCC(oReq)

    Local oResp     := JsonObject():New()
    Local aItens    := {}
    Local oItem     := Nil
    Local cAliasQ   := GetNextAlias()
    Local cFiltroF  := ""
    Local cLikeCod  := ""
    Local cLikeDesc := ""
    Local nCount    := 0

    If ValType(oReq["cFiltro"]) == "C"
        cFiltroF := AllTrim(oReq["cFiltro"])
    EndIf
    cLikeCod  := "%'%" + cFiltroF + "%'%"
    cLikeDesc := cLikeCod

    BeginSql Alias cAliasQ
        SELECT CTT.CTT_CUSTO, CTT.CTT_DESC01
          FROM %table:CTT% CTT
         WHERE CTT.%notDel%
           AND CTT.CTT_FILIAL = %xfilial:CTT%
           AND (CTT.CTT_CUSTO LIKE %exp:cLikeCod% OR CTT.CTT_DESC01 LIKE %exp:cLikeDesc%)
         ORDER BY CTT.CTT_CUSTO
    EndSql

    While (cAliasQ)->(!Eof()) .And. nCount < 20
        oItem := JsonObject():New()
        oItem["value"] := AllTrim((cAliasQ)->CTT_CUSTO)
        oItem["label"] := AllTrim((cAliasQ)->CTT_DESC01)
        aAdd(aItens, oItem)
        nCount++
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

    oResp["success"] := .T.
    oResp["items"]   := aItens
    oResp["hasNext"] := .F.

Return oResp
