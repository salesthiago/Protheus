import { Injectable } from '@angular/core';

// Objetos globais injetados pelo Smart Client quando o app roda embarcado via FwCallApp.
// Nao ha tipagem oficial (nao usamos o pacote @totvs/protheus-lib-core inteiro so por
// causa disso); replicamos apenas o metodo jsToAdvpl que a lib usa por baixo dos panos.
// Mesmo arquivo de POUI/estmvc001, POUI/sct001 e POUI/rtm002.
declare const dialog: { jsToAdvpl?: (type: string, content: string) => void } | undefined;
declare const twebchannel: { jsToAdvpl?: (type: string, content: string) => void } | undefined;

@Injectable({ providedIn: 'root' })
export class ProtheusBridgeService {
  private getChannel(): { jsToAdvpl?: (type: string, content: string) => void } | undefined {
    if (typeof twebchannel !== 'undefined' && typeof twebchannel?.jsToAdvpl === 'function') {
      return twebchannel;
    }
    if (typeof dialog !== 'undefined' && typeof dialog?.jsToAdvpl === 'function') {
      return dialog;
    }
    return undefined;
  }

  insideProtheus(): boolean {
    return this.getChannel() !== undefined;
  }

  fecharApp(): void {
    const channel = this.getChannel();
    if (channel?.jsToAdvpl) {
      channel.jsToAdvpl('close', 'force');
    } else {
      window.close();
    }
  }
}
