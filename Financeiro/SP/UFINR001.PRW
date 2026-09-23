#include 'protheus.ch'
#include 'parmtype.ch'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'TOPCONN.CH'

#Define CRLF chr(13)+chr(10)


/*-------------------------------------------------------------------
- Programa: UFINR001
- Autor: Rafael Brito
- Data: 05/01/2021
- Descrição: Impressão solicitação de pagamento
-------------------------------------------------------------------*/


User function UFINR001()

	//-----------------------------------------------------------------------
	//Variaveis de Tipos de fontes que podem ser utilizadas no relatório
	//-----------------------------------------------------------------------
	Private oFont6		:= TFONT():New("Arial Narrow",7,6,.T.,.F.,5,.T.,5,.T.,.F.) ///Fonte 6 Normal
	Private oFont6N 	:= TFONT():New("Arial Narrow",7,6,,.T.,,,,.T.,.F.) ///Fonte 6 Negrito
	Private oFont8		:= TFONT():New("Arial Narrow",9,8,.T.,.F.,5,.T.,5,.T.,.F.) ///Fonte 8 Normal
	Private oFont8N 	:= TFONT():New("Arial Narrow",8,8,,.T.,,,,.T.,.F.) ///Fonte 8 Negrito
	Private oFont10 	:= TFONT():New("Arial Narrow",9,10,.T.,.F.,5,.T.,5,.T.,.F.) ///Fonte 10 Normal
	Private oFont10S	:= TFONT():New("Arial Narrow",9,10,.T.,.F.,5,.T.,5,.T.,.T.) ///Fonte 10 Sublinhando
    Private oFont10N 	:= TFONT():New("Arial Narrow",9,10,,.T.,,,,.T.,.F.) ///Fonte 10 Negrito
    Private oFont11		:= TFONT():New("Arial Narrow",11,11,,.F.,,,,.T.,.F.) ///Fonte 11 Normal
	Private oFont11NS	:= TFONT():New("Arial Narrow",11,11,,.T.,,,,.T.,.T.) ///Fonte 11 Negrito e Sublinhado
	Private oFont11N	:= TFONT():New("Arial Narrow",11,11,,.T.,,,,.T.,.F.) ///Fonte 11 Negrito
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
	//Variveis para impressão                                              Â³
	//-----------------------------------------------------------------------
	Private cStartPath
	Private nLin 		:= 0
	Private nMargemL    := 50
	Private nMargemR    := 2360
	Private nMargemT	:= 50
	Private nMargemB	:= 3350
	Private nCenterPg	:= 1220
	Private oPrint		:= TMSPRINTER():New("Solicitação de Pagamento")
	Private nPag		:= 0
	Private aPergs 		:= {}
    Private aRetPar 	:= {}
    Private oBrush1		:= TBrush():New( , CLR_HGRAY )
    
	//-----------------------------------------------------------------------
	//Define Tamanho do Papel                                              
	//-----------------------------------------------------------------------
	#define DMPAPER_A4 9 //Papel A4
	oPrint:setPaperSize( DMPAPER_A4 )

	//-----------------------------------------------------------------------
	//Orientacao do papel (Retrato ou Paisagem)                            
	//-----------------------------------------------------------------------
	oPrint:SetPortrait()///Define a orientacao da impressao como retrato
            
    Processa( {|| U_UFINR01A() }, "Aguarde...", "Imprimindo Solicitação...",.F.)

Return

