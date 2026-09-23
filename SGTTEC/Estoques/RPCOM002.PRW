#Include "PROTHEUS.CH"
#Include "RWMAKE.CH"   
#include "RPTDEF.ch"
 
User Function RPCOM002(cFilOri, cDocOri, cSerOri, cForOri, cLojOri)
    Local aParamBox    := {}
	Local cProdDe 	:= space(TamSX3("B1_COD")[1])
    local cProdAte	:= REPLICATE("Z",TAMSX3("B1_COD")[1])
	Local _aAreas	:= GetArea()
	
	cbkp01	:= MV_PAR01
	cbkp02	:= MV_PAR02
	cbkp03	:= MV_PAR03

	aAdd(aParamBox,{01,"Produto de"		, cProdDe	, ""                    ,"","SB1"    ,"", 60,.F.})    // MV_PAR01
    aAdd(aParamBox,{01,"Produto ate"	, cProdAte	, ""                    ,"","SB1"    ,"", 60,.T.})    // MV_PAR02

    If ParamBox(aParamBox,"Etiqueta Produto",/*aRet*/,/*bOk*/,/*aButtons*/,.T.,,,,FUNNAME(),.T.,.T.)
		cProdDe 	:= MV_PAR01
		cProdAte	:= MV_PAR02

		Processa({ || xPrintEtq(cFilOri, cDocOri, cSerOri, cForOri, cLojOri, cProdDe, cProdAte),OemToAnsi('Gerando o relatório.')}, OemToAnsi('Aguarde...'))
	
	endif

	MV_PAR01 := cbkp01
	MV_PAR02 := cbkp02
	MV_PAR03 := cbkp03
	
	RestArea(_aAreas)
Return  
 
Static Function xPrintEtq(cFilOri, cDocOri, cSerOri, cForOri, cLojOri, cProdDe, cProdAte)  
 
	Local aMatProd := {}
	
	SD1->(dbSetorder(1))
	SD1->(dbSeek(cFilOri+cDocOri+cSerOri+cForOri+cLojOri))
	do while SD1->(!Eof()) .and. SD1->(D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA) == cFilOri+cDocOri+cSerOri+cForOri+cLojOri
		if SD1->D1_COD >= cProdDe .and. SD1->D1_COD <= cProdAte

			if SD1->D1_XQTETIQ > 0
				nPos := AScan(aMatProd, {|x| x[1] == SD1->D1_COD })

				if nPos == 0 
									//  15         09            10         
					aAdd(aMatProd, {SD1->D1_COD, SD1->D1_DOC, SD1->D1_DTDIGIT, SD1->D1_XQTETIQ })
				else
					aMatProd[nPos][3] += SD1->D1_XQTETIQ
				endif
			endif
		endif

		SD1->(dbSkip())
	enddo

	//gerando a a continuidade de impressão, ou seja, matriz contendo os pares de impressão
	// XXXXXX XXXXXXX
	// XXXXXX XXXXXXX

	U_fGeraEtq(aMatProd)

	SD1->(dbSetorder(1))
	SD1->(dbSeek(cFilOri+cDocOri+cSerOri+cForOri+cLojOri))

Return

