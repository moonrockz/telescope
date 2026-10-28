// Original Telescope execution lifecycle, Apache-2.0.
export function canonical(value) {
  if (Array.isArray(value)) return `[${value.map(canonical).join(',')}]`;
  if (value && typeof value === 'object') return `{${Object.keys(value).sort().map(k => `${JSON.stringify(k)}:${canonical(value[k])}`).join(',')}}`;
  return JSON.stringify(value);
}

export function validateResponse(request, value) {
  if (!value || typeof value !== 'object') throw Error('Malformed execution response');
  for (const key of ['contract_version', 'provider', 'engine_version', 'generation', 'request_id', 'input_revision']) {
    if (value[key] !== request[key]) throw Error(`Execution response ${key} mismatch`);
  }
  if (!['success', 'blocked', 'error'].includes(value.status) || !Array.isArray(value.diagnostics) || !Array.isArray(value.outputs)) throw Error('Malformed execution result');
  function validateDiagnostic(diagnostic) {
    if (!diagnostic || !['key', 'code', 'severity', 'message'].every(k => typeof diagnostic[k] === 'string' && diagnostic[k].length > 0)) throw Error('Malformed diagnostic');
    for (const key of ['line', 'column', 'end_line', 'end_column']) if (diagnostic[key] != null && (!Number.isInteger(diagnostic[key]) || diagnostic[key] < 1)) throw Error('Malformed diagnostic location');
    if (diagnostic.file != null && (typeof diagnostic.file !== 'string' || !diagnostic.file || diagnostic.file.includes('\\') || diagnostic.file.includes(':') || diagnostic.file.split('/').some(p=> !p || p==='.' || p==='..'))) throw Error('Malformed diagnostic filename');
  }
  value.diagnostics.forEach(validateDiagnostic);
  const ids = new Set();
  for (const output of value.outputs) {
    if (!output || !['id', 'label', 'text', 'language'].every(k => typeof output[k] === 'string') || !output.id || !output.label || ids.has(output.id)) throw Error('Malformed or duplicate output');
    ids.add(output.id);
  }
  if (value.status === 'blocked' && (typeof value.blocked !== 'string' || !value.blocked)) throw Error('Blocked result requires a reason');
  if (value.status !== 'blocked' && value.blocked != null) throw Error('Blocked reason requires blocked status');
  if (value.verdict != null && typeof value.verdict !== 'string') throw Error('Malformed verdict');
  if (value.steps != null) {
    const s = value.steps;
    if (typeof s.session !== 'string' || !s.session || !Array.isArray(s.rows) || !Number.isInteger(s.checked) || s.checked < 0 || s.checked > s.rows.length || typeof s.complete !== 'boolean') throw Error('Malformed step progress');
    const rowIds = new Set();
    for (const row of s.rows) {
      if (!row || !['id', 'label', 'text'].every(k => typeof row[k] === 'string') || !row.id || !row.label || rowIds.has(row.id) || !Array.isArray(row.diagnostics)) throw Error('Malformed step row');
      rowIds.add(row.id); row.diagnostics.forEach(validateDiagnostic);
    }
  }
  return value;
}

