import { CommonModule } from '@angular/common';
import { Component, OnInit, ViewChild } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { map, Observable } from 'rxjs';
import {
  PoButtonModule,
  PoComboFilter,
  PoComboOption,
  PoContainerModule,
  PoDialogService,
  PoDropdownAction,
  PoDropdownModule,
  PoFieldModule,
  PoLookupColumn,
  PoLookupFilter,
  PoLookupFilteredItemsParams,
  PoModalComponent,
  PoModalModule,
  PoNotificationService,
  PoPageModule,
  PoSelectOption,
  PoTableColumn,
  PoTableModule,
  PoTabsModule
} from '@po-ui/ng-components';
import { ItemGridComponent } from '../../shared/item-grid/item-grid.component';
import {
  CASAS_DECIMAIS_VALOR,
  CondPagtoItem,
  Contrato,
  EventoTimeline,
  formatarValor,
  ItemPlanilha,
  NaturezaItem,
  PERIODICIDADE_OPTIONS,
  Pessoa,
  SIM_NAO_OPTIONS,
  SITUACOES_CONTRATO_OPTIONS,
  SituacaoContrato,
  TIPOS_REVISAO_OPTIONS,
  TRANSICOES_SITUACAO,
  TipoContrato,
  TipoContratoItem,
  TipoPlanilhaItem,
  UNIDADES_VIGENCIA_OPTIONS
} from '../../models/contrato.model';
import { ContratoService } from '../../services/contrato.service';
import { ProtheusBridgeService } from '../../services/protheus-bridge.service';

// Planilha em edicao/exibicao na tela -- shape local, usado tanto em modo criar (mutavel, vem do
// modal "Adicionar/Editar Planilha") quanto em modo editar (populado 1x a partir de
// Contrato.planilhas, so leitura). "numero" so existe de verdade depois que o backend atribui
// (contrato ja salvo) -- em modo criar fica undefined at o Confirmar.
interface PlanilhaForm {
  numero?: string;
  tipoPlanilha: string;
  dataInicio: string;
  dataFim: string;
  pessoaCodigo: string;
  pessoaSelecionada: Pessoa | null;
  itens: ItemPlanilha[];
  // Campos da planilha na tela "Elaborar contrato" (ver ZcnCpDic em RTM003App.prw)
  descricao: string;
  indice: string;
  periodicidade: number;
  unidadePer: string;
  modoReajuste: string;
  dataBase: string;
  // Vem do Tipo de Planilha escolhido (TipoPlanilhaItem.exigeCronograma) -- decide se a
  // Periodicidade fica liberada pra digitar ou so leitura (pedido do usuario: "se o tipo de
  // planilha exige cronograma financeiro, a periodicidade fica liberada, senao so leitura").
  // Default .T. (liberada) ate o usuario escolher um tipo de planilha ou se o backend nao
  // localizar o campo real no dicionario -- preserva o comportamento anterior a esta feature.
  exigeCronograma: boolean;
}

// Campos opcionais que dependem do dicionario do ambiente (resposta de dominiosPlanilha).
interface CamposDicionario {
  descCtr: boolean;
  descPla: boolean;
  indice: boolean;
  periodicidade: boolean;
  unidadePer: boolean;
  modoReajuste: boolean;
  dataBase: boolean;
}

const ROTULO_CAMPO: Record<string, string> = {
  descCtr: 'Descrição do contrato',
  descPla: 'Descrição da planilha',
  indice: 'Índice de reajuste',
  periodicidade: 'Periodicidade',
  unidadePer: 'Unidade',
  modoReajuste: 'Modo de reajuste',
  dataBase: 'Data base'
};

// Tela unica de contrato (Fase 5, protótipo "Contratos - Alteração", 2026-08-11) -- substitui
// contrato-form (so criacao) e contrato-detalhe (so leitura/acoes), unificando os dois: "Esta
// deverá ser a mesma tela para alterar o contrato" (pedido explicito do usuario). "modo" decide
// o comportamento ('criar': planilhas editaveis, sem Outras Acoes; 'editar': planilhas SOMENTE
// LEITURA -- mudar planilha de um contrato existente continua exigindo Nova Revisao, decisao
// tomada com o usuario porque o CNTA300 nativo nunca confirmou permitir edicao direta de
// planilha/item fora do fluxo de revisao).
@Component({
  selector: 'app-contrato-editor',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    PoPageModule,
    PoFieldModule,
    PoButtonModule,
    PoContainerModule,
    PoTabsModule,
    PoTableModule,
    PoModalModule,
    PoDropdownModule,
    ItemGridComponent
  ],
  templateUrl: './contrato-editor.component.html',
  styleUrl: './contrato-editor.component.css'
})
export class ContratoEditorComponent implements OnInit {
  // Deixou de ser readonly: apos criar com sucesso (criar(), ver mais abaixo), a tela transita
  // pra modo "editar" no lugar (sem navegar pra outra rota/recarregar o componente), pra poder
  // continuar mostrando o contrato ja salvo e oferecer o prompt de cronograma pendente (item 5).
  modo: 'criar' | 'editar';
  tipo: TipoContrato = 'C';
  // Filial escolhida no modal de selecao de filial da listagem (item 4, contrato-list) --
  // so existe em modo "criar" (vem via query param), enviada em ContratoCriarPayload.filial.
  // O backend (ZcnCriar) recusa se for diferente da filial da sessao atual -- ver nota la.
  filialParaIncluir = '';

  numero = '';
  revisao = '';
  carregando = false;
  salvando = false;
  temCronograma = false;

  // Dados Principais (campos minimos da tela "Elaborar contrato")
  descricao = '';
  dataInicio = '';
  unidadeVigencia = '2';
  vigencia = 12;
  dtAssinatura = '';
  moeda = 1;
  condPagtoCodigo = '';
  condPagtoSelecionado: CondPagtoItem | null = null;
  tipoContratoCodigo = '';
  tipoContratoSelecionado: TipoContratoItem | null = null;

