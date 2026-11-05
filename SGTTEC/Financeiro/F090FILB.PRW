/*

F090QFIL - Ponto de entrada para filtrar os registros da Baixa Pagar Automática
Utilizada pois com a mudança da rotina de baixas automáticas, foi necessário tirar a Filial do filtro padrão.

*/

#INCLUDE "TOTVS.CH"

user function F090FILB()

    Local cFiltro := ""

    cFiltro := " (E2_DATALIB <> '        ' OR (E2_SALDO+E2_SDACRES-E2_SDDECRE) <= "+Alltrim(Str(GetMv('MV_VLMINPG'),15,7))+")"

return(cFiltro)


