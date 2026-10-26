///|
fn manifest_json(entries : String) -> String {
  "{\"schema_version\":1,\"producer\":{\"project\":\"Fixture\",\"ref\":\"abc\",\"pipeline\":\"checked\"},\"entries\":[" +
  entries +
  "]}"
}

///|
fn implemented(id : String, family~ : String = "sequence") -> String {
  "{\"id\":\"\{id}\",\"family\":\"\{family}\",\"title\":\"Review <flow>\",\"status\":\"implemented\",\"sources\":[{\"path\":\"sources/review.mmd\",\"media_type\":\"text/plain\"}],\"preview\":{\"path\":\"previews/review.svg\",\"media_type\":\"image/svg+xml\"},\"player\":{\"path\":\"players/review.html\",\"media_type\":\"text/html\"},\"companions\":[{\"path\":\"players/player.js\",\"media_type\":\"text/javascript\"}]}"
}

///|
fn planned(id : String, family : String) -> String {
  "{\"id\":\"\{id}\",\"family\":\"\{family}\",\"title\":\"Planned example\",\"status\":\"planned\"}"
}

///|
fn errors(text : String) -> String {
  match @gallery.parse_manifest(text, source="fixture.json") {
    Ok(_) => "unexpected success"
    Err(problems) => problems.map(p => p.file + ":" + p.message).join("\n")
  }
}

///|
test "implemented and planned pages preserve status base paths escaping and declared companions" {
  let manifest = @gallery.parse_manifest(
    manifest_json(implemented("review") + "," + planned("dot", "DOT")),
  ).unwrap()
  for base in ["/", "/example/"] {
    let output = @gallery.plan(manifest, base).unwrap()
    assert_eq(output.pages.length(), 3)
    assert_eq(output.pages[0].route, "/gallery/")
    let detail = output.pages[1].body_html
    assert_true(detail.contains("Review &lt;flow&gt;"))
    assert_true(
      detail.contains("src=\"\{base}gallery/artifacts/previews/review.svg\""),
    )
    assert_true(detail.contains("download>sources/review.mmd"))
    assert_true(detail.contains("\{base}gallery/artifacts/players/review.html"))
    assert_true(detail.contains("background:#fff"))
    let planned_body = output.pages[2].body_html
    assert_true(planned_body.contains("Planned"))
    assert_false(planned_body.contains("<img"))
    assert_false(planned_body.contains("href=\"\{base}gallery/artifacts/"))
    assert_eq(output.copies.length(), 4)
    assert_true(
      output.copies.any(copy => {
        copy.output_path == "gallery/artifacts/players/player.js"
      }),
    )
  }
}

///|
test "all seven implemented family labels and planned families are data" {
  let families = [
    "sequence", "BPMN", "swimlane", "regex", "EBNF", "JSON", "YAML",
  ]
  let entries = families.mapi((i, family) => {
    implemented("example-\{i}", family~)
  })
  for
    pair in [
      ("plantuml", "general PlantUML"),
      ("dot", "DOT"),
      ("drawio", "Draw.io"),
    ] {
    entries.push(planned(pair.0, pair.1))
  }
  let manifest = @gallery.parse_manifest(manifest_json(entries.join(","))).unwrap()
  let output = @gallery.plan(manifest, "/example/").unwrap()
  for family in families {
    assert_true(output.pages[0].body_html.contains(family))
  }
  assert_eq(output.pages.length(), 11)
  // Shared files have one output copy, even across several entries.
  assert_eq(output.copies.length(), 4)
  assert_eq(manifest.entries[7].status, @gallery.Planned)
}

///|
test "missing required references aggregate source and SVG failures" {
  let text = manifest_json(
    "{\"id\":\"missing\",\"family\":\"sequence\",\"title\":\"Missing\",\"status\":\"implemented\"}",
  )
  let report = errors(text)
  assert_true(report.contains("fixture.json"))
  assert_true(report.contains("requires sources"))
  assert_true(report.contains("requires SVG preview"))
}

