#include "totvs.ch"

/*
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Pto de Entrada Pedindo Senha qdo. Baixa Por Dação          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ SIGAFIN  -  Ctas. a Pagar                                  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/

User Function FA080TIT()
Local senha 

cAlias := alias()

private _qreturn 
_qreturn := ".T."

if FUNNAME() $ "FINA080*FINA750" .AND. CBANCO = 'CX1'
	MSGSTOP("BANCO: "+CBANCO+" NAO AUTORIZADO. BAIXA CANCELADA!")
	CMOTBX:=''
	dbSelectArea(cAlias)
	_qreturn := ".F."
	Return(&_QRETURN)
endif

if FUNNAME() $ "FINA080*FINA750" .AND. CMOTBX = 'DACAO' .AND. MV_XLIBTIT = .T.
     MsgAlert(cText, cTitle)
	if SE2->E2_MLIBDAC <> 2
		MSGSTOP("Titulo Não Liberado Para Baixa Dacao!")
		CMOTBX:=''
		_qreturn := ".F."
	endif
endif	

dbSelectArea(CALIAS)

return(&_qreturn)               
