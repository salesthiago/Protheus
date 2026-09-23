// Modelo de dados espelhando o MVC oficial da CNTA300/CNTA301 (GCT0109 - Exemplos de Rotina
// Automatica - Rotina CNTA300). Nomes de campo comentados entre parenteses indicam o campo real
// do dicionario que cada propriedade representa. Espelha 1:1 o JSON produzido por
// Contratos/RTM003App.prw (ZcnList/ZcnMont/ZcnPess) do lado ADVPL.

// CN9_ESPCTR: "1"=Compra, "2"=Venda (mesma convencao usada em rtm002/CabCtr) -- aqui usamos as
// siglas 'C'/'V' que ja aparecem nas respostas do rtm002 (CabecalhoContratoResponse.tipo).
export type TipoContrato = 'C' | 'V';

export const TIPOS_CONTRATO_OPTIONS: Array<{ value: TipoContrato; label: string }> = [
  { value: 'C', label: 'Compra' },
  { value: 'V', label: 'Venda' }
];

// Os 11 codigos padrao de CN9_SITUAC (mesma tabela fixa de RT69M003.prw::SitCtrDescPlain e de
// ZcnSitDesc em Contratos/RTM003App.prw). Decisao do usuario (2026-09-03): usar os 11 codigos
// reais, mas com as transicoes controladas por ESTA tela (TRANSICOES_SITUACAO abaixo), nao pelas
// travas da rotina nativa do CNTA300.
export enum SituacaoContrato {
  Cancelado = '01',
  EmElaboracao = '02',
  Emitido = '03',
  EmAprovacao = '04',
  Vigente = '05',
  Paralisado = '06',
  SolicitadaFinalizacao = '07',
  Finalizado = '08',
  EmRevisao = '09',
  Revisado = '10',
  RevisaoAlcadas = 'A'
}

export const SITUACOES_CONTRATO_OPTIONS: Array<{ value: SituacaoContrato; label: string }> = [
  { value: SituacaoContrato.Cancelado, label: 'Cancelado' },
  { value: SituacaoContrato.EmElaboracao, label: 'Em Elaboração' },
  { value: SituacaoContrato.Emitido, label: 'Emitido' },
  { value: SituacaoContrato.EmAprovacao, label: 'Em Aprovação' },
  { value: SituacaoContrato.Vigente, label: 'Vigente' },
  { value: SituacaoContrato.Paralisado, label: 'Paralisado' },
  { value: SituacaoContrato.SolicitadaFinalizacao, label: 'Solicitação de Finalização' },
  { value: SituacaoContrato.Finalizado, label: 'Finalizado' },
  { value: SituacaoContrato.EmRevisao, label: 'Em Revisão' },
  { value: SituacaoContrato.Revisado, label: 'Revisado' },
  { value: SituacaoContrato.RevisaoAlcadas, label: 'Revisão com Aprovação por Alçadas' }
];

// Maquina de estados PROPRIA desta tela: para cada situacao atual, as situacoes para as quais o
// usuario pode mover o contrato. E o espelho EXATO de ZcnSitPode() em Contratos/RTM003App.prw --
// qualquer mudanca aqui tem que ser refletida la (e vice-versa), senao a tela oferece um botao
// que o backend recusa. O backend grava CN9_SITUAC direto (RecLock/Replace) sem passar por
// CN100Situac, e registra o evento na timeline (ZLG) por conta propria.
export const TRANSICOES_SITUACAO: Record<SituacaoContrato, SituacaoContrato[]> = {
  [SituacaoContrato.Cancelado]: [],
  [SituacaoContrato.EmElaboracao]: [SituacaoContrato.Emitido, SituacaoContrato.Cancelado],
  [SituacaoContrato.Emitido]: [SituacaoContrato.EmAprovacao, SituacaoContrato.EmElaboracao, SituacaoContrato.Cancelado],
  [SituacaoContrato.EmAprovacao]: [SituacaoContrato.Vigente, SituacaoContrato.EmElaboracao, SituacaoContrato.Cancelado],
  [SituacaoContrato.Vigente]: [SituacaoContrato.Paralisado, SituacaoContrato.SolicitadaFinalizacao, SituacaoContrato.EmRevisao],
  [SituacaoContrato.Paralisado]: [SituacaoContrato.Vigente, SituacaoContrato.SolicitadaFinalizacao],
  [SituacaoContrato.SolicitadaFinalizacao]: [SituacaoContrato.Finalizado, SituacaoContrato.Vigente],
  [SituacaoContrato.Finalizado]: [SituacaoContrato.Vigente],
  [SituacaoContrato.EmRevisao]: [SituacaoContrato.Revisado, SituacaoContrato.RevisaoAlcadas, SituacaoContrato.Vigente],
  [SituacaoContrato.Revisado]: [SituacaoContrato.Vigente],
  [SituacaoContrato.RevisaoAlcadas]: [SituacaoContrato.Revisado, SituacaoContrato.Vigente]
};

