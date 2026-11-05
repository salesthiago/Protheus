#Include "Protheus.ch"
#Include "TopConn.ch"

/*/{Protheus.doc} MT110FIL
	Programa que Filtra as solicitações conforme Regra
	@type  Static Function
	@author Stephen Noel - SGTTEC
	@since 21/04/2024
	@version 1.0
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
/*/
User Function MT110FIL()

	Local cFiltro 	:= ''
	Local UsuLog	:= RetCodUsr()
	Local cQuery	:= ''
	Local cCusApv   := ''
	Local lCompra   := .f.
	Local _Aarea    := GetArea()
	Local _lAtivo	:= SuperGetMV("MV_XAPVSC", .F., .F.)

	If (FWCodEmp() <> '02' .OR. !_lAtivo) //Regra Aplicada Apenas para LimpaGyn
		Return (cFiltro)
	EndIf
	//Verifica se o Usuario logado é comprador
	DbSelectArea('SY1')
	SY1->(DbSetOrder(3)) //Filial + Cod. Usuario
	If dbSeek(FWxFilial('SY1')+UsuLog)
		lCompra:=.t.
	EndIf
	SY1->(dbCloseArea())

	If !lCompra
		cQuery+= " SELECT "
		cQuery+= " CTT.CTT_CUSTO FROM "+RetSqlName("CTT") +" CTT " 
		cQuery+= " WHERE CTT.D_E_L_E_T_= ' ' "
		cQuery+= "AND CTT_APROVA = '"+UsuLog+"' "

		TCQuery cQuery New Alias "TMP1"

		While tmp1->(!EOf())
			cCusApv+= "/"+tmp1->CTT_CUSTO
			TMP1->(DbSkip())
		EndDo
		If !empty(cCusApv) //Caso seja aprovador, busca todas SCs do Centro de Custos
			cFiltro :=  " Alltrim(C1_CC)$ '"+cCusApv+"'"
		Else //Caso nao seja Comprador nem aprovador, filtra apenas as proprias SCs
			cFiltro := 	"C1_USER == '"+UsuLog+"'"
		EndIf
	EndIf

	RestArea(_Aarea)

Return (cFiltro)
