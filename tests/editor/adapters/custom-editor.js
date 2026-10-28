// Original independent consumer adapter, Apache-2.0. No tutorial imports.
globalThis.customEditorLoads = (globalThis.customEditorLoads || 0) + 1;
export function createAdapter(parent, callbacks) {
  const input = document.createElement('textarea');
  input.className = 'te-plain custom-text-editor';
  input.setAttribute('aria-label', 'Custom code editor'); input.spellcheck = false;
  parent.append(input);
  const selection = () => ({ anchor: input.selectionDirection === 'backward' ? input.selectionEnd : input.selectionStart,
    head: input.selectionDirection === 'backward' ? input.selectionStart : input.selectionEnd });
  const select = value => input.setSelectionRange(Math.min(value.anchor, value.head), Math.max(value.anchor, value.head), value.head < value.anchor ? 'backward' : 'forward');
  input.addEventListener('input', () => callbacks.change(input.value, selection()));
  input.addEventListener('select', () => callbacks.selection(selection()));
  input.addEventListener('click', () => callbacks.selection(selection()));
  input.addEventListener('keyup', () => callbacks.selection(selection()));
  input.addEventListener('keydown', event => {
    if (!(event.ctrlKey || event.metaKey)) return;
    const key = event.key.toLowerCase();
    if (key === 'z' || key === 'y') { event.preventDefault(); (key === 'y' || event.shiftKey ? callbacks.redo : callbacks.undo)(); }
  });
  return {
    show(doc, selection, focus = false) { input.value = doc.text; input.readOnly = doc.editable === false; select(selection); if (focus) input.focus(); },
    setLanguage() {}, selection: select,
    focused: () => document.activeElement === input, focus: () => input.focus(), dispose: () => input.remove(),
  };
}
