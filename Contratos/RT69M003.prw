#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"

// Layout do array de eventos retornado por CarregaEventos() -- um evento por
// linha, sempre nesta ordem de colunas
#DEFINE EV_DATA    1
#DEFINE EV_HORA    2
#DEFINE EV_ACAO    3
#DEFINE EV_REVISA  4
#DEFINE EV_NUMMED  5
#DEFINE EV_ORIGEM  6
#DEFINE EV_ANTES   7
#DEFINE EV_DEPOIS  8
#DEFINE EV_USUARI  9
#DEFINE EV_NOMEUS  10
#DEFINE EV_OBS     11

/*/{Protheus.doc} RT69M003
Gera em PDF a timeline (historico) do contrato posicionado, lendo os eventos
gravados na tabela ZLG pelos pontos de entrada de Gestao de Contratos
(CN300PCMT, C100VLAT, CN100SIT, CNTA121, CN121PED, CNTPRSE2 -- ver pasta
"Controle de Contratos/Ponto de Entrada" e "Gestao de Contratos/Ponto de
Entrada"). Traz TODO o historico do contrato (todas as revisoes), em ordem
cronologica (do evento mais antigo para o mais recente), para poder ser lido
como uma historia do contrato do inicio ao fim.

Layout redesenhado a partir de um prototipo visual (cabecalho com dados do
contrato + timeline em cards, um por evento). O motor TReport usado antes so
desenha tabelas simples, entao o relatorio foi reescrito para desenhar
diretamente via TMSPrinter (mesma classe/tecnica ja usada em
SGTTEC/Compras/RACOM003.prw neste ambiente).

IMPORTANTE (escolhido com o usuario, ver historico): a ideia inicial era usar
FWMSPrinter para gerar o PDF direto e abrir sozinho, sem nenhuma tela
intermediaria. Isso esbarrou no "Printer Agent" (printer.exe) nao instalado
neste appserver, obrigatorio para o FWMSPrinter funcionar. Como o TMSPrinter
(classe mais antiga) ja funciona comprovadamente neste ambiente (via
RACOM003.prw), o relatorio foi trocado para TMSPrinter -- o que exige um
fluxo diferente do pedido originalmente:
1) oPrinter:Setup() -- o USUARIO escolhe a impressora/driver (PDF, etc.) em
   uma tela padrao do Windows, ANTES de "Consultando Historico...".
2) So depois disso e que aparece "Consultando Historico..." enquanto os
   dados sao lidos e as paginas desenhadas.
3) No final, oPrinter:Preview() mostra a pre-visualizacao (nao abre um PDF
   sozinho automaticamente -- e o usuario decide, na propria pre-visualizacao,
   se imprime/exporta).

IMPORTANTE (fidelidade visual, decisao tomada junto com o usuario): o
TMSPrinter neste ambiente so tem Box/Line/Say/SayBitmap/GetTextWidth
confirmados em uso por outros relatorios -- nao ha exemplo de preenchimento
colorido, circulo ou cantos arredondados em nenhum relatorio grafico
existente neste codebase. Por isso o layout usa apenas retangulos retos,
linhas e texto (sem o selo colorido "VIGENTE" do prototipo, sem os icones e
sem os circulos da timeline do prototipo original). As constantes de
posicionamento abaixo sao uma aproximacao calibrada pelos limites de pagina
ja usados em RACOM003.prw (paisagem, sem SetResolution/SetPaperSize
explicitos) e podem precisar de ajuste fino no ambiente real.

O cabecalho do contrato NAO traz Fornecedor (um contrato de compra pode ter
mais de um fornecedor, inviabilizando esse dado) nem Objeto (sem campo
correspondente confirmado). Traz Empresa/Filial (padrao, via SM0), Situacao
Atual (CN9_SITUAC) e Vigencia desde (CN9_DTINIC).

Acionado pelo menu da rotina de Manutencao de Contratos (CTA100MNU.prw).
@type User Function
@since 2026-07-27
/*/
//=============================================================================================================================
    User Function RT69M003()