User function UFINR01A()

	Local nX

    Cabecalho()


    oPrint:FillRect( {nLin,nMargemL, nLin+60, nMargemR}, oBrush1 )
    oPrint:Box( nLin,nMargemL,nLin+440,nMargemR )
    oPrint:Say(nLin, nCenterPg, "Dados Solicitação", oFont14N,,,,2)
	nLin += 60
	oPrint:Line(nLin, nMargemL+490, nLin+120, nMargemL+490)
	oPrint:Line(nLin, nMargemL+1490, nLin+120, nMargemL+1490)
	oPrint:Line(nLin, nMargemL+1900, nLin+120, nMargemL+1900)
	oPrint:Line(nLin+120, nMargemL, nLin+120, nMargemR)

    nLin += 10
	oPrint:Say(nLin, nMargemL+10, "Número", oFont12,,,,)
	oPrint:Say(nLin, nMargemL+500, "Tipo", oFont12,,,,)
    oPrint:Say(nLin, nMargemL+1500, "Vencimento", oFont12,,,,)
    oPrint:Say(nLin, nMargemR-30, "Valor R$", oFont12,,,,1)    
    nLin += 50
    oPrint:Say(nLin, nMargemL+10, SZ2->Z2_NUM, oFont12N,,,,)
    oPrint:Say(nLin, nMargemL+500, UPPER(Posicione("SX5",1,xFilial("SX5")+"05"+SZ2->Z2_TIPO,"X5_DESCRI")), oFont14N,,,,)
	oPrint:Say(nLin, nMargemL+1500, DtoC(SZ2->Z2_VENCTO), oFont12N,,,,)
    oPrint:Say(nLin, nMargemR-30, transform(SZ2->Z2_VALOR,"@E 999,999,999,999.99"), oFont12N,,,,1)

	
	nLin += 70
	oPrint:Line(nLin, nMargemL+1090, nLin+120, nMargemL+1090)
    oPrint:Line(nLin+120, nMargemL, nLin+120, nMargemR)
	oPrint:Say(nLin, nMargemL+10, "Natureza", oFont12N,,,,)
	oPrint:Say(nLin, nMargemL+1100, "Centro de Custo", oFont12N,,,,)       
	nLin += 50
	oPrint:Say(nLin, nMargemL+10, Alltrim(SZ2->Z2_NATUREZ)+" - "+Posicione("SED",1,xFilial("SED")+SZ2->Z2_NATUREZ,"ED_DESCRIC"), oFont12N,,,,)
	oPrint:Say(nLin, nMargemL+1100, Alltrim(SZ2->Z2_CCD)+" - "+Posicione("CTT",1,xFilial("CTT")+SZ2->Z2_CCD,"CTT_DESC01"), oFont12N,,,,)
	
	
	nLin += 70
    oPrint:Say(nLin, nMargemL+10, "Histórico", oFont12N,,,,)    
	nLin += 50
	oPrint:Say(nLin, nMargemL+10, SZ2->Z2_HIST, oFont12N,,,,)

	// --------------------------   Favorecido --------------------------------------------------------------------------------------------------
	nLin += 100
	oPrint:FillRect( {nLin,nMargemL, nLin+60, nMargemR}, oBrush1 )
    oPrint:Box( nLin,nMargemL,nLin+320,nMargemR )
    oPrint:Say(nLin, nCenterPg, "Dados Favorecido", oFont14N,,,,2)
	SA2->(DbSetorder(1))
	SA2->(DbSeek(xFilial("SA2")+SZ2->Z2_FORNECE+SZ2->Z2_LOJA))

	nLin += 60
	oPrint:Line(nLin, nMargemL+590, nLin+120, nMargemL+590)
	oPrint:Line(nLin+120, nMargemL, nLin+120, nMargemR)

	nLin += 10
	oPrint:Say(nLin, nMargemL+10, "Favorecido", oFont12,,,,)
	oPrint:Say(nLin, nMargemL+600, "CNPJ/CPF", oFont12,,,,)
	nLin += 50
    oPrint:Say(nLin, nMargemL+10, SZ2->Z2_FORNECE+" - "+SZ2->Z2_LOJA, oFont12N,,,,)
	oPrint:Say(nLin, nMargemL+600, Transform(SA2->A2_CGC,"@R 99.999.999/9999-99"), oFont12N,,,,)
	nLin += 70
	oPrint:Say(nLin, nMargemL+10, "Nome", oFont12,,,,)
	nLin += 50
    oPrint:Say(nLin, nMargemL+10, SA2->A2_NOME, oFont12N,,,,)


	nLin += 100
	oPrint:FillRect( {nLin,nMargemL, nLin+60, nMargemR}, oBrush1 )
    oPrint:Box( nLin,nMargemL,nLin+320,nMargemR )
    oPrint:Say(nLin, nCenterPg, "Observação", oFont14N,,,,2)
	nLin += 70
	aObserv := QuebraObs(SZ2->Z2_OBSERV)
	nLinAux := 270
	For nX := 1 to len(aObserv)
		If nLinAux >= 50
			oPrint:Say(nLin, nMargemL+10, aObserv[nX], oFont12N,,,,)
			nLin += 50
			nLinAux -= 50
		EndIf
	Next

	nLin += nLinAux
	oPrint:FillRect( {nLin,nMargemL, nLin+60, nMargemR}, oBrush1 )
    oPrint:Box( nLin,nMargemL,nLin+120,nMargemR )
    oPrint:Say(nLin, nCenterPg, "Requisitante", oFont14N,,,,2)
	nLin += 70
	oPrint:Say(nLin, nMargemL+10, SZ2->Z2_REQUISI, oFont12N,,,,)
	

	nLin += 230
	cDataExt := SubStr(DTOS(SZ2->Z2_EMISSAO),7,2)+ " de "+MesExtenso(SubStr(DTOS(SZ2->Z2_EMISSAO),5,2))+" de "+SubStr(DTOS(SZ2->Z2_EMISSAO),1,4)
	oPrint:Say(nLin, nCenterPg, cDataExt , oFont14N,,,,2)

	nLin += 250	
	oPrint:Line(nLin, nMargemL+50, nLin, nMargemL+500)
	oPrint:Line(nLin, nCenterPg-225, nLin, nCenterPg+225)
	oPrint:Line(nLin, nMargemR-50, nLin, nMargemR-500)
	nLin += 10
	oPrint:Say(nLin, nMargemL+50+225, "Requisitante", oFont10N,,,,2)
	oPrint:Say(nLin, nCenterPg, "Gerência", oFont10N,,,,2)
	oPrint:Say(nLin, nMargemR-50-225, "Diretoria", oFont10N,,,,2)

	Rod()// Imprime o Rodapé da página

	//-----------------------------------------------------------------------
	//Pre-visualiza a impressão 				                            
	//-----------------------------------------------------------------------
	oPrint:Preview()

