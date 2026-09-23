#INCLUDE "TOTVS.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"

/*/{Protheus.doc} RTM003App
Abre a tela hibrida (Angular/PO-UI) de Contratos (rtm003) -- inclusao,
mudanca de situacao e revisoes do CNTA300/CNTA301, empacotada em
resource/rtm003.app e carregada via FWCallApp. Programa separado de
RTM002App.prw (mesma pasta, mesmo mecanismo de canal) -- rtm003 nao lida com
cronograma/medicao (CND/CNE/CNTA121), so com CN9/CNC/CNA/CNB.
@type User Function
@author Thiago Sales - Quebec Ambiental
@since 2026-08-10
/*/
//=============================================================================================================================
USER FUNCTION RTM003App()

    FWCallApp("rtm003")

RETURN

/*/{Protheus.doc} JsToAdvpl
Recebe mensagens da tela Angular (rtm003) pelo canal AdvplToJs/JsToAdvpl
(TWebEngine/TWebChannel) -- mesmo padrao de Contratos/RTM002App.prw e
Controle de Contratos/src/AprovCT.prw.
@type Function
@author Thiago Sales - Quebec Ambiental
@since 2026-08-10
/*/
//=============================================================================================================================
Static Function JsToAdvpl(oWebChannel, cType, cContent)

    Local oReq       := JsonObject():New()
    Local oResp      := JsonObject():New()
    Local cReceiveId := ""

    oReq:fromJson(cContent)
    cReceiveId := oReq["receiveId"]

    Do Case
    Case cType == "contratoListar"
        oResp := ZcnList(oReq)
    Case cType == "contratoDetalhe"
        oResp := ZcnDet(oReq)
    Case cType == "contratoCriar"
        oResp := ZcnCriar(oReq)
    Case cType == "contratoAtualizar"
        oResp := ZcnAtu(oReq)
    Case cType == "contratoSituacao"
        oResp := ZcnSit(oReq)
    Case cType == "contratoTimeline"
        oResp := ZcnTL(oReq)
    Case cType == "revisaoAbrir"
        oResp := ZcnRevAb(oReq)
    Case cType == "revisaoAprovar"
        oResp := ZcnAprov(oReq)
    Case cType == "lookupPessoa"
        oResp := ZcnPess(oReq)
    Case cType == "lookupTipoContrato"
        oResp := ZcnTpCt(oReq)
    Case cType == "lookupProduto"
        oResp := ZcnProd(oReq)
    Case cType == "lookupCondPagto"
        oResp := ZcnCndPg(oReq)
    Case cType == "lookupNatureza"
        oResp := ZcnNat(oReq)
    Case cType == "lookupTipoPlanilha"
        oResp := ZcnTpPla(oReq)
    Case cType == "lookupTES"
        oResp := ZcnTes(oReq)
    Case cType == "lookupCentroCusto"
        oResp := ZcnCCus(oReq)
    Case cType == "lookupMoeda"
        oResp := ZcnMoeda(oReq)
    Case cType == "lookupIndice"
        oResp := ZcnIndice(oReq)
    Case cType == "dominiosPlanilha"
        oResp := ZcnDomPla(oReq)
    Case cType == "lookupFilial"
        oResp := ZcnFilial(oReq)
    Case cType == "lookupProximoNumero"
        oResp := ZcnProxNum(oReq)
    Case cType == "gerarCronograma"
        oResp := ZcnGrCrg(oReq)
    OtherWise
        oResp["success"] := .F.
        oResp["message"] := "Operacao nao reconhecida: " + cType
    EndCase

    If !Empty(cReceiveId)
        oWebChannel:AdvplToJs(cReceiveId, oResp:toJson())
    EndIf

Return .T.

/*/{Protheus.doc} ZcnList
Lista contratos (operacao "contratoListar") -- so a revisao corrente de cada
contrato (CN9_REVISA = CN9_REVATU, mesmo campo usado em rtm002/GeraArq para
identificar a revisao vigente). Nome do cliente/fornecedor resolvido por
CNC->(dbSeek()) + ZcnNome -- NAO por JOIN SQL direto: a 1a versao desta
funcao tentava um JOIN usando campos "CNC_CONTRA"/"CNC_REVISA" inventados por
analogia com CNA_CONTRA (que existe de fato, confirmado no GCT0109), mas o
GCT0109 nunca usa esses nomes para CNC especificamente (o oModel resolve a
ligacao via relacao de submodelo, sem precisar de nomes explicitos) -- deu
erro real em producao ("nao existe a coluna cnc.cnc_contra"). dbSeek via
indice (mesma tecnica de ZcnMont) evita essa classe de erro porque nao
depende de eu acertar o nome do campo de ligacao, so a ordem 1 do CNC (que
deve ser FILIAL+CONTRA+REVISA, ainda assim uma suposicao, mas com falha
segura: se a ordem for outra coisa, so retorna pessoaNome vazio, sem quebrar
a tela).
Filtro por tipo ('C'/'V') e situacao e aplicado em memoria (lista pequena o
suficiente nesta fase; se crescer, mover para o WHERE). Filtro por numero (LIKE parcial),
filial (igualdade) e intervalo de data de inicio ja vao para o WHERE (mesmo idioma de LIKE ja
usado em ZcnPess/ZcnTpCt: cFiltNum vazio produz um padrao que ainda casa com tudo, entao a
clausula fica sempre presente na query, sem precisar de BeginSql condicional -- mesma logica
pro intervalo de data, que cai para 01/01/1900..31/12/2099 quando nao informado).
Filtro de filial: quando nao informado, mantem o comportamento anterior (so a filial corrente
da sessao) -- quando informado, permite consultar OUTRA filial sem precisar re-logar (1a parte
do pedido de listagem multi-filial; a parte de listar AUTOMATICAMENTE todas as filiais
permitidas ao usuario, sem filtro explicito, ainda depende de decisao de negocio/pendente).
@type Static Function
@param oReq JsonObject, {tipo, situacao, numero, filial, dataInicioDe, dataInicioAte} (todos opcionais)
@return JsonObject, {success, contratos:[{numero,revisao,tipo,filial,pessoaNome,situacao,situacaoDescricao,vigencia,unidadeVigencia}]}
/*/
//=============================================================================================================================
Static Function ZcnList(oReq)

    Local oResp      := JsonObject():New()
    Local aContratos := {}
    Local oContrato  := Nil
    Local cAliasQ    := GetNextAlias()
    Local cFiltTipo  := ""
    Local cFiltSit   := ""
    Local cTipo      := ""
    Local cCodigo    := ""
    Local cLoja      := ""
    Local nTamNum    := TamSX3("CN9_NUMERO")[1]
    Local nTamRev    := TamSX3("CN9_REVISA")[1]
    Local cFiltNum   := ""
    Local cLikeNum   := ""
    Local cFiltFil   := ""
    Local dFiltDtDe  := CToD("")
    Local dFiltDtAte := CToD("")

    If ValType(oReq["tipo"]) == "C" ; cFiltTipo := AllTrim(oReq["tipo"]) ; EndIf
    If ValType(oReq["situacao"]) == "C" ; cFiltSit := AllTrim(oReq["situacao"]) ; EndIf
    If ValType(oReq["numero"]) == "C" ; cFiltNum := AllTrim(oReq["numero"]) ; EndIf
    If ValType(oReq["filial"]) == "C" .And. !Empty(AllTrim(oReq["filial"])) ; cFiltFil := AllTrim(oReq["filial"]) ; EndIf
    If ValType(oReq["dataInicioDe"])  == "C" .And. !Empty(AllTrim(oReq["dataInicioDe"]))  ; dFiltDtDe  := ZcnSToD(oReq["dataInicioDe"])  ; EndIf
    If ValType(oReq["dataInicioAte"]) == "C" .And. !Empty(AllTrim(oReq["dataInicioAte"])) ; dFiltDtAte := ZcnSToD(oReq["dataInicioAte"]) ; EndIf

    cLikeNum := "%'%" + cFiltNum + "%'%"
    If Empty(cFiltFil)   ; cFiltFil   := xFilial("CN9")     ; EndIf
    If Empty(dFiltDtDe)  ; dFiltDtDe  := SToD("19000101") ; EndIf
    If Empty(dFiltDtAte) ; dFiltDtAte := SToD("20991231") ; EndIf

    BeginSql Alias cAliasQ
        SELECT CN9.CN9_NUMERO AS NUMERO, CN9.CN9_REVISA AS REVISA, CN9.CN9_ESPCTR AS ESPCTR,
               CN9.CN9_FILIAL AS FILIAL, CN9.CN9_SITUAC AS SITUAC, CN9.CN9_UNVIGE AS UNVIGE, CN9.CN9_VIGE AS VIGE
          FROM %table:CN9% CN9
         WHERE CN9.%notDel%
           AND CN9.CN9_FILIAL = %exp:cFiltFil%
           AND CN9.CN9_REVISA = CN9.CN9_REVATU
           AND CN9.CN9_NUMERO LIKE %exp:cLikeNum%
           AND CN9.CN9_DTINIC BETWEEN %exp:dFiltDtDe% AND %exp:dFiltDtAte%
         ORDER BY CN9.CN9_NUMERO
    EndSql

    CNC->(dbSetOrder(1))

    While (cAliasQ)->(!Eof())
        oContrato := JsonObject():New()
        cTipo := IIf(AllTrim((cAliasQ)->ESPCTR) == "1", "C", "V")

        oContrato["numero"]            := AllTrim((cAliasQ)->NUMERO)
        oContrato["revisao"]           := AllTrim((cAliasQ)->REVISA)
        oContrato["tipo"]              := cTipo
        oContrato["filial"]            := AllTrim((cAliasQ)->FILIAL)
        oContrato["situacao"]          := AllTrim((cAliasQ)->SITUAC)
        oContrato["situacaoDescricao"] := ZcnSitDesc(oContrato["situacao"])
        // vigencia/unidadeVigencia enviados SEPARADOS (nao mais concatenados num texto "81 2")
        // -- CN9_UNVIGE e um dominio fechado (1=Dias/2=Meses/3=Anos, confirmado pelo usuario
        // 2026-08-11) que o Angular converte pra rotulo (ver UNIDADES_VIGENCIA_OPTIONS em
        // contrato.model.ts), a mesma conversao que ZcnMont/contrato-editor ja faziam pro
        // cabecalho -- so a listagem estava mandando o codigo cru direto pra tela.
        oContrato["vigencia"]         := (cAliasQ)->VIGE
        oContrato["unidadeVigencia"]  := AllTrim((cAliasQ)->UNVIGE)

        cCodigo := ""
        cLoja   := ""
        // Usa a FILIAL do proprio registro (cAliasQ)->FILIAL, nao xFilial("CNC") (filial da sessao
        // corrente) -- desde que o filtro de filial em ZcnList passou a permitir consultar OUTRA
        // filial (cFiltFil), xFilial("CNC") aqui buscaria sempre na filial da sessao, deixando
        // pessoaNome vazio pra contratos de filiais diferentes da atual.
        If CNC->(dbSeek(Padr((cAliasQ)->FILIAL, Len(xFilial("CNC"))) + Padr((cAliasQ)->NUMERO, nTamNum) + Padr((cAliasQ)->REVISA, nTamRev)))
            If cTipo == "C"
                cCodigo := AllTrim(CNC->CNC_CODIGO)
                cLoja   := AllTrim(CNC->CNC_LOJA)
            Else
                cCodigo := AllTrim(CNC->CNC_CLIENT)
                cLoja   := AllTrim(CNC->CNC_LOJACL)
            EndIf
        EndIf
        oContrato["pessoaNome"] := ZcnNome(cTipo, cCodigo, cLoja)

        If (Empty(cFiltTipo) .Or. oContrato["tipo"] == cFiltTipo) .And.;
           (Empty(cFiltSit)  .Or. oContrato["situacao"] == cFiltSit)
            aAdd(aContratos, oContrato)
        EndIf

        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

    oResp["success"]   := .T.
    oResp["contratos"] := aContratos

Return oResp

/*/{Protheus.doc} ZcnDet
Detalha um contrato (operacao "contratoDetalhe") -- so um atalho para ZcnMont
a partir do payload recebido.
@type Static Function
@param oReq JsonObject, {numero, revisao} (revisao vazia = usa CN9_REVATU)
@return JsonObject, ver ZcnMont
/*/
//=============================================================================================================================
Static Function ZcnDet(oReq)

    Local cNumero  := ""
    Local cRevisao := ""

    If ValType(oReq["numero"]) == "C" ; cNumero  := AllTrim(oReq["numero"])  ; EndIf
    If ValType(oReq["revisao"]) == "C" ; cRevisao := AllTrim(oReq["revisao"]) ; EndIf

Return ZcnMont(cNumero, cRevisao)

