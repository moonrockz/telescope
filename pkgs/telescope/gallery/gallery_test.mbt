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
    assert_true(detail.contains("id=\"gallery-source-0\""))
    assert_true(
      detail.contains("src=\"\{base}gallery/artifacts/previews/review.svg\""),
    )
    assert_true(detail.contains("download>Download source: sources/review.mmd"))
    assert_true(detail.contains("\{base}gallery/artifacts/players/review.html"))
    assert_true(detail.contains("gallery-light-only"))
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
test "families have grouped navigation and SVG previews have download links" {
  let text = manifest_json(
    implemented("first", family="sequence") +
    "," +
    planned("future", "Future & formats") +
    "," +
    implemented("second", family="sequence"),
  )
  let manifest = @gallery.parse_manifest(
    text.replace_all(
      old="\"preview\":{",
      new="\"preview_dark\":{\"path\":\"previews/dark.svg\",\"media_type\":\"image/svg+xml\"},\"preview\":{",
    ),
  ).unwrap()
  for base in ["/diagrams.mbt/", "/diagrams.mbt/next/"] {
    let output = @gallery.plan(manifest, base).unwrap()
    let index = output.pages[0].body_html
    assert_true(index.contains("aria-label=\"Gallery families\""))
    assert_true(index.contains("href=\"#family-first\""))
    assert_true(index.contains("id=\"family-first\"><h2>sequence</h2>"))
    assert_true(
      index.contains("id=\"family-future\"><h2>Future &amp; formats</h2>"),
    )
    for page in [output.pages[1], output.pages[3]] {
      assert_true(
        page.body_html.contains("href=\"" + base + "gallery/#family-first\""),
      )
      assert_true(
        page.body_html.contains(
          "href=\"" +
          base +
          "gallery/artifacts/previews/review.svg\" download>Download SVG</a>",
        ),
      )
      assert_true(
        page.body_html.contains(
          "href=\"" +
          base +
          "gallery/artifacts/previews/dark.svg\" download>Download dark SVG</a>",
        ),
      )
    }
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

///|
test "optional source text is escaped and cannot alter routes or artifact copies" {
  let manifest = @gallery.parse_manifest(manifest_json(implemented("review"))).unwrap()
  let original = @gallery.plan(manifest, "/example/next/").unwrap()
  let source = "<script>alert('source & only')</script>\r\n\"quoted\"\n"
  let enriched = @gallery.plan(
    manifest,
    "/example/next/",
    source_text=Map::from_array([
      ("sources/review.mmd", source),
      ("undeclared.txt", "must never be displayed"),
    ]),
  ).unwrap()
  assert_eq(enriched.copies, original.copies)
  assert_eq(
    enriched.pages.map(page => page.route),
    original.pages.map(page => page.route),
  )
  for page in enriched.pages {
    let detail = page.body_html
    assert_true(
      detail.contains(
        "&lt;script&gt;alert&#40;&#39;source &amp; only&#39;&#41;&lt;&#47;script&gt;&#13;\n&quot;quoted&quot;\n",
      ),
    )
    assert_false(detail.contains(source))
    assert_false(detail.contains("must never be displayed"))
    assert_false(detail.contains(" hidden"))
  }
  assert_true(original.pages[1].body_html.contains("Inline source unavailable"))
  assert_true(
    original.pages[1].body_html.contains("Download source: sources/review.mmd"),
  )
}

///|
test "every declared source is inspectable or has a labeled download" {
  let text = manifest_json(implemented("review")).replace(
    old="\"sources\":[{",
    new="\"sources\":[{\"path\":\"second.json\",\"media_type\":\"application/json\"},{\"path\":\"binary.bin\",\"media_type\":\"application/octet-stream\"},{",
  )
  let manifest = @gallery.parse_manifest(text).unwrap()
  let plan = @gallery.plan(
    manifest,
    "/",
    source_text=Map::from_array([
      ("sources/review.mmd", "First source"),
      ("second.json", "{\"name\":\"second\"}"),
    ]),
  ).unwrap()
  for page in plan.pages {
    let detail = page.body_html
    assert_true(detail.contains("First source"))
    assert_true(detail.contains("{&quot;name&quot;:&quot;second&quot;}"))
    for path in ["sources/review.mmd", "second.json", "binary.bin"] {
      assert_true(detail.contains("Download source: " + path))
    }
    assert_true(detail.contains("Inline source unavailable"))
  }
}

///|
test "canonical preview text stays inert for link checking and version rewriting" {
  let manifest = @gallery.parse_manifest(manifest_json(implemented("review"))).unwrap()
  let svg = "<svg xmlns=\"http://www.w3.org/2000/svg\"><text>url(#mask) /example/next/ &amp; label</text></svg>\r\n"
  let result = @gallery.plan(
    manifest,
    "/example/",
    source_text=Map([("previews/review.svg", svg)]),
  ).unwrap()
  for page in result.pages {
    assert_true(page.body_html.contains("diagram-viewer__canonical"))
    assert_true(page.body_html.contains("url&#40;#mask&#41;"))
    assert_true(page.body_html.contains("&#47;example&#47;next&#47;"))
    assert_true(page.body_html.contains("&#13;\n</template>"))
    assert_false(page.body_html.contains("<svg"))
  }
}

///|
test "index workbenches have independent entry scoped identities and static source" {
  let manifest = @gallery.parse_manifest(
    manifest_json(
      implemented("first") +
      "," +
      implemented("second") +
      "," +
      planned("future", "planned"),
    ),
  ).unwrap()
  let index = @gallery.plan(
      manifest,
      "/next/",
      source_text=Map([("sources/review.mmd", "graph TD\nA-->B\n")]),
    ).unwrap().pages[0].body_html
  for id in ["first", "second"] {
    assert_true(index.contains("id=\"gallery-card-\{id}-preview\""))
    assert_true(index.contains("id=\"gallery-card-\{id}-source\""))
    assert_true(
      index.contains("aria-labelledby=\"gallery-card-\{id}-source-0\""),
    )
    assert_true(index.contains("id=\"gallery-card-\{id}-source-0\""))
  }
  assert_true(index.contains("graph TD\nA--&gt;B\n"))
  assert_false(index.contains("gallery-card-future-source"))
  assert_false(index.contains(" hidden"))
  assert_false(index.contains("role=\"tab\""))
}
