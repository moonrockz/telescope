import { test, expect } from './fixtures.js';

test('search uses the real index, supports slash/arrows/Enter, Escape and empty results', async ({ page, site }) => {
  const fetched: string[] = [];
  page.on('request', request => {
    if (request.url().endsWith('search-index.json')) fetched.push(new URL(request.url()).pathname);
  });
  await page.goto(site.plain + site.base);
  const search = page.getByRole('searchbox', { name: 'Search the site' });
  await expect(search).toBeVisible();
  expect(fetched).toEqual([]);
  await page.keyboard.press('/');
  await expect(search).toBeFocused();
  await search.fill('heliotrope');
  const result = page.locator('.search-results a');
  await expect(result).toHaveCount(1);
  await expect(result).toHaveAttribute('href', site.base + 'docs/guide/');
  await search.press('ArrowDown');
  await expect(page.locator('.search-results .selected a')).toHaveText(/Observatory guide/);
  await Promise.all([page.waitForURL(site.plain + site.base + 'docs/guide/'), search.press('Enter')]);
  await expect(page.getByRole('heading', { name: 'Observatory guide', exact: true })).toBeVisible();
  await search.fill('nosuchobservationxyz');
  await expect(page.locator('.search-empty')).toHaveText('No results');
  await search.press('Escape');
  await expect(search).toHaveValue('');
  await expect(page.locator('.search-results')).toBeHidden();
  expect(fetched.every(path => path === site.base + 'search-index.json')).toBe(true);
});

test('search excludes drafts and development templates', async ({ page, site }) => {
  await page.goto(site.plain + site.base);
  const search = page.getByRole('searchbox', { name: 'Search the site' });
  for (const token of ['Draftobservationtoken', 'Privatetemplatetoken']) {
    await search.fill(token);
    await expect(page.locator('.search-empty')).toHaveText('No results');
    await expect(page.locator('.search-results a')).toHaveCount(0);
  }
  await search.fill('Publishedfirstlighttoken');
  await expect(page.locator('.search-results a')).toHaveAttribute('href', site.base + 'articles/first-light/');
});

test('stored dark theme is applied while the stylesheet is still blocked', async ({ page, context, site }) => {
  await context.addInitScript(() => localStorage.setItem('site-theme', 'dark'));
  let releaseCSS!: () => void;
  const blocked = new Promise<void>(done => { releaseCSS = done; });
  let requestedCSS!: () => void;
  const requested = new Promise<void>(done => { requestedCSS = done; });
  await page.route('**/assets/site.css', async route => {
    requestedCSS();
    await blocked;
    await route.continue();
  });
  const navigation = page.goto(site.plain + site.base + 'docs/guide/');
  try {
    await requested;
    await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
    expect(await page.evaluate(() => document.readyState)).not.toBe('complete');
    // The real render-blocking stylesheet has not been delivered at this observation.
  } finally { releaseCSS(); }
  await navigation;
  const theme = page.getByRole('button', { name: 'Theme: dark', exact: true });
  await expect(theme).toBeVisible();
  await theme.click();
  await expect(page.locator('html')).not.toHaveAttribute('data-theme', /.+/);
  await expect(page.getByRole('button', { name: 'Theme: system', exact: true })).toBeVisible();
  expect(await page.evaluate(() => localStorage.getItem('site-theme'))).toBe('system');
});

test('denied theme storage follows system colors and leaves controls working', async ({ page, context, site }) => {
  await page.emulateMedia({ colorScheme: 'dark' });
  await context.addInitScript(() => {
    for (const method of ['getItem', 'setItem']) {
      Object.defineProperty(Storage.prototype, method, { value() {
        throw new DOMException('Storage denied by browser qualification', 'SecurityError');
      } });
    }
  });
  await page.goto(site.plain + site.base + 'docs/guide/');
  await expect(page.getByRole('button', { name: 'Theme: system', exact: true })).toBeVisible();
  await expect(page.locator('html')).not.toHaveAttribute('data-theme', /.+/);
  expect(await page.evaluate(() => matchMedia('(prefers-color-scheme: dark)').matches)).toBe(true);
  const dark = await page.evaluate(() => {
    const style = getComputedStyle(document.body);
    const luminance = (color: string) => {
      const values = color.match(/[\d.]+/g)!.slice(0, 3).map(value => Number(value) / 255)
        .map(value => value <= 0.04045 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4);
      return values[0] * 0.2126 + values[1] * 0.7152 + values[2] * 0.0722;
    };
    const background = luminance(style.backgroundColor), foreground = luminance(style.color);
    return { background, contrast: (Math.max(background, foreground) + 0.05) / (Math.min(background, foreground) + 0.05) };
  });
  expect(dark.background, 'System dark theme applies a dark rendered background').toBeLessThan(0.1);
  expect(dark.contrast, 'Default body text remains readable with denied storage').toBeGreaterThanOrEqual(4.5);
  await page.getByRole('button', { name: 'Theme: system', exact: true }).click();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'light');
  await expect(page.getByRole('button', { name: 'Theme: light', exact: true })).toBeVisible();
  await page.getByRole('searchbox').fill('heliotrope');
  await expect(page.locator('.search-results a')).toHaveCount(1);
  await expect(page.getByRole('heading', { name: 'Observatory guide', exact: true })).toBeVisible();
});

