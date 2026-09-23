#INCLUDE "TOTVS.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "RESTFUL.ch"

/*/{Protheus.doc} EstMinMax
Abre a tela hibrida (Angular/PO-UI) de Estoque Minimo e Maximo por Produto/Armazem,
empacotada em resource/estmvc001.app e carregada via FWCallApp.
@type User Function
@author Thiago Sales - Quebec Ambiental
@since 2026-07-14
/*/
//=============================================================================================================================
USER FUNCTION EstMinMax()

    FWCallApp("estmvc001")

RETURN

/*/{Protheus.doc} JsToAdvpl
Recebe mensagens da tela Angular (estmvc001) pelo canal AdvplToJs/JsToAdvpl (TWebEngine),
usado como alternativa ao REST enquanto o HTTPREST nao esta configurado neste ambiente
(RESTZEM.PRW confirmado inalcancavel via /rest/ nesta instalacao -- ver notas em
POUI/estmvc001/src/app/services/zem.service.ts). Reaproveita a mesma logica de consulta
do RESTZEM.PRW; so muda o transporte (Self:SetResponse -> oWebChannel:AdvplToJs).

IMPORTANTE: o receiveId nao viaja automatico entre o cliente e o ADVPL -- o lado Angular
(AdvplBridgeService) embute o receiveId dentro do JSON de cContent, e aqui extraimos e
devolvemos a resposta chamando AdvplToJs(cReceiveId, ...), nao AdvplToJs(cType, ...).
@type Function
@author Thiago Sales - Quebec Ambiental
@since 2026-08-06
/*/
//=============================================================================================================================
Static Function JsToAdvpl(oWebChannel, cType, cContent)

    Local oReq       := JsonObject():New()
    Local oResp      := JsonObject():New()
    Local cReceiveId := ""

    oReq:fromJson(cContent)
    cReceiveId := oReq["receiveId"]

    Do Case
    Case cType == "zemListar"
        oResp := ZemList(oReq)
    Case cType == "zemDetalhe"
        oResp := ZemDetal(oReq)
    Case cType == "zemCriar"
        oResp := ZemCria(oReq)
    Case cType == "zemAtualizar"
        oResp := ZemAtual(oReq)
    Case cType == "zemRemover"
        oResp := ZemRemov(oReq)
    Case cType == "zemLookupProdutos"
        oResp := ZemLkpPr(oReq)
    Case cType == "zemLookupArmazens"
        oResp := ZemLkpAr(oReq)
    Case cType == "zemLookupFiliais"
        oResp := ZemLkpFi(oReq)
    Case cType == "zemDashboard"
        oResp := ZemDash(oReq)
    OtherWise
        oResp["success"] := .F.
        oResp["message"] := "Operacao nao reconhecida: " + cType
    EndCase

    If !Empty(cReceiveId)
        oWebChannel:AdvplToJs(cReceiveId, oResp:toJson())
    EndIf

Return .T.

