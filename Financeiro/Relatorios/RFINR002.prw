#include 'protheus.ch'
#include 'parmtype.ch'
#include 'TopConn.ch'

user function RFINR002()

	Local aParamBox := {}
	Local aRet := {}

	//-----------------------------------------------------------------------
	//³Variaveis de Tipos de fontes que podem ser utilizadas no relatório   ³
	//-----------------------------------------------------------------------
	Private oFont6		:= TFONT():New("Arial Narrow",7,6,.T.,.F.,5,.T.,5,.T.,.F.) ///Fonte 6 Normal
	Private oFont6N 	:= TFONT():New("Arial Narrow",7,6,,.T.,,,,.T.,.F.) ///Fonte 6 Negrito
	Private oFont8		:= TFONT():New("Arial Narrow",9,8,.T.,.F.,5,.T.,5,.T.,.F.) ///Fonte 8 Normal
	Private oFont8N 	:= TFONT():New("Arial Narrow",8,8,,.T.,,,,.T.,.F.) ///Fonte 8 Negrito
	Private oFont10 	:= TFONT():New("Arial Narrow",9,10,.T.,.F.,5,.T.,5,.T.,.F.) ///Fonte 10 Normal
	Private oFont10S	:= TFONT():New("Arial Narrow",9,10,.T.,.F.,5,.T.,5,.T.,.T.) ///Fonte 10 Sublinhando
	Private oFont10N 	:= TFONT():New("Arial Narrow",9,9,,.T.,,,,.T.,.F.) ///Fonte 10 Negrito
	Private oFont12		:= TFONT():New("Arial Narrow",12,12,,.F.,,,,.T.,.F.) ///Fonte 12 Normal
	Private oFont12NS	:= TFONT():New("Arial Narrow",12,12,,.T.,,,,.T.,.T.) ///Fonte 12 Negrito e Sublinhado
	Private oFont12N	:= TFONT():New("Arial Narrow",12,12,,.T.,,,,.T.,.F.) ///Fonte 12 Negrito
	Private oFont14		:= TFONT():New("Arial Narrow",14,14,,.F.,,,,.T.,.F.) ///Fonte 14 Normal
	Private oFont14NS	:= TFONT():New("Arial Narrow",14,14,,.T.,,,,.T.,.T.) ///Fonte 14 Negrito e Sublinhado
	Private oFont14N	:= TFONT():New("Arial Narrow",14,14,,.T.,,,,.T.,.F.) ///Fonte 14 Negrito
	Private oFont16 	:= TFONT():New("Arial Narrow",16,16,,.F.,,,,.T.,.F.) ///Fonte 16 Normal
	Private oFont16N	:= TFONT():New("Arial Narrow",16,16,,.T.,,,,.T.,.F.) ///Fonte 16 Negrito
	Private oFont16NS	:= TFONT():New("Arial Narrow",16,16,,.T.,,,,.T.,.T.) ///Fonte 16 Negrito e Sublinhado
	Private oFont20N	:= TFONT():New("Arial Narrow",20,20,,.T.,,,,.T.,.F.) ///Fonte 20 Negrito
	Private oFont22N	:= TFONT():New("Arial Narrow",22,22,,.T.,,,,.T.,.F.) ///Fonte 22 Negrito

	//-----------------------------------------------------------------------
	//³Variveis para impressão                                              ³
	//-----------------------------------------------------------------------
	Private cStartPath
	Private nLin 		:= 0
	Private nMargemL    := 50
	Private nMargemR    := 2300
	Private nMargemT	:= 50
	Private nMargemB	:= 3350
	Private nCenterPg	:= 1220
	Private oPrint		:= TMSPRINTER():New("Bordero")
	Private nPag		:= 1
	//Private cPerg 		:= "RTECR002"
	Private oBrush1		:= TBrush():New( , CLR_HGRAY )

	//-----------------------------------------------------------------------
	//³Define Tamanho do Papel                                              ³
	//-----------------------------------------------------------------------
	#define DMPAPER_A4 9 //Papel A4
	oPrint:setPaperSize( DMPAPER_A4 )
	//TMSPrinter(): SetPaperSize ()

	//-----------------------------------------------------------------------
	//³Cria as perguntas na SX1                                             ³
	//-----------------------------------------------------------------------

	aAdd(aParamBox,{1,"Filial De?",Space(TamSX3("E2_FILIAL")[1]),"","","","",50,.F.})
	aAdd(aParamBox,{1,"Filial Até?",Space(TamSX3("E2_FILIAL")[1]),"","","","",50,.F.})
	aAdd(aParamBox,{1,"Borderô De?",Space(TamSX3("E2_NUMBOR")[1]),"","","","",50,.F.})
	aAdd(aParamBox,{1,"Borderô Até?",Space(TamSX3("E2_NUMBOR")[1]),"","","","",50,.F.})
	aAdd(aParamBox,{1,"Dt. Emis. De?",Ctod(Space(8)),"","","","",50,.F.})
	aAdd(aParamBox,{1,"Dt. Emis. Até?",Ctod(Space(8)),"","","","",50,.F.})
	aAdd(aParamBox,{1,"Dt. Comp. De?",Ctod(Space(8)),"","","","",50,.F.})
	aAdd(aParamBox,{1,"Dt. Comp. Até?",Ctod(Space(8)),"","","","",50,.F.})
	aAdd(aParamBox,{2,"Ordem",0,{"Fornecedor","Titulo","Valor"},80,'.T.',.F.})
	
	//-----------------------------------------------------------------------
	//³Orientacao do papel (Retrato ou Paisagem)                            ³
	//-----------------------------------------------------------------------
	oPrint:SetPortrait()///Define a orientacao da impressao como retrato
	//oPrint:SetLandscape() ///Define a orientacao da impressao como paisagem

	//---------------------------------------------------------------------
	//busca dados do relatório 
	//---------------------------------------------------------------------

	if ParamBox(aParamBox,"Parâmetros",@aRet,,,,,,,.F.,.F.)

		cQry := ChangeQuery(GeraQry(aRet))
		
		If Select("QSE2")>0
			QSE2->(DbCloseArea())
		Endif
		
		TcQuery cQry New Alias "QSE2" // Cria uma nova area com o resultado do query
			
		While QSE2->(!Eof())
			
			nPag := 1
			nTotalGeral := 0
			nCount := QSE2->E2_QUANT
			cNumBor := QSE2->E2_NUMBOR
			CabPagina()
			Cabecalho()
			
			cFilBor := QSE2->E2_FILIAL
			
			nLin+=50
			oPrint:Say(nLin, nMargemL+10, QSE2->E2_FILIAL+" - "+FwFilialName(,QSE2->E2_FILIAL), oFont12N)
			nLin += 80
			
			While QSE2->(!Eof()) .And. QSE2->E2_NUMBOR == cNumBor 
				
				If cFilBor <> QSE2->E2_FILIAL
					nLin += 50
					oPrint:Box( nLin,nMargemR-850,nLin+70,nMargemR )
					oPrint:Line(nLin+70, nMargemL, nLin+70, nMargemR-850)
					nLin += 10
					oPrint:Say(nLin, nMargemR-800, "Total Unidade: ", oFont12)
					oPrint:Say(nLin, nMargemR-50, "R$ " + Transform(nTotalUnid,'@E 99,999,999.99'), oFont12N,,,,1)
					if nLin+250 > nMargemB
						Rod()
						CabPagina()
						Cabecalho()
						nLin += 25
					Else
						nLin+= 50
					EndIf
					
					if nLin+250 > nMargemB
						Rod()
						CabPagina()
						Cabecalho()
					endif
					nLin+=50
					oPrint:Say(nLin, nMargemL+10, QSE2->E2_FILIAL+" - "+FwFilialName(,QSE2->E2_FILIAL), oFont12N)
					nLin += 80
					
				EndIf
				nTotalUnid := 0
				cFilBor := QSE2->E2_FILIAL
				
				While QSE2->(!Eof()) .And. QSE2->E2_NUMBOR == cNumBor .And. QSE2->E2_FILIAL == cFilBor 
					
					//verifico se vai caber o trecho do item na pagina
					If  nCount == 1 
						if nLin+750 > nMargemB
							Rod()
							CabPagina()
							Cabecalho()
							nLin += 25
						endif
					Else
						If nLin+250  > nMargemB
							Rod()
							CabPagina()
							Cabecalho()
							nLin += 25
						endif
					EndIf
					
					ImpItem() //Item
					nTotalUnid += QSE2->E2_VALOR+QSE2->E2_ACRESC-QSE2->E2_DECRESC 
					nTotalGeral += QSE2->E2_VALOR+QSE2->E2_ACRESC-QSE2->E2_DECRESC
					
					QSE2->(DbSkip())
					nCount--
	
				EndDo				
				
			Enddo
			
			nLin += 50
			oPrint:Box( nLin,nMargemR-850,nLin+70,nMargemR )
			oPrint:Line(nLin+70, nMargemL, nLin+70, nMargemR-850)
			nLin += 10
			oPrint:Say(nLin, nMargemR-800, "Total Unidade: ", oFont12)
			oPrint:Say(nLin, nMargemR-50, "R$ " + Transform(nTotalUnid,'@E 99,999,999.99'), oFont12N,,,,1)
		
			nLin += 100
		
			oPrint:Box( nLin,nMargemL,nLin+70,nMargemR )
			nLin += 10
			oPrint:Say(nLin, nMargemR-800, "Total Geral: ", oFont12)
			oPrint:Say(nLin, nMargemR-50, "R$ " + Transform(nTotalGeral,'@E 99,999,999.99'), oFont12N,,,,1)
			nLin += 100
		
			oPrint:Say(nLin, nCenterPg, Alltrim(SM0->M0_CIDCOB) +", "+ Alltrim(Str(Day(dDataBase))) +" DE "+ UPPER(MesExtenso(dDatabase))+" DE "+ Alltrim(Str(Year(dDatabase))) , oFont10,,,,2)	
			nLin += 200
		
			cEnd := Alltrim(SM0->M0_ENDCOB) + " " + Alltrim(SM0->M0_COMPCOB) + " - " + Alltrim(SM0->M0_BAIRCOB)
			ntamEnd:= oPrint:GetTextWidth(cEnd, oFont10)
			oPrint:Line(nLin, nCenterPg-(ntamEnd/2)-100, nLin, nCenterPg+(ntamEnd/2)+100)
			nLin += 15
			
			oPrint:Say(nLin, nCenterPg, SM0->M0_NOMECOM, oFont10,,,,2)	
			nLin += 45
			
			oPrint:Say(nLin, nCenterPg, cEnd, oFont10,,,,2)
			nLin += 45
			
			oPrint:Say(nLin, nCenterPg, "CEP: " + Transform(SM0->M0_CEPCOB,"@R 9	9999-999") + ", CNPJ: " + Transform(SM0->M0_CGC, "@R 99.999.999/9999-99") + ", Fone: " + SM0->M0_TEL, oFont10,,,,2)
		
			Rod()
		EndDo
		//-----------------------------------------------------------------------
		//³Pre-visualiza a impressão 				                            ³
		//-----------------------------------------------------------------------
		oPrint:Preview()
	EndIf
