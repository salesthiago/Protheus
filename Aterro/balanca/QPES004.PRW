#INCLUDE "TOTVS.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "OGA190.ch"
#include "fwmvcdef.ch"

#DEFINE QPES_PORTASERIAL 'S'
#DEFINE QPES_PORTATCPIP  'T'
#DEFINE QPES_BUFFER_LEITURA 32
#DEFINE QPES_TRIES_TO_CONNECT 3
#DEFINE QPES_TRIES_TO_READ    3
#DEFINE QPES_NUM_CONECT       2

/*/{Protheus.doc} QPES004
Abre a tela hibrida (Angular/PO-UI) de Pesagens (tabela NJH), empacotada em
resource/qpes001.app e carregada via FWCallApp. Listagem com filtros (Centro de
Custo, periodo, status, placa, motorista, produto, ticket) e inclusao manual de
pesagem, com os mesmos campos exibidos no ticket impresso (ver QPES001.PRW).

Nao substitui a OGA190Q (pesagem com captura via balanca fisica) nem as acoes de
Cancelar/Finalizar/Alterar -- essas continuam so pela rotina nativa.
@type User Function
@author Thiago Sales - Quebec Ambiental
@since 2026-09-11
/*/
//=============================================================================================================================
USER FUNCTION QPES004()

    FWCallApp("qpes001")

RETURN

/*/{Protheus.doc} JsToAdvpl
Recebe mensagens da tela Angular (qpes001) pelo canal AdvplToJs/JsToAdvpl
(TWebChannel), mesmo padrao adotado em Estoque/Armazem/src/EstMinMax.prw.

O receiveId nao viaja automatico entre o cliente e o ADVPL -- o lado Angular
(AdvplBridgeService) embute o receiveId dentro do JSON de cContent, e aqui
extraimos e devolvemos a resposta chamando AdvplToJs(cReceiveId, ...).
@type Static Function
/*/
//=============================================================================================================================
Static Function JsToAdvpl(oWebChannel, cType, cContent)

    Local oReq       := JsonObject():New()
    Local oResp      := JsonObject():New()
    Local cReceiveId := ""

    oReq:fromJson(cContent)
    cReceiveId := oReq["receiveId"]

    Do Case
    Case cType == "pesListar"
        oResp := PesList(oReq)
    Case cType == "pesDetalhe"
        oResp := PesDetal(oReq)
    Case cType == "pesCriar"
        oResp := PesCria(oReq)
    Case cType == "pesPesar"
        oResp := PesPesar(oReq)
    Case cType == "pesListarBal"
        oResp := PesLstBl(oReq)
    Case cType == "pesLookupProduto"
        oResp := PesLkpPr(oReq)
    Case cType == "pesLookupPlaca"
        oResp := PesLkpPl(oReq)
    Case cType == "pesPlacaDetalhe"
        oResp := PesPlDet(oReq)
    Case cType == "pesImprimir"
        oResp := PesImpTk(oReq)
    Case cType == "pesRelatorio"
        oResp := PesRelat(oReq)
    OtherWise
        oResp["success"] := .F.
        oResp["message"] := "Operacao nao reconhecida: " + cType
    EndCase

    If !Empty(cReceiveId)
        oWebChannel:AdvplToJs(cReceiveId, oResp:toJson())
    EndIf

Return .T.

