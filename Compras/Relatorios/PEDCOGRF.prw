#include 'protheus.ch'
#include 'topconn.ch'
#define CPO_COMPL 'C8_XCOMPL'	// Campo do complemento da cotacao (SC8)


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหออออออัอออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณ LC13R    บAutor ณPedro Netoบ Data ณ  28/07/14   บฑฑ
ฑฑฬออออออออออุออออออออออสออออออฯอออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ PEDIDO DE COMPRAS (Emissao em formato Grafico)             บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ Compras                                                    บฑฑ
ฑฑฬออออออออออุออออออออออัอออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบDATA      ณ ANALISTA ณ MOTIVO                                          บฑฑ
ฑฑฬออออออออออุออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบ          ณ          ณ                                                 บฑฑ
ฑฑศออออออออออฯออออออออออฯอออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

// alterar o parametro MV_PCOMPRA e colocar PEDGRF para substituir a impressใo padrใo.

User Function PEDGRF()
Private	lEnd		:= .f.,;
		aAreaSC7	:= SC7->(GetArea()),;
		aAreaSA2	:= SA2->(GetArea()),;
		aAreaSA5	:= SA5->(GetArea()),;   
		aAreaSF4	:= SF4->(GetArea()),;
	 	cPerg		:= Padr('PEDGRF',10)


	 	//	aAreaSZF	:= SZF->(GetArea()),;

		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณAjusta os parametros.ณ
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
		AjustaSX1(cPerg)

		// Se a Impressใo Nใo Vier da Tela de Pedido de Compras entใo Efetua Pergunta de Parโmetros
		// Caso contrแrio entใo posiciona no pedido que foi clicado a op็ใo imprimir.

		If Upper(ProcName(2)) <> 'A120IMPRI'
           	If !Pergunte(cPerg,.t.)
           		Return
           	Endif

			Private	cNumPed  	:= mv_par01			// Numero do Pedido de Compras
			Private	lImpPrc		:= (mv_par02==2)	// Imprime os Precos ?
			Private	nTitulo 	:= mv_par03			// Titulo do Relatorio ?
			Private	cObserv1	:= mv_par04			// 1a Linha de Observacoes
			Private	cObserv2	:= mv_par05			// 2a Linha de Observacoes
			Private	cObserv3	:= mv_par06			// 3a Linha de Observacoes
			Private	cObserv4	:= mv_par07			// 4a Linha de Observacoes
			Private	lPrintCodFor:= (mv_par08==1)	// Imprime o Cvvvvvvvvvvvvvvvvvvvvvvvvvvvodigo do produto no fornecedor ?
		Else

			Private	cNumPed  	:= SC7->C7_NUM		// Numero do Pedido de Compras
			Private	lImpPrc		:= .t.	// Imprime os Precos ?
			Private	nTitulo 	:= 2			// Titulo do Relatorio ?
			Private	cObserv1	:= ''			// 1a Linha de Observacoes
			Private	cObserv2	:= ''			// 2a Linha de Observacoes
			Private	cObserv3	:= ''			// 3a Linha de Observacoes
			Private	cObserv4	:= ''			// 4a Linha de Observacoes
			Private	lPrintCodFor:= .f.	// Imprime o Codigo do produto no fornecedor ?
  		Endif

		DbSelectArea('SC7')
		SC7->(DbSetOrder(1))
		If	( ! SC7->(DbSeek(xFilial('SC7') + cNumPed)) )
			Help('',1,'PEDGRF',,OemToAnsi('Pedido nใo encontrado.'),1)
			Return .f.
		EndIf

		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณExecuta a rotina de impressao ณ
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
		Processa({ |lEnd| xPrintRel(),OemToAnsi('Gerando o relat๓rio.')}, OemToAnsi('Aguarde...'))
		
		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณRestaura a area anterior ao processamento. !ณ
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
		RestArea(aAreaSC7)
		RestArea(aAreaSA2)
		RestArea(aAreaSA5)
	 //	RestArea(aAreaSZF)
		RestArea(aAreaSF4)

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหออออออัอออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณ xPrintRelบAutor ณLuis Henrique Robustoบ Data ณ  10/09/04   บฑฑ
ฑฑฬออออออออออุออออออออออสออออออฯอออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Imprime a Duplicata...                                     บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ Funcao Principal                                           บฑฑ
ฑฑฬออออออออออุออออออออออัอออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบDATA      ณ ANALISTA ณ MOTIVO                                          บฑฑ
ฑฑฬออออออออออุออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบ          ณ          ณ                                                 บฑฑ
ฑฑศออออออออออฯออออออออออฯอออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function xPrintRel()
local _nt 		:= 0
local i 		:= 0
local _nlinhas 	:= 0
Local aBens		:= {}
Local nBem		:= 0
Local aCompl	:= {}
Local aTot		:= {}
Local aObs		:= {}
Local aCusto	:= {}
Local aVlrBem	:= {}
Local cLinOS	:= ''
Local cLinCC	:= ''
Local cObs		:= ''
Local cPagto	:= ''
Local nIni		:= 0
Local nTop		:= 0
Local nAltRow	:= 0
Local nAltItem	:= 0
Local nAltCond	:= 0
Local nAltTot	:= 0
Local nAltFim	:= 0
Local nTotal	:= 0
Private	oPrint		:= TMSPrinter():New(OemToAnsi('Pedido de Compras')),;
		oBrush		:= TBrush():New(,4),;
		oBrushCz	:= TBrush():New(,RGB(225,225,225)),;
		oPen		:= TPen():New(0,5,CLR_BLACK),;
		cFileLogo	:= GetSrvProfString('Startpath','') + 'LOGORECH02' + '.BMP',;
		oFont07		:= TFont():New('Courier New',07,07,,.F.,,,,.T.,.F.),;
		oFont08		:= TFont():New('Courier New',08,08,,.F.,,,,.T.,.F.),;
		oFont09		:= TFont():New('Tahoma',09,09,,.F.,,,,.T.,.F.),;
		oFont10		:= TFont():New('Tahoma',10,10,,.F.,,,,.T.,.F.),;
		oFont10n	:= TFont():New('Courier New',10,10,,.T.,,,,.T.,.F.),;
		oFont11		:= TFont():New('Tahoma',11,11,,.F.,,,,.T.,.F.),;
		oFont11b	:= TFont():New('Tahoma',11,11,,.T.,,,,.T.,.F.),;
		oFont12		:= TFont():New('Tahoma',09,09,,.T.,,,,.T.,.F.),;
		oFont12n	:= TFont():New('Tahoma',09,09,,.F.,,,,.T.,.F.),;
		oFont13		:= TFont():New('Tahoma',13,13,,.T.,,,,.T.,.F.),;
		oFont14		:= TFont():New('Tahoma',14,14,,.T.,,,,.T.,.F.),;
		oFont15		:= TFont():New('Courier New',15,15,,.T.,,,,.T.,.F.),;
		oFont18		:= TFont():New('Arial',18,18,,.T.,,,,.T.,.T.),;
		oFont16		:= TFont():New('Arial',14,14,,.T.,,,,.T.,.F.),;
		oFont20		:= TFont():New('Arial',20,20,,.F.,,,,.T.,.F.),;
		oFont20n	:= TFont():New('Arial',20,20,,.T.,,,,.T.,.F.),;
		oFont22		:= TFont():New('Arial',22,22,,.T.,,,,.T.,.F.)


	oPrint:Setup()

	cFileLogo := "lgrl" + cEmpAnt + ".bmp"
	//cFileLogo := "lgrlpc" + ".bmp"

	If !File(cFileLogo)
		cFileLogo := "lgrl" + cEmpAnt + cFilAnt + ".bmp"
	EndIf

	Private	lFlag		:= .t.,;	// Controla a impressao do fornecedor
			nLinha		:= 3000,;	// Controla a linha por extenso
			nLinFim		:= 0,;		// Linha final para montar a caixa dos itens
			nPagina		:= 0,;		// Numero da pagina atual
			lPrintDesTab:= .f.,;	// Imprime a Descricao da tabela (a cada nova pagina)
			cRepres		:= Space(80)

	Private	_nQtdReg	:= 0,;		// Numero de registros para intruir a regua
			_nValMerc 	:= 0,;		// Valor das mercadorias
			_nValIPI	:= 0,;		// Valor do I.P.I.
			_nValDesc	:= 0,;		// Valor de Desconto
			_nTotAcr	:= 0,;		// Valor total de acrescimo
			_nTotSeg	:= 0,;		// Valor de Seguro
			_nTotFre	:= 0,;		// Valor de Frete
			_nTotIcmsRet:= 0		// Valor do ICMS Retido

	Private cStartPath             //Pedro Neto

		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณPosiciona nos arquivos necessarios. !ณ
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
		DbSelectArea('SA2')
		SA2->(DbSetOrder(1))
		If	! SA2->(DbSeek(xFilial('SA2')+SC7->(C7_FORNECE+C7_LOJA)))
			Help('',1,'REGNOIS')
			Return .f.
		EndIf

		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณDefine que a impressao deve ser RETRATOณ
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
		oPrint:SetPortrait()

		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณMonta query !ณ    //SC7.C7_CODPRF,
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤู

		//cSELECT :=	'SC7.C7_FILIAL, SC7.C7_NUM, SC7.C7_EMISSAO, SC7.C7_FORNECE, SC7.C7_LOJA, SC7.C7_COND, SC7.C7_CONTATO, ISNULL(CONVERT(VARCHAR(1024),CONVERT(VARBINARY(1024),SC7.C7_OBSM)),'') , '+;
		cSELECT :=	"SC7.C7_FILIAL, SC7.C7_NUM, SC7.C7_EMISSAO, SC7.C7_FORNECE, SC7.C7_LOJA, SC7.C7_COND, SC7.C7_CONTATO, ISNULL(CONVERT(VARCHAR(2047), CONVERT(VARBINARY(2047), C7_OBSM)),'') AS OBSM, "+; //ISNULL(CONVERT(VARCHAR(1024),CONVERT(VARBINARY(1024), C7_OBS)),'') AS OBSM, "+;
					'SC7.C7_ITEM, SC7.C7_UM, SC7.C7_PRODUTO, SC7.C7_DESCRI, SC7.C7_LOCAL, SC7.C7_QUANT, '+;
					'SC7.C7_PRECO, SC7.C7_IPI, SC7.C7_TOTAL, SC7.C7_VLDESC, SC7.C7_DESPESA, '+;
					'SC7.C7_SEGURO, SC7.C7_VALFRE, SC7.C7_TES, SC7.C7_LOCAL, SC7.C7_ICMSRET, SC7.C7_DATPRF, '+;
					'SC1.C1_OP, SC1.C1_XESTOQ, SC7.C7_NUMSC, SC7.C7_ITEMSC, SC7.C7_XESTOQ, SC7.C7_CC, '+;
					"ISNULL((SELECT MAX(SC8.R_E_C_N_O_) FROM " + RetSqlName('SC8') + " SC8 "+;	// Proposta vencedora da cotacao
					"WHERE SC8.D_E_L_E_T_ = ' ' AND SC8.C8_FILIAL = SC7.C7_FILIAL AND SC8.C8_NUM = SC7.C7_NUMCOT "+;
					"AND SC8.C8_FORNECE = SC7.C7_FORNECE AND SC8.C8_LOJA = SC7.C7_LOJA "+;
					"AND SC8.C8_NUMPED = SC7.C7_NUM AND SC8.C8_ITEMPED = SC7.C7_ITEM),0) AS SC8REC "

		//cSELECT :=	"SC7.C7_FILIAL, SC7.C7_NUM, SC7.C7_EMISSAO, SC7.C7_FORNECE, SC7.C7_LOJA, SC7.C7_COND, SC7.C7_CONTATO, ISNULL(CONVERT(VARCHAR(1024),CONVERT(VARBINARY(1024), C7_OBS)),'') AS OBSM"
					//SC7.C7_ITEM, SC7.C7_UM, SC7.C7_PRODUTO, SC7.C7_DESCRI, SC7.C7_QUANT,
					//SC7.C7_PRECO, SC7.C7_IPI, SC7.C7_TOTAL, SC7.C7_VLDESC, SC7.C7_DESPESA,
					//SC7.C7_SEGURO, SC7.C7_VALFRE, SC7.C7_TES, SC7.C7_ICMSRET, SC7.C7_DATPRF
		cFROM   :=	RetSqlName('SC7') + ' SC7 '

		cLEFT	:= retSqlName("SC1") + " SC1 ON (SC1.D_E_L_E_T_ = ' ' AND SC1.C1_FILIAL = SC7.C7_FILIAL "
		cLEFT   += " AND SC1.C1_NUM = SC7.C7_NUMSC AND SC1.C1_ITEM = SC7.C7_ITEMSC AND SC7.C7_TIPO='1' ) "

		cWHERE  :=	'SC7.D_E_L_E_T_ <>   '+CHR(39) + '*'            +CHR(39) + ' AND '+;
					'SC7.C7_FILIAL  =    '+CHR(39) + xFilial('SC7') +CHR(39) + ' AND '+;
					'SC7.C7_NUM     =    '+CHR(39) + cNumPed        +CHR(39)

		cORDER  :=	'SC7.C7_FILIAL, SC7.C7_ITEM '

		cQuery  :=	' SELECT '   + cSELECT + ;
					' FROM '     + cFROM   + ;
					' LEFT JOIN '+ cLEFT   + ;
					' WHERE '    + cWHERE  + ;
					' ORDER BY ' + cORDER

		TCQUERY cQuery NEW ALIAS 'TRA'

		TcSetField('TRA','C7_DATPRF','D')

		If	! USED()
			MsgBox(cQuery+'. Query errada','Erro!!!','STOP')
		EndIf

		DbSelectArea('TRA')
		Count to _nQtdReg
		ProcRegua(_nQtdReg)
		TRA->(DbGoTop())


      cObServ := ''
		While 	TRA->( ! Eof() )

				xVerPag()

				If	( lFlag )
					//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
					//ณFornecedor / Numero    ณ
					//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
					xCabFor()
					lFlag := .f.
				EndIf

				//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
				//ณPrepara o conteudo do item antes de imprimir para  ณ
				//ณsaber a altura total e quebrar a pagina se precisarณ
				//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
				SB1->(dbSetOrder(1), dbSeek(xFilial("SB1")+TRA->C7_PRODUTO))
				If !SB5->(dbSetOrder(1), dbSeek(xFilial("SB5")+TRA->C7_PRODUTO))
					cDesc := AllTrim(SB1->B1_DESC)
				Else
					cDesc := AllTrim(SB5->B5_CEME)
				Endif
				_nLinhas := Max(1,MlCount(cDesc,45))
				nAltRow  := 13 + (_nLinhas * 42)

				aCompl := xCompl(TRA->SC8REC)

				if !Empty(TRA->C1_OP)
					aHistoric := U_fBusSTL(TRA->C7_FILIAL, TRA->C1_OP,TRA->C7_PRODUTO)
					cCodbem := Posicione("STJ",1,TRA->C7_FILIAL+substr(TRA->C1_OP,1,6),"TJ_CODBEM")
					cAno    := Posicione("ST9",1,TRA->C7_FILIAL+cCodBem,"T9_ANOMOD")
					cModelo := Posicione("ST9",1,TRA->C7_FILIAL+cCodBem,"T9_MODELO")

					cLinOS := "OS: "+substr(TRA->C1_OP,1,6)+" Bem: "+alltrim(cCodbem)+;
						if(Empty(cAno),""," - "+alltrim(cAno))+if(Empty(cModelo),""," - "+alltrim(cModelo))+" | "+;
						if(aHistoric[1] = 0,"1ช Compra","ฺlt.: "+dtoc(aHistoric[2])+;
						   " Qt: "+alltrim(transform(aHistoric[1],"@E 9999.99"))+;
						   " Vlr: "+alltrim(transform(aHistoric[3],"@E 999,999.99")))

					if Ascan(aBens, cCodbem) = 0
						aAdd(aBens,cCodbem)
					endif
				else
					// Busca itens que nใo sใo OS Hist๓rico de todos os produtos / Armaz้m
					aHistoric := fBuscaCom(TRA->C7_FILIAL, TRA->C7_PRODUTO, TRA->C7_LOCAL)

					cLinOS := if(aHistoric[1] == 0,"1ช Compra","ฺlt.: "+dtoc(aHistoric[2])+;
						   " Qt: "+alltrim(transform(aHistoric[1],"@E 99,999.999"))+;
						   " Vlr: "+alltrim(transform(aHistoric[3],"@E 999,999.999")))
				endif

				cLinCC := "CC: "+alltrim(TRA->C7_CC)+" - "+;
					alltrim(Posicione("CTT",1,xFilial("CTT")+TRA->C7_CC,"CTT_DESC01"))+" | Estoque SC: "+;
					if(TRA->C1_XESTOQ="S","Sim","Nใo")+ if(Empty(TRA->C7_XESTOQ),"",IF(TRA->C7_XESTOQ="S"," PC: Sim"," PC: Nใo"))

				nAltItem := nAltRow + 5 + (Len(aCompl) * 40) + 64 + 8
				xQuebra(nAltItem + If(lPrintDesTab,55,0))

				If	( lPrintDesTab )
					xTabCab()
				EndIf

				//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
				//ณLinha principal do item ณ
				//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
				nIni := nLinha
				xColunas(nIni,nIni+nAltRow)

				oPrint:Say(nIni+5,0110,Right(TRA->C7_ITEM,2),oFont09)
				If	( lPrintCodFor )
					DbSelectArea('SA5')
					SA5->(DbSetOrder(1))
					If	SA5->(DbSeek(xFilial('SA5') + SA2->A2_COD + SA2->A2_LOJA + TRA->C7_PRODUTO)) .and. ( ! Empty(SA5->A5_CODPRF) )
						oPrint:Say(nIni+5,0168,SA5->A5_CODPRF,oFont09)
					Else
						oPrint:Say(nIni+5,0168,TRA->C7_PRODUTO,oFont09)
					EndIf
				Else
					oPrint:Say(nIni+5,0168,TRA->C7_PRODUTO,oFont09)
				EndIf
				oPrint:Say(nIni+5,1228,TRA->C7_UM,oFont09)
				oPrint:Say(nIni+5,1447,xDtCurta(TRA->C7_DATPRF),oFont09,,,,1)
				oPrint:Say(nIni+5,1670,AllTrim(TransForm(TRA->C7_QUANT,'@E 99,999.99')),oFont12n,,,,1)

				If	( lImpPrc )
					oPrint:Say(nIni+5,1840,AllTrim(TransForm(TRA->C7_PRECO,'@E 999,999.99')),oFont12n,,,,1)
					oPrint:Say(nIni+5,1990,AllTrim(TransForm(TRA->C7_IPI,'@E 99.99')),oFont12n,,,,1)
					oPrint:Say(nIni+5,2290,AllTrim(TransForm(TRA->C7_TOTAL,'@E 999,999.99')),oFont12,,,,1)
				EndIf

				For _nT := 1 To _nLinhas
					oPrint:Say(nIni+5+((_nT-1)*42),0320,Capital(MemoLine(cDesc,45,_nT)),oFont09,,0)
				Next _nT

				nLinha += nAltRow
				oPrint:Line(nLinha,100,nLinha,2300)

				//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
				//ณDetalhe: complemento da cotacao, OS/Bem e CC  ณ
				//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
				nIni := nLinha
				nLinha += 5
				If	( Len(aCompl) > 0 )
					oPrint:FillRect({nLinha,0315,nLinha+(Len(aCompl)*40),2295},oBrushCz)
					oPrint:Say(nLinha,0320,'Marca:',oFont12)
					For _nT := 1 To Len(aCompl)
						oPrint:Say(nLinha,0440,aCompl[_nT],oFont09)
						nLinha += 40
					Next _nT
				EndIf
				oPrint:Say(nLinha,0320,cLinOS,oFont08,,0)
				nLinha += 32
				oPrint:Say(nLinha,0320,cLinCC,oFont08,,0)
				nLinha += 40

				oPrint:Line(nIni,100,nLinha,100)
				oPrint:Line(nIni,2300,nLinha,2300)
				oPrint:Line(nLinha,100,nLinha,2300)

				_nValMerc 		+= TRA->C7_TOTAL
				_nValIPI		+= (TRA->C7_TOTAL * TRA->C7_IPI) / 100
				_nValDesc		+= TRA->C7_VLDESC
				_nTotAcr		+= TRA->C7_DESPESA
				_nTotSeg		+= TRA->C7_SEGURO
				_nTotFre		+= TRA->C7_VALFRE

				If	( Empty(TRA->C7_TES) )
					_nTotIcmsRet	+= TRA->C7_ICMSRET
				Else
					DbSelectArea('SF4')
					SF4->(DbSetOrder(1))
					If	SF4->(DbSeek(xFilial('SF4') + TRA->C7_TES))
						If	( AllTrim(SF4->F4_INCSOL) == 'S' )
							_nTotIcmsRet	+= TRA->C7_ICMSRET
						EndIf
					EndIf
				EndIf

				//cObserv += AllTrim(TRA->C7_OBS)+' '   //ALTERADO PARA NAO PEGAR O CAMPO PADRAO DO SISTEMA
				// Evita repetir a mesma observacao quando ela esta em todos os itens
				If	( ! Empty(TRA->OBSM) ) .and. ! ( AllTrim(TRA->OBSM) $ cObserv )
					cObserv += AllTrim(TRA->OBSM) + ' '
				EndIf

			IncProc()
			DbSelectArea('TRA')
			TRA->(DbSkip())

		End

		xVerPag()

		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณMonta as linhas de TOTAIS    ณ
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
		If	( lImpPrc )
			aAdd(aTot,{'Valor Mercadorias',_nValMerc})
			If	( _nValIpi > 0 )
				aAdd(aTot,{'Valor de I. P. I. (+)',_nValIpi})
			EndIf
			If	( _nValDesc > 0 )
				aAdd(aTot,{'Valor de Desconto (-)',_nValDesc})
			EndIf
			If	( _nTotAcr > 0 )
				aAdd(aTot,{'Valor de Acresc. (+)',_nTotAcr})
			EndIf
			If	( _nTotSeg > 0 )
				aAdd(aTot,{'Valor de Seguro (+)',_nTotSeg})
			EndIf
			If	( _nTotFre > 0 )
				aAdd(aTot,{'Valor de Frete (+)',_nTotFre})
			EndIf
			If	( _nTotIcmsRet > 0 )
				aAdd(aTot,{'Valor de ICMS Retido',_nTotIcmsRet})
			EndIf
		EndIf
		nTotal  := _nValMerc + _nValIPI - _nValDesc + _nTotAcr + _nTotSeg + _nTotFre + _nTotIcmsRet
		nAltTot := (Len(aTot) + 1) * 70

		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณCondicoes do pedido: pagamento e observacoes  ณ
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
		cPagto := '_____________________'
		If !Empty(SC7->C7_COND)
			If SE4->(dbSetOrder(1), dbSeek(xFilial("SE4")+SC7->C7_COND))
				cPagto := Left(AllTrim(SE4->E4_CODIGO) + ' - ' + AllTrim(SE4->E4_DESCRI),45)
			Endif
		Endif

		cObs := AllTrim(cObserv)
		If	Empty(cObs)	// Observacoes informadas nos parametros
			cObs := AllTrim(AllTrim(cObserv1)+' '+AllTrim(cObserv2)+' '+AllTrim(cObserv3)+' '+AllTrim(cObserv4))
		EndIf
		For i := 1 To Min(MlCount(cObs,40),20)
			aAdd(aObs,AllTrim(MemoLine(cObs,40,i)))
		Next i
		If	Empty(aObs)
			aAdd(aObs,'')
		EndIf
		nAltCond := 50 + 15 + 50 + (Len(aObs) * 45) + 15

		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณCusto dos bens da OS ณ
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
		for nBem := 1 to len(aBens)
			aVlrBem := U_fBuscaSt9(aBens[nBem])
			if aVlrBem[2] > 0
				aAdd(aCusto,alltrim(aBens[nBem])+" = R$ "+alltrim(transform(aVlrBem[1],"@e 999,999.99")) + " / R$ "+alltrim(transform(aVlrBem[2],"@e 999,999,999.99")))
			endif
		next

		nAltFim := 15 + Max(nAltCond,nAltTot) + 15 + If(Len(aCusto) > 0, Int((Len(aCusto)+1)/2) * 50 + 15, 0) + 10
		xQuebra(nAltFim)

		nLinha += 15
		nIni := nLinha

		// Quadro das condicoes
		oPrint:FillRect({nIni,0100,nIni+50,1340},oBrushCz)
		oPrint:Box(nIni,0100,nIni+nAltCond,1340)
		oPrint:Line(nIni+50,0100,nIni+50,1340)
		oPrint:Say(nIni+6,0115,OemToAnsi('CONDIวีES DO PEDIDO'),oFont12)
		oPrint:Say(nIni+65,0115,'Pagamento:',oFont11b)
		oPrint:Say(nIni+65,0345,cPagto,oFont11)
		oPrint:Say(nIni+115,0115,OemToAnsi('Observa็๕es/USO:'),oFont11b)
		For i := 1 To Len(aObs)
			oPrint:Say(nIni+115+((i-1)*45),0470,aObs[i],oFont11)
		Next i

		// Quadro dos totais
		For i := 1 To Len(aTot)
			nTop := nIni + ((i-1) * 70)
			oPrint:Box(nTop,1390,nTop+70,2300)
			oPrint:Line(nTop,1840,nTop+70,1840)
			oPrint:Say(nTop+15,1405,aTot[i,1],oFont10)
			oPrint:Say(nTop+12,2285,TransForm(aTot[i,2],'@E 9,999,999.99'),oFont11,,,,1)
		Next i
		nTop := nIni + (Len(aTot) * 70)
		oPrint:FillRect({nTop,1390,nTop+70,2300},oBrushCz)
		oPrint:Box(nTop,1390,nTop+70,2300)
		oPrint:Line(nTop,1840,nTop+70,1840)
		oPrint:Say(nTop+18,1405,'VALOR TOTAL',oFont12)
		If	( lImpPrc )
			oPrint:Say(nTop+6,2285,TransForm(nTotal,'@E 9,999,999.99'),oFont14,,,,1)
		EndIf

		nLinha := nIni + Max(nAltCond,nAltTot) + 15

		// Custo do bem (2 por linha)
		If	( Len(aCusto) > 0 )
			oPrint:Say(nLinha,0100,'Custo do bem:',oFont11b)
			For nBem := 1 To Len(aCusto)
				oPrint:Say(nLinha,If(nBem % 2 == 1,0390,1340),aCusto[nBem],oFont11)
				If	( nBem % 2 == 0 ) .and. ( nBem < Len(aCusto) )
					nLinha += 50
				EndIf
			Next nBem
			nLinha += 65
		EndIf

		oPrint:Line(nLinha,0100,nLinha,2300)
		nLinha += 10

		TRA->(DbCloseArea())

		xRodape()


		If !Empty(_nQtdReg)
			//U_EPed(cNumPed,'')
		Endif

		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณImprime em Video, e finaliza a impressao. !ณ
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
		oPrint:Preview()

