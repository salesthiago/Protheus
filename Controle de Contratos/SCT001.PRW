#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "FWMVCDEF.CH"

/*/{Protheus.doc} SCT001
Cadastro de Aprovadores de Contratos (tabela ZAP).
Campos: ZAP_USER (codigo do usuario), ZAP_NUSER (nome do usuario), ZAP_SITUAC
(1=Ativo / 2=Inativo -- NAO e "A"/"I" apesar do nome do campo sugerir; API REST
em RESTZAP.PRW converte de/para "A"/"I" para o cliente Angular, ver
SituacDB/SituacApi), ZAP_CC (centro de custo -- quando preenchido, o usuario
so aprova solicitacoes deste centro de custo), ZAP_NIVEL (nivel de aprovacao,
1 ou 2).
@type User Function
@author
@since
@version 1
/*/
//=============================================================================================================================
    User Function SCT001()
//=============================================================================================================================
    Local oBrowse := FWMBrowse():New()

    oBrowse:SetAlias("ZAP")
    oBrowse:SetDescription("Aprovadores de Contratos")
    oBrowse:Activate()

Return Nil

/*/{Protheus.doc} MenuDef
Define as opcoes de manutencao disponiveis no browse MVC (Incluir, Alterar, Excluir, Visualizar).
@type Static Function
@return Array aRotina com as operacoes do menu
/*/
//=============================================================================================================================
    Static Function MenuDef()
//=============================================================================================================================
    Local aRotina := {}

    aAdd(aRotina, {"Pesquisar",    "PesqBrw", 0, 1  })
    aAdd(aRotina, {"Visualizar",    "ViewDef.SCT001", 0, 2 })
    aAdd(aRotina, {"Incluir",    "ViewDef.SCT001", 0, 3})
    aAdd(aRotina, {"Alterar",    "ViewDef.SCT001", 0, 4})
    aAdd(aRotina, {"Excluir",    "ViewDef.SCT001", 0, 5})

Return aRotina

/*/{Protheus.doc} ModelDef
Define o modelo de dados MVC para a tabela ZAP.
Chave primaria: ZAP_USER (ZAP_FILIAL gerenciado pelo framework).
Validacao pos-campos: situacao A/I; nivel 1 ou 2.
@type Static Function
@return Object MPFormModel configurado
/*/
//=============================================================================================================================
    Static Function ModelDef()
//=============================================================================================================================
    Local oModel  := MPFormModel():New("ZAPMODEL",, {|oModel| PostModel(oModel)},, )
    Local oStruct := FWFormStruct(1, "ZAP")

    oModel:AddFields("ZAPMASTER",, oStruct)
    oModel:SetPrimaryKey({"ZAP_USER"})
    oModel:SetDescription("Aprovadores de Contratos")
    oModel:GetModel("ZAPMASTER"):SetDescription("Dados do Aprovador")

Return oModel

/*/{Protheus.doc} ViewDef
Define a apresentacao visual MVC para a tabela ZAP.
@type Static Function
@return Object FWFormView configurado
/*/
//=============================================================================================================================
    Static Function ViewDef()
//=============================================================================================================================
    Local oView   := FWFormView():New()
    Local oStruct := FWFormStruct(2, "ZAP")

    oView:SetModel(ModelDef())
    oView:AddField("VIEW01", oStruct, "ZAPMASTER")
    oView:EnableTitleView("VIEW01", "Aprovador de Contratos")

Return oView

/*/{Protheus.doc} PostModel
Validacoes cruzadas executadas apos preenchimento dos campos, antes da gravacao:
  - Situacao deve ser "A" (Ativo) ou "I" (Inativo).
  - Nivel de aprovacao deve ser "1" ou "2".
@type Static Function
@param oModel Object, instancia do MPFormModel
@return logical, .T. se dados validos; .F. cancela a gravacao
/*/
//=============================================================================================================================
    Static Function PostModel(oModel)
//=============================================================================================================================
    // ZAP_SITUAC grava "1"=Ativo/"2"=Inativo no dicionario (confirmado -- nao e "A"/"I").
    // O REST (RESTZAP.PRW) ja converte antes de chamar SetValue, entao aqui o valor
    // recebido do model ja esta em formato de banco.
    Local cSituac := Alltrim(cValToChar(oModel:GetValue("ZAPMASTER", "ZAP_SITUAC")))
    Local cNivel  := Alltrim(cValToChar(oModel:GetValue("ZAPMASTER", "ZAP_NIVEL")))

    If Empty(cSituac) .Or. !Pertence("12", cSituac)
        MsgStop("Situacao invalida.", "Atencao")
        Return .F.
    EndIf

    If Empty(cNivel) .Or. !Pertence("12", cNivel)
        MsgStop("Nivel de aprovacao invalido. Informe 1 ou 2.", "Atencao")
        Return .F.
    EndIf

Return .T.
