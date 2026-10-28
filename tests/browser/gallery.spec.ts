import { test, expect } from './fixtures.js';
import { cp, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFile, spawn } from 'node:child_process';
import { promisify } from 'node:util';
import { createServer } from 'node:net';

const fixture = new URL('./fixture/', import.meta.url);
const sourceText = await readFile(new URL('examples/sources/signal.txt', fixture), 'utf8');
const visibleCards = '.gallery-card:not([hidden])';

async function noPageOverflow(page: import('@playwright/test').Page) {
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBeTruthy();
}

test('responsive cards and details select supplied themes and contain their previews', async ({ page, site }) => {
  for (const width of [360, 768, 1440]) {
    await page.setViewportSize({ width, height: 900 });
    for (const theme of ['light', 'dark'] as const) {
      // Each explicit preference overrides the opposite system scheme.
      await page.emulateMedia({ colorScheme: theme === 'light' ? 'dark' : 'light', reducedMotion: 'reduce' });
      await page.goto(site.plain + site.base);
      await page.evaluate(value => localStorage.setItem('site-theme', value), theme);
      await page.goto(site.plain + site.base + 'gallery/');
      await expect(page.getByRole('searchbox', { name: 'Filter examples' })).toBeVisible();
      await expect(page.locator(visibleCards)).toHaveCount(4);
      const signal = page.getByRole('link', { name: 'Signal path', exact: true });
      await expect(page.locator('.gallery-card').filter({ has: signal }).locator(`.gallery-${theme} img`)).toBeVisible();
      await expect(page.locator('.gallery-card').filter({ has: signal }).locator(`.gallery-${theme === 'light' ? 'dark' : 'light'} img`)).toBeHidden();
      await expect(page.locator('.gallery-card').filter({ has: page.getByRole('link', { name: 'Settings structure', exact: true }) }).locator('.gallery-light-only img')).toBeVisible();
      const images = page.locator('.gallery-card-preview:visible img');
      for (const image of await images.all()) {
        await expect(image).toHaveCSS('object-fit', 'contain');
        expect(await image.evaluate((img: HTMLImageElement) => img.complete && img.naturalWidth > 0)).toBeTruthy();
      }
      const planned = page.getByRole('link', { name: 'Future format', exact: true });
      await expect(page.locator('.gallery-card').filter({ has: planned })).toContainText('Planned');
      await expect(planned.locator('img')).toHaveCount(0);
      await noPageOverflow(page);
      await signal.click();
      await expect(page.locator(`#gallery-preview .gallery-${theme} img`)).toBeVisible();
      await expect(page.locator('#site-links a[aria-current="page"]')).toHaveText('Gallery');
      await expect(page.getByRole('link', { name: 'Download SVG', exact: true })).toHaveAttribute('href', site.base + 'gallery/artifacts/previews/signal.svg');
      await expect(page.getByRole('link', { name: 'Download dark SVG', exact: true })).toHaveAttribute('download', '');
      await expect(page.getByText('Scope: Supplied static message flow; no renderer execution.')).toBeVisible();
      await page.getByRole('tab', { name: 'Source', exact: true }).click();
      await expect(page.locator('.gallery-source-file code').first()).toHaveText(sourceText);
      await noPageOverflow(page);
    }
  }
});