/*/{Protheus.doc} ZcnMont
Monta o JSON completo de um contrato (cabecalho + pessoa + planilhas/itens da
revisao informada + historico de todas as revisoes) -- usado por ZcnDet e
como retorno de ZcnCriar/ZcnRevAb/ZcnSit/ZcnAprov, para o Angular atualizar a
tela sem precisar de uma 2a chamada.
@type Static Function
@param cContra caractere, numero do contrato
@param cRevisa caractere, revisao (vazia = usa CN9_REVATU do contrato)
@return JsonObject, {success, header, pessoa, planilhas:[...], revisoes:[...]}
/*/
//=============================================================================================================================
Static Function ZcnMont(cContra, cRevisa)

    Local oResp     := JsonObject():New()
    Local oHeader   := JsonObject():New()
    Local oPessoa   := JsonObject():New()
    Local aPlan     := {}
    Local aRev      := {}
    Local oPla      := Nil
    Local oItm      := Nil
    Local oRev      := Nil
    Local cTipo     := ""
    Local cModelId  := ""
    Local oModel    := Nil
    Local oModelCNA := Nil
    Local oModelCNB := Nil
    Local oModelRev := Nil
    Local nTamNum   := Max(TamSX3("CN9_NUMERO")[1], Len(cContra))
    Local nTamRev   := 0
    Local nI        := 0
    Local nJ        := 0

    CN9->(dbSetOrder(1)) // CN9_FILIAL+CN9_NUMERO+CN9_REVISA

    If Empty(cRevisa) .And. CN9->(dbSeek(xFilial("CN9") + Padr(cContra, nTamNum)))
        cRevisa := AllTrim(CN9->CN9_REVATU)
    EndIf
    nTamRev := Max(TamSX3("CN9_REVISA")[1], Len(cRevisa))

    If !CN9->(dbSeek(xFilial("CN9") + Padr(cContra, nTamNum) + Padr(cRevisa, nTamRev)))
        oResp["success"] := .F.
        oResp["message"] := "Contrato [" + cContra + "] revisao [" + cRevisa + "] nao encontrado."
        Return oResp
    EndIf

    cTipo := IIf(AllTrim(CN9->CN9_ESPCTR) == "1", "C", "V")

    oHeader["numero"]             := AllTrim(CN9->CN9_NUMERO)
    oHeader["revisao"]            := AllTrim(CN9->CN9_REVISA)
    oHeader["tipo"]               := cTipo
    oHeader["filial"]             := AllTrim(CN9->CN9_FILIAL)
    oHeader["dataInicio"]         := DToS(CN9->CN9_DTINIC)
    oHeader["unidadeVigencia"]    := AllTrim(CN9->CN9_UNVIGE)
    oHeader["vigencia"]           := CN9->CN9_VIGE
    // Val(cValToChar()) = numero tanto se CN9_MOEDA for N quanto se for C ("01")
    oHeader["moeda"]              := Val(cValToChar(CN9->CN9_MOEDA))
    // Descricao do contrato (CN9_DESCRI e campo VIRTUAL): so e lido pelo modelo, mais abaixo
    oHeader["descricao"]          := ""
    oHeader["condPagto"]          := AllTrim(CN9->CN9_CONDPG)
    oHeader["tipoContrato"]       := AllTrim(CN9->CN9_TPCTO)
    oHeader["situacao"]           := AllTrim(CN9->CN9_SITUAC)
    oHeader["situacaoDescricao"]  := ZcnSitDesc(oHeader["situacao"])
    oHeader["temCronograma"]      := ZcnTmCrg(cContra, cRevisa)

    // Campos novos do header (Fase 5, protótipo "Contratos - Alteração") -- CONFIRMADOS PELO
    // USUARIO em 2026-08-11 (2 rodadas de correcao, nomes reais substituindo os chutes
    // iniciais). Todos campos FISICOS normais (exceto justificativa/objeto/clausula, ver bloco
    // do modelo abaixo) -- ainda lidos via ZcnSFld/ZcnSFldN/ZcnSFldD por habito de seguranca
    // (nao custa nada, protege contra erro meu de digitacao ao copiar o nome).
    oHeader["dtAssinatura"]      := ZcnSFldD("CN9", "CN9_ASSINA")
    oHeader["valorInicial"]      := ZcnSFldN("CN9", "CN9_VLINI")
    oHeader["valorAtual"]        := ZcnSFldN("CN9", "CN9_VLATU")
    oHeader["despesaFinanceira"] := ZcnSFldN("CN9", "CN9_VJUROS")
    oHeader["reajuste"]          := AllTrim(ZcnSFld("CN9", "CN9_FLGREJ"))
    oHeader["dtReajuste"]        := ZcnSFldD("CN9", "CN9_DTREAJ")
    oHeader["saldo"]             := ZcnSFldN("CN9", "CN9_SALDO")
    oHeader["dtUltimaRevisao"]   := ZcnSFldD("CN9", "CN9_DTREV")
    oHeader["natureza"]          := AllTrim(ZcnSFld("CN9", "CN9_NATURE"))
    // Ainda NAO confirmados -- so leitura segura (ZcnSFld degrada em "" / 0 sem quebrar a tela
    // se o nome estiver errado), sem escrita nenhuma em ZcnCriar/ZcnAtu (ver la o motivo: um
    // SetValue com nome errado ja confirmou dar THREAD ERROR incapturavel nesta sessao).
    oHeader["valorPresente"]    := ZcnSFldN("CN9", "CN9_VLPRES")
    oHeader["indice"]           := AllTrim(ZcnSFld("CN9", "CN9_INDICE"))
    oHeader["centroCusto"]      := AllTrim(ZcnSFld("CN9", "CN9_CC"))
    oHeader["responsavel"]      := AllTrim(ZcnSFld("CN9", "CN9_RESPON"))
    // CN9_JUSTIF/CN9_OBJCTO/CN9_ALTCLA sao CAMPOS VIRTUAIS (memo, todos confirmados pelo
    // usuario) -- sem coluna fisica na DBF, so resolvidos atraves do MODELO (gatilho do SX3),
    // nunca por alias cru/ZcnSFld. Comecam vazios aqui e sao preenchidos de verdade la embaixo,
    // DEPOIS que oModel:Activate() tiver sucesso (mesmo bloco que ja le CNCDETAIL/CNADETAIL/
    // CNBDETAIL).
    oHeader["justificativa"]    := ""
    oHeader["objeto"]           := ""
    oHeader["clausula"]         := ""

    // Pessoa (CNC) + planilhas/itens (CNA/CNB) da revisao corrente -- lidos via o PROPRIO
    // modelo MVC em modo consulta (MODEL_OPERATION_VIEW), NAO SQL/alias direto. Depois dos
    // erros reais de "coluna nao existe"/"invalid field name" com nomes de campo de ligacao
    // inventados por analogia (CNC_CONTRA, e o mesmo risco existia para CNB_NUMERO -- nenhum
    // dos dois e citado em nenhum exemplo do GCT0109, porque o framework resolve essas
    // relacoes de submodelo sozinho), ler pelo modelo e a fonte mais confiavel possivel: e o
    // MESMISSIMO mecanismo que a tela nativa do CNTA300 usa pra exibir o contrato, e o
    // relacionamento pai-filho (CNADETAIL 1:N CNBDETAIL) e resolvido pelo framework, nao por
    // mim adivinhando nome de coluna.
    cModelId := IIf(cTipo == "C", "CNTA300", "CNTA301")
    oModel   := FWLoadModel(cModelId)
    oModel:SetOperation(MODEL_OPERATION_VIEW)
    If oModel:Activate()
        // CN9_JUSTIF/CN9_OBJCTO/CN9_ALTCLA sao campos VIRTUAIS (ver nota acima) -- so podem ser
        // lidos atraves do modelo, nunca por alias cru. Este e o unico ponto de ZcnMont que
        // consegue ler os campos da revisao CORRENTE (o historico de outras revisoes, mais
        // abaixo, precisa ativar um modelo por linha pra fazer o mesmo -- so pra CN9_JUSTIF,
        // que e o unico exibido no historico).
        oHeader["justificativa"] := AllTrim(oModel:GetValue('CN9MASTER', 'CN9_JUSTIF'))
        oHeader["objeto"]        := AllTrim(oModel:GetValue('CN9MASTER', 'CN9_OBJCTO'))
        oHeader["clausula"]      := AllTrim(oModel:GetValue('CN9MASTER', 'CN9_ALTCLA'))
        If !Empty(ZcnCpDic("descCtr"))
            oHeader["descricao"] := ZcnPlaGet(oModel:GetModel('CN9MASTER'), "descCtr", "C")
        EndIf

        If cTipo == "C"
            oPessoa["codigo"] := AllTrim(oModel:GetValue('CNCDETAIL', 'CNC_CODIGO'))
            oPessoa["loja"]   := AllTrim(oModel:GetValue('CNCDETAIL', 'CNC_LOJA'))
        Else
            oPessoa["codigo"] := AllTrim(oModel:GetValue('CNCDETAIL', 'CNC_CLIENT'))
            oPessoa["loja"]   := AllTrim(oModel:GetValue('CNCDETAIL', 'CNC_LOJACL'))
        EndIf
        oPessoa["nome"] := ZcnNome(cTipo, oPessoa["codigo"], oPessoa["loja"])

        oModelCNA := oModel:GetModel('CNADETAIL')
        oModelCNB := oModel:GetModel('CNBDETAIL')

        For nI := 1 To oModelCNA:Length()
            oModelCNA:GoLine(nI)

            oPla := JsonObject():New()
            oPla["numero"]       := AllTrim(oModelCNA:GetValue('CNA_NUMERO'))
            oPla["tipoPlanilha"] := AllTrim(oModelCNA:GetValue('CNA_TIPPLA'))
            // CNA_DTINI/CNA_DTFIM (data inicio/fim da planilha) -- suposicao por analogia com
            // CN9_DTINIC, nunca confirmada -- ZcnMDat degrada pra "" se o nome estiver errado.
            oPla["dataInicio"]   := ZcnMDat(oModelCNA, 'CNA_DTINI')
            oPla["dataFim"]      := ZcnMDat(oModelCNA, 'CNA_DTFIM')
            // Campos da planilha resolvidos pelo dicionario (ZcnCpDic) -- "" / 0 se o campo nao existir
            oPla["descricao"]     := ZcnPlaGet(oModelCNA, "descPla", "C")
            oPla["indice"]        := ZcnPlaGet(oModelCNA, "indice", "C")
            oPla["periodicidade"] := ZcnPlaGet(oModelCNA, "periodicidade", "N")
            oPla["unidadePer"]    := ZcnPlaGet(oModelCNA, "unidadePer", "C")
            oPla["modoReajuste"]  := ZcnPlaGet(oModelCNA, "modoReajuste", "C")
            oPla["dataBase"]      := ZcnPlaGet(oModelCNA, "dataBase", "D")
            oPla["pessoa"]       := JsonObject():New()
            If cTipo == "C"
                oPla["pessoa"]["codigo"] := AllTrim(oModelCNA:GetValue('CNA_FORNEC'))
                oPla["pessoa"]["loja"]   := AllTrim(oModelCNA:GetValue('CNA_LJFORN'))
            Else
                oPla["pessoa"]["codigo"] := AllTrim(oModelCNA:GetValue('CNA_CLIENT'))
                oPla["pessoa"]["loja"]   := AllTrim(oModelCNA:GetValue('CNA_LOJACL'))
            EndIf
            oPla["pessoa"]["nome"] := ZcnNome(cTipo, oPla["pessoa"]["codigo"], oPla["pessoa"]["loja"])

            oPla["itens"] := {}
            For nJ := 1 To oModelCNB:Length()
                oModelCNB:GoLine(nJ)
                oItm := JsonObject():New()
                oItm["item"]          := AllTrim(oModelCNB:GetValue('CNB_ITEM'))
                oItm["produto"]       := AllTrim(oModelCNB:GetValue('CNB_PRODUT'))
                oItm["descricao"]     := ZcnDesc(oItm["produto"])
                oItm["quantidade"]    := oModelCNB:GetValue('CNB_QUANT')
                oItm["valorUnitario"] := oModelCNB:GetValue('CNB_VLUNIT')
                oItm["tes"]           := AllTrim(oModelCNB:GetValue('CNB_TS'))
                oItm["pedTit"]        := AllTrim(oModelCNB:GetValue('CNB_PEDTIT'))
                // CNB_CC/CNB_PERDES via ZcnMStr/ZcnMNum (nao AllTrim/GetValue direto) --
                // suposicoes de nome de campo, ver nota em ZcnCriar.
                oItm["cc"]            := ZcnMStr(oModelCNB, 'CNB_CC')
                oItm["desconto"]      := ZcnMNum(oModelCNB, 'CNB_PERDES')
                oItm["quantidadeMedida"] := IIf(Empty(ZcnCpo({"CNB_QTDMED"})), 0, IIf(ValType(ZcnMGet(oModelCNB, "CNB_QTDMED")) == "N", ZcnMGet(oModelCNB, "CNB_QTDMED"), 0))
                aAdd(oPla["itens"], oItm)
            Next nJ

            aAdd(aPlan, oPla)
        Next nI

        oModel:DeActivate()
    EndIf

    // Historico de revisoes -- todas as linhas de CN9 para este numero de contrato.
    // IMPORTANTE (corrigido 2026-08-11, esclarecido pelo usuario): CN9_JUSTIF/CN9_TIPREV sao
    // campos VIRTUAIS (declarados no SX3, sem coluna fisica na DBF, resolvidos por gatilho SO
    // atraves do MODELO) -- por isso "invalid field name in Alias CN9->CN9_JUSTIF" acontecia
    // sempre que a leitura era feita por alias cru + ZcnSFld (que so enxerga a estrutura fisica
    // da DBF, nunca campo virtual). ZcnRevAb sempre gravou esse campo com sucesso porque usa
    // oModel:SetValue -- a leitura agora faz o mesmo: ativa um FWLoadModel(VIEW) POR LINHA do
    // historico (CN9 ja posicionado ali pelo DbSkip do loop) e le via oModel:GetValue. Mais
    // pesado que uma leitura de alias simples, mas e o UNICO jeito confiavel de ler campo
    // virtual -- mesmo mecanismo ja usado pra CNADETAIL/CNBDETAIL da revisao corrente, acima.
    CN9->(dbSetOrder(1))
    If CN9->(dbSeek(xFilial("CN9") + Padr(cContra, nTamNum)))
        While !CN9->(Eof()) .And. AllTrim(CN9->CN9_NUMERO) == cContra
            oRev := JsonObject():New()
            oRev["tipo"]          := ""
            oRev["justificativa"] := ""

            Begin Sequence
                oModelRev := FWLoadModel(cModelId)
                oModelRev:SetOperation(MODEL_OPERATION_VIEW)
                If oModelRev:Activate()
                    oRev["tipo"]          := AllTrim(oModelRev:GetValue('CN9MASTER', 'CN9_TIPREV'))
                    oRev["justificativa"] := AllTrim(oModelRev:GetValue('CN9MASTER', 'CN9_JUSTIF'))
                    oModelRev:DeActivate()
                EndIf
            Recover Using oErrRev
                oRev["tipo"]          := ""
                oRev["justificativa"] := ""
            End Sequence

            // CN9_DTREV (Data da Ultima Revisao, confirmado pelo usuario 2026-08-11) -- campo
            // real pra "quando esta revisao foi feita", substitui a aproximacao anterior
            // (CN9_DTINIC, data de inicio do CONTRATO, nao da revisao). Cai de volta pra
            // CN9_DTINIC so se CN9_DTREV vier vazio (ex.: revisao 001, a inicial, pode nao ter
            // esse campo preenchido).
            oRev["data"] := ZcnSFldD("CN9", "CN9_DTREV")
            If Empty(oRev["data"])
                oRev["data"] := DToS(CN9->CN9_DTINIC)
            EndIf
            oRev["situacao"]          := AllTrim(CN9->CN9_SITUAC)
            oRev["situacaoDescricao"] := ZcnSitDesc(oRev["situacao"])
            aAdd(aRev, oRev)
            CN9->(DbSkip())
        EndDo
    EndIf

    oResp["success"]   := .T.
    oResp["header"]    := oHeader
    oResp["pessoa"]    := oPessoa
    oResp["planilhas"] := aPlan
    oResp["revisoes"]  := aRev

Return oResp

/*/{Protheus.doc} ZcnTmCrg
Indica se o contrato+revisao ja tem cronograma financeiro/fisico gerado
(tabela CNF) -- usado por ZcnMont para a tela mostrar um indicador e decidir
se oferece o botao "Incluir Cronograma Financeiro/Fisico" (pedido do
usuario, replica o botao nativo do CNTA300/CN300PrCF).
IMPORTANTE: assume CNF_CONTRA/CNF_REVISA como campos de ligacao (mesma
convencao de CNA_CONTRA/CNA_REVISA, que sao reais), nunca confirmados no
GCT0109 -- envolvido em Begin Sequence/Recover Using de proposito: se o nome
da tabela/campo estiver errado, degrada para "sem cronograma" (.F.) em vez
de quebrar a tela de detalhe inteira.
@type Static Function
@param cContra caractere, numero do contrato
@param cRevisa caractere, revisao
@return logico, .T. se ja existe pelo menos 1 linha de cronograma
/*/
//=============================================================================================================================
Static Function ZcnTmCrg(cContra, cRevisa)

    Local lTem      := .F.
    Local cAliasQ   := GetNextAlias()
    //Local oErrCatch := Nil

    Begin Sequence
        BeginSql Alias cAliasQ
            SELECT COUNT(*) AS QTD
              FROM %table:CNF% CNF
             WHERE CNF.%notDel%
               AND CNF.CNF_FILIAL = %xfilial:CNF%
               AND CNF.CNF_CONTRA = %exp:cContra%
               AND CNF.CNF_REVISA = %exp:cRevisa%
        EndSql
        lTem := (cAliasQ)->QTD > 0
        (cAliasQ)->(DbCloseArea())
    Recover Using oErrCatch
        lTem := .F.
    End Sequence

Return lTem

/*/{Protheus.doc} ZcnSFld
Le um campo de um alias posicionado de forma segura -- confere com FieldPos()
antes (que so retorna 0/nao existe, nunca estoura erro) em vez de acessar o
campo direto via "Alias->CAMPO" (que da "invalid field name" em erro fatal de
thread se o campo nao existir no dicionario deste ambiente). Usar sempre que
um campo do GCT0109 nao tiver sido confirmado como existente nesta base
especifica (ex: CN9_JUSTIF, ver nota em ZcnMont).
@type Static Function
@param cAlias caractere, nome do alias (deve estar aberto e posicionado)
@param cCampo caractere, nome do campo
@return generico, valor do campo (tipo original) ou "" se o campo nao existir
/*/
//=============================================================================================================================
Static Function ZcnSFld(cAlias, cCampo)

    Local nPos := (cAlias)->(FieldPos(cCampo))

Return IIf(nPos > 0, (cAlias)->(FieldGet(nPos)), "")

/*/{Protheus.doc} ZcnSFldN
Mesma ideia de ZcnSFld, mas ja devolve numerico (0 se o campo nao existir ou
nao for numerico) -- evita cada chamador ter que checar ValType antes de
usar o valor num JSON de resposta.
@type Static Function
@param cAlias caractere, nome do alias (deve estar aberto e posicionado)
@param cCampo caractere, nome do campo
@return numerico, valor do campo ou 0
/*/
//=============================================================================================================================
Static Function ZcnSFldN(cAlias, cCampo)

    Local xVal := ZcnSFld(cAlias, cCampo)

Return IIf(ValType(xVal) == "N", xVal, 0)

/*/{Protheus.doc} ZcnSFldD
Mesma ideia de ZcnSFld, mas ja devolve data no formato ISO ("" se o campo nao
existir, nao for data, ou estiver vazio).
@type Static Function
@param cAlias caractere, nome do alias (deve estar aberto e posicionado)
@param cCampo caractere, nome do campo
@return caractere, data ISO ('yyyy-MM-dd') ou ""
/*/
//=============================================================================================================================
Static Function ZcnSFldD(cAlias, cCampo)

    Local xVal := ZcnSFld(cAlias, cCampo)

Return IIf(ValType(xVal) == "D" .And. !Empty(xVal), DToS(xVal), "")

/*/{Protheus.doc} ZcnSitDesc
Traduz o codigo de situacao do cabecalho do contrato (CN9_SITUAC) para a descricao
correspondente, em texto corrido -- MESMA tabela ja usada (e confirmada pelo usuario) em
Contratos/RT69M003.prw::SitCtrDescPlain (relatorio de timeline do contrato). Duplicada aqui
porque Static Function nao e compartilhavel entre fontes .prw diferentes no ADVPL -- cada .prg
e sua propria unidade de compilacao. Usada por ZcnList/ZcnMont para o Angular parar de traduzir
o codigo sozinho (o mapeamento local em contrato.model.ts estava incompleto -- faltavam
02/04/09/10/A -- e por isso mostrava o codigo cru pra varias situacoes reais).
@type Static Function
@param cCod caractere, codigo da situacao (ex: "02", "A")
@return caractere, descricao, ou o proprio codigo se nao mapeado
/*/
//=============================================================================================================================
Static Function ZcnSitDesc(cCod)

    Local cCodT := AllTrim(cCod)
    Local cDesc := cCodT

    Do Case
    Case cCodT == "01" ; cDesc := "Cancelado"
    Case cCodT == "02" ; cDesc := "Em Elaboracao"
    Case cCodT == "03" ; cDesc := "Emitido"
    Case cCodT == "04" ; cDesc := "Em Aprovacao"
    Case cCodT == "05" ; cDesc := "Vigente"
    Case cCodT == "06" ; cDesc := "Paralisado"
    Case cCodT == "07" ; cDesc := "Solicitacao de Finalizacao"
    Case cCodT == "08" ; cDesc := "Finalizado"
    Case cCodT == "09" ; cDesc := "Em Revisao"
    Case cCodT == "10" ; cDesc := "Revisado"
    Case cCodT == "A"  ; cDesc := "Revisao com Aprovacao por Alcadas"
    Case cCodT == "EXCLUIDO" ; cDesc := "Excluido"
    EndCase

Return cDesc

/*/{Protheus.doc} ZcnNome
Resolve o nome de um cliente/fornecedor via SA1 (venda) ou SA2 (compra).
@type Static Function
@param cTipo caractere, 'C' ou 'V'
@param cCodigo caractere, codigo do cliente/fornecedor
@param cLoja caractere, loja
@return caractere, nome (ou "" se nao encontrado/codigo vazio)
/*/
//=============================================================================================================================
Static Function ZcnNome(cTipo, cCodigo, cLoja)

    Local cAliasQ := GetNextAlias()
    Local cNome   := ""

    If Empty(cCodigo)
        Return ""
    EndIf

    If cTipo == "C"
        BeginSql Alias cAliasQ
            SELECT A2_NOME AS NOME
              FROM %table:SA2% SA2
             WHERE SA2.%notDel%
               AND SA2.A2_FILIAL = %xfilial:SA2%
               AND SA2.A2_COD    = %exp:cCodigo%
               AND SA2.A2_LOJA   = %exp:cLoja%
        EndSql
    Else
        BeginSql Alias cAliasQ
            SELECT A1_NOME AS NOME
              FROM %table:SA1% SA1
             WHERE SA1.%notDel%
               AND SA1.A1_FILIAL = %xfilial:SA1%
               AND SA1.A1_COD    = %exp:cCodigo%
               AND SA1.A1_LOJA   = %exp:cLoja%
        EndSql
    EndIf

    If (cAliasQ)->(!Eof())
        cNome := AllTrim((cAliasQ)->NOME)
    EndIf
    (cAliasQ)->(DbCloseArea())

Return cNome

/*/{Protheus.doc} ZcnDesc
Descricao de um produto (SB1), usada para exibir junto ao codigo nos itens
de planilha e no lookup de produto.
@type Static Function
@param cProduto caractere, codigo do produto (B1_COD)
@return caractere, descricao (B1_DESC) ou "" se nao encontrado/vazio
/*/
//=============================================================================================================================
Static Function ZcnDesc(cProduto)

    Local cAliasQ := GetNextAlias()
    Local cDesc   := ""

    If Empty(cProduto)
        Return ""
    EndIf

    BeginSql Alias cAliasQ
        SELECT B1_DESC AS DESCRI
          FROM %table:SB1% SB1
         WHERE SB1.%notDel%
           AND SB1.B1_FILIAL = %xfilial:SB1%
           AND SB1.B1_COD    = %exp:cProduto%
    EndSql

    If (cAliasQ)->(!Eof())
        cDesc := AllTrim((cAliasQ)->DESCRI)
    EndIf
    (cAliasQ)->(DbCloseArea())

Return cDesc

