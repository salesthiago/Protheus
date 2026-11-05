#Include "Protheus.ch"
#Include "TopConn.ch"
 
User Function XDELRGB()
   
Private cPerg := PadR("XDELRGB",10)

ValidPerg(cPerg)

Pergunte(cPerg , .T.)

if !MSGYESNO( "Confirma Exclusão do Movimento do Ponto ? ", "Movimento Ponto" )
    return

endif

cQuery := " DELETE FROM " + retSqlname("RGB") 
cQuery += " WHERE RGB_XLOGDI BETWEEN '" + MV_PAR01 + "' AND '" + MV_PAR02 + "' AND " 
cQuery += " RGB_XLOGHO BETWEEN '" + MV_PAR03 + "' AND '" + MV_PAR04 + "' " 

nStatus := tcsqlexec(cQuery) 

If nStatus < 0 
	MsgStop("Erro na execução da query:"+TcSqlError(), "Atenção")
else
	msginfo("Exclusão realizada com Sucesso","Importação Ponto")	
EndIf

Return

Static Function ValidPerg(cPerg)

Local aAlias := GetArea()
Local aRegs := {}
Local i,j

cPerg := PadR(cPerg, Len(SX1->X1_GRUPO), " ")

aAdd(aRegs,{cPerg, "01", "Data de:	 	","","","mv_ch1","C",10,0,0,"G","","MV_PAR01","","","","","","","","","","","","","","","","","","","","","","","","","","","",".RHMATRIC.","",""})
aAdd(aRegs,{cPerg, "02", "Data Ate:	    ","","","mv_ch2","C",10,0,0,"G","","MV_PAR02","","","","","","","","","","","","","","","","","","","","","","","","","","","",".RHMATRIC.","",""})
aAdd(aRegs,{cPerg, "03", "Hora de:      ","","","mv_ch3","C", 8,0,0,"G","","MV_PAR03","","","","","","","","","","","","","","","","","","","","","","","","","","","",".RHCCUSTO.","",""})
aAdd(aRegs,{cPerg, "04", "Hora Ate:     ","","","mv_ch4","C", 8,0,0,"G","","MV_PAR04","","","","","","","","","","","","","","","","","","","","","","","","","","","",".RHCCUSTO.","",""})

DbSelectArea("SX1")                  
DbSetOrder(1)
For i := 1 to Len(aRegs)
	If !DbSeek(cPerg+aRegs[i,2])
		RecLock("SX1",.T.)
		For j := 1 to FCount()
			FieldPut(j,aRegs[i,j])
		Next
		MsUnlock()
	Endif
Next
RestArea( aAlias )

Return