test('family and case-insensitive text filters combine, announce counts, reset and follow history', async ({ page, site }) => {
  await page.goto(site.plain + site.base + 'gallery/#family-signal');
  const input = page.getByRole('searchbox', { name: 'Filter examples' });
  const count = page.locator('.gallery-results');
  const families = page.getByRole('navigation', { name: 'Gallery families' });
  await expect(count).toHaveText('2 examples');
  await expect(count).toHaveAttribute('aria-live', 'polite');
  await expect(families.getByRole('link', { name: 'Sequence', exact: true })).toHaveAttribute('aria-current', 'true');
  await input.fill('BOUNDARY');
  await expect(page.locator(visibleCards)).toHaveCount(1);
  await expect(page.locator(visibleCards)).toContainText('Signal path');
  await expect(input).toBeFocused();
  await input.fill('sequence');
  await expect(count).toHaveText('2 examples');
  await input.fill('acknowledged');
  await expect(page.locator(visibleCards)).toContainText('Acknowledged reply');
  await families.getByRole('link', { name: 'JSON', exact: true }).click();
  await expect(count).toHaveText('0 examples');
  await expect(page.getByText('No examples match these filters.')).toBeVisible();
  await expect(page.locator('.gallery-group:not([hidden])')).toHaveCount(0);
  await page.goBack();
  await expect(count).toHaveText('1 example');
  await page.goForward();
  await expect(count).toHaveText('0 examples');
  await page.locator('.gallery-empty').getByRole('button', { name: 'Reset filters' }).click();
  await expect(count).toHaveText('4 examples');
  await expect(input).toHaveValue('');
  await expect(input).toBeFocused();
  await expect(page).toHaveURL(site.plain + site.base + 'gallery/');
  await families.getByRole('link', { name: 'JSON', exact: true }).click();
  await expect(count).toHaveText('1 example');
  await input.fill('sequence');
  await expect(count).toHaveText('0 examples');
  await page.getByRole('button', { name: 'Reset filters' }).first().click();
  await expect(count).toHaveText('4 examples');
  await input.fill('object');
  await expect(page.locator(visibleCards)).toContainText('Settings structure');
});

test('inspection tabs support roving arrows Home End and literal multiple sources', async ({ page, site }) => {
  await page.goto(site.plain + site.base + 'gallery/signal/');
  const tabs = page.getByRole('tablist', { name: 'Example inspection' });
  const preview = tabs.getByRole('tab', { name: 'Preview', exact: true });
  const source = tabs.getByRole('tab', { name: 'Source', exact: true });
  await expect(preview).toHaveAttribute('aria-selected', 'true');
  await expect(source).toHaveAttribute('tabindex', '-1');
  await preview.focus();
  await preview.press('ArrowRight');
  await expect(source).toBeFocused();
  await expect(source).toHaveAttribute('aria-selected', 'true');
  await expect(page.getByRole('tabpanel', { name: 'Source', exact: true })).toBeVisible();
  await expect(page.locator('#gallery-preview')).toBeHidden();
  await expect(page.locator('.gallery-source-file code')).toHaveCount(2);
  expect(await page.locator('.gallery-source-file code').first().textContent()).toBe(sourceText);
  expect(await page.evaluate(() => (window as Window & { sourceExecuted?: boolean }).sourceExecuted)).toBeUndefined();
  await expect(page.getByRole('region', { name: 'sources/binary.bin', exact: true })).toContainText('Inline source unavailable');
  await expect(page.getByRole('region', { name: 'sources/invalid.txt', exact: true })).toContainText('Inline source unavailable');
  await source.press('ArrowRight');
  await expect(preview).toBeFocused();
  await preview.press('ArrowLeft');
  await expect(source).toBeFocused();
  await source.press('Home');
  await expect(preview).toBeFocused();
  await preview.press('End');
  await expect(source).toBeFocused();
  await source.press('Enter');
  await expect(source).toHaveAttribute('aria-selected', 'true');
  await expect(page.getByRole('link', { name: 'Open offline player' })).toHaveAttribute('href', site.base + 'gallery/artifacts/players/signal.html');
  for (const path of ['sources/signal.txt', 'sources/settings.json', 'sources/binary.bin', 'sources/invalid.txt', 'previews/signal.svg', 'previews/signal-dark.svg', 'players/signal.html']) {
    const response = await page.request.get(site.plain + site.base + 'gallery/artifacts/' + path);
    expect(response.ok()).toBeTruthy();
    expect(await response.body()).toEqual(await readFile(new URL('examples/' + path, fixture)));
  }
});