///|
test "schema status duplicate id and reserved route rejected" {
  assert_true(
    errors(
      manifest_json(planned("ok", "future")).replace(
        old="schema_version\":1",
        new="schema_version\":2",
      ),
    ).contains("supported version is 1"),
  )
  assert_true(
    errors(
      manifest_json(planned("ok", "future")).replace(
        old="planned",
        new="experimental",
      ),
    ).contains("must be implemented or planned"),
  )
  assert_true(
    errors(manifest_json(planned("same", "one") + "," + planned("same", "two"))).contains(
      "duplicate id and output route",
    ),
  )
  for id in ["artifacts", "../escape", "UPPER", "bad_id", "-start", "end-"] {
    assert_true(
      errors(manifest_json(planned(id, "future"))).contains("id must use"),
    )
  }
}

///|
test "absolute traversal encoded and nonnormalized artifact paths rejected" {
  for
    path in [
      "../secret", "/absolute.svg", "a/../b.svg", "a/./b.svg", "a//b.svg", "C:/b.svg",
      "a\\b.svg", "%2e%2e/secret", "a.svg#fragment", "a.svg?query", "a/", "a b.svg",
    ] {
    let text = manifest_json(implemented("review")).replace(
      old="previews/review.svg",
      new=path.replace(old="\\", new="\\\\"),
    )
    assert_true(errors(text).contains("must be normalized and relative"))
  }
}

///|
test "planned artifact lies and preview media mismatches rejected" {
  let fake = implemented("review").replace(old="implemented", new="planned")
  assert_true(
    errors(manifest_json(fake)).contains(
      "planned entry must not declare runnable artifacts",
    ),
  )
  assert_true(
    errors(
      manifest_json(implemented("review")).replace(
        old="image/svg+xml",
        new="image/png",
      ),
    ).contains("must have media_type image/svg+xml"),
  )
  assert_true(
    errors(
      manifest_json(implemented("review")).replace(
        old="text/html",
        new="text/plain",
      ),
    ).contains("player players/review.html must have media_type text/html"),
  )
}

///|
test "artifact parent file collisions and conflicting shared media types rejected" {
  let collision = implemented("review").replace(
    old="sources/review.mmd",
    new="players",
  )
  assert_true(
    errors(manifest_json(collision)).contains("artifact output collision"),
  )
  let second = implemented("second").replace(
    old="text/plain",
    new="application/json",
  )
  assert_true(
    errors(manifest_json(implemented("first") + "," + second)).contains(
      "conflicting media types",
    ),
  )
}

///|
test "invalid JSON malformed entries optional fields and base paths fail" {
  assert_true(errors("{").contains("invalid JSON"))
  assert_true(errors("[]").contains("must be an object"))
  assert_true(errors(manifest_json("false")).contains("must be an object"))
  let malformed = implemented("review").replace(
    old="\"sources\":[{",
    new="\"sources\":false,\"ignored\":[{",
  )
  assert_true(errors(manifest_json(malformed)).contains("must be an array"))
  let manifest = @gallery.parse_manifest(manifest_json(planned("ok", "future"))).unwrap()
  for base in ["", "relative/", "/bad//", "/../", "//", "/bad/#/"] {
    assert_true(@gallery.plan(manifest, base) is Err(_))
  }
}

///|
test "producer is optional informational provenance with shape validation" {
  let text = "{\"schema_version\":1,\"entries\":[" +
    planned("future", "DOT") +
    "]}"
  let manifest = @gallery.parse_manifest(text).unwrap()
  assert_eq(manifest.producer, None)
  assert_true(
    @gallery.plan(manifest, "/").unwrap().pages[0].body_html.contains("Gallery"),
  )
  assert_true(
    errors(text.replace(old="\"entries\"", new="\"producer\":{},\"entries\"")).contains(
      "producer.project",
    ),
  )
}
