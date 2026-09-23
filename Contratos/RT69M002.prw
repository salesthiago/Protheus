#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "fileio.ch"

/*/{Protheus.doc} RT69M002
Importa dados de arquivo CSV, exibe grid de confirmacao para edicao,
e gera a medicao de contratos apos confirmacao do usuario.
@type User Function
@author
@since
@version 2
@history
/*/
//=============================================================================================================================
    User Function RT69M002()
//=============================================================================================================================

    Local lConfirm  := .F.
    Local aCampos   := {}
    Local aLinhas   := {}
    Private oSay    := Nil
    Private QbLinha := Chr(13)+Chr(10)

    While .T.
        If GetPerg()
            lConfirm := .T.
            Exit
        Else
            If MsgNoYes("Foi detectado o cancelamento do preenchimento dos parametros. Deseja realmente sair da Importacao das Provisoes (Sim / Nao)?","Atencao !!!")
                Return Nil
            EndIf
        EndIf
    End

    If lConfirm
        If LerArquivo(@aCampos, @aLinhas)
            If MostraGrid(aCampos, @aLinhas)
                If Len(aLinhas) > 0
                    FWMsgRun(, {|| ExecutaMed(aCampos, aLinhas)}, "Criacao da Medicao", "Criando medicao de contrato...")
                Else
                    MsgStop("Nenhuma linha restante para processamento.", "Atencao")
                EndIf
            EndIf
        EndIf
    EndIf
Return Nil

/*/{Protheus.doc} LerArquivo
Le o arquivo CSV definido em MV_PAR01 e preenche os arrays de campos e linhas.
@type Static Function
@param aCampos Array, Cabecalho das colunas (passado por referencia)
@param aLinhas Array, Linhas de dados (passado por referencia)
@return logical, .T. se leitura OK e dados encontrados
/*/
//=============================================================================================================================
    Static Function LerArquivo(aCampos, aLinhas)
//=============================================================================================================================

    Local oFile  := Nil
    Local nLin   := 1
    Local nJ     := 0
    Local aDados := {}
    Local lRet   := .F.

    oFile := FWFileReader():New(Alltrim(MV_PAR01))
    If oFile:Open()
        While oFile:hasLine()
            If nLin == 1
                aCampos := CharToArray(oFile:GetLine(), ";")
                nLin += 1
                Loop
            EndIf
            aDados := CharToArray(oFile:GetLine(), ";")
            If Len(aDados) > 0
                // Remove o envoltorio ="valor" usado pelo RT69M001 para proteger
                // codigos com zeros a esquerda de serem reinterpretados pelo Excel.
                // Se o CSV for importado sem passar pelo Excel, o valor ainda vem
                // com esse envoltorio literal - aqui ele e desfeito de qualquer jeito.
                For nJ := 1 To Len(aDados)
                    aDados[nJ] := StripTxtExcel(aDados[nJ])
                Next nJ
                // Garante que a linha tenha o mesmo numero de colunas do cabecalho
                // (CharToArray descarta o ultimo campo quando ele vem vazio)
                While Len(aDados) < Len(aCampos)
                    AAdd(aDados, "")
                End
                AAdd(aLinhas, aDados)
            EndIf
            nLin += 1
        End
        lRet := .T.
    Else
        MsgStop(oFile:error():message, "Atencao")
    EndIf

    If lRet .And. (Len(aCampos) == 0 .Or. Len(aLinhas) == 0)
        MsgStop("Arquivo vazio ou sem dados validos.", "Atencao")
        lRet := .F.
    EndIf
Return lRet

/*/{Protheus.doc} MostraGrid
Exibe dialog com cabecalho do contrato, campo de competencia editavel,
grid (TCBrowse) com scroll horizontal, edicao do campo TES via duplo clique
com consulta padrao SF4 (MsGet F3/HasButton), e botao Confirmar para salvar a medicao.
@type Static Function
@param aCampos Array, Nomes das colunas (cabecalho CSV)
@param aLinhas Array, Dados importados - modificado in-place pelo usuario
@return logical, .T. se usuario clicou em Confirmar; .F. se cancelou
/*/
//=============================================================================================================================
    Static Function MostraGrid(aCampos, aLinhas)