// Um evento da timeline do contrato (tabela ZLG) -- devolvido por ZcnTL (op "contratoTimeline"),
// mesma fonte que o relatorio PDF Contratos/RT69M003.prw imprime.
export interface EventoTimeline {
  data: string; // ISO 'yyyy-MM-dd'
  hora: string;
  acao: string;
  acaoLabel: string;
  revisao: string;
  numMed: string;
  origem: string;
  origemLabel: string;
  antes: string;
  antesLabel: string;
  depois: string;
  depoisLabel: string;
  usuario: string;
  nomeUsuario: string;
  obs: string;
}

export interface TimelineResponse {
  success: boolean;
  message?: string;
  eventos: EventoTimeline[];
}

// Codigos de tipo de revisao aceitos por A300STpRev.
export enum TipoRevisao {
  Aditivo = '1',
  Reajuste = '2',
  Realinhamento = '3',
  Readequacao = '4',
  Paralisacao = '5',
  Reinicio = '6',
  Clausulas = '7',
  Contabil = '8',
  Indice = '9',
  FornecedorCliente = 'A',
  GrupoAprovacao = 'B',
  Renovacao = 'C',
  MultaBonificacao = 'D',
  Caucao = 'E',
  OrcamentoServicosGS = 'F',
  Aberta = 'G'
}

export const TIPOS_REVISAO_OPTIONS: Array<{ value: TipoRevisao; label: string }> = [
  { value: TipoRevisao.Aditivo, label: 'Aditivo' },
  { value: TipoRevisao.Reajuste, label: 'Reajuste' },
  { value: TipoRevisao.Realinhamento, label: 'Realinhamento' },
  { value: TipoRevisao.Readequacao, label: 'Readequação' },
  { value: TipoRevisao.Paralisacao, label: 'Paralisação' },
  { value: TipoRevisao.Reinicio, label: 'Reinício' },
  { value: TipoRevisao.Clausulas, label: 'Cláusulas' },
  { value: TipoRevisao.Contabil, label: 'Contábil' },
  { value: TipoRevisao.Indice, label: 'Índice' },
  { value: TipoRevisao.FornecedorCliente, label: 'Fornecedor/Cliente' },
  { value: TipoRevisao.GrupoAprovacao, label: 'Grupo de aprovação' },
  { value: TipoRevisao.Renovacao, label: 'Renovação' },
  { value: TipoRevisao.MultaBonificacao, label: 'Multa/Bonificação' },
  { value: TipoRevisao.Caucao, label: 'Caução' },
  { value: TipoRevisao.OrcamentoServicosGS, label: 'Orçamento de Serviços GS' },
  { value: TipoRevisao.Aberta, label: 'Aberta' }
];

// Cliente ou fornecedor (CNCDETAIL: CNC_CODIGO/CNC_LOJA para compra, CNC_CLIENT/CNC_LOJACL
// para venda) -- o rotulo exibido ("Cliente" vs "Fornecedor") depende de ContratoHeader.tipo.
export interface Pessoa {
  codigo: string;
  loja: string;
  nome: string;
}

