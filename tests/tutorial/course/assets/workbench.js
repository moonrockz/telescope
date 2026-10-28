// Consumer owns supported modes, encoding, destination and limits.
export function encode({files}) {
  if (files.length !== 1) return {reason:'This workbench supports exactly one file. Current files are preserved.'};
  return {url:'https://example.test/workbench/#' + encodeURIComponent(files[0].text),max_length:2048};
}
