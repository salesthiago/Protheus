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
    Local cFilBkp    := cFilAnt
    Local cNumAc     := ""

    oReq:fromJson(cContent)
    cReceiveId := oReq["receiveId"]

    // Filial do contrato aberto na tela (o Angular manda "filialContrato" em toda chamada feita
    // de dentro do contrato -- a listagem mostra contratos de TODAS as filiais, e sem isso
    // ZcnMont/ZcnAtu/... procuravam o CN9 so na filial da sessao: "Contrato [x] revisao []
    // nao encontrado", 2026-10-07). Restaurada no fim desta funcao. Inclusao e listagem nao
    // trocam (usam a filial da sessao / o proprio filtro).
    If ValType(oReq["filialContrato"]) == "C" .And. !Empty(AllTrim(oReq["filialContrato"])) .And.;
       !(cType $ "contratoCriar/contratoListar/lookupProximoNumero")
        cFilAnt := Padr(AllTrim(oReq["filialContrato"]), Len(cFilAnt))
    EndIf

    // Acesso ao contrato (CNN) -- abrir, alterar, mudar situacao, revisar, excluir ou gerar
    // cronograma so com o usuario cadastrado na CNN do contrato (pedido do usuario 2026-10-07:
    // avisar "sem acesso" ANTES de carregar a tela, em vez de "nao encontrado").
    If ValType(oReq["numero"]) == "C" ; cNumAc := AllTrim(oReq["numero"]) ; EndIf
    If cType $ "acessoVerificar/contratoDetalhe/contratoAtualizar/contratoSituacao/contratoExcluir/revisaoAbrir/revisaoAprovar/gerarCronograma/cronogramaExcluir" .And.;
       !Empty(cNumAc) .And. !ZcnAcTem(cNumAc)
        oResp["success"]   := .F.
        oResp["semAcesso"] := .T.
        oResp["usuario"]   := AllTrim(UsrRetName(__cUserId))
        oResp["message"]   := "O usuario " + AllTrim(UsrRetName(__cUserId)) + " nao possui acesso para alterar o contrato " + cNumAc + "."
        cType := "#semAcesso"
    EndIf

    Do Case
    Case cType == "#semAcesso"
        // resposta ja montada acima
    Case cType == "acessoVerificar"
        oResp := ZcnAcVer(cNumAc)
    Case cType == "contratoListar"
        oResp := ZcnListSeg(oReq)
    Case cType == "contratoDetalhe"
        oResp := ZcnDet(oReq)
    Case cType == "contratoCriar"
        oResp := ZcnCriar(oReq)
    Case cType == "contratoAtualizar"
        oResp := ZcnAtu(oReq)
    Case cType == "contratoSituacao"
        oResp := ZcnSit(oReq)
    Case cType == "contratoExcluir"
        oResp := ZcnExcluir(oReq)
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
    Case cType == "cronogramaExcluir"
        oResp := ZcnCrgExc(oReq)
    Case cType == "anexoListar"
        oResp := ZcnAnLst(oReq)
    Case cType == "anexoCriar"
        oResp := ZcnAnCri(oReq)
    Case cType == "anexoBaixar"
        oResp := ZcnAnBax(oReq)
    Case cType == "anexoRemover"
        oResp := ZcnAnRem(oReq)
    Case cType == "importarExportar"
        oResp := ZcnImpExp(oReq)
    Case cType == "acessoListar"
        oResp := ZcnAcLst(oReq)
    Case cType == "acessoAdicionar"
        oResp := ZcnAcAdd(oReq)
    Case cType == "acessoRemover"
        oResp := ZcnAcRem(oReq)
    Case cType == "lookupUsuario"
        oResp := ZcnUsr(oReq)
    OtherWise
        oResp["success"] := .F.
        oResp["message"] := "Operacao nao reconhecida: " + cType
    EndCase

    cFilAnt := cFilBkp

    If !Empty(cReceiveId)
        oWebChannel:AdvplToJs(cReceiveId, oResp:toJson())
    EndIf

Return .T.

/*/{Protheus.doc} ZcnList
Lista contratos (operacao "contratoListar") -- so a revisao corrente de cada
contrato (CN9_REVATU em branco -- ver comentario do BeginSql). Nome do cliente/fornecedor resolvido por
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
"saldo" (CN9_SALDO, mesmo campo fisico ja lido em ZcnMont/oHeader) e "diasEncerramento" (pedido
do usuario 2026-09-23, "quantidade de dias para encerramento") foram acrescentados nesta fase --
diasEncerramento e CALCULADO (nao existe campo fisico de data-fim no cabecalho do contrato, so
CN9_DTINIC + CN9_VIGE/CN9_UNVIGE), somando a vigencia a data de inicio (dias/meses/anos conforme
CN9_UNVIGE) e subtraindo a data de hoje; pode dar negativo se o contrato ja passou da vigencia.
Filtro por usuario: respeita o ponto de entrada CN100FIL (o mesmo do browse do CNTA100) --
executado uma vez por chamada; a expressao devolvida (ex. "CN9_ESPCTR='2'") e avaliada em cada
registro com o CN9 posicionado pelo R_E_C_N_O_ (a query renomeia os campos, entao nao da pra
avaliar direto no cAliasQ). Retorno vazio (ou PE nao compilado) = sem restricao.
@type Static Function
@param oReq JsonObject, {tipo, situacao, numero, filial, dataInicioDe, dataInicioAte} (todos opcionais)
@return JsonObject, {success, contratos:[{numero,revisao,tipo,filial,pessoaNome,situacao,situacaoDescricao,vigencia,unidadeVigencia,saldo,diasEncerramento}]}
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
    Local cTodasFil  := ""
    Local dFiltDtDe  := CToD("")
    Local dFiltDtAte := CToD("")
    Local dDataFimVig := CToD("")
    Local cFiltPE    := ""
    Local bFiltPE    := Nil

    If ValType(oReq["tipo"]) == "C" ; cFiltTipo := AllTrim(oReq["tipo"]) ; EndIf
    If ValType(oReq["situacao"]) == "C" ; cFiltSit := AllTrim(oReq["situacao"]) ; EndIf
    If ValType(oReq["numero"]) == "C" ; cFiltNum := AllTrim(oReq["numero"]) ; EndIf
    If ValType(oReq["filial"]) == "C" .And. !Empty(AllTrim(oReq["filial"])) ; cFiltFil := AllTrim(oReq["filial"]) ; EndIf
    If ValType(oReq["dataInicioDe"])  == "C" .And. !Empty(AllTrim(oReq["dataInicioDe"]))  ; dFiltDtDe  := ZcnSToD(oReq["dataInicioDe"])  ; EndIf
    If ValType(oReq["dataInicioAte"]) == "C" .And. !Empty(AllTrim(oReq["dataInicioAte"])) ; dFiltDtAte := ZcnSToD(oReq["dataInicioAte"]) ; EndIf

    // Busca por numero sem diferenciar maiuscula/minuscula (pedido do usuario 2026-09-29) --
    // compara UPPER(CN9_NUMERO) com o termo ja em maiusculo. Aspas simples duplicadas porque o
    // termo entra cru no SQL (%exp% com "%...%" nao escapa nada).
    cFiltNum := StrTran(Upper(cFiltNum), "'", "''")
    cLikeNum := "%'%" + cFiltNum + "%'%"
    // Sem filial informada = TODAS as filiais (pedido do usuario 2026-09-29; antes caia na filial
    // da sessao). Mesmo idioma de %exp% cru do cLikeNum: a clausula fica sempre presente, so
    // troca a condicao.
    // Os dois valores vao como literal normal (%exp% sem o truque "%...%" de SQL cru) -- a 1a
    // versao montava a condicao inteira como SQL cru e a tela ficava carregando para sempre ao
    // filtrar uma filial (2026-09-30).
    cTodasFil := IIf(Empty(cFiltFil), "S", "N")
    If Empty(cFiltFil) ; cFiltFil := " " ; EndIf
    If Empty(dFiltDtDe)  ; dFiltDtDe  := SToD("19000101") ; EndIf
    If Empty(dFiltDtAte) ; dFiltDtAte := SToD("20991231") ; EndIf

    // Filtro de visibilidade por usuario (PE CN100FIL -- MV_XGCTUSC/MV_XGCTUSV)
    If ExistBlock("CN100FIL")
        cFiltPE := ExecBlock("CN100FIL", .F., .F.)
        If ValType(cFiltPE) == "C" .And. !Empty(AllTrim(cFiltPE))
            bFiltPE := &("{|| " + AllTrim(cFiltPE) + " }")
        EndIf
    EndIf

    // Revisao vigente = linha com CN9_REVATU EM BRANCO (confirmado no banco 2026-10-20, PSJ-009-JAT:
    // ''->001, 001->002, 002->003, 003 vigente com REVATU vazio -- o REVATU de cada revisao antiga
    // aponta para a SEGUINTE). A regra anterior (REVISA = REVATU) so pegava contratos nunca
    // revisados e escondia todos os revisados. Com uma revisao em aberto (ainda sem aprovacao) ha
    // duas linhas com REVATU vazio: o NOT EXISTS fica com a menor, que e a vigente.
    BeginSql Alias cAliasQ
        SELECT CN9.CN9_NUMERO AS NUMERO, CN9.CN9_REVISA AS REVISA, CN9.CN9_ESPCTR AS ESPCTR,
               CN9.CN9_FILIAL AS FILIAL, CN9.CN9_SITUAC AS SITUAC, CN9.CN9_UNVIGE AS UNVIGE, CN9.CN9_VIGE AS VIGE,
               CN9.CN9_DTINIC AS DTINIC, CN9.CN9_SALDO AS SALDO, CN9.R_E_C_N_O_ AS RECCN9
          FROM %table:CN9% CN9
         WHERE CN9.%notDel%
           AND (CN9.CN9_FILIAL = %exp:cFiltFil% OR %exp:cTodasFil% = 'S')
           AND CN9.CN9_REVATU = ' '
           AND NOT EXISTS (SELECT 1 FROM %table:CN9% CNX
                            WHERE CNX.%notDel%
                              AND CNX.CN9_FILIAL = CN9.CN9_FILIAL
                              AND CNX.CN9_NUMERO = CN9.CN9_NUMERO
                              AND CNX.CN9_REVATU = ' '
                              AND CNX.CN9_REVISA < CN9.CN9_REVISA)
           AND UPPER(CN9.CN9_NUMERO) LIKE %exp:cLikeNum%
           AND CN9.CN9_DTINIC BETWEEN %exp:dFiltDtDe% AND %exp:dFiltDtAte%
         ORDER BY CN9.CN9_NUMERO, CN9.CN9_FILIAL
    EndSql

    CNC->(dbSetOrder(1))

    While (cAliasQ)->(!Eof())
        If bFiltPE != Nil
            CN9->(DbGoTo((cAliasQ)->RECCN9))
            If !CN9->(Eval(bFiltPE))
                (cAliasQ)->(DbSkip())
                Loop
            EndIf
        EndIf

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
        oContrato["saldo"]            := (cAliasQ)->SALDO

        // Data-fim calculada (nao existe campo fisico pra ela no cabecalho) -- soma a vigencia
        // (dias/meses/anos, CN9_UNVIGE) a data de inicio, dias para encerramento = data-fim - hoje.
        // CN9_DTINIC as vezes volta da query embutida como Character em vez de Date quando o
        // valor no banco e NULL (quirk do TOPCONN/MSSQL com campo DATE vazio) -- sem esse guard de
        // ValType ANTES do Do Case, MonthSum() da THREAD ERROR ("expected D") pra esses contratos.
        dDataFimVig := (cAliasQ)->DTINIC
        If ValType(dDataFimVig) == "D" .And. !Empty(dDataFimVig)
            Do Case
            Case AllTrim((cAliasQ)->UNVIGE) == "1" // Dias
                dDataFimVig += (cAliasQ)->VIGE
            Case AllTrim((cAliasQ)->UNVIGE) == "2" // Meses
                dDataFimVig := MonthSum(dDataFimVig, (cAliasQ)->VIGE)
            Case AllTrim((cAliasQ)->UNVIGE) == "3" // Anos
                dDataFimVig := MonthSum(dDataFimVig, (cAliasQ)->VIGE * 12)
            EndCase
            oContrato["diasEncerramento"] := dDataFimVig - Date()
        Else
            oContrato["diasEncerramento"] := 0
        EndIf

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

/*/{Protheus.doc} ZcnListSeg
Chama ZcnList capturando qualquer erro de runtime (mesmo padrao ErrorBlock/Break de ZcnTrySet)
-- sem isso um erro na consulta nunca respondia ao Angular e a tabela ficava em "Carregando..."
para sempre (2026-09-30). Com isso a tela recebe {success:.F., message} e mostra o erro.
@type Static Function
@param oReq JsonObject, ver ZcnList
@return JsonObject, ver ZcnList
/*/
//=============================================================================================================================
Static Function ZcnListSeg(oReq)

    Local bPrevErr := ErrorBlock({|e| Break(e)})
    Local oErr     := Nil
    Local oResp    := Nil

    Begin Sequence
        oResp := ZcnList(oReq)
    Recover Using oErr
        oResp := JsonObject():New()
        oResp["success"] := .F.
        oResp["message"] := "Falha ao consultar contratos: " + AllTrim(oErr:Description)
    End Sequence

    ErrorBlock(bPrevErr)

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

/*/{Protheus.doc} ZcnImpExp
Abre a tela de Importar / Exportar Itens do contrato (U_RTM002App, mesma opcao do menu do
CNTA100 via CTA100MNU) a partir da tela rtm003 (operacao "importarExportar", pedido do usuario
2026-09-29) -- tanto pelo botao ao lado de "Incluir" (sem contrato) quanto pela acao da linha da
listagem (com contrato). RTM002App le o contrato do CN9 POSICIONADO antes do FWCallApp, entao
aqui so posiciona o CN9 (ou deixa em Eof quando nao ha contrato) e chama a funcao. RTM002App usa
xFilial("CN9") nas buscas -- por isso troca cFilAnt para a filial do contrato enquanto a tela
estiver aberta (a listagem pode mostrar contratos de outras filiais) e restaura na volta.
O FWCallApp do rtm002 e modal: esta chamada so responde ao Angular quando a tela for fechada.
@type Static Function
@param oReq JsonObject, {numero, revisao, filial} (todos opcionais)
@return JsonObject, {success, message}
/*/
//=============================================================================================================================
Static Function ZcnImpExp(oReq)

    Local oResp     := JsonObject():New()
    Local aAreaCN9  := CN9->(GetArea())
    Local cFilBkp   := cFilAnt
    Local cNumero   := ""
    Local cRevisao  := ""
    Local cFilCtr   := ""
    Local lAchou    := .F.

    If ValType(oReq["numero"])  == "C" ; cNumero  := AllTrim(oReq["numero"])  ; EndIf
    If ValType(oReq["revisao"]) == "C" ; cRevisao := AllTrim(oReq["revisao"]) ; EndIf
    If ValType(oReq["filial"])  == "C" ; cFilCtr  := AllTrim(oReq["filial"])  ; EndIf

    If !Empty(cFilCtr)
        cFilAnt := Padr(cFilCtr, Len(cFilAnt))
    EndIf

    CN9->(dbSetOrder(1))
    If !Empty(cNumero)
        lAchou := CN9->(dbSeek(xFilial("CN9") + Padr(cNumero, TamSX3("CN9_NUMERO")[1]) + Padr(cRevisao, TamSX3("CN9_REVISA")[1])))
    EndIf
    If !lAchou
        // Sem contrato (botao do cabecalho) ou nao encontrado: CN9 em Eof, RTM002App abre vazio.
        CN9->(dbGoBottom())
        CN9->(dbSkip())
    EndIf

    If !Empty(cNumero) .And. !lAchou
        oResp["success"] := .F.
        oResp["message"] := "Contrato " + cNumero + "/" + cRevisao + " nao encontrado na filial " + cFilAnt + "."
    Else
        U_RTM002App()
        oResp["success"] := .T.
    EndIf

    cFilAnt := cFilBkp
    RestArea(aAreaCN9)

Return oResp

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
    Local xExigeCrg := Nil
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
        oResp["message"] := "Contrato [" + cContra + "] revisao [" + cRevisa + "] nao encontrado na filial " + AllTrim(cFilAnt) + "."
        Return oResp
    EndIf

    cTipo := IIf(AllTrim(CN9->CN9_ESPCTR) == "1", "C", "V")

    oHeader["numero"]             := AllTrim(CN9->CN9_NUMERO)
    // Tamanho do CN9_NUMERO -- limita o campo "Numero" na alteracao em elaboracao (2026-10-20)
    oHeader["tamanhoNumero"]      := TamSX3("CN9_NUMERO")[1]
    oHeader["revisao"]            := AllTrim(CN9->CN9_REVISA)
    oHeader["tipo"]               := cTipo
    oHeader["filial"]             := AllTrim(CN9->CN9_FILIAL)
    // ZcnDateStr (nao DToS cru): devolve "" se CN9_DTINIC estiver em branco (DToS de data vazia
    // vira uma string de ESPACOS, nao ""-- truthy em JS, o que travava o calculo de "Data Final"
    // no Angular, ver dataFinalCalculada()/contrato-editor.component.ts) e formata como ISO
    // 'yyyy-MM-dd' (contrato documentado em ContratoHeader.dataInicio/contrato.model.ts) -- DToS
    // cru devolvia "yyyyMMdd" sem tracos, incompativel com o parser de data do front.
    oHeader["dataInicio"]         := ZcnDateStr(CN9->CN9_DTINIC)
    // Revisao de fato (tem revisao anterior) e a mais recente do contrato -- a tela so libera a
    // edicao da "revisao em aberto" com os dois .T. (ver ZcnTemRevAnt).
    oHeader["revisaoDeFato"]      := ZcnTemRevAnt(cContra, CN9->CN9_REVISA)
    oHeader["revisaoMaisRecente"] := (AllTrim(CN9->CN9_REVISA) == ZcnUltRev(cContra))
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

    // Campos novos do header (Fase 5, prototipo "Contratos - Alteracao") -- CONFIRMADOS PELO
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
            // "Editar Parcela" (contrato-editor) precisa saber se ESTA planilha ja salva permite
            // cronograma financeiro/fisico -- mesma logica/candidatos de campo do lookup
            // ZcnTpPla (usado so na criacao), agora tambem resolvida aqui pra quem abre um
            // contrato ja existente. Xnil (campo nao localizado no dicionario) fica de fora do
            // JSON -- o front assume permitido, mesmo comportamento de antes desta feature.
            xExigeCrg := ZcnPlaExigeCrg(oPla["tipoPlanilha"])
            If xExigeCrg != Nil
                oPla["exigeCronograma"] := xExigeCrg
            EndIf
            // Por planilha (nao so o header.temCronograma do contrato) -- a tela de revisao
            // so oferece "Excluir cronograma financeiro" nas planilhas que de fato tem um.
            oPla["temCronograma"] := ZcnTmCrg(cContra, cRevisa, oPla["numero"])
            // Parcelas do cronograma -- exibidas no "Editar Parcela" (ZcnCrgLst).
            oPla["parcelas"]      := IIf(oPla["temCronograma"], ZcnCrgLst(cContra, cRevisa, oPla["numero"]), {})
            // Planilha com medicao (CNE) nao pode ter os itens alterados na tela, nem em elaboracao.
            oPla["temMedicao"]    := ZcnPlaMed(cContra, cRevisa, oPla["numero"])
            // Planilha incluida nesta revisao -- numa revisao em aberto so essas podem ser alteradas.
            oPla["novaNaRevisao"] := ZcnPlaNaRev(cContra, cRevisa, oPla["numero"])
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
            oPla["pessoa"]["cgc"]  := ZcnCgc(cTipo, oPla["pessoa"]["codigo"], oPla["pessoa"]["loja"])
            // Resumo da planilha so leitura (layout "detalhe" da tela, pedido do usuario
            // 2026-10-09): descricao do tipo, valor total/saldo, proxima medicao e proximo
            // reajuste. Campos lidos via ZcnMNum/ZcnMDat -- campo vazio/ausente degrada pra 0/"".
            oPla["tipoPlanilhaDesc"] := AllTrim(Posicione("CNL", 1, xFilial("CNL") + oModelCNA:GetValue('CNA_TIPPLA'), "CNL_DESCRI"))
            oPla["valorTotal"]       := ZcnMNum(oModelCNA, 'CNA_VLTOT')
            oPla["saldo"]            := ZcnMNum(oModelCNA, 'CNA_SALDO')
            // CNA_PROMED/CNA_PROXRJ confirmados no dicionario CNA (print do usuario 2026-10-09).
            // Sem CNA_PROMED preenchido, cai na competencia da 1a parcela com saldo no cronograma.
            oPla["proximaMedicao"]   := ZcnMDat(oModelCNA, 'CNA_PROMED')
            If Empty(oPla["proximaMedicao"])
                oPla["proximaMedicao"] := ZcnPlaPrxMd(cContra, cRevisa, oPla["numero"])
            EndIf
            oPla["proximoReajuste"]  := ZcnMDat(oModelCNA, 'CNA_PROXRJ')

            oPla["itens"] := {}
            For nJ := 1 To oModelCNB:Length()
                oModelCNB:GoLine(nJ)
                oItm := JsonObject():New()
                oItm["item"]          := AllTrim(oModelCNB:GetValue('CNB_ITEM'))
                oItm["produto"]       := AllTrim(oModelCNB:GetValue('CNB_PRODUT'))
                oItm["descricao"]     := ZcnDesc(oItm["produto"])
                oItm["unidade"]       := AllTrim(Posicione("SB1", 1, xFilial("SB1") + oModelCNB:GetValue('CNB_PRODUT'), "B1_UM"))
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
Com cNumPla, conta so as parcelas daquela planilha (CNF_NUMPLA) -- usado
na tela de revisao, que oferece excluir o cronograma planilha a planilha.
@param cContra caractere, numero do contrato
@param cRevisa caractere, revisao
@param cNumPla caractere, numero da planilha (opcional -- vazio = contrato inteiro)
@return logico, .T. se ja existe pelo menos 1 linha de cronograma
/*/
//=============================================================================================================================
Static Function ZcnTmCrg(cContra, cRevisa, cNumPla)

    Local lTem      := .F.
    Local cAliasQ   := GetNextAlias()
    //Local oErrCatch := Nil

    Default cNumPla := ""

    Begin Sequence
        If Empty(cNumPla)
            BeginSql Alias cAliasQ
                SELECT COUNT(*) AS QTD
                  FROM %table:CNF% CNF
                 WHERE CNF.%notDel%
                   AND CNF.CNF_FILIAL = %xfilial:CNF%
                   AND CNF.CNF_CONTRA = %exp:cContra%
                   AND CNF.CNF_REVISA = %exp:cRevisa%
            EndSql
        Else
            BeginSql Alias cAliasQ
                SELECT COUNT(*) AS QTD
                  FROM %table:CNF% CNF
                 WHERE CNF.%notDel%
                   AND CNF.CNF_FILIAL = %xfilial:CNF%
                   AND CNF.CNF_CONTRA = %exp:cContra%
                   AND CNF.CNF_REVISA = %exp:cRevisa%
                   AND CNF.CNF_NUMPLA = %exp:cNumPla%
            EndSql
        EndIf
        lTem := (cAliasQ)->QTD > 0
        (cAliasQ)->(DbCloseArea())
    Recover Using oErrCatch
        lTem := .F.
    End Sequence

