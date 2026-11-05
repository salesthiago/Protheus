/*
Ponto de entrada 
para filtrar apenas alguns tipos de títulos no financeiro no momento da realização do borderô

processo ocorrerá na limpagyn

Sinval
05/2025
*/

#Include 'Protheus.ch'
 
User Function F240FIL()

    Local cTipos := GETMV("MV_XFITPTI",.F.,"E2_TIPO $ 'NF-BOL-MAN-PX '")

    if cEmpAnt = "02"
        cRet := cTipos
    else
        cRet := ""
    endif
 
Return(cRet)