//=============================================================================================================================

    Local cAliasChk    := ""
    Local cSituacaoHdr := ""
    Local cVigenciaHdr := ""
    Local cRevisaHdr   := ""
    Local aEmpFil      := {}
    Local oPrinter     := Nil
    Private cCtrTL     := ""   // numero do contrato

    If Empty(Alltrim(CN9->CN9_NUMERO))
        MsgStop("Posicione em um contrato antes de gerar a timeline.", "Atencao")
        Return Nil
    EndIf

    cCtrTL := Alltrim(CN9->CN9_NUMERO)

    cAliasChk := BuscaZLG(cCtrTL)
    If (cAliasChk)->(Eof())
        (cAliasChk)->(DbCloseArea())
        MsgStop("Nenhum evento encontrado na timeline do contrato " + cCtrTL + ".", "Atencao")
        Return Nil
    EndIf
    (cAliasChk)->(DbCloseArea())

    // Dados do cabecalho lidos ANTES do Setup()/"Consultando Historico...", com o
    // alias CN9 ja garantidamente posicionado no contrato correto
    cRevisaHdr   := Alltrim(CN9->CN9_REVISA)
    cSituacaoHdr := SitCtrDescPlain(Alltrim(CN9->CN9_SITUAC))
    cVigenciaHdr := FmtData(CN9->CN9_DTINIC)
    aEmpFil      := ObtemEmpFilial(Alltrim(CN9->CN9_FILIAL))

    // TMSPrinter (ver observacao no topo do fonte sobre o FWMSPrinter/Printer
    // Agent) -- Setup() abre a tela padrao de selecao de impressora/driver;
    // se o usuario cancelar, Setup() retorna .F. e nada mais acontece
    oPrinter := TMSPrinter():New("Historico do Contrato")
    oPrinter:SetLandscape()

    If !oPrinter:Setup()
        Return Nil
    EndIf

    FWMsgRun(, {|| GeraTimeline(oPrinter, cCtrTL, cRevisaHdr, cSituacaoHdr, cVigenciaHdr, aEmpFil[1], aEmpFil[2])},;
        "Historico do Contrato", "Consultando Historico...")

Return Nil

/*/{Protheus.doc} BuscaZLG
Abre query na tabela ZLG filtrando pelo numero do contrato (todas as
revisoes), ordenada da data/hora mais antiga para a mais recente -- para que
a leitura siga a sequencia cronologica real dos fatos, do inicio ao fim.
Usada tanto para o teste rapido de "existe algum evento" quanto, em seguida,
por CarregaEventos() para trazer os dados de fato.
@type Static Function
@param cContrato String, numero do contrato (CN9_NUMERO)
@return String, alias da query aberta (TOPCONN), posicionado no primeiro registro
/*/
//=============================================================================================================================
    Static Function BuscaZLG(cContrato)
//=============================================================================================================================

    Local cAlias := GetNextAlias()
    Local cQuery := ""

    cQuery := " SELECT ZLG_DATA, ZLG_HORA, ZLG_REVISA, ZLG_NUMERO, ZLG_NUMMED, ZLG_ACAO, ZLG_ORIGEM, ZLG_ANTES, ZLG_DEPOIS, ZLG_USUARI, ZLG_NOMEUS, ZLG_OBS "
    cQuery += " FROM " + RetSqlName("ZLG") + " ZLG "
    cQuery += " WHERE ZLG.D_E_L_E_T_ = ' ' "
    cQuery += " AND ZLG_FILIAL = '" + FWXFilial("ZLG") + "' "
    cQuery += " AND ZLG_CONTRA = '" + cContrato + "' "
    cQuery += " ORDER BY ZLG_DATA ASC, ZLG_HORA ASC "
    cQuery := ChangeQuery(cQuery)

    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAlias, .F., .T.)
    (cAlias)->(DbGoTop())

Return cAlias

/*/{Protheus.doc} CarregaEventos
Le todos os eventos da timeline do contrato (BuscaZLG) e monta um array em
memoria, um item por evento, na ordem de colunas EV_* definida no topo do
fonte. Carregar tudo em memoria (em vez de So percorrer o cursor uma unica
vez) e necessario para poder medir a altura de cada card ANTES de desenhar
qualquer pagina (ver GeraTimeline).
@type Static Function
@param cContrato String, numero do contrato (CN9_NUMERO)
@return Array, um item por evento: {cData, cHora, cAcao, cRevisa, cNumMed, cOrigem, cAntes, cDepois, cUsuario, cNomeUsr, cObs}
/*/
//=============================================================================================================================
    Static Function CarregaEventos(cContrato)
//=============================================================================================================================

    Local cAlias   := BuscaZLG(cContrato)
    Local aEventos := {}

    While !(cAlias)->(Eof())
        AAdd(aEventos, { FmtData((cAlias)->ZLG_DATA)       ,;
                         Alltrim((cAlias)->ZLG_HORA)        ,;
                         Alltrim((cAlias)->ZLG_ACAO)        ,;
                         Alltrim((cAlias)->ZLG_REVISA)      ,;
                         Alltrim((cAlias)->ZLG_NUMMED)      ,;
                         Alltrim((cAlias)->ZLG_ORIGEM)      ,;
                         Alltrim((cAlias)->ZLG_ANTES)       ,;
                         Alltrim((cAlias)->ZLG_DEPOIS)      ,;
                         Alltrim((cAlias)->ZLG_USUARI)      ,;
                         Alltrim((cAlias)->ZLG_NOMEUS)      ,;
                         Alltrim((cAlias)->ZLG_OBS)         } )
        (cAlias)->(DbSkip())
    EndDo

    (cAlias)->(DbCloseArea())

Return aEventos

