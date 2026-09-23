#INCLUDE "TOTVS.CH"
#INCLUDE "PROTHEUS.CH"

/*/{Protheus.doc} MNTA540App
Abre a tela hibrida (Angular/PO-UI) de Sinistros de Frota (frtsin001),
empacotada em resource/frtsin001.app e carregada via FWCallApp. Recria a
rotina padrao MNTA540 (SIGAMNT / tabela TRH) e suas filhas TRO (veiculos
envolvidos), TRN (testemunhas), TRM (vitimas) e TRI (anexos).

Mesmo mecanismo de canal de Contratos/RTM003App.prw e POUI/estmvc001:
AdvplToJs/JsToAdvpl (TWebEngine/TWebChannel), SEM HTTP/REST. A gravacao e
feita direto por RecLock/Replace (sem MVC), replicando as regras essenciais
do dicionario (dominios, obrigatorios, ExistCpo de SX5).

@type User Function
@author Quebec Ambiental
@since 2026-09-03
/*/
//=============================================================================================================================
USER FUNCTION MNTA540App()

    FWCallApp("frtsin001")

RETURN

/*/{Protheus.doc} JsToAdvpl
Recebe as mensagens da tela Angular (frtsin001) pelo canal
AdvplToJs/JsToAdvpl. O receiveId nao viaja automatico entre JS e ADVPL --
vem embutido no JSON de content e e devolvido via oWebChannel:AdvplToJs.
@type Function
/*/
//=============================================================================================================================
Static Function JsToAdvpl(oWebChannel, cType, cContent)

    Local oReq       := JsonObject():New()
    Local oResp      := JsonObject():New()
    Local cReceiveId := ""

    oReq:fromJson(cContent)
    cReceiveId := oReq["receiveId"]

    Do Case
    Case cType == "sinistroListar"
        oResp := ZsiList(oReq)
    Case cType == "sinistroDetalhe"
        oResp := ZsiDet(oReq)
    Case cType == "sinistroCriar"
        oResp := ZsiCriar(oReq)
    Case cType == "sinistroAtualizar"
        oResp := ZsiAtu(oReq)
    Case cType == "veiculoSalvar"
        oResp := ZsiVeiPut(oReq)
    Case cType == "veiculoRemover"
        oResp := ZsiVeiDel(oReq)
    Case cType == "testemunhaSalvar"
        oResp := ZsiTesPut(oReq)
    Case cType == "testemunhaRemover"
        oResp := ZsiTesDel(oReq)
    Case cType == "vitimaSalvar"
        oResp := ZsiVitPut(oReq)
    Case cType == "vitimaRemover"
        oResp := ZsiVitDel(oReq)
    Case cType == "lookupBem"
        oResp := ZsiLkBem(oReq)
    Case cType == "lookupFuncionario"
        oResp := ZsiLkFunc(oReq)
    Case cType == "lookupDominio"
        oResp := ZsiLkDom(oReq)
    Case cType == "sinistroImportarSimular"
        oResp := ZsiImpSim(oReq)
    Case cType == "sinistroImportar"
        oResp := ZsiImp(oReq)
    Case cType == "configParametrizar"
        oResp := ZsiCfgParam(oReq)
    OtherWise
        oResp["success"] := .F.
        oResp["message"] := "Operacao nao reconhecida: " + cType
    EndCase

    If !Empty(cReceiveId)
        oWebChannel:AdvplToJs(cReceiveId, oResp:toJson())
    EndIf

Return .T.

// =====================================================================================================================
//  LISTA
// =====================================================================================================================

/*/{Protheus.doc} ZsiList
Lista sinistros da filial da sessao (operacao "sinistroListar"). Filtros
opcionais {numero, dataDe, dataAte, placa, evento, culpabilidade, status}.
Filtros de codigo (evento/culpa/status) e texto (numero/placa) usam o idioma
LIKE-casa-tudo ja usado em RTM003App (padrao vazio "%%" continua na query,
sem BeginSql condicional); intervalo de data cai para 1900..2099 quando vazio.
@type Static Function
@param oReq JsonObject
@return JsonObject, {success, sinistros:[{numero,data,hora,evento,eventoLabel,codBem,nomeBem,placa,gravidade,gravidadeLabel,status,statusLabel,culpabilidade,culpabilidadeLabel,culpadoNome,fonte}]}
/*/
//=============================================================================================================================
Static Function ZsiList(oReq)

    Local oResp     := JsonObject():New()
    Local aSin      := {}
    Local oSin      := Nil
    Local oZ        := Nil
    Local cAliasQ   := GetNextAlias()
    Local cNumSin   := ""
    Local cFiltCul  := ZsiReqStr(oReq, "culpabilidade")
    Local cLikeNum  := ZsiLikeAll(ZsiReqStr(oReq, "numero"))
    Local cLikePla  := ZsiLikeAll(ZsiReqStr(oReq, "placa"))
    Local cLikeEve  := ZsiLikeAll(ZsiReqStr(oReq, "evento"))
    Local cLikeSts  := ZsiLikeAll(ZsiReqStr(oReq, "status"))
    Local dDe       := ZsiReqDate(oReq, "dataDe")
    Local dAte      := ZsiReqDate(oReq, "dataAte")

    If Empty(dDe)  ; dDe  := SToD("19000101") ; EndIf
    If Empty(dAte) ; dAte := SToD("20991231") ; EndIf

    // O SELECT so referencia colunas PADRAO da TRH (sempre existem). Os campos custom
    // (TRH_ZCULPA/ZCLPNM/ZFONTE) e o TRH_NOMBEM (virtual) sao lidos DEPOIS, registro a
    // registro, por ZsiTrhZ() -- assim a lista funciona mesmo antes de rodar a
    // parametrizacao (Configuracao) que cria as colunas custom. O filtro por
    // culpabilidade tambem e aplicado em memoria.
    BeginSql Alias cAliasQ
        SELECT TRH_NUMSIN, TRH_DTACID, TRH_HRACID, TRH_EVENTO, TRH_CODBEM,
               TRH_PLACA, TRH_GRAVID, TRH_STATUS
          FROM %table:TRH% TRH
         WHERE TRH.%notDel%
           AND TRH.TRH_FILIAL = %xfilial:TRH%
           AND TRH.TRH_NUMSIN LIKE %exp:cLikeNum%
           AND TRH.TRH_PLACA  LIKE %exp:cLikePla%
           AND TRH.TRH_EVENTO LIKE %exp:cLikeEve%
           AND TRH.TRH_STATUS LIKE %exp:cLikeSts%
           AND TRH.TRH_DTACID BETWEEN %exp:dDe% AND %exp:dAte%
         ORDER BY TRH.TRH_DTACID DESC, TRH.TRH_NUMSIN DESC
    EndSql

    While (cAliasQ)->(!Eof())
        cNumSin := AllTrim((cAliasQ)->TRH_NUMSIN)
        oZ      := ZsiTrhZ(cNumSin)   // {culpa, clpnm, fonte} -- "" se coluna nao existe

        If !Empty(cFiltCul) .And. oZ["culpa"] != cFiltCul
            (cAliasQ)->(dbSkip())
            Loop
        EndIf

        oSin := JsonObject():New()
        oSin["numero"]              := cNumSin
        oSin["data"]                := ZsiJDate((cAliasQ)->TRH_DTACID)
        oSin["hora"]                := AllTrim((cAliasQ)->TRH_HRACID)
        oSin["evento"]              := AllTrim((cAliasQ)->TRH_EVENTO)
        oSin["eventoLabel"]         := ZsiDomLabel("evento", AllTrim((cAliasQ)->TRH_EVENTO))
        oSin["codBem"]              := AllTrim((cAliasQ)->TRH_CODBEM)
        oSin["nomeBem"]             := ZsiNomeBem((cAliasQ)->TRH_CODBEM)
        oSin["placa"]               := AllTrim((cAliasQ)->TRH_PLACA)
        oSin["gravidade"]           := AllTrim((cAliasQ)->TRH_GRAVID)
        oSin["gravidadeLabel"]      := ZsiDomLabel("gravidade", AllTrim((cAliasQ)->TRH_GRAVID))
        oSin["status"]              := AllTrim((cAliasQ)->TRH_STATUS)
        oSin["statusLabel"]         := ZsiSx5Desc("SP", AllTrim((cAliasQ)->TRH_STATUS))
        oSin["culpabilidade"]       := oZ["culpa"]
        oSin["culpabilidadeLabel"]  := ZsiDomLabel("culpa", oZ["culpa"])
        oSin["culpadoNome"]         := oZ["clpnm"]
        oSin["fonte"]               := oZ["fonte"]
        aAdd(aSin, oSin)
        (cAliasQ)->(dbSkip())
    EndDo
    (cAliasQ)->(dbCloseArea())

    oResp["success"]   := .T.
    oResp["sinistros"] := aSin

Return oResp

/*/{Protheus.doc} ZsiTrhZ
Le os campos custom do cabecalho (TRH_ZCULPA/ZCLPNM/ZFONTE) de forma tolerante:
seek na TRH pelo numero e leitura protegida por ErrorBlock. Se as colunas ainda
nao existem (parametrizacao nao rodada), devolve tudo "".
@type Static Function
@return JsonObject, {culpa, clpnm, fonte}
/*/
//=============================================================================================================================
Static Function ZsiTrhZ(cNumSin)

    Local oZ   := JsonObject():New()
    Local bErr := ErrorBlock({|e| Break(e)})

    oZ["culpa"] := ""
    oZ["clpnm"] := ""
    oZ["fonte"] := ""

    Begin Sequence
        If !ZsiTemArea("TRH")
            Break
        EndIf
        TRH->(dbSetOrder(1))
        If TRH->(dbSeek(xFilial("TRH") + PadR(cNumSin, TamSX3("TRH_NUMSIN")[1])))
            If TRH->(FieldPos("TRH_ZCULPA")) > 0 ; oZ["culpa"] := AllTrim(TRH->(FieldGet(FieldPos("TRH_ZCULPA")))) ; EndIf
            If TRH->(FieldPos("TRH_ZCLPNM")) > 0 ; oZ["clpnm"] := AllTrim(TRH->(FieldGet(FieldPos("TRH_ZCLPNM")))) ; EndIf
            If TRH->(FieldPos("TRH_ZFONTE")) > 0 ; oZ["fonte"] := AllTrim(TRH->(FieldGet(FieldPos("TRH_ZFONTE")))) ; EndIf
        EndIf
    Recover
        oZ["culpa"] := ""
        oZ["clpnm"] := ""
        oZ["fonte"] := ""
    End Sequence

    ErrorBlock(bErr)

Return oZ

// =====================================================================================================================
//  DETALHE / MONTAGEM
// =====================================================================================================================

/*/{Protheus.doc} ZsiDet
Carrega um sinistro completo (operacao "sinistroDetalhe") -- cabecalho TRH +
filhas TRO/TRN/TRM/TRI.
@type Static Function
@param oReq JsonObject, {numero}
/*/
//=============================================================================================================================
Static Function ZsiDet(oReq)

    Local oResp   := JsonObject():New()
    Local cNumSin := ZsiReqStr(oReq, "numero")

    If Empty(cNumSin)
        oResp["success"] := .F.
        oResp["message"] := "Numero do sinistro e obrigatorio"
        Return oResp
    EndIf

Return ZsiMont(cNumSin)

