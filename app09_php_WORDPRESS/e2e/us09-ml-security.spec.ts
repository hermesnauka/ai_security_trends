import { test, expect } from '@playwright/test';

test.describe('US-09 ML security (MLSec cards)', () => {
  test('ml-security page shows MLSec cards with MITRE ATLAS refs where curated', async ({ page }) => {
    await page.goto('/frameworks/ml-security/');
    await expect(page.locator('[data-testid="card-EMR3"]')).toContainText('AML.T0018');
  });

  test('EMR2 has no fabricated OWASP badge (curated as empty on purpose)', async ({ page }) => {
    await page.goto('/frameworks/ml-security/');
    const card = page.locator('[data-testid="card-EMR2"]');
    await expect(card).toBeVisible();
    await expect(card.locator('.securepress-ref-chip')).toHaveCount(0);
  });
});
