#include 'protheus.ch'
#include 'Restful.ch'
#INCLUDE "REPORT.CH"
#include "rptdef.ch"
#include "TBICONN.CH"

WSRESTFUL CkListAPI02 DESCRIPTION "eOpera - Checklist" FORMAT "application/json,text/html" 
	WSDATA cpf  	as String Optional
	WSDATA lider	as String Optional

	WSMETHOD POST IncluirCheckList 		DESCRIPTION 'Inclusão Respostas Check List' 	WSSYNTAX '/CkListAPI02/IncluirCheckList'
	WSMETHOD GET  consultarCheckList 	DESCRIPTION 'Consulta Check List'   			WSSYNTAX '/CkListAPI02/consultarCheckList/{cpf}{lider}'

END WSRESTFUL

WSMETHOD GET consultarCheckList WSRECEIVE Cpf, lider WSSERVICE CkListAPI02
	Local lRet 		:= .T.
	Local oResponse	:= JsonObject():New()
    Local cQuery    := ""
	Local cEOL 		:= Chr(13)+Chr(10)
	Local aDestino	:= {"Veiculos", "Equipes", "SESMT", "EPI/EPC/Ferramentas", "Leiturista","Eletricista","APR","IPAL/Int","Lib/Frota"}
	Local aTables   := {"ZCI", "ZCC", "ZC9", "ZCE", "ZC7", "ZC0", "ZCO", "ZC8", "ZC4"} 
	
	/*1=Veiculos;2=Equipes;3=Sesmt/IPAL;4=Epi/Epc/Ferramentas;5=Leiturista;6=Eletricista;7=APR;8=IPAL/Int;9=Lib.Frota 
	/*
    obrigatorio informar o cpf
    */ 

    if cEmpAnt = "02"
        cFilref := "0201"
    else
        cFilRef := "0101"
    endif
	
	RpcClearEnv()
    RpcSetType(3)
    RpcSetEnv(cEmpAnt, cFilref,,,,GetEnvServer(),aTables)
	
	//PREPARE ENVIRONMENT EMPRESA cEmpAnt Filial cFilref TABLES  "ZCI", "ZCC", "ZC9", "ZCE", "ZC7", "ZC0", "ZCO", "ZC8", "ZC4" MODULO "EST"

    IF Empty(Self:cpf)
        SetRestFault(400,EncodeUTF8('O parametro CPF é obrigatório'))
        lRet    := .F.
        Return(lRet)
    EndIF

    //Retorna apenas o Tipo Json
	::SetContentType('application/json')
	
    //Query que irá retornar o Check-list
    cAliasTop := GetNextAlias()
    cQuery := "SELECT ZC0.ZC0_CODCHE CODIGO, ZC0.ZC0_DESCHE NOME, ZC0.ZC0_DESTIN DESTINO,ZCC.ZCC_CPF CPF, ZCC.ZCC_CODLEI LEITURISTA, "+cEOL
    cQuery += "ZC7.ZC7_GRUPER GRUPER, ZC7.ZC7_SEQPER SEQPERG, ZC7.ZC7_CODPER CODPERG,  ZCO.ZCO_DESRES NOMPERG,		"+cEOL
    cQuery += "ZC7.ZC7_NECFOT NECFOTO, ZC7.ZC7_FOTNEG FOTONEG, ZC7.ZC7_INFFOT INFFOTO, ZC7.ZC7_QTDFOT QTDFOTO,		"+cEOL
    cQuery += "ZC7.ZC7_NECJUS NECJUST, ZC8.ZC8_SEQRES SEQRESP, ZC8.ZC8_CODRES CODRESP,                   	 		"+cEOL
    cQuery += "ZC4.ZC4_DESRES RESPOSTA, ZC4.ZC4_TIPRES TIPORES, ZCO.ZCO_RESPNC RESPNC						 		"+cEOL
    cQuery += "FROM "+retSqlName("ZCC") + " ZCC 															 		"+cEOL
    cQuery += "INNER JOIN "+retSqlName("ZC9") + " ZC9 ON (ZC9.D_E_L_E_T_ = ' ' AND ZC9.ZC9_CODGRU = ZCC.ZCC_CODGRU) "+cEOL
    cQuery += "INNER JOIN "+retSqlName("ZCE") + " ZCE ON (ZCE.D_E_L_E_T_ = ' ' AND ZCE.ZCE_CODGRU = ZCC.ZCC_CODGRU) "+cEOL
    cQuery += "INNER JOIN "+retSqlName("ZC7") + " ZC7 ON (ZC7.D_E_L_E_T_ = ' ' AND ZC7.ZC7_CODCHE = ZCE.ZCE_CODCHE) "+cEOL

	if Self:lider = "N"
    	cQuery += "INNER JOIN "+retSqlName("ZC0") + " ZC0 ON (ZC0.D_E_L_E_T_ = ' ' AND ZC0.ZC0_CODCHE = ZCE.ZCE_CODCHE "+cEOL 
		cQuery += "AND ZC0.ZC0_DESTIN NOT IN ('1','7') AND ZC0.ZC0_LIDER = 'N' ) "+cEOL
	else
    	cQuery += "INNER JOIN "+retSqlName("ZC0") + " ZC0 ON (ZC0.D_E_L_E_T_ = ' ' AND ZC0.ZC0_CODCHE = ZCE.ZCE_CODCHE ) "+cEOL
	endif

    cQuery += "INNER JOIN "+retSqlName("ZCO") + " ZCO ON (ZCO.D_E_L_E_T_ = ' ' AND ZCO.ZCO_CODPER = ZC7.ZC7_CODPER) 		"+cEOL
    cQuery += "INNER JOIN "+retSqlName("ZC8") + " ZC8 ON (ZC8.D_E_L_E_T_ = ' ' AND ZC8.ZC8_CODCHE = ZC7.ZC7_CODCHE  		"+cEOL
    cQuery += "AND ZC8.ZC8_GRUPER = ZC7.ZC7_GRUPER AND ZC8.ZC8_SEQPER = ZC7.ZC7_SEQPER AND ZC8.ZC8_CODPER = ZC7.ZC7_CODPER) "+cEOL
    cQuery += "INNER JOIN "+retSqlName("ZC4") + " ZC4 ON (ZC4.D_E_L_E_T_ = ' ' AND ZC4.ZC4_CODRES = ZC8.ZC8_CODRES) 		"+cEOL
	cQuery += "WHERE ZCC.D_E_L_E_T_ = ' ' AND ZCC.ZCC_CPF = '"+alltrim(self:cpf)+"' 										"+cEOL
	cQuery += "ORDER BY CODIGO, GRUPER, SEQPERG, CODPERG, SEQRESP, CODRESP 													"+cEOL
    cQuery := ChangeQuery(cQuery)
    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasTop,.T.,.T.)

	conout("Consultando CheckList Cadastrado")

	oResponse['status'] := 200  // parâmetro que irá retornar com sucesso
	oResponse['dados']	:= {}

	cCodigoCL := ""
	(cAliasTop)->(DbGoTop())
	do While (cAliasTop)->(!Eof())

		oJsonCL := JsonObject():New()
		
		oJsonCL['codigoCheckList']	:= (cAliasTop)->CODIGO
		oJsonCL['nomeCheckList'] 	:= alltrim((cAliasTop)->NOME)
		oJsonCL['destinoCheckList']	:= aDestino[ val((cAliasTop)->DESTINO) ]		
		oJsonCL['perguntas']		:= {}
		
		nPosPerg := 1
		cCodigoCL := (cAliasTop)->CODIGO
		do while (cAliasTop)->(!Eof()) .and. (cAliasTop)->CODIGO == cCodigoCL

			aAdd( oJsonCL['perguntas'], JSONObject():New() )
			oJsonCL['perguntas'][nPosPerg]['seqPergunta'] 			:= (cAliasTop)->SEQPERG
			oJsonCL['perguntas'][nPosPerg]['codPergunta'] 			:= (cAliasTop)->CODPERG
			oJsonCL['perguntas'][nPosPerg]['nomePergunta'] 			:= EncodeUTF8(alltrim((cAliasTop)->NOMPERG))
			oJsonCL['perguntas'][nPosPerg]['necessitaFoto'] 		:= (cAliasTop)->NECFOTO
			oJsonCL['perguntas'][nPosPerg]['qtdeFotos']				:= (cAliasTop)->QTDFOTO 		
			oJsonCL['perguntas'][nPosPerg]['fotoRespNegativa'] 		:= (cAliasTop)->FOTONEG
			oJsonCL['perguntas'][nPosPerg]['inforFotos'] 			:= EncodeUTF8(alltrim((cAliasTop)->INFFOTO))
			oJsonCL['perguntas'][nPosPerg]['necessitaJusticativa'] 	:= (cAliasTop)->NECJUST
			oJsonCL['perguntas'][nPosPerg]['respNC'] 				:= (cAliasTop)->RESPNC
		
			oJsonCL['perguntas'][nPosPerg]['respostas'] := {}

			cResposta 	:= (cAliasTop)->(CODIGO+SEQPERG+CODPERG) 
			nPosResp 	:= 1
			do while (cAliasTop)->(!Eof()) .and. (cAliasTop)->(CODIGO+SEQPERG+CODPERG) == cResposta

				aAdd( oJsonCL['perguntas'][nPosPerg]['respostas'], JSONObject():New() )
				oJsonCL['perguntas'][nPosPerg]['respostas'][nPosResp]['seqResposta'] := (cAliasTop)->SEQRESP
				oJsonCL['perguntas'][nPosPerg]['respostas'][nPosResp]['codResposta'] := (cAliasTop)->CODRESP
				oJsonCL['perguntas'][nPosPerg]['respostas'][nPosResp]['infResposta'] := EncodeUTF8(alltrim((cAliasTop)->RESPOSTA))
				oJsonCL['perguntas'][nPosPerg]['respostas'][nPosResp]['tipResposta'] := (cAliasTop)->TIPORES
				nPosResp++
				
				(cAliasTop)->(dbSkip())
			EndDo
			nPosPerg++
		EndDo
		aAdd(oResponse['dados'], oJsonCL)
	EndDo
	
	::SetResponse(oResponse:ToJson())

	RpcClearEnv()
	//RESET ENVIRONMENT