/*/{Protheus.doc} ZsiMont
Monta o JSON completo de um sinistro. Reusada por ZsiDet/ZsiCriar/ZsiAtu e
pelas operacoes das filhas.
@type Static Function
@param cNumSin caractere, TRH_NUMSIN
@return JsonObject
/*/
//=============================================================================================================================
Static Function ZsiMont(cNumSin)

    Local oResp   := JsonObject():New()
    Local oSin    := Nil
    Local nTamNum := TamSX3("TRH_NUMSIN")[1]

    TRH->(dbSetOrder(1)) // TRH_FILIAL + TRH_NUMSIN
    If !TRH->(dbSeek(xFilial("TRH") + PadR(cNumSin, nTamNum)))
        oResp["success"] := .F.
        oResp["message"] := "Sinistro [" + cNumSin + "] nao encontrado na filial " + xFilial("TRH")
        Return oResp
    EndIf

    oSin := JsonObject():New()
    oSin["numero"]        := AllTrim(TRH->TRH_NUMSIN)
    oSin["filial"]        := AllTrim(TRH->TRH_FILIAL)
    oSin["data"]          := ZsiJDate(TRH->TRH_DTACID)
    oSin["hora"]          := AllTrim(TRH->TRH_HRACID)
    oSin["evento"]        := AllTrim(TRH->TRH_EVENTO)
    oSin["eventoLabel"]   := ZsiDomLabel("evento", AllTrim(TRH->TRH_EVENTO))
    oSin["codBem"]        := AllTrim(TRH->TRH_CODBEM)
    oSin["nomeBem"]       := ZsiNomeBem(TRH->TRH_CODBEM)  // TRH_NOMBEM e virtual -- resolve por ST9
    oSin["placa"]         := AllTrim(TRH->TRH_PLACA)
    oSin["gravidade"]     := AllTrim(TRH->TRH_GRAVID)
    oSin["gravidadeLabel"]:= ZsiDomLabel("gravidade", AllTrim(TRH->TRH_GRAVID))
    oSin["tempo"]         := AllTrim(TRH->TRH_TEMPO)
    oSin["via"]           := AllTrim(TRH->TRH_VIA)
    oSin["periodo"]       := AllTrim(TRH->TRH_PERIOD)
    oSin["maoDirecao"]    := AllTrim(TRH->TRH_VIADIR)
    oSin["local"]         := AllTrim(TRH->TRH_LOCAL)
    oSin["cidade"]        := AllTrim(TRH->TRH_CIDACI)
    oSin["uf"]            := AllTrim(TRH->TRH_UFACID)
    oSin["numeroBO"]      := AllTrim(TRH->TRH_NUMBO)
    oSin["nomeDP"]        := AllTrim(TRH->TRH_NOMDP)
    oSin["interrViagem"]  := AllTrim(TRH->TRH_INTERR)
    oSin["necGuincho"]    := AllTrim(TRH->TRH_GUINCH)
    oSin["valorGuincho"]  := TRH->TRH_VALGUI
    oSin["delitoConcret"] := AllTrim(TRH->TRH_CONDEL)
    oSin["terceiroEvadiu"]:= AllTrim(TRH->TRH_TEREVA)
    oSin["status"]        := AllTrim(TRH->TRH_STATUS)
    oSin["statusLabel"]   := ZsiSx5Desc("SP", AllTrim(TRH->TRH_STATUS))
    oSin["descricao"]     := AllTrim(TRH->TRH_DESCRI)
    oSin["danosFrota"]    := AllTrim(TRH->TRH_FLGDAN)
    oSin["valorDanos"]    := TRH->TRH_VALDAN
    oSin["descDanos"]     := AllTrim(TRH->TRH_DANOS2)
    oSin["ordem"]         := AllTrim(TRH->TRH_ORDEM)
    oSin["dtDigitacao"]   := ZsiJDate(TRH->TRH_DTDIG)
    oSin["culpabilidade"]      := ZsiSFldTrh("TRH_ZCULPA")
    oSin["culpabilidadeLabel"] := ZsiDomLabel("culpa", ZsiSFldTrh("TRH_ZCULPA"))
    oSin["culpadoNome"]        := ZsiSFldTrh("TRH_ZCLPNM")
    oSin["numeroFor"]          := ZsiSFldTrh("TRH_ZNRFOR")
    oSin["valorFolha"]         := ZsiNFldTrh("TRH_ZVLFOL")
    oSin["valorSaldo"]         := ZsiNFldTrh("TRH_ZVLSLD")
    oSin["fonte"]              := ZsiSFldTrh("TRH_ZFONTE")

    oSin["veiculos"]    := ZsiFilTRO(cNumSin)
    oSin["testemunhas"] := ZsiFilTRN(cNumSin)
    oSin["vitimas"]     := ZsiFilTRM(cNumSin)
    oSin["anexos"]      := ZsiFilTRI(cNumSin)

    oResp["success"]  := .T.
    oResp["sinistro"] := oSin

Return oResp

/*/{Protheus.doc} ZsiFilTRO
Le os veiculos envolvidos (TRO) de um sinistro.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiFilTRO(cNumSin)

    Local aRows   := {}
    Local oRow    := Nil
    Local cAliasQ := GetNextAlias()
    Local bErr    := ErrorBlock({|e| Break(e)})

    // Protegido: se as colunas custom (TRO_ZORIG/ZMAT) ainda nao existem, devolve
    // a lista vazia em vez de derrubar a tela (rodar a Configuracao/parametrizacao).
    Begin Sequence

    BeginSql Alias cAliasQ
        SELECT TRO_SEQVEI, TRO_ZORIG, TRO_PLACA, TRO_DESVEI, TRO_MOTVEI, TRO_ZMAT, TRO_CPF,
               TRO_CNHMOT, TRO_TELMOT, TRO_NOMPR, TRO_DANOS, TRO_VALPRE, TRO_VALTER, TRO_PERCEN,
               TRO_SEGUR, TRO_SEGCOR, TRO_APOLIC
          FROM %table:TRO% TRO
         WHERE TRO.%notDel%
           AND TRO.TRO_FILIAL = %xfilial:TRO%
           AND TRO.TRO_NUMSIN = %exp:cNumSin%
         ORDER BY TRO.TRO_SEQVEI
    EndSql

    While (cAliasQ)->(!Eof())
        oRow := JsonObject():New()
        oRow["seq"]         := AllTrim((cAliasQ)->TRO_SEQVEI)
        oRow["origem"]      := AllTrim((cAliasQ)->TRO_ZORIG)
        oRow["origemLabel"] := ZsiDomLabel("origveic", AllTrim((cAliasQ)->TRO_ZORIG))
        oRow["placa"]       := AllTrim((cAliasQ)->TRO_PLACA)
        oRow["descricao"]   := AllTrim((cAliasQ)->TRO_DESVEI)
        oRow["condutor"]    := AllTrim((cAliasQ)->TRO_MOTVEI)
        oRow["matricula"]   := AllTrim((cAliasQ)->TRO_ZMAT)
        oRow["cpf"]         := AllTrim((cAliasQ)->TRO_CPF)
        oRow["cnh"]         := AllTrim((cAliasQ)->TRO_CNHMOT)
        oRow["telefone"]    := AllTrim((cAliasQ)->TRO_TELMOT)
        oRow["proprietario"]:= AllTrim((cAliasQ)->TRO_NOMPR)
        oRow["danos"]       := AllTrim((cAliasQ)->TRO_DANOS)
        oRow["valorPrejuizo"]:= (cAliasQ)->TRO_VALPRE
        oRow["valorTerceiro"]:= (cAliasQ)->TRO_VALTER
        oRow["percentualGanho"]:= (cAliasQ)->TRO_PERCEN
        oRow["segurado"]    := AllTrim((cAliasQ)->TRO_SEGUR)
        oRow["seguradora"]  := AllTrim((cAliasQ)->TRO_SEGCOR)
        oRow["apolice"]     := AllTrim((cAliasQ)->TRO_APOLIC)
        aAdd(aRows, oRow)
        (cAliasQ)->(dbSkip())
    EndDo
    (cAliasQ)->(dbCloseArea())

    Recover
        aRows := {}
        If Select(cAliasQ) > 0 ; (cAliasQ)->(dbCloseArea()) ; EndIf
    End Sequence
    ErrorBlock(bErr)

Return aRows

/*/{Protheus.doc} ZsiFilTRN
Le as testemunhas (TRN) de um sinistro.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiFilTRN(cNumSin)

    Local aRows   := {}
    Local oRow    := Nil
    Local cAliasQ := GetNextAlias()

    BeginSql Alias cAliasQ
        SELECT TRN_SEQTES, TRN_NOMTES, TRN_TELTES, TRN_ENDTES, TRN_CIDTES, TRN_UFTES,
               TRN_TIPDOC, TRN_DOCTO, TRN_QLFTES
          FROM %table:TRN% TRN
         WHERE TRN.%notDel%
           AND TRN.TRN_FILIAL = %xfilial:TRN%
           AND TRN.TRN_NUMSIN = %exp:cNumSin%
         ORDER BY TRN.TRN_SEQTES
    EndSql

    While (cAliasQ)->(!Eof())
        oRow := JsonObject():New()
        oRow["seq"]         := AllTrim((cAliasQ)->TRN_SEQTES)
        oRow["nome"]        := AllTrim((cAliasQ)->TRN_NOMTES)
        oRow["telefone"]    := AllTrim((cAliasQ)->TRN_TELTES)
        oRow["endereco"]    := AllTrim((cAliasQ)->TRN_ENDTES)
        oRow["cidade"]      := AllTrim((cAliasQ)->TRN_CIDTES)
        oRow["uf"]          := AllTrim((cAliasQ)->TRN_UFTES)
        oRow["tipoDoc"]     := AllTrim((cAliasQ)->TRN_TIPDOC)
        oRow["documento"]   := AllTrim((cAliasQ)->TRN_DOCTO)
        oRow["qualificacao"]:= AllTrim((cAliasQ)->TRN_QLFTES)
        aAdd(aRows, oRow)
        (cAliasQ)->(dbSkip())
    EndDo
    (cAliasQ)->(dbCloseArea())

Return aRows

/*/{Protheus.doc} ZsiFilTRM
Le as vitimas (TRM) de um sinistro.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiFilTRM(cNumSin)

    Local aRows   := {}
    Local oRow    := Nil
    Local cAliasQ := GetNextAlias()

    BeginSql Alias cAliasQ
        SELECT TRM_SEQVIT, TRM_INDFUN, TRM_MATVIT, TRM_NOMVIT, TRM_TELVIT, TRM_ENDVIT,
               TRM_CIDVIT, TRM_UFVIT, TRM_LESOES, TRM_ACAO, TRM_DESFUN, TRM_FATAL,
               TRM_CODVIT, TRM_VALVIT
          FROM %table:TRM% TRM
         WHERE TRM.%notDel%
           AND TRM.TRM_FILIAL = %xfilial:TRM%
           AND TRM.TRM_NUMSIN = %exp:cNumSin%
         ORDER BY TRM.TRM_SEQVIT
    EndSql

    While (cAliasQ)->(!Eof())
        oRow := JsonObject():New()
        oRow["seq"]          := AllTrim((cAliasQ)->TRM_SEQVIT)
        oRow["funcionario"]  := AllTrim((cAliasQ)->TRM_INDFUN)
        oRow["matricula"]    := AllTrim((cAliasQ)->TRM_MATVIT)
        oRow["nome"]         := AllTrim((cAliasQ)->TRM_NOMVIT)
        oRow["telefone"]     := AllTrim((cAliasQ)->TRM_TELVIT)
        oRow["endereco"]     := AllTrim((cAliasQ)->TRM_ENDVIT)
        oRow["cidade"]       := AllTrim((cAliasQ)->TRM_CIDVIT)
        oRow["uf"]           := AllTrim((cAliasQ)->TRM_UFVIT)
        oRow["lesoes"]       := AllTrim((cAliasQ)->TRM_LESOES)
        oRow["acaoTomada"]   := AllTrim((cAliasQ)->TRM_ACAO)
        oRow["funcao"]       := AllTrim((cAliasQ)->TRM_DESFUN)
        oRow["fatal"]        := AllTrim((cAliasQ)->TRM_FATAL)
        oRow["condicao"]     := AllTrim((cAliasQ)->TRM_CODVIT)
        oRow["valorVitima"]  := (cAliasQ)->TRM_VALVIT
        aAdd(aRows, oRow)
        (cAliasQ)->(dbSkip())
    EndDo
    (cAliasQ)->(dbCloseArea())

Return aRows

/*/{Protheus.doc} ZsiFilTRI
Le os anexos (TRI) de um sinistro. O binario nao vai no JSON -- so os
metadados; o download e feito pela operacao "anexoDownload" (Fase E).
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiFilTRI(cNumSin)

    Local aRows   := {}
    Local oRow    := Nil
    Local cAliasQ := GetNextAlias()
    Local bErr    := ErrorBlock({|e| Break(e)})

    If !ZsiTemArea("TRI")
        ErrorBlock(bErr)
        Return aRows
    EndIf

    // Protegido: se as colunas custom TRI_Z* ainda nao existem, devolve lista vazia.
    Begin Sequence

    // TRI padrao nao tem chave-filha propria (so FILIAL+NUMSIN). A identidade de cada
    // anexo para download/remocao (Fase E) sera resolvida la -- provavelmente por um
    // campo custom TRI_ZSEQ. Aqui a lista sai ordenada por data/hora de recebimento.
    BeginSql Alias cAliasQ
        SELECT TRI_CODDOC, TRI_NOMDOC, TRI_DTREC, TRI_HRREC,
               TRI_ZTIPO, TRI_ZARQ, TRI_ZPATH, TRI_ZMIME, TRI_ZTAM
          FROM %table:TRI% TRI
         WHERE TRI.%notDel%
           AND TRI.TRI_FILIAL = %xfilial:TRI%
           AND TRI.TRI_NUMSIN = %exp:cNumSin%
         ORDER BY TRI.TRI_DTREC, TRI.TRI_HRREC
    EndSql

    While (cAliasQ)->(!Eof())
        oRow := JsonObject():New()
        oRow["codDoc"]    := AllTrim((cAliasQ)->TRI_CODDOC)
        oRow["nomeDoc"]   := AllTrim((cAliasQ)->TRI_NOMDOC)
        oRow["dataReceb"] := ZsiJDate((cAliasQ)->TRI_DTREC)
        oRow["horaReceb"] := AllTrim((cAliasQ)->TRI_HRREC)
        oRow["tipo"]      := AllTrim((cAliasQ)->TRI_ZTIPO)
        oRow["tipoLabel"] := ZsiDomLabel("tpanexo", AllTrim((cAliasQ)->TRI_ZTIPO))
        oRow["arquivo"]   := AllTrim((cAliasQ)->TRI_ZARQ)
        oRow["caminho"]   := AllTrim((cAliasQ)->TRI_ZPATH)
        oRow["mime"]      := AllTrim((cAliasQ)->TRI_ZMIME)
        oRow["tamanho"]   := (cAliasQ)->TRI_ZTAM
        aAdd(aRows, oRow)
        (cAliasQ)->(dbSkip())
    EndDo
    (cAliasQ)->(dbCloseArea())

    Recover
        aRows := {}
        If Select(cAliasQ) > 0 ; (cAliasQ)->(dbCloseArea()) ; EndIf
    End Sequence
    ErrorBlock(bErr)

