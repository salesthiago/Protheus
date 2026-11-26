#INCLUDE "TOTVS.CH"
#INCLUDE "PROTHEUS.CH"

// Limites (em minutos) sem atualizacao para mudar a cor da borda do card
#DEFINE QP6_MIN_AMARELO   30     // acima de 30 min  -> amarelo
#DEFINE QP6_MIN_VERMELHO  1440   // acima de 1 dia   -> vermelho

/*/{Protheus.doc} QPES006
Monitor de Replicacao de Pesagens por Centro de Custo.

Abre a tela hibrida (Angular/PO-UI) empacotada em resource/qpes006.app e
carregada via FWCallApp (fontes em POUI/qpes006). Cada aterro roda um
programa que replica as pesagens para a base oficial de producao pela API
APIAterro (Aterro/api/APATERRO.PRW - recMovNJH / updMovNJH). Este monitor
mostra, em cards, para cada Centro de Custo (NJH_XCLVL):

  - Centro de Custo e descricao da unidade
  - Ultima atualizacao : data/hora da pesagem mais recente que chegou na base
                         (maior entre NJH_DATPS2+NJH_HORPS2 e NJH_DATPS1+NJH_HORPS1)
  - Registros no dia   : quantidade de registros replicados hoje
                         (NJH_XDTSIN = data de hoje, gravado pela APIAterro)
  - Total recolhido    : soma de (NJH_PESO1 - NJH_PESO2) dos registros
                         replicados hoje, somente pesagens completas (entrada
                         e saida informadas) e nao canceladas (NJH_STATUS <> '4')

Cor da borda do card (tempo desde a ultima atualizacao):
  - Verde    : ate 30 minutos
  - Amarelo  : mais de 30 minutos ate 1 dia
  - Vermelho : mais de 1 dia (ou nenhum registro encontrado)

Observacao: NJH_XDTSIN guarda apenas a DATA da sincronizacao (sem hora), por
isso o horario da "ultima atualizacao" e o da ultima pesagem recebida. Fora do
horario de operacao do aterro (sem caminhoes) o card tende a ficar amarelo
mesmo com a replicacao funcionando.

Nao altera nada na NJH, e so leitura.
@type User Function
@author Thiago Sales - Quebec Ambiental
@since 2026-11-11
/*/
//=============================================================================================================================
User Function QPES006()

    FWCallApp("qpes006")

Return

/*/{Protheus.doc} JsToAdvpl
Recebe mensagens da tela Angular (qpes006) pelo canal AdvplToJs/JsToAdvpl
(TWebChannel), mesmo padrao adotado em Aterro/Relatorios/NJHMON01.PRW.
O lado Angular embute o receiveId dentro do JSON de cContent.
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
    Case cType == "repListar"
        oResp := RepList()
    OtherWise
        oResp["success"] := .F.
        oResp["message"] := "Operacao nao reconhecida: " + cType
    EndCase

    If !Empty(cReceiveId)
        oWebChannel:AdvplToJs(cReceiveId, oResp:toJson())
    EndIf

Return .T.

/*/{Protheus.doc} RepList
Monta um item por Centro de Custo com a ultima atualizacao, a quantidade de
registros replicados hoje e o total recolhido hoje.

Uma unica query: a tabela derivada M agrega por CC as maiores datas de
Primeira/Segunda Pesagem e os totais do dia; o SELECT externo busca a maior
hora dentro dessas datas (evita concatenar data+hora no SQL, que muda de
sintaxe conforme o banco).