/*/{Protheus.doc} PesList
Lista pesagens (NJH) conforme os filtros opcionais recebidos: ticket (LIKE),
cc (NJH_XCLVL exato), status (NJH_STATUS exato), placa/motorista/produto (LIKE)
e periodo (dataDe/dataAte sobre NJH_DATA, formato 'AAAA-MM-DD').

Nao filtra por NJH_FILIAL -- mesma decisao de Aterro/balanca/QPES003.PRW, que
tambem omite esse filtro de proposito para consolidar pesagens de todas as
unidades/filiais numa unica consulta, usando o Centro de Custo (NJH_XCLVL) como
o filtro de unidade. Cada item devolve 'filial' porque a numeracao do ticket
(NJH_CODPAV) e por filial, nao e globalmente unica -- necessario para
PesDetal/PesImpTk conseguirem reabrir o registro certo depois.
@type Static Function
/*/
//=============================================================================================================================
Static Function PesList(oReq)

    Local oResp    := JsonObject():New()
    Local aItens   := {}
    Local oItem    := Nil
    Local cAliasQ  := GetNextAlias()
    Local cQuery   := ""
    Local cTicketF := ""
    Local cCCF     := ""
    Local cStatusF := ""
    Local cPlacaF  := ""
    Local cMotorF  := ""
    Local cProdF   := ""
    Local dDatDe   := CTOD("")
    Local dDatAte  := CTOD("")

    If ValType(oReq["ticket"])    == "C" ; cTicketF := AllTrim(oReq["ticket"])    ; EndIf
    If ValType(oReq["cc"])        == "C" ; cCCF     := AllTrim(oReq["cc"])        ; EndIf
    If ValType(oReq["status"])    == "C" ; cStatusF := AllTrim(oReq["status"])    ; EndIf
    If ValType(oReq["placa"])     == "C" ; cPlacaF  := AllTrim(oReq["placa"])     ; EndIf
    If ValType(oReq["motorista"]) == "C" ; cMotorF  := AllTrim(oReq["motorista"]) ; EndIf
    If ValType(oReq["produto"])   == "C" ; cProdF   := AllTrim(oReq["produto"])   ; EndIf
    If ValType(oReq["dataDe"])  == "C" .And. Len(AllTrim(oReq["dataDe"]))  == 10 ; dDatDe  := SToD(StrTran(oReq["dataDe"] , "-", "")) ; EndIf
    If ValType(oReq["dataAte"]) == "C" .And. Len(AllTrim(oReq["dataAte"])) == 10 ; dDatAte := SToD(StrTran(oReq["dataAte"], "-", "")) ; EndIf

    // Escapa aspas simples antes de concatenar na string SQL (montagem manual, sem BeginSql).
    cTicketF := StrTran(cTicketF, "'", "''")
    cCCF     := StrTran(cCCF,     "'", "''")
    cStatusF := StrTran(cStatusF, "'", "''")
    cPlacaF  := StrTran(Upper(cPlacaF),  "'", "''")
    cMotorF  := StrTran(Upper(cMotorF),  "'", "''")
    cProdF   := StrTran(Upper(cProdF),   "'", "''")

    cQuery := " SELECT NJH.NJH_FILIAL, NJH.NJH_CODPAV, NJH.NJH_XCLVL, NJH.NJH_DATA, NJH.NJH_PLACA, "
    cQuery += " NJH.NJH_NOMMOT, NJH.NJH_DESPRO, NJH.NJH_PESO1, NJH.NJH_PESO2, NJH.NJH_PSSUBT, NJH.NJH_STATUS "
    cQuery += " FROM " + RetSqlName("NJH") + " NJH "
    cQuery += " WHERE NJH.D_E_L_E_T_ = ' ' "
    If !Empty(cTicketF)
        cQuery += " AND NJH.NJH_CODPAV LIKE '%" + cTicketF + "%' "
    EndIf
    If !Empty(cCCF)
        cQuery += " AND NJH.NJH_XCLVL = '" + cCCF + "' "
    EndIf
    If !Empty(cStatusF)
        cQuery += " AND NJH.NJH_STATUS = '" + cStatusF + "' "
    EndIf
    If !Empty(cPlacaF)
        cQuery += " AND UPPER(NJH.NJH_PLACA) LIKE '%" + cPlacaF + "%' "
    EndIf
    If !Empty(cMotorF)
        cQuery += " AND UPPER(NJH.NJH_NOMMOT) LIKE '%" + cMotorF + "%' "
    EndIf
    If !Empty(cProdF)
        cQuery += " AND (UPPER(NJH.NJH_DESPRO) LIKE '%" + cProdF + "%' OR UPPER(NJH.NJH_CODPRO) LIKE '%" + cProdF + "%') "
    EndIf
    If !Empty(dDatDe)
        cQuery += " AND NJH.NJH_DATA >= '" + DToS(dDatDe) + "' "
    EndIf
    If !Empty(dDatAte)
        cQuery += " AND NJH.NJH_DATA <= '" + DToS(dDatAte) + "' "
    EndIf
    cQuery += " ORDER BY NJH.NJH_DATA DESC, NJH.NJH_CODPAV DESC "
    cQuery := ChangeQuery(cQuery)

    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAliasQ, .F., .T.)
    (cAliasQ)->(DbGoTop())

    While (cAliasQ)->(!Eof())
        oItem := JsonObject():New()
        oItem["filial"]    := AllTrim((cAliasQ)->NJH_FILIAL)
        oItem["ticket"]    := AllTrim((cAliasQ)->NJH_CODPAV)
        oItem["cc"]        := AllTrim((cAliasQ)->NJH_XCLVL)
        oItem["data"]      := XFmtDat((cAliasQ)->NJH_DATA)
        oItem["placa"]     := AllTrim((cAliasQ)->NJH_PLACA)
        oItem["motorista"] := AllTrim((cAliasQ)->NJH_NOMMOT)
        oItem["produto"]   := AllTrim((cAliasQ)->NJH_DESPRO)
        oItem["peso1"]     := (cAliasQ)->NJH_PESO1
        oItem["peso2"]     := (cAliasQ)->NJH_PESO2
        oItem["pesoLiq"]   := (cAliasQ)->NJH_PSSUBT
        oItem["status"]    := AllTrim((cAliasQ)->NJH_STATUS)
        aAdd(aItens, oItem)
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

    oResp["success"] := .T.
    oResp["items"]   := aItens

Return oResp

/*/{Protheus.doc} XFmtDat
Formata uma data vinda de um alias de SQL cru (TcGenQry/ChangeQuery, sem passar por
BeginSql/EndSql) para 'DD/MM/AAAA'. Diferente de um DbSeek na propria tabela NJH (onde
o campo chega tipado como Date, ver PesDetal/PesImpTk), um SELECT manual devolve o
campo fisico como ele esta no banco -- e NJH_DATA e fisicamente CHAR(8) 'AAAAMMDD'
(mesma premissa ja usada em QPES003.PRW::xMontaQry3, que compara NJH_DATA com string).
Chamar DtoC() direto nesse valor da erro 'argument #0 error, expected D->C' porque
ValType() vem 'C', nao 'D'. Aceita os dois casos por seguranca (driver/ambiente podem
variar).
@type Static Function
@param uDat Date ou Character, valor bruto vindo do alias de SQL
@return cRet Character, data formatada 'DD/MM/AAAA' (ou vazio se uDat for invalido)
/*/
//=============================================================================================================================
Static Function XFmtDat(uDat)

    Local cRet := ""

    If ValType(uDat) == "D"
        cRet := DtoC(uDat)
    ElseIf ValType(uDat) == "C" .And. Len(AllTrim(uDat)) == 8
        cRet := Substr(uDat, 7, 2) + "/" + Substr(uDat, 5, 2) + "/" + Substr(uDat, 1, 4)
    EndIf

Return cRet

