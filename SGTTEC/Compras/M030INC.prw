#include "rwmake.ch"  
/*
_____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ M030INC    ¦ Autor ¦ Claudio Ferreira    ¦ Data ¦ 14/03/12 ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ Ponto de Entrada apos a inclusao do cliente preenche       ¦¦¦
¦¦¦          ¦ a tabela CTD - Item Contabil                               ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦ Uso      ¦ TOTVS-GO                                                   ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/

User Function M030INC()                       

// Inclusao no Item Contabil. //Cliente
Dbselectarea("CTD")
Dbsetorder(1)
cChave := alltrim(SA1->A1_COD)+SA1->A1_LOJA
IF CTD->(Dbseek(xFilial("CTD")+"C"+cChave))
	_lGrv :=.f.
ELSE
	_lGrv :=.t.
ENDIF

If RecLock("CTD",_lGrv)
	cCPFCNPJ:=TransForm(SA1->A1_CGC,IIf(Len(AllTrim(SA1->A1_CGC))<>14,"@r 999.999.999-99","@r 99.999.999/9999-99"))	
	CTD->CTD_FILIAL := xFilial("CTD")
	CTD->CTD_ITEM   := "C"+cChave
	CTD->CTD_DESC01 := SA1->A1_NOME
	CTD->CTD_CLASSE := "2"
	CTD->CTD_NORMAL := "2"
	CTD->CTD_BLOQ   := "2"
	CTD->CTD_DTEXIS := CtoD("01/01/2012")
	CTD->CTD_ITLP   := CTD->CTD_ITEM
	CTD->CTD_CLOBRG := "2"
	CTD->CTD_ACCLVL := "1"
	CTD->CTD_BOOK   := "AUTO"
	MsUnlock("CTD")
EndIf

Return
