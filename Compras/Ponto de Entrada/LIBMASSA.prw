#Include 'Protheus.ch'
#Include "TopConn.ch"
#Include "Totvs.ch"
#INCLUDE 'RWMAKE.CH'
#INCLUDE 'TBICONN.CH'
#INCLUDE 'FWMVCDEF.CH'

/*/{Protheus.doc} LibMassa
    (long_description)
    @type  Static Function
    @author Stephen Noel - SGTTEC
    @since 09/05/2024
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
/*/
User Function LibMassa()
	Static oButton1
	Static oButton2
	Local oGet1
	Static cGet1 := "      "
	Local oGet2
	Static cGet2 := "      "
	//Local oGroup1
	Local oSay1
	Local oSay2
	Static oDlg

	DEFINE MSDIALOG oDlg TITLE "Aprovacao em Lote" FROM 000, 000  TO 500, 400 COLORS 0, 16777215 PIXEL

	//@ 004, 010 GROUP oGroup1 TO 210, 245 PROMPT "Liberacao em Lote" OF oDlg COLOR 0, 16777215 PIXEL
	@ 036, 020 SAY oSay1 PROMPT "Pedido de:" SIZE 035, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 058, 020 SAY oSay2 PROMPT "Pedido Até:" SIZE 037, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 033, 068 MSGET oGet1 VAR cGet1 SIZE 095, 010 OF oDlg VALID Valida() COLORS 0, 16777215 F3 "SC7" PIXEL
	@ 056, 068 MSGET oGet2 VAR cGet2 SIZE 094, 010 OF oDlg VALID Valida() COLORS 0, 16777215 F3 "SC7" PIXEL
	@ 165, 065 BUTTON oButton1 PROMPT "Cancela" SIZE 037, 012 OF oDlg PIXEL ACTION (oDlg:End())
	@ 165, 147 BUTTON oButton2 PROMPT "Libera" SIZE 037, 012 OF oDlg PIXEL ACTION MsgRun('Processando Pedidos Selecionados...','Liberando',{|| Processa() })

	ACTIVATE MSDIALOG oDlg CENTERED

Return

Static Function Processa()

	Local cQuery := ""
	Local cAliasAux := GetNextAlias()

	cQuery += " SELECT R_E_C_N_O_ RECNO,* FROM "+RetSqlName("SCR") +" SCR "
	cQuery += " WHERE SCR.D_E_L_E_T_ = ' ' "
	cQuery += " AND CR_TIPO IN ('PC','IP') "
	cQuery += " AND CR_STATUS = '02' "
	cQuery += " AND CR_USER = '"+RetCodUsr()+"' "
	cQuery += " AND CR_FILIAL = '"+cFilant+"' "
	cQuery += " AND CR_NUM >= '"+cGet1+"'"
	cQuery += " AND CR_NUM <= '"+cGet2+"'"
	//CR_USER CR_APROV CR_FILIAL CR_STATUS='02' PARA 3
	TCQuery cQuery New Alias &cAliasAux

	If (cAliasAux)->(EoF())
		MsgInfo("Não Existem Pedidos para serem liberados Para os parametros!", "Atenção")
	Else
		(cAliasAux)->(DBGoTop())
		While (cAliasAux)->(!EoF())
			MyExec094((cAliasAux)->RECNO)
			(cAliasAux)->(DBSkip())
		End
		MsgInfo("Pedidos Processados","Atanção")
	EndIf

	(cAliasAux)->(DbCloseArea())

Return

Static Function Valida()

	Local lRet:= .t.

	If (empty(cGet1) .or. empty(cGet1))
		MsgInfo("Necessário definir os Parametros","Atenção")
		lRet:= .f.
	EndIf

Return lRet


Static Function MyExec094(nRecno)

	Default nRecno := 0

	Local oModel094 := Nil      //-- Objeto que receberá o modelo da MATA094
	Local nLenSCR   := 0        //-- Controle de tamanho de campo do documento
	Local lOk       := .T.      //-- Controle de validação e commit
	Local aErro     := {}       //-- Recebe msg de erro de processamento

	nLenSCR := TamSX3("CR_NUM")[1] //-- Obtem tamanho do campo CR_NUM
	DbSelectArea("SCR")
	SCR->(DbSetOrder(1)) //-- CR_FILIAL+CR_TIPO+CR_NUM+CR_APROV
	SCR->(DBGoTop())
	If nRecno > 0
		SCR->(DBGoTo(nRecno))

		//-- Códigos de operações possíveis:
		//--    "001" // Liberado
		//--    "002" // Estornar
		//--    "003" // Superior
		//--    "004" // Transferir Superior
		//--    "005" // Rejeitado
		//--    "006" // Bloqueio
		//--    "007" // Visualizacao

		//-- Seleciona a operação de aprovação de documentos
		A094SetOp('001')

		//-- Carrega o modelo de dados e seleciona a operação de aprovação (UPDATE)
		oModel094 := FWLoadModel('MATA094')
		oModel094:SetOperation( MODEL_OPERATION_UPDATE )
		oModel094:Activate()

		//-- Valida o formulário
		lOk := oModel094:VldData()

		If lOk
			//-- Se validou, grava o formulário
			lOk := oModel094:CommitData()
		EndIf

		//-- Avalia erros
		If !lOk
			//-- Busca o Erro do Modelo de Dados
			aErro := oModel094:GetErrorMessage()

			//-- Monta o Texto que será mostrado na tela
			AutoGrLog("Id do formulário de origem:" + ' [' + AllToChar(aErro[01]) + ']')
			AutoGrLog("Id do campo de origem: "     + ' [' + AllToChar(aErro[02]) + ']')
			AutoGrLog("Id do formulário de erro: "  + ' [' + AllToChar(aErro[03]) + ']')
			AutoGrLog("Id do campo de erro: "       + ' [' + AllToChar(aErro[04]) + ']')
			AutoGrLog("Id do erro: "                + ' [' + AllToChar(aErro[05]) + ']')
			AutoGrLog("Mensagem do erro: "          + ' [' + AllToChar(aErro[06]) + ']')
			AutoGrLog("Mensagem da solução:"        + ' [' + AllToChar(aErro[07]) + ']')
			AutoGrLog("Valor atribuído: "           + ' [' + AllToChar(aErro[08]) + ']')
			AutoGrLog("Valor anterior: "            + ' [' + AllToChar(aErro[09]) + ']')

			//-- Mostra a mensagem de Erro
			MostraErro()
		EndIf

		//-- Desativa o modelo de dados
		oModel094:DeActivate()
	EndIf

Return Nil
