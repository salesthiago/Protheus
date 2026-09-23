import { CommonModule } from '@angular/common';
import { Component, OnInit, ViewChild } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import {
  PoBreadcrumb,
  PoButtonModule,
  PoFieldModule,
  PoModalComponent,
  PoModalModule,
  PoNotificationService,
  PoPageModule,
  PoSelectOption,
  PoTableAction,
  PoTableColumn,
  PoTableModule,
  PoTabsModule
} from '@po-ui/ng-components';
import {
  Anexo,
  BemLookupItem,
  CULPA_OPTIONS,
  EVENTO_OPTIONS,
  GRAVIDADE_OPTIONS,
  ORIGEM_VEICULO_OPTIONS,
  PERIODO_OPTIONS,
  SIMNAO_OPTIONS,
  Sinistro,
  TEMPO_OPTIONS,
  Testemunha,
  VeiculoEnvolvido,
  VIA_OPTIONS,
  VIADIR_OPTIONS,
  Vitima
} from '../../models/sinistro.model';
import { SinistroService } from '../../services/sinistro.service';

// Shapes locais com todos os campos obrigatorios -- ngModel + strictTemplates nao aceitam
// "string | undefined" (mesmo motivo do PlanilhaForm em rtm003/contrato-editor).
interface SinistroForm {
  numero: string;
  data: string;
  hora: string;
  evento: string;
  codBem: string;
  placa: string;
  gravidade: string;
  tempo: string;
  via: string;
  periodo: string;
  maoDirecao: string;
  local: string;
  cidade: string;
  uf: string;
  numeroBO: string;
  nomeDP: string;
  interrViagem: string;
  necGuincho: string;
  valorGuincho: number;
  delitoConcret: string;
  terceiroEvadiu: string;
  status: string;
  descricao: string;
  danosFrota: string;
  valorDanos: number;
  descDanos: string;
  culpabilidade: string;
  culpadoNome: string;
  numeroFor: string;
  valorFolha: number;
  valorSaldo: number;
}

interface VeiculoForm {
  seq: string;
  origem: string;
  placa: string;
  descricao: string;
  condutor: string;
  matricula: string;
  cpf: string;
  cnh: string;
  telefone: string;
  proprietario: string;
  danos: string;
  valorPrejuizo: number;
  valorTerceiro: number;
  percentualGanho: number;
  segurado: string;
  seguradora: string;
  apolice: string;
}

interface TestemunhaForm {
  seq: string;
  nome: string;
  telefone: string;
  endereco: string;
  cidade: string;
  uf: string;
  tipoDoc: string;
  documento: string;
  qualificacao: string;
}

interface VitimaForm {
  seq: string;
  funcionario: string;
  matricula: string;
  nome: string;
  telefone: string;
  endereco: string;
  cidade: string;
  uf: string;
  lesoes: string;
  acaoTomada: string;
  funcao: string;
  fatal: string;
  condicao: string;
  valorVitima: number;
}

function opt(lista: { value: string; label: string }[]): PoSelectOption[] {
  return lista.map(o => ({ value: o.value, label: o.label }));
}

@Component({
  selector: 'app-sinistro-editor',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    PoPageModule,
    PoTabsModule,
    PoFieldModule,
    PoButtonModule,
    PoTableModule,
    PoModalModule
  ],
  templateUrl: './sinistro-editor.component.html',
  styleUrl: './sinistro-editor.component.css'
})
export class SinistroEditorComponent implements OnInit {
  @ViewChild('modalBem') modalBem!: PoModalComponent;
  @ViewChild('modalVeiculo') modalVeiculo!: PoModalComponent;
  @ViewChild('modalTestemunha') modalTestemunha!: PoModalComponent;
  @ViewChild('modalVitima') modalVitima!: PoModalComponent;

  readonly eventoOptions = opt(EVENTO_OPTIONS);
  readonly gravidadeOptions = opt(GRAVIDADE_OPTIONS);
  readonly tempoOptions = opt(TEMPO_OPTIONS);
  readonly viaOptions = opt(VIA_OPTIONS);
  readonly periodoOptions = opt(PERIODO_OPTIONS);
  readonly viadirOptions = opt(VIADIR_OPTIONS);
  readonly simnaoOptions = opt(SIMNAO_OPTIONS);
  readonly culpaOptions = opt(CULPA_OPTIONS);
  readonly origemOptions = opt(ORIGEM_VEICULO_OPTIONS);
  statusOptions: PoSelectOption[] = [];

