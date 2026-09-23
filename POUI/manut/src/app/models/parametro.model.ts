// Espelha a tabela SX6 (parametros do sistema) -- ver Static Function ZmnList/ZmnDet
// em Manutenção/Parametros.prw. 'variavel' e a chave (X6_VAR, ex: MV_XMANUT).
export interface ParametroItem {
  filial: string;
  variavel: string;
  tipo: string;
  conteudo: string;
  descricao: string;
}

export interface ParametroDetalhe extends ParametroItem {
  descricao1: string;
  descricao2: string;
  descricao3: string;
}

// Payload enviado ao salvar (inclusao ou alteracao) -- ver ZmnSalva em
// Manutenção/Parametros.prw. 'descricao1/2/3' sao opcionais (texto de ajuda).
export interface ParametroSalvarPayload {
  variavel: string;
  tipo: string;
  conteudo: string;
  descricao: string;
  descricao1?: string;
  descricao2?: string;
  descricao3?: string;
}

export interface PermissaoResponse {
  success: boolean;
  message?: string;
  usuario: string;
  autorizado: boolean;
}

export interface ParametroListResponse {
  success: boolean;
  message?: string;
  parametros: ParametroItem[];
}

export interface ParametroDetalheResponse extends ParametroDetalhe {
  success: boolean;
  message?: string;
}

export interface ParametroApiResponse {
  success: boolean;
  message?: string;
  variavel?: string;
}

// Tipos aceitos pelo parametro (X6_TIPO) traduzidos para o usuario leigo --
// nada de "C/N/D/L" na tela.
export const TIPOS_PARAMETRO: Array<{ value: string; label: string }> = [
  { value: 'C', label: 'Texto' },
  { value: 'N', label: 'Número' },
  { value: 'D', label: 'Data' },
  { value: 'L', label: 'Sim ou Não' }
];
