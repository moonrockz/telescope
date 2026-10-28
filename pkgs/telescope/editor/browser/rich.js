import { EditorState, Compartment } from '@codemirror/state';
import { EditorView, keymap, lineNumbers, drawSelection } from '@codemirror/view';
import { defaultKeymap, indentWithTab } from '@codemirror/commands';
import { syntaxHighlighting, HighlightStyle, StreamLanguage } from '@codemirror/language';
import { tags } from '@lezer/highlight';
import { moonbitLanguage } from './moonbit.js';

const highlighting = HighlightStyle.define([
  { tag: tags.keyword, class: 'te-token-keyword' },
  { tag: tags.number, class: 'te-token-number' },
  { tag: tags.string, class: 'te-token-string' },
  { tag: tags.comment, class: 'te-token-comment' },
  { tag: tags.meta, class: 'te-token-annotation' },
  { tag: tags.namespace, class: 'te-token-namespace' },
  { tag: tags.typeName, class: 'te-token-type' },
  { tag: tags.atom, class: 'te-token-number' },
]);

export function languageExtension(mode, adapters) {
  if (adapters && Object.hasOwn(adapters, mode)) return adapters[mode];
  return mode === 'moonbit' || mode === 'mbt' ? moonbitLanguage : [];
}

export function createRichAdapter(parent, callbacks, options = {}) {
  const language = new Compartment();
  const editable = new Compartment();
  let quiet = false;
  const extensionFor = mode => languageExtension(mode, options.languageAdapters);
  const view = new EditorView({
    parent,
    state: EditorState.create({
      doc: '',
      extensions: [lineNumbers(), drawSelection(), EditorView.lineWrapping,
        EditorView.contentAttributes.of({ 'aria-label': 'Code editor', spellcheck: 'false' }),
        syntaxHighlighting(highlighting), language.of([]), editable.of(EditorView.editable.of(true)),
        keymap.of([
          { key: 'Mod-z', run: () => callbacks.undo() },
          { key: 'Mod-Shift-z', run: () => callbacks.redo() },
          { key: 'Mod-y', run: () => callbacks.redo() },
          ...defaultKeymap, indentWithTab,
        ]),
        EditorView.updateListener.of(update => {
          if (quiet) return;
          const selection = update.state.selection.main;
          if (update.docChanged) callbacks.change(update.state.doc.toString(), { anchor: selection.anchor, head: selection.head });
          else if (update.selectionSet) callbacks.selection({ anchor: selection.anchor, head: selection.head });
        }),
      ],
    }),
  });
  return {
    show(document, selection, focus = false) {
      quiet = true;
      try {
        view.dispatch({
          changes: { from: 0, to: view.state.doc.length, insert: document.text },
          selection,
          effects: [language.reconfigure(extensionFor(document.language)), editable.reconfigure(EditorView.editable.of(document.editable !== false))],
        });
      } finally { quiet = false; }
      if (focus) view.focus();
    },
    setLanguage(mode) { quiet = true; try { view.dispatch({ effects: language.reconfigure(extensionFor(mode)) }); } finally { quiet = false; } },
    selection(selection) { quiet = true; try { view.dispatch({ selection }); } finally { quiet = false; } },
    focused() { return view.hasFocus; },
    focus() { view.focus(); },
    dispose() { view.destroy(); },
    view,
  };
}

// Inject into declared consumer language factories so extensions use this copy.
export { StreamLanguage };
