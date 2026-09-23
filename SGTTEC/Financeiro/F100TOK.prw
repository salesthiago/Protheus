#Include "rwmake.ch"

/*

ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³ F100TOK  ³ Autor ³ Eder Fernandes do Nascime Data ³ 31/12/2008 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³ Valida Obrigatoriedade do Centro de Custo - Movimentacao Banco ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Observacao³                                                                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³                                          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³             ATUALIZACOES SOFRIDAS DESDE A CONSTRU€AO INICIAL              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Programador   ³  Data  ³              Motivo da Alteracao                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Eder          ³09/02/09³ Validação da Obrigatoriedade da Classe de Valor   ³±±
±±³							no Cadastro do Centro de Custo					  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

User Function F100TOK()

Local _lRet := .t.
Local _cClObrC := "" //Validação de Centro de Custo de Crédito para Classe de Valor Obrigatória
Local _cClObrD := ""//Validação de Centro de Custo de Debito para Classe de Valor Obrigatória

If CRECPAG="P" .and. Empty(M->E5_CCD) .AND. (!M->E5_NATUREZ $ '10010003  /10010014  ')
	Help(" ",1,"CCOBRIGALL")
	_lRet := .f.
EndIf

If CRECPAG="R" .and. Empty(M->E5_CCC) .and. (!M->E5_NATUREZ $ '10010003  /10010014  ')
	Help(" ",1,"CCOBRIGALL")
	_lRet := .f.
EndIf

_cClObrC := Posicione("CTT",1,xFilial("CTT")+M->E5_CCC,"CTT_CLOBRG")//Validação no Cadastro de Centro de Custo a obrigatoriedade da Classe de Valor
_cClObrD := Posicione("CTT",1,xFilial("CTT")+M->E5_CCD,"CTT_CLOBRG")//Validação no Cadastro de Centro de Custo a obrigatoriedade da Classe de Valor
/*
If (SED->ED_X_CLVLR="1" .AND. Empty(M->E5_CLVLDB) .AND. CRECPAG="P") .or. (_cClObrD=="1".AND.Empty(M->E5_CLVLDB))
	MsgBox("A Classe de Valor de Débito não pode ficar vazia, pois irá influênciar na Integração Contábil."+Chr(13)+Chr(10),"Classe de Valor de Débito","Stop")
	_lRet := .f.
EndIf

If (SED->ED_X_CLVLR="1" .AND. Empty(M->E5_CLVLCR) .AND. CRECPAG="R") .or. (_cClObrC=="1".AND.Empty(M->E5_CLVLCR))
	MsgBox("A Classe de Valor de Crédito não pode ficar vazia, pois irá influênciar na Integração Contábil."+Chr(13)+Chr(10),"Classe de Valor de Crédito","Stop")
	_lRet := .f.
EndIf
*/
Return(_lRet)
