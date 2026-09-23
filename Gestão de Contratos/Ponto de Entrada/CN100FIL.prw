/*
Ponto de entrada para filtrar os contrato conforme os usuários, 
contratos de compras ou contratos de vendas

Sinval
04/2025

*/

User Function CN100FIL()

    Local ExpC1 := ""
    //Filtro específico do usuário
    if  cEmpant = "01"
        if __cUserId $ GETMV("MV_XGCTUSV")
            ExpC1 := "CN9_ESPCTR='2'"
        elseif __cUserId $ GETMV("MV_XGCTUSC")
                ExpC1 := "CN9_ESPCTR='1'"    
        else
            ExpC1 := "CN9_FILIAL='9999'"
        endif
    endif

Return ExpC1
