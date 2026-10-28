import test from 'node:test';
import assert from 'node:assert/strict';
import { validateEditorConfig, installFormatterWorker } from '../../pkgs/telescope/editor/browser/editor.js';
const formatter = { id:'trim',contract_version:1,formatter_version:'1',languages:['text'],worker:'trim.js',assets:['trim.js'] };
const config = { documents:[{id:'a',name:'dir/a.txt',language:'text',text:'a'}],formatters:[formatter],languages:{text:{provider:'trim',options:{}}} };

test('explicit binding validation rejects unknown providers languages versions and assets', () => {
  assert.deepEqual(validateEditorConfig(config), []);
  for (const f of [{...formatter,contract_version:2},{...formatter,assets:[]},{...formatter,worker:'../escape.js'},{...formatter,worker:'x/%2e%2e/escape.js',assets:['x/%2e%2e/escape.js']}]) assert.ok(validateEditorConfig({...config,formatters:[f]}).length);
  assert.ok(validateEditorConfig({...config,formatters:[formatter,formatter]}).length);
  assert.ok(validateEditorConfig({...config,languages:{text:{provider:'missing',options:{}}}}).includes('unknown formatter missing'));
  assert.ok(validateEditorConfig({...config,documents:[{...config.documents[0],language:'mbt',formatter:{provider:'trim',options:{}}}]}).some(e=>e.includes('does not support mbt')));
  assert.ok(validateEditorConfig({...config,documents:[{...config.documents[0],name:'../a.txt'}]}).length);
});

test('general JS worker bridge returns literal failures and rejects asynchronous callbacks', () => {
  let reply;
  const scope = {postMessage(value){reply=value;}};
  const request = {input:{target:{text:' a '}}};
  installFormatterWorker(input => ({text:input.target.text.trim()}),scope);
  scope.onmessage({data:request}); assert.deepEqual(reply,{request,output:{text:'a'}});
  installFormatterWorker(() => {throw new Error('<script>literal</script>');},scope);
  scope.onmessage({data:request}); assert.equal(reply.error.message,'<script>literal</script>');
  installFormatterWorker(() => Promise.resolve({text:'wrong'}),scope);
  scope.onmessage({data:request}); assert.match(reply.error.message,/synchronous/);
});

const customEditor = {id:'sample.custom',contract_version:1,kind:'editor',module:'consumer/custom-editor.js',languages:['text'],assets:['consumer/custom-editor.js']};
const customLanguage = {id:'sample.language',contract_version:1,kind:'language',module:'consumer/custom-language.js',languages:['text-demo'],assets:['consumer/custom-language.js']};
test('declarative editor and language registrations validate selection capabilities and containment', () => {
  assert.deepEqual(validateEditorConfig({...config,adapter:'sample.custom',editors:[customEditor,customLanguage]}),[]);
  for (const registration of [{...customEditor,contract_version:2},{...customEditor,kind:'unknown'},{...customEditor,module:'../escape.js'},{...customEditor,assets:[]},{...customEditor,languages:[]},{...customEditor,languages:['text','text']}]) {
    assert.ok(validateEditorConfig({...config,editors:[registration]}).length);
  }
  assert.ok(validateEditorConfig({...config,adapter:'missing',editors:[customEditor]}).includes('unknown editor adapter missing'));
  assert.ok(validateEditorConfig({...config,adapter:'sample.custom',documents:[{id:'a',name:'a.mbt',language:'moonbit',text:''}],editors:[customEditor]}).includes('editor sample.custom does not support moonbit'));
  assert.ok(validateEditorConfig({...config,editors:[customLanguage,{...customLanguage,id:'duplicate'}]}).includes('duplicate language registration for text-demo'));
  assert.deepEqual(validateEditorConfig({...config,adapter:'compiled',adapters:{compiled(){}}}),[]);
  assert.deepEqual(validateEditorConfig({...config,editors:[{...customLanguage,languages:['moonbit']}]}),[]);
});

test('unknown direct adapter IDs do not resolve prototype functions', () => {
  for (const adapter of ['constructor','__proto__','toString']) assert.ok(validateEditorConfig({...config,adapter,adapters:{}}).includes(`unknown editor adapter ${adapter}`));
});