Os Centros de Custo conhecidos (ver RepCCDesc) aparecem sempre, mesmo sem
nenhum registro na NJH (nesse caso o card fica vermelho).
@type Static Function
@return oResp JsonObject, {success, items[], geradoEm, limiteAmareloMin, limiteVermelhoMin}
/*/
//=============================================================================================================================
Static Function RepList()

    Local oResp    := JsonObject():New()
    Local aItens   := {}
    Local aCCFixos := {"0102", "0121", "0606", "9001"}
    Local aCCVistos:= {}
    Local cAliasQ  := GetNextAlias()
    Local cNJH     := RetSqlName("NJH")
    Local cHoje    := DToS(Date())
    Local cQuery   := ""
    Local cCC      := ""
    Local cUlt1    := ""
    Local cUlt2    := ""
    Local cUlt     := ""
    Local nX       := 0

    // M = agregado por Centro de Custo
    cQuery := " SELECT N.NJH_XCLVL XCLVL, M.DT1, M.DT2, M.QTDHOJE, M.PESOHOJE, "
    cQuery += "        MAX(CASE WHEN N.NJH_DATPS1 = M.DT1 THEN N.NJH_HORPS1 ELSE ' ' END) HOR1, "
    cQuery += "        MAX(CASE WHEN N.NJH_DATPS2 = M.DT2 THEN N.NJH_HORPS2 ELSE ' ' END) HOR2 "
    cQuery += " FROM " + cNJH + " N "
    cQuery += " INNER JOIN ( "
    cQuery += "     SELECT NJH_XCLVL CC, "
    cQuery += "            MAX(NJH_DATPS1) DT1, "
    cQuery += "            MAX(NJH_DATPS2) DT2, "
    cQuery += "            SUM(CASE WHEN NJH_XDTSIN = '" + cHoje + "' THEN 1 ELSE 0 END) QTDHOJE, "
    cQuery += "            SUM(CASE WHEN NJH_XDTSIN = '" + cHoje + "' AND NJH_STATUS <> '4' "
    cQuery += "                      AND NJH_PESO1 > 0 AND NJH_PESO2 > 0 "
    cQuery += "                     THEN NJH_PESO1 - NJH_PESO2 ELSE 0 END) PESOHOJE "
    cQuery += "     FROM " + cNJH
    cQuery += "     WHERE D_E_L_E_T_ = ' ' AND NJH_XCLVL <> ' ' "
    cQuery += "     GROUP BY NJH_XCLVL "
    cQuery += " ) M ON M.CC = N.NJH_XCLVL "
    cQuery += " WHERE N.D_E_L_E_T_ = ' ' "
    cQuery += "   AND (N.NJH_DATPS1 = M.DT1 OR N.NJH_DATPS2 = M.DT2) "
    cQuery += " GROUP BY N.NJH_XCLVL, M.DT1, M.DT2, M.QTDHOJE, M.PESOHOJE "
    cQuery := ChangeQuery(cQuery)

    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAliasQ, .F., .T.)
    (cAliasQ)->(DbGoTop())

    While (cAliasQ)->(!Eof())

        cCC := AllTrim((cAliasQ)->XCLVL)

        // Data+hora no formato AAAAMMDDHH:MM -- comparavel como texto
        cUlt1 := RepDtHr((cAliasQ)->DT1, (cAliasQ)->HOR1)
        cUlt2 := RepDtHr((cAliasQ)->DT2, (cAliasQ)->HOR2)
        cUlt  := If(cUlt2 > cUlt1, cUlt2, cUlt1)

        aAdd(aItens, RepItem(cCC, cUlt, (cAliasQ)->QTDHOJE, (cAliasQ)->PESOHOJE))
        aAdd(aCCVistos, cCC)

        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

    // Centros de Custo conhecidos que nao tem nenhum registro na NJH
    For nX := 1 To Len(aCCFixos)
        If aScan(aCCVistos, aCCFixos[nX]) == 0
            aAdd(aItens, RepItem(aCCFixos[nX], "", 0, 0))
        EndIf
    Next nX

    // Mais atrasados primeiro
    ASort(aItens, , , {|x, y| x["minutosDecorridos"] > y["minutosDecorridos"]})

    oResp["success"]           := .T.
    oResp["items"]             := aItens
    oResp["geradoEm"]          := DtoC(Date()) + " " + Time()
    oResp["limiteAmareloMin"]  := QP6_MIN_AMARELO
    oResp["limiteVermelhoMin"] := QP6_MIN_VERMELHO

Return oResp

/*/{Protheus.doc} RepItem
Monta o JSON de um card.
@type Static Function
@param cCC      Character, centro de custo
@param cUlt     Character, ultima atualizacao 'AAAAMMDDHH:MM' (vazio = nunca)
@param nQtdHoje Numeric, registros replicados hoje
@param nPesoHoje Numeric, total recolhido hoje (KG)
@return oItem JsonObject
/*/
//=============================================================================================================================
Static Function RepItem(cCC, cUlt, nQtdHoje, nPesoHoje)

    Local oItem   := JsonObject():New()
    Local dUlt    := CToD("")
    Local cHora   := ""
    Local nMin    := 0
    Local cStatus := ""

    If !Empty(cUlt)
        dUlt  := SToD(Left(cUlt, 8))
        cHora := Substr(cUlt, 9, 5)
        nMin  := RepMinutos(dUlt, cHora)
    Else
        nMin  := 999999
    EndIf

    Do Case
    Case Empty(dUlt) .Or. nMin > QP6_MIN_VERMELHO
        cStatus := "vermelho"
    Case nMin > QP6_MIN_AMARELO
        cStatus := "amarelo"
    OtherWise
        cStatus := "verde"
    EndCase

    oItem["cc"]                := cCC
    oItem["descricao"]         := RepCCDesc(cCC)
    oItem["data"]              := If(Empty(dUlt), "", DtoC(dUlt))
    oItem["hora"]              := cHora
    oItem["minutosDecorridos"] := Int(nMin)
    oItem["registrosHoje"]     := nQtdHoje
    oItem["pesoHoje"]          := Round(nPesoHoje, 0)
    oItem["status"]            := cStatus

Return oItem

/*/{Protheus.doc} RepDtHr
Junta data (AAAAMMDD ou Date) e hora (HH:MM) em 'AAAAMMDDHH:MM'.
Data vazia devolve "" e hora vazia/invalida vira "00:00".
@type Static Function
/*/
//=============================================================================================================================
Static Function RepDtHr(uDat, cHora)

    Local cDat := ""

    If ValType(uDat) == "D"
        cDat := DToS(uDat)
    ElseIf ValType(uDat) == "C"
        cDat := AllTrim(uDat)
    EndIf

    If Len(cDat) <> 8
        Return ""
    EndIf

    cHora := AllTrim(If(ValType(cHora) == "C", cHora, ""))
    If Len(cHora) < 5 .Or. Substr(cHora, 3, 1) <> ":"
        cHora := "00:00"
    EndIf

Return cDat + Left(cHora, 5)

/*/{Protheus.doc} RepMinutos
Minutos decorridos entre a data/hora informada e agora (minimo 0).
@type Static Function
@param dData Date, data de referencia
@param cHora Character, hora 'HH:MM'
@return nMin Numeric
/*/
//=============================================================================================================================
Static Function RepMinutos(dData, cHora)

    Local cAgora  := Time()
    Local nMinAgr := Val(Substr(cAgora, 1, 2)) * 60 + Val(Substr(cAgora, 4, 2))
    Local nMinUlt := Val(Substr(cHora, 1, 2)) * 60 + Val(Substr(cHora, 4, 2))
    Local nMin    := (Date() - dData) * 1440 + (nMinAgr - nMinUlt)

Return Max(nMin, 0)

/*/{Protheus.doc} RepCCDesc
Traduz o codigo do Centro de Custo (NJH_XCLVL) para o nome da unidade.
Mesmo mapeamento de QPES003/QPES005/NJHMON01.
@type Static Function
/*/
//=============================================================================================================================
Static Function RepCCDesc(cCC)

    Local cDesc := ""

    Do Case
    Case cCC == "0102" ; cDesc := "Aparecida de Goiania"
    Case cCC == "0121" ; cDesc := "Trindade"
    Case cCC == "0606" ; cDesc := "Paracatu"
    Case cCC == "9001" ; cDesc := "Ituiutaba"
    Otherwise          ; cDesc := "Centro de Custo " + cCC
    EndCase

Return cDesc
