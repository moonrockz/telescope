import { test, expect } from './fixtures.js';
import type { Page } from '@playwright/test';

async function openEditor(page: Page, site: { registered: string; base: string }) {
  await page.goto(site.registered + site.base + 'editor/');
  await expect(page.locator('.cm-editor')).toBeVisible();
}

// The module is the same public component used by the built page and tutorials.
async function makeEditor(page: Page, base: string, adapter: string, options: Record<string, unknown> = {}) {
  await page.evaluate(async ({ base, adapter, options }) => {
    const { mountEditor } = await import(base + 'assets/editor/editor.js');
    (window as any).testEditor?.dispose();
    document.getElementById('test-editor')?.remove();
    const host = document.createElement('div'); host.id = 'test-editor'; document.querySelector('main')!.append(host);
    (window as any).editorEvents = [];
    (window as any).testEditor = await mountEditor(host, { id: 'test-instance', adapter,
      documents: [{ id: 'a', name: 'a.txt', language: 'text', text: 'alpha  ' },
        { id: 'b', name: 'b.txt', language: 'text', text: 'beta  ' }],
      formatters: [{ id: 'test.whitespace', contract_version: 1, formatter_version: '1', languages: ['text'],
        worker: 'consumer/editor-test-worker.js', assets: ['consumer/editor-test-worker.js'] }],
      languages: { text: { provider: 'test.whitespace', options: {} } }, assetBase: base,
      onChange: (event: unknown) => (window as any).editorEvents.push(event), ...options });
  }, { base, adapter, options });
}

const whitespaceWorker = `self.onmessage = e => { const request = e.data; setTimeout(() => self.postMessage({request, output:{text:request.input.target.text.trimEnd()}}), 80); };`;

test('standalone rich MoonBit aliases highlight live source and retain state in both themes', async ({ page, site }) => {
  await openEditor(page, site);
  const host = page.locator('[data-telescope-editor]');
  const original = await host.evaluate((el: any) => el.telescopeEditor.getDocument('main').text);
  for (const theme of ['light', 'dark']) {
    await page.evaluate(theme => { document.documentElement.dataset.theme = theme; }, theme);
    for (const token of ['keyword', 'number', 'string', 'comment', 'annotation']) await expect(host.locator(`.te-token-${token}`).first()).toBeVisible();
    const ratios = await host.evaluate((node: Element) => {
      const rgb = (value: string) => value.match(/[\d.]+/g)!.slice(0, 3).map(Number);
      const luminance = (value: string) => rgb(value).map(v => v / 255).map(v => v <= .04045 ? v / 12.92 : ((v + .055) / 1.055) ** 2.4).reduce((sum, v, i) => sum + v * [.2126, .7152, .0722][i], 0);
      const bg = luminance(getComputedStyle(node.querySelector('.telescope-editor')!).backgroundColor);
      return [...node.querySelectorAll('[class*="te-token-"]')].map(token => { const fg = luminance(getComputedStyle(token).color); return (Math.max(fg, bg) + .05) / (Math.min(fg, bg) + .05); });
    });
    for (const ratio of ratios) expect(ratio, `${theme} syntax contrast`).toBeGreaterThanOrEqual(4.5);
  }
  await host.evaluate((el: any) => {
    const editor = el.telescopeEditor;
    editor.setSelection('main', { anchor: 5, head: 9 });
    editor.setLanguage('main', 'text');
  });
  await expect(host.locator('.te-token-keyword')).toHaveCount(0);
  await host.evaluate((el: any) => el.telescopeEditor.setLanguage('main', 'mbt'));
  await expect(host.locator('.te-token-keyword').first()).toBeVisible();
  expect(await host.evaluate((el: any) => el.telescopeEditor.getSelection('main'))).toEqual({ anchor: 5, head: 9 });
  expect(await host.evaluate((el: any) => el.telescopeEditor.getDocument('main').text)).toBe(original);
  await host.evaluate((el: any) => el.telescopeEditor.edit('main', 'let text = "incomplete'));
  await expect(host.locator('.te-token-string')).toHaveText('"incomplete');
  await host.evaluate((el: any) => el.telescopeEditor.edit('main', 'let text = "complete"\nlet answer = 42'));
  await expect(host.locator('.te-token-number')).toHaveText('42');
  await host.evaluate((el: any) => el.telescopeEditor.selectDocument('second'));
  await expect(host.locator('.te-token-string')).toHaveText("'x'");
  await host.evaluate((el: any) => { el.telescopeEditor.selectDocument('main'); el.telescopeEditor.undo(); });
  expect(await host.evaluate((el: any) => el.telescopeEditor.getDocument('main').text)).toBe('let text = "incomplete');
  await host.evaluate(async (el: any) => el.telescopeEditor.setAdapter('plain'));
  await expect(host.locator('textarea')).toHaveValue('let text = "incomplete');
  await host.evaluate((el: any) => el.telescopeEditor.undo());
  await expect(host.locator('textarea')).toHaveValue(original);
});