Return

user function fBuscaSt9(cBem)
	local aRet 		:= {0,0}
	Local cQuery	:= ""
	Local cAliasTop	:= getNextAlias()
	Local dDataIni	:= firstday(firstday(dDataBase) - 90)
	Local nTotDias	:= dDatabase - dDataini

	cQuery := "SELECT TJ_CODBEM, SUM(TJ_CUSTMDO+TJ_CUSTMAT+TJ_CUSTMAA+TJ_CUSTMAS+TJ_CUSTTER) AS CUSTO3M, 0 AS CUSTOTOT "
	cQuery += "FROM "+retSqlName("STJ") + " STJ "
	cQuery += "WHERE D_E_L_E_T_ = ' ' AND TJ_CODBEM = '"+cBem+"' AND TJ_TERMINO = 'S' AND "
	cQuery += "TJ_DTPRINI BETWEEN '"+dtos(dDataIni)+"' AND '"+dtos(ddatabase)+"' "
//	cQuery += "DATEADD(MONTH,-3, DATEADD(m, DATEDIFF(m, 0, GETDATE()), 0))  AND DATEADD(m, DATEDIFF(m, 0, GETDATE()), -1) "
	cQuery += "GROUP BY TJ_CODBEM "
	cQuery += "UNION "
	cQuery += "SELECT TJ_CODBEM, 0  AS CUSTO3M, SUM(TJ_CUSTMDO+TJ_CUSTMAT+TJ_CUSTMAA+TJ_CUSTMAS+TJ_CUSTTER) AS CUSTO3M "
	cQuery += "FROM "+retSqlName("STJ") + " STJ "
	cQuery += "WHERE D_E_L_E_T_ = ' '  AND TJ_CODBEM = '"+cBem+"' AND TJ_TERMINO = 'S' "
	cQuery += "GROUP BY TJ_CODBEM "
	cQuery += "ORDER BY TJ_CODBEM "
    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasTop,.T.,.T.)    

	(cAliasTop)->(DbGoTop())
	do while (cAliasTop)->(!Eof())
		aRet[1] += (cAliasTop)->CUSTO3M
		aRet[2] += (cAliasTop)->CUSTOTOT

		(cAliasTop)->(DbSkip())
	enddo

	aRet[1] := (aRet[1] / nTotDias) * 30
	(cAliasTop)->(DbCloseArea())

