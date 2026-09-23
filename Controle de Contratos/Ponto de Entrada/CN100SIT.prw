#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} CN100SIT
Ponto de entrada da rotina de Contratos (CNTA100.PRW / Function CN100Situac),
executado logo APOS a situacao do contrato ter sido alterada (o processamento
interno do sistema ja ocorreu quando este PE dispara). Registra a transicao de
situacao na tabela ZLG (timeline do contrato).

Diferente do CN300PCMT (que loga Inclusao/Alteracao/Exclusao de forma
generica, incluindo a situacao "antes/depois" obtida por tentativa via
oModel/alias CN9), este PE recebe o "antes" e o "depois" prontos, direto dos
parametros -- por isso e a fonte mais confiavel para transicoes de situacao
especificamente.

IMPORTANTE: como consequencia, uma alteracao de contrato que muda a situacao
pode gerar DUAS linhas na timeline para o mesmo evento: uma "ALTERACAO"
generica (via CN300PCMT) e uma "MUDANCA_SITUACAO" especifica (via este PE).
Isso foi mantido assim de proposito (granularidades diferentes); se no futuro
quiser eliminar a duplicidade, ajustar o CN300PCMT para nao gravar quando a
situacao mudar (esse caso ja fica coberto por este PE).

@type User Function
@param ParamIxb[1] caractere, situacao atual do contrato (antes da mudanca)
@param ParamIxb[2] caractere, nova situacao do contrato (depois da mudanca)
@return Nil
@since 2026-07-27
/*/
//=============================================================================================================================
User Function CN100SIT()
//=============================================================================================================================
    Local cSitAntes  := AllTrim(ParamIxb[1])
    Local cSitDepois := AllTrim(ParamIxb[2])
    Local cContra    := ""
    Local cRevisa    := ""

    If Select("CN9") > 0 .And. CN9->(!Eof())
        cContra := AllTrim(CN9->CN9_NUMERO)
        cRevisa := AllTrim(CN9->CN9_REVISA)

        U_SCTGrvZLG(cContra, cRevisa,, , "MUDANCA_SITUACAO", "CN100SIT", cSitAntes, cSitDepois, "")
    EndIf

Return Nil
