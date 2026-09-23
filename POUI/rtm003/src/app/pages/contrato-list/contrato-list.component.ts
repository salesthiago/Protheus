import { CommonModule } from '@angular/common';
import { Component, OnInit, ViewChild } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import {
  PoButtonModule,
  PoDropdownAction,
  PoDropdownModule,
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
  ContratoResumo,
  SITUACOES_CONTRATO_OPTIONS,
  SituacaoContrato,
  TIPOS_CONTRATO_OPTIONS,
  TipoContrato,
  UNIDADES_VIGENCIA_OPTIONS
} from '../../models/contrato.model';
import { ContratoService } from '../../services/contrato.service';

@Component({
  selector: 'app-contrato-list',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    PoPageModule,
    PoTableModule,
    PoButtonModule,
    PoFieldModule,
    PoDropdownModule,
    PoModalModule
  ],
  templateUrl: './contrato-list.component.html',
  styleUrl: './contrato-list.component.css'
})
export class ContratoListComponent implements OnInit {
  @ViewChild('modalBuscaAvancada') modalBuscaAvancada!: PoModalComponent;
  @ViewChild('modalSelecaoFilial') modalSelecaoFilial!: PoModalComponent;

  readonly tipoOptions: Array<PoSelectOption> = [
    { value: '', label: 'Todos' },
    ...TIPOS_CONTRATO_OPTIONS.map(opcao => ({ value: opcao.value, label: opcao.label }))
  ];

  readonly situacaoOptions: Array<PoSelectOption> = [
    { value: '', label: 'Todas' },
    ...SITUACOES_CONTRATO_OPTIONS.map(opcao => ({ value: opcao.value, label: opcao.label }))
  ];

  // Busca principal (p-filter do po-page-list): campo unico de numero do contrato + link nativo
  // "Busca Avançada" (advancedAction) que abre o modal com os demais filtros -- padrao proprio
  // do PO-UI pra essa combinacao (PoPageFilter), sem precisar de accordion/painel custom (nao
  // havia nenhum padrao pronto de busca avancada em rtm003/rtm002 antes desta tela).
  readonly filtroPagina: PoPageFilter = {
    placeholder: 'Buscar por número do contrato',
    action: (valor: string) => this.buscarPorNumero(valor),
    advancedAction: () => this.abrirBuscaAvancada()
  };

  // Array com referencia estavel (criado uma unica vez, campo de classe) -- um literal inline
  // no template ([p-actions]="[{...}]") seria recriado a cada ciclo de change detection, o que
  // faz o Angular achar que o Input mudou toda vez e chamar o setter de "actions" do po-page-list
  // sem parar (a lib reconstroi o menu/dropdown a cada chamada). Em uma WebView embarcada mais
  // fraca (TWebEngine do SmartClient) isso e o suficiente para travar a tela por completo.
  //
  // "Incluir" precisa decidir Compra ou Venda ANTES de carregar a tela de inclusao (pedido do
  // usuario, 2026-08-11) -- um UNICO botao "Incluir" do tipo dropdown com Compra/Venda como
  // opcoes (pedido explicito do usuario, substituindo os 2 botoes separados da rodada
  // anterior). NAO usa PoPageAction/[p-actions] pra isso -- a doc do PoPageAction e explicita
  // que subItems so tem efeito a partir da 3a acao, e so agrupa num dropdown de verdade com 4+
  // acoes no array total (mesmo bug que ja deixou "Incluir" sem funcionar numa rodada anterior).
  // po-dropdown e um componente AUTONOMO sem esse limite (usado do mesmo jeito em
  // contrato-editor pra "Ações Relacionadas") -- por isso "Incluir" vive fora de [p-actions],
  // num po-dropdown proprio.
  // A partir de agora (item 4) escolher Compra/Venda NAO navega mais direto -- abre o modal de
  // selecao de filial primeiro (escolherTipo), so navegando de fato em confirmarInclusao().
  readonly acoesIncluir: Array<PoDropdownAction> = [
    { label: 'Compra', action: () => this.escolherTipo('C') },
    { label: 'Venda', action: () => this.escolherTipo('V') }
  ];

  readonly colunas: Array<PoTableColumn> = [
    { property: 'numero', label: 'Número' },
    { property: 'revisao', label: 'Revisão' },
    { property: 'tipoLabel', label: 'Tipo' },
    { property: 'pessoaNome', label: 'Cliente/Fornecedor' },
    { property: 'situacaoLabel', label: 'Situação' },
    { property: 'vigenciaLabel', label: 'Vigência' }
  ];

  // Filtro principal (numero) fica fora do modal, ligado ao p-filter -- os demais so existem
  // dentro do modal de busca avancada. filtroFilial e igualdade exata contra CN9_FILIAL no
  // backend, alimentado pelas opcoes de filiaisOptions (lookupFilial/SM0) -- ainda SEM checar
  // quais filiais o usuario realmente tem permissao de ver (ver nota em filiaisOptions abaixo).
  filtroNumero = '';
  filtroTipo: TipoContrato | '' = '';
  filtroSituacao: SituacaoContrato | '' = '';
  filtroFilial = '';
  filtroDataInicioDe = '';
  filtroDataInicioAte = '';
  carregando = false;
  contratos: Array<ContratoResumo & { tipoLabel: string; situacaoLabel: string; vigenciaLabel: string }> = [];