// Item de planilha (CNBDETAIL). CNB_TS/CNB_PEDTIT são campos oficiais confirmados no GCT0109;
// cc (CNB_CC, centro de custo) e desconto (CNB_PERDES, desconto percentual) são convenção
// padrão Protheus assumida, não confirmada em nenhum exemplo do GCT0109 (ver ZcnCriar/ZcnMont
// em Contratos/RTM003App.prw). unidade (CNB_UM) é suposição nova da Fase 5 (protótipo
// "Contratos - Alteração", 2026-08-11), mesmo nível de confiança de CNB_CC/CNB_PERDES.
export interface ItemPlanilha {
  item: string; // CNB_ITEM
  produto: string; // CNB_PRODUT
  descricao: string;
  unidade: string; // CNB_UM
  quantidade: number; // CNB_QUANT
  valorUnitario: number; // CNB_VLUNIT
  cc: string; // CNB_CC
  tes: string; // CNB_TS
  pedTit: string; // CNB_PEDTIT ("1"=Nota Fiscal, "2"=Título -- mapeamento assumido, confirmar)
  desconto: number; // CNB_PERDES (percentual, 0-100)
  quantidadeMedida?: number; // CNB_QTDMED -- so leitura (vem do backend)
}

// Casas decimais dos valores monetarios das planilhas (pedido do usuario 2026-09-21: 4 casas).
// Um unico ponto de controle -- usado nos po-number e nos pipes number da tela.
export const CASAS_DECIMAIS_VALOR = 4;
export const FORMATO_VALOR = '1.4-4';

// Opções assumidas para CNB_PEDTIT -- o GCT0109 só mostra o valor "1" sendo gravado, sem
// documentar o domínio completo do campo. Confirmar o mapeamento real quando testado.
export const PEDTIT_OPTIONS: Array<{ value: string; label: string }> = [
  { value: '1', label: 'Nota Fiscal' },
  { value: '2', label: 'Título' }
];

// Planilha do contrato (CNADETAIL) -- um contrato pode ter mais de uma (ver exemplo "Inclusão
// de contrato com múltiplas planilhas" do GCT0109). dataInicio/dataFim (CNA_DTINIC/CNA_DTFIM)
// são suposição nova da Fase 5 -- pessoa passou a ser escolhida POR PLANILHA (não mais um campo
// único do contrato), pedido do usuário 2026-08-11 ("definir o cliente/fornecedor ao adicionar
// uma planilha").
export interface Planilha {
  numero: string; // CNA_NUMERO
  tipoPlanilha: string; // CNA_TIPPLA
  dataInicio: string; // CNA_DTINIC
  dataFim: string; // CNA_DTFIM
  pessoa: Pessoa;
  itens: ItemPlanilha[];
  // Campos abaixo resolvidos no backend pelo dicionario (ZcnCpDic em RTM003App.prw) -- vazios se
  // o campo nao existir neste ambiente.
  descricao?: string;
  indice?: string; // codigo do indice de reajuste (tabela de indices)
  periodicidade?: number;
  unidadePer?: string;
  modoReajuste?: string;
  dataBase?: string; // ISO 'yyyy-MM-dd'
}

// Domínio de CN9_FLGREJ -- confirmado pelo usuário 2026-08-11 ("1"=Sim, "2"=Não). Campo real
// (antes chutado como "CN9_REAJUS").
export const REAJUSTE_OPTIONS: Array<{ value: string; label: string }> = [
  { value: '1', label: 'Sim' },
  { value: '2', label: 'Não' }
];

// Domínio de CN9_UNVIGE -- confirmado pelo usuário 2026-08-11: "1"=Dias, "2"=Meses, "3"=Anos.
// Usado tanto no formulário (contrato-editor) quanto na listagem (contrato-list, que antes
// mandava o código cru concatenado -- "81 2" em vez de "81 Meses" -- ver ZcnList).
export const UNIDADES_VIGENCIA_OPTIONS: Array<{ value: string; label: string }> = [
  { value: '1', label: 'Dias' },
  { value: '2', label: 'Meses' },
  { value: '3', label: 'Anos' }
];

