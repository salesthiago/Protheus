#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "REPORT.CH"

/*/{Protheus.doc} RELLEADT
Relatorio de Lead Time de Compras: tempo (em dias corridos) ate a entrada
no estoque / recebimento no Protheus (SD1->D1_DTDIGIT), contado a partir de:
  1 - Emissao do Pedido de Compra      (SC7->C7_EMISSAO)
  2 - Emissao da Solicitacao de Compra (SC1->C1_EMISSAO)
conforme o parametro "Contar a partir de".

Agrupa por Filial x Armazem x Produto e imprime:
  - Grupo de produto e descricao do grupo
  - Numeros das solicitacoes, pedidos de compra e ordens de servico (OS do
    SIGAMNT) envolvidos (concatenados)
  - Quantidade de entradas (documentos distintos)
  - Quantidade total recebida
  - Lead time minimo, medio e maximo (em dias)
Ao final imprime a linha de TOTAL GERAL.

Regras:
  - Somente NF tipo Normal (D1_TIPO = 'N') vinculadas a pedido de compra.
  - Somente itens ja classificados (D1_TES preenchida) com TES que
    atualiza estoque (F4_ESTOQUE = 'S').
  - Contando a partir da SC, somente pedidos gerados a partir de uma
    solicitacao de compra (C7_NUMSC preenchido) sao considerados.
  - Ordem de Servico: identificada pelo padrao do SIGAMNT no C7_OP do
    pedido ou no C1_OP da SC (TJ_ORDEM + 'OS' + '001'). O parametro
    "Ordem de Servico" permite trazer Todos, Somente com OS ou Somente sem OS.

A saida usa a tela padrao do TReport (PrintDialog), que ja oferece
visualizacao em tela, exportacao para Excel (Planilha) e PDF.

Parametros: Filial De/Ate, Armazem De/Ate, Produto De/Ate,
Data Entrada De/Ate (D1_DTDIGIT), Grupo De/Ate, Contar a partir de e
Ordem de Servico.
@type User Function
@author Thiago Sales - Quebec Ambiental
@since 2026-11-12
/*/
//=============================================================================
User Function RELLEADT()
//=============================================================================
	Local oReport := Nil
	Local cPerg   := "RELLEADT"

	AjustaSX1(Padr(cPerg, 10))

	If !Pergunte(cPerg, .T.)
		Return Nil
	EndIf

	oReport := xRelDef()

	If oReport <> Nil
		oReport:PrintDialog()
	EndIf

Return Nil