  // Lista de filiais (SM0, via lookupFilial) -- alimenta tanto o select de filial da busca
  // avancada quanto o modal de selecao de filial antes de incluir (item 4). Lista TODAS as
  // filiais da empresa, sem checar permissao por usuario (limitacao conhecida, ver nota em
  // Contratos/RTM003App.prw::ZcnFilial).
  filiaisOptions: Array<PoSelectOption> = [];
  // Mesma lista de filiaisOptions + sentinela "Filial atual" (value vazio = sem filtro, backend
  // usa a filial da sessao) -- campo proprio (nao literal recriado no template) pelo mesmo
  // motivo documentado acima em acoesIncluir: um array novo a cada change detection faz o
  // PO-UI achar que o Input mudou toda hora.
  filiaisFiltroOptions: Array<PoSelectOption> = [{ value: '', label: 'Filial atual' }];
  tipoParaIncluir: TipoContrato | null = null;
  filialParaIncluir = '';

  constructor(
    private readonly router: Router,
    private readonly contratoService: ContratoService,
    private readonly poNotification: PoNotificationService
  ) {}

  ngOnInit(): void {
    this.carregar();
    this.contratoService.lookupFilial().subscribe({
      next: resp => {
        this.filiaisOptions = resp.items.map(item => ({ value: item.codigo, label: item.codigo + ' - ' + item.nome }));
        this.filiaisFiltroOptions = [{ value: '', label: 'Filial atual' }, ...this.filiaisOptions];
      },
      error: () => {
        // Falha aqui nao deve travar a tela -- filtro de filial/modal de inclusao so ficam sem
        // opcoes pra escolher; o resto da listagem continua funcionando normalmente.
        this.filiaisOptions = [];
      }
    });
  }

  carregar(): void {
    this.carregando = true;
    this.contratoService
      .listar({
        tipo: this.filtroTipo,
        situacao: this.filtroSituacao,
        numero: this.filtroNumero,
        filial: this.filtroFilial,
        dataInicioDe: this.filtroDataInicioDe,
        dataInicioAte: this.filtroDataInicioAte
      })
      .subscribe({
        next: resp => {
          this.carregando = false;
          this.contratos = resp.contratos.map(contrato => ({
            ...contrato,
            tipoLabel: contrato.tipo === 'C' ? 'Compra' : 'Venda',
            // Descricao vem pronta do backend (ZcnSitDesc) -- o mapeamento local
            // (SITUACOES_CONTRATO_OPTIONS) so entra como fallback pra respostas antigas/sem o campo.
            situacaoLabel:
              contrato.situacaoDescricao ||
              SITUACOES_CONTRATO_OPTIONS.find(opcao => opcao.value === contrato.situacao)?.label ||
              contrato.situacao,
            vigenciaLabel:
              contrato.vigencia +
              ' ' +
              (UNIDADES_VIGENCIA_OPTIONS.find(opcao => opcao.value === contrato.unidadeVigencia)?.label ?? contrato.unidadeVigencia)
          }));
        },
        error: resp => {
          this.carregando = false;
          this.poNotification.error(resp?.message ?? 'Falha ao consultar contratos.');
        }
      });
  }

  buscarPorNumero(valor: string): void {
    this.filtroNumero = valor ?? '';
    this.carregar();
  }

  abrirBuscaAvancada(): void {
    this.modalBuscaAvancada.open();
  }

  aplicarBuscaAvancada(): void {
    this.modalBuscaAvancada.close();
    this.carregar();
  }

  limparBuscaAvancada(): void {
    this.filtroTipo = '';
    this.filtroSituacao = '';
    this.filtroFilial = '';
    this.filtroDataInicioDe = '';
    this.filtroDataInicioAte = '';
    this.modalBuscaAvancada.close();
    this.carregar();
  }

  escolherTipo(tipo: TipoContrato): void {
    this.tipoParaIncluir = tipo;
    this.filialParaIncluir = this.filiaisOptions.length === 1 ? String(this.filiaisOptions[0].value) : '';
    this.modalSelecaoFilial.open();
  }

  confirmarInclusao(): void {
    if (!this.filialParaIncluir) {
      this.poNotification.warning('Selecione a filial do contrato.');
      return;
    }
    this.modalSelecaoFilial.close();
    this.router.navigate(['contratos', 'novo'], {
      queryParams: { tipo: this.tipoParaIncluir, filial: this.filialParaIncluir }
    });
  }

  abrirContrato(contrato: ContratoResumo): void {
    this.router.navigate(['contratos', contrato.numero, contrato.revisao]);
  }
}
