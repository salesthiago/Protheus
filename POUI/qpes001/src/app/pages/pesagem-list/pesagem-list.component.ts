import { Component, HostListener, OnInit, ViewChild } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import {
  PoFieldModule,
  PoModalAction,
  PoModalComponent,
  PoModalModule,
  PoNotificationService,
  PoPageAction,
  PoPageFilter,
  PoPageModule,
  PoSelectOption,
  PoTableAction,
  PoTableColumn,
  PoTableModule
} from '@po-ui/ng-components';
import { CENTROS_CUSTO, PesagemFiltro, PesagemListItem, PesagemPesarResponse, STATUS_PESAGEM } from '../../models/pesagem.model';
import { BalancaSelecaoService } from '../../services/balanca-selecao.service';
import { PesagemService } from '../../services/pesagem.service';
import { ProtheusBridgeService } from '../../services/protheus-bridge.service';

type TipoPeso = '1' | '2';

// Linha da tabela com o rotulo de Centro de Custo ja resolvido -- o backend devolve
// so o codigo (NJH_XCLVL), a traducao pro nome da unidade e feita aqui no front com o
// mesmo mapa usado em Aterro/balanca/QPES003.PRW::xDescCC3.
interface PesagemRow extends PesagemListItem {
  ccLabel: string;
}

@Component({
  selector: 'app-pesagem-list',
  standalone: true,
  imports: [PoPageModule, PoTableModule, PoFieldModule, PoModalModule, FormsModule],
  templateUrl: './pesagem-list.component.html',
  styleUrl: './pesagem-list.component.css'
})
export class PesagemListComponent implements OnInit {
  @ViewChild('modalFiltro', { static: true }) modalFiltro!: PoModalComponent;
  @ViewChild('modalBalanca', { static: true }) modalBalanca!: PoModalComponent;

  // Selecao dentro da modal, antes de confirmar (ver escolherBalanca()).
  balancaEscolhida = '';

  items: Array<PesagemRow> = [];
  loading = false;

  // Linha marcada via seleção do po-table (clique na linha) -- usada pelo atalho F10
  // pra saber em qual pesagem agir, igual ao F10 da OGA190Q nativa (que agia sobre o
  // registro destacado no browse).
  linhaSelecionada: PesagemRow | null = null;
  pesandoLinha = false;

  // filtro: em edicao dentro da modal. filtroAtual: ultimo filtro aplicado (usado em carregar()).
  filtro: PesagemFiltro = {};
  filtroAtual: PesagemFiltro = {};

  // po-datepicker trabalha com Date, o backend espera string 'AAAA-MM-DD' (ver
  // formatarData()) -- por isso ficam fora do objeto 'filtro' que e enviado ao service.
  filtroDataDe: Date | null = null;
  filtroDataAte: Date | null = null;

  readonly ccOptions: Array<PoSelectOption> = [{ label: 'Todos', value: '' }, ...CENTROS_CUSTO];
  readonly statusOptions: Array<PoSelectOption> = [{ label: 'Todos', value: '' }, ...STATUS_PESAGEM];

  readonly columns: Array<PoTableColumn> = [
    { property: 'ticket', label: 'Ticket', type: 'string', width: '10%' },
    { property: 'ccLabel', label: 'Unidade', type: 'string', width: '14%' },
    { property: 'data', label: 'Data', type: 'string', width: '9%' },
    { property: 'placa', label: 'Placa', type: 'string', width: '9%' },
    { property: 'motorista', label: 'Motorista', type: 'string' },
    { property: 'produto', label: 'Produto', type: 'string' },
    { property: 'peso1', label: 'Peso Entrada', type: 'number', width: '10%' },
    { property: 'peso2', label: 'Peso Saída', type: 'number', width: '10%' },
    { property: 'pesoLiq', label: 'Peso Líquido', type: 'number', width: '10%' },
    {
      property: 'status',
      label: 'Status',
      type: 'label',
      width: '12%',
      labels: STATUS_PESAGEM.map(({ value, label, color }) => ({ value, label, color }))
    }
  ];

