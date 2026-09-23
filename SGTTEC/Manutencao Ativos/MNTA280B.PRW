/*
Ponto de Entrada que adiciona botões a opção ações relacionadas na rotina de Solicitação de Serviço.

Data:03/2021

Autor: Sinval
*/

User Function MNTA280B()
 
    Local aReturn := {}
       
    Aadd(aReturn, {"Imprime SS"   , "U_MNTR120Q()", 0, 4})
    Aadd(aReturn, {"Visualiza Arq", "U_fAbreArq()", 0, 4})
    
Return aReturn

User Function fAbreArq(cDirP, cNomeArqP)
    Local aArea := GetArea()
    Local cDoc  := TQB->TQB_XDOC
    Local cTipo := TQB->TQB_XTPARQ

    Decode64(cDoc,GetTempPath()+"ARQUIVO."+cTipo,.F.)

    //Tentando abrir o objeto
    nRet := ShellExecute("open", "ARQUIVO."+cTipo, "", GetTempPath(), 1)
     
    //Se houver algum erro
    If nRet <= 32
        MsgStop("Não foi possível abrir o arquivo " +GetTempPath()+"ARQUIVO."+cTipo+ "!", "Atenção")
    EndIf 
     
    RestArea(aArea)
Return
