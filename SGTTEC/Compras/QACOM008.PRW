/*

Função para trazer a placa no pedido de vendas a partir da OS da sc

*/

user function QACOM008(cFilSC, cNumSC, cItemSC)
    Local cRet      := ""
    Local cNUmOS    := ""

    cNumOS := substr(Posicione("SC1",1,cFilSC+cNumSC+cItemSC,"C1_OP"),1,6)

    if !Empty(cNumOS)
        cCodbem := Posicione("STJ",1,cFilSC+cNumOS,"TJ_CODBEM")
		cAno    := Posicione("ST9",1,cFilSC+cCodbem,"T9_ANOMOD")
		cModelo := Posicione("ST9",1,cFilSC+cCodbem,"T9_MODELO")  
        cRet    := cCodBem + " - " + cAno + " - " + cModelo      
    endif

return(cRet)