return(aRet)

user function fBusSTL(cFilSC7, cOP, cProduto)
	local aRet 		:= {0,"",0}
	Local cQuery	:= ""
	Local cAliasTop	:= getNextAlias()
	Local cOS		:= substr(cOP,1,6)
	Local cBem		:= Posicione("STJ",1,cFilSC7+substr(cOP,1,6),"TJ_CODBEM")

	cQuery := "SELECT TOP 1 STL.TL_CODIGO, STL.TL_QUANTID, STL.TL_CUSTO, STL.TL_DTFIM "
	cQuery += "FROM "+retsqlname("STL") + " STL "
	cQuery += "INNER JOIN "+retSqlName("STJ") + " STJ ON (STJ.D_E_L_E_T_ = ' ' "
	cQuery += "AND STJ.TJ_FILIAL = STL.TL_FILIAL AND STJ.TJ_ORDEM = STL.TL_ORDEM "
	cQuery += "AND STJ.TJ_CODBEM = '"+cBem+"' )"
	cQuery += "WHERE STL.D_E_L_E_T_ = ' ' AND STL.TL_CODIGO = '"+cProduto+"' "
	cQuery += "AND STL.TL_ORDEM <> '"+cOS+"' "
	cQuery += "ORDER BY STL.TL_DTFIM DESC "
    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasTop,.T.,.T.)    

	(cAliasTop)->(DbGoTop())
	do while (cAliasTop)->(!Eof())
		aRet[1] := (cAliasTop)->TL_QUANTID
		aRet[2] := stoD((cAliasTop)->TL_DTFIM)
		aRet[3] := (cAliasTop)->TL_CUSTO / (cAliasTop)->TL_QUANTID

		(cAliasTop)->(DbSkip())
	enddo

	(cAliasTop)->(DbCloseArea())

