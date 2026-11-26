#include 'protheus.ch'
#include 'restful.ch'

/*/{Protheus.doc} APIBI
API REST somente leitura para o BI (DRE online / paineis gerenciais).

Cada consulta do arquivo CONSULTAS-PROTHEUS.sql (escrito para Oracle) virou um
endpoint GET, reescrito para SQL Server. Sao 92 endpoints; GET /bi lista todos
com os parametros aceitos.

ARQUIVOS
  APIBI.PRW   -> servico REST, catalogo, validacao de parametros e execucao
  BIQFIN.PRW  -> financeiro (FIN) e fila de aprovacao (APR)
  BIQCOM.PRW  -> pedidos de compra (PED) e compras (COM)
  BIQRH.PRW   -> folha (FOL), RH (RHU) e medicina do trabalho (MED)
  BIQMNT.PRW  -> manutencao de frota (MNT)
  BIQEST.PRW  -> suprimentos/almoxarifado (EST) e EPI (EPI)
  BIQUSR.PRW  -> usuarios do sistema, modulos e historico de acesso (USR)

PARAMETROS (querystring)
  Tipos: D = data AAAAMMDD | M = competencia AAAAMM | T = data-hora
         AAAA-MM-DDTHH:MM:SS (aceita Z no fim, ou so AAAAMMDD) |
         L = lista de codigos separada por virgula | R = lista de R_E_C_N_O_
  Parametro nao informado assume o padrao do catalogo (HOJE, INIMES = dia 1
  do mes, MESATU = mes atual, -12M = 12 meses atras, ULTSRD = ultima
  competencia fechada na SRD, ou uma data fixa).
  Paginacao opcional: page (1..n) e pageSize (1..50000). Sem pageSize a
  consulta devolve todas as linhas.

RESPOSTA
  { "consulta", "path", "parametros", "page", "pageSize", "count", "hasNext", "items": [ ... ] }

OBSERVACOES
  - Somente SELECT; nenhuma rotina grava no banco.
  - Requer SQL Server 2017+ (TRIM, STRING_AGG, OFFSET/FETCH, TRY_CONVERT).
  - Nomes de tabela via RetSqlName(), entao funciona em qualquer empresa.
  - Nome de coluna em query TOPCONN tem no maximo 10 caracteres; os aliases
    longos do arquivo original sao encurtados no SQL e devolvidos com o nome
    original no JSON (ver xNomeCol).
  - Path params nao sao usados (instaveis neste build, ver RESTZEM.PRW).

@author Thiago Sales - Quebec Ambiental
@since 2026-11-11
/*/
//=============================================================================

#define BI_MAXPAG 50000

Static oColCache := Nil

