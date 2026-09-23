#include 'protheus.ch'
#include 'parmtype.ch'
#include 'TopConn.ch'

user function F240BORD()
	
	//Função para incluir data de compensação do borderô
	U_UF240BORD(2,cNumBor)

Return

User Function UF240BORD(nOpc,cNumBor)

Local aArea := GetArea()
Local aAreaSE2 := SE2->(GetArea())
Local aAreaSEA := SEA->(GetArea())
Local aParamBox := {}
Local aRet := {}
Default nOpc := 1
Default cNumBor := SE2->E2_NUMBOR

If Empty(cNumBor)
	MsgInfo("Esta rotina acessível apenas para títulos em borderô!")
	Return
EndIf

aAdd(aRet,cNumBor)
If nOpc == 1
	aAdd(aRet,SE2->E2_XDTCOMP)
Else
	aAdd(aRet,dDataBase)
EndIf

aAdd(aParamBox,{1,"Numero Borderô",aRet[1],"","","",".F.",50,.F.})
aAdd(aParamBox,{1,"Data Compensação"  ,aRet[2],"","","","",50,.F.})
 
If MsgYesNo("Desja informar uma data para compensação do borderô?")
	if ParamBox(aParamBox,"Parâmetros",@aRet,,,,,,,.F.,.F.)
		If !Empty(aRet[2]) .Or. nOpc == 1
			Processa( {|| U_UF240CMP(@aRet,cNumBor) }, "Aguarde...", "Gravando data de compensação...",.F.)
		EndIf
	EndIf
EndIf
RestArea(aArea)
RestArea(aAreaSE2)
RestArea(aAreaSEA)	
	
Return

User Function UF240CMP(aParam,cNumBor)

	cQry := ChangeQuery(GeraQry(cNumBor))

	If Select("QSE2")>0
		QSE2->(DbCloseArea())
	Endif
	
	TcQuery cQry New Alias "QSE2" // Cria uma nova area com o resultado do query
	
	ProcRegua(RecCount())
	
	While QSE2->(!Eof())
		SE2->(DbGoTo(QSE2->E2_RECNO))
		If RecLock("SE2",.F.)
				SE2->E2_XDTCOMP := aParam[2]
			SE2->(MsUnlock())
		EndIf
		QSE2->(DbSkip())
	EndDO		
	
return

Static Function GeraQry(cNumBor)

Local cQry     := ""

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³    Monta Query com os dados que serao impressos no relatorio        ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	cQry := "SELECT "
	cQry += "		SE2.R_E_C_N_O_ E2_RECNO ""
	cQry += "FROM "+RetSqlName("SE2")+" SE2 "
	cQry += "WHERE "
	cQry += "	SE2.E2_NUMBOR = 	'"+cNumBor+"' "
	cQry += "	AND SE2.D_E_L_E_T_ <> '*'
	
Return cQry