/*/{Protheus.doc} ZcnCriar
Inclui um contrato novo (operacao "contratoCriar") -- replica os exemplos
"Inclusao de contrato"/"Inclusao de contrato de vendas"/"Inclusao de
contrato com multiplas planilhas" do GCT0109: FWLoadModel + SetOperation
(INSERT) + SetValue em CN9MASTER/CNCDETAIL/CNADETAIL/CNBDETAIL +
VldData/CommitData.
Tipo (Compra/Venda) NAO vem mais solto no payload -- e derivado no servidor
a partir do CN1_ESPCTR do "Tipo de Contrato" (CN1) informado, pedido do
usuario (2026-08-10) apos ver que CN1 ja carrega essa informacao (print da
base: CN1_CODIGO/CN1_DESCRI/CN1_ESPCTR confirmados como colunas reais).
Planilhas agora em array (`planilhas`), permitindo mais de uma por contrato
-- mesmo padrao do exemplo oficial "IncMultPlan": CNA_NUMERO sequencial via
StrZero, AddLine a partir da 2a planilha, itens (CNBDETAIL) recomecando do
item 1 em cada planilha (a submodel CNBDETAIL e relativa a linha corrente de
CNADETAIL, confirmado no proprio exemplo oficial).
@type Static Function
@param oReq JsonObject, {header:{numero,dataInicio,unidadeVigencia,vigencia,moeda,condPagto,tipoContrato,justificativa,dtAssinatura,reajuste,indice,despesaFinanceira,objeto,clausula,natureza,centroCusto,responsavel (os ultimos 8 sao suposicao de nome de campo, ver notas abaixo)}, planilhas:[{tipoPlanilha,dataInicio,dataFim,pessoa:{codigo,loja},itens:[{produto,quantidade,valorUnitario}]}]} -- pessoa agora e por planilha, nao mais um campo unico do contrato (Fase 5, 2026-08-11)
@return JsonObject, ver ZcnMont (ou {success:.F., message})
/*/
//=============================================================================================================================
Static Function ZcnCriar(oReq)

    Local oResp      := JsonObject():New()
    Local oModel      := Nil
    Local oModelCNC    := Nil
    Local oModelCNA     := Nil
    Local oModelCNB      := Nil
    Local oHeader         := oReq["header"]
    Local aPlanilhas         := oReq["planilhas"]
    Local aItens              := {}
    Local aFalhas               := {}
    Local aAvisos                := {}
    Local cTipo                  := ""
    Local cCodTpCtr                := ""
    Local cModelId                  := ""
    Local cNumero                    := ""
    Local cRevisao                    := ""
    Local cMsg                         := ""
    Local cCodPessoa                    := ""
    Local cLojPessoa                     := ""
    Local nP                              := 0
    Local nI                               := 0
    Local oPla                              := Nil
    Local oItm                               := Nil
    Local oErrCatch                           := Nil
    Local dDtIniPla                            := CToD("")

    // Filial escolhida no modal de inclusao (item 4, Angular) -- so validada aqui, NUNCA
    // gravada via SetValue em CN9MASTER: CN9_FILIAL de tabelas compartilhadas e determinado
    // pela filial REAL da sessao/RPC corrente (xFilial), nao por um campo do modelo -- setar
    // esse campo manualmente nao muda de fato onde o registro e gravado, so criaria uma falsa
    // sensacao de que funcionou. Ate existir um jeito confirmado de trocar de filial dentro da
    // mesma sessao do FWCallApp, a unica opcao segura e RECUSAR a inclusao se o usuario pediu
    // uma filial diferente da sessao atual, em vez de gravar silenciosamente na filial errada
    // (que foi provavelmente a causa do 1o relato de "contrato sumiu" -- ver ZcnList/ZcnMont,
    // que agora devolvem "filial" no JSON pra facilitar esse diagnostico).
    If ValType(oReq["filial"]) == "C" .And. !Empty(AllTrim(oReq["filial"])) .And.;
       AllTrim(oReq["filial"]) != AllTrim(xFilial("CN9"))
        oResp["success"] := .F.
        oResp["message"] := "Este ambiente nao permite criar o contrato diretamente na filial [" + AllTrim(oReq["filial"]) +;
            "] -- a sessao atual esta na filial [" + AllTrim(xFilial("CN9")) + "]. Faca login nessa filial para incluir o contrato nela."
        Return oResp
    EndIf

    If oHeader == Nil .Or. Empty(AllTrim(oHeader["numero"]))
        oResp["success"] := .F.
        oResp["message"] := "Numero do contrato nao informado"
        Return oResp
    EndIf

    cCodTpCtr := AllTrim(oHeader["tipoContrato"])
    If Empty(cCodTpCtr)
        oResp["success"] := .F.
        oResp["message"] := "Tipo de contrato nao informado"
        Return oResp
    EndIf

    CN1->(dbSetOrder(1)) // CN1_FILIAL+CN1_CODIGO
    If !CN1->(dbSeek(xFilial("CN1") + Padr(cCodTpCtr, TamSX3("CN1_CODIGO")[1])))
        oResp["success"] := .F.
        oResp["message"] := "Tipo de contrato [" + cCodTpCtr + "] nao encontrado"
        Return oResp
    EndIf
    cTipo := IIf(AllTrim(CN1->CN1_ESPCTR) == "1", "C", "V")

    If ValType(aPlanilhas) != "A" .Or. Len(aPlanilhas) == 0
        oResp["success"] := .F.
        oResp["message"] := "Informe ao menos uma planilha"
        Return oResp
    EndIf

    // Pessoa (cliente/fornecedor) e escolhida por planilha na UI, mas CNCDETAIL representa
    // UM UNICO cliente/fornecedor por contrato (e o exemplo oficial GCT0109 de multiplas
    // planilhas sempre repete a mesma pessoa em todas elas). Ate confirmarmos que a CNTA300
    // suporta pessoas distintas entre planilhas do mesmo contrato, exige-se aqui que todas as
    // planilhas usem o mesmo codigo+loja -- CNCDETAIL e preenchido com a pessoa da 1a planilha.
    For nP := 1 To Len(aPlanilhas)
        If aPlanilhas[nP]["pessoa"] == Nil .Or. Empty(AllTrim(aPlanilhas[nP]["pessoa"]["codigo"]))
            oResp["success"] := .F.
            oResp["message"] := "Informe o cliente/fornecedor da planilha " + AllTrim(Str(nP))
            Return oResp
        EndIf
    Next nP

    cCodPessoa := AllTrim(aPlanilhas[1]["pessoa"]["codigo"])
    cLojPessoa := AllTrim(aPlanilhas[1]["pessoa"]["loja"])
    For nP := 2 To Len(aPlanilhas)
        If AllTrim(aPlanilhas[nP]["pessoa"]["codigo"]) != cCodPessoa .Or.;
           AllTrim(aPlanilhas[nP]["pessoa"]["loja"])   != cLojPessoa
            oResp["success"] := .F.
            oResp["message"] := "As planilhas do contrato devem utilizar o mesmo fornecedor."
            Return oResp
        EndIf
    Next nP

    // A partir daqui manipula o modelo MVC de verdade -- envolve em Begin Sequence/Recover
    // Using porque essa parte ja quebrou 2 vezes nesta sessao com erros de runtime do proprio
    // framework (nao validacoes normais de VldData) que a interface Angular so via como um
    // THREAD ERROR sem detalhe. Com isso, qualquer erro de runtime aqui volta como JSON comum
    // (oResp com success=.F./message), sem precisar de outro ciclo de log do TDS pra saber o
    // que quebrou.
    Begin Sequence

    cModelId := IIf(cTipo == "C", "CNTA300", "CNTA301")
    oModel   := FWLoadModel(cModelId)
    oModel:SetOperation(MODEL_OPERATION_INSERT)

    // CanActivate()+Activate() (nao "Activate() e confere o retorno") -- mesma sequencia
    // JA CONFIRMADA FUNCIONANDO em RT69M002.prw/ProcessaPlanilha (CNTA121, mesma familia
    // GCT0109 de CNTA300/301): CanActivate() e o gate real; Activate() e chamado sem
    // condicional depois, confiando que o CanActivate() ja filtrou os casos de falha.
    If !oModel:CanActivate()
        oResp["success"] := .F.
        oResp["message"] := "Nao foi possivel ativar o modelo do contrato." + ;
            IIf(Empty(ZcnErrMsg(oModel)), "", " " + ZcnErrMsg(oModel))
        Return oResp
    EndIf
    oModel:Activate()

    // Cabecalho minimo (CN9MASTER) primeiro, depois CNCDETAIL logo em seguida -- igual ao
    // exemplo oficial GCT0109 ("Inclusao de contrato"). CN9_AUTO/CN9_ESPCTR continuam de fora
    // (nenhum exemplo oficial os seta).
    oModel:SetValue('CN9MASTER', 'CN9_NUMERO' , AllTrim(oHeader["numero"]))
    oModel:SetValue('CN9MASTER', 'CN9_DTINIC' , ZcnSToD(oHeader["dataInicio"]))
    oModel:SetValue('CN9MASTER', 'CN9_UNVIGE' , AllTrim(oHeader["unidadeVigencia"]))
    oModel:SetValue('CN9MASTER', 'CN9_VIGE'   , oHeader["vigencia"])
    oModel:SetValue('CN9MASTER', 'CN9_MOEDA'  , ZcnMoedaVl(oHeader["moeda"]))
    oModel:SetValue('CN9MASTER', 'CN9_CONDPG' , AllTrim(oHeader["condPagto"]))
    oModel:SetValue('CN9MASTER', 'CN9_TPCTO'  , cCodTpCtr)

    // CNCDETAIL: mesmo tratamento que RT69M002 da a QUALQUER grid submodel antes de escrever
    // nele -- garante a linha (AddLine se Length()==0) e POSICIONA explicitamente com GoLine()
    // antes do SetValue (RT69M002/ProcessaPlanilha faz isso pra CXNDETAIL antes de marcar
    // CXN_CHECK, e pra CNEDETAIL antes de LoadValue/TrySet). E exatamente o que faltava aqui: a
    // versao anterior confiava que o Activate() ja deixava CNCDETAIL numa linha "corrente"
    // valida, o que o erro "nao permite a alteracao de uma linha" contradiz.
    // Os SetValue de CNCDETAIL vao via ZcnTrySet (nao direto) -- mesmo mecanismo de TrySet do
    // RT69M002 (troca o ErrorBlock por um Break(e) durante a chamada): se o erro do
    // FWFormGridModel for do tipo que hoje aparece como THREAD ERROR incapturavel, ZcnTrySet
    // consegue capturar a Description REAL do erro em vez de deixar o processo abortar sem
    // detalhe -- e essa Description e o proximo dado que precisamos pra saber a causa raiz.
    oModelCNC := oModel:GetModel("CNCDETAIL")
    If oModelCNC != Nil
        If oModelCNC:Length() < 1
            oModelCNC:AddLine()
        EndIf
        oModelCNC:GoLine(1)
    EndIf

    If cTipo == "C"
        ZcnTrySet(oModel, aFalhas, 'CNCDETAIL', 'CNC_CODIGO', cCodPessoa)
        ZcnTrySet(oModel, aFalhas, 'CNCDETAIL', 'CNC_LOJA'  , cLojPessoa)
    Else
        ZcnTrySet(oModel, aFalhas, 'CNCDETAIL', 'CNC_CLIENT', cCodPessoa)
        ZcnTrySet(oModel, aFalhas, 'CNCDETAIL', 'CNC_LOJACL', cLojPessoa)
    EndIf

    If Len(aFalhas) > 0
        oResp["success"] := .F.
        oResp["message"] := "Falha ao preencher o fornecedor/cliente do contrato (CNCDETAIL): " + aFalhas[1]
        oModel:DeActivate()
        Return oResp
    EndIf

    oModelCNA := oModel:GetModel("CNADETAIL")
    oModelCNB := oModel:GetModel("CNBDETAIL")

    For nP := 1 To Len(aPlanilhas)
        oPla := aPlanilhas[nP]
        // Length() < nP (nao "nP > 1") -- nao assume que a grade ja chega com 1 linha pronta em
        // modo INSERT, confere de verdade. GoLine(nP) explicito depois: nao depender do efeito
        // colateral do AddLine() pra saber qual e a linha corrente da grade.
        If oModelCNA:Length() < nP
            oModelCNA:AddLine()
        EndIf
        oModelCNA:GoLine(nP)

        oModel:LoadValue('CNADETAIL', 'CNA_CONTRA', AllTrim(oHeader["numero"]))
        oModel:SetValue('CNADETAIL', 'CNA_NUMERO', StrZero(nP, Len(CNA->CNA_NUMERO)))
        oModel:SetValue('CNADETAIL', 'CNA_TIPPLA', AllTrim(oPla["tipoPlanilha"]))
        // Pessoa agora vem de DENTRO da planilha (oPla["pessoa"]), nao mais de um campo unico
        // do contrato -- ja validado (nao-vazio e igual em todas as planilhas) mais acima.
        If cTipo == "C"
            oModel:SetValue('CNADETAIL', 'CNA_FORNEC', AllTrim(oPla["pessoa"]["codigo"]))
            oModel:SetValue('CNADETAIL', 'CNA_LJFORN', AllTrim(oPla["pessoa"]["loja"]))
        Else
            oModel:SetValue('CNADETAIL', 'CNA_CLIENT', AllTrim(oPla["pessoa"]["codigo"]))
            oModel:SetValue('CNADETAIL', 'CNA_LOJACL', AllTrim(oPla["pessoa"]["loja"]))
        EndIf
        // CNA_DTINI/CNA_DTFIM -- suposicao por analogia com CN9_DTINIC, nunca confirmada. Via
        // ZcnTrySet (nao SetValue direto): mesmo cuidado do RT69M002 com campo de nome incerto,
        // captura a falha em aFalhas em vez de arriscar THREAD ERROR incapturavel.
        // CNA_DTINI (Data Inicial, campo obrigatorio no modelo -- VLDDATA_OBRIGAT) e preenchido
        // com a "Data base" (dataBase) da propria planilha -- pedido do usuario apos o erro real
        // "O campo Data Inicial (CNA_DTINI) nao foi preenchido" na inclusao. So cai para a data
        // de inicio da planilha/contrato se a Data base nao vier preenchida. Ver tambem ZcnSToD
        // (o bug real era SToD() recebendo a data ISO com tracos, nao a origem do valor).
        dDtIniPla := CToD("")
        If ValType(oPla["dataBase"]) == "C" .And. !Empty(AllTrim(oPla["dataBase"]))
            dDtIniPla := ZcnSToD(oPla["dataBase"])
        ElseIf ValType(oPla["dataInicio"]) == "C" .And. !Empty(AllTrim(oPla["dataInicio"]))
            dDtIniPla := ZcnSToD(oPla["dataInicio"])
        ElseIf ValType(oHeader["dataInicio"]) == "C" .And. !Empty(AllTrim(oHeader["dataInicio"]))
            dDtIniPla := ZcnSToD(oHeader["dataInicio"])
        EndIf
        If !Empty(dDtIniPla)
            ZcnTrySet(oModel, aFalhas, 'CNADETAIL', 'CNA_DTINI', dDtIniPla)
        EndIf
        If ValType(oPla["dataFim"]) == "C" .And. !Empty(AllTrim(oPla["dataFim"]))
            ZcnTrySet(oModel, aFalhas, 'CNADETAIL', 'CNA_DTFIM', ZcnSToD(oPla["dataFim"]))
        EndIf
        // Campos novos da planilha (descricao, indice de reajuste, periodicidade, unidade, modo de
        // reajuste, data base) -- nome do campo resolvido pelo dicionario (ZcnCpDic). Campo nao
        // localizado vira aviso na resposta (nao aborta a inclusao).
        ZcnPlaSet(oModel, aFalhas, aAvisos, "descPla", 'CNADETAIL', oPla["descricao"])
        ZcnPlaSet(oModel, aFalhas, aAvisos, "indice", 'CNADETAIL', oPla["indice"])
        ZcnPlaSet(oModel, aFalhas, aAvisos, "periodicidade", 'CNADETAIL', oPla["periodicidade"])
        ZcnPlaSet(oModel, aFalhas, aAvisos, "unidadePer", 'CNADETAIL', oPla["unidadePer"])
        ZcnPlaSet(oModel, aFalhas, aAvisos, "modoReajuste", 'CNADETAIL', oPla["modoReajuste"])
        ZcnPlaSet(oModel, aFalhas, aAvisos, "dataBase", 'CNADETAIL', oPla["dataBase"])

        aItens := oPla["itens"]
        If ValType(aItens) != "A" ; aItens := {} ; EndIf
        For nI := 1 To Len(aItens)
            oItm := aItens[nI]
            // Itens (CNBDETAIL) sao relativos a linha CORRENTE de CNADETAIL (relacionamento
            // pai-filho resolvido pelo proprio MVC) -- por isso o GoLine(nP) da CNA acima e
            // indispensavel antes deste bloco, e o GoLine(nI) abaixo pela mesma razao.
            If oModelCNB:Length() < nI
                oModelCNB:AddLine()
            EndIf
            oModelCNB:GoLine(nI)

            oModel:SetValue('CNBDETAIL', 'CNB_ITEM'  , StrZero(nI, Len(CNB->CNB_ITEM)))
            oModel:SetValue('CNBDETAIL', 'CNB_PRODUT', AllTrim(oItm["produto"]))
            oModel:SetValue('CNBDETAIL', 'CNB_QUANT' , oItm["quantidade"])
            oModel:SetValue('CNBDETAIL', 'CNB_VLUNIT', oItm["valorUnitario"])
            // IMPORTANTE: CNB_TS/CNB_PEDTIT sao campos oficiais confirmados no GCT0109
            // (exemplos "Inclusão de contrato"/"...de vendas"). CNB_CC/CNB_PERDES (centro de
            // custo/desconto percentual) sao suposicoes -- convencao padrao Protheus, mas nao
            // aparecem em nenhum exemplo do GCT0109; SetValue em campo que o modelo nao
            // reconhece normalmente e ignorado (nao quebra), mas confirmar se o valor nao
            // for persistido.
            If ValType(oItm["tes"]) == "C" .And. !Empty(AllTrim(oItm["tes"]))
                oModel:SetValue('CNBDETAIL', 'CNB_TS', AllTrim(oItm["tes"]))
            EndIf
            If ValType(oItm["cc"]) == "C" .And. !Empty(AllTrim(oItm["cc"]))
                ZcnTrySet(oModel, aFalhas, 'CNBDETAIL', 'CNB_CC', AllTrim(oItm["cc"]))
            EndIf
            If ValType(oItm["pedTit"]) == "C" .And. !Empty(AllTrim(oItm["pedTit"]))
                oModel:SetValue('CNBDETAIL', 'CNB_PEDTIT', AllTrim(oItm["pedTit"]))
            EndIf
            If ValType(oItm["desconto"]) == "N" .And. oItm["desconto"] > 0
                ZcnTrySet(oModel, aFalhas, 'CNBDETAIL', 'CNB_PERDES', oItm["desconto"])
            EndIf
        Next nI
    Next nP

    // CNA_DTINI/DTFIM/CNB_CC/CNB_PERDES sao suposicoes de nome (ver notas acima) -- via
    // ZcnTrySet, uma falha neles NAO aborta silenciosamente nem derruba a thread: cai aqui,
    // com a Description real do framework, e interrompe a inclusao com mensagem clara.
    If Len(aFalhas) > 0
        oResp["success"] := .F.
        oResp["message"] := "Falha ao preencher a planilha/item do contrato: " + aFalhas[1]
        oModel:DeActivate()
        Return oResp
    EndIf

    // Campos adicionais do header (Fase 5, protótipo "Contratos - Alteração", 2026-08-11),
    // TODOS CONFIRMADOS PELO USUARIO -- movidos para DEPOIS de CNC/CNA/CNB de proposito, pra
    // que gatilhos/validacoes desses campos nao interfiram na preparacao das grades do MVC.
    // CN9_JUSTIF/CN9_OBJCTO/CN9_ALTCLA sao campos VIRTUAIS (memo), graváveis via oModel:SetValue
    // normalmente. Os demais (valorPresente/indice/centroCusto/responsavel) continuam SEM
    // gravar -- ainda nao confirmados, so leitura segura em ZcnMont via ZcnSFld.
    If ValType(oHeader["justificativa"]) == "C"
        oModel:SetValue('CN9MASTER', 'CN9_JUSTIF', AllTrim(oHeader["justificativa"]))
    EndIf
    If ValType(oHeader["objeto"]) == "C"
        oModel:SetValue('CN9MASTER', 'CN9_OBJCTO', AllTrim(oHeader["objeto"]))
    EndIf
    If ValType(oHeader["clausula"]) == "C"
        oModel:SetValue('CN9MASTER', 'CN9_ALTCLA', AllTrim(oHeader["clausula"]))
    EndIf
    If ValType(oHeader["dtAssinatura"]) == "C" .And. !Empty(AllTrim(oHeader["dtAssinatura"]))
        oModel:SetValue('CN9MASTER', 'CN9_ASSINA', ZcnSToD(oHeader["dtAssinatura"]))
    EndIf
    If ValType(oHeader["valorInicial"]) == "N"
        oModel:SetValue('CN9MASTER', 'CN9_VLINI', oHeader["valorInicial"])
    EndIf
    If ValType(oHeader["valorAtual"]) == "N"
        oModel:SetValue('CN9MASTER', 'CN9_VLATU', oHeader["valorAtual"])
    EndIf
    If ValType(oHeader["despesaFinanceira"]) == "N"
        oModel:SetValue('CN9MASTER', 'CN9_VJUROS', oHeader["despesaFinanceira"])
    EndIf
    If ValType(oHeader["reajuste"]) == "C" .And. !Empty(AllTrim(oHeader["reajuste"]))
        oModel:SetValue('CN9MASTER', 'CN9_FLGREJ', AllTrim(oHeader["reajuste"]))
    EndIf
    // Descricao do contrato -- campo resolvido pelo dicionario (ZcnCpDic)
    ZcnPlaSet(oModel, aFalhas, aAvisos, "descCtr", 'CN9MASTER', oHeader["descricao"])
    If Len(aFalhas) > 0
        oResp["success"] := .F.
        oResp["message"] := "Falha ao preencher a descricao do contrato: " + aFalhas[1]
        oModel:DeActivate()
        Return oResp
    EndIf
    If ValType(oHeader["natureza"]) == "C" .And. !Empty(AllTrim(oHeader["natureza"]))
        oModel:SetValue('CN9MASTER', 'CN9_NATURE', AllTrim(oHeader["natureza"]))
    EndIf

    If oModel:VldData()
        oModel:CommitData()
        oModel:DeActivate()

        // NAO confia em oModel:GetValue('CN9MASTER','CN9_REVISA') logo apos o CommitData() pra
        // pegar a revisao -- confirmado em teste real que pode vir vazio nesse ponto (o valor
        // real so aparece de fato gravado na tabela, nao necessariamente no cache do model logo
        // apos o commit). Relê direto do alias CN9 (dbSeek so por filial+numero, a 1a e unica
        // revisao que um contrato recem-criado pode ter) -- fonte confiavel, e a mesma tecnica
        // que ZcnMont ja usa como fallback quando recebe revisao vazia.
        cNumero := AllTrim(oHeader["numero"])
        CN9->(dbSetOrder(1)) // CN9_FILIAL+CN9_NUMERO+CN9_REVISA
        If CN9->(dbSeek(xFilial("CN9") + Padr(cNumero, TamSX3("CN9_NUMERO")[1])))
            cRevisao := AllTrim(CN9->CN9_REVISA)
        EndIf

        oResp := ZcnMont(cNumero, cRevisao)
        If Len(aAvisos) > 0
            oResp["avisos"] := aAvisos
        EndIf
    Else
        // ZcnErrMsg varre GetErrorMessage() sem assumir indices fixos (ex.: [3]/[6]), que
        // podiam vir vazios conforme o tipo de erro e gerar mensagem "".
        cMsg := ZcnErrMsg(oModel)
        If Empty(cMsg)
            cMsg := "Falha na validacao do contrato."
        EndIf
        oModel:DeActivate()
        oResp["success"] := .F.
        oResp["message"] := cMsg
    EndIf

    Recover Using oErrCatch
        oResp := JsonObject():New()
        oResp["success"] := .F.
        oResp["message"] := "Erro interno ao criar contrato: " + AllTrim(oErrCatch:description) +;
            IIf(ValType(oErrCatch:operation) == "C" .And. !Empty(oErrCatch:operation), " (" + AllTrim(oErrCatch:operation) + ")", "")
    End Sequence