Return lRet 

//inclusão das respostas do Check List
WSMETHOD POST IncluirCheckList WSSERVICE CkListAPI02
	Local lRet 		:= .T.
	Local cJson		:= ::getContent()
	Local aRet 		:= {}
	Local oResponse, oJson
	Local aTables   := {"ZCI", "ZCC", "ZC9", "ZCE", "ZC7", "ZC0", "ZCO", "ZC8", "ZC4", "ZCJ", "ZCK", "ZDF", "ZDG", "ST9", "TQB","ZDQ", "ZDR"} 	

    if cEmpAnt = "02"
        cFilref := "0201"
    else
        cFilRef := "0101"
    endif

	RpcClearEnv()
    RpcSetType(3)
    RpcSetEnv(cEmpAnt, cFilref,,,,GetEnvServer(),aTables)

    //Retorna apenas o Tipo Json
	::SetContentType('application/json')

	oResponse	:= JsonObject():New()
	oJson		:= JsonObject():New()
	
	oJson:FromJson(cJson)

	conout("Incluindo CheckList CKLIST02 --> "+oJson['ZCI_IDMOV']+" - CPF: "+oJson['ZCI_CPF']+"  "+oJson['ZCI_CODCHE'] )

	//verifica se possui IPAL/Ronda
	lIpal 	:= "ZD7_EQUIPE" $ cJson
	lEqpNC	:= "ZCK_EQUIPN" $ cJson
	lTipMov := "ZCI_ENTSAI" $ cJson
	lPA 	:= "ZCI_PAPOIO" $ cJson

	if "ZCI_DTABER" $ cJson
		dDataInc 	:= stod(oJson["ZCI_DTABER"])
	else
		dDataInc	:= dDataBase
	endif	

	aRet	:= restMovimento(oJson, lIpal, lEqpNC, lTipMov, lPA, dDataInc)  
	
	If aRet[1]
		oResponse['status'] := 200
		oResponse['message']:= aRet[2]
		::SetResponse(oResponse:toJson())
	Else
		lRet := .F.
		SetRestFault(400, aRet[2])
	EndIf

	RpcClearEnv()
	//RESET ENVIRONMENT

Return lRet

/* Função para realizar os registros nas tabelas
ZCI, ZCJ, ZCK, ZCL
*/

