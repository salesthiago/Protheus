//----------------------------------------------------------------------------
/*/{Protheus.doc} MNTA7161
Realiza verificação por linha se deve importar os registros de abastecimentos. 
Tabela CTF
	A - Diesel comum		= 01
	B - Gasolina			= 04
	C - Álcool				= 06
	D - Gasolina aditivada	= 10
	E - Álcool aditivado	= 12
	F - Gasolina premium	= 
	G - Gás metano veicular	= 
	H - Diesel aditivado	= 
	R - Diesel S50			= 14
	S - Diesel S10			= 07
	T - Diesel S10 Aditivado=

@type function
@author Sinval 
@since 11/2021
@sample MNTA7161()

/*/
//----------------------------------------------------------------------------

#Include 'PROTHEUS.ch'

User Function MNTA7161()
Local lRetorno  := .T.
Local _aAreas 	:= getArea()  
Local aCombPro	:= {"A"	 , "B"	, "C"	, "D"	, "E"	, "F"	, "G"	, "H"	, "R"	, "S"	, "T"}
Local aCombQPr	:= {"14 ", "04 ", "06 "	, "10 " , "12 "	,"   "	,"   "	,"   "	,"14 "	, "07 "	, "   "}

Local aCombTic	:= {"AL", "DI", "DS", "DA", "GA", "GC", "GN", "OL" , "AR"}
Local aCombQTi	:= {"06", "01", "07", "14", "10", "04", "04", "018", "016"}

Local nPos		:= 0
Local cNumAbast 
Local _cLayout	:= cCodLay
Local cProFrota	:= "000001"
Local cInterno	:= "000006"
Local cExterno	:= "000007"
Local cCTA		:= "000008"
Local cTicket   := "000009"
Local cTanque	:= ""
Local cTopCom	:= ""
Local nQtdeCom	:= 0 