/*/{Protheus.doc} AjustaSX1
Registra as perguntas do relatorio na tabela SX1, caso ainda nao existam.
@type Static Function
@param cPerg Character, identificador do grupo de perguntas
/*/
//=============================================================================
Static Function AjustaSX1(cPerg)
//=============================================================================
	Local aRegs := {}
	Local nX    := 0
	Local nTFil := TamSX3("D1_FILIAL")[1]
	Local nTLoc := TamSX3("D1_LOCAL")[1]
	Local nTPrd := TamSX3("D1_COD")[1]
	Local nTGrp := TamSX3("B1_GRUPO")[1]

	// {X1_GRUPO,X1_ORDEM,X1_PERGUNTE,X1_PERSPA,X1_PERENG,X1_VARIAVL,X1_TIPO,X1_TAM,X1_DEC,X1_PRESEL,X1_GSC,X1_VALID,X1_VAR01,X1_DEF01,X1_DEF02,X1_DEF03,X1_F3}
	aAdd(aRegs, {cPerg,"01","Filial De          ","Filial De          ","Filial De          ","mv_ch1","C",nTFil,0,0,"G","","mv_par01","","","","SM0"})
	aAdd(aRegs, {cPerg,"02","Filial Ate         ","Filial Ate         ","Filial Ate         ","mv_ch2","C",nTFil,0,0,"G","","mv_par02","","","","SM0"})
	aAdd(aRegs, {cPerg,"03","Armazem De         ","Armazem De         ","Armazem De         ","mv_ch3","C",nTLoc,0,0,"G","","mv_par03","","","","NNR"})
	aAdd(aRegs, {cPerg,"04","Armazem Ate        ","Armazem Ate        ","Armazem Ate        ","mv_ch4","C",nTLoc,0,0,"G","","mv_par04","","","","NNR"})
	aAdd(aRegs, {cPerg,"05","Produto De         ","Produto De         ","Produto De         ","mv_ch5","C",nTPrd,0,0,"G","","mv_par05","","","","SB1"})
	aAdd(aRegs, {cPerg,"06","Produto Ate        ","Produto Ate        ","Produto Ate        ","mv_ch6","C",nTPrd,0,0,"G","","mv_par06","","","","SB1"})
	aAdd(aRegs, {cPerg,"07","Data Entrada De    ","Data Entrada De    ","Data Entrada De    ","mv_ch7","D",8,0,0,"G","","mv_par07","","","",""})
	aAdd(aRegs, {cPerg,"08","Data Entrada Ate   ","Data Entrada Ate   ","Data Entrada Ate   ","mv_ch8","D",8,0,0,"G","","mv_par08","","","",""})
	aAdd(aRegs, {cPerg,"09","Grupo Produto De   ","Grupo Produto De   ","Grupo Produto De   ","mv_ch9","C",nTGrp,0,0,"G","","mv_par09","","","","SBM"})
	aAdd(aRegs, {cPerg,"10","Grupo Produto Ate  ","Grupo Produto Ate  ","Grupo Produto Ate  ","mv_cha","C",nTGrp,0,0,"G","","mv_par10","","","","SBM"})
	aAdd(aRegs, {cPerg,"11","Contar a partir de ","Contar a partir de ","Contar a partir de ","mv_chb","N",1,0,1,"C","","mv_par11","Pedido Compra","Solicitacao Compra","",""})
	aAdd(aRegs, {cPerg,"12","Ordem de Servico   ","Ordem de Servico   ","Ordem de Servico   ","mv_chc","N",1,0,1,"C","","mv_par12","Todos","Somente com OS","Somente sem OS",""})

	DbSelectArea("SX1")
	SX1->(DbSetOrder(1))

	For nX := 1 To Len(aRegs)
		If !SX1->(DbSeek(aRegs[nX][01] + aRegs[nX][02]))
			RecLock("SX1", .T.)
			Replace SX1->X1_GRUPO    With aRegs[nX][01]
			Replace SX1->X1_ORDEM    With aRegs[nX][02]
			Replace SX1->X1_PERGUNTE With aRegs[nX][03]
			Replace SX1->X1_PERSPA   With aRegs[nX][04]
			Replace SX1->X1_PERENG   With aRegs[nX][05]
			Replace SX1->X1_VARIAVL  With aRegs[nX][06]
			Replace SX1->X1_TIPO     With aRegs[nX][07]
			Replace SX1->X1_TAMANHO  With aRegs[nX][08]
			Replace SX1->X1_DECIMAL  With aRegs[nX][09]
			Replace SX1->X1_PRESEL   With aRegs[nX][10]
			Replace SX1->X1_GSC      With aRegs[nX][11]
			Replace SX1->X1_VALID    With aRegs[nX][12]
			Replace SX1->X1_VAR01    With aRegs[nX][13]
			Replace SX1->X1_DEF01    With aRegs[nX][14]
			Replace SX1->X1_DEF02    With aRegs[nX][15]
			Replace SX1->X1_DEF03    With aRegs[nX][16]
			Replace SX1->X1_F3       With aRegs[nX][17]
			MsUnlock("SX1")
		EndIf
	Next nX

Return

/*/{Protheus.doc} xAte
Retorna o valor "Ate" do parametro; se vazio, preenche com "Z" no tamanho
informado (traz tudo).
@type Static Function
/*/
//=============================================================================
Static Function xAte(cVal, nTam)
//=============================================================================
Return If(Empty(cVal), Replicate("Z", nTam), cVal)

/*/{Protheus.doc} xPorSC
Indica se o lead time deve ser contado a partir da Solicitacao de Compra.
@type Static Function
/*/
//=============================================================================
Static Function xPorSC()
//=============================================================================
Return (ValType(mv_par11) == "N" .And. mv_par11 == 2)

/*/{Protheus.doc} xFiltroOS
Retorna a opcao do parametro "Ordem de Servico":
1 = Todos, 2 = Somente com OS, 3 = Somente sem OS.
@type Static Function
/*/
//=============================================================================
Static Function xFiltroOS()
//=============================================================================
Return If(ValType(mv_par12) == "N" .And. mv_par12 >= 1 .And. mv_par12 <= 3, mv_par12, 1)