  breadcrumb: PoBreadcrumb = {
    items: [{ label: 'Sinistros', link: '/sinistros' }, { label: 'Sinistro' }]
  };

  numero = '';
  carregando = false;
  salvando = false;

  form: SinistroForm = SinistroEditorComponent.sinistroVazio();
  sinistro?: Sinistro;

  chaveBem = '';
  filtroBem = '';
  bensEncontrados: BemLookupItem[] = [];
  readonly colunasBem: PoTableColumn[] = [
    { property: 'codigo', label: 'Código', width: '120px' },
    { property: 'nome', label: 'Descrição' },
    { property: 'placa', label: 'Placa', width: '110px' },
    { property: 'serie', label: 'Série', width: '140px' },
    { property: 'tipo', label: 'Tipo', width: '90px' }
  ];

  veiculos: VeiculoEnvolvido[] = [];
  testemunhas: Testemunha[] = [];
  vitimas: Vitima[] = [];
  anexos: Anexo[] = [];

  veiculoEdit: VeiculoForm = SinistroEditorComponent.veiculoVazio();
  testemunhaEdit: TestemunhaForm = SinistroEditorComponent.testemunhaVazia();
  vitimaEdit: VitimaForm = SinistroEditorComponent.vitimaVazia();

  readonly colunasVeiculo: PoTableColumn[] = [
    { property: 'seq', label: 'Seq', width: '70px' },
    { property: 'origemLabel', label: 'Origem', width: '100px' },
    { property: 'placa', label: 'Placa', width: '110px' },
    { property: 'condutor', label: 'Condutor' },
    { property: 'cpf', label: 'CPF', width: '140px' },
    { property: 'valorTerceiro', label: 'Vlr. Terceiro', type: 'currency', format: 'BRL', width: '120px' }
  ];
  readonly colunasTestemunha: PoTableColumn[] = [
    { property: 'seq', label: 'Seq', width: '70px' },
    { property: 'nome', label: 'Nome' },
    { property: 'telefone', label: 'Telefone', width: '140px' },
    { property: 'qualificacao', label: 'Qualificação', width: '160px' }
  ];
  readonly colunasVitima: PoTableColumn[] = [
    { property: 'seq', label: 'Seq', width: '70px' },
    { property: 'nome', label: 'Nome' },
    { property: 'funcao', label: 'Função' },
    { property: 'fatal', label: 'Fatal', width: '90px' }
  ];
  readonly colunasAnexo: PoTableColumn[] = [
    { property: 'tipoLabel', label: 'Tipo', width: '120px' },
    { property: 'nomeDoc', label: 'Documento' },
    { property: 'arquivo', label: 'Arquivo' },
    { property: 'dataReceb', label: 'Recebido', type: 'date', width: '120px' }
  ];

  readonly acoesVeiculo: PoTableAction[] = [
    { label: 'Editar', action: (r: VeiculoEnvolvido) => this.abrirVeiculo(r) },
    { label: 'Excluir', action: (r: VeiculoEnvolvido) => this.removerVeiculo(r), type: 'danger' }
  ];
  readonly acoesTestemunha: PoTableAction[] = [
    { label: 'Editar', action: (r: Testemunha) => this.abrirTestemunha(r) },
    { label: 'Excluir', action: (r: Testemunha) => this.removerTestemunha(r), type: 'danger' }
  ];
  readonly acoesVitima: PoTableAction[] = [
    { label: 'Editar', action: (r: Vitima) => this.abrirVitima(r) },
    { label: 'Excluir', action: (r: Vitima) => this.removerVitima(r), type: 'danger' }
  ];

  constructor(
    private readonly route: ActivatedRoute,
    private readonly router: Router,
    private readonly sinistroService: SinistroService,
    private readonly poNotification: PoNotificationService
  ) {}

  get modoNovo(): boolean {
    return !this.numero;
  }

  ngOnInit(): void {
    this.sinistroService.lookupDominio('status').subscribe({
      next: resp => (this.statusOptions = resp.items.map(i => ({ value: i.value, label: `${i.value} - ${i.label}` }))),
      error: () => (this.statusOptions = [])
    });

    this.numero = this.route.snapshot.paramMap.get('numero') ?? '';
    if (this.numero) {
      this.breadcrumb = {
        items: [{ label: 'Sinistros', link: '/sinistros' }, { label: `Sinistro ${this.numero}` }]
      };
      this.carregar();
    }
  }

