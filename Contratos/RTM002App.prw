#INCLUDE "TOTVS.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "PROTHEUS.CH"

// Contexto do contrato posicionado no browse (CNTA100) no momento em que o usuario acionou
// "Importar / Exportar Itens do contrato" (aRotina com 4o parametro 4 = considera o registro
// posicionado). Capturado em RTM002App() antes do FWCallApp e lido pela tela via a op
// "contratoPosicionado" -- estatica de modulo (fora de function) para sobreviver entre a
// chamada que abre o app e as chamadas subsequentes de JsToAdvpl na mesma thread.
Static cAppCtxContrato := ""
Static cAppCtxRevisao  := ""

/*/{Protheus.doc} RTM002App
Abre a tela hibrida (Angular/PO-UI) de Importacao de Medicao de Contrato,
versao POUI de RT69M002.prw, empacotada em resource/rtm002.app e carregada
via FWCallApp.

Estagio atual (2026-08-14): aba Importar -- upload do CSV (parse no navegador) +
cabecalho do contrato (tipo Compra/Venda, fornecedor/cliente com selecao quando
o contrato tiver mais de um vinculado, saldo, competencias) + lookup de TES +
validacao de limite por competencia/CNF (ValLim) + geracao da medicao via
CNTA121 (GerarMed/GerarPlan, uma medicao por planilha, mesma logica de
RT69M002.prw::ExecutaMed/ProcessaPlanilha adaptada para JSON estruturado em vez
de CSV e sem dialogs nativos MsgStop/MsgInfo -- os resultados voltam no JSON de
resposta). Aba Exportar -- checklist de planilhas (ListaPlan/ExportarCtr), com o
contrato carregado de imediato quando ha um posicionado no browse (CtxPos, sem
o usuario digitar de novo), pre-visualizacao em tela do cronograma financeiro
por planilha marcada (ListaCron/CarregaCron, "sem cronograma financeiro" quando
vazio) e exportacao para XLSX com abas opcionais de cronograma financeiro e da
ultima medicao de cada planilha (CarregaUltMed).
@type User Function
@author Thiago Sales - Quebec Ambiental
@since 2026-08-07
/*/
//=============================================================================================================================
USER FUNCTION RTM002App()

    // Le o contrato posicionado no browse ANTES de abrir o app -- o FWCallApp roda embutido
    // na mesma thread, mas o browse pode mudar de posicao ou fechar a area enquanto o
    // usuario navega na tela Angular, entao o valor precisa ser congelado aqui.
    cAppCtxContrato := ""
    cAppCtxRevisao  := ""
    If Select("CN9") > 0 .And. CN9->(!Eof())
        cAppCtxContrato := AllTrim(CN9->CN9_NUMERO)
        cAppCtxRevisao  := AllTrim(CN9->CN9_REVISA)
    EndIf

    FWCallApp("rtm002")

RETURN

