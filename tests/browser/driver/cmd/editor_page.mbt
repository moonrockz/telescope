///|
/// An ordinary page using the general editor without tutorial configuration.
pub fn editor_page(base : String) -> String {
  let config : Json = {
    "id": "standalone",
    "adapter": "rich",
    "assetBase": base,
    "documents": [
      {
        "id": "main",
        "name": "main.mbt",
        "language": "moonbit",
        "text": "/// MoonBit\n#deprecated\npub fn answer() -> Int {\n  let value = 42\n  let text = \"hello\"\n  #|multiline\n  value\n}\n",
      },
      {
        "id": "second",
        "name": "second.mbt",
        "language": "mbt",
        "text": "let second = 'x'\n",
      },
      {
        "id": "notes",
        "name": "notes.txt",
        "language": "text",
        "text": "first  \nsecond\t",
      },
    ],
    "formatters": [
      {
        "id": "sample.whitespace",
        "contract_version": 1,
        "formatter_version": "1.0.0",
        "languages": ["text"],
        "worker": "consumer/editor-whitespace-worker.js",
        "assets": ["consumer/editor-whitespace-worker.js"],
      },
    ],
    "languages": { "text": { "provider": "sample.whitespace", "options": {} } },
  }
  let encoded = config
    .stringify()
    .replace_all(old="&", new="&amp;")
    .replace_all(old="'", new="&#39;")
    .replace_all(old="<", new="&lt;")
  "<h1>Standalone editor</h1><p>This page has no course or evaluator.</p><link rel=\"stylesheet\" href=\"\{base}assets/editor/editor.css\"><div data-telescope-editor data-config='\{encoded}'><pre>Readable MoonBit source before the editor loads.</pre></div><script type=\"module\" src=\"\{base}assets/editor/editor.js\"></script>"
}
