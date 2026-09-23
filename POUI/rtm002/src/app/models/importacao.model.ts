// Colunas dinamicas: o CSV exportado pelo RT69M001 nao tem layout fixo -- os nomes de
// coluna vem do proprio cabecalho do arquivo (CN9_NUMERO, CNE_QUANT, CNE_VLUNIT, etc.,
// ver RT69M002.prw). Por isso a linha e um dicionario indexado pelo nome da coluna, e nao
// uma interface com campos fixos.
export type LinhaImportacao = Record<string, string>;

export interface MedicaoImportacao {
  colunas: string[];
  linhas: LinhaImportacao[];
}

// Nomes de coluna do arquivo de importacao. O numero do contrato/revisao NAO vem mais do
// arquivo (ver ImportarMedicaoComponent::ngOnInit + contratoPosicionado -- mesma logica da
// aba Exportar): a tela ja parte do contrato posicionado no browse, entao o arquivo so precisa
// identificar planilha+item+produto+quantidade (TES/CC opcionais); descricao, UM, classe
// valor, valor unitario e saldo vem do cadastro da planilha (CNB) via op "itensPlanilha", nao
// do arquivo -- ver CarregaItens/ItensPlan em Contratos/RTM002App.prw.
export const COLUNA_PLANILHA = 'CNE_NUMERO';
export const COLUNA_ITEM = 'CNE_ITEM';
export const COLUNA_PRODUTO = 'CNE_PRODUT';
export const COLUNA_DESCRICAO = 'CNE_DESCRI';
export const COLUNA_UM = 'CNE_UM';
export const COLUNA_QUANTIDADE = 'CNE_QUANT';
export const COLUNA_CC = 'CNE_CC';
export const COLUNA_ITEMCT = 'CNE_ITEMCT';
export const COLUNA_CLASSE_VALOR = 'CNE_CLVL';
export const COLUNA_VALOR_UNITARIO = 'CNE_VLUNIT';
export const COLUNA_SALDO_ITEM = 'SALDO_ITEM';
export const COLUNA_TES = 'CNE_TES';

// Colunas obrigatorias no arquivo -- identificam qual item da planilha esta sendo medido e
// quanto. TES e CC ficam de fora (opcionais, ver COLUNAS_OPCIONAIS): se nao vierem, a tela
// acrescenta a coluna vazia (mesmo comportamento de RT69M002.prw::MostraGrid para TES).
export const COLUNAS_OBRIGATORIAS = [COLUNA_PLANILHA, COLUNA_ITEM, COLUNA_PRODUTO, COLUNA_QUANTIDADE];
export const COLUNAS_OPCIONAIS = [COLUNA_TES, COLUNA_CC];

// Colunas exibidas na grade de itens. Descricao/UM/Classe Valor/Valor Unitario/Saldo sao
// preenchidas via itensPlanilha (CNB), nao lidas do arquivo.
export const COLUNAS_GRID = [
  COLUNA_PLANILHA,
  COLUNA_ITEM,
  COLUNA_PRODUTO,
  COLUNA_DESCRICAO,
  COLUNA_UM,
  COLUNA_QUANTIDADE,
  COLUNA_CC,
  COLUNA_CLASSE_VALOR,
  COLUNA_VALOR_UNITARIO,
  COLUNA_SALDO_ITEM,
  COLUNA_TES
];

export interface ValidacaoLayout {
  valido: boolean;
  colunasFaltantes: string[];
}

// Sinonimos de cabecalho aceitos por campo canonico, alem do proprio nome canonico -- usados
// por CsvParserService para reconhecer TANTO o layout cru originado por RT69M001.prw::GeraArq
// (nomes de campo: CNE_NUMERO, CNE_ITEM, ...) QUANTO o layout amigavel gerado pela propria aba
// Exportar deste app (ExportarMedicaoComponent::gerarXlsx: "Planilha", "Item", ...), permitindo
// reimportar um arquivo exportado por esta mesma tela. Comparacao e' sempre case/acento-
// insensitive (ver CsvParserService.normalizar).
export const ALIASES_COLUNA: Record<string, string[]> = {
  [COLUNA_PLANILHA]: ['Planilha'],
  [COLUNA_ITEM]: ['Item'],
  [COLUNA_PRODUTO]: ['Produto'],
  [COLUNA_DESCRICAO]: ['Descrição', 'Descricao'],
  [COLUNA_UM]: ['UM'],
  [COLUNA_QUANTIDADE]: ['Quantidade'],
  [COLUNA_CC]: ['CC'],
  [COLUNA_ITEMCT]: ['Item CT'],
  [COLUNA_CLASSE_VALOR]: ['Classe Valor'],
  [COLUNA_VALOR_UNITARIO]: ['Valor Unitário', 'Valor Unitario'],
  [COLUNA_SALDO_ITEM]: ['Saldo do Item'],
  [COLUNA_TES]: ['TES']
};

export interface Pessoa {
  codigo: string;
  loja: string;
  nome: string;
}

export interface CabecalhoContratoResponse {
  success: boolean;
  message?: string;
  tipo: 'C' | 'V';
  pessoas: Pessoa[];
  saldoContrato: number;
  competencias: string[];
}

export interface TesLookupItem {
  value: string;
  label: string;
}

export interface TesLookupResponse {
  success: boolean;
  items: TesLookupItem[];
  hasNext: boolean;
}

