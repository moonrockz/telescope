///|
pub(all) struct Page {
  source : String
  route : String
  kind : Kind
  title : String
  summary : String
  date : String
  authors : Array[String]
  order : Int32
  /// A full HTML document: written as it is, without the layout.
  full : Bool
  html : String
  ids : Array[String]
  headings : Array[String]
  /// The "On this page" rail; empty for a full page.
  toc : Array[@model.TocEntry]
  text : String
  /// `status: proposed`: the page shows the banner "Proposed — not implemented".
  proposed : Bool
}

///|
pub(all) struct Prepared {
  pages : Array[Page]
  /// Files to copy: the path below the output directory, then the repository path.
  copies : Array[(String, String)]
  warnings : Array[@model.Problem]
}

///|
/// Optional tutorial composition, kept separate from existing public records.
pub(all) struct TutorialSite {
  pages : Array[Page]
  assets : Array[(String, String)]
  navigation : Array[(String, String)]
}

///|
pub let no_tutorials : TutorialSite = { pages: [], assets: [], navigation: [], }

///|
fn file_stem(path : String) -> String {
  let name = match path.rev_find("/") {
    Some(i) => path[i + 1:].to_owned()
    None => path
  }
  @model.strip_extension(name)
}

///|
/// Build one page, or `None` for a skipped draft. Problems go to `problems`.
fn build_page(
  source : SourceFile,
  kind : Kind,
  _main_build : Bool,
  problems : Array[@model.Problem],
  warnings : Array[@model.Problem],
  config : @model.SiteConfig,
  providers : @extensions.Registry,
  assets : Array[(String, String)],
) -> Page? {
  let path = source.path
  guard source.text is Some(text) else {
    problems.push(@model.problem(path, "content file has no text"))
    return None
  }
  let fm = @content.parse_front_matter(path, text) catch {
    @model.Invalid(found) => {
      problems.append(found)
      return None
    }
  }
  if fm.flag("draft") {
    warnings.push(@model.problem(path, "draft page skipped"))
    return None
  }
  let is_html = path.has_suffix(".html")
  let full = is_html && fm.body.to_lower().contains("<html")
  let doc = if is_html {
    @content.analyse_html(fm.body)
  } else {
    @markdown.render_markdown(path, fm.body) catch {
      @model.Invalid(found) => {
        problems.append(found)
        return None
      }
    }
  }
  // The building blocks of the docs style are HTML passes over the rendered Markdown or HTML body.
  let html = if full { fm.body } else { @content.render_callouts(doc.html) }
  let proposed = match fm.text("status") {
    None => false
    Some("proposed") => true
    Some(value) => {
      problems.push(
        @model.problem(
          path,
          "unknown `status` value `\{value}`: the only value is `proposed`",
        ),
      )
      false
    }
  }
  let title = match (fm.text("title"), doc.title) {
    (Some(t), _) => t
    (None, Some(t)) => t
    (None, None) => file_stem(path)
  }
  let summary = fm.text("summary").unwrap_or(doc.summary)
  let order = match fm.text("order") {
    Some(value) =>
      @string.parse_int(value) catch {
        _ => {
          problems.push(@model.problem(path, "`order` must be a whole number"))
          1000
        }
      }
    None => 1000
  }
  let mut date = ""
  let mut authors = []
  let route = match kind {
    Doc(rel) => @model.doc_route(rel)
    Package(name) => @model.package_route(name)
    PackagePart(name, sub) => @model.package_route(name + "/" + sub)
    Landing => "/"
    Article(file) => {
      let parts = @model.article_parts(file)
      if parts is None {
        problems.push(
          @model.problem(
            path, "articles file name must be `YYYY-MM-DD-slug.md` or `.html`, with a real date and a slug of a-z, 0-9 and single `-`",
          ),
        )
      }
      if fm.text("title") is None {
        problems.push(@model.problem(path, "article needs `title`"))
      }
      authors = fm.list("authors")
      if authors.is_empty() {
        problems.push(@model.problem(path, "article needs `authors`"))
      }
      match (fm.text("date"), parts) {
        (None, _) => problems.push(@model.problem(path, "article needs `date`"))
        (Some(d), Some((file_date, _))) if d != file_date =>
          problems.push(
            @model.problem(
              path,
              "`date` \{d} does not match the file name date \{file_date}",
            ),
          )
        _ => ()
      }
      guard parts is Some((file_date, slug)) else { return None }
      date = file_date
      @model.article_route(slug)
    }
    Forbidden | Other => return None
  }
  let html = if full {
    html
  } else {
    render_fences(path, route, config, providers, html, problems, assets)
  }
  let doc = if full { doc } else { @content.analyse_html(html) }
  Some({
    source: path,
    route,
    kind,
    title,
    summary,
    date,
    authors,
    order,
    full,
    html,
    // Providers can add SVG symbol IDs; anchors come from the final body.
    ids: @content.ids_in(html),
    headings: doc.headings.map(h => h.text),
    toc: if full {
      []
    } else {
      toc_entries(doc.headings)
    },
    text: doc.text,
    proposed,
  })
}

