#INCLUDE "RWMAKE.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TOTVS.CH"
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ QFOL001  ºAutor ³Sinval Gedolin       º Data ³     02/2021 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Importa Folha de Pagamento Domínio                         º±±
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

User Function QFINR003()
	Local cPerg		:= 'QFINR003'
	Local cSep		:= ';'
	Local oReport
	
	cSep	:= ";"

	//->Perguntas
	AjustaSX1(cPerg)

	pergunte(cPerg,.T.)

    if MsgYesNo("Confirma Importação do Arquivo => "+Alltrim(MV_PAR01)+ " ?")
		oReport:= MCHKIMP(Alltrim(MV_PAR01),cSep) 
		
		oReport:PrintDialog()		

		msginfo("Importação Finalizada..","Importação")
    endif

Return()           

Static Function MCHKIMP(cArquivo,cSep)

Local cTitle   	:= "Relatório de Processamento Santander"
Local oReport 
Local oSection1
Local cAliasZAJ := "SE2"

Pergunte("QFINR003",.F.)

oReport:= TReport():New("QFINR003", cTitle, "QFINR003", {|oReport| ReportPrint(oReport, {}, cAliasZAJ, cArquivo)},"Relação de Importações")
oReport:SetTotalInLine(.F.)
oReport:SetLandscape() 
//oReport:ShowHeader()

oSection1:=TRSection():New(oReport,"Relação de Importações",{},{})
oSection1:SetTotalInLine(.F.)

TRCell():New(oSection1,"BANCO" 		, "   ", "Banco" 			/*Titulo*/,/*Picture*/,07 /*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/,,,,,,.F.)
TRCell():New(oSection1,"AGENCIA"	, "   ", "Agência"   		/*Titulo*/,/*Picture*/,10 /*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/,,,,,,.F.)
TRCell():New(oSection1,"LOTE"   	, "   ", "Num.Lote"  		/*Titulo*/,/*Picture*/,10 /*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"NOMEFUN"	, "   ", "Nome Funcionário" /*Titulo*/,/*Picture*/,40 /*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"FORMPGTO"   , "   ", "Forma Pagto"  	/*Titulo*/,/*Picture*/,10 /*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"VALOR"  	, "   ", "Valor Transação"  /*Titulo*/,"@E 999,999,999.99" /*Picture*/,16 /*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"DATALAN"	, "   ", "Data Lança"		/*Titulo*/,/*Picture*/,10 /*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"MSGERRO" 	, "   ", "Mesangem"			/*Titulo*/,/*Picture*/,40 /*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)

oSection1:Cell("BANCO"):SetHeaderAlign("LEFT")
oSection1:Cell("AGENCIA"):SetHeaderAlign("LEFT")
oSection1:Cell("LOTE"):SetHeaderAlign("LEFT")
oSection1:Cell("NOMEFUN"):SetHeaderAlign("LEFT")
oSection1:Cell("FORMPGTO"):SetHeaderAlign("CENTER")
oSection1:Cell("VALOR"):SetHeaderAlign("RIGHT")
oSection1:Cell("DATALAN"):SetHeaderAlign("CENTER")
oSection1:Cell("MSGERRO"):SetHeaderAlign("LEFT")

Return(oReport)

Static Function ReportPrint(oReport, aOrdem, cAliasZAJ, cArquivo)
	Local oSection1 := oReport:Section(1)
	Local nCont   := 1
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

	oSection1:Init()

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
		
		oReport:IncMeter()
		If oReport:Cancel()
			Exit
		EndIf
		
		IncProc("Lendo arquivo texto, Linha ==> "+Alltrim(str(nCont)))
		cLinha := FT_FReadLn()
		nRecno := FT_FRecno() // Retorna a linha corrente

		if !empty(Alltrim(cLinha))

			if substr(cLinha,3,4) = "0033" .and. !"QUEBEC" $ cLinha
				cBanco		:= substr(cLinha,003,04)
				cAgencia	:= substr(cLinha,014,04)
				cNumLote	:= substr(cLinha,026,10)
				cNomFunc	:= substr(cLinha,066,40)
				cFormPgto	:= substr(cLinha,109,02)

				FT_FSKIP()  
				cLinha := Alltrim(FT_FReadLn())				
				nValor := strtran(substr(cLinha,01,12),".","")
				nValor := val(strtran(nValor,",","."))

				//nValor		:= val(substr(cLinha,01,12))
				dDatLan		:= substr(cLinha,37,10)
				cMsgErro	:= alltrim(substr(cLinha,48,50))

				oSection1:Cell("BANCO"):SetValue(cBanco)
				oSection1:Cell("BANCO"):SetAlign("LEFT")
				
				oSection1:Cell("AGENCIA"):SetValue(cAgencia)
				oSection1:Cell("AGENCIA"):SetAlign("LEFT")
				
				oSection1:Cell("LOTE"):SetValue(cNumLote)
				oSection1:Cell("LOTE"):SetAlign("LEFT")

				oSection1:Cell("NOMEFUN"):SetValue(cNomFunc)
				oSection1:Cell("NOMEFUN"):SetAlign("LEFT")

				oSection1:Cell("FORMPGTO"):SetValue(cFormPgto)
				oSection1:Cell("FORMPGTO"):SetAlign("CENTER")

				oSection1:Cell("VALOR"):SetValue(nValor)
				oSection1:Cell("VALOR"):SetAlign("RIGHT")

				oSection1:Cell("DATALAN"):SetValue(dDatLan)
				oSection1:Cell("DATALAN"):SetAlign("LEFT")

				oSection1:Cell("MSGERRO"):SetValue(cMsgErro)
				oSection1:Cell("MSGERRO"):SetAlign("LEFT")

				oSection1:PrintLine()

			endif
		Endif
		FT_FSKIP()  
		nCont++
	EndDo

	FT_FUSE()
	fClose(nHdl )                
	oSection1:Finish()
	
Return                                        

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
