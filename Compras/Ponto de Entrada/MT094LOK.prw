#Include "HBUTTON.CH"
#Include 'Protheus.ch'
#Include "TopConn.ch"
#Include "Totvs.ch"
#INCLUDE 'RWMAKE.CH'
#INCLUDE 'TBICONN.CH'
#INCLUDE 'FWMVCDEF.CH'

User Function MT094LOK()

    Local lRet := .T.
    Local aArea:= GetArea()
    Local cPreco:= ""
    Local nCont := 0
    Static cAliasAux := GetNextAlias()

    If AllToChar(FWCodEmp()) == '02' //Valida se a empresa é a 02

        If !SCR->CR_TIPO$'IP/PC'
            Return lRet
        EndIf
        DBSelectArea('SC7')
        If SC7->(DBSeek(SCR->CR_FILIAL+AllTrim(SCR->CR_NUM)))
            While SC7->(!EoF()) .AND. SCR->CR_NUM = SC7->C7_NUM
                CRIATMP(SC7->C7_PRODUTO)
                DBSelectArea(cAliasAux)
                (cAliasAux)->(DBGoTop())
                While (cAliasAux)->(!EoF())
                    nCont++
                    If nCont == 1 .and. (cAliasAux)->VALOR > 0
                        RecLock('SC7', .F.)
                        
                        if Round(    ((SC7->C7_PRECO - (cAliasAux)->VALOR)/(cAliasAux)->VALOR)*100    ,0) > 999
                            SC7->C7_CONTA40 = 100
                        else
                            SC7->C7_CONTA40:= Round(    ((SC7->C7_PRECO - (cAliasAux)->VALOR)/(cAliasAux)->VALOR)*100    ,0)
                        EndIf

                        SC7->(MsUnlock())
                    EndIf
                    cPreco+= Iif(empty(cPreco),"R$ "+cValToChar((cAliasAux)->VALOR)," / R$ "+cValToChar((cAliasAux)->VALOR))
                    (cAliasAux)->(DBSkip())
                End
                (cAliasAux)->(dbCloseArea())
                cPreco:= StrTran(cPreco,'.',',')
                RecLock('SC7', .F.)
                SC7->C7_ACCNUM := cPreco
                SC7->(MsUnlock())
                SC7->(DBSkip())
                cPreco:= " "
                nCont:= 0
            End
        EndIf
        SC7->(dbCloseArea())

    Endif

    RestArea(aArea)
Return lRet
User Function fonteold()

    If AllToChar(FWCodEmp()) == '02' //Valida se a empresa é a 02

        If !SCR->CR_TIPO$'IP/PC'
            Return lRet
        EndIf
        cCodFor := Posicione('SC7',1,xFilial('SC7')+alltrim(SCR->CR_NUM),'C7_FORNECE')
        cNomefor:= Posicione('SA2',1,xFilial('SA2')+cCodFor,'A2_NOME')

        DEFINE MSDIALOG oDlg TITLE "DADOS DO PEDIDO DE COMPRA" FROM 000, 000  TO 400, 900 COLORS 0, 16777215 PIXEL

        @ 015, 005 GROUP oGroup1 TO 061, 242 OF oDlg COLOR 1, 16777215 PIXEL
        @ 178, 207 BUTTON ok PROMPT "OK" SIZE 037, 012 OF oDlg ACTION (oDlg:End()) PIXEL
        @ 020, 009 SAY oSay2 PROMPT "Nº Pedido de Compra" SIZE 058, 007 OF oDlg COLORS 0, 16777215 PIXEL
        //@ 029, 009 SAY oSay4 PROMPT "Quantidade de Itens" SIZE 052, 007 OF oDlg COLORS 0, 16777215 PIXEL
        //@ 029, 130 SAY oSay5 PROMPT "Prazo Médio do Forn" SIZE 035, 007 OF oDlg COLORS 0, 16777215 PIXEL
        //@ 039, 009 SAY oSay6 PROMPT "Condição de Pgto" SIZE 047, 007 OF oDlg COLORS 0, 16777215 PIXEL
        @ 049, 009 SAY oSay7 PROMPT "Fornecedor" SIZE 029, 007 OF oDlg COLORS 0, 16777215 PIXEL
        @ 019, 130 SAY oSay8 PROMPT "Valor Total" SIZE 057, 007 OF oDlg COLORS 0, 16777215 PIXEL


        @ 18,70  MSGET SCR->CR_NUM   When .F. SIZE 50,8 OF oDlg PIXEL
        /*
        @ 28,70  MSGET 'TMP1->QTD '    When .F. SIZE 50 ,8 OF oDlg PIXEL
        @ 28,170 MSGET 'TMP1->MEDIA'   When .F. SIZE 50 ,8 OF oDlg PIXEL
        @ 38,70  MSGET 'TMP1->E4_DESCRI' When .F. SIZE 150 ,8 OF oDlg PIXEL
        */
        @ 48,70  MSGET cNomefor   When .F. SIZE 150 ,8 OF oDlg PIXEL
        @ 18,170 MSGET SCR->CR_TOTAL Picture "@E 999,999,999,999.99" When .F. SIZE 50,8 OF oDlg PIXEL


        fWBrowse1()

        ACTIVATE MSDIALOG oDlg CENTERED

    Endif

Return lRet

