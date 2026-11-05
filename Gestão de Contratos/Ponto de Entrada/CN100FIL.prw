/*
Ponto de entrada para filtrar os contrato conforme os usuários, 
contratos de compras ou contratos de vendas

Sinval
04/2025

Ajuste 09/2026: o usuário pode estar em um ou nos dois parâmetros
  - MV_XGCTUSC (compras) -> CN9_ESPCTR = '1'
  - MV_XGCTUSV (vendas)  -> CN9_ESPCTR = '2'
  - nos dois             -> sem restrição de espécie (compra e venda)
  - em nenhum            -> não visualiza contratos
Também usado pelo RTM003App (listagem de contratos).
*/

User Function CN100FIL()

    Local ExpC1   := ""
    Local cUsrVen := ""
    Local cUsrCom := ""
    Local lVenda  := .F.
    Local lCompra := .F.

    //Filtro específico do usuário
    if  cEmpant = "01"
        cUsrVen := AllTrim(SuperGetMV("MV_XGCTUSV", .F., ""))
        cUsrCom := AllTrim(SuperGetMV("MV_XGCTUSC", .F., ""))

        lVenda  := !Empty(cUsrVen) .And. __cUserId $ cUsrVen
        lCompra := !Empty(cUsrCom) .And. __cUserId $ cUsrCom

        if lVenda .And. lCompra
            ExpC1 := ""                      // compras e vendas: sem restrição
        elseif lVenda
            ExpC1 := "CN9_ESPCTR='2'"
        elseif lCompra
            ExpC1 := "CN9_ESPCTR='1'"
        else
            ExpC1 := "CN9_FILIAL='9999'"
        endif
    endif

Return ExpC1
