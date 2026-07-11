import { test, expect } from '@playwright/test';

test.describe('US-06 LLM security (LLM cards + matrix)', () => {
  test('llm-security page shows LLM suit cards', async ({ page }) => {
    await page.goto('/frameworks/llm-security/');
    await expect(page.locator('[data-testid="card-LLM2"]')).toBeVisible();
  });

  test('matrix/llm maps LLM10:2025 to card LLM2', async ({ page }) => {
    await page.goto('/matrix/llm/');
    const row = page.locator('[data-testid="matrix-llm"] tr', { hasText: 'LLM10:2025' });
    await expect(row).toContainText('LLM2');
  });
});