test('theme cycle persists an explicit preference across navigation', async ({ page, site }) => {
  await page.goto(site.plain + site.base + 'docs/guide/');
  await page.getByRole('button', { name: 'Theme: system', exact: true }).click();
  await page.getByRole('button', { name: 'Theme: light', exact: true }).click();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
  await page.goto(site.plain + site.base);
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
  await expect(page.getByRole('button', { name: 'Theme: dark', exact: true })).toBeVisible();
});

test('narrow menu works by keyboard and long paths do not overflow the page', async ({ page, site }) => {
  await page.setViewportSize({ width: 360, height: 740 });
  await page.goto(site.plain + site.base + 'docs/guide/');
  const menu = page.getByRole('button', { name: 'Menu', exact: true });
  await expect(menu).toBeVisible();
  const navigation = page.getByRole('navigation', { name: 'Main', exact: true });
  await expect(navigation).toBeHidden();
  await menu.focus();
  await page.keyboard.press('Enter');
  await expect(menu).toHaveAttribute('aria-expanded', 'true');
  await expect(navigation).toBeVisible();
  await page.keyboard.press('Space');
  await expect(menu).toHaveAttribute('aria-expanded', 'false');
  await expect(navigation).toBeHidden();
  const width = await page.evaluate(() => ({ document: document.documentElement.scrollWidth, viewport: innerWidth }));
  expect(width.document).toBeLessThanOrEqual(width.viewport + 1);
  await expect(page.locator('pre').last()).toContainText('0123456789abcdef');
});