test('copy preserves exact text and clipboard denial leaves selection and downloads', async ({ page, site }) => {
  await page.addInitScript(() => {
    Object.defineProperty(navigator, 'clipboard', { configurable: true, value: {
      writeText: async (text: string) => { (window as Window & { copied?: string }).copied = text; },
    } });
  });
  await page.goto(site.plain + site.base + 'gallery/signal/');
  await page.getByRole('tab', { name: 'Source', exact: true }).click();
  const file = page.getByRole('region', { name: 'sources/signal.txt', exact: true });
  const copy = file.getByRole('button', { name: 'Copy source: sources/signal.txt', exact: true });
  await copy.click();
  await expect(file.getByRole('status')).toHaveText('Source copied.');
  expect(await page.evaluate(() => (window as Window & { copied?: string }).copied)).toBe(sourceText);
  await page.evaluate(() => {
    Object.defineProperty(navigator, 'clipboard', { configurable: true, value: {
      writeText: async () => { throw new DOMException('Denied', 'NotAllowedError'); },
    } });
  });
  await copy.click();
  await expect(file.getByRole('status')).toContainText('Copy unavailable.');
  // Selection serialization follows rendered whitespace. Inspect the selected
  // DOM range to verify every source character, including its final CRLF.
  expect(await page.evaluate(() => {
    const selection = getSelection();
    return selection?.rangeCount ? selection.getRangeAt(0).cloneContents().textContent : null;
  })).toBe(sourceText);
  await expect(file.getByRole('link', { name: 'Download source: sources/signal.txt', exact: true })).toBeVisible();
  await expect(copy).toBeFocused();
});

test('static family links previews and every source survive without JS in version trees', async ({ browser, site }) => {
  const context = await browser.newContext({ javaScriptEnabled: false, viewport: { width: 360, height: 844 } });
  try {
    const page = await context.newPage();
    for (const tree of ['', 'next/', 'latest/']) {
      const base = site.base + tree;
      await page.goto(site.versions + base + 'gallery/');
      await expect(page.locator('.gallery-card')).toHaveCount(4);
      await expect(page.getByRole('searchbox', { name: 'Filter examples' })).toHaveCount(0);
      const family = page.getByRole('navigation', { name: 'Gallery families' }).getByRole('link', { name: 'Sequence', exact: true });
      await family.click();
      await expect(page).toHaveURL(site.versions + base + 'gallery/#family-signal');
      await expect(page.locator('#family-signal')).toBeVisible();
      await page.getByRole('link', { name: 'Signal path', exact: true }).click();
      await expect(page.getByRole('heading', { name: 'Signal path', exact: true })).toBeVisible();
      await expect(page.getByRole('img', { name: 'Signal path preview', exact: true })).toBeVisible();
      await expect(page.locator('.gallery-source-file code').first()).toHaveText(sourceText);
      await expect(page.getByRole('tab')).toHaveCount(0);
      await expect(page.getByRole('button', { name: /Copy source/ })).toHaveCount(0);
      await expect(page.getByRole('link', { name: 'Download source: sources/settings.json', exact: true })).toBeVisible();
      await expect(page.locator('#site-links a[aria-current="page"]')).toHaveAttribute('href', base + 'gallery/');
      await expect(page.getByRole('link', { name: 'Download SVG', exact: true })).toHaveAttribute('href', base + 'gallery/artifacts/previews/signal.svg');
      await expect(page.locator('head link[rel="canonical"]')).toHaveAttribute('href', 'https://observatory.example' + site.base + 'latest/gallery/signal/');
      await noPageOverflow(page);
    }
  } finally { await context.close(); }
});

