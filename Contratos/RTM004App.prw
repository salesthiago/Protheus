#INCLUDE "TOTVS.CH"
#INCLUDE "PROTHEUS.CH"

/*/{Protheus.doc} RTM004App
Abre a tela hibrida (Angular/PO-UI) de Servicos de Medicao (rtm004), empacotada
em resource/rtm004.app e carregada via FWCallApp -- mesmo mecanismo de canal de
RTM003App.prw (mesma pasta).

Cadastros mantidos por esta rotina:
  ZMS - Servico de Medicao do contrato (codigo, descricao e status ativo/inativo)
  ZMC - Amarracao Servico de Medicao x Classe de Valor (CTH). Um servico pode ter
        varias classes de valor; o par servico+classe e unico.

Dicionario (criar no Configurador antes de usar -- sem as tabelas a tela so
devolve a mensagem de ZsmTabOk):

  ZMS - Servicos de Medicao (modo de acesso igual ao do CN9)
    ZMS_FILIAL  C  (tamanho da filial)
    ZMS_CODIGO  C  6   Codigo           (obrigatorio)
    ZMS_DESCRI  C  60  Descricao        (obrigatorio)
    ZMS_STATUS  C  1   Status           (obrigatorio) 1=Ativo;2=Inativo  inic. padrao "1"
    Indice 1: ZMS_FILIAL+ZMS_CODIGO   (chave unica)

  ZMC - Servico de Medicao x Classe de Valor (mesmo modo de acesso da ZMS)
    ZMC_FILIAL  C  (tamanho da filial)
    ZMC_CODSRV  C  6   Cod. Servico     (obrigatorio)
    ZMC_CLVL    C  9   Classe de Valor  (obrigatorio, mesmo tamanho de CTH_CLVL, F3 CTH)
    Indice 1: ZMC_FILIAL+ZMC_CODSRV+ZMC_CLVL   (chave unica)
    Indice 2: ZMC_FILIAL+ZMC_CLVL+ZMC_CODSRV

  ZMM - Lancamento de Medicao por competencia (mesmo modo de acesso da ZMS). Uma
        linha por competencia + classe de valor + servico; o "cabecalho" do
        lancamento (competencia + classe) e so o agrupamento dessas linhas e nao
        muda depois de gravado. Descricoes gravadas na inclusao do item.
    ZMM_FILIAL  C  (tamanho da filial)
    ZMM_COMPET  C  6   Competencia      (obrigatorio) AAAAMM, picture @R 999999
    ZMM_CLVL    C  9   Classe de Valor  (obrigatorio, mesmo tamanho de CTH_CLVL, F3 CTH)
    ZMM_DESCVL  C  60  Desc. Classe Vl.
    ZMM_CODSRV  C  6   Cod. Servico     (obrigatorio, mesmo tamanho de ZMS_CODIGO)
    ZMM_DESCSR  C  60  Desc. Servico
    ZMM_VALOR   N  14,2 Valor Medicao   (obrigatorio, picture @E 99,999,999,999.99)
    ZMM_EMISSA  D  8   Dt. Lancamento   (preenchido com a data base na inclusao do item)
    Indice 1: ZMM_FILIAL+ZMM_COMPET+ZMM_CLVL+ZMM_CODSRV   (chave unica)
    Indice 2: ZMM_FILIAL+ZMM_CLVL+ZMM_COMPET

  CTH - campo customizado na Classe de Valor
    CTH_XRET    N       % Retencao       soma dos percentuais das taxas retidas da classe;
                                         aplicado sobre o total bruto da medicao para
                                         chegar ao total liquido (ver ZmmPerRet)

@type User Function
@author Thiago Sales - Quebec Ambiental
@since 2026-09-30
/*/
//=============================================================================================================================
USER FUNCTION RTM004App()

    FWCallApp("rtm004")

RETURN

/*/{Protheus.doc} JsToAdvpl
Recebe mensagens da tela Angular (rtm004) pelo canal AdvplToJs/JsToAdvpl
(TWebEngine/TWebChannel) -- mesmo padrao de Contratos/RTM003App.prw.
Qualquer erro de execucao dentro da operacao vira {success:.F., message} em vez
de derrubar a thread -- sem resposta o Angular fica esperando para sempre.
@type Function
@author Thiago Sales - Quebec Ambiental
@since 2026-09-30
/*/
//=============================================================================================================================
Static Function JsToAdvpl(oWebChannel, cType, cContent)

    Local oReq       := JsonObject():New()
    Local oResp      := JsonObject():New()
    Local oErr       := Nil
    Local bPrev      := Nil
    Local cReceiveId := ""

    oReq:fromJson(cContent)
    cReceiveId := oReq["receiveId"]

    bPrev := ErrorBlock({|e| Break(e)})
    Begin Sequence

    If ZsmTabOk(oResp)
        Do Case
        Case cType == "servicoListar"
            oResp := ZsmList(oReq)
        Case cType == "servicoDetalhe"
            oResp := ZsmDet(oReq)
        Case cType == "servicoSalvar"
            oResp := ZsmSalvar(oReq)
        Case cType == "servicoStatus"
            oResp := ZsmStatus(oReq)
        Case cType == "servicoExcluir"
            oResp := ZsmExcl(oReq)
        Case cType == "servicoProximoCodigo"
            oResp := ZsmProx(oReq)
        Case cType == "classeVincular"
            oResp := ZsmVinc(oReq)
        Case cType == "classeDesvincular"
            oResp := ZsmDesv(oReq)
        Case cType == "lookupClasseValor"
            oResp := ZsmCTH(oReq)
        Case cType == "medicaoListar"
            oResp := IIf(ZmmTabOk(oResp), ZmmList(oReq), oResp)
        Case cType == "medicaoCarregar"
            oResp := IIf(ZmmTabOk(oResp), ZmmCarr(oReq), oResp)
        Case cType == "medicaoSalvar"
            oResp := IIf(ZmmTabOk(oResp), ZmmSalvar(oReq), oResp)
        Case cType == "medicaoExcluir"
            oResp := IIf(ZmmTabOk(oResp), ZmmExcl(oReq), oResp)
        Case cType == "lookupClasseMedicao"
            oResp := ZmmCTH(oReq)
        OtherWise
            oResp["success"] := .F.
            oResp["message"] := "Operacao nao reconhecida: " + cType
        EndCase
    EndIf

    Recover Using oErr
        oResp := JsonObject():New()
        oResp["success"] := .F.
        oResp["message"] := "Falha inesperada: " + IIf(ValType(oErr) == "O", AllTrim(oErr:Description), "erro desconhecido")
    End Sequence
    ErrorBlock(bPrev)

    If !Empty(cReceiveId)
        oWebChannel:AdvplToJs(cReceiveId, oResp:toJson())
    EndIf

Return .T.

