#Include 'Protheus.ch'

User Function MT094END()

    Local cDocto    := PARAMIXB[1]
    Local cTipo     := PARAMIXB[2]
    Local nOpc      := PARAMIXB[3]
    Local cFilDoc   := PARAMIXB[4]
    Local cUserApr  := RetCodUsr()

    if nOpc = 1 //aprovação
        SCR->(DbSetOrder(2))
        if SCR->(DbSeek(cFilDoc+cTipo+cDocto+cUserApr))
            do while SCR->(!Eof()) .and. SCR->(CR_FILIAL+CR_TIPO+CR_NUM+CR_USER) == cFilDoc+cTipo+cDocto+cUserApr
                SCR->(reclock("SCR",.F.))
                SCR->CR_XHRALIB := time()
                SCR->(MsUnLock())
                SCR->(DbSkip())
            enddo
        endif
    endif
Return
