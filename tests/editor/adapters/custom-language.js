// Original independent lexical mode, Apache-2.0. CodeMirror is injected by host.
globalThis.customLanguageLoads = (globalThis.customLanguageLoads || 0) + 1;
export function createLanguages({ StreamLanguage }) {
  return {
    'text-demo': StreamLanguage.define({
      name: 'text-demo',
      token(stream) {
        if (stream.eatSpace()) return null;
        if (stream.match(/demo\b/)) return 'keyword';
        if (stream.match(/\d+/)) return 'number';
        stream.next(); return null;
      },
    }),
  };
}
