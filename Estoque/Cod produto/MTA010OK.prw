#INCLUDE "topconn.ch"     
#INCLUDE "rwmake.ch"
/*
_____________________________________________________________________________
*****************************************************************************
**+-----------------------------------------------------------------------+**
***Programa  * MTA010OK   * Autor * TBC		        * Data * 11/07/08 ***
**+----------+------------------------------------------------------------***
***Descri**o * Ponto de Entrada na validacao da inclusao do produto       ***
***          *                                                            ***
**+----------+------------------------------------------------------------***
***
**+----------+------------------------------------------------------------***
*** Uso      *                                                            ***
**+-----------------------------------------------------------------------+**
*****************************************************************************
*****************************************************************************
*/
 
User Function MTA010OK()
Local _aGrvProd := {}
Local lRet := .T.
Private lMsErroAuto := .F.

If Inclui
	U_RETCODPRO(M->B1_GRUPO,@M->B1_COD)


EndIf

lRet := U_VLDB1NCM()

Return(lRet)

/*
_____________________________________________________________________________
*****************************************************************************
**+-----------------------------------------------------------------------+**
***Programa  * VLDB1NCM   * Autor * TBC                 * Data * 21/08/26 ***
**+----------+------------------------------------------------------------***
***Descri**o * Valida a obrigatoriedade do NCM (B1_POSNCM) no cadastro de ***
***          * produto. O NCM e obrigatorio para qualquer tipo de produto ***
***          * (B1_TIPO), exceto quando o tipo for "MO" (Mao de Obra) ou  ***
***          * "SV" (Servico).                                           ***
**+----------+------------------------------------------------------------***
*** Uso      * Chamada no P.E. MTA010OK (inclusao/alteracao de produto)   ***
**+-----------------------------------------------------------------------+**
*****************************************************************************
*****************************************************************************
*/
User Function VLDB1NCM()
Local lRet := .T.

If !(AllTrim(M->B1_TIPO) $ "MO/SV") .And. Empty(M->B1_POSNCM)
	MsgAlert("O campo NCM (B1_POSNCM) e obrigatorio para produtos que nao sejam do tipo Mao de Obra (MO) ou Servico (SV).","Atencao")
	lRet := .F.
EndIf

Return(lRet)


/*
User Function A010TOK()
 
If Inclui 
	U_RETCODPRO(M->B1_GRUPO,@M->B1_COD)
EndIf
               
Return(.t.)


User Function MT010INC()
Local _aGrvProd := {}
Private lMsErroAuto := .F.

If Inclui 

    //Acrescenta informa**es sobre os campos da SB5
    aadd(_aGrvProd, {"B5_FILIAL"	, SB1->B1_FILIAL	, NIL})
    aadd(_aGrvProd, {"B5_COD"		, SB1->B1_COD		, NIL})
    aadd(_aGrvProd, {"B5_CEMI"		, SB1->B1_DESC	, NIL})
	
	MSExecAuto({|x,y| mata180(x,y)},_aGrvProd,3) //Inclusao
	If lMsErroAuto
		MOSTRAERRO()
	Endif  
	
EndIf
Return .T.
*/

// 
// Validaçãoo:  iif(inclui,U_RETCODPRO(M->B1_GRUPO,@M->B1_COD),.t.)
// 


/*
_____________________________________________________________________________
*****************************************************************************
**+-----------------------------------------------------------------------+**
***Programa  * RETCODPRO  * Autor * TBC                 * Data * 11/07/08 ***
**+----------+------------------------------------------------------------***
***Descri**o * Funcao para determinar qual ser* o proximo numero do produ-***
***          * to para o grupo informado                                  ***
**+----------+------------------------------------------------------------***
*** Uso      *                                                            ***
**+-----------------------------------------------------------------------+**
*****************************************************************************
*****************************************************************************
*/
User Function RETCODPRO(cGrupo,cRetorno)

Local cAlias := Alias()
Local cQuery := ''
Local QAux, nSeq, cRetorno, _cTMS
Local _nTam, _nTamGrupo  := 0

_nTam      := 4
_nTamGrupo := Len(AllTrim(cGrupo))  //TamSX3("B1_GRUPO")[1]//Len(AllTrim(cGrupo))+1
         
cQuery := "SELECT MAX(b1_cod) as NSEQUEN "
cQuery += " FROM "+RetSqlName('SB1')
cQuery += " WHERE "
cQuery +=        "D_E_L_E_T_ <> '*' "
cQuery +=   " AND B1_FILIAL  =  '"+xfilial("SB1")+"'"
cQuery +=   " AND B1_GRUPO   =  '"+cGrupo+"'"
 
cQuery := Changequery(cQuery)           
 
TCQUERY cQuery NEW ALIAS "QAux"
 
nSeq := Soma1(substr(QAux->NSEQUEN,_nTamGrupo+1,_nTam))

QAux->(dbCloseArea())                                        
 
cRetorno := AllTrim(cGrupo)+PADL(nSeq,_nTam,"0")

SB1->(DbSetOrder(1))
do while SB1->(DbSeek(xfilial("SB1")+cRetorno))

	nSeq := Soma1(substr(cRetorno,_nTamGrupo+1,_nTam))

	cRetorno := AllTrim(cGrupo)+PADL(nSeq,_nTam,"0")

	SB1->(DbSkip())
enddo
    
dbselectarea(cAlias)    
 
Return(cRetorno)