test('consumer without gallery has no gallery links controls or enhancement', async ({ page, site }) => {
  const dir = await mkdtemp(resolve(tmpdir(), 'telescope-browser-no-gallery-'));
  const project = resolve(dir, 'input');
  const out = resolve(dir, 'out');
  const cli = resolve(fileURLToPath(new URL('../../', import.meta.url)), process.env.TELESCOPE_CLI || '_build/telescope/telescope');
  await cp(fixture, project, { recursive: true });
  const configPath = resolve(project, 'site/no-gallery.json');
  const config = JSON.parse(await readFile(configPath, 'utf8'));
  await writeFile(configPath, JSON.stringify({ ...config, base_path: site.base }));
  let child: ReturnType<typeof spawn> | undefined;
  try {
    await promisify(execFile)(cli, ['build', '--config', 'site/no-gallery.json', '--out', out], { cwd: project });
    const reservation = createServer();
    await new Promise<void>(done => reservation.listen(0, '127.0.0.1', done));
    const address = reservation.address();
    if (!address || typeof address === 'string') throw new Error('Missing loopback port');
    const port = address.port;
    await new Promise<void>((done, reject) => reservation.close(error => error ? reject(error) : done()));
    child = spawn(cli, ['serve', '--config', configPath, '--out', out, '--base', site.base, '--port', String(port)], { cwd: project, stdio: 'ignore' });
    const url = `http://127.0.0.1:${port}${site.base}`;
    await expect.poll(async () => { try { return (await fetch(url)).status; } catch { return 0; } }).toBe(200);
    await page.goto(url);
    await expect(page.locator('html')).toHaveAttribute('data-js', 'true');
    await expect(page.locator('#site-links').getByRole('link', { name: 'Gallery', exact: true })).toHaveCount(0);
    await expect(page.locator('[data-gallery-index], [data-gallery-detail]')).toHaveCount(0);
    await expect(page.getByRole('searchbox', { name: 'Filter examples' })).toHaveCount(0);
    await expect(page.getByRole('tablist', { name: 'Example inspection' })).toHaveCount(0);
    expect((await page.request.get(url + 'gallery/')).status()).toBe(404);
  } finally {
    if (child && child.exitCode === null && child.signalCode === null) {
      const exited = new Promise<void>(done => child!.once('exit', () => done()));
      child.kill('SIGTERM');
      await exited;
    }
    await rm(dir, { recursive: true, force: true });
  }
});


test('assembled trees preserve literal source URLs for copying and downloads', async ({ page, site }) => {
  await page.addInitScript(() => {
    Object.defineProperty(navigator, 'clipboard', { configurable: true, value: {
      writeText: async (text: string) => { (window as Window & { copied?: string }).copied = text; },
    } });
  });
  for (const tree of ['', 'next/', 'latest/', 'v/0.2/', 'v/0.1/']) {
    const base = site.base + tree;
    await page.goto(site.versions + base + 'gallery/signal/');
    await page.getByRole('tab', { name: 'Source', exact: true }).click();
    const file = page.getByRole('region', { name: 'sources/signal.txt', exact: true });
    expect(await file.locator('pre code').textContent(), `literal source in ${base}`).toBe(sourceText);
    await file.getByRole('button', { name: 'Copy source: sources/signal.txt', exact: true }).click();
    expect(await page.evaluate(() => (window as Window & { copied?: string }).copied)).toBe(sourceText);
    const download = file.getByRole('link', { name: 'Download source: sources/signal.txt', exact: true });
    await expect(download).toHaveAttribute('href', base + 'gallery/artifacts/sources/signal.txt');
    const response = await page.request.get(site.versions + base + 'gallery/artifacts/sources/signal.txt');
    expect(response.ok()).toBeTruthy();
    expect(await response.body()).toEqual(await readFile(new URL('examples/sources/signal.txt', fixture)));
    await expect(page.locator('#site-links a[aria-current="page"]')).toHaveAttribute('href', base + 'gallery/');
  }
});