Return lTem

/*/{Protheus.doc} ZcnPlaMed
Indica se a planilha ja tem medicao (itens de medicao na CNE -- CNE_NUMERO e a planilha, mesma
ligacao usada em RTM002App.prw). Planilha medida nao pode ter os itens alterados pela tela.
@type Static Function
@param cContra caractere, numero do contrato
@param cRevisa caractere, revisao
@param cNumPla caractere, numero da planilha (CNA_NUMERO) -- vazio = qualquer planilha do contrato
@return logico, .T. se existe ao menos um item de medicao
/*/
//=============================================================================================================================
Static Function ZcnPlaMed(cContra, cRevisa, cNumPla)

    Local cAliasQ := GetNextAlias()
    Local cCtr    := Padr(cContra, TamSX3("CNE_CONTRA")[1])
    Local cRev    := Padr(cRevisa, TamSX3("CNE_REVISA")[1])
    Local cPla    := Padr(cNumPla, TamSX3("CNE_NUMERO")[1])
    Local cTodas  := IIf(Empty(cNumPla), "S", "N")
    Local lTem    := .F.

    BeginSql Alias cAliasQ
        SELECT COUNT(*) AS QTD
          FROM %table:CNE% CNE
         WHERE CNE.%notDel%
           AND CNE.CNE_FILIAL = %xfilial:CNE%
           AND CNE.CNE_CONTRA = %exp:cCtr%
           AND CNE.CNE_REVISA = %exp:cRev%
           AND (CNE.CNE_NUMERO = %exp:cPla% OR %exp:cTodas% = 'S')
    EndSql
    lTem := (cAliasQ)->QTD > 0
    (cAliasQ)->(DbCloseArea())

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

Return IIf(ValType(xVal) == "D", ZcnDateStr(xVal), "")

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

/*/{Protheus.doc} ZcnCgc
CNPJ/CPF do cliente/fornecedor (A1_CGC/A2_CGC) ja formatado, para o resumo da planilha.
@type Static Function
@param cTipo caractere, "C" compra (SA2) ou "V" venda (SA1)
@param cCodigo caractere, codigo
@param cLoja caractere, loja
@return caractere, CNPJ/CPF formatado ou "" se nao encontrado/vazio
/*/
//=============================================================================================================================
Static Function ZcnCgc(cTipo, cCodigo, cLoja)

    Local cCgc := ""

    If Empty(cCodigo)
        Return ""
    EndIf

    If cTipo == "C"
        cCgc := AllTrim(Posicione("SA2", 1, xFilial("SA2") + Padr(cCodigo, TamSX3("A2_COD")[1]) + Padr(cLoja, TamSX3("A2_LOJA")[1]), "A2_CGC"))
    Else
        cCgc := AllTrim(Posicione("SA1", 1, xFilial("SA1") + Padr(cCodigo, TamSX3("A1_COD")[1]) + Padr(cLoja, TamSX3("A1_LOJA")[1]), "A1_CGC"))
    EndIf

    Do Case
    Case Len(cCgc) == 14
        cCgc := Transform(cCgc, "@R 99.999.999/9999-99")
    Case Len(cCgc) == 11
        cCgc := Transform(cCgc, "@R 999.999.999-99")
    EndCase

Return cCgc

/*/{Protheus.doc} ZcnPlaPrxMd
Proxima medicao da planilha: competencia (CNF_COMPET, "MM/AAAA") da primeira parcela do
cronograma financeiro (CNF) que ainda tem saldo. Envolvido em Begin Sequence (mesma cautela de
ZcnTmCrg): qualquer erro de campo/SQL degrada para "" em vez de quebrar a tela.
@type Static Function
@param cContra caractere, numero do contrato
@param cRevisa caractere, revisao
@param cNumPla caractere, numero da planilha (CNA_NUMERO)
@return caractere, competencia ("MM/AAAA") ou "" se nao houver parcela em aberto
/*/
//=============================================================================================================================
Static Function ZcnPlaPrxMd(cContra, cRevisa, cNumPla)

    Local cAliasQ := GetNextAlias()
    Local cCompet := ""
    Local bPrev   := ErrorBlock({|e| Break(e)})

    Begin Sequence
        BeginSql Alias cAliasQ
            SELECT CNF.CNF_COMPET AS COMPET
              FROM %table:CNF% CNF
             WHERE CNF.%notDel%
               AND CNF.CNF_FILIAL = %xfilial:CNF%
               AND CNF.CNF_CONTRA = %exp:cContra%
               AND CNF.CNF_REVISA = %exp:cRevisa%
               AND CNF.CNF_NUMPLA = %exp:cNumPla%
               AND CNF.CNF_SALDO  > 0
             ORDER BY CNF.CNF_PARCEL
        EndSql
        If (cAliasQ)->(!Eof())
            cCompet := AllTrim((cAliasQ)->COMPET)
        EndIf
        (cAliasQ)->(DbCloseArea())
    Recover
        cCompet := ""
        If Select(cAliasQ) > 0
            (cAliasQ)->(DbCloseArea())
        EndIf
    End Sequence

    ErrorBlock(bPrev)

Return cCompet

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
    Local nTamNum                               := 0

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

    // Numero digitado livremente na UI pode passar do tamanho de CN9_NUMERO no SX3 -- recusa aqui
    // em vez de truncar (truncar gravaria silenciosamente outro numero e poderia colidir com um
    // contrato existente). A partir daqui oHeader["numero"] ja vai normalizado (trim) para o
    // dbSeek de duplicidade, SetValue de CN9_NUMERO/CNA_CONTRA e ZcnMont pos-commit.
    nTamNum := TamSX3("CN9_NUMERO")[1]
    oHeader["numero"] := AllTrim(oHeader["numero"])
    If Len(oHeader["numero"]) > nTamNum
        oResp["success"] := .F.
        oResp["message"] := "Numero do contrato [" + oHeader["numero"] + "] excede o tamanho do campo CN9_NUMERO (" +;
            AllTrim(Str(nTamNum)) + " caracteres, informado " + AllTrim(Str(Len(oHeader["numero"]))) + ")."
        Return oResp
    EndIf

    // Confere duplicidade ANTES de mexer no modelo MVC -- sem isso, tentar reenviar (ex: apos um
    // erro anterior que na verdade ja tinha comitado o registro, como o crash de ZcnMont pos-
    // commit corrigido em ZcnMStr/ZcnMNum) faz FWLoadModel:Activate() casar com o CN9_NUMERO ja
    // existente e a grade CNADETAIL ser auto-carregada pela relacao com as linhas JA GRAVADAS da
    // planilha antiga, em vez de linhas novas -- e o AddLine/GoLine manuais do loop abaixo
    // perdem a sincronia com essas linhas pre-existentes, o que explica um "CNA_NUMERO nao
    // preenchido" na validacao mesmo com o SetValue sendo chamado normalmente no codigo.
    CN9->(dbSetOrder(1)) // CN9_FILIAL+CN9_NUMERO+CN9_REVISA
    If CN9->(dbSeek(xFilial("CN9") + Padr(AllTrim(oHeader["numero"]), TamSX3("CN9_NUMERO")[1])))
        oResp["success"] := .F.
        oResp["message"] := "Contrato [" + AllTrim(oHeader["numero"]) + "] ja existe (revisao [" + AllTrim(CN9->CN9_REVISA) + "]). Use 'Nova Revisao' para altera-lo ou informe outro numero."
        Return oResp
    EndIf

    // Data de inicio livre na inclusao (pedido do usuario 2026-10-09: retirada a trava de "nao pode
    // ser anterior a data base"), so obrigatoria.
    If Empty(ZcnSToD(oHeader["dataInicio"]))
        oResp["success"] := .F.
        oResp["message"] := "Data de inicio do contrato nao informada"
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
        // Pedido do usuario 2026-10-09: na inclusao a Data base (CNA_DTINI) de toda planilha e
        // IGUAL a data de inicio do contrato -- ignora o que vier na planilha.
        dDtIniPla := ZcnSToD(oHeader["dataInicio"])
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

        aItens := oPla["itens"]
        If ValType(aItens) != "A" ; aItens := {} ; EndIf
        For nI := 1 To Len(aItens)
            oItm := aItens[nI]
            // Itens (CNBDETAIL) sao relativos a linha CORRENTE de CNADETAIL (relacionamento
            // pai-filho resolvido pelo proprio MVC) -- por isso o GoLine(nP) da CNA acima e
            // indispensavel antes deste bloco. Linha 1 ja vem pronta no grid; da 2a em diante
            // ZcnAddLn confere que a linha foi de fato criada (ver nota la).
            If oModelCNB:Length() >= nI
                oModelCNB:GoLine(nI)
            ElseIf !ZcnAddLn(oModel, oModelCNB, aFalhas, "item " + StrZero(nI, Len(CNB->CNB_ITEM)) + " da planilha " + StrZero(nP, Len(CNA->CNA_NUMERO)))
                Exit
            EndIf

            ZcnItmGrv(oModel, aFalhas, oItm, StrZero(nI, Len(CNB->CNB_ITEM)))
            If Len(aFalhas) > 0
                Exit
            EndIf
        Next nI
        If Len(aFalhas) > 0
            Exit
        EndIf
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

    // Campos adicionais do header (Fase 5, prototipo "Contratos - Alteracao", 2026-08-11),
    // TODOS CONFIRMADOS PELO USUARIO -- movidos para DEPOIS de CNC/CNA/CNB de proposito, pra
    // que gatilhos/validacoes desses campos nao interfiram na preparacao das grades do MVC.
    // CN9_JUSTIF/CN9_OBJCTO/CN9_ALTCLA sao campos VIRTUAIS (memo), gravaveis via oModel:SetValue
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
        // apos o commit). Rele direto do alias CN9 (dbSeek so por filial+numero, a 1a e unica
        // revisao que um contrato recem-criado pode ter) -- fonte confiavel, e a mesma tecnica
        // que ZcnMont ja usa como fallback quando recebe revisao vazia.
        cNumero := AllTrim(oHeader["numero"])
        CN9->(dbSetOrder(1)) // CN9_FILIAL+CN9_NUMERO+CN9_REVISA
        If CN9->(dbSeek(xFilial("CN9") + Padr(cNumero, TamSX3("CN9_NUMERO")[1])))
            cRevisao := AllTrim(CN9->CN9_REVISA)
        EndIf

        // Acesso total (CNN) para quem incluiu -- o CNTA300/CNTA301 bloqueia a visualizacao
        // ("sem acesso ao contrato") de quem nao estiver na CNN, e a inclusao via modelo nao
        // grava esse registro sozinha. Demais usuarios: acao "Acessos" da listagem (ZcnAcAdd).
        ZcnAcGrv(cNumero, __cUserId, ZcnAcTot())

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

/*/{Protheus.doc} ZcnSetChk
Como ZcnTrySet, mas tambem confere o RETORNO do SetValue -- .F. (validacao do campo recusou o
valor) vira falha em aFalhas com a mensagem do modelo, em vez de seguir em silencio.
@type Static Function
@param oMdl objeto, modelo ativo
@param aFalhas array, acumulador de falhas
@param cGrid caractere, id do submodelo
@param cField caractere, campo
@param xValue generico, valor
@return logico, .T. se gravou
/*/
//=============================================================================================================================
Static Function ZcnSetChk(oMdl, aFalhas, cGrid, cField, xValue)

    Local bPrevErr := ErrorBlock({|e| Break(e)})
    Local oErr     := Nil
    Local lOk      := .F.
    Local cMsg     := ""

    Begin Sequence
        lOk := oMdl:SetValue(cGrid, cField, xValue)
        If ValType(lOk) != "L"
            lOk := .T.
        EndIf
        If !lOk
            cMsg := ZcnErrMsg(oMdl)
            AAdd(aFalhas, cGrid + "." + cField + ": " + IIf(Empty(cMsg), "valor recusado pelo modelo", cMsg))
        EndIf
    Recover Using oErr
        lOk := .F.
        AAdd(aFalhas, cGrid + "." + cField + ": " + AllTrim(oErr:Description))
    End Sequence

    ErrorBlock(bPrevErr)

Return lOk

/*/{Protheus.doc} ZcnAddLn
Inclui uma linha no grid e posiciona nela, CONFERINDO que a linha foi de fato criada. Antes o
AddLine() era chamado sem checar o retorno: quando a validacao da linha anterior recusava a
inclusao, o GoLine(n) seguinte nao saia da linha atual e os SetValue do proximo item
sobrescreviam o item anterior -- ao confirmar uma planilha com varios produtos, sobrava so um
(2026-10-07). Agora a falha volta em aFalhas com a mensagem do modelo.
@type Static Function
@param oMdl objeto, modelo ativo
@param oGrid objeto, submodelo grid (ex.: CNBDETAIL)
@param aFalhas array, acumulador de falhas
@param cDesc caractere, descricao da linha para a mensagem (ex.: "item 002")
@return logico, .T. se a linha foi incluida e posicionada
/*/
//=============================================================================================================================
Static Function ZcnAddLn(oMdl, oGrid, aFalhas, cDesc)

    Local nAntes := oGrid:Length()
    Local cMsg   := ""

    oGrid:AddLine()
    If oGrid:Length() <= nAntes
        cMsg := ZcnErrMsg(oMdl)
        AAdd(aFalhas, "Nao foi possivel incluir o " + cDesc + IIf(Empty(cMsg), ".", ": " + cMsg))
        Return .F.
    EndIf
    oGrid:GoLine(oGrid:Length())

Return .T.

