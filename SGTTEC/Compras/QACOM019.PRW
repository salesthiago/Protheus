#INCLUDE "TOTVS.CH"

user function QACOM019(cFilPed, cNumPed)
	Local ctexto 	:= ""
	Local cTipo 	:= "IP"

	SCR->(DbSetOrder(1))
	SCR->(DbSeek(cFilped+cTipo+cNumPed))
	do while SCR->(!Eof()) .and. SCR->(CR_FILIAL+CR_TIPO+substr(CR_NUM,1,6)) == cFilPed + cTipo + cNumPed
		cTexto += alltrim(SCR->CR_OBS)
		SCR->(DbSkip())
	enddo
	
return(cTexto)
