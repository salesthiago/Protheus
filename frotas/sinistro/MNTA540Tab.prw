#INCLUDE "TOTVS.CH"
#INCLUDE "PROTHEUS.CH"

/*/{Protheus.doc} MNT540Tab
Cria os campos de usuario, os codigos da tabela SX5 'SP' (status do processo do
sinistro) e, opcionalmente, os tipos de anexo na TRU, necessarios para o app
hibrido de Sinistros de Frota (frtsin001 / MNTA540App.prw).

Espelha 1:1 o arquivo frotas/sinistro/dicionario.md. Alternativa: importar aquele
dicionario pelo Configurador em vez de rodar esta funcao.

Duas formas de rodar:
  - Direto, com o modulo Gestao de Frotas (95) aberto:  U_MNT540Tab()
  - Pela tela de Configuracao do frtsin001 (operacao "configParametrizar" ->
    ZsiCfgParam em MNTA540App.prw chama U_MNT540Tab(.T.))

Idempotente: campos/registros que ja existem sao ignorados.

@type User Function
@param lSilent Logico, .T. nao exibe MsgInfo no fim (chamada pelo canal/headless)
@return Array de caractere, log linha a linha do que foi feito
@author Quebec Ambiental
@since 2026-09-03
/*/
//=============================================================================================================================
USER FUNCTION MNT540Tab(lSilent)

    Local lCriaTRU := .T.   // .F. desliga a criacao dos tipos de documento na TRU
    Local nX       := 0
    Local aSX3     := {}
    Local aSX5     := {}
    Local aTRU     := {}
    Local aLog     := {}

    Default lSilent := .F.

    // ---------------------------------------------------------------------------------------------------------
    // 1) Campos de usuario  { cAlias, cCampo, cTipo, nTam, nDec, cTitulo, cDescric, cPicture, cValid, cF3, cCombo, cWhen, cIniBrw }
    // ---------------------------------------------------------------------------------------------------------
    aAdd(aSX3, {"TRH", "TRH_ZCULPA", "C",  1, 0, "Culpabilid.",  "Culpabilidade do sinistro",                         "@!",                     "", "", "1=Terceiro;2=Empresa;3=Funcionario;4=Forca Maior/Sem Culpa;9=A Apurar", "", "N"})
    aAdd(aSX3, {"TRH", "TRH_ZCLPNM", "C", 60, 0, "Nome Culpado", "Nome do responsavel apontado como culpado",         "@!",                     "", "", "",                                                                     "", "N"})
    aAdd(aSX3, {"TRH", "TRH_ZNRFOR", "C",  6, 0, "Nr. FOR",      "Numero do FOR na planilha de origem",                "@!",                     "", "", "",                                                                     "", "N"})
    aAdd(aSX3, {"TRH", "TRH_ZVLFOL", "N", 14, 2, "Vlr. Folha",   "Valor lancado em folha (somente registro)",          "@E 99,999,999,999.99",   "", "", "",                                                                     "", "N"})
    aAdd(aSX3, {"TRH", "TRH_ZVLSLD", "N", 14, 2, "Vlr. Saldo",   "Saldo a descontar (somente registro)",               "@E 99,999,999,999.99",   "", "", "",                                                                     "", "N"})
    aAdd(aSX3, {"TRH", "TRH_ZIMPKEY","C", 40, 0, "Chave Import", "Hash da linha de origem (idempotencia da importacao)","@!",                     "", "", "",                                                                     "", "S"})
    aAdd(aSX3, {"TRH", "TRH_ZFONTE", "C",  1, 0, "Origem Reg.",  "Origem do registro",                                 "@!",                     "", "", "I=Importacao;M=Manual",                                                 "", "N"})

    aAdd(aSX3, {"TRO", "TRO_ZORIG",  "C",  1, 0, "Orig. Veic.",  "Origem do veiculo envolvido",                        "@!",                     "", "",     "1=Quebec;2=Terceiro",                                               "", "N"})
    aAdd(aSX3, {"TRO", "TRO_ZMAT",   "C",  6, 0, "Matr. Cond.",  "Matricula do condutor quando funcionario Quebec",    "@!",                     "", "SRA", "",                                                    "M->TRO_ZORIG=='1'", "N"})

    aAdd(aSX3, {"TRI", "TRI_ZTIPO",  "C",  1, 0, "Tp. Anexo",    "Tipo do anexo",                                      "@!",                     "", "", "1=Foto;2=Termo;3=Contrato;4=BO;5=Nota Fiscal;9=Outros",                 "", "N"})
    aAdd(aSX3, {"TRI", "TRI_ZARQ",   "C",100, 0, "Arquivo",      "Nome do arquivo original",                           "@!",                     "", "", "",                                                                     "", "N"})
    aAdd(aSX3, {"TRI", "TRI_ZPATH",  "C",254, 0, "Caminho",      "Caminho no servidor (\\sinistros\\anexos\\...)",     "@!",                     "", "", "",                                                                     "", "S"})
    aAdd(aSX3, {"TRI", "TRI_ZMIME",  "C", 40, 0, "Mime",         "Content-type do arquivo",                            "@!",                     "", "", "",                                                                     "", "N"})
    aAdd(aSX3, {"TRI", "TRI_ZTAM",   "N", 12, 0, "Tam. Bytes",   "Tamanho em bytes (limite 100 MB = 104857600)",       "@E 999,999,999,999",     "", "", "",                                                                     "", "N"})

    // ---------------------------------------------------------------------------------------------------------
    // 2) SX5 - tabela 'SP' (Status do Processo do Sinistro)
    // ---------------------------------------------------------------------------------------------------------
    aAdd(aSX5, {"01", "ABERTURA"})
    aAdd(aSX5, {"02", "AGUARDANDO DOCUMENTACAO"})
    aAdd(aSX5, {"03", "ABERTURA DE INQUERITO"})
    aAdd(aSX5, {"04", "JURIDICO"})
    aAdd(aSX5, {"05", "NEGOCIACAO"})
    aAdd(aSX5, {"06", "ARQUIVADO"})
    aAdd(aSX5, {"07", "CANCELADO"})

    // ---------------------------------------------------------------------------------------------------------
    // 3) TRU - tipos de documento de anexo (opcional, para TRI_CODDOC)
    // ---------------------------------------------------------------------------------------------------------
    aAdd(aTRU, {"000001", "FOTO DO ACIDENTE"})
    aAdd(aTRU, {"000002", "TERMO"})
    aAdd(aTRU, {"000003", "CONTRATO"})
    aAdd(aTRU, {"000004", "BOLETIM DE OCORRENCIA"})
    aAdd(aTRU, {"000005", "NOTA FISCAL"})

    ZsiTLog(aLog, Replicate("=", 60))
    ZsiTLog(aLog, "MNT540Tab - inicio - " + DToC(Date()) + " " + Time())

    // --- SX3 -------------------------------------------------------------------------------------------------
    For nX := 1 To Len(aSX3)
        AjSX3(aLog, aSX3[nX][1], aSX3[nX][2], aSX3[nX][3], aSX3[nX][4], aSX3[nX][5], ;
              aSX3[nX][6], aSX3[nX][7], aSX3[nX][8], aSX3[nX][9], aSX3[nX][10], ;
              aSX3[nX][11], aSX3[nX][12], aSX3[nX][13])
    Next nX

    // Materializa as colunas novas no banco
    X31UpdTable("TRH")
    X31UpdTable("TRO")
    X31UpdTable("TRI")
    ZsiTLog(aLog, "MNT540Tab - X31UpdTable TRH/TRO/TRI ok")

    // --- SX5 -------------------------------------------------------------------------------------------------
    For nX := 1 To Len(aSX5)
        AjSX5(aLog, aSX5[nX][1], aSX5[nX][2])
    Next nX

    // --- TRU ------------------------------------------------------------------------------------------------
    If lCriaTRU
        If Select("TRU") == 0
            ChkFile("TRU")
        EndIf
        If Select("TRU") > 0
            For nX := 1 To Len(aTRU)
                AjTRU(aLog, aTRU[nX][1], aTRU[nX][2])
            Next nX
        Else
            ZsiTLog(aLog, "MNT540Tab - AVISO: tabela TRU nao encontrada, tipos de anexo nao criados")
        EndIf
    EndIf

    ZsiTLog(aLog, "MNT540Tab - fim - " + Time())
    ZsiTLog(aLog, Replicate("=", 60))

    If !lSilent .And. !IsBlind()
        MsgInfo("Dicionario de Sinistros de Frota atualizado." + CRLF + ;
                "Verifique o log para detalhes.", "MNT540Tab")
    EndIf