//=============================================================================================================================

    Local oDlg     := Nil
    Local oBrw     := Nil
    Local nI       := 0
    Local lRet     := .F.
    Local aWidths  := {}
    Local nFldSz   := 0
    Local aTam     := {}
    Local cNumCont := ""
    Local cCliente := ""
    Local oGetCli, oNomeCli  := Nil
    Local cLojaCli := ""
    Local cNomeCli := ""
    Local cCompet  := ""
    Local cRevisao := ""
    Local aCompets := {}
    Local cCompCsv := ""
    Local nPosCont := 0
    Local nPosRev  := 0
    Local nPosCli  := 0
    Local nPosLoja := 0
    Local nPosComp := 0
    Local nPosTES  := 0
    Local oGetComp, oGetCont := Nil
    Local nTamNum   := 0
    Local nTamRev   := 0
    Local lAchouCN9 := .F.
    Local nPosQtG   := 0
    Local nPosVUG   := 0
    Local nPosPlan  := 0
    Local nValTotal := 0
    Local nQtdItens := 0
    Local nSaldoCtr := 0
    Local cValTotal := ""
    Local cQtdItens := ""
    Local cSaldoCtr := ""
    Local nQt       := 0
    Local nVu       := 0
    Local nVlLinha  := 0
    Local oBtnConfirm := Nil
    Local oGetQtd, oGetValor, oGetSaldo := Nil

    CN9->(DbSetOrder(1))
    // Mapear posicoes dos campos relevantes no array de colunas
    For nI := 1 To Len(aCampos)
        Do Case
            Case Alltrim(aCampos[nI]) == "CN9_NUMERO" ; nPosCont := nI
            Case Alltrim(aCampos[nI]) == "CN9_REVATU" ; nPosRev  := nI
            Case Alltrim(aCampos[nI]) == "CND_CLIENT" ; nPosCli  := nI
            Case Alltrim(aCampos[nI]) == "CND_LOJACL" ; nPosLoja := nI
            Case Alltrim(aCampos[nI]) == "CN9_COMPET" ; nPosComp := nI
            Case Alltrim(aCampos[nI]) == "CNE_TES"    ; nPosTES  := nI
            Case Alltrim(aCampos[nI]) == "CNE_QUANT"  ; nPosQtG  := nI
            Case Alltrim(aCampos[nI]) == "CNE_VLUNIT" ; nPosVUG  := nI
            Case Alltrim(aCampos[nI]) == "CNE_NUMERO" ; nPosPlan := nI
        EndCase
    Next nI

    // Total de itens e valor total da medicao (mesma regra de parsing usada em ExecutaMed:
    // formato BR, ponto = milhar, virgula = decimal). Acrescenta tambem a coluna CNE_VLTOT
    // no grid (mesmo calculo da linha que grava CNE_VLTOT em ExecutaMed: nQuant * nVlUnit),
    // para o usuario conferir linha a linha - a soma dela bate com nValTotal/cValTotal.
    nQtdItens := Len(aLinhas)
    If nPosQtG > 0 .And. nPosVUG > 0
        AAdd(aCampos, "CNE_VLTOT")
        For nI := 1 To Len(aLinhas)
            nQt := ParseNum(aLinhas[nI][nPosQtG])
            nVu := ParseNum(aLinhas[nI][nPosVUG])
            nVlLinha := TruncaDec(nQt * nVu, "CNE_VLTOT")
            nValTotal += nVlLinha
            AAdd(aLinhas[nI], Transform(nVlLinha, "@E 999,999,999.99"))
        Next nI
    EndIf

    // Extrair valores do cabecalho da primeira linha do CSV
    If Len(aLinhas) > 0
        If nPosCont > 0 ; cNumCont := Alltrim(aLinhas[1][nPosCont]) ; EndIf
        If nPosRev  > 0 ; cRevisao := Alltrim(aLinhas[1][nPosRev])  ; EndIf
        If nPosCli  > 0 ; cCliente := Alltrim(aLinhas[1][nPosCli])  ; EndIf
        If nPosLoja > 0 ; cLojaCli := Alltrim(aLinhas[1][nPosLoja]) ; EndIf
        If nPosComp > 0
            cCompet := Alltrim(aLinhas[1][nPosComp])
            If Len(cCompet) >= 6 // Converter YYYYMMDD ou YYYYMM -> MM/AAAA
                cCompet := SubStr(cCompet, 5, 2) + "/" + SubStr(cCompet, 1, 4)
            EndIf
        EndIf
    EndIf
    
    // CtrCompets() exige o CN9 posicionado no contrato+revisao - sem a revisao o
    // dbSeek cai na 1a revisao (mais antiga) e a lista de competencias vem errada
    If !Empty(cNumCont)
        CN9->(dbSetOrder(1))
        nTamNum   := Max(TamSX3("CN9_NUMERO")[1], Len(cNumCont))
        nTamRev   := Max(TamSX3("CN9_REVISA")[1], Len(cRevisao))
        lAchouCN9 := CN9->(dbSeek(xFilial("CN9") + Padr(cNumCont, nTamNum) + Padr(cRevisao, nTamRev)))
        // Fallback: Excel remove zeros a esquerda da revisao ao resalvar o CSV
        // (ex.: "001" vira "1") - reconstitui antes de desistir da busca
        If !lAchouCN9
            lAchouCN9 := CN9->(dbSeek(xFilial("CN9") + Padr(cNumCont, nTamNum) + Padl(cRevisao, nTamRev, "0")))
        EndIf
        If lAchouCN9
            aCompets := CtrCompets()
            nSaldoCtr := SaldoContrato(Alltrim(CN9->CN9_NUMERO), Alltrim(CN9->CN9_REVISA))
        EndIf
    EndIf

    cQtdItens := cValToChar(nQtdItens)
    cValTotal := Transform(nValTotal, "@E 999,999,999.99")
    cSaldoCtr := Transform(nSaldoCtr, "@E 999,999,999.99")

    // Buscar cliente na SA1 (corrige zeros a esquerda perdidos no CSV e descobre
    // a loja real quando ela nao vem preenchida no arquivo)
    AchaCliente(cCliente, cLojaCli, @cCliente, @cLojaCli, @cNomeCli)

    // Se CNE_TES nao veio no CSV, adiciona coluna vazia para preenchimento manual
    If nPosTES == 0
        nPosTES := Len(aCampos) + 1
        AAdd(aCampos, "CNE_TES")
        For nI := 1 To Len(aLinhas)
            AAdd(aLinhas[nI], "")
        Next nI
    EndIf

    // Calcular larguras das colunas
    For nI := 1 To Len(aCampos)
        aTam   := TamSX3(Alltrim(aCampos[nI]))
        nFldSz := If(Len(aTam) >= 1 .And. aTam[1] > 0, aTam[1], 15)
        AAdd(aWidths, Max(Min(nFldSz * 7, 200), 55))
    Next nI

    DEFINE DIALOG oDlg TITLE "Confirmacao de Dados - Medicao de Contratos" ;
        FROM 0, 0 TO 500, 700 PIXEL

        @ 010, 015 SAY "Contrato.: " OF oDlg PIXEL
        @ 006, 60 MSGET oGetCont VAR cNumCont PICTURE "@!" SIZE 60, 16 OF oDlg PIXEL when .F.
        
        @ 010, 150 SAY "Cliente.: " OF oDlg PIXEL
        @ 06, 180 MSGET oGetCli VAR cCliente PICTURE "@!" SIZE 40, 16 OF oDlg PIXEL when .F.
        @ 06, 220 MSGET oNomeCli VAR cNomeCli PICTURE "@!" SIZE 100, 16 OF oDlg PIXEL when .F.
        
        @ 33, 015 SAY "Competencia:" OF oDlg PIXEL
        @ 30, 60 COMBOBOX oGetComp VAR cCompet ITEMS aCompets SIZE 60, 16 OF oDlg PIXEL

        @ 33, 148 SAY "Qtd. Itens:" OF oDlg PIXEL
        @ 30, 180 MSGET oGetQtd VAR cQtdItens SIZE 40, 16 OF oDlg PIXEL when .F.

        @ 33, 220 SAY "Valor Total:" OF oDlg PIXEL
        @ 30, 250 MSGET oGetValor VAR cValTotal SIZE 75, 16 OF oDlg PIXEL when .F.

        @ 57, 70 SAY "Saldo Contrato:" OF oDlg PIXEL
        @ 55, 120 MSGET oGetSaldo VAR cSaldoCtr SIZE 60, 16 OF oDlg PIXEL when .F.

        @ 55, 005 BUTTON oBtnConfirm PROMPT "Confirmar" SIZE 60, 20 OF oDlg PIXEL ;
            ACTION ConfirmarMed(@lRet, @cCompet, oGetComp, oDlg, aLinhas, nPosPlan, nPosQtG, nPosVUG, cNumCont, cRevisao)
        @ 55, 275 BUTTON "Cancelar"      SIZE 60, 20 OF oDlg PIXEL ACTION (lRet := .F., oDlg:End())

        Begin Sequence
            oBtnConfirm:SetCSS("TButton { background-color: #0066CC; color: #FFFFFF; }")
        Recover
        End Sequence

        oBrw := TCBrowse():New(80, 05, 330, 150,, AClone(aCampos), AClone(aWidths), oDlg,,,,,{||},,,,,,,.F.,,.T.,,.F.,,.T.,.T.)
        oBrw:SetArray(aLinhas)
        oBrw:bLine    := {|| aLinhas[oBrw:nAt]}
        oBrw:lHScroll := .T.

        // Coluna TES: usa bEditExt + oBrw:Edit() para abrir SelTES pelo mecanismo
        // interno do TCBrowse, que suporta ACTIVATE DIALOG sem quebrar o loop de eventos pai
        If nPosTES > 0 .And. nPosTES <= Len(oBrw:aColumns)
            oBrw:aColumns[nPosTES]:lEditable := .T.
            oBrw:aColumns[nPosTES]:bEditExt  := {|| EditaTESExt(oBrw, aLinhas, nPosTES)}
        EndIf
        oBrw:bLDblClick := {|| IIF(oBrw:ColPos() == nPosTES .And. oBrw:nAt > 0, EditaTESExt(oBrw, aLinhas, nPosTES), Nil)}

    ACTIVATE DIALOG oDlg CENTERED

    // Propagar competencia editada para todas as linhas no formato YYYYMM
    If lRet .And. nPosComp > 0 .And. !Empty(StrTran(cCompet, " ", ""))
        cCompCsv := SubStr(cCompet, 4, 4) + SubStr(cCompet, 1, 2) // MM/AAAA -> AAAAMM
        For nI := 1 To Len(aLinhas)
            aLinhas[nI][nPosComp] := cCompCsv
        Next nI
    EndIf