// Cabecalho do contrato (CN9MASTER). Campos abaixo de "temCronograma" são novos da Fase 5
// (protótipo "Contratos - Alteração") -- a maioria CONFIRMADA pelo usuário em 2026-08-11 (2
// rodadas de correção sobre os nomes chutados inicialmente); os poucos ainda marcados
// "suposição" seguem sem gravação no backend (ver ZcnCriar/ZcnAtu) até serem confirmados também.
// Todos opcionais -- telas antigas (revisao-form) não mandam a maioria deles.
export interface ContratoHeader {
  numero: string; // CN9_NUMERO
  revisao: string; // CN9_REVISA
  tipo: TipoContrato; // derivado de CN9_ESPCTR
  filial?: string; // CN9_FILIAL -- filial onde o contrato foi gravado
  dataInicio: string; // CN9_DTINIC (ISO 'yyyy-MM-dd' no front)
  unidadeVigencia: string; // CN9_UNVIGE
  vigencia: number; // CN9_VIGE
  moeda: number; // CN9_MOEDA
  descricao?: string; // descricao do contrato (campo resolvido pelo dicionario -- ZcnCpDic)
  condPagto: string; // CN9_CONDPG
  tipoContrato: string; // CN9_TPCTO
  situacao: SituacaoContrato; // CN9_SITUAC
  // Descricao ja traduzida pelo backend (ZcnSitDesc, Contratos/RTM003App.prw) -- fonte unica de
  // verdade pro texto exibido. O mapeamento local (SITUACOES_CONTRATO_OPTIONS, mais abaixo) era
  // incompleto (faltavam os codigos 02/04/09/10/A) e mostrava o codigo cru nesses casos.
  situacaoDescricao?: string;
  temCronograma: boolean; // ZcnTmCrg -- existe ao menos 1 linha em CNF pra este contrato+revisao
  justificativa?: string; // CN9_JUSTIF (virtual, confirmado real)
  objeto?: string; // CN9_OBJCTO (virtual, confirmado real)
  clausula?: string; // CN9_ALTCLA (virtual, confirmado real)
  dtAssinatura?: string; // CN9_ASSINA (confirmado real)
  valorInicial?: number; // CN9_VLINI (confirmado real)
  valorAtual?: number; // CN9_VLATU (confirmado real)
  despesaFinanceira?: number; // CN9_VJUROS (confirmado real)
  reajuste?: string; // CN9_FLGREJ (confirmado real, "1"/"2")
  dtReajuste?: string; // CN9_DTREAJ (confirmado real, so leitura -- nao enviado no payload)
  saldo?: number; // CN9_SALDO (confirmado real, so leitura)
  dtUltimaRevisao?: string; // CN9_DTREV (confirmado real, so leitura -- tb usado no histórico)
  natureza?: string; // CN9_NATURE (confirmado real -- lookup SED, ver ZcnNat/lookupNatureza)
  valorPresente?: number; // CN9_VLPRES (ainda suposição; fallback: soma das planilhas no cliente)
  indice?: string; // CN9_INDICE (ainda suposição, texto livre -- sem tabela de índices confirmada)
  centroCusto?: string; // CN9_CC (ainda suposição -- reaproveita ZcnCCus/lookupCentroCusto, CTT)
  responsavel?: string; // CN9_RESPON (ainda suposição -- texto livre, sem tabela confirmada)
}

// Uma revisao do historico do contrato (cabecalho CN9 de uma revisao anterior/atual).
export interface Revisao {
  tipo: TipoRevisao;
  justificativa: string; // CN9_JUSTIF
  data: string; // ISO 'yyyy-MM-dd'
  situacao: SituacaoContrato;
  situacaoDescricao?: string; // ver nota em ContratoHeader.situacaoDescricao
}

// Shape agregado que as telas consomem, devolvido por ZcnMont (contratoDetalhe/contratoCriar/
// contratoSituacao/revisaoAbrir/revisaoAprovar).
export interface Contrato {
  header: ContratoHeader;
  pessoa: Pessoa;
  planilhas: Planilha[];
  revisoes: Revisao[];
}