for (const adapter of ['plain', 'rich']) {
  test(`${adapter} standalone compiled Formatter is one undoable change with isolated histories`, async ({ page, site }) => {
    await openEditor(page, site);
    const host = page.locator('[data-telescope-editor]');
    await host.evaluate(async (el: any, adapter: string) => { await el.telescopeEditor.setAdapter(adapter); el.telescopeEditor.selectDocument('notes'); }, adapter);
    await host.getByRole('button', { name: 'Format', exact: true }).click();
    await expect(host.getByRole('status')).toHaveText('Formatted.');
    expect(await host.evaluate((el: any) => el.telescopeEditor.getDocument('notes').text)).toBe('first\nsecond');
    await host.evaluate((el: any) => el.telescopeEditor.focus());
    await page.keyboard.press('ControlOrMeta+z');
    expect(await host.evaluate((el: any) => el.telescopeEditor.getDocument('notes').text)).toBe('first  \nsecond\t');
    await host.evaluate((el: any) => { el.telescopeEditor.selectDocument('second'); el.telescopeEditor.edit('second', 'changed'); el.telescopeEditor.undo(); });
    expect(await host.evaluate((el: any) => el.telescopeEditor.getDocument('second').text)).toBe("let second = 'x'\n");
    expect(await host.evaluate((el: any) => el.telescopeEditor.getDocument('notes').text)).toBe('first  \nsecond\t');
    await expect(host.getByRole('button', { name: 'Format', exact: true })).toBeHidden();
    const input = adapter === 'rich' ? host.locator('.cm-content') : host.locator('textarea');
    await host.evaluate((el: any) => { const length = el.telescopeEditor.getDocument('second').text.length; el.telescopeEditor.setSelection('second', {anchor:length, head:length}); });
    await input.focus(); await page.keyboard.insertText('live');
    expect(await host.evaluate((el: any) => el.telescopeEditor.getDocument('second').text)).toBe("let second = 'x'\nlive");
    await page.keyboard.press('ControlOrMeta+z');
    expect(await host.evaluate((el: any) => el.telescopeEditor.getDocument('second').text)).toBe("let second = 'x'\n");
    await host.evaluate(async (el: any) => { el.telescopeEditor.selectDocument('notes'); await el.telescopeEditor.format(); });
    await host.evaluate((el: any) => { (window as any).standaloneChanges = 0; el.addEventListener('editor-change', () => (window as any).standaloneChanges++); });
    await host.evaluate(async (el: any) => el.telescopeEditor.format());
    expect(await page.evaluate(() => (window as any).standaloneChanges)).toBe(0);
    await host.evaluate((el: any) => el.telescopeEditor.undo());
    expect(await host.evaluate((el: any) => el.telescopeEditor.getDocument('notes').text)).toBe('first  \nsecond\t');
  });

  test(`${adapter} formatting follows originating document across tabs and rejects changed contexts`, async ({ page, context, site }) => {
    await context.route('**/consumer/editor-test-worker.js', route => route.fulfill({ contentType: 'text/javascript', body: whitespaceWorker }));
    await openEditor(page, site); await makeEditor(page, site.base, adapter);
    await page.evaluate(() => { const e = (window as any).testEditor; e.setSelection('b', { anchor: 2, head: 2 }); (window as any).formatting = e.format('a'); e.selectDocument('b'); e.focus(); (window as any).editorFocus = document.activeElement; });
    expect(await page.evaluate(async () => await (window as any).formatting)).toBe(true);
    expect(await page.evaluate(() => (window as any).testEditor.getDocument('a').text)).toBe('alpha');
    expect(await page.evaluate(() => (window as any).testEditor.getSelection('b'))).toEqual({ anchor: 2, head: 2 });
    expect(await page.evaluate(() => document.activeElement === (window as any).editorFocus)).toBe(true);
    await page.evaluate(() => { const e = (window as any).testEditor; e.edit('a', 'alpha  '); (window as any).formatting = e.format('a'); e.edit('b', 'new context'); });
    expect(await page.evaluate(async () => await (window as any).formatting)).toBe(false);
    expect(await page.evaluate(() => (window as any).testEditor.getDocument('a').text)).toBe('alpha  ');
    await page.evaluate(() => { const e = (window as any).testEditor; (window as any).formatting = e.format('a'); e.reset(); });
    expect(await page.evaluate(async () => await (window as any).formatting)).toBe(false);
    expect(await page.evaluate(() => (window as any).testEditor.undo('a'))).toBe(false);
    expect(await page.evaluate(() => (window as any).testEditor.getDocument('a').text)).toBe('alpha  ');
  });
}