  // Listas vindas do backend (carregarDominios): moedas cadastradas, indices de reajuste e
  // combos de Unidade/Modo de reajuste da planilha (X3_CBOX).
  moedaOptions: Array<PoSelectOption> = [];
  indiceOptions: Array<PoSelectOption> = [];
  unidadePeriodicidadeOptions: Array<PoSelectOption> = UNIDADES_VIGENCIA_OPTIONS;
  modoReajusteOptions: Array<PoSelectOption> = [];
  campos: CamposDicionario = {
    descCtr: true,
    descPla: true,
    indice: true,
    periodicidade: true,
    unidadePer: true,
    modoReajuste: true,
    dataBase: true
  };
  erroIndice = '';
  mapaCampos = '';

  // Valores monetarios das planilhas com 4 casas decimais.
  readonly casasDecimais = CASAS_DECIMAIS_VALOR;

  // Textareas
  objeto = '';
  clausula = '';
  justificativa = '';
  naturezaCodigo = '';
  naturezaSelecionada: NaturezaItem | null = null;

  situacaoAtual: SituacaoContrato = SituacaoContrato.Emitido;
  // Descricao ja traduzida pelo backend (ZcnSitDesc) -- fonte preferida pro "Status do Contrato"
  // exibido na tela; SITUACOES_CONTRATO_OPTIONS (local) so entra como fallback, ver situacaoLabel.
  situacaoAtualDescricao = '';

  // Planilhas: uma aba por planilha, itens dentro de cada uma.
  planilhas: PlanilhaForm[] = [];
  planilhaSelecionadaIndex = -1;

  // Historico (aba) + Ações Relacionadas (dropdown, visivel nos 2 modos -- em modo criar as
  // acoes que dependem de um contrato ja salvo ficam desabilitadas, ver recalcularAcoesRelacionadas()).
  transicoesDisponiveis: Array<{ value: SituacaoContrato; label: string }> = [];
  revisoesGrid: Array<{ tipoLabel: string; justificativa: string; data: string; situacaoLabel: string }> = [];
  acoesRelacionadasItems: Array<PoDropdownAction> = [];

  // Linha do Tempo (aba) -- eventos da ZLG (ZcnTL / op contratoTimeline), mesma fonte do PDF
  // Contratos/RT69M003.prw. Carregada junto com o contrato em modo editar.
  timelineGrid: Array<EventoTimeline & { situacaoTransicao: string }> = [];
  carregandoTimeline = false;
  // Observacao opcional gravada em ZLG_OBS junto com a proxima mudanca de situacao.
  obsSituacao = '';

  readonly colunasTimeline: Array<PoTableColumn> = [
    { property: 'data', label: 'Data', type: 'date', width: '110px' },
    { property: 'hora', label: 'Hora', width: '70px' },
    { property: 'acaoLabel', label: 'Evento' },
    { property: 'situacaoTransicao', label: 'Situação' },
    { property: 'revisao', label: 'Rev.', width: '70px' },
    { property: 'origemLabel', label: 'Origem' },
    { property: 'nomeUsuario', label: 'Responsável' },
    { property: 'obs', label: 'Observação' }
  ];

  // Cronograma financeiro/fisico (migrado de contrato-detalhe, mesma logica)
  @ViewChild('modalCronograma') modalCronograma!: PoModalComponent;
  // Prompt exibido logo apos criar um contrato sem cronograma ainda (item 5, pedido do
  // usuario): "criar automaticamente" (na pratica, abre o modal de cronograma JA existente
  // pre-preenchido -- decisao confirmada com o usuario, nao e 100% sem intervencao),
  // "salvar sem cronograma" ou "voltar para elaboracao do contrato". Como o contrato ja foi
  // persistido via MVC neste ponto (CommitData ja rodou), "cancelar"/"voltar" NAO desfaz a
  // criacao (nao existe rotina de exclusao de contrato neste projeto) -- so fecha o prompt e
  // deixa o usuario continuar editando o contrato ja salvo (modo "editar"), sem forcar a
  // decisao sobre cronograma agora.
  @ViewChild('modalCronogramaPendente') modalCronogramaPendente!: PoModalComponent;

  readonly periodicidadeOptions: Array<PoSelectOption> = PERIODICIDADE_OPTIONS;
  readonly simNaoOptions: Array<PoSelectOption> = SIM_NAO_OPTIONS;
  gerandoCronograma = false;
  crgPeriodicidade = 1;
  crgDias = 30;
  crgUltimoDiaMes = 1;
  crgCompetenciaInicio = '';
  crgDataPrevista = '';
  crgQtdParcelas = 1;
  crgCondPagtoCodigo = '';
  crgTaxaJuros = 0;

  // Previa LOCAL (nao enviada ao backend) da distribuicao do valor da planilha entre as
  // parcelas -- pedido do usuario pra bater com a tela nativa do Portal Meus Contratos
  // ("Planilha000001": Total da planilha/Saldo a distribuir/Distribuir/tabela de parcelas). O
  // calculo definitivo continua sendo feito pelo backend (CN300PrCF/ZcnGrCrg, rotina nativa) ao
  // clicar "Confirmar" -- esta tabela so ajuda o usuario a visualizar como o total tende a ficar
  // dividido antes de confirmar.
  crgParcelas: Array<{ parcela: number; competencia: string; data: string; valor: number; saldo: number }> = [];

  readonly colunasCronograma: Array<PoTableColumn> = [
    { property: 'parcela', label: 'Parcela', width: '80px' },
    { property: 'competencia', label: 'Competência', width: '110px' },
    { property: 'data', label: 'Data', type: 'date', width: '110px' },
    { property: 'valor', label: 'Valor' },
    { property: 'saldo', label: 'Saldo' }
  ];

  readonly unidadesVigenciaOptions = UNIDADES_VIGENCIA_OPTIONS;

  readonly colunasRevisoes: Array<PoTableColumn> = [
    { property: 'tipoLabel', label: 'Tipo' },
    { property: 'justificativa', label: 'Justificativa' },
    { property: 'data', label: 'Data', type: 'date' },
    { property: 'situacaoLabel', label: 'Situação' }
  ];

