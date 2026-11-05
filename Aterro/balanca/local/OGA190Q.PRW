#INCLUDE "OGA190.ch"
#include "protheus.ch"
#include "fwmvcdef.ch"
//#INCLUDE 'AGRAXFUN.CH'

#DEFINE BUFFER_LEITURA	32
#DEFINE PORTASERIAL  'S'
#DEFINE PORTATCPIP   'T'
#DEFINE MSECONDS_WAIT 		1000
#DEFINE TRIES_TO_CONNECT 	3
#DEFINE TRIES_TO_READ    	3

Static nPsosVale1		:= 2   // Numero de capturas iguais para considerar o Peso (ex. nPesoVld1 := 2 ,
Static lEhTeste			:=  IIF( IsInCallStack( 'TESTAR' ),.T., .F.)
Static __cAliasC	:= Nil	//Tabela Temporaria para consulta
Static __oArqTemp	:= Nil	//Variavel utilizada para a consulta padrão DX6GRP

Static oMBrowse     := Nil
Static lF10Exec     := .T.
Static aParBal      := nil      // -- Será inicializada na funcao no Activate do Model (Devido a Error log se executado em MDI )--/
/** {Protheus.doc} OGA190
Rotina para pesagem avulsas em balanças cadastradas

@param:     Nil
@author:    Vinicius Becher Pagung
@since:     08/04/2016
@Uso:       SIGAARM - Origenação de Grãos
*/
user Function OGA190Q()
	Local bKeyF10       := SetKey( VK_F10, { || OGA190VKF10(NJH->NJH_CODPAV) 			} )
	Local bKeyF12       := SetKey( VK_F12, { || aParBal:= AGRX003E( .t., 'OGA050001' )   } )

	oMBrowse := FWMBrowse():New()
	oMBrowse:SetAlias( "NJH" )
	oMBrowse:SetDescription( STR0001 ) //"Pesagens Avulsas"
	//oMBrowse:SetMenuDef( "OGA190Q" )
	oMBrowse:AddLegend( "NJH_STATUS=='0'", "RED"        , STR0002 )//"Sem Pesagem"
	oMBrowse:AddLegend( "NJH_STATUS=='1'", "YELLOW"     , STR0003) //"Primeira Pesagem"
	oMBrowse:AddLegend( "NJH_STATUS=='2'", "GREEN"      , STR0004) //"Segunda Pesagem"
	oMBrowse:AddLegend( "NJH_STATUS=='3'", "GRAY"       , STR0005) //"Finalizada"
	oMBrowse:AddLegend( "NJH_STATUS=='4'", "BR_CANCEL"  , STR0037) //"Cancelada"
	oMBrowse:DisableDetails()
	oMBrowse:Activate()

	SetKey( VK_F10, bKeyF10 )
	SetKey( VK_F12, bKeyF12 )

Return( )


/** {Protheus.doc} MenuDef
Função que retorna os itens para construção do menu da rotina

@param:     Nil
@return:    aRotina - Array com os itens do menu
@author:    Vinicius Becher Pagung
@since:     11/04/2016
@Uso:       OGA190 - Pesagens
*/
Static Function MenuDef()
	Local aRotina := {}

	aAdd( aRotina, { STR0007    , "PesqBrw"         , 0, 1, 0, .T. } ) //"Pesquisar"
	aAdd( aRotina, { STR0008    , "ViewDef.OGA190Q" 	, 0, 2, 0, Nil } ) //"Visualizar"
	aAdd( aRotina, { STR0009    , "ViewDef.OGA190Q" 	, 0, 3, 0, Nil } ) //"Incluir"
	aAdd( aRotina, { STR0010    , "ViewDef.OGA190Q" 	, 0, 4, 0, Nil } ) //"Alterar"
	aAdd( aRotina, { STR0036 	, "OGA190C"        	, 0, 4, 0, Nil } ) //"Cancelar"
	aAdd( aRotina, { STR0012    , "OGA190F"        	, 0, 4, 0, Nil } ) //"Finalizar"
	//aAdd( aRotina, { STR0032    , "OGA190VKF10(NJH->NJH_CODPAV)", 0, 4, 0, Nil } ) //"Pesagem"
	aAdd( aRotina, { "Imp. Ticket"    , "U_QPES001()"     , 0, 8, 0, Nil } ) //"Imprimir""OGA190REL"
	//aAdd( aRotina, { STR0014    , "ViewDef.OGA190Q" 	, 0, 9, 0, Nil } ) //"Copiar"

Return( aRotina )


/** {Protheus.doc} ModelDef
Função que retorna o modelo padrao para a rotina

@param:     Nil
@return:    oModel - Modelo de dados
@author:    Vinicius Becher Pagung
@since:     11/04/2016
@Uso:       OGA190 - Pesagens
*/
Static Function ModelDef()
	Local oStruNJH := FWFormStruct( 1, "NJH" )
	Local oModel := MPFormModel():New( "OGA190QA", , {| oModel | PosModelo( oModel ) }, {| oModel | GrvModelo( oModel ) } )

	If GetRpoRelease() <= "12.1.033"
		oStruNJH:AddTrigger( "NJH_CODMOT" , "NJH_NOMMOT"	, {|| .T. }, {|| TrgNJH("NJH_CODMOT")} )
		oStruNJH:AddTrigger( "NJH_CODTRA" , "NJH_NOMTRA"	, {|| .T. }, {|| TrgNJH("NJH_CODTRA")} )
	Endif

	oModel:AddFields( "NJHUNICO", Nil, oStruNJH)
	oModel:SetDescription( "Pesagem Aterro" ) //"Pesagem Avulsa"
	oModel:GetModel( "NJHUNICO" ):SetDescription( "Pesagem Aterro" ) //"Dados da Pesagem"
	oModel:SetDeActivate( { | oModel | fFimModelo( oModel )                        } )
	oModel:SetVldActivate( { | oModel | IniModelo( oModel, oModel:GetOperation() ) } )

Return( oModel )


