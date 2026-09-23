USER FUNCTION XDESCVA()

Local nCompra   := FBUSCAPD("964","V")
Local nEmpresa  := 0

// Executa apenas se o funcionario tiver a verba de compra VT
If nCompra > 0 .and. cEmpAnt = '02'
        
    if (nCompra * 0.11) > nCompra 
        nValor := nCompra
    else 
        nValor  := (nCompra * 0.11) 
        nEmpresa:= (nCompra - nValor)
        fGeraVerba("951",nEmpresa,1,,SRA->RA_CC,"V",,,,,.T.,,,,,.F.) 
    endif
    
    fGeraVerba("454",nValor,0.11,,SRA->RA_CC,"V",,,,,.T.,,,,,.F.) 

Endif

Return
