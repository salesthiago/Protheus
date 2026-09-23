import { Routes } from '@angular/router';
import { ContratoListComponent } from './pages/contrato-list/contrato-list.component';
import { ContratoEditorComponent } from './pages/contrato-editor/contrato-editor.component';
import { RevisaoFormComponent } from './pages/revisao-form/revisao-form.component';

// contrato-editor substitui contrato-form (so criacao) e contrato-detalhe (so leitura/acoes) --
// Fase 5, tela unica de Cadastrais/Historico (pedido do usuario 2026-08-11: "Esta deverá ser a
// mesma tela para alterar o contrato"). "novo" (sem :numero) = modo criar; "/:numero/:revisao"
// (com :numero) = modo editar -- o proprio componente decide o modo pela presenca do parametro.
export const routes: Routes = [
  { path: '', redirectTo: 'contratos', pathMatch: 'full' },
  { path: 'contratos', component: ContratoListComponent },
  { path: 'contratos/novo', component: ContratoEditorComponent },
  { path: 'contratos/:numero/:revisao', component: ContratoEditorComponent },
  { path: 'contratos/:numero/:revisao/revisao', component: RevisaoFormComponent }
];
