// Espelha o item devolvido por MonList (Aterro/Relatorios/NJHMON01.PRW): o registro
// mais recente encontrado na NJH para cada Centro de Custo (NJH_XCLVL) da filial matriz.
export interface MonitorCard {
  cc: string;
  descricao: string;
  ultimoTicket: string;
  // Data/hora da ultima pesagem (Segunda Pesagem > Primeira Pesagem > abertura do
  // ticket sem pesagem nenhuma, nessa ordem de prioridade -- ver MonList no ADVPL).
  data: string;
  hora: string;
  horasDecorridas: number;
  // true quando ha mais de 24h desde a ultima pesagem -- card deve se destacar.
  atrasado: boolean;
}

export interface MonitorListResponse {
  success: boolean;
  message?: string;
  items: MonitorCard[];
  geradoEm: string;
}
