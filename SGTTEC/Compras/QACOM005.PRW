/*

Gatilho para numeração única nas tabelas
SC1
SCP
STJ
GetNumSC1(), GETSXENUM("STJ","TJ_ORDEM")
U_QACOM005("STJ","TJ_ORDEM")
GetSXENum("SCP","CP_NUM")                                                                                                       
U_QACOM005("SCP","CP_NUM")
*/

user function QACOM005(cTabela, cCampo)
    Local _cAreas   := getArea()
    Local cQuery    := ""
    Local cAliasTOP := GetNextAlias()    
    Local cRet      := ""

    cQuery := "SELECT MAX("+cCampo+") AS NUMERO "
    cQuery += "FROM "+retSqlName(cTabela)+ " TAB "
    cQuery += "WHERE TAB.D_E_L_E_T_ = ' ' "
    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasTop,.T.,.T.)    

    cRet := strZero(val((cAliasTop)->NUMERO)+1,TamSx3(cCampo)[1])

    (cAliasTop)->(DbCloseArea())

    RestArea(_cAreas)

return(cRet)
