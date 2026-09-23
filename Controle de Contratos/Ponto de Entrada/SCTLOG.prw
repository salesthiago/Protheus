#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} SCTGrvZLG
Grava um registro de auditoria na tabela ZLG (timeline de contratos), chamada
pelos pontos de entrada de Gestao de Contratos (CN300PCMT e demais que vierem
a ser criados) para registrar cada evento do ciclo de vida do contrato.

IMPORTANTE: nao troca de alias de forma destrutiva -- salva e restaura o alias
corrente, pois e chamada de dentro de pontos de entrada do CNTA300 que ja tem
alias/registros posicionados (CN9, etc.).
@type Function
@param cContra caractere, numero do contrato (CN9_NUMERO)
@param cRevisa caractere, revisao do contrato (CN9_REVISA)
@param cNumero caractere, numero da planilha (opcional, "" quando nao se aplica)
@param cNumMed caractere, numero da medicao (opcional, "" quando nao se aplica)
@param cAcao caractere, acao ocorrida (Ex: "INCLUSAO","ALTERACAO","EXCLUSAO","MEDICAO")
@param cOrigem caractere, ponto de entrada/rotina de origem (Ex: "CN300PCMT")
@param cAntes caractere, situacao/status antes da acao
@param cDepois caractere, situacao/status depois da acao
@param cObs caractere, observacao livre (opcional)
@return Nil
@since 2026-07-27
/*/
//=============================================================================================================================
User Function SCTGrvZLG(cContra, cRevisa, cNumero, cNumMed, cAcao, cOrigem, cAntes, cDepois, cObs)
//=============================================================================================================================
    Local cAliasAnt := Alias()
    Local cUserId   := RetCodUsr()

    Default cNumero := ""
    Default cNumMed := ""
    Default cAntes  := ""
    Default cDepois := ""
    Default cObs    := ""

    DbSelectArea("ZLG")
    RecLock("ZLG", .T.)
        ZLG->ZLG_FILIAL := xFilial("ZLG")
        ZLG->ZLG_CONTRA := PadR(AllTrim(cContra), TamSX3("ZLG_CONTRA")[1])
        ZLG->ZLG_REVISA := PadR(AllTrim(cRevisa), TamSX3("ZLG_REVISA")[1])
        ZLG->ZLG_NUMERO := PadR(AllTrim(cNumero), TamSX3("ZLG_NUMERO")[1])
        ZLG->ZLG_NUMMED := PadR(AllTrim(cNumMed), TamSX3("ZLG_NUMMED")[1])
        ZLG->ZLG_ACAO   := PadR(AllTrim(cAcao),   TamSX3("ZLG_ACAO")[1])
        ZLG->ZLG_ORIGEM := PadR(AllTrim(cOrigem), TamSX3("ZLG_ORIGEM")[1])
        ZLG->ZLG_ANTES  := PadR(AllTrim(cAntes),  TamSX3("ZLG_ANTES")[1])
        ZLG->ZLG_DEPOIS := PadR(AllTrim(cDepois), TamSX3("ZLG_DEPOIS")[1])
        ZLG->ZLG_USUARI := PadR(cUserId, TamSX3("ZLG_USUARI")[1])
        ZLG->ZLG_NOMEUS := PadR(AllTrim(UsrRetName(cUserId)), TamSX3("ZLG_NOMEUS")[1])
        ZLG->ZLG_DATA   := Date()
        ZLG->ZLG_HORA   := Time()
        ZLG->ZLG_OBS    := PadR(AllTrim(cObs), TamSX3("ZLG_OBS")[1])
    MsUnlock()

    If !Empty(cAliasAnt) .And. Select(cAliasAnt) > 0
        DbSelectArea(cAliasAnt)
    EndIf

Return Nil
