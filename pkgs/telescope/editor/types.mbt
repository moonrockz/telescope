///|
/// Portable editor contract. No tutorial or engine types enter this package.
pub let contract_version : Int32 = 1

///|
pub(all) struct Document {
  id : String
  name : String
  text : String
  language : String
} derive(Eq, Debug, ToJson, FromJson)

///|
pub(all) struct Selection {
  anchor : Int32
  head : Int32
} derive(Eq, Debug)

///|
pub(all) struct FormatInput {
  target : Document
  context : Array[Document]
  options : Json
} derive(Eq, Debug, ToJson, FromJson)

///|
pub(all) struct FormatOutput {
  text : String
} derive(Eq, Debug, ToJson, FromJson)

///|
pub(all) struct FormatError {
  code : String
  message : String
} derive(Eq, Debug, ToJson, FromJson)

///|
pub(open) trait Formatter {
  fn format(Self, FormatInput) -> Result[FormatOutput, FormatError]
}

///|
pub(all) struct FormatterRegistration {
  id : String
  contract_version : Int32
  formatter_version : String
  languages : Array[String]
  worker : String
  assets : Array[String]
} derive(Eq, Debug, ToJson, FromJson)

///|
pub(all) struct Binding {
  provider : String
  options : Json
} derive(Eq, Debug, ToJson, FromJson)

///|
pub(all) struct EditorRegistration {
  id : String
  contract_version : Int32
  kind : String
  module_path : String
  languages : Array[String]
  assets : Array[String]
} derive(Eq, Debug)

///|
pub(all) struct Registry {
  editors : Array[EditorRegistration]
  formatters : Array[FormatterRegistration]
  languages : Map[String, Binding]
}

///|
pub fn empty_registry() -> Registry {
  { editors: [], formatters: [], languages: Map([]), }
}

///|
pub(all) struct InputRevision {
  id : String
  revision : Int32
} derive(Eq, Debug)

///|
pub(all) struct FormatRequest {
  contract_version : Int32
  instance : String
  formatter : String
  formatter_version : String
  generation : Int32
  request_id : Int32
  target : String
  revisions : Array[InputRevision]
  input : FormatInput
} derive(Eq, Debug)

///|
pub(all) struct FormatResult {
  request : FormatRequest
  output : Result[FormatOutput, FormatError]
} derive(Eq, Debug)

///|
pub fn resolve_binding(
  registry : Registry,
  document : Document,
  document_binding~ : Binding? = None,
) -> Binding? {
  match document_binding {
    Some(binding) => Some(binding)
    None => registry.languages.get(document.language)
  }
}

///|
pub fn validate_binding(
  formatters : Array[FormatterRegistration],
  language : String,
  binding : Binding,
) -> Array[@model.Problem] {
  let problems = []
  if !(binding.options is Object(_)) {
    problems.push(@model.problem("editor", "formatter options must be a table"))
  }
  problems.append(
    match formatters.iter().find_first(f => f.id == binding.provider) {
      None =>
        [@model.problem("editor", "unknown formatter \{binding.provider}")]
      Some(f) =>
        if !f.languages.contains(language) {
          [
            @model.problem(
              "editor",
              "formatter \{f.id} does not support \{language}",
            ),
          ]
        } else {
          []
        }
    },
  )
  problems
}

///|
pub fn validate_registry(registry : Registry) -> Array[@model.Problem] {
  let problems = []
  let ids : Map[String, Bool] = Map([])
  let language_ids : Map[String, Bool] = Map([])
  for editor in registry.editors {
    if editor.id == "" || ids.contains(editor.id) {
      problems.push(
        @model.problem("editor", "empty or duplicate editor id \{editor.id}"),
      )
    }
    ids[editor.id] = true
    if editor.contract_version != contract_version {
      problems.push(
        @model.problem("editor", "unsupported editor contract version"),
      )
    }
    if !["editor", "language"].contains(editor.kind) {
      problems.push(
        @model.problem(
          "editor",
          "unsupported editor registration kind " + editor.kind,
        ),
      )
    }
    if editor.languages.is_empty() ||
      editor.languages.any(language => language == "") ||
      has_duplicates(editor.languages) {
      problems.push(
        @model.problem(
          "editor", "editor registration languages must be nonempty and unique",
        ),
      )
    }
    if !asset_path(editor.module_path) ||
      !editor.assets.contains(editor.module_path) {
      problems.push(
        @model.problem(
          "editor", "editor module must be contained and declared in assets",
        ),
      )
    }
    if editor.kind == "language" {
      for language in editor.languages {
        if language_ids.contains(language) {
          problems.push(
            @model.problem(
              "editor",
              "duplicate language registration for " + language,
            ),
          )
        }
        language_ids[language] = true
      }
    }
    for path in editor.assets {
      if !asset_path(path) {
        problems.push(
          @model.problem(
            path, "editor asset must be a normalized relative path",
          ),
        )
      }
    }
  }
  ids.clear()
  for formatter in registry.formatters {
    if formatter.id == "" || ids.contains(formatter.id) {
      problems.push(
        @model.problem(
          "editor",
          "empty or duplicate formatter id \{formatter.id}",
        ),
      )
    }
    ids[formatter.id] = true
    if formatter.contract_version != contract_version ||
      formatter.formatter_version == "" {
      problems.push(
        @model.problem(
          "editor", "unsupported formatter contract or empty formatter version",
        ),
      )
    }
    if formatter.languages.is_empty() ||
      formatter.languages.any(l => l == "") ||
      has_duplicates(formatter.languages) {
      problems.push(
        @model.problem(
          "editor", "formatter languages must be nonempty and unique",
        ),
      )
    }
    if !formatter.assets.contains(formatter.worker) {
      problems.push(
        @model.problem("editor", "formatter worker must be declared in assets"),
      )
    }
    for path in formatter.assets {
      if !asset_path(path) {
        problems.push(
          @model.problem(
            path, "formatter asset must be a normalized relative path",
          ),
        )
      }
    }
  }
  for language, binding in registry.languages {
    problems.append(validate_binding(registry.formatters, language, binding))
  }
  problems
}