/*/{Protheus.doc} xExpOS
Expressao SQL que devolve o numero da Ordem de Servico (SIGAMNT) vinculada
ao item do pedido ou da solicitacao, ou NULL quando nao houver.
Padrao MNT: C7_OP / C1_OP = TJ_ORDEM (6) + 'OS' + '001'
(mesma regra usada em BI/BIQFIN.PRW).
@type Static Function
/*/
//=============================================================================
Static Function xExpOS()
//=============================================================================
	Local cE := ""

	cE += "(CASE "
	cE += "WHEN SUBSTRING(SC7.C7_OP, 7, 2) = 'OS' THEN LEFT(SC7.C7_OP, 6) "
	cE += "WHEN SUBSTRING(SC1.C1_OP, 7, 2) = 'OS' THEN LEFT(SC1.C1_OP, 6) "
	cE += "END)"

Return cE

/*/{Protheus.doc} xFromWhere
Monta os JOINs e o WHERE comuns as duas consultas do relatorio (resumo e
lista de pedidos), aplicando todos os filtros dos parametros.
@type Static Function
@return cQ Character, trecho FROM ... WHERE da query
/*/
//=============================================================================
Static Function xFromWhere()
//=============================================================================
	Local cFilDe  := mv_par01
	Local cFilAte := xAte(mv_par02, TamSX3("D1_FILIAL")[1])
	Local cLocDe  := mv_par03
	Local cLocAte := xAte(mv_par04, TamSX3("D1_LOCAL")[1])
	Local cPrdDe  := mv_par05
	Local cPrdAte := xAte(mv_par06, TamSX3("D1_COD")[1])
	Local dDtDe   := If(Empty(mv_par07), CTOD("01/01/1900"), mv_par07)
	Local dDtAte  := If(Empty(mv_par08), Date(), mv_par08)
	Local cGrpDe  := mv_par09
	Local cGrpAte := xAte(mv_par10, TamSX3("B1_GRUPO")[1])
	Local cQ      := ""

	cQ += "FROM " + RetSqlName("SD1") + " SD1 "

	// Item do Pedido de Compras
	cQ += "INNER JOIN " + RetSqlName("SC7") + " SC7 "
	cQ += "ON SC7.C7_FILIAL = SD1.D1_FILIAL "
	cQ += "AND SC7.C7_NUM = SD1.D1_PEDIDO "
	cQ += "AND SC7.C7_ITEM = SD1.D1_ITEMPC "
	cQ += "AND SC7.D_E_L_E_T_ = ' ' "

	// Item da Solicitacao de Compras: obrigatorio quando contar a partir da
	// SC; opcional (LEFT) nos demais casos, para identificar SC e OS
	cQ += If(xPorSC(), "INNER JOIN ", "LEFT JOIN ") + RetSqlName("SC1") + " SC1 "
	cQ += "ON SC1.C1_FILIAL = SC7.C7_FILIAL "
	cQ += "AND SC1.C1_NUM = SC7.C7_NUMSC "
	cQ += "AND SC1.C1_ITEM = SC7.C7_ITEMSC "
	cQ += "AND SC7.C7_NUMSC <> ' ' "
	cQ += "AND SC1.D_E_L_E_T_ = ' ' "

	// Produtos
	cQ += "INNER JOIN " + RetSqlName("SB1") + " SB1 "
	cQ += "ON SB1.B1_FILIAL = SUBSTRING(SD1.D1_FILIAL, 1, LEN(SB1.B1_FILIAL)) "
	cQ += "AND SB1.B1_COD = SD1.D1_COD "
	cQ += "AND SB1.D_E_L_E_T_ = ' ' "

	// Grupos de Produto
	cQ += "LEFT JOIN " + RetSqlName("SBM") + " SBM "
	cQ += "ON SBM.BM_FILIAL = SUBSTRING(SD1.D1_FILIAL, 1, LEN(SBM.BM_FILIAL)) "
	cQ += "AND SBM.BM_GRUPO = SB1.B1_GRUPO "
	cQ += "AND SBM.D_E_L_E_T_ = ' ' "

	// Armazens
	cQ += "LEFT JOIN " + RetSqlName("NNR") + " NNR "
	cQ += "ON NNR.NNR_FILIAL = SUBSTRING(SD1.D1_FILIAL, 1, LEN(NNR.NNR_FILIAL)) "
	cQ += "AND NNR.NNR_CODIGO = SD1.D1_LOCAL "
	cQ += "AND NNR.D_E_L_E_T_ = ' ' "

	// TES que movimenta estoque
	cQ += "INNER JOIN " + RetSqlName("SF4") + " SF4 "
	cQ += "ON SF4.F4_FILIAL = SUBSTRING(SD1.D1_FILIAL, 1, LEN(SF4.F4_FILIAL)) "
	cQ += "AND SF4.F4_CODIGO = SD1.D1_TES "
	cQ += "AND SF4.F4_ESTOQUE = 'S' "
	cQ += "AND SF4.D_E_L_E_T_ = ' ' "

	// Filiais
	cQ += "LEFT JOIN SYS_COMPANY EMP "
	cQ += "ON EMP.M0_CODIGO = '" + cEmpAnt + "' "
	cQ += "AND EMP.M0_CODFIL = SD1.D1_FILIAL "
	cQ += "AND EMP.D_E_L_E_T_ = ' ' "

	cQ += "WHERE SD1.D_E_L_E_T_ = ' ' "
	cQ += "AND SD1.D1_PEDIDO <> ' ' "
	cQ += "AND SD1.D1_TIPO = 'N' "
	cQ += "AND SD1.D1_TES <> ' ' "
	cQ += "AND SD1.D1_DTDIGIT <> ' ' "
	If xPorSC()
		cQ += "AND SC1.C1_EMISSAO <> ' ' "
	Else
		cQ += "AND SC7.C7_EMISSAO <> ' ' "
	EndIf
	cQ += "AND SD1.D1_FILIAL BETWEEN '" + cFilDe + "' AND '" + cFilAte + "' "
	cQ += "AND SD1.D1_LOCAL BETWEEN '" + cLocDe + "' AND '" + cLocAte + "' "
	cQ += "AND SD1.D1_COD BETWEEN '" + cPrdDe + "' AND '" + cPrdAte + "' "
	cQ += "AND SB1.B1_GRUPO BETWEEN '" + cGrpDe + "' AND '" + cGrpAte + "' "
	cQ += "AND SD1.D1_DTDIGIT BETWEEN '" + DTOS(dDtDe) + "' AND '" + DTOS(dDtAte) + "' "

	// Filtro de Ordem de Servico
	If xFiltroOS() == 2
		cQ += "AND " + xExpOS() + " IS NOT NULL "
	ElseIf xFiltroOS() == 3
		cQ += "AND " + xExpOS() + " IS NULL "
	EndIf

