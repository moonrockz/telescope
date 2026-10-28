import { test, expect } from './fixtures.js';
import type { Page } from '@playwright/test';

async function workspace(page: Page, site: {registered:string;base:string}, lesson='editing') {
  await page.goto(site.registered + site.base + `learn/${lesson}/`);
  const mount=page.locator('[data-tutorial-workspace]');
  await expect(mount.locator('.telescope-editor')).toBeVisible();
  await expect(mount).toHaveAttribute('data-state','success');
  return mount;
}

test('static lessons include exact tested source, navigation and search without editor requests', async ({page,site})=>{
  const requests:string[]=[];page.on('request',r=>requests.push(r.url()));
  await page.goto(site.registered + site.base + 'learn/reading/');
  await expect(page.getByText("printf 'A tested command\\n'",{exact:false})).toBeVisible();
  await expect(page.locator('.tutorial-code-group details')).toHaveCount(2);
  await expect(page.locator('.tutorial-contents [aria-current="page"]')).toHaveText('Read first');
  await expect(page.getByRole('link',{name:'Next: Edit text'})).toHaveAttribute('href',site.base+'learn/editing/');
  expect(requests.filter(url=>/assets\/(editor|tutorial)\/.+\.js/.test(url))).toEqual([]);
  const response=await page.request.get(site.registered+site.base+'search-index.json');
  const text=await response.text();expect(text).toContain('A tested command');expect(text).not.toContain('diagnostic_keys');
});

test('tutorial remains readable without scripts with starting downloads and literal source',async ({browser,site})=>{
  const context=await browser.newContext({javaScriptEnabled:false});const page=await context.newPage();
  try {
    await page.goto(site.registered+site.base+'learn/editing/');
    await expect(page.locator('noscript p')).toBeVisible();
    await expect(page.getByRole('link',{name:'Download input.txt'})).toHaveAttribute('href',site.base+'assets/tutorial/files/basics/editing/input.txt');
    await expect(page.locator('.tutorial-starting code').first()).toContainText('<script>globalThis.lessonInjected=true</script>');
    await expect(page.getByRole('button',{name:'Reset',exact:true})).toHaveCount(0);
    await page.goto(site.registered+site.base+'learn/reading/');
    await expect(page.locator('.tutorial-code-group details')).toHaveCount(2);
    await page.locator('.tutorial-code-group summary').first().focus();await page.keyboard.press('Enter');
    await expect(page.locator('.tutorial-code-group details').first()).not.toHaveAttribute('open','');
  } finally { await context.close(); }
});

test('tutorial shared editor formats persists resets and rechecks through ordinary changes',async ({page,site})=>{
  const mount=await workspace(page,site);
  await expect(mount.locator('.tutorial-results pre')).toContainText('<script>globalThis.lessonInjected=true</script>');
  expect(await page.evaluate(()=>(globalThis as any).lessonInjected)).toBeUndefined();
  await mount.evaluate((el:any)=>el.telescopeEditor.edit('input.txt',' changed  '));
  await expect(mount).toHaveAttribute('data-state','success');
  await expect(mount.locator('.tutorial-results pre')).toContainText(' changed  ');
  await mount.getByRole('button',{name:'Format',exact:true}).click();
  await expect(mount.locator('.te-status')).toHaveText('Formatted.');
  await expect(mount).toHaveAttribute('data-state','success');
  expect(await mount.evaluate((el:any)=>el.telescopeEditor.getDocument('input.txt').text)).toBe(' changed');
  await mount.evaluate((el:any)=>el.telescopeEditor.undo('input.txt'));
  await expect(mount).toHaveAttribute('data-state','success');
  expect(await mount.evaluate((el:any)=>el.telescopeEditor.getDocument('input.txt').text)).toBe(' changed  ');
  await page.reload();await expect(mount.locator('.telescope-editor')).toBeVisible();
  expect(await mount.evaluate((el:any)=>el.telescopeEditor.getDocument('input.txt').text)).toBe(' changed  ');
  await mount.getByRole('button',{name:'Expand output',exact:true}).click();
  await mount.getByRole('button',{name:'Reset',exact:true}).click();
  await expect(mount.getByRole('button',{name:'Restore split view',exact:true})).toHaveAttribute('aria-expanded','true');
  expect(await mount.evaluate((el:any)=>el.telescopeEditor.getDocument('input.txt').text)).toContain('Hello <script>');
  await mount.evaluate((el:any)=>el.telescopeEditor.undo('input.txt'));
  expect(await mount.evaluate((el:any)=>el.telescopeEditor.getDocument('input.txt').text)).toContain('Hello <script>');
});

