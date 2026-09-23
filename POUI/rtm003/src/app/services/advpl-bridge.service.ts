import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { ProJsToAdvplService } from '@totvs/protheus-lib-core';

// Mesmo padrao de POUI/estmvc001, POUI/sct001 e POUI/rtm002: usa o canal AdvplToJs/JsToAdvpl
// (TWebEngine/TWebChannel) que o FwCallApp ja disponibiliza, em vez de HttpClient/REST.
// So usa ProJsToAdvplService (construtor vazio, sem dependencia de
// ProThemeService/ProAppConfigService -- aquela cadeia foi o que travou o boot do app em
// estmvc001 quando importamos ProAppConfigModule).
//
// Protocolo: o receiveId nao viaja automatico entre JS e ADVPL (a lib so ecoa o que for
// enviado em sendInfo.content) -- por isso embutimos o receiveId dentro do JSON de content,
// e o lado ADVPL precisa extrair e devolver via oWebChannel:AdvplToJs(receiveId, jsonResp).
// Companheiro no lado ADVPL: Static Function JsToAdvpl no .prw que abre este app via FWCallApp
// (ainda nao criado neste projeto -- ver Fase 2 do plano).
//
// IMPORTANTE: este bridge so funciona se public/assets/preload/advpltojs.js existir neste
// projeto e for incluido no build (ng build copia de public/ para dist/) -- sem ele, toda
// chamada abaixo fica pendurada para sempre, sem nenhum erro no console (ver nota registrada
// na migracao do sct001, 2026-08-07).
@Injectable({ providedIn: 'root' })
export class AdvplBridgeService {
  constructor(private readonly proJsToAdvplService: ProJsToAdvplService) {}

  call<T>(type: string, payload: Record<string, unknown> = {}): Observable<T> {
    const receiveId = `${type}-${Date.now()}-${Math.round(Math.random() * 1e6)}`;
    const content = JSON.stringify({ ...payload, receiveId });

    return this.proJsToAdvplService.buildObservable(
      ({ protheusResponse, subscriber }: { protheusResponse: string; subscriber: { next: (v: T) => void; error: (e: unknown) => void; complete: () => void } }) => {
        try {
          const parsed = JSON.parse(protheusResponse);
          if (parsed?.success === false) {
            subscriber.error(parsed);
          } else {
            subscriber.next(parsed as T);
          }
        } catch {
          subscriber.error({ success: false, message: 'Resposta invalida do ADVPL' });
        }
        subscriber.complete();
      },
      {
        autoDestruct: true,
        receiveId,
        sendInfo: { type, content }
      }
    );
  }
}