Return oResp

/*/{Protheus.doc} ZcnErrMsg
Monta uma mensagem de erro segura a partir de oModel:GetErrorMessage() -- varre TODAS as
posicoes do array (nao assume indices fixos como [3]/[6], que podem vir vazios dependendo do
tipo de erro) e concatena as que forem texto nao-vazio. Usada por ZcnCriar tanto na falha de
CanActivate() quanto na falha de VldData().
@type Static Function
@param oMdl objeto, instancia de FWFormModel/FWModel ja carregada (FWLoadModel)
@return caractere, mensagem concatenada (pode vir vazia se GetErrorMessage() nao retornar texto)
/*/
//=============================================================================================================================
Static Function ZcnErrMsg(oMdl)

    Local aErro := oMdl:GetErrorMessage()
    Local cMsg  := ""
    Local nE    := 0

    If ValType(aErro) == "A"
        For nE := 1 To Len(aErro)
            If ValType(aErro[nE]) == "C" .And. !Empty(AllTrim(aErro[nE]))
                cMsg += IIf(Empty(cMsg), "", " ") + AllTrim(aErro[nE])
            EndIf
        Next nE
    EndIf

Return cMsg

/*/{Protheus.doc} ZcnTrySet
Wrapper de oMdl:SetValue(cGrid,cField,xValue) -- MESMA tecnica do TrySet() ja usado (e
comprovadamente funcionando) em RT69M002.prw/ProcessaPlanilha: troca temporariamente o
ErrorBlock por um bloco que faz Break(e) durante a chamada, convertendo um erro de runtime do
proprio framework MVC (que hoje sai como THREAD ERROR incapturavel por Begin Sequence/Recover
comum, ex.: "FWFormGridModel: Este modelo nao permite a alteracao de uma linha") numa excecao
capturavel de verdade. A falha (com a Description REAL do framework) e empilhada em aFalhas em
vez de derrubar a thread -- quem chama decide se aborta a inclusao com base em Len(aFalhas).
@type Static Function
@param oMdl objeto, instancia de FWFormModel/FWModel ja carregada e ativada
@param aFalhas array, acumulador de mensagens de falha (passado por referencia implicita)
@param cGrid caractere, id do submodelo (ex.: 'CNCDETAIL')
@param cField caractere, nome do campo
@param xValue generico, valor a gravar
@return Nil
/*/
//=============================================================================================================================
Static Function ZcnTrySet(oMdl, aFalhas, cGrid, cField, xValue)

    Local bPrevErr := ErrorBlock({|e| Break(e)})
    Local oErr      := Nil

    Begin Sequence
        oMdl:SetValue(cGrid, cField, xValue)
    Recover Using oErr
        AAdd(aFalhas, cGrid + "." + cField + ": " + AllTrim(oErr:Description))
    End Sequence

    ErrorBlock(bPrevErr)

Return Nil

/*/{Protheus.doc} ZcnAtu
Atualiza SO os campos descritivos do header de um contrato JA EXISTENTE
(operacao "contratoAtualizar") -- Fase 5, tela unica de Cadastrais/Historico,
2026-08-11. Por design NAO mexe em CNCDETAIL/CNADETAIL/CNBDETAIL (pessoa,
planilhas, itens) -- alterar planilhas de um contrato existente continua
exigindo uma Revisao (ZcnRevAb/"Nova Revisao"), decisao tomada com o usuario
porque o CNTA300 nativo nunca confirmou permitir edicao direta de
planilha/item fora do fluxo de revisao (mesma cautela da saga do CNCDETAIL
mais abaixo neste arquivo). Todos os campos aqui sao os mesmos adicionados em
ZcnCriar (mesmas suposicoes de nome, exceto CN9_JUSTIF que e campo virtual
real).
@type Static Function
@param oReq JsonObject, {numero, revisao (opcional, usa CN9_REVATU se vazio), header:{justificativa,dtAssinatura,reajuste,indice,despesaFinanceira,objeto,clausula,natureza,centroCusto,responsavel}}
@return JsonObject, ver ZcnMont (ou {success:.F., message})
/*/
//=============================================================================================================================
Static Function ZcnAtu(oReq)

    Local oResp    := JsonObject():New()
    Local oModel   := Nil
    Local oHeader  := oReq["header"]
    Local cNumero  := ""
    Local cRevisao := ""
    Local cModelId := ""
    Local cTipo    := ""
    Local cMsg     := ""
    Local nTamNum  := 0
    Local nTamRev  := 0
    Local aFalhas  := {}
    Local aAvisos  := {}

    If ValType(oReq["numero"]) == "C" ; cNumero  := AllTrim(oReq["numero"])  ; EndIf
    If ValType(oReq["revisao"]) == "C" ; cRevisao := AllTrim(oReq["revisao"]) ; EndIf

    If Empty(cNumero) .Or. oHeader == Nil
        oResp["success"] := .F.
        oResp["message"] := "Numero do contrato e dados do cabecalho sao obrigatorios"
        Return oResp
    EndIf

    CN9->(dbSetOrder(1))
    nTamNum := Max(TamSX3("CN9_NUMERO")[1], Len(cNumero))

    If Empty(cRevisao) .And. CN9->(dbSeek(xFilial("CN9") + Padr(cNumero, nTamNum)))
        cRevisao := AllTrim(CN9->CN9_REVATU)
    EndIf
    nTamRev := Max(TamSX3("CN9_REVISA")[1], Len(cRevisao))

    If !CN9->(dbSeek(xFilial("CN9") + Padr(cNumero, nTamNum) + Padr(cRevisao, nTamRev)))
        oResp["success"] := .F.
        oResp["message"] := "Contrato [" + cNumero + "] revisao [" + cRevisao + "] nao encontrado."
        Return oResp
    EndIf

    cTipo    := IIf(AllTrim(CN9->CN9_ESPCTR) == "1", "C", "V")
    cModelId := IIf(cTipo == "C", "CNTA300", "CNTA301")

    Begin Sequence

    oModel := FWLoadModel(cModelId)
    oModel:SetOperation(MODEL_OPERATION_UPDATE)
    oModel:Activate()

    // Mesmo bloco de campos confirmados de ZcnCriar (ver as notas la) -- so os CONFIRMADOS
    // pelo usuario sao gravados; os que ainda nao foram confirmados (valorPresente/indice/
    // centroCusto/responsavel) continuam de fora, um nome errado aqui derruba a tela com
    // THREAD ERROR incapturavel (confirmado com CN9_REAJUS).
    If ValType(oHeader["justificativa"]) == "C"
        oModel:SetValue('CN9MASTER', 'CN9_JUSTIF', AllTrim(oHeader["justificativa"]))
    EndIf
    If ValType(oHeader["objeto"]) == "C"
        oModel:SetValue('CN9MASTER', 'CN9_OBJCTO', AllTrim(oHeader["objeto"]))
    EndIf
    If ValType(oHeader["clausula"]) == "C"
        oModel:SetValue('CN9MASTER', 'CN9_ALTCLA', AllTrim(oHeader["clausula"]))
    EndIf
    If ValType(oHeader["dtAssinatura"]) == "C" .And. !Empty(AllTrim(oHeader["dtAssinatura"]))
        oModel:SetValue('CN9MASTER', 'CN9_ASSINA', ZcnSToD(oHeader["dtAssinatura"]))
    EndIf
    If ValType(oHeader["valorInicial"]) == "N"
        oModel:SetValue('CN9MASTER', 'CN9_VLINI', oHeader["valorInicial"])
    EndIf
    If ValType(oHeader["valorAtual"]) == "N"
        oModel:SetValue('CN9MASTER', 'CN9_VLATU', oHeader["valorAtual"])
    EndIf
    If ValType(oHeader["despesaFinanceira"]) == "N"
        oModel:SetValue('CN9MASTER', 'CN9_VJUROS', oHeader["despesaFinanceira"])
    EndIf
    If ValType(oHeader["reajuste"]) == "C" .And. !Empty(AllTrim(oHeader["reajuste"]))
        oModel:SetValue('CN9MASTER', 'CN9_FLGREJ', AllTrim(oHeader["reajuste"]))
    EndIf
    ZcnPlaSet(oModel, aFalhas, aAvisos, "descCtr", 'CN9MASTER', oHeader["descricao"])
    If Len(aFalhas) > 0
        oModel:DeActivate()
        oResp["success"] := .F.
        oResp["message"] := "Falha ao preencher a descricao do contrato: " + aFalhas[1]
        Return oResp
    EndIf
    If ValType(oHeader["natureza"]) == "C" .And. !Empty(AllTrim(oHeader["natureza"]))
        oModel:SetValue('CN9MASTER', 'CN9_NATURE', AllTrim(oHeader["natureza"]))
    EndIf

    If oModel:VldData()
        oModel:CommitData()
        oModel:DeActivate()
        oResp := ZcnMont(cNumero, cRevisao)
        If Len(aAvisos) > 0
            oResp["avisos"] := aAvisos
        EndIf
    Else
        cMsg := AllTrim(oModel:GetErrorMessage()[3]) + " " + AllTrim(oModel:GetErrorMessage()[6])
        oModel:DeActivate()
        oResp["success"] := .F.
        oResp["message"] := AllTrim(cMsg)
    EndIf

    Recover Using oErrCatch
        oResp := JsonObject():New()
        oResp["success"] := .F.
        oResp["message"] := "Erro interno ao atualizar contrato: " + AllTrim(oErrCatch:description) +;
            IIf(ValType(oErrCatch:operation) == "C" .And. !Empty(oErrCatch:operation), " (" + AllTrim(oErrCatch:operation) + ")", "")
    End Sequence

Return oResp

/*/{Protheus.doc} ZcnSitOk
Diz se um codigo de situacao esta entre os 11 codigos padrao do CN9_SITUAC
(01..10 e "A"). Ver ZcnSitDesc para as descricoes.
@type Static Function
@param cCod caractere, codigo (ex: "05", "A")
@return logico
/*/
//=============================================================================================================================
Static Function ZcnSitOk(cCod)
Return AllTrim(cCod) $ "01/02/03/04/05/06/07/08/09/10/A"

/*/{Protheus.doc} ZcnSitPode
Matriz de transicoes de situacao permitidas -- decidida por ESTA rotina (nao
pelas travas nativas do CNTA300). E o espelho exato de TRANSICOES_SITUACAO
em POUI/rtm003/src/app/models/contrato.model.ts: qualquer mudanca aqui tem
que ser refletida la (e vice-versa), senao a tela oferece um botao que o
backend recusa (ou o contrario).
Regra: se cDe vier vazio (situacao atual desconhecida), libera -- nao da pra
validar o que nao se conhece.
@type Static Function
@param cDe   caractere, situacao atual (CN9_SITUAC)
@param cPara caractere, situacao pretendida
@return logico, .T. se a transicao cDe -> cPara e permitida
/*/
//=============================================================================================================================
Static Function ZcnSitPode(cDe, cPara)

    Local cD := AllTrim(cDe)
    Local cP := AllTrim(cPara)
    Local cLista := ""

    If Empty(cD)
        Return .T.
    EndIf

    Do Case
    Case cD == "01" ; cLista := ""                 // Cancelado -- terminal
    Case cD == "02" ; cLista := "03/01"            // Em Elaboracao
    Case cD == "03" ; cLista := "04/02/01"         // Emitido
    Case cD == "04" ; cLista := "05/02/01"         // Em Aprovacao
    Case cD == "05" ; cLista := "06/07/09"         // Vigente
    Case cD == "06" ; cLista := "05/07"            // Paralisado
    Case cD == "07" ; cLista := "08/05"            // Solicitacao de Finalizacao
    Case cD == "08" ; cLista := "05"               // Finalizado (reabertura)
    Case cD == "09" ; cLista := "10/A/05"          // Em Revisao
    Case cD == "10" ; cLista := "05"               // Revisado
    Case cD == "A"  ; cLista := "10/05"            // Revisao com Aprovacao por Alcadas
    OtherWise       ; cLista := ""
    EndCase

Return cP $ cLista