/*/{Protheus.doc} GeraTimeline
Desenha o relatorio completo (cabecalho + caixa de informacoes do contrato +
timeline) no objeto TMSPrinter recebido (ja criado e com Setup() feito pelo
chamador) e finaliza com Preview() -- ver observacao no topo do fonte sobre
por que nao e um PDF direto/automatico.

Feito em duas passadas com o MESMO objeto impressora:
1) Medicao: calcula a altura de cada card (CalcAlturaEvento, que usa
   GetTextWidth para quebrar a descricao em linhas) e decide em que evento
   comeca cada pagina -- necessario para poder escrever "Folha: N/Total" jah
   na primeira pagina.
2) Desenho: percorre os eventos de novo, agora chamando StartPage/EndPage e
   efetivamente desenhando cada card, respeitando as quebras de pagina
   calculadas na passada 1.
@type Static Function
@param oPrinter      objeto TMSPrinter, ja criado e com Setup() concluido pelo chamador
@param cCtrTL        String, numero do contrato
@param cRevisaHdr    String, revisao atual do contrato (CN9_REVISA)
@param cSituacaoHdr  String, situacao atual do contrato, ja traduzida (SitCtrDescPlain)
@param cVigenciaHdr  String, data de inicio de vigencia, ja formatada (FmtData)
@param cNomeEmp      String, nome da empresa (SM0_NOMECOM)
@param cNomeFil      String, nome da filial do contrato (SM0_FILIAL)
/*/
//=============================================================================================================================
    Static Function GeraTimeline(oPrinter, cCtrTL, cRevisaHdr, cSituacaoHdr, cVigenciaHdr, cNomeEmp, cNomeFil)
//=============================================================================================================================

    Local aEventos  := CarregaEventos(cCtrTL)

    Local oFontTitulo  := TFont():New("Arial", , 14, .T., .F.)
    Local oFontSubtit  := TFont():New("Arial", , 11, .T., .F.)
    Local oFontHora    := TFont():New("Arial", ,  9, .T., .F.)
    Local oFontNegrito := TFont():New("Arial", ,  8, .T., .F.)
    Local oFontNormal  := TFont():New("Arial", ,  8, .F., .F.)
    Local oFontPeq     := TFont():New("Arial", ,  7, .F., .F.)
    Local oFontInfo    := TFont():New("Arial", , 11, .F., .F.)

    // Constantes de layout (unidades internas do TMSPrinter) -- calibradas
    // pelos limites de pagina paisagem ja usados em RACOM003.prw (que nao
    // chama SetResolution/SetPaperSize; a tela de Setup() e quem define a
    // impressora/driver). Ver observacao no cabecalho do fonte sobre aproximacao
    Local nMinCol       := 060
    Local nMinLin       := 060
    Local nMaxCol       := 2790
    Local nMaxLin       := 1900
    Local nColCard      := nMinCol + 380
    Local nLarguraCard  := nMaxCol - nColCard - 40
    Local nAltLinha     := 42
    Local nPadCard      := 20
    Local nGapCard      := 30
    Local nLinCab       := 170   // altura reservada para o cabecalho fixo (titulo/folha/data/hora) em toda pagina
    Local nLinInfo      := 420   // altura da caixa de informacoes do contrato (so na 1a pagina)
    Local nLinContinua  := 140   // altura do titulo de continuacao (2a pagina em diante)

    Local aAlturas  := {}
    Local aQuebras  := {}
    Local nAcum     := 0
    Local nTotalPaginas
    Local nPagina
    Local nLin
    Local nI
    Local cSituacaoAtual := ""

    // --- Passada 1: medir a altura de cada card e decidir as quebras de pagina ---

    For nI := 1 To Len(aEventos)
        AAdd(aAlturas, CalcAlturaEvento(oPrinter, oFontNormal, aEventos[nI], nLarguraCard, nAltLinha, nPadCard))
    Next nI

    AAdd(aQuebras, 1)
    nAcum := nMinLin + nLinCab + nLinInfo
    For nI := 1 To Len(aEventos)
        If nAcum + aAlturas[nI] > nMaxLin
            AAdd(aQuebras, nI)
            nAcum := nMinLin + nLinCab + nLinContinua
        EndIf
        nAcum += aAlturas[nI] + nGapCard
    Next nI

    nTotalPaginas := Len(aQuebras)

    // --- Passada 2: desenhar de fato ---

    nPagina := 1
    oPrinter:StartPage()
    DesenhaCabecalho(oPrinter, oFontTitulo, oFontPeq, nMinCol, nMinLin, nMaxCol, nPagina, nTotalPaginas)
    DesenhaInfoContrato(oPrinter, oFontInfo, nMinCol, nMinLin+nLinCab, nMaxCol, cCtrTL, cRevisaHdr,;
        cSituacaoHdr, cVigenciaHdr, cNomeEmp, cNomeFil, Len(aEventos), aEventos)
    DesenhaTituloTimeline(oPrinter, oFontSubtit, nMinCol, nMinLin+nLinCab+nLinInfo, nMaxCol)

    nLin := nMinLin + nLinCab + nLinInfo + 75

    For nI := 1 To Len(aEventos)

        If nI > 1 .And. AScan(aQuebras, nI) > 0
            oPrinter:EndPage()
            nPagina++
            oPrinter:StartPage()
            DesenhaCabecalho(oPrinter, oFontTitulo, oFontPeq, nMinCol, nMinLin, nMaxCol, nPagina, nTotalPaginas)
            Titulo(oPrinter, oFontSubtit, nMinCol, nMinLin+nLinCab, nMaxCol, cCtrTL)
            nLin := nMinLin + nLinCab + nLinContinua
        EndIf

        cSituacaoAtual := AtualizaSituacaoCorrente(cSituacaoAtual, aEventos[nI])

        DesenhaEvento(oPrinter, aEventos[nI], nLin, nMinCol, nColCard, nMaxCol, nLarguraCard,;
            aAlturas[nI], nAltLinha, nPadCard, cSituacaoAtual, oFontHora, oFontPeq, oFontNegrito, oFontNormal)

        nLin += aAlturas[nI] + nGapCard
    Next nI

    oPrinter:EndPage()
    oPrinter:Preview()
    oPrinter:End()