  // ---------- factories ----------
  static sinistroVazio(): SinistroForm {
    return {
      numero: '', data: '', hora: '00:00', evento: '1', codBem: '', placa: '',
      gravidade: '1', tempo: '1', via: '1', periodo: '1', maoDirecao: '1',
      local: '', cidade: '', uf: '', numeroBO: '', nomeDP: '',
      interrViagem: '2', necGuincho: '2', valorGuincho: 0, delitoConcret: '2', terceiroEvadiu: '2',
      status: '01', descricao: '', danosFrota: '2', valorDanos: 0, descDanos: '',
      culpabilidade: '9', culpadoNome: '', numeroFor: '', valorFolha: 0, valorSaldo: 0
    };
  }
  static veiculoVazio(): VeiculoForm {
    return {
      seq: '', origem: '2', placa: '', descricao: '', condutor: '', matricula: '', cpf: '',
      cnh: '', telefone: '', proprietario: '', danos: '1', valorPrejuizo: 0, valorTerceiro: 0,
      percentualGanho: 0, segurado: '', seguradora: '', apolice: ''
    };
  }
  static testemunhaVazia(): TestemunhaForm {
    return { seq: '', nome: '', telefone: '', endereco: '', cidade: '', uf: '', tipoDoc: '', documento: '', qualificacao: 'TESTEMUNHA' };
  }
  static vitimaVazia(): VitimaForm {
    return {
      seq: '', funcionario: '2', matricula: '', nome: '', telefone: '', endereco: '', cidade: '',
      uf: '', lesoes: '', acaoTomada: '', funcao: '', fatal: '2', condicao: '', valorVitima: 0
    };
  }

  carregar(): void {
    this.carregando = true;
    this.sinistroService.detalhe(this.numero).subscribe({
      next: resp => {
        this.carregando = false;
        this.aplicarSinistro(resp.sinistro);
      },
      error: resp => {
        this.carregando = false;
        this.poNotification.error(resp?.message ?? 'Falha ao carregar o sinistro.');
      }
    });
  }

  private aplicarSinistro(s: Sinistro): void {
    this.sinistro = s;
    this.veiculos = s.veiculos ?? [];
    this.testemunhas = s.testemunhas ?? [];
    this.vitimas = s.vitimas ?? [];
    this.anexos = s.anexos ?? [];
    this.chaveBem = s.codBem;
    this.form = {
      numero: s.numero,
      data: s.data,
      hora: s.hora,
      evento: s.evento,
      codBem: s.codBem,
      placa: s.placa,
      gravidade: s.gravidade,
      tempo: s.tempo,
      via: s.via,
      periodo: s.periodo,
      maoDirecao: s.maoDirecao,
      local: s.local,
      cidade: s.cidade,
      uf: s.uf,
      numeroBO: s.numeroBO,
      nomeDP: s.nomeDP,
      interrViagem: s.interrViagem,
      necGuincho: s.necGuincho,
      valorGuincho: s.valorGuincho ?? 0,
      delitoConcret: s.delitoConcret,
      terceiroEvadiu: s.terceiroEvadiu,
      status: s.status,
      descricao: s.descricao,
      danosFrota: s.danosFrota,
      valorDanos: s.valorDanos ?? 0,
      descDanos: s.descDanos ?? '',
      culpabilidade: s.culpabilidade,
      culpadoNome: s.culpadoNome,
      numeroFor: s.numeroFor,
      valorFolha: s.valorFolha ?? 0,
      valorSaldo: s.valorSaldo ?? 0
    };
  }

  // ---------- bem ----------
  abrirBuscaBem(): void {
    this.filtroBem = this.chaveBem;
    this.buscarBem();
    this.modalBem.open();
  }
  buscarBem(): void {
    this.sinistroService.lookupBem(this.filtroBem).subscribe({
      next: resp => (this.bensEncontrados = resp.items ?? []),
      error: () => (this.bensEncontrados = [])
    });
  }
  selecionarBem(bem: BemLookupItem): void {
    this.chaveBem = bem.codigo;
    this.form.codBem = bem.codigo;
    this.form.placa = bem.placa;
    this.form.evento = bem.tipo === 'V' ? '1' : '3';
    this.modalBem.close();
  }