/*/{Protheus.doc} ZsmTabOk
Confere se ZMS/ZMC ja existem no dicionario deste ambiente (ver cabecalho do
fonte). Se nao existirem, preenche oResp com a mensagem de erro.
@type Static Function
@param oResp JsonObject, resposta a preencher em caso de falha
@return logico, .T. se as duas tabelas existem
/*/
//=============================================================================================================================
Static Function ZsmTabOk(oResp)

    If AliasInDic("ZMS") .And. AliasInDic("ZMC")
        Return .T.
    EndIf

    oResp["success"] := .F.
    oResp["message"] := "Tabelas ZMS/ZMC (Servicos de Medicao) nao encontradas no dicionario deste ambiente."

Return .F.

/*/{Protheus.doc} ZsmList
Lista os servicos de medicao da filial (operacao "servicoListar") com a
quantidade de classes de valor vinculadas a cada um. Filtros sao aplicados na
tela (mesmo padrao da listagem do rtm003).
@type Static Function
@param oReq JsonObject, {} (sem parametros)
@return JsonObject, {success, servicos:[{codigo,descricao,status,qtdClasses}]}
/*/
//=============================================================================================================================
Static Function ZsmList(oReq)

    Local oResp   := JsonObject():New()
    Local aItens  := {}
    Local oItem   := Nil
    Local cAliasQ := GetNextAlias()

    BeginSql Alias cAliasQ
        SELECT ZMS.ZMS_CODIGO AS CODIGO,
               ZMS.ZMS_DESCRI AS DESCRI,
               ZMS.ZMS_STATUS AS STATUS,
               (SELECT COUNT(*)
                  FROM %table:ZMC% ZMC
                 WHERE ZMC.%notDel%
                   AND ZMC.ZMC_FILIAL = %xfilial:ZMC%
                   AND ZMC.ZMC_CODSRV = ZMS.ZMS_CODIGO) AS QTDCLS
          FROM %table:ZMS% ZMS
         WHERE ZMS.%notDel%
           AND ZMS.ZMS_FILIAL = %xfilial:ZMS%
         ORDER BY ZMS.ZMS_CODIGO
    EndSql

    While (cAliasQ)->(!Eof())
        oItem := JsonObject():New()
        oItem["codigo"]     := AllTrim((cAliasQ)->CODIGO)
        oItem["descricao"]  := AllTrim((cAliasQ)->DESCRI)
        oItem["status"]     := IIf(AllTrim((cAliasQ)->STATUS) == "2", "2", "1")
        oItem["qtdClasses"] := (cAliasQ)->QTDCLS
        aAdd(aItens, oItem)
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

    oResp["success"]  := .T.
    oResp["servicos"] := aItens

Return oResp

/*/{Protheus.doc} ZsmDet
Detalhe de um servico (operacao "servicoDetalhe").
@type Static Function
@param oReq JsonObject, {codigo}
@return JsonObject, ver ZsmMont
/*/
//=============================================================================================================================
Static Function ZsmDet(oReq)

Return ZsmMont(ZsmStr(oReq, "codigo"))

/*/{Protheus.doc} ZsmMont
Monta a resposta padrao de um servico: cabecalho (ZMS) + classes de valor
vinculadas (ZMC, descricao lida do CTH).
@type Static Function
@param cCodigo caractere, codigo do servico
@param cMsg caractere, mensagem de sucesso opcional
@return JsonObject, {success, message, servico:{codigo,descricao,status}, classes:[{classe,descricao}]}
/*/
//=============================================================================================================================
Static Function ZsmMont(cCodigo, cMsg)

    Local oResp   := JsonObject():New()
    Local oServ   := JsonObject():New()
    Local aClas   := {}
    Local oItem   := Nil
    Local cAliasQ := GetNextAlias()
    Local cCodPad := ""

    Default cMsg := ""

    If !ZsmSeekSrv(cCodigo)
        oResp["success"] := .F.
        oResp["message"] := "Servico de medicao [" + cCodigo + "] nao encontrado."
        Return oResp
    EndIf

    cCodPad := ZMS->ZMS_CODIGO

    oServ["codigo"]    := AllTrim(ZMS->ZMS_CODIGO)
    oServ["descricao"] := AllTrim(ZMS->ZMS_DESCRI)
    oServ["status"]    := IIf(AllTrim(ZMS->ZMS_STATUS) == "2", "2", "1")

    BeginSql Alias cAliasQ
        SELECT ZMC.ZMC_CLVL AS CLASSE, COALESCE(CTH.CTH_DESC01, ' ') AS DESCRI
          FROM %table:ZMC% ZMC
          LEFT JOIN %table:CTH% CTH
            ON CTH.CTH_FILIAL = %xfilial:CTH%
           AND CTH.CTH_CLVL = ZMC.ZMC_CLVL
           AND CTH.%notDel%
         WHERE ZMC.%notDel%
           AND ZMC.ZMC_FILIAL = %xfilial:ZMC%
           AND ZMC.ZMC_CODSRV = %exp:cCodPad%
         ORDER BY ZMC.ZMC_CLVL
    EndSql

    While (cAliasQ)->(!Eof())
        oItem := JsonObject():New()
        oItem["classe"]    := AllTrim((cAliasQ)->CLASSE)
        oItem["descricao"] := AllTrim((cAliasQ)->DESCRI)
        aAdd(aClas, oItem)
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

    oResp["success"] := .T.
    oResp["servico"] := oServ
    oResp["classes"] := aClas
    If !Empty(cMsg)
        oResp["message"] := cMsg
    EndIf

Return oResp