Static Function fWBrowse1()
    Local oWBrowse1
    Local aWBrowse1 := {}
    Local nPenutimo:= 0
    Local nAntpenut:= 0

    cQuery := " SELECT "
    cQuery += " DISTINCT(SCR.CR_NUM), C7_PRODUTO, B1_DESC, SC7.C7_UM, SC7.C7_PRECO , SC7.C7_QUANT, SC7.C7_TOTAL, "
    cQuery += " (SELECT TOP 1 COALESCE(SD1.D1_VUNIT,NULL,0) FROM "+RetSqlName("SD1") +" SD1 WHERE SD1.D_E_L_E_T_ = ' ' AND D1_COD = SC7.C7_PRODUTO ORDER BY D1_EMISSAO DESC) ULTIMO "
    cQuery += " FROM "+RetSqlName("SCR") +" SCR "
    cQuery += " INNER JOIN "+RetSqlName("SC7")+ " SC7 ON CR_FILIAL = SC7.C7_FILIAL AND SC7.C7_NUM = SCR.CR_NUM "
    cQuery += " INNER JOIN "+RetSqlName("SB1")+ " SB1 ON B1_COD = SC7.C7_PRODUTO "
    cQuery += " WHERE SCR.D_E_L_E_T_ = ' ' "
    cQuery += " AND C7_NUM = '"+SCR->CR_NUM+"' "


    cQuery := CHANGEQUERY(cQuery)

    DBUSEAREA(.T.,'TOPCONN',TCGENQRY(,,cQuery),"TMP2",.F.,.T.)
    DBSelectArea("TMP2")
    TMP2->(DBGoTop())
    While !TMP2->( Eof() )
        nPenutimo:= Criatmp1(AllTrim(TMP2->C7_PRODUTO),2,TMP2->CR_NUM)
        nAntpenut:= Criatmp1(AllTrim(TMP2->C7_PRODUTO),3,TMP2->CR_NUM)
        Aadd(aWBrowse1,{;
            Alltrim(TMP2->C7_PRODUTO),;
            Alltrim(TMP2->B1_DESC),;
            Alltrim(TMP2->C7_UM),;
            transform(TMP2->C7_PRECO,"@E 999,999,999,999.99"),;
            transform(TMP2->C7_QUANT,"@E 999,999,999,999.99"),;
            transform(TMP2->C7_TOTAL,"@E 999,999,999,999.99"),;
            transform(TMP2->ULTIMO,"@E 999,999,999,999.99"),;
            transform(nPenutimo,"@E 999,999,999,999.99"),;
            transform(nAntpenut,"@E 999,999,999,999.99") })
        TMP2->(DBSkip())
    Enddo
    TMP2->(dbCloseArea())

    //inserir o nome dos campos aqui.
    @ 072, 004 LISTBOX oWBrowse1 Fields HEADER 'CODIGO',;
        'PRODUTO',;
        'UNIDADE',;
        'PRECO',;
        'QUANTIDADE',;
        'TOTAL',;
        'ULT.PRECO','PEN.PRECO','ANP.PRECO' SIZE 450, 100 OF oDlg PIXEL ColSizes 10,30,10,10,25,25,25,25

    //inserir uma linha nova para cada bloco de header ou conteudo.
    oWBrowse1:SetArray(aWBrowse1)
    oWBrowse1:bLine := {|| {;
        aWBrowse1[oWBrowse1:nAt,1],;
        aWBrowse1[oWBrowse1:nAt,2],;
        aWBrowse1[oWBrowse1:nAt,3],;
        aWBrowse1[oWBrowse1:nAt,4],;
        aWBrowse1[oWBrowse1:nAt,5],;
        aWBrowse1[oWBrowse1:nAt,6],;
        aWBrowse1[oWBrowse1:nAt,7],;
        aWBrowse1[oWBrowse1:nAt,8],;
        aWBrowse1[oWBrowse1:nAt,9]}}
Return

Static Function CriaTmp1(_cProd,_nLinha,_cPedido)

    Local cQuery := ""
    Local cAliasAux := GetNextAlias()
    Local nValor:= 0

    cQuery += " SELECT COALESCE(SUM(VUNIT),NULL,0) VALOR FROM "
    cQuery += " ( "
    cQuery += " SELECT "
    cQuery += " TOP 3 D1_VUNIT VUNIT, "
    cQuery += " ROW_NUMBER() OVER(  ORDER BY D1_EMISSAO DESC ) AS ROWSD1 "
    cQuery += " FROM "+RetSqlName("SD1") +" SD1 WHERE SD1.D_E_L_E_T_ = ' ' AND SD1.D1_TIPO = 'N' AND SD1.D1_COD = '"+_cProd+"'"
    cQuery += " ORDER BY D1_EMISSAO DESC "
    cQuery += " ) AS PRECOS2 "
    cQuery += " WHERE ROWSD1 = "+ cValToChar(_nLinha)

    TCQuery cQuery New Alias &cAliasAux

    nValor:= (cAliasAux)->VALOR
    (cAliasAux)->(DBCloseArea())

Return(nValor)

Static Function CriaTmp(_cProd)

    Local cQuery := ""

    cQuery += " SELECT COALESCE(VUNIT,NULL,0) VALOR FROM "
    cQuery += " ( "
    cQuery += " SELECT "
    cQuery += " TOP 3 D1_VUNIT VUNIT, "
    cQuery += " ROW_NUMBER() OVER(  ORDER BY D1_EMISSAO DESC ) AS ROWSD1 "
    cQuery += " FROM "+RetSqlName("SD1") +" SD1 WHERE SD1.D_E_L_E_T_ = ' ' AND SD1.D1_TIPO = 'N' AND SD1.D1_COD = '"+_cProd+"'"
    cQuery += " ORDER BY D1_EMISSAO DESC "
    cQuery += " ) AS PRECOS2 "

    TCQuery cQuery New Alias &cAliasAux

Return
