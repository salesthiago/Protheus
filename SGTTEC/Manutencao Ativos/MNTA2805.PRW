/*

Alteração da legenda Solicitação de Serviços
10/2024
Sinval

*/

#include "rwmake.ch"      

User Function MNTA2805()

//Acesso: aCoresPE
//Acesso: aVarsPE

aCORES := {;
	{"MNTA280Atr()",'BR_AMARELO'},;
	{"NGSEMAFARO('TQB->TQB_SOLUCA == "+'"A"'+"')",'BR_VERMELHO'},;
	{"NGSEMAFARO('TQB->TQB_SOLUCA == "+'"D"'+"')",'BR_VERDE'},;
	{"NGSEMAFARO('TQB->TQB_SOLUCA == "+'"C"'+"')",'BR_PRETO'},;
	{"NGSEMAFARO('TQB->TQB_SOLUCA == "+'"T"'+"')",'BR_AMARELO'},;
    {"NGSEMAFARO('TQB->TQB_SOLUCA == "+'"E"'+"')",'BR_AZUL'}}

Return aCores
