import { test, expect } from '@playwright/test';

test.describe('US-08 STRIDE EoP catalogue and heatmap (unauthenticated)', () => {
  test('stride catalogue shows all 6 STRIDE suits worth of cards', async ({ page }) => {
    await page.goto('/frameworks/stride/');
    await expect(page.locator('[data-testid="card-SP2"]')).toBeVisible();
    await expect(page.locator('[data-testid="card-EP2"]')).toBeVisible();
  });

  test('heatmap requires login', async ({ page }) => {
    const response = await page.goto('/stride-heatmap/');
    expect(response?.status()).toBe(401);
  });
});
