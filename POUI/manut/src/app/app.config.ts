import { provideRouter, withHashLocation } from '@angular/router';

import { routes } from './app.routes';

import { ApplicationConfig, importProvidersFrom, provideZoneChangeDetection } from '@angular/core';
import { provideHttpClient, withInterceptorsFromDi } from '@angular/common/http';

import { PoHttpRequestModule } from '@po-ui/ng-components';

export const appConfig: ApplicationConfig = {
  providers: [
    // withHashLocation: o app roda embarcado no shell do TOTVS SmartClient WebApp (FWCallApp),
    // servido de um subcaminho que nao controlamos. Rotas por hash (#/pesagens) evitam depender
    // do path absoluto de montagem.
    provideRouter(routes, withHashLocation()),
    // Nao chamamos REST nenhum (tudo via AdvplBridgeService/TWebChannel), mas o proprio
    // PoHttpRequestModule/HttpClient e exigido internamente pelos componentes do PO-UI --
    // sem isso a tela fica em branco (mesma causa documentada em POUI/estmvc001/src/app/app.config.ts).
    provideHttpClient(withInterceptorsFromDi()),
    importProvidersFrom([PoHttpRequestModule]),
    provideZoneChangeDetection({ eventCoalescing: true })
  ]
};
