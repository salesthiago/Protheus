import { CommonModule } from '@angular/common';
import { Component, OnInit, ViewChild } from '@angular/core';
import { FormsModule } from '@angular/forms';
import {
  PoButtonModule,
  PoDialogService,
  PoFieldModule,
  PoIconModule,
  PoInfoModule,
  PoModalComponent,
  PoModalModule,
  PoNotificationService,
  PoPageModule,
  PoSelectOption,
  PoTableAction,
  PoTableColumn,
  PoTableModule
} from '@po-ui/ng-components';
import {
  COLUNAS_GRID,
  COLUNA_CC,
  COLUNA_CLASSE_VALOR,
  COLUNA_DESCRICAO,
  COLUNA_ITEM,
  COLUNA_PLANILHA,
  COLUNA_PRODUTO,
  COLUNA_QUANTIDADE,
  COLUNA_SALDO_ITEM,
  COLUNA_TES,
  COLUNA_UM,
  COLUNA_VALOR_UNITARIO,
  ItemExportacao,
  ItemGeracaoMedicao,
  ItemValidacaoLimite,
  LinhaImportacao,
  Pessoa,
  TesLookupItem
} from '../../models/importacao.model';
import { CsvParserService } from '../../services/csv-parser.service';
import { MedicaoService } from '../../services/medicao.service';
import { ProtheusBridgeService } from '../../services/protheus-bridge.service';

// Versao POUI de RT69M002.prw. Contrato/revisao NAO vem mais do arquivo -- a tela ja parte do
// contrato posicionado no browse (CNTA100), mesma logica da aba Exportar (ver
// ExportarMedicaoComponent::ngOnInit + Static Function CtxPos em Contratos/RTM002App.prw).
// O arquivo so precisa identificar planilha+item+produto+quantidade (TES/CC opcionais) --
// descricao/UM/valor unitario/classe valor/saldo vem do cadastro da planilha (CNB) via op
// "itensPlanilha", nao do arquivo (ver enriquecerLinhas()).
@Component({
  selector: 'app-importar-medicao',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    PoPageModule,
    PoButtonModule,
    PoFieldModule,
    PoModalModule,
    PoTableModule,
    PoInfoModule,
    PoIconModule
  ],
  templateUrl: './importar-medicao.component.html',
  styleUrl: './importar-medicao.component.css'
})
export class ImportarMedicaoComponent implements OnInit {
  readonly colunaTes = COLUNA_TES;
  readonly colunaQuantidade = COLUNA_QUANTIDADE;

  // Icones da biblioteca oficial PO UI (https://po-ui.io/icons) -- cores padrao do tema,
  // sem override.
  readonly iconClear = 'ICON_CLEAR_CONTENT';
  readonly iconUpload = 'ICON_UPLOAD_CLOUD';
  readonly iconInfo = 'ICON_INFO';
  readonly iconDelete = 'ICON_DELETE';

  // Acao de excluir linha do po-table (p-actions) -- padrao do tema (menu/icone de acao por
  // linha), em vez de um botao customizado dentro da celula.
  readonly acoesGrid: Array<PoTableAction> = [
    { label: 'Excluir', icon: this.iconDelete, type: 'danger', action: this.excluirLinha.bind(this) }
  ];

  @ViewChild('modalTes') modalTes!: PoModalComponent;

  colunas: string[] = [];
  tableColumns: Array<PoTableColumn> = [];
  linhas: Array<LinhaImportacao> = [];
  nomeArquivo = '';
  carregandoItens = false;
  valorTotalMedicao = 0;

  numContrato = '';
  revisao = '';
  buscando = false;
  contratoCarregado = false;
  tipoContrato: 'C' | 'V' | '' = '';
  labelPessoa = 'Cliente';
  pessoas: Array<Pessoa> = [];
  pessoaOptions: Array<PoSelectOption> = [];
  pessoaSelecionada = '';
  saldoContrato = 0;
  competenciaOptions: Array<PoSelectOption> = [];
  competenciaSelecionada = '';
  gerandoMedicao = false;

  filtroTes = '';
  resultadosTes: Array<TesLookupItem> = [];
  private linhaEmEdicaoTes: LinhaImportacao | null = null;

  constructor(
    private readonly csvParser: CsvParserService,
    private readonly medicaoService: MedicaoService,
    private readonly poNotification: PoNotificationService,
    private readonly poDialog: PoDialogService,
    private readonly protheusBridge: ProtheusBridgeService
  ) {}

