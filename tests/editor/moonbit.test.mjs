import test from 'node:test';
import assert from 'node:assert/strict';
import { StringStream } from '../../pkgs/telescope/editor/browser/node_modules/@codemirror/language/dist/index.js';
import { languageExtension } from '../../pkgs/telescope/editor/browser/rich.js';
import { moonbitParser } from '../../pkgs/telescope/editor/browser/moonbit.js';

function tokenize(text) {
  const state = moonbitParser.startState(), tokens = [];
  for (const line of text.split('\n')) {
    const stream = new StringStream(line, 4, 2);
    while (!stream.eol()) {
      stream.start = stream.pos;
      const type = moonbitParser.token(stream, state);
      assert.ok(stream.pos > stream.start, 'every token advances');
      tokens.push([stream.current(), type]);
    }
  }
  return tokens;
}

test('MoonBit declarations literals comments annotations and qualified names', () => {
  const code = '/// docs\n#deprecated\npub fn f() -> Int { let x = 0xff; let s = "a\\"b"; let c = \'x\'; @json.parse(s) }\n#|multi line';
  const tokens = tokenize(code);
  for (const expected of [['/// docs','docComment'], ['#deprecated','meta'], ['pub','keyword'],['fn','keyword'],['Int','typeName'],['0xff','number'],['"a\\"b"','string'],["'x'",'string'],['@json','namespace'],['#|multi line','string']]) assert.ok(tokens.some(token => token[0] === expected[0] && token[1] === expected[1]), JSON.stringify(expected));
});

test('incomplete source completes without retaining stale quote highlighting', () => {
  assert.deepEqual(tokenize('let s = "incomplete').at(-1), ['"incomplete','string']);
  const completed = tokenize('let s = "complete"\nlet next = 42');
  assert.ok(completed.some(token => token[0] === 'next' && token[1] === 'variableName'));
  assert.deepEqual(completed.at(-1), ['42','number']);
});

test('nested block comments and source-preserving token text', () => {
  const code = '/* first\n/* nested */ end */\ntrait T { fn f(Self) -> Unit }';
  const tokens = tokenize(code);
  assert.equal(tokens.map(token => token[0]).join(''), code.replaceAll('\n',''));
  assert.ok(tokens.some(token => token[0] === 'trait' && token[1] === 'keyword'));
  assert.equal(tokenize('let x = 1_024.5e-2').at(-1)[1], 'number');
});

test('unknown language IDs never select inherited object entries', () => {
  const adapters = { custom: [] };
  for (const language of ['constructor','__proto__','toString']) assert.deepEqual(languageExtension(language,adapters),[]);
  assert.equal(languageExtension('custom',adapters),adapters.custom);
  assert.equal(languageExtension('moonbit',adapters),languageExtension('mbt',adapters));
});