  // Filtra pelo tipo ja decidido (query param em modo criar, header.tipo carregado em modo
  // editar) -- so mostra Tipos de Contrato compativeis, mesma logica ja usada em contrato-form.
  // Ainda usado (so no .ts) pra resolver o label de exibicao em definirContrato() -- o campo do
  // template agora e o po-combo (tipoContratoComboFilter, mais abaixo).
  readonly tipoContratoFilter: PoLookupFilter = {
    getFilteredItems: (params: PoLookupFilteredItemsParams) =>
      this.contratoService
        .lookupTipoContrato(String(params.filter ?? ''))
        .pipe(map(resp => ({ items: resp.items.filter(item => item.tipo === this.tipo), hasNext: resp.hasNext }))),
    getObjectByValue: (value: string | Array<unknown>) =>
      this.contratoService
        .lookupTipoContrato(String(value))
        .pipe(map(resp => resp.items.find(item => item.codigo === String(value) && item.tipo === this.tipo)))
  };

  readonly pessoaColumns: Array<PoLookupColumn> = [
    { property: 'codigo', label: 'Código', width: '20%' },
    { property: 'loja', label: 'Loja', width: '15%' },
    { property: 'nome', label: 'Nome' }
  ];

  readonly pessoaFilter: PoLookupFilter = {
    getFilteredItems: (params: PoLookupFilteredItemsParams) =>
      this.contratoService.lookupPessoa(this.tipo, String(params.filter ?? '')).pipe(map(resp => ({ items: resp.items, hasNext: resp.hasNext }))),
    getObjectByValue: (value: string | Array<unknown>) =>
      this.contratoService.lookupPessoa(this.tipo, String(value)).pipe(map(resp => resp.items.find(item => item.codigo === String(value))))
  };

  // Ainda usado (so no .ts) pra resolver o label de exibicao em definirContrato() -- o campo do
  // template agora e o po-combo (condPagtoComboFilter, mais abaixo).
  readonly condPagtoFilter: PoLookupFilter = {
    getFilteredItems: (params: PoLookupFilteredItemsParams) =>
      this.contratoService.lookupCondPagto(String(params.filter ?? '')).pipe(map(resp => ({ items: resp.items, hasNext: resp.hasNext }))),
    getObjectByValue: (value: string | Array<unknown>) =>
      this.contratoService.lookupCondPagto(String(value)).pipe(map(resp => resp.items.find(item => item.codigo === String(value))))
  };

  // Natureza (CN9_NATURE) -- confirmado pelo usuario 2026-08-11 como "consulta padrao da
  // tabela SED". Ainda usado (so no .ts) pra resolver o label de exibicao em definirContrato() --
  // o campo do template agora e o po-combo (naturezaComboFilter, mais abaixo).
  readonly naturezaFilter: PoLookupFilter = {
    getFilteredItems: (params: PoLookupFilteredItemsParams) =>
      this.contratoService.lookupNatureza(String(params.filter ?? '')).pipe(map(resp => ({ items: resp.items, hasNext: resp.hasNext }))),
    getObjectByValue: (value: string | Array<unknown>) =>
      this.contratoService.lookupNatureza(String(value)).pipe(map(resp => resp.items.find(item => item.codigo === String(value))))
  };

  // Adapta uma busca no formato "lookupXxx(filtro) -> {items}" (mesma usada pelos po-lookup
  // acima) para a interface PoComboFilter -- pedido do usuario 2026-09-22: os campos de dominio
  // pequeno (Tipo de Contrato, Tipo de Planilha, Cond. Pagto, Natureza) devem mostrar uma
  // listinha de sugestoes ao digitar, o que o po-lookup NAO faz (so abre modal via lupa/TAB) --
  // so o po-combo tem essa busca com lista suspensa. Cliente/Fornecedor continua em po-lookup
  // (lista grande, varias lojas por codigo, precisa da janela de busca com colunas).
  // [p-emit-object-value]="true" no template faz o po-combo devolver o objeto INTEIRO (nao so o
  // "value") no (p-change) -- por isso cada opcao carrega o item original (...item) alem de
  // value/label, pra quem precisar de campos extras (ex: TipoContratoItem.tipo).
  private criarComboFilter<T extends { codigo: string; descricao: string }>(
    buscar: (filtro: string) => Observable<{ items: T[] }>,
    formatarLabel: (item: T) => string = item => item.codigo + ' - ' + item.descricao
  ): PoComboFilter {
    const paraOpcao = (item: T): PoComboOption => ({ value: item.codigo, label: formatarLabel(item), ...item });
    return {
      getFilteredData: (param: { value?: string }) => buscar(param?.value ?? '').pipe(map(resp => resp.items.map(paraOpcao))),
      getObjectByValue: (value: string | number) =>
        buscar(String(value)).pipe(
          map(resp => {
            const item = resp.items.find(i => i.codigo === String(value));
            return item ? paraOpcao(item) : ({ value, label: String(value) } as PoComboOption);
          })
        )
    };
  }

  readonly tipoContratoComboFilter: PoComboFilter = this.criarComboFilter(
    filtro => this.contratoService.lookupTipoContrato(filtro).pipe(map(resp => ({ items: resp.items.filter(item => item.tipo === this.tipo) })))
  );

  readonly condPagtoComboFilter: PoComboFilter = this.criarComboFilter(filtro => this.contratoService.lookupCondPagto(filtro));

  readonly naturezaComboFilter: PoComboFilter = this.criarComboFilter(filtro => this.contratoService.lookupNatureza(filtro));

  readonly tipoPlanilhaComboFilter: PoComboFilter = this.criarComboFilter(filtro => this.contratoService.lookupTipoPlanilha(filtro));

  readonly subtitulo = 'Cadastre e gerencie as informações do contrato';