Return aRows

// =====================================================================================================================
//  CABECALHO -- CRIAR / ATUALIZAR
// =====================================================================================================================

/*/{Protheus.doc} ZsiCriar
Cria um sinistro (operacao "sinistroCriar") por RecLock direto, sem MVC.
Numeracao por GetSxeNum('TRH','TRH_NUMSIN') + ConfirmSX8 (mesma tecnica de
RTM003App). Sempre grava na filial da sessao (xFilial). Aceita, alem do
cabecalho, arrays opcionais {veiculos, testemunhas, vitimas} para a carga.
@type Static Function
@param oReq JsonObject, {sinistro:{...}, veiculos:[], testemunhas:[], vitimas:[]}
/*/
//=============================================================================================================================
Static Function ZsiCriar(oReq)

    Local oSin := oReq["sinistro"]
    Local aVei := IIf(ValType(oReq["veiculos"])    == "A", oReq["veiculos"],    {})
    Local aTes := IIf(ValType(oReq["testemunhas"]) == "A", oReq["testemunhas"], {})
    Local aVit := IIf(ValType(oReq["vitimas"])     == "A", oReq["vitimas"],     {})
    Local oR   := ZsiCriarCore(oSin, aVei, aTes, aVit)

    If !oR["success"]
        Return oR
    EndIf

Return ZsiMont(oR["numero"])

/*/{Protheus.doc} ZsiCriarCore
Nucleo da criacao de um sinistro por RecLock direto (sem MVC), reusado pela
tela (ZsiCriar) e pela importacao da planilha (ZsiImp). Numeracao por
GetSxeNum('TRH','TRH_NUMSIN') + ConfirmSX8. Sempre grava na filial da sessao.
@type Static Function
@param oSin JsonObject cabecalho; aVei/aTes/aVit arrays de filhas (podem ser {})
@return JsonObject, {success, numero, message}
/*/
//=============================================================================================================================
Static Function ZsiCriarCore(oSin, aVei, aTes, aVit)

    Local oResp   := JsonObject():New()
    Local cNumSin := ""
    Local cChvBem := ""
    Local oBem    := Nil
    Local cEvento := ""
    Local nX      := 0

    Default aVei := {}
    Default aTes := {}
    Default aVit := {}

    If oSin == Nil
        oResp["success"] := .F.
        oResp["message"] := "Objeto 'sinistro' nao informado"
        Return oResp
    EndIf

    If Empty(ZsiObjDate(oSin, "data"))
        oResp["success"] := .F.
        oResp["message"] := "Data do sinistro e obrigatoria"
        Return oResp
    EndIf

    // Bem: aceita codBem direto OU chave (placa/serie) para de-para via ST9
    cChvBem := ZsiObjStr(oSin, "codBem")
    If Empty(cChvBem)
        cChvBem := ZsiObjStr(oSin, "chaveBem")
    EndIf
    oBem := ZsiBemPorChave(cChvBem)
    If !oBem["achou"]
        oResp["success"] := .F.
        oResp["message"] := "Bem [" + cChvBem + "] nao encontrado no cadastro de frota (ST9, T9_CATBEM 2 ou 4)"
        Return oResp
    EndIf

    // Evento: usa o informado; senao deriva do tipo do bem (veiculo=1 / equipamento=3)
    cEvento := ZsiObjStr(oSin, "evento")
    If Empty(cEvento)
        cEvento := IIf(oBem["tipo"] == "V", "1", "3")
    EndIf

    cNumSin := GetSxeNum("TRH", "TRH_NUMSIN")

    RecLock("TRH", .T.)
        TRH->TRH_FILIAL := xFilial("TRH")
        TRH->TRH_NUMSIN := cNumSin
        TRH->TRH_DTACID := ZsiObjDate(oSin, "data")
        TRH->TRH_HRACID := ZsiDef(ZsiObjStr(oSin, "hora"), "00:00")
        TRH->TRH_EVENTO := cEvento
        TRH->TRH_CODBEM := oBem["codbem"]
        // TRH_NOMBEM nao e gravado -- e virtual (calculado de ST9 na leitura via X3_RELACAO)
        TRH->TRH_PLACA  := ZsiDef(oBem["placa"], ZsiObjStr(oSin, "placa"))
        TRH->TRH_GRAVID := ZsiDef(ZsiObjStr(oSin, "gravidade"), "1")
        TRH->TRH_TEMPO  := ZsiDef(ZsiObjStr(oSin, "tempo"), "1")
        TRH->TRH_VIA    := ZsiDef(ZsiObjStr(oSin, "via"), "1")
        TRH->TRH_PERIOD := ZsiDef(ZsiObjStr(oSin, "periodo"), "1")
        TRH->TRH_VIADIR := ZsiDef(ZsiObjStr(oSin, "maoDirecao"), "1")
        TRH->TRH_LOCAL  := ZsiDef(ZsiObjStr(oSin, "local"), "IMPORTADO PLANILHA")
        TRH->TRH_CIDACI := ZsiObjStr(oSin, "cidade")
        TRH->TRH_UFACID := ZsiDef(ZsiObjStr(oSin, "uf"), ZsiUFFilial())
        TRH->TRH_NUMBO  := ZsiObjStr(oSin, "numeroBO")
        TRH->TRH_NOMDP  := ZsiObjStr(oSin, "nomeDP")
        TRH->TRH_INTERR := ZsiDef(ZsiObjStr(oSin, "interrViagem"), "2")
        TRH->TRH_GUINCH := ZsiDef(ZsiObjStr(oSin, "necGuincho"), "2")
        TRH->TRH_CONDEL := ZsiDef(ZsiObjStr(oSin, "delitoConcret"), "2")
        TRH->TRH_TEREVA := ZsiDef(ZsiObjStr(oSin, "terceiroEvadiu"), "2")
        TRH->TRH_FLGDAN := "2"  // decisao 0.5: OS automatica sempre desligada nesta etapa
        TRH->TRH_STATUS := ZsiDef(ZsiObjStr(oSin, "status"), "01")
        TRH->TRH_DESCRI := ZsiTruncMemo("TRH_DESCRI", ZsiDef(ZsiObjStr(oSin, "descricao"), "Sinistro incluido pela tela frtsin001"))
        TRH->TRH_DTDIG  := dDataBase
        TRH->TRH_HRDIG  := Left(Time(), 5)
        ZsiSetIf("TRH", "TRH_ZCULPA", ZsiObjStr(oSin, "culpabilidade"))
        ZsiSetIf("TRH", "TRH_ZCLPNM", ZsiObjStr(oSin, "culpadoNome"))
        ZsiSetIf("TRH", "TRH_ZNRFOR", ZsiObjStr(oSin, "numeroFor"))
        ZsiSetIfN("TRH", "TRH_ZVLFOL", ZsiObjNum(oSin, "valorFolha"))
        ZsiSetIfN("TRH", "TRH_ZVLSLD", ZsiObjNum(oSin, "valorSaldo"))
        ZsiSetIf("TRH", "TRH_ZFONTE", ZsiDef(ZsiObjStr(oSin, "fonte"), "M"))
        ZsiSetIf("TRH", "TRH_ZIMPKEY", ZsiObjStr(oSin, "chaveImport"))
    TRH->(MsUnlock())

    ConfirmSX8()

    For nX := 1 To Len(aVei)
        ZsiGrvTRO(cNumSin, aVei[nX], "")
    Next nX
    For nX := 1 To Len(aTes)
        ZsiGrvTRN(cNumSin, aTes[nX], "")
    Next nX
    For nX := 1 To Len(aVit)
        ZsiGrvTRM(cNumSin, aVit[nX], "")
    Next nX

    oResp["success"] := .T.
    oResp["numero"]  := cNumSin

Return oResp

