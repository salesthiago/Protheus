#INCLUDE 'RWMAKE.CH'
User Function GPXMEDPD
Local cCodigo       := paramixb[1]
Local Pd            := paramixb[2]
Local cMedFer       := PosSrv( cCodigo , SRA->RA_FILIAL , 'RV_MEDFER' )
Local cMed13        := SRV->RV_MED13
Local cMedAvi       := SRV->RV_MEDAVI
Local lRet          := .F.

    if cCodigo $ "420-421"
        lRet := .F.

    elseIf  ( !Empty(cMedFer) .And. cMedFer != 'N ' ) .Or. ( !Empty(cMed13)  .And. cMed13  != 'N ' ) .Or.  ( !Empty(cMedAvi) .And. cMedAvi != 'N ' )   
        lRet        := .T.
    EndIf
 
Return(lRet)