/** {Protheus.doc} ViewDef
Função que retorna a view para o modelo padrao da rotina

@param:     Nil
@return:    oView - View do modelo de dados
@author:    Vinicius Becher Pagung
@since:     11/04/2016
@Uso:       OGA190 - Pesagens
*/
Static Function ViewDef()
	Local oStruNJH   := FWFormStruct( 2, "NJH" )
	Local oModel     := FWLoadModel( "OGA190Q" )
	Local oView      := FWFormView():New()

	oStruNJH:RemoveField( "NJH_CODRPC" )

	oView:SetModel( oModel )
	oView:AddField( "VIEW_NJH", oStruNJH, "NJHUNICO" )
	oView:CreateHorizontalBox( "UNICO", 100 )
	oView:SetOwnerView( "VIEW_NJH", "UNICO" )
	oView:EnableTitleView( "VIEW_NJH" )

///=== Define métodos do View ===///
	oView:SetAfterViewActivate( { | oMod | fAftViewActiv( oMod ) } )
	//oView:AddUserButton( STR0017, "BALANCA", {| x | OGA190PESA( oModel , "VIEW"  ) } ) //"Capturar Peso"

	oView:SetCloseOnOk( {||.t.} )

Return( oView )

/** {Protheus.doc} IniModelo
Função que valida a inicialização do modelo de dados

@param:     oModel - Modelo de dados
@return:    lRetorno - verdadeiro ou falso
@author:    Vinicius Becher Pagung
@since:     18/04/2016
@Uso:       OGA190 - Pesagem Avulsa.
*/
Static Function IniModelo( oModel, nOperation)
	Local lRetorno   := .T.

	If nOperation == MODEL_OPERATION_UPDATE
		IF NJH->NJH_STATUS = '3' .or. NJH->NJH_STATUS = '4'
			Help( , ,STR0026, , STR0038, 1, 0 )
			lRetorno := .F.
		EndIf
	EndIf

Return(lRetorno)

/** {Protheus.doc} PosModelo
Função que valida o modelo de dados após a confirmação

@param:     oModel - Modelo de dados
@return:    lRetorno - verdadeiro ou falso
@author:    Vinicius Becher Pagung
@since:     08/04/2016
@Uso:       OGA190 - Pesagens
*/
Static Function PosModelo( oModel )
	Local lRetorno   := .t.
	Local nOperation := oModel:GetOperation()

	If nOperation == MODEL_OPERATION_DELETE
		Help( ,, STR0018,, STR0019, 1, 0) //"HELP"###"Nenhum registro pode ser excluido!!!"
		lRetorno := .f.
	EndIf
	If GetRpoRelease() >= "12.1.033"  .AND. NJH->(ColumnPos('NJH_CGC')) > 0 //Campos novo romaneio
		If !Empty( oModel:GetValue( "NJHUNICO", "NJH_CODMOT" ) )
			DbSelectArea("DA4")
			DBSetOrder(1)
			If DbSeek( FWxFilial("DA4") + oModel:GetValue( "NJHUNICO", "NJH_CODMOT" ) ) .AND. oModel:GetValue( "NJHUNICO", "NJH_CGC" ) <> DA4->DA4_CGC
				Help( ,, "STR0018",, "STR0044", 1, 0) //"HELP"###"O CPF/CNPJ informado para o transportador não corresponde com o valor cadastrado no sistema"
				lRetorno := .f.
			EndIf
		EndIf
		If !Empty( oModel:GetValue( "NJHUNICO", "NJH_CGC" ) ) .AND. !CGC( oModel:GetValue( "NJHUNICO", "NJH_CGC" ) )
			Help( ,, "STR0018",, "STR0045", 1, 0) //"HELP"###""O CPF/CNPJ informado possui formato invalido"
			lRetorno := .f.
		EndIf
	EndIf
Return( lRetorno )


/** {Protheus.doc} GrvModelo
Função que grava o modelo de dados após a confirmação

@param:     oModel - Modelo de dados
@return:    lRetorno - verdadeiro ou falso
@author:    Vinicius Becher Pagung
@since:     11/04/2016
@Uso:       OGA190 - Pesagens
*/
Static Function GrvModelo( oModel )
	Local nOperation    := oModel:GetOperation()
	Local nPeso1        := oModel:GetValue( "NJHUNICO", "NJH_PESO1" )
	Local nPeso2        := oModel:GetValue( "NJHUNICO", "NJH_PESO2" )
	//Local lret 			:= .T.

	If nOperation = MODEL_OPERATION_INSERT .Or. nOperation = MODEL_OPERATION_UPDATE

		If nPeso1 > 0
			oModel:SetValue( "NJHUNICO", "NJH_STATUS", "1" )
		EndIf

		If nPeso2 > 0
			oModel:SetValue( "NJHUNICO", "NJH_STATUS", "2" )
		EndIf

	EndIf

	If nOperation == MODEL_OPERATION_INSERT .And. Empty( oModel:GetValue( "NJHUNICO", "NJH_DATA" ) )
		FwDateUpd(.F.) //garante dDataBase atualizada na virada do dia antes de gravar a data do ticket (NJH_DATA fica "presa" na data de abertura da tela se nao for atualizada aqui)
		oModel:SetValue( "NJHUNICO", "NJH_DATA", dDataBase )
	EndIf

	FWFormCommit( oModel )

	NJ0->(DbSetOrder(1))
	if NJ0->(DbSeek(xFilial("NJ0")+oModel:GetValue( "NJHUNICO", "NJH_CODENT" )+"01"))
		NJ0->(RecLock("NJ0",.F.))
		NJ0->NJ0_NOMLOJ := oModel:GetValue( "NJHUNICO", "NJH_XCLIEN" )
		NJ0->(MsUnLock())
	endif

	DA3->(DbSetOrder(1))
	if DA3->(DbSeek(xfilial("DA3")+oModel:GetValue( "NJHUNICO","NJH_PLACA")))
		DA3->(RecLock("DA3",.F.))
		DA3->DA3_XNOMMO := oModel:GetValue( "NJHUNICO","NJH_NOMMOT")
		DA3->DA3_DESC	:= oModel:GetValue( "NJHUNICO","NJH_OBS")
		DA3->DA3_XCODCL := oModel:GetValue( "NJHUNICO","NJH_CODENT")
		DA3->DA3_XROTA  := oModel:GetValue( "NJHUNICO","NJH_XROTA")
		DA3->(MsUnLock())
	endif

