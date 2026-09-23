import { Routes } from '@angular/router';
import { SinistroListComponent } from './pages/sinistro-list/sinistro-list.component';
import { SinistroEditorComponent } from './pages/sinistro-editor/sinistro-editor.component';
import { SinistroImportComponent } from './pages/sinistro-import/sinistro-import.component';
import { SinistroConfigComponent } from './pages/sinistro-config/sinistro-config.component';

// Tela unica de cadastrais/filhas: "novo" (sem :numero) = modo criar; "/:numero" = modo editar.
// O proprio componente decide o modo pela presenca do parametro (mesmo padrao de rtm003).
export const routes: Routes = [
  { path: '', redirectTo: 'sinistros', pathMatch: 'full' },
  { path: 'sinistros', component: SinistroListComponent },
  { path: 'sinistros/importar', component: SinistroImportComponent },
  { path: 'sinistros/configuracao', component: SinistroConfigComponent },
  { path: 'sinistros/novo', component: SinistroEditorComponent },
  { path: 'sinistros/:numero', component: SinistroEditorComponent }
];
