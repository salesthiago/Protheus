/*
Ponto de entrada para alterar na SRA o novo turno do funcionário.

rotina PONA160

Sinval

02/2025
*/

#INCLUDE "TOTVS.CH"

user function PONAP160()

    Local nQtde := len(aCols)
    Local nPos  := 1
    Local cNovo := ""

    for nPos := 1 to nQtde

        if !aCols[nPos,13]

            cNovo := aCols[ nPos, 5  ]

        endif
    next 

    if !Empty(cNovo)
        SRA->(Reclock("SRA",.F.))
        SRA->RA_TNOTRAB := cNovo
        SRA->(msUnlock())
    endif
    
return