  // ---------- salvar cabecalho ----------
  salvar(): void {
    if (!this.form.data) {
      this.poNotification.warning('Informe a data do sinistro.');
      return;
    }
    if (this.modoNovo && !this.chaveBem) {
      this.poNotification.warning('Selecione o bem (placa, série ou código).');
      return;
    }
    this.salvando = true;

    if (this.modoNovo) {
      this.sinistroService.criar({ ...this.form, chaveBem: this.chaveBem, codBem: this.chaveBem }).subscribe({
        next: resp => {
          this.salvando = false;
          this.poNotification.success(`Sinistro ${resp.sinistro.numero} criado.`);
          this.router.navigate(['sinistros', resp.sinistro.numero]);
        },
        error: resp => {
          this.salvando = false;
          this.poNotification.error(resp?.message ?? 'Falha ao criar o sinistro.');
        }
      });
    } else {
      this.sinistroService.atualizar({ ...this.form, numero: this.numero }).subscribe({
        next: resp => {
          this.salvando = false;
          this.aplicarSinistro(resp.sinistro);
          this.poNotification.success('Sinistro atualizado.');
        },
        error: resp => {
          this.salvando = false;
          this.poNotification.error(resp?.message ?? 'Falha ao atualizar o sinistro.');
        }
      });
    }
  }

  voltar(): void {
    this.router.navigate(['sinistros']);
  }

  // ---------- veiculos ----------
  novoVeiculo(): void {
    this.veiculoEdit = SinistroEditorComponent.veiculoVazio();
    this.modalVeiculo.open();
  }
  abrirVeiculo(v: VeiculoEnvolvido): void {
    this.veiculoEdit = { ...SinistroEditorComponent.veiculoVazio(), ...v };
    this.modalVeiculo.open();
  }
  salvarVeiculo(): void {
    this.sinistroService.salvarVeiculo(this.numero, this.veiculoEdit).subscribe({
      next: resp => {
        this.aplicarSinistro(resp.sinistro);
        this.modalVeiculo.close();
      },
      error: resp => this.poNotification.error(resp?.message ?? 'Falha ao salvar o veículo.')
    });
  }
  removerVeiculo(v: VeiculoEnvolvido): void {
    this.sinistroService.removerVeiculo(this.numero, v.seq).subscribe({
      next: resp => this.aplicarSinistro(resp.sinistro),
      error: resp => this.poNotification.error(resp?.message ?? 'Falha ao remover o veículo.')
    });
  }

  // ---------- testemunhas ----------
  novaTestemunha(): void {
    this.testemunhaEdit = SinistroEditorComponent.testemunhaVazia();
    this.modalTestemunha.open();
  }
  abrirTestemunha(t: Testemunha): void {
    this.testemunhaEdit = { ...SinistroEditorComponent.testemunhaVazia(), ...t };
    this.modalTestemunha.open();
  }
  salvarTestemunha(): void {
    this.sinistroService.salvarTestemunha(this.numero, this.testemunhaEdit).subscribe({
      next: resp => {
        this.aplicarSinistro(resp.sinistro);
        this.modalTestemunha.close();
      },
      error: resp => this.poNotification.error(resp?.message ?? 'Falha ao salvar a testemunha.')
    });
  }
  removerTestemunha(t: Testemunha): void {
    this.sinistroService.removerTestemunha(this.numero, t.seq).subscribe({
      next: resp => this.aplicarSinistro(resp.sinistro),
      error: resp => this.poNotification.error(resp?.message ?? 'Falha ao remover a testemunha.')
    });
  }

  // ---------- vitimas ----------
  novaVitima(): void {
    this.vitimaEdit = SinistroEditorComponent.vitimaVazia();
    this.modalVitima.open();
  }
  abrirVitima(v: Vitima): void {
    this.vitimaEdit = { ...SinistroEditorComponent.vitimaVazia(), ...v };
    this.modalVitima.open();
  }
  salvarVitima(): void {
    this.sinistroService.salvarVitima(this.numero, this.vitimaEdit).subscribe({
      next: resp => {
        this.aplicarSinistro(resp.sinistro);
        this.modalVitima.close();
      },
      error: resp => this.poNotification.error(resp?.message ?? 'Falha ao salvar a vítima.')
    });
  }
  removerVitima(v: Vitima): void {
    this.sinistroService.removerVitima(this.numero, v.seq).subscribe({
      next: resp => this.aplicarSinistro(resp.sinistro),
      error: resp => this.poNotification.error(resp?.message ?? 'Falha ao remover a vítima.')
    });
  }
}
