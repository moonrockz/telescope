///|
pub(all) struct TutorialInput {
  source : String
  root : String
  manifest : @tutorial.Manifest
}

///|
/// Decode the optional manifest separately from the existing SiteConfig record.
pub async fn tutorial_input(
  root : String,
  value : Json,
  out~ : String = "",
) -> TutorialInput? {
  let path = match value {
    Object(fields) =>
      match fields.get("tutorials") {
        None => return None
        Some(String(path)) => path
        _ =>
          raise @model.Invalid([
            @model.problem(
              "site/site.json", "tutorials must name a TOML manifest",
            ),
          ])
      }
    _ => return None
  }
  let real = checked_file(root, path)
  if out != "" && within(out, real) {
    raise @model.Invalid([
      @model.problem(path, "tutorial manifest lies inside output"),
    ])
  }
  let manifest = @tutorial.Manifest::parse(path, @fs.read_file(real).text())
  let input_root = canonical_path(root + "/" + manifest.root)
  guard relative(manifest.root) &&
    within(root, input_root) &&
    @fs.kind(input_root) is Directory &&
    (out == "" || (!within(input_root, out) && !within(out, input_root))) else {
    raise @model.Invalid([
      @model.problem(path, "tutorial root escapes project or overlaps output"),
    ])
  }
  Some({ source: path, root: input_root, manifest, })
}

///|
async fn tutorial_files(
  input : TutorialInput,
  sources : Array[@tutorial.FileSource],
) -> Array[@tutorial.File] {
  let result = []
  for source in sources {
    let path = checked_file(input.root, source.source)
    result.push(@tutorial.File::{
      name: source.name,
      text: @fs.read_file(path).text(),
      language: source.language,
      group: source.group,
    })
  }
  result
}

///|
fn tutorial_page(
  source : String,
  route : String,
  title : String,
  html : String,
  text : String,
) -> @site.Page {
  let doc = @content.analyse_html(html)
  {
    source,
    route,
    kind: Other,
    title,
    summary: doc.summary,
    date: "",
    authors: [],
    order: 1000,
    full: false,
    html,
    ids: doc.ids,
    headings: doc.headings.map(h => h.text),
    toc: [],
    text,
    proposed: false,
  }
}

///|
fn asset_url(
  config : @model.SiteConfig,
  asset_group : String,
  path : String,
) -> String {
  config.href("/assets/tutorial/" + asset_group + "/" + path)
}