Return Nil

/*/{Protheus.doc} CalcAlturaEvento
Calcula a altura (em unidades do TMSPrinter) que o card de um evento vai
ocupar, somando: titulo, linhas da descricao (apos quebra pelo GetTextWidth),
linha "De: X -> Para: Y" (se aplicavel) e a linha de rodape (Local/Situacao/
Responsavel/Observacao).
@type Static Function
@param oPrinter objeto TMSPrinter, ja criado (usado so para medir texto)
@param oFonte   objeto TFont, fonte usada no texto de descricao
@param hEvento  Array, um item do array retornado por CarregaEventos()
@param nLargura Numeric, largura disponivel (em unidades do FWMSPrinter) para o texto de descricao
@param nAltLinha Numeric, altura de uma linha de texto
@param nPad     Numeric, folga (padding) no topo/base do card
@return Numeric, altura total do card
/*/
//=============================================================================================================================
    Static Function CalcAlturaEvento(oPrinter, oFonte, hEvento, nLargura, nAltLinha, nPad)
//=============================================================================================================================

    Local aLinhas  := WrapText(oPrinter, oFonte, DescAcaoDetalhe(hEvento), nLargura)
    Local lDePara  := !Empty(MontaSituacaoLinha(hEvento))
    Local nLinhas  := Len(aLinhas) + 1 + If(lDePara, 1, 0) + 1 // descricao + titulo + (de/para) + rodape

Return (nPad*2) + (nLinhas * nAltLinha) + 25

/*/{Protheus.doc} WrapText
Quebra um texto em varias linhas para caber em uma largura maxima, medindo
cada tentativa de linha com GetTextWidth (metodo do TMSPrinter). Quebra
sempre por palavra inteira (nunca corta uma palavra ao meio).
@type Static Function
@param oPrinter objeto TMSPrinter
@param oFonte   objeto TFont usado para medir o texto
@param cTexto   String, texto a quebrar
@param nLargura Numeric, largura maxima disponivel
@return Array de String, uma linha por item
/*/
//=============================================================================================================================
    Static Function WrapText(oPrinter, oFonte, cTexto, nLargura)
//=============================================================================================================================

    Local aLinhas     := {}
    Local aPalavras   := StrTokArr2(Alltrim(cTexto), " ", .F.)
    Local cLinhaAtual := ""
    Local cTeste      := ""
    Local nI

    If Empty(Alltrim(cTexto))
        AAdd(aLinhas, "")
        Return aLinhas
    EndIf

    For nI := 1 To Len(aPalavras)
        cTeste := If(Empty(cLinhaAtual), aPalavras[nI], cLinhaAtual + " " + aPalavras[nI])

        If Empty(cLinhaAtual) .Or. oPrinter:GetTextWidth(cTeste, oFonte) <= nLargura
            cLinhaAtual := cTeste
        Else
            AAdd(aLinhas, cLinhaAtual)
            cLinhaAtual := aPalavras[nI]
        EndIf
    Next nI

    If !Empty(cLinhaAtual) .Or. Len(aLinhas) == 0
        AAdd(aLinhas, cLinhaAtual)
    EndIf

Return aLinhas

/*/{Protheus.doc} DesenhaCabecalho
Desenha o cabecalho fixo (titulo do relatorio + folha/data/hora), repetido em
todas as paginas.
@type Static Function
/*/
//=============================================================================================================================
    Static Function DesenhaCabecalho(oPrinter, oFontTitulo, oFontPeq, nMinCol, nMinLin, nMaxCol, nPagina, nTotalPaginas)
