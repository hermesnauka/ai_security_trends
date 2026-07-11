import { test, expect } from '@playwright/test';

test.describe('US-10 Mobile security (MASVS via Mobile App cards)', () => {
  test('mobile-security page shows mobile cards with MASVS category chips', async ({ page }) => {
    await page.goto('/frameworks/mobile-security/');
    await expect(page.locator('[data-testid="card-CRM2"]')).toContainText('MASVS-CRYPTO');
  });

  test('matrix/mobile-vs-web lists MASVS categories alongside OWASP Web Top 10', async ({ page }) => {
    await page.goto('/matrix/mobile-vs-web/');
    await expect(page.getByText('MASVS-STORAGE')).toBeVisible();
    await expect(page.getByText('A03:2021')).toBeVisible();
  });
});
