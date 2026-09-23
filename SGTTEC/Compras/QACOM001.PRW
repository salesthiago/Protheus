 #include "protheus.ch"
 
 /*/{Protheus.doc} QACOM001
    Realizar o preenchimento do campo da Nota Fiscal com 9 posições
    @type  Function
    @author sinval
    @since 17/11/2021
    @version 1.0
    @param cNumCaixa, Character, Número da caixa Digitado no Pedido de Venda
    @return (lPermite), Lógico, (Retorna se Permite incluir o Número da caixa)
    @example
    (Não tem exemplo)
    @see (Não tem Link)
/*/

user Function QACOM001(cNumNF)
    Local lRet := .T.      

    if len(alltrim(cNumNF)) < 9
        cNFiscal    := strZero(val(cNumNF),9)
        cNFiscal2   := strZero(val(cNumNF),9)
    endif

    &(ReadVar())

return(lRet)
