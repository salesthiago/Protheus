#Include "Protheus.ch"
#Include "TopConn.ch"

/*/{Protheus.doc} MT110APV
	Valida se o Liberador é o gestor do Centro de Custos
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
User Function MT110APV()

	Local lRet      :=.T.
	Local cAprov    := Posicione('CTT',1,FWxFilial('CTT')+SC1->C1_CC,'CTT_APROVA')
	Local UsuLog	:= RetCodUsr()
	Local _lAtivo	:= SuperGetMV("MV_XAPVSC", .F., .F.)

	If (FWCodEmp() <> '02' .OR. !_lAtivo) //Regra Aplicada Apenas para LimpaGyn
		Return lRet
	EndIf

	If !Alltrim(cAprov) == AllTrim(UsuLog)
		MsgAlert("Você não tem autorização para Liberar esta SC, Procure o gestor do Centro de Custos!","ATENÇÃO!")
		lRet := .F.
	EndIf

Return lRet
 