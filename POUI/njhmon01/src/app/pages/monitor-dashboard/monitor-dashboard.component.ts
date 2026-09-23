import { Component, OnDestroy, OnInit } from '@angular/core';
import { PoPageAction, PoPageModule, PoWidgetModule } from '@po-ui/ng-components';
import { Subscription, interval } from 'rxjs';
import { MonitorCard } from '../../models/monitor.model';
import { MonitorService } from '../../services/monitor.service';

// Card fica destacado quando o ultimo lancamento (pesagem) do Centro de Custo
// passa desse limite -- mesmo criterio calculado no ADVPL (ver MonList em
// Aterro/Relatorios/NJHMON01.PRW), replicado aqui so para nao depender so do
// campo 'atrasado' quando o card fica muito tempo na tela sem um novo refresh.
const LIMITE_HORAS_ATRASO = 24;

// Intervalo de atualizacao automatica da tela (monitor fica aberto na parede/TV,
// sem interacao do usuario -- precisa se atualizar sozinho).
const INTERVALO_REFRESH_MS = 60000;

@Component({
  selector: 'app-monitor-dashboard',
  standalone: true,
  imports: [PoPageModule, PoWidgetModule],
  templateUrl: './monitor-dashboard.component.html',
  styleUrl: './monitor-dashboard.component.css'
})
export class MonitorDashboardComponent implements OnInit, OnDestroy {
  items: MonitorCard[] = [];
  loading = false;
  erro = '';
  geradoEm = '';
  atualizadoEm = '';

  pageActions: Array<PoPageAction> = [
    { label: 'Atualizar', icon: 'an an-arrows-clockwise', action: () => this.carregar() }
  ];

  private refreshSub?: Subscription;

  constructor(private readonly monitorService: MonitorService) {}

  ngOnInit(): void {
    this.carregar();
    this.refreshSub = interval(INTERVALO_REFRESH_MS).subscribe(() => this.carregar());
  }

  ngOnDestroy(): void {
    this.refreshSub?.unsubscribe();
  }

  carregar(): void {
    this.loading = true;
    this.erro = '';

    this.monitorService.listar().subscribe({
      next: resp => {
        this.items = resp.items ?? [];
        this.geradoEm = resp.geradoEm ?? '';
        this.atualizadoEm = new Date().toLocaleTimeString('pt-BR');
        this.loading = false;
      },
      error: err => {
        this.erro = err?.message ?? 'Nao foi possivel carregar o monitor.';
        this.loading = false;
      }
    });
  }

  atrasado(item: MonitorCard): boolean {
    return item.atrasado || item.horasDecorridas > LIMITE_HORAS_ATRASO;
  }
}
