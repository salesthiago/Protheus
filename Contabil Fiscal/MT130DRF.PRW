#Include 'Protheus.ch'
/*/
Autor: Avenues
Data: 04/04/2019
Descricao: Automatização de Códigos de Retenção - Documento de Entrada
/*/
User Function MT103DRF()

Local nCombo := PARAMIXB[1]
Local cCodRet := PARAMIXB[2]
Local oCombo := PARAMIXB[3]
Local oCodRet := PARAMIXB[4]
Local aImpRet := {}
nCombo := 1
cCodRet := if ( !Empty(SA2->A2_XCODRET), SA2->A2_XCODRET , "1708" ) 
aadd(aImpRet,{"IRR",nCombo,cCodRet})
nCombo := 1
cCodRet := "5952"
aadd(aImpRet,{"PIS",nCombo,cCodRet})
nCombo := 1
cCodRet := "5952"
aadd(aImpRet,{"COF",nCombo,cCodRet})
nCombo := 1
cCodRet := "5952"
aadd(aImpRet,{"CSL",nCombo,cCodRet})

Return aImpRet