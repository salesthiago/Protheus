import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import {
  ParametroApiResponse,
  ParametroDetalheResponse,
  ParametroListResponse,
  ParametroSalvarPayload,
  PermissaoResponse
} from '../models/parametro.model';
import { AdvplBridgeService } from './advpl-bridge.service';

// Canal AdvplToJs/JsToAdvpl via AdvplBridgeService, sem HttpClient/REST -- ver
// Static Function JsToAdvpl em Manutenção/Parametros.prw (Do Case com
// manutPermissao/manutListar/manutDetalhe/manutSalvar/manutExcluir).
@Injectable({ providedIn: 'root' })
export class ParametroService {
  constructor(private readonly advplBridge: AdvplBridgeService) {}

  permissao(): Observable<PermissaoResponse> {
    return this.advplBridge.call<PermissaoResponse>('manutPermissao', {});
  }

  listar(busca?: string): Observable<ParametroListResponse> {
    return this.advplBridge.call<ParametroListResponse>('manutListar', { busca: busca ?? '' });
  }

  obter(variavel: string): Observable<ParametroDetalheResponse> {
    return this.advplBridge.call<ParametroDetalheResponse>('manutDetalhe', { variavel });
  }

  salvar(payload: ParametroSalvarPayload): Observable<ParametroApiResponse> {
    return this.advplBridge.call<ParametroApiResponse>('manutSalvar', { ...payload });
  }

  excluir(variavel: string): Observable<ParametroApiResponse> {
    return this.advplBridge.call<ParametroApiResponse>('manutExcluir', { variavel });
  }
}
