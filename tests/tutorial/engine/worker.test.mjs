// The actual compiled worker and native process consume the same standard JSON.
import { readFile } from 'node:fs/promises';
import { runInNewContext } from 'node:vm';
import { spawnSync } from 'node:child_process';
import assert from 'node:assert/strict';

const [workerPath, executable] = process.argv.slice(2);
assert(workerPath && executable, 'usage: worker.test.mjs WORKER_BUNDLE NATIVE_ENGINE');
const source = await readFile(workerPath, 'utf8');
const canonical = value => Array.isArray(value) ? `[${value.map(canonical).join(',')}]` : value && typeof value === 'object'
  ? `{${Object.keys(value).sort().map(key => `${JSON.stringify(key)}:${canonical(value[key])}`).join(',')}}` : JSON.stringify(value);
const base = {contract_version:1,provider:'sample.text',engine_version:'1.0.0',generation:2,request_id:3,
  input_revision:'revision',operation:'evaluate',files:[{name:'input.txt',text:'hello\nERROR second\n',language:'text',group:''}],options:{},session:null,position:null};
const cases = [base,{...base,operation:'start'},{...base,operation:'step',session:'text:1',position:2},
  {...base,options:{uppercase:true,lowercase:true}}, {...base,operation:'run-all'}];
for (const request of cases) {
  let reply;
  const self = {postMessage:value => {reply=JSON.parse(JSON.stringify(value));}};
  runInNewContext(source,{self,console,TextDecoder,TextEncoder},{timeout:1000});
  assert.equal(typeof self.onmessage,'function');
  self.onmessage({data:request});
  const native = spawnSync(executable,[],{input:JSON.stringify(request),encoding:'utf8',timeout:5000});
  assert.equal(native.status,0,native.stderr);
  assert.deepEqual(reply,JSON.parse(native.stdout));
  assert.equal(Array.isArray(reply.blocked),false);
  assert.equal(Array.isArray(reply.steps),false);
  assert.equal(Array.isArray(reply.verdict),false);
  for(const diagnostic of reply.diagnostics) {
    assert.equal(Array.isArray(diagnostic.file),false);
    assert.equal(Array.isArray(diagnostic.line),false);
  }
  if(reply.steps) assert.equal(typeof reply.steps.summary,'string');
}
const absent = {...base}; delete absent.session; delete absent.position;
const absentResult = spawnSync(executable,[],{input:JSON.stringify(absent),encoding:'utf8',timeout:5000});
assert.equal(absentResult.status,0,absentResult.stderr);
const options = {z:1,aa:2,'😀':'unicode','\uE000':false,number:1.0};
const request = {...base,options};
const nativeRevision = spawnSync(executable,['--input-revision'],{input:JSON.stringify(request),encoding:'utf8',timeout:5000});
assert.equal(nativeRevision.status,0,nativeRevision.stderr);
const jsRevision = canonical({schema_version:1,provider:request.provider,engine_version:request.engine_version,
  contract_version:request.contract_version,operation:request.operation,options:request.options,files:request.files});
assert.equal(nativeRevision.stdout,jsRevision,'native/browser canonical input revision differs');
console.log('Compiled worker/native standard JSON parity and input revisions passed.');