//=============================================================================================================================

    Local nLin := nMinLin

    oPrinter:Say(nLin, nMinCol, "HISTORICO DO CONTRATO", oFontTitulo)
    oPrinter:Say(nLin, nMaxCol, "Folha: " + Alltrim(Str(nPagina)) + "/" + Alltrim(Str(nTotalPaginas)), oFontPeq,,,,1)
    nLin += 040
    oPrinter:Say(nLin, nMaxCol, "Data: " + DToC(Date()), oFontPeq,,,,1)
    nLin += 035
    oPrinter:Say(nLin, nMaxCol, "Hora: " + Time(), oFontPeq,,,,1)
    nLin += 045
    oPrinter:Line(nLin, nMinCol, nLin, nMaxCol)

Return Nil

/*/{Protheus.doc} DesenhaInfoContrato
Desenha a caixa com os dados gerais do contrato (numero/revisao, situacao
atual, empresa/filial, vigencia, data de criacao e quantidade de eventos).
So aparece na primeira pagina.
@type Static Function
/*/
//=============================================================================================================================
    Static Function DesenhaInfoContrato(oPrinter, oFontInfo, nMinCol, nLinTopo, nMaxCol, cCtrTL, cRevisaHdr,;
        cSituacaoHdr, cVigenciaHdr, cNomeEmp, cNomeFil, nQtdEventos, aEventos)
//=============================================================================================================================

    Local nLin    := nLinTopo + 050
    Local nColEsq := nMinCol + 020
    Local nColDir := nMinCol + Int((nMaxCol-nMinCol)/2) + 040
    Local cCriadoEm := ""

    If Len(aEventos) > 0
        cCriadoEm := aEventos[1][EV_DATA] + " " + aEventos[1][EV_HORA]
    EndIf

    oPrinter:Box(nLinTopo, nMinCol, nLinTopo+380, nMaxCol)

    oPrinter:Say(nLin, nColEsq, "Contrato: " + cCtrTL + If(Empty(cRevisaHdr), "", " (Revisao " + cRevisaHdr + ")"), oFontInfo)
    oPrinter:Say(nLin, nColDir, "Situacao Atual: " + cSituacaoHdr, oFontInfo)
    nLin += 065

    oPrinter:Say(nLin, nColEsq, "Empresa: " + cNomeEmp, oFontInfo)
    oPrinter:Say(nLin, nColDir, "Filial: " + cNomeFil, oFontInfo)
    nLin += 065

    oPrinter:Say(nLin, nColEsq, "Vigencia desde: " + cVigenciaHdr, oFontInfo)
    oPrinter:Say(nLin, nColDir, "Contrato criado em: " + cCriadoEm, oFontInfo)
    nLin += 065

    oPrinter:Say(nLin, nColEsq, "Quantidade de eventos: " + Alltrim(Str(nQtdEventos)), oFontInfo)

Return Nil

/*/{Protheus.doc} DesenhaTituloTimeline
Desenha a barra de titulo da timeline (1a pagina).
@type Static Function
/*/
//=============================================================================================================================
    Static Function DesenhaTituloTimeline(oPrinter, oFontSubtit, nMinCol, nLin, nMaxCol)
//=============================================================================================================================

    oPrinter:Line(nLin, nMinCol, nLin, nMaxCol)
    nLin += 040
    oPrinter:Say(nLin, nMinCol, "TIMELINE DO CONTRATO - TODOS OS EVENTOS EM ORDEM CRONOLOGICA", oFontSubtit)
    nLin += 035
    oPrinter:Line(nLin, nMinCol, nLin, nMaxCol)

Return Nil

/*/{Protheus.doc} DesenhaTituloContinua
Desenha a barra de titulo simplificada usada nas paginas 2 em diante (sem
repetir a caixa de informacoes do contrato).
@type Static Function
/*/
//=============================================================================================================================
    Static Function Titulo(oPrinter, oFontSubtit, nMinCol, nLin, nMaxCol, cCtrTL)
//=============================================================================================================================

    nLin += 040
    oPrinter:Say(nLin, nMinCol, "TIMELINE DO CONTRATO " + cCtrTL + " (continuacao)", oFontSubtit)
    nLin += 035
    oPrinter:Line(nLin, nMinCol, nLin, nMaxCol)

Return Nil

/*/{Protheus.doc} DesenhaEvento
Desenha um evento da timeline: a coluna de hora/data (centralizada, sem linha
ou marcador de ligacao) e o card (retangulo) com titulo, descricao, linha
"De: X -> Para: Y" (quando aplicavel) e o rodape com 4 colunas (Local,
Situacao, Responsavel, Observacao).
@type Static Function
/*/
//=============================================================================================================================
    Static Function DesenhaEvento(oPrinter, hEvento, nLin, nMinCol, nColCard, nMaxCol, nLarguraCard,;
        nAltura, nAltLinha, nPad, cSituacaoAtual, oFontHora, oFontPeq, oFontNegrito, oFontNormal)
