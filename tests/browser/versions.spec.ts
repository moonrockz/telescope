import { test, expect } from './fixtures.js';

test('version selector preserves an existing page and checks availability with HEAD', async ({ page, site }) => {
  const probes: string[] = [];
  page.on('request', request => { if (request.method() === 'HEAD') probes.push(new URL(request.url()).pathname); });
  await page.goto(site.versions + site.base + 'next/docs/guide/');
  await expect(page.locator('.version-banner')).toHaveText('Unreleased docs.');
  await expect(page.locator('head link[rel="canonical"]')).toHaveAttribute('href', 'https://observatory.example' + site.base + 'latest/docs/guide/');
  const versions = page.getByRole('combobox', { name: 'Docs version', exact: true });
  await expect(versions).toHaveValue('next');
  await expect(versions.locator('option')).toHaveText(['Latest (0.2)', 'main', '0.2', '0.1']);
  await versions.selectOption('0.1');
  await expect(page).toHaveURL(site.versions + site.base + 'v/0.1/docs/guide/');
  expect(probes).toEqual([site.base + 'v/0.1/docs/guide/']);
  await expect(page.getByRole('heading', { name: 'Observatory guide', exact: true })).toBeVisible();
  await expect(page.getByRole('link', { name: 'Open latest docs', exact: true })).toHaveAttribute('href', site.base + 'latest/docs/guide/');
  await page.getByRole('link', { name: 'Open latest docs', exact: true }).click();
  await expect(page).toHaveURL(site.versions + site.base + 'latest/docs/guide/');
});

test('next-only page falls back to target docs section when missing from a release', async ({ page, site }) => {
  const missing: number[] = [];
  page.on('response', response => {
    if (response.request().method() === 'HEAD' && response.url().endsWith('/latest/docs/next-only/')) missing.push(response.status());
  });
  await page.goto(site.versions + site.base + 'next/docs/next-only/');
  await expect(page.getByRole('heading', { name: 'Aurora preview', exact: true })).toBeVisible();
  await expect(page.locator('head link[rel="canonical"]')).toHaveCount(0);
  await page.getByRole('combobox', { name: 'Docs version', exact: true }).selectOption('latest');
  await expect(page).toHaveURL(site.versions + site.base + 'latest/docs/');
  expect(missing).toEqual([404]);
  await expect(page.getByRole('heading', { name: 'Documentation', exact: true })).toBeVisible();
});

test('search fetches the current tree index and cannot find other-version content', async ({ page, site }) => {
  const indexes: string[] = [];
  page.on('request', request => {
    if (request.url().endsWith('search-index.json')) indexes.push(new URL(request.url()).pathname);
  });
  await page.goto(site.versions + site.base + 'v/0.1/docs/guide/');
  const search = page.getByRole('searchbox');
  await search.fill('heliotrope');
  await expect(page.locator('.search-results a')).toHaveAttribute('href', site.base + 'v/0.1/docs/guide/');
  await search.fill('Auroranexttoken');
  await expect(page.locator('.search-empty')).toHaveText('No results');
  await search.fill('Retiredoldtoken');
  await expect(page.locator('.search-results a')).toHaveAttribute('href', site.base + 'v/0.1/docs/retired/');
  expect(indexes).toEqual([site.base + 'v/0.1/search-index.json']);
  await page.goto(site.versions + site.base + 'next/');
  await search.fill('Auroranexttoken');
  await expect(page.locator('.search-results a')).toHaveAttribute('href', site.base + 'next/docs/next-only/');
  await search.fill('Retiredoldtoken');
  await expect(page.locator('.search-empty')).toHaveText('No results');
  expect(indexes).toEqual([site.base + 'v/0.1/search-index.json', site.base + 'next/search-index.json']);
});

test('assembled root and latest search navigate inside the selected tree', async ({ page, site }) => {
  for (const tree of ['', 'latest/']) {
    const currentBase = site.base + tree;
    const loadedIndex = page.waitForRequest(request =>
      request.url() === site.versions + currentBase + 'search-index.json');
    await page.goto(site.versions + currentBase);
    const search = page.getByRole('searchbox');
    await search.fill('heliotrope');
    await loadedIndex;
    const result = page.locator('.search-results a');
    await expect(result).toHaveCount(1);
    await expect(result).toHaveAttribute('href', currentBase + 'docs/guide/');
    await search.press('Enter');
    await expect(page).toHaveURL(site.versions + currentBase + 'docs/guide/');
    await expect(page.getByRole('heading', { name: 'Observatory guide', exact: true })).toBeVisible();
  }
});

test('old-version static banner uses a section fallback without JavaScript', async ({ browser, site }) => {
  const context = await browser.newContext({ javaScriptEnabled: false });
  try {
    const page = await context.newPage();
    await page.goto(site.versions + site.base + 'v/0.1/docs/retired/');
    await expect(page.locator('.version-banner')).toContainText('Older documentation. Latest version: 0.2');
    const latest = page.getByRole('link', { name: 'Open latest docs', exact: true });
    await expect(latest).toHaveAttribute('href', site.base + 'latest/docs/');
    await latest.click();
    await expect(page).toHaveURL(site.versions + site.base + 'latest/docs/');
  } finally { await context.close(); }
});

test('no-release assembly identifies prerelease docs and selects only main', async ({ page, site }) => {
  await page.goto(site.prerelease + site.base + 'docs/guide/');
  await expect(page.locator('.version-banner')).toHaveText('Pre-release docs. No version is released yet.');
  const versions = page.getByRole('combobox', { name: 'Docs version', exact: true });
  await expect(versions.locator('option')).toHaveText(['main']);
  await expect(versions).toHaveValue('next');
  await page.goto(site.prerelease + site.base + 'next/docs/guide/');
  await expect(page.locator('.version-banner')).toHaveText('Pre-release docs. No version is released yet.');
  await expect(versions).toHaveValue('next');
});