  ngOnInit(): void {
    // Contrato ja posicionado no browse (CNTA100) quando o usuario abriu a tela -- carrega de
    // imediato, mesma logica da aba Exportar (ver Static Function CtxPos em
    // Contratos/RTM002App.prw). O usuario ainda pode digitar/buscar outro contrato manualmente
    // se precisar.
    this.medicaoService.contratoPosicionado().subscribe({
      next: resp => {
        if (resp.temContrato) {
          this.numContrato = resp.numContrato;
          this.revisao = resp.revisao;
          this.buscarContrato();
        }
      },
      error: () => {
        // Sem contexto de contrato posicionado -- usuario digita normalmente.
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
        // Se so ha um fornecedor/cliente vinculado ao contrato, seleciona automaticamente;
        // com mais de um (contrato com mais de uma planilha em CNA), o usuário escolhe.
        this.pessoaSelecionada = this.pessoaOptions.length === 1 ? String(this.pessoaOptions[0].value) : '';
        this.saldoContrato = resp.saldoContrato;
        this.competenciaOptions = resp.competencias.map(competencia => ({ value: competencia, label: competencia }));
        this.competenciaSelecionada = resp.competencias[0] ?? '';

        if (this.pessoas.length === 0) {
          this.poNotification.warning(`Nenhum ${this.labelPessoa.toLowerCase()} encontrado vinculado a este contrato.`);
        }
      },
      error: resp => {
        this.buscando = false;
        this.poNotification.error(resp?.message ?? 'Falha ao consultar o cabeçalho do contrato.');
      }
    });
  }

  onArquivoSelecionado(evento: Event): void {
    const input = evento.target as HTMLInputElement;
    const arquivo = input.files?.[0];
    if (!arquivo) {
      return;
    }

    if (!this.contratoCarregado) {
      this.poNotification.warning('Informe e busque o contrato antes de selecionar o arquivo.');
      input.value = '';
      return;
    }

    const leitor = new FileReader();
    leitor.onload = () => {
      const conteudo = String(leitor.result ?? '');
      const importacao = this.csvParser.parse(conteudo);

      if (importacao.linhas.length === 0) {
        this.poNotification.warning('Arquivo vazio ou sem dados válidos.');
        this.limparArquivo();
        return;
      }

      const validacao = this.csvParser.validarLayout(importacao.colunas);
      if (!validacao.valido) {
        this.poDialog.alert({
          title: 'Layout do arquivo inválido',
          message:
            'O arquivo selecionado não traz as colunas mínimas esperadas para identificar o item medido: ' +
            'Planilha, Item, Produto e Quantidade. Colunas ausentes: ' +
            validacao.colunasFaltantes.join(', ')
        });
        this.limparArquivo();
        return;
      }

      // TES e CC sao opcionais no arquivo -- se nao vierem, acrescenta a coluna vazia para
      // preenchimento manual/automatico (mesmo comportamento de RT69M002.prw::MostraGrid para
      // TES, estendido aqui tambem para CC).
      [COLUNA_TES, COLUNA_CC].forEach(coluna => {
        if (!importacao.colunas.includes(coluna)) {
          importacao.linhas.forEach(linha => (linha[coluna] = linha[coluna] ?? ''));
        }
      });

      this.nomeArquivo = arquivo.name;
      this.linhas = importacao.linhas;
      this.enriquecerLinhas();
    };
    leitor.onerror = () => this.poNotification.error('Falha ao ler o arquivo selecionado.');
    leitor.readAsText(arquivo, 'utf-8');

    // Permite selecionar o mesmo arquivo de novo em seguida (o evento 'change' não dispara
    // se o value do input não mudar).
    input.value = '';
  }

  // Completa cada linha do arquivo (que so traz planilha+item+produto+quantidade[+tes][+cc])
  // com descricao/UM/classe valor/valor unitario/saldo consultados no cadastro da planilha
  // (CNB) via op "itensPlanilha" -- essas informacoes nao vem mais do arquivo.
  private enriquecerLinhas(): void {
    const planilhas = Array.from(new Set(this.linhas.map(linha => (linha[COLUNA_PLANILHA] ?? '').trim()).filter(Boolean)));

    if (planilhas.length === 0) {
      this.poNotification.warning('Nenhuma planilha identificada no arquivo (coluna Planilha vazia).');
      this.limparArquivo();
      return;
    }

    this.carregandoItens = true;
    this.medicaoService.itensPlanilha(this.numContrato, this.revisao, planilhas).subscribe({
      next: resp => {
        this.carregandoItens = false;
        this.aplicarCatalogo(resp.itens);
      },
      error: resp => {
        this.carregandoItens = false;
        this.poNotification.error(resp?.message ?? 'Falha ao consultar os itens da planilha.');
        this.limparArquivo();
      }
    });
  }

