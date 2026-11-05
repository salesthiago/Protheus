#INCLUDE "TOTVS.CH"
/*/{Protheus.doc} GP010VALPE
Validar os dados de inclusão/alteração de funcionários

1) Não pode incluir se tiver cpf ativo
2) não pode incluir se o cpf estiver como demitido com período menor que 180 dias

@type     function
@author      Sinval
@since       9/2024
/*/
User Function QFOL010()
    Local lRet      := .T.
    local _aAreas   := getarea()
    Local cCpf      := M->RA_CIC
    //Local cMat      := M->RA_MAT
    Local nTmpDemis := GETMV("MV_XTMPDEM",.F.,180)

    SRA->(DbSetOrder(20))
    if SRA->(DbSeek(cCpf))
        do while SRA->(!Eof()) .and.  SRA->RA_CIC == cCpf
            if SRA->RA_SITFOLH = "D"
                if (date() - nTmpDemis) <= SRA->RA_DEMISSA
                   	
                    MsgInfo("Funcionário/Candidato possui demissão Registrada " + Chr(13) + Chr(10) +;
                            "MENOR do que " +alltrim(str(nTmpDemis)) + " dias, Inclusão não Permitida. "+;
                            Chr(13) + Chr(10) + " Data da Demissão: "+dtoc(SRA->RA_DEMISSA), "Atenção")

                    lRet := .F.
                    exit

                endif
            elseif SRA->RA_SITFOLH $ "A- "

                    MsgInfo("Funcionário Ativo com este CPF " +cCpf+ Chr(13) + Chr(10) +;
                            "Inclusão não Permitida. " + Chr(13) + Chr(10) +;
                            " Matrícula: "+SRA->RA_MAT, "Atenção")
                    lRet := .F.
                    exit
            endif 

            SRA->(DbSkip())
        enddo

    else
        lRet := .T.    

    endif

    restarea(_aAreas)

Return( lRet )