/*/{Protheus.doc} JsToAdvpl
Recebe mensagens da tela Angular (rtm002) pelo canal AdvplToJs/JsToAdvpl
(TWebEngine/TWebChannel) -- mesmo padrao de Estoque/Armazem/src/EstMinMax.prw
e Controle de Contratos/src/AprovCT.prw.
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
    Case cType == "cabecalhoContrato"
        oResp := CabCtr(oReq)
    Case cType == "lookupTES"
        oResp := LstTES(oReq)
    Case cType == "validarLimite"
        oResp := ValLim(oReq)
    Case cType == "gerarMedicao"
        oResp := GerarMed(oReq)
    Case cType == "listarPlanilhas"
        oResp := ListaPlan(oReq)
    Case cType == "exportarContrato"
        oResp := ExportarCtr(oReq)
    Case cType == "listarCronograma"
        oResp := ListaCron(oReq)
    Case cType == "contratoPosicionado"
        oResp := CtxPos(oReq)
    Case cType == "itensPlanilha"
        oResp := ItensPlan(oReq)
    OtherWise
        oResp["success"] := .F.
        oResp["message"] := "Operacao nao reconhecida: " + cType
    EndCase

    If !Empty(cReceiveId)
        oWebChannel:AdvplToJs(cReceiveId, oResp:toJson())
    EndIf

Return .T.

/*/{Protheus.doc} CtxPos
Devolve o contrato/revisao que estava posicionado no browse (CNTA100) quando o usuario abriu
esta tela -- ver os Statics de modulo cAppCtxContrato/cAppCtxRevisao, preenchidos em
RTM002App() antes do FWCallApp. Usado pela aba Exportar para carregar o contrato de imediato,
sem o usuario precisar digitar o numero de novo.
@type Static Function
@return JsonObject, {success, temContrato, numContrato, revisao}
/*/
//=============================================================================================================================
Static Function CtxPos(oReq)

    Local oResp := JsonObject():New()

    oResp["success"]     := .T.
    oResp["temContrato"] := !Empty(cAppCtxContrato)
    oResp["numContrato"] := cAppCtxContrato
    oResp["revisao"]     := cAppCtxRevisao

Return oResp

/*/{Protheus.doc} CabCtr
Retorna os dados de cabecalho do contrato para a tela de importacao: se e um
contrato de Compra ("C") ou Venda ("V") -- via CN9_ESPCTR ("1"=Compra,
"2"=Venda -- ver Contratos/RT69M001.prw, mesmo campo usado la para decidir se
o CSV traz CND_FORNEC ou CND_CLIENT -- a tela usa esse mesmo tipo para rotular
o campo como "Fornecedor" ou "Cliente"), a lista de fornecedores/clientes
distintos vinculados ao contrato (tabela CNA, pode ter mais de um quando o
contrato tem mais de uma planilha com CNA_FORNEC/CNA_CLIENT diferentes -- ver
nota em RT69M001.prw::BuscaCNA, que hoje usa so o primeiro encontrado; aqui a
tela lista todos e deixa o usuario escolher quando houver mais de um), saldo
do contrato e competencias disponiveis (CtrCompets(), funcao padrao do modulo
de Gestao de Contratos).
@type Static Function
@param oReq JsonObject, {cNumCont, cRevisao}
/*/
//=============================================================================================================================
Static Function CabCtr(oReq)

    Local oResp     := JsonObject():New()
    Local aPessoas  := {}
    Local oPessoa   := Nil
    Local aCompets  := {}
    Local nI        := 0
    Local cAliasQ   := ""
    Local cNumCont  := ""
    Local cRevisao  := ""
    Local cTipo     := ""
    Local nTamNum   := 0
    Local nTamRev   := 0
    Local lAchouCN9 := .F.

    If ValType(oReq["cNumCont"]) == "C" ; cNumCont := AllTrim(oReq["cNumCont"]) ; EndIf
    If ValType(oReq["cRevisao"]) == "C" ; cRevisao := AllTrim(oReq["cRevisao"]) ; EndIf

    If Empty(cNumCont)
        oResp["success"] := .F.
        oResp["message"] := "Numero do contrato nao informado"
        Return oResp
    EndIf

    // Mesma logica de posicionamento de RT69M002.prw::MostraGrid/ProcessaPlanilha: inclui a
    // revisao na chave (senao o dbSeek cai na 1a revisao, mais antiga) e tolera a revisao
    // sem zeros a esquerda (Excel remove ao resalvar o CSV).
    CN9->(dbSetOrder(1))
    nTamNum   := Max(TamSX3("CN9_NUMERO")[1], Len(cNumCont))
    nTamRev   := Max(TamSX3("CN9_REVISA")[1], Len(cRevisao))
    lAchouCN9 := CN9->(dbSeek(xFilial("CN9") + Padr(cNumCont, nTamNum) + Padr(cRevisao, nTamRev)))
    If !lAchouCN9
        lAchouCN9 := CN9->(dbSeek(xFilial("CN9") + Padr(cNumCont, nTamNum) + Padl(cRevisao, nTamRev, "0")))
    EndIf

    If !lAchouCN9
        oResp["success"] := .F.
        oResp["message"] := "Contrato [" + cNumCont + "] revisao [" + cRevisao + "] nao encontrado."
        Return oResp
    EndIf

    cTipo := IIf(AllTrim(CN9->CN9_ESPCTR) == "1", "C", "V")

    // Fornecedores/clientes distintos vinculados ao contrato, um por planilha (CNA) --
    // resolve o nome via SA2/SA1, mesmo padrao de join usado em
    // Gestao de Contratos/Relatorios/QGCT001.PRW.
    cAliasQ := GetNextAlias()
    If cTipo == "C"
        BeginSql Alias cAliasQ
            SELECT DISTINCT CNA.CNA_FORNEC AS CODIGO, CNA.CNA_LJFORN AS LOJA, ISNULL(SA2.A2_NOME, '') AS NOME
              FROM %table:CNA% CNA
              LEFT JOIN %table:SA2% SA2
                ON  SA2.D_E_L_E_T_ = ' '
                AND SA2.A2_FILIAL  = %xfilial:SA2%
                AND SA2.A2_COD     = CNA.CNA_FORNEC
                AND SA2.A2_LOJA    = CNA.CNA_LJFORN
             WHERE CNA.%notDel%
               AND CNA.CNA_FILIAL = %xfilial:CNA%
               AND CNA.CNA_CONTRA = %exp:cNumCont%
               AND CNA.CNA_REVISA = %exp:cRevisao%
               AND CNA.CNA_FORNEC <> ' '
        EndSql
    Else
        BeginSql Alias cAliasQ
            SELECT DISTINCT CNA.CNA_CLIENT AS CODIGO, CNA.CNA_LOJACL AS LOJA, ISNULL(SA1.A1_NOME, '') AS NOME
              FROM %table:CNA% CNA
              LEFT JOIN %table:SA1% SA1
                ON  SA1.D_E_L_E_T_ = ' '
                AND SA1.A1_FILIAL  = %xfilial:SA1%
                AND SA1.A1_COD     = CNA.CNA_CLIENT
                AND SA1.A1_LOJA    = CNA.CNA_LOJACL
             WHERE CNA.%notDel%
               AND CNA.CNA_FILIAL = %xfilial:CNA%
               AND CNA.CNA_CONTRA = %exp:cNumCont%
               AND CNA.CNA_REVISA = %exp:cRevisao%
               AND CNA.CNA_CLIENT <> ' '
        EndSql
    EndIf

    While (cAliasQ)->(!Eof())
        oPessoa := JsonObject():New()
        oPessoa["codigo"] := AllTrim((cAliasQ)->CODIGO)
        oPessoa["loja"]   := AllTrim((cAliasQ)->LOJA)
        oPessoa["nome"]   := AllTrim((cAliasQ)->NOME)
        aAdd(aPessoas, oPessoa)
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

    // CtrCompets() exige o CN9 posicionado no contrato+revisao (feito acima).
    aCompets := CtrCompets()
    For nI := 1 To Len(aCompets)
        aCompets[nI] := AllTrim(aCompets[nI])
    Next nI

    oResp["success"]       := .T.
    oResp["tipo"]          := cTipo
    oResp["pessoas"]       := aPessoas
    oResp["saldoContrato"] := SaldoCtr(cNumCont, cRevisao)
    oResp["competencias"]  := aCompets

Return oResp

/*/{Protheus.doc} ListaPlan
Lista as planilhas (CNA) vinculadas ao contrato/revisao, com fornecedor/cliente, valor
total (CNA_VLTOT) e quantidade de itens (CNB) -- usado pela aba Exportar para montar o
checklist de planilhas. Filtra por pessoa quando cCodigoPessoa vier preenchido (mesma
consulta de pessoas ja usada em CabCtr, aqui aplicada como filtro em vez de so listagem).
@type Static Function
@param oReq JsonObject, {cNumCont, cRevisao, cCodigoPessoa, cLojaPessoa}
@return JsonObject, {success, planilhas: [{numero, codigo, loja, nome, valorTotal, qtdItens}]}
/*/
//=============================================================================================================================
Static Function ListaPlan(oReq)

    Local oResp      := JsonObject():New()
    Local aPlanilhas := {}
    Local aQtdItens  := {}
    Local oPlan      := Nil
    Local cAliasQ    := ""
    Local cNumCont   := ""
    Local cRevisao   := ""
    Local cCodPessoa := ""
    Local cLjPessoa  := ""
    Local cTipo      := ""
    Local nTamNum    := 0
    Local nTamRev    := 0
    Local lAchouCN9  := .F.
    Local nPosQtd    := 0

    If ValType(oReq["cNumCont"])      == "C" ; cNumCont   := AllTrim(oReq["cNumCont"])      ; EndIf
    If ValType(oReq["cRevisao"])      == "C" ; cRevisao   := AllTrim(oReq["cRevisao"])      ; EndIf
    If ValType(oReq["cCodigoPessoa"]) == "C" ; cCodPessoa := AllTrim(oReq["cCodigoPessoa"])  ; EndIf
    If ValType(oReq["cLojaPessoa"])   == "C" ; cLjPessoa  := AllTrim(oReq["cLojaPessoa"])    ; EndIf

    If Empty(cNumCont)
        oResp["success"] := .F.
        oResp["message"] := "Numero do contrato nao informado"
        Return oResp
    EndIf

    // Mesma logica de posicionamento de CabCtr/GerarPlan: inclui a revisao na chave e tolera
    // a revisao sem zeros a esquerda (Excel remove ao resalvar o CSV).
    CN9->(dbSetOrder(1))
    nTamNum   := Max(TamSX3("CN9_NUMERO")[1], Len(cNumCont))
    nTamRev   := Max(TamSX3("CN9_REVISA")[1], Len(cRevisao))
    lAchouCN9 := CN9->(dbSeek(xFilial("CN9") + Padr(cNumCont, nTamNum) + Padr(cRevisao, nTamRev)))
    If !lAchouCN9
        lAchouCN9 := CN9->(dbSeek(xFilial("CN9") + Padr(cNumCont, nTamNum) + Padl(cRevisao, nTamRev, "0")))
    EndIf
    If !lAchouCN9
        oResp["success"] := .F.
        oResp["message"] := "Contrato [" + cNumCont + "] revisao [" + cRevisao + "] nao encontrado."
        Return oResp
    EndIf

    cTipo := IIf(AllTrim(CN9->CN9_ESPCTR) == "1", "C", "V")

    // Qtd. de itens por planilha (CNB), carregada de uma unica vez -- ver CarregaQtdItens
    // logo abaixo. Nao usa subquery correlacionada dentro do BeginSql/EndSql (testado: o
    // preprocessador do BeginSql nao aceita "(SELECT ... )" no SELECT list -- erro de
    // compilacao no EndSql do bloco; nao ha nenhum outro uso de subquery em BeginSql no
    // projeto inteiro). Planilha (CNA) e itens (CNB) tem numeracao 1:1 (CNB_NUMERO =
    // CNA_NUMERO), mesmo vinculo usado em ExportarCtr.
    aQtdItens := CarregaQtdItens(cNumCont, cRevisao)

    cAliasQ := GetNextAlias()
    If cTipo == "C"
        BeginSql Alias cAliasQ
            SELECT CNA.CNA_NUMERO AS NUMERO, CNA.CNA_FORNEC AS CODIGO, CNA.CNA_LJFORN AS LOJA,
                   ISNULL(SA2.A2_NOME, '') AS NOME, CNA.CNA_VLTOT AS VLTOT
              FROM %table:CNA% CNA
              LEFT JOIN %table:SA2% SA2
                ON  SA2.D_E_L_E_T_ = ' '
                AND SA2.A2_FILIAL  = %xfilial:SA2%
                AND SA2.A2_COD     = CNA.CNA_FORNEC
                AND SA2.A2_LOJA    = CNA.CNA_LJFORN
             WHERE CNA.%notDel%
               AND CNA.CNA_FILIAL = %xfilial:CNA%
               AND CNA.CNA_CONTRA = %exp:cNumCont%
               AND CNA.CNA_REVISA = %exp:cRevisao%
        EndSql
    Else
        BeginSql Alias cAliasQ
            SELECT CNA.CNA_NUMERO AS NUMERO, CNA.CNA_CLIENT AS CODIGO, CNA.CNA_LOJACL AS LOJA,
                   ISNULL(SA1.A1_NOME, '') AS NOME, CNA.CNA_VLTOT AS VLTOT
              FROM %table:CNA% CNA
              LEFT JOIN %table:SA1% SA1
                ON  SA1.D_E_L_E_T_ = ' '
                AND SA1.A1_FILIAL  = %xfilial:SA1%
                AND SA1.A1_COD     = CNA.CNA_CLIENT
                AND SA1.A1_LOJA    = CNA.CNA_LOJACL
             WHERE CNA.%notDel%
               AND CNA.CNA_FILIAL = %xfilial:CNA%
               AND CNA.CNA_CONTRA = %exp:cNumCont%
               AND CNA.CNA_REVISA = %exp:cRevisao%
        EndSql
    EndIf

    // Filtro por pessoa e ordenacao ficam aqui (ADVPL), nao dentro do BeginSql -- o
    // preprocessador do BeginSql neste ambiente nao aceita bem um filtro opcional inserido
    // como fragmento cru via %exp: (erro de compilacao no EndSql do bloco quando testado; o
    // unico bloco BeginSql comprovadamente compilando neste arquivo, CabCtr logo acima, so
    // usa %exp: para VALOR de campo, nunca para um trecho de SQL inteiro/condicional).
    While (cAliasQ)->(!Eof())
        If Empty(cCodPessoa) .Or. (AllTrim((cAliasQ)->CODIGO) == cCodPessoa .And. AllTrim((cAliasQ)->LOJA) == cLjPessoa)
            oPlan := JsonObject():New()
            oPlan["numero"]     := AllTrim((cAliasQ)->NUMERO)
            oPlan["codigo"]     := AllTrim((cAliasQ)->CODIGO)
            oPlan["loja"]       := AllTrim((cAliasQ)->LOJA)
            oPlan["nome"]       := AllTrim((cAliasQ)->NOME)
            oPlan["valorTotal"] := (cAliasQ)->VLTOT

            nPosQtd := AScan(aQtdItens, {|x| x[1] == oPlan["numero"]})
            oPlan["qtdItens"] := If(nPosQtd > 0, aQtdItens[nPosQtd][2], 0)

            aAdd(aPlanilhas, oPlan)
        EndIf
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

    oResp["success"]   := .T.
    oResp["planilhas"] := aPlanilhas

Return oResp

/*/{Protheus.doc} ExportarCtr
Monta os dados para exportacao do contrato (aba Exportar): itens das planilhas marcadas
(CNB, com saldo por item calculado da mesma forma que RT69M001.prw::GeraArq -- ver
CarregaQtdMedida/QtdJaMedida logo abaixo, copiadas de la) e, opcionalmente, o cronograma
financeiro (CNF) dessas mesmas planilhas.
Ao contrario de RT69M001.prw::BuscaCNA (que so pega o 1o fornecedor/cliente do contrato
inteiro), aqui o fornecedor/cliente de cada item vem da CNA da PROPRIA planilha daquele
item (join CNB_NUMERO = CNA_NUMERO) -- correto mesmo quando o contrato tem planilhas de
pessoas diferentes.
A ligacao CNF-planilha usa CNF_NUMPLA = CNA_NUMERO diretamente -- CNF_NUMPLA existe e e'
usado assim em "Gestao de Contratos/Relatorios/qcntr121.prw" (~linha 505). O comentario em
RT69M002.prw::LimiteCompetencia dizendo que "CNF nao tem chave direta para a planilha" (e o
workaround por VALOR la, CNF_VLPREV * CNF_MAXPAR ~= CNA_VLTOT) parece nao ter considerado
esse campo -- mantido como esta por ora (fora do escopo desta tela mudar LimiteCompetencia),
mas aqui usamos CNF_NUMPLA por ser mais direto e confiavel.
@type Static Function
@param oReq JsonObject, {cNumCont, cRevisao, aPlanilhas: [string], lCronograma: bool, lUltimaMed: bool}
@return JsonObject, {success, tipo, itens: [...], cronograma: [...], ultimaMedicao: [...]}
/*/
//=============================================================================================================================
Static Function ExportarCtr(oReq)

    Local oResp       := JsonObject():New()
    Local aPlanilhas  := {}
    Local aItens      := {}
    Local cNumCont    := ""
    Local cRevisao    := ""
    Local cTipo       := ""
    Local cInPlan     := ""
    Local nI          := 0
    Local nTamNum     := 0
    Local nTamRev     := 0
    Local lAchouCN9   := .F.
    Local lCronograma := .F.
    Local lUltimaMed  := .F.

    If ValType(oReq["cNumCont"])     == "C" ; cNumCont    := AllTrim(oReq["cNumCont"]) ; EndIf
    If ValType(oReq["cRevisao"])     == "C" ; cRevisao    := AllTrim(oReq["cRevisao"]) ; EndIf
    If ValType(oReq["aPlanilhas"])   == "A" ; aPlanilhas  := oReq["aPlanilhas"]         ; EndIf
    If ValType(oReq["lCronograma"])  == "L" ; lCronograma := oReq["lCronograma"]        ; EndIf
    If ValType(oReq["lUltimaMed"])   == "L" ; lUltimaMed  := oReq["lUltimaMed"]         ; EndIf

    If Empty(cNumCont) .Or. Len(aPlanilhas) == 0
        oResp["success"] := .F.
        oResp["message"] := "Contrato ou planilhas nao informados"
        Return oResp
    EndIf

    CN9->(dbSetOrder(1))
    nTamNum   := Max(TamSX3("CN9_NUMERO")[1], Len(cNumCont))
    nTamRev   := Max(TamSX3("CN9_REVISA")[1], Len(cRevisao))
    lAchouCN9 := CN9->(dbSeek(xFilial("CN9") + Padr(cNumCont, nTamNum) + Padr(cRevisao, nTamRev)))
    If !lAchouCN9
        lAchouCN9 := CN9->(dbSeek(xFilial("CN9") + Padr(cNumCont, nTamNum) + Padl(cRevisao, nTamRev, "0")))
    EndIf
    If !lAchouCN9
        oResp["success"] := .F.
        oResp["message"] := "Contrato [" + cNumCont + "] revisao [" + cRevisao + "] nao encontrado."
        Return oResp
    EndIf

    cTipo := IIf(AllTrim(CN9->CN9_ESPCTR) == "1", "C", "V")

    // Monta a clausula IN com os numeros de planilha marcados. Os valores vem de ListaPlan
    // (nao sao texto livre digitado pelo usuario), mas ainda assim so aceitamos o conteudo
    // convertido/trimado, sem interpolar nada alem disso na query.
    For nI := 1 To Len(aPlanilhas)
        aPlanilhas[nI] := AllTrim(cValToChar(aPlanilhas[nI]))
        If !Empty(cInPlan)
            cInPlan += ","
        EndIf
        cInPlan += "'" + aPlanilhas[nI] + "'"
    Next nI

    aItens := CarregaItens(cNumCont, cRevisao, cInPlan, cTipo)

    oResp["success"]       := .T.
    oResp["tipo"]          := cTipo
    oResp["itens"]         := aItens
    oResp["cronograma"]    := If(lCronograma, CarregaCron(cNumCont, cRevisao, cInPlan), {})
    oResp["ultimaMedicao"] := If(lUltimaMed, CarregaUltMed(cNumCont, cRevisao, aPlanilhas), {})

Return oResp

/*/{Protheus.doc} CarregaItens
Consulta os itens das planilhas informadas (CNB, com saldo por item calculado da mesma forma
que RT69M001.prw::GeraArq) -- extraida de ExportarCtr para ser reaproveitada tambem pela aba
Importar (op "itensPlanilha", ver ItensPlan logo abaixo), que usa este mesmo catalogo para
completar descricao/um/valor unitario/classe valor/saldo de um arquivo de importacao que so
traz planilha+item+produto+quantidade (a identificacao minima pedida pelo usuario -- o resto
vem do cadastro da planilha, nao do arquivo).
@type Static Function
@param cNumCont String, numero do contrato (CN9_NUMERO)
@param cRevisao String, revisao do contrato (CN9_REVISA)
@param cInPlan  String, lista de planilhas ja formatada para IN (...), ex: "'000001','000002'"
@param cTipo    String, "C" (Compra, pessoa = fornecedor) ou "V" (Venda, pessoa = cliente)
@return Array de JsonObject, um item de planilha por elemento
/*/
//=============================================================================================================================
Static Function CarregaItens(cNumCont, cRevisao, cInPlan, cTipo)

    Local aItens   := {}
    Local oItem    := Nil
    Local cAliasQ  := ""
    Local cQuery   := ""
    Local aQtdMed  := {}
    Local nQtdMed  := 0
    Local nSaldoIt := 0

    // Saldo por item = quantidade planejada (CNB_QUANT) menos o que ja foi medido em
    // medicoes anteriores (CNE) -- copia literal de RT69M001.prw::CarregaQtdMedida/
    // QtdJaMedida logo abaixo (Static Function nao e visivel entre .prw diferentes, mesmo
    // padrao ja usado aqui para LimiteCompetencia/ParseNum/TruncaDec).
    aQtdMed := CQtdMed(cNumCont, cRevisao)

    // Query classica (ChangeQuery/DbUseArea), nao BeginSql/EndSql: o preprocessador do
    // BeginSql neste ambiente nao aceita "IN (%exp:...)" com lista dinamica (nao ha nenhum
    // outro uso desse padrao no projeto inteiro, e o teste real deu erro de compilacao) --
    // mesmo estilo ja usado com sucesso em CarregaQtdMedida/SaldoCtr/LimiteCompetencia acima.
    cQuery := " SELECT CNB.CNB_NUMERO AS PLANILHA, CNB.CNB_ITEM AS ITEM, CNB.CNB_PRODUT AS PRODUTO, "
    cQuery += " CNB.CNB_DESCRI AS DESCRICAO, CNB.CNB_UM AS UM, CNB.CNB_QUANT AS QUANTIDADE, "
    cQuery += " CNB.CNB_CC AS CC, CNB.CNB_ITEMCT AS ITEMCT, CNB.CNB_CLVL AS CLASSEVALOR, "
    cQuery += " CNB.CNB_VLUNIT AS VALORUNIT, CNA.CNA_FORNEC AS FORNEC, CNA.CNA_LJFORN AS LJFORN, "
    cQuery += " CNA.CNA_CLIENT AS CLIENTE, CNA.CNA_LOJACL AS LOJACLI "
    cQuery += " FROM " + RetSqlName("CNB") + " CNB, " + RetSqlName("CNA") + " CNA "
    cQuery += " WHERE CNB.D_E_L_E_T_ = ' ' "
    cQuery += " AND CNA.D_E_L_E_T_ = ' ' "
    cQuery += " AND CNA.CNA_FILIAL = CNB.CNB_FILIAL "
    cQuery += " AND CNA.CNA_CONTRA = CNB.CNB_CONTRA "
    cQuery += " AND CNA.CNA_REVISA = CNB.CNB_REVISA "
    cQuery += " AND CNA.CNA_NUMERO = CNB.CNB_NUMERO "
    cQuery += " AND CNB.CNB_FILIAL = '" + FWXFilial("CNB") + "' "
    cQuery += " AND CNB.CNB_CONTRA = '" + cNumCont + "' "
    cQuery += " AND CNB.CNB_REVISA = '" + cRevisao  + "' "
    cQuery += " AND CNB.CNB_NUMERO IN (" + cInPlan + ") "
    cQuery += " ORDER BY CNB.CNB_NUMERO, CNB.CNB_ITEM "
    cQuery := ChangeQuery(cQuery)

    cAliasQ := GetNextAlias()
    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAliasQ, .F., .T.)
    (cAliasQ)->(DbGoTop())

    While (cAliasQ)->(!Eof())
        nQtdMed  := QtdJaMedida(aQtdMed, AllTrim((cAliasQ)->ITEM), AllTrim((cAliasQ)->PRODUTO))
        nSaldoIt := (cAliasQ)->QUANTIDADE - nQtdMed

        oItem := JsonObject():New()
        oItem["contrato"]      := cNumCont
        oItem["revisao"]       := cRevisao
        // CN9 nao tem campo CN9_COMPET (THREAD ERROR "invalid field name" -- confirmado 2026-08-14
        // ao testar contra a base real). RT69M001.prw::GeraArq usa "CN9_COMPET" so como NOME da
        // coluna no CSV (cCampos, linha 66/68) mas grava Dtos(DDataBase) -- a data do sistema no
        // momento da exportacao -- e nao um campo real do CN9. Mesma logica replicada aqui.
        oItem["competencia"]   := Dtos(DDataBase)
        oItem["planilha"]      := AllTrim((cAliasQ)->PLANILHA)
        oItem["item"]          := AllTrim((cAliasQ)->ITEM)
        oItem["produto"]       := AllTrim((cAliasQ)->PRODUTO)
        oItem["descricao"]     := AllTrim((cAliasQ)->DESCRICAO)
        oItem["um"]            := AllTrim((cAliasQ)->UM)
        oItem["quantidade"]    := (cAliasQ)->QUANTIDADE
        oItem["cc"]            := AllTrim((cAliasQ)->CC)
        oItem["itemCt"]        := AllTrim((cAliasQ)->ITEMCT)
        oItem["classeValor"]   := AllTrim((cAliasQ)->CLASSEVALOR)
        oItem["valorUnitario"] := (cAliasQ)->VALORUNIT
        If cTipo == "C"
            oItem["pessoaCodigo"] := AllTrim((cAliasQ)->FORNEC)
            oItem["pessoaLoja"]   := AllTrim((cAliasQ)->LJFORN)
        Else
            oItem["pessoaCodigo"] := AllTrim((cAliasQ)->CLIENTE)
            oItem["pessoaLoja"]   := AllTrim((cAliasQ)->LOJACLI)
        EndIf
        oItem["saldoItem"] := nSaldoIt

        aAdd(aItens, oItem)
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

Return aItens

/*/{Protheus.doc} ItensPlan
Lista os itens (catalogo CNB, com descricao/um/valor unitario/classe valor/saldo) das
planilhas informadas -- usada pela aba Importar para completar um arquivo minimo (que so traz
planilha+item+produto+quantidade, ver CsvParserService no Angular) com os dados que vem do
proprio cadastro da planilha, em vez de exigir que o arquivo os carregue.
@type Static Function
@param oReq JsonObject, {cNumCont, cRevisao, aPlanilhas: [string]}
@return JsonObject, {success, tipo, itens: [...]}
/*/
//=============================================================================================================================
Static Function ItensPlan(oReq)

    Local oResp      := JsonObject():New()
    Local aPlanilhas := {}
    Local cNumCont   := ""
    Local cRevisao   := ""
    Local cTipo      := ""
    Local cInPlan    := ""
    Local nI         := 0
    Local nTamNum    := 0
    Local nTamRev    := 0
    Local lAchouCN9  := .F.

    If ValType(oReq["cNumCont"])   == "C" ; cNumCont   := AllTrim(oReq["cNumCont"]) ; EndIf
    If ValType(oReq["cRevisao"])   == "C" ; cRevisao   := AllTrim(oReq["cRevisao"]) ; EndIf
    If ValType(oReq["aPlanilhas"]) == "A" ; aPlanilhas := oReq["aPlanilhas"]         ; EndIf

    If Empty(cNumCont) .Or. Len(aPlanilhas) == 0
        oResp["success"] := .F.
        oResp["message"] := "Contrato ou planilhas nao informados"
        Return oResp
    EndIf

    CN9->(dbSetOrder(1))
    nTamNum   := Max(TamSX3("CN9_NUMERO")[1], Len(cNumCont))
    nTamRev   := Max(TamSX3("CN9_REVISA")[1], Len(cRevisao))
    lAchouCN9 := CN9->(dbSeek(xFilial("CN9") + Padr(cNumCont, nTamNum) + Padr(cRevisao, nTamRev)))
    If !lAchouCN9
        lAchouCN9 := CN9->(dbSeek(xFilial("CN9") + Padr(cNumCont, nTamNum) + Padl(cRevisao, nTamRev, "0")))
    EndIf
    If !lAchouCN9
        oResp["success"] := .F.
        oResp["message"] := "Contrato [" + cNumCont + "] revisao [" + cRevisao + "] nao encontrado."
        Return oResp
    EndIf

    cTipo := IIf(AllTrim(CN9->CN9_ESPCTR) == "1", "C", "V")

    For nI := 1 To Len(aPlanilhas)
        aPlanilhas[nI] := AllTrim(cValToChar(aPlanilhas[nI]))
        If !Empty(cInPlan)
            cInPlan += ","
        EndIf
        cInPlan += "'" + aPlanilhas[nI] + "'"
    Next nI

    oResp["success"] := .T.
    oResp["tipo"]     := cTipo
    oResp["itens"]    := CarregaItens(cNumCont, cRevisao, cInPlan, cTipo)

Return oResp

/*/{Protheus.doc} CarregaCron
Consulta o cronograma financeiro (CNF) das planilhas informadas -- extraida de ExportarCtr
para ser reaproveitada tambem pela pre-visualizacao em tela (op "listarCronograma", ver
ListaCron logo abaixo), que roda independente do checkbox "incluir no arquivo exportado".
Query classica (ChangeQuery/DbUseArea), nao BeginSql/EndSql -- mesmo motivo documentado em
ExportarCtr (o preprocessador do BeginSql neste ambiente nao aceita "IN (%exp:...)" com lista
dinamica).
@type Static Function
@param cNumCont String, numero do contrato (CN9_NUMERO)
@param cRevisao String, revisao do contrato (CN9_REVISA)
@param cInPlan  String, lista de planilhas ja formatada para IN (...), ex: "'000001','000002'"
@return Array de JsonObject, uma parcela do cronograma por elemento
/*/
//=============================================================================================================================
Static Function CarregaCron(cNumCont, cRevisao, cInPlan)

    Local aCronog := {}
    Local oParc   := Nil
    Local cAliasQ := ""
    Local cQuery  := ""

    cQuery := " SELECT CNF.CNF_NUMPLA AS PLANILHA, CNF.CNF_NUMERO AS NUMERO, CNF.CNF_COMPET AS COMPETENCIA, "
    cQuery += " CNF.CNF_PARCEL AS PARCELA, CNF.CNF_PRUMED AS DTPREVISTA, CNF.CNF_VLPREV AS VLPREVISTO, "
    cQuery += " CNF.CNF_MAXPAR AS MAXPARCELA, CNF.CNF_SALDO AS SALDO, CNF.CNF_DTREAL AS DTREALIZADA "
    cQuery += " FROM " + RetSqlName("CNF") + " CNF "
    cQuery += " WHERE CNF.D_E_L_E_T_ = ' ' "
    cQuery += " AND CNF.CNF_FILIAL = '" + FWXFilial("CNF") + "' "
    cQuery += " AND CNF.CNF_CONTRA = '" + cNumCont + "' "
    cQuery += " AND CNF.CNF_REVISA = '" + cRevisao  + "' "
    cQuery += " AND CNF.CNF_NUMPLA IN (" + cInPlan + ") "
    cQuery += " ORDER BY CNF.CNF_NUMPLA, CNF.CNF_COMPET "
    cQuery := ChangeQuery(cQuery)

    cAliasQ := GetNextAlias()
    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAliasQ, .F., .T.)
    (cAliasQ)->(DbGoTop())

    While (cAliasQ)->(!Eof())
        oParc := JsonObject():New()
        oParc["planilha"]      := AllTrim((cAliasQ)->PLANILHA)
        oParc["numero"]        := AllTrim((cAliasQ)->NUMERO)
        oParc["competencia"]   := AllTrim((cAliasQ)->COMPETENCIA)
        oParc["parcela"]       := AllTrim((cAliasQ)->PARCELA)
        oParc["dataPrevista"]  := DateStr((cAliasQ)->DTPREVISTA)
        oParc["valorPrevisto"] := (cAliasQ)->VLPREVISTO
        oParc["maxParcela"]    := (cAliasQ)->MAXPARCELA
        oParc["saldo"]         := (cAliasQ)->SALDO
        oParc["dataRealizada"] := DateStr((cAliasQ)->DTREALIZADA)
        aAdd(aCronog, oParc)
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

Return aCronog

/*/{Protheus.doc} ListaCron
Pre-visualizacao em tela do cronograma financeiro (CNF) das planilhas marcadas na aba
Exportar -- op independente do "Exportar" (nao gera arquivo, so lista para conferencia).
Devolve array vazio (nao erro) quando o contrato/planilhas nao tem cronograma -- quem decide
exibir "sem cronograma financeiro" e o Angular, olhando o tamanho do array.
@type Static Function
@param oReq JsonObject, {cNumCont, cRevisao, aPlanilhas: [string]}
@return JsonObject, {success, cronograma: [...]}
/*/
//=============================================================================================================================
Static Function ListaCron(oReq)

    Local oResp      := JsonObject():New()
    Local cNumCont    := ""
    Local cRevisao   := ""
    Local aPlanilhas := {}
    Local cInPlan    := ""
    Local nI         := 0

    If ValType(oReq["cNumCont"])   == "C" ; cNumCont   := AllTrim(oReq["cNumCont"]) ; EndIf
    If ValType(oReq["cRevisao"])   == "C" ; cRevisao   := AllTrim(oReq["cRevisao"]) ; EndIf
    If ValType(oReq["aPlanilhas"]) == "A" ; aPlanilhas := oReq["aPlanilhas"]         ; EndIf

    If Empty(cNumCont) .Or. Len(aPlanilhas) == 0
        oResp["success"]    := .T.
        oResp["cronograma"] := {}
        Return oResp
    EndIf

    For nI := 1 To Len(aPlanilhas)
        aPlanilhas[nI] := AllTrim(cValToChar(aPlanilhas[nI]))
        If !Empty(cInPlan)
            cInPlan += ","
        EndIf
        cInPlan += "'" + aPlanilhas[nI] + "'"
    Next nI

    oResp["success"]    := .T.
    oResp["cronograma"] := CarregaCron(cNumCont, cRevisao, cInPlan)

Return oResp

/*/{Protheus.doc} CarregaUltMed
Busca a ultima medicao (maior CNE_NUMMED) ja gerada para cada planilha informada -- lembrando
que GerarPlan gera UMA medicao (CND) POR planilha (ver nota em GerarMed), entao "a ultima
medicao do contrato" e, na pratica, a ultima medicao de CADA planilha exportada, nao um unico
numero global. CNE_NUMERO e a chave que liga o item de medicao a planilha (CNA.CNA_NUMERO =
CNE.CNE_NUMERO -- mesmo join usado em Gestao de Contratos/Relatorios/QGCT001.PRW).
Loop planilha-a-planilha com queries simples (nao uma unica query com subquery correlacionada
no SELECT list/derived table) -- mesmo motivo documentado em ListaPlan sobre o BeginSql deste
ambiente nao aceitando esse padrao, e para manter o mesmo estilo (classica/ChangeQuery) do
resto do arquivo.
@type Static Function
@param cNumCont   String, numero do contrato (CN9_NUMERO)
@param cRevisao   String, revisao do contrato (CN9_REVISA)
@param aPlanilhas Array de String, numeros de planilha (CNA_NUMERO/CNE_NUMERO) a consultar
@return Array de JsonObject, itens da ultima medicao de cada planilha (vazio se a planilha
        nunca foi medida)