/*/{Protheus.doc} PesDetal
Obtem uma pesagem especifica pela chave filial+ticket (NJH_CODPAV nao e
globalmente unico, ver nota em PesList). Usada tanto pela tela de Visualizar
quanto pelo botao Imprimir Ticket antes de posicionar o NJH.
@type Static Function
/*/
//=============================================================================================================================
Static Function PesDetal(oReq)

    Local oResp    := JsonObject():New()
    Local cFilialP := ""
    Local cTicketP := ""

    If ValType(oReq["filial"]) == "C" ; cFilialP := AllTrim(oReq["filial"]) ; EndIf
    If ValType(oReq["ticket"]) == "C" ; cTicketP := AllTrim(oReq["ticket"]) ; EndIf

    If Empty(cFilialP) .Or. Empty(cTicketP)
        oResp["success"] := .F.
        oResp["message"] := "Parametros 'filial' e 'ticket' sao obrigatorios"
        Return oResp
    EndIf

    DbSelectArea("NJH")
    DbSetOrder(1)
    If DbSeek(cFilialP + cTicketP)
        oResp["success"]    := .T.
        oResp["filial"]     := AllTrim(NJH->NJH_FILIAL)
        oResp["ticket"]     := AllTrim(NJH->NJH_CODPAV)
        oResp["cc"]         := AllTrim(NJH->NJH_XCLVL)
        oResp["data"]       := DtoC(NJH->NJH_DATA)
        oResp["placa"]      := AllTrim(NJH->NJH_PLACA)
        oResp["motorista"]  := AllTrim(NJH->NJH_NOMMOT)
        oResp["codPro"]     := AllTrim(NJH->NJH_CODPRO)
        oResp["desPro"]     := AllTrim(NJH->NJH_DESPRO)
        oResp["rota"]       := AllTrim(NJH->NJH_XROTA)
        oResp["cliente"]    := AllTrim(NJH->NJH_XCLIEN)
        oResp["fornecedor"] := AllTrim(NJH->NJH_NOMENT)
        oResp["peso1"]      := NJH->NJH_PESO1
        oResp["dataEnt"]    := DtoC(NJH->NJH_DATPS1)
        oResp["horaEnt"]    := AllTrim(NJH->NJH_HORPS1)
        oResp["peso2"]      := NJH->NJH_PESO2
        oResp["dataSai"]    := DtoC(NJH->NJH_DATPS2)
        oResp["horaSai"]    := AllTrim(NJH->NJH_HORPS2)
        oResp["pesoLiq"]    := NJH->NJH_PSSUBT
        oResp["obs"]        := AllTrim(NJH->NJH_OBS)
        oResp["status"]     := AllTrim(NJH->NJH_STATUS)
        oResp["operador"]   := AllTrim(NJH->NJH_XUSER)
    Else
        oResp["success"] := .F.
        oResp["message"] := "Pesagem nao encontrada"
    EndIf

Return oResp

/*/{Protheus.doc} PesNovo
Cria o registro de cabecalho de uma nova pesagem na NJH (placa/motorista/produto/
rota/cliente/fornecedor/obs, sem pesos, status '0'). Usada tanto por PesCria (botao
Salvar, so cabecalho) quanto por PesPesar (pesar sem ter salvo antes -- cria e pesa
numa acao so, a pedido do usuario).

NAO da MsUnLock -- deixa o registro RecLock'ado e NJH posicionado nele, porque
PesPesar ainda precisa gravar o peso capturado antes de liberar. Quem chamar decide
quando soltar o lock (PesCria solta na hora; PesPesar so depois de setar o peso).

Centro de Custo (NJH_XCLVL) fica em branco de proposito -- decisao do usuario:
nao e mais obrigatorio nesta tela, e preenchido em outro momento/processo.
@type Static Function
@param oReq JsonObject, payload recebido do Angular
@param oResp JsonObject, response sendo montada pelo chamador (preenchida com
       success/message em caso de erro de validacao)
@return lOk Logico, .F. se faltou campo obrigatorio (nada foi gravado nesse caso)
/*/
//=============================================================================================================================
Static Function PesNovo(oReq, oResp)

    Local cPlaca   := ""
    Local cMotor   := ""
    Local cCodPro  := ""
    Local cDesPro  := ""
    Local cUmPro   := ""
    Local cRota    := ""
    Local cCodEnt  := ""
    Local cLojEnt  := ""
    Local cClien   := ""
    Local cForn    := ""
    Local cObs     := ""
    Local cTicket  := ""

    If ValType(oReq["placa"])      == "C" ; cPlaca  := AllTrim(oReq["placa"])      ; EndIf
    If ValType(oReq["motorista"])  == "C" ; cMotor  := AllTrim(oReq["motorista"])  ; EndIf
    If ValType(oReq["codPro"])     == "C" ; cCodPro := AllTrim(oReq["codPro"])     ; EndIf
    If ValType(oReq["desPro"])     == "C" ; cDesPro := AllTrim(oReq["desPro"])     ; EndIf
    If ValType(oReq["umPro"])      == "C" ; cUmPro  := AllTrim(oReq["umPro"])      ; EndIf
    If ValType(oReq["rota"])       == "C" ; cRota   := AllTrim(oReq["rota"])       ; EndIf
    If ValType(oReq["codEnt"])     == "C" ; cCodEnt := AllTrim(oReq["codEnt"])     ; EndIf
    If ValType(oReq["lojEnt"])     == "C" ; cLojEnt := AllTrim(oReq["lojEnt"])     ; EndIf
    If ValType(oReq["cliente"])    == "C" ; cClien  := AllTrim(oReq["cliente"])    ; EndIf
    If ValType(oReq["fornecedor"]) == "C" ; cForn   := AllTrim(oReq["fornecedor"]) ; EndIf
    If ValType(oReq["obs"])        == "C" ; cObs    := AllTrim(oReq["obs"])        ; EndIf

    If Empty(cPlaca) .Or. Empty(cMotor) .Or. Empty(cCodPro)
        oResp["success"] := .F.
        oResp["message"] := "Preencha Placa, Motorista e Produto."
        Return .F.
    EndIf

    cTicket := U_FNEXTID("NJH", "NJH_CODPAV", "NJH_FILIAL")

    DbSelectArea("NJH")
    RecLock("NJH", .T.)
    NJH->NJH_FILIAL := xFilial("NJH")
    NJH->NJH_CODPAV := cTicket
    NJH->NJH_DATA   := Date()
    NJH->NJH_PLACA  := cPlaca
    NJH->NJH_NOMMOT := cMotor
    NJH->NJH_CODPRO := cCodPro
    NJH->NJH_DESPRO := cDesPro
    NJH->NJH_UM1PRO := cUmPro
    NJH->NJH_XROTA  := cRota
    NJH->NJH_CODENT := cCodEnt
    NJH->NJH_LOJENT := "01"
    NJH->NJH_XCLIEN := cClien
    NJH->NJH_NOMENT := cForn
    NJH->NJH_NLJENT := cLojEnt
    NJH->NJH_OBS    := cObs
    NJH->NJH_PESO1  := 0
    NJH->NJH_PESO2  := 0
    NJH->NJH_PSSUBT := 0
    NJH->NJH_STATUS := "0"
    NJH->NJH_XUSER  := RetCodUsr()

