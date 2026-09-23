import { Routes } from '@angular/router';
import { MonitorDashboardComponent } from './pages/monitor-dashboard/monitor-dashboard.component';

export const routes: Routes = [
  { path: '', redirectTo: 'monitor', pathMatch: 'full' },
  { path: 'monitor', component: MonitorDashboardComponent }
];
