
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³MNTA4204  ºAutor  ³Adriano Costa º Data ³  08/12/20   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ PONTO DE ENTRADA CHAMADO APOS GRAVACAO DA OS CORRETIVA     º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/   
       
#include "rwmake.ch"
#include "ap5mail.ch"
#include "colors.ch"
#include "font.ch"
#include "Topconn.ch"
#Include "prtopdef.ch"    

       
USER FUNCTION MNTA4204()

// GRAVA AUTOMATICAMENTE A HORA DE PARADA REAL INICIAL DA OS
// E A DATA DE PARADA REAL, MAS PERMITE ALTERAR NO RETORNO
RECLOCK("STJ",.F.)
	STJ->TJ_HOPRINI := M->TJ_HRDIGIT
	STJ->TJ_DTPRINI := M->TJ_DTORIGI
MSUNLOCK("STJ") 

//f420Mail() - Não enviar mais e-mail (Sinval)

Return

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ ENVIA E-MAIL ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Static Function f420Mail()
Local cMsg
Local cAssunto := "Ordem de Serviço"
Local cCC       := SuperGetMv("MV_XDESTOS",,"")
Local cBcc	 	:= ""

    cMsg := "<!DOCTYPE HTML PUBLIC '-//W3C//DTD HTML 4.01 Transitional//EN'>"
	cMsg += '<html>'
	cMsg += '<head>'
	cMsg += '<title></title>'
	cMsg += "<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>"
	cMsg += '</head>'
	cMsg += '<body>'
	cMsg += '<p>Data: "+dToc(dDatabase)+"   Hora: "+Time()+" <br><br>'
	cMsg += '<p><strong>'+cAssunto+'</strong><br><br>' 
	cMsg += '</p>'
	cMsg += '</p>'
	cMsg += '</p>'            
	cMsg += '<html><head><title>OS Corretiva</title></head><body>'
	
	cMsg :='<style type="text/css">'
	cMsg +="body{font-size:12px}"
	cMsg +=".fix{background:#efefef}"
	cMsg +=".tab{font-family:arial;border-collapse:collapse;border-color:#cccccc}"
	cMsg +='</style>'
	
	cMsg +='<table class="tab" width="100%" border="1">'
	
	cMsg +='<tr>'
	cMsg +='<td colspan="4" style="background:#cccccc">Abertura de Ordem de Serviço Corretiva</td>'
	cMsg +='</tr>'
	
	cMsg +='<tr>'
	cMsg +='<td class="fix" width="110">Número</td>'
	cMsg +='<td>'+STJ->TJ_ORDEM+'</td>'
	cMsg +='<td class="fix" width="120">Data Original</td>'
	cMsg +='<td>'+DtoC(STJ->TJ_DTORIGI)+'</td>'
	cMsg +='</tr>'
	
	cMsg +='<tr>'
	cMsg +='<td class="fix">Bem</td>'
	cMsg +='<td>'+STJ->TJ_CODBEM+'</td>'
	cMsg +='<td class="fix">Nome do Bem</td>'
	cMsg +='<td>'+Posicione("ST9",1,xFilial("ST9")+STJ->TJ_CODBEM,"T9_NOME")+'</td>'
	cMsg +='</tr>'
	
	
	cMsg +='<tr>'
	cMsg +='<td class="fix">Serviço</td>'
	cMsg +='<td>'+STJ->TJ_SERVICO+'</td>'
	cMsg +='<td class="fix">Nome do Serviço</td>'
	cMsg +='<td>'+Posicione("ST4",1,xFilial("ST4")+STJ->TJ_SERVICO,"T4_NOME")+'</td>'
	cMsg +='</tr>'
	
	cMsg +='<tr>'
	cMsg +='<td class="fix">Observação</td>'
	cMsg +='<td colspan="3">'+STJ->TJ_OBSERVA+'</td>'
	cMsg +='</tr>'
	
	cMsg +='<tr>'
	cMsg +='<td class="fix">Situação</td>'
	cMsg +='<td>'+Iif(STJ->TJ_SITUACA=="P","Pendente",Iif(STJ->TJ_SITUACA=="L","Liberado","Cancelado"))+'</td>'
	cMsg +='<td class="fix">Hodômetro:</td>'
	cMsg +='<td>'+cValToChar(STJ->TJ_POSCONT)+'</td>'
	cMsg +='</tr>'

	cMsg +='<tr>'
	cMsg +='<td class="fix">Centro de custo</td>'
	cMsg +='<td>'+STJ->TJ_CCUSTO+'</td>'
	cMsg +='<td class="fix">Nome do Centro de Custo</td>'
	cMsg +='<td>'+Posicione("CTT",1,xFilial("CTT")+STJ->TJ_CCUSTO,"CTT_DESC01")+'</td>'
	
	cMsg +='</tr>'

		
	cMsg +='</table>'
	
	
	cAssunto := "*** ABERTURA DE O.S. CORRETIVA "+STJ->TJ_ORDEM+" ***"
	// SendMail(cCC,cBcc,cAssunto,cMsg)
