#Include 'Protheus.ch'

/*----------------------------------------------------------------------
- Programa: NGGERASC11
- Autor: Adriano Costa
- Data: 02/12/2020
- Descrição: Ponto de Entrada que possibilita alterar informações 
              após a geração da solicitação de compras, na abertura da
              OS Corretiva - Manutenção de ativos
------------------------------------------------------------------------*/

User Function NGGERASC11()

      Local aArea	      := GetArea()
      Local aAreaSTL    := STL->(GetArea())
      Local aAreaSB1    := SB1->(GetArea())
      Local aAreaTT9    := TT9->(GetArea())
      Local nOpc        :=  0
      Local aButtons    := {}
      Local oCodFornec
      Local cCodFornec  := ""
      Local oDescFornec
      Local cDescFornec := ""
      Local oCodTarefa
      Local cCodTarefa  := ""
      Local oDescTarefa
      Local cDescTarefa := ""
      Local oCodServico
      Local cCodServico := Space(TamSx3("B1_COD")[1])
      Local oDescServico
      Local cDescServico := ""
      Local oSayFornec
      Local oSayTarefa
      Local oSayServico
      Static oDlg

      STL->(DbSetOrder(9)) // TL_FILIAL + TL_NUMSC + TL_ITEMSC
      If STL->(DbSeek(xFilial("STL") + SC1->C1_NUM + SC1->C1_ITEM))

            If STL->TL_TIPOREG == 'T' // se for terceiro
            
                  cCodFornec := STL->TL_CODIGO
                  cDescFornec := NOMINSBRW(STL->TL_TIPOREG,STL->TL_CODIGO)
                  cCodTarefa := STL->TL_TAREFA
                  cDescTarefa := Posicione("TT9",1,xFilial("TT9")+STL->TL_TAREFA,"TT9_DESCRI")

                  DEFINE MSDIALOG oDlg TITLE "Seleção de Serviço" FROM 000, 000  TO 220, 500 COLORS 0, 16777215 PIXEL

                        @ 030, 006 SAY oSayFornec PROMPT "Fornecedor:" SIZE 039, 007 OF oDlg COLORS 0, 16777215 PIXEL
                        @ 038, 006 MSGET oCodFornec VAR cCodFornec SIZE 041, 010 OF oDlg COLORS 0, 16777215 PIXEL When .F.
                        @ 038, 050 MSGET oDescFornec VAR cDescFornec SIZE 191, 010 OF oDlg COLORS 0, 16777215 PIXEL When .F.
                        @ 053, 006 SAY oSayTarefa PROMPT "Tarefa:" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
                        @ 062, 005 MSGET oCodTarefa VAR cCodTarefa SIZE 041, 010 OF oDlg COLORS 0, 16777215 PIXEL When .F.
                        @ 062, 050 MSGET oDescTarefa VAR cDescTarefa SIZE 191, 010 OF oDlg COLORS 0, 16777215 PIXEL When .F.
                        @ 077, 006 SAY oSayServico PROMPT "Serviço:" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
                        @ 086, 006 MSGET oCodServico VAR cCodServico SIZE 041, 010 OF oDlg COLORS 0, 16777215 PIXEL F3 "SB1" Valid GatSB1(cCodServico,@oDescServico,@cDescServico)
                        @ 086, 050 MSGET oDescServico VAR cDescServico SIZE 191, 010 OF oDlg COLORS 0, 16777215 PIXEL When .F.


                  ACTIVATE MSDIALOG oDlg ON INIT EnchoiceBar(oDlg, {|| (nOpc := 1 , oDlg:End())}, {|| (nOpc := 2 , oDlg:End())},,aButtons) CENTERED 

                  If nOpc == 1
                        if RecLock("SC1",.F.)
                              //SC1->C1_PRODUTO := cCodServico
                              SC1->C1_DESCRI  := cDescServico
                              SC1->(MsUnlock())
                        endif
                  EndIf

            Endif


      ENDIF

      RestArea(aAreaSTL)
      RestArea(aAreaSB1)
      RestArea(aAreaTT9)
      RestArea(aArea)

Return

/*----------------------------------------------------------------------
- Programa: GatSB1
- Autor: Rafael Brito
- Data: 02/12/2020
- Descrição: Gatilha Descrição do Produto
------------------------------------------------------------------------*/

Static Function GatSB1(cCodServico,oDescServico,cDescServico)

      cDescServico := posicione("SB1",1,xFilial("SB1")+cCodServico,"B1_DESC")

      oDescServico:Refresh()

Return
