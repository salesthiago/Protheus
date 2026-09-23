/* Ponto de entrada para substituir a impressão da OS na abertura da Corretiva
//Define Array contendo as Rotinas a executar do programa     
// ----------- Elementos contidos por dimensao ------------    
// 1. Nome a aparecer no cabecalho                             
// 2. Nome da Rotina associada                                 
// 3. Usado pela rotina                                        
// 4. Tipo de Transa‡„o a ser efetuada                         
//    1 - Pesquisa e Posiciona em um Banco de Dados            
//    2 - Simplesmente Mostra os Campos                        
//    3 - Inclui registros no Bancos de Dados                  
//    4 - Altera o registro corrente                           
//    5 - Remove o registro corrente do Banco de Dados         
//    6 - Altera determinados campos sem incluir novos Regs    
// parâmetros para a chamada da rotina     
// lPARI,,,,4,aMATSX1,nRecOs
// NGIMP675(stj->tj_ordem, stj->tj_plano, .F., , STJ->(RECNO()) )
*/

User Function MNTA420C()

    Local nPos := AScan(aRotina, {|x| UPPER(x[1]) == "IMPRIMIR" })
    

    aRotina[nPos][2] := "U_QMNTR675(.F.,,,,4,,STJ->(RECNO()))"
    AAdd(aRotina, {"Imprime O.S", "U_QMNTR676(.F.,,,,4,,STJ->(RECNO()))", 0, 3})
    AAdd(aRotina, {"Retorno O.S", "MNTA400(.F.,,,,4,,STJ->(RECNO()))", 0, 3})

Return aRotina