//=============================================================================================================================

    Local nInnerLin    := nLin + nPad
    Local aLinhasDesc  := WrapText(oPrinter, oFontNormal, DescAcaoDetalhe(hEvento), nLarguraCard)
    Local cDePara      := MontaSituacaoLinha(hEvento)
    Local nColWidth    := Int((nMaxCol - nColCard) / 4)
    Local cObs         := hEvento[EV_OBS]
    Local nColHora     := nMinCol + Int((nColCard - nMinCol) / 2)
    Local nI

    // Coluna de hora/data, centralizada (sem linha/marcador de ligacao -- retirado a pedido do usuario)
    oPrinter:Say(nLin+nPad, nColHora, hEvento[EV_HORA], oFontHora,,,,2)
    oPrinter:Say(nLin+nPad+nAltLinha, nColHora, hEvento[EV_DATA], oFontPeq,,,,2)

    // Card
    oPrinter:Box(nLin, nColCard, nLin+nAltura, nMaxCol)

    oPrinter:Say(nInnerLin, nColCard+nPad, DescAcaoTitulo(hEvento), oFontNegrito)
    nInnerLin += nAltLinha

    For nI := 1 To Len(aLinhasDesc)
        oPrinter:Say(nInnerLin, nColCard+nPad, aLinhasDesc[nI], oFontNormal)
        nInnerLin += nAltLinha
    Next nI

    If !Empty(cDePara)
        oPrinter:Say(nInnerLin, nColCard+nPad, cDePara, oFontNormal)
        nInnerLin += nAltLinha
    EndIf

    oPrinter:Line(nInnerLin, nColCard, nInnerLin, nMaxCol)
    nInnerLin += 025

    oPrinter:Say(nInnerLin, nColCard+nPad             , "Local: "       + OrigemDesc(hEvento[EV_ORIGEM]), oFontNormal)
    oPrinter:Say(nInnerLin, nColCard+nPad+1*nColWidth , "Situacao: "    + cSituacaoAtual, oFontNormal)
    oPrinter:Say(nInnerLin, nColCard+nPad+2*nColWidth , "Responsavel: " + hEvento[EV_NOMEUS] + " (" + hEvento[EV_USUARI] + ")", oFontNormal)
    oPrinter:Say(nInnerLin, nColCard+nPad+3*nColWidth , "Observacao: "  + If(Empty(cObs), "-", cObs), oFontNormal)

Return Nil

/*/{Protheus.doc} FmtData
Formata uma data (campo ZLG_DATA ou qualquer outro) para exibicao
(DD/MM/AAAA). DToC() exige tipo Data -- o TOPCONN (Postgres) as vezes devolve
o campo como caractere (ex: "20260727") em vez de Data, dependendo do
driver/consulta. Aceita os dois formatos para nao derrubar o relatorio por
causa disso.
@type Static Function
@param xData Data ou caractere
@return String, data formatada, ou "" se vazia/invalida
/*/
//=============================================================================================================================
    Static Function FmtData(xData)
//=============================================================================================================================
    Local cRet := ""

    Do Case
    Case ValType(xData) == "D"
        cRet := If(Empty(xData), "", DToC(xData))
    Case ValType(xData) == "C" .And. !Empty(Alltrim(xData))
        cRet := DToC(StoD(Alltrim(xData)))
    OtherWise
        cRet := ""
    EndCase

Return cRet

/*/{Protheus.doc} DescAcaoTitulo
Traduz o codigo tecnico gravado em ZLG_ACAO para um titulo curto em
portugues (sem numero de medicao/revisao -- esses detalhes ficam no texto
descritivo, ver DescAcaoDetalhe).
@type Static Function
@param hEvento Array, um item do array retornado por CarregaEventos()
@return String, titulo do evento
/*/
//=============================================================================================================================
    Static Function DescAcaoTitulo(hEvento)
//=============================================================================================================================
    Local cAcao := hEvento[EV_ACAO]
    Local cRet  := ""

    Do Case
    Case cAcao == "INCLUSAO"
        cRet := "Contrato incluido"
    Case cAcao == "ALTERACAO"
        cRet := "Contrato alterado"
    Case cAcao == "EXCLUSAO"
        cRet := "Contrato excluido"
    Case cAcao == "MUDANCA_SITUACAO"
        cRet := "Situacao do contrato alterada"
    Case cAcao == "TITULO_GERADO"
        cRet := "Titulo financeiro gerado"
    Case cAcao == "MEDICAO_INCLUSAO"
        cRet := "Medicao incluida"
    Case cAcao == "MEDICAO_ALTERACAO"
        cRet := "Medicao alterada"
    Case cAcao == "MEDICAO_EXCLUSAO"
        cRet := "Medicao excluida"
    Case cAcao == "MEDICAO_ESTORNO"
        cRet := "Medicao estornada"
    Case cAcao == "PEDIDO_COMPRA_GERADO"
        cRet := "Pedido de compra gerado"
    OtherWise
        cRet := cAcao
    EndCase

