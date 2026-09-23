#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "REPORT.CH"

/*/{Protheus.doc} RELATER01
Relatorio de Pesagens do Aterro (tabela NJH).
Pode ser executado em dois modos, definidos pelo parametro Tipo de Relatorio:
  Sintetico  - Mostra por status (Sem Pesagem/Primeira Pesagem/Segunda Pesagem/
               Finalizada/Cancelada) a quantidade de tickets e o peso liquido
               total (NJH_PSSUBT), alem dos totais gerais (caminhoes
               contabilizados e peso total pesado exceto cancelados).
  Analitico  - Exporta todos os campos da tabela NJH (exceto NJH_XDTSIN e
               NJH_XSINC, que sao apenas controle interno de sincronizacao),
               acrescido de uma coluna com a descricao textual do status.
Parametros: Centro de Custo (NJH_XCLVL) De/Ate e Data (NJH_DATA) De/Ate.
A exportacao para Excel/PDF/HTML e feita pela propria tela padrao do
TReport, acionada por oReport:PrintDialog() (mesmo mecanismo do RELEST0001).
@type User Function
/*/
//=============================================================================
User Function RELATER01()
//=============================================================================
    Local oReport := Nil

    AjustaSX1(Padr("RELATER01", 10))
    Pergunte("RELATER01", .T.)

    oReport := xMontaRel()
    oReport:PrintDialog()

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

    // {X1_GRUPO,X1_ORDEM,X1_PERGUNTE,X1_PERSPA,X1_PERENG,X1_VARIAVL,X1_TIPO,X1_TAM,X1_DEC,X1_PRESEL,X1_GSC,X1_VALID,X1_VAR01,X1_DEF01,X1_DEF02,X1_DEF03,X1_F3}
    aAdd(aRegs, {cPerg,"01","Tipo de Relatorio  ","Tipo de Relatorio  ","Tipo de Relatorio  ","mv_ch1","N", 1,0,1,"C","","mv_par01","Sintetico","Analitico","",""})
    aAdd(aRegs, {cPerg,"02","Centro Custo De    ","Centro Custo De    ","Centro Custo De    ","mv_ch2","C",15,0,0,"G","","mv_par02","","","",""})
    aAdd(aRegs, {cPerg,"03","Centro Custo Ate   ","Centro Custo Ate   ","Centro Custo Ate   ","mv_ch3","C",15,0,0,"G","","mv_par03","ZZZZZZZZZZZZZZZ","","",""})
    aAdd(aRegs, {cPerg,"04","Data De            ","Data De            ","Data De            ","mv_ch4","D", 8,0,0,"G","","mv_par04","","","",""})
    aAdd(aRegs, {cPerg,"05","Data Ate           ","Data Ate           ","Data Ate           ","mv_ch5","D", 8,0,0,"G","","mv_par05","","","",""})

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

/*/{Protheus.doc} xMontaRel
Monta o objeto TReport de acordo com o modo escolhido (Sintetico/Analitico).
@type Static Function
@return oReport Object, instancia do TReport pronta para impressao
/*/
//=============================================================================
Static Function xMontaRel()
//=============================================================================
    Local oReport   := Nil
    Local oSection1 := Nil
    Local cPeriodo  := "Periodo: " + DtoC(mv_par04) + " a " + DtoC(mv_par05)
    Local cCCusto   := "CC: " + AllTrim(mv_par02) + " a " + AllTrim(mv_par03)
    Local aStru     := {}
    Local aExclude  := {"NJH_XDTSIN", "NJH_XSINC", "D_E_L_E_T_"}
    Local nI        := 0
    Local cField    := ""

    If mv_par01 == 1

        oReport := TReport():New("RELATER01", "Pesagens Aterro - Sintetico - " + cPeriodo + " - " + cCCusto, "RELATER01", {|oReport| xImpSintetico(oReport)}, "Resumo de Pesagens")
        oReport:SetTotalInLine(.F.)
        oReport:oPage:SetPaperSize(10)

        oSection1 := TRSection():New(oReport, "Resumo por Status", {"NJH"}, {})
        oSection1:SetTotalInLine(.F.)

        TRCell():New(oSection1, "DESCSTATUS", "   ", "Status", , 40)
        TRCell():New(oSection1, "QTDSTATUS" , "   ", "Quantidade", "@E 999,999", 12)
        TRCell():New(oSection1, "PESOSTATUS", "   ", "Peso Total (KG)", "@E 999,999,999.99", 18)

        oSection1:Cell("DESCSTATUS"):SetHeaderAlign("LEFT")
        oSection1:Cell("QTDSTATUS"):SetHeaderAlign("RIGHT")
        oSection1:Cell("PESOSTATUS"):SetHeaderAlign("RIGHT")

    Else

        oReport := TReport():New("RELATER01", "Pesagens Aterro - Analitico - " + cPeriodo + " - " + cCCusto, "RELATER01", {|oReport| xImpAnalitico(oReport)}, "Movimentos de Pesagem")
        oReport:SetTotalInLine(.F.)
        oReport:SetLandscape()
        oReport:oPage:SetPaperSize(10)

        oSection1 := TRSection():New(oReport, "Movimentos NJH", {"NJH"}, {})
        oSection1:SetTotalInLine(.F.)

        aStru := NJH->(DbStruct())
        For nI := 1 To Len(aStru)
            cField := AllTrim(aStru[nI][01])
            If AScan(aExclude, {|x| x == cField}) == 0
                TRCell():New(oSection1, cField, "NJH")
            EndIf
        Next nI

        TRCell():New(oSection1, "XSTATUSDESC", "   ", "Descricao do Status", , 20)
        oSection1:Cell("XSTATUSDESC"):SetHeaderAlign("LEFT")

    EndIf

