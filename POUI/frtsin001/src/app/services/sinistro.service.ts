import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { AdvplBridgeService } from './advpl-bridge.service';
import {
  BemLookupItem,
  DominioResponse,
  FuncionarioLookupItem,
  ImportacaoResponse,
  LookupResponse,
  ParametrizacaoResponse,
  SinistroDetalheResponse,
  SinistroListFiltro,
  SinistroListResponse,
  SinistroPayload,
  Testemunha,
  VeiculoEnvolvido,
  Vitima
} from '../models/sinistro.model';

// Usa o canal AdvplToJs/JsToAdvpl via AdvplBridgeService -- ver Static Function JsToAdvpl em
// frotas/sinistro/MNTA540App.prw (Do Case com sinistroListar/Detalhe/Criar/Atualizar,
// veiculo*/testemunha*/vitima*, lookup*, sinistroImportar*). SEM HTTP/REST -- mesmo padrao
// de POUI/estmvc001 / POUI/rtm003.
@Injectable({ providedIn: 'root' })
export class SinistroService {
  constructor(private readonly advplBridge: AdvplBridgeService) {}

  listar(filtro: SinistroListFiltro = {}): Observable<SinistroListResponse> {
    return this.advplBridge.call<SinistroListResponse>('sinistroListar', {
      numero: filtro.numero ?? '',
      dataDe: filtro.dataDe ?? '',
      dataAte: filtro.dataAte ?? '',
      placa: filtro.placa ?? '',
      evento: filtro.evento ?? '',
      culpabilidade: filtro.culpabilidade ?? '',
      status: filtro.status ?? ''
    });
  }

  detalhe(numero: string): Observable<SinistroDetalheResponse> {
    return this.advplBridge.call<SinistroDetalheResponse>('sinistroDetalhe', { numero });
  }

  criar(
    sinistro: SinistroPayload,
    veiculos: Partial<VeiculoEnvolvido>[] = [],
    testemunhas: Partial<Testemunha>[] = [],
    vitimas: Partial<Vitima>[] = []
  ): Observable<SinistroDetalheResponse> {
    return this.advplBridge.call<SinistroDetalheResponse>('sinistroCriar', {
      sinistro,
      veiculos,
      testemunhas,
      vitimas
    });
  }

  atualizar(sinistro: SinistroPayload & { numero: string }): Observable<SinistroDetalheResponse> {
    return this.advplBridge.call<SinistroDetalheResponse>('sinistroAtualizar', { sinistro });
  }

  // ---- filhas ----
  salvarVeiculo(numero: string, veiculo: Partial<VeiculoEnvolvido>): Observable<SinistroDetalheResponse> {
    return this.advplBridge.call<SinistroDetalheResponse>('veiculoSalvar', { numero, veiculo });
  }

  removerVeiculo(numero: string, seq: string): Observable<SinistroDetalheResponse> {
    return this.advplBridge.call<SinistroDetalheResponse>('veiculoRemover', { numero, seq });
  }

  salvarTestemunha(numero: string, testemunha: Partial<Testemunha>): Observable<SinistroDetalheResponse> {
    return this.advplBridge.call<SinistroDetalheResponse>('testemunhaSalvar', { numero, testemunha });
  }

  removerTestemunha(numero: string, seq: string): Observable<SinistroDetalheResponse> {
    return this.advplBridge.call<SinistroDetalheResponse>('testemunhaRemover', { numero, seq });
  }

  salvarVitima(numero: string, vitima: Partial<Vitima>): Observable<SinistroDetalheResponse> {
    return this.advplBridge.call<SinistroDetalheResponse>('vitimaSalvar', { numero, vitima });
  }

  removerVitima(numero: string, seq: string): Observable<SinistroDetalheResponse> {
    return this.advplBridge.call<SinistroDetalheResponse>('vitimaRemover', { numero, seq });
  }

  // ---- lookups ----
  lookupBem(filtro: string): Observable<LookupResponse<BemLookupItem>> {
    return this.advplBridge.call<LookupResponse<BemLookupItem>>('lookupBem', { filtro });
  }

  lookupFuncionario(filtro: string): Observable<LookupResponse<FuncionarioLookupItem>> {
    return this.advplBridge.call<LookupResponse<FuncionarioLookupItem>>('lookupFuncionario', { filtro });
  }

  lookupDominio(dominio: string): Observable<DominioResponse> {
    return this.advplBridge.call<DominioResponse>('lookupDominio', { dominio });
  }

  // ---- importacao da planilha ----
  simularImportacao(conteudoBase64: string): Observable<ImportacaoResponse> {
    return this.advplBridge.call<ImportacaoResponse>('sinistroImportarSimular', { conteudoBase64 });
  }

  efetivarImportacao(conteudoBase64: string): Observable<ImportacaoResponse> {
    return this.advplBridge.call<ImportacaoResponse>('sinistroImportar', { conteudoBase64 });
  }

  // ---- configuracao ----
  // Executa U_MNT540Tab(.T.) no servidor -- cria os campos custom, a SX5 'SP' e a TRU.
  parametrizarDicionario(): Observable<ParametrizacaoResponse> {
    return this.advplBridge.call<ParametrizacaoResponse>('configParametrizar', {});
  }
}
