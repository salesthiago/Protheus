import { CommonModule } from '@angular/common';
import { Component, EventEmitter, Input, OnChanges, Output, ViewChild } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { map } from 'rxjs';
import {
  PoButtonModule,
  PoFieldModule,
  PoLookupColumn,
  PoLookupFilter,
  PoLookupFilteredItemsParams,
  PoModalAction,
  PoModalComponent,
  PoModalModule,
  PoNotificationService,
  PoTableAction,
  PoTableColumn,
  PoTableModule
} from '@po-ui/ng-components';
import { CASAS_DECIMAIS_VALOR, CentroCustoItem, formatarValor, ItemPlanilha, ProdutoItem, TesItem } from '../../models/contrato.model';
import { ContratoService } from '../../services/contrato.service';

// Linha exibida na lista (ja formatada) -- a lista e somente leitura; incluir/editar acontece no
// modal "Item" (layout da tela nativa "Elaborar contrato": Produto/Servico, Valor total do item,
// Valor unitario, Quantidade, Desconto + TES; um unico Centro de custo, sem rateio multiplo --
// pedido do usuario 2026-09-21).
interface LinhaItem {
  origem: ItemPlanilha;
  item: string;
  produto: string;
  quantidade: string;
  valorUnitario: string;
  desconto: string;
  quantidadeMedida: string;
  valorTotal: string;
  tes: string;
  cc: string;
}

// Grade reaproveitavel de itens de planilha (CNBDETAIL), usada no contrato-editor e na
// revisao-form. API publica: [itens], [somenteLeitura], (itensChange).
@Component({
  selector: 'app-item-grid',
  standalone: true,
  imports: [CommonModule, FormsModule, PoTableModule, PoButtonModule, PoFieldModule, PoModalModule],
  templateUrl: './item-grid.component.html',
  styleUrl: './item-grid.component.css'
})
export class ItemGridComponent implements OnChanges {
  @Input() itens: ItemPlanilha[] = [];
  @Input() somenteLeitura = false;
  @Output() itensChange = new EventEmitter<ItemPlanilha[]>();

  @ViewChild('modalItem') modalItem!: PoModalComponent;

  // Valores monetarios com 4 casas decimais (ver CASAS_DECIMAIS_VALOR no model).
  readonly casasDecimais = CASAS_DECIMAIS_VALOR;

  readonly colunas: Array<PoTableColumn> = [
    { property: 'item', label: 'Item', width: '70px' },
    { property: 'produto', label: 'Produto / Serviço' },
    { property: 'quantidade', label: 'Quantidade', width: '110px' },
    { property: 'valorUnitario', label: 'Valor unitário', width: '130px' },
    { property: 'desconto', label: 'Desconto (%)', width: '110px' },
    { property: 'quantidadeMedida', label: 'Quantidade medida', width: '130px' },
    { property: 'valorTotal', label: 'Valor total do item', width: '150px' },
    { property: 'tes', label: 'TES', width: '100px' },
    { property: 'cc', label: 'Centro de custo', width: '150px' }
  ];

  // Referencia estavel (recalculada so em ngOnChanges) -- ver nota em contrato-list sobre
  // po-table reconstruir a grade quando recebe array novo a cada ciclo.
  linhas: LinhaItem[] = [];
  acoes: Array<PoTableAction> = [];

  // Estado do modal: copia de trabalho do item (so vai para a lista em "Inserir"/"Salvar").
  itemEmEdicao: ItemPlanilha = this.itemVazio('');
  indiceEmEdicao: number | null = null;

  acaoConfirmar: PoModalAction = { label: 'Inserir', action: () => this.confirmarItem() };
  acaoCancelar: PoModalAction = { label: 'Cancelar', action: () => this.modalItem.close() };

  readonly produtoColumns: Array<PoLookupColumn> = [
    { property: 'codigo', label: 'Código', width: '30%' },
    { property: 'descricao', label: 'Descrição' }
  ];

  readonly produtoFilter: PoLookupFilter = {
    getFilteredItems: (params: PoLookupFilteredItemsParams) =>
      this.contratoService.lookupProduto(String(params.filter ?? '')).pipe(map(resp => ({ items: resp.items, hasNext: resp.hasNext }))),
    getObjectByValue: (value: string | Array<unknown>) =>
      this.contratoService.lookupProduto(String(value)).pipe(map(resp => resp.items.find(item => item.codigo === String(value))))
  };

  readonly tesColumns: Array<PoLookupColumn> = [
    { property: 'codigo', label: 'Código', width: '30%' },
    { property: 'descricao', label: 'Descrição' }
  ];

  readonly tesFilter: PoLookupFilter = {
    getFilteredItems: (params: PoLookupFilteredItemsParams) =>
      this.contratoService.lookupTes(String(params.filter ?? '')).pipe(map(resp => ({ items: resp.items, hasNext: resp.hasNext }))),
    getObjectByValue: (value: string | Array<unknown>) =>
      this.contratoService.lookupTes(String(value)).pipe(map(resp => resp.items.find(item => item.codigo === String(value))))
  };