  constructor(
    private readonly route: ActivatedRoute,
    private readonly router: Router,
    private readonly contratoService: ContratoService,
    private readonly poNotification: PoNotificationService,
    private readonly poDialog: PoDialogService,
    private readonly protheusBridge: ProtheusBridgeService
  ) {
    const numeroParam = this.route.snapshot.paramMap.get('numero');
    this.modo = numeroParam ? 'editar' : 'criar';
    if (this.modo === 'editar') {
      this.numero = numeroParam ?? '';
      this.revisao = this.route.snapshot.paramMap.get('revisao') ?? '';
    } else {
      const tipoParam = this.route.snapshot.queryParamMap.get('tipo');
      this.tipo = tipoParam === 'V' ? 'V' : 'C';
      this.filialParaIncluir = this.route.snapshot.queryParamMap.get('filial') ?? '';
    }
    this.recalcularAcoesRelacionadas();
  }

  voltarLista(): void {
    this.router.navigate(['contratos']);
  }

  ngOnInit(): void {
    this.carregarDominios();
    if (this.modo === 'editar') {
      this.carregar();
    } else {
      // Tela nativa ja abre com a "Planilha000001" -- mesmo aqui.
      this.adicionarPlanilha();
      // Pre-preenche "Nr. Contrato" com a sugestao do contador automatico (GetSxeNum) -- o
      // campo continua editavel, o usuario pode trocar antes de salvar. Falha aqui nao deve
      // travar a tela: so deixa o campo em branco pro usuario digitar manualmente.
      this.contratoService.sugerirProximoNumero().subscribe({
        next: resp => {
          this.numero = resp.numero;
        },
        error: () => {
          // silencioso -- campo fica em branco, mesmo comportamento de antes desta feature.
        }
      });
    }
  }

  get titulo(): string {
    if (this.modo === 'criar') {
      return this.tipo === 'C' ? 'Novo Contrato de Compra' : 'Novo Contrato de Venda';
    }
    return 'Contrato ' + this.numero + '/' + this.revisao + ' - Alteração';
  }

  get labelPessoa(): string {
    return this.tipo === 'C' ? 'Fornecedor' : 'Cliente';
  }

  get textoTotalGeral(): string {
    return formatarValor(this.valorTotalGeral);
  }

  get especieLabel(): string {
    return this.tipo === 'C' ? 'Compra' : 'Venda';
  }

  // Nomes dos campos opcionais que nao existem no dicionario deste ambiente ("" se todos existem).
  get camposIndisponiveis(): string {
    return Object.entries(this.campos)
      .filter(([, existe]) => !existe)
      .map(([chave]) => ROTULO_CAMPO[chave] ?? chave)
      .join(', ');
  }

  get situacaoLabel(): string {
    return (
      this.situacaoAtualDescricao ||
      SITUACOES_CONTRATO_OPTIONS.find(opcao => opcao.value === this.situacaoAtual)?.label ||
      this.situacaoAtual
    );
  }

  // "Data Final" nao e um campo do backend -- calculada no cliente (dataInicio + vigencia,
  // conforme unidadeVigencia). Retorna string (primitivo), seguro pra chamar direto no
  // template.
  get dataFinalCalculada(): string {
    if (!this.dataInicio || !this.vigencia) {
      return '';
    }
    const data = new Date(this.dataInicio + 'T00:00:00');
    if (this.unidadeVigencia === '1') {
      data.setDate(data.getDate() + this.vigencia);
    } else if (this.unidadeVigencia === '2') {
      data.setMonth(data.getMonth() + this.vigencia);
    } else if (this.unidadeVigencia === '3') {
      data.setFullYear(data.getFullYear() + this.vigencia);
    } else {
      return '';
    }
    return data.toISOString().slice(0, 10);
  }

  get valorTotalGeral(): number {
    return this.planilhas.reduce((total, planilha) => total + this.valorTotalPlanilha(planilha), 0);
  }

  valorTotalPlanilha(planilha: PlanilhaForm): number {
    return planilha.itens.reduce((total, item) => {
      const bruto = (item.quantidade || 0) * (item.valorUnitario || 0);
      return total + bruto - bruto * ((item.desconto || 0) / 100);
    }, 0);
  }

  // Planilha para a qual o modal de cronograma ("Editar Parcela"/"Incluir Cronograma") foi
  // aberto -- sempre a planilha da aba selecionada no momento do clique (ver abrirCronograma()).
  get planilhaCronogramaAtual(): PlanilhaForm | null {
    return this.planilhas[this.planilhaSelecionadaIndex] ?? null;
  }

  get totalPlanilhaCronograma(): number {
    return this.planilhaCronogramaAtual ? this.valorTotalPlanilha(this.planilhaCronogramaAtual) : 0;
  }

  get tituloCronograma(): string {
    return this.planilhaCronogramaAtual
      ? this.tituloPlanilha(this.planilhaCronogramaAtual, this.planilhaSelecionadaIndex)
      : 'Cronograma Financeiro/Físico';
  }

  get saldoADistribuirCronograma(): number {
    const distribuido = this.crgParcelas.reduce((total, parcela) => total + (parcela.valor || 0), 0);
    return this.totalPlanilhaCronograma - distribuido;
  }

  onTipoContratoSelecionado(item: TipoContratoItem | undefined): void {
    this.tipoContratoSelecionado = item ?? null;
  }

  onCondPagtoSelecionado(item: CondPagtoItem | undefined): void {
    this.condPagtoSelecionado = item ?? null;
  }

  onNaturezaSelecionada(item: NaturezaItem | undefined): void {
    this.naturezaSelecionada = item ?? null;
  }

  // ---------- Listas de apoio (moeda, indice, combos da planilha) ----------