test('independent gallery viewports support zoom limits pan fit skins and denied fullscreen', async ({ page, site }) => {
  await page.addInitScript(() => {
    Element.prototype.requestFullscreen = () => Promise.reject(new DOMException('Denied', 'NotAllowedError'));
  });
  await page.goto(site.plain + site.base + 'gallery/');
  const roots = page.locator('.gallery-card-preview[data-diagram-viewer]:not(.gallery-dark)');
  const first = roots.first();
  const second = roots.nth(1);
  const viewport = first.locator('.diagram-viewer__viewport');
  await expect(viewport).toHaveAttribute('data-viewer-scale', '1');
  await first.evaluate(root => { (root as HTMLElement).style.setProperty('--diagram-viewer-accent', '#ab1234'); });
  await first.getByRole('button', { name: 'Zoom in', exact: true }).click();
  await expect(viewport).toHaveAttribute('data-viewer-scale', '1.25');
  await expect(second.locator('.diagram-viewer__viewport')).toHaveAttribute('data-viewer-scale', '1');
  await viewport.focus();
  const before = await first.locator('.diagram-viewer__content').getAttribute('style');
  await viewport.press('ArrowLeft');
  expect(await first.locator('.diagram-viewer__content').getAttribute('style')).not.toBe(before);
  const box = await viewport.boundingBox();
  if (!box) throw new Error('Viewport missing');
  await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
  await page.mouse.down(); await page.mouse.move(box.x + box.width / 2 + 35, box.y + box.height / 2 + 20, { steps: 4 }); await page.mouse.up();
  await expect(page).toHaveURL(site.plain + site.base + 'gallery/');
  await first.getByRole('button', { name: 'Fullscreen', exact: true }).click();
  await expect(viewport).toHaveAttribute('role', 'dialog');
  await expect(viewport).toHaveAttribute('aria-modal', 'true');
  expect(await viewport.evaluate(node => getComputedStyle(node).getPropertyValue('--dv-accent').trim())).toBe('#ab1234');
  await first.getByRole('button', { name: 'Exit fullscreen', exact: true }).press('Escape');
  await expect(first.getByRole('button', { name: 'Fullscreen', exact: true })).toBeFocused();
  expect(await page.evaluate(() => document.body.style.overflow)).toBe('');
  await first.getByRole('button', { name: 'Fit diagram', exact: true }).click();
  await expect(viewport).toHaveAttribute('data-viewer-scale', '1');
  const plus = first.getByRole('button', { name: 'Zoom in', exact: true });
  for (let i = 0; i < 16 && await plus.isEnabled(); i++) await plus.click();
  await expect(plus).toBeDisabled();
  await expect(viewport).toHaveAttribute('data-viewer-scale', '8');
  const minus = first.getByRole('button', { name: 'Zoom out', exact: true });
  for (let i = 0; i < 24 && await minus.isEnabled(); i++) await minus.click();
  await expect(minus).toBeDisabled();
  await expect(viewport).toHaveAttribute('data-viewer-scale', '0.25');
  await first.getByRole('button', { name: 'Fit diagram', exact: true }).click();
  await page.emulateMedia({ media: 'print' });
  await expect(first.locator('.diagram-viewer__content')).toHaveCSS('transform', 'none');
  await expect(first.locator('.diagram-viewer__toolbar')).toBeHidden();
});

