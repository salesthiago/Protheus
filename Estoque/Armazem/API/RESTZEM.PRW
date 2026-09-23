#INCLUDE "TOTVS.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "RESTFUL.ch"

/*/{Protheus.doc} RESTZEM
Endpoint REST para o cadastro de Estoque Minimo e Maximo por Produto/Armazem (ZEM),
consumido pela tela Angular/PO-UI aberta em EstMinMax(). Reutiliza o modelo MVC
definido em ESTMVC001.PRW (ModelDef) para garantir as mesmas validacoes da tela
(PostModel: Filial+Produto+Armazem duplicado, Estoque Maximo >= Minimo, Status 1 ou 2).
Essas mesmas validacoes tambem sao feitas diretamente aqui, ANTES de acionar o
modelo, pois o PostModel usa MsgStop() (caixa de dialogo), que nao funciona em
contexto headless REST.

IMPORTANTE: POST/PUT/DELETE localizam o registro pela chave FILIAL+PROD+LOCAL via
Embedded SQL (BeginSql com R_E_C_N_O_ + DbGoTo), e nao via DbSeek/DbSetOrder.
Isso evita depender de qual numero de indice/ordem da ZEM corresponde a essa chave
-- ordem essa que, neste ambiente, se mostrou incompativel com um DbSeek direto
(a busca por PROD+LOCAL retornava outro registro do mesmo produto em armazem diferente).

IMPORTANTE: erros usam a funcao global SetRestFault(nCode, cMsg) em vez da
propriedade Self:nStatusCode -- nesta build do TOTVS (7.00.240223P), atribuir
Self:nStatusCode diretamente lanca "invalid property NSTATUSCODE". SetRestFault
e o mecanismo usado com sucesso em Aterro/api/APATERRO.PRW deste mesmo projeto.

@path GET    /estoque/zem?cProd=&cLocal=&cStatus=  Lista os registros (filtros opcionais)
@path GET    /estoque/zem/detalhe?cProd=&cLocal=   Obtem um registro especifico
@path POST   /estoque/zem                          Inclui um registro (corpo JSON: prod, nprod, local, estMin, estMax, status)
@path PUT    /estoque/zem?cProd=&cLocal=           Altera um registro (corpo JSON: nprod, estMin, estMax, status)
@path DELETE /estoque/zem?cProd=&cLocal=           Exclui um registro

NOTA: nenhum metodo usa path params ({prod}/{local}) -- todos usam querystring
(cProd/cLocal). Nesta build do TOTVS (7.00.240223P), o binding de path params via
WSRECEIVE se mostrou instavel (funcionava em alguns testes e depois passou a
lancar "invalid property PROD/LOCAL" em GET e PUT tambem, nao so DELETE).
Querystring via WSDATA e o mecanismo comprovadamente estavel neste ambiente.
@author Thiago Sales - Quebec Ambiental
@since 2026-07-14
/*/
//=============================================================================================================================
WSRESTFUL RESTZEM DESCRIPTION "Estoque Minimo e Maximo por Produto/Armazem (ZEM)" FORMAT APPLICATION_JSON

    WSDATA cProd    AS STRING OPTIONAL
    WSDATA cLocal   AS STRING OPTIONAL
    WSDATA cStatus  AS STRING OPTIONAL
    WSDATA cFiltro  AS STRING OPTIONAL

    WSMETHOD GET    ListarZem  DESCRIPTION "Lista os registros de ZEM"  WSSYNTAX "/estoque/zem"                PATH "/estoque/zem"
    WSMETHOD GET    ListaProd DESCRIPTION "Lookup de produtos (SB1)"      WSSYNTAX "/estoque/zem/lookup/produtos" PATH "/estoque/zem/lookup/produtos"
    WSMETHOD GET    ListaAmz DESCRIPTION "Lookup de armazens (NNR)"      WSSYNTAX "/estoque/zem/lookup/armazens" PATH "/estoque/zem/lookup/armazens"
    WSMETHOD GET    Dashboard DESCRIPTION "Dados de saldo x min/max para dashboard/relatorio" WSSYNTAX "/estoque/zem/dashboard" PATH "/estoque/zem/dashboard"
    WSMETHOD GET    ObterZem   DESCRIPTION "Obtem um registro de ZEM"   WSSYNTAX "/estoque/zem/detalhe"       PATH "/estoque/zem/detalhe"
    WSMETHOD POST   IncluirZem DESCRIPTION "Inclui um registro em ZEM" WSSYNTAX "/estoque/zem"                PATH "/estoque/zem"
    WSMETHOD PUT    AlterarZem DESCRIPTION "Altera um registro de ZEM" WSSYNTAX "/estoque/zem"                PATH "/estoque/zem"
    WSMETHOD DELETE ExcluirZem DESCRIPTION "Exclui um registro de ZEM" WSSYNTAX "/estoque/zem" PATH "/estoque/zem"

