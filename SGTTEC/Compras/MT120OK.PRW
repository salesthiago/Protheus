	
#INCLUDE "TOTVS.ch"
#INCLUDE "rwmake.ch"
#INCLUDE "TBICONN.ch"
#INCLUDE "FWMVCDEF.CH"
 
User Function  MT120OK()
    Local nPosCtb   := aScan(aHeader,{|x| AllTrim(x[2]) == 'C7_CONTA'})
    Local nPosProd  := aScan(aHeader,{|x| AllTrim(x[2]) == 'C7_PRODUTO'})
    Local lValido   := .T.
    Local nX        := 0
    Local cProd     := ""
	Local cEOL 		:= Chr(13)+Chr(10)    

    if cEmpAnt = "02"     
        For nX :=1 To Len( aCols )    
            If Empty(aCols[nX][nPosCtb])      
            
                lValido := .F.    

                cProd += cEOL + aCols[nX][nPosProd]    

            EndIf
        Next nX

        if !lValido
            
            Aviso("Código Contábil","Os Produtos Não possuem Código Contábil "+cProd,{'OK'},3)    

        EndIf
    else
        lValido := .T.        
    EndIf

Return(lValido)