/*/{Protheus.doc} ZcnZlgPut
Grava UM evento na tabela ZLG (a mesma timeline que Contratos/RT69M003.prw
le e imprime). Feito manualmente porque ZcnSit deixou de chamar CN100Situac
(era ele quem disparava o PE CN100SIT.prw que gravava a ZLG). Cada replace e
protegido por FieldPos() -- se um campo nao existir no dicionario ZLG deste
ambiente, so e ignorado, sem derrubar a operacao (a mudanca de situacao em
si ja foi persistida antes desta chamada).
@type Static Function
@param cContra caractere, numero do contrato
@param cRevisa caractere, revisao
@param cAcao   caractere, codigo da acao (ex: "MUDANCA_SITUACAO")
@param cAntes  caractere, situacao anterior
@param cDepois caractere, situacao nova
@param cObs    caractere, observacao livre (opcional)
@return Nil
/*/
//=============================================================================================================================
Static Function ZcnZlgPut(cContra, cRevisa, cAcao, cAntes, cDepois, cObs)

    Local cUsr    := AllTrim(cUserName)
    Local cCodUsr := __cUserID
    Local oErr    := Nil

    Default cObs := ""

    // Toda a gravacao da timeline e "best effort": se a ZLG nao existir/mudar de layout
    // neste ambiente, a mudanca de situacao (ja commitada antes desta chamada) NAO pode
    // virar um thread error por causa disso.
    Begin Sequence

    If Select("ZLG") == 0
        ChkFile("ZLG")
    EndIf
    If Select("ZLG") == 0
        Break
    EndIf

    RecLock("ZLG", .T.)
        If ZLG->(FieldPos("ZLG_FILIAL")) > 0 ; ZLG->ZLG_FILIAL := xFilial("ZLG")           ; EndIf
        If ZLG->(FieldPos("ZLG_CONTRA")) > 0 ; ZLG->ZLG_CONTRA := cContra                   ; EndIf
        If ZLG->(FieldPos("ZLG_NUMERO")) > 0 ; ZLG->ZLG_NUMERO := cContra                   ; EndIf
        If ZLG->(FieldPos("ZLG_REVISA")) > 0 ; ZLG->ZLG_REVISA := cRevisa                   ; EndIf
        If ZLG->(FieldPos("ZLG_NUMMED")) > 0 ; ZLG->ZLG_NUMMED := ""                        ; EndIf
        If ZLG->(FieldPos("ZLG_DATA"))   > 0 ; ZLG->ZLG_DATA   := dDataBase                 ; EndIf
        If ZLG->(FieldPos("ZLG_HORA"))   > 0 ; ZLG->ZLG_HORA   := Left(Time(), 5)           ; EndIf
        If ZLG->(FieldPos("ZLG_ACAO"))   > 0 ; ZLG->ZLG_ACAO   := cAcao                     ; EndIf
        If ZLG->(FieldPos("ZLG_ORIGEM")) > 0 ; ZLG->ZLG_ORIGEM := "RTM003App"               ; EndIf
        If ZLG->(FieldPos("ZLG_ANTES"))  > 0 ; ZLG->ZLG_ANTES  := cAntes                    ; EndIf
        If ZLG->(FieldPos("ZLG_DEPOIS")) > 0 ; ZLG->ZLG_DEPOIS := cDepois                   ; EndIf
        If ZLG->(FieldPos("ZLG_USUARI")) > 0 ; ZLG->ZLG_USUARI := cCodUsr                   ; EndIf
        If ZLG->(FieldPos("ZLG_NOMEUS")) > 0 ; ZLG->ZLG_NOMEUS := cUsr                      ; EndIf
        If ZLG->(FieldPos("ZLG_OBS"))    > 0 ; ZLG->ZLG_OBS    := cObs                      ; EndIf
    ZLG->(MsUnlock())

    Recover Using oErr
        // ignora -- timeline e informativa, nao pode derrubar a mudanca de situacao
    End Sequence

Return Nil

/*/{Protheus.doc} ZcnSit
Muda a situacao de um contrato (operacao "contratoSituacao").
IMPORTANTE (pedido do usuario 2026-09-03): esta rotina NAO usa mais
CN100Situac. A rotina nativa do CNTA300 bloqueia mudar contrato fora de "Em
Elaboracao" e trava o fluxo de revisao/aditivo (FWFormGridModel "este modelo
nao permite alteracao de linha") -- foi por isso que a tela padrao "nao
atende". Aqui a transicao e validada contra a matriz PROPRIA desta tela
(ZcnSitPode, espelho de TRANSICOES_SITUACAO no contrato.model.ts) e o
CN9_SITUAC e gravado direto via RecLock/Replace, sem as travas nativas.
Como CN100Situac deixou de rodar, o evento da timeline (ZLG) e gravado aqui
mesmo por ZcnZlgPut -- a mesma ZLG que Contratos/RT69M003.prw le.
@type Static Function
@param oReq JsonObject, {numero, revisao (opcional, usa CN9_REVATU se vazio), novaSituacao, observacao (opcional)}
@return JsonObject, ver ZcnMont (ou {success:.F., message})
/*/
//=============================================================================================================================
Static Function ZcnSit(oReq)

    Local oResp    := JsonObject():New()
    Local cNumero  := ""
    Local cRevisao := ""
    Local cSituac  := ""
    Local cObs     := ""
    Local cAtual   := ""
    Local nTamNum  := 0
    Local nTamRev  := 0

    If ValType(oReq["numero"]) == "C" ; cNumero  := AllTrim(oReq["numero"])  ; EndIf
    If ValType(oReq["revisao"]) == "C" ; cRevisao := AllTrim(oReq["revisao"]) ; EndIf
    If ValType(oReq["novaSituacao"]) == "C" ; cSituac := AllTrim(oReq["novaSituacao"]) ; EndIf
    If ValType(oReq["observacao"]) == "C" ; cObs := AllTrim(oReq["observacao"]) ; EndIf

    If Empty(cNumero) .Or. Empty(cSituac)
        oResp["success"] := .F.
        oResp["message"] := "Numero do contrato e nova situacao sao obrigatorios"
        Return oResp
    EndIf

    If !ZcnSitOk(cSituac)
        oResp["success"] := .F.
        oResp["message"] := "Situacao [" + cSituac + "] nao e um codigo valido de CN9_SITUAC (01..10, A)."
        Return oResp
    EndIf

    CN9->(dbSetOrder(1))
    nTamNum := Max(TamSX3("CN9_NUMERO")[1], Len(cNumero))

    If Empty(cRevisao) .And. CN9->(dbSeek(xFilial("CN9") + Padr(cNumero, nTamNum)))
        cRevisao := AllTrim(CN9->CN9_REVATU)
    EndIf
    nTamRev := Max(TamSX3("CN9_REVISA")[1], Len(cRevisao))

    If !CN9->(dbSeek(xFilial("CN9") + Padr(cNumero, nTamNum) + Padr(cRevisao, nTamRev)))
        oResp["success"] := .F.
        oResp["message"] := "Contrato [" + cNumero + "] revisao [" + cRevisao + "] nao encontrado."
        Return oResp
    EndIf

    cAtual := AllTrim(CN9->CN9_SITUAC)

    If cAtual == cSituac
        oResp["success"] := .F.
        oResp["message"] := "O contrato ja esta na situacao [" + ZcnSitDesc(cSituac) + "]."
        Return oResp
    EndIf

    If !ZcnSitPode(cAtual, cSituac)
        oResp["success"] := .F.
        oResp["message"] := "Transicao de situacao nao permitida: " + ZcnSitDesc(cAtual) + " -> " + ZcnSitDesc(cSituac) + "."
        Return oResp
    EndIf

    // Gravacao direta do CN9_SITUAC (sem CN100Situac / travas nativas)
    RecLock("CN9", .F.)
        CN9->CN9_SITUAC := cSituac
    CN9->(MsUnlock())

    // Timeline (ZLG) -- gravada aqui porque CN100Situac (que disparava o PE
    // CN100SIT) nao roda mais neste fluxo
    ZcnZlgPut(cNumero, cRevisao, "MUDANCA_SITUACAO", cAtual, cSituac, cObs)

    oResp := ZcnMont(cNumero, cRevisao)

Return oResp

/*/{Protheus.doc} ZcnTL
Le a timeline (tabela ZLG) de um contrato -- TODAS as revisoes, em ordem
cronologica -- e devolve para a aba "Linha do Tempo" da tela. Mesma consulta
de Contratos/RT69M003.prw::BuscaZLG (o relatorio PDF do historico), so que
como JSON em vez de PDF. Os codigos tecnicos de ZLG_ACAO/ZLG_ORIGEM sao
traduzidos aqui (ZcnAcaoDesc/ZcnOrigDesc), e ZLG_ANTES/ZLG_DEPOIS via
ZcnSitDesc, para o Angular so exibir.
@type Static Function
@param oReq JsonObject, {numero}
@return JsonObject, {success, eventos:[{data,hora,acao,acaoLabel,revisao,numMed,origem,origemLabel,antes,antesLabel,depois,depoisLabel,usuario,nomeUsuario,obs}]}
/*/
//=============================================================================================================================
Static Function ZcnTL(oReq)

    Local oResp   := JsonObject():New()
    Local aEv     := {}
    Local cNumero := ""
    Local cAlias  := ""
    Local cQuery  := ""
    Local oEv     := Nil
    Local oErr    := Nil

    If ValType(oReq["numero"]) == "C" ; cNumero := AllTrim(oReq["numero"]) ; EndIf

    If Empty(cNumero)
        oResp["success"] := .F.
        oResp["message"] := "Numero do contrato e obrigatorio"
        Return oResp
    EndIf

    // Leitura da timeline e "best effort": qualquer problema com a ZLG neste ambiente
    // devolve uma lista vazia, nunca um thread error (a aba e so informativa).
    oResp["success"] := .T.
    oResp["eventos"] := {}

    Begin Sequence

    If Select("ZLG") == 0
        ChkFile("ZLG")
    EndIf
    If Select("ZLG") == 0
        Break
    EndIf

    cAlias := GetNextAlias()
    cQuery := " SELECT ZLG_DATA, ZLG_HORA, ZLG_REVISA, ZLG_NUMMED, ZLG_ACAO, ZLG_ORIGEM, "
    cQuery += "        ZLG_ANTES, ZLG_DEPOIS, ZLG_USUARI, ZLG_NOMEUS, ZLG_OBS "
    cQuery += " FROM " + RetSqlName("ZLG") + " ZLG "
    cQuery += " WHERE ZLG.D_E_L_E_T_ = ' ' "
    cQuery += "   AND ZLG_FILIAL = '" + FWxFilial("ZLG") + "' "
    cQuery += "   AND ZLG_CONTRA = '" + cNumero + "' "
    cQuery += " ORDER BY ZLG_DATA ASC, ZLG_HORA ASC "
    cQuery := ChangeQuery(cQuery)

    dbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAlias, .F., .T.)

    While !(cAlias)->(Eof())
        oEv := JsonObject():New()
        oEv["data"]         := ZcnDateStr((cAlias)->ZLG_DATA)
        oEv["hora"]         := AllTrim((cAlias)->ZLG_HORA)
        oEv["acao"]         := AllTrim((cAlias)->ZLG_ACAO)
        oEv["acaoLabel"]    := ZcnAcaoDesc(AllTrim((cAlias)->ZLG_ACAO))
        oEv["revisao"]      := AllTrim((cAlias)->ZLG_REVISA)
        oEv["numMed"]       := AllTrim((cAlias)->ZLG_NUMMED)
        oEv["origem"]       := AllTrim((cAlias)->ZLG_ORIGEM)
        oEv["origemLabel"]  := ZcnOrigDesc(AllTrim((cAlias)->ZLG_ORIGEM))
        oEv["antes"]        := AllTrim((cAlias)->ZLG_ANTES)
        oEv["antesLabel"]   := IIf(Empty(AllTrim((cAlias)->ZLG_ANTES)), "", ZcnSitDesc(AllTrim((cAlias)->ZLG_ANTES)))
        oEv["depois"]       := AllTrim((cAlias)->ZLG_DEPOIS)
        oEv["depoisLabel"]  := IIf(Empty(AllTrim((cAlias)->ZLG_DEPOIS)), "", ZcnSitDesc(AllTrim((cAlias)->ZLG_DEPOIS)))
        oEv["usuario"]      := AllTrim((cAlias)->ZLG_USUARI)
        oEv["nomeUsuario"]  := AllTrim((cAlias)->ZLG_NOMEUS)
        oEv["obs"]          := AllTrim((cAlias)->ZLG_OBS)
        AAdd(aEv, oEv)
        (cAlias)->(dbSkip())
    EndDo
    (cAlias)->(dbCloseArea())

    oResp["eventos"] := aEv

    Recover Using oErr
        If !Empty(cAlias) .And. Select(cAlias) > 0
            (cAlias)->(dbCloseArea())
        EndIf
    End Sequence

Return oResp

/*/{Protheus.doc} ZcnDateStr
Converte ZLG_DATA (ou qualquer campo data-ish) para "AAAA-MM-DD". O TOPCONN
as vezes devolve o campo como caractere "AAAAMMDD" em vez de Data. Aceita os
dois -- mesma cautela de RT69M003.prw::FmtData / rtm002 DateStr.
@type Static Function
@param xData Data ou caractere
@return caractere "AAAA-MM-DD" (ou "")
/*/
//=============================================================================================================================
Static Function ZcnDateStr(xData)
    Local cRet := ""
    Do Case
    Case ValType(xData) == "D" .And. !Empty(xData)
        cRet := SubStr(DToS(xData), 1, 4) + "-" + SubStr(DToS(xData), 5, 2) + "-" + SubStr(DToS(xData), 7, 2)
    Case ValType(xData) == "C" .And. Len(AllTrim(xData)) >= 8
        cRet := SubStr(AllTrim(xData), 1, 4) + "-" + SubStr(AllTrim(xData), 5, 2) + "-" + SubStr(AllTrim(xData), 7, 2)
    EndCase
Return cRet

/*/{Protheus.doc} ZcnAcaoDesc
Traduz ZLG_ACAO para um titulo curto em portugues -- mini-porte de
RT69M003.prw::DescAcaoTitulo (Static Function nao e compartilhavel entre
.prw, entao a tabela e repetida).
@type Static Function
@param cAcao caractere
@return caractere
/*/
//=============================================================================================================================
Static Function ZcnAcaoDesc(cAcao)
    Local cRet := cAcao
    Do Case
    Case cAcao == "INCLUSAO"             ; cRet := "Contrato incluido"
    Case cAcao == "ALTERACAO"            ; cRet := "Contrato alterado"
    Case cAcao == "EXCLUSAO"             ; cRet := "Contrato excluido"
    Case cAcao == "MUDANCA_SITUACAO"     ; cRet := "Situacao do contrato alterada"
    Case cAcao == "TITULO_GERADO"        ; cRet := "Titulo financeiro gerado"
    Case cAcao == "MEDICAO_INCLUSAO"     ; cRet := "Medicao incluida"
    Case cAcao == "MEDICAO_ALTERACAO"    ; cRet := "Medicao alterada"
    Case cAcao == "MEDICAO_EXCLUSAO"     ; cRet := "Medicao excluida"
    Case cAcao == "MEDICAO_ESTORNO"      ; cRet := "Medicao estornada"
    Case cAcao == "PEDIDO_COMPRA_GERADO" ; cRet := "Pedido de compra gerado"
    EndCase
Return cRet

/*/{Protheus.doc} ZcnOrigDesc
Traduz ZLG_ORIGEM (ponto de entrada/rotina de origem) para o nome de
negocio -- mini-porte de RT69M003.prw::OrigemDesc.
@type Static Function
@param cOrigem caractere
@return caractere
/*/
//=============================================================================================================================
Static Function ZcnOrigDesc(cOrigem)
    Local cRet := cOrigem
    Do Case
    Case cOrigem == "RTM003App"          ; cRet := "Cadastro de Contratos (tela nova)"
    Case cOrigem == "CN300PCMT"          ; cRet := "Cadastro/Manutencao de Contratos"
    Case cOrigem == "CN100SIT"           ; cRet := "Alteracao de Situacao do Contrato"
    Case "ESTORN" $ Upper(cOrigem)       ; cRet := "Estorno de Medicao"
    Case Left(cOrigem, 7) == "CNTA121"   ; cRet := "Medicao de Contratos"
    Case cOrigem == "CN121PED"           ; cRet := "Geracao de Pedido de Compra"
    Case cOrigem == "CNTPRSE2"           ; cRet := "Geracao de Titulo a Pagar (Financeiro)"
    EndCase
Return cRet