END WSRESTFUL

/*/{Protheus.doc} GET /estoque/zem
Lista os registros de ZEM (com descricao do produto via SB1), aceitando filtros
opcionais por querystring: cProd, cLocal, cStatus.
@return (application/json) { "success": true, "items": [ { "prod","nprod","local","estMin","estMax","status","desc" } ] }
/*/
//=============================================================================================================================
WSMETHOD GET ListarZem WSSERVICE RESTZEM

    Local oResp    := JsonObject():New()
    Local aItens   := {}
    Local oItem    := Nil
    Local cAliasQ  := GetNextAlias()
    Local cProdF   := ""
    Local cLocalF  := ""
    Local cStatusF := ""
    Local cWhere   := ""

    If ValType(Self:cProd) == "C" ;   cProdF   := AllTrim(Self:cProd)   ; EndIf
    If ValType(Self:cLocal) == "C" ;  cLocalF  := AllTrim(Self:cLocal)  ; EndIf
    If ValType(Self:cStatus) == "C" ; cStatusF := AllTrim(Self:cStatus) ; EndIf

    If !Empty(cProdF)
        cWhere += " AND ZEM.ZEM_PROD LIKE '" + cProdF + "%'"
    EndIf
    If !Empty(cLocalF)
        cWhere += " AND ZEM.ZEM_LOCAL = '" + cLocalF + "'"
    EndIf
    If !Empty(cStatusF)
        cWhere += " AND ZEM.ZEM_STATUS = '" + cStatusF + "'"
    EndIf
    cWhere := "%" + cWhere + "%"

    BeginSql Alias cAliasQ
        SELECT ZEM.ZEM_PROD, ZEM.ZEM_NPROD, ZEM.ZEM_LOCAL, ZEM.ZEM_ESTMIN, ZEM.ZEM_ESTMAX, ZEM.ZEM_STATUS,
               ISNULL(B1.B1_DESC, '') AS B1_DESC
          FROM %table:ZEM% ZEM
          LEFT JOIN %table:SB1% B1
            ON  B1.D_E_L_E_T_ = ' '
            AND B1.B1_FILIAL  = %xfilial:SB1%
            AND B1.B1_COD     = ZEM.ZEM_PROD
         WHERE ZEM.%notDel%
           AND ZEM.ZEM_FILIAL = %xfilial:ZEM%
           %exp:cWhere%
         ORDER BY ZEM.ZEM_PROD, ZEM.ZEM_LOCAL
    EndSql

    While (cAliasQ)->(!Eof())
        oItem := JsonObject():New()
        oItem["prod"]   := AllTrim((cAliasQ)->ZEM_PROD)
        oItem["nprod"]  := AllTrim((cAliasQ)->ZEM_NPROD)
        oItem["local"]  := AllTrim((cAliasQ)->ZEM_LOCAL)
        oItem["estMin"] := (cAliasQ)->ZEM_ESTMIN
        oItem["estMax"] := (cAliasQ)->ZEM_ESTMAX
        oItem["status"] := AllTrim((cAliasQ)->ZEM_STATUS)
        oItem["desc"]   := AllTrim((cAliasQ)->B1_DESC)
        aAdd(aItens, oItem)
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

    oResp["success"] := .T.
    oResp["items"]   := aItens

    Self:SetResponse(oResp:toJson())