/*/{Protheus.doc} ZsiAtu
Atualiza o cabecalho de um sinistro (operacao "sinistroAtualizar"). So os
campos editaveis pela tela -- numeracao, digitacao e OS nao mudam.
@type Static Function
@param oReq JsonObject, {sinistro:{numero, ...}}
/*/
//=============================================================================================================================
Static Function ZsiAtu(oReq)

    Local oResp   := JsonObject():New()
    Local oSin    := oReq["sinistro"]
    Local cNumSin := ""
    Local nTamNum := TamSX3("TRH_NUMSIN")[1]

    If oSin == Nil
        oResp["success"] := .F.
        oResp["message"] := "Objeto 'sinistro' nao informado"
        Return oResp
    EndIf

    cNumSin := ZsiObjStr(oSin, "numero")
    If Empty(cNumSin)
        oResp["success"] := .F.
        oResp["message"] := "Numero do sinistro e obrigatorio"
        Return oResp
    EndIf

    TRH->(dbSetOrder(1))
    If !TRH->(dbSeek(xFilial("TRH") + PadR(cNumSin, nTamNum)))
        oResp["success"] := .F.
        oResp["message"] := "Sinistro [" + cNumSin + "] nao encontrado"
        Return oResp
    EndIf

    RecLock("TRH", .F.)
        If !Empty(ZsiObjStr(oSin, "data"))   ; TRH->TRH_DTACID := ZsiObjDate(oSin, "data")  ; EndIf
        If !Empty(ZsiObjStr(oSin, "hora"))   ; TRH->TRH_HRACID := ZsiObjStr(oSin, "hora")   ; EndIf
        If !Empty(ZsiObjStr(oSin, "evento")) ; TRH->TRH_EVENTO := ZsiObjStr(oSin, "evento") ; EndIf
        If !Empty(ZsiObjStr(oSin, "gravidade"))    ; TRH->TRH_GRAVID := ZsiObjStr(oSin, "gravidade")    ; EndIf
        If !Empty(ZsiObjStr(oSin, "tempo"))        ; TRH->TRH_TEMPO  := ZsiObjStr(oSin, "tempo")        ; EndIf
        If !Empty(ZsiObjStr(oSin, "via"))          ; TRH->TRH_VIA    := ZsiObjStr(oSin, "via")          ; EndIf
        If !Empty(ZsiObjStr(oSin, "periodo"))      ; TRH->TRH_PERIOD := ZsiObjStr(oSin, "periodo")      ; EndIf
        If !Empty(ZsiObjStr(oSin, "maoDirecao"))   ; TRH->TRH_VIADIR := ZsiObjStr(oSin, "maoDirecao")   ; EndIf
        If !Empty(ZsiObjStr(oSin, "local"))        ; TRH->TRH_LOCAL  := ZsiObjStr(oSin, "local")        ; EndIf
        TRH->TRH_CIDACI := ZsiObjStr(oSin, "cidade")
        If !Empty(ZsiObjStr(oSin, "uf"))           ; TRH->TRH_UFACID := ZsiObjStr(oSin, "uf")           ; EndIf
        TRH->TRH_NUMBO  := ZsiObjStr(oSin, "numeroBO")
        TRH->TRH_NOMDP  := ZsiObjStr(oSin, "nomeDP")
        If !Empty(ZsiObjStr(oSin, "interrViagem"))  ; TRH->TRH_INTERR := ZsiObjStr(oSin, "interrViagem")  ; EndIf
        If !Empty(ZsiObjStr(oSin, "necGuincho"))    ; TRH->TRH_GUINCH := ZsiObjStr(oSin, "necGuincho")    ; EndIf
        TRH->TRH_VALGUI := ZsiObjNum(oSin, "valorGuincho")
        If !Empty(ZsiObjStr(oSin, "delitoConcret")) ; TRH->TRH_CONDEL := ZsiObjStr(oSin, "delitoConcret") ; EndIf
        If !Empty(ZsiObjStr(oSin, "terceiroEvadiu")); TRH->TRH_TEREVA := ZsiObjStr(oSin, "terceiroEvadiu"); EndIf
        If !Empty(ZsiObjStr(oSin, "status"))        ; TRH->TRH_STATUS := ZsiObjStr(oSin, "status")        ; EndIf
        If !Empty(ZsiObjStr(oSin, "descricao"))     ; TRH->TRH_DESCRI := ZsiTruncMemo("TRH_DESCRI", ZsiObjStr(oSin, "descricao")) ; EndIf
        If !Empty(ZsiObjStr(oSin, "danosFrota"))    ; TRH->TRH_FLGDAN := ZsiObjStr(oSin, "danosFrota")    ; EndIf
        TRH->TRH_VALDAN := ZsiObjNum(oSin, "valorDanos")
        TRH->TRH_DANOS2 := ZsiTruncMemo("TRH_DANOS2", ZsiObjStr(oSin, "descDanos"))
        ZsiSetIf("TRH", "TRH_ZCULPA", ZsiObjStr(oSin, "culpabilidade"))
        ZsiSetIf("TRH", "TRH_ZCLPNM", ZsiObjStr(oSin, "culpadoNome"))
        ZsiSetIf("TRH", "TRH_ZNRFOR", ZsiObjStr(oSin, "numeroFor"))
        ZsiSetIfN("TRH", "TRH_ZVLFOL", ZsiObjNum(oSin, "valorFolha"))
        ZsiSetIfN("TRH", "TRH_ZVLSLD", ZsiObjNum(oSin, "valorSaldo"))
    TRH->(MsUnlock())

Return ZsiMont(cNumSin)

// =====================================================================================================================
//  FILHAS -- VEICULOS (TRO) / TESTEMUNHAS (TRN) / VITIMAS (TRM)
// =====================================================================================================================

/*/{Protheus.doc} ZsiVeiPut
Grava/atualiza um veiculo envolvido (operacao "veiculoSalvar").
@type Static Function
@param oReq JsonObject, {numero, veiculo:{seq?, ...}}
/*/
//=============================================================================================================================
Static Function ZsiVeiPut(oReq)

    Local cNumSin := ZsiReqStr(oReq, "numero")
    Local oVei    := oReq["veiculo"]

    If Empty(cNumSin) .Or. oVei == Nil
        Return ZsiErr("Informe 'numero' e 'veiculo'")
    EndIf
    If !ZsiExisteSin(cNumSin)
        Return ZsiErr("Sinistro [" + cNumSin + "] nao encontrado")
    EndIf

    ZsiGrvTRO(cNumSin, oVei, ZsiObjStr(oVei, "seq"))

Return ZsiMont(cNumSin)

/*/{Protheus.doc} ZsiVeiDel
Remove um veiculo envolvido (operacao "veiculoRemover").
@type Static Function
@param oReq JsonObject, {numero, seq}
/*/
//=============================================================================================================================
Static Function ZsiVeiDel(oReq)

    Local cNumSin := ZsiReqStr(oReq, "numero")
    Local cSeq    := ZsiReqStr(oReq, "seq")

    If Empty(cNumSin) .Or. Empty(cSeq)
        Return ZsiErr("Informe 'numero' e 'seq'")
    EndIf

    ZsiDelFilha("TRO", "TRO_NUMSIN", "TRO_SEQVEI", cNumSin, cSeq)

Return ZsiMont(cNumSin)

/*/{Protheus.doc} ZsiTesPut
Grava/atualiza uma testemunha (operacao "testemunhaSalvar").
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiTesPut(oReq)

    Local cNumSin := ZsiReqStr(oReq, "numero")
    Local oTes    := oReq["testemunha"]

    If Empty(cNumSin) .Or. oTes == Nil
        Return ZsiErr("Informe 'numero' e 'testemunha'")
    EndIf
    If !ZsiExisteSin(cNumSin)
        Return ZsiErr("Sinistro [" + cNumSin + "] nao encontrado")
    EndIf

    ZsiGrvTRN(cNumSin, oTes, ZsiObjStr(oTes, "seq"))

Return ZsiMont(cNumSin)

/*/{Protheus.doc} ZsiTesDel
Remove uma testemunha (operacao "testemunhaRemover").
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiTesDel(oReq)

    Local cNumSin := ZsiReqStr(oReq, "numero")
    Local cSeq    := ZsiReqStr(oReq, "seq")

    If Empty(cNumSin) .Or. Empty(cSeq)
        Return ZsiErr("Informe 'numero' e 'seq'")
    EndIf

    ZsiDelFilha("TRN", "TRN_NUMSIN", "TRN_SEQTES", cNumSin, cSeq)

Return ZsiMont(cNumSin)

/*/{Protheus.doc} ZsiVitPut
Grava/atualiza uma vitima (operacao "vitimaSalvar").
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiVitPut(oReq)

    Local cNumSin := ZsiReqStr(oReq, "numero")
    Local oVit    := oReq["vitima"]

    If Empty(cNumSin) .Or. oVit == Nil
        Return ZsiErr("Informe 'numero' e 'vitima'")
    EndIf
    If !ZsiExisteSin(cNumSin)
        Return ZsiErr("Sinistro [" + cNumSin + "] nao encontrado")
    EndIf

    ZsiGrvTRM(cNumSin, oVit, ZsiObjStr(oVit, "seq"))

Return ZsiMont(cNumSin)

/*/{Protheus.doc} ZsiVitDel
Remove uma vitima (operacao "vitimaRemover").
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiVitDel(oReq)

    Local cNumSin := ZsiReqStr(oReq, "numero")
    Local cSeq    := ZsiReqStr(oReq, "seq")

    If Empty(cNumSin) .Or. Empty(cSeq)
        Return ZsiErr("Informe 'numero' e 'seq'")
    EndIf

    ZsiDelFilha("TRM", "TRM_NUMSIN", "TRM_SEQVIT", cNumSin, cSeq)

Return ZsiMont(cNumSin)

// --- gravadores de filha (reusados por Put e pela carga) -----------------------------------------------------------

/*/{Protheus.doc} ZsiGrvTRO
Insere (cSeq vazio) ou altera (cSeq informado) um registro TRO.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiGrvTRO(cNumSin, oVei, cSeq)

    Local lInclui := Empty(cSeq)
    Local nTamNum := TamSX3("TRO_NUMSIN")[1]
    Local nTamSeq := TamSX3("TRO_SEQVEI")[1]

    If lInclui
        cSeq := ZsiNextSeq("TRO", "TRO_NUMSIN", "TRO_SEQVEI", cNumSin, 1)
    Else
        cSeq := PadR(cSeq, nTamSeq)
        TRO->(dbSetOrder(1))
        If !TRO->(dbSeek(xFilial("TRO") + PadR(cNumSin, nTamNum) + cSeq))
            lInclui := .T.
        EndIf
    EndIf

    RecLock("TRO", lInclui)
        TRO->TRO_FILIAL := xFilial("TRO")
        TRO->TRO_NUMSIN := PadR(cNumSin, nTamNum)
        TRO->TRO_SEQVEI := cSeq
        ZsiSetIf("TRO", "TRO_ZORIG",  ZsiDef(ZsiObjStr(oVei, "origem"), "2"))
        ZsiSetIf("TRO", "TRO_PLACA",  ZsiObjStr(oVei, "placa"))
        ZsiSetIf("TRO", "TRO_DESVEI", ZsiObjStr(oVei, "descricao"))
        ZsiSetIf("TRO", "TRO_MOTVEI", ZsiObjStr(oVei, "condutor"))
        ZsiSetIf("TRO", "TRO_ZMAT",   ZsiObjStr(oVei, "matricula"))
        ZsiSetIf("TRO", "TRO_CPF",    ZsiObjStr(oVei, "cpf"))
        ZsiSetIf("TRO", "TRO_CNHMOT", ZsiObjStr(oVei, "cnh"))
        ZsiSetIf("TRO", "TRO_TELMOT", ZsiObjStr(oVei, "telefone"))
        ZsiSetIf("TRO", "TRO_NOMPR",  ZsiDef(ZsiObjStr(oVei, "proprietario"), ZsiObjStr(oVei, "condutor")))
        ZsiSetIf("TRO", "TRO_DANOS",  ZsiObjStr(oVei, "danos"))
        ZsiSetIfN("TRO", "TRO_VALPRE", ZsiObjNum(oVei, "valorPrejuizo"))
        ZsiSetIfN("TRO", "TRO_VALTER", ZsiObjNum(oVei, "valorTerceiro"))
        ZsiSetIfN("TRO", "TRO_PERCEN", ZsiObjNum(oVei, "percentualGanho"))
        ZsiSetIf("TRO", "TRO_SEGUR",  ZsiObjStr(oVei, "segurado"))
        ZsiSetIf("TRO", "TRO_SEGCOR", ZsiObjStr(oVei, "seguradora"))
        ZsiSetIf("TRO", "TRO_APOLIC", ZsiObjStr(oVei, "apolice"))
    TRO->(MsUnlock())

Return

/*/{Protheus.doc} ZsiGrvTRN
Insere/altera um registro TRN (testemunha).
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiGrvTRN(cNumSin, oTes, cSeq)

    Local lInclui := Empty(cSeq)
    Local nTamNum := TamSX3("TRN_NUMSIN")[1]
    Local nTamSeq := TamSX3("TRN_SEQTES")[1]

    If lInclui
        cSeq := ZsiNextSeq("TRN", "TRN_NUMSIN", "TRN_SEQTES", cNumSin, 1)
    Else
        cSeq := PadR(cSeq, nTamSeq)
        TRN->(dbSetOrder(1))
        If !TRN->(dbSeek(xFilial("TRN") + PadR(cNumSin, nTamNum) + cSeq))
            lInclui := .T.
        EndIf
    EndIf

    RecLock("TRN", lInclui)
        TRN->TRN_FILIAL := xFilial("TRN")
        TRN->TRN_NUMSIN := PadR(cNumSin, nTamNum)
        TRN->TRN_SEQTES := cSeq
        ZsiSetIf("TRN", "TRN_NOMTES", ZsiObjStr(oTes, "nome"))
        ZsiSetIf("TRN", "TRN_TELTES", ZsiObjStr(oTes, "telefone"))
        ZsiSetIf("TRN", "TRN_ENDTES", ZsiObjStr(oTes, "endereco"))
        ZsiSetIf("TRN", "TRN_CIDTES", ZsiObjStr(oTes, "cidade"))
        ZsiSetIf("TRN", "TRN_UFTES",  ZsiObjStr(oTes, "uf"))
        ZsiSetIf("TRN", "TRN_TIPDOC", ZsiObjStr(oTes, "tipoDoc"))
        ZsiSetIf("TRN", "TRN_DOCTO",  ZsiObjStr(oTes, "documento"))
        ZsiSetIf("TRN", "TRN_QLFTES", ZsiDef(ZsiObjStr(oTes, "qualificacao"), "TESTEMUNHA"))
    TRN->(MsUnlock())

