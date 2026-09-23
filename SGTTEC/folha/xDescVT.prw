USER FUNCTION XDESCVT()


Local nBase     := FBUSCAPD("353","V") + FBUSCAPD("354","V")
Local nCompra   := FBUSCAPD("963","V")
Local nEmpresa  := 0

// Executa apenas se o funcionario tiver a verba de compra VT
If nCompra > 0 .and. cEmpAnt = '02'
        
    if (nBase * 0.06) > nCompra 
        nValor := nCompra
    else 
        nValor  := (nBase * 0.06) 
        nEmpresa:= (nCompra - nValor)
        fGeraVerba("754",nEmpresa,1,,SRA->RA_CC,"V",,,,,.T.,,,,,.F.) 
    endif
    
    fGeraVerba("519",nValor,0.06,,SRA->RA_CC,"V",,,,,.T.,,,,,.F.) 

Endif
  
Return
