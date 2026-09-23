/*/{Protheus.doc} FA460FIL
    (manipula o filtro incluindo o número do contrato = Busca de SE2->E2_XCP (Cond Pagamento)
    @type  Function
    @author Sinval
    @since 15/12/2021
    @version 1.0
    @param (cTabela, cCampo), Character, Passa a Tabela a ser verificada
    @return (cRet)
    @example 
    (FA460FIL())
    @see 
/*/
#include "totvs.ch"

user function FA565FIL()
    local cRet := ""

    if MsgYesNo("Deseja Liquidar Títulos do Cartão ?","Filtra Títulos Cartão")

        cRet := " AND E2_XCP = '"+SE2->E2_XCP+"' "

    endif

return(cRet)