/*/{Protheus.doc} ZemFiliais
Retorna as filiais da empresa atual (cEmpAnt) que o usuario logado tem permissao de
acessar (Grupo de Filiais do Configurador). Usada para consolidar os dados de ZEM de
todas as filiais autorizadas numa unica resposta, sem exigir que o usuario troque de
filial manualmente no SmartClient para ver cada uma (pedido do usuario -- em quem tem
acesso a varias filiais, essa troca manual gerava atraso operacional).

IMPORTANTE: a primeira versao usava AllowChangeEnv(), que nao existe nesta instalacao
(THREAD ERROR "cannot find function ALLOWCHANGEENV in AppMap", confirmado em teste
real 2026-08-18). Trocado por FWLoadSM0(lForce, lChkUser) -- funcao de framework bem
mais antiga/disseminada, com lChkUser:=.T. retornando so as filiais que o usuario
logado pode acessar (mesmo mecanismo usado pela tela nativa de troca de filial). Se
isso tambem nao existir neste ambiente, ou nenhuma filial retornar autorizada, cai de
volta para a filial da sessao atual, preservando o comportamento anterior -- mas
valide a compilacao/execucao apos o deploy antes de confiar nisso em producao.
@type Static Function
@return Array de String, codigos de filial (ZEM_FILIAL) autorizados ao usuario
/*/
//=============================================================================================================================
Static Function ZemFiliais()

    Local aFiliais   := {}
    Local aFilPermit := FWLoadSM0(.F., .T.)
    Local nX         := 0

    DbSelectArea("SM0")
    SM0->(DbSetOrder(1))
    SM0->(DbSeek(cEmpAnt))

    While SM0->(!Eof()) .And. SM0->M0_CODIGO == cEmpAnt
        nX := AScan(aFilPermit, {|aFil| AllTrim(aFil[SM0_CODFIL]) == AllTrim(SM0->M0_CODFIL)})
        If nX > 0
            aAdd(aFiliais, AllTrim(SM0->M0_CODFIL))
        EndIf
        SM0->(DbSkip())
    EndDo

    If Empty(aFiliais)
        aAdd(aFiliais, AllTrim(cFilAnt))
    EndIf

Return aFiliais

/*/{Protheus.doc} ZemInFiliais
Monta a lista de filiais autorizadas ao usuario (ZemFiliais()) ja formatada para uso
em clausula SQL IN (...), ex: "'0101','0102'". Os codigos vem sempre de SM0 filtrados
por AllowChangeEnv(), nunca de entrada livre do usuario, entao a concatenacao direta
na string SQL e segura.
@type Static Function
@return String
/*/
//=============================================================================================================================
Static Function ZemInFiliais()

    Local aFiliais := ZemFiliais()
    Local cIn       := ""
    Local nX        := 0

    For nX := 1 To Len(aFiliais)
        cIn += "'" + aFiliais[nX] + "'"
        If nX < Len(aFiliais)
            cIn += ","
        EndIf
    Next nX

Return cIn

/*/{Protheus.doc} ZemComp
Indica se a tabela informada esta configurada como compartilhada entre filiais
(x2_multifil/modo de compartilhamento da instalacao) ou exclusiva por filial. Usada
para montar corretamente a condicao de FILIAL nos JOINs de ZemList/ZemDetal/ZemDash,
que precisam funcionar tanto quando SB1/SB2 sao exclusivos (B1_FILIAL = codigo real da
filial) quanto quando sao compartilhados (B1_FILIAL fica em branco).

CAUSA RAIZ (2026-09-16): a Descricao do Produto sumia so no ambiente de teste porque o
JOIN fazia B1.B1_FILIAL = ZEM.ZEM_FILIAL direto -- funciona quando SB1 e exclusivo por
filial (bate com o codigo), mas retorna sempre vazio quando SB1 e compartilhado (B1_FILIAL
gravado em branco, nunca igual a um codigo real de filial tipo "0101"). Cada
instalacao/empresa pode ter esse compartilhamento configurado de forma diferente.
@type Static Function
@param cAlias String, alias da tabela (ex: "SB1", "SB2")
@return Logical, .T. se a tabela e compartilhada entre filiais
/*/
//=============================================================================================================================
Static Function ZemComp(cAlias)
Return Empty(xFilial(cAlias))