Return

//-----------------------------------------------------------------------
//³Monta o cabeçalho principal 				                            ³
//-----------------------------------------------------------------------
Static Function CabPagina()

	Local cStartPath, cDescLogo

	cStartPath := GetPvProfString(GetEnvServer(),"StartPath","ERROR",GetAdv97())
	cStartPath += If(Right(cStartPath, 1) <> "\", "\", "")

	oPrint:StartPage() // Inicia uma nova pagina
	nLin := nMargemT

	cDescLogo	:= AllTrim("lgrljf"+cFilAnt+".bmp")
	oPrint:SayBitmap(nLin+50, nMargemL+100, cStartPath + cDescLogo, 300, 90) //Impressao da Logo

	oPrint:Say(nLin, 600, FwFilialName(), oFont16)
	nLin += 75

	oPrint:Say(nLin, 600, Alltrim(SM0->M0_ENDCOB) + " " + Alltrim(SM0->M0_COMPCOB) + " - " + Alltrim(SM0->M0_BAIRCOB), oFont10)
	oPrint:Say(nLin, nMargemR-10, "Data: " + DTOC(dDatabase) , oFont10,,,,1)
	nLin += 45
	oPrint:Say(nLin, 600, "CEP: " + Transform(SM0->M0_CEPCOB,"@R 9	9999-999") + " - " + Alltrim(SM0->M0_CIDCOB) + " - " + Alltrim(SM0->M0_ESTCOB) + ".   ", oFont10)
	oPrint:Say(nLin, nMargemR-10, "Hora: " +  TIME(), oFont10,,,,1)
	nLin += 45
	oPrint:Say(nLin, 600, "Fone: " + SM0->M0_TEL, oFont10)
	//oPrint:Say(nLin, 900, "http://site.jfautamacao.com.br/", oFont10)
	oPrint:Say(nLin, nMargemR-10, "Pagina: " + cValToChar(nPag), oFont10,,,,1)
	nLin += 75
	oPrint:Say(nLin, nCenterPg, "Relatório Borderô de Pagamento" , oFont20N,,,,2)
	nLin += 100
	oPrint:Line(nLin, nMargemL, nLin, nMargemR)
	nLin += 50

Return

//-----------------------------------------------------------------------
// Impressão dos dados do cliente
//-----------------------------------------------------------------------
Static Function Cabecalho()

	nLin += 25
	oPrint:Box( nLin,nMargemL,nLin+260,nMargemR )
	oPrint:Line(nLin, nMargemL+590, nLin+130, nMargemL+590)
	oPrint:Line(nLin, nMargemL+1180, nLin+130, nMargemL+1180)
	oPrint:Line(nLin, nMargemL+1770, nLin+130, nMargemL+1770)
	nLin += 15
	oPrint:Say(nLin, nMargemL+10, "Borderô:", oFont10)
	oPrint:Say(nLin, nMargemL+600, "Cheque:", oFont10)
	oPrint:Say(nLin, nMargemL+1190, "Dt. Emissão:", oFont10)
	oPrint:Say(nLin, nMargemL+1780, "Dt. Compensação:", oFont10)
	nLin += 45
	oPrint:Say(nLin, nMargemL+10, QSE2->E2_NUMBOR, oFont14N)
	oPrint:Say(nLin, nMargemL+600, QSE2->E2_NUMBCO, oFont14N)
	oPrint:Say(nLin, nMargemL+1190, DTOC(STOD(QSE2->E2_DTBORDE)), oFont14N)
	oPrint:Say(nLin, nMargemL+1780, DTOC(STOD(QSE2->E2_XDTCOMP)), oFont14N)
	nLin += 70

	oPrint:Line(nLin, nMargemL, nLin, nMargemR)
	oPrint:Line(nLin, nMargeml+1180, nLin+130, nMargemL+1180)
	oPrint:Line(nLin, nMargemL+1770, nLin+130, nMargemL+1770)
	nLin += 15
	oPrint:Say(nLin, nMargemL+10, "Banco:", oFont10)
	oPrint:Say(nLin, nMargemL+1190, "Agência:", oFont10)
	oPrint:Say(nLin, nMargemL+1780, "Conta:", oFont10)
	nLin += 45
	oPrint:Say(nLin, nMargemL+10, QSE2->EA_PORTADO +" - "+Alltrim(QSE2->A6_NREDUZ)+" - "+QSE2->A6_NOME , oFont14N)
	oPrint:Say(nLin, nMargemL+1190, QSE2->EA_AGEDEP, oFont14N)
	oPrint:Say(nLin, nMargemL+1780, QSE2->EA_NUMCON, oFont14N)
	nLin += 70

	//Cab Itens
	oPrint:FillRect( {nLin,nMargemL, nLin+70, nMargemR}, oBrush1 )
	oPrint:Box( nLin,nMargemL,nLin+70,nMargemR )
	nLin += 15
	//oPrint:Say(nLin, nMargemL+10, "Natureza", oFont10N)
	oPrint:Say(nLin, nMargemL+10, "Numero", oFont10N)
	oPrint:Say(nLin, nMargemL+510, "Fornecedor", oFont10N)
	//oPrint:Say(nLin, nMargemL+1300, "Numero", oFont10N)
	oPrint:Say(nLin, nMargemL+1300, "Dt. Emissão", oFont10N)
	//oPrint:Say(nLin, nMargemL+1700, "Dt. Emissão", oFont10N)
	oPrint:Say(nLin, nMargemL+1700, "Dt. Vencto", oFont10N)
	oPrint:Say(nLin, nMargemL+2150, "Valor", oFont10N,,,,1)
	nLin += 50

Return


//-----------------------------------------------------------------------
//³Imprime item do pedido de venda			                            ³
//-----------------------------------------------------------------------
Static Function ImpItem()

	nLin += 25

	/*cNaturez := QSE2->E2_NATUREZ+" - "+POSICIONE("SED",1,XFILIAL("SED")+QSE2->E2_NATUREZ,"ED_DESCRIC")
	cNaturez := POSICIONE("SED",1,XFILIAL("SED")+QSE2->E2_NATUREZ,"ED_DESCRIC")
	if oPrint:GetTextWidth(cNaturez, oFont10N) > 420
		nPosAux := 1
		While oPrint:GetTextWidth(SubStr(cNaturez,1,nPosAux), oFont10N) < 420
			nPosAux++
		Enddo
		oPrint:Say(nLin, nMargemL+10, SubStr(cNaturez,1,nPosAux), oFont10N)
		cNaturez := SubStr(cNaturez,nPosAux+1)
	else
		oPrint:Say(nLin, nMargemL+10, cNaturez, oFont10N)
		cNaturez := ""
	endif
*/
	//cFornece := QSE2->E2_FORNECE+"/"+QSE2->E2_LOJA+" - "+QSE2->A2_NOME
	cFornece := QSE2->A2_NOME
	if oPrint:GetTextWidth(cFornece, oFont10N) > 800
		nPosAux := 1
		While oPrint:GetTextWidth(SubStr(cFornece,1,nPosAux), oFont10N) < 800
			nPosAux++
		Enddo
		oPrint:Say(nLin, nMargemL+510, SubStr(cFornece,1,nPosAux), oFont10N)
		cFornece := SubStr(cFornece,nPosAux+1)
	else
		oPrint:Say(nLin, nMargemL+510, cFornece, oFont10N)
		cFornece := ""
	endif	
	
	oPrint:Say(nLin, nMargemL+10, QSE2->E2_PREFIXO+"-"+QSE2->E2_NUM+"-"+QSE2->E2_PARCELA+"-"+QSE2->E2_TIPO, oFont10)
	oPrint:Say(nLin, nMargemL+1300, DtoC(StoD(QSE2->E2_EMISSAO)), oFont10)
	oPrint:Say(nLin, nMargemL+1700, DtoC(StoD(QSE2->E2_VENCREA)), oFont10)
	oPrint:Say(nLin, nMargemR-25, Alltrim(Transform(QSE2->E2_VALOR+QSE2->E2_ACRESC-QSE2->E2_DECRESC,'@E 99,999,999.99')), oFont10,,,,1)
	nLin += 50
	
	//if !empty(cNaturez) .Or. !empty(cFornece) //se restou descriçao a imprimir
	if !empty(cFornece) //se restou descriçao a imprimir
		//oPrint:Say(nLin, nMargemL+10, cNaturez, oFont10N)
		oPrint:Say(nLin, nMargemL+500, cFornece, oFont10N)
		nLin += 50
	endif

Return

//-----------------------------------------------------------------------
//³Monta o rodapé principal 				                            ³
//-----------------------------------------------------------------------
Static Function Rod()

	nLin := nMargemB
	oPrint:Line(nLin, nMargemL, nLin, nMargemR)
	oPrint:Say(nLin, nMargemL, "Impresso em: " + DTOC(dDatabase) + " " + TIME(), oFont8)
	oPrint:Say(nLin, nCenterPg, "TOTVS - PROTHEUS " + cVersao, oFont8,,,,2)
	oPrint:Say(nLin, nMargemR, "Pagina: " + cValToChar(nPag++), oFont8,,,,1)
	
	oPrint:EndPage() //finaliza pagina

Return

Static Function GeraQry(aRet)

Local cQry     := ""

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³    Monta Query com os dados que serao impressos no relatorio        ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	cQry := "SELECT  QTD.E2_QUANT,SEA.EA_PORTADO, SEA.EA_AGEDEP, SEA.EA_NUMCON,SA6.A6_NOME,SA6.A6_NREDUZ,* "
	cQry += "FROM "+RetSqlName("SE2")+" SE2 "
	cQry += "INNER JOIN (	SELECT SE2.E2_NUMBOR, COUNT(SE2.E2_NUMBOR) E2_QUANT " 
	cQry += "				FROM "+RetSqlName("SE2")+" SE2 " 
	cQry += "				WHERE SE2.E2_NUMBOR <> ' ' " 
	cQry += "					AND SE2.D_E_L_E_T_ <> '*' " 
	cQry += "				GROUP BY SE2.E2_NUMBOR) QTD "
    cQry += "	ON QTD.E2_NUMBOR = SE2.E2_NUMBOR " 
	cQry += "INNER JOIN "+RetSqlName("SEA")+" SEA "
	cQry += "	INNER JOIN "+RetSqlName("SA6")+" SA6 "
	cQry += "		ON SA6.A6_COD = SEA.EA_PORTADO "
	cQry += "			AND SA6.A6_AGENCIA = SEA.EA_AGEDEP "
	cQry += "			AND SA6.A6_NUMCON = SEA.EA_NUMCON "
	cQry += "			AND SA6.D_E_L_E_T_ = SEA.D_E_L_E_T_ "
	cQry += "	ON SEA.EA_FILORIG = SE2.E2_FILIAL "
	cQry += "		AND SEA.EA_NUMBOR = SE2.E2_NUMBOR "
	cQry += "		AND SEA.EA_PREFIXO = SE2.E2_PREFIXO "
	cQry += "		AND SEA.EA_NUM = SE2.E2_NUM "
	cQry += "		AND SEA.EA_PARCELA = SE2.E2_PARCELA "
	cQry += "		AND SEA.EA_TIPO = SE2.E2_TIPO "
	cQry += "		AND SEA.EA_FORNECE = SE2.E2_FORNECE "
	cQry += "		AND SEA.EA_LOJA = SE2.E2_LOJA "
	cQry += "		AND SEA.EA_CART = 'P' "
	cQry += "		AND SEA.D_E_L_E_T_ = SE2.D_E_L_E_T_ "
	cQry += "INNER JOIN "+RetSqlName("SA2")+" SA2 "
	cQry += "	ON SA2.A2_COD = SE2.E2_FORNECE "
	cQry += "		AND SA2.A2_LOJA = SE2.E2_LOJA "
	cQry += "		AND SA2.D_E_L_E_T_ = SE2.D_E_L_E_T_ "
	cQry += "WHERE "
	cQry += "	SE2.E2_FILIAL BETWEEN '"+aRet[1]+"' AND '"+aRet[2]+"' "
    cQry += "	AND SE2.E2_NUMBOR BETWEEN '"+aRet[3]+"' AND '"+aRet[4]+"' "
    cQry += "	AND SE2.E2_DTBORDE BETWEEN '"+DtoS(aRet[5])+"' AND '"+DtoS(aRet[6])+"' "
    cQry += "	AND SE2.E2_XDTCOMP BETWEEN '"+DtoS(aRet[7])+"' AND '"+DtoS(aRet[8])+"' "
    cQry += "	AND SE2.D_E_L_E_T_ <> '*' "
    If !Empty(aRet[9]) .And. aRet[9] == "Fornecedor"
    	cQry += "ORDER BY SE2.E2_NUMBOR, SE2.E2_FILIAL, SA2.A2_NOME, SE2.E2_NUM, SE2.E2_VALOR "
    ElseIf !Empty(aRet[9]) .And. aRet[9] == "Titulo"
       	cQry += "ORDER BY SE2.E2_NUMBOR, SE2.E2_FILIAL, SE2.E2_NUM, SE2.E2_VALOR, SA2.A2_NOME "
    ElseIf !Empty(aRet[9])
       	cQry += "ORDER BY SE2.E2_NUMBOR, SE2.E2_FILIAL, SE2.E2_VALOR, SA2.A2_NOME, E2_NUM "
    EndIf

Return cQry