Return


/*----------------------------------------------------------------------
- Programa: SendMail
- Autor: Rafael Brito
- Data: 17/11/2020
- Descrição: Envia e-mail aos destinatarios
------------------------------------------------------------------------*/
Static Function SendMail(cCC,cBcc,cAssunto,cBody)

	local oServer  	:= Nil
	local oMessage 	:= Nil
	local nErr     	:= 0
	local nx
	local cPopAddr  := AllTrim(GetMv('MV_WFPOP3'))    // Endereco do servidor POP3
	local cSMTPAddr := AllTrim(GetMv('MV_RELSERV'))   // Endereco do servidor SMTP
	local cPOPPort  := GetMv("MV_PORPOP3") 	  		  // Porta do servidor POP
	local cSMTPPort := GetMv("MV_PORSMTP") //587      // Porta do servidor SMTP
	local cUser     := AllTrim(GetMv('MV_RELACNT'))   // Usuario que ira realizar a autenticacao
	local cPass     := AllTrim(GetMV('MV_RELAPSW'))   // Senha do usuario
	local nSMTPTime := GetMV("MV_RELTIME")            // Timeout SMTP             
	local lSSL      := GetMV("MV_RELSSL")			  // SSL
	Local lTLS		:= GetMV("MV_RELTLS")	          // TLS
	Local lAuth     := GetMV("MV_RELAUTH")	  		  // Auth?
	
	Local aFiles  := {}

	nPos := At(":",cSMTPAddr)
	if nPos > 0
		cSMTPAddr := SubStr(cSMTPAddr,1,nPos - 1)
	endif

	nPos := At(":",cPopAddr)
	if nPos > 0
		cPopAddr := SubStr(cPopAddr,1,nPos - 1)
	endif

	// Instancia um novo TMailManager
	oServer := tMailManager():New()    
	If lAuth
		oServer:SMTPAuth( cUser, cPass )// Usa Auth?
	EndIf
	oServer:setUseSSL(lSSL)// SSL?
	oServer:SetUseTLS(lTLS)// TLS?
	oServer:init(cPopAddr, cSMTPAddr, cUser, cPass, cPOPPort, cSMTPPort)

	// Define o Timeout SMTP
	if oServer:SetSMTPTimeout(nSMTPTime) != 0  
		MsgInfo("[ERROR]Falha ao definir timeout","SendMail")  
		return .F.
	endif

	// Conecta ao servidor
	nErr := oServer:smtpConnect()
	if nErr <> 0  
		MsgInfo("[ERROR]Falha ao conectar: " + oServer:getErrorString(nErr),"SendMail")   
		oServer:smtpDisconnect()  
		return .F.
	endif  

	// Realiza autenticacao no servidor
	nErr := oServer:smtpAuth(cUser, cPass)
	if nErr <> 0  
		MsgInfo("[ERROR]Falha ao autenticar: " + oServer:getErrorString(nErr),"SendMail")   
		oServer:smtpDisconnect()  
		return .F.

	endif

	// Cria uma nova mensagem (TMailMessage)
	oMessage 		  := tMailMessage():new()
	oMessage:clear()
	oMessage:cFrom    := cUser //Indica o endereço de uma conta de e-mail (remetente) para representar o e-mail enviado. Exemplo: usuario@provedor.com.br.
	oMessage:cTo      := cCC//pra quem vai o email //Indica o endereço de uma conta de e-mail que será utilizada para enviar o respectivo e-mail.
	oMessage:cCC      := "" ///AllTrim(GetMv("MV_RELFROM"))    //Indica o endereço de e-mail, na seção Com Cópia (CC), que receberá a mensagem.
	oMessage:cBCC     := cBcc    //Indica o endereço de e-mail, na seção Cópia Oculta, que receberá a mensagem.
	oMessage:cSubject := cAssunto   //Indica o assunto do e-mail. Caso não seja especificado, o assunto será enviado em branco.
	oMessage:cBody    := cBody    //Indica o conteúdo da mensagem que será enviada.

	
	For nX := 1 To Len(aFiles)

		If !Empty(aFiles[nX]) .AND. oMessage:AttachFile(aFiles[nX])  < 0

			MsgInfo("[ERROR] Falha ao anexar arquivo " + aFiles[nX] + ":" + oServer:getErrorString(nErr),"SendMail")

		EndIf

	Next

	// Envia a mensagem
	nErr := oMessage:send(oServer)
	
	if nErr <> 0  
		MsgInfo("[ERROR]Falha ao enviar: " + oServer:getErrorString(nErr),"SendMail")  
		oServer:smtpDisconnect()  
		return(.F.)

	endif

	// Disconecta do Servidor
	oServer:smtpDisconnect()

return(.T.)