  readonly ccColumns: Array<PoLookupColumn> = [
    { property: 'codigo', label: 'Código', width: '30%' },
    { property: 'descricao', label: 'Descrição' }
  ];

  readonly ccFilter: PoLookupFilter = {
    getFilteredItems: (params: PoLookupFilteredItemsParams) =>
      this.contratoService.lookupCentroCusto(String(params.filter ?? '')).pipe(map(resp => ({ items: resp.items, hasNext: resp.hasNext }))),
    getObjectByValue: (value: string | Array<unknown>) =>
      this.contratoService.lookupCentroCusto(String(value)).pipe(map(resp => resp.items.find(item => item.codigo === String(value))))
  };

  constructor(
    private readonly contratoService: ContratoService,
    private readonly poNotification: PoNotificationService
  ) {}

  ngOnChanges(): void {
    this.acoes = this.somenteLeitura
      ? []
      : [
          { label: 'Editar', action: (linha: LinhaItem) => this.abrirModal(linha.origem) },
          { label: 'Remover', action: (linha: LinhaItem) => this.removerItem(linha.origem) }
        ];
    this.linhas = this.itens.map(origem => ({
      origem,
      item: origem.item,
      produto: origem.descricao ? origem.produto + ' - ' + origem.descricao : origem.produto,
      quantidade: formatarValor(origem.quantidade, 2),
      valorUnitario: formatarValor(origem.valorUnitario),
      desconto: formatarValor(origem.desconto, 2),
      quantidadeMedida: formatarValor(origem.quantidadeMedida ?? 0, 2),
      valorTotal: formatarValor(this.valorTotalItem(origem)),
      tes: origem.tes,
      cc: origem.cc
    }));
  }

  private itemVazio(numero: string): ItemPlanilha {
    return {
      item: numero,
      produto: '',
      descricao: '',
      unidade: '',
      quantidade: 0,
      valorUnitario: 0,
      quantidadeMedida: 0,
      cc: '',
      tes: '',
      pedTit: '1',
      desconto: 0
    };
  }

  valorTotalItem(item: ItemPlanilha): number {
    const bruto = (item.quantidade || 0) * (item.valorUnitario || 0);
    return bruto - bruto * ((item.desconto || 0) / 100);
  }

  get valorTotalEmEdicao(): string {
    return 'R$ ' + formatarValor(this.valorTotalItem(this.itemEmEdicao));
  }

  adicionarItem(): void {
    this.indiceEmEdicao = null;
    this.itemEmEdicao = this.itemVazio(String(this.itens.length + 1).padStart(3, '0'));
    this.acaoConfirmar = { ...this.acaoConfirmar, label: 'Inserir' };
    this.modalItem.open();
  }

  private abrirModal(item: ItemPlanilha): void {
    this.indiceEmEdicao = this.itens.indexOf(item);
    this.itemEmEdicao = { ...item };
    this.acaoConfirmar = { ...this.acaoConfirmar, label: 'Salvar' };
    this.modalItem.open();
  }

  private confirmarItem(): void {
    if (!this.itemEmEdicao.produto.trim()) {
      this.poNotification.warning('Informe o Produto / Serviço.');
      return;
    }
    if (!(this.itemEmEdicao.quantidade > 0)) {
      this.poNotification.warning('Informe a quantidade.');
      return;
    }
    if (this.indiceEmEdicao === null) {
      this.itens = [...this.itens, this.itemEmEdicao];
    } else {
      this.itens = this.itens.map((item, i) => (i === this.indiceEmEdicao ? this.itemEmEdicao : item));
    }
    this.itensChange.emit(this.itens);
    this.ngOnChanges();
    this.modalItem.close();
  }

  private removerItem(itemRemovido: ItemPlanilha): void {
    // Renumera (001, 002...) para nao deixar buraco na sequencia enviada ao backend.
    this.itens = this.itens
      .filter(item => item !== itemRemovido)
      .map((item, i) => ({ ...item, item: String(i + 1).padStart(3, '0') }));
    this.itensChange.emit(this.itens);
    this.ngOnChanges();
  }

  onProdutoSelecionado(produto: ProdutoItem | undefined): void {
    if (produto) {
      this.itemEmEdicao.produto = produto.codigo;
      this.itemEmEdicao.descricao = produto.descricao;
    }
  }

  onTesSelecionado(tes: TesItem | undefined): void {
    if (tes) {
      this.itemEmEdicao.tes = tes.codigo;
    }
  }

  onCcSelecionado(cc: CentroCustoItem | undefined): void {
    if (cc) {
      this.itemEmEdicao.cc = cc.codigo;
    }
  }
}
