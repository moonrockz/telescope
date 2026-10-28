// Original Telescope lesson composition, Apache-2.0.
import {mountEditor} from '../../editor/browser/editor.js';
import {executionRuntime, restoreEdits, canonical, handoffURL} from './runtime.js';

function element(tag, text, attrs = {}) {
  const node = document.createElement(tag);
  if (text != null) node.textContent = text;
  for (const [key,value] of Object.entries(attrs)) node.setAttribute(key,value);
  return node;
}

export async function mountWorkspace(mount, config, dependencies = {}) {
  const storageKey = `telescope:tutorial:${canonical([config.site,config.base,config.course,config.lesson])}`;
  let storage;
  try { storage = window.localStorage; } catch { storage = null; }
  const starting = config.documents.map(doc => ({...doc}));
  let documents = restoreEdits(storage,storageKey,config.starting_revision,starting);
  const heading = element('h2','Workspace');
  const controls = element('div',null,{class:'tutorial-controls'});
  const reset = element('button','Reset',{type:'button'});
  const expand = element('button','Expand output',{type:'button','aria-expanded':'false'});
  const retry = element('button','Retry',{type:'button'});
  controls.append(reset,expand);
  const status = element('p','Preparing editor',{role:'status','aria-live':'polite'});
  const body = element('div',null,{class:'tutorial-panes'});
  const editorMount = element('div',null,{class:'tutorial-editor'});
  const resultPane = element('section',null,{class:'tutorial-results','aria-label':'Results'});
  const diagnostics = element('div',null,{'aria-label':'Diagnostics'});
  const selector = element('select',null,{'aria-label':'Output'});
  const output = element('pre',null,{tabindex:'0'});
  const steps = element('div',null,{'aria-label':'Steps'});
  resultPane.append(diagnostics,selector,output,steps);
  body.append(editorMount,resultPane);
  mount.append(heading,controls,status,body);
  let runtime, disposed = false, currentResult, selectedOutput, previousOutputs = new Map(), lastSuccessful = new Map();
  let editor;
  function drawOutput() {
    output.replaceChildren();
    const selected = currentResult?.outputs.find(o => o.id === selector.value);
    if (!selected) return;
    const old = previousOutputs.get(selected.id)?.split('\n');
    selected.text.split('\n').forEach((line,index,lines) => {
      const span = element('span',line + (index < lines.length-1 ? '\n' : ''));
      if (old && old[index] !== line) { span.className = 'tutorial-changed-line'; span.setAttribute('data-changed','true'); }
      output.append(span);
    });
  }
  function draw(state) {
    mount.dataset.state = state.state;
    status.textContent = state.message || ({pending:'Checking current files',success:'Current files checked',blocked:'Output blocked',error:'Checking failed',timeout:'Checking timed out'}[state.state] || state.state);
    retry.hidden = !['error','timeout'].includes(state.state);
    if (!state.result) { currentResult = null; diagnostics.replaceChildren(); selector.replaceChildren(); output.replaceChildren(); steps.replaceChildren(); return; }
    if (state.result.status === 'success') {
      previousOutputs = lastSuccessful;
      lastSuccessful = new Map(state.result.outputs.map(o => [o.id,o.text]));
    }
    // Pending renders clear the displayed result but retain prior successful text.
    currentResult = state.result;
    diagnostics.replaceChildren();
    for (const diagnostic of currentResult.diagnostics) {
      const location = diagnostic.file ? ` ${diagnostic.file}${diagnostic.line ? ':'+diagnostic.line : ''}${diagnostic.column ? ':'+diagnostic.column : ''}` : '';
      diagnostics.append(element('p',`${diagnostic.severity} ${diagnostic.code}${location}: ${diagnostic.message}`));
    }
    selector.replaceChildren();
    for (const item of currentResult.outputs) selector.append(element('option',item.label,{value:item.id}));
    if (currentResult.outputs.some(o => o.id === selectedOutput)) selector.value = selectedOutput;
    selector.hidden = !currentResult.outputs.length;
    drawOutput();
    steps.replaceChildren();
    if (currentResult.steps) {
      steps.append(element('p',`${currentResult.steps.checked} steps checked${currentResult.steps.complete ? ', complete' : ''}`));
      for (const row of currentResult.steps.rows.slice(0,currentResult.steps.checked)) {
        steps.append(element('h3',row.label),element('pre',row.text));
        for (const diagnostic of row.diagnostics) steps.append(element('p',`${diagnostic.severity} ${diagnostic.code}: ${diagnostic.message}`));
      }
    }

  }
  selector.addEventListener('change',() => { selectedOutput = selector.value; drawOutput(); });
  try {
    editor = await mountEditor(editorMount,{
      id:`${config.course}/${config.lesson}`,adapter:config.adapter,documents,assetBase:config.base,
      editors:config.editors,formatters:config.formatters,languages:config.formatting?.languages || {},
      ...dependencies.editor,
      onChange() {
        documents = editor.getDocuments();
        try { storage?.setItem(storageKey,JSON.stringify({revision:config.starting_revision,documents:documents.map(d => ({id:d.id,text:d.text}))})); } catch { /* In-memory editing remains usable. */ }
        runtime?.edit();
      },
    });
  } catch (error) { status.textContent = `Editor unavailable: ${error.message}. Starting files remain readable above.`; return {dispose(){mount.replaceChildren();}}; }
  mount.telescopeEditor = editor;
  if (config.provider && config.execution) {
    runtime = executionRuntime({provider:config.provider,execution:config.execution,
      files:() => editor.getDocuments(),onState:draw,...dependencies.runtime});
    controls.append(retry);
    if (config.execution.operation === 'start') {
      if (config.provider.operations.includes('step')) {
        const step = element('button','Step',{type:'button'}); step.onclick = () => runtime.step(); controls.append(step);
      }
      if (config.provider.operations.includes('run-all')) {
        const all = element('button','Run all',{type:'button'}); all.onclick = () => runtime.runAll(); controls.append(all);
      }
    }
    retry.onclick = () => runtime.retry(); retry.hidden = true;
    if (config.provider.workbench) {
      const open = element('button','Open in workbench',{type:'button'});
      open.onclick = async () => {
        const captured = canonical(editor.getDocuments());
        try {
          const {encode} = await import(config.provider.workbench);
          const result = await encode({files:editor.getDocuments(),options:config.execution.options,operation:config.execution.operation});
          if (disposed || canonical(editor.getDocuments()) !== captured) return;
          const url = handoffURL(result,location.href);
          location.assign(url);
        } catch (error) { status.textContent = error.message; }
      };
      controls.append(open);
    }
  } else { status.textContent = 'Editing locally'; resultPane.hidden = true; expand.hidden = true; }
  reset.onclick = () => {
    editor.reset(starting.map(doc => ({...doc})));
    documents = editor.getDocuments();
    try { storage?.removeItem(storageKey); } catch { /* Reset still restores documents. */ }
    runtime?.reset();
    status.textContent = runtime ? 'Checking starting files' : 'Starting files restored';
  };
  expand.onclick = () => {
    const expanded = expand.getAttribute('aria-expanded') !== 'true';
    expand.setAttribute('aria-expanded',String(expanded));
    expand.textContent = expanded ? 'Restore split view' : 'Expand output';
    editorMount.hidden = expanded;
    mount.classList.toggle('tutorial-expanded',expanded);
  };
  const api = {editor,runtime,dispose(){disposed = true;runtime?.dispose();editor.dispose();window.removeEventListener('pagehide',api.dispose);}};
  window.addEventListener('pagehide',api.dispose,{once:true});
  mount.telescopeWorkspace = api;
  return api;
}

for (const mount of document.querySelectorAll('[data-tutorial-workspace]')) {
  const script = mount.querySelector('[data-tutorial-config]');
  try { await mountWorkspace(mount,JSON.parse(script.textContent)); }
  catch (error) { mount.append(element('p',`Workspace unavailable: ${error.message}`,{role:'status'})); }
}