WSRESTFUL APIBI DESCRIPTION "API BI - consultas somente leitura do Protheus" FORMAT APPLICATION_JSON

	WSDATA desde    AS STRING OPTIONAL
	WSDATA de       AS STRING OPTIONAL
	WSDATA ate      AS STRING OPTIONAL
	WSDATA hoje     AS STRING OPTIONAL
	WSDATA ultima   AS STRING OPTIONAL
	WSDATA dia      AS STRING OPTIONAL
	WSDATA mes      AS STRING OPTIONAL
	WSDATA lista    AS STRING OPTIONAL
	WSDATA recs     AS STRING OPTIONAL
	WSDATA vbruto   AS STRING OPTIONAL
	WSDATA vencargo AS STRING OPTIONAL
	WSDATA vextra   AS STRING OPTIONAL
	WSDATA vatest   AS STRING OPTIONAL
	WSDATA vfalta   AS STRING OPTIONAL
	WSDATA escopo   AS STRING OPTIONAL
	WSDATA page     AS STRING OPTIONAL
	WSDATA pageSize AS STRING OPTIONAL

	WSMETHOD GET CATALOGO DESCRIPTION "Lista as consultas disponiveis e seus parametros" ;
		WSSYNTAX "/bi" PATH "/bi" PRODUCES APPLICATION_JSON

	WSMETHOD GET FIN01 DESCRIPTION "Titulos a pagar em aberto com pedido de compra de contrato e/ou OS" ;
		WSSYNTAX "/bi/financeiro/titulos-abertos" PATH "/bi/financeiro/titulos-abertos" PRODUCES APPLICATION_JSON

	WSMETHOD GET FIN02 DESCRIPTION "Baixas no periodo de titulos com pedido de compra de contrato e/ou OS" ;
		WSSYNTAX "/bi/financeiro/pagamentos" PATH "/bi/financeiro/pagamentos" PRODUCES APPLICATION_JSON

	WSMETHOD GET FIN03 DESCRIPTION "Rateio por centro de custo dos titulos informados (R_E_C_N_O_ da SE2)" ;
		WSSYNTAX "/bi/financeiro/rateio-cc" PATH "/bi/financeiro/rateio-cc" PRODUCES APPLICATION_JSON

	WSMETHOD GET FIN04 DESCRIPTION "Centros de custo (CTT) agrupados pelo codigo" ;
		WSSYNTAX "/bi/financeiro/centros-custo" PATH "/bi/financeiro/centros-custo" PRODUCES APPLICATION_JSON

	WSMETHOD GET FIN05 DESCRIPTION "Faturamento mensal por filial (vendas com duplicata e devolucoes) para a DRE" ;
		WSSYNTAX "/bi/financeiro/faturamento" PATH "/bi/financeiro/faturamento" PRODUCES APPLICATION_JSON

	WSMETHOD GET FIN06 DESCRIPTION "Filiais do grupo de empresas com o nome" ;
		WSSYNTAX "/bi/geral/filiais" PATH "/bi/geral/filiais" PRODUCES APPLICATION_JSON

	WSMETHOD GET APR01 DESCRIPTION "Pendencias de alcada (SCR status 02) com item bloqueado na SC7, papel na SAL e limites" ;
		WSSYNTAX "/bi/aprovacao/pendencias" PATH "/bi/aprovacao/pendencias" PRODUCES APPLICATION_JSON

	WSMETHOD GET APR02 DESCRIPTION "Itens dos pedidos pendentes de aprovacao" ;
		WSSYNTAX "/bi/aprovacao/itens" PATH "/bi/aprovacao/itens" PRODUCES APPLICATION_JSON

	WSMETHOD GET APR03 DESCRIPTION "Cotacoes (SC8) dos itens pendentes de aprovacao" ;
		WSSYNTAX "/bi/aprovacao/cotacoes" PATH "/bi/aprovacao/cotacoes" PRODUCES APPLICATION_JSON

	WSMETHOD GET PED01 DESCRIPTION "Deteccao das colunas opcionais de pedidos/notas/alcada" ;
		WSSYNTAX "/bi/pedidos/colunas" PATH "/bi/pedidos/colunas" PRODUCES APPLICATION_JSON

	WSMETHOD GET PED02 DESCRIPTION "Itens de pedido de compra, todos os status (inclui excluidos)" ;
		WSSYNTAX "/bi/pedidos/itens" PATH "/bi/pedidos/itens" PRODUCES APPLICATION_JSON

	WSMETHOD GET PED03 DESCRIPTION "Alcadas de aprovacao (SCR) de pedidos" ;
		WSSYNTAX "/bi/pedidos/alcadas" PATH "/bi/pedidos/alcadas" PRODUCES APPLICATION_JSON

	WSMETHOD GET PED04 DESCRIPTION "Notas de entrada (SD1) vinculadas a pedido" ;
		WSSYNTAX "/bi/pedidos/notas" PATH "/bi/pedidos/notas" PRODUCES APPLICATION_JSON

	WSMETHOD GET PED05 DESCRIPTION "Solicitacoes de compra (SC1) vinculadas a pedido" ;
		WSSYNTAX "/bi/pedidos/solicitacoes" PATH "/bi/pedidos/solicitacoes" PRODUCES APPLICATION_JSON

	WSMETHOD GET PED06 DESCRIPTION "Chaves FILIAL|PEDIDO alteradas desde o ultimo recorte" ;
		WSSYNTAX "/bi/pedidos/alterados" PATH "/bi/pedidos/alterados" PRODUCES APPLICATION_JSON

	WSMETHOD GET COM01 DESCRIPTION "Deteccao de tabelas opcionais (SY1)" ;
		WSSYNTAX "/bi/compras/tabelas" PATH "/bi/compras/tabelas" PRODUCES APPLICATION_JSON

	WSMETHOD GET COM02 DESCRIPTION "Deteccao de colunas opcionais da SC1" ;
		WSSYNTAX "/bi/compras/colunas-sc1" PATH "/bi/compras/colunas-sc1" PRODUCES APPLICATION_JSON

	WSMETHOD GET COM03 DESCRIPTION "Solicitacoes de compra (SC1)" ;
		WSSYNTAX "/bi/compras/solicitacoes" PATH "/bi/compras/solicitacoes" PRODUCES APPLICATION_JSON

	WSMETHOD GET COM04 DESCRIPTION "Cotacoes (SC8)" ;
		WSSYNTAX "/bi/compras/cotacoes" PATH "/bi/compras/cotacoes" PRODUCES APPLICATION_JSON

	WSMETHOD GET COM05 DESCRIPTION "Custo medio dos itens (SB2)" ;
		WSSYNTAX "/bi/compras/custos" PATH "/bi/compras/custos" PRODUCES APPLICATION_JSON

	WSMETHOD GET COM06 DESCRIPTION "Notas de entrada (SD1) agrupadas por documento" ;
		WSSYNTAX "/bi/compras/notas-entrada" PATH "/bi/compras/notas-entrada" PRODUCES APPLICATION_JSON

	WSMETHOD GET FOL01 DESCRIPTION "Folha fechada (SRD) por competencia/roteiro/CC/verba" ;
		WSSYNTAX "/bi/folha/lancamentos" PATH "/bi/folha/lancamentos" PRODUCES APPLICATION_JSON

	WSMETHOD GET FOL02 DESCRIPTION "Previa da folha em calculo (SRC) por competencia/roteiro/CC/verba" ;
		WSSYNTAX "/bi/folha/lancamentos-previa" PATH "/bi/folha/lancamentos-previa" PRODUCES APPLICATION_JSON

	WSMETHOD GET FOL03 DESCRIPTION "Pessoas distintas por competencia (SRD)" ;
		WSSYNTAX "/bi/folha/pessoas-competencia" PATH "/bi/folha/pessoas-competencia" PRODUCES APPLICATION_JSON

	WSMETHOD GET FOL04 DESCRIPTION "Pessoas distintas por competencia (SRC)" ;
		WSSYNTAX "/bi/folha/pessoas-competencia-previa" PATH "/bi/folha/pessoas-competencia-previa" PRODUCES APPLICATION_JSON

	WSMETHOD GET FOL05 DESCRIPTION "Pessoas distintas por competencia e CC (SRD)" ;
		WSSYNTAX "/bi/folha/pessoas-cc" PATH "/bi/folha/pessoas-cc" PRODUCES APPLICATION_JSON

	WSMETHOD GET FOL06 DESCRIPTION "Pessoas distintas por competencia e CC (SRC)" ;
		WSSYNTAX "/bi/folha/pessoas-cc-previa" PATH "/bi/folha/pessoas-cc-previa" PRODUCES APPLICATION_JSON

	WSMETHOD GET FOL07 DESCRIPTION "Cadastro de verbas (SRV)" ;
		WSSYNTAX "/bi/folha/verbas" PATH "/bi/folha/verbas" PRODUCES APPLICATION_JSON

	WSMETHOD GET FOL08 DESCRIPTION "Quadro atual por CC e situacao (SRA)" ;
		WSSYNTAX "/bi/folha/quadro" PATH "/bi/folha/quadro" PRODUCES APPLICATION_JSON

	WSMETHOD GET FOL09 DESCRIPTION "Admissoes e demissoes por mes e CC" ;
		WSSYNTAX "/bi/folha/admissoes-demissoes" PATH "/bi/folha/admissoes-demissoes" PRODUCES APPLICATION_JSON

	WSMETHOD GET RHU01 DESCRIPTION "Funcionarios ativos (SRA) sem dados pessoais" ;
		WSSYNTAX "/bi/rh/pessoas-ativas" PATH "/bi/rh/pessoas-ativas" PRODUCES APPLICATION_JSON

	WSMETHOD GET RHU02 DESCRIPTION "Ultima competencia fechada (SRD)" ;
		WSSYNTAX "/bi/rh/ultima-competencia" PATH "/bi/rh/ultima-competencia" PRODUCES APPLICATION_JSON

	WSMETHOD GET RHU03 DESCRIPTION "Cadastro de verbas (SRV) - colunas DESCR/IDFOL" ;
		WSSYNTAX "/bi/rh/verbas" PATH "/bi/rh/verbas" PRODUCES APPLICATION_JSON

	WSMETHOD GET RHU04 DESCRIPTION "Matriculas com folha no periodo" ;
		WSSYNTAX "/bi/rh/matriculas-periodo" PATH "/bi/rh/matriculas-periodo" PRODUCES APPLICATION_JSON

	WSMETHOD GET RHU05 DESCRIPTION "Valor por matricula das verbas informadas no periodo" ;
		WSSYNTAX "/bi/rh/valor-verbas" PATH "/bi/rh/valor-verbas" PRODUCES APPLICATION_JSON

	WSMETHOD GET RHU06 DESCRIPTION "Periodos aquisitivos de ferias vencidos (SRF)" ;
		WSSYNTAX "/bi/rh/ferias-vencidas" PATH "/bi/rh/ferias-vencidas" PRODUCES APPLICATION_JSON

	WSMETHOD GET RHU07 DESCRIPTION "Dias de ferias gozados por periodo aquisitivo (SRH)" ;
		WSSYNTAX "/bi/rh/ferias-gozadas" PATH "/bi/rh/ferias-gozadas" PRODUCES APPLICATION_JSON

	WSMETHOD GET RHU08 DESCRIPTION "Afastamentos em aberto (SR8)" ;
		WSSYNTAX "/bi/rh/afastamentos" PATH "/bi/rh/afastamentos" PRODUCES APPLICATION_JSON

	WSMETHOD GET RHU09 DESCRIPTION "Hora extra por matricula/competencia (verbas informadas)" ;
		WSSYNTAX "/bi/rh/hora-extra" PATH "/bi/rh/hora-extra" PRODUCES APPLICATION_JSON

	WSMETHOD GET MED01 DESCRIPTION "Atestados medicos (TNY)" ;
		WSSYNTAX "/bi/medicina/atestados" PATH "/bi/medicina/atestados" PRODUCES APPLICATION_JSON

	WSMETHOD GET MED02 DESCRIPTION "Custo por pessoa/competencia (bruto, encargo, extra, atestado, falta)" ;
		WSSYNTAX "/bi/medicina/custo-pessoa" PATH "/bi/medicina/custo-pessoa" PRODUCES APPLICATION_JSON

	WSMETHOD GET MED03 DESCRIPTION "Ferias iniciadas no periodo (SRH)" ;
		WSSYNTAX "/bi/medicina/ferias" PATH "/bi/medicina/ferias" PRODUCES APPLICATION_JSON

	WSMETHOD GET MED04 DESCRIPTION "Pessoas ativas ou demitidas no periodo" ;
		WSSYNTAX "/bi/medicina/pessoas" PATH "/bi/medicina/pessoas" PRODUCES APPLICATION_JSON

	WSMETHOD GET MED05 DESCRIPTION "Rescisoes (SRR) no periodo" ;
		WSSYNTAX "/bi/medicina/rescisoes" PATH "/bi/medicina/rescisoes" PRODUCES APPLICATION_JSON

	WSMETHOD GET MED06 DESCRIPTION "Acidentes de trabalho / CAT (TNC)" ;
		WSSYNTAX "/bi/medicina/acidentes" PATH "/bi/medicina/acidentes" PRODUCES APPLICATION_JSON

	WSMETHOD GET MNT01 DESCRIPTION "Bens / veiculos (ST9)" ;
		WSSYNTAX "/bi/frota/bens" PATH "/bi/frota/bens" PRODUCES APPLICATION_JSON

	WSMETHOD GET MNT02 DESCRIPTION "Ordens de servico (STJ) com custos" ;
		WSSYNTAX "/bi/frota/ordens" PATH "/bi/frota/ordens" PRODUCES APPLICATION_JSON

	WSMETHOD GET MNT03 DESCRIPTION "Insumos das OS por grupo de produto" ;
		WSSYNTAX "/bi/frota/insumos" PATH "/bi/frota/insumos" PRODUCES APPLICATION_JSON

	WSMETHOD GET MNT04 DESCRIPTION "Compras dos CC de frota" ;
		WSSYNTAX "/bi/frota/compras-cc" PATH "/bi/frota/compras-cc" PRODUCES APPLICATION_JSON

	WSMETHOD GET MNT05 DESCRIPTION "Combustivel comprado (SD1)" ;
		WSSYNTAX "/bi/frota/combustivel-nf" PATH "/bi/frota/combustivel-nf" PRODUCES APPLICATION_JSON

	WSMETHOD GET MNT06 DESCRIPTION "Combustivel requisitado do estoque (SD3)" ;
		WSSYNTAX "/bi/frota/combustivel-requisicao" PATH "/bi/frota/combustivel-requisicao" PRODUCES APPLICATION_JSON

	WSMETHOD GET MNT07 DESCRIPTION "Leituras de hodometro (STP) por mes" ;
		WSSYNTAX "/bi/frota/hodometro" PATH "/bi/frota/hodometro" PRODUCES APPLICATION_JSON

	WSMETHOD GET MNT08 DESCRIPTION "Pecas aplicadas nas OS" ;
		WSSYNTAX "/bi/frota/pecas" PATH "/bi/frota/pecas" PRODUCES APPLICATION_JSON

	WSMETHOD GET MNT09 DESCRIPTION "Precos de referencia de pecas (SD1)" ;
		WSSYNTAX "/bi/frota/precos" PATH "/bi/frota/precos" PRODUCES APPLICATION_JSON

	WSMETHOD GET MNT10 DESCRIPTION "Abastecimentos por bem (TQN)" ;
		WSSYNTAX "/bi/frota/abastecimentos" PATH "/bi/frota/abastecimentos" PRODUCES APPLICATION_JSON

	WSMETHOD GET EST01 DESCRIPTION "Produtos com movimento interno (SB1 x SD3)" ;
		WSSYNTAX "/bi/estoque/produtos-movimentados" PATH "/bi/estoque/produtos-movimentados" PRODUCES APPLICATION_JSON

	WSMETHOD GET EST02 DESCRIPTION "Centros de custo (CTT)" ;
		WSSYNTAX "/bi/estoque/centros-custo" PATH "/bi/estoque/centros-custo" PRODUCES APPLICATION_JSON

	WSMETHOD GET EST03 DESCRIPTION "Tipos de movimento (SF5)" ;
		WSSYNTAX "/bi/estoque/tipos-movimento" PATH "/bi/estoque/tipos-movimento" PRODUCES APPLICATION_JSON

	WSMETHOD GET EST04 DESCRIPTION "Precos unitarios de entrada (SD1)" ;
		WSSYNTAX "/bi/estoque/precos-entrada" PATH "/bi/estoque/precos-entrada" PRODUCES APPLICATION_JSON

	WSMETHOD GET EST05 DESCRIPTION "Meses com movimento interno valido (SD3)" ;
		WSSYNTAX "/bi/estoque/meses-movimento" PATH "/bi/estoque/meses-movimento" PRODUCES APPLICATION_JSON

	WSMETHOD GET EST06 DESCRIPTION "Movimentos internos (SD3) do mes" ;
		WSSYNTAX "/bi/estoque/movimentos" PATH "/bi/estoque/movimentos" PRODUCES APPLICATION_JSON

	WSMETHOD GET EST07 DESCRIPTION "Saldos de estoque (SB2) com ultima entrada/saida" ;
		WSSYNTAX "/bi/estoque/saldos" PATH "/bi/estoque/saldos" PRODUCES APPLICATION_JSON

	WSMETHOD GET EST08 DESCRIPTION "Fechamentos mensais (SB9)" ;
		WSSYNTAX "/bi/estoque/fechamentos" PATH "/bi/estoque/fechamentos" PRODUCES APPLICATION_JSON

	WSMETHOD GET EST09 DESCRIPTION "Produtos com solicitacao ao armazem (SB1 x SCP)" ;
		WSSYNTAX "/bi/estoque/produtos-solicitados" PATH "/bi/estoque/produtos-solicitados" PRODUCES APPLICATION_JSON

	WSMETHOD GET EST10 DESCRIPTION "Primeiro/ultimo atendimento das solicitacoes ao armazem" ;
		WSSYNTAX "/bi/estoque/atendimento-sa" PATH "/bi/estoque/atendimento-sa" PRODUCES APPLICATION_JSON

	WSMETHOD GET EST11 DESCRIPTION "Meses com solicitacao ao armazem (SCP)" ;
		WSSYNTAX "/bi/estoque/meses-solicitacao" PATH "/bi/estoque/meses-solicitacao" PRODUCES APPLICATION_JSON

	WSMETHOD GET EST12 DESCRIPTION "Solicitacoes ao armazem (SCP) do mes" ;
		WSSYNTAX "/bi/estoque/solicitacoes" PATH "/bi/estoque/solicitacoes" PRODUCES APPLICATION_JSON

	WSMETHOD GET EST13 DESCRIPTION "Prazo solicitacao x pedido x entrada" ;
		WSSYNTAX "/bi/estoque/prazo-atendimento" PATH "/bi/estoque/prazo-atendimento" PRODUCES APPLICATION_JSON

	WSMETHOD GET EST14 DESCRIPTION "Entradas por nota que movimentam estoque (SD1)" ;
		WSSYNTAX "/bi/estoque/entradas-nf" PATH "/bi/estoque/entradas-nf" PRODUCES APPLICATION_JSON

	WSMETHOD GET EST15 DESCRIPTION "Saidas por nota que movimentam estoque (SD2)" ;
		WSSYNTAX "/bi/estoque/saidas-nf" PATH "/bi/estoque/saidas-nf" PRODUCES APPLICATION_JSON

	WSMETHOD GET EST16 DESCRIPTION "Produtos com saldo cadastrado (SB1 x SB2)" ;
		WSSYNTAX "/bi/estoque/produtos-saldo" PATH "/bi/estoque/produtos-saldo" PRODUCES APPLICATION_JSON

	WSMETHOD GET EST17 DESCRIPTION "Saldo atual por produto|armazem (SB2)" ;
		WSSYNTAX "/bi/estoque/saldo-atual" PATH "/bi/estoque/saldo-atual" PRODUCES APPLICATION_JSON

	WSMETHOD GET EST18 DESCRIPTION "Meses com movimento interno (SD3, sem filtro de estorno)" ;
		WSSYNTAX "/bi/estoque/meses-sd3" PATH "/bi/estoque/meses-sd3" PRODUCES APPLICATION_JSON

	WSMETHOD GET EST19 DESCRIPTION "Movimentos internos do mes para saldo negativo" ;
		WSSYNTAX "/bi/estoque/movimentos-saldo" PATH "/bi/estoque/movimentos-saldo" PRODUCES APPLICATION_JSON

	WSMETHOD GET EST20 DESCRIPTION "Contagens de inventario (SB7)" ;
		WSSYNTAX "/bi/estoque/inventarios" PATH "/bi/estoque/inventarios" PRODUCES APPLICATION_JSON

	WSMETHOD GET EST21 DESCRIPTION "Ajustes de inventario gerados (SD3 doc INVENT)" ;
		WSSYNTAX "/bi/estoque/inventario-ajustes-sd3" PATH "/bi/estoque/inventario-ajustes-sd3" PRODUCES APPLICATION_JSON

	WSMETHOD GET EST22 DESCRIPTION "Ajustes manuais de estoque" ;
		WSSYNTAX "/bi/estoque/ajustes" PATH "/bi/estoque/ajustes" PRODUCES APPLICATION_JSON

	WSMETHOD GET EST23 DESCRIPTION "Entradas e saidas por dia/produto/armazem" ;
		WSSYNTAX "/bi/estoque/movimento-dia" PATH "/bi/estoque/movimento-dia" PRODUCES APPLICATION_JSON

	WSMETHOD GET EPI01 DESCRIPTION "Validade do CA por EPI/fornecedor (TN3)" ;
		WSSYNTAX "/bi/epi/validade-ca" PATH "/bi/epi/validade-ca" PRODUCES APPLICATION_JSON

	WSMETHOD GET EPI02 DESCRIPTION "Meses com entrega de EPI (TNF)" ;
		WSSYNTAX "/bi/epi/meses-entrega" PATH "/bi/epi/meses-entrega" PRODUCES APPLICATION_JSON

	WSMETHOD GET EPI03 DESCRIPTION "Entregas de EPI do mes (TNF)" ;
		WSSYNTAX "/bi/epi/entregas" PATH "/bi/epi/entregas" PRODUCES APPLICATION_JSON

	WSMETHOD GET EPI04 DESCRIPTION "Funcionarios com funcao (SRA x SRJ)" ;
		WSSYNTAX "/bi/epi/pessoas" PATH "/bi/epi/pessoas" PRODUCES APPLICATION_JSON

	WSMETHOD GET EPI05 DESCRIPTION "Produtos usados como EPI" ;
		WSSYNTAX "/bi/epi/itens" PATH "/bi/epi/itens" PRODUCES APPLICATION_JSON

	WSMETHOD GET EPI06 DESCRIPTION "EPI generico x filho (TL0)" ;
		WSSYNTAX "/bi/epi/genericos" PATH "/bi/epi/genericos" PRODUCES APPLICATION_JSON

	WSMETHOD GET EPI07 DESCRIPTION "Durabilidade por EPI (TN3)" ;
		WSSYNTAX "/bi/epi/durabilidade" PATH "/bi/epi/durabilidade" PRODUCES APPLICATION_JSON

	WSMETHOD GET EPI08 DESCRIPTION "EPI por funcao (TNB)" ;
		WSSYNTAX "/bi/epi/por-funcao" PATH "/bi/epi/por-funcao" PRODUCES APPLICATION_JSON

	WSMETHOD GET CTR01 DESCRIPTION "Contratos de compra (CN9), uma linha por revisao" ;
		WSSYNTAX "/bi/contratos/contratos" PATH "/bi/contratos/contratos" PRODUCES APPLICATION_JSON

	WSMETHOD GET CTR02 DESCRIPTION "Itens das medicoes (CNE) de contratos de compra" ;
		WSSYNTAX "/bi/contratos/medicoes" PATH "/bi/contratos/medicoes" PRODUCES APPLICATION_JSON

	WSMETHOD GET USR00 DESCRIPTION "Colunas das tabelas de usuario e auditoria (diagnostico)" ;
		WSSYNTAX "/bi/usuarios/colunas" PATH "/bi/usuarios/colunas" PRODUCES APPLICATION_JSON

	WSMETHOD GET USR01 DESCRIPTION "Usuarios (SYS_USR) com o ultimo acesso" ;
		WSSYNTAX "/bi/usuarios/cadastro" PATH "/bi/usuarios/cadastro" PRODUCES APPLICATION_JSON

	WSMETHOD GET USR02 DESCRIPTION "Modulos dos usuarios (SYS_USR_MODULE)" ;
		WSSYNTAX "/bi/usuarios/modulos" PATH "/bi/usuarios/modulos" PRODUCES APPLICATION_JSON

	WSMETHOD GET USR03 DESCRIPTION "Historico de acesso (TOTVS_AUDIT) por usuario, dia e hora" ;
		WSSYNTAX "/bi/usuarios/acessos" PATH "/bi/usuarios/acessos" PRODUCES APPLICATION_JSON