test('formatter failures, malformed replies, timeout and replacement preserve documents and allow explicit retry', async ({ page, context, site }) => {
  let mode = 'timeout';
  await context.route('**/consumer/editor-test-worker.js', route => route.fulfill({ contentType: 'text/javascript', body: mode === 'timeout' ? 'self.onmessage = () => {}' : mode === 'error' ? `self.onmessage=e=>self.postMessage({request:e.data,error:{code:'syntax',message:'<b>unfinished</b>'}})` : mode === 'malformed' ? `self.onmessage=e=>self.postMessage({request:e.data,output:42})` : mode === 'protocol' ? `self.onmessage=e=>self.postMessage({request:{...e.data,contract_version:2},output:{text:'wrong'}})` : whitespaceWorker }));
  await openEditor(page, site); await makeEditor(page, site.base, 'plain', { formatTimeout: 250 });
  await page.evaluate(async () => (window as any).testEditor.format());
  await expect(page.locator('#test-editor [role=status]')).toContainText('time limit exceeded');
  for (const next of ['error','malformed','protocol']) {
    mode = next; await page.evaluate(async () => (window as any).testEditor.format());
    await expect(page.locator('#test-editor [role=status]')).toContainText(next === 'error' ? '<b>unfinished</b>' : next === 'malformed' ? 'malformed' : 'protocol');
    expect(await page.evaluate(() => (window as any).testEditor.getDocument('a').text)).toBe('alpha  ');
    expect(await page.evaluate(() => (window as any).testEditor.undo('a'))).toBe(false);
  }
  mode = 'success';
  await page.evaluate(() => { const e = (window as any).testEditor; (window as any).formatting = e.format(); e.replaceDocuments([{id:'a',name:'a.txt',text:'replacement',language:'text'}]); });
  expect(await page.evaluate(async () => await (window as any).formatting)).toBe(false);
  expect(await page.evaluate(() => (window as any).testEditor.getDocument('a').text)).toBe('replacement');
  await page.evaluate(() => { const e = (window as any).testEditor; (window as any).formatting = e.format(); e.setFormatters([{id:'test.whitespace',contract_version:1,formatter_version:'2',languages:['text'],worker:'consumer/editor-test-worker.js',assets:['consumer/editor-test-worker.js']}]); });
  expect(await page.evaluate(async () => await (window as any).formatting)).toBe(false);
  await makeEditor(page, site.base, 'plain', { formatTimeout: 2000 });
  expect(await page.evaluate(async () => (window as any).testEditor.format())).toBe(true);
  await page.evaluate(() => { const e = (window as any).testEditor; e.edit('a','  retained  '); (window as any).formatting=e.format(); e.dispose(); });
  expect(await page.evaluate(async () => await (window as any).formatting)).toBe(false);
});

