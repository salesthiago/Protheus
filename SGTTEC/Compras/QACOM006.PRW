/** {Protheus.doc} QACOM005
Registro da Chegada de Notas Fiscais Filiais

Sendo:
@Uso: Projeto Quebec
@Origem: 	
Reservado SZ3

*/

#Include "Totvs.ch"
#Include "FwMvcDef.ch"

User Function QACOM006()

Private oBrowse 	:= FwMBrowse():New()				//Variavel de Browse 

//Alias do Browse
oBrowse:SetAlias('SZ3')
//Descrição da Parte Superior Esquerda do Browse
oBrowse:SetDescripton("Registro de Notas Fiscais Filiais") 

//Adiciona Legenda
oBrowse:AddLegend( "Empty(Z3_DTACLA)" , "RED"	, "NF Não Classificada")
oBrowse:AddLegend( "!Empty(Z3_DTACLA)", "GREEN", "NF Classificado")

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
ADD OPTION aMenu TITLE 'Visualizar'     ACTION 'VIEWDEF.QACOM005'	OPERATION 2 ACCESS 0
ADD OPTION aMenu TITLE 'Incluir'        ACTION 'VIEWDEF.QACOM005' 	OPERATION 3 ACCESS 0
ADD OPTION aMenu TITLE 'Alterar'        ACTION 'VIEWDEF.QACOM005' 	OPERATION 4 ACCESS 0
ADD OPTION aMenu TITLE 'Excluir'        ACTION 'VIEWDEF.QACOM005' 	OPERATION 5 ACCESS 0
ADD OPTION aMenu TITLE 'Imprimir'       ACTION 'VIEWDEF.QACOM005'	OPERATION 6 ACCESS 0
ADD OPTION aMenu TITLE 'Conhecimento'   ACTION 'U_QAC5DOC()'	    OPERATION 4 ACCESS 0
ADD OPTION aMenu TITLE 'Lista Conf.'    ACTION 'U_QAC5LIS()'	    OPERATION 6 ACCESS 0
	
Return(aMenu)

Static Function ModelDef()
//Retorna a Estrutura do Alias passado como Parametro (1=Model,2=View)
Local oStruct	:=	FWFormStruct(1,"SZ3") 
Local oModel

//Instancia do Objeto de Modelo de Dados
oModel	:=	MpFormModel():New('QACOM06A',/*Pré-Validação*/ ,/*Pos-Validacao*/;
                                       ,/*Commit*/,/*Cancel*/)

//Adiciona um modelo de Formulario de Cadastro Similar à Enchoice ou Msmget
oModel:AddFields('SZ3_MASTER', /*cOwner*/, oStruct, /*bPreValidacao*/;
                       , /*bPosValidacao*/, /*bCarga*/ )

//Adiciona Descricao do Modelo de Dados
oModel:SetDescription( 'Registro de Notas Fiscais Filiais' )

//Adiciona Descricao do Componente do Modelo de Dados      
oModel:GetModel( 'SZ3_MASTER' ):SetDescription( 'Registro de Notas Fiscais Filiais' )

//A Chave Primária é obrigatória, caso não tenha defina um array vazio
oModel:SetPrimaryKey({'Z3_FILIAL','Z3_DOC','Z3_SERIE','Z3_CODFOR','Z3_LOJA'})  

Return(oModel)

/* VIEW */
Static Function ViewDef()
Local oStruct	:=	FWFormStruct(2,"SZ3") 	//Retorna a Estrutura do Alias passado
                                            // como Parametro (1=Model,2=View)
Local oModel	:=	FwLoadModel('QACOM006')	//Retorna o Objeto do Modelo de Dados 
Local oView		:=	FwFormView():New()      //Instancia do Objeto de Visualização

//Define o Modelo sobre qual a Visualizacao sera utilizada
oView:SetModel(oModel)	

oView:SetFieldAction("Z3_DOC" 	, {|oView, oModel| fCompDOC(oView, oModel)})