Return

/*/{Protheus.doc} ZsiGrvTRM
Insere/altera um registro TRM (vitima).
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiGrvTRM(cNumSin, oVit, cSeq)

    Local lInclui := Empty(cSeq)
    Local nTamNum := TamSX3("TRM_NUMSIN")[1]
    Local nTamSeq := TamSX3("TRM_SEQVIT")[1]

    If lInclui
        cSeq := ZsiNextSeq("TRM", "TRM_NUMSIN", "TRM_SEQVIT", cNumSin, 1)
    Else
        cSeq := PadR(cSeq, nTamSeq)
        TRM->(dbSetOrder(1))
        If !TRM->(dbSeek(xFilial("TRM") + PadR(cNumSin, nTamNum) + cSeq))
            lInclui := .T.
        EndIf
    EndIf

    RecLock("TRM", lInclui)
        TRM->TRM_FILIAL := xFilial("TRM")
        TRM->TRM_NUMSIN := PadR(cNumSin, nTamNum)
        TRM->TRM_SEQVIT := cSeq
        ZsiSetIf("TRM", "TRM_INDFUN", ZsiDef(ZsiObjStr(oVit, "funcionario"), "2"))
        ZsiSetIf("TRM", "TRM_MATVIT", ZsiObjStr(oVit, "matricula"))
        ZsiSetIf("TRM", "TRM_NOMVIT", ZsiObjStr(oVit, "nome"))
        ZsiSetIf("TRM", "TRM_TELVIT", ZsiObjStr(oVit, "telefone"))
        ZsiSetIf("TRM", "TRM_ENDVIT", ZsiObjStr(oVit, "endereco"))
        ZsiSetIf("TRM", "TRM_CIDVIT", ZsiObjStr(oVit, "cidade"))
        ZsiSetIf("TRM", "TRM_UFVIT",  ZsiObjStr(oVit, "uf"))
        ZsiSetIf("TRM", "TRM_LESOES", ZsiObjStr(oVit, "lesoes"))
        ZsiSetIf("TRM", "TRM_ACAO",   ZsiObjStr(oVit, "acaoTomada"))
        ZsiSetIf("TRM", "TRM_DESFUN", ZsiObjStr(oVit, "funcao"))
        ZsiSetIf("TRM", "TRM_FATAL",  ZsiDef(ZsiObjStr(oVit, "fatal"), "2"))
        ZsiSetIf("TRM", "TRM_CODVIT", ZsiObjStr(oVit, "condicao"))
        ZsiSetIfN("TRM", "TRM_VALVIT", ZsiObjNum(oVit, "valorVitima"))
    TRM->(MsUnlock())

Return

/*/{Protheus.doc} ZsiDelFilha
Exclui logicamente um registro de tabela-filha por chave FILIAL+NUMSIN+SEQ (ordem 1).
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiDelFilha(cAlias, cFldNum, cFldSeq, cNumSin, cSeq)

    Local nTamNum := TamSX3(cFldNum)[1]
    Local nTamSeq := TamSX3(cFldSeq)[1]

    dbSelectArea(cAlias)
    (cAlias)->(dbSetOrder(1))
    If (cAlias)->(dbSeek(xFilial(cAlias) + PadR(cNumSin, nTamNum) + PadR(cSeq, nTamSeq)))
        RecLock(cAlias, .F.)
            (cAlias)->(dbDelete())
        (cAlias)->(MsUnlock())
    EndIf

Return

// =====================================================================================================================
//  LOOKUPS
// =====================================================================================================================

/*/{Protheus.doc} ZsiLkBem
Lookup de bem de frota (operacao "lookupBem") -- ST9 com T9_CATBEM em ('2','4'),
por placa / serie / descricao / codigo. Limite 20 linhas.
@type Static Function
@param oReq JsonObject, {filtro}
@return JsonObject, {success, items:[{codigo,nome,placa,serie,catbem,tipo}]}
/*/
//=============================================================================================================================
Static Function ZsiLkBem(oReq)

    Local oResp   := JsonObject():New()
    Local aItens  := {}
    Local oItem   := Nil
    Local cAliasQ := GetNextAlias()
    Local cLike   := ZsiLikeAll(ZsiReqStr(oReq, "filtro"))
    Local nCount  := 0

    BeginSql Alias cAliasQ
        SELECT T9_CODBEM, T9_NOME, T9_PLACA, T9_SERIE, T9_CATBEM
          FROM %table:ST9% ST9
         WHERE ST9.%notDel%
           AND ST9.T9_FILIAL = %xfilial:ST9%
           AND ST9.T9_CATBEM IN ('2', '4')
           AND ( ST9.T9_CODBEM LIKE %exp:cLike%
              OR ST9.T9_PLACA  LIKE %exp:cLike%
              OR ST9.T9_SERIE  LIKE %exp:cLike%
              OR ST9.T9_NOME   LIKE %exp:cLike% )
         ORDER BY ST9.T9_NOME
    EndSql

    While (cAliasQ)->(!Eof()) .And. nCount < 20
        oItem := JsonObject():New()
        oItem["codigo"] := AllTrim((cAliasQ)->T9_CODBEM)
        oItem["nome"]   := AllTrim((cAliasQ)->T9_NOME)
        oItem["placa"]  := AllTrim((cAliasQ)->T9_PLACA)
        oItem["serie"]  := AllTrim((cAliasQ)->T9_SERIE)
        oItem["catbem"] := AllTrim((cAliasQ)->T9_CATBEM)
        oItem["tipo"]   := IIf(!Empty(AllTrim((cAliasQ)->T9_PLACA)), "V", "E")
        aAdd(aItens, oItem)
        nCount++
        (cAliasQ)->(dbSkip())
    EndDo
    (cAliasQ)->(dbCloseArea())

    oResp["success"] := .T.
    oResp["items"]   := aItens
    oResp["hasNext"] := .F.

Return oResp

/*/{Protheus.doc} ZsiLkFunc
Lookup de funcionario (operacao "lookupFuncionario") -- SRA por matricula/nome.
@type Static Function
@param oReq JsonObject, {filtro}
@return JsonObject, {success, items:[{matricula,nome,centroCusto}]}
/*/
//=============================================================================================================================
Static Function ZsiLkFunc(oReq)

    Local oResp   := JsonObject():New()
    Local aItens  := {}
    Local oItem   := Nil
    Local cAliasQ := GetNextAlias()
    Local cLike   := ZsiLikeAll(ZsiReqStr(oReq, "filtro"))
    Local nCount  := 0

    BeginSql Alias cAliasQ
        SELECT RA_MAT, RA_NOME, RA_CC
          FROM %table:SRA% SRA
         WHERE SRA.%notDel%
           AND SRA.RA_FILIAL = %xfilial:SRA%
           AND ( SRA.RA_MAT LIKE %exp:cLike% OR SRA.RA_NOME LIKE %exp:cLike% )
         ORDER BY SRA.RA_NOME
    EndSql

    While (cAliasQ)->(!Eof()) .And. nCount < 20
        oItem := JsonObject():New()
        oItem["matricula"]   := AllTrim((cAliasQ)->RA_MAT)
        oItem["nome"]        := AllTrim((cAliasQ)->RA_NOME)
        oItem["centroCusto"] := AllTrim((cAliasQ)->RA_CC)
        aAdd(aItens, oItem)
        nCount++
        (cAliasQ)->(dbSkip())
    EndDo
    (cAliasQ)->(dbCloseArea())

    oResp["success"] := .T.
    oResp["items"]   := aItens
    oResp["hasNext"] := .F.

Return oResp

/*/{Protheus.doc} ZsiLkDom
Lookup de dominio (operacao "lookupDominio"). Dominios fixos do dicionario
(evento, gravidade, tempo, via, periodo, viadir, simnao, culpa, fonte,
origveic, tpanexo) ou dinamicos por SX5 (status=SP, uf=12, tipoevento=AF,
causa=CX).
@type Static Function
@param oReq JsonObject, {dominio}
@return JsonObject, {success, items:[{valor,label}]}
/*/
//=============================================================================================================================
Static Function ZsiLkDom(oReq)

    Local oResp := JsonObject():New()
    Local cDom  := Lower(ZsiReqStr(oReq, "dominio"))

    Do Case
    Case cDom == "status"     ; oResp["items"] := ZsiSx5Items("SP")
    Case cDom == "uf"         ; oResp["items"] := ZsiSx5Items("12")
    Case cDom == "tipoevento" ; oResp["items"] := ZsiSx5Items("AF")
    Case cDom == "causa"      ; oResp["items"] := ZsiSx5Items("CX")
    OtherWise
        oResp["items"] := ZsiDomItems(cDom)
    EndCase

    oResp["success"] := .T.

Return oResp

/*/{Protheus.doc} ZsiImpSim
Simulacao da importacao da planilha "sinistros 2026.csv" (operacao
"sinistroImportarSimular"). Faz todo o parsing e o de-para (bem, culpabilidade,
status), classifica cada linha em Criar / Duplicada / Erro e devolve a previa
SEM gravar nada.
@type Static Function
@param oReq JsonObject, {conteudoBase64 | conteudo}
/*/
//=============================================================================================================================
Static Function ZsiImpSim(oReq)
Return ZsiImpProc(oReq, .F.)

/*/{Protheus.doc} ZsiImp
Efetivacao da importacao (operacao "sinistroImportar"). Mesmo parsing da
simulacao; grava as linhas classificadas como "Criar" via ZsiCriarCore
(cabecalho TRH + TRO Quebec/terceiro + TRN do TST). Idempotente por
TRH_ZIMPKEY -- reimportar o mesmo arquivo pula as linhas ja gravadas.
Linha com erro nao interrompe as demais (decisao 0.3).
@type Static Function
@param oReq JsonObject, {conteudoBase64 | conteudo}
/*/
//=============================================================================================================================
Static Function ZsiImp(oReq)
Return ZsiImpProc(oReq, .T.)

/*/{Protheus.doc} ZsiCfgParam
Executa a parametrizacao do dicionario (operacao "configParametrizar") --
chama U_MNT540Tab(.T.) que cria os campos custom nas tabelas TRH, TRO e TRI,
os codigos SX5 'SP' e os tipos de anexo na TRU. Idempotente. O ErrorBlock
temporario transforma erro de runtime em resposta JSON (nao em thread error).
@type Static Function
@param oReq JsonObject (sem parametros)
@return JsonObject, success + message + log (array)
/*/
//=============================================================================================================================
Static Function ZsiCfgParam(oReq)

    Local oResp := JsonObject():New()
    Local aLog  := {}
    Local oErr  := Nil
    Local bErr  := ErrorBlock({|e| Break(e)})

    Begin Sequence
        aLog := U_MNT540Tab(.T.)
        oResp["success"] := .T.
        oResp["message"] := "Parametrizacao executada com sucesso (" + AllTrim(Str(Len(aLog))) + " passos)."
        oResp["log"]     := aLog
    Recover Using oErr
        oResp["success"] := .F.
        oResp["message"] := "Falha na parametrizacao: " + ;
            IIf(ValType(oErr) == "O", AllTrim(oErr:Description), cValToChar(oErr))
        oResp["log"]     := aLog
    End Sequence

    ErrorBlock(bErr)