Return oReport

/*/{Protheus.doc} xDescStatus
Traduz o codigo de NJH_STATUS para a descricao textual correspondente.
@type Static Function
@param cStatus Character, codigo do status (0 a 4)
@return cDesc Character, descricao do status
/*/
//=============================================================================
Static Function xDescStatus(cStatus)
//=============================================================================
    Local cDesc := ""

    Do Case
        Case cStatus == "0" ; cDesc := "Sem Pesagem"
        Case cStatus == "1" ; cDesc := "Primeira Pesagem"
        Case cStatus == "2" ; cDesc := "Segunda Pesagem"
        Case cStatus == "3" ; cDesc := "Finalizada"
        Case cStatus == "4" ; cDesc := "Cancelada"
        Otherwise           ; cDesc := "Nao Identificado"
    EndCase

Return cDesc

/*/{Protheus.doc} xImpSintetico
Executa a consulta agrupada por status e imprime o resumo (quantidade e peso
total por status), alem das linhas de totais gerais.
@type Static Function
@param oReport Object, instancia do TReport em execucao
/*/
//=============================================================================
Static Function xImpSintetico(oReport)
//=============================================================================
#IFDEF TOP
    Local oSection1 := oReport:Section(1)
    Local cAliasTOP := GetNextAlias()
    Local cQuery    := ""
    Local cCCDe     := AllTrim(mv_par02)
    Local cCCAte    := AllTrim(mv_par03)
    Local dDtDe     := mv_par04
    Local dDtAte    := mv_par05
    Local aStatus   := {"0", "1", "2", "3", "4"}
    Local aRes      := {}
    Local nI        := 0
    Local nIdx      := 0
    Local nQtdTot   := 0
    Local nPesoTot  := 0

    For nI := 1 To Len(aStatus)
        aAdd(aRes, {0, 0})
    Next nI

    cQuery := "SELECT NJH.NJH_STATUS, COUNT(*) QTDTOTAL, SUM(NJH.NJH_PSSUBT) PESOTOTAL "
    cQuery += "FROM " + RetSqlName("NJH") + " NJH "
    cQuery += "WHERE NJH.D_E_L_E_T_ = ' ' "
    //cQuery += "AND NJH.NJH_FILIAL = '" + xFilial("NJH") + "' "
    cQuery += "AND NJH.NJH_XCLVL BETWEEN '" + cCCDe + "' AND '" + cCCAte + "' "
    cQuery += "AND NJH.NJH_DATA BETWEEN '" + DTOS(dDtDe) + "' AND '" + DTOS(dDtAte) + "' "
    cQuery += "GROUP BY NJH.NJH_STATUS "

    dbUseArea(.T., "TOPCONN", TcGenQry(, , cQuery), cAliasTOP, .T., .T.)

    dbSelectArea(cAliasTOP)
    dbGoTop()
    Do While !(cAliasTOP)->(Eof())
        nIdx := AScan(aStatus, AllTrim((cAliasTOP)->NJH_STATUS))
        If nIdx > 0
            aRes[nIdx][1] := (cAliasTOP)->QTDTOTAL
            aRes[nIdx][2] := If(Empty((cAliasTOP)->PESOTOTAL), 0, (cAliasTOP)->PESOTOTAL)
        EndIf
        (cAliasTOP)->(dbSkip())
    EndDo
    (cAliasTOP)->(dbCloseArea())

    oSection1:Init()

    For nI := 1 To Len(aStatus)
        oReport:IncMeter()

        oSection1:Cell("DESCSTATUS"):SetValue(xDescStatus(aStatus[nI]))
        oSection1:Cell("QTDSTATUS"):SetValue(aRes[nI][1])
        oSection1:Cell("PESOSTATUS"):SetValue(aRes[nI][2])
        oSection1:PrintLine()

        nQtdTot  += aRes[nI][1]
        nPesoTot += aRes[nI][2]
    Next nI

    oSection1:Cell("DESCSTATUS"):SetValue("TOTAL GERAL (Caminhoes Contabilizados)")
    oSection1:Cell("QTDSTATUS"):SetValue(nQtdTot)
    oSection1:Cell("PESOSTATUS"):SetValue(nPesoTot)
    oSection1:PrintLine()

    oSection1:Cell("DESCSTATUS"):SetValue("TOTAL PESADO (Exceto Cancelados)")
    oSection1:Cell("QTDSTATUS"):SetValue(nQtdTot - aRes[5][1])
    oSection1:Cell("PESOSTATUS"):SetValue(nPesoTot - aRes[5][2])
    oSection1:PrintLine()

    oSection1:Finish()
