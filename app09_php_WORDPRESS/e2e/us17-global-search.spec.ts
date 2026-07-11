import { test, expect } from '@playwright/test';

test.describe('US-17 Global search', () => {
  test('searching a term finds related threats and cards with highlighted excerpts', async ({ page }) => {
    await page.goto('/search/?q=injection');

    await expect(page.locator('[data-testid="search-threats"]')).toContainText('A03:2021');
    await expect(page.locator('[data-testid="search-threats"] mark').first()).toBeVisible();
  });

  test('rejects a query longer than 200 characters at the API layer', async ({ request }) => {
    const longQuery = 'a'.repeat(201);
    const response = await request.get(`/wp-json/securepress/v1/search?q=${longQuery}`);
    expect(response.status()).toBe(422);
  });

  test('search page works via query string with JavaScript disabled', async ({ browser }) => {
    const context = await browser.newContext({ javaScriptEnabled: false });
    const page = await context.newPage();
    await page.goto('/search/?q=injection');
    await expect(page.locator('[data-testid="search-threats"]')).toContainText('A03:2021');
    await context.close();
  });
});
