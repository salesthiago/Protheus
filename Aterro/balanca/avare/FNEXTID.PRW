/*
Gatilho para numeração única nas tabelas
GetSXENum('NJJ','NJJ_CODROM')                                                                                                   
U_FNEXTID("NJH","NJH_CODPAV","NJH_FILIAL")
*/

user function FNEXTID(cTabela, cCampo, cFiltab)

    Local _cAreas   := getArea()
    Local cQuery    := ""
    Local cAliasTOP := GetNextAlias()    
    Local cRet      := ""

    cQuery := "SELECT MAX("+cCampo+") AS NUMERO "
    cQuery += "FROM "+retSqlName(cTabela)+ " TAB "
    cQuery += "WHERE TAB.D_E_L_E_T_ = ' ' AND TAB."+cFiltab+" = '"+cFilAnt+"' "
    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasTop,.T.,.T.)    

    cRet := strZero(val((cAliasTop)->NUMERO)+1,TamSx3(cCampo)[1])

    (cAliasTop)->(DbCloseArea())

    RestArea(_cAreas)

return(cRet)
