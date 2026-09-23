import { Routes } from '@angular/router';
import { ExportarMedicaoComponent } from './pages/exportar-medicao/exportar-medicao.component';
import { ImportarMedicaoComponent } from './pages/importar-medicao/importar-medicao.component';

export const routes: Routes = [
  { path: '', redirectTo: 'importar', pathMatch: 'full' },
  { path: 'importar', component: ImportarMedicaoComponent },
  { path: 'exportar', component: ExportarMedicaoComponent }
];
