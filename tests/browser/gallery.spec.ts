import { test, expect } from './fixtures.js';

test('gallery header, families and SVG downloads work on narrow themed pages', async ({ page, site }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  for (const theme of ['light', 'dark'] as const) {
    await page.emulateMedia({ colorScheme: theme });
    await page.goto(site.plain + site.base + 'gallery/');
    const family = page.getByRole('navigation', { name: 'Gallery families' }).getByRole('link', { name: 'Sequence', exact: true });
    await family.focus();
    await expect(family).toBeFocused();
    await family.press('Enter');
    await expect(page).toHaveURL(site.plain + site.base + 'gallery/#family-signal');
    await page.getByRole('link', { name: 'Signal path', exact: true }).click();
    await expect(page.getByRole('img', { name: 'Signal path preview', exact: true })).toBeVisible();
    const gallery = page.locator('#site-links a[aria-current="page"]');
    await expect(gallery).toHaveText('Gallery');
    await expect(gallery).toHaveAttribute('href', site.base + 'gallery/');
    const download = page.getByRole('link', { name: 'Download SVG', exact: true });
    await expect(download).toHaveAttribute('download', '');
    const response = await page.request.get(new URL((await download.getAttribute('href'))!, page.url()).href);
    expect(response.ok()).toBeTruthy();
    expect(await response.text()).toContain('<svg');
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBeTruthy();
  }
});

test('gallery remains navigable without JavaScript through assembled version trees', async ({ browser, site }) => {
  const context = await browser.newContext({ javaScriptEnabled: false, viewport: { width: 390, height: 844 } });
  try {
    const page = await context.newPage();
    for (const tree of ['', 'next/', 'latest/']) {
      const base = site.base + tree;
      await page.goto(site.versions + base + 'gallery/');
      await page.getByRole('link', { name: 'Signal path', exact: true }).click();
      await expect(page.getByRole('heading', { name: 'Signal path', exact: true })).toBeVisible();
      await expect(page.locator('#site-links a[aria-current="page"]')).toHaveAttribute('href', base + 'gallery/');
      await expect(page.getByRole('link', { name: 'Download SVG', exact: true })).toHaveAttribute('href', base + 'gallery/artifacts/previews/signal.svg');
      await expect(page.locator('head link[rel="canonical"]')).toHaveAttribute('href', 'https://observatory.example' + site.base + 'latest/gallery/signal/');
    }
  } finally { await context.close(); }
});
