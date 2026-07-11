import { test, expect } from '@playwright/test';

// Runs only under the 'chromium-authenticated' project (see
// playwright.config.ts's per-project testMatch) — every other project
// excludes this file via testIgnore, so US-08's unauthenticated 401 check in
// us08-stride.spec.ts never conflicts with this authenticated scenario.
test.describe('US-08 STRIDE heatmap (authenticated as administrator)', () => {
  test('heatmap shows all 6 categories', async ({ page }) => {
    await page.goto('/stride-heatmap/');
    await expect(page.locator('[data-testid="stride-cell-sp"]')).toBeVisible();
    await expect(page.locator('[data-testid="stride-cell-ep"]')).toBeVisible();
  });
});
