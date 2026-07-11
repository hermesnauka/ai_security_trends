import { test, expect } from '@playwright/test';

test.describe('US-13 Python code samples', () => {
  test('every seeded mitigation has a Python tab with a defense sample', async ({ page }) => {
    await page.goto('/threats/?framework=A03:2021');
    await page.locator('.securepress-threat-card a').first().click();

    await page.locator('[data-language-tab="python"]').first().click();
    const pythonBody = page.locator('[data-language-body="python"]').first();
    await expect(pythonBody.locator('.securepress-code-defense pre')).toContainText('SECURE pattern');
  });
});