//Vincula o Objeto visual de Cadastro com o modelo 
oView:AddField( 'SZ3_VIEW', oStruct, 'SZ3_MASTER')

//Define o Preenchimento da Janela
oView:CreateHorizontalBox( 'ID_BOX_ALL'  , 100 )

// Relaciona o ID da View com o "box" para exibicao
oView:SetOwnerView( 'SZ3_VIEW', 'ID_BOX_ALL' )

Return(oView)                       


static function fCompDOC(oView, oModel)

	oModel 		:= FWModelActive()                
	oModelSZ3 	:= oModel:GetModel('SZ3_MASTER')

	oView  		:= FwViewActive()
	nOper		:= oModelSZ3:GetOperation()


	if nOper = 3
        cNFiscal    := oModelSZ3:GetValue('Z3_DOC')
		cNFiscal 	:= strZero(val(cNFiscal),9)

        oModelSZ3:LoadValue('Z3_DOC',cNFiscal)
		oView:Refresh()
	endif
return
  
user function QAC5DOC()

	Local _c9Filial := ""
	Local _c9FilEnt := ""
	Local _c9Entida := ""
	Local _c9EntidaP := "SC7"
	Local _c9CodEnt := ""
	Local _c9CodObj := ""
	Local _aObjetos := {}
	Local _c9CodEntP:= ""
	Local nId		:= 1

	SC7->(DbSetOrder(1))
	SC7->(DbSeek(xFilial("SC7")+ SZ3->Z3_PEDIDO ))
	_c9CodEntP := SC7->(C7_FILIAL+C7_NUM+C7_ITEM)
	
	MsDocument('SZ3',SZ3->(RECNO()), 4)

	_c9Filial := AC9->AC9_FILIAL
	_c9FilEnt := AC9->AC9_FILENT
	_c9Entida := AC9->AC9_ENTIDA
	_c9CodObj := AC9->AC9_CODOBJ
	_c9CodEnt := AC9->AC9_CODENT

	AC9->(DbSetOrder(2)) //AC9_FILIAL + AC9_ENTIDA + AC9_FILENT + AC9_CODENT
	if AC9->(DbSeek(_c9Filial + _c9Entida + _c9FilEnt + _c9CodEnt))
		do while AC9->(!Eof()) .and. AC9->(AC9_FILIAL+AC9_ENTIDA+AC9_FILENT+AC9_CODENT) == _c9Filial + _c9Entida + _c9FilEnt + _c9CodEnt

			aAdd(_aObjetos, AC9->AC9_CODOBJ)
		
			AC9->(DbSkip())
		enddo
	endif

	if len(_aObjetos) > 0 
		
		AC9->(DbSetOrder(2)) //AC9_FILIAL + AC9_ENTIDA + AC9_FILENT + AC9_CODENT
		if AC9->(DbSeek(_c9Filial + _c9EntidaP + _c9FilEnt + _c9CodEntP))
			do while AC9->(!Eof()) .and. alltrim(AC9->(AC9_FILIAL+AC9_ENTIDA+AC9_FILENT+AC9_CODENT)) == _c9Filial + _c9EntidaP + _c9FilEnt + _c9CodEntP

				AC9->(Reclock("AC9",.F.))
				AC9->(dbDelete())		
				AC9->(msUnlock())	

				AC9->(DbSkip())
			enddo
		endif

		for nId := 1 to len(_aObjetos)
			AC9->(reclock("AC9",.T.))
			AC9->AC9_FILIAL	:= _c9Filial
			AC9->AC9_FILENT	:= _c9FilEnt 
			AC9->AC9_ENTIDA	:= _c9EntidaP
			AC9->AC9_CODOBJ := _aObjetos[nId]
			AC9->AC9_CODENT	:= _c9CodEntP
			AC9->(msUnlock())
		next
	endif

return(.T.)


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

User Function QACOM06A

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