// Linha resumida da listagem (ZcnList/contratoListar) -- fonte da contrato-list. vigencia/
// unidadeVigencia vêm SEPARADOS (não mais um texto pré-concatenado "81 2") -- a tela converte
// unidadeVigencia pra rótulo via UNIDADES_VIGENCIA_OPTIONS, mesma conversão do formulário.
export interface ContratoResumo {
  numero: string;
  revisao: string;
  tipo: TipoContrato;
  filial?: string; // CN9_FILIAL
  pessoaNome: string;
  situacao: SituacaoContrato;
  situacaoDescricao?: string; // ver nota em ContratoHeader.situacaoDescricao
  vigencia: number;
  unidadeVigencia: string;
}

// Filtros aceitos por ZcnList (contratoListar) -- todos opcionais. numero e LIKE parcial;
// filial e igualdade exata (quando vazio, o backend usa a filial corrente da sessao);
// dataInicioDe/dataInicioAte formam um intervalo fechado sobre CN9_DTINIC (ISO 'yyyy-MM-dd').
export interface ContratoListFiltro {
  tipo?: TipoContrato | '';
  situacao?: SituacaoContrato | '';
  numero?: string;
  filial?: string;
  dataInicioDe?: string;
  dataInicioAte?: string;
}

// Respostas do bridge (AdvplBridgeService) -- todas trazem "success"/"message" opcional, mesmo
// formato usado em MedicaoService (rtm002).
export interface ContratoListResponse {
  success: boolean;
  message?: string;
  contratos: ContratoResumo[];
}

export interface ContratoDetalheResponse extends Contrato {
  success: boolean;
  message?: string;
  // Chaves de campos que o backend NAO gravou por nao existirem no dicionario (ver ZcnPlaSet).
  avisos?: string[];
}

export interface PessoaLookupResponse {
  success: boolean;
  message?: string;
  items: Pessoa[];
  hasNext: boolean;
}

// Tipo de Contrato (CN1) -- ZcnTpCt/lookupTipoContrato. "tipo" ja vem derivado de CN1_ESPCTR
// (mesma convenção "1"=Compra/"2"=Venda de CN9_ESPCTR) -- escolher um Tipo de Contrato decide
// Compra/Venda, não existe mais um toggle manual separado (pedido do usuário 2026-08-10, CN1 já
// carrega essa informação).
export interface TipoContratoItem {
  codigo: string;
  descricao: string;
  tipo: TipoContrato;
}

export interface TipoContratoLookupResponse {
  success: boolean;
  message?: string;
  items: TipoContratoItem[];
  hasNext: boolean;
}

// Produto (SB1) -- ZcnProd/lookupProduto.
export interface ProdutoItem {
  codigo: string;
  descricao: string;
}

export interface ProdutoLookupResponse {
  success: boolean;
  message?: string;
  items: ProdutoItem[];
  hasNext: boolean;
}

// Condicao de Pagamento (SE4) -- ZcnCndPg/lookupCondPagto.
export interface CondPagtoItem {
  codigo: string;
  descricao: string;
}

export interface CondPagtoLookupResponse {
  success: boolean;
  message?: string;
  items: CondPagtoItem[];
  hasNext: boolean;
}

// Tipo de Planilha (CNL) -- ZcnTpPla/lookupTipoPlanilha. "exigeCronograma" so vem preenchido se o
// backend localizou o campo real no dicionario (candidatos em ZcnTpPla/RTM003App.prw) -- ausente
// (undefined) = campo nao encontrado, a tela assume .T. (comportamento anterior a esta feature:
// Periodicidade sempre liberada em modo criar).
export interface TipoPlanilhaItem {
  codigo: string;
  descricao: string;
  exigeCronograma?: boolean;
}

export interface TipoPlanilhaLookupResponse {
  success: boolean;
  message?: string;
  items: TipoPlanilhaItem[];
  hasNext: boolean;
  campoCronogEncontrado?: boolean;
}

// TES (SF4) -- ZcnTes/lookupTES.
export interface TesItem {
  codigo: string;
  descricao: string;
}

export interface TesLookupResponse {
  success: boolean;
  message?: string;
  items: TesItem[];
  hasNext: boolean;
}

// Centro de Custo (CTT) -- ZcnCCus/lookupCentroCusto.
export interface CentroCustoItem {
  codigo: string;
  descricao: string;
}

