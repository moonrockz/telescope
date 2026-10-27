import { test, expect } from './fixtures.js';

const palettes = {
  light: { background: 'rgb(249, 250, 251)', foreground: 'rgb(17, 24, 39)', accent: '#4f46e5', surface: '#ffffff' },
  dark: { background: 'rgb(15, 16, 20)', foreground: 'rgb(229, 231, 235)', accent: '#a5b4fc', surface: '#17181f' },
};

test('Smithy palette stays consistent across page types and explicit/system preferences', async ({ page, site }) => {
  for (const system of ['light', 'dark'] as const) {
    await page.emulateMedia({ colorScheme: system });
    for (const preference of ['system', 'light', 'dark'] as const) {
      await page.goto(site.plain + site.base);
      await page.evaluate(value => localStorage.setItem('site-theme', value), preference);
      const expected = palettes[preference === 'system' ? system : preference];
      for (const route of ['', 'docs/guide/', 'articles/first-light/', 'api/', 'gallery/']) {
        await page.goto(site.plain + site.base + route);
        const colors = await page.evaluate(() => {
          const root = getComputedStyle(document.documentElement), body = getComputedStyle(document.body);
          return { background: body.backgroundColor, foreground: body.color, accent: root.getPropertyValue('--accent').trim(), surface: root.getPropertyValue('--surface').trim() };
        });
        expect(colors, `${system} system, ${preference} choice, ${route || 'landing'}`).toEqual(expected);
      }
    }
  }
});

test('body, secondary text and essential control boundaries have measured contrast', async ({ page, site }) => {
  for (const theme of ['light', 'dark'] as const) {
    await page.emulateMedia({ colorScheme: theme });
    await page.goto(site.plain + site.base + 'gallery/');
    const ratios = await page.evaluate(() => {
      const root = getComputedStyle(document.documentElement);
      const rgb = (token: string) => {
        const probe = document.createElement('span'); probe.style.color = root.getPropertyValue(token); document.body.append(probe);
        const value = getComputedStyle(probe).color; probe.remove();
        return value.match(/[\d.]+/g)!.slice(0, 3).map(Number);
      };
      const luminance = (values: number[]) => values.map(v => v / 255).map(v => v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4).reduce((sum, value, i) => sum + value * [0.2126, 0.7152, 0.0722][i], 0);
      const contrast = (a: string, b: string) => { const x = luminance(rgb(a)), y = luminance(rgb(b)); return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05); };
      return {
        text: contrast('--page-fg', '--page-bg'), secondary: contrast('--muted', '--surface'),
        links: contrast('--accent', '--page-bg'), selected: contrast('--accent', '--accent-soft'),
        control: contrast('--control-border', '--surface'), focus: contrast('--accent', '--surface'),
      };
    });
    for (const token of ['text', 'secondary', 'links', 'selected'] as const) expect(ratios[token], `${theme} ${token}`).toBeGreaterThanOrEqual(4.5);
    for (const token of ['control', 'focus'] as const) expect(ratios[token], `${theme} ${token}`).toBeGreaterThanOrEqual(3);
    const search = page.getByRole('searchbox', { name: 'Search the site' });
    await search.focus();
    expect(await search.evaluate(node => ({ style: getComputedStyle(node).outlineStyle, width: getComputedStyle(node).outlineWidth }))).toEqual({ style: 'solid', width: '3px' });
  }
});