Return .T.

/*/{Protheus.doc} GET /estoque/zem/detalhe?cProd=&cLocal=
Obtem um registro especifico de ZEM pela chave produto+armazem (via querystring).
@return (application/json) { "success": true, "prod","nprod","local","estMin","estMax","status","desc" }
/*/
//=============================================================================================================================
WSMETHOD GET ObterZem WSSERVICE RESTZEM

    Local oResp   := JsonObject():New()
    Local cAliasQ := GetNextAlias()
    Local cProdP  := ""
    Local cLocalP := ""

    If ValType(Self:cProd) == "C"  ; cProdP  := AllTrim(Self:cProd)  ; EndIf
    If ValType(Self:cLocal) == "C" ; cLocalP := AllTrim(Self:cLocal) ; EndIf

    If Empty(cProdP) .Or. Empty(cLocalP)
        SetRestFault(400, EncodeUTF8("Parametros 'cProd' e 'cLocal' sao obrigatorios"))
        Return .F.
    EndIf

    BeginSql Alias cAliasQ
        SELECT ZEM.ZEM_PROD, ZEM.ZEM_NPROD, ZEM.ZEM_LOCAL, ZEM.ZEM_ESTMIN, ZEM.ZEM_ESTMAX, ZEM.ZEM_STATUS,
               ISNULL(B1.B1_DESC, '') AS B1_DESC
          FROM %table:ZEM% ZEM
          LEFT JOIN %table:SB1% B1
            ON  B1.D_E_L_E_T_ = ' '
            AND B1.B1_FILIAL  = %xfilial:SB1%
            AND B1.B1_COD     = ZEM.ZEM_PROD
         WHERE ZEM.%notDel%
           AND ZEM.ZEM_FILIAL = %xfilial:ZEM%
           AND ZEM.ZEM_PROD   = %exp:cProdP%
           AND ZEM.ZEM_LOCAL  = %exp:cLocalP%
    EndSql

    If (cAliasQ)->(!Eof())
        oResp["success"] := .T.
        oResp["prod"]    := AllTrim((cAliasQ)->ZEM_PROD)
        oResp["nprod"]   := AllTrim((cAliasQ)->ZEM_NPROD)
        oResp["local"]   := AllTrim((cAliasQ)->ZEM_LOCAL)
        oResp["estMin"]  := (cAliasQ)->ZEM_ESTMIN
        oResp["estMax"]  := (cAliasQ)->ZEM_ESTMAX
        oResp["status"]  := AllTrim((cAliasQ)->ZEM_STATUS)
        oResp["desc"]    := AllTrim((cAliasQ)->B1_DESC)
        (cAliasQ)->(DbCloseArea())
        Self:SetResponse(oResp:toJson())
        Return .T.
    EndIf

    (cAliasQ)->(DbCloseArea())
    SetRestFault(404, EncodeUTF8("Registro nao encontrado"))

Return .F.