Return oResp

/*/{Protheus.doc} ZsiImpProc
Motor da importacao. lEfetiva=.F. simula, .T. grava.
@type Static Function
@return JsonObject, {success, efetivado, totalLinhas, resumo:{paraCriar,duplicadas,comErro,importadas}, linhas:[...], erros:[{linha,numeroFor,placa,motivo}], numeros:[...]}
/*/
//=============================================================================================================================
Static Function ZsiImpProc(oReq, lEfetiva)

    Local oResp   := JsonObject():New()
    Local cCsv    := ZsiImpConteudo(oReq)
    Local aLinTxt := {}
    Local aOut    := {}
    Local aErros  := {}
    Local aNums   := {}
    Local aC      := {}
    Local oPrev   := Nil
    Local oR      := Nil
    Local oErrRow := Nil
    Local nX      := 0
    Local nLinNum := 0
    Local nCriar  := 0
    Local nDup    := 0
    Local nErr    := 0
    Local nOk     := 0

    Default lEfetiva := .F.

    If Empty(cCsv)
        Return ZsiErr("Conteudo do arquivo nao informado (envie 'conteudoBase64' ou 'conteudo')")
    EndIf

    aLinTxt := ZsiCsvLinhas(cCsv)

    For nX := 1 To Len(aLinTxt)
        If Empty(AllTrim(aLinTxt[nX]))
            Loop
        EndIf
        aC := ZsiSplit(aLinTxt[nX], ";")
        If Upper(Left(AllTrim(ZsiCel(aC, 1)), 6)) == "NUMERO"
            Loop
        EndIf
        If Empty(AllTrim(ZsiCel(aC, 1))) .And. Empty(AllTrim(ZsiCel(aC, 2))) .And. Empty(AllTrim(ZsiCel(aC, 4)))
            Loop
        EndIf

        nLinNum++
        oPrev := ZsiImpLinha(aC, nLinNum)

        Do Case
        Case oPrev["acao"] == "Criar"     ; nCriar++
        Case oPrev["acao"] == "Duplicada" ; nDup++
        OtherWise                         ; nErr++
        EndCase

        If lEfetiva .And. oPrev["acao"] == "Criar"
            oR := ZsiCriarCore(ZsiImpSinObj(oPrev), ZsiImpVeiArr(oPrev), ZsiImpTesArr(oPrev), {})
            If oR["success"]
                oPrev["acao"]   := "Importada"
                oPrev["numero"] := oR["numero"]
                aAdd(aNums, oR["numero"])
                nOk++
            Else
                oPrev["acao"]   := "Erro"
                oPrev["motivo"] := oR["message"]
                nCriar--
                nErr++
            EndIf
        EndIf

        If oPrev["acao"] == "Erro"
            oErrRow := JsonObject():New()
            oErrRow["linha"]     := nLinNum
            oErrRow["numeroFor"] := oPrev["numeroFor"]
            oErrRow["placa"]     := oPrev["chaveBem"]
            oErrRow["motivo"]    := oPrev["motivo"]
            aAdd(aErros, oErrRow)
        EndIf

        aAdd(aOut, oPrev)
    Next nX

    oResp["success"]     := .T.
    oResp["efetivado"]   := lEfetiva
    oResp["totalLinhas"] := nLinNum
    oResp["resumo"]      := ZsiImpResumo(nCriar, nDup, nErr, nOk, lEfetiva)
    oResp["linhas"]      := aOut
    oResp["erros"]       := aErros
    If lEfetiva
        oResp["numeros"] := aNums
    EndIf

Return oResp

/*/{Protheus.doc} ZsiImpConteudo
Obtem o texto do CSV do oReq: prioriza 'conteudoBase64' (Decode64 -> bytes
CP1252, que sao o proprio texto no RPO) e cai para 'conteudo' (texto puro).
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiImpConteudo(oReq)
    Local cB64 := ZsiReqStr(oReq, "conteudoBase64")
    If !Empty(cB64)
        Return Decode64(cB64)
    EndIf
Return ZsiReqStr(oReq, "conteudo")

/*/{Protheus.doc} ZsiImpLinha
Monta a previa de UMA linha do CSV. Nao grava. Classifica em acao =
Criar / Duplicada / Erro (+ motivo).
Colunas (1-based): 1=NrFOR 2=Data 3=Unidade(ignora) 4=Placa/Serie 5=CarroQuebec
6=CondutorQuebec 7=Matricula 8=CpfTerceiro 9=MotoristaTerceiro 10=PlacaTerceiro
11=Culpabilidade 12=TST 13=ValorTerceiro 14=AcidenteInterno(vazio) 15=EmFolha
16=SaldoDescontar 17=Status 18=Observacao
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiImpLinha(aC, nLin)

    Local oP     := JsonObject():New()
    Local cFor   := ZsiCel(aC, 1)
    Local cDtTx  := ZsiCel(aC, 2)
    Local dData  := ZsiParseData(cDtTx)
    Local cChv   := ZsiCel(aC, 4)
    Local cCondQ := ZsiCel(aC, 6)
    Local cMatr  := ZsiCel(aC, 7)
    Local cCpfT  := ZsiCel(aC, 8)
    Local cMotT  := ZsiCel(aC, 9)
    Local cPlaT  := ZsiCel(aC, 10)
    Local cCulTx := ZsiCel(aC, 11)
    Local cTst   := ZsiCel(aC, 12)
    Local cStsTx := ZsiCel(aC, 17)
    Local cObs   := ZsiCel(aC, 18)
    Local oBem   := ZsiBemPorChave(cChv)
    Local oCul   := ZsiClassCulpa(cCulTx, cCondQ, cMotT)
    Local cEvento:= IIf(oBem["tipo"] == "V", "1", "3")
    Local cKey   := ZsiImpKey(cFor, dData, cChv, cCpfT)

    oP["linha"]              := nLin
    oP["numeroFor"]          := cFor
    oP["dataTexto"]          := cDtTx
    oP["data"]               := IIf(Empty(dData), "", ZsiJDate(dData))
    oP["chaveBem"]           := cChv
    oP["codBem"]             := oBem["codbem"]
    oP["nomeBem"]            := oBem["nome"]
    oP["placa"]              := oBem["placa"]
    oP["tipoBem"]            := oBem["tipo"]
    oP["evento"]             := cEvento
    oP["eventoLabel"]        := ZsiDomLabel("evento", cEvento)
    oP["carroQuebec"]        := ZsiCel(aC, 5)
    oP["condutorQuebec"]     := cCondQ
    oP["matricula"]          := cMatr
    oP["cpfTerceiro"]        := cCpfT
    oP["motoristaTerceiro"]  := cMotT
    oP["placaTerceiro"]      := cPlaT
    oP["culpaTexto"]         := cCulTx
    oP["culpabilidade"]      := oCul["codigo"]
    oP["culpabilidadeLabel"] := ZsiDomLabel("culpa", oCul["codigo"])
    oP["culpadoNome"]        := oCul["nome"]
    oP["tst"]                := cTst
    oP["valorTerceiro"]      := ZsiParseMoeda(ZsiCel(aC, 13))
    oP["valorFolha"]         := ZsiParseMoeda(ZsiCel(aC, 15))
    oP["valorSaldo"]         := ZsiParseMoeda(ZsiCel(aC, 16))
    oP["statusTexto"]        := cStsTx
    oP["status"]             := ZsiDeParaStatus(cStsTx)
    oP["statusLabel"]        := ZsiSx5Desc("SP", ZsiDeParaStatus(cStsTx))
    oP["observacao"]         := cObs
    oP["chaveImport"]        := cKey
    oP["numero"]             := ""
    oP["motivo"]             := ""

    Do Case
    Case Empty(dData)
        oP["acao"]   := "Erro"
        oP["motivo"] := "Data invalida: [" + cDtTx + "]"
    Case !oBem["achou"]
        oP["acao"]   := "Erro"
        oP["motivo"] := "Bem nao encontrado na frota (ST9): [" + cChv + "]"
    Case ZsiJaImportado(cKey)
        oP["acao"]   := "Duplicada"
        oP["motivo"] := "Ja importado anteriormente (mesma chave)"
    OtherWise
        oP["acao"]   := "Criar"
    EndCase

Return oP

/*/{Protheus.doc} ZsiImpSinObj
Monta o objeto 'sinistro' para o ZsiCriarCore a partir da previa de uma linha.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiImpSinObj(oP)
    Local oSin := JsonObject():New()
    oSin["data"]          := oP["data"]
    oSin["codBem"]        := oP["codBem"]
    oSin["evento"]        := oP["evento"]
    oSin["local"]         := "IMPORTADO PLANILHA"
    oSin["descricao"]     := ZsiDef(oP["observacao"], "Importado da planilha sinistros 2026")
    oSin["status"]        := oP["status"]
    oSin["culpabilidade"] := oP["culpabilidade"]
    oSin["culpadoNome"]   := oP["culpadoNome"]
    oSin["numeroFor"]     := oP["numeroFor"]
    oSin["valorFolha"]    := oP["valorFolha"]
    oSin["valorSaldo"]    := oP["valorSaldo"]
    oSin["fonte"]         := "I"
    oSin["chaveImport"]   := oP["chaveImport"]
Return oSin

/*/{Protheus.doc} ZsiImpVeiArr
Monta o array de veiculos (TRO) da linha: sempre o veiculo Quebec (seq 001);
o do terceiro (seq 002) so quando ha placa ou CPF de terceiro.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiImpVeiArr(oP)
    Local aVei := {}
    Local oVQ  := JsonObject():New()
    Local oVT  := Nil

    oVQ["origem"]    := "1"
    oVQ["placa"]     := oP["placa"]
    oVQ["descricao"] := oP["carroQuebec"]
    oVQ["condutor"]  := oP["condutorQuebec"]
    oVQ["matricula"] := oP["matricula"]
    aAdd(aVei, oVQ)

    If !Empty(oP["placaTerceiro"]) .Or. !Empty(oP["cpfTerceiro"])
        oVT := JsonObject():New()
        oVT["origem"]        := "2"
        oVT["placa"]         := oP["placaTerceiro"]
        oVT["condutor"]      := oP["motoristaTerceiro"]
        oVT["proprietario"]  := oP["motoristaTerceiro"]
        oVT["cpf"]           := oP["cpfTerceiro"]
        oVT["valorTerceiro"] := oP["valorTerceiro"]
        oVT["danos"]         := "1"
        aAdd(aVei, oVT)
    EndIf

Return aVei

/*/{Protheus.doc} ZsiImpTesArr
Monta o array de testemunhas (TRN) da linha -- so o TST, quando preenchido.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiImpTesArr(oP)
    Local aTes := {}
    Local oT   := Nil
    If !Empty(oP["tst"])
        oT := JsonObject():New()
        oT["nome"]         := oP["tst"]
        oT["qualificacao"] := "TST"
        aAdd(aTes, oT)
    EndIf
Return aTes

/*/{Protheus.doc} ZsiImpResumo
Bloco de contadores da importacao.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiImpResumo(nCriar, nDup, nErr, nOk, lEfetiva)
    Local oR := JsonObject():New()
    oR["paraCriar"]   := nCriar   // linhas prontas para criar (simulacao)
    oR["duplicadas"]  := nDup
    oR["comErro"]     := nErr
    oR["importadas"]  := IIf(lEfetiva, nOk, 0)
Return oR

