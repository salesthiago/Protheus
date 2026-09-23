import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import {
  BalancaListResponse,
  PesagemApiResponse,
  PesagemDetalheResponse,
  PesagemFiltro,
  PesagemListResponse,
  PesagemLookupResponse,
  PesagemNova,
  PesagemPesarResponse,
  PesagemPlacaDetalhe
} from '../models/pesagem.model';
import { AdvplBridgeService } from './advpl-bridge.service';

// Todos os metodos usam o canal AdvplToJs/JsToAdvpl (TWebEngine/TWebChannel) via
// AdvplBridgeService, sem HttpClient/REST -- ver Static Function JsToAdvpl em
// Aterro/balanca/QPES004.PRW (Do Case com pesListar/pesDetalhe/pesCriar/pesPesar/
// pesLookupProduto/pesLookupPlaca/pesPlacaDetalhe/pesImprimir/pesRelatorio).
@Injectable({ providedIn: 'root' })
export class PesagemService {
  constructor(private readonly advplBridge: AdvplBridgeService) {}

  list(filtro?: PesagemFiltro): Observable<PesagemListResponse> {
    return this.advplBridge.call<PesagemListResponse>('pesListar', {
      ticket: filtro?.ticket ?? '',
      cc: filtro?.cc ?? '',
      status: filtro?.status ?? '',
      placa: filtro?.placa ?? '',
      motorista: filtro?.motorista ?? '',
      produto: filtro?.produto ?? '',
      dataDe: filtro?.dataDe ?? '',
      dataAte: filtro?.dataAte ?? ''
    });
  }

  get(filial: string, ticket: string): Observable<PesagemDetalheResponse> {
    return this.advplBridge.call<PesagemDetalheResponse>('pesDetalhe', { filial, ticket });
  }

  // Salva so o cabecalho (sem pesar) -- fluxo alternativo a pesar() direto.
  create(pesagem: PesagemNova): Observable<PesagemApiResponse> {
    return this.advplBridge.call<PesagemApiResponse>('pesCriar', { ...pesagem });
  }

  // tipo '1' = Peso Entrada, '2' = Peso Saida. Sem 'filial'/'ticket' (pesagem ainda
  // nao salva), cria o registro agora com os dados de cabecalho (Partial porque o
  // formulario manda tudo, mas quem ja tem filial+ticket -- ex. a listagem -- so
  // precisa mandar esses dois, o backend ignora o resto quando o registro ja existe,
  // ver PesPesar em QPES004.PRW). 'pesoManual' e usado so no reenvio apos
  // balancaIndisponivel:true. 'balanca' e o codigo (DX5_CODIGO) escolhido pelo
  // usuario via BalancaSelecaoService -- quando vazio, o backend resolve a balanca
  // default sozinho (AGRX003E), mesmo comportamento de antes desse campo existir.
  pesar(
    tipo: '1' | '2',
    dados: Partial<PesagemNova> & { filial?: string; ticket?: string; pesoManual?: number; balanca?: string }
  ): Observable<PesagemPesarResponse> {
    return this.advplBridge.call<PesagemPesarResponse>('pesPesar', { tipo, ...dados });
  }

  // Lista as balancas cadastradas (DX5) para a escolha do usuario -- equivalente web
  // do F12 da OGA190Q nativa. Ver BalancaSelecaoService, que chama isto uma vez ao
  // carregar a tela de listagem.
  listarBalancas(): Observable<BalancaListResponse> {
    return this.advplBridge.call<BalancaListResponse>('pesListarBal', {});
  }

  imprimir(filial: string, ticket: string): Observable<PesagemApiResponse> {
    return this.advplBridge.call<PesagemApiResponse>('pesImprimir', { filial, ticket });
  }

  // Abre o relatorio nativo de pesagens (Aterro/balanca/QPES003.PRW, sintetico/
  // analitico por Centro de Custo e periodo) na sessao do SmartClient -- de la o
  // usuario exporta para Excel pelo PrintDialog do TReport, ja pronto (ver PesRelat
  // em QPES004.PRW).
  relatorio(): Observable<PesagemApiResponse> {
    return this.advplBridge.call<PesagemApiResponse>('pesRelatorio', {});
  }

  lookupProdutos(filtro?: string): Observable<PesagemLookupResponse> {
    return this.advplBridge.call<PesagemLookupResponse>('pesLookupProduto', { filtro: filtro ?? '' });
  }

  lookupPlacas(filtro?: string): Observable<PesagemLookupResponse> {
    return this.advplBridge.call<PesagemLookupResponse>('pesLookupPlaca', { filtro: filtro ?? '' });
  }

  placaDetalhe(placa: string): Observable<PesagemPlacaDetalhe> {
    return this.advplBridge.call<PesagemPlacaDetalhe>('pesPlacaDetalhe', { placa });
  }
}