END WSRESTFUL

//-----------------------------------------------------------------------------
// GET /bi - catalogo
//-----------------------------------------------------------------------------
WSMETHOD GET CATALOGO WSSERVICE APIBI
	Local aCat  := xCatalogo()
	Local aLst  := {}
	Local aPar  := {}
	Local aDef  := {}
	Local oItem := Nil
	Local oPar  := Nil
	Local oResp := JsonObject():New()
	Local nI    := 0
	Local nJ    := 0

	::SetContentType("application/json")

	For nI := 1 To Len(aCat)
		oItem := JsonObject():New()
		oItem["id"]        := aCat[nI][1]
		oItem["path"]      := aCat[nI][2]
		oItem["descricao"] := aCat[nI][3]
		aPar := {}
		aDef := xSpec(aCat[nI][4])
		For nJ := 1 To Len(aDef)
			oPar := JsonObject():New()
			oPar["nome"]        := aDef[nJ][1]
			oPar["tipo"]        := aDef[nJ][2]
			oPar["obrigatorio"] := (aDef[nJ][3] == "!")
			oPar["padrao"]      := iif(aDef[nJ][3] == "!", "", aDef[nJ][3])
			aAdd(aPar, oPar)
		Next nJ
		oItem["parametros"] := aPar
		aAdd(aLst, oItem)
	Next nI

	oResp["count"] := Len(aLst)
	oResp["items"] := aLst
	::SetResponse(oResp:ToJson())

