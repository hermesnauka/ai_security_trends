import { test, expect } from '@playwright/test';

test.describe('US-15 Scala code samples (supply-chain attacks)', () => {
  test('supply-chain-dependency-integrity mitigation has a Scala sbt-dependency-check sample', async ({ page }) => {
    await page.goto('/threats/?framework=A08:2021');
    await page.locator('.securepress-threat-card a').first().click();

    await page.locator('[data-language-tab="scala"]').first().click();
    const scalaBody = page.locator('[data-language-body="scala"]').first();
    await expect(scalaBody).toContainText('sbt-dependency-check');
  });
});
