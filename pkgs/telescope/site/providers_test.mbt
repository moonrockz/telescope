///|
fn provider_result(html : String) -> @extensions.RenderOutput {
  {
    body_html: html,
    text: "Provider text",
    headings: [],
    assets: [],
    problems: [],
  }
}

///|
async test "explicit providers and route-local islands reach built output" {
  let providers : @extensions.Registry = {
    fences: [
      {
        id: "sample-fence",
        contract_version: 1,
        labels: ["sample"],
        render: input => {
          Ok(
            provider_result(
              "<section id=\"example\">" +
              @content.escape(input.body) +
              "</section>",
            ),
          )
        },
      },
    ],
    pages: [
      {
        id: "workbench",
        contract_version: 1,
        route: "/workbench/",
        render: _ => {
          Ok(provider_result("<h1>Workbench</h1><p>Static content</p>"))
        },
      },
    ],
    islands: [
      {
        id: "controls",
        contract_version: 1,
        routes: ["/workbench/"],
        mount_id: "workbench-controls",
        script: { path: "consumer/controls.js", media_type: "text/javascript", },
        stylesheet: None,
        fallback_html: "<p>Static controls help</p>",
      },
    ],
  }
  let built = @site.build(
    { ..config, packages: [], },
    [
      {
        path: "docs/a.md",
        text: Some(
          "# A\n\n[Jump to rendered symbol](#example)\n\n```sample\n<source>\n```\n",
        ),
      },
    ],
    main_build=true,
    providers~,
  )
  let docs = built.outputs.filter_map(o => {
      match o {
        Text("docs/a/index.html", html) => Some(html)
        _ => None
      }
    })[0]
  assert_true(docs.contains("id=\"example\""))
  assert_true(docs.contains("href=\"#example\""))
  assert_true(docs.contains("&lt;source&gt;"))
  assert_false(docs.contains("controls.js"))
  let workbench = built.outputs.filter_map(o => {
      match o {
        Text("workbench/index.html", html) => Some(html)
        _ => None
      }
    })[0]
  assert_true(workbench.contains("id=\"workbench-controls\""))
  assert_true(workbench.contains("Static controls help"))
  assert_true(workbench.contains("src=\"/m/consumer/controls.js\""))
  assert_true(
    built.outputs
    .iter()
    .any(o => o is Copy("consumer/controls.js", "consumer/controls.js")),
  )
}

///|
test "invalid registry fails before a provider callback executes" {
  let providers : @extensions.Registry = {
    pages: [],
    islands: [],
    fences: [
      {
        id: "invalid",
        contract_version: 2,
        labels: ["test"],
        render: _ => panic(),
      },
    ],
  }
  let problems = try
    @site.prepare({ ..config, packages: [], }, [], main_build=true, providers~)
  catch {
    @model.Invalid(problems) => problems
  } noraise {
    _ => []
  }
  assert_true(
    problems.iter().any(p => p.message.contains("unsupported contract version")),
  )
}

///|
test "host-supplied routes and base-prefixed adapter links are explicit" {
  let prepared = @site.prepare(
    { ..config, packages: [], },
    [
      {
        path: "docs/gallery.md",
        text: Some("# Gallery\n\n[Gallery](/gallery/)\n"),
      },
    ],
    main_build=true,
    external_routes=["/gallery/"],
  )
  assert_true(prepared.pages[0].html.contains("href=\"/m/gallery/\""))
  let missing = try
    @site.prepare(
      { ..config, packages: [], },
      [
        {
          path: "docs/gallery.md",
          text: Some("# Gallery\n\n[Unknown](/workbench/)\n"),
        },
      ],
      main_build=true,
    )
  catch {
    @model.Invalid(problems) => problems
  } noraise {
    _ => []
  }
  assert_true(
    missing.iter().any(p => p.message.contains("no page at site route")),
  )
}

///|
test "repeated fence occurrences provide stable distinct identifier prefixes" {
  let providers : @extensions.Registry = {
    pages: [],
    islands: [],
    fences: [
      {
        id: "diagrams",
        contract_version: 1,
        labels: ["sample", "sample-alias"],
        render: input => {
          Ok(
            provider_result("<svg><g id=\"sample-\{input.ordinal}\"></g></svg>"),
          )
        },
      },
    ],
  }
  let source = "# A\n\n[Second diagram](#sample-2)\n\n```unknown\nsource\n```\n\n```sample\nidentical\n```\n\n```sample-alias\nidentical\n```\n"
  let prepared = @site.prepare(
    { ..config, packages: [], },
    [{ path: "docs/a.md", text: Some(source), }],
    main_build=true,
    providers~,
  )
  assert_true(prepared.pages[0].ids.contains("sample-1"))
  assert_true(prepared.pages[0].ids.contains("sample-2"))
  assert_true(prepared.pages[0].html.contains("href=\"#sample-2\""))
}
