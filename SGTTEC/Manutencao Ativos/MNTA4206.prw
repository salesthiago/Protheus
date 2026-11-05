/*
Ponto de Entrada que permite a inclusão de campos na rotina de OS Corretiva. 
Incluir os Campos:
TJ_DTMPFIM - Data Fim para término na OS
TJ_HOMPFIM - Hora fim para término da OS

Data: 09/2021
Autor: Sinval

*/
#Include 'Protheus.ch'

User Function MNTA4206()

AAdd(aChoice,"TJ_DTMPFIM") 
AAdd(aChoice,"TJ_HOMPFIM") 
Aadd(aChoice,"TJ_STFOLUP")
Aadd(aChoice,"TJ_MOTREPR")

Return .T.
