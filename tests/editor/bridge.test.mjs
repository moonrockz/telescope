import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { runInNewContext } from 'node:vm';

// Build fixtures through scripts/build-fixtures.mbtx first. This is the real
// consumer-compiled MoonBit Formatter and public browser worker bridge.
const worker = await readFile(new URL('../../_build/fixtures/whitespace-worker.js', import.meta.url), 'utf8');
function invoke(request) {
  let reply;
  const scope = { postMessage(value) { reply = value; } };
  runInNewContext(worker, { self: scope });
  scope.onmessage({ data: request });
  return JSON.parse(JSON.stringify(reply));
}

test('compiled standalone Formatter preserves the envelope and formats only target text', () => {
  const request = { contract_version: 1, instance: 'standalone', formatter: 'whitespace', formatter_version: '1', generation: 3, request_id: 7, target: 'a', revisions: [{id:'a',revision:4}], input: { target: { id: 'a', name: 'a.txt', language: 'text', text: 'first  \nsecond\t' }, context: [], options: {} } };
  const reply = invoke(request);
  assert.deepEqual(reply.request, request);
  assert.equal(reply.output.text, 'first\nsecond');
  assert.equal(request.input.target.text, 'first  \nsecond\t');
});

test('compiled bridge reports invalid inputs and unsupported contract honestly', () => {
  assert.equal(invoke({contract_version: 2,input:{}}).error.code, 'protocol');
  assert.equal(invoke({contract_version: 1,input:{}}).error.code, 'protocol');
});