Return( .t. )


user function fVerPla(cPlaca, cCodTic)
	Local lRetP 	:= .T.
	Local cQuery 	:= ""
	Local cAchou	:= ""
	Local cAliasTop	:= getNextAlias()
	Local cEOL 		:= Chr(13)+Chr(10)

	cQuery := "SELECT NJH.NJH_CODPAV, NJH.NJH_PLACA "
	cQuery += "FROM "+retSqlName("NJH") + " NJH "
	cQuery += "WHERE NJH.D_E_L_E_T_ = ' ' "
	cQuery += "AND NJH.NJH_PLACA = '"+cPlaca+"' "
	cQuery += "AND NJH.NJH_CODPAV <> '"+cCodTic+"' "
	cQuery += "AND NJH.NJH_STATUS IN ('0','1') "
	dbUseArea(.T., "TOPCONN", TcGenQry( , , cQuery), cAliasTop, .F., .T.)

	(cAliasTop)->(DbGoTop())
	cAchou := (cAliasTop)->NJH_CODPAV
	(cAliasTop)->(DbCloseArea())

	if !empty(cAchou)

		Help( ,, "Pesagem",, "Veículo Com Pesagem em Aberto. "+cEOL+;
					"Pesagem não Permitida...", 1, 0)

		lRetP := .F.
	endif

return(lRetP)

/** {Protheus.doc} OGA190PESA
Função que cria interface para captura de peso da balança

@param:     oView - View do modelo de dados
@return:    .t. - sempre verdadeiro
@author:    Vinicius Becher Pagung
@since:     11/04/2016
@Uso:       OGA190 - Pesagens
*/
Static Function OGA190PESA( oModel, cOrigem )

	Local oView         := FWViewActive()
	Local aAreaAtu      := GetArea()
	Local oFldNJH       := oModel:GetModel( "NJHUNICO" )
	Local nOperation    := oModel:GetOperation()
	Local cEOL 			:= Chr(13)+Chr(10)
	Local nPeso1        := oFldNJH:GetValue( "NJH_PESO1" )
	Local nPeso2        := oFldNJH:GetValue( "NJH_PESO2" )
	Local lPeso1        := oFldNJH:GetValue( "NJH_PESO1" ) = 0
	Local lPeso2        := oFldNJH:GetValue( "NJH_PESO2" ) = 0
	Local lPeso3        := oFldNJH:GetValue( "NJH_PESO1" ) > 0 .And. oFldNJH:GetValue( "NJH_PESO2" ) > 0
	Local nNJHRECNO     := NJH->( Recno() )
	Local oDlg          := Nil
	Local oCombo        := Nil
	Local cCombo        := ""
	Local nItem         := 1
	Local nPeso         := 0
	Local lPesagManu	:= .f.

	IF aParBal == nIl     // Para Ser Inicializado Somente Qdo ainda não foi
		aParBal := AGRX003E( .f., 'OGA050001' )
	EndIF

	If nOperation = MODEL_OPERATION_INSERT .Or. nOperation = MODEL_OPERATION_UPDATE

		if lPeso3 //.and. !(alltrim(__cUserID)) $ "000000" //oFldNJH:GetValue( "NJH_PESO1" ) > 0 .and. oFldNJH:GetValue( "NJH_PESO1" ) > 0

			Help( ,, "Pesagem",, "Repesagem Não permitida. "+cEOL+;
								"Imprimir o Ticket e registrar ocorrido...", 1, 0)

		else


		If oFldNJH:GetValue( "NJH_STATUS" ) == "3"
			Help( ,, STR0021,, STR0033, 1, 0) //'HELP'###'Esta pesagem nao pode ser finalizada.'
			Return( Nil )
		EndIf
		If lPeso3 //Ja possui as duas pesagens

			oDlg    := TDialog():New(0,0,24,300,"",,,,,CLR_BLACK,CLR_WHITE,,,.T.)
			oCombo  := TComboBox():New( 001, 001, { |u| If( PCount() > 0, cCombo := u, cCombo ) }, {STR0003, STR0004}, 100, 020, oDlg, , { || nItem := oCombo:nAt }, , , , .t., , , , , , , , , "cCombo" ) //"Primeira Pesagem"###"Segunda Pesagem"
			oTButt  := TButton():New( 001, 104, STR0020, oDlg, { || oDlg:End() }, 040, 010, , , .f., .t., .f., , .f., , , .f. ) //"Confirma"
			oDlg:Activate( , , , .t., { || .t. }, , { || } )

			If nItem = 1
				lPeso1 := .t.
				lPeso2 := .f.
			ElseIf nItem = 2
				lPeso1 := .f.
	 			lPeso2 := .t.
			EndIf

		EndIf

		nPeso := 0
		AGRX03AQ( @nPeso, .t., aParBal, /*cMask*/,@lPesagManu, nPeso1, nPeso2 )
		FwDateUpd(.F.) //atualiza database sistema na virada do dia

		If nPeso > 0

			If lPeso1
				If nPeso <> nPeso2
					if empty(fWFldGet('NJH_DATPS1'))
						oFldNJH:SetValue( "NJH_DATPS1", dDataBase )
						oFldNJH:SetValue( "NJH_HORPS1", Substr( Time(), 1, 5 ) )
					endif

					oFldNJH:SetValue( "NJH_PESO1" , nPeso )
					oFldNJH:SetValue( "NJH_MODPS1", IIf( lPesagManu, "M", "A" ) )
					oFldNJH:SetValue( "NJH_PSSUBT", Abs( nPeso - nPeso2 ) )
					IF nPeso2 = 0
						oFldNJH:SetValue( "NJH_STATUS" , "1" )
					Else
						oFldNJH:SetValue( "NJH_STATUS" , "2" )
					EndIf

					If cOrigem == "VIEW"
						oView:ValidField("NJHUNICO","NJH_DATPS1",fWFldGet('NJH_DATPS1'),.T.)
					Else
						If oModel:VldData()
							oModel:CommitData()
							oModel:DeActivate() // Desativa o modelo
							oModel:Destroy() // Destroy o objeto modelo
						Else
							AutoGrLog(oModel:GetErrorMessage()[6])
							AutoGrLog(oModel:GetErrorMessage()[7])
							If !Empty(oModel:GetErrorMessage()[2]) .And. !Empty(oModel:GetErrorMessage()[9])
								AutoGrLog(oModel:GetErrorMessage()[2] + " = " + cValToChar(oModel:GetErrorMessage()[9]))
							EndIf
							MostraErro()
						EndIf
					EndIf
				Else
					Help( ,, STR0021,, STR0034, 1, 0) //'HELP'###'Esta pesagem nao pode ser finalizada.'
					Return( .f. )
				EndIf
			ElseIf lPeso2 //Segunda Pesagem
				If nPeso <> nPeso1 // Consistência para não permitir 2 pesos iguais
					if empty(fWFldGet('NJH_DATPS2'))
						oFldNJH:SetValue( "NJH_DATPS2", dDataBase )
						oFldNJH:SetValue( "NJH_HORPS2", Substr( Time(), 1, 5 ) )
					endif

					oFldNJH:SetValue( "NJH_PESO2" , nPeso )
					oFldNJH:SetValue( "NJH_MODPS2", IIf( lPesagManu, "M", "A" ) )
					oFldNJH:SetValue( "NJH_PSSUBT", Abs( nPeso - nPeso1 ) )
					oFldNJH:SetValue( "NJH_STATUS" , "2" )
					If cOrigem == "VIEW"
						oView:ValidField("NJHUNICO","NJH_DATPS2",fWFldGet('NJH_DATPS2'),.T.)
					Else
						If oModel:VldData()
							oModel:CommitData()
							oModel:DeActivate() // Desativa o modelo
							oModel:Destroy() // Destroy o objeto modelo

						Else
							AutoGrLog(oModel:GetErrorMessage()[6])
							AutoGrLog(oModel:GetErrorMessage()[7])
							If !Empty(oModel:GetErrorMessage()[2]) .And. !Empty(oModel:GetErrorMessage()[9])
								AutoGrLog(oModel:GetErrorMessage()[2] + " = " + cValToChar(oModel:GetErrorMessage()[9]))
							EndIf
							MostraErro()

						EndIf
					EndIf
				Else
					Help( ,, STR0021,, STR0035, 1, 0) //'HELP'###'Esta pesagem nao pode ser finalizada.'
					Return( .f. )
				EndIf
			EndIf
		EndIf
		endif
	EndIf

	If .Not. lF10Exec
		oView:Refresh()
	Else
		NJH->( DbGoTo( nNJHRECNO ) )
		oMBrowse:Refresh()
	Endif
	RestArea( aAreaAtu )
