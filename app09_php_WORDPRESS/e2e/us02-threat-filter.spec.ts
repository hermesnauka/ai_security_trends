import { test, expect } from '@playwright/test';

test.describe('US-02 Threat filtering', () => {
  test('combining framework and severity filters narrows results', async ({ page }) => {
    await page.goto('/threats/?framework=OWASP_LLM&severity=critical');
    await expect(page.getByText('LLM01:2025')).toBeVisible();
    await expect(page.getByText('LLM09:2025')).not.toBeVisible();
  });

  test('search box filters by text without a full navigation once JS loads', async ({ page }) => {
    await page.goto('/threats/');
    await page.fill('#threat-search', 'injection');
    await page.waitForTimeout(400); // debounce in threat-browser.js
    await expect(page.locator('[data-testid="threat-result"]').first()).toBeVisible();
  });

  test('filters work via query string with JavaScript disabled', async ({ browser }) => {
    const context = await browser.newContext({ javaScriptEnabled: false });
    const page = await context.newPage();
    await page.goto('/threats/?framework=OWASP_LLM&severity=critical');
    await expect(page.getByText('LLM01:2025')).toBeVisible();
    await context.close();
  });
});
