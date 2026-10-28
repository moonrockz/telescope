// Browser tooling drives an installed artifact; it does not resolve consumer libraries.
import { chromium } from '../../browser/node_modules/playwright/index.mjs';
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { resolve, extname } from 'node:path';
import assert from 'node:assert/strict';

const [output, base] = process.argv.slice(2);
assert(output && base);
const root = resolve(output);
const requests = [];
const server = createServer(async (request, response) => {
  const pathname = new URL(request.url, 'http://localhost').pathname;
  requests.push(pathname);
  if (!pathname.startsWith(base)) { response.writeHead(404).end(); return; }
  let relative = pathname.slice(base.length);
  if (!relative || relative.endsWith('/')) relative += 'index.html';
  const path = resolve(root, relative);
  if (!path.startsWith(root + '/')) { response.writeHead(404).end(); return; }
  try {
    const bytes = await readFile(path);
    response.setHeader('Content-Type', ({'.html':'text/html','.js':'text/javascript','.css':'text/css','.json':'application/json'})[extname(path)] ?? 'application/octet-stream');
    response.end(bytes);
  } catch { response.writeHead(404).end(); }
});
await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
const address = `http://127.0.0.1:${server.address().port}${base}`;
let browser;
try {
  browser = await chromium.launch({headless:true,args:['--no-sandbox']});
  const page = await browser.newPage({viewport:{width:360,height:780}});
  await page.goto(address + 'learn/reading/');
  await page.getByRole('heading', {name:'Read first',exact:true}).waitFor();
  assert.equal(requests.some(path => /editor|text-worker|tutorial\/workspace\.js/.test(path)), false);
  await page.goto(address + 'learn/editing/');
  const input = page.locator('textarea').first();
  await input.waitFor();
  await input.fill('PACKAGED current revision  ');
  await page.waitForFunction(() => [...document.querySelectorAll('pre')].some(pre => pre.textContent.includes('PACKAGED current revision')));
  await page.getByRole('button', {name:'Format',exact:true}).click();
  await page.waitForFunction(() => document.querySelector('textarea')?.value === 'PACKAGED current revision');
  await input.focus();
  await page.keyboard.press('ControlOrMeta+z');
  assert.equal(await input.inputValue(), 'PACKAGED current revision  ');
  assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), true);
  assert.equal(requests.some(path => /custom-editor\.js|custom-language\.js/.test(path)), false);
  await page.goto(address + 'learn/custom-editor/');
  const customInput = page.locator('textarea').first();
  await customInput.waitFor();
  await customInput.fill('PACKAGED custom adapter');
  await page.waitForFunction(() => [...document.querySelectorAll('pre')].some(pre => pre.textContent.includes('PACKAGED custom adapter')));
  assert.equal(requests.some(path => path.includes('editor-sample.custom/assets/custom-editor.js')), true);
  await page.goto(address + 'learn/custom-language/');
  await page.locator('.cm-editor').waitFor();
  await page.locator('.te-token-keyword').filter({hasText:'demo'}).first().waitFor();
  assert.equal(requests.some(path => path.includes('editor-sample.language/assets/custom-language.js')), true);
  // The ordinary landing page mounts the general editor directly. No lesson,
  // course, storage key or evaluator enters this component configuration.
  await page.goto(address);
  await page.evaluate(async base => {
    const {mountEditor} = await import(base + 'assets/editor/editor.js');
    const host = document.createElement('div'); document.querySelector('main').append(host);
    window.packagedEditor = await mountEditor(host, {
      id:'packaged-standalone', adapter:'rich', assetBase:base,
      documents:[{id:'main',name:'main.mbt',language:'moonbit',text:'let answer = 42\n'},
        {id:'notes',name:'notes.txt',language:'text',text:'standalone  '}],
      formatters:[{id:'sample.whitespace',contract_version:1,formatter_version:'1.0.0',languages:['text'],
        worker:'assets/tutorial/formatter-sample.whitespace/assets/whitespace-worker.js',
        assets:['assets/tutorial/formatter-sample.whitespace/assets/whitespace-worker.js']}],
      languages:{text:{provider:'sample.whitespace',options:{}}},
    });
  }, base);
  await page.locator('.te-token-keyword').first().waitFor();
  await page.evaluate(() => window.packagedEditor.selectDocument('notes'));
  await page.getByRole('button', {name:'Format',exact:true}).click();
  await page.waitForFunction(() => window.packagedEditor.getDocument('notes').text === 'standalone');
  await page.evaluate(() => window.packagedEditor.undo());
  assert.equal(await page.evaluate(() => window.packagedEditor.getDocument('notes').text), 'standalone  ');
  await page.evaluate(() => window.packagedEditor.dispose());
  await browser.close(); browser = undefined;
  console.log(JSON.stringify({packaged_browser_edit:true,base,static_editor_assets_absent:true}));
} finally {
  if (browser) await browser.close();
  await new Promise(resolve => server.close(resolve));
}
