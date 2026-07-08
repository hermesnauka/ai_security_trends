import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink, RouterOutlet } from '@angular/router';
import { MatSidenavModule } from '@angular/material/sidenav';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatListModule } from '@angular/material/list';
import { MatIconModule } from '@angular/material/icon';

import { LanguageToggleComponent } from './shared/components/language-toggle/language-toggle.component';

@Component({
  selector: 'tv-root',
  standalone: true,
  imports: [RouterLink, RouterOutlet, MatSidenavModule, MatToolbarModule, MatListModule, MatIconModule, LanguageToggleComponent],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <mat-sidenav-container class="shell">
      <mat-sidenav mode="side" opened class="shell-nav">
        <mat-nav-list>
          <a mat-list-item routerLink="/">
            <mat-icon matListItemIcon>dashboard</mat-icon>
            <span matListItemTitle>Panel</span>
          </a>
        </mat-nav-list>
      </mat-sidenav>
      <mat-sidenav-content>
        <mat-toolbar color="primary">
          <span>ThreatView 2026</span>
          <span class="spacer"></span>
          <tv-language-toggle />
        </mat-toolbar>
        <main class="shell-content">
          <router-outlet />
        </main>
      </mat-sidenav-content>
    </mat-sidenav-container>
  `,
  styles: [
    `
      .shell {
        height: 100vh;
      }
      .shell-nav {
        width: 200px;
      }
      .spacer {
        flex: 1 1 auto;
      }
      .shell-content {
        padding: 24px;
        max-width: 1100px;
        margin: 0 auto;
      }
    `,
  ],
})
export class AppComponent {}
