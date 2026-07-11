import { test, expect } from '@playwright/test';

test.describe('US-11 DevOps + Cloud + BOT security, and this WordPress install\'s own hardening', () => {
  test('devops-security page shows DVO suit cards', async ({ page }) => {
    await page.goto('/frameworks/devops-security/');
    await expect(page.locator('[data-testid="card-DVOK"]')).toContainText('A06:2021');
  });

  test('BOT suit is rate-limited at 60 requests/minute per IP', async ({ request }) => {
    let lastStatus = 200;
    for (let i = 0; i < 61; i++) {
      const response = await request.get('/wp-json/securepress/v1/threats?suit=bot');
      lastStatus = response.status();
    }
    expect(lastStatus).toBe(429);
  });

  test('xmlrpc.php does not respond as a working XML-RPC endpoint', async ({ request }) => {
    const response = await request.post('/xmlrpc.php', {
      data: '<?xml version="1.0"?><methodCall><methodName>demo.sayHello</methodName></methodCall>',
      headers: { 'Content-Type': 'text/xml' },
    });
    expect(response.status()).not.toBe(200);
  });
});
