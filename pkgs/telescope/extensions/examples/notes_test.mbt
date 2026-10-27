///|
test "consumer-owned note registration executes and keeps island route local" {
  let registry = @examples.registry()
  assert_eq(@extensions.validate_registry(registry).length(), 0)
  let output = @extensions.render_fence(registry, {
    source: "docs/notes.md",
    route: "/docs/notes/",
    base_path: "/",
    body: "<consumer> & <text>",
    language: "consumer-note",
    ordinal: 1,
  }).unwrap()
  assert_true(output.body_html.contains("&lt;consumer&gt; &amp; &lt;text&gt;"))
  assert_eq(@extensions.islands_for_route(registry, "/docs/notes/").length(), 0)
  assert_eq(@extensions.islands_for_route(registry, "/example/").length(), 1)
}