  readonly tableActions: Array<PoTableAction> = [
    { label: 'Visualizar', action: (row: PesagemRow) => this.visualizar(row) },
    {
      label: 'Pesar Entrada',
      icon: 'an an-scales',
      visible: (row: PesagemRow) => this.podePesar(row, '1'),
      action: (row: PesagemRow) => this.pesarLinha(row, '1')
    },
    {
      label: 'Pesar Saída',
      icon: 'an an-scales',
      visible: (row: PesagemRow) => this.podePesar(row, '2'),
      action: (row: PesagemRow) => this.pesarLinha(row, '2')
    },
    { label: 'Imprimir Ticket', action: (row: PesagemRow) => this.imprimir(row), separator: true }
  ];

  readonly pageActions: Array<PoPageAction> = [
    { label: 'Incluir', icon: 'an an-plus', action: () => this.incluir() },
    { label: 'Relatório', icon: 'an an-file-xls', action: () => this.relatorio() },
    { label: 'Fechar', icon: 'an an-x', action: () => this.fechar() }
  ];

  readonly filter: PoPageFilter = {
    placeholder: 'Pesquisar por Ticket',
    action: (value: string) => this.pesquisar(value),
    advancedAction: () => this.abrirFiltroAvancado()
  };

  readonly filtroPrimaryAction: PoModalAction = {
    label: 'Filtrar',
    action: () => this.aplicarFiltroAvancado()
  };

  readonly filtroSecondaryAction: PoModalAction = {
    label: 'Limpar',
    action: () => this.limparFiltroAvancado()
  };

  // Sem acao secundaria (cancelar/fechar) de proposito -- havendo mais de uma
  // balanca ativa, a escolha e obrigatoria antes de pesar, mesmo criterio pedido
  // pelo usuario pra reproduzir o F12 da tela nativa, so que ao carregar a pagina
  // em vez de por atalho de teclado.
  // Nao e 'readonly' porque 'disabled' e alternado em onBalancaChange() conforme o
  // usuario escolhe uma opcao na modal.
  balancaPrimaryAction: PoModalAction = {
    label: 'Confirmar',
    disabled: true,
    action: () => this.escolherBalanca()
  };

  constructor(
    private readonly pesagemService: PesagemService,
    private readonly router: Router,
    private readonly poNotification: PoNotificationService,
    private readonly protheusBridge: ProtheusBridgeService,
    readonly balancaSelecao: BalancaSelecaoService
  ) {}

  ngOnInit(): void {
    this.carregar();
    this.balancaSelecao.carregar(() => {
      if (this.balancaSelecao.precisaEscolher) {
        this.modalBalanca.open();
      }
    });
  }

  onBalancaChange(codigo: string): void {
    this.balancaEscolhida = codigo;
    this.balancaPrimaryAction.disabled = !codigo;
  }

  escolherBalanca(): void {
    if (!this.balancaEscolhida) {
      return;
    }
    this.balancaSelecao.selecionar(this.balancaEscolhida);
    this.modalBalanca.close();
  }

  carregar(): void {
    this.loading = true;

    this.pesagemService.list(this.filtroAtual).subscribe({
      next: response => {
        this.items = (response.items ?? []).map(item => ({ ...item, ccLabel: this.descCC(item.cc) }));
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.poNotification.error('Erro ao carregar a listagem de pesagens.');
      }
    });
  }

  abrirFiltroAvancado(): void {
    this.filtro = { ...this.filtroAtual };
    this.modalFiltro.open();
  }

  aplicarFiltroAvancado(): void {
    if (this.filtroDataDe && this.filtroDataAte && this.filtroDataDe > this.filtroDataAte) {
      this.poNotification.warning('No período, a Data De não pode ser maior que a Data Até.');
      return;
    }

    this.filtroAtual = {
      ...this.filtro,
      dataDe: this.formatarData(this.filtroDataDe),
      dataAte: this.formatarData(this.filtroDataAte)
    };
    this.modalFiltro.close();
    this.carregar();
  }

  limparFiltroAvancado(): void {
    this.filtro = {};
    this.filtroAtual = {};
    this.filtroDataDe = null;
    this.filtroDataAte = null;
    this.modalFiltro.close();
    this.carregar();
  }

  private formatarData(data: Date | null): string {
    if (!data) {
      return '';
    }
    const ano = data.getFullYear();
    const mes = String(data.getMonth() + 1).padStart(2, '0');
    const dia = String(data.getDate()).padStart(2, '0');
    return `${ano}-${mes}-${dia}`;
  }