Return lRet


/*/{Protheus.doc} ExcluirLinha
Exclui a linha atualmente selecionada no browse apos confirmacao.
Usa ADel + ASize para modificar o array in-place, mantendo a referencia original.
@type Static Function
/*/
//=============================================================================================================================
    Static Function ExcluirLinha(aLinhas, oBrw)
//=============================================================================================================================

    Local nAt := oBrw:nAt

    If Len(aLinhas) == 0
        Return Nil
    EndIf

    If MsgNoYes("Deseja excluir a linha " + cValToChar(nAt) + "?", "Atencao")
        ADel(aLinhas, nAt)
        ASize(aLinhas, Len(aLinhas) - 1)
        oBrw:SetArray(aLinhas)
        oBrw:nAt := If(Len(aLinhas) == 0, 0, If(nAt > Len(aLinhas), Len(aLinhas), nAt))
        oBrw:Refresh()
    EndIf
Return Nil

/*/{Protheus.doc} LimparTudo
Remove todos os dados do grid apos confirmacao.
Usa ASize(arr, 0) para limpar in-place preservando a referencia do array.
@type Static Function
/*/
//=============================================================================================================================
    Static Function LimparTudo(aLinhas, oBrw)
//=============================================================================================================================

    If MsgNoYes("Deseja limpar todos os dados importados?", "Atencao")
        ASize(aLinhas, 0)
        oBrw:SetArray(aLinhas)
        oBrw:nAt := 0
        oBrw:Refresh()
    EndIf
Return Nil

/*/{Protheus.doc} ConfirmarMed
Valida se a competencia foi informada, avisa se alguma planilha do arquivo excede o
limite de medicao previsto no cronograma financeiro (CNF) para a competencia escolhida,
e encerra o dialog com confirmacao.
@type Static Function
@param aLinhas   Array, linhas do CSV (para somar por planilha)
@param nPosPlan  Numeric, posicao da coluna CNE_NUMERO (numero da planilha/CNB_NUMERO) em aLinhas
@param nPosQtG   Numeric, posicao da coluna CNE_QUANT em aLinhas
@param nPosVUG   Numeric, posicao da coluna CNE_VLUNIT em aLinhas
@param cNumCont  String, numero do contrato
@param cRevisao  String, revisao do contrato
/*/
//=============================================================================================================================
    Static Function ConfirmarMed(lRet, cCompet, oGetComp, oDlg, aLinhas, nPosPlan, nPosQtG, nPosVUG, cNumCont, cRevisao)
//=============================================================================================================================
    Local aPlanilhas := {}
    Local aSubtot     := {}
    Local cPlanAtual  := ""
    Local nQt         := 0
    Local nVu         := 0
    Local nLimite     := 0
    Local nI          := 0
    Local nPos        := 0
    Local cAviso      := ""

    If Empty(Alltrim(cCompet))
        MsgStop("Informe a Competencia da Medicao no formato MM/AAAA.", "Atencao")
        Return Nil
    EndIf

    // Soma o valor informado por planilha (CNB_NUMERO, vem na coluna CNE_NUMERO do CSV) e
    // compara com o limite de medicao da competencia escolhida, vindo do cronograma
    // financeiro (CNF) daquela planilha - ver LimiteCompetencia(). Um contrato pode ter
    // mais de uma planilha, cada uma com seu proprio limite por competencia.
    If nPosPlan > 0 .And. nPosQtG > 0 .And. nPosVUG > 0
        For nI := 1 To Len(aLinhas)
            cPlanAtual := Alltrim(aLinhas[nI][nPosPlan])
            nPos := AScan(aPlanilhas, cPlanAtual)
            If nPos == 0
                AAdd(aPlanilhas, cPlanAtual)
                AAdd(aSubtot, 0)
                nPos := Len(aPlanilhas)
            EndIf
            nQt := ParseNum(aLinhas[nI][nPosQtG])
            nVu := ParseNum(aLinhas[nI][nPosVUG])
            aSubtot[nPos] += TruncaDec(nQt * nVu, "CNE_VLTOT")
        Next nI

        For nI := 1 To Len(aPlanilhas)
            nLimite := LimiteCompetencia(cNumCont, cRevisao, aPlanilhas[nI], cCompet)
            If nLimite >= 0 .And. aSubtot[nI] > nLimite
                cAviso += "Planilha " + aPlanilhas[nI] + ": total informado " + Transform(aSubtot[nI], "@E 999,999,999.99") + ;
                          " excede o limite da competencia (" + Transform(nLimite, "@E 999,999,999.99") + ")" + QbLinha
            EndIf
        Next nI
    EndIf

    If !Empty(cAviso)
        If !MsgNoYes("As planilhas abaixo excedem o limite de medicao previsto no cronograma financeiro para a competencia " + cCompet + ":" + QbLinha + QbLinha + ;
                     cAviso + QbLinha + "A geracao provavelmente sera rejeitada pelo CNTA121 (CNEVLTOT3). Deseja tentar confirmar mesmo assim?", "Atencao")
            Return Nil
        EndIf
    EndIf

    lRet := .T.
    oDlg:End()
Return Nil

