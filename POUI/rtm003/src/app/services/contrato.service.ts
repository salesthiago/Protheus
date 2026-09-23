import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import {
  CentroCustoLookupResponse,
  CondPagtoLookupResponse,
  ContratoAtualizarPayload,
  ContratoCriarPayload,
  ContratoDetalheResponse,
  ContratoListFiltro,
  ContratoListResponse,
  CronogramaPayload,
  DominiosPlanilhaResponse,
  FilialLookupResponse,
  IndiceLookupResponse,
  MoedaLookupResponse,
  NaturezaLookupResponse,
  PessoaLookupResponse,
  ProdutoLookupResponse,
  ProximoNumeroResponse,
  RevisaoAbrirPayload,
  SituacaoContrato,
  TesLookupResponse,
  TimelineResponse,
  TipoContrato,
  TipoContratoLookupResponse,
  TipoPlanilhaLookupResponse
} from '../models/contrato.model';
import { AdvplBridgeService } from './advpl-bridge.service';

// Usa o canal AdvplToJs/JsToAdvpl via AdvplBridgeService -- ver Static Function JsToAdvpl em
// Contratos/RTM003App.prw (Do Case com contratoListar/contratoDetalhe/contratoCriar/
// contratoAtualizar/contratoSituacao/contratoTimeline/revisaoAbrir/revisaoAprovar/lookup*).
@Injectable({ providedIn: 'root' })
export class ContratoService {
  constructor(private readonly advplBridge: AdvplBridgeService) {}

  listar(filtro: ContratoListFiltro = {}): Observable<ContratoListResponse> {
    return this.advplBridge.call<ContratoListResponse>('contratoListar', {
      tipo: filtro.tipo ?? '',
      situacao: filtro.situacao ?? '',
      numero: filtro.numero ?? '',
      filial: filtro.filial ?? '',
      dataInicioDe: filtro.dataInicioDe ?? '',
      dataInicioAte: filtro.dataInicioAte ?? ''
    });
  }

  detalhe(numero: string, revisao: string): Observable<ContratoDetalheResponse> {
    return this.advplBridge.call<ContratoDetalheResponse>('contratoDetalhe', { numero, revisao });
  }

  criar(payload: ContratoCriarPayload): Observable<ContratoDetalheResponse> {
    return this.advplBridge.call<ContratoDetalheResponse>('contratoCriar', { ...payload });
  }

  atualizar(payload: ContratoAtualizarPayload): Observable<ContratoDetalheResponse> {
    return this.advplBridge.call<ContratoDetalheResponse>('contratoAtualizar', { ...payload });
  }

  alterarSituacao(
    numero: string,
    revisao: string,
    novaSituacao: SituacaoContrato,
    observacao = ''
  ): Observable<ContratoDetalheResponse> {
    return this.advplBridge.call<ContratoDetalheResponse>('contratoSituacao', { numero, revisao, novaSituacao, observacao });
  }

  // Timeline do contrato (tabela ZLG) -- mesma fonte do relatorio PDF Contratos/RT69M003.prw.
  timeline(numero: string): Observable<TimelineResponse> {
    return this.advplBridge.call<TimelineResponse>('contratoTimeline', { numero });
  }

  revisaoAbrir(payload: RevisaoAbrirPayload): Observable<ContratoDetalheResponse> {
    return this.advplBridge.call<ContratoDetalheResponse>('revisaoAbrir', { ...payload });
  }

  revisaoAprovar(numero: string, revisao: string): Observable<ContratoDetalheResponse> {
    return this.advplBridge.call<ContratoDetalheResponse>('revisaoAprovar', { numero, revisao });
  }

  lookupPessoa(tipo: TipoContrato, filtro: string): Observable<PessoaLookupResponse> {
    return this.advplBridge.call<PessoaLookupResponse>('lookupPessoa', { tipo, filtro });
  }

  lookupTipoContrato(filtro: string): Observable<TipoContratoLookupResponse> {
    return this.advplBridge.call<TipoContratoLookupResponse>('lookupTipoContrato', { filtro });
  }

  lookupProduto(filtro: string): Observable<ProdutoLookupResponse> {
    return this.advplBridge.call<ProdutoLookupResponse>('lookupProduto', { filtro });
  }

  lookupCondPagto(filtro: string): Observable<CondPagtoLookupResponse> {
    return this.advplBridge.call<CondPagtoLookupResponse>('lookupCondPagto', { filtro });
  }

  lookupTipoPlanilha(filtro: string): Observable<TipoPlanilhaLookupResponse> {
    return this.advplBridge.call<TipoPlanilhaLookupResponse>('lookupTipoPlanilha', { filtro });
  }

  lookupTes(filtro: string): Observable<TesLookupResponse> {
    return this.advplBridge.call<TesLookupResponse>('lookupTES', { filtro });
  }

  lookupCentroCusto(filtro: string): Observable<CentroCustoLookupResponse> {
    return this.advplBridge.call<CentroCustoLookupResponse>('lookupCentroCusto', { filtro });
  }

  lookupNatureza(filtro: string): Observable<NaturezaLookupResponse> {
    return this.advplBridge.call<NaturezaLookupResponse>('lookupNatureza', { filtro });
  }

  lookupMoeda(): Observable<MoedaLookupResponse> {
    return this.advplBridge.call<MoedaLookupResponse>('lookupMoeda', {});
  }

  lookupIndice(): Observable<IndiceLookupResponse> {
    return this.advplBridge.call<IndiceLookupResponse>('lookupIndice', {});
  }

  dominiosPlanilha(): Observable<DominiosPlanilhaResponse> {
    return this.advplBridge.call<DominiosPlanilhaResponse>('dominiosPlanilha', {});
  }

  lookupFilial(): Observable<FilialLookupResponse> {
    return this.advplBridge.call<FilialLookupResponse>('lookupFilial', {});
  }

  sugerirProximoNumero(): Observable<ProximoNumeroResponse> {
    return this.advplBridge.call<ProximoNumeroResponse>('lookupProximoNumero', {});
  }

  gerarCronograma(payload: CronogramaPayload): Observable<ContratoDetalheResponse> {
    return this.advplBridge.call<ContratoDetalheResponse>('gerarCronograma', { ...payload });
  }
}
