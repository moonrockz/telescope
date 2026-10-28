///|
fn fail(
  file : String,
  path : String,
  message : String,
) -> Unit raise @base.Invalid {
  raise @base.Invalid([@base.problem(file, path + ": " + message)])
}

///|
fn toml_json(
  file : String,
  path : String,
  value : @toml.TomlValue,
) -> Json raise @base.Invalid {
  match value {
    TomlString(text) => Json::string(text)
    TomlInteger(number) =>
      @json.parse(number.to_string()) catch {
        _ => {
          fail(file, path, "integer is outside JSON number range")
          Json::null()
        }
      }
    TomlFloat(number) => {
      let repr = number.to_string()
      if number.is_inf() || number.is_nan() {
        fail(file, path, "non-finite numbers are unsupported")
      }
      @json.parse(repr) catch {
        _ => {
          fail(file, path, "unsupported numeric value")
          Json::null()
        }
      }
    }
    TomlBoolean(value) =>
      if value {
        Json::boolean(true)
      } else {
        Json::boolean(false)
      }
    TomlArray(values) =>
      Json::array(values.mapi((i, v) => toml_json(file, "\{path}[\{i}]", v)))
    TomlTable(fields) => {
      let result : Map[String, Json] = Map([])
      for key, value in fields {
        result[key] = toml_json(file, path + "." + key, value)
      }
      Json::object(result)
    }
    TomlDateTime(_) => {
      fail(file, path, "date/time values are unsupported; use a string")
      Json::null()
    }
  }
}

///|
fn object(
  file : String,
  path : String,
  value : Json,
  keys : Array[String],
) -> Map[String, Json] raise @base.Invalid {
  guard value is Object(fields) else {
    fail(file, path, "expected a table")
    return Map([])
  }
  for key, _ in fields {
    if !keys.contains(key) {
      fail(file, path + "." + key, "unknown field")
    }
  }
  fields
}

///|
fn text(
  file : String,
  path : String,
  fields : Map[String, Json],
  key : String,
  default~ : String? = None,
) -> String raise @base.Invalid {
  match fields.get(key) {
    None if default is Some(value) => value
    Some(String(value)) if value != "" => value
    _ => {
      fail(file, path + "." + key, "expected a nonempty string")
      ""
    }
  }
}

///|
fn list(
  file : String,
  path : String,
  fields : Map[String, Json],
  key : String,
  required~ : Bool = false,
) -> Array[Json] raise @base.Invalid {
  match fields.get(key) {
    None if !required => []
    Some(Array(values)) => values
    _ => {
      fail(file, path + "." + key, "expected an array")
      []
    }
  }
}

///|
fn strings(
  file : String,
  path : String,
  fields : Map[String, Json],
  key : String,
) -> Array[String] raise @base.Invalid {
  list(file, path, fields, key).map(value => {
    match value {
      String(value) if value != "" => value
      _ => {
        fail(file, path + "." + key, "expected nonempty strings")
        ""
      }
    }
  })
}

///|
fn version(
  file : String,
  path : String,
  fields : Map[String, Json],
  key : String,
) -> Int32 raise @base.Invalid {
  match fields.get(key) {
    Some(Number(1, ..)) => 1
    _ => {
      fail(
        file,
        path + "." + key,
        "unsupported or missing version; supported version is 1",
      )
      1
    }
  }
}

///|
fn relative(
  file : String,
  path : String,
  value : String,
) -> String raise @base.Invalid {
  if !@base.relative_path(value) {
    fail(file, path, "expected a normalized relative path")
  }
  value
}

///|
fn identity(
  file : String,
  path : String,
  value : String,
) -> String raise @base.Invalid {
  if value == "." ||
    value == ".." ||
    !value
    .iter()
    .all(c => {
      (c >= 'a' && c <= 'z') ||
      (c >= 'A' && c <= 'Z') ||
      (c >= '0' && c <= '9') ||
      c == '-' ||
      c == '_' ||
      c == '.'
    }) {
    fail(file, path, "expected a letter/digit/dot/hyphen/underscore identity")
  }
  value
}

///|
fn options(
  file : String,
  path : String,
  fields : Map[String, Json],
) -> Json raise @base.Invalid {
  match fields.get("options") {
    None => Json::empty_object()
    Some(Object(values)) => Json::object(values)
    _ => {
      fail(file, path + ".options", "expected a table")
      Json::null()
    }
  }
}

///|
fn parse_binding(
  file : String,
  path : String,
  value : Json,
) -> @editor.Binding raise @base.Invalid {
  let fields = object(file, path, value, ["provider", "options"])
  {
    provider: text(file, path, fields, "provider"),
    options: options(file, path, fields),
  }
}

