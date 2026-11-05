#Include 'Protheus.ch'
#Include 'Topconn.ch'

#define DS_MODALFRAME   128

//--------------------------------------------------------------
/*/{Protheus.doc} MT100GE2
Description
Localização.: Function A103AtuSE2 - Rotina que efetua a integração 
entre o documento de entrada e os títulos financeiros a pagar. 
Finalidade...: Complementar a gravação na tabela dos títulos 
financeiros a pagar. 

@param xParam Parameter Description
@return xRet Return Description
@author TOTVS GOIAS
@since 21/10/2015
/*/
//--------------------------------------------------------------

User Function MT100GE2()
	Local aCols   	:= PARAMIXB[1]
	Local nOpc    	:= PARAMIXB[2]
	Local aHeadSE2	:= PARAMIXB[3]
	Local aArea		:= GetArea()
	Local aAreaSE2	:= SE2->(GetArea())
	Local nReg		:= 0
	Local cHistori	:= ""
	Local cPedidos	:= ""

	//busca pedidos de compras do documento de entrada
	cPedidos := fbuscaPed(SF1->F1_FILIAL, SF1->F1_DOC, SF1->F1_SERIE, SF1->F1_FORNECE, SF1->F1_LOJA)

	//If nOpc == 1 //.. inclusao

	SE2->E2_XCP    := SF1->F1_COND
	SE2->E2_XUSRNF := PswChave(RetCodUsr())
	SE2->E2_XDTNF  := dDataBase
	SE2->E2_XPCOMPR:= cPedidos
	SE2->E2_XHRNF  := time() 

	U_DELeCodBar({SE2->E2_PREFIXO,SE2->E2_NUM,SE2->E2_PARCELA,SE2->E2_VENCREA,SE2->E2_VALOR})
	
		//Grava o Registro
		nReg := SE2->(Recno())

		//Verifica se tem mais de uma parcela
		If Val(SE2->E2_PARCELA) > 1
			cHistori := fHistPar()
		EndIf

		//Voltaa para o registro
		SE2->(DbGoTo(nReg))

		//Chama a Tela de Digitacao do Historico
		If Empty(cHistori)
			cHistori := fHistSE2()
		EndIf

		//se o historico foi preenchido grava na SE2
		If !Empty(cHistori)
			Reclock("SE2",.F.)
			SE2->E2_HIST := cHistori
			SE2->(MsUnlock())
		EndIf

//		if SE2->E2_VALOR != 0
//			If RecLock('SE2',.F.)
//				SE2->E2_DATALIB := Date()
//				SE2->(MsUnlock())
//			endif
//		endIf

	//EndIf

	//Atualiza SZ3 -> Digitação de NF nas filiais.
	if SZ3->(DbSeek(xFilial("SZ3")+SF1->(F1_DOC + F1_SERIE + F1_FORNECE + F1_LOJA)))
		SZ3->(Reclock("SZ3",.F.))
		SZ3->Z3_DTACLA := dDataBase
		SZ3->Z3_HRACLA := time()
		SZ3->Z3_USRCLA := PSWCHAVE(RETCODUSR())
		SZ3->(MsUnlock())
	endif

	SF1->(RecLock("SF1",.F.))
	SF1->F1_XUSR := PswChave(RetCodUsr())
	SF1->(MsUnlock())

	RestArea(aAreaSE2)

Return Nil

//--------------------------------------------------------------
/*/{Protheus.doc} fHistSE2
Description : Abre a Tela para digitacao do Historico do Titulo
na entrada de nota fiscal.
           
@param xParam Parameter Description
@return xRet Return Description
@author  -
@since 21/10/2015
/*/
//--------------------------------------------------------------
Static Function fHistSE2()
	Local oGet1
	Local oGroup1
	Local oSay1
	Local oSButton1
	Local cHistSE2	:= Space(TamSX3("E2_HIST")[1])
	Local cTitulo 	:= "Historico do Documento de Entrada"

	Static oDlg

	DEFINE MSDIALOG oDlg TITLE cTitulo FROM 000, 000  TO 150, 500 COLORS 0, 16777215 PIXEL

	oDlg:lEscClose     := .F.

	@ 003, 003 GROUP oGroup1 TO 071, 247 PROMPT cTitulo OF oDlg COLOR 0, 16777215 PIXEL
	@ 031, 020 MSGET oGet1 VAR cHistSE2 SIZE 210, 011 OF oDlg COLORS 0, 16777215 PIXEL
	DEFINE SBUTTON oSButton1 FROM 049, 108 TYPE 01 OF oDlg ENABLE ACTION If(fValida(cHistSE2),cHistSE2,.F.)
	@ 019, 068 SAY oSay1 PROMPT "Digite aqui o Histórico para o Título Financeiro" SIZE 122, 007 OF oDlg COLORS 0, 16777215 PIXEL

	ACTIVATE MSDIALOG oDlg CENTERED