Return .T.

/*/{Protheus.doc} PesCria
Salva so o cabecalho de uma pesagem (sem pesar ainda) -- usa PesNovo e ja solta
o lock. Fluxo alternativo ao "pesar direto" do PesPesar, para quando o operador
quer confirmar/corrigir os dados antes de ir para a balanca.
@type Static Function
/*/
//=============================================================================================================================
Static Function PesCria(oReq)

    Local oResp := JsonObject():New()

    If !PesNovo(oReq, oResp)
        Return oResp
    EndIf

    NJH->(MsUnLock())

    oResp["success"] := .T.
    oResp["message"] := "Pesagem salva. Ticket " + AllTrim(NJH->NJH_CODPAV)
    oResp["ticket"]  := AllTrim(NJH->NJH_CODPAV)
    oResp["filial"]  := AllTrim(NJH->NJH_FILIAL)

Return oResp

/*/{Protheus.doc} PesPesar
Captura o peso de Entrada ('tipo'='1') ou Saida ('tipo'='2') direto da balanca
fisica, lendo a mesma configuracao (DX5) que o OGA190Q usa, mas com a leitura de
socket/serial reimplementada direto em PesLeituraDX5 (sem TDialog/TTimer -- ver
motivo no cabecalho de PesCapt) e SEM a checagem de usuario x balanca (DX6) que
a AGRX003AQ tem -- decisao do usuario para esta tela nova.

Se 'ticket' vier vazio, cria a pesagem agora (PesNovo, com os dados de cabecalho
que vieram junto no payload) e ja pesa em seguida -- "ao clicar em pesar, ja
salva automaticamente o registro com o peso" (pedido do usuario, elimina o passo
de Salvar antes de pesar).

Se a balanca nao for detectada/nao estiver em modo automatico, PesCapt devolve 0
e aqui devolvemos success:.F. + balancaIndisponivel:.T. SEM gravar peso nenhum
(o registro de cabecalho, se foi criado agora, fica salvo mesmo assim) -- o front
deve entao liberar um campo numerico pra digitar o peso manualmente e reenviar
esta mesma operacao com 'pesoManual' preenchido.
@type Static Function
/*/
//=============================================================================================================================
Static Function PesPesar(oReq)

    Local oResp     := JsonObject():New()
    Local cFilialP  := ""
    Local cTicketP  := ""
    Local cTipo     := ""
    Local nPesoManu := 0
    Local lNovo     := .F.
    Local aParBal   := Nil
    Local nPeso     := 0
    Local cModo     := "A"
    Local nPeso1Atu := 0
    Local nPeso2Atu := 0
    Local cStatus   := "0"
    Local cBalSel   := ""

    If ValType(oReq["filial"])     == "C" ; cFilialP  := AllTrim(oReq["filial"]) ; EndIf
    If ValType(oReq["ticket"])     == "C" ; cTicketP  := AllTrim(oReq["ticket"]) ; EndIf
    If ValType(oReq["tipo"])       == "C" ; cTipo     := AllTrim(oReq["tipo"])   ; EndIf
    If ValType(oReq["pesoManual"]) == "N" ; nPesoManu := oReq["pesoManual"]      ; EndIf
    If ValType(oReq["balanca"])    == "C" ; cBalSel   := AllTrim(oReq["balanca"]); EndIf

    If cTipo <> "1" .And. cTipo <> "2"
        oResp["success"] := .F.
        oResp["message"] := "Parametro 'tipo' invalido (use '1' para Entrada ou '2' para Saida)"
        Return oResp
    EndIf

    lNovo := Empty(cTicketP) .Or. Empty(cFilialP)

    If lNovo
        If !PesNovo(oReq, oResp)
            Return oResp
        EndIf
    Else
        DbSelectArea("NJH")
        DbSetOrder(1)
        If !DbSeek(cFilialP + cTicketP)
            oResp["success"] := .F.
            oResp["message"] := "Pesagem nao encontrada"
            Return oResp
        EndIf
        If NJH->NJH_STATUS $ "3,4"
            oResp["success"] := .F.
            oResp["message"] := "Esta pesagem nao pode ser alterada (finalizada ou cancelada)."
            Return oResp
        EndIf
        RecLock("NJH", .F.)
    EndIf

    nPeso1Atu := NJH->NJH_PESO1
    nPeso2Atu := NJH->NJH_PESO2

    If nPesoManu > 0
        nPeso := nPesoManu
        cModo := "M"
    Else
        If !Empty(cBalSel)
            // Balanca escolhida pelo usuario na tela (equivalente web do F12 da
            // OGA190Q nativa, ver PesLstBl) -- monta o array no mesmo formato que
            // AGRX003E devolveria ([1]=codigo,[2]=permite automatica,[3]=permite
            // manual), sem passar pela resolucao/tela nativa.
            aParBal := { cBalSel, .T., .T. }
        Else
            aParBal := AGRX003E(.F., "OGA050001")
        EndIf
        nPeso   := PesCapt(aParBal)
        If nPeso <= 0
            NJH->(MsUnLock())
            oResp["success"]             := .F.
            oResp["balancaIndisponivel"] := .T.
            oResp["message"]             := "Balanca nao detectada. Informe o peso manualmente."
            oResp["ticket"]              := AllTrim(NJH->NJH_CODPAV)
            oResp["filial"]              := AllTrim(NJH->NJH_FILIAL)
            Return oResp
        EndIf
        cModo := "A"
    EndIf

    If cTipo == "1"
        NJH->NJH_PESO1  := nPeso
        NJH->NJH_DATPS1 := Date()
        NJH->NJH_HORPS1 := Substr(Time(), 1, 5)
        NJH->NJH_MODPS1 := cModo
        nPeso1Atu := nPeso
    Else
        NJH->NJH_PESO2  := nPeso
        NJH->NJH_DATPS2 := Date()
        NJH->NJH_HORPS2 := Substr(Time(), 1, 5)
        NJH->NJH_MODPS2 := cModo
        nPeso2Atu := nPeso
    EndIf

    NJH->NJH_PSSUBT := Abs(nPeso1Atu - nPeso2Atu)
    If nPeso1Atu > 0 ; cStatus := "1" ; EndIf
    If nPeso2Atu > 0 ; cStatus := "2" ; EndIf
    NJH->NJH_STATUS := cStatus

    NJH->(MsUnLock())

    oResp["success"] := .T.
    oResp["ticket"]  := AllTrim(NJH->NJH_CODPAV)
    oResp["filial"]  := AllTrim(NJH->NJH_FILIAL)
    oResp["peso"]    := nPeso
    oResp["pesoLiq"] := NJH->NJH_PSSUBT
    oResp["status"]  := cStatus
    oResp["modo"]    := cModo