Return( .t. )


/** {Protheus.doc} OGA190F
Rotina para estorno do fechamento de pesagem

@param:     oModel - Modelo de Dados
@return:    lRetorno - .t. ou .f.
@author:    Vinícius Becher Pagung
@since:     11/04/2016
@Uso:       OGA190 - Pesagem avulsa
*/
static Function OGA190F( cAlias, nReg, nOpcao )
	Local lRetorno      := .t.
	Local aAreaAtu      := GetArea()

	If NJH->( NJH_STATUS ) <> "2"
		Help( ,, STR0021,, STR0028, 1, 0) //'HELP'###'Esta pesagem nao pode ser finalizada.'
		Return( Nil )
	EndIf

	If .Not. MsgYesNo(STR0029, STR0030) //""###"Finalizar Pesagem"
		Return( Nil )
	EndIf

	If lRetorno
		If RecLock( "NJH", .f. )
			NJH->( NJH_STATUS ) := "3"
			MsUnLock()
		EndIf
	EndIf

	RestArea( aAreaAtu )
Return( Nil )

/** {Protheus.doc} OGA190C
Rotina para o Cancelamento das pesagens

@param:     oModel - Modelo de Dados
@return:    lRetorno - .t. ou .f.
@author:    Vinícius Becher Pagung
@since:     11/04/2016
@Uso:       OGA190 - Pesagem avulsa
*/
static Function OGA190C( cAlias, nReg, nOpcao )
	Local lRetorno      := .t.
	Local aAreaAtu      := GetArea()

	If NJH->( NJH_STATUS ) == "3"
		Help( ,, STR0021,, STR0039, 1, 0) //'HELP'###'Esta pesagem nao pode ser cancelada.'
		Return( Nil )
	EndIf

	If .Not. MsgYesNo(STR0029, STR0040) //""###"Cancelar Pesagem"
		Return( Nil )
	EndIf

	If lRetorno
		If RecLock( "NJH", .f. )
			NJH->( NJH_STATUS ) := "4"
			MsUnLock()
		EndIf
	EndIf

	RestArea( aAreaAtu )
Return( Nil )


/** {Protheus.doc} OGA190VKF10
Função auxililar para chamar a rotina de pesagem

@param:     oModel - Modelo de Dados
@return:    Nil
@author:    Bruna Rocio
@since:     11/11/2014
@Uso:       OGA250 - Romaneio
*/

static Function OGA190VKF10(cCodigoPav)
	Local aAreaAtu  := GetArea()
	Local oModel    := FwModelActive()

	If lF10Exec = .T.
		dbSelectArea("NJH")
		dbSetOrder(1)
		If dbSeek( xFilial('NJH')+ cCodigoPav)

			oModel := FWLoadModel( "OGA190Q" )

			oModel:SetOperation( MODEL_OPERATION_UPDATE )

			IF ! oModel:Activate() // Verificando se o VldActivate Falhou
				cMsg := oModel:GetErrorMessage()[3] + oModel:GetErrorMessage()[6]
				Help( ,,"ERRO",,cMsg, 1, 0 ) //"Ajuda"
				Return (.f.)
			EndIF

			OGA190PESA( oModel, "GRID" )

		Else

			Help(, , STR0026, , STR0041 + Alltrim(cCodigoPav) + STR0042, 1, 0 )

		Endif

		If oModel != Nil
			// Desativamos o Model
			oModel:DeActivate()
		EndIf
	Else
		OGA190PESA( oModel, "VIEW" )
	Endif

	RestArea( aAreaAtu )
	DBSELECTAREA('NJH')
