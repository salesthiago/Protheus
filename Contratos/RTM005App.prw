#INCLUDE "TOTVS.CH"
#INCLUDE "PROTHEUS.CH"

/*/{Protheus.doc} RTM005App
Abre a tela hibrida (Angular/PO-UI) de Cadastro de Taxas (rtm005), empacotada em
resource/rtm005.app e carregada via FWCallApp -- mesmo mecanismo de canal de
RTM003App.prw/RTM004App.prw (mesma pasta). Rotina separada no menu (U_RTM005App).

Cadastro mantido por esta rotina:
  ZMT - Taxa por competencia + projeto (classe de valor/CTH). Na inclusao a tela
        permite gerar a mesma taxa para 12 competencias a partir da informada
        (ex.: 10/2026 gera 10/2026 a 09/2027); na exclusao, permite excluir as
        12 competencias a partir da escolhida, do mesmo projeto.

Dicionario (criar no Configurador antes de usar -- sem a tabela/campo a tela so
devolve a mensagem de ZmtTabOk):

  ZMT - Taxas (modo de acesso igual ao do CN9)
    ZMT_FILIAL  C  (tamanho da filial)
    ZMT_COMP    C  6   Competencia      (obrigatorio) AAAAMM, picture @R 9999/99
    ZMT_CLVL    C  9   Classe Valor     (obrigatorio, mesmo tamanho de CTH_CLVL, F3 CTH)
    ZMT_TIPO    C  1   Tipo Taxa        (obrigatorio) 1=Valor Fixo;2=Percentual  -- CAMPO NOVO
    ZMT_VALOR   N  14,2 Valor Taxa      (obrigatorio) valor em R$ (tipo 1) ou % (tipo 2)
    ZMT_DESC    C  60  Descricao        (obrigatorio) descricao da taxa             -- CAMPO NOVO
    ZMT_USER    C  25  Usuario          usuario que incluiu o registro (cUserName)
    ZMT_DATA    D  8   Data inclui      data da inclusao do registro (Date())
    Indice 1: ZMT_FILIAL+ZMT_COMP
    Indice 2: ZMT_FILIAL+ZMT_COMP+ZMT_CLVL   (chave unica)

Toda leitura da ZMT e por SQL e a gravacao posiciona pelo recno -- nada depende
da ordem dos indices no dicionario (mesmo cuidado de ZmmGrav/ZsmZmcRec no RTM004App).

@type User Function
@author Thiago Sales - Quebec Ambiental
@since 2026-10-07
/*/
//=============================================================================================================================
USER FUNCTION RTM005App()

    FWCallApp("rtm005")

RETURN

