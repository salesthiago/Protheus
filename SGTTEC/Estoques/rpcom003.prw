#Include "PROTHEUS.CH"
#Include "RWMAKE.CH"
#include "RPTDEF.ch"

User Function RPCOM003(cFilOri, cDocOri, cSerOri, cForOri, cLojOri)
	Local aParamBox    := {}
	Local cProdDe 	:= space(TamSX3("B1_COD")[1])
	local cProdAte	:= REPLICATE("Z",TAMSX3("B1_COD")[1])
	Local nQtdeEtq	:= 0

	aAdd(aParamBox,{01,"Produto de"		, cProdDe	, ""                    ,"","SB1"   ,"", 60,.F.})    // MV_PAR01
	aAdd(aParamBox,{01,"Produto ate"	, cProdAte	, ""                    ,"","SB1"   ,"", 60,.T.})    // MV_PAR02
	aAdd(aParamBox,{01,"Qtde Etiquetas"	, nQtdeEtq	, "@E 999"              ,"",""    	,"", 60,.T.})    // MV_PAR02

	If ParamBox(aParamBox,"Etiqueta Produto",/*aRet*/,/*bOk*/,/*aButtons*/,.T.,,,,FUNNAME(),.T.,.T.)
		cProdDe 	:= MV_PAR01
		cProdAte	:= MV_PAR02
		nQtdeEtq	:= MV_PAR03

		Processa({ || xPrintEtq(cProdDe, cProdAte, nQtdeEtq),OemToAnsi('Gerando Etquitas')}, OemToAnsi('Aguarde...'))

	endif

Return

Static Function xPrintEtq(cProdDe, cProdAte, nQtdeEtq)

	Local aMatProd	:= {}

	Private oPrint
	Private oFont06		:= TFont():New('Arial',,06,,.F.,,,,.F.,.F.)
	Private oFont06n	:= TFont():New('Arial',,06,,.T.,,,,.F.,.F.)
	Private oFont08		:= TFont():New('Arial',,08,,.F.,,,,.F.,.F.)
	Private oFont08n	:= TFont():New('Arial',,08,,.T.,,,,.F.,.F.)
	Private oFont10		:= TFont():New('Arial',,10,,.F.,,,,.F.,.F.)
	Private oFont10n	:= TFont():New('Arial',,10,,.T.,,,,.F.,.F.)
	Private oFont12		:= TFont():New('Arial',,12,,.F.,,,,.F.,.F.)
	Private oFont12n	:= TFont():New('Arial',,12,,.T.,,,,.F.,.F.)
	Private oFont14		:= TFont():New('Arial',,14,,.F.,,,,.F.,.F.)
	Private oFont14n	:= TFont():New('Arial',,14,,.T.,,,,.F.,.F.)
	Private oFont26		:= TFont():New('Arial',,26,,.F.,,,,.F.,.F.)
	Private oFont26n	:= TFont():New('Arial',,26,,.T.,,,,.F.,.F.)
	Private nLin		:= 0

	SB1->(dbSetorder(1))
	SB1->(dbSeek(xFilial("SB1")+cProdDe))
	do while SB1->(!Eof()) .and. SB1->(B1_FILIAL+B1_COD) = xFilial("SB1")+cProdDe
		if SB1->B1_COD >= cProdDe .and. SB1->B1_COD <= cProdAte

			nPos := AScan(aMatProd, {|x| x[1] == SB1->B1_COD })

			if nPos == 0
				//  15         09            10
				aAdd(aMatProd, {SB1->B1_COD, "MANUAL   ", dDatabase, nQtdeEtq })
			else
				aMatProd[nPos][3] += nQtdeEtq
			endif
		endif

		SB1->(dbSkip())
	enddo

	U_fGeraEtq(aMatProd)

Return

user Function fGeraEtq(aMatProd)
	Local nX 		:= 0
	Local aMatImpr	:= {}
	Local nIt		:= 1
	Local nCont     := 1
	//Local nIti		:= 1

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


	    WHILE nQtde >= nCont
			Aadd(aMatImpr, {aMatProd[nIt][1]+aMatProd[nIt][2]+dToc(aMatProd[nIt][3]), "" } )
        nCont++
		EndDo

	Next

	cArquivo := __cUserId+".REL"
	oPrint := FwMsPrinter():New(cArquivo, IMP_SPOOL, .T., NIL, .F. /*lSetup*/, NIL, NIL, NIL, NIL, .F.)

	oPrint:SetPortrait()


	For nX := 1 to len(aMatImpr)
		oPrint:StartPage()

		nLin  := 0050

		if !empty(alltrim(substr(aMatImpr[nX][1],1,15)))
			oPrint:Say(nLin,0200, substr(Posicione("SB1",1,xFilial("SB1")+substr(aMatImpr[nX][1],1,15),"B1_DESC"),01,30), oFont09N,,,,0)
				nLin += 0030
			oPrint:Say(nLin,0200, substr(Posicione("SB1",1,xFilial("SB1")+substr(aMatImpr[nX][1],1,15),"B1_GRUPO"),01,30), oFont09N,,,,0)
		endif

		nLin += 0030

		if !empty(alltrim(substr(aMatImpr[nX][1],1,15)))
			oPrint:Say(nLin,0200,"NF: "+substr(aMatImpr[nX][1],16,09),oFont12,,,,0)
		endif

		nLin += 0040

		if !empty(alltrim(substr(aMatImpr[nX][1],1,15)))
			oPrint:Say(nLin,0200,"DT ENT: "+substr(aMatImpr[nX][1],25,10),oFont12,,,,0)
		endif

		nLin += 0300

		if !empty(alltrim(substr(aMatImpr[nX][1],1,15)))
			oPrint:FWMSBAR("CODE128", nLin/117 ,  4.6,alltrim(substr(aMatImpr[nX][1],1,15)) , oPrint, .F., NIL, .T., 0.017, 0.8 , .T., NIL, NIL, .F.)
		endif

		oPrint:EndPage()
	Next nX
    

	oPrint:Print()

Return