///|
/// Static rendering never invokes an evaluator or formatter.
async fn tutorial_site(
  root : String,
  config : @model.SiteConfig,
  input : TutorialInput?,
  policies : Array[@tutorial_check.SourcePolicy],
  guards : Array[TutorialGuard],
) -> @site.TutorialSite {
  guard input is Some(input) else { return @site.no_tutorials }
  let pages = []
  let assets = []
  let navigation = []
  for provider in input.manifest.providers {
    for path in provider.assets {
      ignore(checked_file(input.root, path))
      assets.push(
        (
          "assets/tutorial/" + provider.id + "/" + path,
          input.manifest.root + "/" + path,
        ),
      )
    }
  }
  let editors = input.manifest.editors.map(registration => {
    ..registration,
    module_path: "assets/tutorial/editor-" +
    registration.id +
    "/" +
    registration.module_path,
    assets: registration.assets.map(path => {
      "assets/tutorial/editor-" + registration.id + "/" + path
    }),
  })
  for registration in input.manifest.editors {
    for path in registration.assets {
      ignore(checked_file(input.root, path))
      assets.push(
        (
          "assets/tutorial/editor-" + registration.id + "/" + path,
          input.manifest.root + "/" + path,
        ),
      )
    }
  }
  let formatters = input.manifest.formatters.map(formatter => {
    ..formatter,
    worker: "assets/tutorial/formatter-" + formatter.id + "/" + formatter.worker,
    assets: formatter.assets.map(path => {
      "assets/tutorial/formatter-" + formatter.id + "/" + path
    }),
  })
  for formatter in input.manifest.formatters {
    for path in formatter.assets {
      ignore(checked_file(input.root, path))
      assets.push(
        (
          "assets/tutorial/formatter-" + formatter.id + "/" + path,
          input.manifest.root + "/" + path,
        ),
      )
    }
  }
  for course in input.manifest.courses {
    navigation.push((course.route, course.title))
    let html = "<h1>" +
      @content.escape(course.title) +
      "</h1>" +
      @tutorial_views.contents(config, course)
    pages.push(
      tutorial_page(
        "tutorial:" + course.id,
        course.route,
        course.title,
        html,
        @content.analyse_html(html).text,
      ),
    )
    for lesson in course.lessons {
      let source = input.manifest.root + "/" + lesson.prose
      let prose_path = checked_file(input.root, lesson.prose)
      let prose_source = @fs.read_file(prose_path).text()
      let includes = @tutorial_check.parse_includes(source, prose_source)
      for guard_check in guards {
        let problems = (guard_check.validate)(source, prose_source, includes)
        if !problems.is_empty() {
          raise @model.Invalid(problems)
        }
      }
      let prose = @markdown.render_markdown(source, prose_source)
      let expanded = tutorial_includes(
        input,
        config,
        source,
        prose.html,
        policies,
      )
      let files = tutorial_files(input, lesson.files)
      // Load every case input even for structural builds. Expectations stay private.
      for case in lesson.cases {
        ignore(checked_file(input.root, case.expect))
        ignore(
          @tutorial_check.Expectation::parse(
            case.expect,
            @fs.read_file(checked_file(input.root, case.expect)).text(),
          ),
        )
        ignore(tutorial_files(input, case.files))
      }
      let downloads = []
      for file in lesson.files {
        let path = "assets/tutorial/files/" +
          course.id +
          "/" +
          lesson.slug +
          "/" +
          file.name
        assets.push((path, input.manifest.root + "/" + file.source))
        downloads.push("/" + path)
      }
      let mut html = @tutorial_views.lesson(
        config, course, lesson, expanded, files, downloads,
      )
      if lesson.editor is Some(adapter) {
        let provider = match lesson.execution {
          Some(execution) =>
            input.manifest.providers
            .iter()
            .find_first(p => p.id == execution.provider)
          None => None
        }
        let documents = files.mapi((i, file) => {
          let fields : Map[String, Json] = Map::from_array([
            ("id", Json::string(file.name)),
            ("name", Json::string(file.name)),
            ("text", Json::string(file.text)),
            ("language", Json::string(file.language)),
            ("group", Json::string(file.group)),
          ])
          if lesson.files[i].formatter is Some(binding) {
            fields["formatter"] = binding.to_json()
          }
          Json::object(fields)
        })
        let revision = match (provider, lesson.execution) {
          (Some(provider), Some(execution)) =>
            @tutorial.input_revision(
              provider,
              execution.operation,
              execution.options,
              files,
            )
          _ => @tutorial.revision(Json(files))
        }
        let runtime : Json = {
          "site": config.repo_url,
          "base": config.base_path,
          "course": course.id,
          "lesson": lesson.slug,
          "starting_revision": @tutorial.revision({
            "execution_revision": revision,
            "editors": Json(input.manifest.editors),
            "formatters": Json(input.manifest.formatters),
            "languages": Json(input.manifest.languages),
            "bindings": lesson.files.map(file => Json(file.formatter)),
          }),
          "adapter": adapter,
          "documents": documents,
          "editors": editors,
          "formatters": formatters,
          "formatting": { "languages": input.manifest.languages },
          "provider": match provider {
            Some(provider) => {
              let fields = match provider.to_json() {
                Object(fields) => fields.copy()
                _ => Map([])
              }
              fields["worker"] = Json::string(
                asset_url(config, provider.id, provider.worker),
              )
              if provider.workbench is Some(path) {
                fields["workbench"] = Json::string(
                  asset_url(config, provider.id, path),
                )
              }
              Json::object(fields)
            }
            None => Json::null()
          },
          "execution": match lesson.execution {
            Some(execution) => Json(execution)
            None => Json::null()
          },
        }
        html += "<noscript><p>Live editing and checking need JavaScript. Starting files remain available above.</p></noscript><div data-tutorial-workspace><script type=\"application/json\" data-tutorial-config>" +
          @tutorial.canonical(runtime).replace_all(old="<", new="\\u003c") +
          "</script></div><script type=\"module\" src=\"" +
          config.href("/assets/tutorial/workspace.js") +
          "\"></script><link rel=\"stylesheet\" href=\"" +
          config.href("/assets/editor/editor.css") +
          "\">"
      }
      pages.push(
        tutorial_page(
          source,
          course.lesson_route(lesson),
          lesson.title,
          html,
          @content.analyse_html(expanded).text,
        ),
      )
    }
  }
  ignore(root)
  { pages, assets, navigation, }
}

///|
pub(all) struct TutorialGuard {
  id : String
  validate : (String, String, Array[@tutorial_check.Include]) -> Array[
    @model.Problem,
  ]
}

///|
async fn tutorial_includes(
  input : TutorialInput,
  config : @model.SiteConfig,
  source : String,
  html : String,
  policies : Array[@tutorial_check.SourcePolicy],
) -> String {
  let out = StringBuilder()
  let mut rest = html[:]
  let marker = "<pre><code class=\"language-tutorial-include\">"
  while rest.find(marker) is Some(start) {
    out.write_view(rest[:start])
    let body = rest[start + marker.length():]
    guard body.find("</code></pre>") is Some(end) else { break }
    let includes = @tutorial_check.parse_includes(
      source,
      "```tutorial-include\n" +
      @content.unescape(body[:end].to_owned()) +
      "\n```\n",
    )
    out.write_string(
      "<section class=\"tutorial-code-group\" aria-label=\"Test source examples\">",
    )
    for entry in includes {
      let policy = policies.iter().find_first(p => p.source == entry.path)
      guard policy is Some(policy) else {
        raise @model.Invalid([
          @model.problem(
            source,
            "include " +
            entry.path +
            "#" +
            entry.region +
            " has no consumer source policy",
          ),
        ])
      }
      let path = checked_file(input.root, entry.path)
      let region = @tutorial_check.extract_region(
        entry.path,
        @fs.read_file(path).text(),
        entry.region,
        policy,
      )
      out.write_string(
        "<details open><summary>" + @content.escape(entry.label) + "</summary>",
      )
      for block in region.blocks {
        out.write_string(
          "<pre><code class=\"language-" +
          @content.escape(block.language) +
          "\">" +
          @content.escape(block.text) +
          "</code></pre>",
        )
      }
      let link = config.repo_url +
        "/blob/" +
        config.repo_ref +
        "/" +
        input.manifest.root +
        "/" +
        entry.path
      out.write_string(
        "<p><a href=\"" +
        @content.escape(link) +
        "\">" +
        @content.escape(entry.path + "#" + entry.region) +
        "</a>. Covered by source policy " +
        @content.escape(region.runner) +
        ". Execution evidence is checked separately.</p></details>",
      )
    }
    out.write_string("</section>")
    rest = body[end + "</code></pre>".length():]
  }
  out.write_view(rest)
  out.to_string()
}
