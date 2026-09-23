#include 'protheus.ch'
#include 'parmtype.ch'
#INCLUDE 'FWMVCDEF.CH'


/*-------------------------------------------------------------------
- Programa: UCOMA003
- Autor: Rafael Brito
- Data: 17/09/2019
- Descrição: Tranportadoras prevista no pedido de compra
-------------------------------------------------------------------*/

User function UFINA001()

	Local oBrowse

	Private aRotina
	Private cCadastro := 'Solicitação de Pagamento'
    Private cFields := "Z2_NUM,Z2_TIPO,Z2_FORNECE,Z2_LOJA,Z2_NOME,Z2_NATUREZ,Z2_CCD,Z2_EMISSAO,Z2_VENCTO,Z2_VALOR,Z2_HIST,Z2_OBSERV,Z2_REQUISI,Z2_APROVA"
	PRIVATE aDadosImp := Array(3)
	Private nOldValor := 0

	DbSelectArea("SZ2")

	oBrowse := FWmBrowse():New()
	oBrowse:SetAlias( 'SZ2' )
	oBrowse:SetDescription( cCadastro )

	oBrowse:AddLegend("Empty(Z2_APROVA)", "GREEN"	,	"Solicitação Aberta")
	oBrowse:AddLegend("!Empty(Z2_APROVA)", "RED"		,	"Solicitação Aprovada")  

	oBrowse:Activate()

Return

//-------------------------------------------------------------------
// Definicao do Menu
//-------------------------------------------------------------------
Static Function MenuDef()

	aRotina := {}

	ADD OPTION aRotina TITLE 'Visualizar'      ACTION 'VIEWDEF.UFINA001' OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE 'Incluir'         ACTION 'VIEWDEF.UFINA001' OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE 'Alterar'         ACTION 'U_UFINA01A(4)' OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Excluir'         ACTION 'U_UFINA01A(5)' OPERATION 5 ACCESS 0
	ADD OPTION aRotina TITLE 'Imprimir'        ACTION 'U_UFINR001' OPERATION 8 ACCESS 0
	ADD OPTION aRotina TITLE 'Aprovar'          ACTION 'U_UFINA01B' OPERATION 9 ACCESS 0

Return aRotina

//-------------------------------------------------------------------
// Define Modelo de Dados
//-------------------------------------------------------------------
Static Function ModelDef()

	// Cria a estrutura a ser usada no Modelo de Dados0000000000000000000000
	Local oStruSZ2  := FWFormStruct( 1, 'SZ2', {|cCampo| Alltrim(cCampo) $ cFields },.F. )
	Local oModel
	//Local bLoad := {|oModel, lCopy| loadField(oModel, lCopy)}

	// Cria o objeto do Modelo de Dados
	oModel := MPFormModel():New('UFINP001',  , /*bPosValidacao*/, /*{|oModel| GravaDados( oModel )}*/,  /*bCancel*/ )

	// Adiciona ao modelo uma estrutura de formulario de edicao por campo
	oModel:AddFields( 'SZ2MASTER', /*cOwner*/, oStruSZ2, /*bPreValidacao*/, /*bPosValidacao*/, /*bLoad*/ )

	// Adiciona a chave primaria da tabela principal
	oModel:SetPrimaryKey({ "Z2_FILIAL", "Z2_NUM" })


	// Adiciona a descricao do Modelo de Dados
	oModel:SetDescription( 'Solicitação' )



Return oModel

//-------------------------------------------------------------------
// Define camada de Visão
//-------------------------------------------------------------------
Static Function ViewDef()

	// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
	Local oModel   := FWLoadModel( 'UFINA001' )
	Local oView

	// Cria a estrutura a ser usada na View
	Local oStruSZ2 := FWFormStruct( 2, 'SZ2', {|cCampo| Alltrim(cCampo) $ cFields },.F. )
	
	oStruSZ2:RemoveField( 'ZF_NUM' )

	// Cria o objeto de View
	oView := FWFormView():New()

	// Define qual o Modelo de dados será· utilizado
	oView:SetModel( oModel )

	//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
	oView:AddField( 'VIEW_SZ2', oStruSZ2, 'SZ2MASTER' )

	// Cria um "box" horizontal para receber cada elemento da view
	oView:CreateHorizontalBox( 'TELA'	, 100 )

	// Relaciona o identificador (ID) da View com o "box" para exibiÃ§Ã£o
	oView:SetOwnerView( 'VIEW_SZ2', 'TELA' )	

Return oView