/*/{Protheus.doc} POST /estoque/zem
Inclui um registro na tabela ZEM utilizando o modelo MVC do ESTMVC001.PRW,
garantindo as mesmas validacoes da tela (PostModel), replicadas aqui antes de
acionar o modelo (ver nota no cabecalho do arquivo sobre MsgStop em contexto REST).
@body (application/json) { "prod","nprod","local","estMin","estMax","status" }
@return (application/json) { "success": true, "message": "Registro incluido com sucesso" }
/*/
//=============================================================================================================================
WSMETHOD POST IncluirZem WSSERVICE RESTZEM

    Local oJson    := JsonObject():New()
    Local oResp    := JsonObject():New()
    Local oModel   := Nil
    Local cContent := Self:GetContent()
    Local cMsg     := ""
    Local lRet     := .T.
    Local lAtivado := .F.
    Local lFalha   := .F.
    Local nMin     := 0
    Local nMax     := 0
    Local cStatus  := ""

    If Empty(cContent)
        SetRestFault(400, EncodeUTF8("Corpo da requisicao esta vazio"))
        Return .F.
    EndIf

    oJson:fromJson(cContent)

    If Empty(oJson["prod"]) .Or. Empty(oJson["local"])
        SetRestFault(400, EncodeUTF8("Campos 'prod' e 'local' sao obrigatorios"))
        Return .F.
    EndIf

    nMin    := oJson["estMin"]
    nMax    := oJson["estMax"]
    cStatus := AllTrim(oJson["status"])

    If ValType(nMin) != "N" ; nMin := 0 ; EndIf
    If ValType(nMax) != "N" ; nMax := 0 ; EndIf

    If nMin > 0 .And. nMax > 0 .And. nMax < nMin
        SetRestFault(422, EncodeUTF8("Estoque Maximo nao pode ser menor que o Estoque Minimo."))
        Return .F.
    EndIf

    If Empty(cStatus) .Or. !(cStatus $ "12")
        SetRestFault(422, EncodeUTF8("Status invalido. Informe 1 - Ativo ou 2 - Inativo."))
        Return .F.
    EndIf

    BeginSql Alias "ZEMDUP"
        SELECT ZEM.ZEM_PROD
          FROM %table:ZEM% ZEM
         WHERE ZEM.%notDel%
           AND ZEM.ZEM_FILIAL = %xfilial:ZEM%
           AND ZEM.ZEM_PROD   = %exp:AllTrim(oJson["prod"])%
           AND ZEM.ZEM_LOCAL  = %exp:AllTrim(oJson["local"])%
    EndSql

    If !ZEMDUP->(Eof())
        ZEMDUP->(DbCloseArea())
        SetRestFault(409, EncodeUTF8("Ja existe um registro de Estoque Minimo/Maximo para este Produto/Armazem."))
        Return .F.
    EndIf
    ZEMDUP->(DbCloseArea())

    oModel := FWLoadModel("ESTMVC001")
    oModel:SetOperation(MODEL_OPERATION_INSERT)

    If oModel:Activate()
        lAtivado := .T.

        oModel:SetValue("ZEMMASTER", "ZEM_PROD",   oJson["prod"])
        oModel:SetValue("ZEMMASTER", "ZEM_NPROD",  oJson["nprod"])
        oModel:SetValue("ZEMMASTER", "ZEM_LOCAL",  oJson["local"])
        oModel:SetValue("ZEMMASTER", "ZEM_ESTMIN", oJson["estMin"])
        oModel:SetValue("ZEMMASTER", "ZEM_ESTMAX", oJson["estMax"])
        oModel:SetValue("ZEMMASTER", "ZEM_STATUS", oJson["status"])

        If oModel:VldData()
            oModel:CommitData()
            oResp["success"] := .T.
            oResp["message"] := "Registro incluido com sucesso"
        Else
            cMsg := AllTrim(oModel:GetErrorMessage()[6])
            If Empty(cMsg)
                cMsg := AllTrim(oModel:GetErrorMessage()[3])
            EndIf
            If Empty(cMsg)
                cMsg := "Falha ao validar os dados"
            EndIf
            lFalha := .T.
            lRet   := .F.
        EndIf
    Else
        cMsg := AllTrim(AllTrim(oModel:GetErrorMessage()[3]) + " " + AllTrim(oModel:GetErrorMessage()[6]))
        If Empty(cMsg)
            cMsg := "Falha ao ativar o modelo"
        EndIf
        lFalha := .T.
        lRet   := .F.
    EndIf

    If lAtivado
        oModel:DeActivate()
    EndIf

    If lFalha
        SetRestFault(422, EncodeUTF8(cMsg))
    Else
        Self:SetResponse(oResp:toJson())
    EndIf

Return lRet

