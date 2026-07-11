import { test, expect } from '@playwright/test';

test.describe('US-14 Java code samples', () => {
  test('Java tab shows a PreparedStatement-based defense sample', async ({ page }) => {
    await page.goto('/threats/?framework=A03:2021');
    await page.locator('.securepress-threat-card a').first().click();

    await page.locator('[data-language-tab="java"]').first().click();
    const javaBody = page.locator('[data-language-body="java"]').first();
    await expect(javaBody).toContainText('PreparedStatement');
  });

  test('Java sample is presented as content only, with a framework hint, not part of this plugin\'s own build', async ({ page }) => {
    await page.goto('/threats/?framework=A03:2021');
    await page.locator('.securepress-threat-card a').first().click();
    await page.locator('[data-language-tab="java"]').first().click();

    await expect(page.locator('.securepress-code-framework-hint').first()).toContainText('JDBC');
  });
});