  private aplicarCatalogo(catalogo: Array<ItemExportacao>): void {
    let semCorrespondencia = 0;

    this.linhas.forEach(linha => {
      const planilha = (linha[COLUNA_PLANILHA] ?? '').trim();
      const item = (linha[COLUNA_ITEM] ?? '').trim();
      const produto = (linha[COLUNA_PRODUTO] ?? '').trim();
      const catalogado = catalogo.find(it => it.planilha === planilha && it.item === item && it.produto === produto);

      if (catalogado) {
        linha[COLUNA_DESCRICAO] = catalogado.descricao;
        linha[COLUNA_UM] = catalogado.um;
        linha[COLUNA_CLASSE_VALOR] = catalogado.classeValor;
        linha[COLUNA_VALOR_UNITARIO] = String(catalogado.valorUnitario);
        linha[COLUNA_SALDO_ITEM] = String(catalogado.saldoItem);
        if (!linha[COLUNA_CC]) {
          linha[COLUNA_CC] = catalogado.cc;
        }
      } else {
        semCorrespondencia++;
      }
    });

    this.colunas = COLUNAS_GRID;
    this.tableColumns = COLUNAS_GRID.map(coluna => ({
      property: coluna,
      label: coluna,
      type: coluna === this.colunaTes || coluna === this.colunaQuantidade ? 'cellTemplate' : 'string'
    }));

    if (semCorrespondencia > 0) {
      this.poNotification.warning(
        `${semCorrespondencia} linha(s) do arquivo não correspondem a nenhum item cadastrado na planilha do contrato ` +
          '(confira planilha/item/produto) -- descrição/valor unitário ficaram em branco para elas.'
      );
    }

    this.recalcularValorTotal();
  }

  // Exclui uma linha antes de importar -- disparado pela acao "Excluir" do po-table
  // (acoesGrid, padrao do tema: icone/menu de acao por linha).
  excluirLinha(linha: LinhaImportacao): void {
    this.linhas = this.linhas.filter(item => item !== linha);
    this.recalcularValorTotal();
  }

  // Valor total da medicao = soma de quantidade x valor unitário de cada linha atualmente na
  // grade -- recalculado sempre que a grade muda (arquivo carregado, quantidade editada, linha
  // excluída), para o usuário conferir antes de importar.
  private recalcularValorTotal(): void {
    this.valorTotalMedicao = this.linhas.reduce(
      (total, linha) => total + this.paraNumero(linha[this.colunaQuantidade]) * this.paraNumero(linha[COLUNA_VALOR_UNITARIO]),
      0
    );
  }

  // Converte texto numerico tolerando tanto "1234.56" (ponto decimal) quanto "1234,56"
  // (formato BR, ponto de milhar) -- mesma tolerancia do ParseNum em
  // Contratos/RTM002App.prw, aplicada aqui so para o total exibido em tela.
  private paraNumero(valor: string | undefined): number {
    if (!valor) {
      return 0;
    }
    const texto = valor.includes(',') ? valor.replace(/\./g, '').replace(',', '.') : valor;
    const numero = Number(texto);
    return Number.isFinite(numero) ? numero : 0;
  }

  // Reseta so o arquivo/grade importados, preservando o contrato ja carregado (buscarContrato
  // pode ter vindo do contexto posicionado -- perder isso a cada arquivo invalido seria
  // obrigar o usuario a buscar de novo sem necessidade).
  private limparArquivo(): void {
    this.nomeArquivo = '';
    this.colunas = [];
    this.tableColumns = [];
    this.linhas = [];
    this.valorTotalMedicao = 0;
  }

  abrirBuscaTes(linha: LinhaImportacao): void {
    this.linhaEmEdicaoTes = linha;
    this.filtroTes = '';
    this.resultadosTes = [];
    this.modalTes.open();
    this.buscarTes();
  }

  buscarTes(): void {
    this.medicaoService.lookupTes(this.filtroTes).subscribe({
      next: resp => (this.resultadosTes = resp.items),
      error: () => this.poNotification.error('Falha ao buscar TES.')
    });
  }

  selecionarTes(item: TesLookupItem): void {
    if (this.linhaEmEdicaoTes) {
      this.linhaEmEdicaoTes[this.colunaTes] = item.value;
    }
    this.modalTes.close();
  }

  onQuantidadeAlterada(linha: LinhaImportacao, valor: number | null): void {
    linha[this.colunaQuantidade] = valor != null ? String(valor) : '';
    this.recalcularValorTotal();
  }

