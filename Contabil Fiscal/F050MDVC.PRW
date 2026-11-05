#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"
/*
Descrição:
O ponto de entrada F050MDVC possibilita que o cliente calcule sua
 própria data de vencimento de ímpostos.
Eventos
É chamado na rotina que calcula a data de vencimento dos impostos.

Programa Fonte
FINA050.PRW
*/

User function F050MDVC()

    Local aArea     := GetArea()
    Local dNextDay  := ParamIxb[1] //data calculada pelo sistema
    Local cIMposto  := ParamIxb[2]
    Local dEmissao  := ParamIxb[3]
    Local dEmis1    := ParamIxb[4]
    Local dVencRea  := ParamIxb[5]
    Local nNextMes  := Month(dVencRea)+1
    
    If cImposto $ "PIS,CSLL,COFINS"//Calcula data 20 do próximo mes

        dNextDay := DataValida(cTod("20"+SubStr(cValToChar(MonthSum(SE2->E2_EMISSAO,1)),3,8)),.F.)

    EndIf

    RestArea(aArea)

Return(dNextDay)

 /*/dNextDay := CTOD("20/"+Iif(nNextMes==13,"01",StrZero(nNextMes,2))+"/"+;
    Substr(Str(Iif(nNextMes==13,Year(dVencRea)+1,Year(dVencRea))),2))//Acho o ultimo dia util do periodo desejado

        dNextday := DataValida(dNextday,.F.)/*/

/*
#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"
USER FUNCTION F050MDVC
Local dVencPR  := ParamIXB[1]
Local cImposto := ParamIXB[2]
Local dEmissao := ParamIXB[3]
Local dEmis1   := ParamIXB[4]
Local dVencRea := ParamIXB[5]
Local dDtVenc  := CToD("31/12/2020")
 ALERT("F050MDVC")
RETURN dDtVenc
*/

/*
USER FUNCTION F050MDVC
    Local dVencPR := ParamIXB[1]
    Local cImposto  := ParamIXB[2]
    Local dEmissao  := ParamIXB[3]
    Local dEmis1    := ParamIXB[4]
    Local dVencRea  := ParamIXB[5]
    Local dDtVenc   := CToD("30/12/2020")

        ALERT("F050MDVC")
        
RETURN dDtVenc

*/