Return cHistSE2

//--------------------------------------------------------------
/*/{Protheus.doc} fValida
Description : Valida se o historico foi preenchido.

@param xParam Parameter Description
@return xRet Return Description
@author  -
@since 21/10/2015
/*/
//--------------------------------------------------------------
Static Function fValida(cRet)
	Local lRet := .T.

	Default cRet := ""

//Verifica se o historico foi digitado
	If Empty(cRet)
		MsgAlert("Histórico do Financeiro não Digitado, favor Digitar!")
		Return lRet := .F.
	EndIf

	oDlg:End()

Return lRet


//--------------------------------------------------------------
/*/{Protheus.doc} fHistPar
Description : Funcao para retornar o historico para mais de uma
parcela.
           
@param xParam Parameter Description
@return xRet Return Description
@author  -
@since 21/10/2015
/*/
//--------------------------------------------------------------
Static Function fHistPar()
	Local cRet 			:= ""
	Local cQuery 		:= ""
	Local cPulaLinha	:= CHR(13) + CHR(10)

	If Select("QRYSE2") > 0
		QRYSE2->(DbCloseArea())
	EndIf

//Query de Consulta
	cQuery := " SELECT TOP 1 E2_HIST FROM "+RetSqlName("SE2")+" SE2  									" + cPulaLinha
	cQuery += " WHERE SE2.D_E_L_E_T_= ' '                      											" + cPulaLinha
	cQuery += " AND SE2.E2_NUM = '" + SE2->E2_NUM + "' AND SE2.E2_PREFIXO = '" + SE2->E2_PREFIXO + "'   " + cPulaLinha
	cQuery += " AND SE2.E2_PARCELA = '1' AND SE2.E2_TIPO = '" + SE2->E2_TIPO + "' 						" + cPulaLinha
	cQuery += " AND SE2.E2_FORNECE = '" + SE2->E2_FORNECE + "' AND SE2.E2_LOJA = '" + SE2->E2_LOJA + "' " + cPulaLinha

	TcQuery cQuery New Alias "QRYSE2"

//Verifica o Resultado da Query e alimenta a variavel de retorno
	If QRYSE2->(!Eof())
		cRet := QRYSE2->E2_HIST
	EndIf

Return cRet

static function fbuscaPed(_cFilial, _cDoc, _cSerie, _cFornece, _cLoja)
	Local cNumPed 	:= ""
	Local cQuery 	:= ""
	Local cAliasTop := getNextAlias()
	Local _cAreas	:= getArea()

	cQuery := "SELECT D1_PEDIDO "
	cQuery += "FROM "+retsqlName("SD1") + " SD1 "
	cQuery += "WHERE D_E_L_E_T_ = ' ' AND D1_DOC = '"+_cDoc+"' "
	cQuery += "AND D1_FILIAL = '"+_cFilial+"' AND D1_SERIE = '"+_cSerie+"' "
	cQuery += "AND D1_FORNECE = '"+_cFornece+"' AND D1_LOJA = '"+_cLoja+"' "
	cQuery += "GROUP BY D1_PEDIDO "
    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasTop,.T.,.T.)

	do while (cAliasTop)->(!Eof())

		cNumPed += (cAliasTop)->D1_PEDIDO+"/"

		(cAliasTop)->(DbSkip())
	enddo

	if len(cNumPed) > 14
		cNumPed := substr(cNumPed,1,14)+"+"
	endif

	(cAliasTop)->(DbCloseArea())
	
	RestArea(_cAreas)
return(cNumPed)