/*/{Protheus.doc} EditaTESExt
Chamado pelo bEditExt do TCColumn da coluna TES.
O bEditExt é invocado pelo mecanismo interno do TCBrowse (nao por evento de mouse),
portanto ACTIVATE DIALOG dentro de SelTES nao quebra o loop de eventos da dialog pai.
@type Static Function
/*/
//=============================================================================================================================
    Static Function EditaTESExt(oBrw, aLinhas, nPosTES)
//=============================================================================================================================
    Local nLin := oBrw:nAt
    Local cSel := ""
    Local oDlg := oBrw:oWnd

    If nLin > 0 .And. nLin <= Len(aLinhas)
        cSel := SelTES(Alltrim(aLinhas[nLin][nPosTES]))
        If !Empty(cSel)
            aLinhas[nLin][nPosTES] := cSel
            oBrw:DrawSelect()
        EndIf

        oBrw:SetFocus()
        If oDlg != Nil
            oDlg:Refresh()
        EndIf
    EndIf
Return Nil

/*/{Protheus.doc} SelTES
Abre consulta padrao SF4 via MsGet F3/HasButton.
Fecha automaticamente via bChange apos selecao pelo F3 (valor completo)
ou via VALID apos digitacao manual com Enter/Tab.
@type Static Function
@param cAtual String, Codigo TES ja preenchido
@return String, Codigo TES selecionado ou "" se cancelado
/*/
//=============================================================================================================================
    Static Function SelTES(cAtual)
//=============================================================================================================================
    Local oDlgS   := Nil
    Local oGetTES := Nil
    Local aTam    := TamSX3("CNE_TES")
    Local nTam    := IIF(Len(aTam) > 0 .And. aTam[1] > 0, aTam[1], 3)
    Local cTES    := PadR(Alltrim(cAtual), nTam)
    Local lOk     := .F.

    DEFINE DIALOG oDlgS TITLE "Selecionar TES" FROM 0, 0 TO 60, 270 PIXEL
        @ 10, 010 SAY "TES:" OF oDlgS PIXEL
        @ 07, 040 MSGET oGetTES VAR cTES PICTURE "@!" SIZE 60, 12 F3 "SF4" HASBUTTON OF oDlgS PIXEL
        @ 35, 100 BUTTON "Cancelar" SIZE 65, 15 OF oDlgS PIXEL ACTION oDlgS:End()
        
        oGetTES:bChange := {|| IIF(Len(Alltrim(cTES)) >= nTam, (lOk := .T., oDlgS:End()), Nil)}

    ACTIVATE DIALOG oDlgS CENTERED

Return IIF(lOk .And. !Empty(Alltrim(cTES)), Alltrim(cTES), "")

/*/{Protheus.doc} AchaCliente
Localiza cliente/loja na SA1 a partir dos dados informados (CSV), tolerando
zeros a esquerda perdidos na exportacao e loja nao informada. Retorna via
parametros de referencia o codigo/loja/nome efetivamente encontrados.
@type Static Function
@param cCodCSV  String, Codigo do cliente como veio do arquivo
@param cLojaCSV String, Loja do cliente como veio do arquivo (pode ser vazia)
@param cCodOut  String, Codigo do cliente encontrado (saida por referencia)
@param cLojaOut String, Loja do cliente encontrada (saida por referencia)
@param cNomeOut String, Nome do cliente encontrado (saida por referencia)
@return logical, .T. se encontrou o cliente na SA1
/*/
//====================================================================================================
    Static Function AchaCliente(cCodCSV, cLojaCSV, cCodOut, cLojaOut, cNomeOut)
//====================================================================================================
    // Max() evita truncar cCodCSV/cLojaCSV quando o campo real guarda codigos
    // mais longos que o tamanho declarado no dicionario (SX3) - Padr/Padl cortam
    // a string quando o tamanho alvo e menor que o tamanho atual
    Local nTamCod  := Max(TamSX3("A1_COD")[1], Len(Alltrim(cCodCSV)))
    Local nTamLoj  := Max(TamSX3("A1_LOJA")[1], Len(Alltrim(cLojaCSV)))
    Local cCodZero := ""
    Local cLojZero := ""
    Local lAchou   := .F.

    cCodOut  := ""
    cLojaOut := ""
    cNomeOut := ""

    If Empty(Alltrim(cCodCSV))
        Return .F.
    EndIf

    dbSelectArea("SA1")
    SA1->(dbSetOrder(1))

    // 1a tentativa: codigo/loja exatamente como vieram do arquivo
    If !Empty(Alltrim(cLojaCSV))
        lAchou := SA1->(dbSeek(xFilial("SA1") + Padr(Alltrim(cCodCSV), nTamCod) + Padr(Alltrim(cLojaCSV), nTamLoj)))
    EndIf

    // 2a tentativa: reconstitui zeros a esquerda perdidos no codigo E na loja
    // (o Excel remove zeros a esquerda de colunas numericas ao salvar como CSV)
    If !lAchou .And. !Empty(Alltrim(cLojaCSV))
        cCodZero := Padl(Alltrim(cCodCSV), nTamCod, "0")
        cLojZero := Padl(Alltrim(cLojaCSV), nTamLoj, "0")
        lAchou := SA1->(dbSeek(xFilial("SA1") + cCodZero + cLojZero))
    EndIf

    // 3a tentativa: busca so pelo codigo (zero-preenchido), posicionando na
    // primeira loja existente - usada quando a loja nao veio no arquivo
    If !lAchou
        cCodZero := Padl(Alltrim(cCodCSV), nTamCod, "0")
        If SA1->(dbSeek(xFilial("SA1") + cCodZero)) .And. Alltrim(SA1->A1_COD) == Alltrim(cCodZero)
            lAchou := .T.
        EndIf
    EndIf

    If !lAchou
        If SA1->(dbSeek(xFilial("SA1") + cCodCSV))
            lAchou := .T.
        EndIf
    EndIf

    If !lAchou
        If SA1->(dbSeek(xFilial("SA1") + cCodCSV + cLojZero))
            lAchou := .T.
        EndIf
    EndIf

    If lAchou
        cCodOut  := Alltrim(SA1->A1_COD)
        cLojaOut := Alltrim(SA1->A1_LOJA)
        cNomeOut := Alltrim(SA1->A1_NOME)
    EndIf
Return lAchou

/*/{Protheus.doc} SaldoContrato
Calcula o saldo do contrato: valor total planejado na planilha (CNB) menos
o total ja apropriado em medicoes anteriores (CNE), para o contrato/revisao informados.
Nao reproduz o calculo interno do CNTA121 (que valida o limite POR COMPETENCIA);
serve apenas como saldo geral de referencia para o usuario.
@type Static Function
@param cContrato String, Numero do contrato (CN9_NUMERO)
@param cRevisao  String, Revisao do contrato (CN9_REVISA)
@return Numeric, Saldo do contrato (planejado - ja medido)
/*/
//====================================================================================================
    Static Function SaldoContrato(cContrato, cRevisao)
