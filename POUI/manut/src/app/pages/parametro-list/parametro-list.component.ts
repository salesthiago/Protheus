import { Component, OnInit, ViewChild } from '@angular/core';
import { FormsModule } from '@angular/forms';
import {
  PoButtonModule,
  PoDialogService,
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
import { ParametroItem, ParametroSalvarPayload, TIPOS_PARAMETRO } from '../../models/parametro.model';
import { ParametroService } from '../../services/parametro.service';
import { ProtheusBridgeService } from '../../services/protheus-bridge.service';

// Linha da tabela com rotulos amigaveis ja resolvidos -- o backend devolve o
// dado "cru" (X6_TIPO='L', X6_CONTEUD='S'), a traducao pro usuario leigo e
// feita aqui (ver tipoLabel()/conteudoLabel()).
interface ParametroRow extends ParametroItem {
  tipoLabel: string;
  conteudoLabel: string;
}

@Component({
  selector: 'app-parametro-list',
  standalone: true,
  imports: [PoPageModule, PoTableModule, PoFieldModule, PoModalModule, PoButtonModule, FormsModule],
  templateUrl: './parametro-list.component.html',
  styleUrl: './parametro-list.component.css'
})
export class ParametroListComponent implements OnInit {
  @ViewChild('modalForm', { static: true }) modalForm!: PoModalComponent;

  // Enquanto a permissao nao volta do ADVPL, nao mostra nem a grade nem a
  // mensagem de acesso negado (evita "flash" de conteudo indevido).
  verificandoAcesso = true;
  autorizado = false;
  usuario = '';

  items: Array<ParametroRow> = [];
  loading = false;
  busca = '';

  // Dados do formulario (modal de incluir/editar).
  editando = false;
  saving = false;
  form: ParametroSalvarPayload = { variavel: '', tipo: 'C', conteudo: '', descricao: '' };

  // Campos auxiliares por tipo -- o backend so entende 'conteudo' como texto
  // (X6_CONTEUD e sempre C(250)); cada tipo usa um controle de tela diferente
  // e e convertido para/de texto em prepararCampos()/montarConteudo().
  conteudoTexto = '';
  conteudoNumero: number | null = null;
  conteudoData: Date | null = null;
  conteudoLogico = false;

  readonly tipos: Array<PoSelectOption> = TIPOS_PARAMETRO;

  readonly columns: Array<PoTableColumn> = [
    { property: 'variavel', label: 'Parâmetro', type: 'string', width: '16%' },
    { property: 'descricao', label: 'Descrição', type: 'string' },
    { property: 'tipoLabel', label: 'Tipo', type: 'string', width: '12%' },
    { property: 'conteudoLabel', label: 'Valor Atual', type: 'string', width: '20%' }
  ];

  readonly tableActions: Array<PoTableAction> = [
    { label: 'Editar', icon: 'an an-pencil-simple', action: (row: ParametroRow) => this.editar(row) },
    { label: 'Excluir', icon: 'an an-trash', separator: true, action: (row: ParametroRow) => this.confirmarExclusao(row) }
  ];

  readonly pageActions: Array<PoPageAction> = [
    { label: 'Novo Parâmetro', icon: 'an an-plus', action: () => this.novo() },
    { label: 'Fechar', icon: 'an an-x', action: () => this.fechar() }
  ];

  readonly filter: PoPageFilter = {
    placeholder: 'Pesquisar por nome ou descrição do parâmetro',
    action: (value: string) => this.pesquisar(value)
  };

  readonly modalPrimaryAction: PoModalAction = {
    label: 'Salvar',
    action: () => this.salvar()
  };

  readonly modalSecondaryAction: PoModalAction = {
    label: 'Cancelar',
    action: () => this.modalForm.close()
  };

  constructor(
    private readonly parametroService: ParametroService,
    private readonly poNotification: PoNotificationService,
    private readonly poDialog: PoDialogService,
    private readonly protheusBridge: ProtheusBridgeService
  ) {}

  ngOnInit(): void {
    this.parametroService.permissao().subscribe({
      next: resp => {
        this.usuario = resp.usuario;
        this.autorizado = resp.autorizado;
        this.verificandoAcesso = false;
        if (this.autorizado) {
          this.carregar();
        }
      },
      error: () => {
        this.verificandoAcesso = false;
        this.autorizado = false;
      }
    });
  }

  carregar(): void {
    this.loading = true;

    this.parametroService.listar(this.busca).subscribe({
      next: response => {
        this.items = (response.parametros ?? []).map(item => this.paraLinha(item));
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.poNotification.error('Erro ao carregar a lista de parâmetros.');
      }
    });
  }

  pesquisar(valor: string): void {
    this.busca = valor;
    this.carregar();
  }

  novo(): void {
    this.editando = false;
    this.form = { variavel: '', tipo: 'C', conteudo: '', descricao: '' };
    this.prepararCampos();
    this.modalForm.open();
  }

  editar(row: ParametroRow): void {
    // Busca o detalhe completo (inclui os textos de ajuda) em vez de reaproveitar
    // a linha da lista, pra nao perder descricao1/2/3 ao salvar de novo.
    this.parametroService.obter(row.variavel).subscribe({
      next: det => {
        if (!det.success) {
          this.poNotification.error(det.message ?? 'Erro ao carregar o parâmetro.');
          return;
        }
        this.editando = true;
        this.form = {
          variavel: det.variavel,
          tipo: det.tipo,
          conteudo: det.conteudo,
          descricao: det.descricao,
          descricao1: det.descricao1,
          descricao2: det.descricao2,
          descricao3: det.descricao3
        };
        this.prepararCampos();
        this.modalForm.open();
      },
      error: () => this.poNotification.error('Erro ao carregar o parâmetro.')
    });
  }

  confirmarExclusao(row: ParametroRow): void {
    this.poDialog.confirm({
      title: 'Excluir parâmetro',
      message: `Deseja realmente excluir o parâmetro "${row.variavel}"? Esta ação não pode ser desfeita.`,
      confirm: () => this.excluir(row)
    });
  }

  private excluir(row: ParametroRow): void {
    this.parametroService.excluir(row.variavel).subscribe({
      next: resp => {
        if (!resp.success) {
          this.poNotification.error(resp.message ?? 'Erro ao excluir o parâmetro.');
          return;
        }
        this.poNotification.success(resp.message ?? 'Parâmetro excluído com sucesso.');
        this.carregar();
      },
      error: err => this.poNotification.error(err?.message ?? 'Erro ao excluir o parâmetro.')
    });
  }

  salvar(): void {
    if (!this.validar()) {
      return;
    }

    this.saving = true;
    this.form.conteudo = this.montarConteudo();

    this.parametroService.salvar(this.form).subscribe({
      next: resp => {
        this.saving = false;
        if (!resp.success) {
          this.poNotification.error(resp.message ?? 'Erro ao salvar o parâmetro.');
          return;
        }
        this.poNotification.success(resp.message ?? 'Parâmetro salvo com sucesso.');
        this.modalForm.close();
        this.carregar();
      },
      error: err => {
        this.saving = false;
        this.poNotification.error(err?.message ?? 'Erro ao salvar o parâmetro.');
      }
    });
  }

  private validar(): boolean {
    if (!this.editando) {
      const nome = (this.form.variavel ?? '').toUpperCase().trim();
      if (!nome.startsWith('MV_') || nome.length < 4 || nome.length > 10) {
        this.poNotification.warning('O nome do parâmetro deve começar com "MV_" e ter até 10 letras/números.');
        return false;
      }
      this.form.variavel = nome;
    }
    if (!this.form.descricao?.trim()) {
      this.poNotification.warning('Informe a descrição do parâmetro.');
      return false;
    }
    return true;
  }

  fechar(): void {
    this.protheusBridge.fecharApp();
  }

  // Converte o texto cru do X6_CONTEUD para o campo de tela adequado ao tipo.
  private prepararCampos(): void {
    this.conteudoTexto = this.form.tipo === 'C' ? this.form.conteudo : '';
    this.conteudoNumero = this.form.tipo === 'N' ? Number(this.form.conteudo) || 0 : null;
    this.conteudoLogico = this.form.tipo === 'L' ? this.form.conteudo?.toUpperCase() === 'S' : false;
    this.conteudoData = this.form.tipo === 'D' && this.form.conteudo ? this.dataDeTexto(this.form.conteudo) : null;
  }

  // Ao trocar o Tipo dentro do modal (parametro novo), reinicia o campo de valor.
  onTipoChange(tipo: string): void {
    this.form.tipo = tipo;
    this.conteudoTexto = '';
    this.conteudoNumero = null;
    this.conteudoLogico = false;
    this.conteudoData = null;
  }

  private montarConteudo(): string {
    switch (this.form.tipo) {
      case 'N':
        return String(this.conteudoNumero ?? 0);
      case 'L':
        return this.conteudoLogico ? 'S' : 'N';
      case 'D':
        return this.conteudoData ? this.textoDeData(this.conteudoData) : '';
      default:
        return this.conteudoTexto ?? '';
    }
  }

  // Data guardada em X6_CONTEUD no formato AAAAMMDD (sem separadores).
  private textoDeData(data: Date): string {
    const ano = data.getFullYear();
    const mes = String(data.getMonth() + 1).padStart(2, '0');
    const dia = String(data.getDate()).padStart(2, '0');
    return `${ano}${mes}${dia}`;
  }

  private dataDeTexto(texto: string): Date | null {
    if (texto.length !== 8) {
      return null;
    }
    const ano = Number(texto.substring(0, 4));
    const mes = Number(texto.substring(4, 6));
    const dia = Number(texto.substring(6, 8));
    return new Date(ano, mes - 1, dia);
  }

  private paraLinha(item: ParametroItem): ParametroRow {
    return {
      ...item,
      tipoLabel: TIPOS_PARAMETRO.find(t => t.value === item.tipo)?.label ?? item.tipo,
      conteudoLabel: this.conteudoParaExibicao(item)
    };
  }

  private conteudoParaExibicao(item: ParametroItem): string {
    if (item.tipo === 'L') {
      return item.conteudo?.toUpperCase() === 'S' ? 'Sim' : 'Não';
    }
    if (item.tipo === 'D') {
      const data = this.dataDeTexto(item.conteudo);
      return data ? data.toLocaleDateString('pt-BR') : item.conteudo;
    }
    return item.conteudo;
  }
}