if cEmpAnt = "01"

	if _cLayout = cProFrota  //profrotas
		cNumAbast	:= alltrim(AINCLTR6[01][1])
		nKM			:= AINCLTR6[07][1]
		_cPlaca		:= AINCLTR6[05][1]
		nQtdeCom	:= AINCLTR6[04][1]

	elseif _clayout = cInterno
						// Placa + data + HH = 15 posições
			cNumAbast := substr(AINCLTR6[01][1],1,7)+substr(dtos(AINCLTR6[08][1]),3,6)+substr(AINCLTR6[02][1],1,2)
			nKM			:= AINCLTR6[03][1]
			_cPlaca		:= AINCLTR6[01][1]
			cTanque		:= strZero(val(AINCLTR6[06][1]),2)
			cTopCom		:= strZero(val(AINCLTR6[07][1]),2)
			cPosto		:= PadR(alltrim(AINCLTR6[10][1]),TamSx3("A2_COD")[1])
			cLoja		:= PadR(strZero(val(AINCLTR6[11][1]),4),TamSx3("A2_LOJA")[1])
			nQtdeCom 	:= AINCLTR6[04][1]

	elseif _clayout = cExterno
						// Placa + data + HH = 15 posições
			cNumAbast 	:= alltrim(AINCLTR6[11][1])
			nKM			:= AINCLTR6[04][1]
			_cPlaca		:= AINCLTR6[01][1]
			nQtdeCom 	:= AINCLTR6[04][1]			

	elseif _clayout = cCTA
						// Placa + data + HH = 15 posições
			cNumAbast := substr(AINCLTR6[03][1],1,7)+substr(dtos(AINCLTR6[01][1]),3,6)+substr(AINCLTR6[02][1],1,2)
			nKM			:= AINCLTR6[06][1]
			_cPlaca		:= AINCLTR6[03][1]
			cTanque		:= strZero(val(AINCLTR6[13][1]),2)
			cTopCom		:= "07" 		//strZero(val(AINCLTR6[07][1]),2)
			cPosto		:= "EX0000067" 	//PadR(alltrim(AINCLTR6[10][1]),TamSx3("A2_COD")[1])
			cLoja		:= "0001"  		//PadR(strZero(val(AINCLTR6[11][1]),4),TamSx3("A2_LOJA")[1])
			cCnpjCta	:= "00000000000004"
			cCpfCta		:= "99999999999"
			cBomba		:= "B9"
			nQtdeCom 	:= AINCLTR6[05][1]
			
			AINCLTR6[04][1] := cNumAbast
			AINCLTR6[06][1] := IF(AINCLTR6[06][1] = 0	, AINCLTR6[07][1], AINCLTR6[06][1])
			AINCLTR6[07][1] := IF(AINCLTR6[07][1] <> 0	, 0 			 , 0 )
			AINCLTR6[09][1] := cCpfCta
			AINCLTR6[10][1] := cTopCom
			AINCLTR6[11][1] := cCnpjCta
			AINCLTR6[12][1] := cBomba 
			AINCLTR6[14][1] := cPosto
			AINCLTR6[15][1] := cLoja 

	elseif _clayout = cTicket
			// Placa + data + HH = 15 posições
			cNumAbast 		:= substr(AINCLTR6[06][1],1,7)+substr(dtos(AINCLTR6[02][1]),3,6)+substr(AINCLTR6[14][1],4,2)
			nKM				:= AINCLTR6[07][1]
			_cPlaca			:= AINCLTR6[06][1]
			nQtdeCom 		:= AINCLTR6[04][1]
			AINCLTR6[01][1] := cNumAbast
	endif
		
	if nQtdeCom > 0 
		TR6->(DbSetOrder(1))
		if TR6->(DbSeek(cNumAbast))
			if alltrim(TR6->TR6_PLACA) = alltrim(_cPlaca) 
				if TR6->TR6_KMABAS == nKM
					lRetorno := .F.
				endif
			else
				cNumAbast := alltrim(cNumAbast)+"1"

			endif
		endif

		if lRetorno .and. _clayout = cProFrota
			AINCLTR6[14][1] := GETMV("MV_XCNPJPO")       

			nPos := Ascan(aCombPro,AINCLTR6[4][1])
			if nPos == 0
				AINCLTR6[4][1] := "   "
			else
				AINCLTR6[4][1] := aCombQPr[nPos]
			endif        
		endif	      

		if lRetorno .and. _clayout = cTicket
			AINCLTR6[8][1] := "03506307000157"  //CNPJ      
			if alltrim(AINCLTR6[5][1]) = "AR"
				lRetorno := .F.
			else
				nPos := Ascan(aCombTic,AINCLTR6[5][1])
				if nPos == 0
					AINCLTR6[5][1] := "   "
				else
					AINCLTR6[5][1] := aCombQTi[nPos]
				endif        
			endif
		endif	      

		if lRetorno .and. _clayout = cInterno
			TQI->(dbSetOrder(1))		//posto + Loja + Tanque + Tipo Combustivel
			if TQI->(DbSeek(xFilial("TQI")+;
				cPosto+;
				cLoja+;
				cTanque+cTopCom  ) )
				cComb := TQI->TQI_PRODUT
			else
				cComb := ""
			endif

			if !empty(cComb)
				SB2->(DbSetOrder(1))
				if SB2->(!Dbseek( xFilial('SB2') + cComb + cTanque ))
					CriaSB2( cComb, cTanque )
				else
					AINCLTR6[13][1] := round(SB2->B2_CM1,3)
					AINCLTR6[14][1] := round(AINCLTR6[04][1] * SB2->B2_CM1,2)
					AINCLTR6[06][1]	:= cTanque
					AINCLTR6[07][1]	:= cTopCom
					AINCLTR6[10][1]	:= cPosto
					AINCLTR6[11][1] := cLoja
					AINCLTR6[12][1] := cNumAbast
					AINCLTR6[15][1] := Posicione("TQF",1,XFILIAL("TQF")+cPosto+cLoja,"TQF_CNPJ")
				endif
			endif
		endif
	else
		lRetorno := .F.
	endif

