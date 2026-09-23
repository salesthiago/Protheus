import { provideRouter, withHashLocation } from '@angular/router';

import { routes } from './app.routes';

import { ApplicationConfig, importProvidersFrom, provideZoneChangeDetection } from '@angular/core';
import { provideHttpClient } from '@angular/common/http';

import { PoHttpRequestModule } from '@po-ui/ng-components';

export const appConfig: ApplicationConfig = {
  providers: [
    // withHashLocation: o app roda embarcado no shell do TOTVS SmartClient WebApp (FWCallApp),
    // servido de um subcaminho que nao controlamos. Rotas por hash evitam depender do path
    // absoluto de montagem (mesmo padrao de estmvc001/sct001/rtm002/rtm003).
    provideRouter(routes, withHashLocation()),
    provideHttpClient(),
    importProvidersFrom([PoHttpRequestModule]),
    provideZoneChangeDetection({ eventCoalescing: true })
  ]
};
