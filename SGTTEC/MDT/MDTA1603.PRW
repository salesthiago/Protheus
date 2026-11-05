/*

    Ponto de Entrada para alterar o status do funcionário, quando for retorno ao trabalho e estiver Apto.
    Sinval
    11/2024
    TMY_NATEXA - (natureza = 4 retorno ao trabalho)  TMY_INDPAR
*/

user function MDTA1603()
    Local _aAreas   := getarea()
    Local cIndPar   := TMY->TMY_INDPAR 
    Local cNatAso   := TMY->TMY_NATEXA
    Local cNumFic   := TMY->TMY_NUMFIC
    Local cFilFic   := TMY->TMY_FILIAL
    Local cCodMat   := ""

    TM0->(DbSetOrder(1))
    if TM0->(dbSeek(cFilFic+cNumFic))
        cCodMat := TM0->TM0_MAT
    EndIf

    if cIndPar = "1" .and. cNatAso = "4"
        SRA->(DbSetOrder(1))
        if SRA->(DbSeek(cFilFic+cCodMat))
            if SRA->RA_SITFOLH = "A"
                SRA->(RecLock("SRA",.F.))
                SRA->RA_SITFOLH := " "
                SRA->(MsUnLock())
            endif
        EndIf

    EndIf

    Mdtr465()
    
    RestArea(_aAreas)

return(Nil)
