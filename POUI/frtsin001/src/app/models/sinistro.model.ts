// Espelha 1:1 o JSON produzido por frotas/sinistro/MNTA540App.prw
// (ZsiList / ZsiMont / ZsiFilha* / ZsiLk* / ZsiImpProc). Nomes de campo do
// dicionario indicados entre parenteses.

export interface RespostaBase {
  success: boolean;
  message?: string;
}

// ---------------------------------------------------------------------------
// Dominios fixos (espelho de ZsiDomPares no ADVPL)
// ---------------------------------------------------------------------------
export interface OpcaoDominio {
  value: string;
  label: string;
}

export const EVENTO_OPTIONS: OpcaoDominio[] = [
  { value: '1', label: 'Acidente' },
  { value: '2', label: 'Roubo' },
  { value: '3', label: 'Incidente' }
];

export const GRAVIDADE_OPTIONS: OpcaoDominio[] = [
  { value: '1', label: 'Leve' },
  { value: '2', label: 'Médio' },
  { value: '3', label: 'Grave' },
  { value: '4', label: 'Gravíssimo' }
];

export const TEMPO_OPTIONS: OpcaoDominio[] = [
  { value: '1', label: 'Bom' },
  { value: '2', label: 'Chuvoso' },
  { value: '3', label: 'Neblina' },
  { value: '4', label: 'Nublado' }
];

export const VIA_OPTIONS: OpcaoDominio[] = [
  { value: '1', label: 'Reta' },
  { value: '2', label: 'Curva' },
  { value: '3', label: 'Cruzamento' },
  { value: '4', label: 'Estrada de Terra' }
];

export const PERIODO_OPTIONS: OpcaoDominio[] = [
  { value: '1', label: 'Manhã' },
  { value: '2', label: 'Noite' },
  { value: '3', label: 'Tarde' },
  { value: '4', label: 'Madrugada' }
];

export const VIADIR_OPTIONS: OpcaoDominio[] = [
  { value: '1', label: 'Única' },
  { value: '2', label: 'Dupla' }
];

export const SIMNAO_OPTIONS: OpcaoDominio[] = [
  { value: '1', label: 'Sim' },
  { value: '2', label: 'Não' }
];

export const CULPA_OPTIONS: OpcaoDominio[] = [
  { value: '1', label: 'Terceiro' },
  { value: '2', label: 'Empresa' },
  { value: '3', label: 'Funcionário' },
  { value: '4', label: 'Força Maior / Sem Culpa' },
  { value: '9', label: 'A Apurar' }
];

export const ORIGEM_VEICULO_OPTIONS: OpcaoDominio[] = [
  { value: '1', label: 'Quebec' },
  { value: '2', label: 'Terceiro' }
];

export const TIPO_ANEXO_OPTIONS: OpcaoDominio[] = [
  { value: '1', label: 'Foto' },
  { value: '2', label: 'Termo' },
  { value: '3', label: 'Contrato' },
  { value: '4', label: 'BO' },
  { value: '5', label: 'Nota Fiscal' },
  { value: '9', label: 'Outros' }
];

export function rotuloDominio(opcoes: OpcaoDominio[], valor: string | undefined): string {
  if (!valor) {
    return '';
  }
  return opcoes.find(o => o.value === valor)?.label ?? valor;
}

// ---------------------------------------------------------------------------
// Lista
// ---------------------------------------------------------------------------
export interface SinistroResumo {
  numero: string;            // TRH_NUMSIN
  data: string;              // ISO AAAA-MM-DD (TRH_DTACID)
  hora: string;              // TRH_HRACID
  evento: string;            // TRH_EVENTO
  eventoLabel: string;
  codBem: string;            // TRH_CODBEM
  nomeBem: string;           // TRH_NOMBEM
  placa: string;             // TRH_PLACA
  gravidade: string;         // TRH_GRAVID
  gravidadeLabel: string;
  status: string;            // TRH_STATUS
  statusLabel: string;
  culpabilidade: string;     // TRH_ZCULPA
  culpabilidadeLabel: string;
  culpadoNome: string;       // TRH_ZCLPNM
  fonte: string;             // TRH_ZFONTE (I=Importacao / M=Manual)
}

