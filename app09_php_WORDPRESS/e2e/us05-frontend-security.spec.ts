import { test, expect } from '@playwright/test';

test.describe('US-05 Frontend/client-side security (FRE cards)', () => {
  test('frontend-security page shows FRE suit cards with Polish descriptions', async ({ page }) => {
    await page.goto('/frameworks/frontend-security/?lang=pl');
    await expect(page.locator('[data-testid="card-FRE4"]')).toContainText('James wstrzykuje');
  });

  test('FRE2 shows an OWASP reference chip', async ({ page }) => {
    await page.goto('/frameworks/frontend-security/');
    await expect(page.locator('[data-testid="card-FRE2"]')).toContainText('A03:2021');
  });
});