Return .T.

//-----------------------------------------------------------------------------
// Um metodo por consulta; todos delegam para xRun()
//-----------------------------------------------------------------------------
WSMETHOD GET FIN01 WSSERVICE APIBI
Return xRun(Self, "FIN01")

WSMETHOD GET FIN02 WSSERVICE APIBI
Return xRun(Self, "FIN02")

WSMETHOD GET FIN03 WSSERVICE APIBI
Return xRun(Self, "FIN03")

WSMETHOD GET FIN04 WSSERVICE APIBI
Return xRun(Self, "FIN04")

WSMETHOD GET FIN05 WSSERVICE APIBI
Return xRun(Self, "FIN05")

WSMETHOD GET FIN06 WSSERVICE APIBI
Return xRun(Self, "FIN06")

WSMETHOD GET APR01 WSSERVICE APIBI
Return xRun(Self, "APR01")

WSMETHOD GET APR02 WSSERVICE APIBI
Return xRun(Self, "APR02")

WSMETHOD GET APR03 WSSERVICE APIBI
Return xRun(Self, "APR03")

WSMETHOD GET PED01 WSSERVICE APIBI
Return xRun(Self, "PED01")

WSMETHOD GET PED02 WSSERVICE APIBI
Return xRun(Self, "PED02")

WSMETHOD GET PED03 WSSERVICE APIBI
Return xRun(Self, "PED03")

WSMETHOD GET PED04 WSSERVICE APIBI
Return xRun(Self, "PED04")

WSMETHOD GET PED05 WSSERVICE APIBI
Return xRun(Self, "PED05")

WSMETHOD GET PED06 WSSERVICE APIBI
Return xRun(Self, "PED06")

WSMETHOD GET COM01 WSSERVICE APIBI
Return xRun(Self, "COM01")

WSMETHOD GET COM02 WSSERVICE APIBI
Return xRun(Self, "COM02")

WSMETHOD GET COM03 WSSERVICE APIBI
Return xRun(Self, "COM03")

WSMETHOD GET COM04 WSSERVICE APIBI
Return xRun(Self, "COM04")

WSMETHOD GET COM05 WSSERVICE APIBI
Return xRun(Self, "COM05")

WSMETHOD GET COM06 WSSERVICE APIBI
Return xRun(Self, "COM06")

WSMETHOD GET FOL01 WSSERVICE APIBI
Return xRun(Self, "FOL01")

WSMETHOD GET FOL02 WSSERVICE APIBI
Return xRun(Self, "FOL02")

WSMETHOD GET FOL03 WSSERVICE APIBI
Return xRun(Self, "FOL03")

WSMETHOD GET FOL04 WSSERVICE APIBI
Return xRun(Self, "FOL04")

WSMETHOD GET FOL05 WSSERVICE APIBI
Return xRun(Self, "FOL05")

WSMETHOD GET FOL06 WSSERVICE APIBI
Return xRun(Self, "FOL06")

WSMETHOD GET FOL07 WSSERVICE APIBI
Return xRun(Self, "FOL07")

WSMETHOD GET FOL08 WSSERVICE APIBI
Return xRun(Self, "FOL08")

WSMETHOD GET FOL09 WSSERVICE APIBI
Return xRun(Self, "FOL09")

WSMETHOD GET RHU01 WSSERVICE APIBI
Return xRun(Self, "RHU01")

WSMETHOD GET RHU02 WSSERVICE APIBI
Return xRun(Self, "RHU02")

WSMETHOD GET RHU03 WSSERVICE APIBI
Return xRun(Self, "RHU03")

WSMETHOD GET RHU04 WSSERVICE APIBI
Return xRun(Self, "RHU04")

WSMETHOD GET RHU05 WSSERVICE APIBI
Return xRun(Self, "RHU05")

WSMETHOD GET RHU06 WSSERVICE APIBI
Return xRun(Self, "RHU06")

WSMETHOD GET RHU07 WSSERVICE APIBI
Return xRun(Self, "RHU07")

WSMETHOD GET RHU08 WSSERVICE APIBI
Return xRun(Self, "RHU08")

WSMETHOD GET RHU09 WSSERVICE APIBI
Return xRun(Self, "RHU09")

WSMETHOD GET MED01 WSSERVICE APIBI
Return xRun(Self, "MED01")

WSMETHOD GET MED02 WSSERVICE APIBI
Return xRun(Self, "MED02")

WSMETHOD GET MED03 WSSERVICE APIBI
Return xRun(Self, "MED03")

WSMETHOD GET MED04 WSSERVICE APIBI
Return xRun(Self, "MED04")

WSMETHOD GET MED05 WSSERVICE APIBI
Return xRun(Self, "MED05")

WSMETHOD GET MED06 WSSERVICE APIBI
Return xRun(Self, "MED06")

WSMETHOD GET MNT01 WSSERVICE APIBI
Return xRun(Self, "MNT01")

WSMETHOD GET MNT02 WSSERVICE APIBI
Return xRun(Self, "MNT02")

WSMETHOD GET MNT03 WSSERVICE APIBI
Return xRun(Self, "MNT03")

WSMETHOD GET MNT04 WSSERVICE APIBI
Return xRun(Self, "MNT04")

WSMETHOD GET MNT05 WSSERVICE APIBI
Return xRun(Self, "MNT05")

WSMETHOD GET MNT06 WSSERVICE APIBI
Return xRun(Self, "MNT06")

WSMETHOD GET MNT07 WSSERVICE APIBI
Return xRun(Self, "MNT07")

WSMETHOD GET MNT08 WSSERVICE APIBI
Return xRun(Self, "MNT08")

WSMETHOD GET MNT09 WSSERVICE APIBI
Return xRun(Self, "MNT09")

WSMETHOD GET MNT10 WSSERVICE APIBI
Return xRun(Self, "MNT10")

WSMETHOD GET EST01 WSSERVICE APIBI
Return xRun(Self, "EST01")

WSMETHOD GET EST02 WSSERVICE APIBI
Return xRun(Self, "EST02")

WSMETHOD GET EST03 WSSERVICE APIBI
Return xRun(Self, "EST03")

WSMETHOD GET EST04 WSSERVICE APIBI
Return xRun(Self, "EST04")

WSMETHOD GET EST05 WSSERVICE APIBI
Return xRun(Self, "EST05")

WSMETHOD GET EST06 WSSERVICE APIBI
Return xRun(Self, "EST06")

WSMETHOD GET EST07 WSSERVICE APIBI
Return xRun(Self, "EST07")

WSMETHOD GET EST08 WSSERVICE APIBI
Return xRun(Self, "EST08")

WSMETHOD GET EST09 WSSERVICE APIBI
Return xRun(Self, "EST09")

WSMETHOD GET EST10 WSSERVICE APIBI
Return xRun(Self, "EST10")

WSMETHOD GET EST11 WSSERVICE APIBI
Return xRun(Self, "EST11")

WSMETHOD GET EST12 WSSERVICE APIBI
Return xRun(Self, "EST12")

WSMETHOD GET EST13 WSSERVICE APIBI
Return xRun(Self, "EST13")

WSMETHOD GET EST14 WSSERVICE APIBI
Return xRun(Self, "EST14")

WSMETHOD GET EST15 WSSERVICE APIBI
Return xRun(Self, "EST15")

WSMETHOD GET EST16 WSSERVICE APIBI
Return xRun(Self, "EST16")