Return oResp

/*/{Protheus.doc} PesCapt
Le o peso estabilizado da balanca configurada no parametro 'OGA050001' (mesmo
parametro que a OGA190Q usa). Devolve 0 se a balanca nao estiver configurada ou
nao estiver em modo automatico -- sinal para o chamador (PesPesar) tratar como
"balanca indisponivel" e liberar digitacao manual.

NAO usa U_AGRX03BQ()/AGRX03AQ (as funcoes da OGA190Q.PRW): aquelas abrem
TDialog/TTimer, feitas para o SmartClient classico, e nao funcionam dentro do
contexto hibrido FWCallApp/TWebChannel desta tela -- o dialogo nunca chega a
renderizar e a captura sempre retornava peso 0 ("balanca nao detectada"), mesmo
com a balanca corretamente configurada (o teste do cadastro DX5 funciona porque
roda no SmartClient puro). Por isso a leitura de socket/serial e reimplementada
direto em PesLeituraDX5(), sem interface grafica.

Diferente de AGRX003AQ (que esta funcao substitui aqui), NAO faz a checagem de
usuario x balanca (tabela DX6) -- decisao do usuario para esta tela nova.
@type Static Function
@param aBal Array, retorno de AGRX003E(.F.,'OGA050001') -- [1]=codigo da balanca,
       [2]=permite pesagem automatica, [3]=permite pesagem manual
@return nPeso Numerico, peso capturado (0 se indisponivel)
/*/
//=============================================================================================================================
Static Function PesCapt(aBal)

    Local cBalanca := ""
    Local lPsAuto  := .F.
    Local nPeso    := 0

    If ValType(aBal) == "A" .And. Len(aBal) > 0
        cBalanca := aBal[1]
        lPsAuto  := aBal[2]
    EndIf

    If Empty(cBalanca) .Or. !lPsAuto
        Return 0
    EndIf

    DbSelectArea("DX5")
    DbSetOrder(1)
    If DX5->(MsSeek(xFilial("DX5") + cBalanca))
        nPeso := PesLeituraDX5()
    EndIf
    DX5->(DbCloseArea())

Return nPeso

