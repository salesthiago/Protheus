#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "FWMVCDEF.CH"

/*/{Protheus.doc} CNTA121
Ponto de Entrada Padrao MVC da rotina de Medicao de Contratos (CNTA121,
beta). Registra na tabela ZLG (timeline do contrato) os eventos de
Inclusao/Alteracao/Exclusao/Estorno de medicao.

IMPORTANTE: este ARQUIVO se chama "CNTA121PE.prw" (nao "CNTA121.prw") porque
o proprio fonte padrao da TOTVS para a rotina de medicao ja se chama
CNTA121.PRW -- o RPO nao aceita dois fontes com o mesmo nome, mesmo em pastas
diferentes. O nome do ARQUIVO pode ser qualquer um; o que precisa ser
exatamente "CNTA121" e o nome da FUNCAO abaixo (User Function CNTA121()),
pois e assim que o framework a localiza.

IMPORTANTE: so pode existir UMA "User Function CNTA121()" em todo o RPO -- a
TOTVS chama sempre essa unica funcao para TODOS os eventos MVC da rotina de
medicao, identificados por ParamIxb[2] (cIdPonto)/ParamIxb[3] (cIdModel). Se
no futuro precisar tratar mais eventos do CNTA121 (ex: geracao de multas,
rateios, botoes customizados), adicione um novo "Case"/"If" DENTRO deste
mesmo arquivo -- criar outra "User Function CNTA121()" em outro fonte gera
conflito de nome global e um dos dois deixa de funcionar.

Eventos tratados aqui:
 - FORMCOMMITTTSPOS / CNDMASTER: executado apos a gravacao (commit) do
   cabecalho da medicao (tabela CND) -- cobre Inclusao/Alteracao/Exclusao.
   Equivalente ao antigo CN130PGRV/MD130GRV(pos). Usa
   oModelCND:GetModel():GetOperation() para identificar qual das tres foi.
 - MODELVLDACTIVE + FwIsInCallStack("CN121Estorn"): unico evento MVC chamado
   durante o estorno da medicao (a propria documentacao oficial do CNTA121
   afirma: "as demais operacoes de estorno sao feitas sem utilizar o modelo
   de dados"). Dispara ANTES do estorno ser efetivado -- e um gate de
   validacao, nao uma notificacao de sucesso -- entao o registro em ZLG
   aqui e "melhor esforco": pode ficar gravado mesmo que outra validacao
   bloqueie o estorno na sequencia. Nesse ponto o modelo ainda nao foi
   ativado, entao os dados sao lidos direto do alias CND (conforme o
   proprio exemplo oficial da TOTVS para este evento).

@type User Function
@param ParamIxb[1] objeto, varia conforme o evento (oModel, submodelo, etc)
@param ParamIxb[2] caractere, identificador do evento (cIdPonto)
@param ParamIxb[3] caractere, identificador do modelo/submodelo (cIdModel)
@return logical ou vetor, conforme o evento (ver exemplos oficiais TOTVS em
"CNTA121 - Exemplos pontos de entrada MVC")
@since 2026-07-27
/*/
//=============================================================================================================================
User Function CNTA121()
//=============================================================================================================================
    Local aParam   := PARAMIXB
    Local xRet     := .T.
    Local cIdPonto := ""
    Local cIdModel := ""

    If aParam <> Nil
        cIdPonto := AllTrim(aParam[2])
        cIdModel := aParam[3]

        If cIdPonto == "FORMCOMMITTTSPOS" .And. cIdModel == "CNDMASTER"
            LogMedFormPos(aParam[1])

        ElseIf cIdPonto == "MODELVLDACTIVE" .And. FwIsInCallStack("CN121Estorn")
            LogMedEstorno()

        EndIf
    EndIf

Return xRet

/*/{Protheus.doc} LogMedFormPos
Registra em ZLG a Inclusao/Alteracao/Exclusao do cabecalho da medicao (CND),
disparado pelo evento FORMCOMMITTTSPOS/CNDMASTER (apos a gravacao ja ter
ocorrido). O "antes" fica vazio porque, nesse ponto, o valor anterior da
situacao ja foi sobrescrito em disco -- so o "depois" (estado atual, pos
gravacao) esta disponivel de forma confiavel.
@type Static Function
@param oModelCND objeto FwFormModel, submodelo CNDMASTER (ParamIxb[1] do evento)
@return Nil
/*/
//=============================================================================================================================
Static Function LogMedFormPos(oModelCND)
//=============================================================================================================================
    Local oModel  := oModelCND:GetModel()
    Local nOperac := oModel:GetOperation()
    Local cContra := AllTrim(oModelCND:GetValue("CND_CONTRA"))
    Local cRevisa := AllTrim(oModelCND:GetValue("CND_REVISA"))
    Local cNumMed := AllTrim(oModelCND:GetValue("CND_NUMMED"))
    Local cSituac := AllTrim(oModelCND:GetValue("CND_SITUAC"))
    Local cAcao   := ""

    Do Case
    Case nOperac == MODEL_OPERATION_INSERT
        cAcao := "MEDICAO_INCLUSAO"

    Case nOperac == MODEL_OPERATION_UPDATE
        cAcao := "MEDICAO_ALTERACAO"

    Case nOperac == MODEL_OPERATION_DELETE
        cAcao := "MEDICAO_EXCLUSAO"

    OtherWise
        cAcao := ""
    EndCase

    If !Empty(cAcao)
        U_SCTGrvZLG(cContra, cRevisa, "", cNumMed, cAcao, "CNTA121(FORMCOMMITTTSPOS)", "", cSituac, "")
    EndIf

Return Nil

/*/{Protheus.doc} LogMedEstorno
Registra em ZLG a tentativa de estorno da medicao, disparada pelo evento
MODELVLDACTIVE quando chamado de dentro de CN121Estorn -- unico evento MVC
disponivel para o estorno. Le os dados direto do alias CND (o modelo ainda
nao foi ativado nesse ponto).
@type Static Function
@return Nil
/*/
//=============================================================================================================================
Static Function LogMedEstorno()
//=============================================================================================================================
    Local cContra := ""
    Local cRevisa := ""
    Local cNumMed := ""
    Local cSituac := ""

    If Select("CND") > 0 .And. CND->(!Eof())
        cContra := AllTrim(CND->CND_CONTRA)
        cRevisa := AllTrim(CND->CND_REVISA)
        cNumMed := AllTrim(CND->CND_NUMMED)
        cSituac := AllTrim(CND->CND_SITUAC)

        U_SCTGrvZLG(cContra, cRevisa, "", cNumMed, "MEDICAO_ESTORNO", "CNTA121(MODELVLDACTIVE/CN121Estorn)", cSituac, "",;
            "Registrado antes da efetivacao do estorno -- unico evento MVC disponivel nesse ponto")
    EndIf

Return Nil