test('multiple instances emit independent changes, preserve text while switching adapters, and fit 360px', async ({ page, context, site }) => {
  await context.route('**/consumer/editor-test-worker.js', route => route.fulfill({ contentType: 'text/javascript', body: whitespaceWorker }));
  await page.setViewportSize({ width: 360, height: 800 }); await openEditor(page, site);
  await makeEditor(page, site.base, 'plain');
  await page.locator('#test-editor textarea').fill('user text');
  expect(await page.evaluate(() => (window as any).editorEvents.length)).toBe(1);
  await page.evaluate(async () => { const e = (window as any).testEditor; e.setSelection('a',{anchor:2,head:4}); await e.setAdapter('rich'); });
  expect(await page.evaluate(() => (window as any).testEditor.getSelection('a'))).toEqual({ anchor: 2, head: 4 });
  expect(await page.evaluate(() => (window as any).editorEvents.length)).toBe(1);
  await page.evaluate(() => (window as any).testEditor.undo());
  expect(await page.evaluate(() => (window as any).testEditor.getDocument('a').text)).toBe('alpha  ');
  expect(await page.locator('[data-telescope-editor]').evaluate((el: any) => el.telescopeEditor.getDocument('notes').text)).toBe('first  \nsecond\t');
  expect(await page.evaluate(() => document.documentElement.scrollWidth)).toBeLessThanOrEqual(360);
});

