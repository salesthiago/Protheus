import { Routes } from '@angular/router';
import { ParametroListComponent } from './pages/parametro-list/parametro-list.component';

export const routes: Routes = [
  { path: '', redirectTo: 'parametros', pathMatch: 'full' },
  { path: 'parametros', component: ParametroListComponent }
];