/*/{Protheus.doc} PUT /estoque/zem?cProd=&cLocal=
Altera um registro existente de ZEM utilizando o modelo MVC do ESTMVC001.PRW.
Posiciona o registro pela chave (querystring) antes de ativar o modelo em modo
alteracao. Como e uma alteracao parcial, o Maximo/Minimo/Status considerados na
validacao combinam o que veio no JSON com o valor atual do registro (campos nao
informados mantem o valor gravado).
@body (application/json) { "nprod","estMin","estMax","status" }
@return (application/json) { "success": true, "message": "Registro alterado com sucesso" }
/*/
//=============================================================================================================================
WSMETHOD PUT AlterarZem WSSERVICE RESTZEM

    Local oJson    := JsonObject():New()
    Local oResp    := JsonObject():New()
    Local oModel   := Nil
    Local cContent := Self:GetContent()
    Local cProdP   := ""
    Local cLocalP  := ""
    Local cMsg     := ""
    Local lRet     := .T.
    Local lAtivado := .F.
    Local lFalha   := .F.
    Local nMin     := 0
    Local nMax     := 0
    Local cStatus  := ""

    If ValType(Self:cProd) == "C"  ; cProdP  := AllTrim(Self:cProd)  ; EndIf
    If ValType(Self:cLocal) == "C" ; cLocalP := AllTrim(Self:cLocal) ; EndIf

    If Empty(cProdP) .Or. Empty(cLocalP)
        SetRestFault(400, EncodeUTF8("Parametros 'cProd' e 'cLocal' sao obrigatorios"))
        Return .F.
    EndIf

    If Empty(cContent)
        SetRestFault(400, EncodeUTF8("Corpo da requisicao esta vazio"))
        Return .F.
    EndIf

    BeginSql Alias "ZEMLOC"
        SELECT ZEM.R_E_C_N_O_ AS RECNOZEM
          FROM %table:ZEM% ZEM
         WHERE ZEM.%notDel%
           AND ZEM.ZEM_FILIAL = %xfilial:ZEM%
           AND ZEM.ZEM_PROD   = %exp:cProdP%
           AND ZEM.ZEM_LOCAL  = %exp:cLocalP%
    EndSql

    If ZEMLOC->(Eof())
        ZEMLOC->(DbCloseArea())
        SetRestFault(404, EncodeUTF8("Registro nao encontrado"))
        Return .F.
    EndIf

    DbSelectArea("ZEM")
    ZEM->(DbGoTo(ZEMLOC->RECNOZEM))
    ZEMLOC->(DbCloseArea())

    oJson:fromJson(cContent)

    nMin    := oJson["estMin"]
    nMax    := oJson["estMax"]
    If ValType(nMin) != "N" ; nMin := ZEM->ZEM_ESTMIN ; EndIf
    If ValType(nMax) != "N" ; nMax := ZEM->ZEM_ESTMAX ; EndIf

    cStatus := AllTrim(oJson["status"])
    If Empty(cStatus)
        cStatus := AllTrim(ZEM->ZEM_STATUS)
    EndIf

    If nMin > 0 .And. nMax > 0 .And. nMax < nMin
        SetRestFault(422, EncodeUTF8("Estoque Maximo nao pode ser menor que o Estoque Minimo."))
        Return .F.
    EndIf

    If Empty(cStatus) .Or. !(cStatus $ "12")
        SetRestFault(422, EncodeUTF8("Status invalido. Informe 1 - Ativo ou 2 - Inativo."))
        Return .F.
    EndIf

    oModel := FWLoadModel("ESTMVC001")
    oModel:SetOperation(MODEL_OPERATION_UPDATE)

    If oModel:Activate()
        lAtivado := .T.

        If !Empty(oJson["nprod"])
            oModel:SetValue("ZEMMASTER", "ZEM_NPROD", oJson["nprod"])
        EndIf
        If !Empty(oJson["estMin"])
            oModel:SetValue("ZEMMASTER", "ZEM_ESTMIN", oJson["estMin"])
        EndIf
        If !Empty(oJson["estMax"])
            oModel:SetValue("ZEMMASTER", "ZEM_ESTMAX", oJson["estMax"])
        EndIf
        If !Empty(oJson["status"])
            oModel:SetValue("ZEMMASTER", "ZEM_STATUS", oJson["status"])
        EndIf

        If oModel:VldData()
            oModel:CommitData()
            oResp["success"] := .T.
            oResp["message"] := "Registro alterado com sucesso"
        Else
            cMsg := AllTrim(oModel:GetErrorMessage()[6])
            If Empty(cMsg)
                cMsg := AllTrim(oModel:GetErrorMessage()[3])
            EndIf
            If Empty(cMsg)
                cMsg := "Falha ao validar os dados"
            EndIf
            lFalha := .T.
            lRet   := .F.
        EndIf
    Else
        cMsg := AllTrim(AllTrim(oModel:GetErrorMessage()[3]) + " " + AllTrim(oModel:GetErrorMessage()[6]))
        If Empty(cMsg)
            cMsg := "Falha ao ativar o modelo"
        EndIf
        lFalha := .T.
        lRet   := .F.
    EndIf

    If lAtivado
        oModel:DeActivate()
    EndIf

    If lFalha
        SetRestFault(422, EncodeUTF8(cMsg))
    Else
        Self:SetResponse(oResp:toJson())
    EndIf