///|
fn parse_file(
  file : String,
  path : String,
  value : Json,
) -> FileSource raise @base.Invalid {
  let fields = object(file, path, value, [
    "name", "source", "language", "group", "formatter",
  ])
  {
    name: relative(file, path + ".name", text(file, path, fields, "name")),
    source: relative(file, path + ".source", text(file, path, fields, "source")),
    language: text(file, path, fields, "language", default=Some("text")),
    group: text(file, path, fields, "group", default=Some("")),
    formatter: fields
    .get("formatter")
    .map(value => parse_binding(file, path + ".formatter", value)),
  }
}

///|
fn parse_files(
  file : String,
  path : String,
  fields : Map[String, Json],
) -> Array[FileSource] raise @base.Invalid {
  let values = list(file, path, fields, "files")
  let result = values.mapi((i, value) => {
    parse_file(file, "\{path}.files[\{i}]", value)
  })
  let seen : Map[String, Bool] = Map([])
  for item in result {
    if seen.contains(item.name) {
      fail(file, path + ".files", "duplicate virtual name " + item.name)
    }
    seen[item.name] = true
  }
  result
}

///|
fn parse_provider(
  file : String,
  path : String,
  value : Json,
) -> Provider raise @base.Invalid {
  let fields = object(file, path, value, [
    "id", "contract_version", "engine_version", "operations", "worker", "assets",
    "workbench",
  ])
  let assets = strings(file, path, fields, "assets")
  for asset in assets {
    ignore(relative(file, path + ".assets", asset))
  }
  let worker = relative(
    file,
    path + ".worker",
    text(file, path, fields, "worker"),
  )
  if !assets.contains(worker) {
    fail(file, path + ".worker", "worker must be listed in assets")
  }
  let operations = strings(file, path, fields, "operations")
  if operations.is_empty() {
    fail(file, path + ".operations", "at least one operation is required")
  }
  let seen : Map[String, Bool] = Map([])
  for operation in operations {
    if !["evaluate", "start", "step", "run-all"].contains(operation) ||
      seen.contains(operation) {
      fail(
        file,
        path + ".operations",
        "unsupported or duplicate operation " + operation,
      )
    }
    seen[operation] = true
  }
  if (operations.contains("step") || operations.contains("run-all")) &&
    !operations.contains("start") {
    fail(file, path + ".operations", "stepping requires start")
  }
  let workbench = fields
    .get("workbench")
    .map(value => {
      match value {
        String(asset) => relative(file, path + ".workbench", asset)
        _ => {
          fail(file, path + ".workbench", "expected a relative module path")
          ""
        }
      }
    })
  if workbench is Some(asset) && !assets.contains(asset) {
    fail(file, path + ".workbench", "workbench must be listed in assets")
  }
  {
    id: identity(file, path + ".id", text(file, path, fields, "id")),
    contract_version: version(file, path, fields, "contract_version"),
    engine_version: text(file, path, fields, "engine_version"),
    operations,
    worker,
    assets,
    workbench,
  }
}

///|
fn parse_editor(
  file : String,
  path : String,
  value : Json,
) -> @editor.EditorRegistration raise @base.Invalid {
  let fields = object(file, path, value, [
    "id", "contract_version", "kind", "module", "languages", "assets",
  ])
  {
    id: text(file, path, fields, "id"),
    contract_version: version(file, path, fields, "contract_version"),
    kind: text(file, path, fields, "kind"),
    module_path: text(file, path, fields, "module"),
    languages: strings(file, path, fields, "languages"),
    assets: strings(file, path, fields, "assets"),
  }
}

///|
fn parse_formatter(
  file : String,
  path : String,
  value : Json,
) -> @editor.FormatterRegistration raise @base.Invalid {
  let fields = object(file, path, value, [
    "id", "contract_version", "formatter_version", "languages", "worker", "assets",
  ])
  {
    id: text(file, path, fields, "id"),
    contract_version: version(file, path, fields, "contract_version"),
    formatter_version: text(file, path, fields, "formatter_version"),
    languages: strings(file, path, fields, "languages"),
    worker: text(file, path, fields, "worker"),
    assets: strings(file, path, fields, "assets"),
  }
}

