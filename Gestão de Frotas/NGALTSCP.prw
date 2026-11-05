#Include 'Protheus.ch'
 
User Function NGALTSCP()
 
    Local cCodProd  := PARAMIXB[1] //Código do Produto
    Local cNumOP    := PARAMIXB[2] //Numero da ordem de produção
    Local aInsSTL   := PARAMIXB[3] //Array com os Insumos(STL)
    Local cItemPos  := PARAMIXB[4] //Código do Item
    Local cPlano    := PARAMIXB[5] //Plano da OS
    Local cTipoReg  := "P"         //Sempre sera realizado apenas para insumos do tipo produto
    Local cSeqRela  := "0  "  
    Local cSeqRelat := "B"      //Apenas altera para insumos previstos
 
    Local aRet      := {} //Array com os novos valores para atualizar a SCP
    Local aRetCab   := {}
    Local aRetItem  := {}
    Local cObsSTL   := ""
 
    dbselectArea( "STL" )
    dbsetorder(2) //TL_FILIAL+TL_TIPOREG+TL_SEQRELA+TL_CODIGO+TL_ORDEM+TL_PLANO
    If dbSeek( xFilial("STL") + cTipoReg + cSeqRela + cCodProd + cNumOP + cPlano)
        //cObsSTL :=  STL->TL_OBSERVA
        cObsSTL :=  "MNT" + "" + STJ->TJ_ORDEM + "  " + STJ->TJ_CODBEM
    EndIf 

    /*dbselectArea( "STJ" )
    dbsetorder(1) 
    If dbSeek( xFilial("STJ") + cNumOP + cPlano + cSeqRelat )
        //cObsSTL :=  STL->TL_OBSERVA
        cObsSTL :=  "MNT" + "" + STJ->TJ_ORDEM + "  " + STJ->TJ_CODBEM
    EndIf */
 
    aRetItem := { {"CP_OBS" ,cObsSTL ,NIL} }
 
    aAdd( aRet , aRetCab )
    aAdd( aRet , aRetItem )
 
Return aRet
