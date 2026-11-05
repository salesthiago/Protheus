/*
Ponto de entrada para gravar o código do combustível para Bem
sistema não está gravando informação do código do combustível.
*/

#Include 'Protheus.ch'
 
User Function MNTA6351()
 
    Local aParam    := Paramixb
    Local nRegTQN   := aParam[1]
    Local cPlaca    := aParam[4,2]
 
    if empty(alltrim(TQN->TQN_CODCOM))
        TQN->(RecLock("TQN",.F.))
        TQN->TQN_CODCOM := aParam[04,03]
        TQN->(MsUnLock())
    endif
    
Return Nil
