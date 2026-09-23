/*
 Retorna o usuário da última aprovação
 
*/
#INCLUDE "TOTVS.CH"
user function QACOM017(cFilPed,cNumero)
    Local _cAreas   := getArea()
	local cRet 		:= ""
	Local cQuery	:= ""
	Local cAliasTop	:= getNextAlias()

	cQuery := "SELECT SCR.CR_FILIAL, SCR.CR_NUM, SCR.CR_LIBAPRO, SAK.AK_LOGIN, SCR.CR_DATALIB, SCR.CR_NIVEL "
	cQuery += "FROM "+retSqlName("SCR") + " SCR "
	cQuery += "LEFT JOIN "+retSqlName("SAK") + " SAK ON (SAK.D_E_L_E_T_ = ' ' AND SAK.AK_COD = SCR.CR_LIBAPRO AND SAK.AK_FILIAL = '    ') "
	cQuery += "WHERE SCR.D_E_L_E_T_ = ' ' AND SCR.CR_FILIAL = '"+cFilped+"' AND SCR.CR_NUM = '"+cNumero+"' AND SCR.CR_LIBAPRO <> '' "
	cQuery += "ORDER BY SCR.CR_NIVEL, SCR.CR_DATALIB "
    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasTop,.T.,.T.)    

	(cAliasTop)->(DbGoTop())
	do while (cAliasTop)->(!Eof())
		
		cRet := (cAliasTOP)->AK_LOGIN

		(cAliasTop)->(DbSkip())
	enddo

	(cAliasTop)->(DbCloseArea())

    RestArea(_cAreas)

return(cRet)
