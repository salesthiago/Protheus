#include 'protheus.ch'

/*/{Protheus.doc} BIQUSR
Consultas do BI - 10. Usuarios do sistema e licencas (USR).
Cadastro de usuarios com o ultimo acesso, modulos liberados e historico de acesso
(TOTVS_AUDIT agregado por usuario, dia e hora), para controlar as licencas.
Chamado por APIBI.PRW. Retorna {cSql, cOrdem} ou uma string com a mensagem de erro.

Tabelas de sistema (sem RetSqlName): SYS_USR, SYS_USR_MODULE e TOTVS_AUDIT.
Colunas que podem nao existir no ambiente sao detectadas (U_BIHASCOL) e voltam vazias.
USR00 lista as colunas dessas tabelas, para conferir o que o ambiente tem.

@author Thiago Sales - Quebec Ambiental
@since 2026-11-25
/*/

User Function BIQUSR(cId, oPar)

	Do Case
	Case cId == "USR00" ; Return qUSR00(oPar)
	Case cId == "USR01" ; Return qUSR01(oPar)
	Case cId == "USR02" ; Return qUSR02(oPar)
	Case cId == "USR03" ; Return qUSR03(oPar)
	EndCase

Return Nil

Static Function xQ(cVal)
Return "'" + cVal + "'"

// Expressao TRIM(<alias>.<coluna>) se a coluna existir na tabela, senao texto vazio
Static Function xCol(cTab, cAli, cCampo)
	If U_BIHASCOL(cTab, cCampo)
		Return "TRIM(" + cAli + "." + cCampo + ")"
	EndIf
Return "CAST('' AS VARCHAR(1))"

// Primeira coluna de aCand que existir na tabela ("" se nenhuma)
Static Function xPrim(cTab, aCand)
	Local nI := 0

	For nI := 1 To Len(aCand)
		If U_BIHASCOL(cTab, aCand[nI])
			Return aCand[nI]
		EndIf
	Next nI

Return ""

// USR00 - colunas das tabelas de usuario e auditoria (diagnostico)
Static Function qUSR00(oPar)
	Local cQ := ""

	cQ += "SELECT TABLE_NAME T, COLUMN_NAME C, DATA_TYPE TP, CHARACTER_MAXIMUM_LENGTH TAM "
	cQ += "FROM INFORMATION_SCHEMA.COLUMNS "
	cQ += "WHERE TABLE_NAME IN ('SYS_USR', 'SYS_USR_MODULE', 'SYS_USR_GROUPS', 'TOTVS_AUDIT')"

Return {cQ, "1, 2"}

// USR01 - usuarios (todos, inclusive bloqueados) com o ultimo registro na TOTVS_AUDIT (historico completo)
Static Function qUSR01(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(U.USR_ID) ID, TRIM(U.USR_CODIGO) LOGIN, TRIM(U.USR_NOME) NOME, TRIM(U.USR_EMAIL) EMAIL, "
	cQ += "TRIM(U.USR_MSBLQL) BLOQ, "
	cQ += xCol("SYS_USR", "U", "USR_DEPTO") + " DEPTO, "
	cQ += xCol("SYS_USR", "U", "USR_CARGO") + " CARGO, "
	cQ += "(SELECT MAX(A.ADT_DATA) FROM TOTVS_AUDIT A WHERE A.D_E_L_E_T_ = ' ' AND A.ADT_USER = U.USR_ID) ULT "
	cQ += "FROM SYS_USR U WHERE U.D_E_L_E_T_ = ' '"

Return {cQ, "U.USR_ID"}

// USR02 - modulos do usuario (SYS_USR_MODULE), uma linha por usuario x modulo.
// ACESSO: flag de acesso ao modulo, quando a coluna existe (T = liberado).
Static Function qUSR02(oPar)
	Local cQ := ""

	cQ += "SELECT TRIM(M.USR_ID) ID, TRIM(CAST(M.USR_MODULO AS VARCHAR(10))) MODULO, "
	cQ += xCol("SYS_USR_MODULE", "M", "USR_ACESSO") + " ACESSO, "
	cQ += xCol("SYS_USR_MODULE", "M", "USR_NIVEL") + " NIVEL, "
	cQ += xCol("SYS_USR_MODULE", "M", "USR_ARQMENU") + " MENU "
	cQ += "FROM SYS_USR_MODULE M WHERE M.D_E_L_E_T_ = ' '"

Return {cQ, "1, 2"}

// USR03 - historico de acesso: TOTVS_AUDIT agregado por dia, hora, usuario (e modulo, se a auditoria tiver a coluna).
// ADT_DATA = AAAAMMDDHHMMSS. N = registros de auditoria na hora; PRI/ULT = primeiro e ultimo registro.
Static Function qUSR03(oPar)
	Local cQ   := ""
	Local cMod := xPrim("TOTVS_AUDIT", {"ADT_MODULO", "ADT_MODULE", "ADT_MOD"})
	Local cExp := iif(Empty(cMod), "", "TRIM(CAST(A." + cMod + " AS VARCHAR(20)))")

	cQ += "SELECT SUBSTRING(A.ADT_DATA, 1, 8) DIA, SUBSTRING(A.ADT_DATA, 9, 2) HORA, TRIM(A.ADT_USER) ID, "
	cQ += iif(Empty(cExp), "CAST('' AS VARCHAR(1))", cExp) + " MODULO, "
	cQ += "COUNT(*) N, MIN(A.ADT_DATA) PRI, MAX(A.ADT_DATA) ULT "
	cQ += "FROM TOTVS_AUDIT A "
	cQ += "WHERE A.D_E_L_E_T_ = ' ' AND A.ADT_DATA >= " + xQ(oPar["desde"]) + " "
	cQ += "GROUP BY SUBSTRING(A.ADT_DATA, 1, 8), SUBSTRING(A.ADT_DATA, 9, 2), TRIM(A.ADT_USER)"
	cQ += iif(Empty(cExp), "", ", " + cExp)

Return {cQ, "1, 2, 3, 4"}