export interface SinistroListFiltro {
  numero?: string;
  dataDe?: string;
  dataAte?: string;
  placa?: string;
  evento?: string;
  culpabilidade?: string;
  status?: string;
}

export interface SinistroListResponse extends RespostaBase {
  sinistros: SinistroResumo[];
}

// ---------------------------------------------------------------------------
// Filhas
// ---------------------------------------------------------------------------
export interface VeiculoEnvolvido {
  seq: string;               // TRO_SEQVEI
  origem: string;            // TRO_ZORIG (1=Quebec / 2=Terceiro)
  origemLabel?: string;
  placa: string;             // TRO_PLACA
  descricao: string;         // TRO_DESVEI
  condutor: string;          // TRO_MOTVEI
  matricula: string;         // TRO_ZMAT
  cpf: string;               // TRO_CPF
  cnh: string;               // TRO_CNHMOT
  telefone: string;          // TRO_TELMOT
  proprietario: string;      // TRO_NOMPR
  danos: string;             // TRO_DANOS
  valorPrejuizo: number;     // TRO_VALPRE
  valorTerceiro: number;     // TRO_VALTER
  percentualGanho: number;   // TRO_PERCEN
  segurado: string;          // TRO_SEGUR
  seguradora: string;        // TRO_SEGCOR
  apolice: string;           // TRO_APOLIC
}

export interface Testemunha {
  seq: string;               // TRN_SEQTES
  nome: string;              // TRN_NOMTES
  telefone: string;          // TRN_TELTES
  endereco: string;          // TRN_ENDTES
  cidade: string;            // TRN_CIDTES
  uf: string;                // TRN_UFTES
  tipoDoc: string;           // TRN_TIPDOC
  documento: string;         // TRN_DOCTO
  qualificacao: string;      // TRN_QLFTES
}

export interface Vitima {
  seq: string;               // TRM_SEQVIT
  funcionario: string;       // TRM_INDFUN (1=Sim / 2=Nao)
  matricula: string;         // TRM_MATVIT
  nome: string;              // TRM_NOMVIT
  telefone: string;          // TRM_TELVIT
  endereco: string;          // TRM_ENDVIT
  cidade: string;            // TRM_CIDVIT
  uf: string;                // TRM_UFVIT
  lesoes: string;            // TRM_LESOES
  acaoTomada: string;        // TRM_ACAO
  funcao: string;            // TRM_DESFUN
  fatal: string;             // TRM_FATAL
  condicao: string;          // TRM_CODVIT
  valorVitima: number;       // TRM_VALVIT
}

export interface Anexo {
  codDoc: string;            // TRI_CODDOC
  nomeDoc: string;           // TRI_NOMDOC
  dataReceb: string;         // TRI_DTREC (ISO)
  horaReceb: string;         // TRI_HRREC
  tipo: string;              // TRI_ZTIPO
  tipoLabel: string;
  arquivo: string;           // TRI_ZARQ
  caminho: string;           // TRI_ZPATH
  mime: string;              // TRI_ZMIME
  tamanho: number;           // TRI_ZTAM
}

// ---------------------------------------------------------------------------
// Cabecalho completo
// ---------------------------------------------------------------------------
export interface Sinistro {
  numero: string;
  filial?: string;
  data: string;
  hora: string;
  evento: string;
  eventoLabel?: string;
  codBem: string;
  nomeBem: string;
  placa: string;
  gravidade: string;
  gravidadeLabel?: string;
  tempo: string;
  via: string;
  periodo: string;
  maoDirecao: string;
  local: string;
  cidade: string;
  uf: string;
  numeroBO: string;
  nomeDP: string;
  interrViagem: string;
  necGuincho: string;
  valorGuincho: number;
  delitoConcret: string;
  terceiroEvadiu: string;
  status: string;
  statusLabel?: string;
  descricao: string;
  danosFrota: string;
  valorDanos: number;
  descDanos: string;
  ordem: string;
  dtDigitacao?: string;
  culpabilidade: string;
  culpabilidadeLabel?: string;
  culpadoNome: string;
  numeroFor: string;
  valorFolha: number;
  valorSaldo: number;
  fonte: string;
  veiculos: VeiculoEnvolvido[];
  testemunhas: Testemunha[];
  vitimas: Vitima[];
  anexos: Anexo[];
}

