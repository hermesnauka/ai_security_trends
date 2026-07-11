import { test, expect } from '@playwright/test';

test.describe('US-04 Cross-framework mapping', () => {
  test('A03:2021 Injection shows a cross-reference to LLM01:2025 Prompt Injection', async ({ page }) => {
    await page.goto('/threats/?framework=A03:2021');
    await page.locator('.securepress-threat-card a').first().click();

    await expect(page.locator('[data-testid="cross-references"]')).toContainText('LLM01:2025');
  });

  test('MITRE ATLAS kill-chain timeline renders for LLM01:2025', async ({ page }) => {
    await page.goto('/threats/?framework=OWASP_LLM');
    await page.getByText('LLM01:2025').click();

    await expect(page.locator('[data-testid="killchain"]')).toContainText('TA0003');
  });

  test('kill-chain list is present and readable with JavaScript disabled', async ({ browser }) => {
    const context = await browser.newContext({ javaScriptEnabled: false });
    const page = await context.newPage();
    await page.goto('/threats/?framework=OWASP_LLM');
    await page.getByText('LLM01:2025').click();
    await expect(page.locator('[data-testid="killchain"]')).toBeVisible();
    await context.close();
  });
});
