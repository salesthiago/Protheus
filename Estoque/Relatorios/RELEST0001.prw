#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "REPORT.CH"

/*/{Protheus.doc} RELEST0001
Relatorio de Posicao de Estoque por Produto/Armazem - Quebec Ambiental.
Consulta os produtos cadastrados na tabela ZEM (Estoque Minimo e Maximo),
cruza com o saldo atual (SB2) e a descricao do produto (SB1), e classifica
cada item como: ABAIXO DO MINIMO / NORMAL / ACIMA DO MAXIMO.
Parametros: faixa de armazem (ZEM_LOCAL) e filtro de status (Ativo/Inativo/Todos).
@type User Function
@author
@since
@version 3
/*/
//=============================================================================
User Function RELEST0001()
//=============================================================================
    Local oReport  := NIL
    Local oSection := NIL

    AjustaSX1(Padr("RELEST01", 10))
    Pergunte("RELEST01", .F.)

    DEFINE REPORT oReport NAME "RELEST01" TITLE "Posicao de Estoque" ;
        PARAMETER "RELEST01" ACTION {|oRpt| xGeraRelEst(oRpt)}

        DEFINE SECTION oSection OF oReport TITLE "Posicao de Estoque" TABLES "ZEM"

            DEFINE CELL NAME "ZEM_FILIAL" OF oSection ALIAS "ZEM" TITLE "Filial"       SIZE  6
            DEFINE CELL NAME "ZEM_PROD"   OF oSection ALIAS "ZEM" TITLE "Produto"      SIZE 15
            DEFINE CELL NAME "B1_DESC"    OF oSection ALIAS "SB1" TITLE "Descricao"    SIZE 40
            DEFINE CELL NAME "ZEM_LOCAL"  OF oSection ALIAS "ZEM" TITLE "Armazem"      SIZE  5
            DEFINE CELL NAME "B2_QATU"    OF oSection ALIAS "SB2" TITLE "Saldo Atual"
            DEFINE CELL NAME "ZEM_ESTMIN" OF oSection ALIAS "ZEM" TITLE "Est. Minimo"
            DEFINE CELL NAME "ZEM_ESTMAX" OF oSection ALIAS "ZEM" TITLE "Est. Maximo"
            DEFINE CELL NAME "ZEM_SITUA"  OF oSection ALIAS "ZEM" TITLE "Situacao"     SIZE 20

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
    aAdd(aRegs, {cPerg,"01","Armazem De         ","Armazem De         ","Armazem De         ","mv_ch1","C",2,0,0,"G","","mv_par01","","","","NNR"})
    aAdd(aRegs, {cPerg,"02","Armazem Ate        ","Armazem Ate        ","Armazem Ate        ","mv_ch2","C",2,0,0,"G","","mv_par02","","","","NNR"})
    aAdd(aRegs, {cPerg,"03","Status             ","Status             ","Status             ","mv_ch3","N",1,0,1,"C","","mv_par03","Todos","Ativo","Inativo",""})

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

/*/{Protheus.doc} xGeraRelEst
Executa a consulta SQL e alimenta o TReport via BEGIN REPORT QUERY.
A classificacao (ABAIXO DO MINIMO / NORMAL / ACIMA DO MAXIMO) e calculada
diretamente no SQL via CASE WHEN, evitando laco de processamento linha a linha.
@type Static Function
@param oReport Object, instancia do TReport em execucao
/*/
//=============================================================================
Static Function xGeraRelEst(oReport)
//=============================================================================
#IFDEF TOP
    Local cAlias      := GetNextAlias()
    Local cLocalDe    := Alltrim(mv_par01)
    Local cLocalAte   := Alltrim(mv_par02)
    Local nStsOpc     := mv_par03
    Local cStsWhere   := ""
    Local cExtraWhere := ""

    // Filtro de armazem: so acrescenta a clausula se o parametro foi informado.
    // Envolto em %...% para que %exp:cExtraWhere% expanda como SQL bruto,
    // nao como literal de string (comportamento padrao do BeginSql).
    If !Empty(cLocalDe)
        cExtraWhere += " AND ZEM.ZEM_LOCAL >= '" + cLocalDe + "'"
    EndIf
    If !Empty(cLocalAte)
        cExtraWhere += " AND ZEM.ZEM_LOCAL <= '" + cLocalAte + "'"
    EndIf

    Do Case
        Case nStsOpc == 2 ; cStsWhere := " AND ZEM.ZEM_STATUS = '1' "
        Case nStsOpc == 3 ; cStsWhere := " AND ZEM.ZEM_STATUS = '2' "
        Otherwise         ; cStsWhere := ""
    EndCase

    cExtraWhere := "%" + cExtraWhere + cStsWhere + "%"

    BEGIN REPORT QUERY oReport:Section(1)

    BeginSql alias cAlias
        SELECT  ZEM.ZEM_FILIAL,
                ZEM.ZEM_PROD,
                ZEM.ZEM_LOCAL,
                ZEM.ZEM_ESTMIN,
                ZEM.ZEM_ESTMAX,
                ISNULL(B1.B1_DESC, '')   AS B1_DESC,
                ISNULL(B2.B2_QATU, 0)   AS B2_QATU,
                CASE
                    WHEN ZEM.ZEM_ESTMIN > 0
                     AND ISNULL(B2.B2_QATU, 0) < ZEM.ZEM_ESTMIN
                        THEN 'ABAIXO DO MINIMO'
                    WHEN ZEM.ZEM_ESTMAX > 0
                     AND ISNULL(B2.B2_QATU, 0) > ZEM.ZEM_ESTMAX
                        THEN 'ACIMA DO MAXIMO'
                    ELSE 'NORMAL'
                END AS ZEM_SITUA
        FROM %table:ZEM% ZEM
        LEFT JOIN %table:SB1% B1
            ON  B1.D_E_L_E_T_ = ' '
            AND B1.B1_FILIAL   = %xfilial:SB1%
            AND B1.B1_COD      = ZEM.ZEM_PROD
        LEFT JOIN %table:SB2% B2
            ON  B2.D_E_L_E_T_ = ' '
            AND B2.B2_FILIAL   = %xfilial:SB2%
            AND B2.B2_COD      = ZEM.ZEM_PROD
            AND B2.B2_LOCAL    = ZEM.ZEM_LOCAL
        WHERE ZEM.%notDel%
          AND ZEM.ZEM_FILIAL   = %xfilial:ZEM%
          %exp:cExtraWhere%
        ORDER BY ZEM.ZEM_PROD, ZEM.ZEM_LOCAL
    EndSql

    END REPORT QUERY oReport:Section(1)

    oReport:Section(1):Print()
#ENDIF
Return Nil