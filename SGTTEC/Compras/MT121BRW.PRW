/*             
Sintaxe
MT121BRW - Ponto de Entrada para Envio de E-mail de Confirmação da chegada dos Documentos 
            Nota Fiscal e Boletos

Retorno
URET(Nil)
Menu MATA121 - Pedido de Compras
*/

#include "totvs.ch"

user function MT121BRW()

	AAdd(aRotina,{"Muda Fornecedor" ,"U_QACOM002(SC7->C7_FILIAL, SC7->C7_NUM)"  ,0,6})
	AAdd(aRotina,{"Imprime Mapa"    ,"U_RACOM003('P')"                          ,0,6})

return