WSMETHOD GET EST17 WSSERVICE APIBI
Return xRun(Self, "EST17")

WSMETHOD GET EST18 WSSERVICE APIBI
Return xRun(Self, "EST18")

WSMETHOD GET EST19 WSSERVICE APIBI
Return xRun(Self, "EST19")

WSMETHOD GET EST20 WSSERVICE APIBI
Return xRun(Self, "EST20")

WSMETHOD GET EST21 WSSERVICE APIBI
Return xRun(Self, "EST21")

WSMETHOD GET EST22 WSSERVICE APIBI
Return xRun(Self, "EST22")

WSMETHOD GET EST23 WSSERVICE APIBI
Return xRun(Self, "EST23")

WSMETHOD GET EPI01 WSSERVICE APIBI
Return xRun(Self, "EPI01")

WSMETHOD GET EPI02 WSSERVICE APIBI
Return xRun(Self, "EPI02")

WSMETHOD GET EPI03 WSSERVICE APIBI
Return xRun(Self, "EPI03")

WSMETHOD GET EPI04 WSSERVICE APIBI
Return xRun(Self, "EPI04")

WSMETHOD GET EPI05 WSSERVICE APIBI
Return xRun(Self, "EPI05")

WSMETHOD GET EPI06 WSSERVICE APIBI
Return xRun(Self, "EPI06")

WSMETHOD GET EPI07 WSSERVICE APIBI
Return xRun(Self, "EPI07")

WSMETHOD GET EPI08 WSSERVICE APIBI
Return xRun(Self, "EPI08")

WSMETHOD GET CTR01 WSSERVICE APIBI
Return xRun(Self, "CTR01")

WSMETHOD GET CTR02 WSSERVICE APIBI
Return xRun(Self, "CTR02")

WSMETHOD GET USR00 WSSERVICE APIBI
Return xRun(Self, "USR00")

WSMETHOD GET USR01 WSSERVICE APIBI
Return xRun(Self, "USR01")

WSMETHOD GET USR02 WSSERVICE APIBI
Return xRun(Self, "USR02")

WSMETHOD GET USR03 WSSERVICE APIBI
Return xRun(Self, "USR03")

