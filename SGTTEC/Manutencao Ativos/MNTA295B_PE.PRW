User Function MNTA295B()
  
    Local aRet := {}
      
    //Descrição do Botão, Rotina que será executada.
   AAdd(aRet, {"Retorno O.S", "MNTA400(.F.,,,,4,,STJ->(RECNO()))", 0, 4})
   AAdd(aRet, {"Manutencao" , "MNTA120", 0, 4})
  
Return aRet