/*/{Protheus.doc} ZemList
Lista os registros de ZEM de TODAS as filiais que o usuario tem permissao de acessar
(ZemInFiliais()), aceitando filtros opcionais por cProd/cLocal/cStatus no JSON de
entrada. A descricao do produto vem de ZEM_NPROD (gravada no proprio registro no
momento da inclusao -- ver ZemCria/onProdutoSelecionado em zem-form.component.ts), sem
JOIN com SB1: um JOIN direto por filial (B1.B1_FILIAL = ZEM.ZEM_FILIAL) falha quando a
tabela de produtos esta configurada como compartilhada entre filiais (B1_FILIAL fica em
branco), o que ja causou a descricao sumir so em determinados ambientes/empresas.

Query classica (ChangeQuery/DbUseArea), nao BeginSql/EndSql: o preprocessador do
BeginSql neste ambiente nao aceita "IN (%exp:...)" com lista dinamica (confirmado em
Contratos/RTM002App.prw::CarregaItens -- mesmo padrao replicado aqui).
@type Static Function
/*/
//=============================================================================================================================
Static Function ZemList(oReq)

    Local oResp    := JsonObject():New()
    Local aItens   := {}
    Local oItem    := Nil
    Local cAliasQ  := GetNextAlias()
    Local cQuery   := ""
    Local cProdF   := ""
    Local cLocalF  := ""
    Local cStatusF := ""

    If ValType(oReq["cProd"]) == "C"   ; cProdF   := AllTrim(oReq["cProd"])   ; EndIf
    If ValType(oReq["cLocal"]) == "C"  ; cLocalF  := AllTrim(oReq["cLocal"])  ; EndIf
    If ValType(oReq["cStatus"]) == "C" ; cStatusF := AllTrim(oReq["cStatus"]) ; EndIf

    // Escapa aspas simples antes de concatenar na string SQL -- diferente do BeginSql
    // (%exp:...% escapa sozinho), aqui a montagem e manual.
    cProdF   := StrTran(cProdF,   "'", "''")
    cLocalF  := StrTran(cLocalF,  "'", "''")
    cStatusF := StrTran(cStatusF, "'", "''")

    cQuery := " SELECT ZEM.ZEM_FILIAL, ZEM.ZEM_PROD, ZEM.ZEM_NPROD, ZEM.ZEM_LOCAL, ZEM.ZEM_ESTMIN, ZEM.ZEM_ESTMAX, ZEM.ZEM_STATUS "
    cQuery += " FROM " + RetSqlName("ZEM") + " ZEM "
    cQuery += " WHERE ZEM.D_E_L_E_T_ = ' ' "
    cQuery += "   AND ZEM.ZEM_FILIAL IN (" + ZemInFiliais() + ") "
    If !Empty(cProdF)
        cQuery += " AND ZEM.ZEM_PROD LIKE '" + cProdF + "%' "
    EndIf
    If !Empty(cLocalF)
        cQuery += " AND ZEM.ZEM_LOCAL = '" + cLocalF + "' "
    EndIf
    If !Empty(cStatusF)
        cQuery += " AND ZEM.ZEM_STATUS = '" + cStatusF + "' "
    EndIf
    cQuery += " ORDER BY ZEM.ZEM_FILIAL, ZEM.ZEM_PROD, ZEM.ZEM_LOCAL "
    cQuery := ChangeQuery(cQuery)

    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAliasQ, .F., .T.)
    (cAliasQ)->(DbGoTop())

    While (cAliasQ)->(!Eof())
        oItem := JsonObject():New()
        oItem["filial"] := AllTrim((cAliasQ)->ZEM_FILIAL)
        oItem["prod"]   := AllTrim((cAliasQ)->ZEM_PROD)
        oItem["nprod"]  := AllTrim((cAliasQ)->ZEM_NPROD)
        oItem["local"]  := AllTrim((cAliasQ)->ZEM_LOCAL)
        oItem["estMin"] := (cAliasQ)->ZEM_ESTMIN
        oItem["estMax"] := (cAliasQ)->ZEM_ESTMAX
        oItem["status"] := AllTrim((cAliasQ)->ZEM_STATUS)
        oItem["desc"]   := AllTrim((cAliasQ)->ZEM_NPROD)
        aAdd(aItens, oItem)
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

    oResp["success"] := .T.
    oResp["items"]   := aItens

Return oResp