  importar(): void {
    if (!this.competenciaSelecionada) {
      this.poNotification.warning('Selecione a competência da medição.');
      return;
    }
    if (this.pessoaOptions.length > 1 && !this.pessoaSelecionada) {
      this.poNotification.warning(`Selecione o ${this.labelPessoa.toLowerCase()}.`);
      return;
    }

    const itensLimite: Array<ItemValidacaoLimite> = this.linhas.map(linha => ({
      planilha: linha[COLUNA_PLANILHA] ?? '',
      quantidade: linha[this.colunaQuantidade] ?? '',
      valorUnitario: linha[COLUNA_VALOR_UNITARIO] ?? ''
    }));

    this.gerandoMedicao = true;
    this.medicaoService.validarLimite(this.numContrato, this.revisao, this.competenciaSelecionada, itensLimite).subscribe({
      next: resp => {
        this.gerandoMedicao = false;
        if (resp.excedeLimite) {
          const mensagem = resp.avisos
            .map(
              aviso =>
                `Planilha ${aviso.planilha}: total informado ${aviso.totalInformado.toFixed(2)} excede o limite da competência (${aviso.limite.toFixed(2)})`
            )
            .join('\n');
          this.poDialog.confirm({
            title: 'Limite de medição excedido',
            message: `${mensagem}\n\nA geração provavelmente será rejeitada pelo CNTA121. Deseja tentar confirmar mesmo assim?`,
            confirm: () => this.executarGeracao()
          });
        } else {
          this.executarGeracao();
        }
      },
      error: resp => {
        this.gerandoMedicao = false;
        this.poNotification.error(resp?.message ?? 'Falha ao validar limite de medição.');
      }
    });
  }

  private executarGeracao(): void {
    const [codigoPessoa, lojaPessoa] = this.pessoaSelecionada.split('|');
    const ehFornecedor = this.tipoContrato === 'C';

    const itens: Array<ItemGeracaoMedicao> = this.linhas.map(linha => ({
      planilha: linha[COLUNA_PLANILHA] ?? '',
      item: linha[COLUNA_ITEM] ?? '',
      produto: linha[COLUNA_PRODUTO] ?? '',
      descricao: linha[COLUNA_DESCRICAO] ?? '',
      cc: linha[COLUNA_CC] ?? '',
      tes: linha[this.colunaTes] ?? '',
      quantidade: linha[this.colunaQuantidade] ?? '',
      valorUnitario: linha[COLUNA_VALOR_UNITARIO] ?? ''
    }));

    this.gerandoMedicao = true;
    this.medicaoService
      .gerarMedicao({
        cNumCont: this.numContrato,
        cRevisao: this.revisao,
        cCompet: this.competenciaSelecionada,
        cCliente: !ehFornecedor ? (codigoPessoa ?? '') : '',
        cLojaCli: !ehFornecedor ? (lojaPessoa ?? '') : '',
        cFornec: ehFornecedor ? (codigoPessoa ?? '') : '',
        cLjForn: ehFornecedor ? (lojaPessoa ?? '') : '',
        itens
      })
      .subscribe({
        next: resp => {
          this.gerandoMedicao = false;
          const falhas = resp.resultados.filter(resultado => !resultado.success);
          const mensagem = resp.resultados
            .map(resultado =>
              resultado.success
                ? `Planilha ${resultado.planilha}: medição ${resultado.numMedicao} gerada com sucesso.`
                : `Planilha ${resultado.planilha}: ${resultado.message}`
            )
            .join('\n');

          this.poDialog.alert({
            title: falhas.length === 0 ? 'Medição gerada com sucesso' : 'Geração concluída com falhas',
            message: mensagem,
            ok: () => {
              if (falhas.length === 0) {
                // So limpa o arquivo/grade -- o contrato continua carregado, pronto para uma
                // proxima importacao (ex.: outra planilha/competencia do mesmo contrato).
                this.limparArquivo();
              }
            }
          });
        },
        error: resp => {
          this.gerandoMedicao = false;
          this.poNotification.error(resp?.message ?? 'Falha ao gerar a medição.');
        }
      });
  }

  cancelar(): void {
    this.poDialog.confirm({
      title: 'Cancelar',
      message: 'Deseja realmente cancelar e fechar esta tela?',
      confirm: () => this.protheusBridge.fecharApp()
    });
  }

  limpar(): void {
    this.limparArquivo();
    this.numContrato = '';
    this.revisao = '';
    this.contratoCarregado = false;
    this.tipoContrato = '';
    this.pessoas = [];
    this.pessoaOptions = [];
    this.pessoaSelecionada = '';
    this.saldoContrato = 0;
    this.competenciaOptions = [];
    this.competenciaSelecionada = '';
  }
}
