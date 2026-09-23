#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"

/*/{Protheus.doc} C100VLAT
Ponto de entrada da rotina de Contratos (CNTA300), chamado para decidir se a
operacao de alteracao de um contrato deve ser permitida quando a situacao
atual do contrato nao e "elaboracao" (regra padrao do Protheus bloqueia a
alteracao nesse caso).

Este PE cuida apenas da REGRA DE NEGOCIO (permitir ou nao a alteracao). O
registro do evento na timeline (tabela ZLG) e feito pelo ponto de entrada
CN300PCMT, que dispara logo antes do commit -- ou seja, so registra a
alteracao quando ela de fato for autorizada e prestes a ser gravada. Isso
evita duplicar o mesmo evento em dois pontos de entrada diferentes.

IMPORTANTE: o codigo de situacao "02" abaixo foi fornecido como exemplo padrao
TOTVS para este ponto de entrada -- confirme junto ao dicionario do campo
CN9_SITUAC / CN100SIT se "02" e de fato o codigo que deve permitir a
alteracao neste ambiente.

@type User Function
@param ParamIxb[1] caractere, situacao atual do contrato (CN9_SITUAC)
@param ParamIxb[2] objeto MPFormModel, modelo do CNTA300
@return logical, .T. permite a alteracao, .F. bloqueia
@since 2026-07-27
/*/
//=============================================================================================================================
User Function C100VLAT()
//=============================================================================================================================
    Local lRet    := .T.
    //Local cSituac := ParamIxb[1]
    //Local oModel  := ParamIxb[2]

    //lRet := (cSituac == "02")

Return lRet
