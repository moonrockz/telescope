import {test} from 'node:test';
import assert from 'node:assert/strict';
import {executionRuntime, restoreEdits, canonical, handoffURL} from '../../pkgs/telescope/tutorial/islands/runtime.js';

function fixture({steps=false}={}) {
  let files = [{id:'input',name:'input.txt',text:'one',language:'text',group:''}];
  const workers=[], states=[], timers=new Map(); let id=0, now=0;
  const clock = {
    setTimer(fn,delay) { const key=++id; timers.set(key,{fn,at:now+delay}); return key; },
    clearTimer(key) { timers.delete(key); },
    tick(ms) { const end=now+ms; while(true) { const entry=[...timers].filter(([,t])=>t.at<=end).sort((a,b)=>a[1].at-b[1].at)[0]; if(!entry) break; timers.delete(entry[0]); now=entry[1].at;entry[1].fn(); } now=end; },
  };
  const provider={id:'sample',contract_version:1,engine_version:'1',operations:steps?['start','step','run-all']:['evaluate'],worker:'worker.js'};
  const runtime=executionRuntime({provider,execution:{operation:steps?'start':'evaluate',options:{}},files:()=>files,onState:s=>states.push(s),
    ...clock,workerFactory(){const worker={sent:[],terminate(){this.terminated=true;},postMessage(r){this.sent.push(r);}};workers.push(worker);return worker;}});
  function reply(extra={},worker=workers.at(-1)) { const req=worker.sent.at(-1);worker.onmessage?.({data:{...req,status:'success',diagnostics:[],outputs:[],blocked:null,verdict:null,steps:null,...extra}}); }
  return {runtime,clock,workers,states,reply,edit(text){files=[{...files[0],text}];runtime.edit();}};
}

test('debounce coalesces edits; stale active replies never replace current results',()=>{
  const f=fixture();f.clock.tick(0);assert.equal(f.workers.length,1);
  f.edit('two');f.edit('three');f.clock.tick(249);assert.equal(f.workers[0].sent.length,1);
  f.reply({outputs:[{id:'out',label:'Output',language:'text',text:'old'}]});
  assert.equal(f.states.at(-1).state,'pending');f.clock.tick(1);
  assert.equal(f.workers[0].sent.length,2);assert.equal(f.workers[0].sent[1].files[0].text,'three');
  f.reply();assert.equal(f.states.at(-1).state,'success');
});

test('timeout retries once in fresh runtime; new edit permits recovery',()=>{
  const f=fixture();f.clock.tick(0);f.clock.tick(10000);assert.equal(f.workers.length,2);assert.equal(f.workers[0].terminated,true);
  f.clock.tick(10000);assert.equal(f.states.at(-1).state,'timeout');f.clock.tick(100000);assert.equal(f.workers.length,2);
  f.edit('recovered');f.clock.tick(250);assert.equal(f.workers.length,3);f.reply();assert.equal(f.states.at(-1).state,'success');
});

test('reset/disposal invalidate worker callbacks and queued timers',()=>{
  const f=fixture();f.clock.tick(0);const stale=f.workers[0].onmessage,request=f.workers[0].sent[0];
  f.runtime.reset();f.clock.tick(0);stale({data:{...request,status:'success',diagnostics:[],outputs:[]}});
  assert.equal(f.states.at(-1).state,'pending');f.runtime.dispose();f.clock.tick(50000);assert.equal(f.workers.length,2);assert.equal(f.workers[1].terminated,true);
});

test('protocol mismatch and malformed results fail once without automatic restart',()=>{
  for(const extra of [{contract_version:9},{outputs:'bad'},{status:'blocked'},{diagnostics:[{code:'x'}]}]) {
    const f=fixture();f.clock.tick(0);f.reply(extra);assert.equal(f.states.at(-1).state,'error');f.clock.tick(50000);assert.equal(f.workers.length,1);
  }
});

test('requested steps replay from fresh session after edit; shorter input ends replay',()=>{
  const f=fixture({steps:true});f.clock.tick(0);
  const step=(checked,complete=false)=>({session:'session',rows:[0,1].map(i=>({id:String(i),label:String(i),text:'row',diagnostics:[]})),checked,complete});
  f.reply({steps:step(0)});f.runtime.step();f.clock.tick(0);f.reply({steps:step(1)});
  f.runtime.step();f.clock.tick(0);f.reply({steps:step(2,true)});
  f.edit('short');f.clock.tick(250);assert.equal(f.workers[0].sent.at(-1).operation,'start');assert.equal(f.workers[0].sent.at(-1).session,null);
  f.reply({steps:step(0)});assert.equal(f.workers[0].sent.at(-1).operation,'step');f.reply({steps:step(1,true)});
  assert.equal(f.states.at(-1).result.steps.checked,1);assert.equal(f.runtime.state().requested,2);
});

test('storage accepts same identity and revision only, denied/corrupt storage stays usable',()=>{
  const docs=[{id:'a',text:'start'}],key='course';
  for(const storage of [{getItem(){throw Error('denied');}},{getItem(){return '{bad';}},{getItem(){return JSON.stringify({revision:'old',documents:[{id:'a',text:'bad'}]});}}]) assert.deepEqual(restoreEdits(storage,key,'new',docs),docs);
  const storage={getItem(){return JSON.stringify({revision:'new',documents:[{id:'a',text:'saved'}]});}};
  assert.equal(restoreEdits(storage,key,'new',docs)[0].text,'saved');
  assert.notEqual(canonical(['site','/v/1/','one','lesson']),canonical(['site','/v/2/','one','lesson']));
});

test('workbench handoff rejects unsupported, unsafe and oversized state',()=>{
  for(const result of [{reason:'unsupported'},{url:'javascript:alert(1)',max_length:1000},{url:'https://example.test/'+ 'x'.repeat(100),max_length:10}]) assert.throws(()=>handoffURL(result,'https://example.test/'));
  assert.equal(handoffURL({url:'/workbench/#ok',max_length:100},'https://example.test/'),'https://example.test/workbench/#ok');
});

test('malformed nested diagnostics and missing identity produce visible errors',()=>{
  const f=fixture();f.clock.tick(0);f.reply({steps:{session:'s',rows:[{id:'x',label:'x',text:'x',diagnostics:[null]}],checked:1,complete:true}});
  assert.equal(f.states.at(-1).state,'error');
  const g=fixture();g.clock.tick(0);g.workers[0].onmessage({data:{}});assert.equal(g.states.at(-1).state,'error');
});
