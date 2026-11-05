//para obter as informações de inclusão

//cUserI := FWLeUserlg("F1_USERLGI", 1)
//cDataI := FWLeUserlg("F1_USERLGI", 2)
// para obter as informações de alteração
//cUserA := FWLeUserlg("A1_USERLGA", 1)
//cDataA := FWLeUserlg("A1_USERLGA", 2)

#include "totvs.ch"

user function QACOM003()

    SF1->(DbSetOrder(1))
    SF1->(DbGoTop())    
    do while SF1->(!Eof())
        SE2->(DbSetOrder(6)) //E2_FILIAL+E2_FORNECE+E2_LOJA+E2_PREFIXO+E2_NUM
        if SE2->(DbSeek(SF1->(F1_FILIAL+F1_FORNECE+F1_LOJA+F1_SERIE+F1_DOC)))
            if empty(SE2->E2_XCP)
                SE2->(RecLock("SE2",.F.))
                SE2->E2_XCP    := SF1->F1_COND
                SE2->E2_XUSRNF := FWLeUserlg("F1_USERLGI", 1)
                SE2->E2_XDTNF  := ctod(FWLeUserlg("F1_USERLGI", 2))
                //SE2->E2_XHRNF  := time() 
                SE2->(MsUnLock())
            endif
        endif
        
        SF1->(DbSkip())
    EndDo
    
return(.T.)
