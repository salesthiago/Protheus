import { CommonModule } from '@angular/common';
import { Component, OnInit, ViewChild } from '@angular/core';
import { FormsModule } from '@angular/forms';
import {
  PoButtonModule,
  PoDialogService,
  PoFieldModule,
  PoIconModule,
  PoInfoModule,
  PoNotificationService,
  PoPageModule,
  PoSelectOption,
  PoTableColumn,
  PoTableComponent,
  PoTableModule
} from '@po-ui/ng-components';
import * as XLSX from 'xlsx';
import { ExportarContratoResponse, ParcelaCronograma, Pessoa, PlanilhaExport } from '../../models/importacao.model';
import { MedicaoService } from '../../services/medicao.service';
import { ProtheusBridgeService } from '../../services/protheus-bridge.service';

// Aba Exportar do rtm002 (porta POUI de RT69M001.prw). Ao contrario de RT69M001.prw, que
// exporta CSV com todas as planilhas do contrato e so o 1o fornecedor/cliente encontrado,
// aqui o usuario escolhe quais planilhas exportar (checklist), filtra por fornecedor/cliente
// quando o contrato tiver mais de um vinculado, e pode incluir o cronograma financeiro (CNF)
// como segunda aba do arquivo. Gera um .xlsx com abas nativas via SheetJS (lib "xlsx") --
// ver Static Function ListaPlan/ExportarCtr em Contratos/RTM002App.prw.
@Component({
  selector: 'app-exportar-medicao',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    PoPageModule,
    PoButtonModule,
    PoFieldModule,
    PoTableModule,
    PoInfoModule,
    PoIconModule
  ],
  templateUrl: './exportar-medicao.component.html',
  styleUrl: './exportar-medicao.component.css'
})
export class ExportarMedicaoComponent implements OnInit {
  readonly iconClear = 'ICON_CLEAR_CONTENT';
  readonly iconDownload = 'ICON_DOWNLOAD';
  readonly iconInfo = 'ICON_INFO';

  readonly planilhaColumns: Array<PoTableColumn> = [
    { property: 'numero', label: 'Planilha' },
    { property: 'nome', label: 'Fornecedor/Cliente' },
    { property: 'valorTotal', label: 'Valor Total', type: 'currency', format: 'BRL' },
    { property: 'qtdItens', label: 'Qtd. Itens', type: 'number' }
  ];

  readonly cronogramaColumns: Array<PoTableColumn> = [
    { property: 'planilha', label: 'Planilha' },
    { property: 'competencia', label: 'Competência' },
    { property: 'parcela', label: 'Parcela' },
    { property: 'valorPrevisto', label: 'Valor Previsto', type: 'currency', format: 'BRL' },
    { property: 'saldo', label: 'Saldo', type: 'currency', format: 'BRL' }
  ];

  @ViewChild('tabelaPlanilhas') tabelaPlanilhas!: PoTableComponent;

  numContrato = '';
  revisao = '';
  buscando = false;
  contratoCarregado = false;

  tipoContrato: 'C' | 'V' | '' = '';
  labelPessoa = 'Cliente';
  pessoas: Array<Pessoa> = [];
  pessoaOptions: Array<PoSelectOption> = [];
  pessoaSelecionada = '';

  carregandoPlanilhas = false;
  planilhas: Array<PlanilhaExport> = [];
  incluirCronograma = false;
  incluirUltimaMedicao = false;

  planilhasSelecionadas: Array<string> = [];
  carregandoCronograma = false;
  cronogramaCarregado = false;
  cronograma: Array<ParcelaCronograma> = [];

  exportando = false;

  constructor(
    private readonly medicaoService: MedicaoService,
    private readonly poNotification: PoNotificationService,
    private readonly poDialog: PoDialogService,
    private readonly protheusBridge: ProtheusBridgeService
  ) {}

  ngOnInit(): void {
    // Contrato ja posicionado no browse (CNTA100) quando o usuario abriu a tela -- carrega de
    // imediato em vez de exigir que o usuario digite o numero de novo (ver Static Function
    // CtxPos em Contratos/RTM002App.prw).
    this.medicaoService.contratoPosicionado().subscribe({
      next: resp => {
        if (resp.temContrato) {
          this.numContrato = resp.numContrato;
          this.revisao = resp.revisao;
          this.buscarContrato();
        }
      },
      error: () => {
        // Sem contexto de contrato posicionado (ex.: tela aberta fora do fluxo do browse) --
        // usuario digita normalmente, mesmo comportamento de antes.
      }
    });
  }