return(aRet)

//busca hist๓rio de compras de produtos sem OS
static function fBuscaCom(cFilSC7, cProduto, cLocal)
	local aRet 		:= {0,"",0}
	Local cQuery	:= ""
	Local cAliasTop	:= getNextAlias()

	cQuery := "SELECT TOP 1 SD1.D1_COD, SD1.D1_QUANT, SD1.D1_VUNIT, SD1.D1_DTDIGIT "
	cQuery += "FROM "+retSqlName("SD1") + " SD1 "
	cQuery += "WHERE SD1.D_E_L_E_T_ = ' ' "
	cQuery += "AND SD1.D1_COD = '"+cProduto+"' "
	cQuery += "AND SD1.D1_LOCAL = '"+cLocal+"' "
	cQuery += "AND SD1.D1_FILIAL = '"+cFilSC7+"' "
	cQuery += "AND SD1.D1_TES <> '   ' "
	cQuery += "ORDER BY SD1.D1_DTDIGIT DESC "
    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasTop,.T.,.T.)    

	(cAliasTop)->(DbGoTop())
	do while (cAliasTop)->(!Eof())
		aRet[1] := (cAliasTop)->D1_QUANT
		aRet[2] := stoD((cAliasTop)->D1_DTDIGIT)
		aRet[3] := (cAliasTop)->D1_VUNIT

		(cAliasTop)->(DbSkip())
	enddo

	(cAliasTop)->(DbCloseArea())