Return .t.

/** {Protheus.doc} fAftViewActiv
Função para setar o ambiente na ativação da view, chamada no SetAfterViewActivate()

@param:     oModel
@return:    NIL
@author:    Vinicius Becher Pagung
@since:     11/04/2016
@Uso:       OGA190 - Pesagem Avulsa
*/
Static Function fAftViewActiv( oModel )

	lF10Exec := .f.

Return NIL

/** {Protheus.doc} 7 ffimModelo
Função executada no Deactivate do modelo de dados

@param:     oModel - Modelo de dados
@param:     nOperation - Opcao escolhida pelo usuario no menu (incluir/alterar/excluir)
@return:    lRetorno - verdadeiro ou falso
@author:    E Coelho
@since:     10/09/2015
@Uso:       AgroIndustria
*/
Static Function fFimModelo( oModel )

	lF10Exec := .T.

Return(.t.)

/** {Protheus.doc} OGA190REL
Função que executa o relatório OGR190

@return:    lRetorno - verdadeiro ou falso
@author:    Marcos Wagner Jr.
@since:     11/01/2018
@Uso:       AgroIndustria
*/
static Function OGA190REL()

	U_QPES001()

Return .t.

/** {Protheus.doc} OGA190Cpf
Função que define mascara do cpf

@return:    lRetorno - verdadeiro ou falso
@author:    Vanilda.moggio
@since:     10/2020
@Uso:       AgroIndustria
*/
static Function OGA190Cpf()
Local cMasc := ""
If !Empty(M->NJH_CGC) .And. Len(AllTrim(M->NJH_CGC))<14
    cMasc := "@R 999.999.999-99999%C" //Acrescentados 3 digitos p/ realizar a troca CPF/CNPJ
Else
    cMasc := "@R 99.999.999/9999-99%C"
EndIf

Return cMasc


Static Function TrgNJH(cCampo)

	If cCampo == "NJH_CODMOT"
		Return Posicione("DA4",1,xFilial("DA4") + M->NJH_CODMOT ,"DA4_NOME")
	Elseif cCampo == "NJH_CODTRA"
		Return Posicione("SA4",1,xFilial("SA4") + M->NJH_CODTRA,"A4_NOME")
	EndIf

Return ''


// Indica que tenho q ter 3 pesagens iguais para considerar o peso, razão
// pode ser o excesso de vento na região da balança )