Return cQ

/*/{Protheus.doc} xMontaQry
Monta a query agregada de lead time por Filial x Armazem x Produto.
@type Static Function
@return cQ Character, query SQL
/*/
//=============================================================================
Static Function xMontaQry()
//=============================================================================
	Local cDtIni := If(xPorSC(), "SC1.C1_EMISSAO", "SC7.C7_EMISSAO")
	Local cLT    := "DATEDIFF(DAY, CAST(" + cDtIni + " AS DATE), CAST(SD1.D1_DTDIGIT AS DATE))"
	Local cQ     := ""

	cQ += "SELECT "
	cQ += "SD1.D1_FILIAL FILIAL, "
	cQ += "MAX(COALESCE(EMP.M0_FILIAL, '')) DESCFIL, "
	cQ += "SD1.D1_LOCAL ARMAZEM, "
	cQ += "MAX(COALESCE(NNR.NNR_DESCRI, '')) DESCARM, "
	cQ += "SD1.D1_COD PRODUTO, "
	cQ += "MAX(COALESCE(SB1.B1_DESC, '')) DESCPRD, "
	cQ += "MAX(COALESCE(SB1.B1_UM, '')) UM, "
	cQ += "MAX(COALESCE(SB1.B1_GRUPO, '')) GRUPO, "
	cQ += "MAX(COALESCE(SBM.BM_DESC, '')) DESCGRP, "
	cQ += "COUNT(DISTINCT SD1.D1_DOC + SD1.D1_SERIE + SD1.D1_FORNECE + SD1.D1_LOJA) QTDENT, "
	cQ += "SUM(SD1.D1_QUANT) QTDREC, "
	cQ += "COUNT(*) NITENS, "
	cQ += "SUM(" + cLT + ") SOMALT, "
	cQ += "MIN(" + cLT + ") LTMIN, "
	cQ += "CAST(AVG(CAST(" + cLT + " AS DECIMAL(10,2))) AS DECIMAL(10,2)) LTMED, "
	cQ += "MAX(" + cLT + ") LTMAX "
	cQ += xFromWhere()
	cQ += "GROUP BY SD1.D1_FILIAL, SD1.D1_LOCAL, SD1.D1_COD "
	cQ += "ORDER BY SD1.D1_FILIAL, SD1.D1_LOCAL, LTMED DESC "

