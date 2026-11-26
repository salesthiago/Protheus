/*

16320
236100

*/

user function AGRXFUNPS()
    Local aCap := PARAMIXB[1]

    nPesoTmp := "0"+alltrim(str(aCap[1]))
    
	nNovoPeso	:= val(substr(nPesoTmp,7,1)+substr(nPesoTmp,6,1)+substr(nPesoTmp,5,1)+substr(nPesoTmp,4,1)+substr(nPesoTmp,3,1)+substr(nPesoTmp,2,1)+substr(nPesoTmp,1,1))
	aCap[1]     := nNovoPeso

    //"0236100"

return(aCap)
