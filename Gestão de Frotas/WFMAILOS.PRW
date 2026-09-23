/*----------------------------------------------------------------------
- Programa: MT103FIM
- Autor: Adriano Costa
- Data: 02/12/2020
- Descrição: ENvia email da confirmação da entrada da OS
------------------------------------------------------------------------*/

User Function WfMailOS(aItensNF,cOrigem)


	Local cAssunto	:= iif(cOrigem == "SC","Entrada de NF - Referente OS","Baixa Requisição - Referente OS")
	Local cBcc	 	:= ""
	Local cBody    	:= ""
	//Local cCC	 	:= //SuperGetMv("MV_XDESTWF",,"adriano.carneiro@totvs.com.br")
	Local cCC	 	:= SuperGetMv("MV_XDESTWF",,"")
	Local nX        := 0
		
    //Ajusta string e-mail
	if Empty(cCC)
        Return
	endif

    cBody := "<!DOCTYPE HTML PUBLIC '-//W3C//DTD HTML 4.01 Transitional//EN'>"
	cBody += "<html>"
	cBody += "<head>"
	cBody += "<title></title>"
	cBody += "<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>"
	cBody += "</head>"
	cBody += "<body>"
	cBody += "<p>Data: "+dToc(dDatabase)+"   Hora: "+Time()+" <br><br>"
	cBody += "<p><strong>"+cAssunto+"</strong><br><br>" 
	cBody += "</p>"
	cBody += "</p>"
	cBody += "</p>"

    //Monta tabela
    cBody += "  <tr>"
    If cOrigem == "SC"
        cBody += "    <td width='65%'>Nota Fiscal: "+SF1->F1_DOC+"/"+SF1->F1_SERIE+" - "+Posicione("SA2",1,xFilial("SA2")+SF1->F1_FORNECE+SF1->F1_LOJA,"A2_NOME")+" </td>"
    else
        cBody += "    <td width='65%'>Solicitação: "+SCP->CP_NUM+"/"+SCP->CP_ITEM+" </td>"
    EndIf
    cBody += "  </tr>"
    cBody += "  <tr>"
    cBody += "    <td width='65%'> </td>"
    cBody += "  </tr>" 
    cBody += "<table width='99%' border='1'>"
    cBody += "  <tr>"
    cBody += "    <td width='20%' align='left'>Num. OS</td>"
    cBody += "    <td width='20%' align='left'>Produto</td>"
    cBody += "    <td width='40%' align='left'>Descrição</td>" 
    cBody += "    <td width='20%' align='right'>Quantidade</td>"    
    cBody += "  </tr>"
		
    For nX:= 1 to Len(aItensNF)
        cBody += "  <tr>"
        cBody += "    <td width='20%' align='Left'>"+aItensNF[nX][1]+"</td>"
        cBody += "    <td width='20%' align='Left'>"+aItensNF[nX][2]+"</td>"
        cBody += "    <td width='40%' align='Left'>"+aItensNF[nX][3]+"</td>"            
        cBody += "    <td width='20%' align='right'>"+TransForm(aItensNF[nX][4],"@E 999,999,999.999999")+"</td>"
        cBody += "  </tr>"
        cBody += "</table>"+"<br>"
    Next

    //SendMail(cCC,cBcc,cAssunto,cBody)

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