Return

//-----------------------------------------------------------------------
//Monta o cabeçalho principal 				                            
//-----------------------------------------------------------------------

Static Function Cabecalho()

    Local cStartPath, cDescLogo
    
    nPag ++
    cStartPath := GetPvProfString(GetEnvServer(),"StartPath","ERROR",GetAdv97())
    cStartPath += If(Right(cStartPath, 1) <> "\", "\", "")
    
	oPrint:StartPage() // Inicia uma nova pagina
	nLin := nMargemT

	cDescLogo	:= AllTrim("lgrl"+cEmpAnt+".bmp")
	oPrint:SayBitmap(nLin+50, nMargemL+50, cStartPath + cDescLogo, 250, 250) //Impressao da Logo

	oPrint:Say(nLin, 500, AllTrim(SM0->M0_NOMECOM) +" - "+SM0->M0_FILIAL, oFont12)
	nLin += 75

    oPrint:Say(nLin, 500, "CNPJ: "+Transform(SM0->M0_CGC,"@R 99.999.999/9999-99"), oFont10)
    oPrint:Say(nLin, nMargemR-10, "Data: " + DTOC(dDatabase) , oFont10,,,,1)
    nLin += 45
    oPrint:Say(nLin, 500, Alltrim(SM0->M0_ENDENT) + " " + Alltrim(SM0->M0_COMPENT) + " - " + Alltrim(SM0->M0_BAIRENT), oFont10)
	oPrint:Say(nLin, nMargemR-10, "Hora: " +  TIME(), oFont10,,,,1)
	nLin += 45
    oPrint:Say(nLin, 500, "CEP: " + Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Alltrim(SM0->M0_CIDENT) + " - " + Alltrim(SM0->M0_ESTENT) + ".   ", oFont10)
    oPrint:Say(nLin, 1050, "Fone: " + SM0->M0_TEL, oFont10)
	oPrint:Say(nLin, 1400, "http://www.quebecambiental.com.br", oFont10)
	oPrint:Say(nLin, nMargemR-10, "Pagina: " + cValToChar(nPag), oFont10,,,,1)
    nLin += 75
    oPrint:Say(nLin, nCenterPg, "SOLICITAÇÃO DE PAGAMENTO" , oFont20N,,,,2)
    nLin += 80
	oPrint:Line(nLin, nMargemL, nLin, nMargemR)
	nLin += 50

Return

//-----------------------------------------------------------------------
//Monta o rodapé principal 				                            
//-----------------------------------------------------------------------
Static Function Rod()

	nLin := nMargemB
	oPrint:Line(nLin, nMargemL, nLin, nMargemR)
	oPrint:Say(nLin, nMargemL, "Impresso em: " + DTOC(dDatabase) + " " + TIME(), oFont8)
	oPrint:Say(nLin, nCenterPg, "TOTVS - PROTHEUS " + cVersao, oFont8,,,,2)
	oPrint:Say(nLin, nMargemR, "Pagina: " + cValToChar(nPag), oFont8,,,,1)

	oPrint:EndPage() //finaliza pagina

Return

Static function QuebraObs(cObserv)

	Local aObserv := {}

	aObserv := StrToKArr(cObserv, CRLF)

return aObserv