Return cQ

/*/{Protheus.doc} xAddLista
Acrescenta cValor a lista (separada por virgula) da chave cChave em oLista,
sem repetir valores. oVistos guarda as combinacoes ja incluidas.
@type Static Function
/*/
//=============================================================================
Static Function xAddLista(oLista, oVistos, cTipo, cChave, cValor)
//=============================================================================
	Local cVisto := ""

	cValor := AllTrim(cValor)
	cVisto := cTipo + "|" + cChave + "|" + cValor

	If Empty(cValor) .Or. oVistos[cVisto] <> Nil
		Return Nil
	EndIf

	oVistos[cVisto] := .T.

	If oLista[cChave] == Nil
		oLista[cChave] := cValor
	Else
		oLista[cChave] += ", " + cValor
	EndIf

Return Nil

/*/{Protheus.doc} xListas
Busca os numeros distintos de Pedido de Compra, Solicitacao de Compra e
Ordem de Servico de cada Filial x Armazem x Produto (mesmos filtros do
resumo) e devolve tres JsonObject indexados pela chave
FILIAL+ARMAZEM+PRODUTO, com os numeros concatenados por virgula.
A concatenacao e feita em ADVPL para nao depender da versao do banco
(STRING_AGG so existe a partir do SQL Server 2017).
@type Static Function
@return aRet Array, {oPeds, oSCs, oOSs}
/*/
//=============================================================================
Static Function xListas()
//=============================================================================
	Local oPeds   := JsonObject():New()
	Local oSCs    := JsonObject():New()
	Local oOSs    := JsonObject():New()
	Local oVistos := JsonObject():New()
	Local cAlias  := GetNextAlias()
	Local cQ      := ""
	Local cChave  := ""

	cQ += "SELECT DISTINCT SD1.D1_FILIAL FILIAL, SD1.D1_LOCAL ARMAZEM, SD1.D1_COD PRODUTO, "
	cQ += "SD1.D1_PEDIDO PEDIDO, COALESCE(SC1.C1_NUM, '') NUMSC, COALESCE(" + xExpOS() + ", '') NUMOS "
	cQ += xFromWhere()
	cQ += "ORDER BY 1, 2, 3, 4, 5, 6 "

	TCQuery cQ New Alias (cAlias)

	Do While !(cAlias)->(Eof())
		cChave := (cAlias)->FILIAL + (cAlias)->ARMAZEM + (cAlias)->PRODUTO
		xAddLista(oPeds, oVistos, "P", cChave, (cAlias)->PEDIDO)
		xAddLista(oSCs , oVistos, "S", cChave, (cAlias)->NUMSC)
		xAddLista(oOSs , oVistos, "O", cChave, (cAlias)->NUMOS)
		(cAlias)->(DbSkip())
	EndDo

	(cAlias)->(DbCloseArea())

	FreeObj(oVistos)

Return {oPeds, oSCs, oOSs}

/*/{Protheus.doc} xLista
Retorna a lista concatenada da chave, ou "" quando nao houver.
@type Static Function
/*/
//=============================================================================
Static Function xLista(oLista, cChave)
//=============================================================================
Return If(oLista[cChave] == Nil, "", oLista[cChave])

/*/{Protheus.doc} xTitPer
Subtitulo do relatorio com a base de contagem e o periodo informado.
@type Static Function
/*/
//=============================================================================
Static Function xTitPer()
//=============================================================================
	Local cP := If(xPorSC(), " - A partir da SC", " - A partir do Pedido")

	If xFiltroOS() == 2
		cP += " - Somente com OS"
	ElseIf xFiltroOS() == 3
		cP += " - Somente sem OS"
	EndIf

	cP += " - Entradas de "
	cP += If(Empty(mv_par07), "Inicio", DtoC(mv_par07))
	cP += " a "
	cP += If(Empty(mv_par08), DtoC(Date()), DtoC(mv_par08))

