 #include "protheus.ch"
 
 /*/{Protheus.doc} QACOM002
    Realizar mudança do código do fornecedor do pedido de compra

    @type  Function
    @author sinval
    @since 17/11/2021
    @version 1.0
    @param cNumPed, Número do Pedido de Compras
    @return (lPermite), Lógico, (Retorna se Permite incluir o Número da caixa)
    @example
    (Não tem exemplo)
    @see (Não tem Link)
/*/

user Function QACOM002(cFilPed, cNumped)
    Local cEOL 		:= Chr(13)+Chr(10)
	Local cCodFor   := space(09)
    Local cLojaFor  := space(04)
	Local cRazao    := space(50)
    Local _aAreas   := getArea()
    Local cForOri   := ""
    Local cLojaOri  := ""
    Local lRet      := .T.
    Local cMsg      := ""

    SC7->(DbSetOrder(1))   
    if !SC7->(DbSeek(cFilPed+cNumPed))
        RETURN
    else
        
        cForOri := SC7->C7_FORNECE
        cLojaOri:= SC7->C7_LOJA

        do while SC7->(!Eof()) .and. SC7->(C7_FILIAL+C7_NUM) == cFilPed+cNumPed

            if SC7->C7_QUJE > 0
                cMsg += "Produto: "+SC7->C7_PRODUTO+" Já Recebido "+cEOL
            endif

            if SC7->C7_QTDACLA > 0 
                cMsg += "Produto: "+SC7->C7_PRODUTO+" Está como Pré-Nota "+cEOL    
            endif        

            SC7->(DbSkip())
        enddo

        if !empty(alltrim(cMsg))

            Aviso("Inconsistências",cMsg,{"OK"})

            return
        endif 

    endif 

	DEFINE MSDIALOG oDlg FROM 0,0 TO 200,400 PIXEL TITLE 'Troca de Fornecedor do Pedido'
	// Cria font para uso
	oFont:= TFont():New('Times New Roman',,-14,,.T.)
	// Apresenta o tSay com a fonte Courier New
	oSay := TSay():New( 005, 10, {|| 'Fornecedor..:'},oDlg,, oFont,,,, .T.,,)
	oSay := TSay():New( 020, 10, {|| 'Loja........:'},oDlg,, oFont,,,, .T.,,)
	oSay := TSay():New( 035, 10, {|| 'Razao Social:'},oDlg,, oFont,,,, .T.,,)

	oSay:lTransparent:= .F.			
    oGet1 := TGet():New( 005,060,{ |u| If( PCount() == 0,cCodFor,cCodFor := u ) },oDlg,010,010,'@!',,;
    CLR_BLACK,CLR_WHITE,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"SA2A","cCodFor",,)

//	oGet1:= TGet():New(005,60,{|u| if(PCount()>0,cCodFor:=u,cCodFor)}   ,oDlg,10,10,'@!',,,,,,,.T.,,,,,,,,,,'cCodFor')
	oGet2:= TGet():New(020,60,{|u| if(PCount()>0,cLojaFor:=u,cLojaFor)} ,oDlg,10,04,'@!',,,,,,,.T.,,,,,,,,,,'cLojaFor')
	oGet3:= TGet():New(035,60,{|u| if(PCount()>0,cRazao:=u,cRazao)}     ,oDlg,100,10,'@!',,,,,,,.T.,,,,,,,,,,'cRazao')

                         //Vert,Hor                      larg,altura
    oButton:=tButton():New(60,80,'OK',oDlg,{||oDlg:End()},40,15,,,,.T.)
    ACTIVATE MSDIALOG oDlg CENTERED
	
    if !ApMsgYesNo( "Confirma Substituição do Fornecedor "+cEOL+;
                    cForOri+"-"+cLojaOri+" "+Posicione("SA2",1,xFilial("SA2")+cForOri+cLojaOri,"A2_NOME")+" "+cEOL+;
                    cEOL+;
                    "para o Fornecedor "+cCodFor+" "+Posicione("SA2",1,xFilial("SA2")+cCodFor+cLojaFor,"A2_NOME")+" "+cEOL+;
                    cEOL+;
                    "do Pedido de Compras "+cNumped+" ","Confirmação")
		return
	else
        cNumCot := ""
        SC7->(DbSetOrder(1))   
        if SC7->(DbSeek(cFilPed+cNumPed))
            do while SC7->(!Eof()) .and. SC7->(C7_FILIAL+C7_NUM) == cFilPed+cNumPed

                cNumCot := SC7->C7_NUMCOT
    
                SC7->(RecLock("SC7",.F.))
                SC7->C7_FORNECE := cCodFor
                SC7->C7_LOJA    := cLojaFor
                //SC7->C7_CONAPRO := "B"
                SC7->(MsUnLock())

                SC7->(DbSkip())
            enddo
            
            SC8->(dbsetOrder(1))
            if SC8->(DbSeek(cFilPed+cNumCot))
                do while SC8->(!eof()) .and. SC8->(C8_FILIAL+C8_NUM) == cFilPed+cNumCot
                
                    SC8->(RecLock("SC8",.F.))
                    SC8->C8_FORNECE := cCodFor
                    SC8->C8_LOJA    := cLojaFor
                    SC8->C8_CONTATO := posicione("SA2",1,XFILIAL("SA2")+cCodFor+cLojaFor,"A2_CONTATO")
                    SC8->(MsUnLock())

                    SC8->(DbSkip())
                enddo
            endif

            SCR->(Dbsetorder(1))
            if SCR->(Dbseek(cFilPed+"PC"+cNumPed))
                do while SCR->(!Eof()) .and. alltrim(SCR->(CR_FILIAL+CR_TIPO+CR_NUM)) == cFilPed+"PC"+cNumPed
                    SCR->(Reclock("SCR",.F.))
                    SCR->CR_STATUS  := "02"
                    SCR->CR_DATALIB := CTOD("  /  /  ")
                    SCR->CR_USERLIB := "      "
                    SCR->CR_LIBAPRO := "      "
                    SCR->CR_VALLIB  := 0
                    SCR->(msUnlock())

                    SCR->(DbSkip())
                enddo
            endif
        endif 
    
        SC7->(DbSetOrder(1))   
        SC7->(DbSeek(cFilPed+cNumPed))
    	
        msginfo("Substituição de Fornecedor Realizada","Alteração")
        lRet := .T.
    
    endif	

    restarea(_aAreas)
return(lRet)
