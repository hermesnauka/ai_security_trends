import { ChangeDetectionStrategy, Component, signal } from '@angular/core';
import { MatButtonToggleModule } from '@angular/material/button-toggle';

const STORAGE_KEY = 'tv_locale';
type Locale = 'pl' | 'en';

/**
 * Persists the PL/EN choice to localStorage under the key PLAN.md specifies
 * (D-10), but does NOT translate anything yet - ngx-translate wiring is
 * Phase 5 scope, same deferral app01_react made for its own i18n toggle.
 * This is the toggle's persistence mechanism, not the translation pipeline.
 */
@Component({
  selector: 'tv-language-toggle',
  standalone: true,
  imports: [MatButtonToggleModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <mat-button-toggle-group [value]="locale()" (change)="setLocale($event.value)" aria-label="Language">
      <mat-button-toggle value="pl">PL</mat-button-toggle>
      <mat-button-toggle value="en">EN</mat-button-toggle>
    </mat-button-toggle-group>
  `,
})
export class LanguageToggleComponent {
  readonly locale = signal<Locale>((localStorage.getItem(STORAGE_KEY) as Locale) ?? 'pl');

  setLocale(value: Locale): void {
    this.locale.set(value);
    localStorage.setItem(STORAGE_KEY, value);
  }
}
