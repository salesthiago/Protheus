#INCLUDE "RWMAKE.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TOTVS.CH"
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ QFIN001  ºAutor ³Sinval Gedolin       º Data ³     02/2021 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Importa Arquivo retorno Santander                          º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Funcao Auxilia                                             º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDATA      ³ ANALISTA ³                                                 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±º          ³          ³                                                 º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

User Function QFIN001()
	Local cPerg		:= 'QFIN01'
	Local cSep		:= ';'

	//->Perguntas
	AjustaSX1(cPerg)

	pergunte(cPerg,.T.)
	
	cSep	:= ";"

    if MsgYesNo("Confirma Importação do Arquivo => "+Alltrim(MV_PAR01)+ " ?")
        Processa( {|| MCHKIMP(Alltrim(MV_PAR01),cSep) }, "Aguarde...",;
                         "Importando Localizações ",.F.)

	    msginfo("Importação Finalizada..","Importação")
    endif

Return()           

/*
Importa Arquivo
*/
Static Function MCHKIMP(cArquivo,cSep)
	Local aItens  := {}
	Local nCont   := 1
	Local cCodEmp 	:= ""
	Local cNomEmp 	:= ""
	Local cCnpj		:= ""
	Local cCodfil	:= ""
	Local cNomFil	:= ""
	Local cCnpjFil	:= ""
	Local cCodCtt	:= ""
	Local cNomCtt	:= ""

	Private nHdl  := 0
	Private cEOL  := "CHR(8)"

	If Empty(Alltrim(cArquivo))
		Alert("Nao existem arquivos para importar. Processo ABORTADO")
		Return.F.	
	EndIf

	//+---------------------------------------------------------------------+
	//| Abertura do arquivo texto                                           |
	//+---------------------------------------------------------------------+
	cArqTxt := cArquivo

	nHdl := fOpen(cArqTxt,0 )
	IF nHdl == -1
		IF FERROR()== 516
			ALERT("Feche o programa que gerou o arquivo.")
		EndIF
	EndIf

	//+---------------------------------------------------------------------+
	//| Verifica se foi possÌvel abrir o arquivo                            |
	//+---------------------------------------------------------------------+
	If nHdl == -1
		MsgAlert("O arquivo de nome "+cArquivo+" nao pode ser aberto! Verifique os parametros.","Atencao!" )
		Return
	Endif

	FSEEK(nHdl,0,0 )
	nTamArq:=FSEEK(nHdl,0,2 )
	FSEEK(nHdl,0,0 )
	fClose(nHdl)

	FT_FUse(cArquivo )  //abre o arquivo
	FT_FGoTop()         //posiciona na primeira linha do arquivo
	//nTamLinha := AT(cEOL,cBuffer )
	nTamLinha := Len(FT_FREADLN() ) //Ve o tamanho da linha
	FT_FGOTOP()

	//+---------------------------------------------------------------------+
	//| Verifica quantas linhas tem o arquivo                               |
	//+---------------------------------------------------------------------+
	aDados := {}
	nLinhas := FT_FLastRec() 

	ProcRegua(nLinhas)

	While !FT_FEOF()
		IF nCont > nLinhas
			exit
		Endif

		if nCont == 0
			FT_FSKIP()  
			nCont++
			loop
		endif

		IncProc("Lendo arquivo texto, Linha ==> "+Alltrim(str(nCont)))
		cLinha := Alltrim(FT_FReadLn())
		nRecno := FT_FRecno() // Retorna a linha corrente

		if !empty(Alltrim(cLinha))

			aItens:={}
			aItens:=strToKarr2(cLinha,cSep,.T.)

			if alltrim(aItens[1]) $ "EMP-FIL-CCU-EPG-CMP-EVE-EPGTOT" //CMPTOT
				if aitens[1] $ "EMP"
					cCodEmp	:= Padr(alltrim(aItens[2]),2)
					cNomEmp := alltrim(aItens[3])
					cCnpj	:= alltrim(aItens[4])
				elseif aitens[1] $ "FIL"
						cCodfil		:= Padr(alltrim(aItens[2]),2)
						cNomFil		:= aItens[3]
						cCnpjFil	:= aItens[4]
				elseif aItens[1] $ "CCU"
						cCodCtt		:= aItens[2]
						cNomCtt		:= aItens[3]
				elseif aitens[1] $ "EPG"
						Aadd(aDados, {	aItens[1], aItens[2], aItens[3]		, aitens[4],aItens[5], aItens[6], aItens[7], aitens[8],;
										aItens[9], aItens[10], aItens[11]	, aItens[12], aItens[13], aItens[14], aItens[15]	})
				elseif aitens[1] $ "CMP"
						Aadd(aDados, {aItens[1], aItens[2]})
				elseif aItens[1] $ "EVE"
						Aadd(aDados, {aItens[1], aItens[2], aItens[3], aitens[4],aItens[5], aItens[6]})
				elseif aItens[1] $ "EPGTOT" //"CMPTOT"
						
						MCHKEXA(aDados,	cCodEmp, cNomEmp,cCnpj, cCodfil, cNomFil, cCnpjFil, cCodCtt,cNomCtt)

						aDados := {}
				endif
			endif
		Endif
		FT_FSKIP()  
		nCont++
	EndDo

	FT_FUSE()
	fClose(nHdl )                