user Function fGeraEtq(aMatProd)
	Local nX 		:= 0
	Local aMatImpr	:= {}
	Local nIt		:= 1
	Local nIti		:= 1

	Private oPrint
	Private oFont06		:= TFont():New('Arial',,06,,.F.,,,,.F.,.F.)
	Private oFont06n	:= TFont():New('Arial',,06,,.T.,,,,.F.,.F.)
	Private oFont08		:= TFont():New('Arial',,08,,.F.,,,,.F.,.F.)
	Private oFont08n	:= TFont():New('Arial',,08,,.T.,,,,.F.,.F.)
	Private oFont09		:= TFont():New('Arial',,09,,.F.,,,,.F.,.F.)
	Private oFont09n	:= TFont():New('Arial',,09,,.T.,,,,.F.,.F.)
	Private oFont10		:= TFont():New('Arial',,10,,.F.,,,,.F.,.F.)
	Private oFont10n	:= TFont():New('Arial',,10,,.T.,,,,.F.,.F.)
	Private oFont12		:= TFont():New('Arial',,12,,.F.,,,,.F.,.F.)
	Private oFont12n	:= TFont():New('Arial',,12,,.T.,,,,.F.,.F.)
	Private oFont14		:= TFont():New('Arial',,14,,.F.,,,,.F.,.F.)
	Private oFont14n	:= TFont():New('Arial',,14,,.T.,,,,.F.,.F.)
	Private oFont26		:= TFont():New('Arial',,26,,.F.,,,,.F.,.F.)
	Private oFont26n	:= TFont():New('Arial',,26,,.T.,,,,.F.,.F.)
	Private nLin		:= 0 
 
	//Gerando a Matriz contendo as informações dos produtos que serão impressos.
	for nIt := 1 to len(aMatProd)
		//PRODUTO, NF, DATA, QTDE
		nQtde := aMatProd[nIt][4]

		if len(aMatImpr) > 0

			if aMatImpr[len(aMatImpr)][2] = "" // Significa que tem uma quebra de etiqueta
				aMatImpr[len(aMatImpr)][2] := aMatProd[nIt][1]+aMatProd[nIt][2]+dToc(aMatProd[nIt][3])
				nQtde := nQtde - 1
			endif 

		endif

		if MOD(nQtde, 2) == 0 

			for nIti := 1 to (nQtde/2)
				Aadd(aMatImpr, {aMatProd[nIt][1]+aMatProd[nIt][2]+dToc(aMatProd[nIt][3]), aMatProd[nIt][1]+aMatProd[nIt][2]+dToc(aMatProd[nIt][3])} )
			Next

		else 
			nQtde 	:= int((nQtde/2))

			for nIti := 1 to nQtde
				Aadd(aMatImpr, {aMatProd[nIt][1]+aMatProd[nIt][2]+dToc(aMatProd[nIt][3]), aMatProd[nIt][1]+aMatProd[nIt][2]+dToc(aMatProd[nIt][3])} )
			Next
			
			Aadd(aMatImpr, {aMatProd[nIt][1]+aMatProd[nIt][2]+dToc(aMatProd[nIt][3]), "" } )

		endif

	Next

	cArquivo := __cUserId+".REL"
	oPrint := FwMsPrinter():New(cArquivo, IMP_SPOOL, .T., NIL, .F. /*lSetup*/, NIL, NIL, NIL, NIL, .F.)
    //oPrint:setup()
	oPrint:SetPortrait()  
 
	//1cm +/- 117,5 px 

	For nX := 1 to len(aMatImpr)
 		oPrint:StartPage() 	
		
		nLin  := 0050

		if !empty(alltrim(substr(aMatImpr[nX][1],1,15)))
			oPrint:Say(nLin,0040, substr(Posicione("SB1",1,xFilial("SB1")+substr(aMatImpr[nX][1],1,15),"B1_DESC"),01,30), oFont09N,,,,0)
		endif

		if !empty(alltrim(substr(aMatImpr[nX][2],1,15)))
			oPrint:Say(nLin,0560, substr(Posicione("SB1",1,xFilial("SB1")+substr(aMatImpr[nX][2],1,15),"B1_DESC"),01,30), oFont09N,,,,0)
		endif
		nLin += 0030

		if !empty(alltrim(substr(aMatImpr[nX][1],1,15)))		
        	oPrint:Say(nLin,0040,substr(Posicione("SB1",1,xFilial("SB1")+substr(aMatImpr[nX][1],1,15),"B1_DESC"),31,30),oFont09N,,,,0)
		endif

		if !empty(alltrim(substr(aMatImpr[nX][2],1,15)))
			oPrint:Say(nLin,0560,substr(Posicione("SB1",1,xFilial("SB1")+substr(aMatImpr[nX][2],1,15),"B1_DESC"),31,30),oFont09N,,,,0)
		endif
		nLin += 0040

		if !empty(alltrim(substr(aMatImpr[nX][1],1,15)))	
        	oPrint:Say(nLin,0180,"NF: "+substr(aMatImpr[nX][1],16,09),oFont12,,,,0)
		endif

		if !empty(alltrim(substr(aMatImpr[nX][2],1,15)))		
			oPrint:Say(nLin,0670,"NF: "+substr(aMatImpr[nX][2],16,09),oFont12,,,,0)
		endif
		nLin += 0040

		if !empty(alltrim(substr(aMatImpr[nX][1],1,15)))
        	oPrint:Say(nLin,0130,"DT ENT: "+substr(aMatImpr[nX][1],25,10),oFont12,,,,0)
		endif
		if !empty(alltrim(substr(aMatImpr[nX][2],1,15)))	
			oPrint:Say(nLin,0620,"DT ENT: "+substr(aMatImpr[nX][1],25,10),oFont12,,,,0)
		endif
		nLin += 0340

		if !empty(alltrim(substr(aMatImpr[nX][1],1,15)))
        	oPrint:FWMSBAR("CODE128", nLin/117 ,  0.9 ,alltrim(substr(aMatImpr[nX][1],1,15)) , oPrint, .F., NIL, .T., 0.017, 0.8 , .T., NIL, NIL, .F.)
		endif
		if !empty(alltrim(substr(aMatImpr[nX][2],1,15)))		
        	oPrint:FWMSBAR("CODE128", nLin/117 , 12.4 ,alltrim(substr(aMatImpr[nX][2],1,15)) , oPrint, .F., NIL, .T., 0.017, 0.8 , .T., NIL, NIL, .F.)
		endif

		oPrint:EndPage()
	Next nX
	
	oPrint:Print()
Return 
