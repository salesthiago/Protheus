#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "FWMVCDEF.CH"

/*/{Protheus.doc} ESTMVC001
Cadastro de Estoque Minimo e Maximo por Produto/Armazem (tabela ZEM).
Campos: ZEM_FILIAL, ZEM_PROD, ZEM_LOCAL, ZEM_ESTMIN, ZEM_ESTMAX, ZEM_STATUS.
Status: 1=Ativo / 2=Inativo.
@type User Function
@author
@since
@version 1
/*/
//=============================================================================================================================
    User Function ESTMVC001()
//=============================================================================================================================
    Local oBrowse := FWMBrowse():New()

    oBrowse:SetAlias("ZEM")
    oBrowse:SetDescription("Estoque Minimo e Maximo por Produto/Armazem")
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
    aAdd(aRotina, {"Visualizar",    "ViewDef.ESTMVC001", 0, 2 })
    aAdd(aRotina, {"Incluir",    "ViewDef.ESTMVC001", 0, 3})
    aAdd(aRotina, {"Alterar",    "ViewDef.ESTMVC001", 0, 4})
    aAdd(aRotina, {"Excluir",    "ViewDef.ESTMVC001", 0, 5})
    aAdd(aRotina, {"Relatorio",    "U_RELEST0001()", 0, 6})

Return aRotina

/*/{Protheus.doc} ModelDef
Define o modelo de dados MVC para a tabela ZEM.
Chave primaria: ZEM_PROD + ZEM_LOCAL (ZEM_FILIAL gerenciado pelo framework).
Validacao pos-campos: estoque maximo >= estoque minimo; status 1 ou 2.
@type Static Function
@return Object MPFormModel configurado
/*/
//=============================================================================================================================
    Static Function ModelDef()
//=============================================================================================================================
    Local oModel  := MPFormModel():New("ZEMMMODEL",, {|oModel| PostModel(oModel)},, )
    Local oStruct := FWFormStruct(1, "ZEM")

    oModel:AddFields("ZEMMASTER",, oStruct)
    oModel:SetPrimaryKey({"ZEM_PROD", "ZEM_LOCAL"})
    oModel:SetDescription("Estoque Minimo e Maximo")
    oModel:GetModel("ZEMMASTER"):SetDescription("Dados do Produto no Armazem")

Return oModel

/*/{Protheus.doc} ViewDef
Define a apresentacao visual MVC para a tabela ZEM.
@type Static Function
@return Object FWFormView configurado
/*/
//=============================================================================================================================
    Static Function ViewDef()
//=============================================================================================================================
    Local oView   := FWFormView():New()
    Local oStruct := FWFormStruct(2, "ZEM")

    oView:SetModel(ModelDef())
    oView:AddField("VIEW01", oStruct, "ZEMMASTER")
    oView:EnableTitleView("VIEW01", "Estoque Minimo e Maximo por Produto")

Return oView

/*/{Protheus.doc} PostModel
Validacoes cruzadas executadas apos preenchimento dos campos, antes da gravacao:
  - Filial + Produto + Armazem nao pode se repetir (somente na inclusao; o par
    Produto/Armazem e a chave primaria do modelo, entao nao e editavel na alteracao).
  - Estoque Maximo deve ser >= Estoque Minimo (quando ambos informados).
  - Status deve ser "1" (Ativo) ou "2" (Inativo).
@type Static Function
@param oModel Object, instancia do MPFormModel
@return logical, .T. se dados validos; .F. cancela a gravacao
/*/
//=============================================================================================================================
    Static Function PostModel(oModel)
//=============================================================================================================================
    Local nMin   := oModel:GetValue("ZEMMASTER", "ZEM_ESTMIN")
    Local nMax   := oModel:GetValue("ZEMMASTER", "ZEM_ESTMAX")
    Local cSts   := Alltrim(oModel:GetValue("ZEMMASTER", "ZEM_STATUS"))
    Local cProd  := Alltrim(oModel:GetValue("ZEMMASTER", "ZEM_PROD"))
    Local cLocal := Alltrim(oModel:GetValue("ZEMMASTER", "ZEM_LOCAL"))

    // Consulta via SQL (em vez de DbSeek por indice) para nao depender de qual
    // ordem/indice da ZEM corresponde a FILIAL+PROD+LOCAL, e o %notDel% ja
    // ignora registros com exclusao logica.
    If oModel:GetOperation() == MODEL_OPERATION_INSERT
        BeginSql Alias "ZEMDUP"
            SELECT ZEM.ZEM_PROD
              FROM %table:ZEM% ZEM
             WHERE ZEM.%notDel%
               AND ZEM.ZEM_FILIAL = %xfilial:ZEM%
               AND ZEM.ZEM_PROD   = %exp:cProd%
               AND ZEM.ZEM_LOCAL  = %exp:cLocal%
        EndSql

        If !ZEMDUP->(Eof())
            ZEMDUP->(DbCloseArea())
            MsgStop("Ja existe um registro de Estoque Minimo/Maximo para o Produto " + ;
                    cProd + " no Armazem " + cLocal + ".", "Atencao")
            Return .F.
        EndIf
        ZEMDUP->(DbCloseArea())
    EndIf

    If nMin > 0 .And. nMax > 0 .And. nMax < nMin
        MsgStop("Estoque Maximo (" + cValToChar(nMax) + ") nao pode ser menor que o " + ;
                "Estoque Minimo (" + cValToChar(nMin) + ").", "Atencao")
        Return .F.
    EndIf

    If Empty(cSts) .Or. !(cSts $ "12")
        MsgStop("Status invalido. Informe 1 - Ativo ou 2 - Inativo.", "Atencao")
        Return .F.
    EndIf

Return .T.