/*/{Protheus.doc} ZsiJaImportado
.T. se ja existe um sinistro na filial da sessao com este TRH_ZIMPKEY.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiJaImportado(cKey)

    Local cAliasQ := GetNextAlias()
    Local lAchou  := .F.
    Local bErr    := ErrorBlock({|e| Break(e)})

    If Empty(cKey)
        ErrorBlock(bErr)
        Return .F.
    EndIf

    // Se a coluna TRH_ZIMPKEY ainda nao existe (parametrizacao nao rodada), nao ha
    // como checar duplicidade -- assume nao importado e segue (o ZsiSetIf de
    // TRH_ZIMPKEY na gravacao tambem e protegido).
    Begin Sequence
        BeginSql Alias cAliasQ
            SELECT TRH_NUMSIN
              FROM %table:TRH% TRH
             WHERE TRH.%notDel%
               AND TRH.TRH_FILIAL  = %xfilial:TRH%
               AND TRH.TRH_ZIMPKEY = %exp:cKey%
        EndSql
        lAchou := (cAliasQ)->(!Eof())
        (cAliasQ)->(dbCloseArea())
    Recover
        lAchou := .F.
        If Select(cAliasQ) > 0
            (cAliasQ)->(dbCloseArea())
        EndIf
    End Sequence

    ErrorBlock(bErr)

Return lAchou

/*/{Protheus.doc} ZsiImpKey
Chave de idempotencia de uma linha da planilha (MD5 hex, cabe em C(40)).
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiImpKey(cFor, dData, cChv, cCpf)
    Local cRaw := AllTrim(cFor) + "|" + DToS(dData) + "|" + ;
                  Upper(ZsiNormChave(cChv)) + "|" + ZsiDigitos(cCpf)
Return Left(MD5(cRaw, 2), 40)

/*/{Protheus.doc} ZsiClassCulpa
Classifica o texto livre da coluna CULPABILIDADE em {codigo, nome}. Ver
regra em frotas/sinistro/dicionario.md e CRONOGRAMA.md (secao 4.3).
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiClassCulpa(cTxt, cCondQ, cMotT)

    Local oR := JsonObject():New()
    Local cU := Upper(ZsiSemAcento(AllTrim(cTxt)))

    oR["codigo"] := "9"
    oR["nome"]   := AllTrim(cTxt)

    Do Case
    Case Empty(cU)
        oR["codigo"] := "9"
    Case cU == "QUEBEC"
        oR["codigo"] := "2"
        oR["nome"]   := "QUEBEC"
    Case cU == "TERCEIRO"
        oR["codigo"] := "1"
        oR["nome"]   := AllTrim(cMotT)
    Case cU == "FORCA MAIOR" .Or. cU == "NAO TEM"
        oR["codigo"] := "4"
    Case !Empty(cCondQ) .And. cU == Upper(ZsiSemAcento(AllTrim(cCondQ)))
        oR["codigo"] := "3"
        oR["nome"]   := AllTrim(cCondQ)
    Case !Empty(cMotT) .And. cU == Upper(ZsiSemAcento(AllTrim(cMotT)))
        oR["codigo"] := "1"
        oR["nome"]   := AllTrim(cMotT)
    EndCase

Return oR

/*/{Protheus.doc} ZsiDeParaStatus
Converte o texto da coluna STATUS da planilha para o codigo SX5 'SP'.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiDeParaStatus(cTxt)
    Local cU := Upper(ZsiSemAcento(AllTrim(cTxt)))
    Do Case
    Case Empty(cU)                  ; Return "01"
    Case "TERMO DE ACORDO" $ cU     ; Return "05"
    Case cU == "FINALIZADO"         ; Return "06"
    Case cU == "CANCELADO"          ; Return "07"
    Case "INQUERITO" $ cU           ; Return "03"
    Case "JURIDICO" $ cU            ; Return "04"
    Case "DOCUMENTACAO" $ cU        ; Return "02"
    EndCase
Return "01"

/*/{Protheus.doc} ZsiParseData
Converte "dd/mm/aaaa" (ou dd-mm-aa) em Date. CToD("") se invalida.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiParseData(cTxt)

    Local cT   := AllTrim(cTxt)
    Local aP   := {}
    Local cDia := ""
    Local cMes := ""
    Local cAno := ""
    Local nD   := 0
    Local nM   := 0

    cT := StrTran(cT, ".", "/")
    cT := StrTran(cT, "-", "/")
    aP := ZsiSplit(cT, "/")
    If Len(aP) < 3
        Return CToD("")
    EndIf

    cDia := AllTrim(aP[1])
    cMes := AllTrim(aP[2])
    cAno := AllTrim(aP[3])
    If Len(cAno) == 2
        cAno := "20" + cAno
    EndIf
    nD := Val(cDia)
    nM := Val(cMes)
    If nD < 1 .Or. nD > 31 .Or. nM < 1 .Or. nM > 12 .Or. Val(cAno) < 1900
        Return CToD("")
    EndIf

Return SToD(StrZero(Val(cAno), 4) + StrZero(nM, 2) + StrZero(nD, 2))

/*/{Protheus.doc} ZsiParseMoeda
Converte " R$ 5.271,80 " / " R$ -   " / "" em numerico.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiParseMoeda(cTxt)

    Local cN := Upper(AllTrim(cTxt))

    cN := StrTran(cN, "R$", "")
    cN := StrTran(cN, " ", "")
    cN := StrTran(cN, Chr(9), "")
    cN := StrTran(cN, ".", "")
    cN := StrTran(cN, ",", ".")
    If Empty(cN) .Or. cN == "-"
        Return 0
    EndIf

Return Val(cN)

/*/{Protheus.doc} ZsiCsvLinhas
Quebra o texto do CSV em linhas (normaliza CRLF/CR/LF).
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiCsvLinhas(cCsv)
    Local cN := cCsv
    cN := StrTran(cN, Chr(13) + Chr(10), Chr(10))
    cN := StrTran(cN, Chr(13), Chr(10))
Return ZsiSplit(cN, Chr(10))

/*/{Protheus.doc} ZsiSplit
Split que PRESERVA campos vazios (StrTokArr descarta) -- essencial para CSV
delimitado por ';'.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiSplit(cStr, cDelim)

    Local aOut := {}
    Local nPos := 0
    Local nLen := Len(cDelim)

    Do While .T.
        nPos := At(cDelim, cStr)
        If nPos == 0
            aAdd(aOut, cStr)
            Exit
        EndIf
        aAdd(aOut, SubStr(cStr, 1, nPos - 1))
        cStr := SubStr(cStr, nPos + nLen)
    EndDo

Return aOut

/*/{Protheus.doc} ZsiCel
Celula n (1-based) de um array de campos, trim; "" se fora do intervalo.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiCel(aC, n)
Return IIf(n >= 1 .And. n <= Len(aC), AllTrim(aC[n]), "")

/*/{Protheus.doc} ZsiDigitos
So os digitos de um texto (para CPF).
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiDigitos(cTxt)
    Local cOut := ""
    Local nX   := 0
    Local cCh  := ""
    For nX := 1 To Len(cTxt)
        cCh := SubStr(cTxt, nX, 1)
        If cCh >= "0" .And. cCh <= "9"
            cOut += cCh
        EndIf
    Next nX
Return cOut

/*/{Protheus.doc} ZsiSemAcento
Remove acentuacao (bytes CP1252) para comparacao de texto livre.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiSemAcento(cTxt)

    Local aMap := { {231, "c"}, {199, "C"}, {227, "a"}, {195, "A"}, {225, "a"}, {193, "A"}, ;
                    {224, "a"}, {192, "A"}, {226, "a"}, {194, "A"}, {233, "e"}, {201, "E"}, ;
                    {234, "e"}, {202, "E"}, {232, "e"}, {200, "E"}, {237, "i"}, {205, "I"}, ;
                    {243, "o"}, {211, "O"}, {245, "o"}, {213, "O"}, {244, "o"}, {212, "O"}, ;
                    {250, "u"}, {218, "U"}, {252, "u"}, {220, "U"}, {249, "u"}, {217, "U"} }
    Local nX := 0

    For nX := 1 To Len(aMap)
        cTxt := StrTran(cTxt, Chr(aMap[nX][1]), aMap[nX][2])
    Next nX

Return cTxt

// =====================================================================================================================
//  HELPERS
// =====================================================================================================================

/*/{Protheus.doc} ZsiErr
Monta um JsonObject de erro padrao {success:.F., message}.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiErr(cMsg)
    Local oResp := JsonObject():New()
    oResp["success"] := .F.
    oResp["message"] := cMsg
Return oResp

/*/{Protheus.doc} ZsiReqStr
Le uma chave caractere do oReq de forma segura.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiReqStr(oReq, cKey)
    Local xVal := oReq[cKey]
Return IIf(ValType(xVal) == "C", AllTrim(xVal), "")

/*/{Protheus.doc} ZsiReqDate
Le uma chave data (ISO 'AAAA-MM-DD') do oReq. Devolve CToD("") se vazia/invalida.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiReqDate(oReq, cKey)
    Local cVal := ZsiReqStr(oReq, cKey)
    If Empty(cVal)
        Return CToD("")
    EndIf
Return SToD(StrTran(cVal, "-", ""))

/*/{Protheus.doc} ZsiObjStr
Le uma chave caractere de um sub-objeto Json.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiObjStr(oObj, cKey)
    Local xVal := Nil
    If oObj == Nil
        Return ""
    EndIf
    xVal := oObj[cKey]
    Do Case
    Case ValType(xVal) == "C" ; Return AllTrim(xVal)
    Case ValType(xVal) == "N" ; Return AllTrim(Str(xVal))
    EndCase
Return ""

/*/{Protheus.doc} ZsiObjNum
Le uma chave numerica de um sub-objeto Json (aceita numero ou string numerica).
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiObjNum(oObj, cKey)
    Local xVal := Nil
    If oObj == Nil
        Return 0
    EndIf
    xVal := oObj[cKey]
    Do Case
    Case ValType(xVal) == "N" ; Return xVal
    Case ValType(xVal) == "C" ; Return Val(StrTran(AllTrim(xVal), ",", "."))
    EndCase
Return 0

/*/{Protheus.doc} ZsiObjDate
Le uma chave data (ISO) de um sub-objeto Json.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiObjDate(oObj, cKey)
    Local cVal := ZsiObjStr(oObj, cKey)
    If Empty(cVal) .Or. Len(cVal) < 8
        Return CToD("")
    EndIf
Return SToD(StrTran(cVal, "-", ""))

/*/{Protheus.doc} ZsiDef
Devolve cVal se nao vazio, senao cDefault.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiDef(cVal, cDefault)
Return IIf(Empty(AllTrim(cVal)), cDefault, cVal)

/*/{Protheus.doc} ZsiLikeAll
Monta o argumento LIKE que casa tudo quando o filtro vem vazio (idioma de
RTM003App: "%'%" + filtro + "%'%").
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiLikeAll(cFiltro)
Return "%'%" + AllTrim(cFiltro) + "%'%"

/*/{Protheus.doc} ZsiJDate
Converte data para "AAAA-MM-DD" (ou "" se vazia).
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiJDate(xData)
    Local cS := ""
    If ValType(xData) == "D"
        If Empty(xData)
            Return ""
        EndIf
        cS := DToS(xData)
        Return SubStr(cS, 1, 4) + "-" + SubStr(cS, 5, 2) + "-" + SubStr(cS, 7, 2)
    EndIf
    If ValType(xData) == "C" .And. Len(AllTrim(xData)) == 8
        cS := AllTrim(xData)
        Return SubStr(cS, 1, 4) + "-" + SubStr(cS, 5, 2) + "-" + SubStr(cS, 7, 2)
    EndIf
Return ""

/*/{Protheus.doc} ZsiSetIf
RecLock ja aberto: grava cValor no campo cCampo do alias cAlias, so se o campo
existir no dicionario deste ambiente (protege campos de usuario ainda nao criados).
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiSetIf(cAlias, cCampo, cValor)
    If (cAlias)->(FieldPos(cCampo)) > 0
        (cAlias)->(FieldPut(FieldPos(cCampo), cValor))
    EndIf
Return

/*/{Protheus.doc} ZsiSetIfN
Igual a ZsiSetIf, para campo numerico.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiSetIfN(cAlias, cCampo, nValor)
    If (cAlias)->(FieldPos(cCampo)) > 0
        (cAlias)->(FieldPut(FieldPos(cCampo), nValor))
    EndIf
Return