Return lRet

/*/{Protheus.doc} DELETE /estoque/zem?cProd=&cLocal=
Exclui um registro de ZEM utilizando o modelo MVC do ESTMVC001.PRW.
Posiciona o registro pela chave (querystring) antes de ativar o modelo em modo
exclusao.
@return (application/json) { "success": true, "message": "Registro excluido com sucesso" }
/*/
//=============================================================================================================================
WSMETHOD DELETE ExcluirZem WSSERVICE RESTZEM

    Local oResp     := JsonObject():New()
    Local oModel    := Nil
    Local cProdP    := ""
    Local cLocalP   := ""
    Local cMsg      := ""
    Local lRet      := .T.
    Local lAtivado  := .F.
    Local lFalha    := .F.

    If ValType(Self:cProd) == "C"  ; cProdP  := AllTrim(Self:cProd)  ; EndIf
    If ValType(Self:cLocal) == "C" ; cLocalP := AllTrim(Self:cLocal) ; EndIf

    If Empty(cProdP) .Or. Empty(cLocalP)
        SetRestFault(400, EncodeUTF8("Parametros 'cProd' e 'cLocal' sao obrigatorios"))
        Return .F.
    EndIf

    BeginSql Alias "ZEMLOC"
        SELECT ZEM.R_E_C_N_O_ AS RECNOZEM
          FROM %table:ZEM% ZEM
         WHERE ZEM.%notDel%
           AND ZEM.ZEM_FILIAL = %xfilial:ZEM%
           AND ZEM.ZEM_PROD   = %exp:cProdP%
           AND ZEM.ZEM_LOCAL  = %exp:cLocalP%
    EndSql

    If ZEMLOC->(Eof())
        ZEMLOC->(DbCloseArea())
        SetRestFault(404, EncodeUTF8("Registro nao encontrado"))
        Return .F.
    EndIf

    DbSelectArea("ZEM")
    ZEM->(DbGoTo(ZEMLOC->RECNOZEM))
    ZEMLOC->(DbCloseArea())

    oModel := FWLoadModel("ESTMVC001")
    oModel:SetOperation(MODEL_OPERATION_DELETE)

    If oModel:Activate()
        lAtivado := .T.

        If oModel:VldData()
            oModel:CommitData()
            oResp["success"] := .T.
            oResp["message"] := "Registro excluido com sucesso"
        Else
            cMsg := AllTrim(oModel:GetErrorMessage()[6])
            If Empty(cMsg)
                cMsg := AllTrim(oModel:GetErrorMessage()[3])
            EndIf
            If Empty(cMsg)
                cMsg := "Falha ao validar os dados"
            EndIf
            lFalha := .T.
            lRet   := .F.
        EndIf
    Else
        cMsg := AllTrim(AllTrim(oModel:GetErrorMessage()[3]) + " " + AllTrim(oModel:GetErrorMessage()[6]))
        If Empty(cMsg)
            cMsg := "Falha ao ativar o modelo"
        EndIf
        lFalha := .T.
        lRet   := .F.
    EndIf

    If lAtivado
        oModel:DeActivate()
    EndIf

    If lFalha
        SetRestFault(422, EncodeUTF8(cMsg))
    Else
        Self:SetResponse(oResp:toJson())
    EndIf

