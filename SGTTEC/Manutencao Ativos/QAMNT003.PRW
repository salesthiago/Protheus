/*

U_QAMNT003(STJ->TJ_FILIAL, STJ->TJ_ORDEM)                                       

*/


#include "TOTVS.CH"

user function QAMNT003(cFilOS, cNumOS)

    Local _cAreas   := getArea()
    Local cQuery    := ""
    Local cAliasTOP := GetNextAlias()    
    Local cRet      := ""
 
    cQuery := "SELECT SC1.C1_NUM AS NUMERO, SC1.C1_PEDIDO AS PEDIDO, "
    cQuery += "(SELECT TOP 1 SD1.D1_DOC FROM "+retSqlName("SD1")+ " SD1 WHERE SD1.D_E_L_E_T_ = ' ' AND SD1.D1_PEDIDO = SC1.C1_PEDIDO AND SD1.D1_ITEMPC = SC1.C1_ITEMPED) NOTAFIS "
    cQuery += "FROM "+retSqlName("SC1")+ " SC1 "
    cQuery += "WHERE SC1.D_E_L_E_T_ = ' ' "
    cQuery += "AND SC1.C1_FILIAL = '"+STJ->TJ_FILIAL+"' AND SC1.C1_OS = '"+STJ->TJ_ORDEM+"' "
    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasTop,.T.,.T.)    

    if !empty((cAliasTOP)->PEDIDO)
        cUltAprov := U_QACOM017(cFilOS,(cAliasTOP)->PEDIDO)
    else
        cUltAprov := ""
    endif

    cRet := "SC:"+(cAliasTop)->NUMERO+" PC:"+if(empty((cAliasTOP)->PEDIDO),"      ",(cAliasTOP)->PEDIDO)+" Ult.AProv: "+alltrim(cUltAprov)+" NF:"+(cAliasTOP)->NOTAFIS
    (cAliasTop)->(DbCloseArea())

    RestArea(_cAreas)
return(cRet)
