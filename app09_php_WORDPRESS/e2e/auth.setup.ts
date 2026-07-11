import { test as setup } from '@playwright/test';

const ADMIN_STORAGE_STATE = 'e2e/.auth/admin.json';

// Logs into wp-admin once and saves the session, so US-08's stride-heatmap
// test (and any other capability-gated page) can reuse it instead of
// logging in per-test. Credentials come from env vars, never hardcoded —
// a real CI run supplies SECUREPRESS_ADMIN_USER/SECUREPRESS_ADMIN_PASSWORD
// for a disposable test-only WordPress install.
setup('authenticate as administrator', async ({ page }) => {
  const username = process.env.SECUREPRESS_ADMIN_USER ?? 'admin';
  const password = process.env.SECUREPRESS_ADMIN_PASSWORD;

  if (!password) {
    setup.skip(true, 'SECUREPRESS_ADMIN_PASSWORD not set — skipping auth setup for local runs without a live WP install.');
    return;
  }

  await page.goto('/wp-login.php');
  await page.fill('#user_login', username);
  await page.fill('#user_pass', password);
  await page.click('#wp-submit');
  await page.waitForURL('**/wp-admin/**');

  await page.context().storageState({ path: ADMIN_STORAGE_STATE });
});

export { ADMIN_STORAGE_STATE };
