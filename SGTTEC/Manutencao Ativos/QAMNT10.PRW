/** {Protheus.doc} QAMNT10
Registro da Chegada de Notas Fiscais Filiais

Sendo:
@Uso: Projeto Quebec
@Origem: 	
Reservado STJ

*/

#Include "Totvs.ch"
#Include "FwMvcDef.ch"

User Function QAMNT10()

Private oBrowse 	:= FwMBrowse():New()				//Variavel de Browse 

//Alias do Browse
oBrowse:SetAlias('STJ')
oBrowse:SetFilterDefault("TJ_TERMINO='N' .AND. TJ_PLANO > '000001' .AND. TJ_SITUACA = 'P'") 

//Descrição da Parte Superior Esquerda do Browse
oBrowse:SetDescripton("Ordens de Serviços Preventivas Pendentes") 

//Adiciona Legenda
//oBrowse:AddLegend( "Empty(Z3_DTACLA)" , "RED"	, "NF Não Classificada")
//oBrowse:AddLegend( "!Empty(Z3_DTACLA)", "GREEN", "NF Classificado")

//Habilita os Botões Ambiente e WalkThru
oBrowse:SetWalkThru(.T.)

//Desabilita os Detalhes da parte inferior do Browse
oBrowse:DisableDetails()
          	
//Ativa o Browse
oBrowse:Activate()

Return

Static Function MenuDef()
Local aMenu :=	{}
	
ADD OPTION aMenu TITLE 'Pesquisar'      ACTION 'PesqBrw'       		OPERATION 1 ACCESS 0
ADD OPTION aMenu TITLE 'Visualizar'     ACTION 'VIEWDEF.QAMNT10'	OPERATION 2 ACCESS 0
ADD OPTION aMenu TITLE 'Alterar'        ACTION 'VIEWDEF.QAMNT10' 	OPERATION 4 ACCESS 0
ADD OPTION aMenu TITLE 'Excluir'        ACTION 'VIEWDEF.QAMNT10' 	OPERATION 5 ACCESS 0
	
Return(aMenu)

Static Function ModelDef()
//Retorna a Estrutura do Alias passado como Parametro (1=Model,2=View)
Local oStruct	:=	FWFormStruct(1,"STJ") 
Local oModel

//Instancia do Objeto de Modelo de Dados
oModel	:=	MpFormModel():New('QAMNT10A',/*Pré-Validação*/ ,/*Pos-Validacao*/;
                                       ,/*Commit*/,/*Cancel*/)

//Adiciona um modelo de Formulario de Cadastro Similar à Enchoice ou Msmget
oModel:AddFields('STJ_MASTER', /*cOwner*/, oStruct, /*bPreValidacao*/;
                       , /*bPosValidacao*/, /*bCarga*/ )

//Adiciona Descricao do Modelo de Dados
oModel:SetDescription( "Ordens de Serviços Preventivas Pendentes" )

//Adiciona Descricao do Componente do Modelo de Dados      
oModel:GetModel( 'STJ_MASTER' ):SetDescription( "Ordens de Serviços Preventivas Pendentes")

//A Chave Primária é obrigatória, caso não tenha defina um array vazio
oModel:SetPrimaryKey({'TJ_FILIAL','TJ_ORDEM'})  