/*/{Protheus.doc} ZsmSalvar
Inclui ou altera um servico de medicao (operacao "servicoSalvar").
Na inclusao recusa codigo ja existente e grava, na mesma transacao, as classes
de valor informadas na tela (classes) -- todas validadas antes de gravar
qualquer registro (ZsmVldCls). Na alteracao o
codigo nao muda (so descricao e status); as classes sao mantidas pela propria
tela via classeVincular/classeDesvincular.
@type Static Function
@param oReq JsonObject, {inclusao, codigo, descricao, status, classes:[codigo da classe] (so inclusao)}
@return JsonObject, ver ZsmMont (ou {success:.F., message})
/*/
//=============================================================================================================================
Static Function ZsmSalvar(oReq)

    Local oResp     := JsonObject():New()
    Local lInclusao := ValType(oReq["inclusao"]) == "L" .And. oReq["inclusao"]
    Local cCodigo   := Upper(ZsmStr(oReq, "codigo"))
    Local cDescri   := ZsmStr(oReq, "descricao")
    Local cStatus   := ZsmStr(oReq, "status")
    Local lExiste   := .F.
    Local aClasses  := {}
    Local cClasse   := ""
    Local cErro     := ""
    Local nI        := 0

    Do Case
    Case Empty(cCodigo)
        oResp["message"] := "Codigo do servico e obrigatorio."
    Case Len(cCodigo) > TamSX3("ZMS_CODIGO")[1]
        oResp["message"] := "Codigo do servico deve ter no maximo " + cValToChar(TamSX3("ZMS_CODIGO")[1]) + " caracteres."
    Case Empty(cDescri)
        oResp["message"] := "Descricao do servico e obrigatoria."
    Case Len(cDescri) > TamSX3("ZMS_DESCRI")[1]
        oResp["message"] := "Descricao do servico deve ter no maximo " + cValToChar(TamSX3("ZMS_DESCRI")[1]) + " caracteres."
    Case !(cStatus == "1" .Or. cStatus == "2")
        oResp["message"] := "Status invalido (1=Ativo, 2=Inativo)."
    EndCase

    If !Empty(oResp["message"])
        oResp["success"] := .F.
        Return oResp
    EndIf

    lExiste := ZsmSeekSrv(cCodigo)

    If lInclusao .And. lExiste
        oResp["success"] := .F.
        oResp["message"] := "Ja existe um servico de medicao com o codigo [" + cCodigo + "]."
        Return oResp
    EndIf

    If !lInclusao .And. !lExiste
        oResp["success"] := .F.
        oResp["message"] := "Servico de medicao [" + cCodigo + "] nao encontrado."
        Return oResp
    EndIf

    // Classes de valor da inclusao: valida TODAS antes de gravar (inclusive repetidas na lista).
    If lInclusao .And. ValType(oReq["classes"]) == "A"
        For nI := 1 To Len(oReq["classes"])
            If ValType(oReq["classes"][nI]) != "C" .Or. Empty(oReq["classes"][nI])
                Loop
            EndIf
            cClasse := Upper(AllTrim(oReq["classes"][nI]))
            If aScan(aClasses, {|x| x == cClasse}) > 0
                cErro := "O projeto [" + cClasse + "] foi informado mais de uma vez."
            Else
                cErro := ZsmVldCls(cClasse)
            EndIf
            If !Empty(cErro)
                oResp["success"] := .F.
                oResp["message"] := cErro
                Return oResp
            EndIf
            aAdd(aClasses, cClasse)
        Next nI
    EndIf

    // Sem Begin/End Transaction (mesmo padrao do RTM003App): dentro do FWCallApp a transacao
    // ficava aberta sem commit -- a tela recebia sucesso (a propria thread enxergava o registro),
    // mas nada era efetivado no banco. As classes ja foram todas validadas acima, antes de gravar.
    If !ZMS->(RecLock("ZMS", lInclusao))
        oResp["success"] := .F.
        oResp["message"] := "Servico de medicao [" + cCodigo + "] em uso por outro usuario. Tente novamente."
        Return oResp
    EndIf
        If lInclusao
            ZMS->ZMS_FILIAL := xFilial("ZMS")
            ZMS->ZMS_CODIGO := cCodigo
        EndIf
        ZMS->ZMS_DESCRI := cDescri
        ZMS->ZMS_STATUS := cStatus
    ZMS->(MsUnlock())

    For nI := 1 To Len(aClasses)
        RecLock("ZMC", .T.)
            ZMC->ZMC_FILIAL := xFilial("ZMC")
            ZMC->ZMC_CODSRV := ZMS->ZMS_CODIGO
            ZMC->ZMC_CLVL   := Padr(aClasses[nI], TamSX3("ZMC_CLVL")[1])
        ZMC->(MsUnlock())
    Next nI

Return ZsmMont(cCodigo, IIf(lInclusao, "Servico incluido com " + cValToChar(Len(aClasses)) + " projeto(s).", "Servico alterado com sucesso."))

/*/{Protheus.doc} ZsmStatus
Ativa/inativa um servico de medicao (operacao "servicoStatus").
@type Static Function
@param oReq JsonObject, {codigo, status}
@return JsonObject, {success, message}
/*/
//=============================================================================================================================
Static Function ZsmStatus(oReq)

    Local oResp   := JsonObject():New()
    Local cCodigo := ZsmStr(oReq, "codigo")
    Local cStatus := ZsmStr(oReq, "status")

    If !(cStatus == "1" .Or. cStatus == "2")
        oResp["success"] := .F.
        oResp["message"] := "Status invalido (1=Ativo, 2=Inativo)."
        Return oResp
    EndIf

    If !ZsmSeekSrv(cCodigo)
        oResp["success"] := .F.
        oResp["message"] := "Servico de medicao [" + cCodigo + "] nao encontrado."
        Return oResp
    EndIf

    If !ZMS->(RecLock("ZMS", .F.))
        oResp["success"] := .F.
        oResp["message"] := "Servico de medicao [" + cCodigo + "] em uso por outro usuario. Tente novamente."
        Return oResp
    EndIf
        ZMS->ZMS_STATUS := cStatus
    ZMS->(MsUnlock())

    oResp["success"] := .T.
    oResp["message"] := "Servico " + cCodigo + IIf(cStatus == "1", " ativado.", " inativado.")

Return oResp

/*/{Protheus.doc} ZsmExcl
Exclui um servico de medicao (operacao "servicoExcluir"). Recusa enquanto
houver classe de valor vinculada (ZMC) -- o usuario remove os vinculos ou
inativa o servico -- ou lancamento de medicao (ZMM) usando o servico.
@type Static Function
@param oReq JsonObject, {codigo}
@return JsonObject, {success, message}
/*/
//=============================================================================================================================
Static Function ZsmExcl(oReq)

    Local oResp   := JsonObject():New()
    Local cCodigo := ZsmStr(oReq, "codigo")

    If !ZsmSeekSrv(cCodigo)
        oResp["success"] := .F.
        oResp["message"] := "Servico de medicao [" + cCodigo + "] nao encontrado."
        Return oResp
    EndIf

    If ZsmZmcQtd(ZMS->ZMS_CODIGO) > 0
        oResp["success"] := .F.
        oResp["message"] := "O servico [" + cCodigo + "] possui projetos vinculados. " + ;
            "Remova os vinculos antes de excluir ou inative o servico."
        Return oResp
    EndIf

    If AliasInDic("ZMM") .And. ZmmUsaSrv(ZMS->ZMS_CODIGO)
        oResp["success"] := .F.
        oResp["message"] := "O servico [" + cCodigo + "] possui lancamentos de medicao. Inative o servico em vez de excluir."
        Return oResp
    EndIf

    If !ZMS->(RecLock("ZMS", .F.))
        oResp["success"] := .F.
        oResp["message"] := "Servico de medicao [" + cCodigo + "] em uso por outro usuario. Tente novamente."
        Return oResp
    EndIf
        ZMS->(dbDelete())
    ZMS->(MsUnlock())

    oResp["success"] := .T.
    oResp["message"] := "Servico " + cCodigo + " excluido com sucesso."

Return oResp