  private carregarDominios(): void {
    this.contratoService.lookupMoeda().subscribe({
      next: resp => {
        this.moedaOptions = resp.items.map(item => ({
          value: item.codigo,
          label: String(item.codigo).padStart(2, '0') + ' - ' + item.descricao
        }));
      },
      error: resp => this.poNotification.warning(resp?.message ?? 'Não foi possível carregar as moedas cadastradas.')
    });

    this.contratoService.lookupIndice().subscribe({
      next: resp => {
        this.indiceOptions = resp.items.map(item => ({ value: item.codigo, label: item.codigo + ' - ' + item.descricao }));
      },
      error: resp => {
        this.erroIndice = resp?.message ?? 'Não foi possível carregar os índices de reajuste cadastrados.';
      }
    });

    this.contratoService.dominiosPlanilha().subscribe({
      next: resp => {
        this.campos = resp.campos;
        this.mapaCampos = Object.entries(resp.mapa ?? {})
          .map(([chave, campo]) => (ROTULO_CAMPO[chave] ?? chave) + ' → ' + (campo || '(nenhum)'))
          .join('; ');
        if (resp.unidades?.length) {
          this.unidadePeriodicidadeOptions = resp.unidades;
        }
        this.modoReajusteOptions = resp.modosReajuste ?? [];
      },
      error: () => {
        // silencioso -- sem a resposta, os campos ficam habilitados como estao por padrao
      }
    });
  }

  // ---------- Planilhas (uma aba por planilha) ----------

  tituloPlanilha(planilha: PlanilhaForm, indice: number): string {
    return 'Planilha' + (planilha.numero || String(indice + 1)).padStart(6, '0');
  }

  selecionarPlanilha(indice: number): void {
    this.planilhaSelecionadaIndex = indice;
  }

  private hojeIso(): string {
    const d = new Date();
    return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0');
  }

  adicionarPlanilha(): void {
    this.planilhas = [
      ...this.planilhas,
      {
        tipoPlanilha: '',
        dataInicio: '',
        dataFim: '',
        pessoaCodigo: '',
        pessoaSelecionada: null,
        itens: [],
        descricao: '',
        indice: '',
        periodicidade: 0,
        unidadePer: '',
        modoReajuste: '',
        dataBase: this.hojeIso(),
        exigeCronograma: true
      }
    ];
    this.planilhaSelecionadaIndex = this.planilhas.length - 1;
  }

  removerPlanilha(indice: number): void {
    this.planilhas = this.planilhas.filter((_, i) => i !== indice);
    this.planilhaSelecionadaIndex = this.planilhas.length > 0 ? Math.min(indice, this.planilhas.length - 1) : -1;
  }

  onPessoaSelecionada(planilha: PlanilhaForm, item: Pessoa | undefined): void {
    planilha.pessoaSelecionada = item ?? null;
  }

  // Tipo de planilha escolhido decide se a Periodicidade fica liberada (exige cronograma
  // financeiro/fisico) ou somente leitura -- ver TipoPlanilhaItem.exigeCronograma/ZcnTpPla.
  // "undefined" (campo nao localizado no dicionario deste ambiente) mantem liberada, mesmo
  // comportamento de antes desta feature.
  onTipoPlanilhaSelecionado(planilha: PlanilhaForm, item: TipoPlanilhaItem | undefined): void {
    planilha.exigeCronograma = item?.exigeCronograma ?? true;
    if (!planilha.exigeCronograma) {
      planilha.periodicidade = 0;
    }
  }

  onItensAlterados(indice: number, itens: ItemPlanilha[]): void {
    if (this.planilhas[indice]) {
      this.planilhas[indice].itens = itens;
    }
  }

  // ---------- Carregar / salvar ----------

  private carregar(): void {
    this.carregando = true;
    this.contratoService.detalhe(this.numero, this.revisao).subscribe({
      next: resp => {
        this.carregando = false;
        this.numero = resp.header.numero;
        this.revisao = resp.header.revisao;
        this.definirContrato(resp);
      },
      error: resp => {
        this.carregando = false;
        this.poNotification.error(resp?.message ?? 'Falha ao consultar o contrato.');
      }
    });
  }

  private definirContrato(contrato: Contrato): void {
    this.tipo = contrato.header.tipo;
    this.descricao = contrato.header.descricao ?? '';
    this.dataInicio = contrato.header.dataInicio;
    this.unidadeVigencia = contrato.header.unidadeVigencia;
    this.vigencia = contrato.header.vigencia;
    this.moeda = contrato.header.moeda;
    this.condPagtoCodigo = contrato.header.condPagto;
    this.tipoContratoCodigo = contrato.header.tipoContrato;
    this.situacaoAtual = contrato.header.situacao;
    this.situacaoAtualDescricao = contrato.header.situacaoDescricao ?? '';
    this.temCronograma = contrato.header.temCronograma;
    this.dtAssinatura = contrato.header.dtAssinatura ?? '';
    this.objeto = contrato.header.objeto ?? '';
    this.clausula = contrato.header.clausula ?? '';
    this.justificativa = contrato.header.justificativa ?? '';
    this.naturezaCodigo = contrato.header.natureza ?? '';

    this.planilhas = contrato.planilhas.map(planilha => ({
      numero: planilha.numero,
      tipoPlanilha: planilha.tipoPlanilha,
      dataInicio: planilha.dataInicio,
      dataFim: planilha.dataFim,
      pessoaCodigo: planilha.pessoa.codigo,
      pessoaSelecionada: planilha.pessoa,
      itens: planilha.itens,
      descricao: planilha.descricao ?? '',
      indice: planilha.indice ?? '',
      periodicidade: planilha.periodicidade ?? 0,
      unidadePer: planilha.unidadePer ?? '',
      modoReajuste: planilha.modoReajuste ?? '',
      dataBase: planilha.dataBase ?? '',
      // Em modo editar a Periodicidade ja fica desabilitada pelo proprio modo (ver template) --
      // o valor aqui e irrelevante, mas .T. evita um "somente leitura" incorreto se algum dia a
      // regra mudar.
      exigeCronograma: true
    }));
    this.planilhaSelecionadaIndex = this.planilhas.length > 0 ? 0 : -1;

    const situacoesValidas = TRANSICOES_SITUACAO[contrato.header.situacao] ?? [];
    this.transicoesDisponiveis = SITUACOES_CONTRATO_OPTIONS.filter(opcao => situacoesValidas.includes(opcao.value));

    this.revisoesGrid = contrato.revisoes.map(revisao => ({
      tipoLabel: TIPOS_REVISAO_OPTIONS.find(opcao => opcao.value === revisao.tipo)?.label ?? revisao.tipo,
      justificativa: revisao.justificativa,
      data: revisao.data,
      situacaoLabel:
        revisao.situacaoDescricao ||
        SITUACOES_CONTRATO_OPTIONS.find(opcao => opcao.value === revisao.situacao)?.label ||
        revisao.situacao
    }));

    this.recalcularAcoesRelacionadas();
    this.carregarTimeline();

    // Desc. Tipo / Desc. Pagto (readonly, na aba Cadastrais) nao vem no header -- resolve via
    // o proprio lookup (getObjectByValue), sem precisar de um campo novo no backend so pra isso.
    if (this.tipoContratoCodigo) {
      this.tipoContratoFilter.getObjectByValue(this.tipoContratoCodigo).subscribe(item => {
        this.tipoContratoSelecionado = (item as TipoContratoItem) ?? null;
      });
    }
    if (this.condPagtoCodigo) {
      this.condPagtoFilter.getObjectByValue(this.condPagtoCodigo).subscribe(item => {
        this.condPagtoSelecionado = (item as CondPagtoItem) ?? null;
      });
    }
    if (this.naturezaCodigo) {
      this.naturezaFilter.getObjectByValue(this.naturezaCodigo).subscribe(item => {
        this.naturezaSelecionada = (item as NaturezaItem) ?? null;
      });
    }
  }

