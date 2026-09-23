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

//Pergunte("RSEM01",.T.)

cCaminho    := GetTempPath()
cFile       := cCaminho+"/"+"QPES001"+".rel"

//Criando o objeto do FMSPrinter
oPrinter := tNewMSPrinter():New("Ticket de Pesagem")
oPrinter:SetPortrait() //SetLandscape() 
oPrinter:SetPaperSize(10)
oPrinter:setup()

RptStatus({|lEnd| QPES001I(@lEnd, cFile, @oPrinter)},"Imprimindo Relatorio...")

FreeObj(oPrinter)
oPrinter := Nil

Return Nil

static Function QPES001I(lEnd, cIdent, oPrinter)
    Local nVezes     := 1
    Local cCodUsr    := alltrim(NJH->NJH_XUSER) //RetCodUsr()
    Local cNomComUsr := cCodUsr //Alltrim( UsrFullName(cCodUsr) )

    if lEnd
		oPrinter:StartPage()
		oPrinter:Say(li,5,"Cancelado pelo Operador")
		oPrinter:EndPage()
		oPrinter:Print()
		return
	endIF

    oPrinter:StartPage()
    li := 15

    for nVezes := 1 to 4
        cabecOp(nPagina,@li,oPrinter)

        oPrinter:Say(li,0010,"Placa:"               ,oFontC)
        oPrinter:Say(li,0350,NJH->NJH_PLACA         ,oFontCN)
        li+= 42

        oPrinter:Say(li,0010,"Data Entrada:"        ,oFontC)
        oPrinter:Say(li,0350,dToc(NJH->NJH_DATPS1)  ,oFontCN)
        oPrinter:Say(li,0900,"Hora Entrada:"        ,oFontC)
        oPrinter:Say(li,1300,NJH->NJH_HORPS1        ,oFontCN)
        li+= 42

        oPrinter:Say(li,0010,"Data Saída:"          ,oFontC)
        oPrinter:Say(li,0350,dtoc(NJH->NJH_DATPS2)  ,oFontCN)
        oPrinter:Say(li,0900,"Hora Saída:"          ,oFontC)
        oPrinter:Say(li,1300,NJH->NJH_HORPS2        ,oFontCN)
        li+= 42

        oPrinter:Say(li,0010,"Operador:"            ,oFontC)
        oPrinter:Say(li,0350,cNomComUsr              ,oFontCN)
        li+= 42

        oPrinter:Say(li,0010,"Motorista:"           ,oFontC)
        oPrinter:Say(li,0350,NJH->NJH_NOMMOT        ,oFontCN)
        li+= 42

        oPrinter:Say(li,0010,"Produto:"             ,oFontC)
        oPrinter:Say(li,0350,NJH->NJH_DESPRO        ,oFontCN)
        li+= 42

        oPrinter:Say(li,0010,"Fornecedor:"          ,oFontC)
        oPrinter:Say(li,0350,NJH->NJH_NOMENT        ,oFontCN)
        li+= 42

        oPrinter:Say(li,0010,"Cliente:"             ,oFontC)
        if NJH->NJH_CODENT $ '001575-001587'
            oPrinter:Say(li,0350,'PREFEITURA'          ,oFontCN)
        else
            oPrinter:Say(li,0350,NJH->NJH_XCLIEN       ,oFontCN)
        endif
        li+= 42

        oPrinter:Say(li,0010,"Peso Entrada:"                ,oFontC)
        oPrinter:Say(li,0350,Transform(NJH->NJH_PESO1, "@E 999,999")+ " KG"  ,oFontCN)
        li+= 42

        oPrinter:Say(li,0010,"Peso Saída:"                  ,oFontC)
        oPrinter:Say(li,0350,Transform(NJH->NJH_PESO2, "@E 999,999")+ " KG"  ,oFontCN)
        li+= 42

        oPrinter:Say(li,0010,"Peso Líquido:"                ,oFontC)
        oPrinter:Say(li,0350,Transform(NJH->NJH_PSSUBT, "@E 999,999")+ " KG"  ,oFontCN)
        li+= 42

        oPrinter:Say(li,0010,"Observação:"                  ,oFontC)
        oPrinter:Say(li,0350,NJH->NJH_OBS                   ,oFontCN)
        li+= 42
        oPrinter:Say(li,0010,"ROTA:"                        ,oFontC)
        oPrinter:Say(li,0350,NJH->NJH_XROTA                 ,oFontCN)
        li+= 50


        oPrinter:Say(li,0010,"_______________________________",oFontCN)
        oPrinter:Say(li,0800,"_______________________________",oFontCN)
        oPrinter:Say(li,1500,"_______________________________",oFontCN)

        li+= 35
        oPrinter:Say(li,0250,"Operador",oFontCN)
        oPrinter:Say(li,1050,"Fiscal",oFontCN)
        oPrinter:Say(li,1700,"Motorista",oFontCN)
        li+= 35

        oPrinter:Line( li,0020, li, nMaxCol-10,, "-1")
        li += 35
    next

    oPrinter:EndPage()
	Li := 15					

    oPrinter:Preview()
    oPrinter:end()

Return

Static Function CabecOp(nPagOp, li, oPrinter)

Local cTitulo   := "PREFEITURA MUNICIPAL DE AP. DE GOIÂNIA - GO"
Local cCabec1   := "CNPJ: 01.005.727/0001-24"
Local cCabec2   := "Rua Gervásio Pinheiro S/N - Res. Village Garavelo"                                       
Local cCabec3   := "Aparecida de Goiânia / GO"
Private oFontC
Private oFontT

oFontCB	:= TFont():New('Arial',,06,.T.)
oFontT 	:= TFont():New('Arial',,08,.T.)
oFontTN := TFont():New('Arial',,08,.T.,.T.)
oFontC 	:= TFont():New('Arial',,09,.T.)
oFontCN := TFont():New('Arial',,09,.T.,.T.)
oFont16 := TFont():New('Arial',,11,.T.,.T.)
oFont14 := TFont():New('Arial',,09,.T.)

li+= 10

oPrinter:Say(li,0020,cTitulo,oFont16) 
li += 35
oPrinter:Say(li,0020,cCabec1,oFont14) 
li += 25
oPrinter:Say(li,0020,cCabec2,oFont14) 
oPrinter:Say(li,1400,cCabec3,oFont14) 
li += 25
oPrinter:Line( li,0020, li, nMaxCol-10,, "-1")
li += 18

oPrinter:Say(li,0900,"Ticket de Pesagem Nº "+NJH->NJH_CODPAV,oFont16)
li+= 30 

return