test('configured brand assets and canonical raster adapter work in active version trees', async ({ page, site }) => {
  for (const tree of ['', 'next/']) {
    const base = site.base + tree;
    await page.goto(site.versions + base + 'gallery/signal/');
    await expect(page.locator('.brand img')).toHaveAttribute('src', base + 'assets/brand/logo.svg');
    await expect(page.locator('head link[rel="icon"]')).toHaveAttribute('href', base + 'assets/brand/logo.svg');
    const root = page.locator('.gallery-light[data-diagram-viewer]');
    await root.getByRole('button', { name: 'Zoom in', exact: true }).click();
    await root.getByText('Export image', { exact: true }).click();
    await page.context().setOffline(true);
    const downloadPromise = page.waitForEvent('download');
    await root.getByRole('button', { name: 'Download PNG', exact: true }).click();
    const download = await downloadPromise;
    expect(download.suggestedFilename()).toBe('signal.png');
    const pngPath = await download.path();
    if (!pngPath) throw new Error('PNG download path unavailable');
    const png = await readFile(pngPath);
    expect([...png.subarray(0, 8)]).toEqual([137,80,78,71,13,10,26,10]);
    expect(await page.evaluate(async data => {
      const image = await createImageBitmap(new Blob([new Uint8Array(data)]));
      return [image.width, image.height];
    }, [...png])).toEqual([2, 2]);
    await expect(root.locator('.diagram-viewer__status')).toHaveText('Downloaded PNG, 2 × 2 pixels.');
    const request = await page.evaluate(() => (window as Window & {rasterRequest?: {svg: string; format: string}}).rasterRequest);
    expect(request?.format).toBe('png');
    expect(request?.svg).toBe(await readFile(new URL('examples/previews/signal.svg', fixture), 'utf8'));
    await expect(root.locator('.diagram-viewer__viewport')).toHaveAttribute('data-viewer-scale', '1.25');
    await root.getByLabel('Format', { exact: true }).selectOption('jpeg');
    await root.getByLabel('JPEG quality', { exact: true }).fill('78');
    const jpegPromise = page.waitForEvent('download');
    await root.getByRole('button', { name: 'Download JPEG', exact: true }).click();
    const jpegDownload = await jpegPromise;
    expect(jpegDownload.suggestedFilename()).toBe('signal.jpg');
    const jpegPath = await jpegDownload.path();
    if (!jpegPath) throw new Error('JPEG download path unavailable');
    const jpeg = await readFile(jpegPath);
    expect([...jpeg.subarray(0, 2)]).toEqual([255,216]);
    expect(await page.evaluate(async data => {
      const image = await createImageBitmap(new Blob([new Uint8Array(data)]));
      return [image.width, image.height];
    }, [...jpeg])).toEqual([2, 2]);
    await page.evaluate(() => { (window as Window & {rasterFailure?: boolean}).rasterFailure = true; });
    await root.getByRole('button', { name: 'Download JPEG', exact: true }).click();
    await expect(root.locator('.diagram-viewer__status')).toContainText('Fixture conversion refused');
    await expect(root.getByRole('button', { name: 'Download JPEG', exact: true })).toBeEnabled();
    await expect(page.getByRole('link', { name: 'Download SVG', exact: true })).toBeVisible();
    await page.evaluate(() => {
      Object.assign(window, {rasterFailure: false, rasterHold: true});
    });
    await root.getByRole('button', { name: 'Download JPEG', exact: true }).click();
    await expect(root.getByRole('button', { name: 'Download JPEG', exact: true })).toBeDisabled();
    await root.getByRole('button', { name: 'Cancel export', exact: true }).click();
    await expect(root.locator('.diagram-viewer__status')).toHaveText('Export cancelled.');
    await expect(root.getByRole('button', { name: 'Download JPEG', exact: true })).toBeEnabled();
    await page.evaluate(() => { Object.assign(window, {rasterHold: true}); });
    await root.getByLabel('Format', { exact: true }).selectOption('png');
    const racedDownload = page.waitForEvent('download');
    await root.getByRole('button', { name: 'Download PNG', exact: true }).click();
    await expect(root.getByRole('button', { name: 'Download PNG', exact: true })).toBeDisabled();
    await root.getByLabel('Format', { exact: true }).selectOption('jpeg');
    await root.getByLabel('Width in pixels, blank for source size', { exact: true }).fill('123');
    await page.evaluate(() => { (window as Window & {rasterRelease?: () => void}).rasterRelease?.(); });
    expect((await racedDownload).suggestedFilename()).toBe('signal.png');
    await expect(root.locator('.diagram-viewer__status')).toHaveText('Downloaded PNG, 2 × 2 pixels.');
    const racedRequest = await page.evaluate(() => (window as Window & {rasterRequest?: {format: string; options: object}}).rasterRequest);
    expect(racedRequest).toMatchObject({format: 'png'});
    expect(racedRequest?.options).not.toHaveProperty('width');
    await page.context().setOffline(false);
  }
});

test('detail native fullscreen retains viewport controls and returns focus', async ({ page, site }) => {
  await page.goto(site.plain + site.base + 'gallery/signal/');
  const root = page.locator('.gallery-light[data-diagram-viewer]');
  const viewport = root.locator('.diagram-viewer__viewport');
  await root.getByRole('button', { name: 'Fullscreen', exact: true }).click();
  await expect.poll(() => viewport.evaluate(node => document.fullscreenElement === node)).toBeTruthy();
  await root.getByRole('button', { name: 'Zoom in', exact: true }).click();
  await expect(viewport).toHaveAttribute('data-viewer-scale', '1.25');
  await root.getByRole('button', { name: 'Exit fullscreen', exact: true }).click();
  await expect(root.getByRole('button', { name: 'Fullscreen', exact: true })).toBeFocused();
  expect(await page.evaluate(() => document.fullscreenElement)).toBeNull();
  await root.getByRole('button', { name: 'Fit diagram', exact: true }).click();
  await expect(viewport).toHaveAttribute('data-viewer-scale', '1');
});

