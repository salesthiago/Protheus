#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "fileio.ch"

/*/{Protheus.doc} RT69M001
Exporta os itens da planilha de contrato (CNB) para arquivo CSV,
com validacao dos campos obrigatorios para geracao de medicao.
Campos validados por linha: CNB_ITEM, CNB_PRODUT, CNB_QUANT (> 0), CNB_VLUNIT (> 0).
@type User Function
@author
@since
@version 2
@history
/*/
//=============================================================================================================================
    User Function RT69M001()
//=============================================================================================================================

    Local lConfirm  := .F.
    Local aLogErros := {}
    Local aCliFor   := {}
    Local cCampos   := ""
    Private cAliasCNB := GetNextAlias()
    Private QbLinha   := Chr(13)+Chr(10)

    While .T.
        If GetPerg()
            lConfirm := .T.
            Exit
        Else
            If MsgNoYes("Foi detectado o cancelamento do preenchimento dos parametros. Deseja realmente sair da Exportacao do Arquivo (Sim / Nao)?","Atencao !!!")
                Return Nil
            EndIf
        EndIf
    End

    If !lConfirm
        Return Nil
    EndIf

    // --- Fase 1: Validacao dos dados (interativa com o usuario) ---

    If !BuscaCNB()
        MsgStop("Nao foram encontrados itens de planilha para este contrato.", "Atencao")
        Return Nil
    EndIf

    aLogErros := ValidaCNB()

    If Len(aLogErros) > 0
        If !MostraErros(aLogErros)
            (cAliasCNB)->(DbCloseArea())
            Return Nil
        EndIf
    EndIf

    aCliFor := BuscaCNA()

    If Empty(aCliFor[1])
        (cAliasCNB)->(DbCloseArea())
        MsgStop("Nao foi encontrado fornecedor/cliente vinculado ao contrato.", "Atencao")
        Return Nil
    EndIf

    If Alltrim(CN9->CN9_ESPCTR) == "1"
        cCampos := "CN9_NUMERO;CN9_REVATU;CN9_COMPET;CNE_NUMERO;CNE_ITEM;CNE_PRODUT;CNE_DESCRI;CNE_UM;CNE_QUANT;CNE_CC;CNE_ITEMCT;CNE_CLVL;CNE_VLUNIT;CND_FORNEC;CND_LJFORN;SALDO_ITEM"
    Else
        cCampos := "CN9_NUMERO;CN9_REVATU;CN9_COMPET;CNE_NUMERO;CNE_ITEM;CNE_PRODUT;CNE_DESCRI;CNE_UM;CNE_QUANT;CNE_CC;CNE_ITEMCT;CNE_CLVL;CNE_VLUNIT;CND_CLIENT;CND_LOJACL;SALDO_ITEM"
    EndIf

    // --- Fase 2: Geracao do arquivo ---

    (cAliasCNB)->(DbGoTop())
    FWMsgRun(, {|| GeraArq(aCliFor, cCampos)}, "Geracao do Arquivo (Medicoes)", "Gerando arquivo para medicao ...")
Return Nil

/*/{Protheus.doc} GeraArq
Cria o arquivo CSV com os itens validados da planilha (CNB).
Linhas com campos criticos invalidos sao ignoradas na exportacao.
@type Static Function
@param aCliFor Array, {cCodigo, cLoja} do fornecedor ou cliente do contrato
@param cCampos String, Cabecalho CSV com os nomes dos campos exportados
/*/
//=============================================================================================================================
    Static Function GeraArq(aCliFor, cCampos)