///|
/// Routes the generator writes that no source file gives.
let generated_routes : Array[String] = [
  "/", "/docs/", "/articles/", "/articles/atom.xml", "/search-index.json",
]

///|
/// Parse, render and check every source file. Raises all problems together.
pub fn prepare(
  config : @model.SiteConfig,
  sources : Array[SourceFile],
  main_build~ : Bool,
  api~ : ApiSite = no_api,
  providers~ : @extensions.Registry = @extensions.empty_registry(),
  external_routes~ : Array[String] = [],
  tutorials~ : TutorialSite = no_tutorials,
) -> Prepared raise @model.Invalid {
  let problems : Array[@model.Problem] = @extensions.validate_registry(
    providers,
  )
  let warnings : Array[@model.Problem] = []
  let pages : Array[Page] = tutorials.pages.copy()
  let assets : Array[(String, String)] = tutorials.assets.copy()
  for page in tutorials.pages {
    if generated_routes.contains(page.route) ||
      external_routes.contains(page.route) {
      problems.push(
        @model.problem(
          page.source,
          "tutorial route `\{page.route}` collides with a generated route",
        ),
      )
    }
  }
  for source in sources {
    if tutorials.pages.iter().any(page => page.source == source.path) {
      continue
    }
    if !@model.relative_path(source.path) {
      problems.push(
        @model.problem(
          source.path,
          "source path must be a normalized relative path",
        ),
      )
      continue
    }
    let kind = classify(source.path, config)
    match kind {
      Forbidden =>
        problems.push(
          @model.problem(
            source.path,
            "forbidden path: agent specs, plans and ledgers live in beads",
          ),
        )
      Other => ()
      _ =>
        if build_page(
            source, kind, main_build, problems, warnings, config, providers, assets,
          )
          is Some(page) {
          // A sub-package page listed in `chapters` takes its position there as its order.
          let order = match kind {
            PackagePart(name, sub) =>
              config.chapter_order(name, sub).unwrap_or(page.order)
            _ => page.order
          }
          pages.push({ ..page, order, })
        }
    }
  }
  if problems.is_empty() {
    for adapter in providers.pages {
      let source = "adapter:" + adapter.id
      match
        @extensions.render_page(providers, {
          source,
          route: adapter.route,
          base_path: config.base_path,
          body: "",
          language: "",
          ordinal: 0,
        }) {
        Err(found) => problems.append(found)
        Ok(None) => ()
        Ok(Some(output)) => {
          problems.append(output.problems)
          for asset in output.assets {
            assets.push((asset.path, asset.path))
          }
          let doc = @content.analyse_html(output.body_html)
          pages.push({
            source,
            route: adapter.route,
            kind: Other,
            title: doc.title.unwrap_or(adapter.id),
            summary: doc.summary,
            date: "",
            authors: [],
            order: 1000,
            full: false,
            html: doc.html,
            ids: doc.ids,
            headings: doc.headings.map(h => h.text),
            toc: toc_entries(doc.headings),
            text: if output.text == "" {
              doc.text
            } else {
              output.text
            },
            proposed: false,
          })
        }
      }
    }
  }
  // Every chapter in `site.json` needs a page.
  for entry in config.chapters {
    for sub in entry.chapters {
      let found = pages.iter().any(p => p.kind == PackagePart(entry.name, sub))
      if !found {
        problems.push(
          @model.problem(
            "site/site.json",
            "chapter `\{sub}` of package `\{entry.name}` in site/site.json has no README.md or README.mbt.md",
          ),
        )
      }
    }
  }
  // Every package in `site.json` needs a README.
  for name in config.packages {
    let candidates = [
      "pkgs/\{name}/README.md",
      "pkgs/\{name}/README.mbt.md",
      "apps/\{name}/README.md",
      "apps/\{name}/README.mbt.md",
    ]
    let found = sources.iter().any(s => candidates.contains(s.path))
    if !found {
      problems.push(
        @model.problem(
          "site/site.json",
          "package `\{name}` in site/site.json has no README.md or README.mbt.md in pkgs/\{name}/ or apps/\{name}/",
        ),
      )
    }
  }
  // A directory may hold one README kind; both would give one route two sources.
  let refused : Array[String] = []
  for source in sources {
    if readme_dir(source.path) is Some(dir) &&
      source.path.has_suffix("/README.md") &&
      sources.iter().any(s => s.path == dir + "/README.mbt.md") &&
      !(classify(source.path, config) is Other) {
      problems.push(
        @model.problem(
          source.path,
          "\{dir} has both README.md and README.mbt.md",
        ),
      )
      refused.push(source.path)
      refused.push(dir + "/README.mbt.md")
    }
  }
  // A route below a version tree segment would collide with a tree of the deploy (design D22).
  for page in pages {
    if @model.reserved_route(page.route) {
      problems.push(
        @model.problem(
          page.source,
          "route `\{page.route}` starts with a reserved version segment (`v`, `next` or `latest`)",
        ),
      )
    }
  }
  // Duplicate routes.
  let owners : Map[String, String] = Map([])
  let unique : Array[Page] = []
  for page in pages {
    match owners.get(page.route) {
      Some(first) =>
        // The both-kinds problem already names this pair.
        if !(refused.contains(first) && refused.contains(page.source)) {
          problems.push(
            @model.problem(
              page.source,
              "route `\{page.route}` is also written by `\{first}`",
            ),
          )
        }
      None => {
        owners.set(page.route, page.source)
        unique.push(page)
      }
    }
  }
  // Links.
  let routes : Map[String, String] = Map([])
  for page in unique {
    routes.set(page.source, page.route)
  }
  for page in unique {
    for island in @extensions.islands_for_route(providers, page.route) {
      assets.push((island.script.path, island.script.path))
      if island.stylesheet is Some(asset) {
        assets.push((asset.path, asset.path))
      }
    }
  }
  let site_routes = generated_routes +
    external_routes +
    unique.map(p => p.route) +
    assets.map(asset => "/" + asset.0)
  let ctx = LinkContext::new(
    config,
    routes,
    sources.map(s => s.path) + assets.map(a => a.1),
    site_routes,
    api_anchors=api.anchors(),
  )
  let anchors : Array[(String, String, String)] = []
  let copies : Array[(String, String)] = assets
  let linked = unique.map(page => {
    let html = @content.map_urls(page.html, url => {
      let r = resolve(ctx, page.source, url)
      if r.problem is Some(message) {
        problems.push(@model.problem(page.source, message))
      }
      if r.anchor is Some((route, anchor)) {
        anchors.push((page.source, route, anchor))
      }
      if r.copy is Some(file) && !copies.contains(file) {
        copies.push(file)
      }
      r.url
    })
    { ..page, html, }
  })
  // Anchors on pages from source files. Generated routes have no anchors to check.
  let ids : Map[String, Array[String]] = Map([])
  for page in linked {
    ids.set(page.route, page.ids)
  }
  for check in anchors {
    let (from, route, anchor) = check
    if ids.get(route) is Some(found) && !found.contains(anchor) {
      problems.push(
        @model.problem(from, "anchor `#\{anchor}` does not exist on `\{route}`"),
      )
    }
  }
  // Sidebar groups.
  if config.nav is Some(groups) {
    for message in build_grouped_nav(groups, nav_entries(linked)).1 {
      problems.push(@model.problem("site/site.json", message))
    }
  }
  if problems.length() > 0 {
    raise @model.Invalid(problems)
  }
  { pages: linked, copies, warnings, }
}

///|
/// The pages of the docs sidebar: docs and package pages, except `/docs/` itself.
fn nav_entries(pages : Array[Page]) -> Array[NavEntry] {
  pages.filter_map(p => {
    let source = match p.kind {
      Doc(rel) => rel
      Package(name) => "packages/\{name}/README.md"
      PackagePart(name, sub) => "packages/\{name}/\{sub}/README.md"
      _ => return None
    }
    if p.full || p.route == "/docs/" {
      None
    } else {
      Some({
        route: p.route,
        source,
        title: p.title,
        order: p.order,
        proposed: p.proposed,
      })
    }
  })
}
