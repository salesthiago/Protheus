import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { ProJsToAdvplService } from '@totvs/protheus-lib-core';

// Canal AdvplToJs/JsToAdvpl (TWebEngine) que o FwCallApp disponibiliza -- sem HttpClient/REST,
// conforme padrao adotado no projeto (ver POUI/estmvc001/src/app/services/advpl-bridge.service.ts).
// So usa ProJsToAdvplService (construtor vazio, sem dependencia de ProThemeService/
// ProAppConfigService -- aquela cadeia trava o boot do app quando importamos ProAppConfigModule).
//
// Protocolo: o receiveId nao viaja automatico entre JS e ADVPL (a lib so ecoa o que for
// enviado em sendInfo.content) -- por isso embutimos o receiveId dentro do JSON de content,
// e o lado ADVPL precisa extrair e devolver via oWebChannel:AdvplToJs(receiveId, jsonResp).
// Companheiro no lado ADVPL: Static Function JsToAdvpl em Aterro/Relatorios/NJHMON01.PRW.
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
