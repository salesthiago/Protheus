import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { Router } from '@angular/router';
import {
  PoButtonModule,
  PoContainerModule,
  PoNotificationService,
  PoPageModule,
  PoStepperModule,
  PoTableColumn,
  PoTableModule,
  PoWidgetModule
} from '@po-ui/ng-components';
import { ImportacaoResponse, LinhaImportacao } from '../../models/sinistro.model';
import { SinistroService } from '../../services/sinistro.service';

type Passo = 1 | 2 | 3;

@Component({
  selector: 'app-sinistro-import',
  standalone: true,
  imports: [
    CommonModule,
    PoButtonModule,
    PoTableModule,
    PoStepperModule,
    PoContainerModule,
    PoWidgetModule,
    PoPageModule
  ],
  templateUrl: './sinistro-import.component.html',
  styleUrl: './sinistro-import.component.css'
})
export class SinistroImportComponent {
  passo: Passo = 1;
  processando = false;

  nomeArquivo = '';
  conteudoBase64 = '';

  simulacao?: ImportacaoResponse;
  resultado?: ImportacaoResponse;

  readonly colunasLinhas: PoTableColumn[] = [
    { property: 'linha', label: '#', width: '60px' },
    { property: 'numeroFor', label: 'FOR', width: '70px' },
    { property: 'dataTexto', label: 'Data', width: '100px' },
    { property: 'chaveBem', label: 'Placa/Série', width: '110px' },
    { property: 'nomeBem', label: 'Bem' },
    { property: 'eventoLabel', label: 'Evento', width: '100px' },
    { property: 'condutorQuebec', label: 'Condutor Quebec' },
    { property: 'motoristaTerceiro', label: 'Motorista Terceiro' },
    { property: 'culpabilidadeLabel', label: 'Culpabilidade', width: '130px' },
    { property: 'valorTerceiro', label: 'Vlr. Terceiro', type: 'currency', format: 'BRL', width: '120px' },
    {
      property: 'acao',
      label: 'Ação',
      type: 'label',
      width: '110px',
      labels: [
        { value: 'Criar', color: 'color-11', label: 'Criar' },
        { value: 'Importada', color: 'color-10', label: 'Importada' },
        { value: 'Duplicada', color: 'color-08', label: 'Duplicada' },
        { value: 'Erro', color: 'color-07', label: 'Erro' }
      ]
    },
    { property: 'motivo', label: 'Motivo' }
  ];

  readonly colunasErros: PoTableColumn[] = [
    { property: 'linha', label: '#', width: '60px' },
    { property: 'numeroFor', label: 'FOR', width: '70px' },
    { property: 'placa', label: 'Placa/Série', width: '130px' },
    { property: 'motivo', label: 'Motivo' }
  ];

  constructor(
    private readonly router: Router,
    private readonly sinistroService: SinistroService,
    private readonly poNotification: PoNotificationService
  ) {}

  get linhasSimulacao(): LinhaImportacao[] {
    return this.simulacao?.linhas ?? [];
  }

  aoSelecionarArquivo(evento: Event): void {
    const input = evento.target as HTMLInputElement;
    const arquivo = input.files?.[0];
    if (!arquivo) {
      return;
    }
    this.nomeArquivo = arquivo.name;
    const reader = new FileReader();
    reader.onload = () => {
      const resultado = String(reader.result ?? '');
      // "data:text/csv;base64,XXXX" -> XXXX  (bytes CP1252 originais preservados)
      this.conteudoBase64 = resultado.includes(',') ? resultado.split(',')[1] : resultado;
    };
    reader.onerror = () => this.poNotification.error('Não foi possível ler o arquivo.');
    reader.readAsDataURL(arquivo);
  }

  simular(): void {
    if (!this.conteudoBase64) {
      this.poNotification.warning('Selecione o arquivo CSV.');
      return;
    }
    this.processando = true;
    this.sinistroService.simularImportacao(this.conteudoBase64).subscribe({
      next: resp => {
        this.processando = false;
        this.simulacao = resp;
        this.passo = 2;
      },
      error: resp => {
        this.processando = false;
        this.poNotification.error(resp?.message ?? 'Falha ao simular a importação.');
      }
    });
  }

  efetivar(): void {
    if (!this.simulacao || this.simulacao.resumo.paraCriar === 0) {
      this.poNotification.warning('Não há linhas para importar.');
      return;
    }
    this.processando = true;
    this.sinistroService.efetivarImportacao(this.conteudoBase64).subscribe({
      next: resp => {
        this.processando = false;
        this.resultado = resp;
        this.passo = 3;
        this.poNotification.success(`${resp.resumo.importadas} sinistro(s) importado(s).`);
      },
      error: resp => {
        this.processando = false;
        this.poNotification.error(resp?.message ?? 'Falha ao efetivar a importação.');
      }
    });
  }

  voltarParaArquivo(): void {
    this.passo = 1;
    this.simulacao = undefined;
  }

  concluir(): void {
    this.router.navigate(['sinistros']);
  }
}