//-----------------------------------------------------------------------------
// Catalogo: { id, path, descricao, parametros }
// parametros = "nome:tipo:padrao;..." (padrao "!" = obrigatorio, "" = opcional)
//-----------------------------------------------------------------------------
Static Function xCatalogo()
	Local aCat := {}

	aAdd(aCat, {"FIN01", "/bi/financeiro/titulos-abertos", "Titulos a pagar em aberto com pedido de compra de contrato e/ou OS", "escopo:E:CONTRATO_OS"})
	aAdd(aCat, {"FIN02", "/bi/financeiro/pagamentos", "Baixas no periodo de titulos com pedido de compra de contrato e/ou OS", "de:D:INIMES;ate:D:HOJE;escopo:E:CONTRATO_OS"})
	aAdd(aCat, {"FIN03", "/bi/financeiro/rateio-cc", "Rateio por centro de custo dos titulos informados (R_E_C_N_O_ da SE2)", "recs:R:!"})
	aAdd(aCat, {"FIN04", "/bi/financeiro/centros-custo", "Centros de custo (CTT) agrupados pelo codigo", ""})
	aAdd(aCat, {"FIN05", "/bi/financeiro/faturamento", "Faturamento mensal por filial (vendas com duplicata e devolucoes) para a DRE", "de:D:-12M;ate:D:HOJE"})
	aAdd(aCat, {"FIN06", "/bi/geral/filiais", "Filiais do grupo de empresas com o nome", ""})
	aAdd(aCat, {"APR01", "/bi/aprovacao/pendencias", "Pendencias de alcada (SCR status 02) com item bloqueado na SC7, papel na SAL e limites", ""})
	aAdd(aCat, {"APR02", "/bi/aprovacao/itens", "Itens dos pedidos pendentes de aprovacao", ""})
	aAdd(aCat, {"APR03", "/bi/aprovacao/cotacoes", "Cotacoes (SC8) dos itens pendentes de aprovacao", ""})
	aAdd(aCat, {"PED01", "/bi/pedidos/colunas", "Deteccao das colunas opcionais de pedidos/notas/alcada", ""})
	aAdd(aCat, {"PED02", "/bi/pedidos/itens", "Itens de pedido de compra, todos os status (inclui excluidos)", "desde:T:"})
	aAdd(aCat, {"PED03", "/bi/pedidos/alcadas", "Alcadas de aprovacao (SCR) de pedidos", "desde:T:"})
	aAdd(aCat, {"PED04", "/bi/pedidos/notas", "Notas de entrada (SD1) vinculadas a pedido", "desde:T:"})
	aAdd(aCat, {"PED05", "/bi/pedidos/solicitacoes", "Solicitacoes de compra (SC1) vinculadas a pedido", "desde:T:"})
	aAdd(aCat, {"PED06", "/bi/pedidos/alterados", "Chaves FILIAL|PEDIDO alteradas desde o ultimo recorte", "desde:T:!;dia:D:HOJE"})
	aAdd(aCat, {"COM01", "/bi/compras/tabelas", "Deteccao de tabelas opcionais (SY1)", ""})
	aAdd(aCat, {"COM02", "/bi/compras/colunas-sc1", "Deteccao de colunas opcionais da SC1", ""})
	aAdd(aCat, {"COM03", "/bi/compras/solicitacoes", "Solicitacoes de compra (SC1)", "desde:D:-12M"})
	aAdd(aCat, {"COM04", "/bi/compras/cotacoes", "Cotacoes (SC8)", "desde:D:-12M"})
	aAdd(aCat, {"COM05", "/bi/compras/custos", "Custo medio dos itens (SB2)", ""})
	aAdd(aCat, {"COM06", "/bi/compras/notas-entrada", "Notas de entrada (SD1) agrupadas por documento", "desde:D:-12M"})
	aAdd(aCat, {"FOL01", "/bi/folha/lancamentos", "Folha fechada (SRD) por competencia/roteiro/CC/verba", "desde:M:-13M"})
	aAdd(aCat, {"FOL02", "/bi/folha/lancamentos-previa", "Previa da folha em calculo (SRC) por competencia/roteiro/CC/verba", "ultima:M:ULTSRD"})
	aAdd(aCat, {"FOL03", "/bi/folha/pessoas-competencia", "Pessoas distintas por competencia (SRD)", "desde:M:-13M"})
	aAdd(aCat, {"FOL04", "/bi/folha/pessoas-competencia-previa", "Pessoas distintas por competencia (SRC)", "ultima:M:ULTSRD"})
	aAdd(aCat, {"FOL05", "/bi/folha/pessoas-cc", "Pessoas distintas por competencia e CC (SRD)", "desde:M:-13M"})
	aAdd(aCat, {"FOL06", "/bi/folha/pessoas-cc-previa", "Pessoas distintas por competencia e CC (SRC)", "ultima:M:ULTSRD"})
	aAdd(aCat, {"FOL07", "/bi/folha/verbas", "Cadastro de verbas (SRV)", ""})
	aAdd(aCat, {"FOL08", "/bi/folha/quadro", "Quadro atual por CC e situacao (SRA)", ""})
	aAdd(aCat, {"FOL09", "/bi/folha/admissoes-demissoes", "Admissoes e demissoes por mes e CC", "desde:M:-13M"})
	aAdd(aCat, {"RHU01", "/bi/rh/pessoas-ativas", "Funcionarios ativos (SRA) sem dados pessoais", ""})
	aAdd(aCat, {"RHU02", "/bi/rh/ultima-competencia", "Ultima competencia fechada (SRD)", ""})
	aAdd(aCat, {"RHU03", "/bi/rh/verbas", "Cadastro de verbas (SRV) - colunas DESCR/IDFOL", ""})
	aAdd(aCat, {"RHU04", "/bi/rh/matriculas-periodo", "Matriculas com folha no periodo", "de:M:-3M;ate:M:MESATU"})
	aAdd(aCat, {"RHU05", "/bi/rh/valor-verbas", "Valor por matricula das verbas informadas no periodo", "de:M:-3M;ate:M:MESATU;lista:L:!"})
	aAdd(aCat, {"RHU06", "/bi/rh/ferias-vencidas", "Periodos aquisitivos de ferias vencidos (SRF)", "hoje:D:HOJE"})
	aAdd(aCat, {"RHU07", "/bi/rh/ferias-gozadas", "Dias de ferias gozados por periodo aquisitivo (SRH)", ""})
	aAdd(aCat, {"RHU08", "/bi/rh/afastamentos", "Afastamentos em aberto (SR8)", "hoje:D:HOJE"})
	aAdd(aCat, {"RHU09", "/bi/rh/hora-extra", "Hora extra por matricula/competencia (verbas informadas)", "de:M:-12M;ate:M:MESATU;lista:L:!"})
	aAdd(aCat, {"MED01", "/bi/medicina/atestados", "Atestados medicos (TNY)", "desde:D:-12M"})
	aAdd(aCat, {"MED02", "/bi/medicina/custo-pessoa", "Custo por pessoa/competencia (bruto, encargo, extra, atestado, falta)", "desde:M:-12M;vbruto:L:;vencargo:L:;vextra:L:;vatest:L:;vfalta:L:"})
	aAdd(aCat, {"MED03", "/bi/medicina/ferias", "Ferias iniciadas no periodo (SRH)", "desde:D:-12M"})
	aAdd(aCat, {"MED04", "/bi/medicina/pessoas", "Pessoas ativas ou demitidas no periodo", "desde:D:-12M"})
	aAdd(aCat, {"MED05", "/bi/medicina/rescisoes", "Rescisoes (SRR) no periodo", "desde:D:-12M"})
	aAdd(aCat, {"MED06", "/bi/medicina/acidentes", "Acidentes de trabalho / CAT (TNC)", ""})
	aAdd(aCat, {"MNT01", "/bi/frota/bens", "Bens / veiculos (ST9)", ""})
	aAdd(aCat, {"MNT02", "/bi/frota/ordens", "Ordens de servico (STJ) com custos", "desde:D:-24M"})
	aAdd(aCat, {"MNT03", "/bi/frota/insumos", "Insumos das OS por grupo de produto", "desde:D:-24M"})
	aAdd(aCat, {"MNT04", "/bi/frota/compras-cc", "Compras dos CC de frota", "desde:D:-24M"})
	aAdd(aCat, {"MNT05", "/bi/frota/combustivel-nf", "Combustivel comprado (SD1)", "desde:D:-24M"})
	aAdd(aCat, {"MNT06", "/bi/frota/combustivel-requisicao", "Combustivel requisitado do estoque (SD3)", "desde:D:-24M"})
	aAdd(aCat, {"MNT07", "/bi/frota/hodometro", "Leituras de hodometro (STP) por mes", "desde:D:-24M"})
	aAdd(aCat, {"MNT08", "/bi/frota/pecas", "Pecas aplicadas nas OS", "desde:D:-24M"})
	aAdd(aCat, {"MNT09", "/bi/frota/precos", "Precos de referencia de pecas (SD1)", "desde:D:-24M"})
	aAdd(aCat, {"MNT10", "/bi/frota/abastecimentos", "Abastecimentos por bem (TQN)", "desde:D:-24M"})
	aAdd(aCat, {"EST01", "/bi/estoque/produtos-movimentados", "Produtos com movimento interno (SB1 x SD3)", ""})
	aAdd(aCat, {"EST02", "/bi/estoque/centros-custo", "Centros de custo (CTT)", ""})
	aAdd(aCat, {"EST03", "/bi/estoque/tipos-movimento", "Tipos de movimento (SF5)", ""})
	aAdd(aCat, {"EST04", "/bi/estoque/precos-entrada", "Precos unitarios de entrada (SD1)", "desde:D:20250101"})
	aAdd(aCat, {"EST05", "/bi/estoque/meses-movimento", "Meses com movimento interno valido (SD3)", ""})
	aAdd(aCat, {"EST06", "/bi/estoque/movimentos", "Movimentos internos (SD3) do mes", "mes:M:MESATU"})
	aAdd(aCat, {"EST07", "/bi/estoque/saldos", "Saldos de estoque (SB2) com ultima entrada/saida", "hoje:D:HOJE"})
	aAdd(aCat, {"EST08", "/bi/estoque/fechamentos", "Fechamentos mensais (SB9)", "desde:D:20250101"})
	aAdd(aCat, {"EST09", "/bi/estoque/produtos-solicitados", "Produtos com solicitacao ao armazem (SB1 x SCP)", ""})
	aAdd(aCat, {"EST10", "/bi/estoque/atendimento-sa", "Primeiro/ultimo atendimento das solicitacoes ao armazem", ""})
	aAdd(aCat, {"EST11", "/bi/estoque/meses-solicitacao", "Meses com solicitacao ao armazem (SCP)", "desde:D:20260101;hoje:D:HOJE"})
	aAdd(aCat, {"EST12", "/bi/estoque/solicitacoes", "Solicitacoes ao armazem (SCP) do mes", "mes:M:MESATU"})
	aAdd(aCat, {"EST13", "/bi/estoque/prazo-atendimento", "Prazo solicitacao x pedido x entrada", "desde:D:20250101"})
	aAdd(aCat, {"EST14", "/bi/estoque/entradas-nf", "Entradas por nota que movimentam estoque (SD1)", ""})
	aAdd(aCat, {"EST15", "/bi/estoque/saidas-nf", "Saidas por nota que movimentam estoque (SD2)", ""})
	aAdd(aCat, {"EST16", "/bi/estoque/produtos-saldo", "Produtos com saldo cadastrado (SB1 x SB2)", ""})
	aAdd(aCat, {"EST17", "/bi/estoque/saldo-atual", "Saldo atual por produto|armazem (SB2)", ""})
	aAdd(aCat, {"EST18", "/bi/estoque/meses-sd3", "Meses com movimento interno (SD3, sem filtro de estorno)", ""})
	aAdd(aCat, {"EST19", "/bi/estoque/movimentos-saldo", "Movimentos internos do mes para saldo negativo", "mes:M:MESATU"})
	aAdd(aCat, {"EST20", "/bi/estoque/inventarios", "Contagens de inventario (SB7)", "desde:D:20260101;hoje:D:HOJE"})
	aAdd(aCat, {"EST21", "/bi/estoque/inventario-ajustes-sd3", "Ajustes de inventario gerados (SD3 doc INVENT)", "desde:D:20260101"})
	aAdd(aCat, {"EST22", "/bi/estoque/ajustes", "Ajustes manuais de estoque", "desde:D:20260101;hoje:D:HOJE"})
	aAdd(aCat, {"EST23", "/bi/estoque/movimento-dia", "Entradas e saidas por dia/produto/armazem", "de:D:HOJE;hoje:D:HOJE"})
	aAdd(aCat, {"EPI01", "/bi/epi/validade-ca", "Validade do CA por EPI/fornecedor (TN3)", ""})
	aAdd(aCat, {"EPI02", "/bi/epi/meses-entrega", "Meses com entrega de EPI (TNF)", "desde:D:20251001;hoje:D:HOJE"})
	aAdd(aCat, {"EPI03", "/bi/epi/entregas", "Entregas de EPI do mes (TNF)", "mes:M:MESATU;hoje:D:HOJE"})
	aAdd(aCat, {"EPI04", "/bi/epi/pessoas", "Funcionarios com funcao (SRA x SRJ)", ""})
	aAdd(aCat, {"EPI05", "/bi/epi/itens", "Produtos usados como EPI", ""})
	aAdd(aCat, {"EPI06", "/bi/epi/genericos", "EPI generico x filho (TL0)", ""})
	aAdd(aCat, {"EPI07", "/bi/epi/durabilidade", "Durabilidade por EPI (TN3)", ""})
	aAdd(aCat, {"EPI08", "/bi/epi/por-funcao", "EPI por funcao (TNB)", ""})
	aAdd(aCat, {"CTR01", "/bi/contratos/contratos", "Contratos de compra (CN9), uma linha por revisao", ""})
	aAdd(aCat, {"CTR02", "/bi/contratos/medicoes", "Itens das medicoes (CNE) de contratos de compra", "desde:D:-24M"})
	aAdd(aCat, {"USR00", "/bi/usuarios/colunas", "Colunas das tabelas de usuario e auditoria (diagnostico)", ""})
	aAdd(aCat, {"USR01", "/bi/usuarios/cadastro", "Usuarios (SYS_USR) com o ultimo acesso", ""})
	aAdd(aCat, {"USR02", "/bi/usuarios/modulos", "Modulos dos usuarios (SYS_USR_MODULE)", ""})
	aAdd(aCat, {"USR03", "/bi/usuarios/acessos", "Historico de acesso (TOTVS_AUDIT) por usuario, dia e hora", "desde:D:-24M"})

Return aCat

//-----------------------------------------------------------------------------
// Converte "nome:tipo:padrao;..." em { {nome, tipo, padrao}, ... }
//-----------------------------------------------------------------------------
Static Function xSpec(cSpec)
	Local aRet := {}
	Local aItm := {}
	Local aTok := {}
	Local nI   := 0

	If Empty(cSpec)
		Return aRet
	EndIf

	aItm := StrTokArr2(cSpec, ";")
	For nI := 1 To Len(aItm)
		aTok := StrTokArr2(aItm[nI], ":", .T.)
		aSize(aTok, 3)
		aAdd(aRet, {aTok[1], aTok[2], iif(ValType(aTok[3]) == "C", aTok[3], "")})
	Next nI

Return aRet

