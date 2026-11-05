#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "fileio.ch"

/*/{Protheus.doc} CTA100MNU
CTA100MNU - Manutenção de contratos.
@type class 
@author 
@since 
@version 
@obs LOCALIZAÇÃO : Function CNTA100 - Rotina Responsável pela Manutenção de Contratos.
EM QUE PONTO : Antes de montar a tela do browser.
UTILIZAÇÃO : Para adicionar botões no menu principal da rotina.
@link https://tdn.totvs.com/pages/releaseview.action?pageId=6089605
@history 
/*/
//=============================================================================================================================
    User Function CTA100MNU()
//=============================================================================================================================

    Local aArea := GetArea()

    aadd(aRotina,{"#Exportar Itens (Medição)","U_RT69M001()",0,4,58,Nil,Nil,Nil})
    aadd(aRotina,{"#Importar Itens (Medição)","U_RT69M002()",0,4,58,Nil,Nil,Nil})
    //aadd(aRotina,{"Importar / Exportar Itens do contrato","U_RTM002App()",0,4,58,Nil,Nil,Nil})
    aadd(aRotina,{"Histórico Contrato","U_RT69M003()",0,4,58,Nil,Nil,Nil})
    //aadd(aRotina,{"Cadastro de Contratos (nova tela)","U_RTM003App()",0,4,58,Nil,Nil,Nil})
    RestArea(aArea)
Return Nil 