/*/
//=============================================================================================================================
Static Function CarregaUltMed(cNumCont, cRevisao, aPlanilhas)

    Local aRet    := {}
    Local oItem   := Nil
    Local cAliasQ := ""
    Local cQuery  := ""
    Local cPlan   := ""
    Local cUltNum := ""
    Local nI      := 0

    For nI := 1 To Len(aPlanilhas)
        cPlan := AllTrim(cValToChar(aPlanilhas[nI]))

        cQuery := " SELECT MAX(CNE_NUMMED) AS ULTNUM "
        cQuery += " FROM " + RetSqlName("CNE") + " CNE "
        cQuery += " WHERE CNE.D_E_L_E_T_ = ' ' "
        cQuery += " AND CNE_FILIAL = '" + FWXFilial("CNE") + "' "
        cQuery += " AND CNE_CONTRA = '" + cNumCont + "' "
        cQuery += " AND CNE_REVISA = '" + cRevisao  + "' "
        cQuery += " AND CNE_NUMERO = '" + cPlan     + "' "
        cQuery := ChangeQuery(cQuery)

        cAliasQ := GetNextAlias()
        DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAliasQ, .F., .T.)
        cUltNum := If((cAliasQ)->(Eof()) .Or. Empty((cAliasQ)->ULTNUM), "", AllTrim((cAliasQ)->ULTNUM))
        (cAliasQ)->(DbCloseArea())

        If Empty(cUltNum)
            Loop
        EndIf

        // CNE010 nao tem colunas CNE_DESCRI nem CNE_TES (confirmado via erro real do SQL Server:
        // "Invalid column name 'CNE_DESCRI'"/"'CNE_TES'") -- ao contrario do que os nomes desses
        // campos em GerarPlan/TrySet (que gravam via MVC, nao SQL direto) sugeririam. Descricao
        // vem por JOIN com CNB (mesmo join de planilha+item usado em ExportarCtr), e TES fica de
        // fora deste retorno por nao haver coluna real para ler.
        cQuery := " SELECT CNE.CNE_ITEM AS ITEM, CNE.CNE_PRODUT AS PRODUTO, CNB.CNB_DESCRI AS DESCRICAO, "
        cQuery += " CNE.CNE_QUANT AS QUANTIDADE, CNE.CNE_VLUNIT AS VALORUNIT, CNE.CNE_VLTOT AS VALORTOT, "
        cQuery += " CNE.CNE_CC AS CC, CNE.CNE_DTENT AS DTENTREGA "
        cQuery += " FROM " + RetSqlName("CNE") + " CNE "
        cQuery += " LEFT JOIN " + RetSqlName("CNB") + " CNB "
        cQuery += " ON CNB.D_E_L_E_T_ = ' ' "
        cQuery += " AND CNB.CNB_FILIAL = CNE.CNE_FILIAL "
        cQuery += " AND CNB.CNB_CONTRA = CNE.CNE_CONTRA "
        cQuery += " AND CNB.CNB_REVISA = CNE.CNE_REVISA "
        cQuery += " AND CNB.CNB_NUMERO = CNE.CNE_NUMERO "
        cQuery += " AND CNB.CNB_ITEM   = CNE.CNE_ITEM "
        cQuery += " WHERE CNE.D_E_L_E_T_ = ' ' "
        cQuery += " AND CNE_FILIAL = '" + FWXFilial("CNE") + "' "
        cQuery += " AND CNE_CONTRA = '" + cNumCont + "' "
        cQuery += " AND CNE_REVISA = '" + cRevisao  + "' "
        cQuery += " AND CNE_NUMERO = '" + cPlan     + "' "
        cQuery += " AND CNE_NUMMED = '" + cUltNum   + "' "
        cQuery += " ORDER BY CNE.CNE_ITEM "
        cQuery := ChangeQuery(cQuery)

        cAliasQ := GetNextAlias()
        DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAliasQ, .F., .T.)
        (cAliasQ)->(DbGoTop())
        While !(cAliasQ)->(Eof())
            oItem := JsonObject():New()
            oItem["planilha"]      := cPlan
            oItem["numMedicao"]    := cUltNum
            oItem["item"]          := AllTrim((cAliasQ)->ITEM)
            oItem["produto"]       := AllTrim((cAliasQ)->PRODUTO)
            oItem["descricao"]     := AllTrim((cAliasQ)->DESCRICAO)
            oItem["quantidade"]    := (cAliasQ)->QUANTIDADE
            oItem["valorUnitario"] := (cAliasQ)->VALORUNIT
            oItem["valorTotal"]    := (cAliasQ)->VALORTOT
            oItem["cc"]            := AllTrim((cAliasQ)->CC)
            oItem["dataEntrega"]   := DateStr((cAliasQ)->DTENTREGA)
            aAdd(aRet, oItem)
            (cAliasQ)->(DbSkip())
        EndDo
        (cAliasQ)->(DbCloseArea())
    Next nI

Return aRet

/*/{Protheus.doc} LstTES
Lookup de TES (SF4) para o campo editavel de TES da grade de itens. Filtra por
codigo (prefixo) ou descricao (substring) via cFiltro.
IMPORTANTE: assume tabela SF4 com campos F4_CODIGO/F4_TEXTO (padrao Protheus).
Confirme no dicionario de dados caso o ambiente use outra nomenclatura.
IMPORTANTE: sem paginacao real -- limita a 20 registros no laco ADVPL.
@type Static Function
@param oReq JsonObject, {cFiltro}
/*/
//=============================================================================================================================
Static Function LstTES(oReq)

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
        SELECT F4_CODIGO, F4_TEXTO
          FROM %table:SF4% SF4
         WHERE SF4.%notDel%
           AND (SF4.F4_CODIGO LIKE %exp:cLikeCod% OR SF4.F4_TEXTO LIKE %exp:cLikeDesc%)
         ORDER BY SF4.F4_CODIGO
    EndSql

    While (cAliasQ)->(!Eof()) .And. nCount < 20
        oItem := JsonObject():New()
        oItem["value"] := AllTrim((cAliasQ)->F4_CODIGO)
        oItem["label"] := AllTrim((cAliasQ)->F4_CODIGO) + " - " + AllTrim((cAliasQ)->F4_TEXTO)
        aAdd(aItens, oItem)
        nCount++
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

    oResp["success"] := .T.
    oResp["items"]   := aItens
    oResp["hasNext"] := .F.

Return oResp

/*/{Protheus.doc} SaldoCtr
Calcula o saldo do contrato: valor total planejado na planilha (CNB) menos o
total ja apropriado em medicoes anteriores (CNE). Mesma logica de
RT69M002.prw::SaldoCtr -- nao reproduz a validacao POR COMPETENCIA que o
CNTA121 faz, serve so como saldo geral de referencia.
@type Static Function
/*/
//=============================================================================================================================
Static Function SaldoCtr(cContrato, cRevisao)

    Local cAlias   := ""
    Local cQuery   := ""
    Local nVlPlan  := 0
    Local nVlMed   := 0

    cQuery := " SELECT SUM(CNB_QUANT * CNB_VLUNIT) AS VLPLAN "
    cQuery += " FROM " + RetSqlName("CNB") + " CNB "
    cQuery += " WHERE CNB.D_E_L_E_T_ = ' ' "
    cQuery += " AND CNB_FILIAL = '" + FWXFilial("CNB") + "' "
    cQuery += " AND CNB_CONTRA = '" + cContrato + "' "
    cQuery += " AND CNB_REVISA = '" + cRevisao  + "' "
    cQuery := ChangeQuery(cQuery)

    cAlias := GetNextAlias()
    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAlias, .F., .T.)
    nVlPlan := If(Empty((cAlias)->VLPLAN), 0, (cAlias)->VLPLAN)
    (cAlias)->(DbCloseArea())

    cQuery := " SELECT SUM(CNE_VLTOT) AS VLMED "
    cQuery += " FROM " + RetSqlName("CNE") + " CNE "
    cQuery += " WHERE CNE.D_E_L_E_T_ = ' ' "
    cQuery += " AND CNE_FILIAL = '" + FWXFilial("CNE") + "' "
    cQuery += " AND CNE_CONTRA = '" + cContrato + "' "
    cQuery += " AND CNE_REVISA = '" + cRevisao  + "' "
    cQuery := ChangeQuery(cQuery)

    cAlias := GetNextAlias()
    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAlias, .F., .T.)
    nVlMed := If(Empty((cAlias)->VLMED), 0, (cAlias)->VLMED)
    (cAlias)->(DbCloseArea())

Return nVlPlan - nVlMed

/*/{Protheus.doc} LimiteCompetencia
Calcula o limite de medicao para UMA planilha numa competencia especifica, usando o
Cronograma Financeiro (CNF) -- copia literal de RT69M002.prw::LimiteCompetencia (Static
Function nao e visivel entre .prw diferentes). Ver o comentario la para a formula completa
e a premissa de ligacao por VALOR (CNF_VLPREV * CNF_MAXPAR ~= CNA_VLTOT) entre CNF e CNA.
@type Static Function
@param cContrato String, numero do contrato (CN9_NUMERO)
@param cRevisao  String, revisao do contrato (CN9_REVISA)
@param cNumPlan  String, numero da planilha (CNA_NUMERO/CNB_NUMERO)
@param cCompet   String, competencia no formato MM/AAAA
@return Numeric, limite de medicao para aquela planilha/competencia, ou -1 se nao encontrado
/*/
//=============================================================================================================================
Static Function LimiteCompetencia(cContrato, cRevisao, cNumPlan, cCompet)

    Local cAlias     := ""
    Local cQuery     := ""
    Local nVlTotPlan := 0
    Local nLimite    := -1

    cQuery := " SELECT CNA_VLTOT "
    cQuery += " FROM " + RetSqlName("CNA") + " CNA "
    cQuery += " WHERE CNA.D_E_L_E_T_ = ' ' "
    cQuery += " AND CNA_FILIAL = '" + FWXFilial("CNA") + "' "
    cQuery += " AND CNA_CONTRA = '" + cContrato + "' "
    cQuery += " AND CNA_NUMERO = '" + cNumPlan  + "' "
    cQuery := ChangeQuery(cQuery)

    cAlias := GetNextAlias()
    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAlias, .F., .T.)
    If !(cAlias)->(Eof())
        nVlTotPlan := (cAlias)->CNA_VLTOT
    EndIf
    (cAlias)->(DbCloseArea())

    If nVlTotPlan <= 0
        Return -1
    EndIf

    cQuery := " SELECT CNF_VLPREV, CNF_SALDO "
    cQuery += " FROM " + RetSqlName("CNF") + " CNF "
    cQuery += " WHERE CNF.D_E_L_E_T_ = ' ' "
    cQuery += " AND CNF_FILIAL = '" + FWXFilial("CNF") + "' "
    cQuery += " AND CNF_CONTRA = '" + cContrato + "' "
    cQuery += " AND CNF_REVISA = '" + cRevisao  + "' "
    cQuery += " AND CNF_COMPET = '" + cCompet   + "' "
    cQuery += " AND ABS((CNF_VLPREV * CNF_MAXPAR) - " + Str(nVlTotPlan, 20, 2) + ") < 1 "
    cQuery := ChangeQuery(cQuery)

    cAlias := GetNextAlias()
    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAlias, .F., .T.)
    If !(cAlias)->(Eof())
        nLimite := (cAlias)->CNF_VLPREV + (cAlias)->CNF_SALDO
    EndIf
    (cAlias)->(DbCloseArea())

Return nLimite

/*/{Protheus.doc} DateStr
Converte um valor "tipo data" vindo de um alias de query (ChangeQuery/DbUseArea via TOPCONN)
para "AAAAMMDD", tolerando tanto Date quanto Character -- alguns campos data neste dicionario
(ex.: CNF_PRUMED/CNF_DTREAL, confirmado Character em
"Gestao de Contratos/Relatorios/qcntr121.prw" linhas 143/144, comparados contra literais de
string) voltam como texto e nao como Date de uma query TOPCONN, ao contrario do que o nome do
campo sugere -- DtoS() direto nesses campos gera "argument #0 error, expected D->C". Outros
(ex.: CNE_DTENT, que QGCT001.PRW precisa passar por stoD() apos a mesma query) parecem seguir
o mesmo padrao. Esta funcao evita reproduzir esse erro campo a campo.
@type Static Function
@param xVal Date ou Character, valor lido do alias de query
@return Character, "AAAAMMDD" (ou "" se vazio/tipo inesperado)
/*/
//====================================================================================================
Static Function DateStr(xVal)

    Local cRet := ""

    Do Case
    Case ValType(xVal) == "D"
        cRet := DtoS(xVal)
    Case ValType(xVal) == "C"
        cRet := AllTrim(xVal)
    EndCase

Return cRet

/*/{Protheus.doc} ParseNum
Converte texto numerico vindo do JS para Numeric -- copia de RT69M002.prw::ParseNum, mesma
tolerancia a formato BR (virgula decimal) alem do formato sem separador de milhar.
@type Static Function
@param cVal String, Valor numerico como veio do JS
@return Numeric, Valor convertido
/*/
//====================================================================================================
Static Function ParseNum(cVal)

    Local cTxt := Alltrim(cVal)

    If "," $ cTxt
        cTxt := StrTran(StrTran(cTxt, ".", ""), ",", ".")
    EndIf
Return Val(cTxt)

/*/{Protheus.doc} TruncaDec
Trunca (sem arredondar) um valor numerico para a quantidade de casas decimais do campo
informado -- copia de RT69M002.prw::TruncaDec.
@type Static Function
@param nValor Numeric, valor a truncar
@param cCampo String, nome do campo no dicionario (define a quantidade de casas decimais)
@return Numeric, valor truncado
/*/
//====================================================================================================
Static Function TruncaDec(nValor, cCampo)

    Local aTam   := TamSX3(cCampo)
    Local nDec   := If(Len(aTam) >= 2 .And. aTam[2] > 0, aTam[2], 2)
    Local nFator := 10 ** nDec
Return Int(nValor * nFator + 0.00001) / nFator

/*/{Protheus.doc} CarregaQtdItens
Carrega, de uma unica vez, a quantidade de itens (CNB) de cada planilha (CNB_NUMERO) do
contrato/revisao informados -- usada por ListaPlan para montar o checklist de planilhas da
aba Exportar. Query flat com GROUP BY (sem BeginSql/EndSql e sem subquery -- ver nota em
ListaPlan sobre o BeginSql nao aceitar subquery no SELECT list), mesmo estilo de
CarregaQtdMedida logo abaixo.
@type Static Function
@param cContrato String, Numero do contrato (CN9_NUMERO)
@param cRevisao  String, Revisao do contrato (CN9_REVISA)
@return Array, {{cNumPlanilha, nQtdItens}, ...}
/*/
//====================================================================================================
Static Function CarregaQtdItens(cContrato, cRevisao)

    Local cAlias := GetNextAlias()
    Local cQuery := ""
    Local aRet   := {}

    cQuery := " SELECT CNB_NUMERO, COUNT(*) AS QTDITENS "
    cQuery += " FROM " + RetSqlName("CNB") + " CNB "
    cQuery += " WHERE CNB.D_E_L_E_T_ = ' ' "
    cQuery += " AND CNB_FILIAL = '" + FWXFilial("CNB") + "' "
    cQuery += " AND CNB_CONTRA = '" + cContrato + "' "
    cQuery += " AND CNB_REVISA = '" + cRevisao  + "' "
    cQuery += " GROUP BY CNB_NUMERO "
    cQuery := ChangeQuery(cQuery)

    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAlias, .F., .T.)
    (cAlias)->(DbGoTop())
    While !(cAlias)->(Eof())
        AAdd(aRet, {Alltrim((cAlias)->CNB_NUMERO), (cAlias)->QTDITENS})
        (cAlias)->(DbSkip())
    End
    (cAlias)->(DbCloseArea())
Return aRet

/*/{Protheus.doc} CarregaQtdMedida
Carrega, de uma unica vez, a quantidade ja medida (SUM de CNE_QUANT) em medicoes
anteriores para cada combinacao item+produto do contrato/revisao informados -- copia
literal de RT69M001.prw::CarregaQtdMedida (Static Function nao e visivel entre .prw
diferentes, mesmo padrao ja usado aqui para LimiteCompetencia/ParseNum/TruncaDec).
Usada por ExportarCtr (aba Exportar) para calcular o saldo por item.
@type Static Function
@param cContrato String, Numero do contrato (CN9_NUMERO)
@param cRevisao  String, Revisao do contrato (CN9_REVISA)
@return Array, {{cItem, cProduto, nQtdMedida}, ...}
/*/
//====================================================================================================
Static Function CQtdMed(cContrato, cRevisao)

    Local cAlias := GetNextAlias()
    Local cQuery := ""
    Local aRet   := {}

    cQuery := " SELECT CNE_ITEM, CNE_PRODUT, SUM(CNE_QUANT) AS QTDMED "
    cQuery += " FROM " + RetSqlName("CNE") + " CNE "
    cQuery += " WHERE CNE.D_E_L_E_T_ = ' ' "
    cQuery += " AND CNE_FILIAL = '" + FWXFilial("CNE") + "' "
    cQuery += " AND CNE_CONTRA = '" + cContrato + "' "
    cQuery += " AND CNE_REVISA = '" + cRevisao  + "' "
    cQuery += " GROUP BY CNE_ITEM, CNE_PRODUT "
    cQuery := ChangeQuery(cQuery)

    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAlias, .F., .T.)
    (cAlias)->(DbGoTop())
    While !(cAlias)->(Eof())
        AAdd(aRet, {Alltrim((cAlias)->CNE_ITEM), Alltrim((cAlias)->CNE_PRODUT), (cAlias)->QTDMED})
        (cAlias)->(DbSkip())
    End
    (cAlias)->(DbCloseArea())
Return aRet

/*/{Protheus.doc} QtdJaMedida
Consulta no array retornado por CarregaQtdMedida a quantidade ja medida para um
item+produto especifico -- copia literal de RT69M001.prw::QtdJaMedida.
@type Static Function
@param aQtdMed Array, Retorno de CarregaQtdMedida
@param cItem   String, Codigo do item (CNB_ITEM)
@param cProduto String, Codigo do produto (CNB_PRODUT)
@return Numeric, Quantidade ja medida (0 se nunca medido)
/*/
//====================================================================================================
Static Function QtdJaMedida(aQtdMed, cItem, cProduto)

    Local nPos := AScan(aQtdMed, {|x| x[1] == cItem .And. x[2] == cProduto})
Return If(nPos > 0, aQtdMed[nPos][3], 0)

//====================================================================================================
Static Function TrySet(oMdl, aFalhas, cGrd, cFld, xVal)

    Local bPrevErr := ErrorBlock({|e| Break(e)})
    Local oErr := Nil
    Begin Sequence
        oMdl:SetValue(cGrd, cFld, xVal)
    Recover Using oErr
        AAdd(aFalhas, cFld + ": " + oErr:Description)
    End Sequence
    ErrorBlock(bPrevErr)
Return Nil

/*/{Protheus.doc} ValLim
Valida se alguma planilha do arquivo excede o limite de medicao previsto no cronograma
financeiro (CNF) para a competencia escolhida -- mesma logica de
RT69M002.prw::ConfirmarMed, mas devolve os avisos em JSON (esta tela nao usa MsgNoYes; quem
decide se continua mesmo assim e o usuario, via po-dialog no Angular).
@type Static Function
@param oReq JsonObject, {cNumCont, cRevisao, cCompet, itens: [{planilha, quantidade, valorUnitario}]}
@return JsonObject, {success, excedeLimite, avisos: [{planilha, totalInformado, limite}]}
/*/
//=============================================================================================================================
Static Function ValLim(oReq)

    Local oResp      := JsonObject():New()
    Local aItens     := {}
    Local aPlanilhas := {}
    Local aSubtot    := {}
    Local aAvisos    := {}
    Local oItem      := Nil
    Local oAviso     := Nil
    Local cNumCont   := ""
    Local cRevisao   := ""
    Local cCompet    := ""
    Local cPlan      := ""
    Local nQt        := 0
    Local nVu        := 0
    Local nLimite    := 0
    Local nI         := 0
    Local nPos       := 0

    If ValType(oReq["cNumCont"]) == "C" ; cNumCont := AllTrim(oReq["cNumCont"]) ; EndIf
    If ValType(oReq["cRevisao"]) == "C" ; cRevisao := AllTrim(oReq["cRevisao"]) ; EndIf
    If ValType(oReq["cCompet"])  == "C" ; cCompet  := AllTrim(oReq["cCompet"])  ; EndIf
    If ValType(oReq["itens"])    == "A" ; aItens   := oReq["itens"]             ; EndIf

    If Empty(cNumCont) .Or. Empty(cCompet)
        oResp["success"] := .F.
        oResp["message"] := "Contrato ou competencia nao informados"
        Return oResp
    EndIf

    // Soma o valor informado por planilha (mesma logica de RT69M002.prw::ConfirmarMed) --
    // um contrato pode ter mais de uma planilha, cada uma com seu proprio limite.
    For nI := 1 To Len(aItens)
        oItem := aItens[nI]
        cPlan := AllTrim(oItem["planilha"])
        nPos  := AScan(aPlanilhas, cPlan)
        If nPos == 0
            AAdd(aPlanilhas, cPlan)
            AAdd(aSubtot, 0)
            nPos := Len(aPlanilhas)
        EndIf
        nQt := ParseNum(oItem["quantidade"])
        nVu := ParseNum(oItem["valorUnitario"])
        aSubtot[nPos] += TruncaDec(nQt * nVu, "CNE_VLTOT")
    Next nI

    For nI := 1 To Len(aPlanilhas)
        nLimite := LimiteCompetencia(cNumCont, cRevisao, aPlanilhas[nI], cCompet)
        If nLimite >= 0 .And. aSubtot[nI] > nLimite
            oAviso := JsonObject():New()
            oAviso["planilha"]       := aPlanilhas[nI]
            oAviso["totalInformado"] := aSubtot[nI]
            oAviso["limite"]         := nLimite
            AAdd(aAvisos, oAviso)
        EndIf
    Next nI

    oResp["success"]      := .T.
    oResp["excedeLimite"] := Len(aAvisos) > 0
    oResp["avisos"]       := aAvisos

Return oResp

/*/{Protheus.doc} GerarMed
Agrupa os itens recebidos por planilha e gera UMA medicao (CNTA121) por planilha via
GerarPlan -- mesma logica de RT69M002.prw::ExecutaMed (gerar tudo junto numa unica medicao
somaria os limites de cronogramas financeiros distintos).
@type Static Function
@param oReq JsonObject, {cNumCont, cRevisao, cCompet, cCliente, cLojaCli, cFornec, cLjForn,
       itens: [{planilha, item, produto, descricao, cc, tes, quantidade, valorUnitario}]}
