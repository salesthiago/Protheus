/*
    Atualiza Data de Vencimento do Borderô
    11/2024
    Sinval
*/
#INCLUDE "TOTVS.CH"

user function FALTVBOR()
    Local cPerg     := "FALTVBOR"
    Local cQuery    := ""
    Local nStatus   := 0

    AjustaSX1(cPerg)

    Pergunte(cPerg,.T.)Ä

	if !ApMsgYesNo("Confirma Alteração do Borderô "+MV_PAR01+" para a Data "+dtoc(MV_PAR02) + " ? ","Confirmação")
		return
	endif

    cQuery := "UPDATE "+retSqlName("SE2") + " SET E2_VENCTO = '"+dtos(MV_PAR02)+"' , E2_VENCREA = '"+dtos(MV_PAR02)+"' "
    cQuery += "WHERE E2_NUMBOR = '"+MV_PAR01+"' "

    nStatus := tcsqlexec(cQuery) 

    If nStatus < 0 
	    MsgStop("Erro na execução da query:"+TcSqlError(), "Atenção")
    else
	    msginfo("Alteração da Data de Vencimento realizada com Sucesso","Importação Ponto")	
    EndIf

return(Nil)


//===============
// AjustaSX1 
//
Static Function AjustaSX1(cPerg)
Local _sAlias 	:= Alias()
Local aRegs 	:= {}
Local i,j

dbSelectArea("SX1")
dbSetOrder(1)
cPerg := PADR(cPerg,10)

//(sx1) Grupo/Ordem/Pergunta/Variavel/Tipo/Tamanho/Decimal/Presel/GSC/Valid/Var01/Def01/Cnt01/Var02/Def02/Cnt02/Var03/Def03/Cnt03/Var04/Def04/Cnt04/Var05/Def05/Cnt05
aAdd(aRegs,{cPerg,"01","Número Borderô   ?"   ,"","","mv_ch1","C", 06,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","",""})
aAdd(aRegs,{cPerg,"02","Nova Data Vencto ?"   ,"","","mv_ch2","D", 08,0,0,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","","","",""})

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
