#include "rwmake.ch"
/*
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Pto de Entrada Pedindo Senha qdo. Baixa Por Dação          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ SIGAFIN  -  Ctas. a Pagar                                  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/

User Function FA070TIT()

cAliais := alias()

Private _qreturn 
_qreturn := ".T."


if FUNNAME() $ "FINA070*FINA740" .AND. CBANCO = 'CX1'
	MSGSTOP("BANCO: "+CBANCO+" NAO AUTORIZADO. BAIXA CANCELADA!")
	CMOTBX:=''
	dbSelectArea(cAlias)
	_qreturn := ".F."
	Return(&_QRETURN)
endif

if FUNNAME() $ "FINA070*FINA740" .AND. CMOTBX = 'DACAO'
	if SE1->E1_MLIBDAC <> "3"
		MSGSTOP("Titulo Nao Liberado Para Baixa Dacao!")
		CMOTBX:=''
		_qreturn := ".F."
	endif
else
	if SE1->E1_MLIBDAC <> "0"
		MSGSTOP("Titulo Liberado Para Baixa Dacao, Verifique!")
		CMOTBX:=''
		_qreturn := ".F."
	endif
endif

dbSelectArea(cAlias)
Return(&_QRETURN)