/*/{Protheus.doc} ZcnItmGrv
Grava os campos de um item (CNBDETAIL) na linha JA POSICIONADA do grid -- usado na inclusao
(ZcnCriar), na revisao (ZcnRevAb) e na alteracao dos itens em elaboracao (ZcnAtuItens).
Produto, quantidade e valor unitario conferem o retorno (ZcnSetChk); os demais seguem a mesma
tolerancia de antes (CNB_CC/CNB_PERDES sao suposicoes de nome, via ZcnTrySet).
@type Static Function
@param oMdl objeto, modelo ativo
@param aFalhas array, acumulador de falhas
@param oItm JsonObject, {produto, quantidade, valorUnitario, tes, cc, pedTit, desconto}
@param cItem caractere, CNB_ITEM a gravar (vazio = mantem o da linha)
@return Nil
/*/
//=============================================================================================================================
Static Function ZcnItmGrv(oMdl, aFalhas, oItm, cItem)

    Local nQtdFal := Len(aFalhas)

    If !Empty(cItem)
        oMdl:SetValue('CNBDETAIL', 'CNB_ITEM', cItem)
    EndIf
    If AllTrim(oMdl:GetValue('CNBDETAIL', 'CNB_PRODUT')) != AllTrim(oItm["produto"])
        ZcnSetChk(oMdl, aFalhas, 'CNBDETAIL', 'CNB_PRODUT', AllTrim(oItm["produto"]))
    EndIf
    If Len(aFalhas) > nQtdFal
        Return Nil
    EndIf
    ZcnSetChk(oMdl, aFalhas, 'CNBDETAIL', 'CNB_QUANT' , oItm["quantidade"])
    ZcnSetChk(oMdl, aFalhas, 'CNBDETAIL', 'CNB_VLUNIT', oItm["valorUnitario"])
    // CNB_TS/CNB_PEDTIT confirmados no GCT0109; CNB_CC/CNB_PERDES sao suposicoes (ver ZcnCriar).
    If ValType(oItm["tes"]) == "C" .And. !Empty(AllTrim(oItm["tes"]))
        oMdl:SetValue('CNBDETAIL', 'CNB_TS', AllTrim(oItm["tes"]))
    EndIf
    If ValType(oItm["cc"]) == "C" .And. !Empty(AllTrim(oItm["cc"]))
        ZcnTrySet(oMdl, aFalhas, 'CNBDETAIL', 'CNB_CC', AllTrim(oItm["cc"]))
    EndIf
    If ValType(oItm["pedTit"]) == "C" .And. !Empty(AllTrim(oItm["pedTit"]))
        oMdl:SetValue('CNBDETAIL', 'CNB_PEDTIT', AllTrim(oItm["pedTit"]))
    EndIf
    If ValType(oItm["desconto"]) == "N" .And. (oItm["desconto"] > 0 .Or. ZcnMNum(oMdl:GetModel('CNBDETAIL'), 'CNB_PERDES') > 0)
        ZcnTrySet(oMdl, aFalhas, 'CNBDETAIL', 'CNB_PERDES', oItm["desconto"])
    EndIf

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
Excecao (pedido do usuario 2026-10-07): enquanto o contrato estiver EM ELABORACAO (CN9_SITUAC
"02"), "planilhas" pode trazer os itens de planilhas SEM medicao para serem regravados no mesmo
commit (ZcnAtuItens) -- a mesma edicao que o CNTA300 nativo permite nessa situacao.
@param oReq JsonObject, {numero, revisao (opcional, usa CN9_REVATU se vazio), header:{justificativa,dtAssinatura,reajuste,indice,despesaFinanceira,objeto,clausula,natureza,centroCusto,responsavel}, planilhas:[{numero, itens:[...]}] (opcional)}
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
    Local aPlaItm  := oReq["planilhas"]
    Local aPlaNov  := oReq["planilhasNovas"]
    Local nP       := 0
    Local nI       := 0
    Local nMaxPla  := 0
    Local lRevAb   := .F.
    Local aPlaExc  := oReq["excluirPlanilhas"]
    Local oMdlCNA  := Nil
    Local aItmDel  := {}
    Local cNovoNum := ""

    If ValType(oReq["numero"]) == "C" ; cNumero  := AllTrim(oReq["numero"])  ; EndIf
    If ValType(oReq["revisao"]) == "C" ; cRevisao := AllTrim(oReq["revisao"]) ; EndIf
    If ValType(aPlaItm) != "A" ; aPlaItm := {} ; EndIf
    If ValType(aPlaNov) != "A" ; aPlaNov := {} ; EndIf
    If ValType(aPlaExc) != "A" ; aPlaExc := {} ; EndIf

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

    // Revisao em aberto (Em Revisao/Alcadas, pedido do usuario 2026-10-09): pode incluir planilhas
    // e alterar as que foram incluidas NESTA revisao -- as herdadas da revisao anterior nao.
    lRevAb := AllTrim(CN9->CN9_SITUAC) $ "09/A"
    // Trava (2026-10-09): registro "Em Revisao" que NAO e uma revisao de fato (a revisao original,
    // ou uma revisao que nao e a mais recente) nunca e alterado por aqui -- foi assim que a planilha
    // nova acabou gravada no contrato original em vez da revisao.
    If lRevAb .And. (!ZcnTemRevAnt(cNumero, cRevisao) .Or. AllTrim(cRevisao) != ZcnUltRev(cNumero))
        oResp["success"] := .F.
        oResp["message"] := "O registro " + cNumero + "/" + cRevisao + " nao e a revisao em aberto do contrato -- nada foi gravado. " + ;
            "Abra a revisao pela opcao 'Alterar Revisao' da listagem."
        Return oResp
    EndIf
    If Len(aPlaItm) > 0 .And. AllTrim(CN9->CN9_SITUAC) != "02" .And. !lRevAb
        oResp["success"] := .F.
        oResp["message"] := "As planilhas so podem ser alteradas com o contrato em elaboracao ou com a revisao em aberto."
        Return oResp
    EndIf
    If lRevAb
        For nP := 1 To Len(aPlaItm)
            If (ValType(aPlaItm[nP]) $ "JO") .And. ValType(aPlaItm[nP]["numero"]) == "C" .And. ;
               !ZcnPlaNaRev(cNumero, cRevisao, AllTrim(aPlaItm[nP]["numero"]))
                oResp["success"] := .F.
                oResp["message"] := "A planilha " + AllTrim(aPlaItm[nP]["numero"]) + " veio da revisao anterior e nao pode ser alterada -- inclua uma nova planilha."
                Return oResp
            EndIf
        Next nP
    EndIf
    // Exclusao de planilhas ja gravadas (pedido do usuario 2026-10-09): mesmas regras da alteracao
    // -- em elaboracao, ou planilha incluida na revisao em aberto; nunca planilha com medicao.
    For nP := 1 To Len(aPlaExc)
        If AllTrim(CN9->CN9_SITUAC) != "02" .And. !(lRevAb .And. ZcnPlaNaRev(cNumero, cRevisao, AllTrim(cValToChar(aPlaExc[nP]))))
            oResp["success"] := .F.
            oResp["message"] := "A planilha " + AllTrim(cValToChar(aPlaExc[nP])) + " nao pode ser excluida (so em elaboracao ou se incluida na revisao em aberto)."
            Return oResp
        EndIf
        If ZcnPlaMed(cNumero, cRevisao, AllTrim(cValToChar(aPlaExc[nP])))
            oResp["success"] := .F.
            oResp["message"] := "A planilha " + AllTrim(cValToChar(aPlaExc[nP])) + " ja possui medicao e nao pode ser excluida."
            Return oResp
        EndIf
    Next nP

    // Planilhas novas (pedido do usuario 2026-10-07): em elaboracao sem NENHUMA medicao no
    // contrato, ou numa revisao em aberto.
    If Len(aPlaNov) > 0 .And. AllTrim(CN9->CN9_SITUAC) != "02" .And. !lRevAb
        oResp["success"] := .F.
        oResp["message"] := "Novas planilhas so podem ser incluidas com o contrato em elaboracao ou com a revisao em aberto."
        Return oResp
    EndIf
    If Len(aPlaNov) > 0 .And. !lRevAb .And. ZcnPlaMed(cNumero, cRevisao, "")
        oResp["success"] := .F.
        oResp["message"] := "O contrato ja possui medicao -- nao e possivel incluir novas planilhas."
        Return oResp
    EndIf

    cTipo    := IIf(AllTrim(CN9->CN9_ESPCTR) == "1", "C", "V")
    cModelId := IIf(cTipo == "C", "CNTA300", "CNTA301")

    // Troca do numero (pedido do usuario 2026-10-20): so em elaboracao, validada ANTES de gravar
    // qualquer coisa; a troca em si (ZcnRenum) roda depois do commit do modelo.
    If ValType(oReq["novoNumero"]) == "C" ; cNovoNum := AllTrim(oReq["novoNumero"]) ; EndIf
    If !Empty(cNovoNum) .And. cNovoNum != cNumero
        If AllTrim(CN9->CN9_SITUAC) != "02"
            oResp["success"] := .F.
            oResp["message"] := "O numero so pode ser alterado com o contrato em elaboracao."
            Return oResp
        EndIf
        If Len(cNovoNum) > TamSX3("CN9_NUMERO")[1]
            oResp["success"] := .F.
            oResp["message"] := "O numero do contrato deve ter no maximo " + cValToChar(TamSX3("CN9_NUMERO")[1]) + " caracteres."
            Return oResp
        EndIf
        cMsg := ZcnNumDup(cNovoNum, cTipo, ZcnPesCtr(CN9->CN9_FILIAL, cNumero, cRevisao, cTipo))
        If !Empty(cMsg)
            oResp["success"] := .F.
            oResp["message"] := cMsg + " Nada foi gravado."
            Return oResp
        EndIf
        // ZcnPesCtr/ZcnNumDup reposicionam CNC/CN9 -- volta para o contrato em alteracao.
        CN9->(dbSetOrder(1))
        CN9->(dbSeek(xFilial("CN9") + Padr(cNumero, nTamNum) + Padr(cRevisao, nTamRev)))
    Else
        cNovoNum := ""
    EndIf

    Begin Sequence

    oModel := FWLoadModel(cModelId)
    oModel:SetOperation(MODEL_OPERATION_UPDATE)
    // Confere o Activate -- seguir com o modelo inativo estoura THREAD ERROR no 1o SetValue
    // (mesmo caso de ZcnRevAb, 2026-10-09).
    If !oModel:Activate()
        cMsg := ZcnErrMsg(oModel)
        oResp["success"] := .F.
        oResp["message"] := "Nao foi possivel abrir o contrato " + cNumero + "/" + cRevisao + " para alteracao." + IIf(Empty(cMsg), "", " " + cMsg)
        Return oResp
    EndIf

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

    // Planilhas excluidas: primeiro o cronograma (CNF), depois a linha da planilha (CNA).
    For nP := 1 To Len(aPlaExc)
        If !ZcnPosPla(oModel, AllTrim(cValToChar(aPlaExc[nP])))
            AAdd(aFalhas, "planilha " + AllTrim(cValToChar(aPlaExc[nP])) + " nao encontrada no contrato.")
        Else
            ZcnRvDlCrg(oModel, aFalhas, AllTrim(cValToChar(aPlaExc[nP])))
            If Len(aFalhas) == 0 .And. ZcnPosPla(oModel, AllTrim(cValToChar(aPlaExc[nP]))) .And. ;
               !oModel:GetModel('CNADETAIL'):DeleteLine()
                AAdd(aFalhas, "nao foi possivel excluir a planilha " + AllTrim(cValToChar(aPlaExc[nP])) + ". " + ZcnErrMsg(oModel))
            EndIf
        EndIf
        If Len(aFalhas) > 0
            oModel:DeActivate()
            oResp["success"] := .F.
            oResp["message"] := "Falha ao excluir a planilha: " + aFalhas[1]
            Return oResp
        EndIf
    Next nP

    // Itens das planilhas (so em elaboracao, conferido acima) -- planilha a planilha.
    For nP := 1 To Len(aPlaItm)
        ZcnAtuItens(oModel, aFalhas, aAvisos, aPlaItm[nP], cNumero, cRevisao, cTipo, aItmDel)
        If Len(aFalhas) > 0
            oModel:DeActivate()
            oResp["success"] := .F.
            oResp["message"] := "Falha ao alterar os itens da planilha: " + aFalhas[1]
            Return oResp
        EndIf
    Next nP

    // Planilhas novas -- CNA_NUMERO = maior existente + 1 (mesma regra de ZcnRevAb).
    If Len(aPlaNov) > 0
        oMdlCNA := oModel:GetModel('CNADETAIL')
        For nI := 1 To oMdlCNA:Length()
            oMdlCNA:GoLine(nI)
            nMaxPla := Max(nMaxPla, Val(oMdlCNA:GetValue('CNA_NUMERO')))
        Next nI
        For nP := 1 To Len(aPlaNov)
            nMaxPla++
            ZcnPlaNova(oModel, aFalhas, aAvisos, aPlaNov[nP], cNumero, cTipo, StrZero(nMaxPla, Len(CNA->CNA_NUMERO)))
            If Len(aFalhas) > 0
                oModel:DeActivate()
                oResp["success"] := .F.
                oResp["message"] := "Falha ao incluir a nova planilha " + StrZero(nMaxPla, Len(CNA->CNA_NUMERO)) + ": " + aFalhas[1]
                Return oResp
            EndIf
        Next nP
    EndIf

    If oModel:VldData()
        oModel:CommitData()
        oModel:DeActivate()
        ZcnCnbDel(cNumero, cRevisao, aItmDel)
        If !Empty(cNovoNum)
            cMsg := ZcnRenum(cNumero, cNovoNum)
            If Empty(cMsg)
                ZcnZlgPut(cNovoNum, cRevisao, "NUMERO_ALTERADO", "", "", "Numero do contrato alterado de " + cNumero + " para " + cNovoNum)
                cNumero := cNovoNum
            EndIf
        EndIf
        oResp := ZcnMont(cNumero, cRevisao)
        If !Empty(cNovoNum) .And. cNumero != cNovoNum
            oResp["avisoNumero"] := "Contrato salvo, mas o numero NAO foi alterado: " + cMsg
        EndIf
        If Len(aAvisos) > 0
            oResp["avisos"] := aAvisos
        EndIf
    Else
        cMsg := ZcnErrMsg(oModel)
        oModel:DeActivate()
        oResp["success"] := .F.
        oResp["message"] := IIf(Empty(cMsg), "Falha na validacao do contrato.", cMsg)
    EndIf

    Recover Using oErrCatch
        oResp := JsonObject():New()
        oResp["success"] := .F.
        oResp["message"] := "Erro interno ao atualizar contrato: " + AllTrim(oErrCatch:description) +;
            IIf(ValType(oErrCatch:operation) == "C" .And. !Empty(oErrCatch:operation), " (" + AllTrim(oErrCatch:operation) + ")", "")
    End Sequence

Return oResp

/*/{Protheus.doc} ZcnAtuItens
Regrava os itens (CNBDETAIL) de UMA planilha de contrato em elaboracao, dentro do modelo ja
ativo em MODEL_OPERATION_UPDATE (ZcnAtu). A lista da tela e a lista final da planilha, na mesma
ordem das linhas lidas por ZcnMont: a linha N recebe o item N (mantendo o CNB_ITEM ja gravado),
itens a mais viram linhas novas (CNB_ITEM = maior existente + 1) e linhas que sobraram (itens
removidos na tela) sao excluidas. Recusa planilha com medicao (ZcnPlaMed).
@type Static Function
@param oModel objeto, modelo CNTA300/CNTA301 ativo em UPDATE
@param aFalhas array, acumulador de falhas
@param aAvisos array, campos nao localizados no dicionario (ZcnPlaSet)
@param oPla JsonObject, {numero, tipoPlanilha, descricao, pessoa:{codigo,loja}, indice, periodicidade, unidadePer, modoReajuste, dataBase, itens:[{produto,quantidade,valorUnitario,tes,cc,pedTit,desconto}]} -- campos do cabecalho opcionais
@param cContra caractere, numero do contrato
@param cRevisa caractere, revisao
@param cTipo caractere, "C" compra / "V" venda
@param aItmDel array, acumulador {planilha, CNB_ITEM} dos itens excluidos (ver ZcnCnbDel)
@return Nil
/*/
//=============================================================================================================================
Static Function ZcnAtuItens(oModel, aFalhas, aAvisos, oPla, cContra, cRevisa, cTipo, aItmDel)

    Local oModelCNA := oModel:GetModel('CNADETAIL')
    Local oModelCNB := oModel:GetModel('CNBDETAIL')
    Local aItens    := {}
    Local cNumPla   := ""
    Local cMsg      := ""
    Local cItem     := ""
    Local nLinPla   := 0
    Local nQtdLin   := 0
    Local nMaxItm   := 0
    Local nI        := 0

    If !(ValType(oPla) $ "JO")
        Return Nil
    EndIf
    If ValType(oPla["numero"]) == "C" ; cNumPla := AllTrim(oPla["numero"]) ; EndIf
    If ValType(oPla["itens"]) == "A" ; aItens := oPla["itens"] ; EndIf

    If Empty(cNumPla)
        AAdd(aFalhas, "numero da planilha nao informado.")
        Return Nil
    EndIf
    If Len(aItens) == 0
        AAdd(aFalhas, "a planilha " + cNumPla + " precisa de ao menos um item.")
        Return Nil
    EndIf
    If ZcnPlaMed(cContra, cRevisa, cNumPla)
        AAdd(aFalhas, "a planilha " + cNumPla + " ja possui medicao -- os itens nao podem ser alterados.")
        Return Nil
    EndIf

    For nI := 1 To oModelCNA:Length()
        oModelCNA:GoLine(nI)
        If !oModelCNA:IsDeleted() .And. AllTrim(oModelCNA:GetValue('CNA_NUMERO')) == cNumPla
            nLinPla := nI
            Exit
        EndIf
    Next nI
    If nLinPla == 0
        AAdd(aFalhas, "planilha " + cNumPla + " nao encontrada no contrato.")
        Return Nil
    EndIf
    oModelCNA:GoLine(nLinPla)

    // Cabecalho da planilha (pedido do usuario 2026-10-09): em elaboracao e sem medicao a
    // planilha inteira pode ser alterada, nao so os itens. So grava o que mudou -- SetValue com
    // o mesmo valor ainda dispararia gatilhos/validacoes do CNTA300 a toa.
    ZcnAtuCabPla(oModel, aFalhas, aAvisos, oPla, cTipo)
    If Len(aFalhas) > 0
        Return Nil
    EndIf

    nQtdLin := oModelCNB:Length()
    For nI := 1 To nQtdLin
        oModelCNB:GoLine(nI)
        nMaxItm := Max(nMaxItm, Val(oModelCNB:GetValue('CNB_ITEM')))
    Next nI

    For nI := 1 To Len(aItens)
        If nI <= nQtdLin
            oModelCNB:GoLine(nI)
            If oModelCNB:IsDeleted()
                oModelCNB:UnDeleteLine()
            EndIf
            cItem := ""
        Else
            nMaxItm++
            cItem := StrZero(nMaxItm, Len(CNB->CNB_ITEM))
            If !ZcnAddLn(oModel, oModelCNB, aFalhas, "item " + cItem + " da planilha " + cNumPla)
                Return Nil
            EndIf
        EndIf
        ZcnItmGrv(oModel, aFalhas, aItens[nI], cItem)
        If Len(aFalhas) > 0
            Return Nil
        EndIf
    Next nI

    // Itens removidos na tela -- guardados em aItmDel para ZcnCnbDel conferir depois do commit.
    For nI := Len(aItens) + 1 To nQtdLin
        oModelCNB:GoLine(nI)
        If !oModelCNB:IsDeleted()
            AAdd(aItmDel, {cNumPla, AllTrim(oModelCNB:GetValue('CNB_ITEM'))})
        EndIf
        If !oModelCNB:IsDeleted() .And. !oModelCNB:DeleteLine()
            cMsg := ZcnErrMsg(oModel)
            AAdd(aFalhas, "nao foi possivel remover o item " + AllTrim(oModelCNB:GetValue('CNB_ITEM')) + " da planilha " + cNumPla +;
                IIf(Empty(cMsg), ".", ": " + cMsg))
            Return Nil
        EndIf
    Next nI

Return Nil

/*/{Protheus.doc} ZcnAtuCabPla
Grava os campos do cabecalho de uma planilha EXISTENTE (CNADETAIL ja posicionado na linha
dela) recebidos da tela -- so os que vieram no payload e diferem do valor atual. Mesmos campos e
helpers de ZcnPlaNova (CNA_TIPPLA, pessoa, ZcnPlaSet para os campos resolvidos pelo dicionario).
@type Static Function
@param oModel objeto, modelo CNTA300/CNTA301 ativo em UPDATE
@param aFalhas array, acumulador de falhas
@param aAvisos array, campos nao localizados no dicionario
@param oPla JsonObject, ver ZcnAtuItens
@param cTipo caractere, "C" compra / "V" venda
@return Nil
/*/
//=============================================================================================================================
Static Function ZcnAtuCabPla(oModel, aFalhas, aAvisos, oPla, cTipo)

    Local oMdlCNA := oModel:GetModel('CNADETAIL')
    Local cCpoCod := IIf(cTipo == "C", 'CNA_FORNEC', 'CNA_CLIENT')
    Local cCpoLj  := IIf(cTipo == "C", 'CNA_LJFORN', 'CNA_LOJACL')
    Local aChaves := {{"descricao", "descPla", "C"}, {"indice", "indice", "C"}, {"periodicidade", "periodicidade", "N"}, ;
                      {"unidadePer", "unidadePer", "C"}, {"modoReajuste", "modoReajuste", "C"}, {"dataBase", "dataBase", "D"}}
    Local xNovo   := Nil
    Local nI      := 0

    If ValType(oPla["tipoPlanilha"]) == "C" .And. !Empty(AllTrim(oPla["tipoPlanilha"])) .And. ;
       AllTrim(oPla["tipoPlanilha"]) != AllTrim(oMdlCNA:GetValue('CNA_TIPPLA'))
        ZcnTrySet(oModel, aFalhas, 'CNADETAIL', 'CNA_TIPPLA', AllTrim(oPla["tipoPlanilha"]))
    EndIf

    If ValType(oPla["pessoa"]) $ "JO" .And. ValType(oPla["pessoa"]["codigo"]) == "C" .And. !Empty(AllTrim(oPla["pessoa"]["codigo"])) .And. ;
       (AllTrim(oPla["pessoa"]["codigo"]) != AllTrim(oMdlCNA:GetValue(cCpoCod)) .Or. AllTrim(oPla["pessoa"]["loja"]) != AllTrim(oMdlCNA:GetValue(cCpoLj)))
        ZcnTrySet(oModel, aFalhas, 'CNADETAIL', cCpoCod, AllTrim(oPla["pessoa"]["codigo"]))
        ZcnTrySet(oModel, aFalhas, 'CNADETAIL', cCpoLj, AllTrim(oPla["pessoa"]["loja"]))
    EndIf

    For nI := 1 To Len(aChaves)
        If Len(aFalhas) > 0
            Exit
        EndIf
        xNovo := oPla[aChaves[nI][1]]
        If xNovo == Nil .Or. (ValType(xNovo) == "C" .And. Empty(AllTrim(xNovo)))
            Loop
        EndIf
        If aChaves[nI][3] == "D"
            xNovo := ZcnSToD(xNovo)
            If ZcnPlaGet(oMdlCNA, aChaves[nI][2], "D") == ZcnDateStr(xNovo)
                Loop
            EndIf
            If xNovo < dDataBase
                AAdd(aFalhas, "a data base da planilha (" + DToC(xNovo) + ") nao pode ser anterior a data base do sistema (" + DToC(dDataBase) + ").")
                Exit
            EndIf
        ElseIf ZcnPlaGet(oMdlCNA, aChaves[nI][2], aChaves[nI][3]) == IIf(aChaves[nI][3] == "N", xNovo, AllTrim(cValToChar(xNovo)))
            Loop
        EndIf
        ZcnPlaSet(oModel, aFalhas, aAvisos, aChaves[nI][2], 'CNADETAIL', xNovo)
    Next nI

Return Nil

/*/{Protheus.doc} ZcnPesCtr
Codigo do fornecedor (compra) ou cliente (venda) do contrato, lido da CNC -- mesma busca de
ZcnList (CNC ordem 1 = FILIAL+NUMERO+REVISA).
@type Static Function
@param cFil caractere, filial do contrato
@param cContra caractere, numero do contrato
@param cRevisa caractere, revisao
@param cTipo caractere, "C" compra / "V" venda
@return caractere, codigo da pessoa ("" se nao achar)
/*/
//=============================================================================================================================
Static Function ZcnPesCtr(cFil, cContra, cRevisa, cTipo)

    Local cCod := ""

    CNC->(dbSetOrder(1))
    If CNC->(dbSeek(Padr(cFil, Len(xFilial("CNC"))) + Padr(cContra, TamSX3("CN9_NUMERO")[1]) + Padr(cRevisa, TamSX3("CN9_REVISA")[1])))
        cCod := AllTrim(IIf(cTipo == "C", CNC->CNC_CODIGO, CNC->CNC_CLIENT))
    EndIf

Return cCod

/*/{Protheus.doc} ZcnNumDup
Valida o NOVO numero de um contrato em elaboracao (pedido do usuario 2026-10-20). Recusa se:
- ja existe contrato com esse numero NESTA filial (chave do CN9 e FILIAL+NUMERO+REVISA, nao da
  pra ter dois iguais aqui, seja qual for o fornecedor/cliente);
- ja existe contrato com esse numero em OUTRA filial para o mesmo fornecedor (compra) ou
  cliente (venda).
@type Static Function
@param cNovo caractere, numero pretendido
@param cTipo caractere, "C" compra / "V" venda (do contrato que esta sendo alterado)
@param cCodPes caractere, fornecedor/cliente do contrato que esta sendo alterado
@return caractere, mensagem de recusa ("" = numero livre)
/*/
//=============================================================================================================================
Static Function ZcnNumDup(cNovo, cTipo, cCodPes)

    Local cAliasQ := GetNextAlias()
    Local cNum    := Padr(cNovo, TamSX3("CN9_NUMERO")[1])
    Local cMsg    := ""
    Local cTipoQ  := ""

    BeginSql Alias cAliasQ
        SELECT CN9.CN9_FILIAL AS FILIAL, CN9.CN9_REVISA AS REVISA, CN9.CN9_ESPCTR AS ESPCTR
          FROM %table:CN9% CN9
         WHERE CN9.%notDel%
           AND CN9.CN9_NUMERO = %exp:cNum%
         ORDER BY CN9.CN9_FILIAL, CN9.CN9_REVISA
    EndSql
    While (cAliasQ)->(!Eof()) .And. Empty(cMsg)
        cTipoQ := IIf(AllTrim((cAliasQ)->ESPCTR) == "1", "C", "V")
        If (cAliasQ)->FILIAL == xFilial("CN9")
            cMsg := "Ja existe o contrato " + AllTrim(cNovo) + " nesta filial (" + AllTrim(xFilial("CN9")) + ")."
        ElseIf cTipoQ == cTipo .And. !Empty(cCodPes) .And. ZcnPesCtr((cAliasQ)->FILIAL, cNovo, (cAliasQ)->REVISA, cTipoQ) == cCodPes
            cMsg := "Ja existe o contrato " + AllTrim(cNovo) + " na filial " + AllTrim((cAliasQ)->FILIAL) + ;
                " para o mesmo " + IIf(cTipo == "C", "fornecedor", "cliente") + " (" + cCodPes + ")."
        EndIf
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

Return cMsg

