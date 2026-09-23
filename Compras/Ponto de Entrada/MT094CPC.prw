#Include "Protheus.ch"
#Include "TopConn.ch"

/*/{Protheus.doc} MT094CPC
	Adiciona campso do pedido de compras no momento da aprovação
	@type  Static Function
	@author Stephen Noel - SGTTEC
	@since 05/05/2024
	@version 1.0
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
/*/

User Function MT094CPC()

	Local cCampos := " "

	If AllToChar(FWCodEmp()) == '02' //Valida se a empresa é a 02
	
		cCampos := "C7_DESC|C7_VLDESC|C7_OBS|C7_XINFCOM|C7_ACCNUM|C7_CONTA40|C7_CONTA|C7_OP" //A separação dos campos devem ser feitos com uma barra vertical ( | ), igual é demonstrado no exemplo.

	else

		cCampos := "C7_DESC|C7_VLDESC|C7_OBS"

	endIf

Return(cCampos)