/*/{Protheus.doc} ZsiSFldTrh
Le um campo caractere da TRH posicionada, protegido por FieldPos + ErrorBlock
(campo custom pode existir no SX3 mas ainda nao na tabela fisica).
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiSFldTrh(cCampo)
    Local xRet := ""
    Local bErr := ErrorBlock({|e| Break(e)})
    Begin Sequence
        If TRH->(FieldPos(cCampo)) > 0
            xRet := TRH->(FieldGet(FieldPos(cCampo)))
        EndIf
    Recover
        xRet := ""
    End Sequence
    ErrorBlock(bErr)
Return IIf(ValType(xRet) == "C", AllTrim(xRet), "")

/*/{Protheus.doc} ZsiNFldTrh
Le um campo numerico da TRH posicionada, protegido por FieldPos + ErrorBlock.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiNFldTrh(cCampo)
    Local xRet := 0
    Local bErr := ErrorBlock({|e| Break(e)})
    Begin Sequence
        If TRH->(FieldPos(cCampo)) > 0
            xRet := TRH->(FieldGet(FieldPos(cCampo)))
        EndIf
    Recover
        xRet := 0
    End Sequence
    ErrorBlock(bErr)
Return IIf(ValType(xRet) == "N", xRet, 0)

/*/{Protheus.doc} ZsiTruncMemo
Trunca um texto ao tamanho do campo (evita erro ao gravar memo curto por
Replace direto -- textos longos ficam para tratamento MSMM na Fase D).
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiTruncMemo(cCampo, cTexto)
    Local nTam := TamSX3(cCampo)[1]
Return Left(AllTrim(cTexto), nTam)

/*/{Protheus.doc} ZsiExisteSin
.T. se o sinistro existe na filial da sessao.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiExisteSin(cNumSin)
    Local nTamNum := TamSX3("TRH_NUMSIN")[1]
    TRH->(dbSetOrder(1))
Return TRH->(dbSeek(xFilial("TRH") + PadR(cNumSin, nTamNum)))

/*/{Protheus.doc} ZsiTemArea
.T. se a tabela existe/abre neste ambiente.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiTemArea(cAlias)
    If Select(cAlias) == 0
        ChkFile(cAlias)
    EndIf
Return Select(cAlias) > 0

/*/{Protheus.doc} ZsiNextSeq
Proxima sequencia livre de uma tabela-filha (chave FILIAL+NUMSIN, ordem nOrder).
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiNextSeq(cAlias, cFldNum, cFldSeq, cNumSin, nOrder)

    Local aArea  := GetArea()
    Local nMax   := 0
    Local nTamN  := TamSX3(cFldNum)[1]
    Local nTamS  := TamSX3(cFldSeq)[1]
    Local cKey   := xFilial(cAlias) + PadR(cNumSin, nTamN)

    dbSelectArea(cAlias)
    (cAlias)->(dbSetOrder(nOrder))
    If (cAlias)->(dbSeek(cKey))
        While !(cAlias)->(Eof()) .And. ;
              xFilial(cAlias) + (cAlias)->(FieldGet(FieldPos(cFldNum))) == cKey
            nMax := Max(nMax, Val((cAlias)->(FieldGet(FieldPos(cFldSeq)))))
            (cAlias)->(dbSkip())
        EndDo
    EndIf
    RestArea(aArea)

Return StrZero(nMax + 1, nTamS)

/*/{Protheus.doc} ZsiUFFilial
UF da filial corrente (SM0 -> M0_ESTENT / M0_ESTADO).
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiUFFilial()
    Local cUF := ""
    Local aArea := SM0->(GetArea())
    SM0->(dbSetOrder(1))
    If SM0->(dbSeek(cEmpAnt + cFilAnt))
        cUF := AllTrim(SM0->M0_ESTENT)
        If Empty(cUF) .And. SM0->(FieldPos("M0_ESTADO")) > 0
            cUF := AllTrim(SM0->M0_ESTADO)
        EndIf
    EndIf
    RestArea(aArea)
Return cUF

/*/{Protheus.doc} ZsiNomeBem
Descricao do bem (T9_NOME) a partir do codigo -- substitui a leitura do campo
virtual TRH_NOMBEM, que nao tem coluna fisica.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiNomeBem(cCod)
    Local cC := AllTrim(cCod)
    If Empty(cC)
        Return ""
    EndIf
Return AllTrim(Posicione("ST9", 1, xFilial("ST9") + PadR(cC, TamSX3("T9_CODBEM")[1]), "T9_NOME"))

/*/{Protheus.doc} ZsiBemPorChave
De-para de bem: recebe codigo do bem OU placa OU numero de serie, procura na
ST9 (T9_CATBEM em '2','4') e devolve {achou, codbem, nome, placa, serie, tipo}
com tipo 'V' (veiculo -- tem placa) ou 'E' (equipamento -- so serie).
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiBemPorChave(cChave)

    Local oBem    := JsonObject():New()
    Local cAliasQ := GetNextAlias()
    Local cNorm   := ZsiNormChave(cChave)
    Local cLike   := "%'%" + cNorm + "%'%"

    oBem["achou"]  := .F.
    oBem["codbem"] := ""
    oBem["nome"]   := ""
    oBem["placa"]  := ""
    oBem["serie"]  := ""
    oBem["tipo"]   := "V"

    If Empty(cNorm)
        Return oBem
    EndIf

    // Traz candidatos por LIKE amplo (placa/serie/codigo) e faz o casamento exato em
    // memoria com a chave normalizada -- evita depender de REPLACE()/funcao de string
    // especifica do banco e cobre placas gravadas com mascara ("ABC-1234").
    BeginSql Alias cAliasQ
        SELECT T9_CODBEM, T9_NOME, T9_PLACA, T9_SERIE
          FROM %table:ST9% ST9
         WHERE ST9.%notDel%
           AND ST9.T9_CATBEM IN ('2', '4')
           AND ( ST9.T9_PLACA  LIKE %exp:cLike%
              OR ST9.T9_SERIE  LIKE %exp:cLike%
              OR ST9.T9_CODBEM LIKE %exp:cLike% )
         ORDER BY ST9.T9_FILIAL
    EndSql

    While (cAliasQ)->(!Eof())
        If ZsiNormChave((cAliasQ)->T9_PLACA)  == cNorm .Or. ;
           ZsiNormChave((cAliasQ)->T9_SERIE)  == cNorm .Or. ;
           ZsiNormChave((cAliasQ)->T9_CODBEM) == cNorm
            oBem["achou"]  := .T.
            oBem["codbem"] := AllTrim((cAliasQ)->T9_CODBEM)
            oBem["nome"]   := AllTrim((cAliasQ)->T9_NOME)
            oBem["placa"]  := AllTrim((cAliasQ)->T9_PLACA)
            oBem["serie"]  := AllTrim((cAliasQ)->T9_SERIE)
            oBem["tipo"]   := IIf(!Empty(AllTrim((cAliasQ)->T9_PLACA)), "V", "E")
            Exit
        EndIf
        (cAliasQ)->(dbSkip())
    EndDo
    (cAliasQ)->(dbCloseArea())

Return oBem

/*/{Protheus.doc} ZsiNormChave
Normaliza placa/serie: remove espacos, ponto, traco e barra; caixa alta.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiNormChave(cChave)
    Local cOut := Upper(AllTrim(cChave))
    cOut := StrTran(cOut, " ", "")
    cOut := StrTran(cOut, ".", "")
    cOut := StrTran(cOut, "-", "")
    cOut := StrTran(cOut, "/", "")
Return cOut

/*/{Protheus.doc} ZsiSx5Desc
Descricao de um item de SX5 (cTabela+cChave) ou "" se nao existir.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiSx5Desc(cTabela, cChave)
    Local cRet := ""
    Local bErr := ErrorBlock({|e| Break(e)})
    Begin Sequence
        If !Empty(AllTrim(cChave))
            // Posicione em SX5 ordem 1 = X5_FILIAL+X5_TABELA+X5_CHAVE (mesmo padrao de
            // RTM003App). X5Descri() exigia SX5 posicionada e estourava "Alias does not exist".
            // Campos padronizados no tamanho do dicionario para casar a chave do indice.
            cRet := AllTrim(Posicione("SX5", 1, ;
                xFilial("SX5") + PadR(cTabela, TamSX3("X5_TABELA")[1]) + ;
                PadR(AllTrim(cChave), TamSX3("X5_CHAVE")[1]), "X5_DESCRI"))
        EndIf
    Recover
        cRet := ""
    End Sequence
    ErrorBlock(bErr)
Return cRet

/*/{Protheus.doc} ZsiSx5Items
Lista de itens de uma tabela de SX5 -> [{valor,label}].
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiSx5Items(cTabela)

    Local aItens  := {}
    Local oItem   := Nil
    Local cAliasQ := GetNextAlias()

    BeginSql Alias cAliasQ
        SELECT X5_CHAVE, X5_DESCRI
          FROM %table:SX5% SX5
         WHERE SX5.%notDel%
           AND SX5.X5_FILIAL = %xfilial:SX5%
           AND SX5.X5_TABELA = %exp:cTabela%
         ORDER BY X5_CHAVE
    EndSql

    While (cAliasQ)->(!Eof())
        oItem := JsonObject():New()
        oItem["valor"] := AllTrim((cAliasQ)->X5_CHAVE)
        oItem["label"] := AllTrim((cAliasQ)->X5_DESCRI)
        aAdd(aItens, oItem)
        (cAliasQ)->(dbSkip())
    EndDo
    (cAliasQ)->(dbCloseArea())

Return aItens

/*/{Protheus.doc} ZsiDomItems
Itens dos dominios fixos do dicionario -> [{valor,label}].
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiDomItems(cDom)

    Local aPares := ZsiDomPares(cDom)
    Local aItens := {}
    Local oItem  := Nil
    Local nX     := 0

    For nX := 1 To Len(aPares)
        oItem := JsonObject():New()
        oItem["valor"] := aPares[nX][1]
        oItem["label"] := aPares[nX][2]
        aAdd(aItens, oItem)
    Next nX

Return aItens

/*/{Protheus.doc} ZsiDomLabel
Rotulo de um valor de dominio fixo (ou o proprio valor se nao mapeado).
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiDomLabel(cDom, cValor)

    Local aPares := ZsiDomPares(cDom)
    Local nX     := 0

    If Empty(cValor)
        Return ""
    EndIf
    For nX := 1 To Len(aPares)
        If aPares[nX][1] == cValor
            Return aPares[nX][2]
        EndIf
    Next nX

Return cValor

/*/{Protheus.doc} ZsiDomPares
Tabela fixa {valor,label} de cada dominio do dicionario. Espelha
frotas/sinistro/dicionario.md e o SX3 real da TRH.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiDomPares(cDom)

    Local aP := {}

    Do Case
    Case cDom == "evento"
        aP := { {"1","Acidente"}, {"2","Roubo"}, {"3","Incidente"} }
    Case cDom == "gravidade"
        aP := { {"1","Leve"}, {"2","Medio"}, {"3","Grave"}, {"4","Gravissimo"} }
    Case cDom == "tempo"
        aP := { {"1","Bom"}, {"2","Chuvoso"}, {"3","Neblina"}, {"4","Nublado"} }
    Case cDom == "via"
        aP := { {"1","Reta"}, {"2","Curva"}, {"3","Cruzamento"}, {"4","Estrada de Terra"} }
    Case cDom == "periodo"
        aP := { {"1","Manha"}, {"2","Noite"}, {"3","Tarde"}, {"4","Madrugada"} }
    Case cDom == "viadir"
        aP := { {"1","Unica"}, {"2","Dupla"} }
    Case cDom == "simnao"
        aP := { {"1","Sim"}, {"2","Nao"} }
    Case cDom == "culpa"
        aP := { {"1","Terceiro"}, {"2","Empresa"}, {"3","Funcionario"}, {"4","Forca Maior / Sem Culpa"}, {"9","A Apurar"} }
    Case cDom == "fonte"
        aP := { {"I","Importacao"}, {"M","Manual"} }
    Case cDom == "origveic"
        aP := { {"1","Quebec"}, {"2","Terceiro"} }
    Case cDom == "tpanexo"
        aP := { {"1","Foto"}, {"2","Termo"}, {"3","Contrato"}, {"4","BO"}, {"5","Nota Fiscal"}, {"9","Outros"} }
    EndCase

Return aP
