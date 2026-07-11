import { test, expect } from '@playwright/test';

test.describe('US-16 Lua code samples (rate limiting / LLM DoS)', () => {
  test('LLM10:2025 unbounded-consumption mitigation has a lua-resty-limit-req defense sample', async ({ page }) => {
    await page.goto('/threats/?framework=OWASP_LLM');
    await page.getByText('LLM10:2025').click();

    await page.locator('[data-language-tab="lua"]').first().click();
    const luaBody = page.locator('[data-language-body="lua"]').first();
    await expect(luaBody).toContainText('lua-resty-limit-req');
  });
});