  // "Ações Relacionadas" (renomeado de "Outras Ações" -- pedido do usuario 2026-08-11) fica
  // visivel nos 2 modos ("Faltou o botao Ações Relacionadas com Criar cronograma financeiro"
  // na tela de novo contrato) -- mas Nova Revisão/Aprovar Revisão/Mudar Situação/Cronograma
  // dependem de um contrato JA SALVO (numero+revisao reais), entao ficam desabilitadas em modo
  // criar em vez de escondidas -- o usuario ve a opção existe, só não pode usar antes de
  // Confirmar pela 1a vez.
  private recalcularAcoesRelacionadas(): void {
    const semContratoSalvo = this.modo === 'criar';
    this.acoesRelacionadasItems = [
      { label: 'Nova Revisão', disabled: semContratoSalvo, action: () => this.novaRevisao() },
      { label: 'Aprovar Revisão', disabled: semContratoSalvo, action: () => this.aprovarRevisao() },
      {
        label: 'Mudar Situação',
        disabled: semContratoSalvo || this.transicoesDisponiveis.length === 0,
        subItems: this.transicoesDisponiveis.map(transicao => ({
          label: 'Mudar para ' + transicao.label,
          action: () => this.alterarSituacao(transicao.value)
        }))
      },
      {
        label: this.temCronograma ? 'Criar cronograma financeiro (já gerado)' : 'Criar cronograma financeiro',
        disabled: semContratoSalvo || this.temCronograma,
        action: () => this.abrirCronograma()
      }
    ];
  }

  confirmar(): void {
    if (this.modo === 'criar') {
      this.criar();
    } else {
      this.atualizar();
    }
  }

  private criar(): void {
    if (!this.numero.trim()) {
      this.poNotification.warning('Informe o número do contrato.');
      return;
    }
    if (!this.dataInicio) {
      this.poNotification.warning('Informe a data de início do contrato.');
      return;
    }
    if (!this.tipoContratoSelecionado) {
      this.poNotification.warning('Selecione o Tipo de Contrato.');
      return;
    }
    if (this.planilhas.length === 0) {
      this.poNotification.warning('Adicione ao menos uma planilha.');
      return;
    }
    const planilhaSemTipo = this.planilhas.findIndex(planilha => !planilha.tipoPlanilha.trim());
    if (planilhaSemTipo >= 0) {
      this.planilhaSelecionadaIndex = planilhaSemTipo;
      this.poNotification.warning('Informe o tipo de planilha (' + this.tituloPlanilha(this.planilhas[planilhaSemTipo], planilhaSemTipo) + ').');
      return;
    }
    const planilhaSemPessoa = this.planilhas.findIndex(planilha => !planilha.pessoaSelecionada);
    if (planilhaSemPessoa >= 0) {
      this.planilhaSelecionadaIndex = planilhaSemPessoa;
      this.poNotification.warning(
        'Selecione o ' + this.labelPessoa.toLowerCase() + ' (' + this.tituloPlanilha(this.planilhas[planilhaSemPessoa], planilhaSemPessoa) + ').'
      );
      return;
    }
    const planilhaSemItens = this.planilhas.findIndex(planilha => planilha.itens.length === 0);
    if (planilhaSemItens >= 0) {
      this.planilhaSelecionadaIndex = planilhaSemItens;
      this.poNotification.warning('Adicione ao menos um item em cada planilha.');
      return;
    }

    this.salvando = true;
    this.contratoService
      .criar({
        filial: this.filialParaIncluir || undefined,
        header: {
          numero: this.numero.trim(),
          dataInicio: this.dataInicio,
          unidadeVigencia: this.unidadeVigencia,
          vigencia: this.vigencia,
          moeda: this.moeda,
          descricao: this.descricao.trim() || undefined,
          condPagto: this.condPagtoCodigo,
          tipoContrato: this.tipoContratoSelecionado.codigo,
          justificativa: this.justificativa.trim() || undefined,
          dtAssinatura: this.dtAssinatura || undefined,
          // Vl. Inicial/Vl. Atual (CN9_VLINI/CN9_VLATU) = total calculado das planilhas na criacao --
          // ainda nao existe reajuste, entao os dois sao iguais nesse momento (nao aparecem mais na tela).
          valorInicial: this.valorTotalGeral,
          valorAtual: this.valorTotalGeral,
          objeto: this.objeto.trim() || undefined,
          clausula: this.clausula.trim() || undefined,
          natureza: this.naturezaCodigo || undefined
        },
        planilhas: this.planilhas.map(planilha => ({
          tipoPlanilha: planilha.tipoPlanilha,
          // CNA_DTINI e obrigatorio no modelo (VLDDATA_OBRIGAT) -- a planilha herda o prazo do contrato
          // (Data de inicio / Data final calculada), a tela nativa nao tem campos de data na planilha.
          dataInicio: planilha.dataInicio || this.dataInicio || undefined,
          dataFim: planilha.dataFim || this.dataFinalCalculada || undefined,
          pessoa: planilha.pessoaSelecionada
            ? { codigo: planilha.pessoaSelecionada.codigo, loja: planilha.pessoaSelecionada.loja }
            : undefined,
          descricao: planilha.descricao.trim() || undefined,
          indice: planilha.indice || undefined,
          periodicidade: planilha.periodicidade || undefined,
          unidadePer: planilha.unidadePer || undefined,
          modoReajuste: planilha.modoReajuste || undefined,
          dataBase: planilha.dataBase || undefined,
          itens: planilha.itens.map(item => ({
            produto: item.produto,
            unidade: item.unidade,
            quantidade: item.quantidade,
            valorUnitario: item.valorUnitario,
            cc: item.cc,
            tes: item.tes,
            pedTit: item.pedTit,
            desconto: item.desconto
          }))
        }))
      })
      .subscribe({
        next: resp => {
          this.salvando = false;
          this.modo = 'editar';
          this.numero = resp.header.numero;
          this.revisao = resp.header.revisao;
          this.definirContrato(resp);
          // NAO navega para /contratos/{numero}/{revisao} aqui -- "contratos/novo" e
          // "contratos/:numero/:revisao" sao rotas DIFERENTES, entao router.navigate() destroi
          // e recria o componente (nao so atualiza a URL). Isso disparava um novo ngOnInit ->
          // carregar() enquanto os lookups assincronos de definirContrato() (tipoContrato/
          // condPagto via getObjectByValue) ainda podiam estar em andamento, causando
          // "Cannot read properties of undefined (reading 'numero')" no bridge (observable
          // sendo destruido no meio de uma resposta pendente). Ficar na MESMA instancia, so
          // com modo/numero/revisao atualizados, resolve -- a URL so fica desatualizada (ainda
          // mostra /contratos/novo), mas a tela em si passa a se comportar como "editar".
          this.poNotification.success('Contrato criado com sucesso.');
          this.avisarCamposNaoGravados(resp.avisos);
          if (!resp.header.temCronograma) {
            this.modalCronogramaPendente.open();
          }
        },
        error: resp => {
          this.salvando = false;
          this.poNotification.error(resp?.message ?? 'Falha ao criar o contrato.');
        }
      });
  }

