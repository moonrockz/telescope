import { defineConfig } from '@playwright/test';
import { fileURLToPath } from 'node:url';

export const evidenceDir = fileURLToPath(new URL('../../_build/browser/', import.meta.url));

export default defineConfig({
  testDir: '.',
  testMatch: '*.spec.ts',
  globalSetup: './setup.ts',
  outputDir: `${evidenceDir}/test-results`,
  reporter: [['list'], ['json', { outputFile: `${evidenceDir}/results.json` }],
    ['html', { outputFolder: `${evidenceDir}/report`, open: 'never' }]],
  workers: 2,
  retries: 0,
  forbidOnly: !!process.env.CI,
  timeout: 30_000,
  expect: { timeout: 5_000 },
  use: { browserName: 'chromium', trace: 'retain-on-failure', screenshot: 'only-on-failure' },
  projects: [
    { name: 'root', metadata: { base: '/' } },
    { name: 'nested', metadata: { base: '/example/' } },
  ],
});
