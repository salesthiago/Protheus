/*
Ponto de Entrada para não permitir novas pesagens no romaneio após as duas pesagens

Autor: Sinval
Data: 08/10/2022

*/                   

#include "totvs.ch"

user function OG250PES()

    //Local aPar  := PARAMIXB
    Local lret  := .T.
    /*
    if FwFldGet('NJJ_PESO1') > 0 .AND. FwFldGet('NJJ_PESO2') > 0 

        MsgAlert("Duas Pesagens já foram realizadas","Operação não Permitida")

        lRet := .F.

    endif
    */
return(lRet)