  buscarContrato(): void {
    if (!this.numContrato) {
      this.poNotification.warning('Informe o número do contrato.');
      return;
    }

    this.buscando = true;
    this.medicaoService.cabecalhoContrato(this.numContrato, this.revisao).subscribe({
      next: resp => {
        this.buscando = false;
        this.contratoCarregado = true;
        this.tipoContrato = resp.tipo;
        this.labelPessoa = resp.tipo === 'C' ? 'Fornecedor' : 'Cliente';
        this.pessoas = resp.pessoas;
        this.pessoaOptions = resp.pessoas.map(pessoa => ({
          value: `${pessoa.codigo}|${pessoa.loja}`,
          label: `${pessoa.codigo}/${pessoa.loja} - ${pessoa.nome}`
        }));
        // Com so um fornecedor/cliente, ja usa ele como filtro; com mais de um, comeca sem
        // filtro (lista as planilhas de todos) ate o usuario escolher.
        this.pessoaSelecionada = this.pessoaOptions.length === 1 ? String(this.pessoaOptions[0].value) : '';

        if (this.pessoas.length === 0) {
          this.poNotification.warning(`Nenhum ${this.labelPessoa.toLowerCase()} encontrado vinculado a este contrato.`);
        }

        this.carregarPlanilhas();
      },
      error: resp => {
        this.buscando = false;
        this.poNotification.error(resp?.message ?? 'Falha ao consultar o cabeçalho do contrato.');
      }
    });
  }

  onPessoaAlterada(valor: string): void {
    this.pessoaSelecionada = valor;
    this.carregarPlanilhas();
  }

  private carregarPlanilhas(): void {
    const [codigoPessoa, lojaPessoa] = this.pessoaSelecionada ? this.pessoaSelecionada.split('|') : ['', ''];

    this.carregandoPlanilhas = true;
    this.planilhasSelecionadas = [];
    this.cronogramaCarregado = false;
    this.cronograma = [];
    this.medicaoService.listarPlanilhas(this.numContrato, this.revisao, codigoPessoa, lojaPessoa).subscribe({
      next: resp => {
        this.carregandoPlanilhas = false;
        this.planilhas = resp.planilhas;
        if (this.planilhas.length === 0) {
          this.poNotification.warning('Nenhuma planilha encontrada para este contrato/fornecedor/cliente.');
        }
      },
      error: resp => {
        this.carregandoPlanilhas = false;
        this.poNotification.error(resp?.message ?? 'Falha ao consultar as planilhas do contrato.');
      }
    });
  }

  // Disparado pelos eventos p-selected/p-unselected/p-all-selected/p-all-unselected do
  // po-table de planilhas -- mantém a pré-visualização do cronograma financeiro em dia com o
  // checklist marcado, sem depender do botão "Exportar".
  onSelecaoPlanilhaAlterada(): void {
    const selecionadas: Array<PlanilhaExport> = this.tabelaPlanilhas?.itemsSelected ?? [];
    this.planilhasSelecionadas = selecionadas.map(planilha => planilha.numero);
    this.carregarCronograma();
  }

  private carregarCronograma(): void {
    if (!this.incluirCronograma || this.planilhasSelecionadas.length === 0) {
      this.cronogramaCarregado = false;
      this.cronograma = [];
      return;
    }

    this.carregandoCronograma = true;
    this.medicaoService.listarCronograma(this.numContrato, this.revisao, this.planilhasSelecionadas).subscribe({
      next: resp => {
        this.carregandoCronograma = false;
        this.cronogramaCarregado = true;
        this.cronograma = resp.cronograma;
      },
      error: resp => {
        this.carregandoCronograma = false;
        this.cronogramaCarregado = true;
        this.cronograma = [];
        this.poNotification.error(resp?.message ?? 'Falha ao consultar o cronograma financeiro.');
      }
    });
  }

  onIncluirCronogramaAlterado(): void {
    this.carregarCronograma();
  }

  exportar(): void {
    const selecionadas: Array<PlanilhaExport> = this.tabelaPlanilhas?.itemsSelected ?? [];
    if (selecionadas.length === 0) {
      this.poNotification.warning('Selecione ao menos uma planilha para exportar.');
      return;
    }

    this.exportando = true;
    this.medicaoService
      .exportarContrato({
        cNumCont: this.numContrato,
        cRevisao: this.revisao,
        aPlanilhas: selecionadas.map(planilha => planilha.numero),
        lCronograma: this.incluirCronograma,
        lUltimaMed: this.incluirUltimaMedicao
      })
      .subscribe({
        next: resp => {
          this.exportando = false;
          this.gerarXlsx(resp);
        },
        error: resp => {
          this.exportando = false;
          this.poNotification.error(resp?.message ?? 'Falha ao exportar o contrato.');
        }
      });
  }

