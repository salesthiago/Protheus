import { CommonModule } from '@angular/common';
import { Component, OnInit, ViewChild } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import {
  PoButtonModule,
  PoFieldModule,
  PoModalComponent,
  PoModalModule,
  PoNotificationService,
  PoPageFilter,
  PoPageModule,
  PoSelectOption,
  PoTableColumn,
  PoTableModule
} from '@po-ui/ng-components';
import {
  CULPA_OPTIONS,
  EVENTO_OPTIONS,
  SinistroResumo
} from '../../models/sinistro.model';
import { SinistroService } from '../../services/sinistro.service';

@Component({
  selector: 'app-sinistro-list',
  standalone: true,
  imports: [CommonModule, FormsModule, PoPageModule, PoTableModule, PoButtonModule, PoModalModule, PoFieldModule],
  templateUrl: './sinistro-list.component.html',
  styleUrl: './sinistro-list.component.css'
})
export class SinistroListComponent implements OnInit {
  @ViewChild('modalBuscaAvancada') modalBuscaAvancada!: PoModalComponent;

  readonly eventoOptions: PoSelectOption[] = [
    { value: '', label: 'Todos' },
    ...EVENTO_OPTIONS.map(o => ({ value: o.value, label: o.label }))
  ];

  readonly culpaOptions: PoSelectOption[] = [
    { value: '', label: 'Todas' },
    ...CULPA_OPTIONS.map(o => ({ value: o.value, label: o.label }))
  ];

  statusOptions: PoSelectOption[] = [{ value: '', label: 'Todos' }];

  readonly filtroPagina: PoPageFilter = {
    placeholder: 'Buscar por número do sinistro',
    action: (valor: string) => this.buscarPorNumero(valor),
    advancedAction: () => this.modalBuscaAvancada.open()
  };

  readonly colunas: PoTableColumn[] = [
    { property: 'numero', label: 'Número', width: '90px' },
    { property: 'data', label: 'Data', type: 'date', width: '110px' },
    { property: 'eventoLabel', label: 'Evento', width: '110px' },
    { property: 'placa', label: 'Placa', width: '100px' },
    { property: 'nomeBem', label: 'Bem' },
    { property: 'gravidadeLabel', label: 'Gravidade', width: '110px' },
    { property: 'culpabilidadeLabel', label: 'Culpabilidade', width: '140px' },
    { property: 'statusLabel', label: 'Status', width: '150px' },
    {
      property: 'fonte',
      label: 'Origem',
      width: '90px',
      type: 'label',
      labels: [
        { value: 'I', color: 'color-08', label: 'Importado' },
        { value: 'M', color: 'color-11', label: 'Manual' }
      ]
    }
  ];

  filtroNumero = '';
  filtroPlaca = '';
  filtroEvento = '';
  filtroCulpa = '';
  filtroStatus = '';
  filtroDataDe = '';
  filtroDataAte = '';
  carregando = false;
  sinistros: SinistroResumo[] = [];

  constructor(
    private readonly router: Router,
    private readonly sinistroService: SinistroService,
    private readonly poNotification: PoNotificationService
  ) {}

  ngOnInit(): void {
    this.carregar();
    this.sinistroService.lookupDominio('status').subscribe({
      next: resp => {
        this.statusOptions = [
          { value: '', label: 'Todos' },
          ...resp.items.map(i => ({ value: i.value, label: `${i.value} - ${i.label}` }))
        ];
      },
      error: () => (this.statusOptions = [{ value: '', label: 'Todos' }])
    });
  }

  carregar(): void {
    this.carregando = true;
    this.sinistroService
      .listar({
        numero: this.filtroNumero,
        placa: this.filtroPlaca,
        evento: this.filtroEvento,
        culpabilidade: this.filtroCulpa,
        status: this.filtroStatus,
        dataDe: this.filtroDataDe,
        dataAte: this.filtroDataAte
      })
      .subscribe({
        next: resp => {
          this.carregando = false;
          this.sinistros = resp.sinistros ?? [];
        },
        error: resp => {
          this.carregando = false;
          this.poNotification.error(resp?.message ?? 'Falha ao consultar sinistros.');
        }
      });
  }

  buscarPorNumero(valor: string): void {
    this.filtroNumero = valor ?? '';
    this.carregar();
  }

  aplicarBuscaAvancada(): void {
    this.modalBuscaAvancada.close();
    this.carregar();
  }

  limparBuscaAvancada(): void {
    this.filtroPlaca = '';
    this.filtroEvento = '';
    this.filtroCulpa = '';
    this.filtroStatus = '';
    this.filtroDataDe = '';
    this.filtroDataAte = '';
    this.modalBuscaAvancada.close();
    this.carregar();
  }

  novo(): void {
    this.router.navigate(['sinistros', 'novo']);
  }

  importar(): void {
    this.router.navigate(['sinistros', 'importar']);
  }

  configuracao(): void {
    this.router.navigate(['sinistros', 'configuracao']);
  }

  abrir(sinistro: SinistroResumo): void {
    this.router.navigate(['sinistros', sinistro.numero]);
  }
}