Return cP

/*/{Protheus.doc} xRelDef
Monta o objeto TReport do relatorio de lead time.
@type Static Function
@return oReport Object, instancia do TReport
/*/
//=============================================================================
Static Function xRelDef()
//=============================================================================
	Local oReport   := Nil
	Local oSection1 := Nil
	Local cOrigem   := If(xPorSC(), "da solicitacao de compra", "do pedido de compra")

	oReport := TReport():New("RELLEADT", "Lead Time de Compras" + xTitPer(), "RELLEADT", ;
		{|oReport| xImprime(oReport)}, "Lead time em dias entre a emissao " + cOrigem + " e a entrada no estoque")
	oReport:SetTotalInLine(.F.)
	oReport:SetLandscape()
	oReport:oPage:SetPaperSize(9)

	oSection1 := TRSection():New(oReport, "Lead Time", {"SD1"}, {})
	oSection1:SetTotalInLine(.F.)

	TRCell():New(oSection1, "FILIAL" , "   ", "Filial"          ,                    , TamSX3("D1_FILIAL")[1] + 2)
	TRCell():New(oSection1, "DESCFIL", "   ", "Desc. Filial"    ,                    , 15)
	TRCell():New(oSection1, "ARMAZEM", "   ", "Armazem"         ,                    , 7)
	TRCell():New(oSection1, "DESCARM", "   ", "Desc. Armazem"   ,                    , 15)
	TRCell():New(oSection1, "GRUPO"  , "   ", "Grupo"           ,                    , TamSX3("B1_GRUPO")[1] + 2)
	TRCell():New(oSection1, "DESCGRP", "   ", "Desc. Grupo"     ,                    , 20)
	TRCell():New(oSection1, "PRODUTO", "   ", "Produto"         ,                    , TamSX3("D1_COD")[1])
	TRCell():New(oSection1, "DESCPRD", "   ", "Descricao"       ,                    , 30)
	TRCell():New(oSection1, "UM"     , "   ", "UM"              ,                    , 3)
	TRCell():New(oSection1, "SOLICIT", "   ", "Solicitacoes"    ,                    , 20, /*lPixel*/, /*bBlock*/, "LEFT", .T.)
	TRCell():New(oSection1, "PEDIDOS", "   ", "Pedidos"         ,                    , 20, /*lPixel*/, /*bBlock*/, "LEFT", .T.)
	TRCell():New(oSection1, "ORDSERV", "   ", "Ordens Servico"  ,                    , 20, /*lPixel*/, /*bBlock*/, "LEFT", .T.)
	TRCell():New(oSection1, "QTDENT" , "   ", "Qtd Entradas"    , "@E 999,999"       , 12)
	TRCell():New(oSection1, "QTDREC" , "   ", "Qtd Recebida"    , "@E 999,999,999.99", 16)
	TRCell():New(oSection1, "LTMIN"  , "   ", "LT Min (dias)"   , "@E 99,999"        , 13)
	TRCell():New(oSection1, "LTMED"  , "   ", "LT Medio (dias)" , "@E 99,999.99"     , 15)
	TRCell():New(oSection1, "LTMAX"  , "   ", "LT Max (dias)"   , "@E 99,999"        , 13)

	oSection1:Cell("QTDENT"):SetHeaderAlign("RIGHT")
	oSection1:Cell("QTDREC"):SetHeaderAlign("RIGHT")
	oSection1:Cell("LTMIN") :SetHeaderAlign("RIGHT")
	oSection1:Cell("LTMED") :SetHeaderAlign("RIGHT")
	oSection1:Cell("LTMAX") :SetHeaderAlign("RIGHT")

Return oReport