Return cRet

/*/{Protheus.doc} DescAcaoDetalhe
Monta a frase explicativa (corpo do card) para o evento, em portugues,
incluindo numero da medicao (quando aplicavel) e a revisao do contrato entre
parenteses no final (quando informada).
@type Static Function
@param hEvento Array, um item do array retornado por CarregaEventos()
@return String, frase explicativa do evento
/*/
//=============================================================================================================================
    Static Function DescAcaoDetalhe(hEvento)
//=============================================================================================================================
    Local cAcao   := hEvento[EV_ACAO]
    Local cNumMed := hEvento[EV_NUMMED]
    Local cRevisa := hEvento[EV_REVISA]
    Local cRet    := ""

    Do Case
    Case cAcao == "INCLUSAO"
        cRet := "O contrato foi cadastrado no sistema."
    Case cAcao == "ALTERACAO"
        cRet := "Dados do contrato foram alterados."
    Case cAcao == "EXCLUSAO"
        cRet := "O contrato foi excluido do sistema."
    Case cAcao == "MUDANCA_SITUACAO"
        cRet := "A situacao do contrato foi alterada."
    Case cAcao == "TITULO_GERADO"
        cRet := "Titulo a pagar gerado automaticamente."
    Case cAcao == "MEDICAO_INCLUSAO"
        cRet := "Medicao " + If(Empty(cNumMed), "", "numero " + cNumMed + " ") + "incluida no contrato."
    Case cAcao == "MEDICAO_ALTERACAO"
        cRet := "Medicao " + If(Empty(cNumMed), "", "numero " + cNumMed + " ") + "foi alterada."
    Case cAcao == "MEDICAO_EXCLUSAO"
        cRet := "Medicao " + If(Empty(cNumMed), "", "numero " + cNumMed + " ") + "foi excluida."
    Case cAcao == "MEDICAO_ESTORNO"
        cRet := "Medicao " + If(Empty(cNumMed), "", "numero " + cNumMed + " ") + "foi estornada."
    Case cAcao == "PEDIDO_COMPRA_GERADO"
        cRet := "Pedido de compra gerado" + If(Empty(cNumMed), " a partir do contrato.", " a partir da medicao numero " + cNumMed + ".")
    OtherWise
        cRet := cAcao
    EndCase

    If !Empty(cRevisa)
        cRet += " (Revisao " + cRevisa + ")"
    EndIf

Return cRet

/*/{Protheus.doc} OrigemDesc
Traduz o codigo tecnico gravado em ZLG_ORIGEM (ponto de entrada/rotina que
gerou o evento) para o nome da tela/rotina de negocio correspondente, em
portugues. Tabela fixa, com base nos pontos de entrada existentes em
"Controle de Contratos/Ponto de Entrada" e "Gestao de Contratos/Ponto de
Entrada": CN300PCMT (Manutencao de Contratos), CN100SIT (mudanca de
situacao), CNTA121 (Medicao, incluindo o estorno), CN121PED (geracao de
pedido de compra) e CNTPRSE2 (geracao de titulo a pagar).
@type Static Function
@param cOrigem String, codigo bruto de ZLG_ORIGEM (ex: "CNTA121(FORMCOMMITTTSPOS)")
@return String, nome da rotina em portugues, ou o proprio codigo se nao mapeado
/*/
//=============================================================================================================================
    Static Function OrigemDesc(cOrigem)
//=============================================================================================================================
    Local cDesc := cOrigem

    Do Case
    Case cOrigem == "CN300PCMT"
        cDesc := "Cadastro/Manutencao de Contratos"
    Case cOrigem == "CN100SIT"
        cDesc := "Alteracao de Situacao do Contrato"
    Case "MODELVLDACTIVE" $ cOrigem .Or. "ESTORN" $ Upper(cOrigem)
        cDesc := "Estorno de Medicao"
    Case Left(cOrigem, 7) == "CNTA121"
        cDesc := "Medicao de Contratos"
    Case cOrigem == "CN121PED"
        cDesc := "Geracao de Pedido de Compra"
    Case cOrigem == "CNTPRSE2"
        cDesc := "Geracao de Titulo a Pagar (Financeiro)"
    OtherWise
        cDesc := cOrigem
    EndCase

Return cDesc