return(aRet)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหออออออัอออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณ xCabec() บAutor ณLuis Henrique Robustoบ Data ณ  25/10/04   บฑฑ
ฑฑฬออออออออออุออออออออออสออออออฯอออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Imprime o Cabecalho do relatorio...                        บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ Funcao Principal                                           บฑฑ
ฑฑฬออออออออออุออออออออออัอออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบDATA      ณ ANALISTA ณ  MOTIVO                                         บฑฑ
ฑฑฬออออออออออุออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบ          ณ          ณ                                                 บฑฑ
ฑฑศออออออออออฯออออออออออฯอออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function xCabec()
Local cTitRel := ''

		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณImprime o cabecalho da empresa. !ณ
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

		SM0->(DbSetOrder(1))
		SM0->(DbSeek(cEmpAnt+SC7->C7_FILENT))

		oPrint:SayBitmap(0050,0100,cFileLogo,0560,0280)  // Area da logo: 560 x 280 (largura x altura)
		// Bloco da empresa alinhado a esquerda, logo apos a logo (coluna 760)
		oPrint:Say(0050,0760,AllTrim(Upper(SM0->M0_NOMECOM)),oFont13)
		oPrint:Say(0115,0760,AllTrim(SM0->M0_ENDCOB)+'  -  '+Capital(AllTrim(SM0->M0_CIDCOB))+'/'+AllTrim(SM0->M0_ESTCOB)+'  -  CEP '+AllTrim(TransForm(SM0->M0_CEPCOB,'@R 99.999-999')),oFont10)
		oPrint:Say(0165,0760,'CNPJ: '+TransForm(SM0->M0_CGC,'@R 99.999.999/9999-99'),oFont12)
		oPrint:Say(0165,1260,'IE: '+AllTrim(SM0->M0_INSC),oFont12)
		if  cEmpAnt == "01"
			oPrint:Say(0210,0760,'www.quebecambiental.com.br'+'  -  Fone '+TransForm(AllTrim(SM0->M0_TEL),"@R (999) 9999-9999"),oFont10)
		else
			oPrint:Say(0210,0760,'www.consorciolimpagyn.com.br'+'  -  Fone '+TransForm(AllTrim(SM0->M0_TEL),"@R (999) 9999-9999"),oFont10)
		endif

		oPrint:Line(0265,0760,0265,2300)
		oPrint:Say(0280,0760,"Armaz้m: "+AllTrim(Posicione("NNR",1,xFilial("NNR")+SC7->C7_LOCAL,"NNR_DESCRI")),oFont12) //Pedro Neto

		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณTitulo do Relatorioณ
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
		cTitRel := If(nTitulo == 1,OemToAnsi('Cota็ใo de Compras'),OemToAnsi('Pedido de Compras'))
		If	( nPagina > 1 )
			oPrint:Say(0395,0455,cTitRel,oFont22)
			oPrint:Say(0425,1262,'- PC '+AllTrim(SC7->C7_NUM)+OemToAnsi(' (continua็ใo)'),oFont16)
		Else
			oPrint:Say(0395,1200,cTitRel,oFont22,,,,2)
		EndIf

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหออออออัอออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณ xRodape()บAutor ณLuis Henrique Robustoบ Data ณ  25/10/04   บฑฑ
ฑฑฬออออออออออุออออออออออสออออออฯอออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Imprime o Rodape do Relatorio....                          บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ Funcao Principal                                           บฑฑ
ฑฑฬออออออออออุออออออออออัอออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบDATA      ณ ANALISTA ณ  MOTIVO                                         บฑฑ
ฑฑฬออออออออออุออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบ          ณ          ณ                                                 บฑฑ
ฑฑศออออออออออฯออออออออออฯอออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function xRodape()
      