///|
fn parse_lesson(
  file : String,
  path : String,
  value : Json,
  providers : Array[Provider],
) -> Lesson raise @base.Invalid {
  let fields = object(file, path, value, [
    "slug", "title", "section", "prose", "references", "files", "execution", "cases",
    "editor",
  ])
  let files = parse_files(file, path, fields)
  let execution = fields
    .get("execution")
    .map(value => {
      let at = path + ".execution"
      let execution = object(file, at, value, [
        "provider", "operation", "options",
      ])
      let provider = text(file, at, execution, "provider")
      let operation = text(file, at, execution, "operation")
      match providers.iter().find_first(p => p.id == provider) {
        None => fail(file, at + ".provider", "unknown provider " + provider)
        Some(p) =>
          if !p.operations.contains(operation) {
            fail(
              file,
              at + ".operation",
              "provider " + provider + " does not support " + operation,
            )
          }
      }
      Execution::{ provider, operation, options: options(file, at, execution), }
    })
  let cases = list(file, path, fields, "cases").mapi((i, value) => {
    let at = "\{path}.cases[\{i}]"
    let fields = object(file, at, value, ["id", "expect", "files"])
    CaseSource::{
      id: identity(file, at + ".id", text(file, at, fields, "id")),
      expect: relative(file, at + ".expect", text(file, at, fields, "expect")),
      files: parse_files(file, at, fields),
    }
  })
  let case_ids : Map[String, Bool] = Map([])
  for case in cases {
    if case_ids.contains(case.id) {
      fail(file, path + ".cases", "duplicate case " + case.id)
    }
    case_ids[case.id] = true
  }
  if execution is Some(_) && (!case_ids.contains("start") || files.is_empty()) {
    fail(file, path, "executable lessons require files and a start case")
  }
  if execution is None &&
    (
      fields.contains("cases") ||
      fields.contains("files") ||
      fields.contains("editor")
    ) {
    fail(file, path, "static lessons reject files, cases and editor")
  }
  let references = list(file, path, fields, "references").mapi((i, value) => {
    let at = "\{path}.references[\{i}]"
    let fields = object(file, at, value, ["label", "url"])
    let url = text(file, at, fields, "url")
    if !url.has_prefix("https://") && !url.has_prefix("http://") {
      fail(file, at + ".url", "references require http or https")
    }
    Reference::{ label: text(file, at, fields, "label"), url, }
  })
  let editor = fields
    .get("editor")
    .map(value => {
      match value {
        String(id) if id != "" => id
        _ => {
          fail(
            file,
            path + ".editor",
            "expected a nonempty editor registration ID",
          )
          "plain"
        }
      }
    })
  {
    slug: identity(file, path + ".slug", text(file, path, fields, "slug")),
    title: text(file, path, fields, "title"),
    section: text(file, path, fields, "section", default=Some("")),
    prose: relative(file, path + ".prose", text(file, path, fields, "prose")),
    references,
    files,
    execution,
    cases,
    editor,
  }
}