  private gerarXlsx(resp: ExportarContratoResponse): void {
    const labelPessoa = resp.tipo === 'C' ? 'Fornecedor' : 'Cliente';

    const linhasItens = resp.itens.map(item => ({
      Planilha: item.planilha,
      Item: item.item,
      Produto: item.produto,
      Descrição: item.descricao,
      UM: item.um,
      Quantidade: item.quantidade,
      CC: item.cc,
      'Item CT': item.itemCt,
      'Classe Valor': item.classeValor,
      'Valor Unitário': item.valorUnitario,
      [labelPessoa]: `${item.pessoaCodigo}/${item.pessoaLoja}`,
      'Saldo do Item': item.saldoItem,
      Contrato: item.contrato,
      Revisão: item.revisao,
      Competência: item.competencia
    }));

    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, XLSX.utils.json_to_sheet(linhasItens), 'Contrato');

    if (this.incluirCronograma) {
      const linhasCronograma = resp.cronograma.map(parcela => ({
        Planilha: parcela.planilha,
        'Nº Cronograma': parcela.numero,
        Parcela: parcela.parcela,
        Competência: parcela.competencia,
        'Data Prevista': this.formatarData(parcela.dataPrevista),
        'Valor Previsto': parcela.valorPrevisto,
        '% Máx. Parcela': parcela.maxParcela,
        Saldo: parcela.saldo,
        'Data Realizada': this.formatarData(parcela.dataRealizada)
      }));
      XLSX.utils.book_append_sheet(workbook, XLSX.utils.json_to_sheet(linhasCronograma), 'Cronograma Financeiro');
    }

    if (this.incluirUltimaMedicao) {
      // Colunas na mesma ordem/nome exigidos pela aba Importar (Planilha, Item, Produto,
      // Quantidade obrigatórios; TES, CC opcionais -- ver COLUNAS_OBRIGATORIAS/OPCIONAIS em
      // importacao.model.ts) primeiro, para esta aba poder ser reimportada diretamente sem
      // edição manual do cabeçalho. TES fica em branco -- CNE010 não tem essa coluna (ver
      // CarregaUltMed em Contratos/RTM002App.prw), quem quiser reconhecer TES preenche à mão.
      // Colunas informativas (Nº Medição, Descrição, Valor Unitário, Valor Total, Data Entrega)
      // vêm depois, só para referência -- ignoradas pelo parser de importação.
      const linhasUltimaMedicao = resp.ultimaMedicao.map(item => ({
        Planilha: item.planilha,
        Item: item.item,
        Produto: item.produto,
        Quantidade: item.quantidade,
        TES: '',
        CC: item.cc,
        'Nº Medição': item.numMedicao,
        Descrição: item.descricao,
        'Valor Unitário': item.valorUnitario,
        'Valor Total': item.valorTotal,
        'Data Entrega': this.formatarData(item.dataEntrega)
      }));
      XLSX.utils.book_append_sheet(workbook, XLSX.utils.json_to_sheet(linhasUltimaMedicao), 'Última Medição');
    }

    const nomeArquivo = 'Contrato_' + this.numContrato.replace(/[/\\]/g, '_') + '.xlsx';
    XLSX.writeFile(workbook, nomeArquivo);
  }

  // Converte "AAAAMMDD" (DtoS do ADVPL) para "DD/MM/AAAA"; vazio/em branco vira ''.
  private formatarData(cAaaammdd: string): string {
    const valor = (cAaaammdd ?? '').trim();
    if (valor.length !== 8) {
      return '';
    }
    return `${valor.substring(6, 8)}/${valor.substring(4, 6)}/${valor.substring(0, 4)}`;
  }

  cancelar(): void {
    this.poDialog.confirm({
      title: 'Cancelar',
      message: 'Deseja realmente cancelar e fechar esta tela?',
      confirm: () => this.protheusBridge.fecharApp()
    });
  }

  limpar(): void {
    this.numContrato = '';
    this.revisao = '';
    this.contratoCarregado = false;
    this.tipoContrato = '';
    this.pessoas = [];
    this.pessoaOptions = [];
    this.pessoaSelecionada = '';
    this.planilhas = [];
    this.incluirCronograma = false;
    this.incluirUltimaMedicao = false;
    this.planilhasSelecionadas = [];
    this.carregandoCronograma = false;
    this.cronogramaCarregado = false;
    this.cronograma = [];
  }
}
