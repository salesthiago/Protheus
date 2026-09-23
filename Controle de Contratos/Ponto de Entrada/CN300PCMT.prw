#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "FWMVCDEF.CH"

/*/{Protheus.doc} CN300PCMT
Ponto de entrada da rotina de Contratos (CNTA300/CNTA301), executado
imediatamente antes da gravacao (commit) do modelo. Usado aqui apenas como
"observador": nao cancela a gravacao (sempre retorna .T.), apenas registra o
evento (Inclusao/Alteracao/Exclusao) na tabela ZLG, para compor a timeline do
contrato.

Como o commit ainda nao ocorreu quando este PE executa, os campos lidos
diretamente do alias CN9 ainda refletem o estado ANTES da gravacao (o que esta
gravado em disco), enquanto oModel:GetValue() reflete o estado DEPOIS (o que
esta prestes a ser gravado). Essa e a base para preencher ZLG_ANTES/ZLG_DEPOIS.

IMPORTANTE: o Id do submodel "CN9MASTER" e o nome real, confirmado pelo
proprio exemplo oficial TOTVS deste ponto de entrada.

IMPORTANTE: quando oModel:GetModel("CN9MASTER") for Nil, o commit nao e do
cabecalho do contrato (provavelmente e do modelo de Medicao/CNTA301) -- esse
branch ainda esta pendente porque nao temos confirmado o Id do submodel e os
nomes de campo (numero da planilha/medicao) da Medicao. Enquanto isso nao for
confirmado, nao gravamos nada para nao registrar dados incorretos na timeline.

@type User Function
@param ParamIxb[1] objeto MPFormModel, modelo do CNTA300/CNTA301
@return logical, lCommit -- sempre .T. (nao cancela a gravacao)
@since 2026-07-27
/*/
//=============================================================================================================================
User Function CN300PCMT()
//=============================================================================================================================
    Local lCommit  := .T.
    Local oModel   := ParamIxb[1]
    Local oCN9     := Nil
    Local cContra  := ""
    Local cRevisa  := ""
    Local cAcao    := ""
    Local cAntes   := ""
    Local cDepois  := ""
    Local nOperac  := 0

    If ValType(oModel) == "O"
        oCN9 := oModel:GetModel("CN9MASTER")

        If !(oCN9 == Nil)
            nOperac := oModel:GetOperation()
            cContra := AllTrim(oCN9:GetValue("CN9_NUMERO"))
            cRevisa := AllTrim(oCN9:GetValue("CN9_REVISA"))
            cDepois := AllTrim(oCN9:GetValue("CN9_SITUAC"))

            Do Case
            Case nOperac == MODEL_OPERATION_INSERT
                cAcao  := "INCLUSAO"
                cAntes := ""

            Case nOperac == MODEL_OPERATION_UPDATE
                cAcao  := "ALTERACAO"
                cAntes := SitDiscoCN9(cContra, cRevisa)

            Case nOperac == MODEL_OPERATION_DELETE
                cAcao   := "EXCLUSAO"
                cAntes  := SitDiscoCN9(cContra, cRevisa)
                cDepois := "EXCLUIDO"

            OtherWise
                cAcao := ""
            EndCase

            If !Empty(cAcao)
                U_SCTGrvZLG(cContra, cRevisa,, , cAcao, "CN300PCMT", cAntes, cDepois, "")
            EndIf
        EndIf
    EndIf

Return lCommit

/*/{Protheus.doc} SitDiscoCN9
Le a situacao (CN9_SITUAC) gravada em disco para o contrato/revisao
informados, usando o alias CN9 se ele ja estiver aberto e posicionado no
registro correto -- protege contra o alias nao estar aberto neste contexto
(evita erro de "alias nao encontrado") e contra estar posicionado em outro
registro.
@type Static Function
@param cContra caractere, numero do contrato
@param cRevisa caractere, revisao do contrato
@return caractere, situacao gravada em disco, ou "" se nao for possivel ler
/*/
//=============================================================================================================================
Static Function SitDiscoCN9(cContra, cRevisa)
//=============================================================================================================================
    Local cSituac := ""

    If Select("CN9") > 0 .And. CN9->(!Eof()) .And.;
            AllTrim(CN9->CN9_NUMERO) == AllTrim(cContra) .And. AllTrim(CN9->CN9_REVISA) == AllTrim(cRevisa)
        cSituac := AllTrim(CN9->CN9_SITUAC)
    EndIf

Return cSituac