User Function UFINA01A(_nOpc)
	
	If  _nOpc == 4
		If SE2->(DbSeek(xFilial("SE2")+"SP "+SZ2->Z2_NUM+"   "+SZ2->Z2_TIPO+SZ2->Z2_FORNECE+SZ2->Z2_LOJA))
			lRet := .F.
			Help( ,, 'Help',, 'Alteração Bloqueada. Entre em contato com financeiro para excluir o título vinculado', 1, 0 )
		Else
			FWExecView( 'Alterar','VIEWDEF.UFINA001',4,, {|| .T. })
		EndIf
	Else
		If SE2->(DbSeek(xFilial("SE2")+"SP "+SZ2->Z2_NUM+"   "+SZ2->Z2_TIPO+SZ2->Z2_FORNECE+SZ2->Z2_LOJA))
			lRet := .F.
			Help( ,, 'Help',, 'Exclusão Bloqueada. Entre em contato com financeiro para excluir o título vinculado', 1, 0 )
		Else
			FWExecView( 'Excluir','VIEWDEF.UFINA001',5,, {|| .T. })
		EndIf
	EndIf
Return


User Function UFINA01B(oModel)
	Local lRet 			:= .T.
	
	If __cUserId $ GetMv("MV_XAPROSP")
		If Empty(SZ2->Z2_APROVA)
			FIN050EXEC(3)
		Else
			MsgInfo("Solicitação já aprovada anteriormente.")
		EndIf
	Else
		Help( ,, 'Help',, 'Usuário sem permissão para aprovar solicitação de pagamento', 1, 0 )
	EndIf
    
Return lRet


Static Function FIN050EXEC(_nOpc)
LOCAL aArray := {}
Local lContinua := .T. 
PRIVATE lMsErroAuto := .F.

SE2->(DbSetorder(1))
//If _nOpc <> 3
//	if !SE2->(DbSeek(xFilial("SE2")+"SP "+SZ2->Z2_NUM+"   "+SZ2->Z2_TIPO+SZ2->Z2_FORNECE+SZ2->Z2_LOJA))
//		lContinua := .F.
//	EndIf
//else
	If SE2->(DbSeek(xFilial("SE2")+"SP "+SZ2->Z2_NUM+"   "+SZ2->Z2_TIPO+SZ2->Z2_FORNECE+SZ2->Z2_LOJA))
		lContinua := .F.
	EndIf
//EndIf

If lContinua

	//If _nOpc <> 5
		aArray := { { "E2_PREFIXO"  , "SP "			             		, NIL },;
					{ "E2_NUM"      , SZ2->Z2_NUM   		         	, NIL },;
					{ "E2_TIPO"     , SZ2->Z2_TIPO        		      	, NIL },;
					{ "E2_NATUREZ"  , SZ2->Z2_NATUREZ             		, NIL },;
					{ "E2_FORNECE"  , SZ2->Z2_FORNECE     		       	, NIL },;
					{ "E2_LOJA"		, SZ2->Z2_LOJA		            	, NIL },;
					{ "E2_EMISSAO"  , SZ2->Z2_EMISSAO					, NIL },;
					{ "E2_VENCTO"   , SZ2->Z2_VENCTO					, NIL },;
					{ "E2_VENCREA"  , DataValida(SZ2->Z2_VENCTO	,.T.)	, NIL },;
					{ "E2_VALOR"    , SZ2->Z2_VALOR              		, NIL },;
					{ "E2_CCD"  	, SZ2->Z2_CCD		            	, NIL }}
					//{ "E2_HIST"		, SZ2->Z2_HIST              			, NIL },;
	
	//Else 
	//	aArray := { { "E2_PREFIXO"  , "SP "			             		, NIL },;
	//				{ "E2_NUM"      , SZ2->Z2_NUM   		         		, NIL }}
	//EndIf

	aArray := FWVetByDic( aArray, 'SE2', .F. )

	MsExecAuto( { |x,y,z| FINA050(x,y,z)}, aArray,, _nOpc)  // 3 - Inclusao, 4 - Alteração, 5 - Exclusão
	
	
	If lMsErroAuto
		MostraErro()
	else
		Reclock("SE2",.F.)
			SE2->E2_HIST := SZ2->Z2_HIST
		SE2->(MsUnLock())

		Reclock("SZ2",.F.)
			SZ2->Z2_APROVA := USRRETNAME(__CUSERID)
		SZ2->(MsUnLock())

		MsgInfo("Solicitação aprovada com sucesso!")

	EndIf
Else
	lMsErroAuto := .T.
EndIf
 
Return !lMsErroAuto

