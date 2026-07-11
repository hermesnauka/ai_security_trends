import { test, expect } from '@playwright/test';

test.describe('US-19 Digital-by-Default Harms', () => {
  test('shows all 5 suits and the disclaimer banner', async ({ page }) => {
    await page.goto('/frameworks/digital-harms/');
    await expect(page.locator('[data-testid="harms-disclaimer-banner"]')).toBeVisible();

    for (const suit of ['sco', 'arc', 'age', 'tru', 'por']) {
      await expect(page.locator(`[data-testid="${suit}-section"]`)).toBeVisible();
    }
  });

  test('switching to Polish shows the reviewed SCO2 translation', async ({ page }) => {
    await page.goto('/frameworks/digital-harms/?lang=pl');
    await expect(page.locator('[data-testid="card-SCO2"]')).toContainText(/Tommy nie tworzy/i);
  });

  test('a design-harm card never shows a severity badge, at the API layer too', async ({ request }) => {
    const response = await request.get('/wp-json/securepress/v1/threats?suit=sco');
    const body = await response.json();

    for (const card of body.content) {
      expect(card.cardKind).toBe('design_harm');
      expect(card.severity).toBeUndefined();
    }
  });
});
