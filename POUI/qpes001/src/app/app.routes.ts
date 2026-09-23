import { Routes } from '@angular/router';
import { PesagemFormComponent } from './pages/pesagem-form/pesagem-form.component';
import { PesagemListComponent } from './pages/pesagem-list/pesagem-list.component';

export const routes: Routes = [
  { path: '', redirectTo: 'pesagens', pathMatch: 'full' },
  { path: 'pesagens', component: PesagemListComponent },
  { path: 'pesagens/novo', component: PesagemFormComponent },
  { path: 'pesagens/:filial/:ticket', component: PesagemFormComponent }
];