///|
pub extend Document with Eq::{equal, not_equal}

///|
pub extend Document with @debug.Debug::{to_repr}

///|
pub extend Selection with Eq::{equal, not_equal}

///|
pub extend Selection with @debug.Debug::{to_repr}

///|
pub extend FormatInput with Eq::{equal, not_equal}

///|
pub extend FormatInput with @debug.Debug::{to_repr}

///|
pub extend FormatOutput with Eq::{equal, not_equal}

///|
pub extend FormatOutput with @debug.Debug::{to_repr}

///|
pub extend FormatError with Eq::{equal, not_equal}

///|
pub extend FormatError with @debug.Debug::{to_repr}

///|
pub extend FormatterRegistration with Eq::{equal, not_equal}

///|
pub extend FormatterRegistration with @debug.Debug::{to_repr}

///|
pub extend Binding with Eq::{equal, not_equal}

///|
pub extend Binding with @debug.Debug::{to_repr}

///|
pub extend EditorRegistration with Eq::{equal, not_equal}

///|
pub extend EditorRegistration with @debug.Debug::{to_repr}

///|
pub extend InputRevision with Eq::{equal, not_equal}

///|
pub extend InputRevision with @debug.Debug::{to_repr}

///|
pub extend FormatRequest with Eq::{equal, not_equal}

///|
pub extend FormatRequest with @debug.Debug::{to_repr}

///|
pub extend FormatResult with Eq::{equal, not_equal}

///|
pub extend FormatResult with @debug.Debug::{to_repr}

///|
fn has_duplicates(values : Array[String]) -> Bool {
  let seen : Map[String, Bool] = Map([])
  for value in values {
    if seen.contains(value) {
      return true
    }
    seen[value] = true
  }
  false
}

///|
pub extend FormatterRegistration with ToJson::{to_json}

///|
pub extend FormatterRegistration with @json.FromJson::{from_json}

///|
pub extend Binding with ToJson::{to_json}

///|
pub extend Binding with @json.FromJson::{from_json}

///|
pub extend Document with ToJson::{to_json}

///|
pub extend Document with @json.FromJson::{from_json}

///|
pub extend FormatInput with ToJson::{to_json}

///|
pub extend FormatInput with @json.FromJson::{from_json}

///|
pub extend FormatOutput with ToJson::{to_json}

///|
pub extend FormatOutput with @json.FromJson::{from_json}

///|
pub extend FormatError with ToJson::{to_json}

///|
pub extend FormatError with @json.FromJson::{from_json}

///|
fn asset_path(path : String) -> Bool {
  @model.relative_path(path) &&
  !path.contains("%") &&
  !path.contains("?") &&
  !path.contains("#") &&
  path.iter().all(c => c >= ' ')
}

///|
pub extend EditorRegistration with ToJson::{to_json}

///|
pub extend EditorRegistration with @json.FromJson::{from_json}

///|
/// Built-in plain/rich adapters accept any language with readable fallback.
/// Declarative custom adapters must explicitly support every supplied document.
pub fn validate_editor_binding(
  editors : Array[EditorRegistration],
  adapter : String,
  languages : Array[String],
) -> Array[@model.Problem] {
  match
    editors
    .iter()
    .find_first(editor => editor.id == adapter && editor.kind == "editor") {
    None =>
      if ["plain", "rich"].contains(adapter) {
        []
      } else {
        [@model.problem("editor", "unknown editor adapter " + adapter)]
      }
    Some(editor) =>
      languages.filter_map(language => {
        if editor.languages.contains(language) {
          None
        } else {
          Some(
            @model.problem(
              "editor",
              "editor " + adapter + " does not support " + language,
            ),
          )
        }
      })
  }
}

///|
pub impl ToJson for EditorRegistration with fn to_json(self) {
  {
    "id": self.id,
    "contract_version": self.contract_version,
    "kind": self.kind,
    "module": self.module_path,
    "languages": self.languages,
    "assets": self.assets,
  }
}

///|
pub impl @json.FromJson for EditorRegistration with fn from_json(value, path) {
  guard value is Object(fields) else {
    raise @json.JsonDecodeError((path, "expected editor registration object"))
  }
  for key, _ in fields {
    if !["id", "contract_version", "kind", "module", "languages", "assets"].contains(
        key,
      ) {
      raise @json.JsonDecodeError(
        (path.add_key(key), "unknown editor registration field"),
      )
    }
  }
  fn required(key : String) -> Json raise @json.JsonDecodeError {
    match fields.get(key) {
      Some(value) => value
      None =>
        raise @json.JsonDecodeError(
          (path.add_key(key), "required field is missing"),
        )
    }
  }
  {
    id: @json.from_json(required("id"), path=path.add_key("id")),
    contract_version: match required("contract_version") {
      Number(value, ..) if !value.is_nan() &&
        !value.is_inf() &&
        value >= -2147483648.0 &&
        value <= 2147483647.0 &&
        value == value.floor() => value.to_int()
      _ =>
        raise @json.JsonDecodeError(
          (path.add_key("contract_version"), "expected an integer"),
        )
    },
    kind: @json.from_json(required("kind"), path=path.add_key("kind")),
    module_path: @json.from_json(
      required("module"),
      path=path.add_key("module"),
    ),
    languages: @json.from_json(
      required("languages"),
      path=path.add_key("languages"),
    ),
    assets: @json.from_json(required("assets"), path=path.add_key("assets")),
  }
}