test('tutorial rich MoonBit mode shares aliases state themes and narrow layout',async ({page,site})=>{
  await page.setViewportSize({width:360,height:800});const mount=await workspace(page,site,'moonbit');
  for(const theme of ['light','dark']) {
    await page.evaluate(theme=>{document.documentElement.dataset.theme=theme;},theme);
    await expect(mount.locator('.te-token-keyword').first()).toBeVisible();
    await expect(mount.getByRole('button',{name:'Format',exact:true})).toBeHidden();
    expect(await page.evaluate(()=>document.documentElement.scrollWidth)).toBeLessThanOrEqual(360);
  }
  await mount.evaluate((el:any)=>{const e=el.telescopeEditor;e.edit('main.mbt','let value = "unfinished');e.setSelection('main.mbt',{anchor:4,head:9});e.selectDocument('second.mbt');});
  await expect(mount.locator('.te-token-string').first()).toBeVisible();
  await mount.evaluate((el:any)=>el.telescopeEditor.selectDocument('main.mbt'));
  expect(await mount.evaluate((el:any)=>el.telescopeEditor.getSelection('main.mbt'))).toEqual({anchor:4,head:9});
  await mount.evaluate((el:any)=>el.telescopeEditor.undo('main.mbt'));
  expect(await mount.evaluate((el:any)=>el.telescopeEditor.getDocument('main.mbt').text)).toContain('pub fn answer');
});

test('comparison groups have isolated histories; workbench unsupported state preserves every file',async ({page,site})=>{
  const mount=await workspace(page,site,'comparison');
  await mount.getByLabel('Output',{exact:true}).selectOption('comparison');await expect(mount.locator('.tutorial-results pre')).toContainText('changed');
  await mount.evaluate((el:any)=>{const e=el.telescopeEditor;e.edit('old/input.txt','Old edited');e.selectDocument('new/input.txt');e.edit('new/input.txt','New edited');e.undo();});
  expect(await mount.evaluate((el:any)=>el.telescopeEditor.getDocument('old/input.txt').text)).toBe('Old edited');
  expect(await mount.evaluate((el:any)=>el.telescopeEditor.getDocument('new/input.txt').text)).toBe('New text\n');
  await mount.getByRole('button',{name:'Open in workbench'}).click();
  await expect(mount.getByRole('status').first()).toContainText('exactly one file');
  expect(page.url()).toContain('learn/comparison/');
});

test('step requests replay requested position after edits and Run all completes',async ({page,site})=>{
  const mount=await workspace(page,site,'steps');
  await mount.getByRole('button',{name:'Step',exact:true}).click();await expect(mount.locator('[aria-label="Steps"]')).toContainText('1 steps checked');
  await mount.getByRole('button',{name:'Step',exact:true}).click();await expect(mount.locator('[aria-label="Steps"]')).toContainText('2 steps checked');
  await mount.evaluate((el:any)=>el.telescopeEditor.edit('input.txt','short\n'));
  await expect(mount).toHaveAttribute('data-state','success');await expect(mount.locator('[aria-label="Steps"]')).toContainText('1 steps checked, complete');
  await mount.getByRole('button',{name:'Reset',exact:true}).click();await expect(mount).toHaveAttribute('data-state','success');
  await mount.getByRole('button',{name:'Run all',exact:true}).click();await expect(mount.locator('[aria-label="Steps"]')).toContainText('3 steps checked, complete');
});

test('stalled runtime retries once and preserves readable editable files',async ({page,site})=>{
  await page.clock.install();let workers=0;
  await page.route('**/assets/tutorial/sample.text/assets/text-worker.js',route=>{workers++;return route.fulfill({contentType:'text/javascript',body:'self.onmessage = () => {};'});});
  await page.goto(site.registered+site.base+'learn/editing/');const mount=page.locator('[data-tutorial-workspace]');
  await expect(mount.locator('.telescope-editor')).toBeVisible();
  await page.clock.runFor(10020);await expect.poll(()=>workers).toBe(2);
  await page.clock.runFor(10020);await expect(mount).toHaveAttribute('data-state','timeout');
  await mount.evaluate((el:any)=>el.telescopeEditor.edit('input.txt','still editable'));expect(await mount.evaluate((el:any)=>el.telescopeEditor.getDocument('input.txt').text)).toBe('still editable');
});