/*/{Protheus.doc} ZemDetal
Obtem um registro especifico de ZEM pela chave produto+armazem. Aceita 'cFilial'
opcional (a lista/dashboard agora traz linhas de varias filiais -- ver ZemList/ZemDash
-- entao a tela pode precisar reabrir um registro que nao esta na filial da sessao
atual). Sem 'cFilial', mantem o comportamento antigo (filial da sessao atual).
@type Static Function
/*/
//=============================================================================================================================
Static Function ZemDetal(oReq)

    Local oResp     := JsonObject():New()
    Local cAliasQ   := GetNextAlias()
    Local cProdP    := ""
    Local cLocalP   := ""
    Local cFilialP  := ""
    Local cFilBusca := ""

    If ValType(oReq["cProd"]) == "C"   ; cProdP   := AllTrim(oReq["cProd"])   ; EndIf
    If ValType(oReq["cLocal"]) == "C"  ; cLocalP  := AllTrim(oReq["cLocal"])  ; EndIf
    If ValType(oReq["cFilial"]) == "C" ; cFilialP := AllTrim(oReq["cFilial"]) ; EndIf

    If Empty(cProdP) .Or. Empty(cLocalP)
        oResp["success"] := .F.
        oResp["message"] := "Parametros 'cProd' e 'cLocal' sao obrigatorios"
        Return oResp
    EndIf

    // So aceita consultar filial diferente da sessao se ela estiver entre as
    // filiais autorizadas ao usuario (ZemFiliais()) -- evita que um payload
    // adulterado no front consulte uma filial nao permitida.
    If !Empty(cFilialP) .And. AScan(ZemFiliais(), cFilialP) == 0
        oResp["success"] := .F.
        oResp["message"] := "Filial nao autorizada"
        Return oResp
    EndIf
    cFilBusca := If(Empty(cFilialP), AllTrim(cFilAnt), cFilialP)

    BeginSql Alias cAliasQ
        SELECT ZEM.ZEM_FILIAL, ZEM.ZEM_PROD, ZEM.ZEM_NPROD, ZEM.ZEM_LOCAL, ZEM.ZEM_ESTMIN, ZEM.ZEM_ESTMAX, ZEM.ZEM_STATUS
          FROM %table:ZEM% ZEM
         WHERE ZEM.%notDel%
           AND ZEM.ZEM_FILIAL = %exp:cFilBusca%
           AND ZEM.ZEM_PROD   = %exp:cProdP%
           AND ZEM.ZEM_LOCAL  = %exp:cLocalP%
    EndSql

    If (cAliasQ)->(!Eof())
        oResp["success"] := .T.
        oResp["filial"]  := AllTrim((cAliasQ)->ZEM_FILIAL)
        oResp["prod"]    := AllTrim((cAliasQ)->ZEM_PROD)
        oResp["nprod"]   := AllTrim((cAliasQ)->ZEM_NPROD)
        oResp["local"]   := AllTrim((cAliasQ)->ZEM_LOCAL)
        oResp["estMin"]  := (cAliasQ)->ZEM_ESTMIN
        oResp["estMax"]  := (cAliasQ)->ZEM_ESTMAX
        oResp["status"]  := AllTrim((cAliasQ)->ZEM_STATUS)
        oResp["desc"]    := AllTrim((cAliasQ)->ZEM_NPROD)
    Else
        oResp["success"] := .F.
        oResp["message"] := "Registro nao encontrado"
    EndIf
    (cAliasQ)->(DbCloseArea())

Return oResp