//====================================================================================================
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
Cronograma Financeiro (CNF) - e ele, nao o saldo total do item/contrato, que o CNTA121
usa para validar CNEVLTOT3. Formula confirmada com dados reais do contrato 019/2026-ITU:
limite = CNF_VLPREV (valor previsto da parcela da competencia) + CNF_SALDO (saldo ainda
nao realizado, inclui o que ficou de parcelas anteriores nao medidas).
CNF nao tem uma chave direta para a planilha (CNF_NUMERO usa numeracao propria, diferente
de CNA_NUMERO/CNB_NUMERO) - a ligacao usada aqui e por VALOR: o total do cronograma
(CNF_VLPREV * CNF_MAXPAR) bate com o valor total da planilha (CNA_VLTOT). Confirmado nos
dois cronogramas do contrato de teste (bateu exato nos dois). Se essa premissa nao se
confirmar em outro contrato, revisar.
@type Static Function
@param cContrato String, numero do contrato (CN9_NUMERO)
@param cRevisao  String, revisao do contrato (CN9_REVISA)
@param cNumPlan  String, numero da planilha (CNA_NUMERO/CNB_NUMERO)
@param cCompet   String, competencia no formato MM/AAAA
@return Numeric, limite de medicao para aquela planilha/competencia, ou -1 se nao encontrado
        (planilha sem cronograma cadastrado, ou sem parcela para essa competencia)