test('older tutorial tree keeps its own search links navigation and persistence base',async ({page,site})=>{
  const base=site.base+'v/0.1/';
  await page.goto(site.versions+base+'learn/reading/');
  await expect(page.locator('.tutorial-contents [aria-current="page"]')).toHaveText('Read first');
  await expect(page.getByRole('link',{name:'Next: Edit text'})).toHaveAttribute('href',base+'learn/editing/');
  const response=await page.request.get(site.versions+base+'search-index.json');
  expect(await response.text()).toContain('Tutorial static reading');
  await page.goto(site.versions+base+'learn/editing/');const mount=page.locator('[data-tutorial-workspace]');
  await expect(mount).toHaveAttribute('data-state','success');
  await mount.evaluate((el:any)=>el.telescopeEditor.edit('input.txt','old version only'));
  await page.goto(site.versions+site.base+'v/0.2/learn/editing/');await expect(mount).toHaveAttribute('data-state','success');
  expect(await mount.evaluate((el:any)=>el.telescopeEditor.getDocument('input.txt').text)).toContain('Hello <script>');
});

test('denied browser storage leaves editing and Reset usable',async ({page,site})=>{
  await page.addInitScript(()=>{Storage.prototype.getItem=function(){throw Error('denied');};Storage.prototype.setItem=function(){throw Error('denied');};Storage.prototype.removeItem=function(){throw Error('denied');};});
  const mount=await workspace(page,site);await mount.evaluate((el:any)=>el.telescopeEditor.edit('input.txt','in memory'));
  await expect(mount).toHaveAttribute('data-state','success');
  await mount.getByRole('button',{name:'Reset',exact:true}).click();
  expect(await mount.evaluate((el:any)=>el.telescopeEditor.getDocument('input.txt').text)).toContain('Hello <script>');
});

test('tutorial composes consumer editor and language registrations with route-local assets',async ({page,site})=>{
  const requests:string[]=[];page.on('request',r=>requests.push(r.url()));
  let mount=await workspace(page,site,'custom-editor');
  await expect(mount.locator('.custom-text-editor')).toBeVisible();
  await mount.evaluate((el:any)=>el.telescopeEditor.edit('input.txt','custom editor change'));
  await expect(mount).toHaveAttribute('data-state','success');await expect(mount.locator('.tutorial-results pre')).toContainText('custom editor change');
  expect(requests.some(url=>url.includes('editor-sample.custom/assets/custom-editor.js'))).toBe(true);
  expect(requests.some(url=>url.includes('editor-sample.language/assets/custom-language.js'))).toBe(false);
  requests.length=0;mount=await workspace(page,site,'custom-language');
  await expect(mount.locator('.te-token-keyword')).toHaveText('demo');
  expect(requests.some(url=>url.includes('editor-sample.language/assets/custom-language.js'))).toBe(true);
  expect(requests.some(url=>url.includes('editor-sample.custom/assets/custom-editor.js'))).toBe(false);
});

test('shared course navigation remains present on API and gallery pages',async ({page,site})=>{
  for(const path of ['api/','api/qualification/observatory-api/','gallery/','gallery/signal/']) {
    await page.goto(site.registered+site.base+path);
    await expect(page.getByRole('navigation',{name:'Main',exact:true}).getByRole('link',{name:'Text lessons'})).toHaveAttribute('href',site.base+'learn/');
  }
});