/** {Protheus.doc} AGRX003A
Captura de peso da balança
Parametros
@npeso		:= Ponteiro de variavel que irá conter o Peso
lMostra		:= Indica se mostra a tela de  Peso;
aBal		:= Array Identificando : [01] codigo da Balança, [2] Permite Pesagem Automatica, [3] Permite Pesagem Manual
cMask 		:= Mascara do Campo de Pesagem padrão é "@E 999,999,999" pois são Balanças rodoviarias
@lPesagManu	:= identificará se a pesagem foi feita de forma automatica ou manual

@author: 	Ricardo Tomasi
@since: 	12/07/2010
@Uso: 		Generico Agro
*/
static Function AGRX03AQ( nPeso, lMostra, aBal, cMask, lPesagManu, nPeso1, nPeso2)
	Local aAreaAtu 		:= GetArea()
	Local aAreaDX6		:= DX6->(GetArea() )
	Local aAreaDX5		:= DX5->(GetArea() )
	Local oDlg     		:= Nil
	Local oBtn1    		:= Nil
	Local oBtn2    		:= Nil
	Local oFont    		:= Nil
	Local oPeso			:= Nil
	Local cId			:= __cUserID
	Local cBalanca 		:= CriaVar('DX5_CODIGO', .f.)
	Local nPesoCapt		:= 0

	Local __lPsAuto  	:= .F.
	Local __lPsManual	:= .F.
	Local nPesoST 		:= 0
	Local cLib          := ""
	Local lIsDark       := .F.
	Local cTheme        := Nil

	Default nPeso		:= 0
	Default lMostra		:= .t.
	Default aBal		:= {}

	Default lPesagManu	:= .f.   // Identifica se a Pesagem foi feita de Forma Automatica

	/*cMask = alterado o tipo da picture com base nos campos de quantidade SD1.
	Parametro: Formato para campos de peso no romaneio. Caso não tenha conteúdo,
	ou não exista o parâmetro, será considerado o formato @E 999,999.*/
	Default cMask		:= SuperGetMV("MV_OGPICPS",,"@E 999,999")
	Default nPeso1		:= 0
	Default nPeso2		:= 0

	Private _lUsuar  	:= .F.
	Private _lGrupo		:= .F.

	nPesoST := Abs(nPeso1 - nPeso2)

	If Len( aBal ) > 0
		cBalanca      	:= aBal[ 1 ]
		__lPsAuto       := aBal[ 2 ]
		__lPsManual     := aBal[ 3 ]
	EndIf

	// Validação de Usuário X Balança
	If GetRpoRelease() < "12.1.023"
		dbSelectArea( "DX6" )
		dbSetOrder( 1 )
		If dbSeek( xFilial( "DX6" ) + cId + cBalanca )
			If DX6_STATUS <> "1" // 1=Autorizado
				Help(,,STR0010,,STR0011 + Chr(10) + Chr(13) +  "[ " + STR0012 + cId + "; " + STR0013 + cBalanca + " ]" , 1, 0 )  //"Ajuda"###"Usuario não autorizado a efetuar pesagens nesta balança!"###"Usuário: "###"Balança: "
				RestArea( aAreaAtu )
				RestArea( aAreaDX6 )
				RestArea( aAreaDX5 )
				Return( Nil )
			EndIf
		Else
			Help(,,STR0010,,STR0014 + Chr(10) + Chr(13) +  "[ " + STR0012 + cId + "; " + STR0013 + cBalanca + " ]" , 1, 0 ) //"Ajuda"###"Usuario não cadastrado para utilizar esta balança!"###"Usuário: "###"Balança: "
			RestArea( aAreaAtu )
			RestArea( aAreaDX6 )
			RestArea( aAreaDX5 )
			Return( Nil )
		EndIf
	Else

		If .NOT. Empty(cBalanca)

			AX003BPUSM(cId, Iif (.NOT. Empty(cBalanca),cBalanca,"")) //Busca balança por usuário sem mensagens

			If .NOT. _lUsuar
				AX003BpGSM(cId, Iif (.NOT. Empty(cBalanca),cBalanca,""))
			EndIf

			If .NOT. _lUsuar .AND. .NOT. _lGrupo
		//		Help(" ",1,"NOBALXUSR")"Não foi encontrado relacionamento de usuário ou grupo de usuário x balança.
		//		Verifique se existe balança cadastrada no 'Cadastro de Balanças' e
		//		também se existe permissão no cadastro de 'Usuário x Balança' para o usuário ou o grupo de usuário."
				MsgAlert(STR0036)
				cBalanca := ""

				RestArea( aAreaAtu )
				RestArea( aAreaDX6 )
				Return(Nil)
			EndIf
		Else
			Help(" ",1,"NOBALXUSR")
			RestArea( aAreaAtu )
			RestArea( aAreaDX6 )
			Return(Nil)
		EndIf
	EndIf

	DX5->(dbSelectArea("DX5"))
	DX5->(dbSetOrder(1))
	If DX5->(MsSeek( xFilial( "DX5" ) + cBalanca ))
		If lMostra

			oFont := TFont():New( 'Arial', , 232, , .t. )

			If GetRpoRelease() >= "12.1.2410"
				cTheme := totvs.framework.css.getNewWebAppTheme()
				lIsDark := iif(!empty(cTheme) .and. cTheme == "DARK", .T., .F.) //Valida se o tema ativo é o dark
			Endif

			If lIsDark
				oDlg  := TDialog():New( 000, 000, 330, 1024, "Peso da Balança", , , , , , , , , .t. )	//"Peso da Balança"
			Else
				oDlg  := TDialog():New( 000, 000, 330, 1024, "Peso da Balança", , , , , CLR_BLACK, CLR_WHITE, , , .t. )	//"Peso da Balança"
			Endif

			oTimeClose	:= TTimer():New( 0800, { || /*oTimeClose:Deactivate(),*/ oDlg:End()}, oDlg )   //Timer que irá fechar a Janela apos a pasegem Automatica ser capturada

			If lIsDark
				oPeso := TGet():New( 01, 01, { |u| If( PCount() > 0, nPeso := u, nPeso ) } , oDlg, 512, 120, cMask, /*validacao*/, , , oFont, .f., , .t., , .f., { || __lPsManual }/*when*/, .f., .f., , .f., .f., ,"nPeso", , , , )
			Else
				oPeso := TGet():New( 01, 01, { |u| If( PCount() > 0, nPeso := u, nPeso ) } , oDlg, 512, 120, cMask, /*validacao*/, CLR_RED, CLR_WHITE, oFont, .f., , .t., , .f., { || __lPsManual }/*when*/, .f., .f., , .f., .f., ,"nPeso", , , , )
			Endif

			GetRemoteType(@cLib)
			If "HTML" $ cLib
				oPeso:SetCss("TGet {max-height: inherit;}")
			EndIf

			oSay1Pes	:= TSay():New(130,  5, {|| OemToAnsi( "1ª Pesagem" ) } ,oDlg                          , , , .f., .f., .f., .t., , , Len(STR0037)*4, 010 ) //"1ª Pesagem"
			oG1Pes		:= TGet():New(138,  5, {|| nPeso1}, oDlg, 40,10, cMask, { || .T.}     ,      ,          , , .F., , .T., , .F., {|| .f.},   ,   ,,   ,   ,,"nPeso1",,,,,.T.)

			oSay2Pes	:= TSay():New(130, 55, {|| OemToAnsi( "2ª Pesagem" ) } ,oDlg                          , , , .f., .f., .f., .t., , , Len(STR0038)*4, 010 ) //"2ª Pesagem"
			oG2Pes		:= TGet():New(138, 55, {|| nPeso2}, oDlg, 40,10, cMask, { || .T.}     ,       ,         , , .f., , .t., , .f., {|| .f.},,,,,,,,,,,,.T.)

			oSay3Pes	:= TSay():New(130,105, {|| OemToAnsi( "Subtotal" ) } ,oDlg                          , , , .f., .f., .f., .t., , , Len(STR0039)*4, 010 ) //"Subtotal""
			oG3Pes		:= TGet():New(138,105, {|| nPesoST},oDlg, 40,10, cMask, { || .T.}     ,       ,         , , .f., , .t., , .f., {|| .f.},,,,,,,,,,,,.T.)

			oBtn1 := TButton():New( 150, 421, "Capturar" , oDlg, { || nPeso := AGRX03BQ( ), oPeso:CtrlRefresh(),nPesoCapt:=nPeso,IIf( nPeso>0 .or. lEhTeste, oTimeClose:Activate(), .t.) }, 40, 10, , , .f., .t., .f., , .f., { || __lPsAuto } /*when*/, , .f. ) //#Capturar
			oBtn2 := TButton():New( 150, 471, "Confirmar" , oDlg, { || IIF(nPeso > 0, oDlg:End(), .f. ) }, 40, 10, , , .f., .t., .f., , .f., , , .f. )	//#Confirmar
			oDlg:Activate( , , , .t., , , ,)
		Else
			If __lPsAuto
				nPeso 		:= AGRX03BQ( )
				nPesoCapt	:= nPeso    //Tratamento para Identificar se Peso Foi Digitado para Qdo o tipo de Pesagem esta ambos
			EndIf
		EndIf
	EndIf
	DX5->(DbCloseArea())

	IF nPeso != nPesoCapt   // Se o Peso não Bate com o Peso Capturado Indica que a Pesagem foi inserida de forma manual.
		lPesagManu := .t.	//pesagem manual
	Else
		lPesagManu := .f.	//pesagem auto
	EndIf

	RestArea( aAreaAtu )
	RestArea( aAreaDX6 )
	RestArea( aAreaDX5 )

Return( Nil )

/** {Protheus.doc} AGRX003B
Retorna Peso Estabilizado da Balança
@author: 	Ricardo Tomasi
@since: 	12/07/2010
@Uso: 		Generico Agro
*/

