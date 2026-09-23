#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "FWMVCDEF.CH"

/*/{Protheus.doc} SCT002
Timeline de Contratos (tabela ZLG) -- somente visualizacao. Mostra o historico
de eventos (Inclusao/Alteracao/Exclusao, e futuramente Medicao) gravado pelos
pontos de entrada CN300PCMT e C100VLAT (ver Ponto de Entrada/CN300PCMT.prw).

Tela apenas de consulta: o menu abaixo so expoe Pesquisar e Visualizar --
gravacao em ZLG deve acontecer exclusivamente pelos pontos de entrada, nunca
por digitacao manual do usuario.

Para localizar a timeline de um contrato especifico, use a pesquisa padrao do
browse (Pesquisar) filtrando por ZLG_CONTRA/ZLG_REVISA.

IMPORTANTE: a ordem de exibicao do browse segue o indice padrao (ordem 1) da
tabela ZLG no dicionario de dados -- confirme se ele agrupa por
contrato+revisao e ordena por data/hora, para que a tela realmente leia como
uma linha do tempo. Caso nao exista esse indice, criar um na ordem
ZLG_FILIAL+ZLG_CONTRA+ZLG_REVISA+ZLG_DATA+ZLG_HORA.
@type User Function
@author
@since 2026-07-27
@version 1
/*/
//=============================================================================================================================
User Function SCT002()
//=============================================================================================================================
    Local oBrowse := FWMBrowse():New()

    oBrowse:SetAlias("ZLG")
    oBrowse:SetDescription("Timeline de Contratos")
    oBrowse:Activate()

Return Nil

/*/{Protheus.doc} MenuDef
Define as opcoes disponiveis no browse MVC -- apenas Pesquisar e Visualizar,
pois ZLG e uma tabela de log/auditoria (sem Incluir/Alterar/Excluir manual).
@type Static Function
@return Array aRotina com as operacoes do menu
/*/
//=============================================================================================================================
    Static Function MenuDef()
//=============================================================================================================================
    Local aRotina := {}

    aAdd(aRotina, {"Pesquisar",  "PesqBrw",        0, 1})
    aAdd(aRotina, {"Visualizar", "ViewDef.SCT002", 0, 2})

Return aRotina

/*/{Protheus.doc} ModelDef
Define o modelo de dados MVC (somente leitura) para a tabela ZLG.
Chave usada no model (identificacao do registro de log, nao um indice de
negocio): ZLG_CONTRA+ZLG_REVISA+ZLG_NUMERO+ZLG_NUMMED+ZLG_DATA+ZLG_HORA+ZLG_USUARI
(ZLG_FILIAL gerenciado pelo framework).
@type Static Function
@return Object MPFormModel configurado
/*/
//=============================================================================================================================
    Static Function ModelDef()
//=============================================================================================================================
    Local oModel  := MPFormModel():New("ZLGMODEL")
    Local oStruct := FWFormStruct(1, "ZLG")

    oModel:AddFields("ZLGMASTER",, oStruct)
    oModel:SetPrimaryKey({"ZLG_CONTRA", "ZLG_REVISA", "ZLG_NUMERO", "ZLG_NUMMED", "ZLG_DATA", "ZLG_HORA", "ZLG_USUARI"})
    oModel:SetDescription("Timeline de Contratos")
    oModel:GetModel("ZLGMASTER"):SetDescription("Evento do Contrato")

Return oModel

/*/{Protheus.doc} ViewDef
Define a apresentacao visual MVC (somente leitura) para a tabela ZLG.
@type Static Function
@return Object FWFormView configurado
/*/
//=============================================================================================================================
    Static Function ViewDef()
//=============================================================================================================================
    Local oView   := FWFormView():New()
    Local oStruct := FWFormStruct(2, "ZLG")

    oView:SetModel(ModelDef())
    oView:AddField("VIEW01", oStruct, "ZLGMASTER")
    oView:EnableTitleView("VIEW01", "Evento do Contrato")

Return oView
