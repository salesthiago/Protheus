#Include "Protheus.ch"

/*/{Protheus.doc} MA103OPC
Ponto de entrada do MATA103 (Cadastro de Fornecedores) que adiciona uma
opcao de menu para ativar/desativar os parametros MV_CHVNFE e MV_DCHVNFE.
@type Function
@author Thiago Sales
@since 18/09/2026
@version 1.0
@param aRotina, Array, menu de opcoes padrao do MATA103 (recebido via PARAMIXB[1])
@return aRotina, Array, menu de opcoes com a nova entrada acrescentada
/*/
User Function MA103OPC()

	Local aRotina := {}

	Aadd(aRotina, {"Parametros NFe", "U_MA103NFE", 0, 5}) 

Return aRotina

/*/{Protheus.doc} MA103NFE
Tela simples para o usuario ativar ou desativar os parametros MV_CHVNFE e
MV_DCHVNFE. Caixa marcada = ativado (grava .T.), desmarcada = desativado
(grava .F.).
@type Function
@author Thiago Sales
@since 18/09/2026
@version 1.0
/*/
User Function MA103NFE()

	Local oDlg
	Local oChk1
	Local oChk2
	Local lChvNfe  := GetMv("MV_CHVNFE" , , .F.)
	Local lDChvNfe := GetMv("MV_DCHVNFE", , .F.)

	DEFINE MSDIALOG oDlg TITLE "Configuracao NFe" FROM 000, 000 TO 150, 400 PIXEL

	@ 050, 010 CHECKBOX oChk1 VAR lChvNfe  PROMPT "Ativar exigencia de Chave de Acesso da NFe (MV_CHVNFE)"   SIZE 370, 010 OF oDlg PIXEL
	@ 068, 010 CHECKBOX oChk2 VAR lDChvNfe PROMPT "Ativar debito automatico da Chave de Acesso (MV_DCHVNFE)" SIZE 370, 010 OF oDlg PIXEL

	EnchoiceBar(oDlg, {|| MA103Ok(lChvNfe, lDChvNfe, oDlg) }, {|| oDlg:End() })

	ACTIVATE MSDIALOG oDlg CENTERED

Return Nil

/*/{Protheus.doc} MA103Ok
Confirma a tela MA103NFE: grava os parametros e fecha o dialogo.
@type Static Function
@author Thiago Sales
@since 18/09/2026
@version 1.0
/*/
Static Function MA103Ok(lChvNfe, lDChvNfe, oDlg)

	MA103PMV(lChvNfe, lDChvNfe)
	oDlg:End()

Return Nil

/*/{Protheus.doc} MA103PMV
Grava os parametros MV_CHVNFE e MV_DCHVNFE de acordo com a marcacao feita
pelo usuario na tela MA103NFE.
@type Static Function
@author Thiago Sales
@since 18/09/2026
@version 1.0
@param lChvNfe,  Logico, .T. para ativar MV_CHVNFE,  .F. para desativar
@param lDChvNfe, Logico, .T. para ativar MV_DCHVNFE, .F. para desativar
/*/
Static Function MA103PMV(lChvNfe, lDChvNfe)

	PutMv("MV_CHVNFE" , If(lChvNfe , ".T.", ".F.") )
	PutMv("MV_DCHVNFE", If(lDChvNfe, ".T.", ".F.") )

	MsgInfo("Parametros MV_CHVNFE e MV_DCHVNFE atualizados com sucesso.", "Config. NFe")

Return Nil