RETURN aLog

/*/{Protheus.doc} ZsiTLog
Registra uma linha no log (array por referencia) e tambem no console.
@type Static Function
/*/
//=============================================================================================================================
Static Function ZsiTLog(aLog, cMsg)
    aAdd(aLog, cMsg)
    ConOut(cMsg)
RETURN

/*/{Protheus.doc} AjSX3
Cria um campo de usuario no SX3 se ainda nao existir. X3_PROPRI='U', X3_CONTEXT='R'.
@type Static Function
/*/
//=============================================================================================================================
Static Function AjSX3(aLog, cAlias, cCampo, cTipo, nTam, nDec, cTitulo, cDescric, cPicture, cValid, cF3, cCombo, cWhen, cIniBrw)

    Local aArea   := GetArea()
    Local nOrdem  := 0
    Local nTamCpo := TamSX3("X3_CAMPO")[1]
    Local nTamOrd := TamSX3("X3_ORDEM")[1]

    dbSelectArea("SX3")

    SX3->(dbSetOrder(2))  // X3_CAMPO
    If SX3->(dbSeek(PadR(cCampo, nTamCpo)))
        ZsiTLog(aLog, "  SX3 " + cCampo + " ja existe - ignorado")
        RestArea(aArea)
        Return
    EndIf

    // proxima ordem livre do arquivo
    SX3->(dbSetOrder(1))  // X3_ARQUIVO
    If SX3->(dbSeek(cAlias))
        While !SX3->(Eof()) .And. SX3->X3_ARQUIVO == cAlias
            nOrdem := Max(nOrdem, Val(SX3->X3_ORDEM))
            SX3->(dbSkip())
        EndDo
    EndIf
    nOrdem++

    RecLock("SX3", .T.)
        SX3->X3_ARQUIVO := cAlias
        SX3->X3_ORDEM   := StrZero(nOrdem, nTamOrd)
        SX3->X3_CAMPO   := PadR(cCampo, nTamCpo)
        SX3->X3_TIPO    := cTipo
        SX3->X3_TAMANHO := nTam
        SX3->X3_DECIMAL := nDec
        SX3->X3_TITULO  := cTitulo
        SX3->X3_TITSPA  := cTitulo
        SX3->X3_TITENG  := cTitulo
        SX3->X3_DESCRIC := cDescric
        SX3->X3_DESCSPA := cDescric
        SX3->X3_DESCENG := cDescric
        SX3->X3_PICTURE := cPicture
        SX3->X3_VALID   := cValid
        SX3->X3_F3      := cF3
        SX3->X3_CBOX    := cCombo
        SX3->X3_CBOXSPA := cCombo
        SX3->X3_CBOXENG := cCombo
        SX3->X3_WHEN    := cWhen
        SX3->X3_CONTEXT := "R"
        SX3->X3_PROPRI  := "U"
        SX3->X3_NIVEL   := 1
        SX3->X3_VISUAL  := "A"
        SX3->X3_INIBRW  := IIf(Empty(cIniBrw), "N", cIniBrw)
        SX3->X3_PYME    := "S"
        If SX3->(FieldPos("X3_MODAL")) > 0 ; SX3->X3_MODAL := "N" ; EndIf
        If SX3->(FieldPos("X3_BROWSE")) > 0 ; SX3->X3_BROWSE := "S" ; EndIf
    MsUnlock()

    ZsiTLog(aLog, "  SX3 " + cCampo + " criado (ordem " + StrZero(nOrdem, nTamOrd) + ")")
    RestArea(aArea)