//TESTE PEDRO 
    	
    
    	cComprador:= ""
		cAlter	  := ""
		cAprov	  := ""
		lNewAlc	  := .F.
		lLiber 	  := .F.
		
		dbSelectArea("SC7")
		//If !Empty(SC7->C7_APROV)
			
			lNewAlc := .T.
			cComprador := UsrFullName(SC7->C7_USER) 
			If SC7->C7_CONAPRO != "B"
				lLiber := .T.
			EndIf
			dbSelectArea("SCR")
			dbSetOrder(1)
			if dbSeek(SC7->C7_FILIAL+"PC"+SC7->C7_NUM)
				cTipoSC7 := "PC"
				cAprov := AllTrim(UsrFullName(SCR->CR_USERLIB))
			else
				dbSeek(xFilial("SCR")+"IP"+SC7->C7_NUM)
				cTipoSC7 := "IP"
				cAprov := AllTrim(UsrFullName(SCR->CR_USERLIB))				
			endif
			/*
			While !Eof() .And. SCR->CR_FILIAL+Alltrim(SCR->CR_NUM) == xFilial("SCR")+SC7->C7_NUM .And. SCR->CR_TIPO == cTipoSC7
				cAprov += AllTrim(UsrFullName(SCR->CR_USERLIB)) +'                                                              '
					//Do Case
					//Case SCR->CR_STATUS=="03" //Liberado
						//cAprov += "Ok"
					//Case SCR->CR_STATUS=="04" //Bloqueado
					//	cAprov += "BLQ"
					//Case SCR->CR_STATUS=="05" //Nivel Liberado
					 //	cAprov += "##"
					//OtherWise                 //Aguar.Lib
						//cAprov += "??"
				//EndCase
				//cAprov += "] - "
				dbSelectArea("SCR")
				dbSkip()
			Enddo
			*/
			If !Empty(SC7->C7_GRUPCOM)
				dbSelectArea("SAJ")
				dbSetOrder(1)
				dbSeek(xFilial("SAJ")+SC7->C7_GRUPCOM)
				While !Eof() .And. SAJ->AJ_FILIAL+SAJ->AJ_GRCOM == xFilial("SAJ")+SC7->C7_GRUPCOM
					If SAJ->AJ_USER != SC7->C7_USER
						cAlter += AllTrim(UsrFullName(SAJ->AJ_USER))+"/"
					EndIf
					dbSelectArea("SAJ")
					dbSkip()
				EndDo
			EndIf
		//EndIf
             // TESTE PEDRO

	// Assinaturas
	oPrint:Line(2930,0300,2930,1000)
	oPrint:Line(2930,1400,2930,2100)
	oPrint:Say(2945,0650,cComprador,oFont13,,,,2)
	oPrint:Say(2945,1750,cAprov,oFont13,,,,2)
	if cEmpant = "01"
		oPrint:Say(2995,0650,'Quebec',oFont11,,,,2)
	else
		oPrint:Say(2995,0650,'Limpa Gyn',oFont11,,,,2)
	endif
	oPrint:Say(2995,1750,'Aprovador',oFont11,,,,2)

	oPrint:Line(3100,0100,3100,2300)
	oPrint:SayBitmap(3120,160,"logo_totvs.bmp", 140, 60) //Impressao da Logo
	oPrint:Say(3120,1200,OemToAnsi('Pแgina ')+cValToChar(nPagina),oFont11,,,,2)
	oPrint:Say(3120,2290, DTOC(dDatabase) + " " + TIME(), oFont10,,,,1)
	oPrint:Line(3200,0100,3200,2300)
	oPrint:EndPage()
Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหออออออัอออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณ xVerPag()บAutor ณLuis Henrique Robustoบ Data ณ  25/10/04   บฑฑ
ฑฑฬออออออออออุออออออออออสออออออฯอออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Verifica se deve ou nao saltar pagina...                   บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ Funcao Principal                                           บฑฑ
ฑฑฬออออออออออุออออออออออัอออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบDATA      ณ ANALISTA ณ  MOTIVO                                         บฑฑ
ฑฑฬออออออออออุออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบ          ณ          ณ                                                 บฑฑ
ฑฑศออออออออออฯออออออออออฯอออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function xVerPag()

	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณInicia a montagem da impressao.ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
	//If	( nLinha >= 3000 )
	If	( nLinha >= 2800 )//Delimita o fim da impressao dos itens
		If	( ! lFlag )
			xRodape()
			oPrint:EndPage()
			nLinha:= 520	// Paginas de continuacao: tabela logo abaixo do titulo
		Else
			nLinha:= 800	// Primeira pagina: ajustada em xCabFor()
		EndIf

		nPagina++
		oPrint:StartPage()
		xCabec()

		lPrintDesTab := .t.

	EndIf


Return

/*/{Protheus.doc} xQuebra
Quebra a pagina antes de imprimir um bloco que nao cabe ate o limite (2800).
/*/
Static Function xQuebra(nAltura)

	If	( nLinha + nAltura > 2800 )
		nLinha := 2800
		xVerPag()
	EndIf

Return

/*/{Protheus.doc} xCabFor
Quadro do fornecedor, quadro do numero do pedido e aviso (somente 1a pagina).
/*/
Static Function xCabFor()
Local cContato := AllTrim(SC7->C7_CONTATO)

	If	Empty(cContato)
		cContato := AllTrim(SA2->A2_CONTATO)
	EndIf
	If	Empty(cContato)
		cContato := '-'
	EndIf

	// Fornecedor
	oPrint:FillRect({0495,0100,0545,1860},oBrushCz)
	oPrint:Box(0495,0100,0765,1860)
	oPrint:Line(0545,0100,0545,1860)
	oPrint:Say(0502,0115,'FORNECEDOR',oFont12)
	oPrint:Say(0552,0115,AllTrim(SA2->A2_NOME) + '  ('+AllTrim(SA2->A2_COD)+'/'+AllTrim(SA2->A2_LOJA)+')',oFont13)
	oPrint:Say(0615,0115,OemToAnsi('Endere็o:'),oFont10)
	oPrint:Say(0615,0400,Left(AllTrim(SA2->A2_END),35),oFont11)
	oPrint:Say(0660,0115,OemToAnsi('Municํpio/UF:'),oFont10)
	oPrint:Say(0660,0400,AllTrim(SA2->A2_MUN)+'/'+AllTrim(SA2->A2_EST),oFont11)
	oPrint:Say(0705,0115,'Telefone:',oFont10)
	oPrint:Say(0705,0400,AllTrim(SA2->A2_TEL),oFont11)
	oPrint:Say(0615,1180,'CNPJ:',oFont10)
	oPrint:Say(0615,1340,TransForm(SA2->A2_CGC,'@R 99.999.999/9999-99'),oFont11)
	oPrint:Say(0660,1180,'CEP:',oFont10)
	oPrint:Say(0660,1340,TransForm(SA2->A2_CEP,'@R 99.999-999'),oFont11)
	oPrint:Say(0705,1180,'Contato:',oFont10)
	oPrint:Say(0705,1340,Left(cContato,22),oFont11)

	// Numero do pedido
	oPrint:FillRect({0495,1900,0545,2300},oBrushCz)
	oPrint:Box(0495,1900,0765,2300)
	oPrint:Line(0545,1900,0545,2300)
	oPrint:Say(0502,2100,OemToAnsi('PEDIDO Nบ'),oFont12,,,,2)
	oPrint:Say(0560,2100,SC7->C7_NUM,oFont20n,,,,2)
	oPrint:Say(0655,2100,'SC: '+SC7->C7_NUMSC,oFont12,,,,2)
	oPrint:Say(0705,2100,OemToAnsi('Emissใo: ')+Dtoc(SC7->C7_EMISSAO),oFont12n,,,,2)

	// Aviso
	if cEmpAnt = "01"
		oPrint:Box(0790,0100,0850,2300)
		oPrint:Say(0800,1200,OemToAnsi("Nใo serใo aceitas notas fiscais e boletos enviados por e-mail! Todos serใo recusados."),oFont11b,,,,2)
		nLinha := 0875
	else
		oPrint:Box(0790,0100,0910,2300)
		oPrint:Say(0800,1200,OemToAnsi("Horแrio de recebimento de mercadoria:"),oFont11b,,,,2)
		oPrint:Say(0850,1200,OemToAnsi("De segunda a sexta das 8:30 เs 11:00 e 13:00 เs 17:30 e Sแbados das 8:30 เs 11:00"),oFont11,,,,2)
		nLinha := 0935
	endif

Return

/*/{Protheus.doc} xTabCab
Cabecalho da tabela de itens.
/*/
Static Function xTabCab()

	oPrint:FillRect({nLinha,100,nLinha+55,2300},oBrushCz)
	oPrint:Line(nLinha,100,nLinha,2300)
	xColunas(nLinha,nLinha+55)

	oPrint:Say(nLinha+8,0110,OemToAnsi('It'),oFont12)
	oPrint:Say(nLinha+8,0170,OemToAnsi('C๓digo'),oFont12)
	oPrint:Say(nLinha+8,0320,OemToAnsi('Descri็ใo'),oFont12)
	oPrint:Say(nLinha+8,1228,OemToAnsi('Un'),oFont12)
	oPrint:Say(nLinha+8,1310,OemToAnsi('Entrega'),oFont12)
	oPrint:Say(nLinha+8,1670,OemToAnsi('Qtde'),oFont12,,,,1)
	oPrint:Say(nLinha+8,1840,OemToAnsi('Vlr.Unit.'),oFont12,,,,1)
	oPrint:Say(nLinha+8,1990,OemToAnsi('IPI %'),oFont12,,,,1)
	oPrint:Say(nLinha+8,2290,OemToAnsi('Valor Total'),oFont12,,,,1)

	nLinha += 55
	oPrint:Line(nLinha,100,nLinha,2300)
	lPrintDesTab := .f.

Return

