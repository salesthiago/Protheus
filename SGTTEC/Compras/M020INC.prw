#include "rwmake.ch"      
/*
_____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ M020INC    ¦ Autor ¦ Claudio Ferreira   ¦ Data ¦ 14/02/2012¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ Ponto de Entrada apos a inclusao do fornecedor preenche    ¦¦¦
¦¦¦          ¦ a tabela CTD - Item Contabil                               ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦ Uso      ¦ TOTVS-GO                                                   ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/

User Function M020INC()          

// Inclusao no Item Contabil. //Fornecedor
Dbselectarea("CTD")
Dbsetorder(1)
cChave := alltrim(SA2->A2_COD)+SA2->A2_LOJA
IF CTD->(Dbseek(xFilial("CTD")+"F"+cChave))
	_lGrv :=.f.
ELSE
	_lGrv :=.t.
ENDIF

If RecLock("CTD",_lGrv)
	cCPFCNPJ:=TransForm(SA2->A2_CGC,IIf(Len(AllTrim(SA2->A2_CGC))<>14,"@r 999.999.999-99","@r 99.999.999/9999-99"))	
	CTD->CTD_FILIAL := xFilial("CTD")
	CTD->CTD_ITEM   := "F"+cChave
	CTD->CTD_DESC01 := SA2->A2_NOME
	CTD->CTD_CLASSE := "2"
	CTD->CTD_NORMAL := "1"
	CTD->CTD_BLOQ   := "2"
	CTD->CTD_DTEXIS := CtoD("01/01/2010")
	CTD->CTD_ITLP   := CTD->CTD_ITEM
	CTD->CTD_CLOBRG := "2"
	CTD->CTD_ACCLVL := "1"  
	CTD->CTD_BOOK   := "AUTO"
	MsUnlock("CTD")
EndIf

Return