Return                                        

Static Function MCHKEXA(aItens,	cCodEmp, cNomEmp,cCnpj, cCodfil, cNomFil, cCnpjFil, cCodCtt,cNomCtt)

	Local cCodFun 	:= ""
	Local cNomFun	:= ""
	Local cCpfFun 	:= ""
	Local cCodCar	:= ""
	Local cNomCar 	:= ""
	Local cCodFunc	:= ""
	Local cNomFunc	:= ""
	Local dDtaAdm	:= ctod("  /  /  ")
	Local dDtadem	:= CTOD("  /  /  ")
	Local cSituac	:= ""
	Local cPeriod	:= ""
	Local cCodRub 	:= ""
	Local cDesRub 	:= ""
	Local cTipCal	:= ""
	Local nRefCal	:= 0
	Local nVlrCal	:= 0
	Local cCodDep	:= ""
	Local cNomDep	:= ""
	Local cCodSer	:= ""
	Local cNomSer	:= ""
	Local nReg 		:= 1

   /*+--------------------------------------+
	|           Layout do Arquivo          |
	+---+----------------------------------+
	|POS|CAMPO                             |
	+---+----------------------------------+
	 EMP;7	;QUEBEC CONSTRUCOES E TECNOLOGIA AMBIENTA;26921551000777
	 FIL;1	;QUEBEC CONSTRUCOES E TECNOLOGIA AMBIENTA;26921551000777
	 CCU;2	;VARRIÇAO NOTURNA EQ.2
	 EPG	;105;ANTONIO DOS SANTOS CASTRO;75459566304;118;AUX. DE LIMPEZA/ VARRIÇÃO;;;30/05/2020;;Trabalhando
	 CMP	;03/2022
	 EVE	;17;INSALUBRIDADE 40%;Automatico;40;242,4
	+---+----------------------------------+*/  
	for nReg := 1 to len(aItens)
		if alltrim(aItens[nReg][1]) $ "EMP-FIL-CCU-EPG-CMP-EVE"