test('instance themes select light tokens on a dark site independently of system colors', async ({ page, site }) => {
  await page.emulateMedia({ colorScheme: 'light' });
  await page.addInitScript(() => localStorage.setItem('site-theme', 'dark'));
  await page.goto(site.plain + site.base + 'gallery/signal/');
  const root = page.locator('.gallery-dark[data-diagram-viewer]');
  await expect(root).toHaveAttribute('data-viewer-resolved-theme', 'dark');
  await root.evaluate(node => node.setAttribute('data-viewer-theme', 'light'));
  await expect(root).toHaveAttribute('data-viewer-resolved-theme', 'light');
  await expect(root).toHaveCSS('background-color', 'rgb(249, 250, 251)');
  await expect(root).toHaveCSS('color', 'rgb(17, 24, 39)');
  await root.evaluate(node => node.setAttribute('data-viewer-theme', 'system'));
  await expect(root).toHaveCSS('background-color', 'rgb(249, 250, 251)');
  await expect(root).toHaveCSS('color', 'rgb(17, 24, 39)');
});

test('applied site theme overrides stale denied storage for viewer colors and exports', async ({ page, site }) => {
  await page.emulateMedia({ colorScheme: 'dark' });
  await page.addInitScript(() => {
    Object.defineProperty(Storage.prototype, 'getItem', { value(key: string) { return key === 'site-theme' ? 'dark' : null; } });
    Object.defineProperty(Storage.prototype, 'setItem', { value() { throw new DOMException('Denied', 'SecurityError'); } });
  });
  await page.goto(site.plain + site.base + 'gallery/signal/');
  await page.getByRole('button', { name: 'Theme: dark', exact: true }).click();
  await page.getByRole('button', { name: 'Theme: system', exact: true }).click();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'light');
  const root = page.locator('.gallery-light[data-diagram-viewer]');
  await expect(root).toHaveAttribute('data-viewer-resolved-theme', 'light');
  await expect(root).toHaveCSS('background-color', 'rgb(249, 250, 251)');
  await root.getByText('Export image', { exact: true }).click();
  const download = page.waitForEvent('download');
  await root.getByRole('button', { name: 'Download PNG', exact: true }).click();
  await download;
  expect(await page.evaluate(() => (window as Window & {rasterRequest?: {options: {theme: string}}}).rasterRequest?.options.theme)).toBe('light');
  await page.getByRole('button', { name: 'Theme: light', exact: true }).click();
  await page.getByRole('button', { name: 'Theme: dark', exact: true }).click();
  await expect(page.locator('html')).not.toHaveAttribute('data-theme', /.+/);
  await expect(page.locator('.gallery-dark[data-diagram-viewer]')).toHaveAttribute('data-viewer-resolved-theme', 'dark');
  await page.emulateMedia({ colorScheme: 'light' });
  await expect(page.locator('.gallery-light[data-diagram-viewer]')).toHaveAttribute('data-viewer-resolved-theme', 'light');
});

test('modal fullscreen restores scroll coordinates near the page bottom', async ({ page, site }) => {
  await page.setViewportSize({width: 360, height: 900});
  await page.addInitScript(() => { Element.prototype.requestFullscreen = () => Promise.reject(new DOMException('Denied', 'NotAllowedError')); });
  await page.goto(site.plain + site.base + 'gallery/');
  const target = page.locator('[data-diagram-viewer]:not(.gallery-dark)').last();
  const fullscreen = target.getByRole('button', {name: 'Fullscreen', exact: true});
  await target.scrollIntoViewIfNeeded();
  await fullscreen.evaluate(node => node.addEventListener('click', () => {
    document.documentElement.dataset.beforeModalScroll = String(scrollY);
  }, {capture: true, once: true}));
  await fullscreen.click();
  await expect(target.locator('.diagram-viewer__viewport')).toHaveAttribute('aria-modal', 'true');
  await target.getByRole('button', {name: 'Exit fullscreen', exact: true}).press('Escape');
  expect(await page.evaluate(() => scrollY)).toBe(await page.evaluate(() => Number(document.documentElement.dataset.beforeModalScroll)));
  await expect(fullscreen).toBeFocused();
});
