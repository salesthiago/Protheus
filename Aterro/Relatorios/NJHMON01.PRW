#INCLUDE "TOTVS.CH"
#INCLUDE "PROTHEUS.CH"

/*/{Protheus.doc} NJHMON01
Abre a tela hibrida (Angular/PO-UI) de Monitor de Pesagens (tabela NJH),
empacotada em resource/njhmon01.app e carregada via FWCallApp. Mostra, em
cards, o ultimo registro lancado em cada Centro de Custo (NJH_XCLVL) da
filial matriz -- objetivo e detectar rapidamente unidades que pararam de
lancar pesagens (card destacado quando o ultimo lancamento passa de 24h).

Nao altera nada na NJH, e so leitura -- ver MonList.
@type User Function
@author Thiago Sales - Quebec Ambiental
@since 2026-09-21
/*/
//=============================================================================================================================
User Function NJHMON01()

    FWCallApp("njhmon01")

Return

/*/{Protheus.doc} JsToAdvpl
Recebe mensagens da tela Angular (njhmon01) pelo canal AdvplToJs/JsToAdvpl
(TWebChannel), mesmo padrao adotado em Aterro/balanca/QPES004.PRW.
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
    Case cType == "monListar"
        oResp := MonList(oReq)
    OtherWise
        oResp["success"] := .F.
        oResp["message"] := "Operacao nao reconhecida: " + cType
    EndCase

    If !Empty(cReceiveId)
        oWebChannel:AdvplToJs(cReceiveId, oResp:toJson())
    EndIf

Return .T.

/*/{Protheus.doc} MonList
Monta, por Centro de Custo (NJH_XCLVL) da filial matriz ('01', fixo via
xFilial -- NJH e tabela compartilhada entre filiais, ver nota de xFilial mais
abaixo), o registro mais recente encontrado na NJH.

A consulta traz TODOS os registros da filial matriz ordenados por
NJH_XCLVL, NJH_DATA DESC, R_E_C_N_O_ DESC; o loop abaixo aproveita essa
ordenacao e so pega a PRIMEIRA linha de cada grupo de CC (a mais recente),
descartando as demais -- evita subquery/GROUP BY, mesmo espirito do loop de
grupos ja usado em QPES003.PRW::xImpSintetico.

Para cada CC, a "data/hora da ultima pesagem" exibida prioriza a Segunda
Pesagem (NJH_DATPS2/NJH_HORPS2); se nao houver, cai para a Primeira Pesagem
(NJH_DATPS1/NJH_HORPS1); se o ticket mais recente ainda nao foi pesado
nenhuma vez, usa a data de abertura do ticket (NJH_DATA) com hora "00:00"
(pior caso -- conta o dia inteiro como tempo parado).

Centros de Custo sem nenhum registro na NJH nao aparecem (nao ha lista fixa
de unidades aqui -- so mostra o que a tabela realmente tem). Registros com
NJH_XCLVL em branco (ticket criado sem CC definido, ver PesNovo em
QPES004.PRW) sao ignorados.

