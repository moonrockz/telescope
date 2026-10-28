// General editor. Persistence, execution and course state belong to callers.
let instanceSequence = 0;
const clone = value => structuredClone(value);
const relative = path => typeof path === 'string' && path.length > 0 &&
  !path.startsWith('/') && !path.includes('\\') && !/[:\u0000-\u001f]/.test(path) &&
  path.split('/').every(part => part && part !== '.' && part !== '..');
const assetRelative = path => relative(path) && !/[%?#]/.test(path);
const unique = values => new Set(values).size === values.length;
const own = (object, key) => object && Object.hasOwn(object, key) ? object[key] : undefined;
const bindingFor = (document, config) => document.formatter ?? own(config.languages, document.language);
const finiteTimeout = timeout => Number.isFinite(timeout) && timeout > 0 ? timeout : 10_000;

const record = value => value !== null && typeof value === 'object' && !Array.isArray(value);
function jsonValue(value, seen = new Set()) {
  if (value === null || typeof value === 'string' || typeof value === 'boolean') return true;
  if (typeof value === 'number') return Number.isFinite(value);
  if (typeof value !== 'object' || seen.has(value)) return false;
  seen.add(value);
  const valid = Array.isArray(value) ? value.every(v => jsonValue(v, seen)) :
    (Object.getPrototypeOf(value) === Object.prototype || Object.getPrototypeOf(value) === null) && Object.values(value).every(v => jsonValue(v, seen));
  seen.delete(value); return valid;
}

export function validateEditorConfig(config) {
  const errors = [];
  if (!record(config)) return ['editor configuration must be a table'];
  if (!Array.isArray(config.documents) || config.documents.length === 0) errors.push('documents must be a nonempty array');
  const documents = Array.isArray(config.documents) ? config.documents : [];
  if (!unique(documents.map(d => d?.id))) errors.push('document identities must be unique');
  for (const d of documents) {
    if (!record(d) || typeof d.id !== 'string' || !d.id || !relative(d.name) || typeof d.text !== 'string' || typeof d.language !== 'string') errors.push('invalid editor document');
  }
  if (config.formatters !== undefined && !Array.isArray(config.formatters)) errors.push('formatters must be an array');
  const formatters = Array.isArray(config.formatters) ? config.formatters : [];
  if (!unique(formatters.map(f => f?.id))) errors.push('formatter identifiers must be unique');
  for (const f of formatters) {
    if (!record(f)) { errors.push('invalid formatter registration'); continue; }
    if (typeof f.id !== 'string' || !f.id || f.contract_version !== 1 || typeof f.formatter_version !== 'string' || !f.formatter_version) errors.push('unsupported formatter contract or version');
    if (!Array.isArray(f.languages) || !f.languages.length || !unique(f.languages) || f.languages.some(l => typeof l !== 'string' || !l)) errors.push(`formatter ${f.id} requires unique supported languages`);
    if (!Array.isArray(f.assets) || !assetRelative(f.worker) || !f.assets.includes(f.worker) || f.assets.some(p => !assetRelative(p))) errors.push(`formatter ${f.id} requires contained declared assets and worker`);
  }
  const validateBinding = (language, binding) => {
    const f = formatters.find(f => f && f.id === binding?.provider);
    if (!f) errors.push(`unknown formatter ${binding?.provider}`);
    else if (!Array.isArray(f.languages) || !f.languages.includes(language)) errors.push(`formatter ${f.id} does not support ${language}`);
    if (!record(binding) || (binding.options !== undefined && (!record(binding.options) || !jsonValue(binding.options)))) errors.push('formatter options must be a JSON-compatible table');
  };
  if (config.languages !== undefined && !record(config.languages)) errors.push('language bindings must be a table');
  else for (const [language, binding] of Object.entries(config.languages || {})) validateBinding(language, binding);
  for (const d of documents) if (d?.formatter) validateBinding(d.language, d.formatter);
  if (config.editors !== undefined && !Array.isArray(config.editors)) errors.push('editors must be an array');
  const editors = Array.isArray(config.editors) ? config.editors : [];
  if (!unique(editors.map(e => e?.id))) errors.push('editor identifiers must be unique');
  const languageIds = new Set();
  for (const e of editors) {
    if (!record(e)) { errors.push('invalid editor registration'); continue; }
    if (typeof e.id !== 'string' || !e.id || e.contract_version !== 1 || !['editor', 'language'].includes(e.kind) ||
      !Array.isArray(e.languages) || !e.languages.length || e.languages.some(l => typeof l !== 'string' || !l) || !unique(e.languages) ||
      !assetRelative(e.module) || !Array.isArray(e.assets) || !e.assets.includes(e.module) || e.assets.some(p => !assetRelative(p))) errors.push(`invalid editor registration ${e.id}`);
    if (e.kind === 'language' && Array.isArray(e.languages)) for (const language of e.languages) {
      if (languageIds.has(language)) errors.push(`duplicate language registration for ${language}`);
      languageIds.add(language);
    }
  }
  const adapter = config.adapter || 'plain';
  const selected = editors.find(e => e?.kind === 'editor' && e.id === adapter);
  if (selected) {
    for (const d of documents) if (!selected.languages?.includes(d?.language)) errors.push(`editor ${adapter} does not support ${d?.language}`);
  } else if (!['plain', 'rich'].includes(adapter) && typeof own(config.adapters, adapter) !== 'function') errors.push(`unknown editor adapter ${adapter}`);
  return errors;
}

function clampSelection(selection, length) {
  const clamp = value => Math.max(0, Math.min(length, Number.isInteger(value) ? value : 0));
  return { anchor: clamp(selection.anchor), head: clamp(selection.head) };
}

function mapSelection(selection, before, after) {
  let prefix = 0;
  while (prefix < before.length && prefix < after.length && before[prefix] === after[prefix]) prefix++;
  let suffix = 0;
  while (suffix < before.length - prefix && suffix < after.length - prefix && before[before.length - 1 - suffix] === after[after.length - 1 - suffix]) suffix++;
  const map = position => position <= prefix ? position : position >= before.length - suffix ? position + after.length - before.length : Math.min(position, after.length - suffix);
  return clampSelection({ anchor: map(selection.anchor), head: map(selection.head) }, after.length);
}

function createPlainAdapter(parent, callbacks) {
  const input = document.createElement('textarea');
  input.className = 'te-plain'; input.setAttribute('aria-label', 'Code editor'); input.spellcheck = false;
  parent.append(input);
  const selection = () => ({ anchor: input.selectionDirection === 'backward' ? input.selectionEnd : input.selectionStart,
    head: input.selectionDirection === 'backward' ? input.selectionStart : input.selectionEnd });
  const onInput = () => callbacks.change(input.value, selection());
  const onSelection = () => callbacks.selection(selection());
  const onKey = event => {
    if (!(event.ctrlKey || event.metaKey)) return;
    const key = event.key.toLowerCase();
    if (key === 'z' || key === 'y') {
      event.preventDefault();
      (key === 'y' || event.shiftKey ? callbacks.redo : callbacks.undo)();
    }
  };
  input.addEventListener('input', onInput); input.addEventListener('select', onSelection);
  input.addEventListener('keyup', onSelection); input.addEventListener('click', onSelection); input.addEventListener('keydown', onKey);
  const setSelection = value => input.setSelectionRange(Math.min(value.anchor, value.head), Math.max(value.anchor, value.head), value.head < value.anchor ? 'backward' : 'forward');
  return {
    show(document, selection, focus = false) { input.value = document.text; input.readOnly = document.editable === false; setSelection(selection); if (focus) input.focus(); },
    setLanguage() {}, selection: setSelection,
    focused: () => document.activeElement === input, focus: () => input.focus(), dispose: () => input.remove(),
  };
}

export async function mountEditor(element, initialConfig) {
  const config = { adapter: 'plain', editors: [], formatters: [], languages: {}, ...initialConfig };
  const errors = validateEditorConfig(config);
  if (errors.length) throw new Error(errors.join('; '));
  config.formatters = clone(config.formatters); config.languages = clone(config.languages); config.editors = clone(config.editors);
  const instance = `${config.id || 'telescope-editor'}:${++instanceSequence}`;
  let generation = 0, requestId = 0, pending = null, disposed = false, adapter;
  let documents = new Map(), active, adapterRequest = 0, documentRequest = 0, languageSequence = 0;
  const languageRequests = new Map();
  const makeDocuments = values => new Map(values.map(value => [value.id, { document: clone(value), revision: 0, selection: { anchor: 0, head: 0 }, undo: [], redo: [] }]));
  documents = makeDocuments(config.documents); active = config.documents[0].id;
  const wrapper = document.createElement('section'); wrapper.className = 'telescope-editor'; wrapper.setAttribute('aria-label', config.label || 'Editor');
  const toolbar = document.createElement('div'); toolbar.className = 'te-toolbar';
  const label = document.createElement('label'); label.append('File ');
  const selector = document.createElement('select'); selector.setAttribute('aria-label', 'Editor file'); label.append(selector);
  const formatButton = document.createElement('button'); formatButton.type = 'button'; formatButton.textContent = 'Format';
  const inputHost = document.createElement('div'); inputHost.className = 'te-input';
  const status = document.createElement('div'); status.className = 'te-status'; status.setAttribute('role', 'status'); status.setAttribute('aria-live', 'polite');
  toolbar.append(label, formatButton); wrapper.append(toolbar, inputHost, status);
  // Declared module imports remain optional and route-local. Language modules
  // receive this bundle's StreamLanguage, avoiding another CodeMirror instance.
  const directLanguages = { ...config.languageAdapters };
  const loadedLanguages = new Set(), moduleCache = new Map();
  const registrationFor = kind => config.editors.find(e => e.kind === 'editor' && e.id === kind);
  const builtinRich = kind => kind === 'rich' && !registrationFor(kind) && !own(config.adapters, kind);
  const moduleFor = registration => {
    if (!moduleCache.has(registration.id)) moduleCache.set(registration.id,
      import(new URL(registration.module, new URL(config.assetBase || document.baseURI, document.baseURI)).href));
    return moduleCache.get(registration.id);
  };
  const languagesNeeded = values => config.editors.filter(e => e.kind === 'language' && !loadedLanguages.has(e.id) &&
    e.languages.some(language => values.some(d => d.language === language) && !Object.hasOwn(directLanguages, language)));
  async function prepareRich(values) {
    const rich = await import('./rich.js');
    for (const registration of languagesNeeded(values)) {
      const languageModule = await moduleFor(registration);
      if (typeof languageModule.createLanguages !== 'function') throw new Error(`language ${registration.id} must export createLanguages`);
      const extensions = languageModule.createLanguages({ StreamLanguage: rich.StreamLanguage });
      if (!record(extensions) || registration.languages.some(language => !Object.hasOwn(extensions, language)) ||
        Object.keys(extensions).some(language => !registration.languages.includes(language))) throw new Error(`language ${registration.id} returned undeclared or missing bindings`);
      config.languageAdapters = { ...config.languageAdapters, ...extensions, ...directLanguages };
      loadedLanguages.add(registration.id);
    }
    return rich;
  }
  async function createAdapter(kind, parent, callbacks, values) {
    let result;
    if (typeof own(config.adapters, kind) === 'function') result = await own(config.adapters, kind)(parent, callbacks, config);
    else if (registrationFor(kind)) {
      const registration = registrationFor(kind), module = await moduleFor(registration);
      if (typeof module.createAdapter !== 'function') throw new Error(`editor ${registration.id} must export createAdapter`);
      result = await module.createAdapter(parent, callbacks, config);
    } else if (kind === 'rich') result = (await prepareRich(values)).createRichAdapter(parent, callbacks, config);
    else result = createPlainAdapter(parent, callbacks);
    if (!result || ['show', 'setLanguage', 'selection', 'focused', 'focus', 'dispose'].some(method => typeof result[method] !== 'function')) throw new Error(`editor ${kind} returned an incompatible adapter`);
    return result;
  }
  const say = text => { status.textContent = text; };
  const current = () => documents.get(active);
  const publicDocuments = () => [...documents.values()].map(d => clone(d.document));
  const invalidate = () => {
    generation++;
    if (pending) { clearTimeout(pending.timer); pending.worker.terminate(); pending.resolve(false); pending = null; }
    if (!disposed) { formatButton.disabled = false; say(''); }
  };
  const updateControls = () => {
    const selected = current(); selector.value = active;
    formatButton.hidden = selected.document.editable === false || !bindingFor(selected.document, config);
    formatButton.disabled = !!pending;
  };
  const notify = (state, origin) => {
    const event = { id: state.document.id, text: state.document.text, document: clone(state.document), documents: publicDocuments(), origin };
    config.onChange?.(event); element.dispatchEvent(new CustomEvent('editor-change', { detail: event }));
  };
  const show = (focus = false) => {
    const state = current(); adapter.show(state.document, state.selection, focus); updateControls();
  };
  const change = (id, text, selection, origin = 'edit') => {
    if (disposed) return false;
    const state = documents.get(id);
    if (!state || state.document.editable === false || text === state.document.text) return false;
    const focused = id === active && adapter.focused();
    const previousText = state.document.text;
    state.undo.push({ text: previousText, selection: { ...state.selection } }); state.redo.length = 0;
    state.document.text = text; state.revision++;
    state.selection = selection ? clampSelection(selection, text.length) : mapSelection(state.selection, previousText, text);
    invalidate();
    // An adapter-originated edit is already visible. Replacing it again would
    // reset incremental parsing and interfere with active text composition.
    if (id === active) { if (selection) updateControls(); else show(focused); }
    notify(state, origin); return true;
  };
  const history = (id, backwards) => {
    if (disposed) return false;
    const state = documents.get(id); if (!state || state.document.editable === false) return false;
    const from = backwards ? state.undo : state.redo, to = backwards ? state.redo : state.undo;
    const next = from.pop(); if (!next) return false;
    const focused = id === active && adapter.focused();
    to.push({ text: state.document.text, selection: { ...state.selection } });
    state.document.text = next.text; state.selection = next.selection; state.revision++;
    invalidate(); if (id === active) show(focused); notify(state, backwards ? 'undo' : 'redo'); return true;
  };
  const callbacks = {
    change: (text, selection) => change(active, text, selection),
    selection: selection => { if (!disposed) current().selection = clampSelection(selection, current().document.text.length); },
    undo: () => history(active, true), redo: () => history(active, false),
  };
  // Keep authored fallback until every selected module has loaded successfully.
  adapter = await createAdapter(config.adapter, inputHost, callbacks, publicDocuments());
  const refreshOptions = () => {
    selector.replaceChildren();
    for (const state of documents.values()) {
      const option = document.createElement('option'); option.value = state.document.id;
      option.textContent = `${state.document.group ? state.document.group + ' / ' : ''}${state.document.name}`; selector.append(option);
    }
    label.hidden = documents.size < 2; show();
  };
  const fail = message => { if (!disposed) say(`Formatting failed: ${message}`); };
  const api = {
    getDocuments: publicDocuments,
    getDocument(id = active) { return clone(documents.get(id)?.document); },
    getSelection(id = active) { return { ...documents.get(id).selection }; },
    setSelection(id, selection) { const state = documents.get(id); state.selection = clampSelection(selection, state.document.text.length); if (id === active) adapter.selection(state.selection); },
    selectDocument(id) { if (disposed || !documents.has(id)) return false; active = id; show(); return true; },
    setLanguage(id, language) {
      const state = documents.get(id); if (!state || disposed) return;
      const proposed = publicDocuments().map(d => d.id === id ? { ...d, language } : d);
      const errors = validateEditorConfig({ ...config, documents: proposed }); if (errors.length) throw new Error(errors.join('; '));
      const token = ++languageSequence; languageRequests.set(id, token);
      invalidate();
      const apply = () => {
        if (disposed || documents.get(id) !== state || languageRequests.get(id) !== token) return;
        state.document.language = language; state.revision++;
        if (id === active) { adapter.setLanguage(language); updateControls(); }
      };
      if (builtinRich(config.adapter) && languagesNeeded(proposed).length) return prepareRich(proposed).then(apply);
      apply();
    },
    async setAdapter(kind) {
      if (disposed) return;
      const token = ++adapterRequest;
      if (kind === config.adapter) return;
      const errors = validateEditorConfig({ ...config, adapter: kind, documents: publicDocuments() }); if (errors.length) throw new Error(errors.join('; '));
      const focused = adapter.focused(), nextHost = document.createElement('div'); nextHost.className = 'te-input';
      const next = await createAdapter(kind, nextHost, callbacks, publicDocuments());
      if (disposed || adapterRequest !== token) { next.dispose(); return; }
      const currentErrors = validateEditorConfig({ ...config, adapter: kind, documents: publicDocuments() });
      if (currentErrors.length) { next.dispose(); throw new Error(currentErrors.join('; ')); }
      if (builtinRich(kind) && languagesNeeded(publicDocuments()).length) await prepareRich(publicDocuments());
      if (disposed || adapterRequest !== token) { next.dispose(); return; }
      adapter.dispose(); inputHost.replaceChildren(...nextHost.childNodes); adapter = next; config.adapter = kind; show(focused);
    },
    edit(id, text) { return change(id, text); },
    undo(id = active) { return history(id, true); }, redo(id = active) { return history(id, false); },
    reset(values = config.documents) { return api.replaceDocuments(values); },
    replaceDocuments(values) {
      if (disposed) return;
      const errors = validateEditorConfig({ ...config, documents: values }); if (errors.length) throw new Error(errors.join('; '));
      const token = ++documentRequest;
      invalidate(); languageRequests.clear();
      const apply = () => {
        if (disposed || documentRequest !== token) return;
        const currentErrors = validateEditorConfig({ ...config, documents: values }); if (currentErrors.length) throw new Error(currentErrors.join('; '));
        documents = makeDocuments(values); if (!documents.has(active)) active = values[0].id; refreshOptions();
      };
      if (builtinRich(config.adapter) && languagesNeeded(values).length) return prepareRich(values).then(apply);
      apply();
    },
    setFormatters(formatters, languages = config.languages) {
      const errors = validateEditorConfig({ ...config, documents: publicDocuments(), formatters, languages }); if (errors.length) throw new Error(errors.join('; '));
      invalidate(); config.formatters = clone(formatters); config.languages = clone(languages); updateControls();
    },
    async format(id = active) {
      if (disposed || pending) return false;
      const state = documents.get(id); if (!state || state.document.editable === false) return false;
      const binding = bindingFor(state.document, config); if (!binding) return false;
      const formatter = config.formatters.find(f => f.id === binding.provider);
      const request = { contract_version: 1, instance, formatter: formatter.id, formatter_version: formatter.formatter_version,
        generation, request_id: ++requestId, target: id, revisions: [...documents.values()].map(s => ({ id: s.document.id, revision: s.revision })),
        input: { target: clone(state.document), context: publicDocuments().filter(d => d.id !== id), options: clone(binding.options || {}) } };
      let worker;
      try { worker = new Worker(new URL(formatter.worker, new URL(config.assetBase || document.baseURI, document.baseURI)), { type: 'module' }); }
      catch (error) { fail(error.message); return false; }
      say('Formatting…'); formatButton.disabled = true;
      return new Promise(resolve => {
        const finish = (ok, error) => {
          if (pending?.worker !== worker) return;
          clearTimeout(pending.timer); pending = null; worker.terminate(); formatButton.disabled = false;
          if (error) fail(error); else say(ok ? 'Formatted.' : 'Already formatted.'); resolve(ok);
        };
        const timer = setTimeout(() => finish(false, 'time limit exceeded; use Format to retry.'), finiteTimeout(config.formatTimeout));
        pending = { worker, timer, resolve };
        worker.onerror = event => { event.preventDefault(); finish(false, event.message || 'worker error'); };
        worker.onmessage = event => {
          if (pending?.worker !== worker || disposed) return;
          const reply = event.data;
          const echoed = reply?.request;
          const fields = ['contract_version','instance','formatter','formatter_version','generation','request_id','target'];
          if (!echoed || fields.some(key => echoed[key] !== request[key]) || JSON.stringify(echoed.revisions) !== JSON.stringify(request.revisions)) return finish(false, 'invalid response identity or protocol.');
          if (generation !== request.generation || request.revisions.some(r => documents.get(r.id)?.revision !== r.revision)) return finish(false, 'inputs changed.');
          if (reply.error && typeof reply.error.code === 'string' && typeof reply.error.message === 'string') return finish(false, `${reply.error.code}: ${reply.error.message}`);
          if (!reply.output || typeof reply.output.text !== 'string' || reply.error) return finish(false, 'malformed response.');
          // Complete this worker before the ordinary edit invalidates requests.
          clearTimeout(pending.timer); pending = null; worker.terminate(); formatButton.disabled = false;
          const changed = change(id, reply.output.text, null, 'format'); say(changed ? 'Formatted.' : 'Already formatted.'); resolve(changed);
        };
        try { worker.postMessage(request); } catch (error) { finish(false, error.message); }
      });
    },
    focus() { if (!disposed) adapter.focus(); },
    dispose() {
      if (disposed) return; invalidate(); disposed = true; adapter.dispose(); wrapper.remove();
      delete element.telescopeEditor;
    },
  };
  selector.addEventListener('change', () => api.selectDocument(selector.value));
  formatButton.addEventListener('click', () => api.format());
  element.replaceChildren(wrapper); refreshOptions(); element.telescopeEditor = api;
  return api;
}

/** Install in a consumer worker around its compiled Formatter implementation.
 * The handler computes a target document's text and never receives editor state.
 */
export function installFormatterWorker(handler, scope = globalThis) {
  scope.onmessage = event => {
    const request = event.data;
    try {
      const output = handler(request.input);
      if (output && typeof output.then === 'function') throw new Error('Formatter must be synchronous');
      scope.postMessage({ request, output });
    } catch (error) {
      scope.postMessage({ request, error: { code: typeof error.code === 'string' ? error.code : 'formatter', message: String(error.message || error) } });
    }
  };
}

export async function mountEditors(root = document) {
  for (const element of root.querySelectorAll('[data-telescope-editor]')) {
    if (element.telescopeEditor) continue;
    try {
      const encoded = element.dataset.config || element.querySelector('[data-editor-config]')?.textContent;
      await mountEditor(element, JSON.parse(encoded));
    } catch (error) {
      const status = document.createElement('p'); status.setAttribute('role', 'status'); status.textContent = `Editor unavailable: ${error.message}`; element.append(status);
    }
  }
}
if (typeof document !== 'undefined') {
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', () => mountEditors(), { once: true });
  else queueMicrotask(() => mountEditors());
}