/*/{Protheus.doc} ZcnRevAb
Abre uma revisao (operacao "revisaoAbrir") -- A300STpRev + FWLoadModel +
SetOperation(INSERT) + Activate(.T.) + SetValue CN9_TIPREV/CN9_JUSTIF,
replicando os exemplos de revisao do GCT0109.
Comportamento generico desta fase (consistente com a tela unica de revisao
ja aprovada para todos os 16 tipos): se "planilhas" vier preenchido, cada
elemento entra como UMA planilha nova na revisao (mesmo padrao do exemplo
"Revisao de aditivo", agora podendo ser mais de uma -- mesmo formato de
payload de ZcnCriar). Regras especificas por tipo (ex: CN300RdSld no
realinhamento, CN9_MOTPAR/CN9_DTFIMP na paralisacao) ainda nao foram
implementadas -- ficam para um proximo incremento.
@type Static Function
@param oReq JsonObject, {numero, revisaoBase (opcional), tipoRevisao, justificativa, planilhas:[{tipoPlanilha,itens:[...]}] (opcional)}
@return JsonObject, ver ZcnMont (ou {success:.F., message})
/*/
//=============================================================================================================================
Static Function ZcnRevAb(oReq)

    Local oResp         := JsonObject():New()
    Local oModel         := Nil
    Local oModelCNA       := Nil
    Local oModelCNB        := Nil
    Local aPlanilhas         := oReq["planilhas"]
    Local aItens              := {}
    Local cNumero              := ""
    Local cRevisaoBase          := ""
    Local cTipoRevisao           := ""
    Local cJustific               := ""
    Local cModelId                 := ""
    Local cTipo                     := ""
    Local cNovaRevisao                := ""
    Local cMsg                         := ""
    Local nP                            := 0
    Local nI                             := 0
    Local oPla                            := Nil
    Local oItm                             := Nil
    Local nTamNum                           := 0
    Local nTamRev                            := 0
    Local oErrCatch                          := Nil
    Local dDtIniPla                          := CToD("")

    If ValType(oReq["numero"]) == "C" ; cNumero := AllTrim(oReq["numero"]) ; EndIf
    If ValType(oReq["revisaoBase"]) == "C" ; cRevisaoBase := AllTrim(oReq["revisaoBase"]) ; EndIf
    If ValType(oReq["tipoRevisao"]) == "C" ; cTipoRevisao := AllTrim(oReq["tipoRevisao"]) ; EndIf
    If ValType(oReq["justificativa"]) == "C" ; cJustific := AllTrim(oReq["justificativa"]) ; EndIf
    If ValType(aPlanilhas) != "A" ; aPlanilhas := {} ; EndIf

    If Empty(cNumero) .Or. Empty(cTipoRevisao) .Or. Empty(cJustific)
        oResp["success"] := .F.
        oResp["message"] := "Numero do contrato, tipo de revisao e justificativa sao obrigatorios"
        Return oResp
    EndIf

    CN9->(dbSetOrder(1))
    nTamNum := Max(TamSX3("CN9_NUMERO")[1], Len(cNumero))

    If Empty(cRevisaoBase) .And. CN9->(dbSeek(xFilial("CN9") + Padr(cNumero, nTamNum)))
        cRevisaoBase := AllTrim(CN9->CN9_REVATU)
    EndIf
    nTamRev := Max(TamSX3("CN9_REVISA")[1], Len(cRevisaoBase))

    If !CN9->(dbSeek(xFilial("CN9") + Padr(cNumero, nTamNum) + Padr(cRevisaoBase, nTamRev)))
        oResp["success"] := .F.
        oResp["message"] := "Contrato [" + cNumero + "] revisao [" + cRevisaoBase + "] nao encontrado."
        Return oResp
    EndIf

    cTipo    := IIf(AllTrim(CN9->CN9_ESPCTR) == "1", "C", "V")
    cModelId := IIf(cTipo == "C", "CNTA300", "CNTA301")

    A300STpRev(cTipoRevisao)

    // Mesmo motivo do Begin Sequence em ZcnCriar: manipulacao de modelo MVC ja quebrou com
    // erro de runtime do proprio framework nesta sessao -- converte pra JSON de erro comum em
    // vez de THREAD ERROR.
    Begin Sequence

    oModel := FWLoadModel(cModelId)
    oModel:SetOperation(MODEL_OPERATION_INSERT)
    oModel:Activate(.T.)

    oModel:SetValue('CN9MASTER', 'CN9_TIPREV', cTipoRevisao)
    oModel:SetValue('CN9MASTER', 'CN9_JUSTIF', cJustific)

    If Len(aPlanilhas) > 0
        oModelCNA := oModel:GetModel('CNADETAIL')
        oModelCNB := oModel:GetModel('CNBDETAIL')

        For nP := 1 To Len(aPlanilhas)
            oPla := aPlanilhas[nP]

            oModelCNA:AddLine()
            // Forma dispatcher (oModel:SetValue('CNADETAIL', campo, valor)), nao mais direto no
            // submodelo -- mesma correcao de ZcnCriar, baseada no exemplo oficial completo que
            // o usuario conseguiu (2026-08-11): CNADETAIL/CNBDETAIL nunca sao editados via
            // objeto de submodelo direto em nenhum exemplo real, sempre via oModel:SetValue com
            // o id do submodelo como parametro. CNA_CONTRA via LoadValue (unico campo assim).
            oModel:LoadValue('CNADETAIL', 'CNA_CONTRA', cNumero)
            oModel:SetValue('CNADETAIL', 'CNA_NUMERO', StrZero(oModelCNA:GetLine(), Len(CNA->CNA_NUMERO)))
            oModel:SetValue('CNADETAIL', 'CNA_TIPPLA', AllTrim(oPla["tipoPlanilha"]))
            // Pessoa por planilha (Fase 5, mesma mudanca de ZcnCriar) -- se a planilha da
            // revisao trouxer "pessoa" no payload, usa ela; senao (compatibilidade com
            // revisao-form, que ainda nao manda esse campo) cai de volta pro cliente/fornecedor
            // ja gravado em CNCDETAIL, igual o comportamento de antes.
            If oPla["pessoa"] != Nil .And. !Empty(AllTrim(oPla["pessoa"]["codigo"]))
                If cTipo == "C"
                    oModel:SetValue('CNADETAIL', 'CNA_FORNEC', AllTrim(oPla["pessoa"]["codigo"]))
                    oModel:SetValue('CNADETAIL', 'CNA_LJFORN', AllTrim(oPla["pessoa"]["loja"]))
                Else
                    oModel:SetValue('CNADETAIL', 'CNA_CLIENT', AllTrim(oPla["pessoa"]["codigo"]))
                    oModel:SetValue('CNADETAIL', 'CNA_LOJACL', AllTrim(oPla["pessoa"]["loja"]))
                EndIf
            Else
                If cTipo == "C"
                    oModel:SetValue('CNADETAIL', 'CNA_FORNEC', oModel:GetValue('CNCDETAIL', 'CNC_CODIGO'))
                    oModel:SetValue('CNADETAIL', 'CNA_LJFORN', oModel:GetValue('CNCDETAIL', 'CNC_LOJA'))
                Else
                    oModel:SetValue('CNADETAIL', 'CNA_CLIENT', oModel:GetValue('CNCDETAIL', 'CNC_CLIENT'))
                    oModel:SetValue('CNADETAIL', 'CNA_LOJACL', oModel:GetValue('CNCDETAIL', 'CNC_LOJACL'))
                EndIf
            EndIf
            // CNA_DTINI (obrigatorio no modelo) -- mesma logica de ZcnCriar: prioriza a Data
            // base da planilha (pedido do usuario), depois a data de inicio da propria planilha
            // e, por fim (revisao-form ainda nao manda nenhum dos dois), a data de inicio ja
            // gravada no contrato base (CN9_DTINIC, lida do proprio modelo ja ativo).
            dDtIniPla := CToD("")
            If ValType(oPla["dataBase"]) == "C" .And. !Empty(AllTrim(oPla["dataBase"]))
                dDtIniPla := ZcnSToD(oPla["dataBase"])
            ElseIf ValType(oPla["dataInicio"]) == "C" .And. !Empty(AllTrim(oPla["dataInicio"]))
                dDtIniPla := ZcnSToD(oPla["dataInicio"])
            Else
                dDtIniPla := oModel:GetValue('CN9MASTER', 'CN9_DTINIC')
            EndIf
            If !Empty(dDtIniPla)
                oModel:SetValue('CNADETAIL', 'CNA_DTINI', dDtIniPla)
            EndIf
            If ValType(oPla["dataFim"]) == "C" .And. !Empty(AllTrim(oPla["dataFim"]))
                oModel:SetValue('CNADETAIL', 'CNA_DTFIM', ZcnSToD(oPla["dataFim"]))
            EndIf

            aItens := oPla["itens"]
            If ValType(aItens) != "A" ; aItens := {} ; EndIf
            For nI := 1 To Len(aItens)
                oItm := aItens[nI]
                // Length() < nI (nao "nI > 1") -- mesma cautela do fix de CNCDETAIL em
                // ZcnCriar: a linha 1 desta planilha (recem-criada por AddLine acima) pode nao
                // vir pronta para edicao, confere antes de assumir.
                If oModelCNB:Length() < nI
                    oModelCNB:AddLine()
                EndIf
                // Forma dispatcher, mesmo motivo do CNADETAIL acima.
                oModel:SetValue('CNBDETAIL', 'CNB_ITEM'  , StrZero(nI, Len(CNB->CNB_ITEM)))
                oModel:SetValue('CNBDETAIL', 'CNB_PRODUT', AllTrim(oItm["produto"]))
                oModel:SetValue('CNBDETAIL', 'CNB_QUANT' , oItm["quantidade"])
                oModel:SetValue('CNBDETAIL', 'CNB_VLUNIT', oItm["valorUnitario"])
                // Mesma ressalva de ZcnCriar sobre CNB_CC/CNB_PERDES serem suposicoes.
                If ValType(oItm["tes"]) == "C" .And. !Empty(AllTrim(oItm["tes"]))
                    oModel:SetValue('CNBDETAIL', 'CNB_TS', AllTrim(oItm["tes"]))
                EndIf
                If ValType(oItm["cc"]) == "C" .And. !Empty(AllTrim(oItm["cc"]))
                    oModel:SetValue('CNBDETAIL', 'CNB_CC', AllTrim(oItm["cc"]))
                EndIf
                If ValType(oItm["pedTit"]) == "C" .And. !Empty(AllTrim(oItm["pedTit"]))
                    oModel:SetValue('CNBDETAIL', 'CNB_PEDTIT', AllTrim(oItm["pedTit"]))
                EndIf
                If ValType(oItm["desconto"]) == "N" .And. oItm["desconto"] > 0
                    oModel:SetValue('CNBDETAIL', 'CNB_PERDES', oItm["desconto"])
                EndIf
            Next nI
        Next nP
    EndIf

    If oModel:VldData()
        oModel:CommitData()
        cNovaRevisao := AllTrim(oModel:GetValue('CN9MASTER', 'CN9_REVISA'))
        oModel:DeActivate()
        oResp := ZcnMont(cNumero, cNovaRevisao)
    Else
        cMsg := AllTrim(oModel:GetErrorMessage()[3]) + " " + AllTrim(oModel:GetErrorMessage()[6])
        oModel:DeActivate()
        oResp["success"] := .F.
        oResp["message"] := AllTrim(cMsg)
    EndIf

    Recover Using oErrCatch
        oResp := JsonObject():New()
        oResp["success"] := .F.
        oResp["message"] := "Erro interno ao abrir revisao: " + AllTrim(oErrCatch:description) +;
            IIf(ValType(oErrCatch:operation) == "C" .And. !Empty(oErrCatch:operation), " (" + AllTrim(oErrCatch:operation) + ")", "")
    End Sequence

Return oResp

/*/{Protheus.doc} ZcnAprov
Aprova a revisao posicionada (operacao "revisaoAprovar") -- wrapper de
CN300Aprov, replica o exemplo "Aprovacao de revisao (sem alcadas)" do
GCT0109.
@type Static Function
@param oReq JsonObject, {numero, revisao (opcional, usa CN9_REVATU se vazio)}
@return JsonObject, ver ZcnMont (ou {success:.F., message})
/*/
//=============================================================================================================================
Static Function ZcnAprov(oReq)

    Local oResp    := JsonObject():New()
    Local cNumero  := ""
    Local cRevisao := ""
    Local cMsgErro := ""
    Local nRet     := 0
    Local nTamNum  := 0
    Local nTamRev  := 0

    If ValType(oReq["numero"]) == "C" ; cNumero  := AllTrim(oReq["numero"])  ; EndIf
    If ValType(oReq["revisao"]) == "C" ; cRevisao := AllTrim(oReq["revisao"]) ; EndIf

    If Empty(cNumero)
        oResp["success"] := .F.
        oResp["message"] := "Numero do contrato nao informado"
        Return oResp
    EndIf

    CN9->(dbSetOrder(1))
    nTamNum := Max(TamSX3("CN9_NUMERO")[1], Len(cNumero))

    If Empty(cRevisao) .And. CN9->(dbSeek(xFilial("CN9") + Padr(cNumero, nTamNum)))
        cRevisao := AllTrim(CN9->CN9_REVATU)
    EndIf
    nTamRev := Max(TamSX3("CN9_REVISA")[1], Len(cRevisao))

    If !CN9->(dbSeek(xFilial("CN9") + Padr(cNumero, nTamNum) + Padr(cRevisao, nTamRev)))
        oResp["success"] := .F.
        oResp["message"] := "Contrato [" + cNumero + "] revisao [" + cRevisao + "] nao encontrado."
        Return oResp
    EndIf

    nRet := CN300Aprov(.T.,, @cMsgErro)

    If nRet == 1
        oResp := ZcnMont(cNumero, cRevisao)
    Else
        oResp["success"] := .F.
        oResp["message"] := IIf(Empty(cMsgErro), "Falha ao aprovar a revisao", cMsgErro)
    EndIf

Return oResp

/*/{Protheus.doc} ZcnGrCrg
Gera o cronograma financeiro/fisico de um contrato+revisao existente
(operacao "gerarCronograma") -- replica o exemplo oficial do GCT0109:
SetMVValue dos parametros do Pergunte "CN300CRG" + Pergunte(,.F.) (nao
exibe a tela, roda com os valores ja setados) + CN300PrCF(.T.), com o
modelo do contrato ativo em modo atualizacao. Mesmo botao "Incluir
Cronograma Financeiro/Fisico" da tela nativa do CNTA300.
Parametros do Pergunte "CN300CRG" (ordem oficial do GCT0109):
MV_PAR01=periodicidade(1=Mensal,2=Quinzenal,3=Diario,4=Cond.Pagto),
MV_PAR02=dias, MV_PAR03=ultimoDiaMes(1=Sim,2=Nao),
MV_PAR04=competenciaInicio("MM/AAAA"), MV_PAR05=dataPrevista(1a medicao),
MV_PAR06=qtdParcelas, MV_PAR07=condPagto, MV_PAR08=taxaJuros.
@type Static Function
@param oReq JsonObject, {numero, revisao, periodicidade, dias, ultimoDiaMes, competenciaInicio, dataPrevista, qtdParcelas, condPagto, taxaJuros}
@return JsonObject, ver ZcnMont (ou {success:.F., message})
/*/
//=============================================================================================================================
Static Function ZcnGrCrg(oReq)

    Local oResp     := JsonObject():New()
    Local oModel     := Nil
    Local cNumero     := ""
    Local cRevisao     := ""
    Local cModelId       := ""
    Local cTipo           := ""
    Local cMsg              := ""
    Local nTamNum             := 0
    Local nTamRev              := 0
    Local oErrCatch             := Nil

    If ValType(oReq["numero"]) == "C" ; cNumero  := AllTrim(oReq["numero"])  ; EndIf
    If ValType(oReq["revisao"]) == "C" ; cRevisao := AllTrim(oReq["revisao"]) ; EndIf

    If Empty(cNumero)
        oResp["success"] := .F.
        oResp["message"] := "Numero do contrato nao informado"
        Return oResp
    EndIf

    CN9->(dbSetOrder(1))
    nTamNum := Max(TamSX3("CN9_NUMERO")[1], Len(cNumero))

    If Empty(cRevisao) .And. CN9->(dbSeek(xFilial("CN9") + Padr(cNumero, nTamNum)))
        cRevisao := AllTrim(CN9->CN9_REVATU)
    EndIf
    nTamRev := Max(TamSX3("CN9_REVISA")[1], Len(cRevisao))

    If !CN9->(dbSeek(xFilial("CN9") + Padr(cNumero, nTamNum) + Padr(cRevisao, nTamRev)))
        oResp["success"] := .F.
        oResp["message"] := "Contrato [" + cNumero + "] revisao [" + cRevisao + "] nao encontrado."
        Return oResp
    EndIf

    cTipo    := IIf(AllTrim(CN9->CN9_ESPCTR) == "1", "C", "V")
    cModelId := IIf(cTipo == "C", "CNTA300", "CNTA301")

    // Begin Sequence/Recover Using -- mesmo motivo de ZcnCriar/ZcnRevAb: CN300PrCF e funcao
    // nativa do modulo (nao minha), qualquer comportamento inesperado aqui vira JSON de erro
    // em vez de THREAD ERROR.
    Begin Sequence

    oModel := FWLoadModel(cModelId)
    oModel:SetOperation(MODEL_OPERATION_UPDATE)
    oModel:Activate()

    SetMVValue("CN300CRG", "MV_PAR01", oReq["periodicidade"])
    SetMVValue("CN300CRG", "MV_PAR02", oReq["dias"])
    SetMVValue("CN300CRG", "MV_PAR03", oReq["ultimoDiaMes"])
    SetMVValue("CN300CRG", "MV_PAR04", AllTrim(oReq["competenciaInicio"]))
    SetMVValue("CN300CRG", "MV_PAR05", ZcnSToD(oReq["dataPrevista"]))
    SetMVValue("CN300CRG", "MV_PAR06", oReq["qtdParcelas"])
    SetMVValue("CN300CRG", "MV_PAR07", AllTrim(oReq["condPagto"]))
    SetMVValue("CN300CRG", "MV_PAR08", oReq["taxaJuros"])
    Pergunte("CN300CRG", .F.)

    CN300PrCF(.T.)

    If oModel:VldData()
        oModel:CommitData()
        oModel:DeActivate()
        oResp := ZcnMont(cNumero, cRevisao)
    Else
        cMsg := AllTrim(oModel:GetErrorMessage()[3]) + " " + AllTrim(oModel:GetErrorMessage()[6])
        oModel:DeActivate()
        oResp["success"] := .F.
        oResp["message"] := AllTrim(cMsg)
    EndIf

    Recover Using oErrCatch
        oResp := JsonObject():New()
        oResp["success"] := .F.
        oResp["message"] := "Erro interno ao gerar cronograma: " + AllTrim(oErrCatch:description) +;
            IIf(ValType(oErrCatch:operation) == "C" .And. !Empty(oErrCatch:operation), " (" + AllTrim(oErrCatch:operation) + ")", "")
    End Sequence

Return oResp

/*/{Protheus.doc} ZcnPess
Lookup de cliente/fornecedor (operacao "lookupPessoa") -- consulta SA2
(compra) ou SA1 (venda) por codigo/nome, mesmo estilo de
RTM002App.prw::LstTES (limite de 20 linhas, sem paginacao real nesta fase).
@type Static Function
@param oReq JsonObject, {tipo ('C'/'V'), filtro}
@return JsonObject, {success, items:[{codigo,loja,nome}]}
/*/
//=============================================================================================================================
Static Function ZcnPess(oReq)

    Local oResp   := JsonObject():New()
    Local aItens  := {}
    Local oItem   := Nil
    Local cAliasQ := GetNextAlias()
    Local cTipo   := ""
    Local cFiltro := ""
    Local cLike   := ""
    Local nCount  := 0

    If ValType(oReq["tipo"]) == "C" ; cTipo   := AllTrim(oReq["tipo"])   ; EndIf
    If ValType(oReq["filtro"]) == "C" ; cFiltro := AllTrim(oReq["filtro"]) ; EndIf
    cLike := "%'%" + cFiltro + "%'%"

    If cTipo == "C"
        BeginSql Alias cAliasQ
            SELECT A2_COD AS CODIGO, A2_LOJA AS LOJA, A2_NOME AS NOME
              FROM %table:SA2% SA2
             WHERE SA2.%notDel%
               AND SA2.A2_FILIAL = %xfilial:SA2%
               AND (SA2.A2_COD LIKE %exp:cLike% OR SA2.A2_NOME LIKE %exp:cLike%)
             ORDER BY SA2.A2_NOME
        EndSql
    Else
        BeginSql Alias cAliasQ
            SELECT A1_COD AS CODIGO, A1_LOJA AS LOJA, A1_NOME AS NOME
              FROM %table:SA1% SA1
             WHERE SA1.%notDel%
               AND SA1.A1_FILIAL = %xfilial:SA1%
               AND (SA1.A1_COD LIKE %exp:cLike% OR SA1.A1_NOME LIKE %exp:cLike%)
             ORDER BY SA1.A1_NOME
        EndSql
    EndIf

    While (cAliasQ)->(!Eof()) .And. nCount < 20
        oItem := JsonObject():New()
        oItem["codigo"] := AllTrim((cAliasQ)->CODIGO)
        oItem["loja"]   := AllTrim((cAliasQ)->LOJA)
        oItem["nome"]   := AllTrim((cAliasQ)->NOME)
        aAdd(aItens, oItem)
        nCount++
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

    oResp["success"] := .T.
    oResp["items"]   := aItens
    oResp["hasNext"] := .F.

Return oResp