static Function AGRX03BQ( )
	Local cTitulo		:= "Integração de Balanças" 		//#"Integração de Balanças"
	Local cMensagem		:= "Aguardando estabilização do peso... Visor  "		//#"Aguardando estabilização do peso... Visor  "
	Local oTimer		:= Nil
	Local nFor01		:= 0
	Private oDlg		:= Nil
	Private aCap		:= {}
	Private nSeq		:= 1
	Private nCap		:= 0
	Private oSay		:= Nil
	Private _nPsosVale1	:= 2   // Numero de capturas iguais para considerar o Peso (ex. nPesoVld1 := 2 ,

	If DX5->(FieldPos("DX5_LERVEZ"))
		_nPsosVale1 := DX5->( DX5_LERVEZ )
	Endif
	_nPsosVale1 := Max( 1, _nPsosVale1 )  // garante ao menos 1 leitura; DX5_LERVEZ=0 causava array vazio

	For nFor01 := 1 to   _nPsosVale1    //adiiconando a qtd de pensagesn que são necessarias para considerar 1 peso valido
		aAdd( aCap, 0 )
	Next _nPsosVale1

	oDlg 		:= TDialog():New( 000, 000, 090, 320, cTitulo, , , , , CLR_BLACK, CLR_WHITE, , , .t. )
	oTimer 		:= TTimer():New( 0, { || AGRX03FQ( ),oTimer:Deactivate(), oDlg:End()}, oDlg )
	oSay		:= TSay():New( 010, 010, { || cMensagem + "[ " + Str( nCap ) + " ]" }, oDlg, , , , , , .t., CLR_RED, CLR_WHITE, 460, 020 ) 		//#Cancelar
	oTBut 		:= TButton():New( 030, 060, STR0019, oDlg, { || oDlg:End() }, 040, 010, , , .f., .t., .f., , .f., , , .f. )
	oDlg:Activate( , , , .t., { || .t. }, , { || oTimer:Activate() } )

Return( nCap )

/** {Protheus.doc} AGRX003F
Auxilia na estabilização da balaça

@author: 	Ricardo Tomasi
@since: 	12/07/2010
@Uso: 		Generico Agro
*/
static Function AGRX03FQ(  )

	Local nFor01 	:= 0
	Local nPesoAux	:= 0
	Local nLastPeso := 0
	Local lPesoOk	:= .t.
	Local nOperacao :=  SuperGetMv('MV_AGRO042', , 1 )  // 1- nivel binario 2- nivel numerico 3- sem conferencia

	If nSeq >  nPsosVale1
		nSeq := 1
	EndIf

	nCap := AGRX03DQ( DX5->DX5_TIPPOR, DX5->DX5_TIPVEL, DX5->DX5_TIPPAR, DX5->DX5_NBITDA, DX5->DX5_NBITPA, DX5->DX5_TIMOUT, DX5->DX5_SCRIPT,DX5->DX5_TIPLEI,DX5->DX5_IPSERV,DX5->DX5_PORSER, DX5->DX5_INTLEI  )

	aCap[ 1 ] := nCap

	oSay:Refresh()

	IF lEhTeste
		Return( .t. )
	EndIF
	// Verifica se o Ultimo Peso Capturado corresponde aos Outros Pesos  Capturados
	// Tratando com StrTran é para o Caso de Haver uma mascara com decimais
	// desta forma garanto que a funcao nAnd não retorne um resultado
	// errado poi a nAnd nao trabalha com numeros com casas decimais.

	If ExistBlock( 'AGRXFUNPS' )
		acap := ExecBlock('AGRXFUNPS',.F.,.F., {acap} )
	Endif
	IF nSeq == nPsosVale1

		lPesoOk	:= .t.
		for nfor01 := 1 to nPsosVale1 - 1

			nPesoAux  :=  Val(StrTran(StrTran(cvaltochar( acap[ nFor01     ] ),',',''),'.',''))
			nLastpeso :=  Val(StrTran(StrTran(cvaltochar( acap[ nPsosVale1 ] ),',',''),'.',''))
			If nOperacao == 1 //nivel binario
				IF .not. nAnd( nLastPeso, nPesoAux ) == nLastPeso
					lPesoOk := .f.
					Exit
				EndIF
			ElseIf nOperacao == 2 //nivel numerico
				IF .not. nPesoAux == nLastPeso
					lPesoOk := .f.
					Exit
				EndIF
			EndIf
		nExt nFor01

		IF lPesoOk

			nCap := aCap[ 1 ]

			oDlg:End()
		EndIF

	//	nPesoTmp 		:= right("0000"+alltrim(str(aCap[1])),7)
	//	nNovoPeso		:= val(substr(nPesoTmp,7,1)+substr(nPesoTmp,6,1)+substr(nPesoTmp,5,1)+substr(nPesoTmp,4,1)+substr(nPesoTmp,3,1)+substr(nPesoTmp,2,1)+substr(nPesoTmp,1,1))
	//	aCap[1]     	:= nNovoPeso
	//	nCap 			:= aCap[ 1 ]

	//else
	//	nPesoTmp 		:= right("0000"+alltrim(str(aCap[1])),7)
	//	nNovoPeso		:= val(substr(nPesoTmp,7,1)+substr(nPesoTmp,6,1)+substr(nPesoTmp,5,1)+substr(nPesoTmp,4,1)+substr(nPesoTmp,3,1)+substr(nPesoTmp,2,1)+substr(nPesoTmp,1,1))
	//	aCap[1]     	:= nNovoPeso
		nCap 			:= aCap[ 1 ]
	EndIF

	nSeq ++

Return( Nil )