/*/{Protheus.doc} ZsmProx
Sugere o proximo codigo de servico (operacao "servicoProximoCodigo") -- maior
ZMS_CODIGO da filial + 1 (Soma1). So uma sugestao para pre-preencher o campo;
a unicidade real e garantida em ZsmSalvar (recusa codigo ja existente).
@type Static Function
@param oReq JsonObject, {} (sem parametros)
@return JsonObject, {success, codigo}
/*/
//=============================================================================================================================
Static Function ZsmProx(oReq)

    Local oResp   := JsonObject():New()
    Local cAliasQ := GetNextAlias()
    Local nTam    := TamSX3("ZMS_CODIGO")[1]
    Local cMax    := ""

    BeginSql Alias cAliasQ
        SELECT MAX(ZMS.ZMS_CODIGO) AS MAXCOD
          FROM %table:ZMS% ZMS
         WHERE ZMS.%notDel%
           AND ZMS.ZMS_FILIAL = %xfilial:ZMS%
    EndSql

    If (cAliasQ)->(!Eof()) .And. ValType((cAliasQ)->MAXCOD) == "C"
        cMax := AllTrim((cAliasQ)->MAXCOD)
    EndIf
    (cAliasQ)->(DbCloseArea())

    oResp["success"] := .T.
    oResp["codigo"]  := IIf(Empty(cMax), StrZero(1, nTam), AllTrim(Soma1(Padr(cMax, nTam))))

Return oResp

/*/{Protheus.doc} ZsmVinc
Vincula uma classe de valor a um servico (operacao "classeVincular").
Valida: servico existe; classe existe no CTH, e analitica e nao esta
bloqueada; e o par servico+classe ainda nao esta cadastrado na ZMC.
@type Static Function
@param oReq JsonObject, {codigo, classe}
@return JsonObject, ver ZsmMont (ou {success:.F., message})
/*/
//=============================================================================================================================
Static Function ZsmVinc(oReq)

    Local oResp   := JsonObject():New()
    Local cCodigo := ZsmStr(oReq, "codigo")
    Local cClasse := Upper(ZsmStr(oReq, "classe"))
    Local cClPad  := ""
    Local cErro   := ""

    If Empty(cClasse)
        oResp["success"] := .F.
        oResp["message"] := "Projeto e obrigatorio."
        Return oResp
    EndIf

    If !ZsmSeekSrv(cCodigo)
        oResp["success"] := .F.
        oResp["message"] := "Servico de medicao [" + cCodigo + "] nao encontrado."
        Return oResp
    EndIf

    cClPad := Padr(cClasse, TamSX3("ZMC_CLVL")[1])

    cErro := ZsmVldCls(cClasse)
    If !Empty(cErro)
        oResp["success"] := .F.
        oResp["message"] := cErro
        Return oResp
    EndIf

    If ZsmZmcRec(ZMS->ZMS_CODIGO, cClPad) > 0
        oResp["success"] := .F.
        oResp["message"] := "O projeto [" + cClasse + "] ja esta vinculado ao servico [" + cCodigo + "]."
        Return oResp
    EndIf

    RecLock("ZMC", .T.)
        ZMC->ZMC_FILIAL := xFilial("ZMC")
        ZMC->ZMC_CODSRV := ZMS->ZMS_CODIGO
        ZMC->ZMC_CLVL   := cClPad
    ZMC->(MsUnlock())

Return ZsmMont(cCodigo, "Projeto " + cClasse + " vinculado.")

/*/{Protheus.doc} ZsmVldCls
Valida uma classe de valor para vinculo: existe no CTH, e analitica e nao
esta bloqueada. Usada por ZsmVinc e pela inclusao com classes (ZsmSalvar).
@type Static Function
@param cClasse caractere, codigo da classe de valor
@return caractere, mensagem de erro ou "" se valida
/*/
//=============================================================================================================================
Static Function ZsmVldCls(cClasse)

    CTH->(dbSetOrder(1)) // CTH_FILIAL+CTH_CLVL
    If !CTH->(dbSeek(xFilial("CTH") + Padr(cClasse, TamSX3("CTH_CLVL")[1])))
        Return "Projeto [" + cClasse + "] nao encontrado."
    EndIf

    If AllTrim(CTH->CTH_BLOQ) == "1"
        Return "Projeto [" + cClasse + "] esta bloqueado."
    EndIf

    If AllTrim(CTH->CTH_CLASSE) == "1"
        Return "Projeto [" + cClasse + "] e sintetico. Informe um projeto analitico."
    EndIf

Return ""

/*/{Protheus.doc} ZsmDesv
Remove o vinculo de uma classe de valor com o servico (operacao
"classeDesvincular").
@type Static Function
@param oReq JsonObject, {codigo, classe}
@return JsonObject, ver ZsmMont (ou {success:.F., message})
/*/
//=============================================================================================================================
Static Function ZsmDesv(oReq)

    Local oResp   := JsonObject():New()
    Local cCodigo := ZsmStr(oReq, "codigo")
    Local cClasse := ZsmStr(oReq, "classe")
    Local nRecZmc := 0

    If !ZsmSeekSrv(cCodigo)
        oResp["success"] := .F.
        oResp["message"] := "Servico de medicao [" + cCodigo + "] nao encontrado."
        Return oResp
    EndIf

    nRecZmc := ZsmZmcRec(ZMS->ZMS_CODIGO, Padr(cClasse, TamSX3("ZMC_CLVL")[1]))
    If nRecZmc > 0
        ZMC->(dbGoTo(nRecZmc))
    Else
        oResp["success"] := .F.
        oResp["message"] := "O projeto [" + cClasse + "] nao esta vinculado ao servico [" + cCodigo + "]."
        Return oResp
    EndIf

    If !ZMC->(RecLock("ZMC", .F.))
        oResp["success"] := .F.
        oResp["message"] := "Vinculo em uso por outro usuario. Tente novamente."
        Return oResp
    EndIf
        ZMC->(dbDelete())
    ZMC->(MsUnlock())

Return ZsmMont(cCodigo, "Projeto " + cClasse + " removido.")

/*/{Protheus.doc} ZsmZmcRec
Localiza o vinculo servico x classe de valor na ZMC por SQL, comparando os
proprios campos -- nao depende da ordem do indice 1 da ZMC no dicionario (com o
indice criado diferente da especificacao, o dbSeek encontrava outra classe do
mesmo servico e acusava "ja vinculada", 2026-10-02).
@type Static Function
@param cCodPad caractere, codigo do servico (com padding de ZMS_CODIGO)
@param cClPad caractere, classe de valor (com padding de ZMC_CLVL)
@return numerico, R_E_C_N_O_ do vinculo ou 0 se nao existe
/*/
//=============================================================================================================================
Static Function ZsmZmcRec(cCodPad, cClPad)

    Local cAliasQ := GetNextAlias()
    Local nRec    := 0

    BeginSql Alias cAliasQ
        SELECT MIN(ZMC.R_E_C_N_O_) AS REC
          FROM %table:ZMC% ZMC
         WHERE ZMC.%notDel%
           AND ZMC.ZMC_FILIAL = %xfilial:ZMC%
           AND ZMC.ZMC_CODSRV = %exp:cCodPad%
           AND ZMC.ZMC_CLVL = %exp:cClPad%
    EndSql
    If (cAliasQ)->(!Eof()) .And. ValType((cAliasQ)->REC) == "N"
        nRec := (cAliasQ)->REC
    EndIf
    (cAliasQ)->(DbCloseArea())