//-----------------------------------------------------------------------------
// Fluxo comum: valida parametros, monta o SQL, executa e responde
//-----------------------------------------------------------------------------
Static Function xRun(oWS, cId)
	Local aCat  := xCatalogo()
	Local nPos  := aScan(aCat, {|x| x[1] == cId})
	Local oPar  := JsonObject():New()
	Local oResp := Nil
	Local xQry  := Nil
	Local cErro := ""
	Local cPag  := ""
	Local cTam  := ""
	Local nPage := 0
	Local nSize := 0

	oWS:SetContentType("application/json")

	If nPos == 0
		SetRestFault(404, EncodeUTF8("Consulta nao cadastrada: " + cId))
		Return .F.
	EndIf

	If !xParams(oWS, aCat[nPos][4], oPar, @cErro)
		SetRestFault(400, EncodeUTF8(cErro))
		Return .F.
	EndIf

	cPag := xLePar(oWS, "page")
	cTam := xLePar(oWS, "pagesize")
	If (!Empty(cPag) .And. !xSoDig(cPag)) .Or. (!Empty(cTam) .And. !xSoDig(cTam))
		SetRestFault(400, EncodeUTF8("page e pageSize devem ser numeros inteiros"))
		Return .F.
	EndIf
	nPage := Max(Val(cPag), 1)
	nSize := Val(cTam)
	If nSize > BI_MAXPAG
		SetRestFault(400, EncodeUTF8("pageSize maximo: " + cValToChar(BI_MAXPAG)))
		Return .F.
	EndIf

	xQry := xBuild(cId, oPar)
	If ValType(xQry) == "C"
		SetRestFault(400, EncodeUTF8(xQry))
		Return .F.
	ElseIf ValType(xQry) != "A"
		SetRestFault(500, EncodeUTF8("Consulta sem montagem de SQL: " + cId))
		Return .F.
	EndIf

	oResp := JsonObject():New()
	oResp["consulta"]   := cId
	oResp["path"]       := aCat[nPos][2]
	oResp["parametros"] := oPar
	oResp["page"]       := iif(nSize > 0, nPage, 1)
	oResp["pageSize"]   := nSize

	If !xExec(xQry[1], xQry[2], nPage, nSize, oResp, @cErro)
		SetRestFault(500, EncodeUTF8(cErro))
		Return .F.
	EndIf

	oWS:SetResponse(oResp:ToJson())

Return .T.

//-----------------------------------------------------------------------------
// Encaminha para o fonte do modulo. Retorna {cSql, cOrdem} ou a mensagem de erro.
//-----------------------------------------------------------------------------
Static Function xBuild(cId, oPar)
	Local cMod := Left(cId, 3)

	Do Case
	Case cMod $ "FIN|APR"
		Return U_BIQFIN(cId, oPar)
	Case cMod $ "PED|COM"
		Return U_BIQCOM(cId, oPar)
	Case cMod $ "FOL|RHU|MED"
		Return U_BIQRH(cId, oPar)
	Case cMod == "MNT"
		Return U_BIQMNT(cId, oPar)
	Case cMod $ "EST|EPI"
		Return U_BIQEST(cId, oPar)
	Case cMod == "CTR"
		Return U_BIQCTR(cId, oPar)
	Case cMod == "USR"
		Return U_BIQUSR(cId, oPar)
	EndCase

Return Nil

//-----------------------------------------------------------------------------
// Le, aplica o padrao e valida cada parametro declarado no catalogo.
// Os valores ficam em oPar ja no formato seguro para concatenar no SQL:
//   D/M -> so digitos | T -> "AAAA-MM-DD HH:MM:SS" | L -> 'a','b' | R -> 1,2
//-----------------------------------------------------------------------------
Static Function xParams(oWS, cSpec, oPar, cErro)
	Local aDef := xSpec(cSpec)
	Local cVal := ""
	Local nI   := 0

	For nI := 1 To Len(aDef)
		cVal := xLePar(oWS, aDef[nI][1])

		If Empty(cVal)
			If aDef[nI][3] == "!"
				cErro := "Parametro obrigatorio nao informado: " + aDef[nI][1]
				Return .F.
			EndIf
			cVal := xDefault(aDef[nI][2], aDef[nI][3])
		EndIf

		If !Empty(cVal)
			cVal := xValida(aDef[nI][1], aDef[nI][2], cVal, @cErro)
			If cVal == Nil
				Return .F.
			EndIf
		EndIf

		oPar[aDef[nI][1]] := cVal
	Next nI

Return .T.

//-----------------------------------------------------------------------------
// Le um parametro da querystring (WSDATA). Sem macro: Locals nao sao visiveis.
//-----------------------------------------------------------------------------
Static Function xLePar(oWS, cNome)
	Local xVal := Nil

	Do Case
	Case cNome == "desde"    ; xVal := oWS:desde
	Case cNome == "de"       ; xVal := oWS:de
	Case cNome == "ate"      ; xVal := oWS:ate
	Case cNome == "hoje"     ; xVal := oWS:hoje
	Case cNome == "ultima"   ; xVal := oWS:ultima
	Case cNome == "dia"      ; xVal := oWS:dia
	Case cNome == "mes"      ; xVal := oWS:mes
	Case cNome == "lista"    ; xVal := oWS:lista
	Case cNome == "recs"     ; xVal := oWS:recs
	Case cNome == "vbruto"   ; xVal := oWS:vbruto
	Case cNome == "vencargo" ; xVal := oWS:vencargo
	Case cNome == "vextra"   ; xVal := oWS:vextra
	Case cNome == "vatest"   ; xVal := oWS:vatest
	Case cNome == "vfalta"   ; xVal := oWS:vfalta
	Case cNome == "escopo"   ; xVal := oWS:escopo
	Case cNome == "page"     ; xVal := oWS:page
	Case cNome == "pagesize" ; xVal := oWS:pageSize
	EndCase

	If ValType(xVal) == "N"
		Return cValToChar(xVal)
	ElseIf ValType(xVal) != "C"
		Return ""
	EndIf

Return AllTrim(xVal)

//-----------------------------------------------------------------------------
// Valor padrao do parametro
//-----------------------------------------------------------------------------
Static Function xDefault(cTipo, cTok)
	Local dHoje := Date()
	Local dRef  := Nil
	Local nQtd  := 0

	Do Case
	Case Empty(cTok) .Or. cTok == "!"
		Return ""
	Case cTok == "HOJE"
		Return DtoS(dHoje)
	Case cTok == "INIMES"
		Return Left(DtoS(dHoje), 6) + "01"
	Case cTok == "MESATU"
		Return Left(DtoS(dHoje), 6)
	Case cTok == "ULTSRD"
		Return xUltSRD()
	Case Left(cTok, 1) == "-"
		nQtd := Val(SubStr(cTok, 2, Len(cTok) - 2))
		If Right(cTok, 1) == "D"
			dRef := dHoje - nQtd
		Else
			dRef := MonthSub(dHoje, nQtd)
		EndIf
		Return iif(cTipo == "M", Left(DtoS(dRef), 6), DtoS(dRef))
	EndCase

Return cTok

//-----------------------------------------------------------------------------
// Ultima competencia fechada na SRD (padrao do parametro "ultima")
//-----------------------------------------------------------------------------
Static Function xUltSRD()
	Local cAlias := GetNextAlias()
	Local cRet   := ""

	DbUseArea(.T., "TOPCONN", TcGenQry(,, "SELECT MAX(RD_DATARQ) YM FROM " + RetSqlName("SRD") + " WHERE D_E_L_E_T_ = ' '"), cAlias, .F., .T.)
	If !(cAlias)->(Eof())
		cRet := AllTrim((cAlias)->YM)
	EndIf
	(cAlias)->(DbCloseArea())

	If Empty(cRet)
		cRet := Left(DtoS(Date()), 6)
	EndIf

Return cRet

//-----------------------------------------------------------------------------
// Valida e normaliza o valor conforme o tipo. Retorna Nil em caso de erro.
//-----------------------------------------------------------------------------
Static Function xValida(cNome, cTipo, cVal, cErro)
	Local aTok := {}
	Local cRet := ""
	Local cItm := ""
	Local nI   := 0

	Do Case
	Case cTipo == "E"
		// escopo do financeiro: CONTRATO_OS (padrao) ou TODOS
		cRet := Upper(AllTrim(cVal))
		If !(cRet == "CONTRATO_OS" .Or. cRet == "TODOS")
			cErro := cNome + ": use CONTRATO_OS ou TODOS"
			Return Nil
		EndIf

	Case cTipo == "D"
		If Len(cVal) != 8 .Or. !xSoDig(cVal) .Or. Empty(StoD(cVal))
			cErro := cNome + ": data invalida, use AAAAMMDD"
			Return Nil
		EndIf
		cRet := cVal

	Case cTipo == "M"
		If Len(cVal) != 6 .Or. !xSoDig(cVal) .Or. Val(Right(cVal, 2)) < 1 .Or. Val(Right(cVal, 2)) > 12
			cErro := cNome + ": competencia invalida, use AAAAMM"
			Return Nil
		EndIf
		cRet := cVal

	Case cTipo == "T"
		If Len(cVal) == 8 .And. xSoDig(cVal)
			cVal := Left(cVal, 4) + "-" + SubStr(cVal, 5, 2) + "-" + Right(cVal, 2) + "T00:00:00"
		EndIf
		If Right(cVal, 1) == "Z"
			cVal := Left(cVal, Len(cVal) - 1)
		EndIf
		cVal := Left(cVal, 19)
		If Len(cVal) != 19 .Or. ;
		   !xSoDig(Left(cVal, 4) + SubStr(cVal, 6, 2) + SubStr(cVal, 9, 2) + SubStr(cVal, 12, 2) + SubStr(cVal, 15, 2) + Right(cVal, 2)) .Or. ;
		   SubStr(cVal, 5, 1) + SubStr(cVal, 8, 1) + SubStr(cVal, 11, 1) + SubStr(cVal, 14, 1) + SubStr(cVal, 17, 1) != "--T::" .Or. ;
		   Empty(StoD(Left(cVal, 4) + SubStr(cVal, 6, 2) + SubStr(cVal, 9, 2)))
			cErro := cNome + ": data-hora invalida, use AAAA-MM-DDTHH:MM:SS"
			Return Nil
		EndIf
		cRet := StrTran(cVal, "T", " ")

	Case cTipo == "L"
		aTok := StrTokArr2(cVal, ",")
		If Len(aTok) > 500
			cErro := cNome + ": maximo de 500 codigos"
			Return Nil
		EndIf
		For nI := 1 To Len(aTok)
			cItm := AllTrim(aTok[nI])
			If Empty(cItm)
				Loop
			EndIf
			If Len(cItm) > 30 .Or. !xCodOk(cItm)
				cErro := cNome + ": codigo invalido '" + cItm + "' (use letras, numeros, _ . - /)"
				Return Nil
			EndIf
			cRet += iif(Empty(cRet), "", ",") + "'" + cItm + "'"
		Next nI

	Case cTipo == "R"
		aTok := StrTokArr2(cVal, ",")
		If Len(aTok) > 1000
			cErro := cNome + ": maximo de 1000 registros por chamada"
			Return Nil
		EndIf
		For nI := 1 To Len(aTok)
			cItm := AllTrim(aTok[nI])
			If Empty(cItm)
				Loop
			EndIf
			If !xSoDig(cItm) .Or. Len(cItm) > 12
				cErro := cNome + ": R_E_C_N_O_ invalido '" + cItm + "'"
				Return Nil
			EndIf
			cRet += iif(Empty(cRet), "", ",") + cItm
		Next nI

	OtherWise
		cErro := cNome + ": tipo de parametro desconhecido"
		Return Nil
	EndCase

