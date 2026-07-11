import { test, expect } from '@playwright/test';

test.describe('US-07 Agentic AI + Cloud', () => {
  test('agentic-ai page shows AAI suit cards, AAIK flagged as autonomy risk', async ({ page }) => {
    await page.goto('/frameworks/agentic-ai/');
    await expect(page.locator('[data-testid="card-AAIK"] [data-testid="autonomy-risk-badge"]')).toBeVisible();
  });

  test('CLD3 (cloud storage exposure) cross-references A05:2021', async ({ page }) => {
    await page.goto('/frameworks/devops-security/');
    await expect(page.locator('[data-testid="card-CLD3"]')).toContainText('A05:2021');
  });

  test('matrix/agentic honestly reports that no Agentic AI Top 10 threats are seeded', async ({ page }) => {
    await page.goto('/matrix/agentic/');
    await expect(page.getByText(/not yet seeded/i)).toBeVisible();
  });
});