export interface CentroCustoLookupResponse {
  success: boolean;
  message?: string;
  items: CentroCustoItem[];
  hasNext: boolean;
}

// Filial (SM0) -- ZcnFilial/lookupFilial. Lista TODAS as filiais da empresa corrente, sem
// checar permissão por usuário (limitação conhecida, ver nota em ZcnFilial no
// Contratos/RTM003App.prw) -- usada no filtro de filial da busca avançada e no modal de
// seleção de filial antes de incluir um contrato.
export interface FilialItem {
  codigo: string; // M0_CODFIL
  nome: string; // M0_FILIAL
}

export interface FilialLookupResponse {
  success: boolean;
  message?: string;
  items: FilialItem[];
}

// Sugestão de próximo número de contrato (ZcnProxNum/lookupProximoNumero) -- via GetSxeNum
// (contador automático já configurado no SX3 de CN9_NUMERO, confirmado pelo usuário). Só
// pré-preenche o campo "Nr. Contrato"; continua editável, ZcnCriar grava o que vier no payload.
export interface ProximoNumeroResponse {
  success: boolean;
  message?: string;
  numero: string;
}

// Natureza (SED) -- ZcnNat/lookupNatureza. CN9_NATURE confirmado pelo usuário 2026-08-11 como
// "consulta padrão da tabela SED" -- substitui o domínio placeholder chutado (NATUREZA_OPTIONS,
// removido) por um po-lookup de verdade, mesmo padrão de Centro de Custo/Cond. Pagto.
export interface NaturezaItem {
  codigo: string;
  descricao: string;
}

export interface NaturezaLookupResponse {
  success: boolean;
  message?: string;
  items: NaturezaItem[];
  hasNext: boolean;
}

// Payload de item ao criar/revisar -- espelha o que ZcnCriar/ZcnRevAb esperam por item.
export interface ItemPayload {
  produto: string;
  unidade: string;
  quantidade: number;
  valorUnitario: number;
  cc: string;
  tes: string;
  pedTit: string;
  desconto: number;
}

// Payload de uma planilha ao criar/revisar -- espelha {tipoPlanilha, dataInicio, dataFim,
// pessoa, itens} de ZcnCriar/ZcnRevAb. pessoa/dataInicio/dataFim são opcionais no tipo porque
// revisao-form ainda não coleta esses campos (ZcnRevAb cai de volta pro CNCDETAIL atual quando
// "pessoa" não vem) -- mas contrato-editor, em modo criar, sempre os preenche antes de enviar.
export interface PlanilhaPayload {
  tipoPlanilha: string;
  dataInicio?: string;
  dataFim?: string;
  pessoa?: { codigo: string; loja: string };
  itens: ItemPayload[];
  descricao?: string;
  indice?: string;
  periodicidade?: number;
  unidadePer?: string;
  modoReajuste?: string;
  dataBase?: string;
}

// Payloads enviados ao ADVPL -- espelham o que ZcnCriar/ZcnRevAb esperam em oReq. "tipo" NÃO
// entra mais no payload de criação -- o servidor deriva de CN1_ESPCTR a partir do
// header.tipoContrato recebido (fonte única da verdade, ver ZcnCriar). "pessoa" de nível de
// contrato foi REMOVIDO (Fase 5) -- agora é por planilha (ver PlanilhaPayload).
export interface ContratoCriarPayload {
  // Filial escolhida no modal de inclusão (item 4) -- o backend (ZcnCriar) só ACEITA se for
  // igual à filial da sessão atual; do contrário recusa com mensagem clara (ver nota em
  // Contratos/RTM003App.prw sobre por que não dá pra simplesmente gravar em outra filial).
  filial?: string;
  header: {
    numero: string;
    dataInicio: string;
    unidadeVigencia: string;
    vigencia: number;
    moeda: number;
    descricao?: string;
    condPagto: string;
    tipoContrato: string;
    justificativa?: string;
    dtAssinatura?: string;
    valorInicial?: number;
    valorAtual?: number;
    objeto?: string;
    clausula?: string;
    natureza?: string;
  };
  planilhas: PlanilhaPayload[];
}