/*/{Protheus.doc} MontaSituacaoLinha
Monta a linha "De: X -> Para: Y" (ou so "Situacao: X", quando so um dos
lados estiver preenchido) a partir de ZLG_ANTES/ZLG_DEPOIS, traduzindo os
codigos via SitCtrDescPlain -- somente quando a acao se refere ao CABECALHO
do contrato (CN9_SITUAC). As demais acoes (medicao, titulo, pedido) usam
outros dominios de situacao e ficam de fora, para nao confundir o leitor com
um codigo que nao se aplica ao contrato.
@type Static Function
@param hEvento Array, um item do array retornado por CarregaEventos()
@return String, "De: X -> Para: Y", so um lado, ou "" se nao se aplica
/*/
//=============================================================================================================================
    Static Function MontaSituacaoLinha(hEvento)
//=============================================================================================================================
    Local cAcao   := hEvento[EV_ACAO]
    Local cAntes  := hEvento[EV_ANTES]
    Local cDepois := hEvento[EV_DEPOIS]
    Local cRet    := ""

    If !(cAcao $ "INCLUSAO|ALTERACAO|EXCLUSAO|MUDANCA_SITUACAO")
        Return ""
    EndIf

    If !Empty(cAntes)  ; cAntes  := SitCtrDescPlain(cAntes)  ; EndIf
    If !Empty(cDepois) ; cDepois := SitCtrDescPlain(cDepois) ; EndIf

    Do Case
    Case !Empty(cAntes) .And. !Empty(cDepois)
        cRet := "De: " + cAntes + "   ->   Para: " + cDepois
    Case Empty(cAntes) .And. !Empty(cDepois)
        cRet := "Situacao: " + cDepois
    Case !Empty(cAntes) .And. Empty(cDepois)
        cRet := "Situacao: " + cAntes
    OtherWise
        cRet := ""
    EndCase

Return cRet

/*/{Protheus.doc} AtualizaSituacaoCorrente
Mantem, ao longo da leitura cronologica da timeline, a situacao "corrente" do
contrato -- atualizada sempre que um evento traz uma nova situacao
(ZLG_DEPOIS) e mantida (carry-forward) nos demais eventos, para preencher a
coluna "Situacao" do rodape de cada card com a situacao vigente NAQUELE
momento da historia (e nao so nos eventos de mudanca de situacao).
@type Static Function
@param cAtual  String, situacao corrente ate aqui (ja traduzida, ver SitCtrDescPlain)
@param hEvento Array, um item do array retornado por CarregaEventos()
@return String, situacao corrente apos este evento
/*/
//=============================================================================================================================
    Static Function AtualizaSituacaoCorrente(cAtual, hEvento)
//=============================================================================================================================
    Local cAcao   := hEvento[EV_ACAO]
    Local cDepois := hEvento[EV_DEPOIS]

    If cAcao $ "INCLUSAO|ALTERACAO|MUDANCA_SITUACAO" .And. !Empty(cDepois)
        cAtual := SitCtrDescPlain(cDepois)
    ElseIf cAcao == "EXCLUSAO"
        cAtual := "Excluido"
    EndIf

Return cAtual

/*/{Protheus.doc} SitCtrDescPlain
Traduz o codigo de situacao do CABECALHO DO CONTRATO (CN9_SITUAC) para a
descricao correspondente, em texto corrido (sem o prefixo numerico do
codigo). Tabela fixa (nao vem do dicionario/CT): 01-Cancelado,
02-Em Elaboracao, 03-Emitido, 04-Em Aprovacao, 05-Vigente, 06-Paralisado,
07-Solicitacao de Finalizacao, 08-Finalizado, 09-Em Revisao, 10-Revisado,
A-Revisao com Aprovacao por Alcadas.
@type Static Function
@param cCod String, codigo da situacao (ex: "02", "A"), ou "EXCLUIDO"
@return String, descricao, ou o proprio codigo se nao mapeado
/*/
//=============================================================================================================================
    Static Function SitCtrDescPlain(cCod)
//=============================================================================================================================
    Local cCodT := Alltrim(cCod)
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

/*/{Protheus.doc} ObtemEmpFilial
Le, na tabela SM0, o nome da empresa logada (cEmpAnt) e o nome da filial do
CONTRATO (nao necessariamente a filial logada no momento em que o relatorio
e chamado). Protege a area/ordem da SM0 (GetArea/RestArea), pois e uma
tabela compartilhada que outras rotinas podem estar usando.
@type Static Function
@param cFilCtr String, codigo da filial do contrato (CN9_FILIAL)
@return Array, {cNomeEmpresa, cNomeFilial} -- "" quando nao encontrado
/*/
//=============================================================================================================================
    Static Function ObtemEmpFilial(cFilCtr)
//=============================================================================================================================
    Local aArea := SM0->(GetArea())
    Local aRet  := {"", ""}

    SM0->(DbSetOrder(1))
    If SM0->(DbSeek(cEmpAnt + cFilCtr))
        aRet := { Alltrim(SM0->M0_NOMECOM), Alltrim(SM0->M0_FILIAL) }
    EndIf

    RestArea(aArea)

Return aRet