oStruct:SetProperty("TJ_FILIAL" , MODEL_FIELD_WHEN, {|| .F.})
oStruct:SetProperty("TJ_ORDEM" , MODEL_FIELD_WHEN, {|| .F.})
oStruct:SetProperty("TJ_PLANO" , MODEL_FIELD_WHEN, {|| .F.})
oStruct:SetProperty("TJ_CODBEM" , MODEL_FIELD_WHEN, {|| .F.})
oStruct:SetProperty("TJ_TIPOOS" , MODEL_FIELD_WHEN, {|| .F.})
oStruct:SetProperty("TJ_SERVICO" , MODEL_FIELD_WHEN, {|| .F.})
oStruct:SetProperty("TJ_SEQRELA" , MODEL_FIELD_WHEN, {|| .F.})
oStruct:SetProperty("TJ_DTORIGI" , MODEL_FIELD_WHEN, {|| .F.})
oStruct:SetProperty("TJ_TIPO" , MODEL_FIELD_WHEN, {|| .F.})
oStruct:SetProperty("TJ_SITUACA" , MODEL_FIELD_WHEN, {|| .T.})
oStruct:SetProperty("TJ_TERMINO" , MODEL_FIELD_WHEN, {|| .F.})
oStruct:SetProperty("TJ_POSCONT" , MODEL_FIELD_WHEN, {|| .F.})
oStruct:SetProperty("TJ_HORACO1" , MODEL_FIELD_WHEN, {|| .F.})
oStruct:SetProperty("TJ_POSCON2" , MODEL_FIELD_WHEN, {|| .F.})
oStruct:SetProperty("TJ_HORACO2" , MODEL_FIELD_WHEN, {|| .F.})
oStruct:SetProperty("TJ_CODAREA" , MODEL_FIELD_WHEN, {|| .F.})
oStruct:SetProperty("TJ_CCUSTO" , MODEL_FIELD_WHEN, {|| .F.})
oStruct:SetProperty("TJ_CENTRAB" , MODEL_FIELD_WHEN, {|| .F.})
oStruct:SetProperty("TJ_DTMPINI" , MODEL_FIELD_WHEN, {|| .F.})
oStruct:SetProperty("TJ_HOMPINI" , MODEL_FIELD_WHEN, {|| .F.})
oStruct:SetProperty("TJ_DTMPFIM" , MODEL_FIELD_WHEN, {|| .F.})
oStruct:SetProperty("TJ_HOMPFIM" , MODEL_FIELD_WHEN, {|| .F.})
oStruct:SetProperty("TJ_HOPRINI" , MODEL_FIELD_WHEN, {|| .F.})
oStruct:SetProperty("TJ_USUARIO" , MODEL_FIELD_WHEN, {|| .F.})
oStruct:SetProperty("TJ_PRIORID" , MODEL_FIELD_WHEN, {|| .F.})
//oStruct:SetProperty("TJ_LUBRIFI" , MODEL_FIELD_WHEN, {|| .F.})
oStruct:SetProperty("TJ_TERCEIR" , MODEL_FIELD_WHEN, {|| .F.})
oStruct:SetProperty("TJ_OBSERVA" , MODEL_FIELD_WHEN, {|| .F.})
//oStruct:SetProperty("TJ_CONTINI" , MODEL_FIELD_WHEN, {|| .F.})
//oStruct:SetProperty("TJ_FATURA" , MODEL_FIELD_WHEN, {|| .F.})
//oStruct:SetProperty("TJ_APROPRI" , MODEL_FIELD_WHEN, {|| .F.})
oStruct:SetProperty("TJ_DTMPFIM" , MODEL_FIELD_WHEN, {|| .F.})
oStruct:SetProperty("TJ_XETAPA" , MODEL_FIELD_WHEN, {|| .F.})
oStruct:SetProperty("TJ_SOLICI" , MODEL_FIELD_WHEN, {|| .F.})
oStruct:SetProperty("TJ_PAPOIO" , MODEL_FIELD_WHEN, {|| .F.})
oStruct:SetProperty("TJ_XCPF" , MODEL_FIELD_WHEN, {|| .F.})

//oStruct:SetProperty("B8_LOTEFOR", MODEL_FIELD_OBRIGAT, .F. ) 

Return(oModel)

/* VIEW */
Static Function ViewDef()
Local oStruct	:=	FWFormStruct(2,"STJ") 	//Retorna a Estrutura do Alias passado
                                            // como Parametro (1=Model,2=View)
Local oModel	:=	FwLoadModel('QAMNT10')	//Retorna o Objeto do Modelo de Dados 
Local oView		:=	FwFormView():New()      //Instancia do Objeto de Visualização

//Define o Modelo sobre qual a Visualizacao sera utilizada
oView:SetModel(oModel)	

