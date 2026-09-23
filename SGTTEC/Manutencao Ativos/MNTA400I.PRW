/* Ponto de entrada para substituir a impressão pelo novo fonte da OS

*/

User Function MNTA400I

    Local aRot :=  aClone(ParamIXB[1])

    Local nPos := AScan(aRot, {|x| UPPER(x[1]) == "IMPRIMIR" })

    aRot[nPos][2] := "U_QMNTR675(.F.,,,,4,,STJ->(RECNO()))"
    
    
Return aRot
