#INCLUDE "topconn.ch"
#INCLUDE "Protheus.ch"
#INCLUDE "TbiConn.ch"
#INCLUDE "rwmake.ch"
#INCLUDE "COLORS.CH"
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"
#INCLUDE "TBICODE.CH"  

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑฺฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฟฑฑ
ฑฑณFuncao    ณ FA740BRW ณ Autor ณ Adriano Costa         			ณ Data ณ 17/06/16 ณฑฑ
ฑฑรฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤดฑฑ
ฑฑณDescricao ณ O ponto de entrada FA740BRW foi desenvolvido para adicionar itens      ณฑฑ
ฑฑณ			 ณ no menu da mBrowse. Retorna array com os novas op็๕es e manda como     ณฑฑ
ฑฑณ			 ณ parโmetro o array com as op็๕es padrใo                                 ณฑฑ
ฑฑรฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤดฑฑ
ฑฑณUso       ณ Financeiro                                                             ณฑฑ
ฑฑภฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤูฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
//Ponto de Entrada para incluir o recibo no financeiro com o fonte RecFin
User function FA740BRW   

Local aArea   := GetArea()   
Local aBotao := {}

	// Cria botใo de Recibo                                               
	aadd(aBotao,{'Recibo'          								,'U_RECFIN'       	   , 0 , 7,0,NIL})
	aadd(aBotao,{'Rel. Conta a receber em Aberto','FINR130'     , 0 , 7,0,NIL})
	aadd(aBotao,{"Rel. Rela็ใo de Baixas" ,"FINR190"	  		, 0 , 7,0,NIL})

		
RestArea(aArea)

Return (aBotao)
     