///|
pub fn Manifest::parse(
  file : String,
  source : String,
) -> Manifest raise @base.Invalid {
  let parsed = @toml.parse(source) catch {
    error =>
      raise @base.Invalid([@base.problem(file, "invalid TOML: \{error}")])
  }
  if parsed is TomlTable(root) {
    match root.get("schema_version") {
      Some(TomlInteger(_)) | None => ()
      _ => fail(file, "tutorials.schema_version", "expected an integer version")
    }
    for key in ["providers", "editors", "formatters"] {
      if root.get(key) is Some(TomlArray(items)) {
        for i, item in items {
          if item is TomlTable(fields) {
            match fields.get("contract_version") {
              Some(TomlInteger(_)) | None => ()
              _ =>
                fail(
                  file,
                  "\{key}[\{i}].contract_version",
                  "expected an integer version",
                )
            }
          }
        }
      }
    }
  }
  let value = toml_json(file, "tutorials", parsed)
  let fields = object(file, "tutorials", value, [
    "schema_version", "root", "providers", "editors", "formatters", "formatting",
    "courses",
  ])
  let providers = list(file, "tutorials", fields, "providers").mapi((i, v) => {
    parse_provider(file, "providers[\{i}]", v)
  })
  let ids : Map[String, Bool] = Map([])
  for provider in providers {
    if ids.contains(provider.id) {
      fail(file, "providers", "duplicate provider " + provider.id)
    }
    ids[provider.id] = true
  }
  let editors = list(file, "tutorials", fields, "editors").mapi((i, value) => {
    parse_editor(file, "editors[\{i}]", value)
  })
  let formatters = list(file, "tutorials", fields, "formatters").mapi((i, v) => {
    parse_formatter(file, "formatters[\{i}]", v)
  })
  let languages : Map[String, @editor.Binding] = Map([])
  if fields.get("formatting") is Some(formatting) {
    let formatting = object(file, "formatting", formatting, ["languages"])
    if formatting.get("languages") is Some(value) {
      guard value is Object(entries) else {
        fail(file, "formatting.languages", "expected a table")
        abort("unreachable")
      }
      for language, binding in entries {
        languages[language] = parse_binding(
          file,
          "formatting.languages." + language,
          binding,
        )
      }
    }
  }
  let registry : @editor.Registry = { editors, formatters, languages, }
  let problems = @editor.validate_registry(registry)
  if !problems.is_empty() {
    raise @base.Invalid(problems.map(p => { ..p, file, }))
  }
  let courses = list(file, "tutorials", fields, "courses", required=true).mapi((
    i,
    value,
  ) => {
    let at = "courses[\{i}]"
    let fields = object(file, at, value, ["id", "title", "route", "lessons"])
    let route = text(file, at, fields, "route")
    if !route.has_prefix("/") ||
      !route.has_suffix("/") ||
      route == "/" ||
      !@base.relative_path(route[1:route.length() - 1].to_owned()) ||
      @base.reserved_route(route) ||
      !route
      .iter()
      .all(c => {
        (c >= 'a' && c <= 'z') ||
        (c >= 'A' && c <= 'Z') ||
        (c >= '0' && c <= '9') ||
        c == '/' ||
        c == '-' ||
        c == '_' ||
        c == '.'
      }) {
      fail(
        file,
        at + ".route",
        "expected a nonreserved normalized route prefix",
      )
    }
    let lessons = list(file, at, fields, "lessons", required=true).mapi((
      j,
      value,
    ) => parse_lesson(file, "\{at}.lessons[\{j}]", value, providers))
    let seen : Map[String, Bool] = Map([])
    for lesson_index, lesson in lessons {
      if seen.contains(lesson.slug) {
        fail(file, at + ".lessons", "duplicate lesson slug " + lesson.slug)
      }
      seen[lesson.slug] = true
      if lesson.editor is Some(selected) {
        let errors = @editor.validate_editor_binding(
          editors,
          selected,
          lesson.files.map(file => file.language),
        )
        if !errors.is_empty() {
          raise @base.Invalid(
            errors.map(problem => {
              ..problem,
              file,
              message: "\{at}.lessons[\{lesson_index}].editor: " +
              problem.message,
            }),
          )
        }
      }
      let declared_files = lesson.files.mapi((index, doc) => {
        (doc, "files[\{index}]")
      })
      for case_index, case in lesson.cases {
        declared_files.append(
          case.files.mapi((index, doc) => {
            (doc, "cases[\{case_index}].files[\{index}]")
          }),
        )
      }
      for (doc, location) in declared_files {
        let binding = match doc.formatter {
          Some(value) => Some(value)
          None => languages.get(doc.language)
        }
        if binding is Some(binding) {
          let errors = @editor.validate_binding(
            formatters,
            doc.language,
            binding,
          )
          if !errors.is_empty() {
            raise @base.Invalid(
              errors.map(p => {
                ..p,
                file,
                message: "\{at}.lessons[\{lesson_index}].\{location}.formatter: " +
                p.message,
              }),
            )
          }
        }
      }
    }
    Course::{
      id: identity(file, at + ".id", text(file, at, fields, "id")),
      title: text(file, at, fields, "title"),
      route,
      lessons,
    }
  })
  let seen : Map[String, Bool] = Map([])
  let routes : Map[String, Bool] = Map([])
  for course in courses {
    if seen.contains(course.id) {
      fail(file, "courses", "duplicate course id " + course.id)
    }
    if routes.contains(course.route) {
      fail(file, "courses", "duplicate course route " + course.route)
    }
    seen[course.id] = true
    routes[course.route] = true
  }
  let prose_routes : Map[String, String] = Map([])
  for course_index, course in courses {
    for lesson_index, lesson in course.lessons {
      if prose_routes.get(lesson.prose) is Some(previous) {
        fail(
          file,
          "courses[\{course_index}].lessons[\{lesson_index}].prose",
          "lesson prose already maps to " +
          previous +
          "; each prose source must be unique",
        )
      }
      prose_routes[lesson.prose] = course.lesson_route(lesson)
    }
  }
  {
    schema_version: version(file, "tutorials", fields, "schema_version"),
    root: relative(
      file,
      "tutorials.root",
      text(file, "tutorials", fields, "root"),
    ),
    providers,
    editors,
    formatters,
    languages,
    courses,
  }
}