test('unchanged formatting makes no tutorial storage write or execution request in either adapter',async ({page,site})=>{
  const mount=await workspace(page,site);
  await mount.evaluate((el:any)=>el.telescopeEditor.edit('input.txt','already formatted\n'));
  await expect(mount).toHaveAttribute('data-state','success');
  await page.clock.install();
  await page.evaluate(()=>{
    const counters=(window as any).formatCounters={storage:0,execution:0,changes:0};
    const write=Storage.prototype.setItem;
    Storage.prototype.setItem=function(key,value){if(key.startsWith('telescope:tutorial:'))counters.storage++;return write.call(this,key,value);};
    const post=Worker.prototype.postMessage;
    Worker.prototype.postMessage=function(message:any,...args:any[]){if(message?.provider==='sample.text')counters.execution++;return (post as any).call(this,message,...args);};
    document.querySelector('[data-tutorial-workspace]')!.addEventListener('editor-change',()=>counters.changes++,true);
  });
  for(const adapter of ['plain','rich']) {
    await mount.evaluate(async(el:any,adapter)=>el.telescopeEditor.setAdapter(adapter),adapter);
    await mount.getByRole('button',{name:'Format',exact:true}).click();
    await expect(mount.locator('.te-status')).toHaveText('Already formatted.');
    await page.clock.runFor(500);
    expect(await page.evaluate(()=>(window as any).formatCounters)).toEqual({storage:0,execution:0,changes:0});
  }
});

test('tutorial Reset invalidates a pending shared-editor formatting reply',async ({page,site})=>{
  await page.route('**/assets/tutorial/formatter-sample.whitespace/assets/whitespace-worker.js',route=>route.fulfill({contentType:'text/javascript',body:`self.onmessage=e=>{const request=e.data;setTimeout(()=>self.postMessage({request,output:{text:'stale formatted text'}}),5000);};`}));
  const mount=await workspace(page,site);
  await mount.evaluate((el:any)=>el.telescopeEditor.edit('input.txt','edited before format  '));
  await mount.getByRole('button',{name:'Format',exact:true}).click();
  await expect(mount.locator('.te-status')).toHaveText('Formatting…');
  await mount.getByRole('button',{name:'Reset',exact:true}).click();
  await expect(mount).toHaveAttribute('data-state','success');
  expect(await mount.evaluate((el:any)=>el.telescopeEditor.getDocument('input.txt').text)).toContain('Hello <script>');
  expect(await mount.evaluate((el:any)=>el.telescopeEditor.getDocument('input.txt').text)).not.toContain('stale formatted');
});

test('execution blocked and incompatible results remain literal preserve focus and recover after editing',async ({page,site})=>{
  await page.route('**/assets/tutorial/sample.text/assets/text-worker.js',route=>route.fulfill({contentType:'text/javascript',body:`self.onmessage=e=>{const q=e.data;const text=q.files[0].text;const blocked=!text.includes('recover')&&!text.includes('malformed');self.postMessage({contract_version:text.includes('malformed')?9:q.contract_version,provider:q.provider,engine_version:q.engine_version,generation:q.generation,request_id:q.request_id,input_revision:q.input_revision,status:blocked?'blocked':'success',diagnostics:blocked?[{key:'blocked',code:'BLOCKED',severity:'warning',message:'Literal <script>globalThis.blockedInjected=true</script>',file:'input.txt',line:1,column:1,end_line:null,end_column:null}]:[],outputs:blocked?[]:[{id:'text',label:'Text',language:'text',text}],blocked:blocked?'Consumer blocked <script>text</script>':null,verdict:null,steps:null});};`}));
  await page.goto(site.registered+site.base+'learn/editing/');const mount=page.locator('[data-tutorial-workspace]');
  await expect(mount).toHaveAttribute('data-state','blocked');
  await expect(mount.locator('.tutorial-results')).toContainText('Literal <script>globalThis.blockedInjected=true</script>');
  expect(await page.evaluate(()=>(globalThis as any).blockedInjected)).toBeUndefined();
  await mount.getByLabel('Code editor',{exact:true}).focus();
  await mount.evaluate((el:any)=>el.telescopeEditor.edit('input.txt','malformed current input'));
  await expect(mount).toHaveAttribute('data-state','error');
  await expect(mount.getByLabel('Code editor',{exact:true})).toBeFocused();
  expect(await mount.evaluate((el:any)=>el.telescopeEditor.getDocument('input.txt').text)).toBe('malformed current input');
  await mount.evaluate((el:any)=>el.telescopeEditor.edit('input.txt','recover current input'));
  await expect(mount).toHaveAttribute('data-state','success');
  await expect(mount.locator('.tutorial-results pre')).toHaveText('recover current input');
});