/*			if alltrim(aItens[nReg][1]) == "EMP"
				cCodEmp	:= Padr(alltrim(aItens[nReg][2]),2)
				cNomEmp := alltrim(aItens[nReg][3])
				cCnpj	:= alltrim(aItens[nReg][4])
			elseif alltrim(aItens[nReg][1]) == "FIL"
					cCodfil		:= Padr(alltrim(aItens[nReg][2]),2)
					cNomFil		:= aItens[nReg][3]
					cCnpjFil	:= aItens[nReg][4]
			elseif alltrim(aItens[nReg][1]) == "CCU"
					cCodCtt		:= aItens[nReg][2]
					cNomCtt		:= aItens[nReg][3]
*/
			if alltrim(aItens[nReg][1]) == "EPG"
					cCodFun 	:= Padr(alltrim(aItens[nReg][2]),7)
					cNomFun		:= aItens[nReg][3]
					cCpfFun 	:= aItens[nReg][4]
					cCodCar		:= aItens[nReg][5]
					cNomCar 	:= aItens[nReg][6]
					cCodFunc	:= aItens[nReg][7]
					cNomFunc	:= aItens[nReg][8]
					dDtaAdm		:= ctoD(aItens[nReg][9])
					dDtadem		:= cToD(aItens[nReg][10])
					cSituac		:= aItens[nReg][11]
					cCodDep 	:= Padr(aItens[nReg][12],4)
					cNomDep 	:= aItens[nReg][13]
					cCodSer 	:= Padr(aItens[nReg][14],4)
					cNomSer  	:= aItens[nReg][15]

			elseif alltrim(aItens[nReg][1]) == "CMP"
					cPeriod		:= aItens[nReg][2]
			elseif alltrim(aItens[nReg][1]) == "EVE"
					cCodRub 	:= Padr(alltrim(aItens[nReg][2]),4)
					cDesRub 	:= aItens[nReg][3]
					cTipCal		:= aItens[nReg][4]
					nRefCal		:= val(strtran(aItens[nReg][5],",","."))
					nVlrCal		:= val(strtran(aItens[nReg][6],",","."))
	
					//Z4_FILIAL + Z4_CODEMP + Z4_CODFIL + Z4_CODFUN + Z4_CODRUB + Z4_COMPETE

					SZ4->(DbSetorder(1))
					if SZ4->(DbSeek(xFilial("SZ4")+cCodEmp + cCodfil + cCodFun + cCodRub + cPeriod))
						SZ4->(Reclock("SZ4",.F.))
					else
						SZ4->(Reclock("SZ4",.T.))
						SZ4->Z4_FILIAL 	:= xFilial("SZ4")
						SZ4->Z4_CODEMP 	:= cCodEmp
						//SZ4->Z4_NOMEMP	:= cNomEmp
						SZ4->Z4_CNPJEMP := cCnpj
						SZ4->Z4_CODFIL	:= cCodFil
						//SZ4->Z4_NOMFIL	:= cNomFil
						SZ4->Z4_CNPJFIL := cCnpjFil
						SZ4->Z4_CODFUN  := cCodFun
						SZ4->Z4_NOMFUN  := cNomFun

						SZ4->Z4_CODRUB  := cCodRub
						//SZ4->Z4_DESRUB  := cDesRub
						SZ4->Z4_COMPETE := cPeriod
						SZ4->Z4_CODCC	:= cCodCtt
						SZ4->Z4_NOMCC	:= cNomCtt
						SZ4->Z4_CPF		:= cCpfFun
						SZ4->Z4_CODCAR	:= cCodCar
						SZ4->Z4_NOMCAR	:= cNomCar
						SZ4->Z4_DTAADM	:= dDtaAdm
						SZ4->Z4_DTADEM  := dDtadem
						SZ4->Z4_COMPETE := cPeriod

						SZ4->Z4_CODDEP	:= cCodDep
						SZ4->Z4_NOMDEP	:= cNomDep
						SZ4->Z4_CODSER 	:= cCodSer
						SZ4->Z4_NOMSER	:= cNomSer
					endif

					SZ4->Z4_SITUACA	:= cSituac
					SZ4->Z4_TIPCALC	:= cTipCal
					SZ4->Z4_VLRREF	:= nRefCal
					SZ4->Z4_VALOR	:= nVlrCal
					SZ4->(MsUnlock())

					//Alimenta cadastro de rúbricas
					SZ5->(DbSetorder(1))
					if !SZ5->(DbSeek(xFilial("SZ5")+cCodRub))
						SZ5->(Reclock("SZ5",.T.))
						SZ5->Z5_FILIAL 	:= xFilial("SZ5")
						SZ5->Z5_CODRUB  := cCodRub
						SZ5->Z5_DESRUB  := cDesRub
						SZ5->(MsUnlock())
					endif

					//Alimenta cadastro de Funções
					SZ8->(DbSetorder(1))
					if !SZ8->(DbSeek(xFilial("SZ8")+cCodCar))
						SZ8->(Reclock("SZ8",.T.))
						SZ8->Z8_FILIAL 	:= xFilial("SZ8")
						SZ8->Z8_CODFUNC := cCodCar
						SZ8->Z8_NOMFUNC	:= cNomCar
						SZ8->(MsUnlock())
					endif

					//Alimenta cadastro de Funções
					SZ9->(DbSetorder(2))
					if !SZ9->(DbSeek(xFilial("SZ9")+cCodEmp+cCodDep))
						SZ9->(Reclock("SZ9",.T.))
						SZ9->Z9_FILIAL 	:= xFilial("SZ9")
						SZ9->Z9_CODEMP  := cCodEmp
						SZ9->Z9_CODDEP	:= cCodDep
						SZ9->Z9_NOMDEP  := cNomDep
						SZ9->(MsUnlock())
					endif

					//Alimenta cadastro de Funções
					SZA->(DbSetorder(2))
					if !SZA->(DbSeek(xFilial("SZA")+cCodEmp+cCodDep+cCodSer))
						SZA->(Reclock("SZA",.T.))
						SZA->ZA_FILIAL 	:= xFilial("SZA")
						SZA->ZA_CODSER	:= cCodSer
						SZA->ZA_NOMSER	:= cNomSer
						SZA->ZA_CODEMP	:= cCodEmp
						SZA->ZA_CODDEP  := cCodDep
						SZA->ZA_NOMDEP  := cNomDep
						SZA->(MsUnlock())
					endif
			endif
		endif
	next

Return Nil

Static Function AjustaSX1(cPerg)
	Local aRegs     := {}  
    Local _sAlias	:= Alias()
    Local i, j

    dbSelectArea("SX1")
    dbSetOrder(1)
    cPerg	:= PADR(cPerg,10)

    //          Grupo/Ordem/Pergunta          /1Perspa/2Pereng/3Variavel/4Tipo/5Tamanho/6Decimal/7Presel/8GSC/9Valid/10Var01/11Def01/12Defspa1/13Defeng1/14Cnt01/15Var02/16Def02/17Defspa2/18Defeng2/19Cnt02/20Var03/21Def03/22Defspa3/23Defeng3/24Cnt03/25Var04/26Def04/27Defspa4/28Defeng4/29Cnt04/30Var05/31Def05/32Defspa5/33Defeng5/34Cnt05/35F3
    aAdd(aRegs,{cPerg,'01','Local do Arquivo   ?','Local do Arquivo   ?','Local do Arquivo   ?','mv_ch1','C',99,0,0,'G','','mv_par01','','','','','','','','','','','','','','','','','','','','','','DIR'})

    For i:=1 to Len(aRegs)
	    If !dbSeek(cPerg+aRegs[i,2])
		    RecLock("SX1",.T.)
    		For j:=1 to FCount()
	    		If j <= Len(aRegs[i])
		    		FieldPut(j,aRegs[i,j])
			    Endif
    		Next
	    	MsUnlock()
	    Endif
    Next

    dbSelectArea(_sAlias)
Return