export function executionRuntime({provider, execution, files, onState, workerFactory = url => new Worker(url, {type:'module'}),
  setTimer = setTimeout, clearTimer = clearTimeout, debounce = 250, timeout = 10000}) {
  let worker, generation = 0, requestId = 0, active, pending = true, disposed = false;
  let debounceTimer, deadline, retries = 0, session = null, checked = 0, requested = 0, runAll = false;
  let currentFiles = files(), revision = inputRevision(currentFiles);
  const isSteps = execution.operation === 'start';
  function inputRevision(input) {
    return canonical({schema_version:1, provider:provider.id, engine_version:provider.engine_version,
      contract_version:provider.contract_version, operation:execution.operation, options:execution.options,
      files:input.map(({name,text,language,group}) => ({name,text,language,group:group || ''}))});
  }
  function status(state, result, message) { onState({state, result, message}); }
  function stop() {
    clearTimer(deadline); deadline = undefined;
    if (worker) { worker.onmessage = null; worker.onerror = null; worker.terminate(); worker = undefined; }
    generation++; session = null; checked = 0;
  }
  function fail(message) { active = undefined; pending = false; stop(); status('error', null, message); }
  function schedule(delay = debounce) {
    clearTimer(debounceTimer);
    debounceTimer = setTimer(() => { debounceTimer = undefined; dispatch(); }, delay);
  }
  function dispatch() {
    if (disposed || active || !pending || debounceTimer !== undefined) return;
    if (!worker) {
      generation++;
      try { worker = workerFactory(provider.worker); }
      catch (error) { fail(String(error)); return; }
      const mountedWorker = worker;
      worker.onerror = () => { if (worker === mountedWorker && !disposed) fail('Execution worker failed. Edit or Retry to try again.'); };
      worker.onmessage = event => receive(event.data, mountedWorker);
    }
    let operation = execution.operation;
    if (isSteps && session) operation = runAll ? 'run-all' : 'step';
    if (!provider.operations.includes(operation)) { fail(`Provider does not support ${operation}`); return; }
    active = {contract_version:1, provider:provider.id, engine_version:provider.engine_version,
      generation, request_id:++requestId, input_revision:revision, operation,
      files:currentFiles.map(f => ({name:f.name,text:f.text,language:f.language,group:f.group || ''})),
      options:execution.options, session, position:requested};
    pending = false; status('pending');
    const request = active;
    deadline = setTimer(() => {
      if (active !== request || disposed) return;
      active = undefined; stop();
      if (request.input_revision !== revision) { pending = true; dispatch(); return; }
      if (retries++ === 0) { pending = true; dispatch(); }
      else { pending = false; status('timeout', null, 'Execution timed out twice. Edit or Retry to try again.'); }
    }, timeout);
    try { worker.postMessage(active); } catch (error) { fail(String(error)); }
  }
  function receive(value, source) {
    if (disposed || source !== worker || !active) return;
    const request = active;
    // Messages from earlier requests cannot consume the current deadline.
    if (value && Number.isInteger(value.generation) && Number.isInteger(value.request_id) && (value.generation !== request.generation || value.request_id !== request.request_id)) return;
    clearTimer(deadline); deadline = undefined; active = undefined;
    if (request.input_revision !== revision) { pending = true; dispatch(); return; }
    let result;
    try { result = validateResponse(request, value); } catch (error) { fail(error.message); return; }
    if (isSteps && result.status === 'success' && !result.steps) { fail('Stepping provider omitted progress'); return; }
    if (result.steps) {
      const previousChecked = checked;
      session = result.steps.session; checked = result.steps.checked;
      if (result.status === 'success' && !result.steps.complete && (runAll || checked < requested)) {
        if (request.operation !== 'start' && checked <= previousChecked) { fail('Step execution made no progress'); return; }
        pending = true; dispatch(); return;
      }
    }
    status(result.status, result, result.blocked);
    if (pending) dispatch();
  }
  function edit() {
    if (disposed) return;
    const next = files(), nextRevision = inputRevision(next);
    if (revision === nextRevision) return;
    currentFiles = next; revision = nextRevision; retries = 0; session = null; checked = 0;
    pending = true; status('pending'); schedule();
  }
  schedule(0);
  return {
    edit,
    reset() { if (disposed) return; active = undefined; stop(); currentFiles = files(); revision = inputRevision(currentFiles); retries = 0; requested = 0; runAll = false; pending = true; status('pending'); schedule(0); },
    retry() { if (disposed) return; active = undefined; stop(); retries = 0; pending = true; schedule(0); },
    step() { if (disposed || !isSteps) return; requested = Math.max(requested,checked) + 1; runAll = false; pending = true; schedule(0); },
    runAll() { if (disposed || !isSteps) return; runAll = true; pending = true; schedule(0); },
    dispose() { disposed = true; active = undefined; clearTimer(debounceTimer); stop(); },
    state: () => ({generation, active, revision, requested, retries, disposed}),
  };
}

export function restoreEdits(storage, key, revision, documents) {
  try {
    const saved = JSON.parse(storage.getItem(key));
    if (!saved || saved.revision !== revision || !Array.isArray(saved.documents) || saved.documents.length !== documents.length) return documents;
    if (!documents.every((doc,i) => saved.documents[i].id === doc.id && typeof saved.documents[i].text === 'string')) return documents;
    return documents.map((doc,i) => ({...doc,text:saved.documents[i].text}));
  } catch { return documents; }
}

export function handoffURL(result, base) {
  if (!result || typeof result.url !== 'string') throw Error(result?.reason || 'This workbench cannot represent the current files.');
  const url = new URL(result.url, base);
  if (!['http:','https:'].includes(url.protocol) || url.username || url.password) throw Error('Unsafe workbench destination');
  if (!Number.isSafeInteger(result.max_length) || result.max_length < 1 || url.href.length > result.max_length) throw Error('Workbench state is too large. Current files are preserved.');
  return url.href;
}
