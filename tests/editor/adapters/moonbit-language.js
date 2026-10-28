// Original consumer replacement mode, Apache-2.0.
export function createLanguages({ StreamLanguage }) {
  const mode = StreamLanguage.define({
    name: 'consumer-moonbit',
    token(stream) {
      if (stream.eatSpace()) return null;
      if (stream.match(/custom\b/)) return 'keyword';
      stream.next(); return null;
    },
  });
  return { moonbit: mode, mbt: mode };
}
