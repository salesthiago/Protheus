/*

Ponto de entrada para restaurar o conteúdo do parâmetro alterado no pe fc021cpo

*/

#include "totvs.ch"

user function FC021ATRB()

    //Local aComplem  := PARAMIXB
    Local _aAreas   := getArea()
/*
    if aComplem[3] = "E2"
        if FINC021->E2_DESDOBR = "S"
            FINC021->E2_DESDOBR := "N"
        endif
    endif
*/
    PUTMV("MV_NRASDSD",".F.")

    restArea(_aAreas)

return(nil)