Return nRec

/*/{Protheus.doc} ZsmZmcQtd
Quantidade de classes de valor vinculadas ao servico (ZMC), por SQL -- mesmo
motivo de ZsmZmcRec.
@type Static Function
@param cCodPad caractere, codigo do servico (com padding de ZMS_CODIGO)
@return numerico
/*/
//=============================================================================================================================
Static Function ZsmZmcQtd(cCodPad)

    Local cAliasQ := GetNextAlias()
    Local nQtd    := 0

    BeginSql Alias cAliasQ
        SELECT COUNT(*) AS QTD
          FROM %table:ZMC% ZMC
         WHERE ZMC.%notDel%
           AND ZMC.ZMC_FILIAL = %xfilial:ZMC%
           AND ZMC.ZMC_CODSRV = %exp:cCodPad%
    EndSql
    If (cAliasQ)->(!Eof())
        nQtd := (cAliasQ)->QTD
    EndIf
    (cAliasQ)->(DbCloseArea())

Return nQtd

/*/{Protheus.doc} ZsmCTH
Consulta de classes de valor (operacao "lookupClasseValor") -- so analiticas
e nao bloqueadas, as mesmas que ZsmVinc aceita. Mesmo formato dos lookups do
RTM003App (ZcnCCus): ate 20 itens por busca.
@type Static Function
@param oReq JsonObject, {filtro}
@return JsonObject, {success, items:[{codigo,descricao}], hasNext}
/*/
//=============================================================================================================================
Static Function ZsmCTH(oReq)

    Local oResp   := JsonObject():New()
    Local aItens  := {}
    Local oItem   := Nil
    Local cAliasQ := GetNextAlias()
    Local cLike   := "%'%" + Upper(ZsmStr(oReq, "filtro")) + "%'%"
    Local nCount  := 0

    BeginSql Alias cAliasQ
        SELECT CTH_CLVL AS CODIGO, CTH_DESC01 AS DESCRI
          FROM %table:CTH% CTH
         WHERE CTH.%notDel%
           AND CTH.CTH_FILIAL = %xfilial:CTH%
           AND CTH.CTH_CLASSE = '2'
           AND CTH.CTH_BLOQ <> '1'
           AND (CTH.CTH_CLVL LIKE %exp:cLike% OR UPPER(CTH.CTH_DESC01) LIKE %exp:cLike%)
         ORDER BY CTH.CTH_CLVL
    EndSql

    While (cAliasQ)->(!Eof()) .And. nCount < 20
        oItem := JsonObject():New()
        oItem["codigo"]    := AllTrim((cAliasQ)->CODIGO)
        oItem["descricao"] := AllTrim((cAliasQ)->DESCRI)
        aAdd(aItens, oItem)
        nCount++
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

    oResp["success"] := .T.
    oResp["items"]   := aItens
    oResp["hasNext"] := .F.

Return oResp

/*/{Protheus.doc} ZmmTabOk
Confere se a ZMM (Lancamento de Medicao) ja existe no dicionario deste ambiente.
Separada de ZsmTabOk para o cadastro de servicos continuar funcionando antes de
a ZMM ser criada.
@type Static Function
@param oResp JsonObject, resposta a preencher em caso de falha
@return logico, .T. se a tabela existe
/*/
//=============================================================================================================================
Static Function ZmmTabOk(oResp)

    If AliasInDic("ZMM")
        Return .T.
    EndIf

    oResp["success"] := .F.
    oResp["message"] := "Tabela ZMM (Lancamentos de Medicao) nao encontrada no dicionario deste ambiente."

Return .F.

/*/{Protheus.doc} ZmmList
Lista os lancamentos de medicao da filial (operacao "medicaoListar"), um por
competencia + classe de valor, com quantidade de itens e total. Filtros sao
aplicados na tela (mesmo padrao de ZsmList).
@type Static Function
@param oReq JsonObject, {} (sem parametros)
@return JsonObject, {success, lancamentos:[{competencia,mes,ano,classe,descricaoClasse,qtdItens,total}]}
/*/
//=============================================================================================================================
Static Function ZmmList(oReq)

    Local oResp   := JsonObject():New()
    Local aItens  := {}
    Local oItem   := Nil
    Local cAliasQ := GetNextAlias()

    BeginSql Alias cAliasQ
        Column TOTAL As Numeric(16, 2)
        SELECT ZMM.ZMM_COMPET AS COMPET,
               ZMM.ZMM_CLVL AS CLASSE,
               MAX(ZMM.ZMM_DESCVL) AS DESCRI,
               COUNT(*) AS QTD,
               SUM(ZMM.ZMM_VALOR) AS TOTAL
          FROM %table:ZMM% ZMM
         WHERE ZMM.%notDel%
           AND ZMM.ZMM_FILIAL = %xfilial:ZMM%
         GROUP BY ZMM.ZMM_COMPET, ZMM.ZMM_CLVL
         ORDER BY ZMM.ZMM_COMPET DESC, ZMM.ZMM_CLVL
    EndSql

    While (cAliasQ)->(!Eof())
        oItem := JsonObject():New()
        oItem["competencia"]     := AllTrim((cAliasQ)->COMPET)
        oItem["ano"]             := Val(Left((cAliasQ)->COMPET, 4))
        oItem["mes"]             := Val(SubStr((cAliasQ)->COMPET, 5, 2))
        oItem["classe"]          := AllTrim((cAliasQ)->CLASSE)
        oItem["descricaoClasse"] := AllTrim((cAliasQ)->DESCRI)
        oItem["qtdItens"]        := (cAliasQ)->QTD
        oItem["total"]           := (cAliasQ)->TOTAL
        aAdd(aItens, oItem)
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

    oResp["success"]     := .T.
    oResp["lancamentos"] := aItens

Return oResp

/*/{Protheus.doc} ZmmCarr
Carrega o lancamento de uma competencia + classe de valor (operacao
"medicaoCarregar"). Se ainda nao houver nada gravado devolve existe=.F. e a
grade vazia (a tela entra em modo inclusao).
@type Static Function
@param oReq JsonObject, {mes, ano, classe}
@return JsonObject, ver ZmmMont
/*/
//=============================================================================================================================
Static Function ZmmCarr(oReq)

    Local oResp   := JsonObject():New()
    Local cErro   := ""
    Local cComp   := ZmmComp(oReq, @cErro)
    Local cClasse := Upper(ZsmStr(oReq, "classe"))

    If Empty(cErro) .And. Empty(cClasse)
        cErro := "Projeto e obrigatorio."
    EndIf

    // Lancamento novo so com classe valida; um ja gravado abre mesmo que a classe tenha sido bloqueada depois.
    If Empty(cErro) .And. !ZmmExiste(cComp, cClasse)
        cErro := ZsmVldCls(cClasse)
    EndIf

    If !Empty(cErro)
        oResp["success"] := .F.
        oResp["message"] := cErro
        Return oResp
    EndIf