/*/
//=============================================================================================================================
    Static Function LimiteCompetencia(cContrato, cRevisao, cNumPlan, cCompet)
//=============================================================================================================================
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

/*/{Protheus.doc} ExecutaMed
Agrupa as linhas do CSV por planilha (CNB_NUMERO, exportado na coluna CNE_NUMERO) e
processa cada planilha separadamente - um contrato pode ter mais de uma planilha
(confirmado: contrato 019/2026-ITU tem duas), cada uma com seu proprio cronograma
financeiro e limite de medicao por competencia (ver LimiteCompetencia). Gerar tudo
junto numa unica medicao somava os limites de planilhas diferentes e estourava o
limite da competencia sem necessidade.
@type Static Function
@param aCampos Array, Nomes dos campos (cabecalho CSV)
@param aLinhas Array, Linhas de dados confirmadas pelo usuario
/*/
//=============================================================================================================================
    Static Function ExecutaMed(aCampos, aLinhas)
//=============================================================================================================================

    Local nX        := 0
    Local nPosPlan  := AScan(aCampos, {|x| Alltrim(x) == "CNE_NUMERO"})
    Local aPlanilhas:= {}
    Local aLinhasPl := {}
    Local cPlanAtual:= ""
    Local nP        := 0

    // Descobre as planilhas distintas presentes no arquivo, na ordem em que aparecem
    For nX := 1 To Len(aLinhas)
        cPlanAtual := If(nPosPlan > 0, Alltrim(aLinhas[nX][nPosPlan]), "")
        If AScan(aPlanilhas, cPlanAtual) == 0
            AAdd(aPlanilhas, cPlanAtual)
        EndIf
    Next nX

    For nP := 1 To Len(aPlanilhas)
        aLinhasPl := {}
        For nX := 1 To Len(aLinhas)
            If (If(nPosPlan > 0, Alltrim(aLinhas[nX][nPosPlan]), "")) == aPlanilhas[nP]
                AAdd(aLinhasPl, aLinhas[nX])
            EndIf
        Next nX
        ProcessaPlanilha(aCampos, aLinhasPl, aPlanilhas[nP])
    Next nP
Return Nil

/*/{Protheus.doc} ProcessaPlanilha
Gera UMA medicao (MVC FWLoadModel CNTA121) para os itens de UMA planilha especifica.
@type Static Function
@param aCampos Array, Nomes dos campos (cabecalho CSV)
@param aLinhas Array, Linhas de dados desta planilha (ja filtradas por ExecutaMed)
@param cNumPlanilha String, numero da planilha (CNB_NUMERO/CNA_NUMERO) sendo processada
/*/
//=============================================================================================================================
    Static Function ProcessaPlanilha(aCampos, aLinhas, cNumPlanilha)
//=============================================================================================================================

    Local nX        := 0
    Local nY        := 0
    Local oModel    := Nil
    Local oGridDet  := Nil
    Local oGridCXN  := Nil
    Local cItemPad  := ""
    Local cProdCsv  := ""
    Local lAchouItem:= .F.
    Local lMarcouPlan := .F.
    Local cValCXN   := ""
    Local nLinCXN   := 0
    Local nLin      := 0
    Local aCompets  := {}
    Local nCompet   := 0
    Local cNumCont  := ""
    Local cRevisao  := ""
    Local cCompet   := ""
    Local cNumMed   := ""
    Local cMsg      := ""
    Local cCliente  := ""
    Local cLojaCli  := ""
    Local cNomeCli  := ""
    Local cItemCsv  := ""
    Local nTamItem  := TamSX3("CNE_ITEM")[1]
    Local nQuant    := 0
    Local nVlUnit   := 0
    Local nFalhasAntes := 0
    Local aErros    := {}
    Local aFalhas   := {}
    Local nTamNum   := 0
    Local nTamRev   := 0
    Local lAchouCN9 := .F.

    // Posicoes dos campos de cabecalho no CSV
    Local nPosCont  := AScan(aCampos, {|x| Alltrim(x) == "CN9_NUMERO"})
    Local nPosRev   := AScan(aCampos, {|x| Alltrim(x) == "CN9_REVATU"})
    Local nPosComp  := AScan(aCampos, {|x| Alltrim(x) == "CN9_COMPET"})
    Local nPosForn  := AScan(aCampos, {|x| Alltrim(x) == "CND_FORNEC"})
    Local nPosLjFn  := AScan(aCampos, {|x| Alltrim(x) == "CND_LJFORN"})
    Local nPosCli   := AScan(aCampos, {|x| Alltrim(x) == "CND_CLIENT"})
    Local nPosLjCl  := AScan(aCampos, {|x| Alltrim(x) == "CND_LOJACL"})
    Local nPosPed   := AScan(aCampos, {|x| Alltrim(x) == "CNB_PEDTIT"})
    Local nPosNE    := AScan(aCampos, {|x| Alltrim(x) == "CNB_CODNE"})
    // Posicoes dos campos de item no CSV
    Local nPosItem  := AScan(aCampos, {|x| Alltrim(x) == "CNE_ITEM"})
    Local nPosProd  := AScan(aCampos, {|x| Alltrim(x) == "CNE_PRODUT"})
    Local nPosDesc  := AScan(aCampos, {|x| Alltrim(x) == "CNE_DESCRI"})
    //Local nPosUM    := AScan(aCampos, {|x| Alltrim(x) == "CNE_UM"})
    Local nPosQt    := AScan(aCampos, {|x| Alltrim(x) == "CNE_QUANT"})
    Local nPosVU    := AScan(aCampos, {|x| Alltrim(x) == "CNE_VLUNIT"})
    Local nPosTES   := AScan(aCampos, {|x| Alltrim(x) == "CNE_TES"})
    Local nPosCC    := AScan(aCampos, {|x| Alltrim(x) == "CNE_CC"})
    
    // Extrair cabecalho da primeira linha do CSV
    If nPosCont > 0 ; cNumCont := Alltrim(aLinhas[1][nPosCont]) ; EndIf
    If nPosRev  > 0 ; cRevisao := Alltrim(aLinhas[1][nPosRev])  ; EndIf
    If nPosCli  > 0 ; cCliente := Alltrim(aLinhas[1][nPosCli])  ; EndIf
    If nPosLjCl > 0 ; cLojaCli := Alltrim(aLinhas[1][nPosLjCl]) ; EndIf
    If nPosComp > 0
        cCompet := Alltrim(aLinhas[1][nPosComp])
        // Garantir formato MM/AAAA exigido pelo CNTA121
        If Len(cCompet) == 6 // AAAAMM -> MM/AAAA
            cCompet := SubStr(cCompet, 5, 2) + "/" + SubStr(cCompet, 1, 4)
        EndIf
    EndIf

    // Cliente/loja: confirma o registro na SA1 (corrige zeros a esquerda perdidos
    // no CSV e descobre a loja real quando ela nao vem preenchida no arquivo)
    AchaCliente(cCliente, cLojaCli, @cCliente, @cLojaCli, @cNomeCli)

    // Posicionar na CN9 - obrigatorio para o CNTA121
    // Inclui a revisao na chave: sem ela o dbSeek cai na 1a revisao do contrato
    // (a mais antiga), o que faz CtrCompets() trazer um intervalo de competencias errado
    CN9->(dbSetOrder(1))
    nTamNum   := Max(TamSX3("CN9_NUMERO")[1], Len(cNumCont))
    nTamRev   := Max(TamSX3("CN9_REVISA")[1], Len(cRevisao))
    lAchouCN9 := CN9->(dbSeek(xFilial("CN9") + Padr(cNumCont, nTamNum) + Padr(cRevisao, nTamRev)))
    // Fallback: Excel remove zeros a esquerda da revisao ao resalvar o CSV
    If !lAchouCN9
        lAchouCN9 := CN9->(dbSeek(xFilial("CN9") + Padr(cNumCont, nTamNum) + Padl(cRevisao, nTamRev, "0")))
    EndIf
    If !lAchouCN9
        MsgStop("Contrato [" + cNumCont + "] revisao [" + cRevisao + "] nao encontrado na filial.", "Atencao")
        Return Nil
    EndIf

    // CND_RCCOMP espera o INDICE da competencia dentro de CtrCompets(), nao o texto.
    // Precisa estar posicionado no CN9 (acima) antes de chamar CtrCompets().
    aCompets := CtrCompets()
    nCompet  := AScan(aCompets, {|x| Alltrim(x) == Alltrim(cCompet)})
    If nCompet == 0
        MsgStop("Competencia [" + cCompet + "] nao esta disponivel para este contrato.", "Atencao")
        Return Nil
    EndIf

    // Carregar o modelo MVC do CNTA121 e configurar para inclusao
    oModel := FWLoadModel("CNTA121")
    oModel:SetOperation(MODEL_OPERATION_INSERT)

    If !oModel:CanActivate()
        MsgStop("Nao foi possivel ativar o modelo CNTA121.", "Atencao")
        Return Nil
    EndIf
    oModel:Activate()

    // --- Cabecalho da medicao (CNDMASTER) ---
    oModel:SetValue("CNDMASTER", "CND_CONTRA", CN9->CN9_NUMERO)
    oModel:SetValue("CNDMASTER", "CND_REVISA", cRevisao)
    //oModel:SetValue("CNDMASTER", "CND_COMPET", cCompet)
    oModel:SetValue("CNDMASTER", "CND_RCCOMP", cValToChar(nCompet)) // Reconhece competencia - indice dentro de CtrCompets()

    // NOTA: a coluna CNE_NUMERO do CSV traz CNB_NUMERO (numero da PLANILHA, ver RT69M001
    // GeraArq), nao um numero de medicao - por isso NAO e usada para forcar CND_NUMERO
    // (fazia isso antes; forcava "000001"/"000002" como se fosse o numero da medicao,
    // o que e incorreto e colidiria entre as duas planilhas). CND_NUMERO fica com a
    // numeracao automatica padrao do CNTA121.
    If nPosForn > 0 ; oModel:SetValue("CNDMASTER", "CND_FORNEC", Alltrim(aLinhas[1][nPosForn])) ; EndIf
    If nPosLjFn > 0 ; oModel:SetValue("CNDMASTER", "CND_LJFORN", Alltrim(aLinhas[1][nPosLjFn])) ; EndIf
    If !Empty(cCliente)
        oModel:SetValue("CNDMASTER", "CND_CLIENT", cCliente)
        oModel:SetValue("CNDMASTER", "CND_LOJACL", cLojaCli)
    EndIf
    If nPosPed  > 0 .And. !Empty(Alltrim(aLinhas[1][nPosPed]))
        oModel:SetValue("CNDMASTER", "CNB_PEDTIT", Alltrim(aLinhas[1][nPosPed]))
        If Alltrim(aLinhas[1][nPosPed]) == "2" .And. nPosNE > 0
            oModel:SetValue("CNDMASTER", "CNB_CODNE", Alltrim(aLinhas[1][nPosNE]))
        EndIf
    EndIf

    // Marcar a planilha antes dos itens - e o que habilita o LoadValue() a adicionar itens
    // em CNEDETAIL (padrao TOTVS para o modo Reconhece Competencia). O contrato pode ter
    // mais de uma planilha em CXNDETAIL (confirmado: 019/2026-ITU tem duas) - tenta achar a
    // linha da planilha cNumPlanilha testando os nomes de campo mais provaveis antes de
    // marcar CXN_CHECK. NAO FOI POSSIVEL CONFIRMAR o nome real do campo sem rodar no
    // ambiente - se nenhum candidato bater, cai no comportamento antigo (marca a planilha
    // "atual"). CONFERIR MANUALMENTE ao testar um contrato com mais de uma planilha: a
    // medicao gerada para a 2a planilha realmente trouxe os itens da 2a planilha?
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
                // oGridCXN:SetValue() (chamada direto no objeto do grid) NAO persiste o
                // valor aqui (confirmado em teste: lMarcouPlan ficava .T. mas CXN_CHECK
                // continuava .F. depois). oModel:SetValue() no nivel do modelo, apos o
                // GoLine posicionar a linha certa, e a forma que realmente funciona (igual
                // ao fallback abaixo, que sempre usou essa forma com sucesso).
                oModel:SetValue("CXNDETAIL", "CXN_CHECK", .T.)
                lMarcouPlan := .T.
                Exit
            EndIf
        Next nLinCXN
    EndIf
    If !lMarcouPlan
        // A planilha informada nao esta pendente de medicao para esta competencia no
        // CXNDETAIL do CNTA121 (ja foi medida antes, ou o cliente/fornecedor gravado no
        // cabecalho da medicao nao bate com o cadastrado na CNA desta planilha). Abortar
        // em vez de marcar a planilha errada (causava itens da planilha cNumPlanilha
        // sendo gravados sob outra planilha, gerando falhas incoerentes como SEMTESITEM).
        MsgStop("Planilha " + cNumPlanilha + " nao foi encontrada como pendente de medicao " + ;
                "para a competencia " + cCompet + " (grid CXNDETAIL do CNTA121)." + QbLinha + QbLinha + ;
                "Possiveis causas: esta planilha ja foi medida nesta competencia, ou o " + ;
                "cliente/fornecedor gravado no cabecalho da medicao nao corresponde ao " + ;
                "cadastrado na CNA desta planilha.", "Atencao")
        oModel:DeActivate()
        Return Nil
    EndIf


    // --- Itens da medicao (CNEDETAIL) ---
    oGridDet := oModel:GetModel("CNEDETAIL")

    For nX := 1 To Len(aLinhas)
        nQuant  := 0
        nVlUnit := 0
        nFalhasAntes := Len(aFalhas)

        // CNE_ITEM e obrigatorio - usa o valor do CSV (zero-preenchido a esquerda)
        // ou gera um sequencial quando o arquivo nao trouxer a coluna/valor
        // LoadValue() e o metodo padrao TOTVS para adicionar um item a planilha
        // quando CXN_CHECK esta marcado (substitui o AddLine()). Como marcar a
        // planilha pode auto-popular itens pendentes reais, primeiro procura se
        // o item ja existe no grid antes de chamar LoadValue - senao duplica a
        // linha e da erro de chave duplicada no commit.
        // CNB_ITEM identifica um AGRUPAMENTO da planilha, nao a linha - varios produtos
        // podem compartilhar o mesmo CNE_ITEM (confirmado com o cliente: a mesma medicao
        // trouxe 45 linhas com poucos codigos de item distintos). Comparar so por CNE_ITEM
        // fazia a 2a, 3a... linha do mesmo item serem tratadas como "ja existe" e
        // SOBRESCREVIAM (via TrySet abaixo) os dados da linha anterior em vez de criar uma
        // linha nova - o total gravado (CNE_VLTOT) ficava menor que a soma real do CSV.
        // Agora tambem compara o produto: so reaproveita a linha (auto-populada pelo
        // CXN_CHECK) quando item E produto batem; itens repetidos com produto diferente
        // passam a gerar uma linha por produto, como na medicao manual.
        cItemCsv := ""
        If nPosItem > 0 ; cItemCsv := Alltrim(aLinhas[nX][nPosItem]) ; EndIf
        If Empty(cItemCsv) ; cItemCsv := cValToChar(nX) ; EndIf
        cItemPad   := Padl(cItemCsv, nTamItem, "0")
        cProdCsv   := If(nPosProd > 0, Alltrim(aLinhas[nX][nPosProd]), "")
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
            oGridDet:LoadValue("CNE_ITEM", cItemPad)
        EndIf

        If nPosProd  > 0 ; TrySet(oModel, aFalhas, "CNEDETAIL", "CNE_PRODUT", Padr(Alltrim(aLinhas[nX][nPosProd]), Max(TamSX3("CNE_PRODUT")[1], Len(Alltrim(aLinhas[nX][nPosProd])))))  ; EndIf
        If nPosDesc  > 0 ; TrySet(oModel, aFalhas, "CNEDETAIL", "CNE_DESCRI", Alltrim(aLinhas[nX][nPosDesc]))  ; EndIf
    
        If nPosTES   > 0 .And. !Empty(Alltrim(aLinhas[nX][nPosTES]))
            TrySet(oModel, aFalhas, "CNEDETAIL", "CNE_TES", Alltrim(aLinhas[nX][nPosTES]))
        EndIf
        If nPosCC    > 0
            TrySet(oModel, aFalhas, "CNEDETAIL", "CNE_CC",  Alltrim(aLinhas[nX][nPosCC]))
        EndIf

        If nPosQt > 0
            nQuant := ParseNum(aLinhas[nX][nPosQt])
            TrySet(oModel, aFalhas, "CNEDETAIL", "CNE_QUANT", nQuant)
        EndIf
        If nPosVU > 0
            nVlUnit := ParseNum(aLinhas[nX][nPosVU])
            TrySet(oModel, aFalhas, "CNEDETAIL", "CNE_VLUNIT", nVlUnit)
            TrySet(oModel, aFalhas, "CNEDETAIL", "CNE_VLTOT",  TruncaDec(nQuant * nVlUnit, "CNE_VLTOT"))
        EndIf
        TrySet(oModel, aFalhas, "CNEDETAIL", "CNE_REVISA", cRevisao)

        If Len(aFalhas) > nFalhasAntes
            cMsg := "Planilha " + cNumPlanilha + " - Falha ao preencher a linha " + cValToChar(nX) + " do arquivo:" + QbLinha
            For nY := nFalhasAntes + 1 To Len(aFalhas)
                cMsg += aFalhas[nY] + QbLinha
            Next nY
            oModel:DeActivate()
            MsgStop(cMsg, "Atencao")
            Return Nil
        EndIf
    Next nX

    // Validar e gravar via MVC
    If oModel:VldData()
        oModel:CommitData()
    EndIf

    // Verificar resultado e exibir mensagem
    If oModel:HasErrorMessage()
        aErros := oModel:GetErrorMessage()
        For nY := 1 To Len(aErros)
            If ValType(aErros[nY]) == "A"
                cMsg += cValToChar(aErros[nY][1]) + QbLinha
            Else
                cMsg += cValToChar(aErros[nY]) + QbLinha
            EndIf
        Next nY
        oModel:DeActivate()
        MsgStop("Falha na geracao da Medicao (planilha " + cNumPlanilha + "):" + QbLinha + cMsg, "Atencao")
    Else
        // Ler numero gerado antes do DeActivate
        cNumMed := Alltrim(CND->CND_NUMMED)
        cMsg    := "Medicao incluida com sucesso!" + QbLinha
        cMsg    += "Planilha: "     + cNumPlanilha              + QbLinha
        cMsg    += "Filial: "       + Alltrim(CND->CND_FILIAL) + QbLinha
        cMsg    += "Num. Medicao: " + cNumMed                  + QbLinha
        oModel:DeActivate()
        MsgInfo(cMsg, "Atencao")
    EndIf

Return Nil

/*/{Protheus.doc} ParseNum
Converte texto numerico vindo do CSV para Numeric, tratando os dois formatos possiveis:
- Sem virgula: assume ponto como separador decimal (formato gravado por cValToChar()
  no RT69M001, sem separador de milhar) - usado direto com Val().
