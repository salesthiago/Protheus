/** {Protheus.doc} QACOM005
Cadastro SRA com filtro de funcionários ativos Dif de Demitidos

Sendo:
@Uso: Projeto Quebec
@Origem: 	
Reservado SZ9

*/

#Include "Totvs.ch"
#Include "FwMvcDef.ch"

User Function QFOL009()

Private oBrowse 	:= FwMBrowse():New()				//Variavel de Browse 

//Alias do Browse
oBrowse:SetAlias('SRD')
//Descrição da Parte Superior Esquerda do Browse
oBrowse:SetDescripton("Lançamentos Acumulados") 

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
ADD OPTION aMenu TITLE 'Visualizar'     ACTION 'VIEWDEF.QFOL009'	OPERATION 2 ACCESS 0
//ADD OPTION aMenu TITLE 'Incluir'        ACTION 'VIEWDEF.QFOL009' 	OPERATION 3 ACCESS 0
//ADD OPTION aMenu TITLE 'Alterar'        ACTION 'VIEWDEF.QFOL009' 	OPERATION 4 ACCESS 0
//ADD OPTION aMenu TITLE 'Excluir'        ACTION 'VIEWDEF.QFOL009' 	OPERATION 5 ACCESS 0
ADD OPTION aMenu TITLE 'Imprimir'       ACTION 'VIEWDEF.QFOL009'	OPERATION 6 ACCESS 0
	
Return(aMenu)

Static Function ModelDef()
//Retorna a Estrutura do Alias passado como Parametro (1=Model,2=View)
Local oStruct	:=	FWFormStruct(1,"SRD") 
Local oModel

//Instancia do Objeto de Modelo de Dados
oModel	:=	MpFormModel():New('QFOL009A',/*Pré-Validação*/ ,/*Pos-Validacao*/;
                                       ,/*Commit*/,/*Cancel*/)

//Adiciona um modelo de Formulario de Cadastro Similar à Enchoice ou Msmget
oModel:AddFields('SRD_MASTER', /*cOwner*/, oStruct, /*bPreValidacao*/;
                       , /*bPosValidacao*/, /*bCarga*/ )

//Adiciona Descricao do Modelo de Dados
oModel:SetDescription( "Lançamentos Acumulados Folha" )

//Adiciona Descricao do Componente do Modelo de Dados      
oModel:GetModel( 'SRD_MASTER' ):SetDescription( "Lançamentos Acumulados Folha")

//A Chave Primária é obrigatória, caso não tenha defina um array vazio
//oModel:SetPrimaryKey({'RA_FILIAL','RA_CODSER'})  

oModel:GetModel('SRD_MASTER'):SetLoadFilter(, " RA_SITFOLH NOT IN ('D','T') " )
    
Return(oModel)

/* VIEW */
Static Function ViewDef()
Local oStruct	:=	FWFormStruct(2,"SRD") 	//Retorna a Estrutura do Alias passado
                                            // como Parametro (1=Model,2=View)
Local oModel	:=	FwLoadModel('QFOL009')	//Retorna o Objeto do Modelo de Dados 
Local oView		:=	FwFormView():New()      //Instancia do Objeto de Visualização

//Define o Modelo sobre qual a Visualizacao sera utilizada
oView:SetModel(oModel)	

//oView:SetFieldAction("Z3_DOC" 	, {|oView, oModel| fCompDOC(oView, oModel)})

//Vincula o Objeto visual de Cadastro com o modelo 
oView:AddField( 'SRD_VIEW', oStruct, 'SRD_MASTER')

//Define o Preenchimento da Janela
oView:CreateHorizontalBox( 'ID_BOX_ALL'  , 100 )

// Relaciona o ID da View com o "box" para exibicao
oView:SetOwnerView( 'SRD_VIEW', 'ID_BOX_ALL' )

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

User Function QQFOL009A

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
        
			/*
            if nOper == 3 .or. nOper == 4
                if !RetCodUsr() $ GETMV("MV_XMVFOLD")
                    MsgInfo("Usuário sem Permissão para Acessar a Rotina","Atenção")
                    xRet := .F.
                Endif
            Endif
			*/

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