/*/{Protheus.doc} xColunas
Linhas verticais das colunas da tabela de itens.
/*/
Static Function xColunas(nIni,nFim)

	oPrint:Line(nIni,0100,nFim,0100) // Item
	oPrint:Line(nIni,0160,nFim,0160) // Codigo
	oPrint:Line(nIni,0310,nFim,0310) // Descricao
	oPrint:Line(nIni,1220,nFim,1220) // Un
	oPrint:Line(nIni,1300,nFim,1300) // Entrega
	oPrint:Line(nIni,1455,nFim,1455) // Qtde
	oPrint:Line(nIni,1680,nFim,1680) // Unit
	oPrint:Line(nIni,1850,nFim,1850) // Ipi
	oPrint:Line(nIni,2000,nFim,2000) // Total
	oPrint:Line(nIni,2300,nFim,2300)

Return

/*/{Protheus.doc} xCompl
Retorna o complemento da cotacao (proposta vencedora no SC8) quebrado em linhas.
/*/
Static Function xCompl(nRecSC8)
Local aRet	:= {}
Local cTxt	:= ''
Local nPos	:= 0
Local nX	:= 0

	If	( nRecSC8 > 0 ) .and. ( (nPos := SC8->(FieldPos(CPO_COMPL))) > 0 )
		SC8->(DbGoTo(nRecSC8))
		cTxt := AllTrim(SC8->(FieldGet(nPos)))
		For nX := 1 To MlCount(cTxt,85)
			If	! Empty(MemoLine(cTxt,85,nX))
				aAdd(aRet,AllTrim(MemoLine(cTxt,85,nX)))
			EndIf
		Next nX
	EndIf

Return aRet

/*/{Protheus.doc} xDtCurta
Data no formato dd/mm/aa para caber na coluna de entrega.
/*/
Static Function xDtCurta(dData)

	If	Empty(dData)
		Return ''
	EndIf

Return StrZero(Day(dData),2)+'/'+StrZero(Month(dData),2)+'/'+Right(StrZero(Year(dData),4),2)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหออออออัอออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณ AjustaSX1บAutor ณLuis Henrique Robustoบ Data ณ  25/10/04   บฑฑ
ฑฑฬออออออออออุออออออออออสออออออฯอออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Ajusta o SX1 - Arquivo de Perguntas..                      บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ Funcao Principal                                           บฑฑ
ฑฑฬออออออออออุออออออออออัอออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบDATA      ณ ANALISTA ณ MOTIVO                                          บฑฑ
ฑฑฬออออออออออุออออออออออุอออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบ          ณ          ณ                                                 บฑฑ
ฑฑศออออออออออฯออออออออออฯอออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function AjustaSX1(cPerg)
Local	aRegs   := {}
//		_sAlias := Alias(),;
Local 	nX

		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณCampos a serem grav. no SX1ณ
		//ณaRegs[nx][01] - X1_GRUPO   ณ
		//ณaRegs[nx][02] - X1_ORDEM   ณ
		//ณaRegs[nx][03] - X1_PERGUNTEณ
		//ณaRegs[nx][04] - X1_PERSPA  ณ
		//ณaRegs[nx][05] - X1_PERENG  ณ
		//ณaRegs[nx][06] - X1_VARIAVL ณ
		//ณaRegs[nx][07] - X1_TIPO    ณ
		//ณaRegs[nx][08] - X1_TAMANHO ณ
		//ณaRegs[nx][09] - X1_DECIMAL ณ
		//ณaRegs[nx][10] - X1_PRESEL  ณ
		//ณaRegs[nx][11] - X1_GSC     ณ
		//ณaRegs[nx][12] - X1_VALID   ณ
		//ณaRegs[nx][13] - X1_VAR01   ณ
		//ณaRegs[nx][14] - X1_DEF01   ณ
		//ณaRegs[nx][15] - X1_DEF02   ณ
		//ณaRegs[nx][16] - X1_DEF03   ณ
		//ณaRegs[nx][17] - X1_F3      ณ
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

		//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
		//ณCria uma array, contendo todos os valores...ณ
		//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
		aAdd(aRegs,{cPerg,'01','Numero do Pedido   ?','Numero do Pedido   ?','Numero do Pedido   ?','mv_ch1','C', 6,0,0,'G','','mv_par01','','','','SC7'})
		aAdd(aRegs,{cPerg,'02','Imprime precos     ?','Imprime precos     ?','Imprime precos     ?','mv_ch2','N', 1,0,1,'C','','mv_par02',OemToAnsi('Nใo'),'Sim','',''})
		aAdd(aRegs,{cPerg,'03','Titulo do Relatorio?','Titulo do Relatorio?','Titulo do Relatorio?','mv_ch3','N', 1,0,1,'C','','mv_par03',OemToAnsi('Cota็ใo'),'Pedido','',''})
		aAdd(aRegs,{cPerg,'04',OemToAnsi('Observa็๕es'),'Observa็๕es         ','Observa็๕es         ','mv_ch4','C',70,0,1,'G','','mv_par04','','','',''})
		aAdd(aRegs,{cPerg,'05','                    ','                    ','                    ','mv_ch5','C',70,0,1,'G','','mv_par05','','','',''})
		aAdd(aRegs,{cPerg,'06','                    ','                    ','                    ','mv_ch6','C',70,0,0,'G','','mv_par06','','','',''})
		aAdd(aRegs,{cPerg,'07','                    ','                    ','                    ','mv_ch7','C',70,0,0,'G','','mv_par07','','','',''})
		aAdd(aRegs,{cPerg,'08','Imp. Cod. Prod. For?','Imp. Cod. Prod. For?','Imp. Cod. Prod. For?','mv_ch8','N', 1,0,1,'C','','mv_par08',OemToAnsi('Sim'),OemToAnsi('Nใo'),'',''})

		DbSelectArea('SX1')
		SX1->(DbSetOrder(1))

		For nX:=1 to Len(aRegs)
			If !SX1->(DbSeek(aRegs[nx][01]+aRegs[nx][02]))
				RecLock('SX1',.t.)
				Replace SX1->X1_GRUPO		With aRegs[nx][01]
				Replace SX1->X1_ORDEM   	With aRegs[nx][02]
				Replace SX1->X1_PERGUNTE	With aRegs[nx][03]
				Replace SX1->X1_PERSPA		With aRegs[nx][04]
				Replace SX1->X1_PERENG		With aRegs[nx][05]
				Replace SX1->X1_VARIAVL		With aRegs[nx][06]
				Replace SX1->X1_TIPO		With aRegs[nx][07]
				Replace SX1->X1_TAMANHO		With aRegs[nx][08]
				Replace SX1->X1_DECIMAL		With aRegs[nx][09]
				Replace SX1->X1_PRESEL		With aRegs[nx][10]
				Replace SX1->X1_GSC			With aRegs[nx][11]
				Replace SX1->X1_VALID		With aRegs[nx][12]
				Replace SX1->X1_VAR01		With aRegs[nx][13]
				Replace SX1->X1_DEF01		With aRegs[nx][14]
				Replace SX1->X1_DEF02		With aRegs[nx][15]
				Replace SX1->X1_DEF03		With aRegs[nx][16]
				Replace SX1->X1_F3   		With aRegs[nx][17]
				MsUnlock('SX1')
			Endif
		Next nX

Return



