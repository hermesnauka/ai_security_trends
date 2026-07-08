import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatIconModule } from '@angular/material/icon';
import { catchError, of } from 'rxjs';

import { FrameworkService } from '../../core/services/framework.service';
import { ThreatService } from '../../core/services/threat.service';
import { Framework } from '../../shared/models/framework.model';

@Component({
  selector: 'tv-dashboard',
  standalone: true,
  imports: [MatCardModule, MatFormFieldModule, MatInputModule, MatIconModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <h1>ThreatView 2026</h1>
    <p class="subtitle">
      Interaktywna baza zagrożeń, mitigacji i przykładów kodu w OWASP, MITRE ATLAS i CompTIA SecAI+.
    </p>

    @if (loadFailed()) {
      <div class="error-banner">
        Nie udało się połączyć z API. Sprawdź, czy backend działa na porcie 8080 (<code>docker compose up</code>).
      </div>
    }

    <div class="stats">
      <mat-card>
        <mat-card-subtitle>Frameworki bezpieczeństwa</mat-card-subtitle>
        <mat-card-title>{{ frameworks().length }}</mat-card-title>
      </mat-card>
      <mat-card>
        <mat-card-subtitle>Zagrożenia w katalogu</mat-card-subtitle>
        <mat-card-title>{{ threatCount() ?? '—' }}</mat-card-title>
      </mat-card>
    </div>

    <mat-form-field appearance="outline" class="search">
      <mat-label>Szybkie wyszukiwanie, np. prompt injection...</mat-label>
      <input matInput [value]="query()" (input)="query.set($any($event.target).value)" />
      <mat-icon matSuffix>search</mat-icon>
    </mat-form-field>

    <h2>Frameworki</h2>
    <div class="framework-grid">
      @for (framework of filteredFrameworks(); track framework.code) {
        <mat-card class="framework-card">
          <mat-card-subtitle>{{ framework.code }}</mat-card-subtitle>
          <mat-card-title>{{ framework.name }}</mat-card-title>
          <mat-card-content>{{ framework.version }}</mat-card-content>
        </mat-card>
      } @empty {
        <p class="muted">Brak frameworków spełniających wyszukiwanie.</p>
      }
    </div>
  `,
  styles: [
    `
      .subtitle {
        color: #666;
        max-width: 640px;
      }
      .error-banner {
        background: #fdecea;
        border: 1px solid #f5c6cb;
        color: #611a15;
        padding: 12px 16px;
        border-radius: 4px;
        margin-bottom: 16px;
      }
      .stats {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
        gap: 16px;
        margin-bottom: 24px;
      }
      .search {
        width: 100%;
        max-width: 480px;
        display: block;
        margin-bottom: 24px;
      }
      .framework-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
        gap: 16px;
      }
      .muted {
        color: #888;
      }
    `,
  ],
})
export class DashboardComponent {
  private readonly frameworkService = inject(FrameworkService);
  private readonly threatService = inject(ThreatService);

  readonly query = signal('');
  readonly loadFailed = signal(false);

  private readonly frameworksResult = toSignal(
    this.frameworkService.getFrameworks().pipe(
      catchError(() => {
        this.loadFailed.set(true);
        return of<Framework[]>([]);
      }),
    ),
    { initialValue: [] as Framework[] },
  );

  readonly frameworks = computed(() => this.frameworksResult());

  readonly filteredFrameworks = computed(() => {
    const q = this.query().trim().toLowerCase();
    if (!q) return this.frameworks();
    return this.frameworks().filter(
      (f) => f.name.toLowerCase().includes(q) || f.code.toLowerCase().includes(q),
    );
  });

  private readonly threatCountResult = toSignal(
    this.threatService.search({ size: 1 }).pipe(
      catchError(() => of(null)),
    ),
    { initialValue: null },
  );

  readonly threatCount = computed(() => this.threatCountResult()?.totalElements ?? null);
}
