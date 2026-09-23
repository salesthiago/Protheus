import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { MonitorListResponse } from '../models/monitor.model';
import { AdvplBridgeService } from './advpl-bridge.service';

// Usa o canal AdvplToJs/JsToAdvpl (TWebEngine/TWebChannel) via AdvplBridgeService, sem
// HttpClient/REST -- ver Static Function JsToAdvpl em Aterro/Relatorios/NJHMON01.PRW
// (Do Case com o unico tipo usado aqui, 'monListar').
@Injectable({ providedIn: 'root' })
export class MonitorService {
  constructor(private readonly advplBridge: AdvplBridgeService) {}

  listar(): Observable<MonitorListResponse> {
    return this.advplBridge.call<MonitorListResponse>('monListar', {});
  }
}