Return ZmmMont(cComp, cClasse)

/*/{Protheus.doc} ZmmMont
Monta a resposta padrao de um lancamento: itens gravados na ZMM e os servicos
que podem ser adicionados (ativos e vinculados a classe de valor na ZMC).
@type Static Function
@param cComp caractere, competencia AAAAMM
@param cClasse caractere, classe de valor (sem padding)
@param cMsg caractere, mensagem de sucesso opcional
@return JsonObject, {success, message, existe, competencia, mes, ano, classe, descricaoClasse,
        percentualRetencao, itens:[{codigo,descricao,valor,emissao}], servicos:[{codigo,descricao}]}
/*/
//=============================================================================================================================
Static Function ZmmMont(cComp, cClasse, cMsg)

    Local oResp  := JsonObject():New()
    Local aItens := ZmmGrav(cComp, cClasse)

    Default cMsg := ""

    oResp["success"]         := .T.
    oResp["existe"]          := Len(aItens) > 0
    oResp["competencia"]     := cComp
    oResp["ano"]             := Val(Left(cComp, 4))
    oResp["mes"]             := Val(SubStr(cComp, 5, 2))
    oResp["classe"]          := AllTrim(cClasse)
    oResp["descricaoClasse"] := ZmmDescVl(cClasse)
    oResp["percentualRetencao"] := ZmmPerRet(cClasse)
    oResp["itens"]           := aItens
    oResp["servicos"]        := ZmmDisp(cClasse)
    If !Empty(cMsg)
        oResp["message"] := cMsg
    EndIf

Return oResp

/*/{Protheus.doc} ZmmGrav
Itens gravados na ZMM para uma competencia + classe de valor. Toda leitura da
ZMM e por SQL e a gravacao posiciona pelo recno devolvido aqui -- nada depende
da ordem do indice 1 no dicionario (com o indice criado diferente da
especificacao, o dbSeek posicionava em outro servico e o item novo sobrescrevia
o ja gravado, 2026-10-02 -- mesmo problema de ZsmZmcRec).
@type Static Function
@param cComp caractere, competencia AAAAMM
@param cClasse caractere, classe de valor (sem padding)
@return array, [{codigo,descricao,valor,emissao (AAAAMMDD),recno}]
/*/
//=============================================================================================================================
Static Function ZmmGrav(cComp, cClasse)

    Local aItens  := {}
    Local oItem   := Nil
    Local cAliasQ := GetNextAlias()
    Local cClPad  := Padr(cClasse, TamSX3("ZMM_CLVL")[1])

    BeginSql Alias cAliasQ
        Column VALOR As Numeric(14, 2)
        SELECT ZMM.ZMM_CODSRV AS CODIGO,
               ZMM.ZMM_DESCSR AS DESCRI,
               ZMM.ZMM_VALOR AS VALOR,
               ZMM.ZMM_EMISSA AS EMISSA,
               ZMM.R_E_C_N_O_ AS REC
          FROM %table:ZMM% ZMM
         WHERE ZMM.%notDel%
           AND ZMM.ZMM_FILIAL = %xfilial:ZMM%
           AND ZMM.ZMM_COMPET = %exp:cComp%
           AND ZMM.ZMM_CLVL = %exp:cClPad%
         ORDER BY ZMM.ZMM_CODSRV
    EndSql

    While (cAliasQ)->(!Eof())
        oItem := JsonObject():New()
        oItem["codigo"]    := AllTrim((cAliasQ)->CODIGO)
        oItem["descricao"] := AllTrim((cAliasQ)->DESCRI)
        oItem["valor"]     := (cAliasQ)->VALOR
        oItem["emissao"]   := AllTrim((cAliasQ)->EMISSA)
        oItem["recno"]     := (cAliasQ)->REC
        aAdd(aItens, oItem)
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

Return aItens

/*/{Protheus.doc} ZmmDisp
Servicos que podem compor a medicao de uma classe de valor: ativos na ZMS e
vinculados a classe na ZMC.
@type Static Function
@param cClasse caractere, classe de valor (sem padding)
@return array, [{codigo,descricao}]
/*/
//=============================================================================================================================
Static Function ZmmDisp(cClasse)

    Local aItens  := {}
    Local oItem   := Nil
    Local cAliasQ := GetNextAlias()
    Local cClPad  := Padr(cClasse, TamSX3("ZMC_CLVL")[1])

    BeginSql Alias cAliasQ
        SELECT ZMS.ZMS_CODIGO AS CODIGO, ZMS.ZMS_DESCRI AS DESCRI
          FROM %table:ZMC% ZMC
          JOIN %table:ZMS% ZMS
            ON ZMS.ZMS_FILIAL = %xfilial:ZMS%
           AND ZMS.ZMS_CODIGO = ZMC.ZMC_CODSRV
           AND ZMS.ZMS_STATUS <> '2'
           AND ZMS.%notDel%
         WHERE ZMC.%notDel%
           AND ZMC.ZMC_FILIAL = %xfilial:ZMC%
           AND ZMC.ZMC_CLVL = %exp:cClPad%
         ORDER BY ZMS.ZMS_CODIGO
    EndSql

    While (cAliasQ)->(!Eof())
        oItem := JsonObject():New()
        oItem["codigo"]    := AllTrim((cAliasQ)->CODIGO)
        oItem["descricao"] := AllTrim((cAliasQ)->DESCRI)
        aAdd(aItens, oItem)
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

Return aItens