Return lRet

/*/{Protheus.doc} GET /estoque/zem/lookup/produtos
Lookup de produtos (SB1) para o campo Produto do formulario Angular (po-lookup).
Filtra por codigo (prefixo) ou descricao (substring) via querystring cFiltro.
IMPORTANTE: sem paginacao real -- limita a 20 registros no laco ADVPL (hasNext sempre false).
Suficiente para o volume atual; se a SB1 crescer muito, revisar com paginacao via OFFSET/FETCH.
@return (application/json) { "success": true, "items": [ { "value","label" } ], "hasNext": false }
/*/
//=============================================================================================================================
WSMETHOD GET ListaProd WSSERVICE RESTZEM

    Local oResp    := JsonObject():New()
    Local aItens   := {}
    Local oItem    := Nil
    Local cAliasQ  := GetNextAlias()
    Local cFiltroF := ""
    Local cLikeCod  := ""
    Local cLikeDesc := ""
    Local nCount    := 0

    If ValType(Self:cFiltro) == "C"
        cFiltroF := AllTrim(Self:cFiltro)
    EndIf
    cLikeCod  := "%'%" + cFiltroF + "%'%"
    cLikeDesc := cLikeCod

    BeginSql Alias cAliasQ
        SELECT B1.B1_COD, B1.B1_DESC
          FROM %table:SB1% B1
         WHERE B1.%notDel%
           AND B1.B1_FILIAL = %xfilial:SB1%
           AND (B1.B1_COD LIKE %exp:cLikeCod% OR B1.B1_DESC LIKE %exp:cLikeDesc%)
         ORDER BY B1.B1_COD
    EndSql

    While (cAliasQ)->(!Eof()) .And. nCount < 20
        oItem := JsonObject():New()
        oItem["value"] := AllTrim((cAliasQ)->B1_COD)
        oItem["label"] := AllTrim((cAliasQ)->B1_DESC)
        aAdd(aItens, oItem)
        nCount++
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

    oResp["success"] := .T.
    oResp["items"]   := aItens
    oResp["hasNext"] := .F.

    Self:SetResponse(oResp:toJson())

Return .T.

/*/{Protheus.doc} GET /estoque/zem/lookup/armazens
Lookup de armazens (tabela NNR - Locais de Armazenagem) para o campo Armazem do
formulario Angular (po-lookup). Filtra por codigo (prefixo) ou descricao (substring)
via querystring cFiltro.
IMPORTANTE: assume tabela NNR com campos NNR_CODIGO/NNR_DESCRI (padrao Protheus).
Confirme no dicionario de dados caso o ambiente use outra tabela/campos.
IMPORTANTE: sem paginacao real -- limita a 20 registros no laco ADVPL (hasNext sempre false).
@return (application/json) { "success": true, "items": [ { "value","label" } ], "hasNext": false }
/*/
//=============================================================================================================================
WSMETHOD GET ListaAmz WSSERVICE RESTZEM

    Local oResp    := JsonObject():New()
    Local aItens   := {}
    Local oItem    := Nil
    Local cAliasQ  := GetNextAlias()
    Local cFiltroF := ""
    Local cLikeCod  := ""
    Local cLikeDesc := ""
    Local nCount    := 0

    If ValType(Self:cFiltro) == "C"
        cFiltroF := AllTrim(Self:cFiltro)
    EndIf
    cLikeCod  := "%'%" + cFiltroF + "%'%"
    cLikeDesc := cLikeCod

    BeginSql Alias cAliasQ
        SELECT NNR.NNR_CODIGO, NNR.NNR_DESCRI
          FROM %table:NNR% NNR
         WHERE NNR.%notDel%
           AND NNR.NNR_FILIAL = %xfilial:NNR%
           AND (NNR.NNR_CODIGO LIKE %exp:cLikeCod% OR NNR.NNR_DESCRI LIKE %exp:cLikeDesc%)
         ORDER BY NNR.NNR_CODIGO
    EndSql

    While (cAliasQ)->(!Eof()) .And. nCount < 20
        oItem := JsonObject():New()
        oItem["value"] := AllTrim((cAliasQ)->NNR_CODIGO)
        oItem["label"] := AllTrim((cAliasQ)->NNR_DESCRI)
        aAdd(aItens, oItem)
        nCount++
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

    oResp["success"] := .T.
    oResp["items"]   := aItens
    oResp["hasNext"] := .F.

    Self:SetResponse(oResp:toJson())

