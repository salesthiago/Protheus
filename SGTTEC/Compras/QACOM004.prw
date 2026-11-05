/*

Gatilho para campo virtual contendo as datas 
de vencimento dos títulos a pagar.

*/

user function QACOM004()
    Local cRet      := ""
    Local cChaveSE2 := SF1->(F1_FILIAL+F1_FORNECE+F1_LOJA+F1_SERIE+F1_DOC)
    Local _cAreas   := getArea()

    SE2->(DbSetOrder(6)) //E2_FILIAL+E2_FORNECE+E2_LOJA+E2_PREFIXO+E2_NUM
    if SE2->(DbSeek(cChaveSE2))
        do while SE2->(!Eof()) .and. SE2->(E2_FILIAL+E2_FORNECE+E2_LOJA+E2_PREFIXO+E2_NUM) == cChaveSE2
            
            cRet += dToC(SE2->E2_VENCREA) + " - "

            SE2->(DbSkip())
        enddo
    endif

    RestArea(_cAreas)

return(cRet)
