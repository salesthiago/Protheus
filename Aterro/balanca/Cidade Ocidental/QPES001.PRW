#INCLUDE "FIVEWIN.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "APWIZARD.CH"
#INCLUDE "FILEIO.CH"
#INCLUDE "RPTDEF.CH"                                      
#INCLUDE "FWPrintSetup.ch"
#INCLUDE "TOTVS.CH"
#INCLUDE "PARMTYPE.CH"
#Include "RWMAKE.CH"

user Function QPES001()

Local oPrinter 	:= Nil
Local lEnd		:= .T.
Local cPerg     := "RSEM01"

Private oFont8 	:= TFont():New('Arial',,08,.T.,.F.)
Private oFont9 	:= TFont():New('Arial',,09,.T.,.F.)
Private oFontT 	:= TFont():New('Arial',,10,.T.)
Private oFontTN	:= TFont():New('Arial',,10,.T.,.T.)
Private oFontC 	:= TFont():New('Arial',,12,.T.,.F.)
Private oFontCN := TFont():New('Arial',,12,.T.,.T.)
Private oFontT_	:= TFont():New('Arial',,10,.T.,.F.)

Private aArray	:= {}
Private li		:= 15
Private nMaxLin	:= 1800
Private nMaxCol	:= 2500
Private lItemNeg:= .F. 
Private nPagina := 1

AjustaSX1(cPerg)

SetMVValue(cPerg,"MV_PAR01", NJH->NJH_CODPAV )
SetMVValue(cPerg,"MV_PAR02", NJH->NJH_CODPAV )

Pergunte(cPerg,.T.)

cCaminho    := GetTempPath()
cFile       := cCaminho+"/"+"QPES001"+".rel"

//Criando o objeto do FMSPrinter
//oPrinter := tNewMSPrinter():New("Tickwet de Pesagem")

oPrint := FWMSPrinter():New(cFilePrintert ,IMP_SPOOL/*IMP_PDF*/, lAdjustToLegacy, /*cPathInServer*/, lDisabeSetup , lTReport, /*@oPrintSetup*/, cPrinter, lServer, lPDFAsPNG, /*lRaw*/, /*lViewPDF*/, /*nQtdCopy*/ )

oPrinter:SetPortrait() //SetLandscape() 
oPrinter:SetPaperSize(10)
oPrint:cPathPDF:="C:\TOTVS\"
oPrinter:setup()

RptStatus({|lEnd| QPES001I(@lEnd, cFile, @oPrinter, MV_PAR01, MV_PAR02, MV_PAR03)},"Imprimindo Relatorio...")

FreeObj(oPrinter)
oPrinter := Nil

Return Nil

static Function QPES001I(lEnd, cIdent, oPrinter, cTicIni, cTicFim, cCliente)
    Local nVezes     := 1
    Local cCodUsr    := alltrim(NJH->NJH_XUSER) //RetCodUsr()
    Local cNomComUsr := cCodUsr //Alltrim( UsrFullName(cCodUsr) )


    NJH->(DbSetOrder(1))
    if NJH->(DbSeek(xFilial("NJH")+cTicIni))
        do while NJH->(!Eof()) .and. NJH->NJH_CODPAV >= cTicIni .and. NJH->NJH_CODPAV <= cTicFim

            if lEnd
                oPrinter:StartPage()
                oPrinter:Say(li,5,"Cancelado pelo Operador")
                oPrinter:EndPage()
                oPrinter:Print()
                return
            endIF

            if !empty(cCliente)
                if alltrim(cCliente) <> alltrim(NJH->NJH_NOMENT)
                    NJH->(DbSkip())
                    loop
                endif
            endif

            for nVezes := 1 to 3
                cabecOp(nPagina,@li,oPrinter)

                oPrinter:Say(li,0010,"Placa:"               ,oFontC)
                oPrinter:Say(li,0350,NJH->NJH_PLACA         ,oFontCN)
                li+= 45

                oPrinter:Say(li,0010,"Data Entrada:"        ,oFontC) 	
                oPrinter:Say(li,0350,dToc(NJH->NJH_DATPS1)  ,oFontCN) 				
                oPrinter:Say(li,0900,"Hora Entrada:"        ,oFontC)
                oPrinter:Say(li,1300,NJH->NJH_HORPS1        ,oFontCN) 	
                li+= 45

                oPrinter:Say(li,0010,"Data Saída:"          ,oFontC) 	
                oPrinter:Say(li,0350,dtoc(NJH->NJH_DATPS2)  ,oFontCN) 				
                oPrinter:Say(li,0900,"Hora Saída:"          ,oFontC)
                oPrinter:Say(li,1300,NJH->NJH_HORPS2        ,oFontCN) 	
                li+= 45

                oPrinter:Say(li,0010,"Operador:"            ,oFontC) 				
                oPrinter:Say(li,0350,cNomComUsr              ,oFontCN) 				
                li+= 45

                oPrinter:Say(li,0010,"Motorista:"           ,oFontC)
                oPrinter:Say(li,0350,NJH->NJH_NOMMOT        ,oFontCN) 				
                li+= 45

                oPrinter:Say(li,0010,"Produto:"             ,oFontC) 				
                oPrinter:Say(li,0350,NJH->NJH_DESPRO        ,oFontCN) 	
                li+= 45
                
                oPrinter:Say(li,0010,"Fornecedor:"          ,oFontC)
                //oPrinter:Say(li,0350,NJH->NJH_NOMENT        ,oFontCN)
                li+= 45

                oPrinter:Say(li,0010,"Cliente:"             ,oFontC)
                oPrinter:Say(li,0350,NJH->NJH_XCLIEN       ,oFontCN) 	

                li+= 75

                oPrinter:Say(li,0010,"Peso Entrada:"                ,oFontC)
                oPrinter:Say(li,0350,Transform(NJH->NJH_PESO1, "@E 999,999")+ " KG"  ,oFontCN) 	
                li+= 45

                oPrinter:Say(li,0010,"Peso Saída:"                  ,oFontC)
                oPrinter:Say(li,0350,Transform(NJH->NJH_PESO2, "@E 999,999")+ " KG"  ,oFontCN) 	
                li+= 45

                oPrinter:Say(li,0010,"Peso Líquido:"                ,oFontC)
                oPrinter:Say(li,0350,Transform(NJH->NJH_PSSUBT, "@E 999,999")+ " KG"  ,oFontCN) 	
                li+= 65

                oPrinter:Say(li,0010,"Observação:"                  ,oFontC)
                oPrinter:Say(li,1600,"ROTA:"                        ,oFontC)
                oPrinter:Say(li,0350,NJH->NJH_OBS                   ,oFontCN) 	
                oPrinter:Say(li,1700,NJH->NJH_XROTA                 ,oFontCN)         
                li+= 50*3

                oPrinter:Say(li,0010,"_______________________________",oFontCN)
                oPrinter:Say(li,0800,"_______________________________",oFontCN)
                oPrinter:Say(li,1500,"_______________________________",oFontCN)

                li+= 45
                //oPrinter:Say(li,0250,"Operador",oFontCN)     
                //oPrinter:Say(li,1050,"Fiscal",oFontCN)     
                //oPrinter:Say(li,1700,"Motorista",oFontCN)     
                li+= 45

                oPrinter:Line( li,0020, li, nMaxCol-10,, "-1")
                li += 45 * 2
            next

            oPrinter:EndPage()
            Li := 15					

            oPrinter:Preview()
            oPrinter:end()

            NJH->(DbSkip())
        enddo
    endIF

