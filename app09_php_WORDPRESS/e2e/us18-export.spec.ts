import { test, expect } from '@playwright/test';

test.describe('US-18 Export filtered threats to CSV', () => {
  test('export button enqueues a job and offers a download link once complete', async ({ page }) => {
    await page.goto('/threats/?framework=OWASP_LLM');

    await page.locator('[data-testid="export-trigger"]').click();

    await expect(page.locator('[data-testid="export-status"] a')).toBeVisible({ timeout: 15_000 });
  });

  test('the no-JS baseline is a plain link returning job JSON directly', async ({ request }) => {
    const response = await request.get('/wp-json/securepress/v1/export?format=csv&framework=OWASP_LLM');
    expect(response.status()).toBe(202);
    const body = await response.json();
    expect(body.jobId).toBeTruthy();
  });

  test('PDF format is rejected rather than silently downgraded to CSV', async ({ request }) => {
    const response = await request.get('/wp-json/securepress/v1/export?format=pdf');
    expect(response.status()).toBe(422);
  });
});
