import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import {
  CabecalhoContratoResponse,
  ContratoPosicionadoResponse,
  ExportarContratoRequest,
  ExportarContratoResponse,
  GerarMedicaoRequest,
  GerarMedicaoResponse,
  ItemValidacaoLimite,
  ItensPlanilhaResponse,
  ListarCronogramaResponse,
  ListarPlanilhasResponse,
  TesLookupResponse,
  ValidarLimiteResponse
} from '../models/importacao.model';
import { AdvplBridgeService } from './advpl-bridge.service';

// Usa o canal AdvplToJs/JsToAdvpl via AdvplBridgeService -- ver Static Function JsToAdvpl em
// Contratos/RTM002App.prw (Do Case com cabecalhoContrato/lookupTES/validarLimite/gerarMedicao/
// listarPlanilhas/exportarContrato).
@Injectable({ providedIn: 'root' })
export class MedicaoService {
  constructor(private readonly advplBridge: AdvplBridgeService) {}

  cabecalhoContrato(numContrato: string, revisao: string): Observable<CabecalhoContratoResponse> {
    return this.advplBridge.call<CabecalhoContratoResponse>('cabecalhoContrato', {
      cNumCont: numContrato,
      cRevisao: revisao
    });
  }

  lookupTes(filtro: string): Observable<TesLookupResponse> {
    return this.advplBridge.call<TesLookupResponse>('lookupTES', { cFiltro: filtro });
  }

  validarLimite(
    numContrato: string,
    revisao: string,
    competencia: string,
    itens: ItemValidacaoLimite[]
  ): Observable<ValidarLimiteResponse> {
    return this.advplBridge.call<ValidarLimiteResponse>('validarLimite', {
      cNumCont: numContrato,
      cRevisao: revisao,
      cCompet: competencia,
      itens
    });
  }

  gerarMedicao(payload: GerarMedicaoRequest): Observable<GerarMedicaoResponse> {
    return this.advplBridge.call<GerarMedicaoResponse>('gerarMedicao', payload as unknown as Record<string, unknown>);
  }

  listarPlanilhas(
    numContrato: string,
    revisao: string,
    codigoPessoa = '',
    lojaPessoa = ''
  ): Observable<ListarPlanilhasResponse> {
    return this.advplBridge.call<ListarPlanilhasResponse>('listarPlanilhas', {
      cNumCont: numContrato,
      cRevisao: revisao,
      cCodigoPessoa: codigoPessoa,
      cLojaPessoa: lojaPessoa
    });
  }

  exportarContrato(payload: ExportarContratoRequest): Observable<ExportarContratoResponse> {
    return this.advplBridge.call<ExportarContratoResponse>('exportarContrato', payload as unknown as Record<string, unknown>);
  }

  listarCronograma(numContrato: string, revisao: string, planilhas: string[]): Observable<ListarCronogramaResponse> {
    return this.advplBridge.call<ListarCronogramaResponse>('listarCronograma', {
      cNumCont: numContrato,
      cRevisao: revisao,
      aPlanilhas: planilhas
    });
  }

  contratoPosicionado(): Observable<ContratoPosicionadoResponse> {
    return this.advplBridge.call<ContratoPosicionadoResponse>('contratoPosicionado', {});
  }

  itensPlanilha(numContrato: string, revisao: string, planilhas: string[]): Observable<ItensPlanilhaResponse> {
    return this.advplBridge.call<ItensPlanilhaResponse>('itensPlanilha', {
      cNumCont: numContrato,
      cRevisao: revisao,
      aPlanilhas: planilhas
    });
  }
}