Devolve os itens ordenados do mais atrasado para o mais recente
(horasDecorridas DESC), para os CCs criticos aparecerem primeiro na tela.
@type Static Function
@param oReq JsonObject, requisicao (sem parametros usados por enquanto)
@return oResp JsonObject, {success, items[], geradoEm}
/*/
//=============================================================================================================================
Static Function MonList(oReq)

    Local oResp    := JsonObject():New()
    Local aItens   := {}
    Local oItem    := Nil
    Local cAliasQ  := GetNextAlias()
    Local cFilMat  := xFilial("NJH", "01")
    Local cQuery   := ""
    Local cCCAnt   := "*ini*"
    Local cCCAtu   := ""
    Local dDataUlt := CToD("")
    Local cHoraUlt := ""
    Local nHoras   := 0

    cQuery := " SELECT NJH.NJH_XCLVL, NJH.NJH_DATA, NJH.NJH_HORPS1, NJH.NJH_HORPS2, "
    cQuery += " NJH.NJH_DATPS1, NJH.NJH_DATPS2, NJH.NJH_PESO1, NJH.NJH_PESO2, NJH.NJH_CODPAV "
    cQuery += " FROM " + RetSqlName("NJH") + " NJH "
    cQuery += " WHERE NJH.D_E_L_E_T_ = ' ' "
    cQuery += " AND NJH.NJH_FILIAL = '" + cFilMat + "' "
    cQuery += " ORDER BY NJH.NJH_XCLVL, NJH.NJH_DATA DESC, NJH.R_E_C_N_O_ DESC "
    cQuery := ChangeQuery(cQuery)

    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAliasQ, .F., .T.)
    (cAliasQ)->(DbGoTop())

    While (cAliasQ)->(!Eof())

        cCCAtu := AllTrim((cAliasQ)->NJH_XCLVL)

        If Empty(cCCAtu) .Or. cCCAtu == cCCAnt
            (cAliasQ)->(DbSkip())
            Loop
        EndIf
        cCCAnt := cCCAtu

        If (cAliasQ)->NJH_PESO2 > 0 .And. !Empty(XDataVal((cAliasQ)->NJH_DATPS2))
            dDataUlt := XDataVal((cAliasQ)->NJH_DATPS2)
            cHoraUlt := AllTrim((cAliasQ)->NJH_HORPS2)
        ElseIf (cAliasQ)->NJH_PESO1 > 0 .And. !Empty(XDataVal((cAliasQ)->NJH_DATPS1))
            dDataUlt := XDataVal((cAliasQ)->NJH_DATPS1)
            cHoraUlt := AllTrim((cAliasQ)->NJH_HORPS1)
        Else
            dDataUlt := XDataVal((cAliasQ)->NJH_DATA)
            cHoraUlt := "00:00"
        EndIf

        If Empty(cHoraUlt) .Or. Len(cHoraUlt) < 5
            cHoraUlt := "00:00"
        EndIf

        nHoras := MonHoras(dDataUlt, cHoraUlt)

        oItem := JsonObject():New()
        oItem["cc"]              := cCCAtu
        oItem["descricao"]       := MonCCDesc(cCCAtu)
        oItem["ultimoTicket"]    := AllTrim((cAliasQ)->NJH_CODPAV)
        oItem["data"]            := DtoC(dDataUlt)
        oItem["hora"]            := cHoraUlt
        oItem["horasDecorridas"] := Round(Max(nHoras, 0), 1)
        oItem["atrasado"]        := (nHoras > 24)
        aAdd(aItens, oItem)

        (cAliasQ)->(DbSkip())
    EndDo
    (cAliasQ)->(DbCloseArea())

    ASort(aItens, , , {|x, y| x["horasDecorridas"] > y["horasDecorridas"]})

    oResp["success"]  := .T.
    oResp["items"]    := aItens
    oResp["geradoEm"] := DtoC(Date()) + " " + Time()

Return oResp

/*/{Protheus.doc} MonCCDesc
Traduz o codigo do Centro de Custo (NJH_XCLVL) para o nome da unidade.
Mesmo mapeamento ja usado em Aterro/balanca/QPES003.PRW::xDescCC3 (nao
reaproveitado direto porque aquela funcao e Static de outro fonte -- ver
regra do prefixo U_ para User Function, nao se aplica aqui pois nem foi
promovida a User).
@type Static Function
@param cCC Character, codigo do centro de custo (NJH_XCLVL)
@return cDesc Character, descricao da unidade
/*/
//=============================================================================================================================
Static Function MonCCDesc(cCC)

    Local cDesc := ""

    Do Case
    Case cCC == "0102" ; cDesc := "Aparecida de Goiania"
    Case cCC == "0121" ; cDesc := "Trindade"
    Case cCC == "0606" ; cDesc := "Paracatu"
    Case cCC == "9001" ; cDesc := "Ituiutaba"
    Otherwise          ; cDesc := "Centro de Custo " + cCC
    EndCase

Return cDesc

/*/{Protheus.doc} MonHoras
Calcula quantas horas se passaram entre a data/hora informada e agora.
'cHora' no formato 'HH:MM' (mesmo formato gravado em NJH_HORPS1/NJH_HORPS2,
ver PesPesar em QPES004.PRW -- Substr(Time(),1,5)).
@type Static Function
@param dData Date, data de referencia
@param cHora Character, hora de referencia 'HH:MM'
@return nHoras Numeric, horas decorridas (999999 se dData vier vazia)
/*/
//=============================================================================================================================
Static Function MonHoras(dData, cHora)

    Local nSegAgora := Val(Substr(Time(), 1, 2)) * 3600 + Val(Substr(Time(), 4, 2)) * 60 + Val(Substr(Time(), 7, 2))
    Local nSegUlt   := Val(Substr(cHora, 1, 2)) * 3600 + Val(Substr(cHora, 4, 2)) * 60
    Local nDias     := 0
    Local nHoras    := 0

    If Empty(dData)
        Return 999999
    EndIf

    nDias  := Date() - dData
    nHoras := (nDias * 86400 + (nSegAgora - nSegUlt)) / 3600

Return nHoras

/*/{Protheus.doc} XDataVal
Converte um valor de data vindo de um alias de SQL cru (TcGenQry/ChangeQuery,
sem passar por BeginSql/EndSql) para tipo Date. Mesma premissa documentada em
QPES004.PRW::XFmtDat -- o driver pode devolver a data ja tipada (D) ou como
CHAR(8) 'AAAAMMDD', dependendo do campo/ambiente.
@type Static Function
@param uDat Date ou Character, valor bruto vindo do alias de SQL
@return dRet Date, convertido (CToD("") se uDat for invalido/vazio)
/*/
//=============================================================================================================================
Static Function XDataVal(uDat)

    Local dRet := CToD("")

    If ValType(uDat) == "D"
        dRet := uDat
    ElseIf ValType(uDat) == "C" .And. Len(AllTrim(uDat)) == 8
        dRet := SToD(uDat)
    EndIf

Return dRet
