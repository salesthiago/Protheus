import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';
import { BalancaItem } from '../models/pesagem.model';
import { PesagemService } from './pesagem.service';

// Equivalente web da selecao de balanca por F12 na OGA190Q nativa (ver AGRX003E em
// Aterro/balanca/local/OGA190Q.PRW). Aqui nao ha atalho de teclado: a lista de
// balancas e buscada uma vez ao carregar a tela de listagem (PesagemListComponent)
// e, havendo mais de uma ativa, o usuario e obrigado a escolher antes de pesar --
// a escolha fica guardada em memoria (singleton 'root') pelo tempo de vida da SPA,
// igual a variavel Static aParBal do fonte nativo (nao sobrevive a um reload do app).
@Injectable({ providedIn: 'root' })
export class BalancaSelecaoService {
  balancas: Array<BalancaItem> = [];
  carregando = false;

  private carregada = false;
  private readonly selecionadaSubject = new BehaviorSubject<string>('');
  readonly selecionada$ = this.selecionadaSubject.asObservable();

  constructor(private readonly pesagemService: PesagemService) {}

  get selecionada(): string {
    return this.selecionadaSubject.value;
  }

  // true so quando ha mais de uma balanca ativa e nenhuma foi escolhida ainda --
  // gatilho para a tela abrir a modal de escolha obrigatoria.
  get precisaEscolher(): boolean {
    return this.balancas.length > 1 && !this.selecionada;
  }

  // Busca a lista uma unica vez por sessao da SPA. Com 0 ou 1 balanca ativa, resolve
  // sozinho (sem balanca -> backend cai no fallback AGRX003E; com uma so -> usa ela
  // direto, sem perguntar nada ao usuario).
  carregar(aoTerminar?: () => void): void {
    if (this.carregada) {
      aoTerminar?.();
      return;
    }

    this.carregando = true;
    this.pesagemService.listarBalancas().subscribe({
      next: resp => {
        this.carregando = false;
        this.carregada = true;
        this.balancas = resp.balancas ?? [];
        if (this.balancas.length === 1) {
          this.selecionar(this.balancas[0].value);
        }
        aoTerminar?.();
      },
      error: () => {
        // Falha ao listar balancas nao deve travar a tela -- segue sem selecao,
        // o backend cai no mesmo fallback de resolucao automatica de sempre.
        this.carregando = false;
        this.carregada = true;
        aoTerminar?.();
      }
    });
  }

  selecionar(codigo: string): void {
    this.selecionadaSubject.next(codigo);
  }
}