/*/{Protheus.doc} PesLeituraDX5
Leitura direta (sem TDialog/TTimer) do peso na balanca posicionada na tabela
DX5. Reimplementa a mesma logica de AGRX03DQ (OGA190Q.PRW) para conexao
serial/TCP-IP e aplicacao do Script de conversao, mas sem qualquer interface
grafica -- ver motivo no cabecalho de PesCapt.
@type Static Function
@return nPeso Numerico, peso lido (0 se falhar a conexao/leitura)
/*/
//=============================================================================================================================
Static Function PesLeituraDX5()

    Local cTpRead    := DX5->DX5_TIPLEI
    Local cPorta     := AllTrim(DX5->DX5_TIPPOR)
    Local cTimeOut   := DX5->DX5_TIMOUT
    Local cSettings  := AllTrim(DX5->DX5_TIPVEL) + "," + AllTrim(DX5->DX5_TIPPAR) + "," + ;
                         AllTrim(DX5->DX5_NBITDA) + "," + AllTrim(DX5->DX5_NBITPA) + "," + AllTrim(cTimeOut)
    Local cScript    := DX5->DX5_SCRIPT
    Local cIpServer  := AllTrim(DX5->DX5_IPSERV)
    Local cPrtaIPSer := AllTrim(DX5->DX5_PORSER)
    Local nWait4Read := DX5->DX5_INTLEI
    Local cPortaMs   := cPorta + ":" + cSettings
    Local cConteudo  := ""
    Local nRetorno   := 0
    Local nHdlePorta := 0
    Local nHdll      := 0
    Local nBytes     := 0
    Local nCont      := 0
    Local cParte     := Space(1)
    Local oSocket    := Nil
    Local nSockResp  := 0
    Local nSockRead  := 0
    Local cBuffer    := ""
    Local nFor01     := 0
    Local nFor02     := 0
    Local nVezes     := 0

    Do Case
    Case cTpRead == QPES_PORTASERIAL

        nHdlePorta := fOpenPort(cPorta, cSettings, 2)

        If nHdlePorta == -1

            FClose(nHdlePorta)
            MsOpenPort(nHdll, cPortaMs)
            cConteudo := Space(100)
            While Empty(cConteudo) .And. nCont < 50
                MsRead(nHdll, @cConteudo)
                nCont++
            EndDo
            MsClosePort(nHdll)

            If Substr(cConteudo, 8, 8) <> Substr(cConteudo, Len(cConteudo) - 12, 8)
                cConteudo := ""
            ElseIf Val(Substr(cConteudo, 8, 8)) >= 90000 .Or. Val(Substr(cConteudo, 8, 8)) <= 500
                cConteudo := ""
            EndIf
        Else
            For nFor01 := 1 To QPES_TRIES_TO_READ
                cConteudo := ""
                For nFor02 := 1 To QPES_BUFFER_LEITURA
                    cParte := Space(1)
                    nBytes := FRead(nHdlePorta, @cParte, 1)
                    If Empty(nBytes)
                        Exit
                    EndIf
                    cConteudo += cParte
                Next nFor02
                If !Empty(cConteudo)
                    Exit
                EndIf
            Next nFor01
            FClose(nHdlePorta)
        EndIf

    Case cTpRead == QPES_PORTATCPIP

        For nVezes := 1 To QPES_NUM_CONECT
            cConteudo := ""
            oSocket := tSocketClient():New()
            oSocket:Reset()
            oSocket := tSocketClient():New()

            For nFor01 := 1 To QPES_TRIES_TO_CONNECT
                nSockResp := oSocket:Connect(Val(cPrtaIPSer), cIpServer, Val(cTimeOut))
                If oSocket:IsConnected() .And. nSockResp == 0
                    Exit
                EndIf
            Next nFor01

            If nSockResp == 0
                Sleep(nWait4Read)
                For nFor01 := 1 To QPES_TRIES_TO_READ
                    cBuffer   := ""
                    nSockRead := oSocket:Receive(@cBuffer, Val(cTimeOut))
                    If nSockRead > 0
                        cConteudo := cBuffer
                        Exit
                    Else
                        cConteudo := ""
                    EndIf
                Next nFor01

                If Substr(cConteudo, 5, 5) <> Substr(cConteudo, Len(cConteudo) - 6, 5)
                    cConteudo := ""
                ElseIf Val(Substr(cConteudo, 5, 5)) >= 90000 .Or. Val(Substr(cConteudo, 5, 5)) <= 500
                    cConteudo := ""
                EndIf
            EndIf
            oSocket:CloseConnection()

            If !Empty(cConteudo)
                Exit
            EndIf
        Next nVezes

    EndCase

    If !Empty(AllTrim(cScript))
        cScript   := "{||" + AllTrim(cScript) + "}"
        cConteudo := Eval(&(cScript))
        nRetorno  := Val(cConteudo)
    EndIf

Return nRetorno

/*/{Protheus.doc} PesLkpPr
Lookup de produtos (tabela SB1) para o campo Produto do formulario de inclusao.
Mesmo padrao de Estoque/Armazem/src/EstMinMax.prw::ZemLkpPr (limite de 20
registros, sem paginacao real). Devolve tambem a unidade de medida (B1_UM) para
preencher NJH_UM1PRO automaticamente.
@type Static Function
/*/
//=============================================================================================================================
Static Function PesLkpPr(oReq)

    Local oResp     := JsonObject():New()
    Local aItens    := {}
    Local oItem     := Nil
    Local cAliasQ   := GetNextAlias()
    Local cFiltroF  := ""
    Local cLike     := ""
    Local nCount    := 0

    If ValType(oReq["filtro"]) == "C"
        cFiltroF := AllTrim(oReq["filtro"])
    EndIf
    cLike := "%'%" + cFiltroF + "%'%"

    BeginSql Alias cAliasQ
        SELECT B1.B1_COD, B1.B1_DESC, B1.B1_UM
          FROM %table:SB1% B1
         WHERE B1.%notDel%
           AND B1.B1_FILIAL = %xfilial:SB1%
           AND (B1.B1_COD LIKE %exp:cLike% OR B1.B1_DESC LIKE %exp:cLike%)
         ORDER BY B1.B1_COD
    EndSql

    While (cAliasQ)->(!Eof()) .And. nCount < 20
        oItem := JsonObject():New()
        oItem["value"] := AllTrim((cAliasQ)->B1_COD)
        oItem["label"] := AllTrim((cAliasQ)->B1_DESC)
        oItem["um"]    := AllTrim((cAliasQ)->B1_UM)
        aAdd(aItens, oItem)
        nCount++
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

    oResp["success"] := .T.
    oResp["items"]   := aItens
    oResp["hasNext"] := .F.

