import { test, expect } from '@playwright/test';

test.describe('US-12 Website App security (VE/AT/SM/AZ/CR/C cards)', () => {
  test('website-app page shows VE3 mapped to A03:2021 Injection', async ({ page }) => {
    await page.goto('/frameworks/website-app/');
    await expect(page.locator('[data-testid="card-VE3"]')).toContainText('A03:2021');
  });

  test('AZ5 (broken authorization) is shown with critical severity', async ({ page }) => {
    await page.goto('/frameworks/website-app/');
    await expect(page.locator('[data-testid="card-AZ5"] [data-testid="severity-badge"]')).toContainText('critical');
  });
});