//oView:SetFieldAction("Z3_DOC" 	, {|oView, oModel| fCompDOC(oView, oModel)})

//Vincula o Objeto visual de Cadastro com o modelo 
oView:AddField( 'STJ_VIEW', oStruct, 'STJ_MASTER')

//Define o Preenchimento da Janela
oView:CreateHorizontalBox( 'ID_BOX_ALL'  , 100 )

// Relaciona o ID da View com o "box" para exibicao
oView:SetOwnerView( 'STJ_VIEW', 'ID_BOX_ALL' )

Return(oView)                       


/*
___________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ ANFF004A.prw ¦ Autor ¦ Sinval         ¦ Data ¦    08/2021  ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ Ponto de Entrada da Rotina                                 ¦¦¦
¦¦¦			 ¦ 															  ¦¦¦
¦¦¦          ¦ 															  ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Objetivo  ¦                                            				  ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/

/*
IDs dos Pontos de Entrada
-------------------------

MODELPRE 			Antes da alteração de qualquer campo do modelo. (requer retorno lógico)
MODELPOS 			Na validação total do modelo (requer retorno lógico)

FORMPRE 			Antes da alteração de qualquer campo do formulário. (requer retorno lógico)
FORMPOS 			Na validação total do formulário (requer retorno lógico)

FORMLINEPRE 		Antes da alteração da linha do formulário GRID. (requer retorno lógico)
FORMLINEPOS 		Na validação total da linha do formulário GRID. (requer retorno lógico)

MODELCOMMITTTS 		Apos a gravação total do modelo e dentro da transação
MODELCOMMITNTTS 	Apos a gravação total do modelo e fora da transação

FORMCOMMITTTSPRE 	Antes da gravação da tabela do formulário
FORMCOMMITTTSPOS 	Apos a gravação da tabela do formulário

FORMCANCEL 			No cancelamento do botão.

BUTTONBAR 			Para acrescentar botoes a ControlBar

MODELVLDACTIVE 		Para validar se deve ou nao ativar o Model

Parametros passados para os pontos de entrada:
PARAMIXB[1] - Objeto do formulário ou model, conforme o caso.
PARAMIXB[2] - Id do local de execução do ponto de entrada
PARAMIXB[3] - Id do formulário

Se for uma FORMGRID
PARAMIXB[4] - Linha da Grid
PARAMIXB[5] - Acao da Grid
*/

User Function QAMNT10A

	Local nQtdElIXB		:= 0
	Local oObj			:= ''
	Local cIdPonto		:= ''
	Local cIdModel		:= ''
	Local cClasse		:= ''
	Local nOper 		:= 0          
	Local xRet			:= .T.   
    
	If PARAMIXB <> Nil
		nQtdElIXB	:= Len(PARAMIXB)
		oObj 		:= PARAMIXB[1]
		cIdPonto	:= PARAMIXB[2]
		cIdModel	:= PARAMIXB[3]
		cClasse 	:= Iif(oObj<>Nil, oObj:ClassName(), '')	// Nome da classe utilizada na rotina (FWFORMFIELD - Formulário, FWFORMGRID - Grid)
		nOper 		:= oObj:getOperation()  

		If cIdPonto == 'MODELVLDACTIVE' 
        
		ElseIf cIdPonto == 'BUTTONBAR'

		ElseIf cIdPonto == 'FORMPRE'

		ElseIf cIdPonto == 'FORMPOS'
				
		ElseIf cIdPonto == 'FORMLINEPRE'    
		
		ElseIf cIdPonto == 'FORMLINEPOS'
				
		ElseIf cIdPonto == 'MODELPRE'

		ElseIf cIdPonto == 'MODELPOS'
		
		ElseIf cIdPonto == 'FORMCOMMITTTSPRE'         
				
		ElseIf cIdPonto == 'FORMCOMMITTTSPOS'

		ElseIf cIdPonto == 'MODELCOMMITTTS'

		ElseIf cIdPonto == 'MODELCOMMITNTTS'

  		ElseIf cIdPonto == 'MODELCANCEL'

		EndIf

	EndIf

Return xRet