/*/{Protheus.doc} ZcnTpCt
Lookup de Tipo de Contrato (operacao "lookupTipoContrato") -- consulta CN1
por codigo/descricao. Cada item ja vem com "tipo" ('C'/'V') derivado de
CN1_ESPCTR (mesma convencao de CN9_ESPCTR: "1"=Compra, "2"=Venda) -- e assim
que o Angular decide, so de olhar pra qual Tipo de Contrato foi escolhido,
se deve abrir a busca de Cliente ou de Fornecedor (pedido do usuario
2026-08-10, apos ver que CN1 ja carrega essa informacao).
@type Static Function
@param oReq JsonObject, {filtro}
@return JsonObject, {success, items:[{codigo,descricao,tipo}]}
/*/
//=============================================================================================================================
Static Function ZcnTpCt(oReq)

    Local oResp   := JsonObject():New()
    Local aItens  := {}
    Local oItem   := Nil
    Local cAliasQ := GetNextAlias()
    Local cFiltro := ""
    Local cLike   := ""
    Local nCount  := 0

    If ValType(oReq["filtro"]) == "C" ; cFiltro := AllTrim(oReq["filtro"]) ; EndIf
    cLike := "%'%" + cFiltro + "%'%"

    BeginSql Alias cAliasQ
        SELECT CN1_CODIGO AS CODIGO, CN1_DESCRI AS DESCRI, CN1_ESPCTR AS ESPCTR
          FROM %table:CN1% CN1
         WHERE CN1.%notDel%
           AND CN1.CN1_FILIAL = %xfilial:CN1%
           AND (CN1.CN1_CODIGO LIKE %exp:cLike% OR CN1.CN1_DESCRI LIKE %exp:cLike%)
         ORDER BY CN1.CN1_DESCRI
    EndSql

    While (cAliasQ)->(!Eof()) .And. nCount < 20
        oItem := JsonObject():New()
        oItem["codigo"]    := AllTrim((cAliasQ)->CODIGO)
        oItem["descricao"] := AllTrim((cAliasQ)->DESCRI)
        oItem["tipo"]      := IIf(AllTrim((cAliasQ)->ESPCTR) == "1", "C", "V")
        aAdd(aItens, oItem)
        nCount++
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

    oResp["success"] := .T.
    oResp["items"]   := aItens
    oResp["hasNext"] := .F.

Return oResp

/*/{Protheus.doc} ZcnProd
Lookup de produto (operacao "lookupProduto") -- consulta SB1 por
codigo/descricao, mesmo estilo de ZcnPess/RTM002App.prw::LstTES (limite de
20 linhas, sem paginacao real nesta fase).
@type Static Function
@param oReq JsonObject, {filtro}
@return JsonObject, {success, items:[{codigo,descricao}]}
/*/
//=============================================================================================================================
Static Function ZcnProd(oReq)

    Local oResp   := JsonObject():New()
    Local aItens  := {}
    Local oItem   := Nil
    Local cAliasQ := GetNextAlias()
    Local cFiltro := ""
    Local cLike   := ""
    Local nCount  := 0

    If ValType(oReq["filtro"]) == "C" ; cFiltro := AllTrim(oReq["filtro"]) ; EndIf
    cLike := "%'%" + cFiltro + "%'%"

    BeginSql Alias cAliasQ
        SELECT B1_COD AS CODIGO, B1_DESC AS DESCRI
          FROM %table:SB1% SB1
         WHERE SB1.%notDel%
           AND SB1.B1_FILIAL = %xfilial:SB1%
           AND (SB1.B1_COD LIKE %exp:cLike% OR SB1.B1_DESC LIKE %exp:cLike%)
         ORDER BY SB1.B1_DESC
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

/*/{Protheus.doc} ZcnCndPg
Lookup de Condicao de Pagamento (operacao "lookupCondPagto") -- consulta SE4
por codigo/descricao (E4_CODIGO/E4_DESCRI, tabela core do Protheus,
Financeiro), mesmo estilo de ZcnPess/ZcnTpCt/ZcnProd (limite de 20 linhas,
sem paginacao real nesta fase).
@type Static Function
@param oReq JsonObject, {filtro}
@return JsonObject, {success, items:[{codigo,descricao}], hasNext}
/*/
//=============================================================================================================================
Static Function ZcnCndPg(oReq)

    Local oResp   := JsonObject():New()
    Local aItens  := {}
    Local oItem   := Nil
    Local cAliasQ := GetNextAlias()
    Local cFiltro := ""
    Local cLike   := ""
    Local nCount  := 0

    If ValType(oReq["filtro"]) == "C" ; cFiltro := AllTrim(oReq["filtro"]) ; EndIf
    cLike := "%'%" + cFiltro + "%'%"

    BeginSql Alias cAliasQ
        SELECT E4_CODIGO AS CODIGO, E4_DESCRI AS DESCRI
          FROM %table:SE4% SE4
         WHERE SE4.%notDel%
           AND SE4.E4_FILIAL = %xfilial:SE4%
           AND (SE4.E4_CODIGO LIKE %exp:cLike% OR SE4.E4_DESCRI LIKE %exp:cLike%)
         ORDER BY SE4.E4_CODIGO
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

/*/{Protheus.doc} ZcnNat
Lookup de Natureza (operacao "lookupNatureza") -- consulta SED por
codigo/descricao (CN9_NATURE, confirmado pelo usuario 2026-08-11).
Campos ED_CODIGO/ED_DESCRIC confirmados pelo usuario 2026-08-11 (o chute
inicial, ED_DESCRI por analogia com SE4/E4_DESCRI, deu erro real de SQL --
"nao existe a coluna ed_descri" -- a diferenca era so o "C" no final).
@type Static Function
@param oReq JsonObject, {filtro}
@return JsonObject, {success, items:[{codigo,descricao}], hasNext}
/*/
//=============================================================================================================================
Static Function ZcnNat(oReq)

    Local oResp   := JsonObject():New()
    Local aItens  := {}
    Local oItem   := Nil
    Local cAliasQ := GetNextAlias()
    Local cFiltro := ""
    Local cLike   := ""
    Local nCount  := 0

    If ValType(oReq["filtro"]) == "C" ; cFiltro := AllTrim(oReq["filtro"]) ; EndIf
    cLike := "%'%" + cFiltro + "%'%"

    BeginSql Alias cAliasQ
        SELECT ED_CODIGO AS CODIGO, ED_DESCRIC AS DESCRI
          FROM %table:SED% SED
         WHERE SED.%notDel%
           AND SED.ED_FILIAL = %xfilial:SED%
           AND (SED.ED_CODIGO LIKE %exp:cLike% OR SED.ED_DESCRIC LIKE %exp:cLike%)
         ORDER BY SED.ED_CODIGO
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

/*/{Protheus.doc} ZcnTpPla
Lookup de Tipo de Planilha (operacao "lookupTipoPlanilha") -- consulta CNL
por codigo/descricao.
IMPORTANTE: nomes de campo (CNL_CODIGO/CNL_DESCRI) assumidos por analogia com
CN1 (CN1_CODIGO/CN1_DESCRI, confirmados por print do usuario) -- CNL nunca
aparece em nenhum exemplo do GCT0109, confirmar contra o dicionario deste
ambiente se der erro de coluna/alias.
@type Static Function
@param oReq JsonObject, {filtro}
@return JsonObject, {success, items:[{codigo,descricao}], hasNext}
/*/
//=============================================================================================================================
Static Function ZcnTpPla(oReq)

    Local oResp   := JsonObject():New()
    Local aItens  := {}
    Local oItem   := Nil
    Local cAliasQ := GetNextAlias()
    Local cFiltro := ""
    Local cLike   := ""
    Local nCount  := 0
    // Campo que indica "exige cronograma financeiro/fisico" no Tipo de Planilha (pedido do
    // usuario: se exigir, a Periodicidade da planilha fica liberada pra digitar, senao so
    // leitura) -- nome nunca confirmado neste ambiente, candidatos abaixo via ZcnCpo (mesma
    // tecnica de ZcnCpDic).
    Local cCpoCrg := ZcnCpo({"CNL_CRONOG", "CNL_GERCRO", "CNL_TPCRO", "CNL_FISFIN"})
    Local cValCrg := ""
    Local lComCrg := !Empty(cCpoCrg)
    Local bPrevErr := Nil
    Local oErrCrg  := Nil

    If ValType(oReq["filtro"]) == "C" ; cFiltro := AllTrim(oReq["filtro"]) ; EndIf
    cLike := "%'%" + cFiltro + "%'%"

    // BeginSql e macro de COMPILACAO -- nao da pra injetar um trecho de SQL OPCIONAL via %exp:
    // quando a variavel vem vazia: o preprocessador troca "" por um literal ' ' em vez de nada,
    // o que gerou erro real de sintaxe em producao (22/09/2026): "DESCRI ' ' FROM CNL010...".
    // Por isso o campo extra (CRONOG) agora usa um BeginSql PROPRIO, protegido por Begin
    // Sequence: se o nome do campo estiver errado/a sintaxe der problema, cai pro SELECT
    // simples (sem exigeCronograma) em vez de quebrar a busca de Tipo de Planilha inteira.
    If lComCrg
        bPrevErr := ErrorBlock({|e| Break(e)})
        Begin Sequence
            BeginSql Alias cAliasQ
                SELECT CNL_CODIGO AS CODIGO, CNL_DESCRI AS DESCRI, CNL.%exp:cCpoCrg% AS CRONOG
                  FROM %table:CNL% CNL
                 WHERE CNL.%notDel%
                   AND CNL.CNL_FILIAL = %xfilial:CNL%
                   AND (CNL.CNL_CODIGO LIKE %exp:cLike% OR CNL.CNL_DESCRI LIKE %exp:cLike%)
                 ORDER BY CNL.CNL_CODIGO
            EndSql
        Recover Using oErrCrg
            lComCrg := .F.
            If Select(cAliasQ) > 0
                (cAliasQ)->(DbCloseArea())
            EndIf
        End Sequence
        ErrorBlock(bPrevErr)
    EndIf

    If !lComCrg
        BeginSql Alias cAliasQ
            SELECT CNL_CODIGO AS CODIGO, CNL_DESCRI AS DESCRI
              FROM %table:CNL% CNL
             WHERE CNL.%notDel%
               AND CNL.CNL_FILIAL = %xfilial:CNL%
               AND (CNL.CNL_CODIGO LIKE %exp:cLike% OR CNL.CNL_DESCRI LIKE %exp:cLike%)
             ORDER BY CNL.CNL_CODIGO
        EndSql
    EndIf

    While (cAliasQ)->(!Eof()) .And. nCount < 20
        oItem := JsonObject():New()
        oItem["codigo"]    := AllTrim((cAliasQ)->CODIGO)
        oItem["descricao"] := AllTrim((cAliasQ)->DESCRI)
        // "S"/"1"/"T"/"Y" cobrem os formatos mais comuns de campo Sim/Nao (char de combo "S"/"N"
        // ou "1"/"2", ou logico convertido por cValToChar) -- se o campo nao foi localizado no
        // dicionario, "exigeCronograma" fica de fora do JSON (o front assume .T., preservando o
        // comportamento de antes desta feature: Periodicidade sempre liberada em modo criar).
        If lComCrg
            cValCrg := AllTrim(Upper(cValToChar((cAliasQ)->CRONOG)))
            oItem["exigeCronograma"] := cValCrg == "S" .Or. cValCrg == "1" .Or. cValCrg == "T" .Or. cValCrg == "Y"
        EndIf
        aAdd(aItens, oItem)
        nCount++
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

    oResp["success"] := .T.
    oResp["items"]   := aItens
    oResp["hasNext"] := .F.
    oResp["campoCronogEncontrado"] := lComCrg

Return oResp

/*/{Protheus.doc} ZcnTes
Lookup de TES (operacao "lookupTES") -- consulta SF4 por codigo/descricao.
IMPORTANTE: assume tabela SF4 com campos F4_CODIGO/F4_TEXTO (padrao
Protheus) -- mesma suposicao (ainda nao confirmada neste ambiente) ja
registrada em Contratos/RTM002App.prw::LstTES.
@type Static Function
@param oReq JsonObject, {filtro}
@return JsonObject, {success, items:[{codigo,descricao}], hasNext}
/*/
//=============================================================================================================================
Static Function ZcnTes(oReq)

    Local oResp   := JsonObject():New()
    Local aItens  := {}
    Local oItem   := Nil
    Local cAliasQ := GetNextAlias()
    Local cFiltro := ""
    Local cLike   := ""
    Local nCount  := 0

    If ValType(oReq["filtro"]) == "C" ; cFiltro := AllTrim(oReq["filtro"]) ; EndIf
    cLike := "%'%" + cFiltro + "%'%"

    BeginSql Alias cAliasQ
        SELECT F4_CODIGO AS CODIGO, F4_TEXTO AS DESCRI
          FROM %table:SF4% SF4
         WHERE SF4.%notDel%
           AND (SF4.F4_CODIGO LIKE %exp:cLike% OR SF4.F4_TEXTO LIKE %exp:cLike%)
         ORDER BY SF4.F4_CODIGO
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

/*/{Protheus.doc} ZcnCCus
Lookup de Centro de Custo (operacao "lookupCentroCusto") -- consulta CTT
(tabela core do Protheus, praticamente qualquer modulo) por codigo/descricao.
@type Static Function
@param oReq JsonObject, {filtro}
@return JsonObject, {success, items:[{codigo,descricao}], hasNext}
/*/
//=============================================================================================================================
Static Function ZcnCCus(oReq)

    Local oResp   := JsonObject():New()
    Local aItens  := {}
    Local oItem   := Nil
    Local cAliasQ := GetNextAlias()
    Local cFiltro := ""
    Local cLike   := ""
    Local nCount  := 0

    If ValType(oReq["filtro"]) == "C" ; cFiltro := AllTrim(oReq["filtro"]) ; EndIf
    cLike := "%'%" + cFiltro + "%'%"

    BeginSql Alias cAliasQ
        SELECT CTT_CUSTO AS CODIGO, CTT_DESC01 AS DESCRI
          FROM %table:CTT% CTT
         WHERE CTT.%notDel%
           AND CTT.CTT_FILIAL = %xfilial:CTT%
           AND (CTT.CTT_CUSTO LIKE %exp:cLike% OR CTT.CTT_DESC01 LIKE %exp:cLike%)
         ORDER BY CTT.CTT_CUSTO
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

/*/{Protheus.doc} ZcnFilial
Lista as filiais da empresa corrente (SM0) -- operacao "lookupFilial", usada pelo Angular no
filtro de filial da busca avancada e no modal de selecao de filial antes de incluir um
contrato. Mesmo padrao de leitura de SM0 ja usado (e funcionando) em
Contratos/RT69M003.prw::ObtemEmpFilial (GetArea/RestArea porque SM0 e tabela compartilhada).
IMPORTANTE (limitacao conhecida, ainda sem solucao confirmada): esta funcao lista TODAS as
filiais da empresa (cEmpAnt), SEM checar quais delas o usuario logado tem realmente liberadas
no SIGACFG. Nao foi encontrado, durante a implementacao, um metodo/API nativo confirmado para
essa checagem especifica neste ambiente/release -- se este Protheus usa grupo de filiais por
usuario, esta lista ainda nao respeita essa restricao. Ajustar aqui assim que o
metodo/tabela correto for confirmado.
@type Static Function
@param oReq JsonObject, {} (sem parametros)
@return JsonObject, {success, items:[{codigo,nome}]}
/*/
//=============================================================================================================================
Static Function ZcnFilial(oReq)

    Local oResp  := JsonObject():New()
    Local aItens := {}
    Local oItem  := Nil
    Local aArea  := SM0->(GetArea())

    SM0->(dbSetOrder(1)) // M0_CODIGO+M0_CODFIL
    SM0->(dbSeek(cEmpAnt))
    While !SM0->(Eof()) .And. AllTrim(SM0->M0_CODIGO) == AllTrim(cEmpAnt)
        oItem := JsonObject():New()
        oItem["codigo"] := AllTrim(SM0->M0_CODFIL)
        oItem["nome"]   := AllTrim(SM0->M0_FILIAL)
        aAdd(aItens, oItem)
        SM0->(DbSkip())
    EndDo

    RestArea(aArea)

    oResp["success"] := .T.
    oResp["items"]   := aItens

Return oResp

/*/{Protheus.doc} ZcnProxNum
Sugere o proximo numero de contrato (operacao "lookupProximoNumero") via GetSxeNum -- le o
contador automatico ja configurado no dicionario (SX3) de CN9_NUMERO (confirmado pelo usuario,
2026-08-12). Usada pelo Angular SO pra pre-preencher o campo "Nr. Contrato" ao abrir a tela de
novo contrato -- o campo continua editavel, o usuario pode trocar por outro numero antes de
salvar (ZcnCriar sempre grava o que vier em oHeader["numero"], nao chama GetSxeNum de novo).
IMPORTANTE: nao chama ConfirmSX8()/RollBackSX8() -- e so uma sugestao/preview, nao uma reserva
formal do numero. Risco aceito: em uso concorrente (2 usuarios abrindo "Novo Contrato" quase ao
mesmo tempo), os dois podem receber a MESMA sugestao; a unicidade real continua garantida pela
chave do CN9 (VldData/CommitData recusa duplicata), entao o pior caso e um dos dois precisar
trocar o numero manualmente antes de salvar -- nao um dado corrompido.
@type Static Function
@param oReq JsonObject, {} (sem parametros)
@return JsonObject, {success, numero}
/*/
//=============================================================================================================================
Static Function ZcnProxNum(oReq)

    Local oResp := JsonObject():New()

    oResp["success"] := .T.
    oResp["numero"]  := AllTrim(GetSxeNum("CN9", "CN9_NUMERO"))

Return oResp

/*/{Protheus.doc} ZcnMStr
Le um campo caractere de um submodelo (CNBDETAIL, etc.) de forma segura --
oSubModel:GetValue devolve Nil se o campo nao existir no submodelo, e
AllTrim(Nil) estoura erro; esta funcao protege contra isso. Usar para campos
ainda nao confirmados neste ambiente (ex: CNB_CC).
@type Static Function
@return caractere, valor do campo (trim) ou "" se nao existir/nao for caractere
/*/
//=============================================================================================================================
Static Function ZcnMStr(oSubModel, cCampo)

    Local xVal := oSubModel:GetValue(cCampo)

Return IIf(ValType(xVal) == "C", AllTrim(xVal), "")

/*/{Protheus.doc} ZcnMNum
Mesma ideia de ZcnMStr, para campo numerico (ex: CNB_PERDES).
@type Static Function
@return numerico, valor do campo ou 0 se nao existir/nao for numerico
/*/
//=============================================================================================================================
Static Function ZcnMNum(oSubModel, cCampo)

    Local xVal := oSubModel:GetValue(cCampo)

Return IIf(ValType(xVal) == "N", xVal, 0)

/*/{Protheus.doc} ZcnMDat
Mesma ideia de ZcnMStr/ZcnMNum, para campo data de um submodelo (ex:
CNA_DTINI/CNA_DTFIM). Devolve ISO ('yyyy-MM-dd') ou "" se nao existir/nao
for data/vazio.
@type Static Function
@return caractere, data ISO ou ""
/*/
//=============================================================================================================================
Static Function ZcnMDat(oSubModel, cCampo)

    Local xVal := oSubModel:GetValue(cCampo)