Return cRet

Static Function xSoDig(cVal)
	Local nI := 0

	If Empty(cVal)
		Return .F.
	EndIf
	For nI := 1 To Len(cVal)
		If !IsDigit(SubStr(cVal, nI, 1))
			Return .F.
		EndIf
	Next nI

Return .T.

Static Function xCodOk(cVal)
	Local cOk := "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.-/"
	Local nI  := 0

	For nI := 1 To Len(cVal)
		If !(Upper(SubStr(cVal, nI, 1)) $ cOk)
			Return .F.
		EndIf
	Next nI

Return .T.

//-----------------------------------------------------------------------------
// Executa o SQL e preenche oResp com count/hasNext/items.
// Com pageSize > 0 pagina no proprio SQL Server (OFFSET/FETCH), buscando
// uma linha a mais para saber se existe proxima pagina.
//-----------------------------------------------------------------------------
Static Function xExec(cSql, cOrdem, nPage, nSize, oResp, cErro)
	Local cAlias := GetNextAlias()
	Local bOld   := Nil
	Local lOk    := .T.
	Local lMais  := .F.
	Local aStru  := {}
	Local aCampo := {}
	Local aItens := {}
	Local oItem  := Nil
	Local xVal   := Nil
	Local nI     := 0

	If nSize > 0
		cSql += " ORDER BY " + iif(Empty(cOrdem), "1", cOrdem)
		cSql += " OFFSET " + cValToChar((nPage - 1) * nSize) + " ROWS FETCH NEXT " + cValToChar(nSize + 1) + " ROWS ONLY"
	ElseIf !Empty(cOrdem)
		cSql += " ORDER BY " + cOrdem
	EndIf

	bOld := ErrorBlock({|oErr| cErro := oErr:Description, Break(oErr)})
	Begin Sequence
		DbUseArea(.T., "TOPCONN", TcGenQry(,, cSql), cAlias, .F., .T.)
	Recover
		lOk := .F.
	End Sequence
	ErrorBlock(bOld)

	If !lOk
		cErro := "Erro ao executar a consulta: " + AllTrim(cErro) + " " + AllTrim(TCSqlError())
		ConOut("[APIBI] " + cErro + CRLF + cSql)
		Return .F.
	EndIf

	aStru := (cAlias)->(DbStruct())
	For nI := 1 To Len(aStru)
		aAdd(aCampo, xNomeCol(aStru[nI][1]))
	Next nI

	While !(cAlias)->(Eof())
		If nSize > 0 .And. Len(aItens) >= nSize
			lMais := .T.
			Exit
		EndIf

		oItem := JsonObject():New()
		For nI := 1 To Len(aStru)
			xVal := (cAlias)->(FieldGet(nI))
			Do Case
			Case ValType(xVal) == "C"
				xVal := xUtf8(RTrim(xVal))
			Case ValType(xVal) == "D"
				xVal := DtoS(xVal)
			EndCase
			oItem[aCampo[nI]] := xVal
		Next nI
		aAdd(aItens, oItem)

		(cAlias)->(DbSkip())
	EndDo
	(cAlias)->(DbCloseArea())

	oResp["count"]   := Len(aItens)
	oResp["hasNext"] := lMais
	oResp["items"]   := aItens

Return .T.

Static Function xUtf8(cVal)
	Local cRet := EncodeUTF8(cVal)

Return iif(cRet == Nil, cVal, cRet)

//-----------------------------------------------------------------------------
// O TOPCONN limita o nome da coluna a 10 caracteres. Os fontes BIQ* usam
// aliases curtos e aqui eles voltam ao nome usado no arquivo original.
//-----------------------------------------------------------------------------
Static Function xNomeCol(cCampo)
	Local cRet := AllTrim(cCampo)

	Do Case
	Case cRet == "NATDESC"    ; cRet := "NATUREZA_DESC"
	Case cRet == "APROV_ID"   ; cRet := "APROVADOR_ID"
	Case cRet == "APROV_LOG"  ; cRet := "APROVADOR_LOGIN"
	Case cRet == "APROV_NOM"  ; cRet := "APROVADOR_NOME"
	Case cRet == "APROV_COD"  ; cRet := "APROVADOR_COD"
	Case cRet == "LIBAPR"     ; cRet := "TIPO_APROVADOR"
	Case cRet == "TPLIBER"    ; cRet := "TIPO_LIBERACAO"
	Case cRet == "LIM_MIN"    ; cRet := "LIMITE_MIN"
	Case cRet == "LIM_MAX"    ; cRet := "LIMITE_MAX"
	Case cRet == "AUTOLIM"    ; cRet := "CONSIDERA_LIMITE"
	Case cRet == "EMISS_PED"  ; cRet := "EMISSAO_PEDIDO"
	Case cRet == "FORNEC_NOM" ; cRet := "FORNECEDOR_NOME"
	Case cRet == "FORNEC_CGC" ; cRet := "FORNECEDOR_CNPJ"
	Case cRet == "SOLICITAC"  ; cRet := "SOLICITACAO"
	Case cRet == "SOLICITANT" ; cRet := "SOLICITANTE"
	Case cRet == "ALTER_UTC"  ; cRet := "ALTERADO_UTC"
	Case cRet == "PRECO_INI"  ; cRet := "PRECO_INICIAL"
	Case cRet == "ORC_FORNEC" ; cRet := "ORCAMENTO_FORNECEDOR"
	Case cRet == "JUSTIFIC"   ; cRet := "JUSTIFICATIVA"
	Case cRet == "LIBER_POR"  ; cRet := "LIBERADO_POR"
	EndCase

Return cRet

//-----------------------------------------------------------------------------
// Indica se a coluna existe na tabela fisica (substitui ALL_TAB_COLUMNS).
// Usado para campos que podem nao existir no ambiente: S_T_A_M_P_,
// I_N_S_D_T_ e campos customizados. O resultado fica em cache na thread.
//-----------------------------------------------------------------------------
User Function BIHASCOL(cTabela, cCampo)
	Local cChave := Upper(AllTrim(cTabela) + "|" + AllTrim(cCampo))
	Local cAlias := ""
	Local cSql   := ""
	Local lRet   := .F.

	If oColCache == Nil
		oColCache := JsonObject():New()
	EndIf
	If ValType(oColCache[cChave]) == "L"
		Return oColCache[cChave]
	EndIf

	cSql := "SELECT COUNT(*) N FROM INFORMATION_SCHEMA.COLUMNS "
	cSql += "WHERE TABLE_NAME = '" + AllTrim(cTabela) + "' AND COLUMN_NAME = '" + AllTrim(cCampo) + "'"

	cAlias := GetNextAlias()
	DbUseArea(.T., "TOPCONN", TcGenQry(,, cSql), cAlias, .F., .T.)
	lRet := (cAlias)->N > 0
	(cAlias)->(DbCloseArea())

	oColCache[cChave] := lRet

Return lRet

//-----------------------------------------------------------------------------
// Devolve cExpr se a coluna existir na tabela do alias Protheus cTab;
// senao devolve um NULL tipado (vira "" no JSON).
//-----------------------------------------------------------------------------
User Function BICOL(cTab, cCampo, cExpr)

	If U_BIHASCOL(RetSqlName(cTab), cCampo)
		Return cExpr
	EndIf

Return "CAST(NULL AS VARCHAR(250))"