  pesquisar(value: string): void {
    this.filtroAtual = { ...this.filtroAtual, ticket: value };
    this.carregar();
  }

  incluir(): void {
    this.router.navigate(['/pesagens/novo']);
  }

  visualizar(row: PesagemRow): void {
    this.router.navigate(['/pesagens', row.filial, row.ticket]);
  }

  imprimir(row: PesagemRow): void {
    this.pesagemService.imprimir(row.filial, row.ticket).subscribe({
      error: err => this.poNotification.error(err?.message ?? 'Erro ao imprimir o ticket.')
    });
  }

  // Abre o relatorio nativo de pesagens (QPES003, sintetico/analitico por Centro de
  // Custo e periodo) na sessao do SmartClient -- de la o usuario exporta para Excel
  // pelo PrintDialog do TReport.
  relatorio(): void {
    this.pesagemService.relatorio().subscribe({
      error: err => this.poNotification.error(err?.message ?? 'Erro ao abrir o relatório.')
    });
  }

  // Tecla F10 pesa automaticamente a linha selecionada na tabela: entrada primeiro,
  // depois saída, seguindo o mesmo critério do botão/ação da lista -- pedido do
  // usuário pra espelhar o atalho F10 da OGA190Q nativa.
  @HostListener('document:keydown', ['$event'])
  onKeydown(event: KeyboardEvent): void {
    if (event.key !== 'F10') {
      return;
    }
    event.preventDefault();

    if (!this.linhaSelecionada) {
      this.poNotification.warning('Selecione uma pesagem na lista antes de pressionar F10.');
      return;
    }

    if (this.balancaSelecao.precisaEscolher) {
      this.poNotification.warning('Escolha a balança antes de pesar.');
      this.modalBalanca.open();
      return;
    }

    if (this.podePesar(this.linhaSelecionada, '1')) {
      this.pesarLinha(this.linhaSelecionada, '1');
    } else if (this.podePesar(this.linhaSelecionada, '2')) {
      this.pesarLinha(this.linhaSelecionada, '2');
    } else {
      this.poNotification.information('Esta pesagem já está completa ou não pode ser alterada.');
    }
  }

  // tipo '1' (Entrada): só falta o peso de entrada. tipo '2' (Saída): entrada já
  // capturada, falta a saída. Nenhum dos dois quando já pesado por completo ou quando
  // a pesagem está Finalizada/Cancelada (status '3'/'4').
  podePesar(row: PesagemRow, tipo: TipoPeso): boolean {
    if (row.status === '3' || row.status === '4') {
      return false;
    }
    return tipo === '1' ? row.peso1 === 0 : row.peso1 > 0 && row.peso2 === 0;
  }

  pesarLinha(row: PesagemRow, tipo: TipoPeso): void {
    if (this.pesandoLinha) {
      return;
    }
    if (this.balancaSelecao.precisaEscolher) {
      this.poNotification.warning('Escolha a balança antes de pesar.');
      this.modalBalanca.open();
      return;
    }
    this.pesandoLinha = true;

    this.pesagemService.pesar(tipo, { filial: row.filial, ticket: row.ticket, balanca: this.balancaSelecao.selecionada }).subscribe({
      next: resp => this.aplicarResultadoPesagem(resp),
      error: (err: PesagemPesarResponse) => this.aplicarResultadoPesagem(err)
    });
  }

  private aplicarResultadoPesagem(resp: PesagemPesarResponse): void {
    this.pesandoLinha = false;

    if (!resp.success) {
      if (resp.balancaIndisponivel) {
        this.poNotification.warning('Balança não detectada. Abra o ticket (Visualizar) para informar o peso manualmente.');
      } else {
        this.poNotification.error(resp.message ?? 'Erro ao capturar o peso.');
      }
      return;
    }

    this.poNotification.success('Peso capturado e salvo com sucesso.');
    this.carregar();
  }

  fechar(): void {
    this.protheusBridge.fecharApp();
  }

  private descCC(cc: string): string {
    return CENTROS_CUSTO.find(item => item.value === cc)?.label ?? cc;
  }
}