RETURN

/*/{Protheus.doc} AjSX5
Cria/atualiza um registro da SX5 via PutSx5 (upsert). Tabela fixa 'SP'.
@type Static Function
/*/
//=============================================================================================================================
Static Function AjSX5(aLog, cChave, cDescric)

    PutSx5("SP", cChave, cDescric, cDescric, cDescric)
    ZsiTLog(aLog, "  SX5 SP/" + cChave + " = " + cDescric)

RETURN

/*/{Protheus.doc} AjTRU
Cria um tipo de documento na TRU se ainda nao existir.
@type Static Function
/*/
//=============================================================================================================================
Static Function AjTRU(aLog, cCod, cNom)

    Local aArea   := GetArea()
    Local nTamCod := TamSX3("TRU_CODDOC")[1]

    dbSelectArea("TRU")
    TRU->(dbSetOrder(1))  // TRU_FILIAL + TRU_CODDOC
    If TRU->(dbSeek(xFilial("TRU") + PadR(cCod, nTamCod)))
        ZsiTLog(aLog, "  TRU " + cCod + " ja existe - ignorado")
        RestArea(aArea)
        Return
    EndIf

    RecLock("TRU", .T.)
        TRU->TRU_FILIAL := xFilial("TRU")
        TRU->TRU_CODDOC := PadR(cCod, nTamCod)
        TRU->TRU_NOMDOC := cNom
        If TRU->(FieldPos("TRU_TIPEVE")) > 0 ; TRU->TRU_TIPEVE := "1" ; EndIf
    MsUnlock()

    ZsiTLog(aLog, "  TRU " + cCod + " = " + cNom)
    RestArea(aArea)

RETURN