/*/{Protheus.doc} JsToAdvpl
Recebe mensagens da tela Angular (rtm005) pelo canal AdvplToJs/JsToAdvpl
(TWebEngine/TWebChannel) -- mesmo padrao de Contratos/RTM004App.prw.
Qualquer erro de execucao dentro da operacao vira {success:.F., message} em vez
de derrubar a thread -- sem resposta o Angular fica esperando para sempre.
@type Function
@author Thiago Sales - Quebec Ambiental
@since 2026-10-07
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

    If cType == "projetoListar"
        oResp := ZmtCTH(oReq)
    ElseIf ZmtTabOk(oResp)
        Do Case
        Case cType == "taxaListar"
            oResp := ZmtList(oReq)
        Case cType == "taxaDetalhe"
            oResp := ZmtDet(oReq)
        Case cType == "taxaSalvar"
            oResp := ZmtSalvar(oReq)
        Case cType == "taxaExcluir"
            oResp := ZmtExcl(oReq)
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

/*/{Protheus.doc} ZmtTabOk
Confere se a ZMT (com os campos novos ZMT_TIPO e ZMT_DESC) ja existe no dicionario deste
ambiente. Se nao existir, preenche oResp com a mensagem de erro.
@type Static Function
@param oResp JsonObject, resposta a preencher em caso de falha
@return logico, .T. se a tabela e o campo existem
/*/
//=============================================================================================================================
Static Function ZmtTabOk(oResp)

    If !AliasInDic("ZMT")
        oResp["success"] := .F.
        oResp["message"] := "Tabela ZMT (Taxas) nao encontrada no dicionario deste ambiente."
        Return .F.
    EndIf

    If ZMT->(FieldPos("ZMT_TIPO")) == 0
        oResp["success"] := .F.
        oResp["message"] := "Campo ZMT_TIPO (1=Valor Fixo;2=Percentual) nao encontrado na tabela ZMT. Crie o campo no Configurador."
        Return .F.
    EndIf

    If ZMT->(FieldPos("ZMT_DESC")) == 0
        oResp["success"] := .F.
        oResp["message"] := "Campo ZMT_DESC (Descricao da taxa) nao encontrado na tabela ZMT. Crie o campo no Configurador."
        Return .F.
    EndIf

Return .T.

/*/{Protheus.doc} ZmtList
Lista as taxas da filial (operacao "taxaListar"), com a descricao do projeto
(CTH). Filtros sao aplicados na tela (mesmo padrao do RTM004App).
@type Static Function
@param oReq JsonObject, {} (sem parametros)
@return JsonObject, {success, taxas:[ver ZmtJson]}
/*/
//=============================================================================================================================
Static Function ZmtList(oReq)

    Local oResp   := JsonObject():New()
    Local aItens  := {}
    Local cAliasQ := GetNextAlias()

    BeginSql Alias cAliasQ
        Column VALOR As Numeric(16, 4)
        SELECT ZMT.ZMT_COMP AS COMP,
               ZMT.ZMT_CLVL AS CLASSE,
               COALESCE(CTH.CTH_DESC01, ' ') AS DESCRI,
               ZMT.ZMT_TIPO AS TIPO,
               ZMT.ZMT_VALOR AS VALOR,
               ZMT.ZMT_DESC AS DESCTAXA,
               ZMT.ZMT_USER AS USUARIO,
               ZMT.ZMT_DATA AS DATAINC
          FROM %table:ZMT% ZMT
          LEFT JOIN %table:CTH% CTH
            ON CTH.CTH_FILIAL = %xfilial:CTH%
           AND CTH.CTH_CLVL = ZMT.ZMT_CLVL
           AND CTH.%notDel%
         WHERE ZMT.%notDel%
           AND ZMT.ZMT_FILIAL = %xfilial:ZMT%
         ORDER BY ZMT.ZMT_COMP DESC, ZMT.ZMT_CLVL
    EndSql

    While (cAliasQ)->(!Eof())
        aAdd(aItens, ZmtJson((cAliasQ)->COMP, (cAliasQ)->CLASSE, (cAliasQ)->DESCRI, (cAliasQ)->TIPO, ;
            (cAliasQ)->VALOR, (cAliasQ)->DESCTAXA, (cAliasQ)->USUARIO, (cAliasQ)->DATAINC))
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

    oResp["success"] := .T.
    oResp["taxas"]   := aItens

Return oResp

/*/{Protheus.doc} ZmtDet
Detalhe de uma taxa (operacao "taxaDetalhe").
@type Static Function
@param oReq JsonObject, {mes, ano, classe}
@return JsonObject, {success, taxa:[ver ZmtJson]}
/*/
//=============================================================================================================================
Static Function ZmtDet(oReq)

    Local oResp   := JsonObject():New()
    Local cErro   := ""
    Local cComp   := ZmtComp(oReq, @cErro)
    Local cClasse := Upper(ZmtStr(oReq, "classe"))
    Local nRec    := 0

    If Empty(cErro)
        nRec := ZmtRec(cComp, cClasse)
        If nRec == 0
            cErro := "Taxa do projeto [" + cClasse + "] na competencia " + ZmtCompFmt(cComp) + " nao encontrada."
        EndIf
    EndIf

    If !Empty(cErro)
        oResp["success"] := .F.
        oResp["message"] := cErro
        Return oResp
    EndIf

    ZMT->(dbGoTo(nRec))

    oResp["success"] := .T.
    oResp["taxa"]    := ZmtJson(ZMT->ZMT_COMP, ZMT->ZMT_CLVL, ZmtDescVl(cClasse), ZMT->ZMT_TIPO, ;
        ZMT->ZMT_VALOR, ZMT->ZMT_DESC, ZMT->ZMT_USER, DToS(ZMT->ZMT_DATA))

Return oResp

/*/{Protheus.doc} ZmtSalvar
Inclui ou altera uma taxa (operacao "taxaSalvar").
Inclusao: com gerar12Meses grava a mesma taxa nas 12 competencias a partir de
mes/ano (ex.: 10/2026 a 09/2027). Todas as competencias sao conferidas ANTES de
gravar: se alguma ja tiver taxa para o projeto, nada e gravado e a mensagem
lista as competencias em conflito. ZMT_USER/ZMT_DATA = usuario e data da inclusao.
Alteracao: projeto e competencia (chave) nao mudam -- so tipo, valor e descricao; usuario e
data da inclusao sao mantidos.
Sem Begin/End Transaction -- mesmo motivo de ZsmSalvar no RTM004App (dentro do
FWCallApp a transacao ficava aberta sem commit).
@type Static Function
@param oReq JsonObject, {inclusao, mes, ano, classe, tipo, valor, descricao, gerar12Meses}
@return JsonObject, {success, message}
/*/
//=============================================================================================================================
Static Function ZmtSalvar(oReq)

    Local oResp     := JsonObject():New()
    Local lInclusao := ValType(oReq["inclusao"]) == "L" .And. oReq["inclusao"]
    Local lGerar12  := lInclusao .And. ValType(oReq["gerar12Meses"]) == "L" .And. oReq["gerar12Meses"]
    Local cErro     := ""
    Local cComp     := ZmtComp(oReq, @cErro)
    Local cClasse   := Upper(ZmtStr(oReq, "classe"))
    Local cTipo     := ZmtStr(oReq, "tipo")
    Local nValor    := IIf(ValType(oReq["valor"]) == "N", Round(oReq["valor"], 2), 0)
    Local cDesc     := Left(ZmtStr(oReq, "descricao"), TamSX3("ZMT_DESC")[1])
    Local aComps    := {}
    Local cExist    := ""
    Local cClPad    := ""
    Local cUser     := ""
    Local nRec      := 0
    Local nI        := 0

    Do Case
    Case !Empty(cErro)
    Case Empty(cClasse)
        cErro := "Projeto (classe de valor) e obrigatorio."
    Case Empty(cDesc)
        cErro := "Descricao da taxa e obrigatoria."
    Case !(cTipo == "1" .Or. cTipo == "2")
        cErro := "Tipo da taxa invalido (1=Valor Fixo, 2=Percentual)."
    Case nValor <= 0
        cErro := "Informe um valor maior que zero."
    Case cTipo == "2" .And. nValor > 100
        cErro := "O percentual nao pode ser maior que 100%."
    EndCase

    If !Empty(cErro)
        oResp["success"] := .F.
        oResp["message"] := cErro
        Return oResp
    EndIf

    // ---------- Alteracao: so tipo, valor e descricao ----------
    If !lInclusao
        nRec := ZmtRec(cComp, cClasse)
        If nRec == 0
            oResp["success"] := .F.
            oResp["message"] := "Taxa do projeto [" + cClasse + "] na competencia " + ZmtCompFmt(cComp) + " nao encontrada."
            Return oResp
        EndIf

        ZMT->(dbGoTo(nRec))
        If !ZMT->(RecLock("ZMT", .F.))
            oResp["success"] := .F.
            oResp["message"] := "Taxa em uso por outro usuario. Tente novamente."
            Return oResp
        EndIf
            ZMT->ZMT_TIPO  := cTipo
            ZMT->ZMT_VALOR := nValor
            ZMT->ZMT_DESC  := cDesc
        ZMT->(MsUnlock())

        oResp["success"] := .T.
        oResp["message"] := "Taxa de " + ZmtCompFmt(cComp) + " alterada com sucesso."
        Return oResp
    EndIf

    // ---------- Inclusao (1 ou 12 competencias) ----------
    cErro := ZmtVldCls(cClasse)
    If !Empty(cErro)
        oResp["success"] := .F.
        oResp["message"] := cErro
        Return oResp
    EndIf

    For nI := 0 To IIf(lGerar12, 11, 0)
        aAdd(aComps, ZmtSomaMes(cComp, nI))
    Next nI

    // Confere TODAS antes de gravar qualquer registro.
    For nI := 1 To Len(aComps)
        If ZmtRec(aComps[nI], cClasse) > 0
            cExist += IIf(Empty(cExist), "", ", ") + ZmtCompFmt(aComps[nI])
        EndIf
    Next nI

    If !Empty(cExist)
        oResp["success"] := .F.
        oResp["message"] := "O projeto [" + cClasse + "] ja possui taxa na(s) competencia(s): " + cExist + ;
            ". Nada foi gravado. Altere ou exclua as existentes antes de incluir."
        Return oResp
    EndIf

    cClPad := Padr(cClasse, TamSX3("ZMT_CLVL")[1])
    cUser  := Left(AllTrim(cUserName), TamSX3("ZMT_USER")[1])

    For nI := 1 To Len(aComps)
        RecLock("ZMT", .T.)
            ZMT->ZMT_FILIAL := xFilial("ZMT")
            ZMT->ZMT_COMP   := aComps[nI]
            ZMT->ZMT_CLVL   := cClPad
            ZMT->ZMT_TIPO   := cTipo
            ZMT->ZMT_VALOR  := nValor
            ZMT->ZMT_DESC   := cDesc
            ZMT->ZMT_USER   := cUser
            ZMT->ZMT_DATA   := Date()
        ZMT->(MsUnlock())
    Next nI

    oResp["success"] := .T.
    If Len(aComps) > 1
        oResp["message"] := cValToChar(Len(aComps)) + " taxas incluidas para o projeto " + cClasse + ;
            " (" + ZmtCompFmt(aComps[1]) + " a " + ZmtCompFmt(aComps[Len(aComps)]) + ")."
    Else
        oResp["message"] := "Taxa de " + ZmtCompFmt(cComp) + " incluida para o projeto " + cClasse + "."
    EndIf

Return oResp

/*/{Protheus.doc} ZmtExcl
Exclui a taxa de uma competencia + projeto (operacao "taxaExcluir"). Com
excluir12Meses exclui tambem as competencias seguintes do mesmo projeto -- as 12
a partir da informada (as que nao existirem sao ignoradas).
@type Static Function
@param oReq JsonObject, {mes, ano, classe, excluir12Meses}
@return JsonObject, {success, message}
/*/
//=============================================================================================================================
Static Function ZmtExcl(oReq)

    Local oResp    := JsonObject():New()
    Local lExcl12  := ValType(oReq["excluir12Meses"]) == "L" .And. oReq["excluir12Meses"]
    Local cErro    := ""
    Local cComp    := ZmtComp(oReq, @cErro)
    Local cClasse  := Upper(ZmtStr(oReq, "classe"))
    Local cCompAt  := ""
    Local nRec     := 0
    Local nExcl    := 0
    Local nFalha   := 0
    Local nI       := 0

    If Empty(cErro) .And. ZmtRec(cComp, cClasse) == 0
        cErro := "Taxa do projeto [" + cClasse + "] na competencia " + ZmtCompFmt(cComp) + " nao encontrada."
    EndIf

    If !Empty(cErro)
        oResp["success"] := .F.
        oResp["message"] := cErro
        Return oResp
    EndIf

    For nI := 0 To IIf(lExcl12, 11, 0)
        cCompAt := ZmtSomaMes(cComp, nI)
        nRec    := ZmtRec(cCompAt, cClasse)
        If nRec == 0
            Loop
        EndIf
        ZMT->(dbGoTo(nRec))
        If ZMT->(!Eof()) .And. ZMT->(RecLock("ZMT", .F.))
            ZMT->(dbDelete())
            ZMT->(MsUnlock())
            nExcl++
        Else
            nFalha++
        EndIf
    Next nI

    oResp["success"] := .T.
    If lExcl12
        oResp["message"] := cValToChar(nExcl) + " taxa(s) excluida(s) do projeto " + cClasse + ;
            " (" + ZmtCompFmt(cComp) + " a " + ZmtCompFmt(ZmtSomaMes(cComp, 11)) + ")." + ;
            IIf(nFalha > 0, " " + cValToChar(nFalha) + " em uso por outro usuario nao foram excluidas.", "")
    Else
        oResp["message"] := IIf(nExcl > 0, "Taxa de " + ZmtCompFmt(cComp) + " excluida com sucesso.", ;
            "Taxa em uso por outro usuario. Tente novamente.")
        oResp["success"] := nExcl > 0
    EndIf

Return oResp

/*/{Protheus.doc} ZmtCTH
Lista completa de projetos (classes de valor analiticas e nao bloqueadas) para o
select da tela (operacao "projetoListar").
@type Static Function
@param oReq JsonObject, {} (sem parametros)
@return JsonObject, {success, items:[{codigo,descricao}]}
/*/
//=============================================================================================================================
Static Function ZmtCTH(oReq)

    Local oResp   := JsonObject():New()
    Local aItens  := {}
    Local oItem   := Nil
    Local cAliasQ := GetNextAlias()

    BeginSql Alias cAliasQ
        SELECT CTH_CLVL AS CODIGO, CTH_DESC01 AS DESCRI
          FROM %table:CTH% CTH
         WHERE CTH.%notDel%
           AND CTH.CTH_FILIAL = %xfilial:CTH%
           AND CTH.CTH_CLASSE = '2'
           AND CTH.CTH_BLOQ <> '1'
         ORDER BY CTH.CTH_CLVL
    EndSql

    While (cAliasQ)->(!Eof())
        oItem := JsonObject():New()
        oItem["codigo"]    := AllTrim((cAliasQ)->CODIGO)
        oItem["descricao"] := AllTrim((cAliasQ)->DESCRI)
        aAdd(aItens, oItem)
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

    oResp["success"] := .T.
    oResp["items"]   := aItens

Return oResp

/*/{Protheus.doc} ZmtJson
Monta o JSON de uma taxa (formato de TaxaResumo em rtm005/models/taxa.model.ts).
@type Static Function
@return JsonObject, {competencia,mes,ano,classe,descricaoClasse,tipo,valor,descricao,usuario,data}
/*/
//=============================================================================================================================
Static Function ZmtJson(cComp, cClasse, cDescri, cTipo, nValor, cDescTx, cUser, cData)

    Local oItem := JsonObject():New()

    oItem["competencia"]     := AllTrim(cComp)
    oItem["ano"]             := Val(Left(cComp, 4))
    oItem["mes"]             := Val(SubStr(cComp, 5, 2))
    oItem["classe"]          := AllTrim(cClasse)
    oItem["descricaoClasse"] := AllTrim(cDescri)
    oItem["tipo"]            := IIf(AllTrim(cTipo) == "1", "1", "2")
    oItem["valor"]           := nValor
    oItem["descricao"]       := AllTrim(cDescTx)
    oItem["usuario"]         := AllTrim(cUser)
    oItem["data"]            := AllTrim(cData)

Return oItem

/*/{Protheus.doc} ZmtRec
Localiza a taxa de uma competencia + projeto por SQL (chave do indice 2).
@type Static Function
@param cComp caractere, competencia AAAAMM
@param cClasse caractere, classe de valor (sem padding)
@return numerico, R_E_C_N_O_ ou 0 se nao existe
/*/
//=============================================================================================================================
Static Function ZmtRec(cComp, cClasse)

    Local cAliasQ := GetNextAlias()
    Local cCmPad  := Padr(cComp, TamSX3("ZMT_COMP")[1])
    Local cClPad  := Padr(cClasse, TamSX3("ZMT_CLVL")[1])
    Local nRec    := 0

    BeginSql Alias cAliasQ
        SELECT MIN(ZMT.R_E_C_N_O_) AS REC
          FROM %table:ZMT% ZMT
         WHERE ZMT.%notDel%
           AND ZMT.ZMT_FILIAL = %xfilial:ZMT%
           AND ZMT.ZMT_COMP = %exp:cCmPad%
           AND ZMT.ZMT_CLVL = %exp:cClPad%
    EndSql
    If (cAliasQ)->(!Eof()) .And. ValType((cAliasQ)->REC) == "N"
        nRec := (cAliasQ)->REC
    EndIf
    (cAliasQ)->(DbCloseArea())

Return nRec

/*/{Protheus.doc} ZmtVldCls
Valida o projeto (classe de valor) para inclusao: existe no CTH, e analitica e
nao esta bloqueada -- mesmas regras de ZsmVldCls no RTM004App.
@type Static Function
@param cClasse caractere, codigo da classe de valor
@return caractere, mensagem de erro ou "" se valida
/*/
//=============================================================================================================================
Static Function ZmtVldCls(cClasse)

    CTH->(dbSetOrder(1)) // CTH_FILIAL+CTH_CLVL
    If !CTH->(dbSeek(xFilial("CTH") + Padr(cClasse, TamSX3("CTH_CLVL")[1])))
        Return "Projeto (classe de valor) [" + cClasse + "] nao encontrado."
    EndIf

    If AllTrim(CTH->CTH_BLOQ) == "1"
        Return "Projeto (classe de valor) [" + cClasse + "] esta bloqueado."
    EndIf

    If AllTrim(CTH->CTH_CLASSE) == "1"
        Return "Projeto (classe de valor) [" + cClasse + "] e sintetico. Informe uma classe analitica."
    EndIf

Return ""

/*/{Protheus.doc} ZmtDescVl
Descricao da classe de valor (CTH_DESC01), "" se nao encontrada.
@type Static Function
@param cClasse caractere, classe de valor (sem padding)
@return caractere
/*/
//=============================================================================================================================
Static Function ZmtDescVl(cClasse)

    CTH->(dbSetOrder(1)) // CTH_FILIAL+CTH_CLVL
    If CTH->(dbSeek(xFilial("CTH") + Padr(cClasse, TamSX3("CTH_CLVL")[1])))
        Return AllTrim(CTH->CTH_DESC01)
    EndIf

Return ""

/*/{Protheus.doc} ZmtComp
Monta a competencia AAAAMM (ZMT_COMP) a partir de {mes, ano} da requisicao
(numero ou texto). Em caso de erro preenche cErro (por referencia).
@type Static Function
@param oReq JsonObject, {mes, ano}
@param cErro caractere, mensagem de erro (referencia)
@return caractere, competencia AAAAMM ("" se invalida)
/*/
//=============================================================================================================================
Static Function ZmtComp(oReq, cErro)

    Local nMes := IIf(ValType(oReq["mes"]) == "N", oReq["mes"], Val(ZmtStr(oReq, "mes")))
    Local nAno := IIf(ValType(oReq["ano"]) == "N", oReq["ano"], Val(ZmtStr(oReq, "ano")))

    If nMes < 1 .Or. nMes > 12
        cErro := "Mes de competencia invalido."
        Return ""
    EndIf

    If nAno < 2000 .Or. nAno > 2100
        cErro := "Ano de competencia invalido."
        Return ""
    EndIf

Return StrZero(nAno, 4) + StrZero(nMes, 2)

/*/{Protheus.doc} ZmtSomaMes
Soma n meses a uma competencia AAAAMM (vira o ano quando passa de dezembro).
@type Static Function
@param cComp caractere, competencia AAAAMM
@param nMeses numerico, meses a somar (0 = a propria competencia)
@return caractere, competencia AAAAMM
/*/
//=============================================================================================================================
Static Function ZmtSomaMes(cComp, nMeses)

    Local nTotal := Val(Left(cComp, 4)) * 12 + Val(SubStr(cComp, 5, 2)) - 1 + nMeses

Return StrZero(Int(nTotal / 12), 4) + StrZero(Mod(nTotal, 12) + 1, 2)

/*/{Protheus.doc} ZmtCompFmt
Competencia AAAAMM formatada como MM/AAAA para mensagens.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZmtCompFmt(cComp)

Return SubStr(cComp, 5, 2) + "/" + Left(cComp, 4)

/*/{Protheus.doc} ZmtStr
Le uma propriedade caractere do JSON de requisicao (trim), "" se ausente.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZmtStr(oReq, cChave)

    If ValType(oReq[cChave]) == "C"
        Return AllTrim(oReq[cChave])
    EndIf

Return ""
