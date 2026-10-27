///|
async test "current compiler metadata renders API anchors, source refs and warnings" {
  let api_package = @model.ApiPackage::parse(
    "fixtures/moon-doc/content-package.json",
    @fs.read_file("fixtures/moon-doc/content-package.json").text(),
  )
  let index = @model.api_index_packages(
    "fixtures/moon-doc/module-index.json",
    @fs.read_file("fixtures/moon-doc/module-index.json").text(),
  )
  assert_true(index.contains(api_package.path))
  assert_true(@model.api_anchors(api_package).contains("Document"))
  let api : @site.ApiSite = {
    commit: "fixture-ref",
    modules: [
      {
        dir: "pkgs/telescope",
        name: "moonrockz/telescope",
        packages: [api_package],
        readmes: Map([]),
      },
    ],
  }
  let built = @site.build(
    { ..config, packages: [], api: ["pkgs/telescope"], },
    [],
    main_build=true,
    api~,
    external_routes=["/gallery/"],
  )
  let html = built.outputs.filter_map(o => {
      match o {
        Text("api/moonrockz/telescope/content/index.html", html) => Some(html)
        _ => None
      }
    })[0]
  assert_true(html.contains("id=\"Document\""))
  assert_true(html.contains("href=\"/m/gallery/\""))
  assert_true(html.contains("id=\"analyse_html\""))
  assert_true(
    html.contains("/blob/fixture-ref/pkgs/telescope/content/document.mbt#L"),
  )
  assert_true(
    built.warnings.iter().any(p => p.message.contains("has no doc prose")),
  )
  let search = api.search_entries()
  assert_true(
    search
    .iter()
    .any(e => e.route == "/api/moonrockz/telescope/content/#Document"),
  )
}
