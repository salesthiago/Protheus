// Espelha os campos exibidos no ticket impresso (Aterro/balanca/Aparecida/QPES001.PRW),
// tabela NJH. 'filial' e 'ticket' juntos sao a chave (NJH_CODPAV e numerado por filial,
// nao e globalmente unico -- ver Aterro/balanca/Aparecida/FNEXTID.PRW).
export interface PesagemListItem {
  filial: string;
  ticket: string;
  cc: string;
  data: string;
  placa: string;
  motorista: string;
  produto: string;
  peso1: number;
  peso2: number;
  pesoLiq: number;
  status: string;
}

export interface PesagemDetalhe {
  filial: string;
  ticket: string;
  cc: string;
  data: string;
  placa: string;
  motorista: string;
  codPro: string;
  desPro: string;
  rota: string;
  cliente: string;
  fornecedor: string;
  peso1: number;
  dataEnt: string;
  horaEnt: string;
  peso2: number;
  dataSai: string;
  horaSai: string;
  pesoLiq: number;
  obs: string;
  status: string;
  operador: string;
}

// Payload de inclusao -- somente os campos do formulario (a numeracao do ticket, a
// filial, o operador e o status sao calculados no ADVPL, ver PesNovo em QPES004.PRW).
// Sem 'cc' (Centro de Custo) -- removido a pedido do usuario, nao e mais obrigatorio
// nesta tela, e preenchido em outro momento. Sem peso1/peso2 -- pesagem agora e via
// captura na balanca (ver PesagemService.pesar()), nao mais digitada no formulario.
export interface PesagemNova {
  placa: string;
  motorista: string;
  codPro: string;
  desPro: string;
  umPro?: string;
  rota?: string;
  codEnt?: string;
  lojEnt?: string;
  cliente?: string;
  fornecedor?: string;
  obs?: string;
}

// Dados do veiculo (DA3) devolvidos ao selecionar uma Placa -- preenche o resto do
// formulario automaticamente (ver PesPlDet em QPES004.PRW).
export interface PesagemPlacaDetalhe {
  success: boolean;
  message?: string;
  motorista: string;
  rota: string;
  codPro: string;
  desPro: string;
  umPro: string;
  codEnt: string;
  lojEnt: string;
  cliente: string;
  fornecedor: string;
  obs: string;
}

// Resposta de PesPesar -- 'balancaIndisponivel' sinaliza que a balanca nao foi
// detectada/nao esta em modo automatico; o front deve liberar digitacao manual do
// peso e reenviar a mesma chamada com 'pesoManual' preenchido.
export interface PesagemPesarResponse {
  success: boolean;
  message?: string;
  balancaIndisponivel?: boolean;
  ticket?: string;
  filial?: string;
  peso?: number;
  pesoLiq?: number;
  status?: string;
  modo?: string;
}

export interface PesagemFiltro {
  ticket?: string;
  cc?: string;
  status?: string;
  placa?: string;
  motorista?: string;
  produto?: string;
  dataDe?: string;
  dataAte?: string;
}

export interface PesagemListResponse {
  success: boolean;
  items: PesagemListItem[];
  message?: string;
}

export interface PesagemDetalheResponse extends PesagemDetalhe {
  success: boolean;
  message?: string;
}

export interface PesagemApiResponse {
  success: boolean;
  message?: string;
  ticket?: string;
}

export interface PesagemLookupItem {
  value: string;
  label: string;
  um?: string;
}

export interface PesagemLookupResponse {
  success: boolean;
  items: PesagemLookupItem[];
  hasNext: boolean;
}

// Balanca cadastrada (DX5) que o usuario pode escolher para capturar o peso --
// equivalente web da selecao por F12 na OGA190Q nativa (ver PesLstBl em
// Aterro/balanca/QPES004.PRW).
export interface BalancaItem {
  value: string;
  label: string;
}

export interface BalancaListResponse {
  success: boolean;
  message?: string;
  balancas: BalancaItem[];
}

// Centros de Custo conhecidos (NJH_XCLVL) -- mesmo mapeamento usado em
// Aterro/balanca/QPES003.PRW::xDescCC3.
export const CENTROS_CUSTO: Array<{ value: string; label: string }> = [
  { value: '0102', label: 'Aparecida de Goiania' },
  { value: '0121', label: 'Trindade' },
  { value: '0606', label: 'Paracatu' },
  { value: '9001', label: 'Ituiutaba' }
];

// Status NJH_STATUS -- mesmo dominio do OGA190Q (AddLegend) e da regra de negocio
// registrada em memoria (Finalizado = status '2', Cancelado = '4', demais = incompleto).
export const STATUS_PESAGEM: Array<{ value: string; label: string; color: string }> = [
  { value: '0', label: 'Sem Pesagem', color: 'color-07' },
  { value: '1', label: 'Primeira Pesagem', color: 'color-08' },
  { value: '2', label: 'Segunda Pesagem', color: 'color-11' },
  { value: '3', label: 'Finalizada', color: 'color-03' },
  { value: '4', label: 'Cancelada', color: 'color-10' }
];
