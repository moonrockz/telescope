// Lexical MoonBit mode for CodeMirror. The pinned Smithy static scanner and
// stream-language integration are behavior references. See UPSTREAM.md.
import { StreamLanguage } from '@codemirror/language';

const keywords = new Set(('as async break catch const continue defer derive else enum extern fn for guard if impl import in is let loop match mut noraise priv pub raise readonly return struct suberror test trait try type typealias using while with').split(' '));
const atoms = new Set(['true', 'false']);
export const moonbitParser = {
  name: 'moonbit',
  startState() { return { commentDepth: 0 }; },
  token(stream, state) {
    if (state.commentDepth) {
      while (!stream.eol()) {
        if (stream.match('/*')) state.commentDepth++;
        else if (stream.match('*/')) { if (--state.commentDepth === 0) break; }
        else stream.next();
      }
      return 'comment';
    }
    if (stream.eatSpace()) return null;
    if (stream.match('///')) { stream.skipToEnd(); return 'docComment'; }
    if (stream.match('//')) { stream.skipToEnd(); return 'comment'; }
    if (stream.match('/*')) { state.commentDepth = 1; return 'comment'; }
    if (stream.match('#|')) { stream.skipToEnd(); return 'string'; }
    if (stream.match(/#(?:[A-Za-z_][\w]*)(?:\([^\n]*\)?)?/)) return 'meta';
    if (stream.match(/@[A-Za-z_][\w]*(?:\/[A-Za-z_][\w]*)*/)) return 'namespace';
    const quote = stream.peek();
    if (quote === '"' || quote === "'") {
      stream.next();
      let escaped = false;
      while (!stream.eol()) {
        const c = stream.next();
        if (!escaped && c === quote) break;
        escaped = !escaped && c === '\\';
      }
      // A live unterminated quote is confined to its line. Completing it causes
      // ordinary incremental re-tokenization without retaining a stale state.
      return 'string';
    }
    if (stream.match(/(?:0[xX][\da-fA-F_]+|0[bB][01_]+|0[oO][0-7_]+|\d[\d_]*(?:\.\d[\d_]*)?(?:[eE][+-]?\d[\d_]*)?)(?:[uUlLfFdD]|UL|L)?/)) return 'number';
    const word = stream.match(/[A-Za-z_][\w]*/);
    if (word) {
      if (keywords.has(word[0])) return 'keyword';
      if (atoms.has(word[0])) return 'atom';
      if (/^[A-Z]/.test(word[0])) return 'typeName';
      return 'variableName';
    }
    if (stream.match(/[-+*\/%=<>!&|^~?:]+/)) return 'operator';
    stream.next();
    return null;
  },
  languageData: { commentTokens: { line: '//', block: { open: '/*', close: '*/' } } },
};
export const moonbitLanguage = StreamLanguage.define(moonbitParser);
