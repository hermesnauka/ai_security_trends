import { Routes } from '@angular/router';

// Phase 1 scope is Dashboard only, per PLAN.md's own Phase 1 checklist
// (US-01 coverage lives inside the dashboard's inline framework list, not a
// separate route yet - FrameworkListComponent/FrameworkDetailComponent are
// explicitly Phase 2). Lazy-loaded via loadComponent per the directory layout.
export const routes: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./features/dashboard/dashboard.component').then((m) => m.DashboardComponent),
  },
  { path: '**', redirectTo: '' },
];
