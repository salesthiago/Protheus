User Function MNTA1301()
/* ParamIXB	[1] - Importacoes		
[1]  - Filial		[2]  - Numero do Abastecimento		
[3]  - Placa do Veiculo		[4]  - Combustivel/Convenio		
[5]  - CPF do Motorista		[6]  - Posicao do Contador		
[7]  - Quantidade de Combustivel Abastecido		
[8]  - Valor Unitario do Combustivel		
[9]  - Data do Abastecimento		
[10] - Hora do Abastecimento		
[11] - Posicao do Contador 2 (zerado se nao houver segundo contador - 0)*/

Local aImport := aClone(ParamIXB[1])

MsgInfo("Importações: "+Len(aImport),"P.E. MNTA1301")

Return .T.