//=============================================================================================================================

    Local cArquivo  := "Contrato_" + StrTran(StrTran(Alltrim(CN9->CN9_NUMERO), "/", "_"), "\", "_") + ".csv"
    Local cCaminho  := Alltrim(MV_PAR01)
    Local cSrvFile  := ""
    Local cConteudo := ""
    Local aQtdMed   := {}
    Local nQtdMed   := 0
    Local nSaldoIt  := 0

    // Saldo por item = quantidade planejada na planilha (CNB_QUANT) menos o que ja
    // foi medido em medicoes anteriores (SUM de CNE_QUANT) para o mesmo item+produto -
    // carregado uma unica vez para nao rodar uma query por linha do loop abaixo.
    aQtdMed := CarregaQtdMedida(Alltrim(CN9->CN9_NUMERO), Alltrim(CN9->CN9_REVISA))

    If ".CSV" $ Upper(cCaminho)
        MsgStop("Informe apenas a pasta de destino. Exemplo: C:\TOTVS. O nome do arquivo ser� gerado automaticamente.", "Aten��o")
        Return Nil
    EndIf

    If Right(cCaminho, 1) == "\"
        cCaminho := Left(cCaminho, Len(cCaminho)-1)
    EndIf

    cConteudo := cCampos + QbLinha

    (cAliasCNB)->(DbGoTop())
    While !(cAliasCNB)->(Eof())
        If !LinhaInvalida()
            nQtdMed  := QtdJaMedida(aQtdMed, Alltrim((cAliasCNB)->CNB_ITEM), Alltrim((cAliasCNB)->CNB_PRODUT))
            nSaldoIt := (cAliasCNB)->CNB_QUANT - nQtdMed

            // Campos tipo codigo sao protegidos com TxtExcel() para o Excel nao
            // interpretar como numero/data e descartar zeros a esquerda ao salvar
            // novamente como CSV. CNB_QUANT/CNB_VLUNIT/SALDO_ITEM ficam como numero
            // puro mesmo, pois o usuario edita esses valores como numero na planilha.
            cConteudo += TxtExcel(Alltrim(CN9->CN9_NUMERO))               + ";" + ;
                         TxtExcel(Alltrim(CN9->CN9_REVISA))               + ";" + ;
                         TxtExcel(Dtos(DDataBase))                        + ";" + ;
                         TxtExcel(Alltrim((cAliasCNB)->CNB_NUMERO))       + ";" + ;
                         TxtExcel(Alltrim((cAliasCNB)->CNB_ITEM))         + ";" + ;
                         TxtExcel(Alltrim((cAliasCNB)->CNB_PRODUT))       + ";" + ;
                         Alltrim((cAliasCNB)->CNB_DESCRI)                 + ";" + ;
                         TxtExcel(Alltrim((cAliasCNB)->CNB_UM))           + ";" + ;
                         Alltrim(cValToChar((cAliasCNB)->CNB_QUANT))      + ";" + ;
                         TxtExcel(Alltrim((cAliasCNB)->CNB_CC))           + ";" + ;
                         TxtExcel(Alltrim((cAliasCNB)->CNB_ITEMCT))       + ";" + ;
                         TxtExcel(Alltrim((cAliasCNB)->CNB_CLVL))         + ";" + ;
                         Alltrim(cValToChar((cAliasCNB)->CNB_VLUNIT))     + ";" + ;
                         TxtExcel(Alltrim(aCliFor[1]))                    + ";" + ;
                         TxtExcel(Alltrim(aCliFor[2]))                    + ";" + ;
                         Alltrim(cValToChar(nSaldoIt))                    + QbLinha
        EndIf
        (cAliasCNB)->(DbSkip())
    End

    (cAliasCNB)->(DbCloseArea())

    cSrvFile := "\system\" + cArquivo

    MemoWrit(cSrvFile, cConteudo)

    If CpyS2t(cSrvFile, cCaminho, .T.)
        MsgInfo("O arquivo " + cArquivo + " foi gerado com sucesso no diretorio " + cCaminho, "Atencao")
    Else
        MsgStop("Falha ao copiar o arquivo para a pasta selecionada: " + cCaminho, "Atencao")
    EndIf

    FErase(cSrvFile)
Return Nil

/*/{Protheus.doc} CarregaQtdMedida
Carrega, de uma unica vez, a quantidade ja medida (SUM de CNE_QUANT) em medicoes
anteriores para cada combinacao item+produto do contrato/revisao informados.
@type Static Function
@param cContrato String, Numero do contrato (CN9_NUMERO)
@param cRevisao  String, Revisao do contrato (CN9_REVISA)
@return Array, {{cItem, cProduto, nQtdMedida}, ...}
/*/
//====================================================================================================
    Static Function CarregaQtdMedida(cContrato, cRevisao)
//====================================================================================================
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
item+produto especifico.
@type Static Function
@param aQtdMed Array, Retorno de CarregaQtdMedida
@param cItem   String, Codigo do item (CNB_ITEM)
@param cProduto String, Codigo do produto (CNB_PRODUT)
@return Numeric, Quantidade ja medida (0 se nunca medido)
/*/
//====================================================================================================
    Static Function QtdJaMedida(aQtdMed, cItem, cProduto)
//====================================================================================================
    Local nPos := AScan(aQtdMed, {|x| x[1] == cItem .And. x[2] == cProduto})
Return If(nPos > 0, aQtdMed[nPos][3], 0)

/*/{Protheus.doc} ValidaCNB
Percorre todos os registros do alias cAliasCNB validando os campos obrigatorios
para geracao de medicao. Deixa o alias posicionado no primeiro registro ao final.
Campos verificados: CNB_ITEM (nao vazio), CNB_PRODUT (nao vazio),
                    CNB_QUANT (> 0), CNB_VLUNIT (> 0).
@type Static Function
@return Array, Lista de descricoes de erro por linha (vazio se todos validos)
/*/
//=============================================================================================================================
    Static Function ValidaCNB()
//=============================================================================================================================

    Local aLog   := {}
    Local nLinha := 0
    Local cRef   := ""
    Local cErro  := ""

    (cAliasCNB)->(DbGoTop())

    While !(cAliasCNB)->(Eof())
        nLinha += 1
        cRef   := "Linha " + StrZero(nLinha, 3) + " | Item: " + Alltrim((cAliasCNB)->CNB_ITEM) + " | Prod: " + Alltrim((cAliasCNB)->CNB_PRODUT)
        cErro  := ""

        If Empty(Alltrim((cAliasCNB)->CNB_ITEM))
            cErro += "   - ITEM (CNB_ITEM) em branco" + Chr(10)
        EndIf
        If Empty(Alltrim((cAliasCNB)->CNB_PRODUT))
            cErro += "   - PRODUTO (CNB_PRODUT) em branco" + Chr(10)
        EndIf
        If (cAliasCNB)->CNB_QUANT <= 0
            cErro += "   - QUANTIDADE (CNB_QUANT) deve ser maior que zero" + Chr(10)
        EndIf
        If (cAliasCNB)->CNB_VLUNIT <= 0
            cErro += "   - VALOR UNITARIO (CNB_VLUNIT) deve ser maior que zero" + Chr(10)
        EndIf

        If !Empty(cErro)
            AAdd(aLog, cRef + ":" + Chr(10) + cErro)
        EndIf

        (cAliasCNB)->(DbSkip())
    End

    (cAliasCNB)->(DbGoTop())
Return aLog

/*/{Protheus.doc} LinhaInvalida
Verifica se a linha atual do alias cAliasCNB possui campos criticos ausentes.
Usada dentro do loop de escrita para ignorar linhas que o usuario optou por manter
mesmo com pendencias.
@type Static Function
@return logical, .T. se a linha deve ser ignorada na exportacao
/*/
//=============================================================================================================================
    Static Function LinhaInvalida()
//=============================================================================================================================
Return (Empty(Alltrim((cAliasCNB)->CNB_ITEM))   .Or. ;
        Empty(Alltrim((cAliasCNB)->CNB_PRODUT))  .Or. ;
        (cAliasCNB)->CNB_QUANT  <= 0             .Or. ;
        (cAliasCNB)->CNB_VLUNIT <= 0)

/*/{Protheus.doc} MostraErros
Exibe resumo das pendencias de validacao e pergunta ao usuario se deseja
prosseguir exportando apenas as linhas validas.
Mostra no maximo 10 erros detalhados; demais sao contabilizados no rodape.
@type Static Function
@param aLog Array, Lista de mensagens de erro geradas por ValidaCNB
@return logical, .T. se o usuario optar por continuar com as linhas validas
/*/
//=============================================================================================================================
    Static Function MostraErros(aLog)
//=============================================================================================================================

    Local cMsg    := ""
    Local nI      := 0
    Local nExibe  := If(Len(aLog) > 10, 10, Len(aLog))

    cMsg := "Foram encontradas pendencias em " + cValToChar(Len(aLog)) + " linha(s) da planilha:" + Chr(10) + Chr(10)

    For nI := 1 To nExibe
        cMsg += aLog[nI] + Chr(10)
    Next nI

    If Len(aLog) > 10
        cMsg += "... e mais " + cValToChar(Len(aLog) - 10) + " linha(s) com pendencias." + Chr(10)
    EndIf

    cMsg += Chr(10) + "As linhas invalidas serao IGNORADAS na exportacao." + Chr(10)
    cMsg += "Deseja continuar exportando apenas as linhas validas?"
Return MsgNoYes(cMsg, "Pendencias na Planilha - Atencao")

/*/{Protheus.doc} BuscaCNB
Abre query na tabela CNB filtrando pelo contrato e revisao correntes (CN9).
Popula o alias privado cAliasCNB. Fecha o alias e retorna .F. se sem registros.
@type Static Function
@return logical, .T. se ha itens de planilha; .F. se nenhum registro encontrado
/*/
//=============================================================================================================================
    Static Function BuscaCNB()
//=============================================================================================================================

    Local cQuery := ""

    cQuery := " SELECT CNB.* "
    cQuery += " FROM "  + RetSqlName("CNB") + " CNB "
    cQuery += " WHERE CNB.D_E_L_E_T_ = ' ' "
    cQuery += " AND CNB_FILIAL = '" + FWXFilial("CNB") + "' "
    cQuery += " AND CNB_CONTRA = '" + Alltrim(CN9->CN9_NUMERO) + "' "
    cQuery += " AND CNB_REVISA = '" + Alltrim(CN9->CN9_REVISA) + "' "
    cQuery := ChangeQuery(cQuery)

    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAliasCNB, .F., .T.)
    (cAliasCNB)->(DbGoTop())

    If (cAliasCNB)->(Eof())
        (cAliasCNB)->(DbCloseArea())
        Return .F.
    EndIf
Return .T.

/*/{Protheus.doc} BuscaCNA
Busca o codigo e loja do fornecedor ou cliente vinculado ao contrato (tabela CNA).
Prioriza CNA_FORNEC; se vazio, usa CNA_CLIENT.
@type Static Function
@return Array, {cCodigo, cLoja} - string vazia se nao encontrado
/*/
//=============================================================================================================================
    Static Function BuscaCNA()
//=============================================================================================================================

    Local cQuery    := ""
    Local cAliasCNA := GetNextAlias()
    Local cCliFor   := ""
    Local cLjClFor  := ""

    cQuery := " SELECT CNA_FORNEC, CNA_LJFORN, CNA_CLIENT, CNA_LOJACL "
    cQuery += " FROM " + RetSqlName("CNA") + " CNA "
    cQuery += " WHERE CNA.D_E_L_E_T_ = ' ' "
    cQuery += " AND (CNA_FORNEC <> ' ' OR CNA_CLIENT <> ' ') "
    cQuery += " AND CNA_FILIAL = '" + FWXFilial("CNA") + "' "
    cQuery += " AND CNA_CONTRA = '" + Alltrim(CN9->CN9_NUMERO) + "' "
    cQuery := ChangeQuery(cQuery)

    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAliasCNA, .F., .T.)
    (cAliasCNA)->(DbGoTop())

    If !(cAliasCNA)->(Eof())
        If Empty(Alltrim((cAliasCNA)->CNA_FORNEC))
            cCliFor  := Alltrim((cAliasCNA)->CNA_CLIENT)
            cLjClFor := Alltrim((cAliasCNA)->CNA_LOJACL)
        Else
            cCliFor  := Alltrim((cAliasCNA)->CNA_FORNEC)
            cLjClFor := Alltrim((cAliasCNA)->CNA_LJFORN)
        EndIf
    EndIf

    (cAliasCNA)->(DbCloseArea())
Return {cCliFor, cLjClFor}

/*/{Protheus.doc} TxtExcel
Protege um valor tipo codigo (com possiveis zeros a esquerda) para que o Excel
nao o reinterprete como numero/data ao abrir ou resalvar o CSV, o que descartaria
os zeros a esquerda (ex.: cliente "01067479" viraria "1067479").
Usa o truque classico de formula do Excel: ="valor" e' avaliado como texto puro
e, ao salvar novamente como CSV, o Excel grava so o resultado (o valor original),
sem a formula.
@type Static Function
@param cValor String, Valor original do campo
@return String, Valor envolvido em ="..." para preservar como texto no Excel
/*/
//====================================================================================================
    Static Function TxtExcel(cValor)
//====================================================================================================
Return '="' + cValor + '"'

/*/{Protheus.doc} GetPerg
Exibe ParamBox para selecao do diretorio de destino do arquivo CSV exportado.
@type Static Function
@return logical, .T. se o usuario confirmou os parametros
/*/
//====================================================================================================
    Static Function GetPerg()
//====================================================================================================

    Local aPergs      := {}
    Local aRet        := {}
    Local lRet        := .T.
    Private cCadastro := "Perguntas"

    AAdd(aPergs, {6, "Salvar Arq. em", Padr("",300), "", ".T.", "", 80, .T., "", "", GETF_LOCALHARD+GETF_RETDIRECTORY}) // MV_PAR01

    If !ParamBox(aPergs, "Geracao de Arquivo (Medicao)", aRet, /*bValid*/, /*aButtons*/, .T., /*nPosX*/, /*nPosY*/, /*oDialog*/, "RT69M001", .T., .T.)
        lRet := .F.
    EndIf
Return lRet
