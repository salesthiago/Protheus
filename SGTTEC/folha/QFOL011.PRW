#INCLUDE "TOTVS.CH"
/*/{Protheus.doc} GP010VALPE
Validar os dados de inclusão/alteração de funcionários

1) Não pode incluir se tiver cpf ativo
2) não pode incluir se o cpf estiver como demitido com período menor que 180 dias

@type     function
@author      Sinval
@since       9/2024
/*/
User Function QFOL011()
    Local lRet      := .T.
    local _aAreas   := getarea()
    Local cCpf      := M->TM0_CPF
    Local cQuery    := ""
    Local cAliasTop := getNextAlias()

    cQuery := "SELECT COUNT(*) QTDE "
    cQuery += "FROM "+retSqlName("TM0") + " TM0 "
    cQuery += "WHERE TM0.D_E_L_E_T_ = ' ' "
    cQuery += "AND TM0.TM0_CPF = '"+cCpf+"' "
    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasTop,.T.,.T.)

    (cAliasTop)->(DbGoTop())

    if (cAliasTop)->QTDE > 0 
        MsgInfo("Candidato já Possui Ficha Médica neste CPF " +cCpf+ Chr(13) + Chr(10) +;
                "Inclusão não Permitida. " + Chr(13) + Chr(10) +;
                " Ficha Médica: "+TM0->TM0_NUMFIC, "Atenção")
        lRet := .F.
    else
        lRet := .T.    

    endif

    (cAliasTop)->(DbCloseArea())
    restarea(_aAreas)

Return( lRet )
