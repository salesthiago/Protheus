/*/{Protheus.doc} F460VAL
    (Retrna o array com as informações do título gerado na liquidação)
    @type  Function
    @author Sinval
    @since 20/04/2021
    @version 1.0
    @example 
    (F460VAL()
    @see 
/*/
#include "totvs.ch"

user function F460VAL()

    Local aBaixa    := {}
    //Local aComplem  := PARAMIXB
    Local _aAreas   := getArea()

    Private lMsErroAuto:= .F.

    if MsgYesNo("Deseja Baixar o Título Gerado na Liquidação ? ","Liquidação")

        aBaixa := { {"E1_PREFIXO"   , SE1->E1_PREFIXO   ,Nil },;
                    {"E1_NUM"       , SE1->E1_NUM       ,Nil },;
                    {"E1_TIPO"      , SE1->E1_TIPO      ,Nil },;
                    {"E1_CLIENTE"   , SE1->E1_CLIENTE   ,Nil },;
                    {"E1_LOJA"      , SE1->E1_LOJA      ,Nil },;
                    {"E1_NATUREZ"   , SE1->E1_NATUREZ   ,Nil },;
                    {"E1_PARCELA"   , SE1->E1_PARCELA   ,Nil },;
                    {"AUTMOTBX"     ,"NOR"              ,Nil },;
                    {"AUTBANCO"     , SE1->E1_BCOCHQ    ,Nil },;
                    {"AUTAGENCIA"   , SE1->E1_AGECHQ    ,Nil },;
                    {"AUTCONTA"     , SE1->E1_CTACHQ    ,Nil },;
                    {"AUTDTBAIXA"   , dDatabase         ,Nil },;
                    {"AUTDTCREDITO" , dDatabase         ,Nil },;
                    {"AUTHIST"      , SE1->E1_HIST      ,Nil }}

        MSExecAuto({|x,y| Fina070(x,y)},aBaixa,3) //3 - Baixa de Título, 5 - Cancelamento de baixa, 6 - Exclusão de Baixa.

        If lMsErroAuto
            MostraErro()
        Endif
    
    endif

    restArea(_aAreas)

return(nil)