/*/{Protheus.doc} ZmmSalvar
Grava o lancamento de uma competencia + classe de valor (operacao
"medicaoSalvar") a partir da grade da tela: inclui os itens novos (ZMM_EMISSA =
data base), altera o valor dos ja gravados e exclui os que foram removidos da
grade. A competencia e a classe sao a chave do lancamento -- nunca mudam em
registro ja gravado. Todos os itens sao validados antes de gravar qualquer
registro. Sem Begin/End Transaction -- mesmo motivo de ZsmSalvar.
@type Static Function
@param oReq JsonObject, {mes, ano, classe, itens:[{codigo, valor}]}
@return JsonObject, ver ZmmMont (ou {success:.F., message})
/*/
//=============================================================================================================================
Static Function ZmmSalvar(oReq)

    Local oResp    := JsonObject():New()
    Local cErro    := ""
    Local cComp    := ZmmComp(oReq, @cErro)
    Local cClasse  := Upper(ZsmStr(oReq, "classe"))
    Local cClPad   := ""
    Local cDescVl  := ""
    Local aGrav    := {}
    Local aDisp    := {}
    Local aGravar  := {}
    Local oItem    := Nil
    Local cCodigo  := ""
    Local cCodPad  := ""
    Local nValor   := 0
    Local nIncl    := 0
    Local nAlt     := 0
    Local nExcl    := 0
    Local nI       := 0
    Local lAchou   := .F.
    Local nPos     := 0

    If Empty(cErro) .And. Empty(cClasse)
        cErro := "Projeto e obrigatorio."
    EndIf
    If Empty(cErro) .And. (ValType(oReq["itens"]) != "A" .Or. Len(oReq["itens"]) == 0)
        cErro := "Adicione ao menos um item. Para apagar o lancamento inteiro use Excluir."
    EndIf
    If Empty(cErro) .And. !ZmmExiste(cComp, cClasse)
        cErro := ZsmVldCls(cClasse)
    EndIf

    // Valida TODOS os itens antes de gravar: item novo so com servico ativo vinculado a classe;
    // item ja gravado continua valendo mesmo que o vinculo tenha sido removido depois.
    If Empty(cErro)
        aGrav := ZmmGrav(cComp, cClasse)
        aDisp := ZmmDisp(cClasse)
        For nI := 1 To Len(oReq["itens"])
            oItem := oReq["itens"][nI]
            If ValType(oItem) != "J"
                Loop
            EndIf
            cCodigo := Upper(ZsmStr(oItem, "codigo"))
            nValor  := IIf(ValType(oItem["valor"]) == "N", Round(oItem["valor"], 2), 0)
            Do Case
            Case aScan(aDisp, {|x| x["codigo"] == cCodigo}) == 0 .And. aScan(aGrav, {|x| x["codigo"] == cCodigo}) == 0
                cErro := "O servico [" + cCodigo + "] nao esta vinculado ao projeto [" + cClasse + "] ou esta inativo."
            Case nValor <= 0
                cErro := "Informe um valor maior que zero para o servico [" + cCodigo + "]."
            Case aScan(aGravar, {|x| x[1] == cCodigo}) > 0
                cErro := "O servico [" + cCodigo + "] foi informado mais de uma vez."
            EndCase
            If !Empty(cErro)
                Exit
            EndIf
            aAdd(aGravar, {cCodigo, nValor})
        Next nI
    EndIf

    If !Empty(cErro)
        oResp["success"] := .F.
        oResp["message"] := cErro
        Return oResp
    EndIf

    cClPad  := Padr(cClasse, TamSX3("ZMM_CLVL")[1])
    cDescVl := ZmmDescVl(cClasse)

    // Itens removidos da grade.
    For nI := 1 To Len(aGrav)
        If aScan(aGravar, {|x| x[1] == aGrav[nI]["codigo"]}) == 0
            ZMM->(dbGoTo(aGrav[nI]["recno"]))
            If ZMM->(!Eof()) .And. ZMM->(RecLock("ZMM", .F.))
                ZMM->(dbDelete())
                ZMM->(MsUnlock())
                nExcl++
            EndIf
        EndIf
    Next nI

    // Inclusao/alteracao.
    For nI := 1 To Len(aGravar)
        cCodigo := aGravar[nI][1]
        nValor  := aGravar[nI][2]
        cCodPad := Padr(cCodigo, TamSX3("ZMM_CODSRV")[1])
        nPos    := aScan(aGrav, {|x| x["codigo"] == cCodigo})
        lAchou  := nPos > 0
        If lAchou
            ZMM->(dbGoTo(aGrav[nPos]["recno"]))
        EndIf

        If lAchou .And. ZMM->ZMM_VALOR == nValor
            Loop
        EndIf

        If !ZMM->(RecLock("ZMM", !lAchou))
            Loop
        EndIf
            If !lAchou
                ZMM->ZMM_FILIAL := xFilial("ZMM")
                ZMM->ZMM_COMPET := cComp
                ZMM->ZMM_CLVL   := cClPad
                ZMM->ZMM_DESCVL := cDescVl
                ZMM->ZMM_CODSRV := cCodPad
                ZMM->ZMM_DESCSR := IIf(ZsmSeekSrv(cCodigo), ZMS->ZMS_DESCRI, "")
                ZMM->ZMM_EMISSA := dDataBase
            EndIf
            ZMM->ZMM_VALOR := nValor
        ZMM->(MsUnlock())
        If lAchou
            nAlt++
        Else
            nIncl++
        EndIf
    Next nI

Return ZmmMont(cComp, cClasse, "Medicao gravada: " + cValToChar(nIncl) + " item(ns) incluido(s), " + ;
    cValToChar(nAlt) + " alterado(s), " + cValToChar(nExcl) + " excluido(s).")

/*/{Protheus.doc} ZmmExcl
Exclui o lancamento inteiro de uma competencia + classe de valor (operacao
"medicaoExcluir").
@type Static Function
@param oReq JsonObject, {mes, ano, classe}
@return JsonObject, {success, message}
/*/
//=============================================================================================================================
Static Function ZmmExcl(oReq)

    Local oResp   := JsonObject():New()
    Local cErro   := ""
    Local cComp   := ZmmComp(oReq, @cErro)
    Local cClasse := Upper(ZsmStr(oReq, "classe"))
    Local aGrav   := {}
    Local nExcl   := 0
    Local nI      := 0

    If Empty(cErro) .And. !ZmmExiste(cComp, cClasse)
        cErro := "Lancamento de medicao nao encontrado."
    EndIf

    If !Empty(cErro)
        oResp["success"] := .F.
        oResp["message"] := cErro
        Return oResp
    EndIf

    aGrav := ZmmGrav(cComp, cClasse)
    For nI := 1 To Len(aGrav)
        ZMM->(dbGoTo(aGrav[nI]["recno"]))
        If ZMM->(!Eof()) .And. ZMM->(RecLock("ZMM", .F.))
            ZMM->(dbDelete())
            ZMM->(MsUnlock())
            nExcl++
        EndIf
    Next nI

    oResp["success"] := .T.
    oResp["message"] := "Lancamento excluido (" + cValToChar(nExcl) + " item(ns))."

Return oResp