/*/{Protheus.doc} ZemCria
Inclui um registro na tabela ZEM via modelo MVC do ESTMVC001.PRW, com as mesmas
validacoes de RESTZEM::IncluirZem (duplicidade, Max >= Min, Status 1/2).

Aceita 'filial' opcional -- pedido do usuario para a tela de Incluir perguntar em qual
filial gravar quando ele tem acesso a mais de uma (ver ZemLkpFi/zem-list.component.ts).
Sem ela, mantem o comportamento antigo (grava na filial da sessao atual). O valor e
setado no modelo APOS Activate() (que ja preenche ZEM_FILIAL com xFilial() por
default), sobrescrevendo o default -- CONFIRME em teste real no SmartClient que esse
SetValue realmente prevalece sobre o RecLock automatico do framework antes de confiar
nisso em producao.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZemCria(oReq)

    Local oResp    := JsonObject():New()
    Local oModel   := Nil
    Local cMsg     := ""
    Local lAtivado := .F.
    Local lFalha   := .F.
    Local nMin     := 0
    Local nMax     := 0
    Local cStatus  := ""
    Local cFilialP := ""
    Local cFilDest := ""

    If Empty(oReq["prod"]) .Or. Empty(oReq["local"])
        oResp["success"] := .F.
        oResp["message"] := "Campos 'prod' e 'local' sao obrigatorios"
        Return oResp
    EndIf

    If ValType(oReq["filial"]) == "C" ; cFilialP := AllTrim(oReq["filial"]) ; EndIf

    // Mesmo criterio de seguranca de ZemDetal/ZemAtual/ZemRemov -- so aceita gravar
    // numa filial diferente da sessao se ela estiver entre as autorizadas ao usuario.
    If !Empty(cFilialP) .And. AScan(ZemFiliais(), cFilialP) == 0
        oResp["success"] := .F.
        oResp["message"] := "Filial nao autorizada"
        Return oResp
    EndIf
    cFilDest := If(Empty(cFilialP), AllTrim(cFilAnt), cFilialP)

    nMin    := oReq["estMin"]
    nMax    := oReq["estMax"]
    cStatus := AllTrim(oReq["status"])

    If ValType(nMin) != "N" ; nMin := 0 ; EndIf
    If ValType(nMax) != "N" ; nMax := 0 ; EndIf

    If nMin > 0 .And. nMax > 0 .And. nMax < nMin
        oResp["success"] := .F.
        oResp["message"] := "Estoque Maximo nao pode ser menor que o Estoque Minimo."
        Return oResp
    EndIf

    If Empty(cStatus) .Or. !(cStatus $ "12")
        oResp["success"] := .F.
        oResp["message"] := "Status invalido. Informe 1 - Ativo ou 2 - Inativo."
        Return oResp
    EndIf

    BeginSql Alias "ZEMDUP"
        SELECT ZEM.ZEM_PROD
          FROM %table:ZEM% ZEM
         WHERE ZEM.%notDel%
           AND ZEM.ZEM_FILIAL = %exp:cFilDest%
           AND ZEM.ZEM_PROD   = %exp:AllTrim(oReq["prod"])%
           AND ZEM.ZEM_LOCAL  = %exp:AllTrim(oReq["local"])%
    EndSql

    If !ZEMDUP->(Eof())
        ZEMDUP->(DbCloseArea())
        oResp["success"] := .F.
        oResp["message"] := "Ja existe um registro de Estoque Minimo/Maximo para este Produto/Armazem."
        Return oResp
    EndIf
    ZEMDUP->(DbCloseArea())

    oModel := FWLoadModel("ESTMVC001")
    oModel:SetOperation(MODEL_OPERATION_INSERT)

    If oModel:Activate()
        lAtivado := .T.

        oModel:SetValue("ZEMMASTER", "ZEM_FILIAL", cFilDest)
        oModel:SetValue("ZEMMASTER", "ZEM_PROD",   oReq["prod"])
        oModel:SetValue("ZEMMASTER", "ZEM_NPROD",  oReq["nprod"])
        oModel:SetValue("ZEMMASTER", "ZEM_LOCAL",  oReq["local"])
        oModel:SetValue("ZEMMASTER", "ZEM_ESTMIN", oReq["estMin"])
        oModel:SetValue("ZEMMASTER", "ZEM_ESTMAX", oReq["estMax"])
        oModel:SetValue("ZEMMASTER", "ZEM_STATUS", oReq["status"])

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

/*/{Protheus.doc} ZemAtual
Altera um registro existente de ZEM via modelo MVC do ESTMVC001.PRW. Alteracao
parcial: campos nao informados no payload mantem o valor gravado. Aceita 'cFilial'
opcional (mesmo motivo de ZemDetal -- a linha alterada pode ter vindo de uma
listagem que agora agrega varias filiais).
@type Static Function
/*/
//=============================================================================================================================
Static Function ZemAtual(oReq)

    Local oResp     := JsonObject():New()
    Local oModel    := Nil
    Local cProdP    := ""
    Local cLocalP   := ""
    Local cFilialP  := ""
    Local cFilBusca := ""
    Local cMsg      := ""
    Local lAtivado  := .F.
    Local lFalha    := .F.
    Local nMin      := 0
    Local nMax      := 0
    Local cStatus   := ""

    If ValType(oReq["cProd"]) == "C"   ; cProdP   := AllTrim(oReq["cProd"])   ; EndIf
    If ValType(oReq["cLocal"]) == "C"  ; cLocalP  := AllTrim(oReq["cLocal"])  ; EndIf
    If ValType(oReq["cFilial"]) == "C" ; cFilialP := AllTrim(oReq["cFilial"]) ; EndIf

    If Empty(cProdP) .Or. Empty(cLocalP)
        oResp["success"] := .F.
        oResp["message"] := "Parametros 'cProd' e 'cLocal' sao obrigatorios"
        Return oResp
    EndIf

    If !Empty(cFilialP) .And. AScan(ZemFiliais(), cFilialP) == 0
        oResp["success"] := .F.
        oResp["message"] := "Filial nao autorizada"
        Return oResp
    EndIf
    cFilBusca := If(Empty(cFilialP), AllTrim(cFilAnt), cFilialP)

    BeginSql Alias "ZEMLOC"
        SELECT ZEM.R_E_C_N_O_ AS RECNOZEM
          FROM %table:ZEM% ZEM
         WHERE ZEM.%notDel%
           AND ZEM.ZEM_FILIAL = %exp:cFilBusca%
           AND ZEM.ZEM_PROD   = %exp:cProdP%
           AND ZEM.ZEM_LOCAL  = %exp:cLocalP%
    EndSql

    If ZEMLOC->(Eof())
        ZEMLOC->(DbCloseArea())
        oResp["success"] := .F.
        oResp["message"] := "Registro nao encontrado"
        Return oResp
    EndIf

    DbSelectArea("ZEM")
    ZEM->(DbGoTo(ZEMLOC->RECNOZEM))
    ZEMLOC->(DbCloseArea())

    nMin := oReq["estMin"]
    nMax := oReq["estMax"]
    If ValType(nMin) != "N" ; nMin := ZEM->ZEM_ESTMIN ; EndIf
    If ValType(nMax) != "N" ; nMax := ZEM->ZEM_ESTMAX ; EndIf

    cStatus := AllTrim(oReq["status"])
    If Empty(cStatus)
        cStatus := AllTrim(ZEM->ZEM_STATUS)
    EndIf

    If nMin > 0 .And. nMax > 0 .And. nMax < nMin
        oResp["success"] := .F.
        oResp["message"] := "Estoque Maximo nao pode ser menor que o Estoque Minimo."
        Return oResp
    EndIf

    If Empty(cStatus) .Or. !(cStatus $ "12")
        oResp["success"] := .F.
        oResp["message"] := "Status invalido. Informe 1 - Ativo ou 2 - Inativo."
        Return oResp
    EndIf

    oModel := FWLoadModel("ESTMVC001")
    oModel:SetOperation(MODEL_OPERATION_UPDATE)

    If oModel:Activate()
        lAtivado := .T.

        If !Empty(oReq["nprod"])
            oModel:SetValue("ZEMMASTER", "ZEM_NPROD", oReq["nprod"])
        EndIf
        If !Empty(oReq["estMin"])
            oModel:SetValue("ZEMMASTER", "ZEM_ESTMIN", oReq["estMin"])
        EndIf
        If !Empty(oReq["estMax"])
            oModel:SetValue("ZEMMASTER", "ZEM_ESTMAX", oReq["estMax"])
        EndIf
        If !Empty(oReq["status"])
            oModel:SetValue("ZEMMASTER", "ZEM_STATUS", oReq["status"])
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

/*/{Protheus.doc} ZemRemov
Exclui um registro de ZEM via modelo MVC do ESTMVC001.PRW. Aceita 'cFilial' opcional
(mesmo motivo de ZemDetal -- a linha excluida pode ter vindo de uma listagem que
agora agrega varias filiais).
@type Static Function
/*/
//=============================================================================================================================
Static Function ZemRemov(oReq)

    Local oResp     := JsonObject():New()
    Local oModel    := Nil
    Local cProdP    := ""
    Local cLocalP   := ""
    Local cFilialP  := ""
    Local cFilBusca := ""
    Local cMsg      := ""
    Local lAtivado  := .F.
    Local lFalha    := .F.

    If ValType(oReq["cProd"]) == "C"   ; cProdP   := AllTrim(oReq["cProd"])   ; EndIf
    If ValType(oReq["cLocal"]) == "C"  ; cLocalP  := AllTrim(oReq["cLocal"])  ; EndIf
    If ValType(oReq["cFilial"]) == "C" ; cFilialP := AllTrim(oReq["cFilial"]) ; EndIf

    If Empty(cProdP) .Or. Empty(cLocalP)
        oResp["success"] := .F.
        oResp["message"] := "Parametros 'cProd' e 'cLocal' sao obrigatorios"
        Return oResp
    EndIf

    If !Empty(cFilialP) .And. AScan(ZemFiliais(), cFilialP) == 0
        oResp["success"] := .F.
        oResp["message"] := "Filial nao autorizada"
        Return oResp
    EndIf
    cFilBusca := If(Empty(cFilialP), AllTrim(cFilAnt), cFilialP)

    BeginSql Alias "ZEMLOC"
        SELECT ZEM.R_E_C_N_O_ AS RECNOZEM
          FROM %table:ZEM% ZEM
         WHERE ZEM.%notDel%
           AND ZEM.ZEM_FILIAL = %exp:cFilBusca%
           AND ZEM.ZEM_PROD   = %exp:cProdP%
           AND ZEM.ZEM_LOCAL  = %exp:cLocalP%
    EndSql

    If ZEMLOC->(Eof())
        ZEMLOC->(DbCloseArea())
        oResp["success"] := .F.
        oResp["message"] := "Registro nao encontrado"
        Return oResp
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

/*/{Protheus.doc} ZemLkpPr
Lookup de produtos (SB1) para o campo Produto do formulario Angular. Mesma logica
de RESTZEM::ListaProd (limite de 20 registros, sem paginacao real).
@type Static Function
/*/
//=============================================================================================================================
Static Function ZemLkpPr(oReq)

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

Return oResp

/*/{Protheus.doc} ZemLkpAr
Lookup de armazens (tabela NNR) para o campo Armazem do formulario Angular. Mesma
logica de RESTZEM::ListaAmz (limite de 20 registros, sem paginacao real).
@type Static Function
/*/
//=============================================================================================================================
Static Function ZemLkpAr(oReq)

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

Return oResp

/*/{Protheus.doc} ZemLkpFi
Lista as filiais que o usuario logado tem permissao de acessar (ZemFiliais()), com o
nome de cada uma (SM0->M0_FILIAL), para a tela Angular exibir a selecao de filial ao
Incluir um novo registro quando o usuario tem acesso a mais de uma filial.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZemLkpFi(oReq)

    Local oResp     := JsonObject():New()
    Local aItens    := {}
    Local oItem     := Nil
    Local aFiliais  := ZemFiliais()
    Local nX        := 0

    DbSelectArea("SM0")
    SM0->(DbSetOrder(1))

    For nX := 1 To Len(aFiliais)
        oItem := JsonObject():New()
        oItem["value"] := aFiliais[nX]
        oItem["label"] := aFiliais[nX]
        If SM0->(DbSeek(cEmpAnt + aFiliais[nX]))
            oItem["label"] := aFiliais[nX] + " - " + AllTrim(SM0->M0_FILIAL)
        EndIf
        aAdd(aItens, oItem)
    Next nX

    oResp["success"] := .T.
    oResp["items"]   := aItens