/*/{Protheus.doc} xImprime
Executa a consulta e imprime uma linha por Filial x Armazem x Produto,
com a linha de TOTAL GERAL ao final.
@type Static Function
@param oReport Object, instancia do TReport em execucao
/*/
//=============================================================================
Static Function xImprime(oReport)
//=============================================================================
	Local oSection1 := oReport:Section(1)
	Local cAlias    := GetNextAlias()
	Local cQuery    := xMontaQry()
	Local aListas   := xListas()
	Local oPeds     := aListas[1]
	Local oSCs      := aListas[2]
	Local oOSs      := aListas[3]
	Local cChave    := ""
	Local nReg      := 0
	Local nTEnt     := 0
	Local nTRec     := 0
	Local nTItens   := 0
	Local nTSomaLT  := 0
	Local nTMin     := Nil
	Local nTMax     := Nil

	TCQuery cQuery New Alias (cAlias)

	(cAlias)->(DbEval({|| nReg++}))
	oReport:SetMeter(nReg)
	(cAlias)->(DbGoTop())

	oSection1:Init()

	Do While !(cAlias)->(Eof())

		oReport:IncMeter()
		If oReport:Cancel()
			Exit
		EndIf

		cChave := (cAlias)->FILIAL + (cAlias)->ARMAZEM + (cAlias)->PRODUTO

		oSection1:Cell("FILIAL") :SetValue((cAlias)->FILIAL)
		oSection1:Cell("DESCFIL"):SetValue(AllTrim((cAlias)->DESCFIL))
		oSection1:Cell("ARMAZEM"):SetValue((cAlias)->ARMAZEM)
		oSection1:Cell("DESCARM"):SetValue(AllTrim((cAlias)->DESCARM))
		oSection1:Cell("GRUPO")  :SetValue((cAlias)->GRUPO)
		oSection1:Cell("DESCGRP"):SetValue(AllTrim((cAlias)->DESCGRP))
		oSection1:Cell("PRODUTO"):SetValue((cAlias)->PRODUTO)
		oSection1:Cell("DESCPRD"):SetValue(AllTrim((cAlias)->DESCPRD))
		oSection1:Cell("UM")     :SetValue((cAlias)->UM)
		oSection1:Cell("SOLICIT"):SetValue(xLista(oSCs , cChave))
		oSection1:Cell("PEDIDOS"):SetValue(xLista(oPeds, cChave))
		oSection1:Cell("ORDSERV"):SetValue(xLista(oOSs , cChave))
		oSection1:Cell("QTDENT") :SetValue((cAlias)->QTDENT)
		oSection1:Cell("QTDREC") :SetValue((cAlias)->QTDREC)
		oSection1:Cell("LTMIN")  :SetValue((cAlias)->LTMIN)
		oSection1:Cell("LTMED")  :SetValue((cAlias)->LTMED)
		oSection1:Cell("LTMAX")  :SetValue((cAlias)->LTMAX)
		oSection1:PrintLine()

		nTEnt    += (cAlias)->QTDENT
		nTRec    += (cAlias)->QTDREC
		nTItens  += (cAlias)->NITENS
		nTSomaLT += (cAlias)->SOMALT
		nTMin    := If(nTMin == Nil, (cAlias)->LTMIN, Min(nTMin, (cAlias)->LTMIN))
		nTMax    := If(nTMax == Nil, (cAlias)->LTMAX, Max(nTMax, (cAlias)->LTMAX))

		(cAlias)->(DbSkip())
	EndDo

	(cAlias)->(DbCloseArea())

	// Total geral (media ponderada pela quantidade de itens de NF)
	If nTItens > 0
		oReport:SkipLine()
		oSection1:Cell("FILIAL") :SetValue("TOTAL")
		oSection1:Cell("DESCFIL"):SetValue("GERAL")
		oSection1:Cell("ARMAZEM"):SetValue("")
		oSection1:Cell("DESCARM"):SetValue("")
		oSection1:Cell("GRUPO")  :SetValue("")
		oSection1:Cell("DESCGRP"):SetValue("")
		oSection1:Cell("PRODUTO"):SetValue("")
		oSection1:Cell("DESCPRD"):SetValue("")
		oSection1:Cell("UM")     :SetValue("")
		oSection1:Cell("SOLICIT"):SetValue("")
		oSection1:Cell("PEDIDOS"):SetValue("")
		oSection1:Cell("ORDSERV"):SetValue("")
		oSection1:Cell("QTDENT") :SetValue(nTEnt)
		oSection1:Cell("QTDREC") :SetValue(nTRec)
		oSection1:Cell("LTMIN")  :SetValue(nTMin)
		oSection1:Cell("LTMED")  :SetValue(Round(nTSomaLT / nTItens, 2))
		oSection1:Cell("LTMAX")  :SetValue(nTMax)
		oSection1:PrintLine()
	EndIf

	oSection1:Finish()

	FreeObj(oPeds)
	FreeObj(oSCs)
	FreeObj(oOSs)

Return Nil
