#Include 'Protheus.ch'
#Include "TopConn.ch"
#Include "Totvs.ch"

/*/{Protheus.doc} MTA094RO
    Ponto de entrada para adição
    @type  User Function
    @author Stephen Noel - SGTTEC
    @since 09/05/2024
    @version 1.0
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
/*/
User Function MTA094RO()

	Local aRotina:= PARAMIXB[1]
    
	If AllToChar(FWCodEmp()) == '02'
		Aadd(aRotina,{'Liberacao em Lote'   ,"u_LibMassa()"     ,0,4,0,NIL})
		Aadd(aRotina,{'Imprime Mapa'        ,"U_RACOM003('L')"  ,0,4,0,NIL})
  else
		Aadd(aRotina,{'Liberacao em Lote'   ,"u_LibMassa()"     ,0,4,0,NIL})  
		Aadd(aRotina,{'Imprime Mapa'        ,"U_RACOM003('L')"  ,0,4,0,NIL})
  End

  Aadd(aRotina,{'Conhecimento',"U_MSdoc()", 0, 4,0,NIL})

Return (aRotina)

User Function MSdoc()

    Private aRotina := FWloadmenudef('MATA094')

    SC7->(DbSetOrder(1))
    SC7->(DbSeek(xFilial("SC7")+substr(SCR->CR_NUM,1,6)+"0001"))
    
    MsDocument('SC7',SC7->(RecNo()), 4)

return .t.
