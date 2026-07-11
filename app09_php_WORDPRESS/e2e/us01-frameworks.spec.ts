import { test, expect } from '@playwright/test';

test.describe('US-01 Framework catalogue', () => {
  test('home page lists at least 11 seeded frameworks as tiles', async ({ page }) => {
    await page.goto('/security-catalogue/');
    const tiles = page.locator('.securepress-framework-tile');
    await expect(tiles).toHaveCount(await tiles.count());
    expect(await tiles.count()).toBeGreaterThanOrEqual(11);
  });

  test('clicking a framework tile navigates to its threat archive', async ({ page }) => {
    await page.goto('/security-catalogue/');
    await page.getByText('OWASP Top 10 for Large Language Model Applications').click();
    await expect(page).toHaveURL(/\/threats\/\?framework=OWASP_LLM/);
  });

  test('works with JavaScript disabled', async ({ browser }) => {
    const context = await browser.newContext({ javaScriptEnabled: false });
    const page = await context.newPage();
    await page.goto('/security-catalogue/');
    await expect(page.locator('.securepress-framework-tile').first()).toBeVisible();
    await context.close();
  });
});