#ENDIF
Return Nil

/*/{Protheus.doc} xImpAnalitico
Exporta todos os campos da tabela NJH (exceto NJH_XDTSIN e NJH_XSINC),
acrescentando a descricao textual do status em cada linha.
@type Static Function
@param oReport Object, instancia do TReport em execucao
/*/
//=============================================================================
Static Function xImpAnalitico(oReport)
//=============================================================================
#IFDEF TOP
    Local oSection1 := oReport:Section(1)
    Local cAliasTOP := GetNextAlias()
    Local cQuery    := ""
    Local cCCDe     := AllTrim(mv_par02)
    Local cCCAte    := AllTrim(mv_par03)
    Local dDtDe     := mv_par04
    Local dDtAte    := mv_par05
    Local aStru     := NJH->(DbStruct())
    Local aExclude  := {"NJH_XDTSIN", "NJH_XSINC", "D_E_L_E_T_"}
    Local aFields   := {}
    Local aTypes    := {}
    Local cCampos   := ""
    Local cField    := ""
    Local cValor    := ""
    Local nI        := 0

    For nI := 1 To Len(aStru)
        cField := AllTrim(aStru[nI][01])
        If AScan(aExclude, {|x| x == cField}) == 0
            aAdd(aFields, cField)
            aAdd(aTypes, aStru[nI][02])
        EndIf
    Next nI

    For nI := 1 To Len(aFields)
        cCampos += "NJH." + aFields[nI]
        If nI < Len(aFields)
            cCampos += ", "
        EndIf
    Next nI

    cQuery := "SELECT " + cCampos + " "
    cQuery += "FROM " + RetSqlName("NJH") + " NJH "
    cQuery += "WHERE NJH.D_E_L_E_T_ = ' ' "
    //cQuery += "AND NJH.NJH_FILIAL = '" + xFilial("NJH") + "' "
    cQuery += "AND NJH.NJH_XCLVL BETWEEN '" + cCCDe + "' AND '" + cCCAte + "' "
    cQuery += "AND NJH.NJH_DATA BETWEEN '" + DTOS(dDtDe) + "' AND '" + DTOS(dDtAte) + "' "
    cQuery += "ORDER BY NJH.NJH_DATA, NJH.NJH_CODPAV "

    dbUseArea(.T., "TOPCONN", TcGenQry(, , cQuery), cAliasTOP, .T., .T.)

    oSection1:Init()

    dbSelectArea(cAliasTOP)
    dbGoTop()
    Do While !(cAliasTOP)->(Eof())

        oReport:IncMeter()
        If oReport:Cancel()
            Exit
        EndIf

        For nI := 1 To Len(aFields)
            cValor := (cAliasTOP)->(FieldGet(nI))
            If aTypes[nI] == "D" .And. ValType(cValor) == "C"
                cValor := If(Empty(cValor), CtoD(""), StoD(cValor))
            EndIf
            oSection1:Cell(aFields[nI]):SetValue(cValor)
        Next nI

        oSection1:Cell("XSTATUSDESC"):SetValue(xDescStatus(AllTrim((cAliasTOP)->NJH_STATUS)))

        oSection1:PrintLine()

        (cAliasTOP)->(dbSkip())
    EndDo

    (cAliasTOP)->(dbCloseArea())
    oSection1:Finish()
#ENDIF
Return Nil