/*/{Protheus.doc} ZcnRenum
Troca o numero de um contrato EM ELABORACAO em todas as tabelas ligadas a ele (pedido do usuario
2026-10-20). O CNTA300 nao deixa alterar o CN9_NUMERO (e chave), entao a troca e feita registro a
registro, numa transacao so, DEPOIS do commit do modelo em ZcnAtu. Tabelas/campos que nao
existirem neste ambiente sao ignorados (AliasInDic/FieldPos). Em elaboracao nao ha medicao
(CND/CNE), so o cadastro, cronograma, acessos, timeline (ZLG) e anexos (AC9).
@type Static Function
@param cAntigo caractere, numero atual
@param cNovo caractere, numero novo (ja validado por ZcnNumDup)
@return caractere, mensagem de erro ("" = ok)
/*/
//=============================================================================================================================
Static Function ZcnRenum(cAntigo, cNovo)

    Local aMapa    := {{"CN9", "CN9_NUMERO"}, {"CNA", "CNA_CONTRA"}, {"CNB", "CNB_CONTRA"}, {"CNC", "CNC_NUMERO"}, ;
                       {"CNF", "CNF_CONTRA"}, {"CNS", "CNS_CONTRA"}, {"CNN", "CNN_CONTRA"}, {"CNZ", "CNZ_CONTRA"}, ;
                       {"CNX", "CNX_CONTRA"}, {"CPD", "CPD_CONTRA"}, {"ZLG", "ZLG_CONTRA"}, {"ZLG", "ZLG_NUMERO"}}
    Local bPrevErr := ErrorBlock({|e| Break(e)})
    Local oErr     := Nil
    Local cMsg     := ""
    Local cAlias   := ""
    Local cCampo   := ""
    Local cAliasQ  := ""
    Local cQuery   := ""
    Local cChvAnt  := ""
    Local cChvNov  := ""
    Local nI       := 0

    Begin Transaction
    Begin Sequence
        For nI := 1 To Len(aMapa)
            cAlias := aMapa[nI][1]
            cCampo := aMapa[nI][2]
            If !AliasInDic(cAlias)
                Loop
            EndIf
            DbSelectArea(cAlias)
            If (cAlias)->(FieldPos(cCampo)) == 0
                Loop
            EndIf
            cQuery := "SELECT R_E_C_N_O_ AS REC FROM " + RetSqlName(cAlias) + ;
                      " WHERE D_E_L_E_T_ = ' '" + ;
                      IIf((cAlias)->(FieldPos(cAlias + "_FILIAL")) > 0, " AND " + cAlias + "_FILIAL = '" + xFilial(cAlias) + "'", "") + ;
                      " AND " + cCampo + " = '" + Padr(cAntigo, TamSX3(cCampo)[1]) + "'"
            cAliasQ := GetNextAlias()
            DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAliasQ, .F., .T.)
            While (cAliasQ)->(!Eof())
                (cAlias)->(DbGoTo((cAliasQ)->REC))
                If !RecLock(cAlias, .F.)
                    cMsg := "registro da tabela " + cAlias + " bloqueado por outro usuario."
                    Break
                EndIf
                (cAlias)->(FieldPut(FieldPos(cCampo), Padr(cNovo, TamSX3(cCampo)[1])))
                (cAlias)->(MsUnlock())
                (cAliasQ)->(DbSkip())
            EndDo
            (cAliasQ)->(DbCloseArea())
        Next nI

        // Anexos (Banco de Conhecimento): AC9_CODENT = FILIAL+NUMERO (ver ZcnAnChave)
        cChvAnt := Padr(ZcnAnChave(cAntigo), TamSX3("AC9_CODENT")[1])
        cChvNov := Padr(ZcnAnChave(cNovo), TamSX3("AC9_CODENT")[1])
        cQuery  := "SELECT R_E_C_N_O_ AS REC FROM " + RetSqlName("AC9") + ;
                   " WHERE D_E_L_E_T_ = ' ' AND AC9_FILIAL = '" + xFilial("AC9") + "'" + ;
                   " AND AC9_ENTIDA = 'CN9' AND AC9_CODENT = '" + cChvAnt + "'"
        cAliasQ := GetNextAlias()
        DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAliasQ, .F., .T.)
        While (cAliasQ)->(!Eof())
            AC9->(DbGoTo((cAliasQ)->REC))
            If RecLock("AC9", .F.)
                AC9->AC9_CODENT := cChvNov
                AC9->(MsUnlock())
            EndIf
            (cAliasQ)->(DbSkip())
        EndDo
        (cAliasQ)->(DbCloseArea())
    Recover Using oErr
        If Empty(cMsg)
            cMsg := IIf(ValType(oErr) == "O", AllTrim(oErr:Description), "erro desconhecido")
        EndIf
    End Sequence
    If !Empty(cMsg)
        If Select(cAliasQ) > 0
            (cAliasQ)->(DbCloseArea())
        EndIf
        DisarmTransaction()
    EndIf
    End Transaction

    ErrorBlock(bPrevErr)

Return cMsg

/*/{Protheus.doc} ZcnCnbDel
Garante a exclusao dos itens removidos na tela (aItmDel, montado por ZcnAtuItens) DEPOIS do
CommitData de ZcnAtu. Bug de producao (2026-10-20): o DeleteLine do CNBDETAIL voltava .T., o
commit passava, mas os itens continuavam gravados e "voltavam" para a planilha ao recarregar.
Aqui cada item que ainda existir (CNB nao deletado) e apagado direto -- se o commit do modelo ja
tiver apagado, a query nao acha nada e nada e feito.
@type Static Function
@param cContra caractere, numero do contrato
@param cRevisa caractere, revisao
@param aItmDel array, {{planilha, CNB_ITEM}, ...}
@return Nil
/*/
//=============================================================================================================================
Static Function ZcnCnbDel(cContra, cRevisa, aItmDel)

    Local cAliasQ := ""
    Local cCtr    := Padr(cContra, TamSX3("CNB_CONTRA")[1])
    Local cRev    := Padr(cRevisa, TamSX3("CNB_REVISA")[1])
    Local cPla    := ""
    Local cItm    := ""
    Local nI      := 0

    For nI := 1 To Len(aItmDel)
        cPla    := Padr(aItmDel[nI][1], TamSX3("CNB_NUMERO")[1])
        cItm    := Padr(aItmDel[nI][2], TamSX3("CNB_ITEM")[1])
        cAliasQ := GetNextAlias()
        BeginSql Alias cAliasQ
            SELECT CNB.R_E_C_N_O_ AS RECCNB
              FROM %table:CNB% CNB
             WHERE CNB.%notDel%
               AND CNB.CNB_FILIAL = %xfilial:CNB%
               AND CNB.CNB_CONTRA = %exp:cCtr%
               AND CNB.CNB_REVISA = %exp:cRev%
               AND CNB.CNB_NUMERO = %exp:cPla%
               AND CNB.CNB_ITEM   = %exp:cItm%
        EndSql
        While (cAliasQ)->(!Eof())
            CNB->(DbGoTo((cAliasQ)->RECCNB))
            If CNB->(!Eof()) .And. RecLock("CNB", .F.)
                CNB->(DbDelete())
                CNB->(MsUnlock())
            EndIf
            (cAliasQ)->(DbSkip())
        EndDo
        (cAliasQ)->(DbCloseArea())
    Next nI

Return Nil

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
    Case cD == "02" ; cLista := "03/05/01"          // Em Elaboracao (pedido usuario 2026-09-23: direto pra Emitido, Vigente ou Cancelado)
    Case cD == "03" ; cLista := "04/02/01"         // Emitido
    Case cD == "04" ; cLista := "05/02/01"         // Em Aprovacao
    Case cD == "05" ; cLista := "06/07/09/02"      // Vigente (02 pedido usuario 2026-10-20; ZcnSit recusa se houver medicao)
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

    Recover
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

    // Vigente -> Em Elaboracao: em elaboracao as planilhas/itens voltam a ser editaveis, o que nao
    // pode acontecer com o contrato ja medido.
    If cAtual == "05" .And. cSituac == "02" .And. ZcnPlaMed(cNumero, cRevisao, "")
        oResp["success"] := .F.
        oResp["message"] := "O contrato ja possui medicao e nao pode voltar para Em Elaboracao."
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

/*/{Protheus.doc} ZcnExcluir
Exclui DEFINITIVAMENTE um contrato (operacao "contratoExcluir") -- pedido do
usuario 2026-09-23 ("Deletar contrato" na tela, so visivel enquanto o
contrato esta em elaboracao). NAO EXISTIA nenhuma rotina de exclusao neste
projeto ate agora (ver nota antiga em ZcnCriar/ZcnAtu sobre isso) -- e uma
operacao NOVA e DESTRUTIVA, sem historico de uso neste codebase.
Guarda de seguranca: SO EXCLUI se CN9_SITUAC (da revisao) for "02" (Em
Elaboracao) -- um contrato que ja foi emitido/aprovado/vigente tem que ser
encerrado via mudanca de situacao (ZcnSit), nunca apagado. Essa checagem e
feita aqui no backend (nao so escondendo o botao no Angular) porque e a
unica garantia real contra excluir um contrato que ja saiu do rascunho.
Usa FWLoadModel + MODEL_OPERATION_DELETE (mesmo padrao MVC oficial de
exclusao do Protheus) -- cascateia para CNCDETAIL/CNADETAIL/CNBDETAIL via
relacao de submodelo, igual ZcnCriar faz pra INSERT. ErrorBlock trocado por
Break(e) ANTES do Begin Sequence (mesmo padrao de ZcnIndice, mais abaixo
neste arquivo) -- assim Recover so entra em erro de runtime DE VERDADE (com
objeto de erro real, :Description acessivel); as saidas esperadas (Activate/
VldData/CommitData falhando) usam Return direto, sem passar pelo Recover.
@type Static Function
@param oReq JsonObject, {numero, revisao (opcional, usa CN9_REVATU se vazio)}
@return JsonObject, {success, message}
/*/
//=============================================================================================================================
Static Function ZcnExcluir(oReq)

    Local oResp    := JsonObject():New()
    Local oModel   := Nil
    Local oErr     := Nil
    Local bPrev    := Nil
    Local cNumero  := ""
    Local cRevisao := ""
    Local cAtual   := ""
    Local cTipo    := ""
    Local cModelId := ""
    Local nTamNum  := 0
    Local nTamRev  := 0

    If ValType(oReq["numero"]) == "C" ; cNumero  := AllTrim(oReq["numero"])  ; EndIf
    If ValType(oReq["revisao"]) == "C" ; cRevisao := AllTrim(oReq["revisao"]) ; EndIf

    If Empty(cNumero)
        oResp["success"] := .F.
        oResp["message"] := "Numero do contrato e obrigatorio."
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
    If cAtual != "02"
        oResp["success"] := .F.
        oResp["message"] := "So e possivel excluir um contrato em elaboracao (situacao atual: " + ZcnSitDesc(cAtual) + ")."
        Return oResp
    EndIf

    cTipo    := IIf(AllTrim(CN9->CN9_ESPCTR) == "1", "C", "V")
    cModelId := IIf(cTipo == "C", "CNTA300", "CNTA301")

    bPrev := ErrorBlock({|e| Break(e)})
    Begin Sequence

    oModel := FWLoadModel(cModelId)
    oModel:SetOperation(MODEL_OPERATION_DELETE)

    If !oModel:Activate()
        ErrorBlock(bPrev)
        oResp["success"] := .F.
        oResp["message"] := "Nao foi possivel ativar o modelo do contrato para exclusao." + ;
            IIf(Empty(ZcnErrMsg(oModel)), "", " " + ZcnErrMsg(oModel))
        Return oResp
    EndIf

    If !oModel:VldData()
        oModel:DeActivate()
        ErrorBlock(bPrev)
        oResp["success"] := .F.
        oResp["message"] := "Nao foi possivel validar a exclusao do contrato." + ;
            IIf(Empty(ZcnErrMsg(oModel)), "", " " + ZcnErrMsg(oModel))
        Return oResp
    EndIf

    If !oModel:CommitData()
        oResp["success"] := .F.
        oResp["message"] := "Falha ao excluir o contrato." + IIf(Empty(ZcnErrMsg(oModel)), "", " " + ZcnErrMsg(oModel))
        oModel:DeActivate()
        ErrorBlock(bPrev)
        Return oResp
    EndIf

    oModel:DeActivate()
    ErrorBlock(bPrev)

    oResp["success"] := .T.
    oResp["message"] := "Contrato excluido com sucesso."

    Recover Using oErr
        ErrorBlock(bPrev)
        oResp["success"] := .F.
        oResp["message"] := "Falha inesperada ao excluir o contrato: " + AllTrim(oErr:Description)
    End Sequence

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

    Recover
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
    Case cAcao == "REVISAO"              ; cRet := "Revisao do contrato aberta"
    Case cAcao == "TITULO_GERADO"        ; cRet := "Titulo financeiro gerado"
    Case cAcao == "MEDICAO_INCLUSAO"     ; cRet := "Medicao incluida"
    Case cAcao == "MEDICAO_ALTERACAO"    ; cRet := "Medicao alterada"
    Case cAcao == "MEDICAO_EXCLUSAO"     ; cRet := "Medicao excluida"
    Case cAcao == "MEDICAO_ESTORNO"      ; cRet := "Medicao estornada"
    Case cAcao == "PEDIDO_COMPRA_GERADO" ; cRet := "Pedido de compra gerado"
    Case cAcao == "NUMERO_ALTERADO"      ; cRet := "Numero do contrato alterado"
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
Tela de revisao = a mesma tela do contrato (contrato-editor, modo "revisar",
pedido do usuario 2026-09-24) -- nao existe mais a tela de selecao do tipo de
revisao. Numa unica gravacao (um so CommitData) a revisao pode:
  - alterar os campos do cabecalho ("header", mesmos campos de ZcnCriar);
  - excluir o cronograma financeiro de planilhas JA EXISTENTES
    ("excluirCronograma", lista de CNA_NUMERO) -- planilhas/itens existentes
    NUNCA sao alterados aqui, so o cronograma pode ser removido;
  - incluir planilhas NOVAS ("planilhas", mesmo formato de ZcnCriar), cada uma
    com o seu proprio cronograma opcional ("cronograma", mesmos parametros do
    Pergunte CN300CRG usados em ZcnGrCrg).