  cronogramaPendenteCriarAgora(): void {
    this.modalCronogramaPendente.close();
    this.abrirCronograma();
  }

  cronogramaPendenteSalvarSemCronograma(): void {
    this.modalCronogramaPendente.close();
  }

  cronogramaPendenteVoltarElaboracao(): void {
    this.modalCronogramaPendente.close();
  }

  private atualizar(): void {
    this.salvando = true;
    this.contratoService
      .atualizar({
        numero: this.numero,
        revisao: this.revisao,
        header: {
          descricao: this.descricao.trim() || undefined,
          justificativa: this.justificativa.trim() || undefined,
          dtAssinatura: this.dtAssinatura || undefined,
          objeto: this.objeto.trim() || undefined,
          clausula: this.clausula.trim() || undefined,
          natureza: this.naturezaCodigo || undefined
        }
      })
      .subscribe({
        next: resp => {
          this.salvando = false;
          this.poNotification.success('Contrato atualizado com sucesso.');
          this.avisarCamposNaoGravados(resp.avisos);
          this.definirContrato(resp);
        },
        error: resp => {
          this.salvando = false;
          this.poNotification.error(resp?.message ?? 'Falha ao atualizar o contrato.');
        }
      });
  }

  // Campos que o backend nao gravou por nao existirem no dicionario do ambiente (ZcnPlaSet).
  private avisarCamposNaoGravados(avisos: string[] | undefined): void {
    if (avisos?.length) {
      this.poNotification.warning(
        'Salvo, mas estes campos não foram gravados (não localizados no dicionário): ' +
          avisos.map(chave => ROTULO_CAMPO[chave] ?? chave).join(', ') +
          '.'
      );
    }
  }

  cancelar(): void {
    this.poDialog.confirm({
      title: 'Cancelar',
      message:
        this.modo === 'criar' ? 'Deseja realmente cancelar e descartar este contrato?' : 'Deseja realmente cancelar as alterações?',
      confirm: () => {
        if (this.protheusBridge.insideProtheus()) {
          this.protheusBridge.fecharApp();
        } else {
          this.router.navigate(['contratos']);
        }
      }
    });
  }

  // ---------- Outras Ações (modo editar): Revisão / Situação / Cronograma ----------

  novaRevisao(): void {
    this.router.navigate(['contratos', this.numero, this.revisao, 'revisao']);
  }

  aprovarRevisao(): void {
    this.carregando = true;
    this.contratoService.revisaoAprovar(this.numero, this.revisao).subscribe({
      next: resp => {
        this.carregando = false;
        this.definirContrato(resp);
        this.poNotification.success('Revisão aprovada com sucesso.');
      },
      error: resp => {
        this.carregando = false;
        this.poNotification.error(resp?.message ?? 'Falha ao aprovar a revisão.');
      }
    });
  }

  alterarSituacao(novaSituacao: SituacaoContrato): void {
    this.carregando = true;
    const obs = this.obsSituacao.trim();
    this.contratoService.alterarSituacao(this.numero, this.revisao, novaSituacao, obs).subscribe({
      next: resp => {
        this.carregando = false;
        this.obsSituacao = '';
        this.definirContrato(resp);
        this.poNotification.success('Situação atualizada com sucesso.');
      },
      error: resp => {
        this.carregando = false;
        this.poNotification.error(resp?.message ?? 'Falha ao alterar a situação do contrato.');
      }
    });
  }