User Function EPed(cPedido,cProduto)
Local _aArea  := GetArea()
//local _nLinhas := 0
Private oArial30  	:=	TFont():New("Arial",,24,,.F.,,,,,.F.,.F.)
Private oArial14N	:=	TFont():New("Arial Narrow",,14,,.T.,,,,,.F.,.F.)
Private oArial15N	:=	TFont():New("Arial Narrow",,15,,.T.,,,,,.F.,.F.) 
Private oArial18N	:=	TFont():New("Arial Narrow",,18,,.T.,,,,,.F.,.F.) 
Private o17N	:=	TFont():New("Arial Narrow",,12,,.T.,,,,,.F.,.F.)//TFont():New("",,10,,.T.,,,,,.F.,.F.)
Private o19N	:=	TFont():New("Arial Narrow",,14,,.T.,,,,,.F.,.F.)//TFont():New("",,10,,.T.,,,,,.F.,.F.)
Private o18N	:=	TFont():New("",,12,,.T.,,,,,.F.,.F.)
Private o21N	:=	TFont():New("",,10,,.T.,,,,,.F.,.F.)
Private o10N	:=	TFont():New("",,7,,.T.,,,,,.F.,.F.)
Private o11N	:=	TFont():New("",,8,,.T.,,,,,.F.,.F.)
Private oTimes14N	:=	TFont():New("Times New Roman",,12,,.T.,,,,,.F.,.F.)
Private oTimes17N	:=	TFont():New("Times New Roman",,17,,.F.,,,,,.F.,.F.)
Private oTimes21N	:=	TFont():New("Times New Roman",,24,,.T.,,,,,.F.,.F.)   
Private oTimes24N	:=	TFont():New("Times New Roman",,24,,.T.,,,,,.T.,.F.)
Private o29N	:=	TFont():New("",,18,,.T.,,,,,.F.,.F.)
Private o28N	:=	TFont():New("Times New Roman",,12,,.T.,,,,,.F.,.F.)
PRIVATE oFont6  := TFont():New( "Arial",,08,,.f.,,,,,.f. )        
Private cxmail  := SuperGetMv( "MV_XPEDXML" )    //PARAMETRO QUE DEFINE QUAL E-MAIL SERม INFORMADO NO RELATORIO PARA RECEBIMENTO DE XML


aPrd := {}
If !Empty(cPedido) 
	If SC7->(dbSetOrder(1), dbSeek(xFilial("SC7")+cPedido))
		While SC7->(!Eof()) .And. SC7->C7_NUM == cPedido
			If !Empty(cProduto)
				If cProduto <> SC7->C7_PRODUTO
					SC7->(dbSkip(1));Loop
				Endif
			Endif
			
			SB1->(dbSetOrder(1), dbSeek(xFilial("SB1")+SC7->C7_PRODUTO))

			AAdd(aPrd,{SC7->C7_PRODUTO, SB1->B1_DESC, SB1->B1_UM, SC7->C7_QUANT})
			
			SC7->(dbSkip(1))
		Enddo
	Endif
ElseIf !Empty(cProduto)
	SB1->(dbSetOrder(1), dbSeek(xFilial("SB1")+cProduto))

	AAdd(aPrd,{cProduto, SB1->B1_DESC, SB1->B1_UM, 1})
Else
	Return .t.
Endif

SC7->(dbSetOrder(1), dbSeek(xFilial("SC7")+cPedido))
SA2->(dbSetOrder(1), dbSeek(xFilial("SA2")+SC7->C7_FORNECE+SC7->C7_LOJA))

//oPrinter:Setup()
//oPrinter:SetPortrait()

/* COMETANDA PEDRO NETO
For _nX := 1 To Len(aPrd)           

	SB1->(dbSetOrder(1), dbSeek(xFilial("SB1")+aPrd[_nX,1]))

	For nCopias := 1 To 1 //aPrd[_nX,4]
		oPrint:StartPage()
		               
			
		If _nX == 1
		*/                                 
		/*	
			oPrint:Say(0150,900,"A T E N ว ร O",oTimes24N,,0)
			oPrint:Say(0350,070,"Autorizamos o fornecimento dos materiais / equipamentos relacionados nesta",oArial18N,,0)  
			oPrint:Say(0430,070,"ordem de compra, desde que sejam obedecidas as regras abaixo:",oArial18N,,0)
			oPrint:Say(0800,070,"*Somente faturar para o CNPJ descrito na ordem de compra.",oArial14N,,0)
			oPrint:Say(0930,070,"*Constar no rodap้ da nota fiscal o n๚mero do pedido de compra.",oArial14N,,0)
			oPrint:Say(1050,070,"*Obedecer rigorosamente as condi็๕es de pagamento, valor unitแrio e quantidades descritas na ordem de compra.",oArial14N,,0)  
			oPrint:Say(1180,070,"*Em cumprimento as determina็๕es legais, o fornecedor que emitir a nota fiscal eltr๔nica (NF-e),em substitui็ใo",oArial14N,,0)
			oPrint:Say(1230,070," as nota fiscais Modelos 1A,deverใo encaminhแ-las ao endere็o eletr๔nico: " + cxmail+ ".",oArial14N,,0)
			oPrint:Say(1360,070,"*Caso nใo sejam cumpridas as exig๊ncias acima, a Quebec Ambiental reserva-se o direito de nใo receber a mercadoria/",oArial14N,,0)  
			oPrint:Say(1410,070," equipamento.Toda e qualquer devolu็ใo ocorrerแ por conta e risco do fornecedor.",oArial14N,,0) 
		
		    
		oPrint:Box(3200,50,70,2400)
		oPrint:Line(3100,50,3100,2400)	
	   	oPrint:SayBitmap(3120,160,"logo_totvs.bmp", 140, 60) //Impressao da Logo
	   	oPrint:Say(3120, 1200, "Microsiga Protheus", oFont10N,,,,2)
		oPrint:Say(3120,2290, DTOC(dDatabase) + " " + TIME(), oFont10,,,,1)
*/
		
		
		/*
		
		Endif
		
		oPrint:Box(0044,0046,0182,0800)
		oPrint:Box(0182,0046,0293,0800)
	
		MSBAR("CODE3_9",0.8,0.8,Rtrim(aPrd[_nX,1]),oPrint,.f.,NIL,.T.,0.0270,0.7,.F.,oFont6,"CODE3_9",.F.)
	
		oPrint:Say(0150,0200,aPrd[_nX,1],o11N,,0)
		
		oPrint:Say(0204,0058,"Pedido:",oTimes14N,,0)
		oPrint:Say(0200,0240,cPedido,o19N,,0)
		oPrint:Box(0293,0046,0371,800)
		oPrint:Say(0297,0063,"Fornec:",oTimes14N,,0)
		oPrint:Say(0297,0240,Capital(SA2->A2_NOME),o11N,,0)
		oPrint:Box(0371,0046,0946,800)
		oPrint:Say(0390,0079,"Descri็ใo:",oTimes14N,,0)
	
		cDesc := aPrd[_nX,2]
		
		_nLinhas := MlCount(cDesc,45)
		lI := 0440 
		For _nT := 1 To _nLinhas
			oPrint:Say(lI,0079,Capital(MemoLine(cDesc,45,_nT)),o11N,,0)
			lI+=30
		Next _nT
				

		oPrint:Say(0660,0079,"Tipo:",oTimes14N,,0)
		oPrint:Say(0660,0300,"Unidade:",oTimes14N,,0)
		oPrint:Say(0660,0500,"Peso Total:",oTimes14N,,0)

		oPrint:Say(0722,0079,SB1->B1_TIPO,o17N,,0)
		oPrint:Say(0722,0300,aPrd[_nX,3],o17N,,0)
		oPrint:Say(0722,0500,TransForm((SB1->B1_PESO * aPrd[_nX,4]),"@E 99,999.9999"),o17N,,0)
		oPrint:Say(0804,0079,"Alm.Padrใo:",oTimes14N,,0)
		oPrint:Say(0857,0079,SB1->B1_LOCPAD,o17N,,0)
		oPrint:Box(0946,0046,1100,800)
	
		oPrint:Say(0080,0520,"QTDE: "+Str(aPrd[_nX,4],5),o28N,,0)
		*/
   //	Private cStartPath    
	//Private nLin 	:= 0    
	//Private nMargemL    := 160  
	//Private nMargemR    := 2300 
	//Private nMargemT	:= 150
	//Private nMargemB	:= 3000
	
	
		/*  
		oPrint:EndPage()*/
	//Next
//Next
RestArea(_aArea)
Return

