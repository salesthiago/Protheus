import { NgTemplateOutlet } from '@angular/common';
import { Component, HostListener, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { map } from 'rxjs';
import {
  PoButtonModule,
  PoComboFilter,
  PoComboOption,
  PoFieldModule,
  PoLookupColumn,
  PoLookupFilter,
  PoLookupFilteredItemsParams,
  PoNotificationService,
  PoPageAction,
  PoPageModule
} from '@po-ui/ng-components';
import { PesagemLookupItem, PesagemNova, PesagemPesarResponse, STATUS_PESAGEM } from '../../models/pesagem.model';
import { BalancaSelecaoService } from '../../services/balanca-selecao.service';
import { PesagemService } from '../../services/pesagem.service';

type TipoPeso = '1' | '2';

@Component({
  selector: 'app-pesagem-form',
  standalone: true,
  imports: [PoPageModule, PoFieldModule, PoButtonModule, FormsModule, NgTemplateOutlet],
  templateUrl: './pesagem-form.component.html',
  styleUrl: './pesagem-form.component.css'
})
export class PesagemFormComponent implements OnInit {
  // Campos do formulario de inclusao (limitados ao que aparece no ticket impresso --
  // QPES001.PRW), preenchidos automaticamente ao selecionar a Placa (ver
  // onPlacaSelecionada). Sem Centro de Custo (removido a pedido do usuario) e sem
  // peso1/peso2 (agora sao capturados na balanca, ver pesarEntrada/pesarSaida).
  model: PesagemNova = { placa: '', motorista: '', codPro: '', desPro: '' };

  // 'ticket'/'filial' so existem depois que a pesagem foi salva (por Salvar ou pelo
  // 1o clique em Pesar, que salva sozinho). Enquanto vazios, os botoes de pesar ainda
  // funcionam -- eles criam o registro na hora, usando os dados do 'model' atual.
  ticket = '';
  filial = '';
  data = '';
  status = '';
  operador = '';

  peso1 = 0;
  dataEnt = '';
  horaEnt = '';
  pesando1 = false;
  balancaIndisp1 = false;
  pesoManual1: number | null = null;

  peso2 = 0;
  dataSai = '';
  horaSai = '';
  pesando2 = false;
  balancaIndisp2 = false;
  pesoManual2: number | null = null;

  pesoLiquido = 0;

  isNew = true;
  isView = false;
  saving = false;
  loading = false;

  readonly statusLabels = STATUS_PESAGEM;

  readonly lookupColumns: Array<PoLookupColumn> = [
    { property: 'value', label: 'Código', width: '30%' },
    { property: 'label', label: 'Descrição' }
  ];

  readonly produtoFilter: PoLookupFilter = {
    getFilteredItems: (params: PoLookupFilteredItemsParams) =>
      this.pesagemService.lookupProdutos(params.filter).pipe(map(resp => ({ items: resp.items, hasNext: resp.hasNext }))),
    getObjectByValue: (value: string) =>
      this.pesagemService.lookupProdutos(String(value)).pipe(map(resp => resp.items.find(item => item.value === value)))
  };

  // "Consulta padrão" da Placa (tabela DA3, ver PesLkpPl/PesPlDet em QPES004.PRW).
  // po-combo (não po-lookup) porque o pedido do usuário foi uma lista suspensa que já
  // aparece conforme digita, sem precisar clicar numa lupa pra abrir modal.
  readonly placaFilter: PoComboFilter = {
    getFilteredData: (params: { value: string }) =>
      this.pesagemService.lookupPlacas(params?.value).pipe(map(resp => resp.items as Array<PoComboOption>)),
    getObjectByValue: (value: string | number) =>
      this.pesagemService.lookupPlacas(String(value)).pipe(map(resp => resp.items.find(item => item.value === value) as PoComboOption))
  };

  readonly viewActions: Array<PoPageAction> = [
    { label: 'Imprimir Ticket', action: () => this.imprimir() },
    { label: 'Voltar', action: () => this.voltar() }
  ];

  constructor(
    private readonly route: ActivatedRoute,
    private readonly router: Router,
    private readonly pesagemService: PesagemService,
    private readonly poNotification: PoNotificationService,
    private readonly balancaSelecao: BalancaSelecaoService
  ) {}

  ngOnInit(): void {
    this.route.paramMap.subscribe(params => {
      const filial = params.get('filial');
      const ticket = params.get('ticket');
      this.isNew = !filial || !ticket;
      this.isView = !this.isNew;

      if (filial && ticket) {
        this.loading = true;

        this.pesagemService.get(filial, ticket).subscribe({
          next: response => {
            this.model = {
              placa: response.placa,
              motorista: response.motorista,
              codPro: response.codPro,
              desPro: response.desPro,
              rota: response.rota,
              cliente: response.cliente,
              fornecedor: response.fornecedor,
              obs: response.obs
            };
            this.ticket = response.ticket;
            this.filial = response.filial;
            this.data = response.data;
            this.status = response.status;
            this.operador = response.operador;
            this.peso1 = response.peso1;
            this.dataEnt = response.dataEnt;
            this.horaEnt = response.horaEnt;
            this.peso2 = response.peso2;
            this.dataSai = response.dataSai;
            this.horaSai = response.horaSai;
            this.pesoLiquido = response.pesoLiq;
            this.loading = false;
          },
          error: () => {
            this.loading = false;
            this.poNotification.error('Erro ao carregar a pesagem.');
            this.voltar();
          }
        });
      } else {
        this.model = { placa: '', motorista: '', codPro: '', desPro: '' };
      }
    });
  }

  get statusLabel(): string {
    return this.statusLabels.find(item => item.value === this.status)?.label ?? this.status;
  }

  // Uma pesagem incompleta (status '0'/'1', sem os dois pesos ainda) continua
  // permitindo capturar o peso que falta mesmo reaberta na tela de Visualizar depois
  // -- o caminhao normalmente sai e so volta depois pra 2a pesagem. So trava mesmo
  // quando ja foi Finalizada ('3') ou Cancelada ('4').
  get podeCapturar(): boolean {
    return this.status !== '3' && this.status !== '4';
  }

  get titulo(): string {
    return this.isView ? `Pesagem ${this.ticket}` : 'Incluir Pesagem';
  }

  // Preenche codPro/desPro/umPro a partir do produto escolhido no lookup (SB1) --
  // continua editavel manualmente mesmo depois do preenchimento automatico pela Placa.
  onProdutoSelecionado(item: PesagemLookupItem | undefined): void {
    this.model.codPro = item?.value ?? '';
    this.model.desPro = item?.label ?? '';
    this.model.umPro = item?.um ?? '';
  }

  // Ao selecionar a Placa (consulta padrão DA3, via po-combo), busca o resto dos dados
  // do veiculo (motorista/rota/produto/cliente/fornecedor) e preenche o formulario
  // sozinho. p-emit-object-value faz o po-combo emitir o PoComboOption inteiro, nao so
  // o value -- mas ao digitar e apagar o campo ele tambem dispara com undefined/''.
  onPlacaSelecionada(item: PoComboOption | undefined): void {
    const value = item?.value ? String(item.value) : '';
    this.model.placa = value;
    if (!value) {
      return;
    }

    this.pesagemService.placaDetalhe(value).subscribe({
      next: det => {
        if (!det.success) {
          this.poNotification.warning(det.message ?? 'Veículo não cadastrado.');
          return;
        }
        this.model.motorista = det.motorista;
        this.model.rota = det.rota;
        this.model.codPro = det.codPro;
        this.model.desPro = det.desPro;
        this.model.umPro = det.umPro;
        this.model.codEnt = det.codEnt;
        this.model.lojEnt = det.lojEnt;
        this.model.cliente = det.cliente;
        this.model.fornecedor = det.fornecedor;
        this.model.obs = det.obs;
      },
      error: err => this.poNotification.warning(err?.message ?? 'Erro ao buscar dados do veículo.')
    });
  }

  salvar(): void {
    if (!this.validar()) {
      return;
    }

    this.saving = true;

    this.pesagemService.create(this.model).subscribe({
      next: response => {
        this.saving = false;
        this.ticket = response.ticket ?? this.ticket;
        this.poNotification.success(response.message ?? 'Pesagem salva com sucesso.');
      },
      error: err => {
        this.saving = false;
        this.poNotification.error(err?.message ?? 'Erro ao salvar a pesagem.');
      }
    });
  }

  // Tecla F10 pesa automaticamente, na ordem correta (entrada primeiro, depois
  // saída) -- mesmo atalho da tela nativa OGA190Q, agora tambem valido aqui.
  @HostListener('document:keydown', ['$event'])
  onKeydown(event: KeyboardEvent): void {
    if (event.key !== 'F10') {
      return;
    }
    event.preventDefault();

    if (!this.podeCapturar) {
      this.poNotification.information('Esta pesagem já está completa ou não pode ser alterada.');
      return;
    }

    if (this.peso1 === 0 && !this.pesando1 && !this.balancaIndisp1) {
      this.pesarEntrada();
    } else if (this.peso1 > 0 && this.peso2 === 0 && !this.pesando2 && !this.balancaIndisp2) {
      this.pesarSaida();
    }
  }

  pesarEntrada(): void {
    this.pesar('1');
  }

  pesarSaida(): void {
    this.pesar('2');
  }

  confirmarPesoManual(tipo: TipoPeso): void {
    const pesoManual = tipo === '1' ? this.pesoManual1 : this.pesoManual2;
    if (!pesoManual || pesoManual <= 0) {
      this.poNotification.warning('Informe um peso válido.');
      return;
    }
    this.pesar(tipo, pesoManual);
  }

  private pesar(tipo: TipoPeso, pesoManual?: number): void {
    if (!pesoManual && !this.validar()) {
      return;
    }
    // Guarda defensiva: na pratica a lista (tela de entrada da SPA) ja resolve a
    // escolha antes de chegar aqui, ver BalancaSelecaoService/PesagemListComponent.
    if (this.balancaSelecao.precisaEscolher) {
      this.poNotification.warning('Volte para a listagem e escolha a balança antes de pesar.');
      return;
    }

    if (tipo === '1') {
      this.pesando1 = true;
    } else {
      this.pesando2 = true;
    }

    const payload = {
      ...this.model,
      filial: this.filial || undefined,
      ticket: this.ticket || undefined,
      pesoManual,
      balanca: this.balancaSelecao.selecionada
    };

    this.pesagemService.pesar(tipo, payload).subscribe({
      next: resp => this.aplicarPesagem(resp, tipo),
      error: (err: PesagemPesarResponse) => this.aplicarPesagem(err, tipo)
    });
  }

  private aplicarPesagem(resp: PesagemPesarResponse, tipo: TipoPeso): void {
    if (tipo === '1') {
      this.pesando1 = false;
    } else {
      this.pesando2 = false;
    }

    if (!resp.success) {
      this.ticket = resp.ticket ?? this.ticket;
      this.filial = resp.filial ?? this.filial;

      if (resp.balancaIndisponivel) {
        if (tipo === '1') {
          this.balancaIndisp1 = true;
        } else {
          this.balancaIndisp2 = true;
        }
        this.poNotification.warning(resp.message ?? 'Balança não detectada.');
      } else {
        this.poNotification.error(resp.message ?? 'Erro ao capturar o peso.');
      }
      return;
    }

    this.ticket = resp.ticket ?? this.ticket;
    this.filial = resp.filial ?? this.filial;
    this.status = resp.status ?? this.status;
    this.pesoLiquido = resp.pesoLiq ?? this.pesoLiquido;

    if (tipo === '1') {
      this.peso1 = resp.peso ?? this.peso1;
      this.balancaIndisp1 = false;
      this.pesoManual1 = null;
    } else {
      this.peso2 = resp.peso ?? this.peso2;
      this.balancaIndisp2 = false;
      this.pesoManual2 = null;
    }

    this.poNotification.success('Peso capturado e salvo com sucesso.');
  }

  imprimir(): void {
    if (!this.filial || !this.ticket) {
      return;
    }
    this.pesagemService.imprimir(this.filial, this.ticket).subscribe({
      error: err => this.poNotification.error(err?.message ?? 'Erro ao imprimir o ticket.')
    });
  }

  voltar(): void {
    this.router.navigate(['/pesagens']);
  }

  private validar(): boolean {
    if (!this.model.placa?.trim()) {
      this.poNotification.warning('Informe a Placa.');
      return false;
    }
    if (!this.model.motorista?.trim()) {
      this.poNotification.warning('Informe o Motorista.');
      return false;
    }
    if (!this.model.codPro) {
      this.poNotification.warning('Informe o Produto.');
      return false;
    }
    return true;
  }
}