elseif cEmpAnt = "02"
		aCombTic	:= {"AL", "DI", "DS", "DA", "GA", "GC", "GN", "OL" , "AR"}
		aCombQTi	:= {"06", "01", "07", "14", "10", "04", "04", "018", "016"}

		nPos		:= 0
		cNumAbast	:= "" 
		cCTA		:= "000006"
		cTicket   	:= "000009"
		cTanque		:= ""
		cTopCom		:= ""

	if _clayout = cCTA .and. alltrim(AINCLTR6[12][1]) $ "PA2-PA4-PA1-PA3"
						// Placa + data + HH = 15 posições
		cNumAbast := substr(AINCLTR6[04][1],1,7)+substr(dtos(AINCLTR6[01][1]),3,6)+substr(AINCLTR6[02][1],4,2)
		nKM			:= AINCLTR6[06][1]
		cCodbem		:= AINCLTR6[03][1]   //prefixo
		_cPlaca		:= Posicione("ST9",1,XFILIAL("ST9")+cCodbem,"T9_PLACA")
		cTopCom		:= "001" 		//strZero(val(AINCLTR6[07][1]),2)
		cPosto		:= "54305037 " 	//PadR(alltrim(AINCLTR6[10][1]),TamSx3("A2_COD")[1])
		cLoja		:= "0001"  		//PadR(strZero(val(AINCLTR6[11][1]),4),TamSx3("A2_LOJA")[1])
		cCnpjCta	:= "54305037000157"
		cCpfCta		:= "77764994120"

		if alltrim(AINCLTR6[12][1]) = "PA2"
			cBomba		:= "001"
			cTanque		:= "24" //strZero(val(AINCLTR6[13][1]),2)
		elseif alltrim(AINCLTR6[12][1]) = "PA1"
			cBomba		:= "001"
			cTanque		:= "22" //strZero(val(AINCLTR6[13][1]),2)
		elseif alltrim(AINCLTR6[12][1]) = "PA3"		
			cBomba		:= "001"
			cTanque		:= "26" //strZero(val(AINCLTR6[13][1]),2)
		else
			if right(AINCLTR6[10][1],1) = "1"
				cBomba		:= "001"
			elseif right(AINCLTR6[10][1],1) = "2"
				cBomba		:= "002"
			else
				cBomba		:= "   "
			endif
			cTanque		:= "20" //strZero(val(AINCLTR6[13][1]),2)

		endif

		AINCLTR6[04][1] := cNumAbast
		
		if AINCLTR6[06][1] = 0 .and. AINCLTR6[07][1] <> 0
			AINCLTR6[06][1] := AINCLTR6[07][1]
			AINCLTR6[07][1] := 0 
		endif
		
		AINCLTR6[03][1] := _cPlaca
		AINCLTR6[09][1] := cCpfCta
		AINCLTR6[10][1] := cTopCom
		AINCLTR6[11][1] := cCnpjCta
		AINCLTR6[12][1] := cBomba 
		AINCLTR6[13][1] := cTanque 
		AINCLTR6[14][1] := cPosto
		AINCLTR6[15][1] := cLoja 
		lRetorno := .T.
	elseif _clayout = cTicket
			// Placa + data + HH = 15 posições
			cNumAbast := substr(AINCLTR6[06][1],1,7)+substr(dtos(AINCLTR6[02][1]),3,6)+substr(AINCLTR6[14][1],4,2)
			nKM			:= AINCLTR6[07][1]
			_cPlaca		:= AINCLTR6[06][1]
	else
		lRetorno := .F.
	endif
		
	if lRetorno
		TR6->(DbSetOrder(1))
		if TR6->(DbSeek(cNumAbast))
			if alltrim(TR6->TR6_PLACA) = alltrim(_cPlaca) 
				if TR6->TR6_KMABAS == nKM
					lRetorno := .F.
				endif
			else
				cNumAbast := alltrim(cNumAbast)+"1"

			endif
		endif
	endif
	
	if lRetorno .and. _clayout = cTicket
		AINCLTR6[8][1] := "03506307000157"  //CNPJ      

		nPos := Ascan(aCombTic,AINCLTR6[5][1])
		if nPos == 0
			AINCLTR6[5][1] := "   "
		else
			AINCLTR6[5][1] := aCombQTi[nPos]
		endif        
	endif	      

	if _clayout = cInterno .and. lRetorno
		TQI->(dbSetOrder(1))		//posto + Loja + Tanque + Tipo Combustivel
		If TQI->(DbSeek(xFilial("TQI")+;
			cPosto+;
			cLoja+;
			cTanque+cTopCom  ) )
			cComb := TQI->TQI_PRODUT
		else
			cComb := ""
		EndIf

		if !empty(cComb)
			SB2->(DbSetOrder(1))
			If SB2->(!Dbseek( xFilial('SB2') + cComb + cTanque ))
				CriaSB2( cComb, cTanque )
			else
				//AINCLTR6[13][1] := round(SB2->B2_CM1,3)
				AINCLTR6[08][1] := round(AINCLTR6[05][1] * SB2->B2_CM1,2)

			endif
		endif
	endif

endif

TR6->(DbSetOrder(1))

restArea(_aAreas)	       
Return lRetorno
