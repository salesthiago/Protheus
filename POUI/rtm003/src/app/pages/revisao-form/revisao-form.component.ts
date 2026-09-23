import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { PoButtonModule, PoDialogService, PoFieldModule, PoNotificationService, PoPageAction, PoPageModule, PoSelectOption } from '@po-ui/ng-components';
import { ItemGridComponent } from '../../shared/item-grid/item-grid.component';
import { ItemPlanilha, TIPOS_REVISAO_OPTIONS, TipoRevisao } from '../../models/contrato.model';
import { ContratoService } from '../../services/contrato.service';
import { ProtheusBridgeService } from '../../services/protheus-bridge.service';

// Tela generica de revisao (aditivo, reajuste, renovacao, paralisacao/reinicio etc.) --
// decisao confirmada com o usuario: um unico formulario com seletor cobrindo os 16 tipos de
// A300STpRev, reaproveitando os mesmos campos de planilha/itens da inclusao de contrato. Ver
// exemplos "Revisão Aberta"/"Revisão de realinhamento"/"Revisão de aditivo" do GCT0109.
//
// Comportamento do backend (Contratos/RTM003App.prw::ZcnRevAb) nesta fase: se "itens" vier
// preenchido, entra como UMA planilha nova na revisao, igual pro qualquer tipo escolhido --
// regras especificas por tipo (CN300RdSld no realinhamento, CN9_MOTPAR/CN9_DTFIMP na
// paralisacao etc.) ainda nao foram implementadas. "Tipo de Planilha" so e obrigatorio quando
// ha itens.
@Component({
  selector: 'app-revisao-form',
  standalone: true,
  imports: [CommonModule, FormsModule, PoPageModule, PoFieldModule, PoButtonModule, ItemGridComponent],
  templateUrl: './revisao-form.component.html',
  styleUrl: './revisao-form.component.css'
})
export class RevisaoFormComponent {
  readonly tipoRevisaoOptions: Array<PoSelectOption> = TIPOS_REVISAO_OPTIONS.map(opcao => ({
    value: opcao.value,
    label: opcao.label
  }));

  readonly numero: string;
  readonly revisaoAtual: string;

  // Exposto pro template poder comparar tipoRevisao === TipoRevisao.Reajuste (*ngIf) --
  // enums TypeScript nao ficam visiveis no template a menos que passem por um campo da classe.
  readonly TipoRevisao = TipoRevisao;

  tipoRevisao: TipoRevisao = TipoRevisao.Aditivo;
  justificativa = '';
  tipoPlanilha = '';
  itens: ItemPlanilha[] = [];
  salvando = false;

  // Mesma mudanca de contrato-form: Cancelar/Salvar saem do rodape fixo (que cobria o botao
  // "Adicionar Item") e vao pro topo, como acoes da po-page-list. Referencia estavel (campo).
  readonly acoesPage: Array<PoPageAction> = [
    { label: 'Cancelar', action: () => this.cancelar() },
    { label: 'Salvar', action: () => this.salvar(), disabled: () => this.salvando }
  ];

  constructor(
    private readonly route: ActivatedRoute,
    private readonly router: Router,
    private readonly contratoService: ContratoService,
    private readonly poNotification: PoNotificationService,
    private readonly poDialog: PoDialogService,
    private readonly protheusBridge: ProtheusBridgeService
  ) {
    this.numero = this.route.snapshot.paramMap.get('numero') ?? '';
    this.revisaoAtual = this.route.snapshot.paramMap.get('revisao') ?? '';
  }

  onItensAlterados(itens: ItemPlanilha[]): void {
    this.itens = itens;
  }

  // Justificativa so aparece/e exigida em revisao de Reajuste (pedido do usuario) -- trocar pra
  // outro tipo limpa o campo, pra nao mandar uma justificativa de um reajuste anterior escondida.
  onTipoRevisaoAlterado(tipoRevisao: TipoRevisao): void {
    this.tipoRevisao = tipoRevisao;
    if (tipoRevisao !== TipoRevisao.Reajuste) {
      this.justificativa = '';
    }
  }

  salvar(): void {
    if (this.tipoRevisao === TipoRevisao.Reajuste && !this.justificativa.trim()) {
      this.poNotification.warning('Informe a justificativa do reajuste (CN9_JUSTIF é obrigatório).');
      return;
    }
    if (this.itens.length > 0 && !this.tipoPlanilha.trim()) {
      this.poNotification.warning('Informe o tipo de planilha para os itens adicionados.');
      return;
    }

    this.salvando = true;
    this.contratoService
      .revisaoAbrir({
        numero: this.numero,
        revisaoBase: this.revisaoAtual,
        tipoRevisao: this.tipoRevisao,
        justificativa: this.justificativa.trim(),
        // "planilhas" e um array (mesmo contrato de payload de contratoCriar) -- esta tela
        // ainda so lida com 0 ou 1 planilha nova por revisao (sem abas), por isso o array tem
        // no maximo 1 elemento aqui.
        planilhas:
          this.itens.length > 0
            ? [
                {
                  tipoPlanilha: this.tipoPlanilha,
                  itens: this.itens.map(item => ({
                    produto: item.produto,
                    unidade: item.unidade,
                    quantidade: item.quantidade,
                    valorUnitario: item.valorUnitario,
                    cc: item.cc,
                    tes: item.tes,
                    pedTit: item.pedTit,
                    desconto: item.desconto
                  }))
                }
              ]
            : []
      })
      .subscribe({
        next: resp => {
          this.salvando = false;
          this.poNotification.success('Revisão aberta com sucesso.');
          this.router.navigate(['contratos', resp.header.numero, resp.header.revisao]);
        },
        error: resp => {
          this.salvando = false;
          this.poNotification.error(resp?.message ?? 'Falha ao abrir a revisão.');
        }
      });
  }

  cancelar(): void {
    this.poDialog.confirm({
      title: 'Cancelar',
      message: 'Deseja realmente cancelar esta revisão?',
      confirm: () => {
        if (this.protheusBridge.insideProtheus()) {
          this.protheusBridge.fecharApp();
        } else {
          this.router.navigate(['contratos', this.numero, this.revisaoAtual]);
        }
      }
    });
  }
}