- Com virgula: assume formato BR (ponto = milhar, virgula = decimal), produzido quando
  o arquivo e reaberto/resalvo no Excel com configuracao regional Brasil.
Ambiguidade so existiria se alguem digitasse manualmente um valor inteiro com ponto de
milhar e sem casas decimais (ex.: "35.569" para 35569) - caso nao coberto, pois os
campos CNE_QUANT/CNE_VLUNIT normalmente tem casas decimais.
@type Static Function
@param cVal String, Valor numerico como veio da celula do CSV
@return Numeric, Valor convertido
/*/
//====================================================================================================
    Static Function ParseNum(cVal)
//====================================================================================================
    Local cTxt := Alltrim(cVal)

    If "," $ cTxt
        cTxt := StrTran(StrTran(cTxt, ".", ""), ",", ".")
    EndIf
Return Val(cTxt)

/*/{Protheus.doc} TruncaDec
Trunca (sem arredondar) um valor numerico para a quantidade de casas decimais definida
no dicionario de dados (SX3) do campo informado. Usado nos calculos de quantidade *
valor unitario, que por padrao seriam ARREDONDADOS ao serem gravados no campo do banco
(ex.: 0.005 vira 0.01) - aqui o excedente e simplesmente descartado (0.005 vira 0.00).
@type Static Function
@param nValor Numeric, valor a truncar
@param cCampo String, nome do campo no dicionario (define a quantidade de casas decimais)
@return Numeric, valor truncado
/*/
//====================================================================================================
    Static Function TruncaDec(nValor, cCampo)
//====================================================================================================
    Local aTam   := TamSX3(cCampo)
    Local nDec   := If(Len(aTam) >= 2 .And. aTam[2] > 0, aTam[2], 2)
    Local nFator := 10 ** nDec
    // Epsilon compensa erro de representacao binaria de ponto flutuante (ex.: 1.10 * 100
    // pode resultar em 109.99999999994 em vez de 110) - sem ele, Int() truncaria um
    // centavo/unidade a menos do que deveria em casos assim.
Return Int(nValor * nFator + 0.00001) / nFator

/*/{Protheus.doc} CharToArray
Converte string delimitada em array, separando pelo delimitador informado.
@type Static Function
@param cLinha String, Linha a ser convertida
@param cSepar String, Caractere separador
@return Array, Array com os valores da linha
/*/
//====================================================================================================
    Static Function CharToArray(cLinha, cSepar)
//====================================================================================================

    Local nPos   := 0
    Local aLinha := {}

    nPos := At(cSepar, cLinha)
    While !Empty(cLinha) .And. nPos > 0
        AAdd(aLinha, SubStr(cLinha, 1, nPos-1))
        cLinha := SubStr(cLinha, nPos+1, Len(cLinha)-nPos)
        nPos   := At(cSepar, cLinha)
        If nPos == 0 .And. !Empty(cLinha)
            nPos := Len(cLinha)+1
        EndIf
    EndDo
Return aLinha

/*/{Protheus.doc} StripTxtExcel
Remove o envoltorio ="valor" (truque usado no RT69M001 para proteger codigos
com zeros a esquerda no Excel) e devolve o valor puro. Se o valor nao estiver
envolvido nesse formato, retorna sem alteracao.
@type Static Function
@param cVal String, Valor lido de uma celula do CSV
@return String, Valor sem o envoltorio de formula
/*/
//====================================================================================================
    Static Function StripTxtExcel(cVal)
//====================================================================================================
    If Len(cVal) >= 3 .And. Left(cVal, 2) == '="' .And. Right(cVal, 1) == '"'
        Return SubStr(cVal, 3, Len(cVal) - 3)
    EndIf
Return cVal

/*/{Protheus.doc} GetPerg
Exibe ParamBox para selecao do arquivo CSV a importar.
@type Static Function
@return logical, .T. se usuario confirmou os parametros
/*/
//====================================================================================================
    Static Function GetPerg()
//====================================================================================================

    Local aPergs         := {}
    Local aRet           := {}
    Local lRet           := .T.
    Private cCadastro    := "Perguntas"

    AAdd(aPergs, {6, "Local do Arquivo", Padr("",300), "", ".T.", "", 80, .T., "", "", GETF_LOCALHARD+GETF_NETWORKDRIVE}) // MV_PAR01

    If !ParamBox(aPergs, "Buscar Arquivo", aRet, /*bValid*/, /*aButtons*/, .T., /*nPosX*/, /*nPosY*/, /*oDialog*/, "RT69M002", .T., .T.)
        lRet := .F.
    EndIf
Return lRet

/*/{Protheus.doc} MkColBlock
Cria um codeblock com closure correto para leitura de uma coluna especifica do array.
Usar funcao auxiliar evita o problema de closure do loop e o escopo limitado do operador &().
@type Static Function
@param aData  Array, linhas de dados do browse
@param oBrwRef Object, instancia do TCBrowse
@param nIdx Numeric, indice da coluna no array
@return Block
/*/
//====================================================================================================
    Static Function MkColBlock(aData, oBrwRef, nIdx)
//====================================================================================================
Return {|| If(Len(aData) >= oBrwRef:nAt .And. oBrwRef:nAt > 0, aData[oBrwRef:nAt][nIdx], '') }

//====================================================================================================
    Static Function TrySet(oMdl, aFalhas, cGrd, cFld, xVal)
//====================================================================================================
    Local bPrevErr := ErrorBlock({|e| Break(e)})
    Local oErr := Nil
    Begin Sequence
        oMdl:SetValue(cGrd, cFld, xVal)
    Recover Using oErr
        AAdd(aFalhas, cFld + ": " + oErr:Description)
    End Sequence
    ErrorBlock(bPrevErr)
Return Nil
