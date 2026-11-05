/*
Ponto de entrada para substituição da impressão da OS
ExecBlock("MNTIMPOS",.F.,.F.,{stj->tj_plano,stj->tj_ordem,stj->tj_dtmpini})

Data: 04/2022
Sinval
*/

#Include 'Protheus.ch'
 
User Function MNTIMPOS()
 
    Local aParam    := Paramixb
    Local cPlanode  := aParam[4]
    Local cPlanoAte := aParam[5]    
    Local cOrdem    := aParam[2]
    Local cDtIni    := aParam[3]
    Local aRelOS    := aParam[6]
    Local nIt

    for nIt := 1 to len(aRelOS)
        
        STJ->(DbSetOrder(1))
        if STJ->(DbSeek(xFilial("STJ")+aRelOS[nIt][2]))

            aMATSX1 := {    {'01', Space(Len(stj->tj_plano))},{'02',Replicate('Z',Len(stj->tj_plano))},;
                            {'07', Space(Len(stj->tj_ccusto))},{'08',Replicate('Z',Len(stj->tj_ccusto))},;
                            {'09', Space(Len(stj->tj_centrab))},{'10',Replicate('Z',Len(stj->tj_centrab))},;
                            {'11', Space(Len(stj->tj_codarea))},{'12',Replicate('Z',Len(stj->tj_codarea))},;
                            {'13', STJ->TJ_ORDEM},{'14',STJ->TJ_ORDEM},{'15',STJ->TJ_DTMPINI},;
                            {'16', STJ->TJ_DTMPINI} }        

            U_QMNTR675(.F.,,,,4,aMATSX1,STJ->(RECNO()))
        
        //U_QMNTR675(.F.,cPlanode,cPlanoAte,aRelOS,4,,)
        EndIf
    
    Next
 
Return Nil
