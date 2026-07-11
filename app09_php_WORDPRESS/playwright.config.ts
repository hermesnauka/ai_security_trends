import { defineConfig, devices } from '@playwright/test';

// PLAN.md Phase 7: one Playwright scenario per user story, run against the
// PHP-rendered pages (no React/SPA — every assertion below is against
// server-rendered HTML, per this app's progressive-enhancement architecture).
export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  retries: process.env.CI ? 2 : 0,
  reporter: 'html',
  use: {
    baseURL: process.env.SECUREPRESS_BASE_URL ?? 'http://localhost:8009',
    trace: 'on-first-retry',
  },
  projects: [
    { name: 'setup', testMatch: /auth\.setup\.ts/ },
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
      dependencies: ['setup'],
      testIgnore: /-authenticated\.spec\.ts/,
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
      dependencies: ['setup'],
      testIgnore: /-authenticated\.spec\.ts/,
    },
    {
      name: 'chromium-authenticated',
      use: { ...devices['Desktop Chrome'], storageState: 'e2e/.auth/admin.json' },
      dependencies: ['setup'],
      testMatch: /-authenticated\.spec\.ts/,
    },
  ],
});