test('invalid formatter bindings fail before mount and unrelated pages fetch no editor assets', async ({ page, site }) => {
  const requests: string[] = []; page.on('request', request => requests.push(request.url()));
  await page.goto(site.registered + site.base + 'workbench/');
  expect(requests.filter(url => /assets\/editor\//.test(url))).toEqual([]);
  await page.goto(site.registered + site.base + 'editor/');
  await expect(page.locator('.cm-editor')).toBeVisible();
  const errors = await page.evaluate(async base => {
    const { validateEditorConfig } = await import(base + 'assets/editor/editor.js');
    return validateEditorConfig({documents:[{id:'a',name:'a.mbt',language:'moonbit',text:''}],formatters:[],languages:{moonbit:{provider:'missing',options:{}}}});
  }, site.base);
  expect(errors).toContain('unknown formatter missing');
});

const declaredEditor = { id: 'sample.custom', contract_version: 1, kind: 'editor', module: 'consumer/custom-editor.js', languages: ['text'], assets: ['consumer/custom-editor.js'] };
const declaredLanguage = { id: 'sample.language', contract_version: 1, kind: 'language', module: 'consumer/custom-language.js', languages: ['text-demo'], assets: ['consumer/custom-language.js'] };

test('declared standalone editor loads only its selected module and shares formatting history', async ({ page, site }) => {
  const requests: string[] = []; page.on('request', r => requests.push(r.url()));
  await openEditor(page, site);
  await makeEditor(page, site.base, 'sample.custom', { editors: [declaredEditor, declaredLanguage],
    formatters: [{ id: 'sample.whitespace', contract_version: 1, formatter_version: '1', languages: ['text'], worker: 'consumer/editor-whitespace-worker.js', assets: ['consumer/editor-whitespace-worker.js'] }],
    languages: { text: { provider: 'sample.whitespace', options: {} } } });
  const host = page.locator('#test-editor'), input = host.locator('.custom-text-editor');
  await expect(input).toHaveValue('alpha  ');
  expect(requests.filter(url => url.endsWith('/consumer/custom-editor.js'))).toHaveLength(1);
  expect(requests.filter(url => url.endsWith('/consumer/custom-language.js'))).toHaveLength(0);
  await input.fill('consumer text  ');
  expect(await page.evaluate(() => (window as any).editorEvents.length)).toBe(1);
  await host.getByRole('button', { name: 'Format', exact: true }).click();
  await expect(input).toHaveValue('consumer text');
  await input.focus(); await page.keyboard.press('ControlOrMeta+z');
  await expect(input).toHaveValue('consumer text  ');
  await page.evaluate(async () => { const e = (window as any).testEditor; await e.setAdapter('plain'); await e.setAdapter('sample.custom'); e.selectDocument('b'); e.edit('b', 'other'); e.undo(); e.selectDocument('a'); });
  await expect(host.locator('.custom-text-editor')).toHaveValue('consumer text  ');
  expect(requests.filter(url => url.endsWith('/consumer/custom-editor.js'))).toHaveLength(1);
});

test('declared rich language uses injected CodeMirror and switches without changing text history or events', async ({ page, site }) => {
  const requests: string[] = []; page.on('request', r => requests.push(r.url()));
  await openEditor(page, site);
  await makeEditor(page, site.base, 'rich', { editors: [declaredEditor, declaredLanguage],
    documents: [{ id: 'a', name: 'a.demo', language: 'text-demo', text: 'demo answer = 42\n' }] });
  const host = page.locator('#test-editor');
  await expect(host.locator('.te-token-keyword')).toHaveText('demo');
  await expect(host.locator('.te-token-number')).toHaveText('42');
  expect(requests.filter(url => url.endsWith('/consumer/custom-language.js'))).toHaveLength(1);
  expect(requests.filter(url => url.endsWith('/consumer/custom-editor.js'))).toHaveLength(0);
  await page.evaluate(async () => { const e = (window as any).testEditor; e.edit('a', 'demo changed = 42\n'); e.setSelection('a', {anchor:2,head:5}); await e.setLanguage('a', 'text'); });
  await expect(host.locator('.te-token-keyword')).toHaveCount(0);
  await page.evaluate(async () => (window as any).testEditor.setLanguage('a', 'text-demo'));
  await expect(host.locator('.te-token-keyword')).toHaveText('demo');
  expect(await page.evaluate(() => (window as any).testEditor.getSelection('a'))).toEqual({anchor:2,head:5});
  expect(await page.evaluate(() => (window as any).editorEvents.length)).toBe(1);
  await page.evaluate(() => (window as any).testEditor.undo());
  expect(await page.evaluate(() => (window as any).testEditor.getDocument('a').text)).toBe('demo answer = 42\n');
  expect(requests.filter(url => url.endsWith('/consumer/custom-language.js'))).toHaveLength(1);
});

test('explicit registered MoonBit replacement applies to both aliases without replacing documents', async ({ page, site }) => {
  await openEditor(page, site);
  await makeEditor(page, site.base, 'rich', {
    editors: [{ id: 'replacement', contract_version: 1, kind: 'language', module: 'consumer/moonbit-language.js', languages: ['moonbit', 'mbt'], assets: ['consumer/moonbit-language.js'] }],
    documents: [{ id: 'a', name: 'a.mbt', language: 'moonbit', text: 'custom pub fn answer()' }],
  });
  const host = page.locator('#test-editor');
  await expect(host.locator('.te-token-keyword')).toHaveText('custom');
  await page.evaluate(async () => { const e = (window as any).testEditor; e.setSelection('a', {anchor:3,head:7}); await e.setLanguage('a','mbt'); });
  await expect(host.locator('.te-token-keyword')).toHaveText('custom');
  expect(await page.evaluate(() => (window as any).testEditor.getDocument('a').text)).toBe('custom pub fn answer()');
  expect(await page.evaluate(() => (window as any).testEditor.getSelection('a'))).toEqual({anchor:3,head:7});
  expect(await page.evaluate(() => (window as any).editorEvents.length)).toBe(0);
});

test('unknown prototype-shaped languages remain editable without fabricated mode or Format action', async ({ page, site }) => {
  await openEditor(page, site);
  for (const language of ['constructor','__proto__']) {
    await makeEditor(page,site.base,'rich',{documents:[{id:'a',name:'a.any',language,text:'readable source'}],formatters:[],languages:{},languageAdapters:{other:[]}});
    const host=page.locator('#test-editor');
    await expect(host.getByRole('button',{name:'Format',exact:true})).toBeHidden();
    await expect(host.locator('.cm-content')).toHaveText('readable source');
    expect(await page.evaluate(async ()=>(window as any).testEditor.format())).toBe(false);
    await page.evaluate(()=>(window as any).testEditor.edit('a','still editable'));
    expect(await page.evaluate(()=>(window as any).testEditor.getDocument('a').text)).toBe('still editable');
  }
});