Return oResp

/*/{Protheus.doc} PesLkpPl
Lookup de veiculos (tabela DA3) pelo campo Placa -- "consulta padrao" pedida pelo
usuario. So devolve value/label (placa + motorista) pra lista de sugestoes ficar
leve; os demais dados (produto/rota/cliente/fornecedor) sao buscados a parte, so
quando uma placa e efetivamente selecionada (ver PesPlDet), pra nao fazer varios
Posicione() extras por tecla digitada.
@type Static Function
/*/
//=============================================================================================================================
Static Function PesLkpPl(oReq)

    Local oResp     := JsonObject():New()
    Local aItens    := {}
    Local oItem     := Nil
    Local cAliasQ   := GetNextAlias()
    Local cFiltroF  := ""
    Local cLike     := ""
    Local nCount    := 0

    If ValType(oReq["filtro"]) == "C"
        cFiltroF := AllTrim(Upper(oReq["filtro"]))
    EndIf
    cLike := "%'%" + cFiltroF + "%'%"

    BeginSql Alias cAliasQ
        SELECT DA3.DA3_PLACA, DA3.DA3_XNOMMO
          FROM %table:DA3% DA3
         WHERE DA3.%notDel%
           AND DA3.DA3_FILIAL = %xfilial:DA3%
           AND UPPER(DA3.DA3_PLACA) LIKE %exp:cLike%
         ORDER BY DA3.DA3_PLACA
    EndSql

    While (cAliasQ)->(!Eof()) .And. nCount < 20
        oItem := JsonObject():New()
        oItem["value"] := AllTrim((cAliasQ)->DA3_PLACA)
        oItem["label"] := AllTrim((cAliasQ)->DA3_PLACA) + " - " + AllTrim((cAliasQ)->DA3_XNOMMO)
        aAdd(aItens, oItem)
        nCount++
        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

    oResp["success"] := .T.
    oResp["items"]   := aItens
    oResp["hasNext"] := .F.

Return oResp

/*/{Protheus.doc} PesPlDet
Dados do veiculo (tabela DA3) para preencher automaticamente Motorista, Rota,
Produto, Cliente e Fornecedor ao selecionar uma Placa no formulario de inclusao
(pedido do usuario). Mapeamento confirmado com o usuario:
  DA3_XCOD             -> codigo do Produto (busca desc/UM na SB1)
  DA3_XCODCL+DA3_XLOJCL -> Fornecedor (busca nome na NJ0, ver abaixo)
  DA3_XNOMMO           -> nome do Motorista (ja e texto, sem lookup)
  DA3_XROTA            -> Rota (ja e texto, sem lookup)

Cliente e Fornecedor usam a MESMA tabela NJ0, so que com loja diferente: Cliente
usa loja fixa "01" (igual a gravacao em OGA190Q.PRW::GrvModelo, que sempre grava/
busca NJ0 com CODENT+"01") e devolve NJ0_NOMLOJ; Fornecedor usa a loja do proprio
veiculo (DA3_XLOJCL) e devolve NJ0_NOME (campo diferente, confirmado pelo
usuario). Busca por DbSeek com a chave concatenada (mesmo idioma ja usado no
codigo nativo), sem precisar saber o nome dos campos de chave da NJ0/DA3.

Tambem devolve 'obs' a partir de DA3_DESC, que preenche automaticamente o campo
Observacao (NJH_OBS) do formulario -- pedido do usuario, mesmo criterio dos
demais campos desta funcao (sobrescreve o que estiver no formulario ao trocar
de placa).
@type Static Function
/*/
//=============================================================================================================================
Static Function PesPlDet(oReq)

    Local oResp    := JsonObject():New()
    Local cPlaca   := ""
    Local cCodEnt  := ""
    Local cLojEnt  := ""
    Local cCodPro  := ""

    If ValType(oReq["placa"]) == "C" ; cPlaca := AllTrim(oReq["placa"]) ; EndIf

    If Empty(cPlaca)
        oResp["success"] := .F.
        oResp["message"] := "Parametro 'placa' e obrigatorio"
        Return oResp
    EndIf

    DbSelectArea("DA3")
    DbSetOrder(1)
    If !DbSeek(xFilial("DA3") + cPlaca)
        oResp["success"] := .F.
        oResp["message"] := "Veiculo nao cadastrado (placa " + cPlaca + ")"
        Return oResp
    EndIf

    cCodPro := AllTrim(DA3->DA3_XCOD)
    cCodEnt := AllTrim(DA3->DA3_XCODCL)
    cLojEnt := AllTrim(DA3->DA3_XLOJCL)

    oResp["success"]   := .T.
    oResp["motorista"] := AllTrim(DA3->DA3_XNOMMO)
    oResp["rota"]      := AllTrim(DA3->DA3_XROTA)
    oResp["codPro"]    := cCodPro
    oResp["codEnt"]    := cCodEnt
    oResp["lojEnt"]    := cLojEnt
    oResp["desPro"]    := ""
    oResp["umPro"]     := ""
    oResp["cliente"]   := ""
    oResp["fornecedor"] := ""
    oResp["obs"]       := AllTrim(DA3->DA3_DESC)

    If !Empty(cCodPro)
        oResp["desPro"] := AllTrim(Posicione("SB1", 1, xFilial("SB1") + cCodPro, "B1_DESC"))
        oResp["umPro"]  := AllTrim(Posicione("SB1", 1, xFilial("SB1") + cCodPro, "B1_UM"))
    EndIf

    If !Empty(cCodEnt)
        oResp["cliente"] := AllTrim(Posicione("NJ0", 1, xFilial("NJ0") + cCodEnt + "01", "NJ0_NOMLOJ"))
        If !Empty(cLojEnt)
            oResp["fornecedor"] := AllTrim(Posicione("NJ0", 1, xFilial("NJ0") + cCodEnt + cLojEnt, "NJ0_NOME"))
        EndIf
    EndIf

