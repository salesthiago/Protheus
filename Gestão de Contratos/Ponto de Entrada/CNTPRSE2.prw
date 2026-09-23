#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWBROWSE.CH"
#INCLUDE "FWMVCDEF.CH"
User function CNTPRSE2()

    Local aArea      := GetArea()
    Local lDeletou   := .F.
    Local cUsuario   := AllTrim(UsrRetName(RetCodUsr()))

    IF FwIsInCallStack("CN121MedEnc")
        if CN9->(CN9_FILIAL+CN9_NUMERO+CN9_REVISA) == SE2->(E2_FILORIG + E2_MDCONTR + E2_MDREVIS) ;
            .And. CNA->(CNA_FILIAL+CNA_CONTRA+CNA_REVISA) == SE2->(E2_FILORIG + E2_MDCONTR + E2_MDREVIS)
            SE2->(DbDelete())
            lDeletou := .T.

            // Registra na timeline do contrato (ZLG) a exclusao do titulo, informando
            // o usuario logado que efetuou a exclusao (ZLG_USUARI/ZLG_NOMEUS ja gravam
            // o usuario automaticamente dentro de U_SCTGrvZLG, mas tambem citamos aqui
            // na observacao para ficar explicito no historico).
            U_SCTGrvZLG(AllTrim(SE2->E2_MDCONTR), AllTrim(SE2->E2_MDREVIS), "", "", "TITULO_EXCLUIDO", "CNTPRSE2", "", "",;
                "Titulo " + AllTrim(SE2->E2_NUM) + " excluido pelo usuario logado (" + cUsuario + ")")
        Endif
    Endif

    // Registra na timeline do contrato (ZLG) a geracao do titulo a pagar -- so quando o
    // titulo estiver de fato vinculado a uma medicao de contrato (E2_MDCONTR preenchido) e
    // nao tiver sido excluido pelo tratamento acima (senao registraria um titulo que nem
    // chegou a existir). Usa os campos do proprio SE2 (E2_MDCONTR/E2_MDREVIS) em vez do
    // alias CN9, pois este PE tambem roda para SE2 sem relacao com contrato, quando CN9
    // pode estar posicionado em outro registro.
    If !lDeletou .And. !Empty(AllTrim(SE2->E2_MDCONTR))

        // Copia o centro de custo do item de medicao (CNE_CC) para o titulo recem-criado
        // (E2_CCD), quando o alias CNE (item da medicao que originou o titulo) estiver
        // posicionado e o titulo ainda nao tiver centro de custo preenchido.
        If Select("CNE") > 0 .And. !Empty(CNE->CNE_CC) .And. Empty(SE2->E2_CCD)
            RecLock("SE2", .F.)
                SE2->E2_CCD := CNE->CNE_CC
            MsUnlock()
        EndIf

        U_SCTGrvZLG(AllTrim(SE2->E2_MDCONTR), AllTrim(SE2->E2_MDREVIS), "", "", "TITULO_GERADO", "CNTPRSE2", "", "",;
            "Titulo " + AllTrim(SE2->E2_NUM) + " a pagar gerado. Com vencimento " + DToC(SE2->E2_VENCTO))
    EndIf

    RestArea(aArea)

Return