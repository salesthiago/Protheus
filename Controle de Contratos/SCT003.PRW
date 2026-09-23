#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "FWMVCDEF.CH"

/*/{Protheus.doc} SCT003
Cadastro de Solicitacoes de Contrato (tabela ZSC, com grids filhas ZSD -- Cotacoes --
e ZSE -- Anexos). Tela classica MVC para consulta/manutencao dentro do ambiente
Protheus; o fluxo real de trabalho do usuario (preencher necessidade, cadastrar as
3 cotacoes, eleger vencedor, anexar arquivos, enviar para aprovacao e aprovar/
reprovar Nivel 1/Nivel 2) acontece pela tela Angular/PO-UI do projeto sct001,
consumindo Controle de Contratos/API/RESTSCT.PRW -- esta tela e o espelho MVC
padrao (mesmo papel que SCT001 tem para ZAP), nao o fluxo de aprovacao em si.

A grid de Anexos (ZSE) e somente leitura aqui: o upload real do arquivo acontece
pela REST (POST /solicitacoes/zsc/anexo), pois um grid MVC classico nao tem um bom
widget de selecao/upload de arquivo.

Regras de status (ZSC_STATUS): 1-Rascunho, 2-Aguardando Aprovacao N1,
3-Aguardando Aprovacao N2, 4-Aprovado, 5-Reprovado. Alteracao/Exclusao manual so e
permitida com a solicitacao em Rascunho ou Reprovado (1/5) -- nos demais status ela
esta em fluxo de aprovacao e so pode ser mexida pelos endpoints de workflow do REST.
@type User Function
@author
@since 2026-07-28
@version 1
/*/
//=============================================================================================================================
    User Function SCT003()
//=============================================================================================================================
    Local oBrowse := FWMBrowse():New()

    oBrowse:SetAlias("ZSC")
    oBrowse:SetDescription("Solicitacoes de Contrato")
    oBrowse:Activate()

Return Nil

/*/{Protheus.doc} MenuDef
Define as opcoes de manutencao disponiveis no browse MVC (Incluir, Alterar,
Excluir, Visualizar). As transicoes de workflow (Enviar para Aprovacao, Aprovar,
Reprovar) NAO estao aqui -- vivem exclusivamente nos endpoints de
Controle de Contratos/API/RESTSCT.PRW, consumidos pela tela PO-UI.
@type Static Function
@return Array aRotina com as operacoes do menu
/*/
//=============================================================================================================================
    Static Function MenuDef()
//=============================================================================================================================
    Local aRotina := {}

    aAdd(aRotina, {"Pesquisar",  "PesqBrw",        0, 1})
    aAdd(aRotina, {"Visualizar", "ViewDef.SCT003", 0, 2})
    aAdd(aRotina, {"Incluir",    "ViewDef.SCT003", 0, 3})
    aAdd(aRotina, {"Alterar",    "ViewDef.SCT003", 0, 4})
    aAdd(aRotina, {"Excluir",    "ViewDef.SCT003", 0, 5})

Return aRotina

/*/{Protheus.doc} ModelDef
Define o modelo de dados MVC para a solicitacao de contrato: master ZSC +
grid ZSD (Cotacoes, minimo 3 linhas exigido no envio para aprovacao -- validado
no REST, nao aqui) + grid ZSE (Anexos, somente leitura nesta tela).
Chave primaria do master: ZSC_NUM (ZSC_FILIAL gerenciado pelo framework).
Vinculo das grids: ZSD_FILIAL+ZSD_NUM e ZSE_FILIAL+ZSE_NUM apontando para o
ZSC_NUM do master.

IMPORTANTE: confirme nesta build do Protheus a assinatura exata de
oModel:AddGrid()/oModel:SetRelation() -- variam entre versoes do framework;
os parametros usados abaixo seguem o padrao mais comum (grid simples vinculada
por filial+chave do master).
@type Static Function
@return Object MPFormModel configurado
/*/
//=============================================================================================================================
    Static Function ModelDef()
//=============================================================================================================================
    Local oModel     := MPFormModel():New("ZSCMODEL",, {|oModel| PostModel(oModel)},, )
    Local oStructZSC := FWFormStruct(1, "ZSC")
    Local oStructZSD := FWFormStruct(1, "ZSD")
    Local oStructZSE := FWFormStruct(1, "ZSE")

    oModel:AddFields("ZSCMASTER",, oStructZSC)
    oModel:AddGrid("ZSDDETAIL", "ZSCMASTER", oStructZSD)
    oModel:AddGrid("ZSEDETAIL", "ZSCMASTER", oStructZSE)

    oModel:SetPrimaryKey({"ZSC_NUM"})
    oModel:SetRelation("ZSDDETAIL", {{"ZSD_FILIAL", "xFilial('ZSD')"}, {"ZSD_NUM", "ZSC_NUM"}}, ZSD->(IndexKey(1)))
    oModel:SetRelation("ZSEDETAIL", {{"ZSE_FILIAL", "xFilial('ZSE')"}, {"ZSE_NUM", "ZSC_NUM"}}, ZSE->(IndexKey(1)))

    // Anexos: grid somente leitura nesta tela (ver cabecalho do arquivo) -- upload/remocao
    // real acontecem pela REST, que grava direto em ZSE por fora do modelo desta tela.
    oModel:GetModel("ZSEDETAIL"):SetNoInsertLine(.T.)
    oModel:GetModel("ZSEDETAIL"):SetNoUpdateLine(.T.)
    oModel:GetModel("ZSEDETAIL"):SetNoDeleteLine(.T.)

    oModel:SetDescription("Solicitacao de Contrato")
    oModel:GetModel("ZSCMASTER"):SetDescription("Dados da Solicitacao")
    oModel:GetModel("ZSDDETAIL"):SetDescription("Cotacoes")
    oModel:GetModel("ZSEDETAIL"):SetDescription("Anexos")

