///|
fn input(
  language~ : String = "note",
  body~ : String = "hello",
  route~ : String = "/demo/",
) -> @extensions.RenderInput {
  {
    source: "docs/demo.md",
    route,
    base_path: "/example/",
    body,
    language,
    ordinal: 1,
  }
}

///|
fn render(
  input : @extensions.RenderInput,
) -> Result[@extensions.RenderOutput, @extensions.AdapterError] {
  Ok({
    body_html: "<aside><h2 id=\"note\">Note</h2><p>Reviewed consumer output</p></aside>",
    text: input.body,
    headings: [{ id: "note", text: "Note", level: 2, }],
    assets: [],
    problems: [],
  })
}

///|
fn fence(
  id~ : String = "notes",
  version~ : Int32 = 1,
  label~ : String = "note",
) -> @extensions.FenceAdapter {
  { id, contract_version: version, labels: [label], render, }
}

///|
fn island(
  id~ : String = "demo-island",
  route~ : String = "/demo/",
  mount~ : String = "demo-mount",
) -> @extensions.IslandAdapter {
  {
    id,
    contract_version: 1,
    routes: [route],
    mount_id: mount,
    script: { path: "assets/demo.js", media_type: "text/javascript", },
    stylesheet: Some({ path: "assets/demo.css", media_type: "text/css", }),
    fallback_html: "<p>Readable without JavaScript.</p>",
  }
}

///|
test "consumer fence callback and escaped unknown fence baseline" {
  let registry : @extensions.Registry = {
    pages: [],
    fences: [fence()],
    islands: [],
  }
  let result = @extensions.render_fence(registry, input()).unwrap()
  assert_true(result.body_html.contains("Reviewed consumer output"))
  assert_eq(result.headings[0].id, "note")
  let unknown = @extensions.render_fence(
    registry,
    input(language="unknown\" onclick=\"x", body="<script>&\"'"),
  ).unwrap()
  assert_eq(
    unknown.body_html,
    "<pre><code class=\"language-unknown&quot; onclick=&quot;x\">&lt;script&gt;&amp;&quot;&#39;</code></pre>",
  )
  assert_true(
    unknown.body_html.contains("language-unknown&quot; onclick=&quot;x"),
  )
  assert_false(unknown.body_html.contains("<script>"))
  assert_eq(unknown.text, "<script>&\"'")
}

///|
test "duplicate ids versions labels and routes fail before callback" {
  let calls : Array[String] = []
  let dangerous : @extensions.FenceAdapter = {
    id: "same",
    contract_version: 99,
    labels: ["note"],
    render: arg => {
      calls.push(arg.body)
      render(arg)
    },
  }
  let registry : @extensions.Registry = {
    pages: [
      { id: "page-one", contract_version: 1, route: "/demo/", render, },
      { id: "page-two", contract_version: 1, route: "/demo/", render, },
    ],
    fences: [fence(id="same"), dangerous],
    islands: [],
  }
  let report = @extensions.validate_registry(registry)
    .map(p => p.message)
    .join("\n")
  assert_true(report.contains("duplicate adapter id"))
  assert_true(report.contains("supported version is 1"))
  assert_true(report.contains("duplicate fence label note"))
  assert_true(report.contains("duplicate page route /demo/"))
  assert_true(@extensions.render_fence(registry, input()) is Err(_))
  assert_eq(calls.length(), 0)
}

///|
test "page exact route and island explicit route preserve no-JS fallback" {
  let registry : @extensions.Registry = {
    pages: [{ id: "demo-page", contract_version: 1, route: "/demo/", render, }],
    fences: [],
    islands: [island()],
  }
  assert_eq(@extensions.validate_registry(registry).length(), 0)
  assert_true(@extensions.render_page(registry, input()).unwrap() is Some(_))
  assert_true(
    @extensions.render_page(registry, input(route="/docs/")).unwrap() is None,
  )
  assert_eq(@extensions.islands_for_route(registry, "/docs/").length(), 0)
  let active = @extensions.islands_for_route(registry, "/demo/")
  assert_eq(active.length(), 1)
  assert_true(active[0].fallback_html.contains("Readable without JavaScript"))
}

///|
test "island duplicate mount invalid assets and absent fallback diagnosed" {
  let bad : @extensions.IslandAdapter = {
    ..island(id="bad"),
    script: { path: "../escape.js", media_type: "text/html", },
    fallback_html: "",
  }
  let registry : @extensions.Registry = {
    pages: [],
    fences: [],
    islands: [island(), bad],
  }
  let report = @extensions.validate_registry(registry)
    .map(p => p.message)
    .join("\n")
  assert_true(report.contains("duplicate island mount /demo/#demo-mount"))
  assert_true(report.contains("asset path must be normalized and relative"))
  assert_true(report.contains("requires readable fallback_html"))
  assert_true(report.contains("JavaScript media_type"))
}

///|
test "adapter errors carry provider source and stage" {
  let registry : @extensions.Registry = {
    pages: [],
    islands: [],
    fences: [
      {
        ..fence(),
        render: _ => {
          Err({ stage: "parse", message: "invalid consumer grammar", })
        },
      },
    ],
  }
  match @extensions.render_fence(registry, input()) {
    Ok(_) => fail("expected error")
    Err(problems) => {
      assert_eq(problems[0].file, "docs/demo.md")
      assert_true(
        problems[0].message.contains(
          "adapter notes at parse: invalid consumer grammar",
        ),
      )
    }
  }
}

///|
test "invalid callback outputs report assets and duplicate heading facts" {
  let registry : @extensions.Registry = {
    pages: [],
    islands: [],
    fences: [
      {
        ..fence(),
        render: _ => {
          Ok({
            body_html: "<p>reviewed</p>",
            text: "reviewed",
            headings: [
              { id: "same", text: "A", level: 2, },
              { id: "same", text: "B", level: 7, },
            ],
            assets: [{ path: "/outside.css", media_type: "text/css", }],
            problems: [],
          })
        },
      },
    ],
  }
  match @extensions.render_fence(registry, input()) {
    Ok(_) => fail("expected error")
    Err(problems) => {
      assert_true(problems.all(p => p.file == "docs/demo.md"))
      let report = problems.map(p => p.message).join("\n")
      assert_true(report.contains("asset path must be normalized and relative"))
      assert_true(
        report.contains(
          "adapter notes at render: invalid or duplicate heading same",
        ),
      )
    }
  }
}
