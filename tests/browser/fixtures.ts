import { test as base, expect } from '@playwright/test';
import { readFile } from 'node:fs/promises';
import { statePath, type Servers } from './setup.js';

export const test = base.extend<{ site: Servers[string]; scriptErrors: string[] }>({
  site: async ({}, use, testInfo) => {
    const servers: Servers = JSON.parse(await readFile(statePath, 'utf8'));
    await use(servers[testInfo.project.name]);
  },
  scriptErrors: [async ({ page }, use) => {
    const errors: string[] = [];
    page.on('pageerror', error => errors.push(error.message));
    await use(errors);
    expect(errors, 'No uncaught browser script errors').toEqual([]);
  }, { auto: true }],
});
export { expect };
