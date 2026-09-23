#include "rwmake.ch"  
#Include "SigaWin.ch"

/*
__________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Programa  ¦ MT100TOK  ¦ Utilizador ¦ Claudio Ferreira ¦ Data ¦ 04/06/12¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ Ponto de Entrada na confirmação da nota de entrada         ¦¦¦
¦¦¦          ¦                                                            ¦¦¦
¦¦¦          ¦ 															  ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦ Uso      ¦ TOTVS-GO                                                   ¦¦¦    
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*/

User Function MT100TOK()      
  Local lRet      := .T.
  Local cForLoj   := CA100FOR+CLOJA
  Local cNFDig    := cNFiscal
  Local cEspNF    := cEspecie
  Local cSerNF    := cSerie

/* desabilitado pois a função VALCCF não está no projeto e não temos o fonte

if ('MATA103'$FUNNAME() .or. 'MATA116'$FUNNAME()) .and. !cTipo $ "D/"
  //Valida o preenchimento do C.Custo para TES Estoque="N" 
  lRet:=U_ValCCNF(aCols,aBackColsSDE)  
  if lRet .and. SuperGetMV("MV_XVALATF",.F.,.T.) //Valida falta da TES Imobilizado
    lRet:=U_ValImob(aCols)
  Endif  
endif
*/

//verifica se existe NF do Fornecedor já classificado
// referência

if !fVerNFFor(cNFDig, cForLoj, cEspNF, cSerNF)
    msginfo("Nota Fiscal Já Digitada para este Fornecedor","NF Digitada")
    lRet := .F.
endif

Return lRet
 
static function fVerNFFor(cNFDig, cForLoj, cEspNF, cSerNF)
  Local lRet      := .T.
  Local cQuery    := ""
  Local cAliasTop :=  getNextAlias()

  cQuery := "SELECT COUNT(F1_FILIAL) QTDENF FROM "+retSqlName("SF1") + " SF1 "
  cQuery += "WHERE SF1.D_E_L_E_T_ = ' ' "
  cQuery += "AND SF1.F1_DOC = '"+strZero(val(cNFDig),9)+"' "
  cQuery += "AND SF1.F1_FORNECE = '"+substring(cForLoj,1,9)+"' AND SF1.F1_LOJA = '"+substring(cForLoj,10,4)+"' "
  cQuery += "AND SF1.F1_STATUS <> ' ' AND SF1.F1_ESPECIE = '"+cEspNF+"' "
  cQuery += "AND SF1.F1_SERIE = '"+cSerNF+"' "
  dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasTop,.T.,.T.)     

  if (cAliasTop)->QTDENF >= 1

    lRet := .F.

  endif

return(lRet)


User Function MT116TOK() 
Local lRet:=.t.  
Private aBackColsSDE:={}
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Ponto de Entrada Padrao                                  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If ExistBlock("MT100TOK")
	lRet := ExecBlock("MT100TOK",.F.,.F.)
	If ValType(lRet) <> "L"
		lRet := .T.
	EndIf
EndIf

Return lRet