/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณ RecFin  บ Autor ณ Microsiga         บ Data ณ  04/12/12     บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDescricao ณ Recibo de pagamento					                	  บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ                                                            บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
/*/


User Function RecFin()

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณVariaveis de Tipos de fontes que podem ser utilizadas no relat๓rio   ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
Local nX

Private oFont6		:= TFONT():New("ARIAL",7,6,.T.,.F.,5,.T.,5,.T.,.F.) ///Fonte 6 Normal
Private oFont6N 	:= TFONT():New("ARIAL",7,6,,.T.,,,,.T.,.F.) ///Fonte 6 Negrito
Private oFont8		:= TFONT():New("ARIAL",9,8,.T.,.F.,5,.T.,5,.T.,.F.) ///Fonte 8 Normal
Private oFont8N 	:= TFONT():New("ARIAL",8,8,,.T.,,,,.T.,.F.) ///Fonte 8 Negrito
Private oFont10 	:= TFONT():New("ARIAL",9,10,.T.,.F.,5,.T.,5,.T.,.F.) ///Fonte 10 Normal
Private oFont10S	:= TFONT():New("ARIAL",9,10,.T.,.F.,5,.T.,5,.T.,.T.) ///Fonte 10 Sublinhando
Private oFont10N 	:= TFONT():New("ARIAL",9,10,,.T.,,,,.T.,.F.) ///Fonte 10 Negrito
Private oFont12		:= TFONT():New("ARIAL",12,12,,.F.,,,,.T.,.F.) ///Fonte 12 Normal
Private oFont12NS	:= TFONT():New("ARIAL",12,12,,.T.,,,,.T.,.T.) ///Fonte 12 Negrito e Sublinhado
Private oFont12N	:= TFONT():New("ARIAL",12,12,,.T.,,,,.T.,.F.) ///Fonte 12 Negrito
Private oFont14		:= TFONT():New("ARIAL",14,14,,.F.,,,,.T.,.F.) ///Fonte 14 Normal
Private oFont14NS	:= TFONT():New("ARIAL",14,14,,.T.,,,,.T.,.T.) ///Fonte 14 Negrito e Sublinhado
Private oFont14N	:= TFONT():New("ARIAL",14,14,,.T.,,,,.T.,.F.) ///Fonte 14 Negrito
Private oFont16 	:= TFONT():New("ARIAL",16,16,,.F.,,,,.T.,.F.) ///Fonte 16 Normal
Private oFont16N	:= TFONT():New("ARIAL",16,16,,.T.,,,,.T.,.F.) ///Fonte 16 Negrito
Private oFont16NS	:= TFONT():New("ARIAL",16,16,,.T.,,,,.T.,.T.) ///Fonte 16 Negrito e Sublinhado
Private oFont20N	:= TFONT():New("ARIAL",20,20,,.T.,,,,.T.,.F.) ///Fonte 20 Negrito
Private oFont22N	:= TFONT():New("ARIAL",22,22,,.T.,,,,.T.,.F.) ///Fonte 22 Negrito

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณVariveis para impressใo                                              ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

Private cStartPath
Private nLin 		:= 50
Private oPrint		:= TMSPRINTER():New("")
Private nPag		:= 1
_CTITULO := ""
//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณDefine Tamanho do Papel                                                  ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

#define DMPAPER_A4 9 //Papel A4
oPrint:setPaperSize( 9 )

//TMSPrinter(): SetPaperSize ()

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณCria as perguntas na SX1                                             ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

//AjustaSx1()
//pergunte(cPerg,.T.) //Chama a tela de parametros

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณOrientacao do papel (Retrato ou Paisagem)                                             ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

oPrint:SetPortrait()///Define a orientacao da impressao como retrato
//oPrint:SetLandscape() ///Define a orientacao da impressao como paisagem

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณMonta Query com os dados que serใo impressos no relat๓rio            ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
aTitulos := {}
APAG     := {}
NumNcc:=""
cQry:=""
aCheque:={}

NCHEQUE := 0
ADINHEI := {}
NCREDIT := 0
NTOTAL  := 0
nTotNCC := 0
CDOCUMENTO := ""

CCLIENTE := SE1->E1_CLIENTE
CLOJA    := SE1->E1_LOJA

//IF ALLTRIM(SE1->E1_TIPO) == "RA" .OR. ALLTRIM(SE1->E1_TIPO) == "NCC"
//	DBSELECTAREA("SE1")
//	SE1->(DBSETORDER(2))
//	IF SE1->(DBSEEK(XFILIAL("SE1")+SE1->(CCLIENTE+CLOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO)))

//	ENDIF
//ENDIF

cQry:="		  SELECT"
cQry+="				 *"
cQry+="		   FROM " + RetSqlName("SE5") + " E5
cQry+="		  WHERE E5.D_E_L_E_T_ <> '*'
cQry+="		    AND E5_FILIAL    = '"+XFILIAL("SE5")+"' "
cQry+="			AND E5_PREFIXO = '"+SE1->E1_PREFIXO+"'   "
cQry+="			AND E5_NUMERO  = '"+SE1->E1_NUM+"'   "
cQry+="			AND E5_PARCELA = '"+SE1->E1_PARCELA+"'   "
cQry+="			AND E5_TIPO    = '"+SE1->E1_TIPO+"'   "
cQry+="			AND E5_MOTBX    IN ('LIQ','CMP')   "

TcQuery cQry New Alias "QRY3" // Cria uma nova area com o resultado do query
While QRY3->(!EoF())
	CDOCUMENTO := QRY3->E5_DOCUMEN
	QRY3->(DBSKIP())
ENDDO
QRY3->(DBCLOSEAREA())

IF ALLTRIM(SE1->E1_TIPO) == "RA" .OR. ALLTRIM(SE1->E1_TIPO) == "NCC"
	CDOCUMENTO := SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO)+"01"
ENDIF
//CDOCUMENTO := POSICIONE("SE5",7,XFILIAL("SE5")+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO),"E5_DOCUMEN")

cQry:="		  SELECT"
cQry+="				 E5_PREFIXO, E5_NUMERO, E5_PARCELA, E5_TIPO"
cQry+="		   FROM " + RetSqlName("SE5") + " E5
cQry+="		  WHERE E5.D_E_L_E_T_ <> '*'
cQry+="		    AND E5_FILIAL    = '"+XFILIAL("SE5")+"' "
IF !EMPTY(CDOCUMENTO)
	cQry+="			AND E5_DOCUMEN = '"+CDOCUMENTO+"'   "
	cQry+="			AND E5_TIPO != 'CH '   "     
	cQry+="		AND E5_MOTBX = 'LIQ'   " + CRLF  //Adicionado devido o E5_DOCUMEN ser gerado tamb้m pela baixa por lote, entใo trazia a baixa por lote junto com a baixa de liquida็ใo.
ELSE
	cQry+="			AND E5_PREFIXO = '"+SE1->E1_PREFIXO+"'   "
	cQry+="			AND E5_NUMERO  = '"+SE1->E1_NUM+"'   "
	cQry+="			AND E5_PARCELA = '"+SE1->E1_PARCELA+"'   "
	cQry+="			AND E5_TIPO    = '"+SE1->E1_TIPO+"'   "
ENDIF
cQry+="			GROUP BY E5_PREFIXO, E5_NUMERO, E5_PARCELA, E5_TIPO"
cQry+="			ORDER BY E5_PREFIXO, E5_NUMERO, E5_PARCELA, E5_TIPO"


//cQry := Changequery(cQry)
TcQuery cQry New Alias "QRY2" // Cria uma nova area com o resultado do query

IF QRY2->(EOF())
	QRY2->(DBCLOSEAREA())
	cQry:="		  SELECT"
	cQry+="				 E1_PREFIXO AS E5_PREFIXO, E1_NUM AS E5_NUMERO, E1_PARCELA AS E5_PARCELA, E1_TIPO AS E5_TIPO"
	cQry+="		   FROM " + RetSqlName("SE1") + " E1
	cQry+="		  WHERE E1.D_E_L_E_T_ <> '*'
	cQry+="		    AND E1_FILIAL    = '"+XFILIAL("SE1")+"' "
	cQry+="			AND E1_PREFIXO = '"+SE1->E1_PREFIXO+"'   "
	cQry+="			AND E1_NUM  = '"+SE1->E1_NUM+"'   "
	cQry+="			AND E1_PARCELA = '"+SE1->E1_PARCELA+"'   "
	cQry+="			AND E1_TIPO    = '"+SE1->E1_TIPO+"'   "
	cQry+="			GROUP BY E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO"
	
	//cQry := Changequery(cQry)
	TcQuery cQry New Alias "QRY2" // Cria uma nova area com o resultado do query
ENDIF

While QRY2->(!EoF())
	DBSELECTAREA("SE1")
	SE1->(DBSETORDER(1))	// E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
	IF SE1->(DBSEEK(XFILIAL("SE1")+QRY2->(E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO)))
		//		AADD(aTitulos,{SE1->E1_PREFIXO, SE1->E1_NUM, SE1->E1_PARCELA, SE1->E1_EMISSAO, SE1->E1_VENCTO, SE1->E1_TIPO, SE1->E1_VALOR, SE1->E1_JUROS, SE1->E1_MULTA, SE1->E1_DESCONT, SE1->E1_SALDO})
		
		//Baixa Normal
		cQry:="		  SELECT"
		cQry+="				 E5_SEQ,"
		cQry+="				 E5.R_E_C_N_O_ REG,"
		cQry+="				 E5_DATA,"
		cQry+="				 E5_NUMERO,"
		cQry+="				 E5_VALOR,"
		cQry+="				 'Dinheiro' E5_MOTBX,"
		cQry+="				 E5_DOCUMEN,"
		cQry+="				 E5_PARCELA,"
		cQry+="				 E5_PREFIXO,"
		cQry+="				 E5_HISTOR,"
		cQry+="				 E5_TIPODOC,"
		cQry+="				 E5_FILORIG"
		cQry+="		   FROM " + RetSqlName("SE5") + " E5
		cQry+="       INNER JOIN " + RetSqlName("SE1") + " E1 ON (E5_NUMERO    = E1_NUM
		cQry+="												   AND E5_PARCELA  = E1_PARCELA
		cQry+="												   AND E5_PREFIXO  = E1_PREFIXO
		cQry+="												   AND E5_CLIFOR   = E1_CLIENTE
		cQry+="												   AND E5_LOJA     = E1_LOJA
		cQry+="												   AND E5_TIPO     = E1_TIPO		
		cQry+="		  		     					           AND E5.D_E_L_E_T_ = E1.D_E_L_E_T_)
		cQry+="		  WHERE E5.D_E_L_E_T_ <> '*'
		cQry+="		    AND E5_MOTBX    = 'NOR' "
		cQry+="         AND E5_TIPODOC <> 'JR' "
		cQry+="         AND E5_TIPODOC <> 'TR' "
		cQry+="         AND E5_TIPODOC <> 'MT' "
		cQry+="			AND E5_SITUACA <> 'C' "
		cQry+="			AND E5_TIPODOC <> 'DC' " //POR SANGELLES DATA 04/01/2013, NรO PUXAR OS DESCONTOS
		cQry+="			AND E5_TIPODOC NOT IN ('DB','OD') " //NAO TRAZER MOVIMENTACOES INTERNAS
		cQry+="			AND E5_NUMERO = '"+AllTrim(SE1->E1_NUM)+"'   "
		cQry+="			AND E5_PARCELA = '"+AllTrim(SE1->E1_PARCELA)+"'   "
		cQry+="			AND E5_CLIFOR = '"+AllTrim(SE1->E1_CLIENTE)+"'   "
		cQry+="			AND E5_LOJA = '"+AllTrim(SE1->E1_LOJA)+"'   "
		
		cQry+="	     UNION ALL
		
		//Liquidado
		cQry+="		  SELECT"
		cQry+="				 E5_SEQ,"
		cQry+="				 E5.R_E_C_N_O_ REG,"
		cQry+="				 E5_DATA,"
		cQry+="				 E5_NUMERO,"
		cQry+="				 E5_VALOR,"
		cQry+="				 'Cheque' E5_MOTBX,"
		cQry+="				 E5_DOCUMEN,"
		cQry+="				 E5_PARCELA,"
		cQry+="				 E5_PREFIXO,"
		cQry+="				 E5_HISTOR,"
		cQry+="				 E5_TIPODOC,"
		cQry+="				 E5_FILORIG"
		cQry+="		   FROM " + RetSqlName("SE5") + " E5"
		cQry+="       INNER JOIN " + RetSqlName("SE1") + " E1 ON (E5_NUMERO     = E1_NUM"
		cQry+="												   AND E5_PARCELA    = E1_PARCELA
		cQry+="												   AND E5_PREFIXO    = E1_PREFIXO
		cQry+="												   AND E5_CLIFOR   = E1_CLIENTE
		cQry+="												   AND E5_LOJA     = E1_LOJA
		cQry+="												   AND E5_TIPO     = E1_TIPO		
		cQry+="		  		     					           AND E5.D_E_L_E_T_ = E1.D_E_L_E_T_)"
		cQry+="		  WHERE E5.D_E_L_E_T_ <> '*'"
		cQry+="		    AND E5_MOTBX    = 'LIQ'"
		cQry+="			AND E5_SITUACA <> 'C'"
		cQry+="			AND E5_TIPODOC <> 'JR'"
		cQry+="         AND E5_TIPODOC <> 'TR' "
		cQry+="         AND E5_TIPODOC <> 'MT' "
		cQry+="			AND E5_TIPODOC <> 'DC' " //POR SANGELLES DATA 04/01/2013, NรO PUXAR OS DESCONTOS
		cQry+="			AND E5_NUMERO = '"+AllTrim(SE1->E1_NUM)+"'   "
		cQry+="			AND E5_PARCELA = '"+AllTrim(SE1->E1_PARCELA)+"'   "
		cQry+="			AND E5_CLIFOR = '"+AllTrim(SE1->E1_CLIENTE)+"'   "
		cQry+="			AND E5_LOJA = '"+AllTrim(SE1->E1_LOJA)+"'   "
		
		cQry+="	     UNION ALL"
		
		//Faturado
		cQry+="		  SELECT"
		cQry+="				 E5_SEQ,"
		cQry+="				 E5.R_E_C_N_O_ REG,"
		cQry+="				 E5_DATA,"
		cQry+="				 E5_NUMERO,"
		cQry+="				 E5_VALOR,"
		cQry+="				 'teste1' E5_MOTBX,"
		cQry+="				 E5_DOCUMEN,"
		cQry+="				 E5_PARCELA,"
		cQry+="				 E5_PREFIXO,"
		cQry+="				 E5_HISTOR,"
		cQry+="				 E5_TIPODOC,"
		cQry+="				 E5_FILORIG"
		cQry+="		   FROM " + RetSqlName("SE5") + " E5"
		cQry+="       INNER JOIN " + RetSqlName("SE1") + " E1 ON (E5_FATURA     = E1_NUM"
		cQry+="												   AND E5_PARCELA    = E1_PARCELA
		cQry+="												   AND E5_CLIFOR   = E1_CLIENTE
		cQry+="												   AND E5_LOJA     = E1_LOJA
		cQry+="												   AND E5_TIPO     = E1_TIPO		
		cQry+="												   AND E5_FILORIG    = E1_MSFIL"
		cQry+="		  		     					           AND E5.D_E_L_E_T_ = E1.D_E_L_E_T_)"
		cQry+="		  WHERE E5.D_E_L_E_T_ <> '*'"
		cQry+="		    AND E5_MOTBX = 'FAT'"
		cQry+="         AND E5_TIPODOC <> 'ES'
		cQry+="			AND E5_TIPODOC != 'DC' " //POR SANGELLES DATA 04/01/2013, NรO PUXAR OS DESCONTOS
		cQry+="			AND E5_NUMERO = '"+AllTrim(SE1->E1_NUM)+"'   "
		cQry+="			AND E5_PARCELA = '"+AllTrim(SE1->E1_PARCELA)+"'   "
		cQry+="			AND E5_CLIFOR = '"+AllTrim(SE1->E1_CLIENTE)+"'   "
		cQry+="			AND E5_LOJA = '"+AllTrim(SE1->E1_LOJA)+"'   "
		
		cQry+="	     UNION ALL"
		
		//Compensacao simples
		cQry+="	     SELECT"
		cQry+="				 E5_SEQ,"
		cQry+="				 E5.R_E_C_N_O_ REG,"
		cQry+="				 E5_DATA,"
		cQry+="				 E5_NUMERO,"
		cQry+="				 E5_VALOR,"
		cQry+="				 'Credito Interno' E5_MOTBX,"
		cQry+="				 E5_DOCUMEN,"
		cQry+="				 E5_PARCELA,"
		cQry+="				 E5_PREFIXO,"
		cQry+="				 E5_HISTOR,"
		cQry+="				 E5_TIPODOC,"
		cQry+="				 E5_FILORIG"
		cQry+="	       FROM " + RetSqlName("SE5") + " E5"
		cQry+="       INNER JOIN " + RetSqlName("SE1") + " E1 ON (E5_NUMERO     = E1_NUM"
		cQry+="												   AND E5_PARCELA    = E1_PARCELA
		cQry+="												   AND E5_PREFIXO    = E1_PREFIXO
		cQry+="												   AND E5_CLIFOR   = E1_CLIENTE
		cQry+="												   AND E5_LOJA     = E1_LOJA
		cQry+="												   AND E5_TIPO     = E1_TIPO		
		cQry+="		  		   				                  AND E5.D_E_L_E_T_ = E1.D_E_L_E_T_)"
		cQry+="		  WHERE E5.D_E_L_E_T_ <> '*'"
		cQry+="		    AND E5_MOTBX     = 'CMP'"
		cQry+="		    AND E5_TIPODOC  IN ('CP', 'ES')"
		cQry+="		    AND E5_TIPO NOT IN ('NCC', 'RA')"
		cQry+="			AND E5_TIPODOC <> 'DC' " //POR SANGELLES DATA 04/01/2013, NรO PUXAR OS DESCONTOS
		cQry+="			AND E5_NUMERO = '"+AllTrim(SE1->E1_NUM)+"'   "
		cQry+="			AND E5_PARCELA = '"+AllTrim(SE1->E1_PARCELA)+"'   "
		cQry+="			AND E5_CLIFOR = '"+AllTrim(SE1->E1_CLIENTE)+"'   "
		cQry+="			AND E5_LOJA = '"+AllTrim(SE1->E1_LOJA)+"'   "
		
		cQry+="	     UNION ALL
		
		//Compensacao carteiras
		cQry+="	     SELECT"
		cQry+="				 E5_SEQ,"
		cQry+="				 E5.R_E_C_N_O_ REG,"
		cQry+="				 E5_DATA,"
		cQry+="				 E5_NUMERO,"
		cQry+="				 E5_VALOR,"
		cQry+="				 'Credito Interno' E5_MOTBX,"
		cQry+="				 E5_DOCUMEN,"
		cQry+="				 E5_PARCELA,"
		cQry+="				 E5_PREFIXO,"
		cQry+="				 E5_HISTOR,"
		cQry+="				 E5_TIPODOC,"
		cQry+="				 E5_FILORIG"
		cQry+="	       FROM " + RetSqlName("SE5") + " E5"
		cQry+="       INNER JOIN " + RetSqlName("SE1") + " E1 ON (E5_NUMERO     = E1_NUM"
		cQry+="												   AND E5_PARCELA    = E1_PARCELA
		cQry+="												   AND E5_PREFIXO    = E1_PREFIXO
		cQry+="												   AND E5_CLIFOR   = E1_CLIENTE
		cQry+="												   AND E5_LOJA     = E1_LOJA
		cQry+="												   AND E5_TIPO     = E1_TIPO		
		cQry+="		  		   				                  AND E5.D_E_L_E_T_  = E1.D_E_L_E_T_)"
		cQry+="		  WHERE E5.D_E_L_E_T_ <> '*'"
		cQry+="		    AND E5_MOTBX   = 'CEC'"
		cQry+="		    AND E5_TIPODOC <> 'JR'"
		cQry+="         AND E5_TIPODOC <> 'MT' "
		cQry+="			AND E5_TIPODOC <> 'DC' " //POR SANGELLES DATA 04/01/2013, NรO PUXAR OS DESCONTOS
		cQry+="			AND E5_NUMERO = '"+AllTrim(SE1->E1_NUM)+"'   "
		cQry+="			AND E5_PARCELA = '"+AllTrim(SE1->E1_PARCELA)+"'   "
		cQry+="			AND E5_CLIFOR = '"+AllTrim(SE1->E1_CLIENTE)+"'   "
		cQry+="			AND E5_LOJA = '"+AllTrim(SE1->E1_LOJA)+"'   "
		cQry+="			ORDER By E5_SEQ,"
		cQry+="				 	 REG "
		
		cQry := Changequery(cQry)
		TcQuery cQry New Alias "QRY" // Cria uma nova area com o resultado do query
		NTOTAL2 := 0
		IF QRY->(!EoF())
			While QRY->(!EoF())
				If (QRY->E5_SEQ == "01" .Or. Empty(QRY->E5_SEQ)) .And. ALLTRIM(QRY->E5_TIPODOC) == "E2"
					QRY->(dbSkip())
					Loop
				EndIf
				
				DO CASE
					CASE ALLTRIM(QRY->E5_MOTBX) == "Cheque"
						IF ALLTRIM(QRY->E5_TIPODOC) == "ES" .OR. ALLTRIM(QRY->E5_TIPODOC) == "E2"
							NCHEQUE -= QRY->E5_VALOR
						ELSE
							NCHEQUE += QRY->E5_VALOR
						ENDIF
						_CHISTCHE := QRY->E5_HISTOR
					CASE ALLTRIM(QRY->E5_MOTBX) == "Dinheiro"
						IF ALLTRIM(QRY->E5_TIPODOC) == "ES" .OR. ALLTRIM(QRY->E5_TIPODOC) == "E2"
							If Len(ADINHEI) > 0
								ADINHEI[Len(ADINHEI)][2]	-= QRY->E5_VALOR
							EndIf
						ELSE
							aAdd(ADINHEI, {QRY->E5_DATA, QRY->E5_VALOR, QRY->E5_HISTOR})
						ENDIF
					CASE ALLTRIM(QRY->E5_MOTBX) == "Credito Interno"
						IF ALLTRIM(QRY->E5_TIPODOC) == "ES" .OR. ALLTRIM(QRY->E5_TIPODOC) == "E2"
							NCREDIT -= QRY->E5_VALOR
						ELSE
							NCREDIT += QRY->E5_VALOR
						ENDIF
						_CHISTCRE := QRY->E5_HISTOR
				ENDCASE
				
				IF ALLTRIM(QRY->E5_TIPODOC) == "ES" .OR. ALLTRIM(QRY->E5_TIPODOC) == "E2"
					NTOTAL     -= QRY->E5_VALOR
					NTOTAL2    -= QRY->E5_VALOR
				ELSE
					NTOTAL     += QRY->E5_VALOR
					NTOTAL2    += QRY->E5_VALOR
				ENDIF
				DDATABAIXA := QRY->E5_DATA
				if Alltrim(QRY->E5_MOTBX)=="Cheque"  .Or. Alltrim(QRY->E5_MOTBX)=="Credito Interno"
					cQry:=""
					cQry:="		  SELECT"
					cQry+="				 E1_NUM, E1_PREFIXO, E1_TIPO, E1_PARCELA, E1_BCOCHQ, E1_AGECHQ, E1_CTACHQ, SUM(E1_VALOR) E1_VALOR, SUM(E1_SALDO) E1_SALDO"
					cQry+="		   FROM " + RetSqlName("SE1") + " E1
					cQry+="		  WHERE E1.D_E_L_E_T_ <> '*'
					//cQry+="			AND E1_NUM = '"+Alltrim(QRY->E5_DOCUMEN)+"'   "
					cQry+="			AND E1_CLIENTE = '"+AllTrim(SE1->E1_CLIENTE)+"'   "
					cQry+="			AND E1_LOJA = '"+AllTrim(SE1->E1_LOJA)+"'   "
					//cQry+="			AND E1_TIPO = 'NCC' "
					//cQry+="			AND E1_PREFIXO = 'LIQ' "
					if Alltrim(QRY->E5_MOTBX)=="Cheque"
						cQry+="			AND E1_NUMLIQ = '"+Alltrim(QRY->E5_DOCUMEN)+"'
					ELSE
						cQry+="			AND E1_PREFIXO = '"+ALLTRIM(SUBSTR(QRY->E5_DOCUMEN,1,3))+"'
						cQry+="			AND E1_NUM = '"+ALLTRIM(SUBSTR(QRY->E5_DOCUMEN,4,9))+"'
						cQry+="			AND E1_PARCELA = '"+ALLTRIM(SUBSTR(QRY->E5_DOCUMEN,13,3))+"'
						cQry+="			AND E1_TIPO = '"+ALLTRIM(SUBSTR(QRY->E5_DOCUMEN,16,3))+"'
					ENDIF
					cQry+="			Group By E1_NUM,E1_PREFIXO,E1_TIPO, E1_PARCELA, E1_BCOCHQ, E1_AGECHQ, E1_CTACHQ "
					
					MemoWrite("c:\temp\recfin"+str(nLin)+"sql.txt", cQry)
					
					
					cQry := Changequery(cQry)
					TcQuery cQry New Alias "QRY4" // Cria uma nova area com o resultado do query
					
					While QRY4->(!EoF())
						if QRY4->E1_TIPO=='NCC'
							IF QRY4->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO) != _CTITULO
								nTotNCC+=QRY4->E1_SALDO
								NumNCC:=""//allTrim(QRY4->E1_NUM)+" / "+QRY4->E1_PREFIXO
							ENDIF
						Else
							if QRY4->E1_TIPO=='CH '
								_NCHEQUE := ASCAN(aCheque,{|x|(X[1]+X[2]+X[3]+X[4]+X[5] == QRY4->E1_PREFIXO+QRY4->E1_NUM+QRY4->E1_BCOCHQ+QRY4->E1_AGECHQ+QRY4->E1_CTACHQ)})
								IF _NCHEQUE == 0
									AADD(aCheque,{QRY4->E1_PREFIXO, QRY4->E1_NUM, QRY4->E1_BCOCHQ, QRY4->E1_AGECHQ, QRY4->E1_CTACHQ, QRY4->E1_VALOR})
								ENDIF
							ELSE
								IF QRY4->E1_TIPO=='RA '
									IF QRY4->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO) != _CTITULO
										nTotNCC+=QRY4->E1_SALDO
									ENDIF
								ENDIF
							ENDIF
						Endif
						_CTITULO := QRY4->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO)
						Qry4->(DbSkip())
					EndDo
					
					Qry4->(dbCloseArea())
				EndIf
				QRY->(DBSKIP())
			ENDDO
			AADD(aTitulos,{SE1->E1_PREFIXO, SE1->E1_NUM, SE1->E1_PARCELA, SE1->E1_EMISSAO, SE1->E1_VENCTO, SE1->E1_TIPO, NTOTAL2, IIF(!EMPTY(SE1->E1_JUROS),SE1->E1_JUROS,SE1->E1_ACRESC), SE1->E1_MULTA, SE1->E1_DESCONT, SE1->E1_SALDO})
		ELSE
			ntotal := SE1->E1_SALDO
			AADD(aTitulos,{SE1->E1_PREFIXO, SE1->E1_NUM, SE1->E1_PARCELA, SE1->E1_EMISSAO, SE1->E1_VENCTO, SE1->E1_TIPO, SE1->E1_SALDO, SE1->E1_JUROS, SE1->E1_MULTA, SE1->E1_DESCONT, SE1->E1_SALDO})
		ENDIF
		
		QRY->(DBCLOSEAREA())
		
		//QRY2->(DBSKIP())
	ENDIF
	QRY2->(DBSKIP())
ENDDO
QRY2->(DBCLOSEAREA())

Cabecalho()

nLin+=100
oPrint:Say(nLin, 1150, "RECIBO", oFont14N,,,,2)
nLin+=100
NomCli:=Posicione("SA1",1,xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA,"A1_NOME")
Pessoa:=Posicione("SA1",1,xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA,"A1_PESSOA")
CGC:=Alltrim(Posicione("SA1",1,xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA,"A1_CGC"))
oPrint:Say(nLin, 150, "Recebemos de "+SE1->E1_CLIENTE+"/"+SE1->E1_LOJA+" - "+Alltrim(NomCli)+" - CNPJ: "+iif(Pessoa=="J",Transform(CGC,"@R 99.999.999/9999-99"),Transform(CGC,"@R 999.999.999-99"))+" a quantia supra de ", oFont10N)
nLin+=50
nLinExt:=nLin
nLin+= 50

cValExt:=Extenso(nTotal,.F.,1,"","1",.T.,.F.)
oPrint:Say(nLinExt, 150, Transform(nTotal,"@E 999,999.99")+"("+cValExt+"), verifique o hist๓rico abaixo para forma de pagamento:", oFont10N)

nLin+=30
oPrint:Say(nLin, 400, "Hist๓rico de Pagamentos do Tํtulo:", oFont10)
nLin+=50

//FOR NX := 1 TO 3
For nX := 1 to Len(aDinhei)
	IF ADINHEI[nX][2] > 0
		oPrint:Say(nLin, 420, "Dinheiro...: R$", oFont10)
		oPrint:Say(nLin, 620, Transform(ADINHEI[nX][2],"@E 9,999,999,999,999.99"), oFont10)
		oPrint:Say(nLin, 920, DTOC(STOD(ADINHEI[nX][1])), oFont10)
		oPrint:Say(nLin, 1100, "<---- "+ADINHEI[nX][3], oFont10)
		nLin+=50
	ENDIF
Next nX

IF NCHEQUE != 0
	oPrint:Say(nLin, 420, "Cheque...: R$", oFont10)
	oPrint:Say(nLin, 620, Transform(NCHEQUE,"@E 9,999,999,999,999.99"), oFont10)
	oPrint:Say(nLin, 920, DTOC(STOD(DDATABAIXA)), oFont10)
	oPrint:Say(nLin, 1100, "<---- "+_CHISTCHE, oFont10)
	nLin+=50
ENDIF

IF NCREDIT != 0
	oPrint:Say(nLin, 420, "Cr้dito Interno: R$", oFont10)
	oPrint:Say(nLin, 620, Transform(NCREDIT,"@E 9,999,999,999,999.99"), oFont10)
	oPrint:Say(nLin, 920, DTOC(STOD(DDATABAIXA)), oFont10)
	oPrint:Say(nLin, 1100, "<---- "+_CHISTCRE, oFont10)
	nLin+=50
ENDIF

oPrint:Line (nLin, 400, nLin, 1100)
oPrint:Say(nLin, 420, "Total"+"...: R$", oFont10)
oPrint:Say(nLin, 620, Transform(NTOTAL,"@E 9,999,999,999,999.99"), oFont10)
nLin+=50

nLin+=100
oPrint:Say(nLin, 150, "Referente ao(s) pagamentos do(s) documento(s) abaixo:", oFont10N)
nLin+=100

oPrint:Line (nLin, 150, nLin, 2300)
nLin+= 15
oPrint:Say(nLin, 150, "DOCUMENTO", oFont8N)
oPrint:Say(nLin, 500, "EMISSรO", oFont8N)
oPrint:Say(nLin, 750, "VENCIMENTO", oFont8N)
oPrint:Say(nLin, 1050, "FORMA", oFont8N)
oPrint:Say(nLin, 1250, "VALOR", oFont8N)
oPrint:Say(nLin, 1450, "JUROS", oFont8N)
oPrint:Say(nLin, 1650, "MULTA", oFont8N)
oPrint:Say(nLin, 1850, "DESCONTO", oFont8N)
oPrint:Say(nLin, 2100, "TOTAL REC.", oFont8N)
nLin+= 50
oPrint:Line (nLin, 150, nLin, 2300)
nLin+= 20

_NTOTTITU := 0
IF !EMPTY(ATITULOS)
	FOR NX := 1 TO LEN(aTitulos)
		oPrint:Say(nLin, 150, aTitulos[NX,1]+" - "+Rtrim(aTitulos[NX,2])+"/"+aTitulos[NX,3], oFont8N)
		oPrint:Say(nLin, 500, DTOC(aTitulos[NX,4]), oFont8N)
		oPrint:Say(nLin, 750, DTOC(aTitulos[NX,5]), oFont8N)
		oPrint:Say(nLin, 1050, aTitulos[NX,6], oFont8N)
		oPrint:Say(nLin, 1245, Transform(aTitulos[NX,7]-aTitulos[NX,8]-aTitulos[NX,9]+aTitulos[NX,10],"@E 999,999.99"), oFont8N)
		oPrint:Say(nLin, 1445, Transform(aTitulos[NX,8],"@E 999,999.99"), oFont8N)
		oPrint:Say(nLin, 1645, Transform(aTitulos[NX,9],"@E 999,999.99"), oFont8N)
		oPrint:Say(nLin, 1845, Transform(aTitulos[NX,10],"@E 999,999.99"), oFont8N)
		oPrint:Say(nLin, 2100, Transform(aTitulos[NX,7],"@E 999,999.99"), oFont8N)
		_NTOTTITU += aTitulos[NX,7]
		nLin+= 50
		if nLin>=2800
			Rod()
			Cabecalho()
		EndIf
	NEXT NX
	oPrint:Line (nLin, 150, nLin, 2300)
	oPrint:Say(nLin, 2100, Transform(_NTOTTITU,"@E 999,999.99"), oFont8N)
ENDIF

_NTOTCHEQUE := 0
if len(aCheque)>0
	nLin+=100
	oPrint:Say(nLin, 150, "Cheques Recebidos:", oFont8N)
	nLin+=50
	oPrint:Say(nLin, 200, "Cheque", oFont8N)
	oPrint:Say(nLin, 450, "Banco", oFont8N)
	oPrint:Say(nLin, 550, "Ag๊ncia", oFont8N)
	oPrint:Say(nLin, 650, "Conta", oFont8N)
	oPrint:Say(nLin, 850, "Valor", oFont8N)
	oPrint:Line(nLin+30, 150, nLin+30, 1100)
	nLin+=50
	For nX:=1 to len(aCheque)
		oPrint:Say(nLin, 200, aCheque[nX][1]+"-"+aCheque[nX][2], oFont8N)
		oPrint:Say(nLin, 450, aCheque[nX][3], oFont8N)
		oPrint:Say(nLin, 550, aCheque[nX][4], oFont8N)
		oPrint:Say(nLin, 650, aCheque[nX][5], oFont8N)
		oPrint:Say(nLin, 850, Transform(aCheque[nX][6],"@E 999,999.99"), oFont8N)
		nLin+=50
		_NTOTCHEQUE += aCheque[nX][6]
		if nLin>=3100
			Rod()
			Cabecalho()
		EndIf
	Next
	oPrint:Line(nLin, 150, nLin, 1100)
	oPrint:Say(nLin, 850, Transform(_NTOTCHEQUE,"@E 999,999.99"), oFont8N)
	
EndIf

nLin+=100

IF nTotNCC != 0
	oPrint:Say(nLin, 150, "Cr้dito interno gerado no recebimento: ", oFont10N)
	nLin+=100
	oPrint:Say(nLin, 150, NumNCC+" - R$ "+Transform(nTotNCC,"@E 9,999,999,999,999.99"), oFont10N)
	
	nLin+=100
ENDIF

if nLin>=3000
	Rod()
	Cabecalho()
EndIf

if nLin>=2800
	Rod()
	Cabecalho()
EndIf

cEmpNome := Alltrim(SM0->M0_NOMECOM)
cEmpCnpj := Transform(SM0->M0_CGC, "@R 99.999.999/9999-99")
cEmpEnd := Alltrim(SM0->M0_ENDCOB) + ", " + Alltrim(SM0->M0_COMPCOB) + ", " + Alltrim(SM0->M0_BAIRCOB) + ", " + Alltrim(SM0->M0_CIDCOB)+ "/" + Alltrim(SM0->M0_ESTCOB)

//oPrint:Say(nLin, 1150, "Aparecida de Goiโnia,"+strzero(day(dDataBase),2)+" de "+mesextenso(dDataBase)+" de "+strzero(year(dDataBase),4), oFont10N,,,,2)
oPrint:Say(nLin, 1150, Alltrim(SM0->M0_CIDCOB)+","+strzero(day(dDataBase),2)+" de "+mesextenso(dDataBase)+" de "+strzero(year(dDataBase),4), oFont10N,,,,2)
nLin+=300
oPrint:Say(nLin, 1150, "______________________________________________________________", oFont10N,,,,2)
nLin+=50
//oPrint:Say(nLin, 1150, "LUZTOL INDฺSTRIA QUอMICA LTDA", oFont14N,,,,2)
oPrint:Say(nLin, 1150, cEmpNome, oFont14N,,,,2)


Rod()

///////////////////////////////////////////////////////////////////////////////////////
////Visualiza a impressao
///////////////////////////////////////////////////////////////////////////////////////
oPrint:Preview()

Return


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณCabecalho บAutor  ณMicrosiga           บ Data ณ  01/11/11   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Funcao que monta o cabe็alho do relatorio                  บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                        บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function Cabecalho()

cEmpNome := Alltrim(SM0->M0_NOMECOM)
cEmpCnpj := Transform(SM0->M0_CGC, "@R 99.999.999/9999-99")
cEmpEnd := Alltrim(SM0->M0_ENDCOB) + ", " + Alltrim(SM0->M0_COMPCOB) + ", " + Alltrim(SM0->M0_BAIRCOB) + ", " + Alltrim(SM0->M0_CIDCOB)+ "/" + Alltrim(SM0->M0_ESTCOB)

oPrint:StartPage() // Inicia uma nova pagina
cStartPath := GetPvProfString(GetEnvServer(),"StartPath","ERROR",GetAdv97())
cStartPath += If(Right(cStartPath, 1) <> "\", "\", "")
nlin := 50
nLin+=100
//oPrint:SayBitmap(100, 150, cStartPath + "lgrl01.bmp", 200, 110)///Impressao da Logo
//oPrint:Say(nLin, 150, "LUZTOL INDฺSTRIA QUอMICA LTDA", oFont14N)
oPrint:Say(nLin, 150, cEmpNome, oFont14N)
oPrint:Say(nLin, 2100, "Pแgina: " + strzero(nPag,3), oFont8N)
nLin+=50
//oPrint:Say(nLin, 150, "Rua 14 QD. 13 LTS. 08-40 - Polo Empresarial Goiแs - Ap. de Goโnia - GO", oFont10N)
oPrint:Say(nLin, 150, cEmpEnd, oFont10N)
oPrint:Say(nLin, 2100, DTOC(dDatabase), oFont8N)
nLin+=50
oPrint:Say(nLin, 150, "Fone: +55 " +alltrim(SM0->M0_TEL), oFont10N)
oPrint:Say(nLin, 2100, TIME(), oFont8N)
oPrint:Say(nLin, 850, "", oFont14N)
nLin+=50
oPrint:Say(nLin, 150, "CNPJ: "+ cEmpCnpj , oFont10N)
nLin+=80
oPrint:Line (nLin, 150, nLin, 2300)
nLin+=30


Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ

ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณRod       บAutor  ณMicrosiga           บ Data ณ  01/11/11   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Funcao que monta o rodape do Relatorio                     บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                        บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function Rod()

cStartPath := GetPvProfString(GetEnvServer(),"StartPath","ERROR",GetAdv97())
cStartPath += If(Right(cStartPath, 1) <> "\", "\", "")
////

nLin:=3300
oPrint:Line (nLin, 150, nLin, 2300)
nLin+=20
oPrint:SayBitmap(nLin, 150, cStartPath + "logo_totvs.gif", 228, 050)///Impressao da Logo
oPrint:Say(nLin, 1100, "Microsiga Protheus", oFont10N)
oPrint:Say(nLin, 2100, TIME(), oFont8N)
nLin+=50
oPrint:Line (nLin, 150, nLin, 2300)
nPag++
oPrint:EndPage() // Finaliza a pagina

Return



Static Function AjustaSX1()

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณAjustaSx1   บAutor  ณMicrosiga         บ Data ณ  11/01/11   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Atualiza as peguntas na tabela SX1                         บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Local aHelpPor	:= {}
Local aHelpEng	:= {}
Local aHelpSpa	:= {}

PutSx1( "RTMKR002", "01","Pedido/Num. Orc?","Pedido/Num. Orc?","Pedido/Num. Orc?","mv_ch1","C",6,0,0,"G","","","","",;
"mv_par01"," ","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa)
PutSx1( "RTMKR002", "02","Filial?","Filial?","Filial?","mv_ch2","C",4,0,0,"G","","SM0","","",;
"mv_par02"," ","","","","","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa)
PutSx1( "RTMKR002", "03","Origem?","Origem?","Origem?","mv_ch3","N",1,0,0,"C","","","","",;
"mv_par03","Faturamento","","","","Loja","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa)

Return 
