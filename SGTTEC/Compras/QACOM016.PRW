/*
Gatilho para preenchimento automático das colunas de data prevista de entrada e data digitação
C7_XENTREG 
C7_DATPRF 

*/
#INCLUDE "TOTVS.CH"
user function QACOM016()
    Local _cAreas   := getArea()
	Local nIt		:= 1
	Local nPosGrv	:= n+1
	Local nPosDtE	:= aScan(aHeader, { |x| AllTrim(Upper(x[2])) == 'C7_XDTENTR'})
	Local nPosDtd	:= aScan(aHeader, { |x| AllTrim(Upper(x[2])) == 'C7_DATPRF'})

	dDataDig	:= aCols[n][nPosDtE] //(18)dt. Prevista de Entrega
	dDataEnt	:= aCols[n][nPosDtd] //(19)

	for nIt := nPosGrv to len(aCols)

		if aCols[nIt][nPosDtE] = ctod("  /  / ")

		//if aCols[nIt][18] = ctod("  /  / ")
			aCols[nIt][nPosDtE] := dDataDig
		endif

		//aCols[nIt][19] := dDataEnt
		aCols[nIt][nPosDtd] := dDataEnt

	Next

    RestArea(_cAreas)

return(dDataDig)
