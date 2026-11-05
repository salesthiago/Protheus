#Include "Protheus.ch"
#Include "TopConn.ch"

/*/{Protheus.doc} InicBrow
    Inicializador padrao de campos da rotina de aprovaçaõ
    @type  User Function
    @author Stephen Noel  - SGTTEC
    @since 16/05/2024
    @version 1.0
    @see (links_or_references)
    /*/
User Function InicBrow(cPar)//u_InicBrow('01')

	Local aArea     := GetArea()
	Local cVarIniPd := ""

	If cPar == '01'
		cVarIniPd :=Solici()
	ElseIf cPar == '02'
		cVarIniPd :=JaAprovou()
	ElseIf cPar == '03'
		cVarIniPd :=RetFonre()
	ElseIf cPar == '04'
		cVarIniPd :=RetProds()
	elseif cPar == '05'   //Observações dos pedidos
		cVarIniPd :=RetObs()
	
	EndIf

	RestArea(aArea)

Return cVarIniPd

Static Function Solici()

	Local cNumSC := Posicione('SC7',1,xFilial('SC7')+Alltrim(SCR->CR_NUM),'C7_NUMSC')
	Local aSolic := Posicione('SC1',1,xFilial('SC1')+cNumSC,'C1_SOLICIT')

Return aSolic

Static Function JaAprovou()

	Local cAprov   := ''
	Local cQuery := ""
	Local cAliasAux := GetNextAlias()

	cQuery += " SELECT CR_LIBAPRO, SAK.AK_LOGIN NOMEAPROV, SCR.CR_DATALIB "
	cQuery += " FROM "+RetSqlName("SCR") +" SCR "
	cQuery += " INNER JOIN "+retSqlName("SAK") + " SAK ON (SAK.D_E_L_E_T_ = ' ' AND SAK.AK_COD = SCR.CR_LIBAPRO AND SAK.AK_FILIAL = SCR.CR_FILIAL) "	
	cQuery += " WHERE SCR.D_E_L_E_T_ = ' ' "
	//cQuery += " AND CR_TIPO IN ('PC','IP') "
	//cQuery += " AND CR_STATUS IN ('02','05') "
	cQuery += " AND SCR.CR_LIBAPRO <> '      '"
	cQuery += " AND SCR.CR_FILIAL = '"+SCR->CR_FILIAL+"' "
	cQuery += " AND SCR.CR_NUM = '"+SCR->CR_NUM+"'"

	TCQuery cQuery New Alias &cAliasAux

	While (cAliasAux)->(!Eof())
		cAprov+= Iif(empty(cAprov),AllTrim((cAliasAux)->NOMEAPROV)+"-"+dtoc(STOD((cAliasAux)->CR_DATALIB)), "/"+AllTrim((cAliasAux)->NOMEAPROV)+"-"+dtoc(STOD((cAliasAux)->CR_DATALIB)))
		(cAliasAux)->(DBSkip())
	EndDo

	(cAliasAux)->(DBCloseArea())

Return cAprov

Static Function RetFonre()

	Local cNomeFor := ''

	DbSelectArea('SC7')
	SC7->(DBSetOrder(1))
	If SC7->(DBSeek(fwxFilial('SC7')+Alltrim(SCR->CR_NUM)))
		cNomeFor := Posicione('SA2',1,XFILIAL('SA2')+SC7->(C7_FORNECE+C7_LOJA),'A2_NOME')
	EndIf
	SC7->(DBCloseArea())

Return cNomeFor


Static Function RetProds()

	Local cProds:= " "
	Local cQuery := ""
	Local cAliasAux := GetNextAlias()

	cQuery += " SELECT B1_DESC FROM SC7020 SC7"
	cQuery += " INNER JOIN SB1020  SB1 ON B1_COD =  C7_PRODUTO "
	cQuery += " WHERE  SB1.D_E_L_E_T_ = ' ' "
	cQuery += " AND  SC7.D_E_L_E_T_ = ' ' "
	cQuery += " AND C7_FILIAL = '"+SCR->CR_FILIAL+"' "
	cQuery += " AND C7_NUM = '"+SCR->CR_NUM+"'"


	TCQuery cQuery New Alias &cAliasAux

	While (cAliasAux)->(!Eof())
		cProds+= Iif(empty(cProds),AllTrim((cAliasAux)->B1_DESC), " / "+AllTrim((cAliasAux)->B1_DESC))
		(cAliasAux)->(DBSkip())
	EndDo

	(cAliasAux)->(DBCloseArea())


Return cProds

Static Function RetObs()

	Local cObs := ""
	Local cQuery := ""
	Local cAliasAux := GetNextAlias()

	cQuery += " SELECT DISTINCT C7_OBS, C7_XINFCOM "
	cQuery += " FROM "+retSqlName("SC7") + " SC7 "
	cQuery += " WHERE  SC7.D_E_L_E_T_ = ' ' "
	cQuery += " AND  SC7.D_E_L_E_T_ = ' ' "
	cQuery += " AND C7_FILIAL = '"+SCR->CR_FILIAL+"' "
	cQuery += " AND C7_NUM = '"+SCR->CR_NUM+"'"
	TCQuery cQuery New Alias &cAliasAux

	While (cAliasAux)->(!Eof())
		if !Empty(alltrim((cAliasAux)->C7_OBS)) .or. !Empty(alltrim((cAliasAux)->C7_XINFCOM))
			cObs+= " "+AllTrim((cAliasAux)->C7_OBS)+ ","+AllTrim((cAliasAux)->C7_XINFCOM)
		Endif
		(cAliasAux)->(DBSkip())
	EndDo

	(cAliasAux)->(DBCloseArea())

Return(cObs)