test('JavaScript-disabled narrow reading keeps navigation, skip link, ToC and code', async ({ browser, site }) => {
  const context = await browser.newContext({ javaScriptEnabled: false, viewport: { width: 360, height: 740 } });
  try {
    const page = await context.newPage();
    await page.goto(site.plain + site.base + 'docs/guide/');
    await expect(page.getByRole('heading', { name: 'Observatory guide', exact: true })).toBeVisible();
    await expect(page.getByRole('navigation', { name: 'Main', exact: true })).toBeVisible();
    await expect(page.locator('pre code').first()).toHaveText("printf 'observatory\\n'\n");
    await expect(page.getByRole('button', { name: 'Copy code' })).toHaveCount(0);
    await expect(page.getByRole('searchbox')).toHaveCount(0);
    const width = await page.evaluate(() => ({ document: document.documentElement.scrollWidth, viewport: innerWidth }));
    expect(width.document).toBeLessThanOrEqual(width.viewport + 1);
    await page.keyboard.press('Tab');
    await expect(page.getByRole('link', { name: 'Skip to content' })).toBeFocused();
    await page.keyboard.press('Enter');
    await expect(page).toHaveURL(/#content$/);
    const toc = page.locator('#site-toc');
    await expect(toc.getByRole('link', { name: 'First observation', exact: true })).toHaveAttribute('href', '#first-observation');
    await toc.getByRole('link', { name: 'First observation', exact: true }).click();
    await expect(page).toHaveURL(/#first-observation$/);
    await page.screenshot({ path: new URL(`../../_build/browser/no-js-${site.base === '/' ? 'root' : 'nested'}.png`, import.meta.url).pathname, fullPage: true });
  } finally { await context.close(); }
});

test('ToC links move to real headings and scrolling updates the current location', async ({ page, site }) => {
  await page.setViewportSize({ width: 1280, height: 450 });
  await page.goto(site.plain + site.base + 'docs/guide/');
  const toc = page.locator('#site-toc');
  await toc.getByRole('link', { name: 'Reading notes', exact: true }).click();
  await expect(page).toHaveURL(/#reading-notes$/);
  await expect(toc.locator('[aria-current="location"]')).toHaveText('Reading notes');
  await expect(page.locator('#reading-notes')).toBeInViewport();
});

test('copy control writes only code to the actual clipboard and announces success', async ({ page, context, site }) => {
  await context.grantPermissions(['clipboard-read', 'clipboard-write']);
  await page.goto(site.plain + site.base + 'docs/guide/');
  const button = page.getByRole('button', { name: 'Copy code', exact: true }).first();
  await button.focus();
  await page.keyboard.press('Enter');
  await expect(button).toHaveAttribute('data-state', 'copied');
  expect(await page.evaluate(() => navigator.clipboard.readText())).toBe("printf 'observatory\\n'");
  await expect(page.locator('[aria-live="polite"]')).toHaveText('Copied');
});

test('copy rejection announces failure without breaking the page', async ({ page, context, site }) => {
  await context.addInitScript(() => Object.defineProperty(navigator, 'clipboard', { value: {
    writeText: () => Promise.reject(new DOMException('Denied', 'NotAllowedError')),
  } }));
  await page.goto(site.plain + site.base + 'docs/guide/');
  const button = page.getByRole('button', { name: 'Copy code', exact: true }).first();
  await button.click();
  await expect(button).toHaveAttribute('data-state', 'failed');
  await expect(page.locator('[aria-live="polite"]')).toHaveText('Copy failed');
  await expect(page.locator('pre code').first()).toContainText("printf 'observatory");
});

test('reviewed HTML script is route-local and executes under both deployment bases', async ({ page, site }) => {
  const scripts: string[] = [];
  page.on('request', request => { if (request.resourceType() === 'script') scripts.push(request.url()); });
  await page.goto(site.plain + site.base + 'docs/guide/');
  await expect(page.getByRole('searchbox')).toBeVisible();
  expect(scripts.filter(url => url.endsWith('/docs/counter.js'))).toEqual([]);
  await page.goto(site.plain + site.base + 'docs/interactive/');
  const counter = page.getByRole('button', { name: 'Observations: 0', exact: true });
  await counter.click();
  await expect(page.getByRole('button', { name: 'Observations: 1', exact: true })).toBeVisible();
  expect(scripts.filter(url => url.endsWith('/docs/counter.js'))).toEqual([site.plain + site.base + 'docs/counter.js']);
});

test('registered island loads its script and stylesheet only on its declared route', async ({ page, site }) => {
  const assets: string[] = [];
  page.on('request', request => { if (request.url().includes('/consumer/counter.')) assets.push(request.url()); });
  await page.goto(site.registered + site.base + 'docs/guide/');
  await expect(page.getByRole('searchbox')).toBeVisible();
  expect(assets).toEqual([]);
  await expect(page.locator('#registered-counter')).toHaveCount(0);
  await page.goto(site.registered + site.base + 'workbench/');
  const counter = page.getByRole('button', { name: 'Registered observations: 0', exact: true });
  await counter.click();
  await expect(page.getByRole('button', { name: 'Registered observations: 1', exact: true })).toHaveCSS('border-top-color', 'rgb(12, 100, 140)');
  expect(assets.sort()).toEqual([site.registered + site.base + 'consumer/counter.css',
    site.registered + site.base + 'consumer/counter.js'].sort());
  await page.goto(site.registered + site.base + 'docs/guide/');
  await expect(page.getByRole('searchbox')).toBeVisible();
  expect(assets).toHaveLength(2);
});

test('registered island fallback remains useful without JavaScript', async ({ browser, site }) => {
  const context = await browser.newContext({ javaScriptEnabled: false });
  try {
    const page = await context.newPage();
    await page.goto(site.registered + site.base + 'workbench/');
    await expect(page.getByRole('heading', { name: 'Registered workbench', exact: true })).toBeVisible();
    await expect(page.locator('#registered-counter')).toHaveText(/instructions remain readable without JavaScript/);
    await expect(page.getByRole('button', { name: /Registered observations/ })).toHaveCount(0);
  } finally { await context.close(); }
});