Return oModel

/*/{Protheus.doc} ViewDef
Define a apresentacao visual MVC: cabecalho da solicitacao no topo, grid de
cotacoes no meio, grid de anexos (somente leitura) embaixo.
@type Static Function
@return Object FWFormView configurado
/*/
//=============================================================================================================================
    Static Function ViewDef()
//=============================================================================================================================
    Local oView      := FWFormView():New()
    Local oStructZSC := FWFormStruct(2, "ZSC")
    Local oStructZSD := FWFormStruct(2, "ZSD")
    Local oStructZSE := FWFormStruct(2, "ZSE")

    oView:SetModel(ModelDef())
    oView:AddField("VIEW_ZSC", oStructZSC, "ZSCMASTER")
    oView:AddGrid("VIEW_ZSD", oStructZSD, "ZSDDETAIL")
    oView:AddGrid("VIEW_ZSE", oStructZSE, "ZSEDETAIL")

    oView:CreateHorizontalBox("HBSUP", 40)
    oView:CreateHorizontalBox("HBCOT", 30)
    oView:CreateHorizontalBox("HBANE", 30)

    oView:SetOwnerView("VIEW_ZSC", "HBSUP")
    oView:SetOwnerView("VIEW_ZSD", "HBCOT")
    oView:SetOwnerView("VIEW_ZSE", "HBANE")

    oView:EnableTitleView("VIEW_ZSC", "Solicitacao")
    oView:EnableTitleView("VIEW_ZSD", "Cotacoes")
    oView:EnableTitleView("VIEW_ZSE", "Anexos")

Return oView

/*/{Protheus.doc} PostModel
Validacoes cruzadas executadas apos preenchimento dos campos, antes da gravacao:
  - ZSC_STATUS deve ser um dos codigos validos (1 a 5).
  - Alteracao/Exclusao manual pela tela classica so e permitida com a situacao
    gravada em disco igual a Rascunho (1) ou Reprovado (5) -- nos demais status a
    solicitacao esta em fluxo de aprovacao e so pode ser mexida via REST/workflow.
@type Static Function
@param oModel Object, instancia do MPFormModel
@return logical, .T. se dados validos; .F. cancela a gravacao
/*/
//=============================================================================================================================
    Static Function PostModel(oModel)
//=============================================================================================================================
    Local oModelZSC  := oModel:GetModel("ZSCMASTER")
    Local cStatus    := Alltrim(oModelZSC:GetValue("ZSC_STATUS"))
    Local cStatusDsk := ""
    Local nOperac    := oModel:GetOperation()

    If Empty(cStatus) .Or. !(cStatus $ "12345")
        MsgStop("Status invalido. Informe um codigo de 1 a 5.", "Atencao")
        Return .F.
    EndIf

    If nOperac == MODEL_OPERATION_UPDATE .Or. nOperac == MODEL_OPERATION_DELETE
        cStatusDsk := SituacDisco(oModelZSC:GetValue("ZSC_NUM"))
        If !Empty(cStatusDsk) .And. !(cStatusDsk $ "15")
            MsgStop("Esta solicitacao esta em fluxo de aprovacao (nao esta em Rascunho/Reprovado) e nao pode ser alterada/excluida por aqui. Use os endpoints de workflow do RESTSCT.", "Atencao")
            Return .F.
        EndIf
    EndIf

Return .T.

/*/{Protheus.doc} SituacDisco
Le a situacao (ZSC_STATUS) gravada em disco para o numero de solicitacao
informado, protegendo contra o alias ZSC nao estar aberto/posicionado neste
contexto (mesmo padrao usado em SitDiscoCN9, Ponto de Entrada/CN300PCMT.prw).
@type Static Function
@param cNum caractere, numero da solicitacao (ZSC_NUM)
@return caractere, situacao gravada em disco, ou "" se nao for possivel ler
/*/
//=============================================================================================================================
Static Function SituacDisco(cNum)
//=============================================================================================================================
    Local cStatus  := ""
    Local cAliasQ  := GetNextAlias()

    BeginSql Alias cAliasQ
        SELECT ZSC.ZSC_STATUS
          FROM %table:ZSC% ZSC
         WHERE ZSC.%notDel%
           AND ZSC.ZSC_FILIAL = %xfilial:ZSC%
           AND ZSC.ZSC_NUM    = %exp:Alltrim(cNum)%
    EndSql

    If (cAliasQ)->(!Eof())
        cStatus := Alltrim((cAliasQ)->ZSC_STATUS)
    EndIf
    (cAliasQ)->(DbCloseArea())

Return cStatus