Return oResp

/*/{Protheus.doc} ZemDash
Retorna produto/armazem/saldo atual/minimo/maximo para o dashboard, de TODAS as
filiais que o usuario tem permissao de acessar (ZemInFiliais()) -- mesmo motivo de
ZemList. Classificacao de faixa continua sendo feita no front. Descricao vem de
ZEM_NPROD (sem JOIN com SB1 -- ver ZemList). O JOIN com SB2 (saldo) usa
B2.B2_FILIAL = ZEM.ZEM_FILIAL quando SB2 e exclusivo por filial, ou ignora a filial
(compartilhado) -- ver ZemComp().

Query classica (ChangeQuery/DbUseArea), pelo mesmo motivo documentado em ZemList
(BeginSql neste ambiente nao aceita IN (%exp:...) com lista dinamica).
@type Static Function
/*/
//=============================================================================================================================
Static Function ZemDash(oReq)

    Local oResp   := JsonObject():New()
    Local aItens  := {}
    Local oItem   := Nil
    Local cAliasQ := GetNextAlias()
    Local cQuery  := ""

    cQuery := " SELECT ZEM.ZEM_FILIAL, ZEM.ZEM_PROD, ZEM.ZEM_NPROD, ZEM.ZEM_LOCAL, "
    cQuery += " ISNULL(B2.B2_QATU, 0) AS SALDO, ZEM.ZEM_ESTMIN, ZEM.ZEM_ESTMAX, ZEM.ZEM_STATUS "
    cQuery += " FROM " + RetSqlName("ZEM") + " ZEM "
    cQuery += " LEFT JOIN " + RetSqlName("SB2") + " B2 "
    cQuery += "   ON B2.D_E_L_E_T_ = ' ' "
    cQuery += If(ZemComp("SB2"), "  AND RTrim(B2.B2_FILIAL) = '' ", "  AND B2.B2_FILIAL = ZEM.ZEM_FILIAL ")
    cQuery += "  AND B2.B2_COD     = ZEM.ZEM_PROD "
    cQuery += "  AND B2.B2_LOCAL   = ZEM.ZEM_LOCAL "
    cQuery += " WHERE ZEM.D_E_L_E_T_ = ' ' "
    cQuery += "   AND ZEM.ZEM_FILIAL IN (" + ZemInFiliais() + ") "
    cQuery += " ORDER BY ZEM.ZEM_FILIAL, ZEM.ZEM_PROD, ZEM.ZEM_LOCAL "
    cQuery := ChangeQuery(cQuery)

    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAliasQ, .F., .T.)
    (cAliasQ)->(DbGoTop())

    While (cAliasQ)->(!Eof())
        oItem := JsonObject():New()
        oItem["filial"] := AllTrim((cAliasQ)->ZEM_FILIAL)
        oItem["prod"]   := AllTrim((cAliasQ)->ZEM_PROD)
        oItem["desc"]   := AllTrim((cAliasQ)->ZEM_NPROD)
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

Return oResp