// Payload/resposta de "validarLimite" -- ver Static Function ValLim em Contratos/RTM002App.prw,
// porta de RT69M002.prw::ConfirmarMed (soma por planilha x limite do cronograma financeiro/CNF).
export interface ItemValidacaoLimite {
  planilha: string;
  quantidade: string;
  valorUnitario: string;
}

export interface AvisoLimite {
  planilha: string;
  totalInformado: number;
  limite: number;
}

export interface ValidarLimiteResponse {
  success: boolean;
  message?: string;
  excedeLimite: boolean;
  avisos: AvisoLimite[];
}

// Payload/resposta de "gerarMedicao" -- ver Static Function GerarMed/GerarPlan em
// Contratos/RTM002App.prw, porta de RT69M002.prw::ExecutaMed/ProcessaPlanilha (uma medicao
// CNTA121 por planilha).
export interface ItemGeracaoMedicao {
  planilha: string;
  item: string;
  produto: string;
  descricao: string;
  cc: string;
  tes: string;
  quantidade: string;
  valorUnitario: string;
}

export interface GerarMedicaoRequest {
  cNumCont: string;
  cRevisao: string;
  cCompet: string;
  cCliente: string;
  cLojaCli: string;
  cFornec: string;
  cLjForn: string;
  itens: ItemGeracaoMedicao[];
}

export interface ResultadoPlanilha {
  planilha: string;
  success: boolean;
  numMedicao?: string;
  message?: string;
}

export interface GerarMedicaoResponse {
  success: boolean;
  message?: string;
  resultados: ResultadoPlanilha[];
}

// ---- Aba Exportar (Static Function ListaPlan/ExportarCtr em Contratos/RTM002App.prw) ----

// Planilha (CNA) do contrato, para o checklist de seleção da aba Exportar.
export interface PlanilhaExport {
  numero: string;
  codigo: string;
  loja: string;
  nome: string;
  valorTotal: number;
  qtdItens: number;
}

export interface ListarPlanilhasResponse {
  success: boolean;
  message?: string;
  planilhas: PlanilhaExport[];
}

// Item de planilha (CNB) exportado -- ver Static Function ExportarCtr em
// Contratos/RTM002App.prw. Diferente do layout CSV de RT69M001.prw::GeraArq, o
// fornecedor/cliente aqui vem por item (da CNA da própria planilha), não fixo no primeiro
// da CNA do contrato inteiro.
export interface ItemExportacao {
  contrato: string;
  revisao: string;
  competencia: string;
  planilha: string;
  item: string;
  produto: string;
  descricao: string;
  um: string;
  quantidade: number;
  cc: string;
  itemCt: string;
  classeValor: string;
  valorUnitario: number;
  pessoaCodigo: string;
  pessoaLoja: string;
  saldoItem: number;
}

// Resposta de "itensPlanilha" (op usada pela aba Importar para completar descricao/um/valor
// unitario/classe valor/saldo a partir do cadastro da planilha -- CarregaItens/ItensPlan em
// Contratos/RTM002App.prw). Mesmo shape de item de ExportarCtr, por isso reaproveita
// ItemExportacao.
export interface ItensPlanilhaResponse {
  success: boolean;
  message?: string;
  tipo: 'C' | 'V';
  itens: ItemExportacao[];
}

// Parcela do cronograma financeiro (CNF) de uma planilha, incluída quando o usuário marca
// "Incluir cronograma financeiro" -- vira a segunda aba do XLSX exportado.
export interface ParcelaCronograma {
  planilha: string;
  numero: string;
  competencia: string;
  parcela: string;
  dataPrevista: string;
  valorPrevisto: number;
  maxParcela: number;
  saldo: number;
  dataRealizada: string;
}

// Item da última medição (CNE) já gerada para uma planilha -- incluída quando o usuário marca
// "Incluir última medição". GerarPlan gera uma medição por planilha, então isto é "a última
// medição DE CADA planilha exportada", não um único número global de medição do contrato.
// "tes" nao entra aqui: CNE010 nao tem coluna CNE_TES (confirmado por erro real do SQL Server
// -- "Invalid column name 'CNE_TES'" -- ao consultar direto, ver Static Function CarregaUltMed
// em Contratos/RTM002App.prw).
export interface ItemUltimaMedicao {
  planilha: string;
  numMedicao: string;
  item: string;
  produto: string;
  descricao: string;
  quantidade: number;
  valorUnitario: number;
  valorTotal: number;
  cc: string;
  dataEntrega: string;
}

export interface ExportarContratoRequest {
  cNumCont: string;
  cRevisao: string;
  aPlanilhas: string[];
  lCronograma: boolean;
  lUltimaMed: boolean;
}

export interface ExportarContratoResponse {
  success: boolean;
  message?: string;
  tipo: 'C' | 'V';
  itens: ItemExportacao[];
  cronograma: ParcelaCronograma[];
  ultimaMedicao: ItemUltimaMedicao[];
}

// Pré-visualização do cronograma financeiro (op "listarCronograma") -- roda independente do
// checkbox "incluir no arquivo exportado", disparada sempre que a seleção de planilhas muda.
export interface ListarCronogramaResponse {
  success: boolean;
  message?: string;
  cronograma: ParcelaCronograma[];
}

// Contrato posicionado no browse (CNTA100) quando o usuário abriu a tela -- op
// "contratoPosicionado", ver Static Function CtxPos em Contratos/RTM002App.prw.
export interface ContratoPosicionadoResponse {
  success: boolean;
  message?: string;
  temContrato: boolean;
  numContrato: string;
  revisao: string;
}
