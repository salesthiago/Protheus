import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { Router } from '@angular/router';
import {
  PoButtonModule,
  PoDialogService,
  PoNotificationService,
  PoPageModule,
  PoWidgetModule
} from '@po-ui/ng-components';
import { SinistroService } from '../../services/sinistro.service';

@Component({
  selector: 'app-sinistro-config',
  standalone: true,
  imports: [CommonModule, PoPageModule, PoWidgetModule, PoButtonModule],
  templateUrl: './sinistro-config.component.html',
  styleUrl: './sinistro-config.component.css'
})
export class SinistroConfigComponent {
  processando = false;
  concluido = false;
  log: string[] = [];

  constructor(
    private readonly router: Router,
    private readonly sinistroService: SinistroService,
    private readonly poDialog: PoDialogService,
    private readonly poNotification: PoNotificationService
  ) {}

  get logTexto(): string {
    return this.log.join('\n');
  }

  confirmarParametrizacao(): void {
    this.poDialog.confirm({
      title: 'Parametrizar Dicionário',
      message:
        'Isto vai criar/atualizar os campos de usuário (TRH_Z*, TRO_Z*, TRI_Z*), ' +
        'os status do processo (SX5 "SP") e os tipos de anexo (TRU). ' +
        'A operação é idempotente — o que já existe é ignorado. Executar agora?',
      confirm: () => this.executar(),
      cancel: () => undefined
    });
  }

  private executar(): void {
    this.processando = true;
    this.concluido = false;
    this.log = [];
    this.sinistroService.parametrizarDicionario().subscribe({
      next: resp => {
        this.processando = false;
        this.concluido = true;
        this.log = resp.log ?? [];
        this.poNotification.success(resp.message ?? 'Parametrização concluída.');
      },
      error: resp => {
        this.processando = false;
        this.log = resp?.log ?? [];
        this.poNotification.error(resp?.message ?? 'Falha ao executar a parametrização.');
      }
    });
  }

  voltar(): void {
    this.router.navigate(['sinistros']);
  }
}