Return .T.

/*/{Protheus.doc} GET /estoque/zem/dashboard
Retorna produto/armazem/saldo atual/minimo/maximo para o dashboard e para o
relatorio exportavel no Angular. Mesmo cruzamento (ZEM+SB1+SB2) usado em
Estoque/Relatorios/RELEST0001.prw, mas devolvendo os numeros crus -- a
classificacao de faixa (abaixo/proximo/normal/acima) e feita no front, onde e
mais facil ajustar os percentuais sem precisar recompilar o ADVPL.
@return (application/json) { "success": true, "items": [ { "prod","desc","local","saldo","estMin","estMax","status" } ] }
/*/
//=============================================================================================================================
WSMETHOD GET Dashboard WSSERVICE RESTZEM

    Local oResp   := JsonObject():New()
    Local aItens  := {}
    Local oItem   := Nil
    Local cAliasQ := GetNextAlias()

    BeginSql Alias cAliasQ
        SELECT ZEM.ZEM_PROD, ISNULL(B1.B1_DESC, '') AS B1_DESC, ZEM.ZEM_LOCAL,
               ISNULL(B2.B2_QATU, 0) AS SALDO, ZEM.ZEM_ESTMIN, ZEM.ZEM_ESTMAX, ZEM.ZEM_STATUS
          FROM %table:ZEM% ZEM
          LEFT JOIN %table:SB1% B1
            ON  B1.D_E_L_E_T_ = ' '
            AND B1.B1_FILIAL  = %xfilial:SB1%
            AND B1.B1_COD     = ZEM.ZEM_PROD
          LEFT JOIN %table:SB2% B2
            ON  B2.D_E_L_E_T_ = ' '
            AND B2.B2_FILIAL  = %xfilial:SB2%
            AND B2.B2_COD     = ZEM.ZEM_PROD
            AND B2.B2_LOCAL   = ZEM.ZEM_LOCAL
         WHERE ZEM.%notDel%
           AND ZEM.ZEM_FILIAL = %xfilial:ZEM%
         ORDER BY ZEM.ZEM_PROD, ZEM.ZEM_LOCAL
    EndSql

    While (cAliasQ)->(!Eof())
        oItem := JsonObject():New()
        oItem["prod"]   := AllTrim((cAliasQ)->ZEM_PROD)
        oItem["desc"]   := AllTrim((cAliasQ)->B1_DESC)
        oItem["local"]  := AllTrim((cAliasQ)->ZEM_LOCAL)
        oItem["saldo"]  := (cAliasQ)->SALDO
        oItem["estMin"] := (cAliasQ)->ZEM_ESTMIN
        oItem["estMax"] := (cAliasQ)->ZEM_ESTMAX
        oItem["status"] := AllTrim((cAliasQ)->ZEM_STATUS)
        aAdd(aItens, oItem)
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

    oResp["success"] := .T.
    oResp["items"]   := aItens

    Self:SetResponse(oResp:toJson())

Return .T.