export interface RevisaoAbrirPayload {
  numero: string;
  revisaoBase?: string;
  tipoRevisao: TipoRevisao;
  justificativa: string;
  planilhas?: PlanilhaPayload[];
}

// Payload de atualização (operação "contratoAtualizar", Fase 5) -- SÓ os campos descritivos do
// header. Por design nunca inclui planilhas/itens -- alterar isso continua exigindo uma Revisão
// (ver ZcnAtu em Contratos/RTM003App.prw e a decisão documentada no plano desta fase).
export interface ContratoAtualizarPayload {
  numero: string;
  revisao: string;
  header: {
    descricao?: string;
    justificativa?: string;
    dtAssinatura?: string;
    objeto?: string;
    clausula?: string;
    natureza?: string;
  };
}

// Cronograma financeiro/fisico (CN300PrCF, botao nativo "Incluir Cronograma Financeiro/
// Físico") -- ZcnGrCrg/gerarCronograma. Nomes e ordem dos parametros espelham o grupo de
// perguntas "CN300CRG" documentado no GCT0109 (MV_PAR01..MV_PAR08).
export const PERIODICIDADE_OPTIONS: Array<{ value: number; label: string }> = [
  { value: 1, label: 'Mensal' },
  { value: 2, label: 'Quinzenal' },
  { value: 3, label: 'Diário' },
  { value: 4, label: 'Condição de Pagamento' }
];

export const SIM_NAO_OPTIONS: Array<{ value: number; label: string }> = [
  { value: 1, label: 'Sim' },
  { value: 2, label: 'Não' }
];

export interface CronogramaPayload {
  numero: string;
  revisao: string;
  periodicidade: number; // MV_PAR01: 1=Mensal,2=Quinzenal,3=Diário,4=Cond.Pagamento
  dias: number; // MV_PAR02
  ultimoDiaMes: number; // MV_PAR03: 1=Sim,2=Não
  competenciaInicio: string; // MV_PAR04: "MM/AAAA"
  dataPrevista: string; // MV_PAR05: data prevista da 1ª medição (ISO 'yyyy-MM-dd')
  qtdParcelas: number; // MV_PAR06
  condPagto: string; // MV_PAR07
  taxaJuros: number; // MV_PAR08
}

// Moeda -- ZcnMoeda/lookupMoeda (tabela CTO, ou MV_MOEDA1..9 como alternativa). "codigo" numerico.
export interface MoedaItem {
  codigo: number;
  descricao: string;
}

export interface MoedaLookupResponse {
  success: boolean;
  message?: string;
  items: MoedaItem[];
  hasNext: boolean;
}

// Indice de reajuste -- ZcnIndice/lookupIndice (tabela de indices cadastrados, CN6).
export interface IndiceItem {
  codigo: string;
  descricao: string;
}

export interface IndiceLookupResponse {
  success: boolean;
  message?: string;
  items: IndiceItem[];
  hasNext: boolean;
}

// Operacao "dominiosPlanilha" (ZcnDomPla): quais campos opcionais existem no dicionario deste
// ambiente + opcoes de combo (X3_CBOX) de "Unidade" e "Modo de reajuste" da planilha.
export interface DominiosPlanilhaResponse {
  success: boolean;
  message?: string;
  campos: {
    descCtr: boolean;
    descPla: boolean;
    indice: boolean;
    periodicidade: boolean;
    unidadePer: boolean;
    modoReajuste: boolean;
    dataBase: boolean;
  };
  mapa?: Record<string, string>; // chave logica -> campo real resolvido ("" se nao achou)
  unidades: Array<{ value: string; label: string }>;
  modosReajuste: Array<{ value: string; label: string }>;
}

// Formata valor em pt-BR (o locale do app nao e registrado, entao o pipe number sairia em en-US: "108,000.0000").
export function formatarValor(valor: number | null | undefined, casas = CASAS_DECIMAIS_VALOR): string {
  return new Intl.NumberFormat('pt-BR', { minimumFractionDigits: casas, maximumFractionDigits: casas }).format(valor ?? 0);
}