  // Confirma antes de mover a situação -- a transição é aplicada pelo backend (RTM003App::ZcnSit)
  // gravando CN9_SITUAC direto, sem as travas nativas do CNTA300, e registrando o evento na ZLG.
  confirmarMudancaSituacao(alvo: { value: SituacaoContrato; label: string }): void {
    this.poDialog.confirm({
      title: 'Mudar situação do contrato',
      message: `Mover o contrato de "${this.situacaoLabel}" para "${alvo.label}"?`,
      confirm: () => this.alterarSituacao(alvo.value)
    });
  }

  carregarTimeline(): void {
    if (this.modo !== 'editar' || !this.numero) {
      this.timelineGrid = [];
      return;
    }
    this.carregandoTimeline = true;
    this.contratoService.timeline(this.numero).subscribe({
      next: resp => {
        this.carregandoTimeline = false;
        this.timelineGrid = (resp.eventos ?? []).map(evento => ({
          ...evento,
          situacaoTransicao:
            evento.antesLabel && evento.depoisLabel
              ? `${evento.antesLabel} → ${evento.depoisLabel}`
              : evento.depoisLabel || evento.antesLabel || ''
        }));
      },
      error: () => {
        // silencioso -- timeline é informativa, não bloqueia a tela
        this.carregandoTimeline = false;
        this.timelineGrid = [];
      }
    });
  }

  abrirCronograma(): void {
    // Pre-preenche a Periodicidade com a ja escolhida na planilha (Fase 5), se houver -- gesto
    // de "editar" em vez de sempre comecar do zero (pedido do usuario pro botao "Editar Parcela").
    const planilhaAtual = this.planilhaCronogramaAtual;
    this.crgPeriodicidade =
      planilhaAtual?.periodicidade && this.periodicidadeOptions.some(opcao => opcao.value === planilhaAtual.periodicidade)
        ? planilhaAtual.periodicidade
        : 1;
    this.crgDias = 30;
    this.crgUltimoDiaMes = 1;
    this.crgCompetenciaInicio = '';
    this.crgDataPrevista = this.dataInicio;
    this.crgQtdParcelas = 1;
    this.crgCondPagtoCodigo = this.condPagtoCodigo;
    this.crgTaxaJuros = 0;
    this.crgParcelas = [];
    this.modalCronograma.open();
  }

  // Previa local: divide o total da planilha em partes iguais entre "Quantidade de Parcelas",
  // avancando a competencia conforme a Periodicidade escolhida (Quinzenal = +15 dias, Diario =
  // +"Dia(s)" dias, Mensal/Cond.Pagto = +1 mes, aproximacao razoavel so para a previa -- o
  // calculo real de datas de Cond.Pagto e feito pela rotina nativa no "Confirmar"). A ultima
  // parcela absorve a diferenca de arredondamento das anteriores, pra fechar exatamente no total.
  distribuirCronograma(): void {
    const qtd = Math.max(Math.trunc(this.crgQtdParcelas || 0), 0);
    if (qtd === 0) {
      this.poNotification.warning('Informe a quantidade de parcelas.');
      return;
    }
    const total = this.totalPlanilhaCronograma;
    const valorParcela = Math.round((total / qtd) * 10000) / 10000;
    const dataBase = this.crgDataPrevista ? new Date(this.crgDataPrevista + 'T00:00:00') : new Date();
    const parcelas: typeof this.crgParcelas = [];
    let somaAcumulada = 0;

    for (let indice = 0; indice < qtd; indice++) {
      const data = new Date(dataBase);
      if (this.crgPeriodicidade === 2) {
        data.setDate(data.getDate() + indice * 15);
      } else if (this.crgPeriodicidade === 3) {
        data.setDate(data.getDate() + indice * (this.crgDias || 30));
      } else {
        data.setMonth(data.getMonth() + indice);
      }
      const valor = indice === qtd - 1 ? Math.round((total - somaAcumulada) * 10000) / 10000 : valorParcela;
      somaAcumulada += valor;
      const dataIso = data.toISOString().slice(0, 10);
      parcelas.push({
        parcela: indice + 1,
        competencia: dataIso.slice(5, 7) + '/' + dataIso.slice(0, 4),
        data: dataIso,
        valor,
        saldo: Math.round((total - somaAcumulada) * 10000) / 10000
      });
    }

    this.crgParcelas = parcelas;
  }

  removerTodasParcelas(): void {
    this.crgParcelas = [];
    this.crgQtdParcelas = 0;
  }

  adicionarParcelaManual(): void {
    this.crgQtdParcelas = (this.crgQtdParcelas || 0) + 1;
    this.distribuirCronograma();
  }

  salvarCronograma(): void {
    if (!this.crgCompetenciaInicio.trim()) {
      this.poNotification.warning('Informe a competência de início (MM/AAAA).');
      return;
    }
    if (!this.crgDataPrevista) {
      this.poNotification.warning('Informe a data prevista da 1ª medição.');
      return;
    }

    this.gerandoCronograma = true;
    this.contratoService
      .gerarCronograma({
        numero: this.numero,
        revisao: this.revisao,
        periodicidade: this.crgPeriodicidade,
        dias: this.crgDias,
        ultimoDiaMes: this.crgUltimoDiaMes,
        competenciaInicio: this.crgCompetenciaInicio.trim(),
        dataPrevista: this.crgDataPrevista,
        qtdParcelas: this.crgQtdParcelas,
        condPagto: this.crgCondPagtoCodigo,
        taxaJuros: this.crgTaxaJuros
      })
      .subscribe({
        next: resp => {
          this.gerandoCronograma = false;
          this.definirContrato(resp);
          this.poNotification.success('Cronograma financeiro/físico gerado com sucesso.');
          this.crgParcelas = [];
          this.modalCronograma.close();
        },
        error: resp => {
          this.gerandoCronograma = false;
          this.poNotification.error(resp?.message ?? 'Falha ao gerar o cronograma financeiro/físico.');
        }
      });
  }
}