Return oResp

/*/{Protheus.doc} PesImpTk
Posiciona o NJH pela chave filial+ticket e chama U_QPES001() (o mesmo relatorio
de ticket usado pelo menu nativo da OGA190Q), abrindo a pre-visualizacao de
impressao na sessao do SmartClient.
@type Static Function
/*/
//=============================================================================================================================
Static Function PesImpTk(oReq)

    Local oResp    := JsonObject():New()
    Local cFilialP := ""
    Local cTicketP := ""

    If ValType(oReq["filial"]) == "C" ; cFilialP := AllTrim(oReq["filial"]) ; EndIf
    If ValType(oReq["ticket"]) == "C" ; cTicketP := AllTrim(oReq["ticket"]) ; EndIf

    If Empty(cFilialP) .Or. Empty(cTicketP)
        oResp["success"] := .F.
        oResp["message"] := "Parametros 'filial' e 'ticket' sao obrigatorios"
        Return oResp
    EndIf

    DbSelectArea("NJH")
    DbSetOrder(1)
    If DbSeek(cFilialP + cTicketP)
        U_QPES001()
        oResp["success"] := .T.
    Else
        oResp["success"] := .F.
        oResp["message"] := "Pesagem nao encontrada"
    EndIf

Return oResp

/*/{Protheus.doc} PesRelat
Abre o relatorio nativo de pesagens (Aterro/balanca/QPES003.PRW -- sintetico ou
analitico por Centro de Custo e periodo) na sessao do SmartClient, chamado pelo
botao "Relatorio" da listagem do POUI. Mesmo padrao de PesImpTk (U_QPES001()):
so dispara a rotina nativa, sem repassar filtros -- o QPES003 pergunta os
proprios parametros (Pergunte("QPES003",.T.)) antes de montar o TReport. A
exportacao para Excel ja vem pronta no PrintDialog do TReport, sem necessidade
de logica adicional aqui.
@type Static Function
/*/
//=============================================================================================================================
Static Function PesRelat(oReq)

    Local oResp := JsonObject():New()

    U_QPES003()

    oResp["success"] := .T.

Return oResp

/*/{Protheus.doc} PesLstBl
Lista as balancas cadastradas (DX5) da filial/ambiente atual, para a tela
escolher qual usar na captura de peso -- equivalente web da selecao por F12/
AGRX003E da OGA190Q nativa, que nao pode ser reaproveitada aqui porque abre
TDialog/TTimer (nao renderiza no contexto hibrido FWCallApp/TWebChannel, ver
motivo completo no cabecalho de PesCapt).

O dicionario da DX5 e nativo (modulo Agroindustria, fora deste repositorio) e
o nome exato dos campos de descricao/bloqueio nao e conhecido aqui -- por
isso a funcao descobre esses campos em tempo de execucao via DbStruct(): o
primeiro campo cujo nome contem 'DESC' vira o rotulo exibido, e um campo
contendo 'BLQL' (padrao MSBLQL do Protheus) filtra balancas bloqueadas,
quando existirem. Sem esses campos, a funcao lista tudo que nao estiver
deletado, so pelo codigo (DX5_CODIGO, unico campo que o restante deste
fonte ja usa e sabe que existe).
@type Static Function
/*/
//=============================================================================================================================
Static Function PesLstBl(oReq)

    Local oResp     := JsonObject():New()
    Local aItens    := {}
    Local oItem     := Nil
    Local aEstru    := {}
    Local cCampDesc := ""
    Local cCampBlq  := ""
    Local nI        := 0
    Local cCodigo   := ""
    Local cLabel    := ""

    DbSelectArea("DX5")
    DbSetOrder(1)

    aEstru := DX5->(DbStruct())
    For nI := 1 To Len(aEstru)
        If Empty(cCampDesc) .And. "DESC" $ Upper(aEstru[nI][1])
            cCampDesc := aEstru[nI][1]
        ElseIf Empty(cCampBlq) .And. "BLQL" $ Upper(aEstru[nI][1])
            cCampBlq := aEstru[nI][1]
        EndIf
    Next nI

    DX5->(DbSeek(xFilial("DX5")))
    While DX5->(!Eof()) .And. DX5->DX5_FILIAL == xFilial("DX5")
        If Empty(cCampBlq) .Or. DX5->(FieldGet(FieldPos(cCampBlq))) <> "1"
            cCodigo := AllTrim(DX5->DX5_CODIGO)
            cLabel  := cCodigo
            If !Empty(cCampDesc) .And. !Empty(AllTrim(DX5->(FieldGet(FieldPos(cCampDesc)))))
                cLabel += " - " + AllTrim(DX5->(FieldGet(FieldPos(cCampDesc))))
            EndIf

            oItem := JsonObject():New()
            oItem["value"] := cCodigo
            oItem["label"] := cLabel
            aAdd(aItens, oItem)
        EndIf
        DX5->(DbSkip())
    EndDo

    oResp["success"]  := .T.
    oResp["balancas"] := aItens

Return oResp