"tipoRevisao" deixou de vir da tela: sem ele, usa o parametro MV_ZCNTREV
(default "G" = Revisao Aberta, o tipo que libera alterar todos os campos).
@type Static Function
@param oReq JsonObject, {numero, revisaoBase (opcional), tipoRevisao (opcional), justificativa, header:{...} (opcional), excluirCronograma:[numeroPlanilha] (opcional), planilhas:[{tipoPlanilha,pessoa,itens:[...],cronograma:{...}}] (opcional)}
@return JsonObject, ver ZcnMont (ou {success:.F., message})
/*/
//=============================================================================================================================
Static Function ZcnRevAb(oReq)

    Local oResp         := JsonObject():New()
    Local oModel         := Nil
    Local oModelCNA       := Nil
    Local oModelCNB        := Nil
    Local oHeader           := oReq["header"]
    Local aPlanilhas         := oReq["planilhas"]
    Local aExcCrg             := oReq["excluirCronograma"]
    Local aFalhas              := {}
    Local aAvisos               := {}
    Local cNumero              := ""
    Local cRevisaoBase          := ""
    Local cTipoRevisao           := ""
    Local cTpRevCod              := ""
    Local cTpRevEsp              := ""
    Local cJustific               := ""
    Local cModelId                 := ""
    Local cTipo                     := ""
    Local cNovaRevisao                := ""
    Local cMsg                         := ""
    Local nP                            := 0
    Local nI                             := 0
    Local nMaxPla                         := 0
    Local oPla                            := Nil
    Local nTamNum                           := 0
    Local nTamRev                            := 0
    Local oErrCatch                          := Nil
    Local lOk                                := .T.
    Local cFalha                             := ""
    Local bPrevErr                           := Nil

    If ValType(oReq["numero"]) == "C" ; cNumero := AllTrim(oReq["numero"]) ; EndIf
    If ValType(oReq["revisaoBase"]) == "C" ; cRevisaoBase := AllTrim(oReq["revisaoBase"]) ; EndIf
    If ValType(oReq["tipoRevisao"]) == "C" ; cTipoRevisao := AllTrim(oReq["tipoRevisao"]) ; EndIf
    If ValType(oReq["justificativa"]) == "C" ; cJustific := AllTrim(oReq["justificativa"]) ; EndIf
    If ValType(aPlanilhas) != "A" ; aPlanilhas := {} ; EndIf
    If ValType(aExcCrg) != "A" ; aExcCrg := {} ; EndIf
    If !(ValType(oHeader) $ "JO") ; oHeader := Nil ; EndIf
    If Empty(cTipoRevisao)
        cTipoRevisao := AllTrim(SuperGetMV("MV_ZCNTREV", .F., "G"))
    EndIf

    If Empty(cNumero) .Or. Empty(cJustific)
        oResp["success"] := .F.
        oResp["message"] := "Numero do contrato e justificativa da revisao sao obrigatorios"
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

    // CN9_TIPREV e o CODIGO do cadastro de tipos de revisao (CN0_CODIGO, ex.: "001"), validado
    // contra CN0 ordem 1; A300STpRev recebe a ESPECIE (CN0_TIPO, 1..G). Gravar "G" direto no
    // CN9_TIPREV dava REGNOIS no CN0 + CNTA300OPN "Informe o tipo de Revisao" (2026-09-28).
    cTpRevCod := ZcnTpRvCod(cTipoRevisao, @cTpRevEsp)
    If Empty(cTpRevCod)
        oResp["success"] := .F.
        oResp["message"] := "Nenhum tipo de revisao cadastrado (CN0) para [" + cTipoRevisao + "]. Cadastre um tipo de revisao com essa especie ou ajuste o parametro MV_ZCNTREV."
        Return oResp
    EndIf

    A300STpRev(cTpRevEsp)

    // Mesmo motivo do Begin Sequence em ZcnCriar: manipulacao de modelo MVC ja quebrou com
    // erro de runtime do proprio framework nesta sessao -- converte pra JSON de erro comum em
    // vez de THREAD ERROR.
    // ErrorBlock com Break: sem ele o Begin Sequence nao captura erro de runtime do framework
    // (virava THREAD ERROR na tela -- 2026-10-09).
    bPrevErr := ErrorBlock({|e| Break(e)})
    Begin Sequence

    oModel := FWLoadModel(cModelId)
    oModel:SetOperation(MODEL_OPERATION_INSERT)
    // Activate(.T.) = copia da revisao base. Se o CNTA300 recusar abrir a revisao (situacao do
    // contrato, revisao ja em aberto, tipo de revisao...), devolve o motivo do modelo em vez de
    // seguir para o SetValue com o modelo inativo ("Ative a classe (Activate) antes de utilizar
    // este metodo", 2026-10-09).
    If !oModel:Activate(.T.)
        cMsg := ZcnErrMsg(oModel)
        ErrorBlock(bPrevErr)
        oResp["success"] := .F.
        oResp["message"] := "Nao foi possivel abrir a revisao do contrato " + cNumero + "/" + cRevisaoBase + "." + ;
            IIf(Empty(cMsg), " Verifique se o contrato esta vigente e sem outra revisao em aberto.", " " + cMsg)
        Return oResp
    EndIf

    oModel:SetValue('CN9MASTER', 'CN9_TIPREV', cTpRevCod)
    oModel:SetValue('CN9MASTER', 'CN9_JUSTIF', cJustific)

    // Cabecalho -- mesmos campos de ZcnCriar, mas via ZcnRvSet: so grava o que MUDOU em relacao
    // a revisao base (evita disparar gatilho/validacao de campo que o usuario nem tocou) e usa
    // ZcnTrySet por baixo, entao um campo bloqueado pelo tipo de revisao vira mensagem clara em
    // aFalhas em vez de THREAD ERROR.
    If oHeader != Nil
        If ValType(oHeader["dataInicio"]) == "C" .And. !Empty(AllTrim(oHeader["dataInicio"]))
            ZcnRvSet(oModel, aFalhas, 'CN9_DTINIC', ZcnSToD(oHeader["dataInicio"]))
        EndIf
        If ValType(oHeader["unidadeVigencia"]) == "C" .And. !Empty(AllTrim(oHeader["unidadeVigencia"]))
            ZcnRvSet(oModel, aFalhas, 'CN9_UNVIGE', AllTrim(oHeader["unidadeVigencia"]))
        EndIf
        If ValType(oHeader["vigencia"]) == "N" .And. oHeader["vigencia"] > 0
            ZcnRvSet(oModel, aFalhas, 'CN9_VIGE', oHeader["vigencia"])
        EndIf
        If ValType(oHeader["moeda"]) == "N" .And. oHeader["moeda"] > 0
            ZcnRvSet(oModel, aFalhas, 'CN9_MOEDA', ZcnMoedaVl(oHeader["moeda"]))
        EndIf
        If ValType(oHeader["condPagto"]) == "C" .And. !Empty(AllTrim(oHeader["condPagto"]))
            ZcnRvSet(oModel, aFalhas, 'CN9_CONDPG', AllTrim(oHeader["condPagto"]))
        EndIf
        If ValType(oHeader["tipoContrato"]) == "C" .And. !Empty(AllTrim(oHeader["tipoContrato"]))
            ZcnRvSet(oModel, aFalhas, 'CN9_TPCTO', AllTrim(oHeader["tipoContrato"]))
        EndIf
        If ValType(oHeader["natureza"]) == "C" .And. !Empty(AllTrim(oHeader["natureza"]))
            ZcnRvSet(oModel, aFalhas, 'CN9_NATURE', AllTrim(oHeader["natureza"]))
        EndIf
        If ValType(oHeader["dtAssinatura"]) == "C" .And. !Empty(AllTrim(oHeader["dtAssinatura"]))
            ZcnRvSet(oModel, aFalhas, 'CN9_ASSINA', ZcnSToD(oHeader["dtAssinatura"]))
        EndIf
        If ValType(oHeader["objeto"]) == "C"
            ZcnRvSet(oModel, aFalhas, 'CN9_OBJCTO', AllTrim(oHeader["objeto"]))
        EndIf
        If ValType(oHeader["clausula"]) == "C"
            ZcnRvSet(oModel, aFalhas, 'CN9_ALTCLA', AllTrim(oHeader["clausula"]))
        EndIf
        ZcnPlaSet(oModel, aFalhas, aAvisos, "descCtr", 'CN9MASTER', oHeader["descricao"])
    EndIf

    // Cada etapa abaixo so roda se a anterior nao acumulou falha (lOk/cFalha) -- sem Break:
    // dentro deste Begin Sequence ele cairia no Recover com oErrCatch Nil.
    If Len(aFalhas) > 0
        lOk    := .F.
        cFalha := "Falha ao alterar o cabecalho do contrato na revisao: " + aFalhas[1]
    EndIf

    oModelCNA := oModel:GetModel('CNADETAIL')
    oModelCNB := oModel:GetModel('CNBDETAIL')

    // Excluir o cronograma financeiro de planilhas EXISTENTES -- as planilhas/itens em si
    // continuam intocados (regra do usuario: planilha existente nao pode ser alterada).
    If lOk
        For nP := 1 To Len(aExcCrg)
            If ValType(aExcCrg[nP]) == "C" .And. !Empty(AllTrim(aExcCrg[nP]))
                ZcnRvDlCrg(oModel, aFalhas, AllTrim(aExcCrg[nP]))
            EndIf
        Next nP
        If Len(aFalhas) > 0
            lOk    := .F.
            cFalha := "Falha ao excluir o cronograma financeiro: " + aFalhas[1]
        EndIf
    EndIf

    If lOk .And. Len(aPlanilhas) > 0
        // CNA_NUMERO da planilha nova = maior numero existente + 1 (nao GetLine() -- a
        // numeracao das planilhas da revisao base pode ter buracos).
        For nI := 1 To oModelCNA:Length()
            oModelCNA:GoLine(nI)
            nMaxPla := Max(nMaxPla, Val(oModelCNA:GetValue('CNA_NUMERO')))
        Next nI

        For nP := 1 To Len(aPlanilhas)
            If !lOk
                Exit
            EndIf
            oPla := aPlanilhas[nP]

            nMaxPla++
            ZcnPlaNova(oModel, aFalhas, aAvisos, oPla, cNumero, cTipo, StrZero(nMaxPla, Len(CNA->CNA_NUMERO)))

            If Len(aFalhas) > 0
                lOk    := .F.
                cFalha := "Falha ao preencher a nova planilha " + StrZero(nMaxPla, Len(CNA->CNA_NUMERO)) + ": " + aFalhas[1]
                Loop
            EndIf

            // Cronograma da planilha nova -- mesmo mecanismo de ZcnGrCrg (Pergunte CN300CRG +
            // CN300PrCF), rodando com a CNADETAIL posicionada NESTA planilha, dentro do mesmo
            // modelo da revisao (um so CommitData no fim).
            If ValType(oPla["cronograma"]) $ "JO"
                ZcnRvCrg(oModel, aFalhas, oPla["cronograma"])
                If Len(aFalhas) > 0
                    lOk    := .F.
                    cFalha := "Falha ao gerar o cronograma da nova planilha " + StrZero(nMaxPla, Len(CNA->CNA_NUMERO)) + ": " + aFalhas[1]
                EndIf
            EndIf
        Next nP
    EndIf

    If !lOk
        oModel:DeActivate()
        oResp["success"] := .F.
        oResp["message"] := cFalha
    ElseIf oModel:VldData()
        oModel:CommitData()
        cNovaRevisao := AllTrim(oModel:GetValue('CN9MASTER', 'CN9_REVISA'))
        oModel:DeActivate()
        // Revisao vazia no cache do modelo: usa a MAIOR revisao gravada (a recem-aberta), nunca o
        // CN9_REVATU -- ele so muda na aprovacao e apontava a tela para a revisao ORIGINAL.
        If Empty(cNovaRevisao) .Or. cNovaRevisao == AllTrim(cRevisaoBase)
            cNovaRevisao := ZcnUltRev(cNumero)
        EndIf
        // Mesmo cuidado de ZcnCriar: CN9_REVISA pode vir vazio do cache do modelo logo apos o
        // commit -- nesse caso ZcnMont usa CN9_REVATU (a revisao recem-aberta).
        oResp := ZcnMont(cNumero, cNovaRevisao)
        If Len(aAvisos) > 0
            oResp["avisos"] := aAvisos
        EndIf
        If oResp["success"] == .T.
            cNovaRevisao := AllTrim(oResp["header"]["revisao"])
            // antes/depois vazios: a timeline (ZcnTL) traduz esses campos como SITUACAO.
            ZcnZlgPut(cNumero, cNovaRevisao, "REVISAO", "", "", "Revisao base " + cRevisaoBase + ": " + cJustific)
        EndIf
    Else
        cMsg := ZcnErrMsg(oModel)
        oModel:DeActivate()
        oResp["success"] := .F.
        oResp["message"] := IIf(Empty(cMsg), "Falha na validacao da revisao.", cMsg)
    EndIf

    Recover Using oErrCatch
        oResp := JsonObject():New()
        oResp["success"] := .F.
        oResp["message"] := "Erro interno ao abrir revisao" + IIf(ValType(oErrCatch) == "O", ": " + AllTrim(oErrCatch:description) +;
            IIf(ValType(oErrCatch:operation) == "C" .And. !Empty(oErrCatch:operation), " (" + AllTrim(oErrCatch:operation) + ")", ""), "")
    End Sequence
    ErrorBlock(bPrevErr)

Return oResp

/*/{Protheus.doc} ZcnPlaNova
Inclui uma planilha NOVA (CNADETAIL + itens CNBDETAIL) num modelo CNTA300/CNTA301 ja ativo --
usado na revisao (ZcnRevAb) e na alteracao de contrato em elaboracao sem medicao (ZcnAtu, pedido
do usuario 2026-10-07). Pessoa: a da planilha, ou a do contrato (CNCDETAIL) se nao vier.
CNA_DTINI: data base > data inicio da planilha > CN9_DTINIC do modelo.
@type Static Function
@param oModel objeto, modelo ativo
@param aFalhas array, acumulador de falhas
@param aAvisos array, campos nao localizados no dicionario (ZcnPlaSet)
@param oPla JsonObject, planilha (ver PlanilhaPayload no Angular)
@param cNumero caractere, numero do contrato
@param cTipo caractere, "C" compra / "V" venda
@param cNumPla caractere, CNA_NUMERO da planilha nova
@return Nil
/*/
//=============================================================================================================================
Static Function ZcnPlaNova(oModel, aFalhas, aAvisos, oPla, cNumero, cTipo, cNumPla)

    Local oModelCNB := oModel:GetModel('CNBDETAIL')
    Local aItens    := {}
    Local oItm      := Nil
    Local dDtIniPla := CToD("")
    Local nI        := 0

    If !ZcnAddLn(oModel, oModel:GetModel('CNADETAIL'), aFalhas, "planilha " + cNumPla)
        Return Nil
    EndIf

    // Forma dispatcher (oModel:SetValue('CNADETAIL', campo, valor)), nao mais direto no
    // submodelo -- mesma correcao de ZcnCriar, baseada no exemplo oficial completo que
    // o usuario conseguiu (2026-08-11): CNADETAIL/CNBDETAIL nunca sao editados via
    // objeto de submodelo direto em nenhum exemplo real, sempre via oModel:SetValue com
    // o id do submodelo como parametro. CNA_CONTRA via LoadValue (unico campo assim).
    oModel:LoadValue('CNADETAIL', 'CNA_CONTRA', cNumero)
    // CNA_NUMERO: com o modelo em ALTERACAO (Alterar Revisao/elaboracao, ZcnAtu) o CNTA300 recusa o
    // SetValue no campo-chave sem avisar e a validacao final acusava "Nr Planilha (CNA_NUMERO) nao
    // foi preenchido" (2026-10-09). Cai para LoadValue -- o numero ja e unico (maior + 1).
    If !oModel:SetValue('CNADETAIL', 'CNA_NUMERO', cNumPla)
        oModel:LoadValue('CNADETAIL', 'CNA_NUMERO', cNumPla)
    EndIf
    // CNA_REVISA da linha nova = revisao do contrato no modelo (a relacao nem sempre preenche em
    // alteracao).
    If Empty(oModel:GetValue('CNADETAIL', 'CNA_REVISA'))
        oModel:LoadValue('CNADETAIL', 'CNA_REVISA', oModel:GetValue('CN9MASTER', 'CN9_REVISA'))
    EndIf
    If Empty(oModel:GetValue('CNADETAIL', 'CNA_NUMERO'))
        AAdd(aFalhas, "nao foi possivel preencher o numero da planilha (CNA_NUMERO)." + ;
            IIf(Empty(ZcnErrMsg(oModel)), "", " " + ZcnErrMsg(oModel)))
        Return Nil
    EndIf
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
        If dDtIniPla < dDataBase
            AAdd(aFalhas, "a data base da planilha (" + DToC(dDtIniPla) + ") nao pode ser anterior a data base do sistema (" + DToC(dDataBase) + ").")
            Return Nil
        EndIf
    ElseIf ValType(oPla["dataInicio"]) == "C" .And. !Empty(AllTrim(oPla["dataInicio"]))
        dDtIniPla := ZcnSToD(oPla["dataInicio"])
    Else
        dDtIniPla := oModel:GetValue('CN9MASTER', 'CN9_DTINIC')
    EndIf
    If !Empty(dDtIniPla)
        ZcnTrySet(oModel, aFalhas, 'CNADETAIL', 'CNA_DTINI', dDtIniPla)
    EndIf
    If ValType(oPla["dataFim"]) == "C" .And. !Empty(AllTrim(oPla["dataFim"]))
        ZcnTrySet(oModel, aFalhas, 'CNADETAIL', 'CNA_DTFIM', ZcnSToD(oPla["dataFim"]))
    EndIf
    // Campos da planilha resolvidos pelo dicionario -- mesmos de ZcnCriar. A Data base e o
    // proprio CNA_DTINI, ja gravado acima.
    ZcnPlaSet(oModel, aFalhas, aAvisos, "descPla", 'CNADETAIL', oPla["descricao"])
    ZcnPlaSet(oModel, aFalhas, aAvisos, "indice", 'CNADETAIL', oPla["indice"])
    ZcnPlaSet(oModel, aFalhas, aAvisos, "periodicidade", 'CNADETAIL', oPla["periodicidade"])
    ZcnPlaSet(oModel, aFalhas, aAvisos, "unidadePer", 'CNADETAIL', oPla["unidadePer"])
    ZcnPlaSet(oModel, aFalhas, aAvisos, "modoReajuste", 'CNADETAIL', oPla["modoReajuste"])

    aItens := oPla["itens"]
    If ValType(aItens) != "A" ; aItens := {} ; EndIf
    For nI := 1 To Len(aItens)
        oItm := aItens[nI]
        // Length() < nI (nao "nI > 1") -- mesma cautela do fix de CNCDETAIL em
        // ZcnCriar: a linha 1 desta planilha (recem-criada por AddLine acima) pode nao
        // vir pronta para edicao, confere antes de assumir. Da 2a linha em diante,
        // ZcnAddLn confere que a linha foi de fato criada (antes um AddLine recusado
        // fazia o item seguinte sobrescrever o anterior).
        If oModelCNB:Length() >= nI
            oModelCNB:GoLine(nI)
        ElseIf !ZcnAddLn(oModel, oModelCNB, aFalhas, "item " + StrZero(nI, Len(CNB->CNB_ITEM)))
            Exit
        EndIf
        ZcnItmGrv(oModel, aFalhas, oItm, StrZero(nI, Len(CNB->CNB_ITEM)))
        If Len(aFalhas) > 0
            Exit
        EndIf
    Next nI

Return Nil

/*/{Protheus.doc} ZcnTpRvCod
Resolve o tipo de revisao para o par (codigo CN0_CODIGO, especie CN0_TIPO). Aceita tanto um
codigo ja cadastrado em CN0 (ex.: "001") quanto uma especie (ex.: "G" = Revisao Aberta) -- no
segundo caso usa o primeiro codigo de CN0 dessa especie.
@type Static Function
@param cTpRev caractere, codigo CN0 ou especie
@param cEspecie caractere, por referencia -- recebe a especie (CN0_TIPO) para A300STpRev
@return caractere, CN0_CODIGO para CN9_TIPREV (vazio se nao encontrado)
/*/
//=============================================================================================================================
Static Function ZcnTpRvCod(cTpRev, cEspecie)

    Local cCodigo := ""
    Local cAliasQ := ""

    cEspecie := cTpRev

    CN0->(dbSetOrder(1)) // CN0_FILIAL+CN0_CODIGO
    If Len(cTpRev) > 1 .And. CN0->(dbSeek(xFilial("CN0") + Padr(cTpRev, Len(CN0->CN0_CODIGO))))
        cCodigo  := CN0->CN0_CODIGO
        cEspecie := AllTrim(CN0->CN0_TIPO)
        Return cCodigo
    EndIf

    cAliasQ := GetNextAlias()
    BeginSql Alias cAliasQ
        SELECT MIN(CN0.CN0_CODIGO) AS CODIGO
          FROM %table:CN0% CN0
         WHERE CN0.%notDel%
           AND CN0.CN0_FILIAL = %xfilial:CN0%
           AND CN0.CN0_TIPO = %exp:cTpRev%
    EndSql
    If !(cAliasQ)->(Eof())
        cCodigo := AllTrim((cAliasQ)->CODIGO)
    EndIf
    (cAliasQ)->(dbCloseArea())

Return cCodigo

/*/{Protheus.doc} ZcnRvSet
Grava um campo do cabecalho (CN9MASTER) na revisao SO se o valor mudou em relacao ao que o
modelo ja carregou da revisao base -- evita disparar gatilho/validacao de campo que o usuario
nem tocou (alguns ficam bloqueados conforme o tipo de revisao). Usa ZcnTrySet, entao uma
recusa do framework vira mensagem em aFalhas.
@type Static Function
@param oModel objeto, modelo da revisao ja ativo
@param aFalhas array, acumulador de falhas
@param cCampo caractere, campo de CN9MASTER
@param xNovo generico, valor novo
@return Nil
/*/
//=============================================================================================================================
Static Function ZcnRvSet(oModel, aFalhas, cCampo, xNovo)

    Local xAtual := oModel:GetValue('CN9MASTER', cCampo)

    If ValType(xAtual) == "C" .And. ValType(xNovo) == "C"
        If AllTrim(xAtual) == AllTrim(xNovo)
            Return Nil
        EndIf
    ElseIf ValType(xAtual) == ValType(xNovo) .And. xAtual == xNovo
        Return Nil
    EndIf

    ZcnTrySet(oModel, aFalhas, 'CN9MASTER', cCampo, xNovo)

Return Nil

/*/{Protheus.doc} ZcnRvDlCrg
Exclui (DeleteLine) todas as parcelas do cronograma financeiro (CNFDETAIL) de UMA planilha ja
existente, dentro do modelo da revisao -- a planilha e os itens continuam intocados. Parcela
que o framework nao deixar excluir (ex.: ja medida) vira mensagem em aFalhas. Mesmo ErrorBlock
de ZcnTrySet, pra erro de runtime do MVC nao virar THREAD ERROR.
@type Static Function
@param oModel objeto, modelo da revisao ja ativo
@param aFalhas array, acumulador de falhas
@param cNumPla caractere, CNA_NUMERO da planilha
@return Nil
/*/
//=============================================================================================================================
Static Function ZcnRvDlCrg(oModel, aFalhas, cNumPla)

    Local bPrevErr := ErrorBlock({|e| Break(e)})
    Local oErr     := Nil
    Local oMdlCNA  := Nil
    Local oMdlCNF  := Nil
    Local lAchou   := .F.
    Local nL       := 0

    Begin Sequence
        oMdlCNA := oModel:GetModel('CNADETAIL')
        For nL := 1 To oMdlCNA:Length()
            oMdlCNA:GoLine(nL)
            If Val(oMdlCNA:GetValue('CNA_NUMERO')) == Val(cNumPla)
                lAchou := .T.
                Exit
            EndIf
        Next nL

        If !lAchou
            AAdd(aFalhas, "Planilha [" + cNumPla + "] nao encontrada na revisao.")
        Else
            oMdlCNF := oModel:GetModel('CNFDETAIL')
            If oMdlCNF == Nil
                AAdd(aFalhas, "Submodelo do cronograma financeiro (CNFDETAIL) nao localizado no modelo do contrato.")
            ElseIf !oMdlCNF:IsEmpty()
                For nL := 1 To oMdlCNF:Length()
                    oMdlCNF:GoLine(nL)
                    If !oMdlCNF:IsDeleted() .And. !oMdlCNF:DeleteLine()
                        AAdd(aFalhas, "Planilha [" + cNumPla + "], parcela " + AllTrim(cValToChar(nL)) + ": " + ZcnErrMsg(oModel))
                        Exit
                    EndIf
                Next nL
            EndIf
            // Sem cronograma: limpa o numero do cronograma da planilha (CNA_CRONOG) -- senao o
            // CN300PrCF recusa gerar outro ("Esta planilha ja possui um cronograma financeiro
            // associado", 2026-10-09).
            If Len(aFalhas) == 0 .And. !Empty(ZcnCpo({"CNA_CRONOG"}))
                oModel:LoadValue('CNADETAIL', 'CNA_CRONOG', Space(TamSX3("CNA_CRONOG")[1]))
            EndIf
        EndIf
    Recover Using oErr
        AAdd(aFalhas, "Planilha [" + cNumPla + "]: " + AllTrim(oErr:Description))
    End Sequence

    ErrorBlock(bPrevErr)

Return Nil

/*/{Protheus.doc} ZcnPosPla
Posiciona a CNADETAIL do modelo na planilha informada (linha nao excluida).
@type Static Function
@param oModel objeto, modelo CNTA300/CNTA301 ativo
@param cNumPla caractere, numero da planilha (CNA_NUMERO)
@return logico, .T. se encontrou
/*/
//=============================================================================================================================
Static Function ZcnPosPla(oModel, cNumPla)

    Local oMdlCNA := oModel:GetModel('CNADETAIL')
    Local nL      := 0

    For nL := 1 To oMdlCNA:Length()
        oMdlCNA:GoLine(nL)
        If !oMdlCNA:IsDeleted() .And. Val(oMdlCNA:GetValue('CNA_NUMERO')) == Val(cNumPla)
            Return .T.
        EndIf
    Next nL

Return .F.

/*/{Protheus.doc} ZcnCrgLst
Parcelas do cronograma financeiro (CNF) de uma planilha -- exibidas no "Editar Parcela" da tela
(pedido do usuario 2026-10-09: o cronograma ja gerado nao aparecia). Campos opcionais via ZcnCpo;
qualquer erro de SQL devolve lista vazia.
@type Static Function
@param cContra caractere, numero do contrato
@param cRevisa caractere, revisao
@param cNumPla caractere, numero da planilha
@return array, [{parcela, competencia, data, valor, saldo}]
/*/
//=============================================================================================================================
Static Function ZcnCrgLst(cContra, cRevisa, cNumPla)

    Local aParc   := {}
    Local oParc   := Nil
    Local cAliasQ := GetNextAlias()
    Local cCpoDt  := ZcnCpo({"CNF_PRUMED", "CNF_DTVENC"})
    Local cQuery  := ""
    Local bPrev   := ErrorBlock({|e| Break(e)})

    cQuery := "SELECT CNF_PARCEL AS PARCEL, CNF_COMPET AS COMPET, CNF_VLPREV AS VLPREV, CNF_SALDO AS SALDO" + ;
              IIf(Empty(cCpoDt), "", ", " + cCpoDt + " AS DTPREV") + ;
              " FROM " + RetSqlName("CNF") + ;
              " WHERE D_E_L_E_T_ = ' ' AND CNF_FILIAL = '" + xFilial("CNF") + "'" + ;
              " AND CNF_CONTRA = '" + Padr(cContra, TamSX3("CNF_CONTRA")[1]) + "'" + ;
              " AND CNF_REVISA = '" + Padr(cRevisa, TamSX3("CNF_REVISA")[1]) + "'" + ;
              " AND CNF_NUMPLA = '" + Padr(cNumPla, TamSX3("CNF_NUMPLA")[1]) + "'" + ;
              " ORDER BY CNF_PARCEL"

    Begin Sequence
        DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAliasQ, .F., .T.)
        While (cAliasQ)->(!Eof())
            oParc := JsonObject():New()
            oParc["parcela"]     := Val(cValToChar((cAliasQ)->PARCEL))
            oParc["competencia"] := AllTrim((cAliasQ)->COMPET)
            oParc["data"]        := IIf(Empty(cCpoDt), "", ZcnDateStr((cAliasQ)->DTPREV))
            oParc["valor"]       := (cAliasQ)->VLPREV
            oParc["saldo"]       := (cAliasQ)->SALDO
            AAdd(aParc, oParc)
            (cAliasQ)->(DbSkip())
        EndDo
        (cAliasQ)->(DbCloseArea())
    Recover
        aParc := {}
        If Select(cAliasQ) > 0
            (cAliasQ)->(DbCloseArea())
        EndIf
    End Sequence

    ErrorBlock(bPrev)

Return aParc

/*/{Protheus.doc} ZcnCrgExc
Exclui o cronograma financeiro de uma planilha ja gravada (operacao "cronogramaExcluir", pedido do
usuario 2026-10-09) -- contrato em elaboracao, ou planilha incluida na revisao em aberto; nunca
planilha com medicao. Se o tipo da planilha exigir cronograma, o proprio CNTA300 recusa na
validacao (A300NCRON) e a mensagem volta para a tela -- nesse caso use "Substituir cronograma".
@type Static Function
@param oReq JsonObject, {numero, revisao, numPla}
@return JsonObject, ver ZcnMont (ou {success:.F., message})
/*/
//=============================================================================================================================
Static Function ZcnCrgExc(oReq)

    Local oResp    := JsonObject():New()
    Local oModel   := Nil
    Local cNumero  := ""
    Local cRevisao := ""
    Local cNumPla  := ""
    Local cMsg     := ""
    Local aFalhas  := {}
    Local bPrevErr := Nil
    Local oErr     := Nil

    If ValType(oReq["numero"]) == "C" ; cNumero  := AllTrim(oReq["numero"])  ; EndIf
    If ValType(oReq["revisao"]) == "C" ; cRevisao := AllTrim(oReq["revisao"]) ; EndIf
    If ValType(oReq["numPla"]) == "C" ; cNumPla  := AllTrim(oReq["numPla"])  ; EndIf

    CN9->(dbSetOrder(1))
    If Empty(cNumero) .Or. Empty(cNumPla) .Or. ;
       !CN9->(dbSeek(xFilial("CN9") + Padr(cNumero, TamSX3("CN9_NUMERO")[1]) + Padr(cRevisao, TamSX3("CN9_REVISA")[1])))
        oResp["success"] := .F.
        oResp["message"] := "Contrato/planilha nao encontrado (" + cNumero + "/" + cRevisao + ", planilha " + cNumPla + ")."
        Return oResp
    EndIf
    If !(AllTrim(CN9->CN9_SITUAC) == "02" .Or. (AllTrim(CN9->CN9_SITUAC) $ "09/A" .And. ZcnPlaNaRev(cNumero, cRevisao, cNumPla) .And. ;
         ZcnTemRevAnt(cNumero, cRevisao) .And. AllTrim(cRevisao) == ZcnUltRev(cNumero)))
        oResp["success"] := .F.
        oResp["message"] := "O cronograma so pode ser excluido com o contrato em elaboracao ou em planilha incluida na revisao em aberto."
        Return oResp
    EndIf
    If ZcnPlaMed(cNumero, cRevisao, cNumPla)
        oResp["success"] := .F.
        oResp["message"] := "A planilha " + cNumPla + " ja possui medicao -- o cronograma nao pode ser excluido."
        Return oResp
    EndIf

    bPrevErr := ErrorBlock({|e| Break(e)})
    Begin Sequence
        oModel := FWLoadModel(IIf(AllTrim(CN9->CN9_ESPCTR) == "1", "CNTA300", "CNTA301"))
        oModel:SetOperation(MODEL_OPERATION_UPDATE)
        If !oModel:Activate()
            oResp["success"] := .F.
            oResp["message"] := "Nao foi possivel abrir o contrato para alteracao. " + ZcnErrMsg(oModel)
        ElseIf !ZcnPosPla(oModel, cNumPla)
            oModel:DeActivate()
            oResp["success"] := .F.
            oResp["message"] := "Planilha [" + cNumPla + "] nao encontrada no contrato."
        Else
            ZcnRvDlCrg(oModel, aFalhas, cNumPla)
            If Len(aFalhas) > 0
                oModel:DeActivate()
                oResp["success"] := .F.
                oResp["message"] := "Falha ao excluir o cronograma: " + aFalhas[1]
            ElseIf oModel:VldData()
                oModel:CommitData()
                oModel:DeActivate()
                oResp := ZcnMont(cNumero, cRevisao)
                ZcnZlgPut(cNumero, cRevisao, "CRONOGRAMA_EXCLUIDO", "", "", "Cronograma financeiro da planilha " + cNumPla + " excluido")
            Else
                cMsg := ZcnErrMsg(oModel)
                oModel:DeActivate()
                oResp["success"] := .F.
                oResp["message"] := IIf(Empty(cMsg), "Falha na validacao do contrato.", cMsg)
            EndIf
        EndIf
    Recover Using oErr
        oResp := JsonObject():New()
        oResp["success"] := .F.
        oResp["message"] := "Erro interno ao excluir o cronograma" + IIf(ValType(oErr) == "O", ": " + AllTrim(oErr:Description), "")
    End Sequence
    ErrorBlock(bPrevErr)

Return oResp

/*/{Protheus.doc} ZcnRvCrg
Gera o cronograma financeiro/fisico da planilha POSICIONADA na CNADETAIL do modelo da revisao
-- mesmo mecanismo de ZcnGrCrg (Pergunte "CN300CRG" + CN300PrCF), mas sem ativar/commitar um
modelo proprio: roda dentro do modelo da revisao, que e gravado de uma vez so no fim de
ZcnRevAb.
@type Static Function
@param oModel objeto, modelo da revisao ja ativo, CNADETAIL posicionada na planilha nova
@param aFalhas array, acumulador de falhas
@param oCrg JsonObject, {periodicidade, dias, ultimoDiaMes, competenciaInicio, dataPrevista, qtdParcelas, condPagto, taxaJuros}
@return Nil
/*/
//=============================================================================================================================
Static Function ZcnRvCrg(oModel, aFalhas, oCrg)

    Local bPrevErr := ErrorBlock({|e| Break(e)})
    Local oErr     := Nil
    Local oMdlCNF  := Nil
    Local nQtdCrg  := 0
    Local nL       := 0

    Begin Sequence
        FWModelActive(oModel)

        SetMVValue("CN300CRG", "MV_PAR01", oCrg["periodicidade"])
        SetMVValue("CN300CRG", "MV_PAR02", oCrg["dias"])
        SetMVValue("CN300CRG", "MV_PAR03", oCrg["ultimoDiaMes"])
        SetMVValue("CN300CRG", "MV_PAR04", AllTrim(cValToChar(oCrg["competenciaInicio"])))
        SetMVValue("CN300CRG", "MV_PAR05", ZcnSToD(oCrg["dataPrevista"]))
        SetMVValue("CN300CRG", "MV_PAR06", oCrg["qtdParcelas"])
        SetMVValue("CN300CRG", "MV_PAR07", AllTrim(cValToChar(oCrg["condPagto"])))
        SetMVValue("CN300CRG", "MV_PAR08", oCrg["taxaJuros"])
        Pergunte("CN300CRG", .F.)

        CN300PrCF(.T.)

        // Confere se o CN300PrCF gerou as parcelas (CNFDETAIL da planilha posicionada). Se nao
        // gerou, para AQUI com mensagem clara: seguir ate o VldData fazia o proprio CNTA300 abrir
        // a tela de parametros do cronograma e, no Cancelar, recusar com A300NCRON (2026-10-09).
        oMdlCNF := oModel:GetModel('CNFDETAIL')
        If oMdlCNF != Nil
            For nL := 1 To oMdlCNF:Length()
                oMdlCNF:GoLine(nL)
                If !oMdlCNF:IsDeleted() .And. !Empty(oMdlCNF:GetValue('CNF_COMPET'))
                    nQtdCrg++
                EndIf
            Next nL
            If nQtdCrg == 0
                AAdd(aFalhas, "o Protheus nao gerou nenhuma parcela do cronograma com os parametros informados " + ;
                    "(competencia de inicio " + AllTrim(cValToChar(oCrg["competenciaInicio"])) + ", 1a competencia " + ;
                    DToC(ZcnSToD(oCrg["dataPrevista"])) + ")." + IIf(Empty(ZcnErrMsg(oModel)), "", " " + ZcnErrMsg(oModel)))
            EndIf
        EndIf
    Recover Using oErr
        AAdd(aFalhas, AllTrim(oErr:Description))
    End Sequence

    ErrorBlock(bPrevErr)

Return Nil

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
    Local cNumPla               := ""
    Local aFalhas               := {}

    If ValType(oReq["numero"]) == "C" ; cNumero  := AllTrim(oReq["numero"])  ; EndIf
    If ValType(oReq["revisao"]) == "C" ; cRevisao := AllTrim(oReq["revisao"]) ; EndIf
    If ValType(oReq["numPla"]) == "C" ; cNumPla := AllTrim(oReq["numPla"]) ; EndIf

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
    // Confere o Activate -- seguir com o modelo inativo estoura THREAD ERROR no 1o SetValue
    // (mesmo caso de ZcnRevAb, 2026-10-09).
    If !oModel:Activate()
        cMsg := ZcnErrMsg(oModel)
        oResp["success"] := .F.
        oResp["message"] := "Nao foi possivel abrir o contrato " + cNumero + "/" + cRevisao + " para alteracao." + IIf(Empty(cMsg), "", " " + cMsg)
        Return oResp
    EndIf

    // Planilha alvo (2026-10-09): antes o CN300PrCF rodava na linha que estivesse posicionada na
    // CNADETAIL (a 1a) -- com mais de uma planilha o cronograma ia para a planilha errada.
    // "substituir": exclui o cronograma atual da planilha antes de gerar o novo, no mesmo commit.
    If !Empty(cNumPla)
        If !ZcnPosPla(oModel, cNumPla)
            oModel:DeActivate()
            oResp["success"] := .F.
            oResp["message"] := "Planilha [" + cNumPla + "] nao encontrada no contrato."
            Return oResp
        EndIf
        If ValType(oReq["substituir"]) == "L" .And. oReq["substituir"]
            ZcnRvDlCrg(oModel, aFalhas, cNumPla)
            If Len(aFalhas) > 0
                oModel:DeActivate()
                oResp["success"] := .F.
                oResp["message"] := "Falha ao excluir o cronograma atual: " + aFalhas[1]
                Return oResp
            EndIf
        EndIf
    EndIf

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

/*/{Protheus.doc} ZcnAnChave
Monta a chave AC9_CODENT usada para vincular o contrato (CN9) ao Banco de
Conhecimento nativo -- CN9_FILIAL+CN9_NUMERO, conforme documentacao oficial
TOTVS repassada pelo usuario 2026-09-23 (AC9_ENTIDA="CN9", AC9_FILENT=filial
do contrato, AC9_CODENT=concatenacao das chaves do registro de origem).
@type Static Function
@param cNumero caractere, numero do contrato
@return caractere, chave AC9_CODENT
/*/
//=============================================================================================================================
Static Function ZcnAnChave(cNumero)
Return xFilial("CN9") + Padr(AllTrim(cNumero), TamSX3("CN9_NUMERO")[1])

/*/{Protheus.doc} ZcnAnDir
Diretorio fisico onde os arquivos do Banco de Conhecimento (ACB) sao
gravados neste ambiente -- MV_DIRDOC + "CO"+empresa+"\"+filial+"\", conforme
documentacao oficial TOTVS repassada pelo usuario 2026-09-23. NAO reproduz a
logica nativa de deteccao de tabela compartilhada (pasta "Shared" quando
AC9/ACB/ACC estao configuradas como unicas/sem filial no SX2) -- sem uma
forma confirmada de checar isso por codigo, sempre usa a pasta POR FILIAL.
Isso e seguro para o proprio ciclo desta funcionalidade (grava e le sempre
do mesmo lugar), mas pode nao ser exatamente a mesma pasta que o Wizard
nativo ("Outras Acoes > Conhecimento") usaria se este ambiente rodar AC9/
ACB em modo compartilhado -- nesse caso, um anexo incluido por aqui pode nao
aparecer no Wizard nativo (e vice-versa) ate isso ser confirmado/ajustado.
@type Static Function
@return caractere, caminho do diretorio (com "\" no final)
/*/
//=============================================================================================================================
Static Function ZcnAnDir()

    Local cDirDoc := AllTrim(GetMv("MV_DIRDOC", .F., ""))

    If Empty(cDirDoc)
        cDirDoc := "\protheus_data\dirdoc\"
    EndIf
    If Right(cDirDoc, 1) != "\"
        cDirDoc += "\"
    EndIf

Return cDirDoc + "CO" + cEmpAnt + "\" + xFilial("ACB") + "\"

/*/{Protheus.doc} ZcnAnLst
Lista os anexos de um contrato (operacao "anexoListar") -- consulta o Banco
de Conhecimento nativo (AC9 vinculado a ACB), nao uma tabela propria. Join
por ACB_CODOBJ SOMENTE (sem casar ACB_FILIAL) porque ACB costuma ser uma
tabela compartilhada entre filiais (mesma cautela ja registrada em memoria
deste projeto sobre JOIN cross-filial silenciosamente vazio quando uma das
tabelas e compartilhada).
@type Static Function
@param oReq JsonObject, {numero}
@return JsonObject, {success, anexos:[{item,nome,tamanho}]}
/*/
//=============================================================================================================================
Static Function ZcnAnLst(oReq)

    Local oResp    := JsonObject():New()
    Local aAnexos  := {}
    Local oLinha   := Nil
    Local cNumero  := ""
    Local cChave   := ""
    Local cAliasQ  := ""
    Local cDir     := ""
    Local nHandle  := 0

    If ValType(oReq["numero"]) == "C" ; cNumero := AllTrim(oReq["numero"]) ; EndIf

    If Empty(cNumero)
        oResp["success"] := .F.
        oResp["message"] := "Numero do contrato nao informado"
        Return oResp
    EndIf

    cChave := ZcnAnChave(cNumero)
    cDir   := ZcnAnDir()

    cAliasQ := GetNextAlias()
    BeginSql Alias cAliasQ
        SELECT ACB.ACB_CODOBJ, ACB.ACB_OBJETO, ACB.ACB_DESCRI
          FROM %table:AC9% AC9
          INNER JOIN %table:ACB% ACB ON ACB.ACB_CODOBJ = AC9.AC9_CODOBJ AND ACB.%notDel%
         WHERE AC9.%notDel%
           AND AC9.AC9_FILIAL = %xfilial:AC9%
           AND AC9.AC9_ENTIDA = 'CN9'
           AND AC9.AC9_FILENT = %xfilial:CN9%
           AND AC9.AC9_CODENT = %exp:cChave%
         ORDER BY ACB.ACB_CODOBJ
    EndSql
    While (cAliasQ)->(!Eof())
        oLinha := JsonObject():New()
        oLinha["item"]    := AllTrim((cAliasQ)->ACB_CODOBJ)
        oLinha["nome"]    := AllTrim((cAliasQ)->ACB_DESCRI)
        // Tamanho lido do proprio arquivo em disco (nao existe campo confirmado de tamanho na
        // ACB) -- degrada pra 0 se o arquivo nao for encontrado, sem quebrar a listagem.
        oLinha["tamanho"] := 0
        nHandle := fOpen(cDir + AllTrim((cAliasQ)->ACB_OBJETO), 0)
        If nHandle != -1
            oLinha["tamanho"] := fSeek(nHandle, 0, 2)
            fClose(nHandle)
        EndIf
        aAdd(aAnexos, oLinha)
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

    oResp["success"] := .T.
    oResp["anexos"]  := aAnexos

Return oResp

/*/{Protheus.doc} ZcnAnCri
Anexa um arquivo ao contrato (operacao "anexoCriar") usando o Banco de
Conhecimento NATIVO do Protheus (AC9+ACB), conforme documentacao oficial
TOTVS repassada pelo usuario 2026-09-23 -- substitui a 1a versao desta
funcao (que usava uma tabela ZCN propria, criada so por seguranca enquanto
a estrutura real da AC9/ACB nao estava confirmada).
Grava o arquivo fisico em ZcnAnDir() (MV_DIRDOC) e os metadados em:
  ACB_CODOBJ (numerador GetSxeNum, chave unica) / ACB_OBJETO (nome do
  arquivo em disco, <codigo>+extensao) / ACB_DESCRI (nome original)
  AC9_CODOBJ (= ACB_CODOBJ) / AC9_ENTIDA ("CN9") / AC9_FILENT (filial do
  contrato) / AC9_CODENT (ZcnAnChave -- CN9_FILIAL+CN9_NUMERO)
Campos "principais" confirmados pelo usuario -- outros campos que a AC9/ACB
exijam neste ambiente especifico (nao confirmados) podem fazer o RecLock
falhar; o Begin Sequence abaixo converte isso num erro comum em vez de
THREAD ERROR, e desfaz a reserva do numerador (RollBackSX8) se algo falhar
no meio do caminho.
Sem checagem de assinatura de conteudo -- aceita qualquer tipo comum de
documento, mas BLOQUEIA extensoes executaveis/script (medida minima de
seguranca, upload irrestrito de arquivo e um risco conhecido).
@type Static Function
@param oReq JsonObject, {numero, nome, conteudoBase64}
@return JsonObject, {success, item, message}
/*/
//=============================================================================================================================
Static Function ZcnAnCri(oReq)

    Local oResp       := JsonObject():New()
    Local oErrCatch    := Nil
    Local cNumero       := ""
    Local cNomeArq        := ""
    Local cBase64           := ""
    Local cBinario            := ""
    Local cCodObj              := ""
    Local cDir                   := ""
    Local cArqDisco                := ""
    Local cCaminho                   := ""
    Local cExt                         := ""
    Local nHandle                        := 0
    Local nPosBase64                       := 0
    Local lReservou                          := .F.
    Local aExtBloq := {".EXE", ".BAT", ".CMD", ".COM", ".PS1", ".VBS", ".JS", ".SH", ".DLL", ".SCR", ".MSI", ".JAR", ".APP"}

    If ValType(oReq["numero"]) == "C" ; cNumero := AllTrim(oReq["numero"]) ; EndIf

    If Empty(cNumero)
        oResp["success"] := .F.
        oResp["message"] := "Numero do contrato nao informado"
        Return oResp
    EndIf

    CN9->(dbSetOrder(1))
    If !CN9->(dbSeek(xFilial("CN9") + Padr(cNumero, TamSX3("CN9_NUMERO")[1])))
        oResp["success"] := .F.
        oResp["message"] := "Contrato [" + cNumero + "] nao encontrado."
        Return oResp
    EndIf

    cNomeArq := AllTrim(cValToChar(oReq["nome"]))
    cBase64  := oReq["conteudoBase64"]

    If Empty(cNomeArq) .Or. Empty(cBase64)
        oResp["success"] := .F.
        oResp["message"] := "Informe 'nome' e 'conteudoBase64' do arquivo"
        Return oResp
    EndIf

    cExt := Upper(cNomeArq)
    cExt := SubStr(cExt, RAt(".", cExt))
    If AScan(aExtBloq, cExt) > 0
        oResp["success"] := .F.
        oResp["message"] := "Tipo de arquivo nao permitido (" + cExt + ")"
        Return oResp
    EndIf

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

    // Begin Sequence/Recover -- mesmo motivo do resto do arquivo: gravar em AC9/ACB e uma area
    // nova/nao testada nesta sessao, qualquer erro de runtime (campo obrigatorio que eu nao
    // conheca, etc.) vira JSON de erro em vez de THREAD ERROR, e desfaz a reserva do numerador.
    Begin Sequence

    cCodObj := GetSxeNum("ACB", "ACB_CODOBJ")
    lReservou := .T.

    cDir := ZcnAnDir()
    If !ExistDir(cDir)
        MakeDir(cDir) // ignora retorno -- se ja existir por corrida concorrente, fCreate abaixo ainda funciona
    EndIf

    cArqDisco := AllTrim(cCodObj) + Lower(cExt)
    cCaminho  := cDir + cArqDisco

    nHandle := fCreate(cCaminho)
    If nHandle == -1
        RollBackSX8()
        oResp["success"] := .F.
        oResp["message"] := "Falha ao criar o arquivo no servidor (" + cCaminho + ")"
        Return oResp
    EndIf

    If fWrite(nHandle, cBinario, Len(cBinario)) != Len(cBinario)
        fClose(nHandle)
        FErase(cCaminho)
        RollBackSX8()
        oResp["success"] := .F.
        oResp["message"] := "Falha ao gravar todo o conteudo do arquivo"
        Return oResp
    EndIf
    fClose(nHandle)

    DbSelectArea("ACB")
    RecLock("ACB", .T.)
        ACB->ACB_FILIAL := xFilial("ACB")
        ACB->ACB_CODOBJ := cCodObj
        ACB->ACB_OBJETO := cArqDisco
        ACB->ACB_DESCRI := cNomeArq
    MsUnlock()

    DbSelectArea("AC9")
    RecLock("AC9", .T.)
        AC9->AC9_FILIAL := xFilial("AC9")
        AC9->AC9_CODOBJ := cCodObj
        AC9->AC9_ENTIDA := "CN9"
        AC9->AC9_FILENT := xFilial("CN9")
        AC9->AC9_CODENT := ZcnAnChave(cNumero)
    MsUnlock()

    ConfirmSX8()
    lReservou := .F.

    oResp["success"] := .T.
    oResp["item"]    := AllTrim(cCodObj)
    oResp["message"] := "Anexo incluido com sucesso"

    Recover Using oErrCatch
        If lReservou
            RollBackSX8()
        EndIf
        oResp := JsonObject():New()
        oResp["success"] := .F.
        oResp["message"] := "Erro interno ao anexar arquivo: " + AllTrim(oErrCatch:description) +;
            IIf(ValType(oErrCatch:operation) == "C" .And. !Empty(oErrCatch:operation), " (" + AllTrim(oErrCatch:operation) + ")", "")
    End Sequence

Return oResp

/*/{Protheus.doc} ZcnAnBax
Baixa um anexo do contrato (conteudo em base64, operacao "anexoBaixar") --
le o registro AC9+ACB pelo codigo de objeto (item) e devolve o arquivo
fisico gravado em ZcnAnDir().
@type Static Function
@param oReq JsonObject, {numero, item}
@return JsonObject, {success, nome, conteudoBase64}
/*/
//=============================================================================================================================
Static Function ZcnAnBax(oReq)

    Local oResp    := JsonObject():New()
    Local cNumero  := ""
    Local cItem    := ""
    Local cChave   := ""
    Local cAliasQ  := ""
    Local cCaminho := ""
    Local cNomeArq := ""
    Local nHandle  := 0
    Local nTam     := 0
    Local cBuffer  := ""

    If ValType(oReq["numero"]) == "C" ; cNumero := AllTrim(oReq["numero"]) ; EndIf
    If ValType(oReq["item"])   == "C" ; cItem   := AllTrim(oReq["item"])   ; EndIf

    If Empty(cNumero) .Or. Empty(cItem)
        oResp["success"] := .F.
        oResp["message"] := "Parametros 'numero' e 'item' sao obrigatorios"
        Return oResp
    EndIf

    cChave  := ZcnAnChave(cNumero)
    cAliasQ := GetNextAlias()
    BeginSql Alias cAliasQ
        SELECT ACB.ACB_OBJETO, ACB.ACB_DESCRI
          FROM %table:AC9% AC9
          INNER JOIN %table:ACB% ACB ON ACB.ACB_CODOBJ = AC9.AC9_CODOBJ AND ACB.%notDel%
         WHERE AC9.%notDel%
           AND AC9.AC9_FILIAL = %xfilial:AC9%
           AND AC9.AC9_ENTIDA = 'CN9'
           AND AC9.AC9_FILENT = %xfilial:CN9%
           AND AC9.AC9_CODENT = %exp:cChave%
           AND AC9.AC9_CODOBJ = %exp:cItem%
    EndSql
    If (cAliasQ)->(Eof())
        (cAliasQ)->(DbCloseArea())
        oResp["success"] := .F.
        oResp["message"] := "Anexo nao encontrado"
        Return oResp
    EndIf

    cNomeArq := AllTrim((cAliasQ)->ACB_DESCRI)
    cCaminho := ZcnAnDir() + AllTrim((cAliasQ)->ACB_OBJETO)
    (cAliasQ)->(DbCloseArea())

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

/*/{Protheus.doc} ZcnAnRem
Remove um anexo do contrato (registros AC9+ACB + arquivo em disco, operacao
"anexoRemover"). Posiciona por RECNO (achado via SQL) em vez de DbSeek --
nao ha confirmacao da ordem/indice real de AC9/ACB neste ambiente, RECNO
funciona independente disso.
@type Static Function
@param oReq JsonObject, {numero, item}
@return JsonObject, {success, message}
/*/
//=============================================================================================================================
Static Function ZcnAnRem(oReq)

    Local oResp     := JsonObject():New()
    Local cNumero   := ""
    Local cItem     := ""
    Local cChave    := ""
    Local cAliasQ   := ""
    Local cCaminho  := ""
    Local nRecnoAc9 := 0
    Local nRecnoAcb := 0

    If ValType(oReq["numero"]) == "C" ; cNumero := AllTrim(oReq["numero"]) ; EndIf
    If ValType(oReq["item"])   == "C" ; cItem   := AllTrim(oReq["item"])   ; EndIf

    If Empty(cNumero) .Or. Empty(cItem)
        oResp["success"] := .F.
        oResp["message"] := "Parametros 'numero' e 'item' sao obrigatorios"
        Return oResp
    EndIf

    cChave  := ZcnAnChave(cNumero)
    cAliasQ := GetNextAlias()
    BeginSql Alias cAliasQ
        SELECT AC9.R_E_C_N_O_ AS AC9RECNO, ACB.R_E_C_N_O_ AS ACBRECNO, ACB.ACB_OBJETO
          FROM %table:AC9% AC9
          INNER JOIN %table:ACB% ACB ON ACB.ACB_CODOBJ = AC9.AC9_CODOBJ AND ACB.%notDel%
         WHERE AC9.%notDel%
           AND AC9.AC9_FILIAL = %xfilial:AC9%
           AND AC9.AC9_ENTIDA = 'CN9'
           AND AC9.AC9_FILENT = %xfilial:CN9%
           AND AC9.AC9_CODENT = %exp:cChave%
           AND AC9.AC9_CODOBJ = %exp:cItem%
    EndSql
    If (cAliasQ)->(Eof())
        (cAliasQ)->(DbCloseArea())
        oResp["success"] := .F.
        oResp["message"] := "Anexo nao encontrado"
        Return oResp
    EndIf

    nRecnoAc9 := (cAliasQ)->AC9RECNO
    nRecnoAcb := (cAliasQ)->ACBRECNO
    cCaminho  := ZcnAnDir() + AllTrim((cAliasQ)->ACB_OBJETO)
    (cAliasQ)->(DbCloseArea())

    DbSelectArea("AC9")
    AC9->(DbGoTo(nRecnoAc9))
    RecLock("AC9", .F.)
        AC9->(DbDelete())
    MsUnlock()

    DbSelectArea("ACB")
    ACB->(DbGoTo(nRecnoAcb))
    RecLock("ACB", .F.)
        ACB->(DbDelete())
    MsUnlock()

    If !Empty(cCaminho) .And. File(cCaminho)
        FErase(cCaminho)
    EndIf

    oResp["success"] := .T.
    oResp["message"] := "Anexo removido com sucesso"

Return oResp

/*/{Protheus.doc} ZcnAcTot
Codigo de "Acesso Total" do CNN_TRACOD -- procura no combo do dicionario (X3_CBOX) a opcao cujo
texto contenha "TOTAL"; se o campo nao tiver combo, assume "001" (acesso total do padrao GCT).
@type Static Function
@return caractere, codigo do tipo de acesso total
/*/
//=============================================================================================================================
Static Function ZcnAcTot()

    Local aOpc := ZcnCbox("CNN_TRACOD")
    Local nI   := 0

    For nI := 1 To Len(aOpc)
        If "TOTAL" $ Upper(aOpc[nI]["label"])
            Return aOpc[nI]["value"]
        EndIf
    Next nI

Return "001"

/*/{Protheus.doc} ZcnAcQtd
Conta registros de acesso (CNN) do contrato na filial corrente -- opcionalmente so de um
usuario e/ou de um tipo de acesso (CNN_TRACOD).
@type Static Function
@param cContra caractere, numero do contrato
@param cUsr caractere, codigo do usuario (vazio = todos)
@param cTraCod caractere, tipo de acesso (vazio = todos)
@return numerico, quantidade de registros
/*/
//=============================================================================================================================
Static Function ZcnAcQtd(cContra, cUsr, cTraCod)

    Local cAliasQ := GetNextAlias()
    Local cCtr    := Padr(cContra, TamSX3("CNN_CONTRA")[1])
    Local nQtd    := 0

    BeginSql Alias cAliasQ
        SELECT CNN.CNN_USRCOD, CNN.CNN_TRACOD
          FROM %table:CNN% CNN
         WHERE CNN.%notDel%
           AND CNN.CNN_FILIAL = %xfilial:CNN%
           AND CNN.CNN_CONTRA = %exp:cCtr%
         ORDER BY CNN.CNN_USRCOD
    EndSql
    // Filtro de usuario/tipo aplicado aqui (poucas linhas por contrato) -- evita montar
    // fragmento dinamico de WHERE dentro do BeginSql.
    While (cAliasQ)->(!Eof())
        If (Empty(cUsr) .Or. AllTrim((cAliasQ)->CNN_USRCOD) == AllTrim(cUsr)) .And.;
           (Empty(cTraCod) .Or. AllTrim((cAliasQ)->CNN_TRACOD) == AllTrim(cTraCod))
            nQtd++
        EndIf
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

Return nQtd

/*/{Protheus.doc} ZcnAcPode
Indica se o usuario logado pode gerenciar os acessos (CNN) do contrato: administrador, quem
ja tem acesso total ao contrato, ou qualquer usuario enquanto o contrato ainda nao tiver nenhum
acesso cadastrado (contratos incluidos pela tela antes do acesso automatico ao criador -- sem
isso ninguem conseguiria dar o 1o acesso).
@type Static Function
@param cContra caractere, numero do contrato
@return logico
/*/
//=============================================================================================================================
Static Function ZcnAcPode(cContra)

    If FWIsAdmin(__cUserId)
        Return .T.
    EndIf

Return ZcnAcQtd(cContra, "", "") == 0 .Or. ZcnAcQtd(cContra, __cUserId, ZcnAcTot()) > 0

/*/{Protheus.doc} ZcnAcTem
Indica se o usuario logado tem acesso (qualquer tipo de CNN_TRACOD) ao contrato na filial
corrente -- pelo proprio codigo (CNN_USRCOD) ou por um grupo dele (CNN_GRPCOD, quando o campo
existir no dicionario). Mesma regra do CNTA300/CNTA301 ("sem acesso ao contrato"). Usada em
JsToAdvpl antes de abrir/alterar o contrato.
@type Static Function
@param cContra caractere, numero do contrato
@return logico
/*/
//=============================================================================================================================
Static Function ZcnAcTem(cContra)

    Local cAliasQ := GetNextAlias()
    Local cCtr    := Padr(cContra, TamSX3("CNN_CONTRA")[1])
    Local aGrupos := UsrRetGrp(UsrRetName(__cUserId), __cUserId)
    Local lGrp    := .F.
    Local lTem    := .F.

    If ValType(aGrupos) != "A" ; aGrupos := {} ; EndIf

    DbSelectArea("CNN")
    lGrp := CNN->(FieldPos("CNN_GRPCOD")) > 0

    BeginSql Alias cAliasQ
        SELECT CNN.R_E_C_N_O_ AS CNNRECNO
          FROM %table:CNN% CNN
         WHERE CNN.%notDel%
           AND CNN.CNN_FILIAL = %xfilial:CNN%
           AND CNN.CNN_CONTRA = %exp:cCtr%
    EndSql

    While (cAliasQ)->(!Eof()) .And. !lTem
        CNN->(DbGoTo((cAliasQ)->CNNRECNO))
        If !Empty(CNN->CNN_USRCOD) .And. AllTrim(CNN->CNN_USRCOD) == AllTrim(__cUserId)
            lTem := .T.
        ElseIf lGrp .And. !Empty(CNN->CNN_GRPCOD) .And. aScan(aGrupos, {|x| AllTrim(x) == AllTrim(CNN->CNN_GRPCOD)}) > 0
            lTem := .T.
        EndIf
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

Return lTem

/*/{Protheus.doc} ZcnTemRevAnt
Diz se o registro (numero+revisao) e uma REVISAO de fato, ou seja, se existe uma revisao anterior
do mesmo contrato. A revisao original (a primeira gravada) devolve .F. -- trava usada para nunca
gravar alteracao de revisao no contrato original (erro real de 2026-10-09: "Alterar Revisao"
gravou a planilha nova na revisao original).
@type Static Function
@param cContra caractere, numero do contrato
@param cRevisa caractere, revisao
@return logico
/*/
//=============================================================================================================================
Static Function ZcnTemRevAnt(cContra, cRevisa)

    Local cAliasQ := GetNextAlias()
    Local cCtr    := Padr(cContra, TamSX3("CN9_NUMERO")[1])
    Local cRev    := Padr(cRevisa, TamSX3("CN9_REVISA")[1])
    Local lTem    := .F.

    BeginSql Alias cAliasQ
        SELECT COUNT(*) AS QTD
          FROM %table:CN9% CN9
         WHERE CN9.%notDel%
           AND CN9.CN9_FILIAL = %xfilial:CN9%
           AND CN9.CN9_NUMERO = %exp:cCtr%
           AND CN9.CN9_REVISA < %exp:cRev%
    EndSql
    lTem := (cAliasQ)->QTD > 0
    (cAliasQ)->(DbCloseArea())

Return lTem

/*/{Protheus.doc} ZcnUltRev
Maior CN9_REVISA do contrato (a revisao mais recente gravada -- o CN9_REVATU so passa a apontar
para ela depois da aprovacao).
@type Static Function
@param cContra caractere, numero do contrato
@return caractere, revisao ("" se o contrato so tem a revisao original)
/*/
//=============================================================================================================================
Static Function ZcnUltRev(cContra)

    Local cAliasQ := GetNextAlias()
    Local cCtr    := Padr(cContra, TamSX3("CN9_NUMERO")[1])
    Local cRev    := ""

    BeginSql Alias cAliasQ
        SELECT MAX(CN9.CN9_REVISA) AS REVISA
          FROM %table:CN9% CN9
         WHERE CN9.%notDel%
           AND CN9.CN9_FILIAL = %xfilial:CN9%
           AND CN9.CN9_NUMERO = %exp:cCtr%
    EndSql
    If (cAliasQ)->(!Eof())
        cRev := AllTrim((cAliasQ)->REVISA)
    EndIf
    (cAliasQ)->(DbCloseArea())

Return cRev

/*/{Protheus.doc} ZcnRevAberta
Revisao em aberto do contrato: a revisao mais recente (ZcnUltRev), desde que seja uma revisao de
fato (ZcnTemRevAnt) e esteja com situacao "09" (Em Revisao) ou "A" (alcadas). Nunca devolve a
revisao original.
@type Static Function
@param cContra caractere, numero do contrato
@return caractere, revisao em aberto ou Nil se nao houver
/*/
//=============================================================================================================================
Static Function ZcnRevAberta(cContra)

    Local cRev := ZcnUltRev(cContra)
    Local cSit := ""

    // A revisao em aberto e SEMPRE a mais recente, e precisa ser uma revisao de fato (ter revisao
    // anterior) -- nunca a original, mesmo que a original esteja marcada "Em Revisao".
    If !ZcnTemRevAnt(cContra, cRev)
        Return Nil
    EndIf
    cSit := AllTrim(Posicione("CN9", 1, xFilial("CN9") + Padr(cContra, TamSX3("CN9_NUMERO")[1]) + Padr(cRev, TamSX3("CN9_REVISA")[1]), "CN9_SITUAC"))
    If !(cSit $ "09/A")
        Return Nil
    EndIf

Return cRev

/*/{Protheus.doc} ZcnPlaNaRev
Diz se a planilha foi incluida NESTA revisao, ou seja, se nao existe na revisao anterior do
contrato (a maior CN9_REVISA menor que a atual). Revisao sem anterior (a original) = .F.
Usado para liberar a edicao so das planilhas novas de uma revisao em aberto.
@type Static Function
@param cContra caractere, numero do contrato
@param cRevisa caractere, revisao atual
@param cNumPla caractere, numero da planilha (CNA_NUMERO)
@return logico
/*/
//=============================================================================================================================
Static Function ZcnPlaNaRev(cContra, cRevisa, cNumPla)

    Local cAliasQ := GetNextAlias()
    Local cCtr    := Padr(cContra, TamSX3("CN9_NUMERO")[1])
    Local cRev    := Padr(cRevisa, TamSX3("CN9_REVISA")[1])
    Local cPla    := Padr(cNumPla, TamSX3("CNA_NUMERO")[1])
    Local cRevAnt := ""
    Local lNova   := .F.

    BeginSql Alias cAliasQ
        SELECT MAX(CN9.CN9_REVISA) AS REVANT, COUNT(*) AS QTD
          FROM %table:CN9% CN9
         WHERE CN9.%notDel%
           AND CN9.CN9_FILIAL = %xfilial:CN9%
           AND CN9.CN9_NUMERO = %exp:cCtr%
           AND CN9.CN9_REVISA < %exp:cRev%
    EndSql
    If (cAliasQ)->(Eof()) .Or. (cAliasQ)->QTD == 0
        (cAliasQ)->(DbCloseArea())
        Return .F.
    EndIf
    cRevAnt := (cAliasQ)->REVANT
    (cAliasQ)->(DbCloseArea())

    BeginSql Alias cAliasQ
        SELECT COUNT(*) AS QTD
          FROM %table:CNA% CNA
         WHERE CNA.%notDel%
           AND CNA.CNA_FILIAL = %xfilial:CNA%
           AND CNA.CNA_CONTRA = %exp:cCtr%
           AND CNA.CNA_REVISA = %exp:cRevAnt%
           AND CNA.CNA_NUMERO = %exp:cPla%
    EndSql
    lNova := (cAliasQ)->QTD == 0
    (cAliasQ)->(DbCloseArea())

Return lNova

/*/{Protheus.doc} ZcnAcVer
Operacao "acessoVerificar" -- chamada pela listagem ANTES de abrir o contrato. A checagem de
acesso em si fica em JsToAdvpl (ZcnAcTem); se chegou aqui, o usuario tem acesso -- so confere
se o contrato existe na filial (ja trocada para a do contrato em JsToAdvpl).
@type Static Function
@param cContra caractere, numero do contrato
@return JsonObject, {success, message}
/*/
//=============================================================================================================================
Static Function ZcnAcVer(cContra)

    Local oResp := JsonObject():New()

    CN9->(dbSetOrder(1))
    If CN9->(dbSeek(xFilial("CN9") + Padr(cContra, Max(TamSX3("CN9_NUMERO")[1], Len(cContra)))))
        oResp["success"] := .T.
        // Revisao ja aberta (Em Revisao/Revisao em Alcadas): a listagem abre ESSA revisao para
        // edicao em vez de tentar abrir outra (pedido do usuario 2026-10-09 -- a 2a tentativa dava
        // CNTA300NOVIG "contrato nao se encontra vigente").
        oResp["revisaoAberta"] := ZcnRevAberta(cContra)
    Else
        oResp["success"] := .F.
        oResp["message"] := "Contrato [" + cContra + "] nao encontrado na filial " + AllTrim(cFilAnt) + "."
    EndIf

Return oResp

/*/{Protheus.doc} ZcnAcGrv
Grava um acesso (CNN) do usuario ao contrato, na filial corrente -- nao duplica se o usuario
ja tiver esse mesmo tipo de acesso.
@type Static Function
@param cContra caractere, numero do contrato
@param cUsr caractere, codigo do usuario
@param cTraCod caractere, tipo de acesso (CNN_TRACOD)
@return logico, .T. se gravou (ou ja existia)
/*/
//=============================================================================================================================
Static Function ZcnAcGrv(cContra, cUsr, cTraCod)

    If ZcnAcQtd(cContra, cUsr, cTraCod) > 0
        Return .T.
    EndIf

    DbSelectArea("CNN")
    RecLock("CNN", .T.)
        CNN->CNN_FILIAL := xFilial("CNN")
        CNN->CNN_CONTRA := cContra
        CNN->CNN_USRCOD := cUsr
        CNN->CNN_TRACOD := cTraCod
    MsUnlock()

Return .T.

/*/{Protheus.doc} ZcnAcFil
Troca cFilAnt para a filial do contrato (a listagem mostra contratos de varias filiais) e
devolve a filial anterior para o chamador restaurar -- mesmo tratamento de ZcnImpExp.
@type Static Function
@param oReq JsonObject, {filial}
@return caractere, filial anterior (cFilAnt antes da troca)
/*/
//=============================================================================================================================
Static Function ZcnAcFil(oReq)

    Local cFilBkp := cFilAnt

    If ValType(oReq["filial"]) == "C" .And. !Empty(AllTrim(oReq["filial"]))
        cFilAnt := Padr(AllTrim(oReq["filial"]), Len(cFilAnt))
    EndIf

Return cFilBkp

/*/{Protheus.doc} ZcnAcLst
Lista os usuarios/grupos com acesso ao contrato (tabela CNN, operacao "acessoListar") -- e a
mesma tabela que o CNTA300/CNTA301 consulta antes de abrir o contrato ("sem acesso ao
contrato"). Devolve tambem os tipos de acesso (combo do CNN_TRACOD) e se o usuario logado pode
incluir/remover acessos (ZcnAcPode).
@type Static Function
@param oReq JsonObject, {numero, filial}
@return JsonObject, {success, podeGerenciar, tipoPadrao, tipos:[{value,label}], acessos:[{recno,usuario,login,nome,grupo,grupoNome,tipo,tipoLabel}]}
/*/
//=============================================================================================================================
Static Function ZcnAcLst(oReq)

    Local oResp    := JsonObject():New()
    Local aAcessos := {}
    Local aTipos   := ZcnCbox("CNN_TRACOD")
    Local oLinha   := Nil
    Local cAliasQ  := ""
    Local cNumero  := ""
    Local cCtr     := ""
    Local cFilBkp  := ZcnAcFil(oReq)
    Local nPos     := 0

    If ValType(oReq["numero"]) == "C" ; cNumero := AllTrim(oReq["numero"]) ; EndIf

    If Empty(cNumero)
        cFilAnt := cFilBkp
        oResp["success"] := .F.
        oResp["message"] := "Numero do contrato nao informado"
        Return oResp
    EndIf

    cCtr    := Padr(cNumero, TamSX3("CNN_CONTRA")[1])
    cAliasQ := GetNextAlias()
    BeginSql Alias cAliasQ
        SELECT CNN.R_E_C_N_O_ AS CNNRECNO
          FROM %table:CNN% CNN
         WHERE CNN.%notDel%
           AND CNN.CNN_FILIAL = %xfilial:CNN%
           AND CNN.CNN_CONTRA = %exp:cCtr%
         ORDER BY CNN.CNN_USRCOD, CNN.CNN_TRACOD
    EndSql

    // Le o registro pelo RECNO (nao pelas colunas da query) -- CNN_GRPCOD pode nao existir
    // neste dicionario, ZcnSFld degrada pra "" sem quebrar a listagem.
    DbSelectArea("CNN")
    While (cAliasQ)->(!Eof())
        CNN->(DbGoTo((cAliasQ)->CNNRECNO))
        oLinha := JsonObject():New()
        oLinha["recno"]     := (cAliasQ)->CNNRECNO
        oLinha["usuario"]   := AllTrim(CNN->CNN_USRCOD)
        oLinha["login"]     := IIf(Empty(oLinha["usuario"]), "", AllTrim(UsrRetName(oLinha["usuario"])))
        oLinha["nome"]      := IIf(Empty(oLinha["usuario"]), "", AllTrim(UsrFullName(oLinha["usuario"])))
        oLinha["grupo"]     := AllTrim(ZcnSFld("CNN", "CNN_GRPCOD"))
        oLinha["grupoNome"] := IIf(Empty(oLinha["grupo"]), "", AllTrim(GrpRetName(oLinha["grupo"])))
        oLinha["tipo"]      := AllTrim(CNN->CNN_TRACOD)
        nPos := AScan(aTipos, {|o| o["value"] == oLinha["tipo"]})
        oLinha["tipoLabel"] := IIf(nPos > 0, aTipos[nPos]["label"], oLinha["tipo"])
        aAdd(aAcessos, oLinha)
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

    oResp["success"]       := .T.
    oResp["podeGerenciar"] := ZcnAcPode(cNumero)
    oResp["tipoPadrao"]    := ZcnAcTot()
    oResp["tipos"]         := aTipos
    oResp["acessos"]       := aAcessos

    cFilAnt := cFilBkp

Return oResp

/*/{Protheus.doc} ZcnAcAdd
Concede acesso ao contrato para um usuario (grava CNN, operacao "acessoAdicionar").
@type Static Function
@param oReq JsonObject, {numero, filial, usuario, tipo (vazio = acesso total)}
@return JsonObject, {success, message}
/*/
//=============================================================================================================================
Static Function ZcnAcAdd(oReq)

    Local oResp    := JsonObject():New()
    Local oErr     := Nil
    Local bPrevErr := Nil
    Local cFilBkp  := ZcnAcFil(oReq)
    Local cNumero  := ""
    Local cUsr     := ""
    Local cTipo    := ""

    If ValType(oReq["numero"])  == "C" ; cNumero := AllTrim(oReq["numero"])  ; EndIf
    If ValType(oReq["usuario"]) == "C" ; cUsr    := AllTrim(oReq["usuario"]) ; EndIf
    If ValType(oReq["tipo"])    == "C" ; cTipo   := AllTrim(oReq["tipo"])    ; EndIf
    If Empty(cTipo)
        cTipo := ZcnAcTot()
    EndIf

    oResp["success"] := .F.
    Do Case
    Case Empty(cNumero) .Or. Empty(cUsr)
        oResp["message"] := "Informe o contrato e o usuario."
    Case !CN9->(dbSetOrder(1), dbSeek(xFilial("CN9") + Padr(cNumero, TamSX3("CN9_NUMERO")[1])))
        oResp["message"] := "Contrato [" + cNumero + "] nao encontrado na filial " + AllTrim(cFilAnt) + "."
    Case Empty(UsrRetName(cUsr))
        oResp["message"] := "Usuario [" + cUsr + "] nao encontrado."
    Case !ZcnAcPode(cNumero)
        oResp["message"] := "Voce nao tem acesso total a este contrato para conceder acesso a outros usuarios."
    Case ZcnAcQtd(cNumero, cUsr, cTipo) > 0
        oResp["message"] := "O usuario " + AllTrim(UsrRetName(cUsr)) + " ja possui este acesso ao contrato."
    OtherWise
        bPrevErr := ErrorBlock({|e| Break(e)})
        Begin Sequence
            ZcnAcGrv(cNumero, cUsr, cTipo)
            oResp["success"] := .T.
            oResp["message"] := "Acesso concedido ao usuario " + AllTrim(UsrRetName(cUsr)) + "."
        Recover Using oErr
            oResp["success"] := .F.
            oResp["message"] := "Erro ao gravar o acesso (CNN): " + AllTrim(oErr:description)
        End Sequence
        ErrorBlock(bPrevErr)
    EndCase

    cFilAnt := cFilBkp

Return oResp

/*/{Protheus.doc} ZcnAcRem
Remove um acesso do contrato (registro CNN pelo RECNO, operacao "acessoRemover") -- confere que
o registro e mesmo do contrato informado antes de apagar. Nao deixa o contrato sem nenhum
usuario com acesso total (ninguem mais conseguiria abri-lo nem dar acesso pela tela).
@type Static Function
@param oReq JsonObject, {numero, filial, recno}
@return JsonObject, {success, message}
/*/
//=============================================================================================================================
Static Function ZcnAcRem(oReq)

    Local oResp    := JsonObject():New()
    Local cFilBkp  := ZcnAcFil(oReq)
    Local cNumero  := ""
    Local cTot     := ZcnAcTot()
    Local nRecno   := 0

    If ValType(oReq["numero"]) == "C" ; cNumero := AllTrim(oReq["numero"]) ; EndIf
    If ValType(oReq["recno"])  == "N" ; nRecno  := oReq["recno"]            ; EndIf

    oResp["success"] := .F.
    DbSelectArea("CNN")
    If nRecno > 0
        CNN->(DbGoTo(nRecno))
    EndIf

    Do Case
    Case Empty(cNumero) .Or. nRecno <= 0
        oResp["message"] := "Informe o contrato e o acesso a remover."
    Case CNN->(Eof()) .Or. CNN->(Deleted()) .Or. CNN->CNN_FILIAL != xFilial("CNN") .Or. AllTrim(CNN->CNN_CONTRA) != cNumero
        oResp["message"] := "Acesso nao encontrado para o contrato [" + cNumero + "]."
    Case !ZcnAcPode(cNumero)
        oResp["message"] := "Voce nao tem acesso total a este contrato para remover acessos."
    Case AllTrim(CNN->CNN_TRACOD) == AllTrim(cTot) .And. !Empty(CNN->CNN_USRCOD) .And. ZcnAcQtdTot(cNumero) <= 1
        oResp["message"] := "Nao e possivel remover o unico usuario com acesso total ao contrato."
    OtherWise
        RecLock("CNN", .F.)
            CNN->(DbDelete())
        MsUnlock()
        oResp["success"] := .T.
        oResp["message"] := "Acesso removido."
    EndCase

    cFilAnt := cFilBkp

Return oResp

/*/{Protheus.doc} ZcnAcQtdTot
Quantos usuarios (nao grupos) tem acesso total ao contrato -- usado por ZcnAcRem.
@type Static Function
@param cContra caractere, numero do contrato
@return numerico
/*/
//=============================================================================================================================
Static Function ZcnAcQtdTot(cContra)

    Local cAliasQ := GetNextAlias()
    Local cTot    := AllTrim(ZcnAcTot())
    Local cCtr    := Padr(cContra, TamSX3("CNN_CONTRA")[1])
    Local nQtd    := 0

    BeginSql Alias cAliasQ
        SELECT CNN.CNN_USRCOD, CNN.CNN_TRACOD
          FROM %table:CNN% CNN
         WHERE CNN.%notDel%
           AND CNN.CNN_FILIAL = %xfilial:CNN%
           AND CNN.CNN_CONTRA = %exp:cCtr%
         ORDER BY CNN.CNN_USRCOD
    EndSql
    While (cAliasQ)->(!Eof())
        If !Empty((cAliasQ)->CNN_USRCOD) .And. AllTrim((cAliasQ)->CNN_TRACOD) == cTot
            nQtd++
        EndIf
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

Return nQtd

/*/{Protheus.doc} ZcnUsr
Lookup de usuarios do Protheus (operacao "lookupUsuario") para conceder acesso ao contrato --
consulta a SYS_USR (usuarios ativos) por codigo/login/nome. Se a consulta SQL falhar (tabela de
usuarios em outro formato neste ambiente), cai para AllUsers().
@type Static Function
@param oReq JsonObject, {filtro}
@return JsonObject, {success, items:[{codigo,login,nome}], hasNext}
/*/
//=============================================================================================================================
Static Function ZcnUsr(oReq)

    Local oResp    := JsonObject():New()
    Local aItens   := {}
    Local aUsr     := {}
    Local oItem    := Nil
    Local oErr     := Nil
    Local bPrevErr := Nil
    Local cAliasQ  := GetNextAlias()
    Local cFiltro  := ""
    Local cQuery   := ""
    Local lSql     := .F.
    Local nI       := 0

    If ValType(oReq["filtro"]) == "C" ; cFiltro := Upper(AllTrim(oReq["filtro"])) ; EndIf
    cFiltro := StrTran(StrTran(cFiltro, "'", ""), "%", "")

    bPrevErr := ErrorBlock({|e| Break(e)})
    Begin Sequence
        cQuery := "SELECT USR_ID, USR_CODIGO, USR_NOME FROM SYS_USR" +;
            " WHERE D_E_L_E_T_ = ' ' AND USR_MSBLQL <> '1'" +;
            " AND (USR_ID LIKE '%" + cFiltro + "%' OR UPPER(USR_CODIGO) LIKE '%" + cFiltro + "%'" +;
            " OR UPPER(USR_NOME) LIKE '%" + cFiltro + "%')" +;
            " ORDER BY USR_NOME"
        MPSysOpenQuery(cQuery, cAliasQ)
        While (cAliasQ)->(!Eof()) .And. Len(aItens) < 20
            oItem := JsonObject():New()
            oItem["codigo"] := AllTrim((cAliasQ)->USR_ID)
            oItem["login"]  := AllTrim((cAliasQ)->USR_CODIGO)
            oItem["nome"]   := AllTrim((cAliasQ)->USR_NOME)
            aAdd(aItens, oItem)
            (cAliasQ)->(DbSkip())
        EndDo
        (cAliasQ)->(DbCloseArea())
        lSql := .T.
    Recover Using oErr
        lSql := .F.
    End Sequence
    ErrorBlock(bPrevErr)

    If !lSql
        aItens := {}
        aUsr   := AllUsers()
        For nI := 1 To Len(aUsr)
            If Len(aItens) >= 20
                Exit
            EndIf
            If !aUsr[nI][1][17] .And. (Empty(cFiltro) .Or. cFiltro $ Upper(aUsr[nI][1][1] + " " + aUsr[nI][1][2] + " " + aUsr[nI][1][4]))
                oItem := JsonObject():New()
                oItem["codigo"] := AllTrim(aUsr[nI][1][1])
                oItem["login"]  := AllTrim(aUsr[nI][1][2])
                oItem["nome"]   := AllTrim(aUsr[nI][1][4])
                aAdd(aItens, oItem)
            EndIf
        Next nI
    EndIf

    oResp["success"] := .T.
    oResp["items"]   := aItens
    oResp["hasNext"] := .F.

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
    cLike := "%'%" + Upper(cFiltro) + "%'%" // UPPER nos dois lados: busca sem diferenciar maiuscula/minuscula

    If cTipo == "C"
        BeginSql Alias cAliasQ
            SELECT A2_COD AS CODIGO, A2_LOJA AS LOJA, A2_NOME AS NOME
              FROM %table:SA2% SA2
             WHERE SA2.%notDel%
               AND SA2.A2_FILIAL = %xfilial:SA2%
               AND (UPPER(SA2.A2_COD) LIKE %exp:cLike% OR UPPER(SA2.A2_NOME) LIKE %exp:cLike%)
             ORDER BY SA2.A2_NOME
        EndSql
    Else
        BeginSql Alias cAliasQ
            SELECT A1_COD AS CODIGO, A1_LOJA AS LOJA, A1_NOME AS NOME
              FROM %table:SA1% SA1
             WHERE SA1.%notDel%
               AND SA1.A1_FILIAL = %xfilial:SA1%
               AND (UPPER(SA1.A1_COD) LIKE %exp:cLike% OR UPPER(SA1.A1_NOME) LIKE %exp:cLike%)
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
    cLike := "%'%" + Upper(cFiltro) + "%'%" // UPPER nos dois lados: busca sem diferenciar maiuscula/minuscula

    BeginSql Alias cAliasQ
        SELECT CN1_CODIGO AS CODIGO, CN1_DESCRI AS DESCRI, CN1_ESPCTR AS ESPCTR
          FROM %table:CN1% CN1
         WHERE CN1.%notDel%
           AND CN1.CN1_FILIAL = %xfilial:CN1%
           AND (UPPER(CN1.CN1_CODIGO) LIKE %exp:cLike% OR UPPER(CN1.CN1_DESCRI) LIKE %exp:cLike%)
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
    cLike := "%'%" + Upper(cFiltro) + "%'%" // UPPER nos dois lados: busca sem diferenciar maiuscula/minuscula

    BeginSql Alias cAliasQ
        SELECT B1_COD AS CODIGO, B1_DESC AS DESCRI, B1_UM AS UM
          FROM %table:SB1% SB1
         WHERE SB1.%notDel%
           AND SB1.B1_FILIAL = %xfilial:SB1%
           AND (UPPER(SB1.B1_COD) LIKE %exp:cLike% OR UPPER(SB1.B1_DESC) LIKE %exp:cLike%)
         ORDER BY SB1.B1_DESC
    EndSql

    While (cAliasQ)->(!Eof()) .And. nCount < 20
        oItem := JsonObject():New()
        oItem["codigo"]    := AllTrim((cAliasQ)->CODIGO)
        oItem["descricao"] := AllTrim((cAliasQ)->DESCRI)
        oItem["unidade"]   := AllTrim((cAliasQ)->UM)
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
    cLike := "%'%" + Upper(cFiltro) + "%'%" // UPPER nos dois lados: busca sem diferenciar maiuscula/minuscula

    BeginSql Alias cAliasQ
        SELECT E4_CODIGO AS CODIGO, E4_DESCRI AS DESCRI
          FROM %table:SE4% SE4
         WHERE SE4.%notDel%
           AND SE4.E4_FILIAL = %xfilial:SE4%
           AND (UPPER(SE4.E4_CODIGO) LIKE %exp:cLike% OR UPPER(SE4.E4_DESCRI) LIKE %exp:cLike%)
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
    cLike := "%'%" + Upper(cFiltro) + "%'%" // UPPER nos dois lados: busca sem diferenciar maiuscula/minuscula

    BeginSql Alias cAliasQ
        SELECT ED_CODIGO AS CODIGO, ED_DESCRIC AS DESCRI
          FROM %table:SED% SED
         WHERE SED.%notDel%
           AND SED.ED_FILIAL = %xfilial:SED%
           AND (UPPER(SED.ED_CODIGO) LIKE %exp:cLike% OR UPPER(SED.ED_DESCRIC) LIKE %exp:cLike%)
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

/*/{Protheus.doc} ZcnPlaExigeCrg
Resolve se UM Tipo de Planilha (CNL) especifico exige cronograma financeiro/
fisico -- mesmos candidatos de campo do lookup ZcnTpPla (logo abaixo), mas
para um codigo ja conhecido. Usado por ZcnMont para devolver esse flag em
planilhas de um contrato JA SALVO (o lookup ZcnTpPla so cobre a combo de
selecao na tela de criacao) -- sem isso, o botao "Editar Parcela" nao tinha
como saber, ao reabrir um contrato existente, se a planilha permite
cronograma (pedido do usuario 2026-09-23, com base na doc oficial de
Contrato Flexivel: Medicao Eventual/Ctr. Fixo determinam se ha cronograma).
@type Static Function
@param cCodigo caractere, codigo do Tipo de Planilha (CNA_TIPPLA)
@return logico ou Nil (campo nao localizado no dicionario, ou codigo vazio/nao encontrado)
/*/
//=============================================================================================================================
Static Function ZcnPlaExigeCrg(cCodigo)

    Local cCpoCrg  := ZcnCpo({"CNL_CRONOG", "CNL_GERCRO", "CNL_TPCRO", "CNL_FISFIN"})
    Local cAliasQ  := ""
    Local cValCrg  := ""
    Local xRet     := Nil
    Local bPrevErr := Nil

    If Empty(cCpoCrg) .Or. Empty(AllTrim(cCodigo))
        Return Nil
    EndIf

    cAliasQ  := GetNextAlias()
    bPrevErr := ErrorBlock({|e| Break(e)})
    Begin Sequence
        BeginSql Alias cAliasQ
            SELECT CNL.%exp:cCpoCrg% AS CRONOG
              FROM %table:CNL% CNL
             WHERE CNL.%notDel%
               AND CNL.CNL_FILIAL = %xfilial:CNL%
               AND CNL.CNL_CODIGO = %exp:AllTrim(cCodigo)%
        EndSql
        If (cAliasQ)->(!Eof())
            cValCrg := AllTrim(Upper(cValToChar((cAliasQ)->CRONOG)))
            xRet := cValCrg == "S" .Or. cValCrg == "1" .Or. cValCrg == "T" .Or. cValCrg == "Y"
        EndIf
        (cAliasQ)->(DbCloseArea())
    Recover
        xRet := Nil
        If Select(cAliasQ) > 0
            (cAliasQ)->(DbCloseArea())
        EndIf
    End Sequence
    ErrorBlock(bPrevErr)

Return xRet

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

    If ValType(oReq["filtro"]) == "C" ; cFiltro := AllTrim(oReq["filtro"]) ; EndIf
    cLike := "%'%" + Upper(cFiltro) + "%'%" // UPPER nos dois lados: busca sem diferenciar maiuscula/minuscula

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
                   AND (UPPER(CNL.CNL_CODIGO) LIKE %exp:cLike% OR UPPER(CNL.CNL_DESCRI) LIKE %exp:cLike%)
                 ORDER BY CNL.CNL_CODIGO
            EndSql
        Recover
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
               AND (UPPER(CNL.CNL_CODIGO) LIKE %exp:cLike% OR UPPER(CNL.CNL_DESCRI) LIKE %exp:cLike%)
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
    cLike := "%'%" + Upper(cFiltro) + "%'%" // UPPER nos dois lados: busca sem diferenciar maiuscula/minuscula

    BeginSql Alias cAliasQ
        SELECT F4_CODIGO AS CODIGO, F4_TEXTO AS DESCRI
          FROM %table:SF4% SF4
         WHERE SF4.%notDel%
           AND (UPPER(SF4.F4_CODIGO) LIKE %exp:cLike% OR UPPER(SF4.F4_TEXTO) LIKE %exp:cLike%)
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
    cLike := "%'%" + Upper(cFiltro) + "%'%" // UPPER nos dois lados: busca sem diferenciar maiuscula/minuscula

    BeginSql Alias cAliasQ
        SELECT CTT_CUSTO AS CODIGO, CTT_DESC01 AS DESCRI
          FROM %table:CTT% CTT
         WHERE CTT.%notDel%
           AND CTT.CTT_FILIAL = %xfilial:CTT%
           AND (UPPER(CTT.CTT_CUSTO) LIKE %exp:cLike% OR UPPER(CTT.CTT_DESC01) LIKE %exp:cLike%)
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
@return JsonObject, {success, numero, tamanho}
/*/
//=============================================================================================================================
Static Function ZcnProxNum(oReq)

    Local oResp := JsonObject():New()

    oResp["success"] := .T.
    oResp["numero"]  := AllTrim(GetSxeNum("CN9", "CN9_NUMERO"))
    // Tamanho do CN9_NUMERO no SX3 -- para o Angular limitar o campo (maxlength) na digitacao
    oResp["tamanho"] := TamSX3("CN9_NUMERO")[1]

Return oResp

/*/{Protheus.doc} ZcnMStr
Le um campo caractere de um submodelo (CNBDETAIL, etc.) de forma segura --
em FWFormGridModel (grades), GetValue com um Id de campo que NAO existe na
estrutura do modelo ESTOURA ERRO em vez de devolver Nil (ao contrario do que
o nome sugere); por isso a leitura passa por ZcnMGet, que blinda via
Begin Sequence/Recover. Usar para campos ainda nao confirmados neste
ambiente (ex: CNB_CC).
@type Static Function
@return caractere, valor do campo (trim) ou "" se nao existir/nao for caractere
/*/
//=============================================================================================================================
Static Function ZcnMStr(oSubModel, cCampo)

    Local xVal := ZcnMGet(oSubModel, cCampo)

Return IIf(ValType(xVal) == "C", AllTrim(xVal), "")

/*/{Protheus.doc} ZcnMNum
Mesma ideia de ZcnMStr, para campo numerico (ex: CNB_PERDES).
@type Static Function
@return numerico, valor do campo ou 0 se nao existir/nao for numerico
/*/
//=============================================================================================================================
Static Function ZcnMNum(oSubModel, cCampo)

    Local xVal := ZcnMGet(oSubModel, cCampo)

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

    Local xVal := ZcnMGet(oSubModel, cCampo)

Return IIf(ValType(xVal) == "D", ZcnDateStr(xVal), "")


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
        aCand := {"CNA_PERI", "CNA_PERREA", "CNA_PERREJ", "CNA_PERIND"}
    Case cChave == "unidadePer"
        aCand := {"CNA_UNPERI", "CNA_UNIREA", "CNA_UNIPER"}
    Case cChave == "modoReajuste"
        aCand := {"CNA_MODORJ", "CNA_MODREJ", "CNA_MODREA", "CNA_TPREJ"}
    Case cChave == "dataBase"
        aCand := {"CNA_DTINI"} // "Data base" da tela = CNA_DTINI (confirmado pelo usuario 2026-10-09)
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

    Begin Sequence
        xVal := oSub:GetValue(cCampo)
    Recover
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
        Return IIf(ValType(xVal) == "D", ZcnDateStr(xVal), "")
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
        xConv := ZcnSToD(xVal)
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
        Recover
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