@return JsonObject, {success, resultados: [{planilha, success, numMedicao, message}]}
/*/
//=============================================================================================================================
Static Function GerarMed(oReq)

    Local oResp       := JsonObject():New()
    Local aItens      := {}
    Local aPlanilhas  := {}
    Local aResultados := {}
    Local oResPlan    := Nil
    Local cNumCont    := ""
    Local cRevisao    := ""
    Local cCompet     := ""
    Local cCliente    := ""
    Local cLojaCli    := ""
    Local cFornec     := ""
    Local cLjForn     := ""
    Local aItensPlan  := {}
    Local cPlan       := ""
    Local nI          := 0
    Local nP          := 0

    If ValType(oReq["cNumCont"]) == "C" ; cNumCont := AllTrim(oReq["cNumCont"]) ; EndIf
    If ValType(oReq["cRevisao"]) == "C" ; cRevisao := AllTrim(oReq["cRevisao"]) ; EndIf
    If ValType(oReq["cCompet"])  == "C" ; cCompet  := AllTrim(oReq["cCompet"])  ; EndIf
    If ValType(oReq["cCliente"]) == "C" ; cCliente := AllTrim(oReq["cCliente"]) ; EndIf
    If ValType(oReq["cLojaCli"]) == "C" ; cLojaCli := AllTrim(oReq["cLojaCli"]) ; EndIf
    If ValType(oReq["cFornec"])  == "C" ; cFornec  := AllTrim(oReq["cFornec"])  ; EndIf
    If ValType(oReq["cLjForn"])  == "C" ; cLjForn  := AllTrim(oReq["cLjForn"])  ; EndIf
    If ValType(oReq["itens"])    == "A" ; aItens   := oReq["itens"]             ; EndIf

    If Empty(cNumCont) .Or. Empty(cCompet) .Or. Len(aItens) == 0
        oResp["success"] := .F.
        oResp["message"] := "Dados insuficientes para gerar a medicao"
        Return oResp
    EndIf

    // Planilhas distintas presentes, na ordem em que aparecem.
    For nI := 1 To Len(aItens)
        cPlan := AllTrim(aItens[nI]["planilha"])
        If AScan(aPlanilhas, cPlan) == 0
            AAdd(aPlanilhas, cPlan)
        EndIf
    Next nI

    For nP := 1 To Len(aPlanilhas)
        aItensPlan := {}
        For nI := 1 To Len(aItens)
            If AllTrim(aItens[nI]["planilha"]) == aPlanilhas[nP]
                AAdd(aItensPlan, aItens[nI])
            EndIf
        Next nI
        oResPlan := GerarPlan(cNumCont, cRevisao, cCompet, cCliente, cLojaCli, cFornec, cLjForn, aItensPlan, aPlanilhas[nP])
        AAdd(aResultados, oResPlan)
    Next nP

    oResp["success"]    := .T.
    oResp["resultados"] := aResultados

Return oResp

/*/{Protheus.doc} GerarPlan
Gera UMA medicao (MVC FWLoadModel CNTA121) para os itens de UMA planilha especifica --
mesma logica de RT69M002.prw::ProcessaPlanilha, adaptada para receber itens estruturados
(JsonObject vindo do Angular) em vez de colunas de CSV, e devolver o resultado em JSON em
vez de MsgStop/MsgInfo (dialogs nativos nao fazem sentido aqui -- esta tela roda embutida
via FwCallApp/PO-UI e quem exibe mensagem ao usuario e o Angular).
IMPORTANTE: diferente de RT69M002.prw::ProcessaPlanilha, o cliente/fornecedor NAO passa por
AchaCliente() aqui -- a tela ja resolveu codigo/loja certos via CabCtr (consulta direta na
CNA), entao chegam prontos em cCliente/cLojaCli ou cFornec/cLjForn.
@type Static Function
@param aItens Array de JsonObject, itens desta planilha (ja filtrados por GerarMed)
@param cNumPlanilha String, numero da planilha (CNB_NUMERO/CNA_NUMERO) sendo processada
@return JsonObject, {planilha, success, numMedicao, message}
/*/
//=============================================================================================================================
Static Function GerarPlan(cNumCont, cRevisao, cCompet, cCliente, cLojaCli, cFornec, cLjForn, aItens, cNumPlanilha)

    Local oResPlan    := JsonObject():New()
    Local oModel      := Nil
    Local oGridDet    := Nil
    Local oGridCXN    := Nil
    Local oItem       := Nil
    Local cItemPad    := ""
    Local cProdCsv    := ""
    Local cDescricao  := ""
    Local cTes        := ""
    Local cCC         := ""
    Local lAchouItem  := .F.
    Local lMarcouPlan := .F.
    Local cValCXN     := ""
    Local nLinCXN     := 0
    Local nLin        := 0
    Local nLinhasAntes:= 0
    Local aChavesImp  := {}
    Local cChaveLinha := ""
    Local aCompets    := {}
    Local nCompet     := 0
    Local cNumMed     := ""
    Local cMsg        := ""
    Local nTamItem    := TamSX3("CNE_ITEM")[1]
    Local nQuant      := 0
    Local nVlUnit     := 0
    Local nFalhasAntes:= 0
    Local aErros      := {}
    Local aFalhas     := {}
    Local nTamNum     := 0
    Local nTamRev     := 0
    Local lAchouCN9   := .F.
    Local nX          := 0
    Local nY          := 0
    Local cItemCsv    := ""

    oResPlan["planilha"] := cNumPlanilha

    // Posicionar na CN9 - obrigatorio para o CNTA121. Inclui a revisao na chave (senao o
    // dbSeek cai na 1a revisao, a mais antiga) e tolera a revisao sem zeros a esquerda.
    CN9->(dbSetOrder(1))
    nTamNum   := Max(TamSX3("CN9_NUMERO")[1], Len(cNumCont))
    nTamRev   := Max(TamSX3("CN9_REVISA")[1], Len(cRevisao))
    lAchouCN9 := CN9->(dbSeek(xFilial("CN9") + Padr(cNumCont, nTamNum) + Padr(cRevisao, nTamRev)))
    If !lAchouCN9
        lAchouCN9 := CN9->(dbSeek(xFilial("CN9") + Padr(cNumCont, nTamNum) + Padl(cRevisao, nTamRev, "0")))
    EndIf
    If !lAchouCN9
        oResPlan["success"] := .F.
        oResPlan["message"] := "Contrato [" + cNumCont + "] revisao [" + cRevisao + "] nao encontrado na filial."
        Return oResPlan
    EndIf

    // CND_RCCOMP espera o INDICE da competencia dentro de CtrCompets(), nao o texto.
    aCompets := CtrCompets()
    nCompet  := AScan(aCompets, {|x| Alltrim(x) == Alltrim(cCompet)})
    If nCompet == 0
        oResPlan["success"] := .F.
        oResPlan["message"] := "Competencia [" + cCompet + "] nao esta disponivel para este contrato."
        Return oResPlan
    EndIf

    oModel := FWLoadModel("CNTA121")
    oModel:SetOperation(MODEL_OPERATION_INSERT)

    If !oModel:CanActivate()
        oResPlan["success"] := .F.
        oResPlan["message"] := "Nao foi possivel ativar o modelo CNTA121."
        Return oResPlan
    EndIf
    oModel:Activate()

    // --- Cabecalho da medicao (CNDMASTER) ---
    oModel:SetValue("CNDMASTER", "CND_CONTRA", CN9->CN9_NUMERO)
    oModel:SetValue("CNDMASTER", "CND_REVISA", cRevisao)
    oModel:SetValue("CNDMASTER", "CND_RCCOMP", cValToChar(nCompet)) // Reconhece competencia - indice dentro de CtrCompets()

    If !Empty(cFornec)
        oModel:SetValue("CNDMASTER", "CND_FORNEC", cFornec)
        oModel:SetValue("CNDMASTER", "CND_LJFORN", cLjForn)
    EndIf
    If !Empty(cCliente)
        oModel:SetValue("CNDMASTER", "CND_CLIENT", cCliente)
        oModel:SetValue("CNDMASTER", "CND_LOJACL", cLojaCli)
    EndIf

    // Marcar a planilha antes dos itens - ver nota extensa em RT69M002.prw::ProcessaPlanilha
    // sobre por que isso e necessario (habilita o LoadValue() e evita gravar itens sob a
    // planilha errada quando o contrato tem mais de uma planilha em CXNDETAIL).
    oGridCXN := oModel:GetModel("CXNDETAIL")
    If !Empty(cNumPlanilha) .And. oGridCXN != Nil
        For nLinCXN := 1 To oGridCXN:Length()
            oGridCXN:GoLine(nLinCXN)
            cValCXN := ""
            Begin Sequence
                cValCXN := Alltrim(oGridCXN:GetValue("CXN_NUMPLA"))
            Recover
                cValCXN := ""
            End Sequence
            If cValCXN == cNumPlanilha
                oModel:SetValue("CXNDETAIL", "CXN_CHECK", .T.)
                lMarcouPlan := .T.
                Exit
            EndIf
        Next nLinCXN
    EndIf
    If !lMarcouPlan
        oModel:DeActivate()
        oResPlan["success"] := .F.
        oResPlan["message"] := "Planilha " + cNumPlanilha + " nao foi encontrada como pendente de medicao para a competencia " + cCompet + ;
            " (grid CXNDETAIL do CNTA121). Possiveis causas: esta planilha ja foi medida nesta competencia, ou o cliente/fornecedor " + ;
            "informado nao corresponde ao cadastrado na CNA desta planilha."
        Return oResPlan
    EndIf

    // --- Itens da medicao (CNEDETAIL) ---
    oGridDet := oModel:GetModel("CNEDETAIL")

    For nX := 1 To Len(aItens)
        oItem   := aItens[nX]
        nQuant  := 0
        nVlUnit := 0
        nFalhasAntes := Len(aFalhas)

        cItemCsv := ""
        cProdCsv := ""
        cDescricao := ""
        cTes := ""
        cCC  := ""
        If ValType(oItem["item"])      == "C" ; cItemCsv   := AllTrim(oItem["item"])      ; EndIf
        If ValType(oItem["produto"])   == "C" ; cProdCsv   := AllTrim(oItem["produto"])   ; EndIf
        If ValType(oItem["descricao"]) == "C" ; cDescricao := AllTrim(oItem["descricao"]) ; EndIf
        If ValType(oItem["tes"])       == "C" ; cTes       := AllTrim(oItem["tes"])       ; EndIf
        If ValType(oItem["cc"])        == "C" ; cCC        := AllTrim(oItem["cc"])        ; EndIf

        // CNE_ITEM e obrigatorio - usa o valor recebido (zero-preenchido a esquerda) ou gera
        // um sequencial quando nao vier. Ver nota extensa em RT69M002.prw::ProcessaPlanilha
        // sobre por que so reaproveita a linha auto-populada pelo CXN_CHECK quando item E
        // produto batem (varios produtos podem compartilhar o mesmo CNE_ITEM).
        If Empty(cItemCsv) ; cItemCsv := cValToChar(nX) ; EndIf
        cItemPad := Padl(cItemCsv, nTamItem, "0")

        // Registra a chave item+produto deste item importado -- usada na limpeza apos o laco
        // (ver comentario logo antes do "Validar e gravar via MVC" abaixo) para apagar qualquer
        // linha que o CXN_CHECK tenha auto-populado para OUTROS itens da planilha que nao foram
        // importados pelo usuario. Sem isso a medicao poderia medir itens/quantidades que nunca
        // vieram do arquivo.
        AAdd(aChavesImp, cItemPad + "|" + cProdCsv)

        // BUG CONFIRMADO AO VIVO 2026-08-14: com 2 itens novos (nenhuma linha pre-existente
        // batendo com nenhum dos dois), so o ULTIMO sobrevivia na medicao gravada -- o
        // LoadValue() do 2o item sobrescrevia a linha do 1o em vez de criar uma nova. Raciocinio:
        // LoadValue() so dispara o comportamento "adicionar linha" (documentado em
        // RT69M002.prw::ProcessaPlanilha como o que substitui o AddLine(), habilitado pelo
        // CXN_CHECK) quando o cursor do grid ainda nao foi deslocado por um GoLine() para uma
        // linha JA existente -- e e exatamente isso que o laco de busca acima faz a partir do
        // 2o item em diante (posiciona em oGridDet:Length(), uma linha real, antes de constatar
        // que nao bateu). Corrigido forcando uma linha nova via AddLine() sempre que a planilha
        // ja tinha ao menos 1 linha ANTES de comecar a processar este item (nLinhasAntes > 0) --
        // preserva o comportamento original (sem AddLine) so para o 1o item de uma planilha
        // vazia, que e o cenario ja confirmado funcionando na ferramenta nativa.
        nLinhasAntes := oGridDet:Length()

        lAchouItem := .F.
        For nLin := 1 To oGridDet:Length()
            oGridDet:GoLine(nLin)
            If Alltrim(oGridDet:GetValue("CNE_ITEM")) == Alltrim(cItemPad) .And. ;
               (Empty(cProdCsv) .Or. Alltrim(oGridDet:GetValue("CNE_PRODUT")) == cProdCsv)
                lAchouItem := .T.
                Exit
            EndIf
        Next nLin
        If !lAchouItem
            If nLinhasAntes > 0
                oGridDet:AddLine()
            EndIf
            oGridDet:LoadValue("CNE_ITEM", cItemPad)
        EndIf

        If !Empty(cProdCsv)   ; TrySet(oModel, aFalhas, "CNEDETAIL", "CNE_PRODUT", Padr(cProdCsv, Max(TamSX3("CNE_PRODUT")[1], Len(cProdCsv)))) ; EndIf
        If !Empty(cDescricao) ; TrySet(oModel, aFalhas, "CNEDETAIL", "CNE_DESCRI", cDescricao) ; EndIf
        If !Empty(cTes)       ; TrySet(oModel, aFalhas, "CNEDETAIL", "CNE_TES",    cTes)       ; EndIf
        If !Empty(cCC)        ; TrySet(oModel, aFalhas, "CNEDETAIL", "CNE_CC",     cCC)        ; EndIf

        nQuant  := ParseNum(oItem["quantidade"])
        nVlUnit := ParseNum(oItem["valorUnitario"])
        TrySet(oModel, aFalhas, "CNEDETAIL", "CNE_QUANT",  nQuant)
        TrySet(oModel, aFalhas, "CNEDETAIL", "CNE_VLUNIT", nVlUnit)
        TrySet(oModel, aFalhas, "CNEDETAIL", "CNE_VLTOT",  TruncaDec(nQuant * nVlUnit, "CNE_VLTOT"))
        TrySet(oModel, aFalhas, "CNEDETAIL", "CNE_REVISA", cRevisao)

        If Len(aFalhas) > nFalhasAntes
            cMsg := "Falha ao preencher a linha " + cValToChar(nX) + " da planilha " + cNumPlanilha + ":" + Chr(10)
            For nY := nFalhasAntes + 1 To Len(aFalhas)
                cMsg += aFalhas[nY] + Chr(10)
            Next nY
            oModel:DeActivate()
            oResPlan["success"] := .F.
            oResPlan["message"] := cMsg
            Return oResPlan
        EndIf
    Next nX

    // So medir o que foi importado: qualquer linha de CNEDETAIL cuja chave item+produto NAO
    // esteja em aChavesImp (ou seja, uma linha que o CXN_CHECK auto-populou para outro item
    // pendente da planilha, nao selecionado pelo usuario no arquivo) e removida antes de
    // gravar. Percorre de tras para frente porque DelLine() desloca os indices das linhas
    // seguintes.
    For nLin := oGridDet:Length() To 1 Step -1
        oGridDet:GoLine(nLin)
        cChaveLinha := Alltrim(oGridDet:GetValue("CNE_ITEM")) + "|" + Alltrim(oGridDet:GetValue("CNE_PRODUT"))
        If AScan(aChavesImp, cChaveLinha) == 0
            // THREAD ERROR confirmado ao vivo 2026-08-14: "Cannot find method
            // FWFORMGRIDMODEL:DELLINE" -- essa classe nao expoe DelLine() (abreviado). O nome
            // completo DeleteLine() segue a mesma convencao ja usada e confirmada neste
            // ambiente em SetNoDeleteLine()/SetNoInsertLine()/SetNoUpdateLine() (ver
            // "Controle de Contratos/SCT003.PRW" linha ~94).
            oGridDet:DeleteLine()
        EndIf
    Next nLin

    // Validar e gravar via MVC
    If oModel:VldData()
        oModel:CommitData()
    EndIf

    If oModel:HasErrorMessage()
        aErros := oModel:GetErrorMessage()
        cMsg := ""
        For nY := 1 To Len(aErros)
            If ValType(aErros[nY]) == "A"
                cMsg += cValToChar(aErros[nY][1]) + Chr(10)
            Else
                cMsg += cValToChar(aErros[nY]) + Chr(10)
            EndIf
        Next nY
        oModel:DeActivate()
        oResPlan["success"] := .F.
        oResPlan["message"] := cMsg
    Else
        // Ler numero gerado antes do DeActivate
        cNumMed := Alltrim(CND->CND_NUMMED)
        oModel:DeActivate()
        oResPlan["success"]    := .T.
        oResPlan["numMedicao"] := cNumMed
    EndIf

Return oResPlan