Return IIf(ValType(xVal) == "D" .And. !Empty(xVal), DToS(xVal), "")


/*/{Protheus.doc} ZcnSToD
Converte uma data ISO ("yyyy-MM-dd", formato usado pelo Angular/po-datepicker) para data-simples.
IMPORTANTE: SToD() nativo espera 8 digitos no formato AAAAMMDD SEM separador -- passar a string ISO
direto (com os tracos) faz SToD() extrair mes/dia errados e devolver uma data vazia. Isso causava o
erro "O campo Data Inicial (CNA_DTINI) nao foi preenchido" mesmo com a data de inicio preenchida na
tela (SToD("2026-09-22") virava mes=0, dia invalido). Aceita tambem uma data-simples ja pronta
(devolve como veio) ou uma string AAAAMMDD sem traco (StrTran nao afeta).
@type Static Function
@param xVal caractere ISO/AAAAMMDD ou data-simples
@return data-simples, ou data vazia se xVal for vazio/invalido
/*/
//=============================================================================================================================
Static Function ZcnSToD(xVal)

    If ValType(xVal) == "D"
        Return xVal
    EndIf
    If ValType(xVal) != "C" .Or. Empty(AllTrim(xVal))
        Return CToD("")
    EndIf

Return SToD(StrTran(AllTrim(xVal), "-", ""))

/*/{Protheus.doc} ZcnCpo
Devolve o primeiro campo da lista que EXISTE no dicionario (SX3, inclui campo virtual) ou ""
se nenhum existir. Usada para os campos cujo nome exato nao foi confirmado neste ambiente --
assim um nome errado nunca vira erro de execucao (THREAD ERROR), so um campo "nao localizado".
@type Static Function
@param aCand array, nomes candidatos, em ordem de preferencia
@return caractere, nome do campo encontrado ou ""
/*/
//=============================================================================================================================
Static Function ZcnCpo(aCand)

    Local nI := 0

    For nI := 1 To Len(aCand)
        If !Empty(GetSx3Cache(aCand[nI], "X3_TIPO"))
            Return aCand[nI]
        EndIf
    Next nI

Return ""

/*/{Protheus.doc} ZcnCpDic
Mapa CENTRAL chave-logica -> campo real do dicionario para os campos da tela cujo nome nao foi
confirmado (descricao do contrato e campos de reajuste da planilha). Se algum campo real tiver
outro nome neste ambiente, e SO acrescentar o nome na lista da chave correspondente aqui.
@type Static Function
@param cChave caractere, chave logica (descCtr, descPla, indice, periodicidade, unidadePer, modoReajuste, dataBase)
@return caractere, nome do campo existente ou "" se nenhum candidato existir no dicionario
/*/
//=============================================================================================================================
Static Function ZcnCpDic(cChave)

    Local aCand := {}
    Local cRet  := ""

    Do Case
    Case cChave == "descCtr"
        aCand := {"CN9_DESCRI", "CN9_DESCCT", "CN9_DESCR"}
    Case cChave == "descPla"
        aCand := {"CNA_DESCPL", "CNA_DESCRI", "CNA_DESCR"}
    Case cChave == "indice"
        aCand := {"CNA_INDICE", "CNA_INDREA", "CNA_INDREJ"}
    Case cChave == "periodicidade"
        aCand := {"CNA_PERREA", "CNA_PERREJ", "CNA_PERIND"}
    Case cChave == "unidadePer"
        aCand := {"CNA_UNPERI", "CNA_UNIREA", "CNA_UNIPER"}
    Case cChave == "modoReajuste"
        aCand := {"CNA_MODREJ", "CNA_MODREA", "CNA_TPREJ"}
    Case cChave == "dataBase"
        aCand := {"CNA_DTBASE", "CNA_DTBREA", "CNA_DATBAS"}
    EndCase

    cRet := ZcnCpo(aCand)
    If Empty(cRet)
        cRet := ZcnCpBusca(cChave)
    EndIf

Return cRet

/*/{Protheus.doc} ZcnMGet
GetValue de submodelo que nunca estoura: erro de runtime (campo fora da estrutura do modelo)
vira Nil.
@type Static Function
@return generico, valor do campo ou Nil
/*/
//=============================================================================================================================
Static Function ZcnMGet(oSub, cCampo)

    Local bPrev := ErrorBlock({|e| Break(e)})
    Local xVal  := Nil
    Local oErr  := Nil

    Begin Sequence
        xVal := oSub:GetValue(cCampo)
    Recover Using oErr
        xVal := Nil
    End Sequence

    ErrorBlock(bPrev)

Return xVal

/*/{Protheus.doc} ZcnPlaGet
Le de um submodelo o campo apontado por uma chave de ZcnCpDic ja convertido para o formato da
resposta JSON (cKind: "C" texto, "N" numero, "D" data ISO). Devolve o vazio do tipo se o campo
nao existir.
@type Static Function
@return caractere/numerico conforme cKind
/*/
//=============================================================================================================================
Static Function ZcnPlaGet(oSub, cChave, cKind)

    Local cCpo := ZcnCpDic(cChave)
    Local xVal := Nil

    If !Empty(cCpo)
        xVal := ZcnMGet(oSub, cCpo)
    EndIf

    If cKind == "N"
        Return IIf(ValType(xVal) == "N", xVal, 0)
    EndIf
    If cKind == "D"
        Return IIf(ValType(xVal) == "D" .And. !Empty(xVal), DToS(xVal), "")
    EndIf

Return IIf(ValType(xVal) == "C", AllTrim(xVal), "")

/*/{Protheus.doc} ZcnPlaSet
Grava no modelo o campo apontado por uma chave de ZcnCpDic, convertendo o valor recebido do JSON
para o tipo do campo no dicionario. Valor vazio/Nil = nao grava. Campo nao localizado =
acrescenta a chave em aAvisos (uma vez) e nao grava. Erro do SetValue = empilha em aFalhas
(ZcnTrySet).
@type Static Function
@return Nil
/*/
//=============================================================================================================================
Static Function ZcnPlaSet(oModel, aFalhas, aAvisos, cChave, cGrid, xVal)

    Local cCpo  := ZcnCpDic(cChave)
    Local cTipo := ""
    Local xConv := Nil

    If xVal == Nil .Or. (ValType(xVal) == "C" .And. Empty(AllTrim(xVal)))
        Return Nil
    EndIf

    If Empty(cCpo)
        If AScan(aAvisos, cChave) == 0
            AAdd(aAvisos, cChave)
        EndIf
        Return Nil
    EndIf

    cTipo := GetSx3Cache(cCpo, "X3_TIPO")
    Do Case
    Case cTipo == "D"
        xConv := IIf(ValType(xVal) == "D", xVal, SToD(cValToChar(xVal)))
    Case cTipo == "N"
        xConv := IIf(ValType(xVal) == "N", xVal, Val(cValToChar(xVal)))
    OtherWise
        xConv := AllTrim(cValToChar(xVal))
    EndCase

    ZcnTrySet(oModel, aFalhas, cGrid, cCpo, xConv)

Return Nil

/*/{Protheus.doc} ZcnMoedaVl
Converte o numero da moeda para o tipo real de CN9_MOEDA (N ou C com zeros a esquerda).
@type Static Function
@return numerico ou caractere
/*/
//=============================================================================================================================
Static Function ZcnMoedaVl(xMoeda)

    Local aTam := TamSX3("CN9_MOEDA")
    Local nMoe := IIf(ValType(xMoeda) == "N", Int(xMoeda), Val(cValToChar(xMoeda)))

    If Len(aTam) >= 3 .And. aTam[3] == "C"
        Return StrZero(nMoe, aTam[1])
    EndIf

Return nMoe

/*/{Protheus.doc} ZcnCbox
Le as opcoes do combo (X3_CBOX, formato "1=Texto;2=Texto") de um campo do dicionario.
@type Static Function
@return array de JsonObject {value,label} (vazio se o campo nao existir ou nao tiver combo)
/*/
//=============================================================================================================================
Static Function ZcnCbox(cCampo)

    Local aRet := {}
    Local cBox := ""
    Local aPar := {}
    Local aKV  := {}
    Local nI   := 0
    Local oOpt := Nil

    If Empty(cCampo)
        Return aRet
    EndIf

    cBox := AllTrim(cValToChar(GetSx3Cache(cCampo, "X3_CBOX")))
    If Empty(cBox) .Or. Left(cBox, 1) == "#"
        Return aRet
    EndIf

    aPar := StrTokArr(cBox, ";")
    For nI := 1 To Len(aPar)
        aKV := StrTokArr(aPar[nI], "=")
        If Len(aKV) >= 2
            oOpt := JsonObject():New()
            oOpt["value"] := AllTrim(aKV[1])
            oOpt["label"] := AllTrim(aKV[2])
            AAdd(aRet, oOpt)
        EndIf
    Next nI

Return aRet

/*/{Protheus.doc} ZcnMoeda
Lookup de Moeda (operacao "lookupMoeda") -- lista as moedas cadastradas: tabela CTO (moedas
contabeis, CTO_MOEDA/CTO_DESC) e, se a CTO nao existir/estiver vazia/falhar, as moedas dos
parametros MV_MOEDA1..MV_MOEDA9. "codigo" volta NUMERICO (o que CN9_MOEDA/o front usam).
@type Static Function
@param oReq JsonObject, sem parametros
@return JsonObject, {success, items:[{codigo,descricao}], hasNext}
/*/
//=============================================================================================================================
Static Function ZcnMoeda(oReq)

    Local oResp   := JsonObject():New()
    Local aItens  := {}
    Local oItem   := Nil
    Local cAliasQ := GetNextAlias()
    Local cQuery  := ""
    Local cCodF   := ZcnCpo({"CTO_MOEDA"})
    Local cDesF   := ZcnCpo({"CTO_DESC", "CTO_DESCRI"})
    Local cDesc   := ""
    Local bPrev   := Nil
    Local oErr    := Nil
    Local nI      := 0

    If AliasInDic("CTO") .And. !Empty(cCodF) .And. !Empty(cDesF)
        cQuery := "SELECT " + cCodF + " AS CODIGO, " + cDesF + " AS DESCRI" + ;
                  " FROM " + RetSqlName("CTO") + " WHERE D_E_L_E_T_ = ' '" + ;
                  " AND CTO_FILIAL = '" + xFilial("CTO") + "' ORDER BY " + cCodF
        bPrev := ErrorBlock({|e| Break(e)})
        Begin Sequence
            DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAliasQ, .F., .T.)
            While (cAliasQ)->(!Eof())
                oItem := JsonObject():New()
                oItem["codigo"]    := Val(AllTrim((cAliasQ)->CODIGO))
                oItem["descricao"] := AllTrim((cAliasQ)->DESCRI)
                AAdd(aItens, oItem)
                (cAliasQ)->(DbSkip())
            EndDo
            (cAliasQ)->(DbCloseArea())
        Recover Using oErr
            aItens := {}
            If Select(cAliasQ) > 0
                (cAliasQ)->(DbCloseArea())
            EndIf
        End Sequence
        ErrorBlock(bPrev)
    EndIf

    If Len(aItens) == 0
        For nI := 1 To 9
            cDesc := AllTrim(SuperGetMV("MV_MOEDA" + cValToChar(nI), .F., ""))
            If !Empty(cDesc)
                oItem := JsonObject():New()
                oItem["codigo"]    := nI
                oItem["descricao"] := cDesc
                AAdd(aItens, oItem)
            EndIf
        Next nI
    EndIf

    oResp["success"] := .T.
    oResp["items"]   := aItens
    oResp["hasNext"] := .F.

Return oResp

/*/{Protheus.doc} ZcnIndice
Lookup de Indice de reajuste (operacao "lookupIndice") -- tabela de indices cadastrados do
Gestao de Contratos (CN6, CN6_CODIGO/CN6_DESCRI; rotina CNTA050). Tabela/campos verificados no
dicionario antes de consultar: se nao existirem devolve success=.F. com mensagem clara em vez
de erro de SQL.
@type Static Function
@param oReq JsonObject, sem parametros
@return JsonObject, {success, items:[{codigo,descricao}], hasNext}
/*/
//=============================================================================================================================
Static Function ZcnIndice(oReq)

    Local oResp   := JsonObject():New()
    Local aItens  := {}
    Local oItem   := Nil
    Local cAliasQ := GetNextAlias()
    Local cQuery  := ""
    Local cCodF   := ZcnCpo({"CN6_CODIGO"})
    Local cDesF   := ZcnCpo({"CN6_DESCRI", "CN6_DESC"})
    Local bPrev   := Nil
    Local oErr    := Nil

    If !AliasInDic("CN6") .Or. Empty(cCodF)
        oResp["success"] := .F.
        oResp["message"] := "Tabela de indices (CN6) nao localizada no dicionario deste ambiente."
        Return oResp
    EndIf

    cQuery := "SELECT " + cCodF + " AS CODIGO, " + IIf(Empty(cDesF), cCodF, cDesF) + " AS DESCRI" + ;
              " FROM " + RetSqlName("CN6") + " WHERE D_E_L_E_T_ = ' '" + ;
              " AND CN6_FILIAL = '" + xFilial("CN6") + "' ORDER BY " + cCodF

    bPrev := ErrorBlock({|e| Break(e)})
    Begin Sequence
        DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAliasQ, .F., .T.)
        While (cAliasQ)->(!Eof())
            oItem := JsonObject():New()
            oItem["codigo"]    := AllTrim((cAliasQ)->CODIGO)
            oItem["descricao"] := AllTrim((cAliasQ)->DESCRI)
            AAdd(aItens, oItem)
            (cAliasQ)->(DbSkip())
        EndDo
        (cAliasQ)->(DbCloseArea())
    Recover Using oErr
        aItens := {}
        If Select(cAliasQ) > 0
            (cAliasQ)->(DbCloseArea())
        EndIf
        ErrorBlock(bPrev)
        oResp["success"] := .F.
        oResp["message"] := "Falha ao consultar a tabela de indices (CN6): " + AllTrim(oErr:Description)
        Return oResp
    End Sequence
    ErrorBlock(bPrev)

    oResp["success"] := .T.
    oResp["items"]   := aItens
    oResp["hasNext"] := .F.

Return oResp

/*/{Protheus.doc} ZcnDomPla
Operacao "dominiosPlanilha": diz a tela quais campos opcionais (descricao do contrato e campos de
reajuste da planilha) existem neste dicionario e devolve as opcoes de combo (X3_CBOX) de
"Unidade" e "Modo de reajuste" da planilha -- a tela desabilita o que nao existir e nao inventa
dominio.
@type Static Function
@param oReq JsonObject, sem parametros
@return JsonObject, {success, campos:{chave:bool}, unidades:[{value,label}], modosReajuste:[{value,label}]}
/*/
//=============================================================================================================================
Static Function ZcnDomPla(oReq)

    Local oResp   := JsonObject():New()
    Local oCampos := JsonObject():New()
    Local oMapa   := JsonObject():New()

    oCampos["descCtr"]      := !Empty(ZcnCpDic("descCtr"))
    oCampos["descPla"]      := !Empty(ZcnCpDic("descPla"))
    oCampos["indice"]       := !Empty(ZcnCpDic("indice"))
    oCampos["periodicidade"] := !Empty(ZcnCpDic("periodicidade"))
    oCampos["unidadePer"]   := !Empty(ZcnCpDic("unidadePer"))
    oCampos["modoReajuste"] := !Empty(ZcnCpDic("modoReajuste"))
    oCampos["dataBase"]     := !Empty(ZcnCpDic("dataBase"))

    oMapa["descCtr"]       := ZcnCpDic("descCtr")
    oMapa["descPla"]       := ZcnCpDic("descPla")
    oMapa["indice"]        := ZcnCpDic("indice")
    oMapa["periodicidade"] := ZcnCpDic("periodicidade")
    oMapa["unidadePer"]    := ZcnCpDic("unidadePer")
    oMapa["modoReajuste"]  := ZcnCpDic("modoReajuste")
    oMapa["dataBase"]      := ZcnCpDic("dataBase")

    oResp["success"]       := .T.
    oResp["mapa"]          := oMapa
    oResp["campos"]        := oCampos
    oResp["unidades"]      := ZcnCbox(ZcnCpDic("unidadePer"))
    oResp["modosReajuste"] := ZcnCbox(ZcnCpDic("modoReajuste"))

Return oResp


/*/{Protheus.doc} ZcnCpBusca
Fallback de ZcnCpDic: quando nenhum nome candidato existe, procura na CNA (SX3, inclui virtuais)
um campo cujo TITULO/DESCRICAO bata com a chave logica. Ignora os campos de recorrencia
(CNA_PERIOD, CNA_PERREC, CNA_DIASEM, CNA_DIAMES, CNA_QTDREC), que tambem tem "periodicidade" no
titulo mas nao sao a periodicidade de reajuste. Devolve o primeiro que bater ou "".
@type Static Function
@param cChave caractere, chave logica de ZcnCpDic (so as da planilha)
@return caractere, nome do campo ou ""
/*/
//=============================================================================================================================
Static Function ZcnCpBusca(cChave)

    Local aCampos := {}
    Local cCpo    := ""
    Local cTxt    := ""
    Local nI      := 0

    If !(cChave $ "descPla|indice|periodicidade|unidadePer|modoReajuste|dataBase")
        Return ""
    EndIf

    aCampos := FWSX3Util():GetAllFields("CNA", .T.)
    If ValType(aCampos) != "A"
        Return ""
    EndIf

    For nI := 1 To Len(aCampos)
        cCpo := AllTrim(aCampos[nI])
        If cCpo $ "CNA_PERIOD|CNA_PERREC|CNA_DIASEM|CNA_DIAMES|CNA_QTDREC"
            Loop
        EndIf
        cTxt := Upper(FwNoAccent(AllTrim(cValToChar(GetSx3Cache(cCpo, "X3_TITULO"))) + " " + AllTrim(cValToChar(GetSx3Cache(cCpo, "X3_DESCRIC")))))

        Do Case
        Case cChave == "periodicidade" .And. "PERIOD" $ cTxt
            Return cCpo
        Case cChave == "unidadePer" .And. "UNIDADE" $ cTxt .And. "PERIOD" $ cTxt
            Return cCpo
        Case cChave == "modoReajuste" .And. "MODO" $ cTxt .And. "REAJ" $ cTxt
            Return cCpo
        Case cChave == "indice" .And. "INDICE" $ cTxt .And. "REAJ" $ cTxt
            Return cCpo
        Case cChave == "dataBase" .And. "DATA BASE" $ cTxt
            Return cCpo
        Case cChave == "descPla" .And. "DESCRICAO" $ cTxt .And. "PLANILHA" $ cTxt
            Return cCpo
        EndCase
    Next nI

Return ""