/** {Protheus.doc} AGRX003D
Integra com a balança e captura o peso
@author: 	Ricardo Tomasi
@since: 	12/07/2010
@Uso: 		Generico Agro
*/
static Function AGRX03DQ(cPorta, cBaudRate, cParity, cData, cStop, cTimeOut, cScript, cTpRead, cIpServer, cPrtaIPSer,nWait4Read )
	// Vars de Conexao com Serial
	Local cParte		:= Space( 1 )
	Local cSettings		:= AllTrim( cBaudRate )+','+AllTrim( cParity )+','+AllTrim( cData )+','+AllTrim( cStop )+','+AllTrim( cTimeOut )
	Local nHdlePorta
	Local nBytes		:= 0
	//--End VArs de Comunicacao Serial--
	// Vars de Conexao com Tsokect ( TCPIP)
	Local oSocket
	Local nSockResp  := 0
	Local nSockRead  := 0
	Local cBuffer	 := ''
	///		Local atSocketC	:= ClassMethArray( oSocket ) // Encontrando os Methodos da classe
	//--End Vars de Comunicação TCPIP


	Local nFor01		:= 0
	Local nFor02		:= 0
	Local nRetorno		:= 0
	Local cConteudo		:= ""
	Local nHdll  		:= 0
	Local nCont  		:= 0
	Local cPortaMs 		:= AllTrim(cPorta) + ':' + AllTrim(cSettings)
	Local nVezes 		:= 1
	Local nNumConect	:= 2

	Do Case
		Case cTpRead == PORTASERIAL  		 //Comunicação Serial

		nHdlePorta	:= fOpenPort( cPorta, cSettings, 2 ) // Tentando conectar

		IF nHdlePorta == -1 //caso não conecte com o fOpenPort, irá tentar com o MsOpenPort

			FClose( nHdlePorta )

			MsOpenPort(nHdll, cPortaMs)

			cConteudo := space(100)

			While (Empty(cConteudo) .AND. nCont < 50)
				MsRead(nHdll, @cConteudo)
				nCont++
			EndDo

			MsClosePort(nHdll)

			if substr(cconteudo,8,8)  <> SUBSTR(cconteudo,len(cconteudo)-12,8)  //substr(cConteudo,354,7)
				cConteudo := ""
			else

				if val(substr(cconteudo,8,8)) >= 90000 .or. val(substr(cconteudo,8,8)) <= 500
					cConteudo := ""
				endif
			endif
			//If Empty(cConteudo)
			//	Help(,,STR0010,,STR0021 + Chr(10) + Chr(13) +  "[ " + cPorta + " ]" , 1, 0 )  //"Ajuda"####não foi possivel conectar com a balança na Porta#
			//	Return 0
			//EndIf
		Else
			For nFor01 := 1 to TRIES_TO_READ  		// tenta conectar N vezes
				cConteudo := ''
				For nFor02 := 1 to BUFFER_LEITURA   //32
					cParte := Space( 1 )
					nBytes := FRead( nHdlePorta, @cParte, 1 )
					If Empty( nBytes )
						Exit
					EndIf
					cConteudo += cParte
				Next nFor02
				IF ! Empty( cConTeudo )
					Exit
				EndIF
			Next nFor01
			FClose( nHdlePorta )
		EndIf

		Case cTpRead == PORTATCPIP // Para conectar Utilizar Endereco do Servidor (padraoIP), Porta do servidor IP, timeout

		//IF nWait4Read < MSECONDS_WAIT    // Ajustando o Tempo de Espera para Pelo menos 2000 milessegundos
		//	nWait4Red := MSECONDS_WAIT
		//EndIF

		for nVezes := 1 to nNumConect
			cBuffer 	:= ''

			oSocket 	:= tSocketClient():New()   	//Criando a Clase
			oSocket:Reset()   //Fechando a Conexão
			oSocket 	:= tSocketClient():New()   	//Criando a Clase

			For nFor01 := 1 to TRIES_TO_CONNECT   	// tenta conectar N vezes
				nSockResp := oSocket:Connect( val(cPrtaIPSer),Alltrim(cIpServer),Val( cTimeOut ) )
				//Verificamos se a conexao foi efetuada com sucesso
				IF !( oSocket:IsConnected() )  //ntSocketConnected == 0 OK
					Help(,,STR0010,,STR0020 + Chr(10) + Chr(13) +  "[ " + StrZero( nFor01,3 ) + " ]" , 1, 0 )  //"Ajuda"####não foi possivel conectar com a balança na Porta#
				ElseIF nSockResp == 0   // Conexão Ok
					Exit
				EndIF
			Next

			IF nSockResp == 0 // Indica que Está conectado // Enviando um Get Para Capturar o Peso
				Sleep ( nWait4Read )
				For nFor01 := 1 To TRIES_TO_READ
					cBuffer := ""
					nSockRead = oSocket:Receive( @cBuffer,  Val( cTimeout ) )
					IF( nSockRead > 0 )
						cConteudo := cBuffer
						Exit
					Else
						cConteudo := ''
					Endif
				Next nFor01

				//if len(cConteudo) > 150
				if substr(cconteudo,5, 5) <> SUBSTR(cconteudo, len(cconteudo)- 6, 5)  //substr(cConteudo,354,7)
					cConteudo := ""
				endif
				//endif

				if val(substr(cconteudo,5,5)) >= 90000 .or. val(substr(cconteudo,5, 5)) <= 500
					cConteudo := ""
				endif

				///oSocket:CloseConnection()   //Fechando a Conexão
			Else
				Help(,,STR0010,,STR0027 + Chr(10) + Chr(13) +  "[ "  + cIpServer + "/" + cPrtaIPSer + " ]" , 1, 0 )  //"Ajuda"####não foi possivel conectar com a balança. Tentavia:# ###"Balança: "
			EndIF
			oSocket:CloseConnection()   //Fechando a Conexão
		next
	EndCase

	//	IF IsInCallStack( 'TESTAR' ) /*.and. lShowCFG */ .and. len(alltrim(cconteudo)) > 0 //Indica que está testando a comunicação e que devemos mostrar esta mensagem
	IF lEhTeste
		AGRXFUNCFG( cConteudo ) // Mostra tela Explicativa de Config da Balança;
	EndIF

	If .Not. Empty( AllTrim( cScript ) )   			// Irá Aplicar o Script no cConteudo
		cScript := "{||" +  Alltrim(cScript) + "}"  //Transformando o Script em bloco de codigo
		cConteudo := Eval( &( cScript ) )
		nRetorno := Val( cConteudo )
	Else
		nRetorno := 0
	EndIf

Return( nRetorno )
