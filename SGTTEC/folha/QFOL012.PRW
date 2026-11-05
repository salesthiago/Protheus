#Include "Protheus.ch"
#Include "TopConn.ch"
 
User Function QFOL012()
   
    Local cFicMed   := ""
    Local cAliasTop := getnextalias()
    
    Private cPerg   := PadR("QFOL012",10)

    ValidPerg(cPerg)

    Pergunte(cPerg , .T.)

    if !MSGYESNO( "Confirma Limpeza no Sesmt da Matrícula "+MV_PAR01 + " ? ", "Movimento" )
        return
    endif

    /*
    cQuery := "SELECT TM0_FILIAL, TM0_NUMFIC "
    cQuery += "FROM "+retSqlName("TM0") + " TM0 "
    cQuery += "WHERE TM0.D_E_L_E_T_ = ' ' "
    cQuery += "AND TM0.TM0_MAT = '"+MV_PAR01+"' AND TM0.TM0_FILIAL = '"+cFilant+"' "
    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasTop,.T.,.T.)

    (cAliasTop)->(DbGoTop())
    cFicMed := (cAliasTop)->TM0_NUMFIC

    (cAliasTop)->(DbCloseArea())

    if !empty(cFicMed)

        TM0->(DbSetorder(1))
        if TM0->(DbSeek(cFilAnt+cFicMed))
            TM0->(RecLock("TM0",.F.))
            TM0->TM0_MAT = ""
            TM0->(MsUnlock())
        EndIf

        TM5->(DbSetorder(1))
        if TM5->(DbSeek(cFilAnt+cFicMed))
            TM5->(RecLock("TM5",.F.))
            TM5->TM5_MAT = ""
            TM5->(MsUnlock())
        EndIf

    EndIf

    */
    
    TM0->(DbSetorder(11))
    if TM0->(DbSeek(xFilial("TM0")+MV_PAR01))
        do while TM0->(!Eof()) .and. TM0->(TM0_FILIAL+TM0_MAT) == xFilial("TM0")+MV_PAR01

            cNumFic := TM0->TM0_NUMFIC

            TM0->(RecLock("TM0",.F.))
            TM0->TM0_LOCFIC := TM0->TM0_MAT
            TM0->TM0_MAT = ""
            TM0->(MsUnlock())

            TM5->(DbSetorder(1))
            if TM5->(DbSeek(xFilial("TM5")+cNumFic))
                do while TM5->(!Eof()) .and. TM5->(TM5_FILIAL+TM5_NUMFIC) == xFilial("TM5")+cNumFic

                    TM5->(RecLock("TM5",.F.))
                    TM5->TM5_OBSERV := TM5->TM5_MAT
                    TM5->TM5_MAT = ""
                    TM5->(MsUnlock())

                    TM5->(DbSeek(xFilial("TM5")+cNumFic))
                    
                    //TM5->(DbSkip())
                enddo
            EndIf

            TM0->(DbSeek(xFilial("TM0")+MV_PAR01))

            //TM0->(DbSkip())
        enddo
    EndIf

    TMJ->(DbSetorder(9))
    if TMJ->(DbSeek(xFilial("TMJ")+MV_PAR01))
        do while TMJ->(!Eof()) .and. TMJ->(TMJ_FILIAL+TMJ_MAT) == xFilial("TMJ")+MV_PAR01
            TMJ->(RecLock("TMJ",.F.))
            TMJ->TMJ_OBSCON := TMJ->TMJ_MAT
            TMJ->TMJ_MAT = ""
            TMJ->(MsUnlock())

            TMJ->(DbSeek(xFilial("TMJ")+MV_PAR01))

            //TMJ->(DbSkip())
        enddo
    EndIf

    RFV->(DbSetorder(1))
    if RFV->(DbSeek(xFilial("RFV")+MV_PAR01))
        do while RFV->(!Eof()) .and. RFV->(RFV_FILIAL+RFV_MAT) = xFilial("RFV")+MV_PAR01
            RFV->(RecLock("RFV",.F.))
            RFV->(dbDelete())
            RFV->(MsUnlock())
            RFV->(DbSkip())
        EndDo
    endif

    RI1->(DbSetorder(1))
    if RI1->(DbSeek(xFilial("RI1")+MV_PAR01))
        do while RI1->(!Eof()) .and. RI1->(RI1_FILIAL+RI1_MAT) = xFilial("RI1")+MV_PAR01
            RI1->(RecLock("RI1",.F.))
            RI1->(dbDelete())
            RI1->(MsUnlock())
            RI1->(DbSkip())
        EndDo
    endif

    lTemSaldo := .F.
    TNF->(DbSetOrder(3))
    if TNF->(DbSeek(cFilAnt+MV_PAR01))
        do while TNF->(!Eof()) .and. TNF->(TNF_FILIAL+TNF_MAT) == cFilAnt+MV_PAR01
            if TNF->(TNF_QTDENT-TNF_QTDEVO) > 0
                lTemSaldo := .T.
            endif
            TNF->(DbSkip())
        EndDo

    endif

    if lTemSaldo
	    msginfo("Matrícula Possui Saldo de EPI, favor realizar a devolução Total","Exclusão Matrícula")
    else

        TNF->(DbSetOrder(3))
        if TNF->(DbSeek(cFilAnt+MV_PAR01))
            do while TNF->(!Eof()) .and. TNF->(TNF_FILIAL+TNF_MAT) == cFilAnt+MV_PAR01
                TNF->(RecLock("TNF",.F.))
                TNF->TNF_NSERIE := TNF->TNF_MAT
                TNF->TNF_MAT := ""
                TNF->(MsUnlock())

                TNF->(DbSeek(cFilAnt+MV_PAR01))

            EndDo

            msginfo("Exclusão realizada com Sucesso","Exclusão Matrícula")
        
        endif

    endif
Return

Static Function ValidPerg(cPerg)

Local aAlias := GetArea()
Local aRegs := {}
Local i,j

cPerg := PadR(cPerg, Len(SX1->X1_GRUPO), " ")

aAdd(aRegs,{cPerg, "01", "Matrícula ?	","","","mv_ch1","C",06,0,0,"G","","MV_PAR01","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})

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