Return

Static Function CabecOp(nPagOp, li, oPrinter)

Local cTitulo   := "QUEBEC CONSTRUÇÕES E TECNOLOGIA AMBIENTAL S/A"
Local cCabec1   := "AREA QUINHO GLEBA 01C COM 9 HECT. 02"
Local cCabec2   := "CNPJ: 26.921.551/0002-62 INSC. 104232013"                                       
Local cCabec3   := "CEP 72.880-000 - CIDADE OCIDADENTAL - GOIAS"
Private oFontC
Private oFontT

oFontCB	:= TFont():New('Arial',,06,.T.)
oFontT 	:= TFont():New('Arial',,10,.T.)
oFontTN := TFont():New('Arial',,10,.T.,.T.)
oFontC 	:= TFont():New('Arial',,12,.T.)
oFontCN := TFont():New('Arial',,12,.T.,.T.)
oFont16 := TFont():New('Arial',,16,.T.,.T.)
oFont14 := TFont():New('Arial',,14,.T.)

oPrinter:StartPage()
//oPrinter:Line( li, 10, li, nMaxCol-10,, "-1")
li+= 20

//oPrinter:Cmtr2Pix(nAltura,nLargura)

oPrinter:Say(li,0450,cTitulo,oFont16) 
li += 50
oPrinter:Say(li,0580,cCabec1, oFont14) 
li += 45
oPrinter:Say(li,0580,cCabec2, oFont14) 
LI += 45
oPrinter:Say(li,0530,cCabec3, oFont14) 
li += 45
oPrinter:Line( li,0020, li, nMaxCol-10,, "-1")
li += 35

//oPrinter:Line( li,20, li, nMaxCol-10,, "-1")
//li+=30
oPrinter:Say(li,0010, "SAÍDA DE VEÍCULO - RECEBIMENTO", oFont16)
oPrinter:Say(li,1200,"Ticket de Pesagem Nº "+NJH->NJH_CODPAV,oFont16)
li+= 50 

return

//===============
// AjustaSX1 
//
Static Function AjustaSX1(cPerg)
Local _sAlias := Alias()
Local aRegs := {}
Local i,j

dbSelectArea("SX1")
dbSetOrder(1)
cPerg := PADR(cPerg,10)

//(sx1) Grupo/Ordem/Pergunta/Variavel/Tipo/Tamanho/Decimal/Presel/GSC/Valid/Var01/Def01/Cnt01/Var02/Def02/Cnt02/Var03/Def03/Cnt03/Var04/Def04/Cnt04/Var05/Def05/Cnt05
aAdd(aRegs,{cPerg,"01","Ticket De   ?"    	,"","","mv_ch1","C", 06,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","",""})
aAdd(aRegs,{cPerg,"02","Ticket Até  ?"    	,"","","mv_ch2","C", 06,0,0,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","","","",""})
aAdd(aRegs,{cPerg,"03","Cliente 	?"  	,"","","mv_ch3","C", 30,0,0,"G","","mv_par03","","","","","","","","","","","","","","","","","","","","","","","","","",""})

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
