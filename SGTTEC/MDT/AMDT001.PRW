#include "totvs.ch"

/*
Função para retornar texto padrão para os campos da tabela TMU

*/

user function fFunTxt(cNomCampo)

    Local cTexto := ""

    if cNomCampo  = "TMT_MHISPR"
        cTexto := "Nega comorbidades"+chr(13)+chr(10)
        ctexto += "Nega medicamento de uso contínuo"+chr(13)+chr(10)
        ctexto += "Nega alergia"+chr(13)+chr(10)
        ctexto += "Nega tabagismo"+chr(13)+chr(10)
        ctexto += "Nega etilismo"
    EndIf
    
return(cTexto)