export interface SinistroDetalheResponse extends RespostaBase {
  sinistro: Sinistro;
}

// Payload de criacao/atualizacao do cabecalho -- so os campos que a tela edita.
export interface SinistroPayload {
  numero?: string;
  data?: string;
  hora?: string;
  evento?: string;
  codBem?: string;      // codigo ST9 (ou "chaveBem" placa/serie na criacao)
  chaveBem?: string;
  placa?: string;
  gravidade?: string;
  tempo?: string;
  via?: string;
  periodo?: string;
  maoDirecao?: string;
  local?: string;
  cidade?: string;
  uf?: string;
  numeroBO?: string;
  nomeDP?: string;
  interrViagem?: string;
  necGuincho?: string;
  valorGuincho?: number;
  delitoConcret?: string;
  terceiroEvadiu?: string;
  status?: string;
  descricao?: string;
  danosFrota?: string;
  valorDanos?: number;
  descDanos?: string;
  culpabilidade?: string;
  culpadoNome?: string;
  numeroFor?: string;
  valorFolha?: number;
  valorSaldo?: number;
}

// ---------------------------------------------------------------------------
// Lookups
// ---------------------------------------------------------------------------
export interface BemLookupItem {
  codigo: string;
  nome: string;
  placa: string;
  serie: string;
  catbem: string;
  tipo: string;     // V=veiculo / E=equipamento
}

export interface FuncionarioLookupItem {
  matricula: string;
  nome: string;
  centroCusto: string;
}

export interface LookupResponse<T> extends RespostaBase {
  items: T[];
  hasNext?: boolean;
}

export interface DominioResponse extends RespostaBase {
  items: OpcaoDominio[];
}

// ---------------------------------------------------------------------------
// Importacao da planilha
// ---------------------------------------------------------------------------
export type AcaoImportacao = 'Criar' | 'Duplicada' | 'Erro' | 'Importada';

export interface LinhaImportacao {
  linha: number;
  numeroFor: string;
  dataTexto: string;
  data: string;
  chaveBem: string;
  codBem: string;
  nomeBem: string;
  placa: string;
  tipoBem: string;
  evento: string;
  eventoLabel: string;
  carroQuebec: string;
  condutorQuebec: string;
  matricula: string;
  cpfTerceiro: string;
  motoristaTerceiro: string;
  placaTerceiro: string;
  culpaTexto: string;
  culpabilidade: string;
  culpabilidadeLabel: string;
  culpadoNome: string;
  tst: string;
  valorTerceiro: number;
  valorFolha: number;
  valorSaldo: number;
  statusTexto: string;
  status: string;
  statusLabel: string;
  observacao: string;
  chaveImport: string;
  acao: AcaoImportacao;
  motivo: string;
  numero: string;
}

export interface ResumoImportacao {
  paraCriar: number;
  duplicadas: number;
  comErro: number;
  importadas: number;
}

export interface ErroImportacao {
  linha: number;
  numeroFor: string;
  placa: string;
  motivo: string;
}

export interface ImportacaoResponse extends RespostaBase {
  efetivado: boolean;
  totalLinhas: number;
  resumo: ResumoImportacao;
  linhas: LinhaImportacao[];
  erros: ErroImportacao[];
  numeros?: string[];
}

// ---------------------------------------------------------------------------
// Configuração / parametrização do dicionário (U_MNT540Tab)
// ---------------------------------------------------------------------------
export interface ParametrizacaoResponse extends RespostaBase {
  log: string[];
}