/*/{Protheus.doc} ZmmCTH
Consulta de classes de valor para o lancamento de medicao (operacao
"lookupClasseMedicao") -- mesmas regras de ZsmCTH, mas so as classes que tem
ao menos um servico ativo vinculado (ZMC).
@type Static Function
@param oReq JsonObject, {filtro}
@return JsonObject, {success, items:[{codigo,descricao}], hasNext}
/*/
//=============================================================================================================================
Static Function ZmmCTH(oReq)

    Local oResp   := JsonObject():New()
    Local aItens  := {}
    Local oItem   := Nil
    Local cAliasQ := GetNextAlias()
    Local cLike   := "%'%" + Upper(ZsmStr(oReq, "filtro")) + "%'%"
    Local nCount  := 0

    BeginSql Alias cAliasQ
        SELECT CTH_CLVL AS CODIGO, CTH_DESC01 AS DESCRI
          FROM %table:CTH% CTH
         WHERE CTH.%notDel%
           AND CTH.CTH_FILIAL = %xfilial:CTH%
           AND CTH.CTH_CLASSE = '2'
           AND CTH.CTH_BLOQ <> '1'
           AND (CTH.CTH_CLVL LIKE %exp:cLike% OR UPPER(CTH.CTH_DESC01) LIKE %exp:cLike%)
           AND EXISTS (SELECT 1
                         FROM %table:ZMC% ZMC
                         JOIN %table:ZMS% ZMS
                           ON ZMS.ZMS_FILIAL = %xfilial:ZMS%
                          AND ZMS.ZMS_CODIGO = ZMC.ZMC_CODSRV
                          AND ZMS.ZMS_STATUS <> '2'
                          AND ZMS.%notDel%
                        WHERE ZMC.%notDel%
                          AND ZMC.ZMC_FILIAL = %xfilial:ZMC%
                          AND ZMC.ZMC_CLVL = CTH.CTH_CLVL)
         ORDER BY CTH.CTH_CLVL
    EndSql

    While (cAliasQ)->(!Eof()) .And. nCount < 20
        oItem := JsonObject():New()
        oItem["codigo"]    := AllTrim((cAliasQ)->CODIGO)
        oItem["descricao"] := AllTrim((cAliasQ)->DESCRI)
        aAdd(aItens, oItem)
        nCount++
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

    oResp["success"] := .T.
    oResp["items"]   := aItens
    oResp["hasNext"] := .F.

Return oResp

/*/{Protheus.doc} ZmmComp
Monta a competencia AAAAMM (ZMM_COMPET) a partir de {mes, ano} da requisicao
(numero ou texto). Em caso de erro preenche cErro (por referencia).
@type Static Function
@param oReq JsonObject, {mes, ano}
@param cErro caractere, mensagem de erro (referencia)
@return caractere, competencia AAAAMM ("" se invalida)
/*/
//=============================================================================================================================
Static Function ZmmComp(oReq, cErro)

    Local nMes := IIf(ValType(oReq["mes"]) == "N", oReq["mes"], Val(ZsmStr(oReq, "mes")))
    Local nAno := IIf(ValType(oReq["ano"]) == "N", oReq["ano"], Val(ZsmStr(oReq, "ano")))

    If nMes < 1 .Or. nMes > 12
        cErro := "Mes de competencia invalido."
        Return ""
    EndIf

    If nAno < 2000 .Or. nAno > 2100
        cErro := "Ano de competencia invalido."
        Return ""
    EndIf

Return StrZero(nAno, 4) + StrZero(nMes, 2)

/*/{Protheus.doc} ZmmDescVl
Descricao da classe de valor (CTH_DESC01), "" se nao encontrada.
@type Static Function
@param cClasse caractere, classe de valor (sem padding)
@return caractere
/*/
//=============================================================================================================================
Static Function ZmmDescVl(cClasse)

    CTH->(dbSetOrder(1)) // CTH_FILIAL+CTH_CLVL
    If CTH->(dbSeek(xFilial("CTH") + Padr(cClasse, TamSX3("CTH_CLVL")[1])))
        Return AllTrim(CTH->CTH_DESC01)
    EndIf

Return ""

/*/{Protheus.doc} ZmmPerRet
Percentual de retencao da classe de valor (CTH_XRET -- soma das taxas). A tela
calcula total bruto, valor retido e total liquido a partir dele. Devolve 0 se a
classe nao existir ou se o campo ainda nao foi criado neste ambiente.
@type Static Function
@param cClasse caractere, classe de valor (sem padding)
@return numerico, percentual (ex.: 11.33 = 11,33%)
/*/
//=============================================================================================================================
Static Function ZmmPerRet(cClasse)

    If CTH->(FieldPos("CTH_XRET")) == 0
        Return 0
    EndIf

    CTH->(dbSetOrder(1)) // CTH_FILIAL+CTH_CLVL
    If CTH->(dbSeek(xFilial("CTH") + Padr(cClasse, TamSX3("CTH_CLVL")[1])))
        Return CTH->CTH_XRET
    EndIf

Return 0

/*/{Protheus.doc} ZmmExiste
Indica se ja ha algum item gravado na ZMM para a competencia + classe.
@type Static Function
@param cComp caractere, competencia AAAAMM
@param cClasse caractere, classe de valor (sem padding)
@return logico
/*/
//=============================================================================================================================
Static Function ZmmExiste(cComp, cClasse)

    Local cAliasQ := GetNextAlias()
    Local cClPad  := Padr(cClasse, TamSX3("ZMM_CLVL")[1])
    Local lExiste := .F.

    BeginSql Alias cAliasQ
        SELECT COUNT(*) AS QTD
          FROM %table:ZMM% ZMM
         WHERE ZMM.%notDel%
           AND ZMM.ZMM_FILIAL = %xfilial:ZMM%
           AND ZMM.ZMM_COMPET = %exp:cComp%
           AND ZMM.ZMM_CLVL = %exp:cClPad%
    EndSql
    lExiste := (cAliasQ)->(!Eof()) .And. (cAliasQ)->QTD > 0
    (cAliasQ)->(DbCloseArea())

Return lExiste

/*/{Protheus.doc} ZmmUsaSrv
Indica se o servico tem algum lancamento de medicao (usada por ZsmExcl).
@type Static Function
@param cCodPad caractere, codigo do servico (com padding de ZMS_CODIGO)
@return logico
/*/
//=============================================================================================================================
Static Function ZmmUsaSrv(cCodPad)

    Local cAliasQ := GetNextAlias()
    Local lUsa    := .F.

    BeginSql Alias cAliasQ
        SELECT COUNT(*) AS QTD
          FROM %table:ZMM% ZMM
         WHERE ZMM.%notDel%
           AND ZMM.ZMM_FILIAL = %xfilial:ZMM%
           AND ZMM.ZMM_CODSRV = %exp:cCodPad%
    EndSql
    lUsa := (cAliasQ)->(!Eof()) .And. (cAliasQ)->QTD > 0
    (cAliasQ)->(DbCloseArea())

Return lUsa

/*/{Protheus.doc} ZsmSeekSrv
Posiciona a ZMS no servico informado (indice 1, filial corrente).
@type Static Function
@param cCodigo caractere, codigo do servico (sem padding)
@return logico, .T. se encontrou
/*/
//=============================================================================================================================
Static Function ZsmSeekSrv(cCodigo)

    If Empty(cCodigo)
        Return .F.
    EndIf

    ZMS->(dbSetOrder(1)) // ZMS_FILIAL+ZMS_CODIGO

Return ZMS->(dbSeek(xFilial("ZMS") + Padr(AllTrim(cCodigo), TamSX3("ZMS_CODIGO")[1])))

/*/{Protheus.doc} ZsmStr
Le uma propriedade caractere do JSON de requisicao (trim), "" se ausente.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsmStr(oReq, cChave)

    If ValType(oReq[cChave]) == "C"
        Return AllTrim(oReq[cChave])
    EndIf

Return ""