Static Function restMovimento(oJson, lIpal, lEqpNC, lTipMov, lPA, dDataInc)
	Local aRet 			:= {}
	Local nFotos		:= 1
	Local nRespostas	:= 1
	//Local nIpal 		:= 1
	Local nPerguntas	:= 1
	//Local bFechado      := .T. // para verificacao do turno aberto
	//Local cQuery	    := ""
	//Local cEOL 		    := Chr(13)+Chr(10)	
	Local lTemIPAL 		:= .F.
	Local nItZDQ		:= 1
	Local nEqpNC		:= 1
	Local cHoraInc		:= time()
	Local nItReVe		:= 1

	/*
	if lTipMov
		cTipMov := ojson["ZCI_ENTSAI"]
	else
		cTipMov := "  "
	endif
	*/
	
	if lPA
		cPA := oJson["ZCI_PAPOIO"]
	else
		cPA := ""
	endif

	ZCI->(DbSetOrder(1))
	if ZCI->(DbSeek(xFilial("ZCI")+alltrim(oJson["ZCI_IDMOV"])))

		if !Empty(alltrim(ZCI->ZCI_DTFECH))
			aRet := {.F., EncodeUTF8('Este turno já está fechado.')}
		else
			ZCI->(RecLock("ZCI",.F.))
			ZCI->ZCI_UNIDAD := oJson["ZCI_UNIDAD"]
			ZCI->ZCI_SERVIC := ojson["ZCI_SERVIC"]
			ZCI->ZCI_KMVEIC := ojson["ZCI_KMVEIC"]
			ZCI->ZCI_HORIME := ojson["ZCI_HORIME"]
			ZCI->ZCI_SETOR  := ojson["ZCI_SETOR"]
			ZCI->ZCI_FILVEI := ojson["ZCI_FILVEI"] 
			ZCI->(msUnLock())

			for nPerguntas := 1 to len(oJson["perguntas"])

				//1=Veiculos;2=Equipes;3=Sesmt/IPAL;4=Epi/Epc/Ferramentas;5=Leiturista;6=Eletricista;7=APR;8=IPAL/int;9=Lib/Frota                 
				cTipInsp := Posicione("ZC0",1,XFILIAL("ZC0")+oJson["perguntas"][nPerguntas]["ZCJ_CODCHE"],"ZC0_DESTIN")

				if cTipInsp == "9"
					cTipMov := "LF"
				elseif cTipInsp == "8"
						cTipMov := "II"
				elseif cTipInsp == "3"
						cTipMov := "IS"
				elseif cTipInsp == "1"
						cTipMov := "VE"
				elseif cTipInsp == "2"
						cTipMov := "EQ"
				elseif cTipInsp == "4"
						cTipMov := "EP"
				elseif cTipInsp == "5"
						cTipMov := "LE"
				elseif cTipInsp == "6"
						cTipMov := "OP"
				elseif cTipInsp == "7"
						cTipMov := "AP"

				else
						cTipMov := "ND"
				endif

				if empty(oJson["ZCI_PLACA"])
					cPlaca := oJson["ZD7_PLACA"]
				else
					cPlaca := oJson["ZCI_PLACA"]
				endif

				ZCJ->(DbSetOrder(3))
				if !ZCJ->(DbSeek(xFilial("ZCJ")+oJson["ZCI_IDMOV"]+oJson["ZCI_SEQMOV"]+;
												oJson["ZCI_CPF"]+oJson["ZCI_CPFMEM"]+;
												cPlaca+;
												oJson["perguntas"][nPerguntas]["ZCJ_CODCHE"]+;
												oJson["perguntas"][nPerguntas]["ZCJ_SEQPER"]+;
												oJson["perguntas"][nPerguntas]["ZCJ_CODPER"]+;
												dtos(dDataInc)+cHoraInc+cTipMov))
					ZCJ->(recLock("ZCJ",.T.))
					ZCJ->ZCJ_FILIAL	:= xfilial("ZCJ")
					ZCJ->ZCJ_IDMOV 	:= oJson["ZCI_IDMOV"]
					ZCJ->ZCJ_SEQMOV := oJson["ZCI_SEQMOV"]
					ZCJ->ZCJ_CPF 	:= oJson["ZCI_CPF"]
					ZCJ->ZCJ_CPFMEM := oJson["ZCI_CPFMEM"]
					ZCJ->ZCJ_PLACA  := cPlaca
					ZCJ->ZCJ_CODCHE := oJson["perguntas"][nPerguntas]["ZCJ_CODCHE"]
					ZCJ->ZCJ_SEQPER	:= oJson["perguntas"][nPerguntas]["ZCJ_SEQPER"]
					ZCJ->ZCJ_CODPER	:= oJson["perguntas"][nPerguntas]["ZCJ_CODPER"]
					ZCJ->ZCJ_DESRES	:= DecodeUtf8(oJson["perguntas"][nPerguntas]["ZCJ_DESRES"])
					ZCJ->ZCJ_DATA   := dDataInc
					ZCJ->ZCJ_HORA   := cHoraInc
					ZCJ->ZCJ_TPMOV  := cTipMov
					ZCJ->(msUnlock())
				else
					ZCJ->(recLock("ZCJ",.F.))
					ZCJ->ZCJ_SEQPER	:= oJson["perguntas"][nPerguntas]["ZCJ_SEQPER"]
					ZCJ->ZCJ_CODPER	:= oJson["perguntas"][nPerguntas]["ZCJ_CODPER"]
					ZCJ->ZCJ_DESRES	:= DecodeUtf8(oJson["perguntas"][nPerguntas]["ZCJ_DESRES"])
					ZCJ->(msUnlock())
				endif

				conout("Tem Inspeção... "+cTipMov)
				if lIpal
					for nItZDQ := 1 to len(oJson["ZD7_EQUIPE"])

						conout("Tem Equipe Liberada - Membros")
						if UPPER(oJson["ZD7_EQUIPE"][nItZDQ]["tipoMembro"]) = "LIDER"
							cTpMembro := "L"
						elseif UPPER(oJson["ZD7_EQUIPE"][nItZDQ]["tipoMembro"]) = "LIDER_EQUIPE"
								cTpMembro := "E"
						else
							cTpMembro := "M"
						endif
						//PadR(alltrim(oJson["ZD7_EQUIPE"][nItZDQ]["cpfMembro"]),TamSx3("ZDQ_EQUIPE")[1])+;

						ZDQ->(DbSetOrder(2))
						//ZDQ_FILIAL+ZDQ_PLACA+DTOS(ZDQ_DATA)+ZDQ_TIPMEM+ZDQ_TIPMOV "    RKK7D4320251103LIS"
						if !ZDQ->(DbSeek(xFilial("ZDQ")			+;
							PadR(alltrim(cPlaca),TamSx3("ZDF_PLACA")[1])	+;
							dtos(dDataInc) 						+; 
							cTpMembro							+;
							cTipMov+oJson["ZCI_CPF"]+oJson["ZD7_EQUIPE"][nItZDQ]["cpfMembro"]))

							ZDQ->(recLock("ZDQ",.T.))
							ZDQ->ZDQ_IDMOV	:= oJson["ZCI_IDMOV"]
							ZDQ->ZDQ_IDMEM  := oJson["ZD7_IDIPAL"]
							ZDQ->ZDQ_CPFTEC	:= oJson["ZCI_CPF"]
							ZDQ->ZDQ_DATA   := dDataInc
							ZDQ->ZDQ_HORA	:= cHoraInc
							ZDQ->ZDQ_PLACA  := cPlaca
							ZDQ->ZDQ_EQUIPE := oJson["ZD7_EQUIPE"][nItZDQ]["cpfMembro"]
							ZDQ->ZDQ_TIPMEM := cTpMembro
							ZDQ->ZDQ_TIPMOV := cTipMov
							
							if cEmpAnt = "02"
								ZDQ->ZDQ_PAPOIO := oJson["ZD7_PAPOIO"]
								ZDQ->ZDQ_FREQUE := oJson["ZD7_FREQUE"]
								ZDQ->ZDQ_SETOR  := oJson["ZD7_SETOR"] 						
							endif

							ZDQ->(msUnLock())
						endif
					next
				endif

				//registrando dados do IPAL
				//if !Empty(alltrim(oJson["ZD7_IDIPAL"])) .or. !Empty(alltrim(oJson["ZD7_PLACA"])) .or. len(oJson["ZD7_EQUIPE"]) > 0 
				if lEqpNC .and. cTipInsp $ "3-8-9"
					
					ZDF->(DbSetorder(1))
					if !ZDF->(DbSeek(xfilial("ZDF")+oJson["ZCI_IDMOV"]+;
										PadR(alltrim(oJson["ZD7_IDIPAL"]),TamSx3("ZDF_IDIPAL")[1])+;
										PadR(alltrim(cPlaca),TamSx3("ZDF_PLACA")[1])+;
										PadR(alltrim(oJson["ZCI_CPFMEM"]),TamSx3("ZDF_CPFMEM")[1])+;
										dtos(dDataInc)+cHoraInc+cTipMov))
						ZDF->(RecLock("ZDF",.T.))
						ZDF->ZDF_FILIAL	:= xFilial("ZDF")
						ZDF->ZDF_IDMOV	:= oJson["ZCI_IDMOV"]
						ZDF->ZDF_IDIPAL	:= DecodeUtf8(alltrim(oJson["ZD7_IDIPAL"]))
						ZDF->ZDF_ENIPAL	:= DecodeUtf8(alltrim(oJson["ZD7_ENIPAL"]))
						ZDF->ZDF_BAIPAL	:= DecodeUtf8(alltrim(oJson["ZD7_BAIPAL"]))
						ZDF->ZDF_CIIPAL	:= DecodeUtf8(alltrim(oJson["ZD7_CIIPAL"]))
						ZDF->ZDF_LAIPAL	:= oJson["ZD7_LAIPAL"]
						ZDF->ZDF_LGIPAL	:= oJson["ZD7_LGIPAL"]
						ZDF->ZDF_EXTRA	:= oJson["ZD7_EXTRA"]
						ZDF->ZDF_NUMOS	:= oJson["ZD7_NUMOS"]
						ZDF->ZDF_OFFLI	:= oJson["ZD7_OFFLI"]
						ZDF->ZDF_UNICON := ""  // strZero(val(oJson["ZD7_UNICON"]),11)
						ZDF->ZDF_PLACA  := cPlaca
						ZDF->ZDF_CPFMEM := oJson["ZCI_CPFMEM"]
						ZDF->ZDF_TPIPAL := if(cTipMov=="3","I","E")  
						if cEmpAnt = "02"
							ZDF->ZDF_PAPOIO := oJson["ZD7_PAPOIO"]
							ZDF->ZDF_FREQUE := oJson["ZD7_FREQUE"]
							ZDF->ZDF_SETOR  := oJson["ZD7_SETOR"] 						
						endif
						ZDF->ZDF_DATA   := dDataInc
						ZDF->ZDF_HORA   := cHoraInc
						ZDF->ZDF_TPMOV  := cTipMov
						ZDF->(msUnLock())
					else
						ZDF->(RecLock("ZDF",.F.))
						ZDF->ZDF_ENIPAL	:= DecodeUtf8(alltrim(oJson["ZD7_ENIPAL"]))
						ZDF->ZDF_BAIPAL	:= DecodeUtf8(alltrim(oJson["ZD7_BAIPAL"]))
						ZDF->ZDF_CIIPAL	:= DecodeUtf8(alltrim(oJson["ZD7_CIIPAL"]))
						ZDF->ZDF_LAIPAL	:= oJson["ZD7_LAIPAL"]
						ZDF->ZDF_LGIPAL	:= oJson["ZD7_LGIPAL"]
						ZDF->ZDF_EXTRA	:= oJson["ZD7_EXTRA"]
						ZDF->ZDF_NUMOS	:= oJson["ZD7_NUMOS"]
						ZDF->ZDF_OFFLI	:= oJson["ZD7_OFFLI"]
						ZDF->ZDF_UNICON := ""  //strZero(val(oJson["ZD7_UNICON"]),11)						
						ZDF->ZDF_PLACA  := cPlaca	
						ZDF->ZDF_CPFMEM := oJson["ZCI_CPFMEM"]											
						ZDF->ZDF_TPIPAL := if(cTipMov=="3","I","E") 
						if cEmpAnt = "02"
							ZDF->ZDF_PAPOIO := oJson["ZD7_PAPOIO"]
							ZDF->ZDF_FREQUE := oJson["ZD7_FREQUE"]
							ZDF->ZDF_SETOR  := oJson["ZD7_SETOR"] 						
						endif
						ZDF->(msUnLock())
					endif

					lTemIPAL := .T.

				endif

				for nRespostas := 1 to len(oJson["perguntas"][nPerguntas]["respostas"])		
					//(2) ZCK_FILIAL+ZCK_IDMOV+ZCK_SEQMOV+CK_CPF+ZCK_CPFMEM+ZCK_CODCHE+ZCK_SEQPER+ZCK_CODPER+ZCK_SEQRES+ZCK_CODRES                                                                  
					ZCK->(DbSetOrder(2))
					if !ZCK->(DbSeek(xFilial("ZCK")+oJson["ZCI_IDMOV"]+oJson["ZCI_SEQMOV"]+;
													oJson["ZCI_CPF"]+oJson["ZCI_CPFMEM"]+;
													cPlaca +;
													oJson["perguntas"][nPerguntas]["ZCJ_CODCHE"]+;
													oJson["perguntas"][nPerguntas]["ZCJ_SEQPER"]+;
													oJson["perguntas"][nPerguntas]["ZCJ_CODPER"]+;
													oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_SEQRES"]+;
													oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_CODRES"]+;
													dtos(dDataInc)+cHoraInc+cTipMov))

						ZCK->(recLock("ZCK",.T.))
						ZCK->ZCK_FILIAL	:= xfilial("ZCK")
						ZCK->ZCK_IDMOV 	:= oJson["ZCI_IDMOV"]
						ZCK->ZCK_SEQMOV := oJson["ZCI_SEQMOV"]
						ZCK->ZCK_CPF 	:= oJson["ZCI_CPF"]
						ZCK->ZCK_CPFMEM := oJson["ZCI_CPFMEM"]
						ZCK->ZCK_PLACA  := cPlaca
						ZCK->ZCK_CODCHE := oJson["perguntas"][nPerguntas]["ZCJ_CODCHE"]
						ZCK->ZCK_SEQPER := oJson["perguntas"][nPerguntas]["ZCJ_SEQPER"]
						ZCK->ZCK_CODPER	:= oJson["perguntas"][nPerguntas]["ZCJ_CODPER"]
						ZCK->ZCK_SEQRES	:= oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_SEQRES"]
						ZCK->ZCK_CODRES	:= oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_CODRES"]
						ZCK->ZCK_DESRES := DecodeUtf8(oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_DESRES"])
						ZCK->ZCK_INFRES	:= DecodeUtf8(oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_INFRES"])
						ZCK->ZCK_DATA   := dDataInc
						ZCK->ZCK_HORA   := cHoraInc
						ZCK->ZCK_TPMOV  := cTipMov
						ZCK->(msUnLock())
					else
						ZCK->(recLock("ZCK",.F.))
						ZCK->ZCK_INFRES	:= DecodeUtf8(oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_INFRES"])
						ZCK->(msUnLock())
					endif

					//realiza inclusão da Solicitação de Serviços
//					if Posicione("ZC0",1,XFILIAL("ZC0")+oJson["perguntas"][nPerguntas]["ZCJ_CODCHE"],"ZC0_DESTIN") = "1" .or. ;//indica veículos
//						Posicione("ZCO",1,XFILIAL("ZCO")+oJson["perguntas"][nPerguntas]["ZCJ_CODPER"],"ZCO_EMFROT") = "S"

					//if Posicione("ZCO",1,XFILIAL("ZCO")+oJson["perguntas"][nPerguntas]["ZCJ_CODPER"],"ZCO_EMFROT") $ "F-S-T"

					//se a pergunta for de cunho negativa, onde o Não é que está em conformidade ou se for checklist de IPAL e a pergunta estiver
					//identificada para enviar e-mail para o frotas
					cPerNeg 	:= Posicione("ZCO",1,XFILIAL("ZCO")+oJson["perguntas"][nPerguntas]["ZCJ_CODPER"],"ZCO_PERNEG") 
					cResPer 	:= Posicione("ZC4",1,XFILIAL("ZC4")+oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_CODRES"],"ZC4_TIPRES")							
					cPerFrot	:= Posicione("ZCO",1,XFILIAL("ZCO")+oJson["perguntas"][nPerguntas]["ZCJ_CODPER"],"ZCO_RESPNC") 
					cTipoServ	:= Posicione("ZCO",1,XFILIAL("ZCO")+oJson["perguntas"][nPerguntas]["ZCJ_CODPER"],"ZCO_TPSERV") 
						
					//Conout("Pergunta: "+oJson["perguntas"][nPerguntas]["ZCJ_CODPER"]+ " | cPerNeg "+cPerNeg+"   cResper "+cResper+"    cPerFrot "+cPerFrot)
						
					// se resposta for negativa
					if (cResPer = "N" .and. cPerNeg = "N") .or. (cResPer = "S" .and. cPerNeg = "S")

						//if Posicione("ZC0",1,XFILIAL("ZC0")+oJson["perguntas"][nPerguntas]["ZCJ_CODCHE"],"ZC0_DESTIN") = "1"		
						if cPerFrot = "F"		
							cChaveSS := oJson["ZCI_IDMOV"] + oJson["ZCI_SEQMOV"] + oJson["ZCI_CPF"] + oJson["ZCI_CPFMEM"] + ;
									  oJson["perguntas"][nPerguntas]["ZCJ_CODCHE"] + oJson["perguntas"][nPerguntas]["ZCJ_SEQPER"] + ;
									  oJson["perguntas"][nPerguntas]["ZCJ_CODPER"]

								//IDMOV + ZCI_SEQMOV + ZCI_CPF + ZCI_CPFMEM + ZCJ_CODCHE + ZCJ_SEQPER + ZCJ_CODPER
								// 10   +    03      +    11   +    11      +     5      +    3       +    5
					
							if cEmpAnt = "01"
								U_fVerifSS(Posicione("ZCO",1,XFILIAL("ZCO")+oJson["perguntas"][nPerguntas]["ZCJ_CODPER"],"ZCO_DESRES"),;
										DecodeUtf8(oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_INFRES"]),;
										DecodeUtf8(oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_DESRES"]),;
										cPlaca, oJson["ZCI_CONTAD"], oJson["ZCI_CPF"], oJson["ZCI_IDMOV"],"Resposta Checklist","",cTipoServ,;
										cChaveSS, cPA, dDataInc )//Verifica a necessidade geração da SS
							endif
						endif
					endif

					if cPerFrot = "S"  //se for IPAL mas a NC é para o Frotas

						if (cResPer = "N" .and. cPerNeg = "N") .or. (cResPer = "S" .and. cPerNeg = "S")
							cPlacaUsr := Posicione("ZCI",1,XFILIAL("ZCI")+oJson["ZD7_IDIPAL"],"ZCI_PLACA")
							cCpfUsr   := Posicione("ZCI",1,XFILIAL("ZCI")+oJson["ZD7_IDIPAL"],"ZCI_CPF")
							/*
							fEnvEmail(cPlacaUsr, cPlacaUsr,;
									Posicione("ZCO",1,XFILIAL("ZCO")+oJson["perguntas"][nPerguntas]["ZCJ_CODPER"],"ZCO_DESRES"),;
									DecodeUtf8(oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_INFRES"]),;
									DecodeUtf8(oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_DESRES"]),;
									"   ", oJson["ZCI_IDMOV"],;
									"Mot.Turno: "+alltrim(Posicione("ZCC",3,XFILIAL("ZCC")+cCpfUsr,"ZCC_NOME"))+ " - "+;
									"Mot.Sesmt: "+alltrim(Posicione("ZCC",3,XFILIAL("ZCC")+oJson["ZCI_CPF"],"ZCC_NOME")),;
									"Não Conformidade Checklist-IPAL", "Checklist-IPAL",cPerFrot)
							*/
						endif
					endif
 
					//tratativa para gerar SS da placa com problema condição de inspeção do aterro
					if cEmpAnt = "01"
						for nItReVe := 1 to len(oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_VEICUN"])
							cPlaca 	:= oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_VEICUN"][nItReVe]["codPlaca"]
							cCodBem := oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_VEICUN"][nItReVe]["codBem"]

							U_fVerifSS(Posicione("ZCO",1,XFILIAL("ZCO")+oJson["perguntas"][nPerguntas]["ZCJ_CODPER"],"ZCO_DESRES"),;
										DecodeUtf8(oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_INFRES"]),;
										DecodeUtf8(oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_DESRES"]),;
										cPlaca, oJson["ZCI_CONTAD"], oJson["ZCI_CPF"], oJson["ZCI_IDMOV"],"Resposta Checklist","",cTipoServ,;
										cChaveSS, cPA, dDataInc )//Verifica a necessidade geração da SS

							//ZDV_FILIAL+ZDV_IDMOV+ZDV_SEQMOV+ZDV_CODCHE+ZDV_SEQPER+ZDV_CODPER+ZDV_SEQRES+ZDV_CODRES+ZDV_PLACA
							ZDV->(DbSetOrder(1))
							if !ZDV->(DbSeek(xFilial("ZDV")+ oJson["ZCI_IDMOV"]+oJson["ZCI_SEQMOV"]+oJson["ZCI_CPF"]+;
															oJson["perguntas"][nPerguntas]["ZCJ_CODCHE"]+;
															oJson["perguntas"][nPerguntas]["ZCJ_SEQPER"]+;
															oJson["perguntas"][nPerguntas]["ZCJ_CODPER"]+;
															oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_SEQRES"]+;
															oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_CODRES"]+;
															cPlaca))

								ZDV->(recLock("ZDV",.T.))
								ZDV->ZDV_FILIAL	:= xfilial("ZDV")
								ZDV->ZDV_IDMOV 	:= oJson["ZCI_IDMOV"]
								ZDV->ZDV_SEQMOV := oJson["ZCI_SEQMOV"]
								ZDV->ZDV_CPF    := oJson["ZCI_CPF"]
								ZDV->ZDV_PLACA  := cPlaca
								ZDV->ZDV_CODBEM := cCodBem
								ZDV->ZDV_CODCHE := oJson["perguntas"][nPerguntas]["ZCJ_CODCHE"]
								ZDV->ZDV_SEQPER := oJson["perguntas"][nPerguntas]["ZCJ_SEQPER"]
								ZDV->ZDV_CODPER	:= oJson["perguntas"][nPerguntas]["ZCJ_CODPER"]
								ZDV->ZDV_SEQRES	:= oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_SEQRES"]
								ZDV->ZDV_CODRES	:= oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_CODRES"]
								ZDV->ZDV_DATA   := dDataInc
								ZDV->ZDV_HORA   := cHoraInc
								ZDV->(msUnLock())
							endif
						next
					endif
					
					if cPerFrot = "T" //PERGUNTA para TI
						if (cResPer = "N" .and. cPerNeg = "N") .or. (cResPer = "S" .and. cPerNeg = "S")
							/*
							fEnvEmail(oJson["ZCI_PLACA"], oJson["ZCI_PLACA"],;
									Posicione("ZCO",1,XFILIAL("ZCO")+oJson["perguntas"][nPerguntas]["ZCJ_CODPER"],"ZCO_DESRES"),;
									DecodeUtf8(oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_INFRES"]),;
									DecodeUtf8(oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_DESRES"]),;
									"   ", oJson["ZCI_IDMOV"],;
									alltrim(Posicione("ZCC",3,XFILIAL("ZCC")+oJson["ZCI_CPF"],"ZCC_NOME")), "Não Conformidade Checklist", "Checklist",cPerFrot)
							*/
						endif
					endif

					//realiza inclusão de não conformidade para IPAL, quando resposta for negativa
					
					if cTipInsp $ "3-8" //Posicione("ZC0",1,XFILIAL("ZC0")+oJson["perguntas"][nPerguntas]["ZCJ_CODCHE"],"ZC0_DESTIN") $ "3-8" //indica IPAL e IPAL Interno

						//se a pergunta for de cunho negativa, onde o Não é que está em conformidade
						cPerNeg := Posicione("ZCO",1,XFILIAL("ZCO")+oJson["perguntas"][nPerguntas]["ZCJ_CODPER"],"ZCO_PERNEG") 
						cResPer := Posicione("ZC4",1,XFILIAL("ZC4")+oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_CODRES"],"ZC4_TIPRES")							

						// se resposta for negativa inclui pendências para serem analisadas
						if ((cResPer = "N" .and. cPerNeg = "N") .or. (cResPer = "S" .and. cPerNeg = "S"))

							//se houver membros relacionados a resposta negativa
							if lEqpNC
								for nEqpNC := 1 to  len(oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_EQUIPN"])     //len(ZCK_EQUIPN)
									U_fIncIpal(	oJson["ZCI_IDMOV"], oJson["ZD7_IDIPAL"],;
												oJson["perguntas"][nPerguntas]["ZCJ_CODCHE"],;
												oJson["perguntas"][nPerguntas]["ZCJ_SEQPER"],;
												oJson["perguntas"][nPerguntas]["ZCJ_CODPER"],;
												oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_SEQRES"],;
												oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_CODRES"],;
												oJson["ZCI_CPF"],;
												oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_EQUIPN"][nEqpNC]["cpf"],;
												oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_INFRES"],;
												Posicione("ZCC",3,XFILIAL("ZCC")+oJson["ZCI_CPFMEM"],"ZCC_PROJET"), dDataInc,;
												cPlaca, cHoraInc, cTipMov)
									
									//busca o lider da equipe no momento da liberação pelo supervisor
									ZDQ->(DbSetOrder(2))
									if ZDQ->(dbSeek(xFilial("ZDQ")+cPlaca+DTOS(dDataInc)+"E"+"LF"))  //Liberação de frotas
										cCpfSup 	:= ZDQ->ZDQ_CPFTEC
										cIdMovLib	:= ZDQ->ZDQ_IDMOV
										cCPfLider	:= ZDQ->ZDQ_EQUIPE
									else
										cCpfSup		:= ""
										cIdMovLib	:= ""
										cCPfLider	:= ""
									endif
									
									//realiza gravação das respostas x Membros com não conformidade
									//ZDR_FILIAL+ZDR_IDMOV+ZDR_IDIPAL+ZDR_PLACA+ZDR_CODCHE+ZCJ_SEQPER+ZCJ_CODPER+ZDR_CPFMEM+DTOS(ZDR_DATA)+ZDR_TPMOV
									//EG - ENTRADA GARAGEM
									//SG - SAÍDA GARAGEM
									//EO - ENTRADA OFICINA
									//SO - SAÍDA OFICINA
									//ZDR_FILIAL+ZDR_IDMOV+ZDR_IDIPAL+ZDR_PLACA+ZDR_CODCHE+ZDR_CODPER+ZDR_SEQPER+ZDR_CPFMEM+DTOS(ZDR_DATA)+ZDR_TPMOV   
									if !ZDR->(DbSeek(xFilial("ZDR")+oJson["ZCI_IDMOV"]+oJson["ZD7_IDIPAL"]+;
													cPlaca + oJson["perguntas"][nPerguntas]["ZCJ_CODCHE"]+;
													oJson["perguntas"][nPerguntas]["ZCJ_CODPER"]+;
													oJson["perguntas"][nPerguntas]["ZCJ_SEQPER"]+cCPfLider+;
													dTos(dDataInc)+cHoraInc+cTipMov))
										ZDR->(RecLock("ZDR",.T.))
										ZDR->ZDR_FILIAL := xFilial("ZDR")
										ZDR->ZDR_IDMOV 	:= oJson["ZCI_IDMOV"]
										ZDR->ZDR_IDIPAL	:= oJson["ZD7_IDIPAL"]
										ZDR->ZDR_PLACA 	:= cPlaca
										ZDR->ZDR_TPMOV 	:= cTipMov
										ZDR->ZDR_CODCHE	:= oJson["perguntas"][nPerguntas]["ZCJ_CODCHE"]
										ZDR->ZDR_CODPER	:= oJson["perguntas"][nPerguntas]["ZCJ_CODPER"]
										ZDR->ZDR_SEQPER := oJson["perguntas"][nPerguntas]["ZCJ_SEQPER"]
										ZDR->ZDR_CODRES	:= oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_CODRES"]
										ZDR->ZDR_SEQRES	:= oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_SEQRES"]
										ZDR->ZDR_CPFSUP	:= cCpfSup
										ZDR->ZDR_CPFMEM	:= oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_EQUIPN"][nEqpNC]["cpf"]
										ZDR->ZDR_OBS   	:= ""
										ZDR->ZDR_DATA  	:= dDataInc
										ZDR->ZDR_HORA  	:= cHoraInc
										ZDR->ZDR_PROJET	:= Posicione("ZCC",3,XFILIAL("ZCC")+oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_EQUIPN"][nEqpNC]["cpf"],"ZCC_PROJET")
										ZDR->ZDR_CPFLID	:= cCPfLider
										ZDR->ZDR_IDLIBE	:= cIdMovLib
										ZDR->(msUnLock())
									endif
								next
							else
								U_fIncIpal(	oJson["ZCI_IDMOV"], oJson["ZD7_IDIPAL"],;
											oJson["perguntas"][nPerguntas]["ZCJ_CODCHE"],;
											oJson["perguntas"][nPerguntas]["ZCJ_SEQPER"],;
											oJson["perguntas"][nPerguntas]["ZCJ_CODPER"],;
											oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_SEQRES"],;
											oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_CODRES"],;
											oJson["ZCI_CPF"],oJson["ZCI_CPFMEM"],;
											oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_INFRES"],;
											Posicione("ZCC",3,XFILIAL("ZCC")+oJson["ZCI_CPFMEM"],"ZCC_PROJET"), dDataInc,;
											IF(empty(oJson["ZD7_PLACA"]),ojson["ZD7_PLACA"],oJson["ZCI_PLACA"]), cHoraInc, cTipMov)
								/*
								fEnvEmail(oJson["ZCI_PLACA"], oJson["ZCI_PLACA"],;
										Posicione("ZCO",1,XFILIAL("ZCO")+oJson["perguntas"][nPerguntas]["ZCJ_CODPER"],"ZCO_DESRES"),;
										DecodeUtf8(oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_INFRES"]),;
										DecodeUtf8(oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_DESRES"]),;
										"   ", oJson["ZCI_IDMOV"],;
										alltrim(Posicione("ZCC",3,XFILIAL("ZCC")+oJson["ZCI_CPF"],"ZCC_NOME")), "Não Conformidade IPAL", "Checklist",cPerFrot)	
								*/									
							endif

						endif
					endif
										
					for nFotos := 1 to len(oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["fotos"])
						ZCL->(DbSetOrder(2))
						if !ZCL->(DbSeek(xFilial("ZCL")+oJson["ZCI_IDMOV"]+oJson["ZCI_SEQMOV"]+;
														oJson["ZCI_CPF"]+oJson["ZCI_CPFMEM"]+;
														cPlaca+;
														oJson["perguntas"][nPerguntas]["ZCJ_CODCHE"]+;
														oJson["perguntas"][nPerguntas]["ZCJ_SEQPER"]+;
														oJson["perguntas"][nPerguntas]["ZCJ_CODPER"]+;
														oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_SEQRES"]+;
														oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_CODRES"]+;
														dtos(dDataInc)+cHoraInc+cTipMov))
							
							if !Empty(alltrim(oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["fotos"][nFotos]["foto"]))
								ZCL->(recLock("ZCL",.T.))
								ZCL->ZCL_FILIAL	:= xfilial("ZCL")
								ZCL->ZCL_IDMOV 	:= oJson["ZCI_IDMOV"]
								ZCL->ZCL_CPF    := oJson["ZCI_CPF"]
								ZCL->ZCL_CPFMEM := oJson["ZCI_CPFMEM"]
								ZCL->ZCL_PLACA  := cPlaca
								ZCL->ZCL_CODCHE := oJson["perguntas"][nPerguntas]["ZCJ_CODCHE"]
								ZCL->ZCL_SEQPER := oJson["perguntas"][nPerguntas]["ZCJ_SEQPER"]
								ZCL->ZCL_CODPER	:= oJson["perguntas"][nPerguntas]["ZCJ_CODPER"]
								ZCL->ZCL_SEQRES	:= oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_SEQRES"]
								ZCL->ZCL_CODRES	:= oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["ZCK_CODRES"]
								ZCL->ZCL_FOTO	:= oJson["perguntas"][nPerguntas]["respostas"][nRespostas]["fotos"][nFotos]["foto"]
								ZCL->ZCL_DATA   := dDataInc
								ZCL->ZCL_HORA   := cHoraInc
								ZCL->ZCL_TPMOV  := cTipMov								
								ZCL->(msUnLock())
							endif
						endif
					next	

				next
			next
			
			aRet := {.T., EncodeUTF8('Check List Incluído com sucesso.')}
			
		EndIF
		
    else
		aRet := {.F., EncodeUTF8('Check List Inexistente, Realizar Abertura de Turno.')}
	endif

Return aRet
  
user function fVerifSS(cPergunta, cInfResp, cDesRes, cPlaca, cContad, cCpf, cIdmov, cOrigem, cEspaco, cTpServ, cChaveSS, cPA, dDataInc)

	//Local aSolic 	:= {} 
	Local cCodBem	:= "" 
	Local lRet		:= .T.
	Local _aArea 	:= getArea()
	//Local nAux		:= 1
	
	Private lMSHelpAuto := .T. // Nao apresenta erro em tela
	Private lMSErroAuto := .F. //   Caso a variavel torne-se .T. apos MsExecAuto, apresenta erro em tela
	Private l280Auto	:= .T.
 
	if !empty(cPlaca)
		conout(" - Perg: "+cPergunta)
		conout(" - cInfResp: "+cInfResp)
		conout(" - cDesres: "+cDesRes)
		conout(" - cPlaca: "+cPlaca)
		//conout(" - Contad: "+cContad)
		conout(" - cpf: "+cCpf)
		conout(" - cIdmov: "+cIdmov)
		conout(" - Tip Serv: "+cTpServ)

		if empty(cTpServ)
			cTpServ := "000001"
		endif

		cCodBem := Posicione("ST9",14,cPlaca,"T9_CODBEM") 
		cCc		:= Posicione("ST9",14,cPlaca,"T9_CCUSTO") 
		cFilbem := Posicione("ST9",14,cPlaca,"T9_FILIAL") 

		conout('Codbem: '+cCodBem)
		conout('Filial: '+cFilant)
 
		if !Empty(cCodBem)
		
			if empty(cFilbem)
				cFilbem := "0101"
			endif
			
			cFilant := cFilbem
			conout('Filial chave: '+cFilBem + cChaveSS)			
			
			if substr(cChaveSS,1,4) == "CK23"
				cTexto := 	alltrim(cPergunta) + CHR(13)+CHR(10) + " Placa: "+cPlaca			
				
				cNumSol := U_EMNT001("TQB","TQB_SOLICI")   //GetSXEnum("TQB","TQB_SOLICI")
				ConfirmSX8()

				TQB->(recLock("TQB",.T.))
				TQB->TQB_FILIAL := cFilbem
				TQB->TQB_SOLICI := cNumSol
				TQB->TQB_TIPOSS := "B"
				TQB->TQB_CODBEM := cCodBem
				TQB->TQB_CCUSTO := cCc
				TQB->TQB_DTABER := dDataInc
				TQB->TQB_HOABER := substr(time(),1,5)
				TQB->TQB_USUARI := "eopera-app"
				TQB->TQB_SOLUCA := "A"
				TQB->TQB_CDSOLI := "000000"
				TQB->TQB_TPSERV := "1"
				TQB->TQB_CRITIC := 1
				TQB->TQB_ORIGEM := "RPC"
				TQB->TQB_CDSERV	:= cTpServ
				TQB->TQB_XCPF	:= cCpf
				TQB->TQB_XIDMOV	:= cIdmov	
				TQB->TQB_XPLACA	:= cPlaca
				TQB->TQB_XCHAVE := cNumSol
				
				if valtype(cContad) = "N"
					TQB->TQB_POSCON := cContad
				else
					TQB->TQB_POSCON := val(cContad)
				endif

				if cEmpant == "02"
					TQB->TQB_PAPOIO := cPA
				endif

				TQB->(msUnLock())

				TQB->(recLock("TQB",.F.))
				TQB->TQB_CODMSS := MSMM(,80,, cTexto ,1,,,"TQB","TQB_CODMSS")
				TQB->(msUnLock())

			else

				cTexto := 	alltrim(cPergunta) + CHR(13)+CHR(10) + alltrim(cInfResp)+ CHR(13)+CHR(10) +;
						  	alltrim(cDesRes) + CHR(13)+CHR(10) + "Hodometro: "+cContad +CHR(13)+CHR(10) +;
							alltrim(Posicione("ZCC",3,XFILIAL("ZCC")+cCpf,"ZCC_NOME")) +CHR(13)+CHR(10) +;
							"IDMOV: "+cIdmov + " Placa: "+cPlaca

				cNumSol := U_EMNT001("TQB","TQB_SOLICI")   //GetSXEnum("TQB","TQB_SOLICI")
				ConfirmSX8()

				TQB->(DbSetOrder(15))
				if !TQB->(DbSeek(cFilbem+cChaveSS))
					TQB->(recLock("TQB",.T.))
					TQB->TQB_FILIAL := cFilbem
					TQB->TQB_SOLICI := cNumSol
					TQB->TQB_TIPOSS := "B"
					TQB->TQB_CODBEM := cCodBem
					TQB->TQB_CCUSTO := cCc
					TQB->TQB_DTABER := dDataBase
					TQB->TQB_HOABER := substr(time(),1,5)
					TQB->TQB_USUARI := "eopera-app"
					TQB->TQB_SOLUCA := "A"
					TQB->TQB_CDSOLI := "000000"
					TQB->TQB_TPSERV := "1"
					TQB->TQB_CRITIC := 1
					TQB->TQB_ORIGEM := "RPC"
					TQB->TQB_CDSERV	:= cTpServ
					TQB->TQB_XCPF	:= cCpf
					TQB->TQB_XIDMOV	:= cIdmov	
					TQB->TQB_XPLACA	:= cPlaca
					TQB->TQB_XCHAVE := cChaveSS
					/*
					if IsNumeric(cContad)
						TQB->TQB_POSCON := cContad
					else
						TQB->TQB_POSCON := val(cContad)
					endif					
					*/
					
					TQB->(msUnLock())

					TQB->(recLock("TQB",.F.))
					TQB->TQB_CODMSS := MSMM(,80,, cTexto ,1,,,"TQB","TQB_CODMSS")
					TQB->(msUnLock())

					ConfirmSX8()
				//else
				//	TQB->(recLock("TQB",.F.))
				//	TQB->TQB_CODMSS := MSMM(TQB->TQB_CODMSS,80,, cTexto ,1,,,"TQB","TQB_CODMSS")
				//	TQB->(msUnLock())
				endif
			endif

			/*	
			aSolic := {	{"TQB_CODBEM", cCodBem															  							, Nil } ,;  
						{"TQB_DESCSS", 	alltrim(cPergunta) + CHR(13)+CHR(10) + alltrim(cInfResp)+ CHR(13)+CHR(10) +;
										alltrim(cDesRes) + CHR(13)+CHR(10) + "Hodometro: "+cContad +CHR(13)+CHR(10) +;
										alltrim(Posicione("ZCC",3,XFILIAL("ZCC")+cCpf,"ZCC_NOME")) +CHR(13)+CHR(10) +;
										"IDMOV: "+cIdmov + " Placa: "+cPlaca														, Nil } ,; 
						{"TQB_CDSERV", cTpServ															  							, Nil } ,;
						{"TQB_XCPF"	 , cCpf																  							, Nil } ,;
						{"TQB_XIDMOV", cIdmov															  							, Nil } ,;						
						{"TQB_XPLACA", cPlaca																						, Nil }}  

			MSExecAuto( {|x,z,y,w| MNTA280(x,z,y,w)}, , , aSolic )
		
			If lMsErroAuto
				lRet := .F.
				conout("ERRO cklist02 - inclusão da SS")
			else
			*/
				//fEnvEmail(cCodbem, cPlaca, cPergunta, cInfResp, cDesRes, cContad, cIdmov,;
				//			alltrim(Posicione("ZCC",3,XFILIAL("ZCC")+cCpf,"ZCC_NOME")), TQB->TQB_SOLICI, cOrigem, "F")

			//Endif
			
		else
			lRet := .F.
		endif	

	endif

	RestArea(_aArea)
Return(lRet)
user function fIncIpal(cIdmov, cIDIpal, cCodChe, cSeqPer, cCodPer, cSeqRes, cCodRes, cCpftec, cCpfMem, cObs, cProjeto, dDtAber, cPlaca, cHoraInc, cTipMov)
	Local lRet		:= .T.
	Local _aArea 	:= getArea()
	Local cCpfSup	:= ""
	Local cIdMovLib	:= ""
	
	ZDQ->(DbSetOrder(2))
	if ZDQ->(dbSeek(xFilial("ZDQ")+cPlaca+DTOS(dDtAber)+"L"+"LF"))  //busca o lider da equipe no momento da liberação pelo supervisor
		cCpfSup 	:= ZDQ->ZDQ_CPFTEC
		cIdMovLib	:= ZDQ->ZDQ_IDMOV
	endif

	cRegist := GetSXENum("ZDG","ZDG_REGIST") 

	ZDG->(DbSetorder(2))  //ZDG_FILIAL+ZDG_IDMOV+ZDG_IDIPAL+ZDG_CODCHE+ZDG_SEQPER+ZDG_CODPER+ZDG_SEQRES+ZDG_CODRES
	if !ZDG->(DbSeek(xfilial("ZDG") + cIdmov + cIDIpal + cCodChe + cSeqPer + cCodPer + cSeqRes + cCodRes + cPlaca + cCpftec + cCpfMem + dtos(dDtAber) + cHoraInc + cTipMov ))
		ZDG->(RecLock("ZDG",.T.))
		ZDG->ZDG_FILIAL	:= xFilial("ZDG")
		ZDG->ZDG_REGIST	:= cRegist                                                                                                 
		ZDG->ZDG_IDMOV	:= cIdmov
		ZDG->ZDG_IDIPAL	:= cIDIpal
		ZDG->ZDG_CODCHE	:= cCodChe
		ZDG->ZDG_SEQPER := cSeqPer
		ZDG->ZDG_CODPER	:= cCodPer
		ZDG->ZDG_SEQRES := cSeqRes
		ZDG->ZDG_CODRES	:= cCodRes
		ZDG->ZDG_CPFTEC	:= cCpftec
		ZDG->ZDG_CPFMEM := cCpfMem
		ZDG->ZDG_OBS   	:= cObs
		ZDG->ZDG_DATGER	:= dDtAber
		ZDG->ZDG_DATPRG	:= ctod("  /  /    ")
		ZDG->ZDG_DATFIN	:= ctod("  /  /    ")
		ZDG->ZDG_FUNTRA	:= ""
		ZDG->ZDG_REF   	:= ""
		ZDG->ZDG_STATUS	:= "P"
		ZDG->ZDG_PROJET	:= cProjeto
		ZDG->ZDG_PLACA  := cPlaca
		ZDG->ZDG_CPFSUP := cCpfSup
		ZDG->ZDG_IDLIBE := cIdMovLib		
		ZDG->ZDG_HORINC := cHoraInc
		ZDG->ZDG_TPMOV  := cTipMov
		ZDG->(msUnLock())
	endif

	ConfirmSX8()				

	RestArea(_aArea)
Return(lRet)

static function fEnvEmail(cCodbem, cPlaca, cPergunta, cInfResp, cDesRes, cContad, cIdmov, cNome, cNumSol, cOrigem, cDestino)
	Local cMsg := ""
	Local xRet
	Local oServer, oMessage
	Local lMailAuth	:= SuperGetMv("MV_RELAUTH",,.F.)
	Local nPorta    := 587 //informa a porta que o servidor SMTP irá se comunicar, podendo ser 25 ou 587
    Local cPara     := GETMV("MV_XAPPSSE") 
    Local cCopia    := "" //GETMV("MV_XCEMAIL") 
    Local cAssunto  := "Solicitação de Serviço Gerada por eOpera - "+cOrigem
    Local 	cMensagem := "Foi Gerado uma Solicitação de Serviço para o Veículo: "+cPlaca+" do Motorista "+alltrim(cNome) + CRLF
			cMensagem += '<br>' + CRLF
    		cMensagem += '<br>' + CRLF
			if !empty(cCodBem)
    			cMensagem += "Centro de Custo: "+Posicione("ST9",1,xFilial("ST9")+cCodbem,"T9_CCUSTO") + "-"+;
							Posicione("CTT",1,XFILIAL("CTT")+Posicione("ST9",1,xFilial("ST9")+cCodbem,"T9_CCUSTO"),"CTT_DESC01") + CRLF
			endif
    		cMensagem += '<br>' + CRLF
    		cMensagem += "Pergunta: "+alltrim(cPergunta) + CRLF
    		cMensagem += '<br>' + CRLF
    		cMensagem += "Resposta: "+alltrim(cInfResp)+ " "+ alltrim(cDesRes) + CRLF
    		cMensagem += '<br>' + CRLF
    		cMensagem += "Contador:" + cContad + " ID Movimento: " + cIdmov + CRLF
    		cMensagem += '<br>' + CRLF
    		cMensagem += "Num Solicitação: "+cNumSol + CRLF
    		cMensagem += '<br>' + CRLF
    		cMensagem += '<br>' + CRLF	
			cMensagem += "GERADO POR EOPERA" + CRLF
 
	Private cMailConta :=GETMV("MV_RELACNT") //Conta utilizada para envio do email
	Private cMailServer:=GETMV("MV_XSRVMAI",.F.,"smtp.office365.com")  //GETMV("MV_RELSERV") //Servidor SMTP
	Private cMailSenha :=GETMV("MV_RELPSW")  //Senha da conta de e-mail utilizada para envio
    
	if cDestino = "F" //frota
		cPara     := GETMV("MV_XAPPEEF",.F.,"sinval@sgttec.com.br") 
	elseif cDestino = "S" //Sesmt
			cPara := GETMV("MV_XAPPEES",.F.,"sinval@sgttec.com.br") 
	elseif cDestino = "T" //TI
			cPara := GETMV("MV_XAPPEET",.F.,"sinval@sgttec.com.br") 
	else
			cPara := "sinval@sgttec.com.br"
	endif

	conout("Enviando E-mail "+cPara)

	if !Empty(cPara)
		oMessage:= TMailMessage():New()
		oMessage:Clear()
	
		oMessage:cDate	 := cValToChar( Date() )
		oMessage:cFrom 	 := cMailConta
		oMessage:cTo 	 := cPara
		oMessage:cCc     := cCopia
		oMessage:cSubject:= cAssunto
		oMessage:cBody 	 := cMensagem

		oServer := tMailManager():New()
		oServer:SetUseTLS( .T. ) //Indica se será utilizará a comunicação segura através de SSL/TLS (.T.) ou não (.F.)
	
		xRet := oServer:Init( "", cMailServer, cMailConta, cMailSenha, nPorta ) //inicilizar o servidor
		if xRet != 0
			conout("O servidor SMTP não foi inicializado: " + oServer:GetErrorString( xRet ) )
			return
		endif
	
		xRet := oServer:SetSMTPTimeout( 60 ) //Indica o tempo de espera em segundos.
		if xRet != 0
			conout("Não foi possível definir " + cProtocol + " tempo limite para " + cValToChar( nTimeout ))
		endif
	
		xRet := oServer:SMTPConnect()
		if xRet <> 0
			conout("Não foi possível conectar ao servidor SMTP: " + oServer:GetErrorString( xRet ))
			return
		endif
	
		if lMailAuth
			//O método SMTPAuth ao tentar realizar a autenticação do 
			//usuário no servidor de e-mail, verifica a configuração 
			//da chave AuthSmtp, na seção [Mail], no arquivo de 
			//configuração (INI) do TOTVS Application Server, para determinar o valor.
			xRet := oServer:SmtpAuth( cMailConta, cMailSenha )
			if xRet <> 0
				cMsg := "Could not authenticate on SMTP server: " + oServer:GetErrorString( xRet )
				conout( cMsg )
				oServer:SMTPDisconnect()
				return
			endif
		Endif
		xRet := oMessage:Send( oServer )
		if xRet <> 0
			conout("Não foi possível enviar mensagem: " + oServer:GetErrorString( xRet ))
		else
			conout("E-mail enviado com suscesso" )
		endif
	
		xRet := oServer:SMTPDisconnect()
		if xRet <> 0
			conout("Não foi possível desconectar o servidor SMTP: " + oServer:GetErrorString( xRet ))
		endif
	endif
return

/*
Para utilização no Inicializador Padrao do campo:

IF(!INCLUI,MSMM(SA1->A1_CODTST),"")
===========================================================
Para gravacao do campo memo, incluir a funcao MSMM no programa. 
No caso de inclusao:
_cTeste := M->A1_TESTE
_nTam := TamSX3("A1_TESTE")
_nTam1 := _nTam[1]
MSMM(,_nTam1,,_cTeste,1,,,"SA1","A1_CODTST")

Caso seja alteracao:
_cTeste := M->A1_TESTE
_nTam := TamSX3("A1_TESTE")
_nTam1 := _nTam[1]
MSMM(SA1->A1_TESTE,_nTam1,,_cTeste,1,,,"SA1","A1_CODTST")


SELECT ZC0.ZC0_CODCHE CODIGO, ZC0.ZC0_DESCHE NOME, ZC0.ZC0_DESTIN DESTINO,ZCC.ZCC_CPF CPF, ZCC.ZCC_CODLEI LEITURISTA, 
ZC7.ZC7_GRUPER GRUPER, ZC7.ZC7_SEQPER SEQPERG, ZC7.ZC7_CODPER CODPERG,  ZCO.ZCO_DESRES NOMPERG, 
ZC7.ZC7_NECFOT NECFOTO, ZC7.ZC7_FOTNEG FOTONEG, ZC7.ZC7_INFFOT INFFOTO, ZC7.ZC7_QTDFOT QTDFOTO,	 
ZC7.ZC7_NECJUS NECJUST, ZC8.ZC8_SEQRES SEQRESP, ZC8.ZC8_CODRES CODRESP, 
ZC4.ZC4_DESRES RESPOSTA, ZC4.ZC4_TIPRES TIPORES 
FROM ZCC010 ZCC 
INNER JOIN ZC9010 ZC9 ON (ZC9.D_E_L_E_T_ = ' ' AND ZC9.ZC9_CODGRU = ZCC.ZCC_CODGRU) 
INNER JOIN ZCE010 ZCE ON (ZCE.D_E_L_E_T_ = ' ' AND ZCE.ZCE_CODGRU = ZCC.ZCC_CODGRU) 
INNER JOIN ZC7010 ZC7 ON (ZC7.D_E_L_E_T_ = ' ' AND ZC7.ZC7_CODCHE = ZCE.ZCE_CODCHE) 
INNER JOIN ZC0010 ZC0 ON (ZC0.D_E_L_E_T_ = ' ' AND ZC0.ZC0_CODCHE = ZCE.ZCE_CODCHE ) 
INNER JOIN ZCO010 ZCO ON (ZCO.D_E_L_E_T_ = ' ' AND ZCO.ZCO_CODPER = ZC7.ZC7_CODPER) 
INNER JOIN ZC8010 ZC8 ON (ZC8.D_E_L_E_T_ = ' ' AND ZC8.ZC8_CODCHE = ZC7.ZC7_CODCHE  
AND ZC8.ZC8_GRUPER = ZC7.ZC7_GRUPER AND ZC8.ZC8_SEQPER = ZC7.ZC7_SEQPER AND ZC8.ZC8_CODPER = ZC7.ZC7_CODPER) 
INNER JOIN ZC4010 ZC4 ON (ZC4.D_E_L_E_T_ = ' ' AND ZC4.ZC4_CODRES = ZC8.ZC8_CODRES) 
WHERE ZCC.D_E_L_E_T_ = ' ' AND ZCC.ZCC_CPF = '13136648803'
ORDER BY CODIGO, GRUPER, SEQPERG, CODPERG, SEQRESP, CODRESP



*/
