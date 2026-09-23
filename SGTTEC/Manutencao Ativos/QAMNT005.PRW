/*
Função para retornar o campo observação da SS
Sinval
03/2025
U_QAMNT005(TQB->TQB_CODMSS)       CRIADO O CAMPO TQB_XOBS                                              
*/
#include "TOTVS.CH"

user function QAMNT005(cCodMSS)
    Local ctexto := ""
    
    if SYP->(dbSeek(xFilial("SYP")+cCodMSS))
        do while SYP->(!Eof()) .and. SYP->YP_CHAVE == cCodMSS

            cTexto += alltrim(StrTran(SYP->YP_TEXTO,"\13\10",""))

            SYP->(DbSkip())
        enddo
    endif


return(cTexto)
