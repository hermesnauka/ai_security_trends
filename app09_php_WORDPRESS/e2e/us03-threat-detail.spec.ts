import { test, expect } from '@playwright/test';

test.describe('US-03 Threat detail with mitigations and code', () => {
  test('shows overview, attack vectors, mitigations, and code sample tabs', async ({ page }) => {
    await page.goto('/threats/?framework=A03:2021');
    await page.locator('.securepress-threat-card a').first().click();

    await expect(page.locator('[data-testid="threat-detail"]')).toBeVisible();
    await expect(page.locator('#mitigations')).toBeVisible();
    await expect(page.locator('#code-samples')).toBeVisible();
  });

  test('attack-demo code is hidden until the disclosure is opened', async ({ page }) => {
    await page.goto('/threats/?framework=A03:2021');
    await page.locator('.securepress-threat-card a').first().click();

    const codeBody = page.locator('[data-testid="attack-demo-code-body"]').first();
    await expect(codeBody).toBeHidden();

    await page.locator('.securepress-attack-demo-label').first().click();
    await expect(codeBody).toBeVisible();
  });

  test('language tabs switch which code sample is shown once JS loads', async ({ page }) => {
    await page.goto('/threats/?framework=A03:2021');
    await page.locator('.securepress-threat-card a').first().click();

    const goTab = page.locator('[data-language-tab="go"]').first();
    await goTab.click();
    await expect(goTab).toHaveAttribute('aria-selected', 'true');
  });
});
