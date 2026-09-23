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
    Private oFontC 	:= TFont():New('Arial',,14,.T.,.F.)
    Private oFontCN := TFont():New('Arial',,14,.T.,.T.)
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
    Local nLinIni    := 0
    Local nPula      := 50   // espacamento entre linhas do corpo do ticket
    Local nColBrd    := 0015 // margem esquerda da moldura
    Local nColBrdF   := nMaxCol-15 // margem direita da moldura

    if lEnd
		oPrinter:StartPage()
		oPrinter:Say(li,5,"Cancelado pelo Operador")
		oPrinter:EndPage()
		oPrinter:Print()
		return
	endIF

    oPrinter:StartPage()
    li := 30

    for nVezes := 1 to 3
        nLinIni := li
        cabecOp(nPagina,@li,oPrinter)

        oPrinter:Say(li,0100,"Placa:"               ,oFontC)
        oPrinter:Say(li,0470,NJH->NJH_PLACA         ,oFontCN)
        li+= nPula

        oPrinter:Say(li,0100,"Data Entrada:"        ,oFontC)
        oPrinter:Say(li,0470,dToc(NJH->NJH_DATPS1)  ,oFontCN)
        oPrinter:Say(li,0950,"Hora Entrada:"        ,oFontC)
        oPrinter:Say(li,1350,NJH->NJH_HORPS1        ,oFontCN)
        li+= nPula

        oPrinter:Say(li,0100,"Data Saída:"          ,oFontC)
        oPrinter:Say(li,0470,dtoc(NJH->NJH_DATPS2)  ,oFontCN)
        oPrinter:Say(li,0950,"Hora Saída:"          ,oFontC)
        oPrinter:Say(li,1350,NJH->NJH_HORPS2        ,oFontCN)
        li+= nPula

        oPrinter:Say(li,0100,"Operador:"            ,oFontC)
        oPrinter:Say(li,0470,cNomComUsr              ,oFontCN)
        li+= nPula

        oPrinter:Say(li,0100,"Motorista:"           ,oFontC)
        oPrinter:Say(li,0470,NJH->NJH_NOMMOT        ,oFontCN)
        li+= nPula

        oPrinter:Say(li,0100,"Produto:"             ,oFontC)
        oPrinter:Say(li,0470,NJH->NJH_DESPRO        ,oFontCN)
        li+= nPula

        oPrinter:Say(li,0100,"Fornecedor:"          ,oFontC)
        oPrinter:Say(li,0470,NJH->NJH_NOMENT        ,oFontCN)
        li+= nPula

        oPrinter:Say(li,0100,"Cliente:"             ,oFontC)
        if NJH->NJH_CODENT $ '001575-001587'
            oPrinter:Say(li,0470,'PREFEITURA'          ,oFontCN)
        else
            oPrinter:Say(li,0470,NJH->NJH_XCLIEN       ,oFontCN)
        endif
        li+= nPula

        oPrinter:Say(li,0100,"Peso Entrada:"                ,oFontC)
        oPrinter:Say(li,0470,Transform(NJH->NJH_PESO1, "@E 999,999")+ " KG"  ,oFontCN)
        li+= nPula

        oPrinter:Say(li,0100,"Peso Saída:"                  ,oFontC)
        oPrinter:Say(li,0470,Transform(NJH->NJH_PESO2, "@E 999,999")+ " KG"  ,oFontCN)
        li+= nPula

        oPrinter:Say(li,0100,"Peso Líquido:"                ,oFontC)
        oPrinter:Say(li,0470,Transform(NJH->NJH_PSSUBT, "@E 999,999")+ " KG"  ,oFontCN)
        li+= nPula

        oPrinter:Say(li,0100,"Observação:"                  ,oFontC)
        oPrinter:Say(li,0470,NJH->NJH_OBS                   ,oFontCN)
        li+= nPula
        oPrinter:Say(li,0100,"ROTA:"                        ,oFontC)
        oPrinter:Say(li,0470,NJH->NJH_XROTA                 ,oFontCN)
        li+= (nPula + 12)


        oPrinter:Say(li,0110,"_______________________________",oFontCN)
        oPrinter:Say(li,0850,"_______________________________",oFontCN)
        oPrinter:Say(li,1550,"_______________________________",oFontCN)

        li+= 45
        oPrinter:Say(li,0350,"Operador",oFontCN)
        oPrinter:Say(li,1100,"Fiscal",oFontCN)
        oPrinter:Say(li,1750,"Motorista",oFontCN)
        li+= 45

        // moldura (borda) ao redor de cada ticket
        oPrinter:Line( nLinIni, nColBrd , nLinIni, nColBrdF,, "-2")
        oPrinter:Line( li     , nColBrd , li     , nColBrdF,, "-2")
        oPrinter:Line( nLinIni, nColBrd , li     , nColBrd ,, "-2")
        oPrinter:Line( nLinIni, nColBrdF, li     , nColBrdF,, "-2")

        li += 55
    next

    oPrinter:EndPage()
	Li := 15					

    oPrinter:Preview()
    oPrinter:end()

Return

Static Function CabecOp(nPagOp, li, oPrinter)

    Local cTitulo   := "CTC QUEBEC AMBIENTAL SPE ITUIUTABA"
    Local cCabec1   := "CNPJ: 66.729.172/0001-09"
    Local cCabec2   := "Rua Aloisio Andrade Chaves SN"                                       
    Local cCabec3   := "Ituiutaba / MG"
    
    Private oFontC
    Private oFontT

    oFontCB	:= TFont():New('Arial',,06,.T.)
    oFontT 	:= TFont():New('Arial',,08,.T.)
    oFontTN := TFont():New('Arial',,08,.T.,.T.)
    oFontC 	:= TFont():New('Arial',,09,.T.)
    oFontCN := TFont():New('Arial',,09,.T.,.T.)
    oFont16 := TFont():New('Arial',,13,.T.,.T.)
    oFont14 := TFont():New('Arial',,11,.T.)

    li+= 40   // afasta o cabecalho da borda superior

    oPrinter:Say(li,0040,cTitulo,oFont16)
    li += 48
    oPrinter:Say(li,0040,cCabec1,oFont14)
    li += 46
    oPrinter:Say(li,0040,cCabec2,oFont14)
    oPrinter:Say(li,1400,cCabec3,oFont14)
    li += 40
    oPrinter:Line( li,0040, li, nMaxCol-40,, "-1")
    li += 28

    oPrinter:Say(li,0900,"Ticket de Pesagem Nº "+NJH->NJH_CODPAV,oFont16)
    li+= 48

return
