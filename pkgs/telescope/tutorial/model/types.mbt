///|
pub(all) struct Provider {
  id : String
  contract_version : Int32
  engine_version : String
  operations : Array[String]
  worker : String
  assets : Array[String]
  workbench : String?
} derive(Eq, Debug)

///|
pub(all) struct FileSource {
  name : String
  source : String
  language : String
  group : String
  formatter : @editor.Binding?
} derive(Eq, Debug)

///|
pub(all) struct File {
  name : String
  text : String
  language : String
  group : String
} derive(Eq, Debug, ToJson, FromJson)

///|
pub(all) struct Execution {
  provider : String
  operation : String
  options : Json
} derive(Eq, Debug, ToJson, FromJson)

///|
pub(all) struct Reference {
  label : String
  url : String
} derive(Eq, Debug, ToJson, FromJson)

///|
pub(all) struct CaseSource {
  id : String
  expect : String
  files : Array[FileSource]
} derive(Eq, Debug, ToJson, FromJson)

///|
pub(all) struct Lesson {
  slug : String
  title : String
  section : String
  prose : String
  references : Array[Reference]
  files : Array[FileSource]
  execution : Execution?
  cases : Array[CaseSource]
  editor : String?
} derive(Eq, Debug)

///|
pub(all) struct Course {
  id : String
  title : String
  route : String
  lessons : Array[Lesson]
} derive(Eq, Debug, ToJson, FromJson)

///|
pub(all) struct Manifest {
  schema_version : Int32
  root : String
  providers : Array[Provider]
  editors : Array[@editor.EditorRegistration]
  formatters : Array[@editor.FormatterRegistration]
  languages : Map[String, @editor.Binding]
  courses : Array[Course]
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn Course::lesson_route(self : Course, lesson : Lesson) -> String {
  self.route + lesson.slug + "/"
}

///|
pub fn Course::neighbors(self : Course, slug : String) -> (Lesson?, Lesson?) {
  for i, lesson in self.lessons {
    if lesson.slug == slug {
      return (
        if i > 0 {
          Some(self.lessons[i - 1])
        } else {
          None
        },
        if i + 1 < self.lessons.length() {
          Some(self.lessons[i + 1])
        } else {
          None
        },
      )
    }
  }
  (None, None)
}

///|
pub(all) struct Diagnostic {
  key : String
  code : String
  severity : String
  message : String
  file : String?
  line : Int32?
  column : Int32?
  end_line : Int32?
  end_column : Int32?
} derive(Eq, Debug)

///|
pub(all) struct Output {
  id : String
  label : String
  language : String
  text : String
} derive(Eq, Debug, ToJson, FromJson)

///|
pub(all) struct StepRow {
  id : String
  label : String
  diagnostics : Array[Diagnostic]
  text : String
} derive(Eq, Debug, ToJson, FromJson)

///|
pub(all) struct Steps {
  session : String
  rows : Array[StepRow]
  checked : Int32
  complete : Bool
  summary : String?
} derive(Eq, Debug)

///|
pub(all) struct Request {
  contract_version : Int32
  provider : String
  engine_version : String
  generation : Int32
  request_id : Int32
  input_revision : String
  operation : String
  files : Array[File]
  options : Json
  session : String?
  position : Int32?
} derive(Eq, Debug)

///|
pub(all) struct Response {
  contract_version : Int32
  provider : String
  engine_version : String
  generation : Int32
  request_id : Int32
  input_revision : String
  status : String
  diagnostics : Array[Diagnostic]
  outputs : Array[Output]
  blocked : String?
  verdict : String?
  steps : Steps?
} derive(Eq, Debug)

///|
pub(all) struct EvaluationError {
  code : String
  message : String
} derive(Eq, Debug, ToJson, FromJson)

///|
pub(open) trait Evaluator {
  fn evaluate(Self, Request) -> Result[Response, EvaluationError]
}

///|
pub(all) struct EvaluatorRegistration {
  provider : String
  engine_version : String
  contract_version : Int32
  operations : Array[String]
  evaluate : (Request) -> Result[Response, EvaluationError]
}

///|
pub fn response_for(request : Request) -> Response {
  {
    contract_version: request.contract_version,
    provider: request.provider,
    engine_version: request.engine_version,
    generation: request.generation,
    request_id: request.request_id,
    input_revision: request.input_revision,
    status: "success",
    diagnostics: [],
    outputs: [],
    blocked: None,
    verdict: None,
    steps: None,
  }
}

///|
pub fn response_problems(
  request : Request,
  response : Response,
) -> Array[String] {
  let problems = []
  if response.contract_version != 1 {
    problems.push("unsupported response contract_version")
  }
  if response.provider != request.provider ||
    response.engine_version != request.engine_version {
    problems.push("response provider/version mismatch")
  }
  if response.generation != request.generation ||
    response.request_id != request.request_id ||
    response.input_revision != request.input_revision {
    problems.push("stale response identity or input revision")
  }
  if !["success", "blocked", "error"].contains(response.status) {
    problems.push("unknown response status")
  }
  if response.status == "blocked" && response.blocked is None {
    problems.push("blocked response requires a reason")
  }
  if response.status != "blocked" && response.blocked is Some(_) {
    problems.push("blocked reason requires blocked status")
  }
  let outputs : Map[String, Bool] = Map([])
  for output in response.outputs {
    if output.id == "" || output.label == "" || outputs.contains(output.id) {
      problems.push("invalid or duplicate output identity")
    }
    outputs[output.id] = true
  }
  for diagnostic in response.diagnostics {
    if diagnostic.key == "" ||
      diagnostic.code == "" ||
      diagnostic.severity == "" ||
      diagnostic.message == "" {
      problems.push("diagnostic requires key, code, severity and message")
    }
    if diagnostic.file is Some(file) && !@base.relative_path(file) {
      problems.push("diagnostic file is not a virtual relative path")
    }
    for
      position in [
        diagnostic.line,
        diagnostic.column,
        diagnostic.end_line,
        diagnostic.end_column,
      ] {
      if position is Some(position) && position < 1 {
        problems.push("diagnostic spans are one-based")
      }
    }
  }
  if response.steps is Some(steps) {
    if steps.checked < 0 ||
      steps.checked > steps.rows.length() ||
      steps.session == "" {
      problems.push("invalid step progress")
    }
    let rows : Map[String, Bool] = Map([])
    for row in steps.rows {
      if row.id == "" || row.label == "" || rows.contains(row.id) {
        problems.push("invalid or duplicate step identity")
      }
      rows[row.id] = true
    }
  }
  problems
}

///|
/// Canonical JSON preserves arrays while sorting every object's keys.
pub fn canonical(value : Json) -> String {
  match value {
    Object(fields) => {
      let keys = fields.keys().collect()
      keys.sort_by(lexical_compare)
      "{" +
      keys
      .map(key => Json::string(key).stringify() + ":" + canonical(fields[key]))
      .join(",") +
      "}"
    }
    Array(values) => "[" + values.map(canonical).join(",") + "]"
    _ => value.stringify()
  }
}

///|
/// A freshness identity, not a cryptographic integrity promise.
pub fn revision(value : Json) -> String {
  canonical(value)
}

///|
pub fn input_revision(
  provider : Provider,
  operation : String,
  options : Json,
  files : Array[File],
) -> String {
  revision({
    "schema_version": 1,
    "provider": provider.id,
    "engine_version": provider.engine_version,
    "contract_version": provider.contract_version,
    "operation": operation,
    "options": options,
    "files": Json(files),
  })
}

///|
pub fn overlay_files(start : Array[File], overlay : Array[File]) -> Array[File] {
  let merged = start.copy()
  for file in overlay {
    match
      merged
      .iter2()
      .to_array()
      .iter()
      .find_first(pair => pair.1.name == file.name) {
      Some((index, _)) => merged[index] = file
      None => merged.push(file)
    }
  }
  merged
}

///|
pub extend Provider with Eq::{equal, not_equal}

///|
pub extend Provider with @debug.Debug::{to_repr}

///|
pub extend Provider with ToJson::{to_json}

///|
pub extend Provider with @json.FromJson::{from_json}

///|
pub extend FileSource with Eq::{equal, not_equal}

///|
pub extend FileSource with @debug.Debug::{to_repr}

///|
pub extend FileSource with ToJson::{to_json}

///|
pub extend FileSource with @json.FromJson::{from_json}

///|
pub extend File with Eq::{equal, not_equal}

///|
pub extend File with @debug.Debug::{to_repr}

///|
pub extend File with ToJson::{to_json}

///|
pub extend File with @json.FromJson::{from_json}

///|
pub extend Execution with Eq::{equal, not_equal}

///|
pub extend Execution with @debug.Debug::{to_repr}

///|
pub extend Execution with ToJson::{to_json}

///|
pub extend Execution with @json.FromJson::{from_json}

///|
pub extend Reference with Eq::{equal, not_equal}

///|
pub extend Reference with @debug.Debug::{to_repr}

///|
pub extend Reference with ToJson::{to_json}

///|
pub extend Reference with @json.FromJson::{from_json}

///|
pub extend CaseSource with Eq::{equal, not_equal}

///|
pub extend CaseSource with @debug.Debug::{to_repr}

///|
pub extend CaseSource with ToJson::{to_json}

///|
pub extend CaseSource with @json.FromJson::{from_json}

///|
pub extend Lesson with Eq::{equal, not_equal}

///|
pub extend Lesson with @debug.Debug::{to_repr}

///|
pub extend Lesson with ToJson::{to_json}

///|
pub extend Lesson with @json.FromJson::{from_json}

///|
pub extend Course with Eq::{equal, not_equal}

///|
pub extend Course with @debug.Debug::{to_repr}

///|
pub extend Course with ToJson::{to_json}

///|
pub extend Course with @json.FromJson::{from_json}

///|
pub extend Manifest with Eq::{equal, not_equal}

///|
pub extend Manifest with @debug.Debug::{to_repr}

///|
pub extend Manifest with ToJson::{to_json}

///|
pub extend Manifest with @json.FromJson::{from_json}

///|
pub extend Diagnostic with Eq::{equal, not_equal}

///|
pub extend Diagnostic with @debug.Debug::{to_repr}

///|
pub extend Diagnostic with ToJson::{to_json}

///|
pub extend Diagnostic with @json.FromJson::{from_json}

///|
pub extend Output with Eq::{equal, not_equal}

///|
pub extend Output with @debug.Debug::{to_repr}

///|
pub extend Output with ToJson::{to_json}

///|
pub extend Output with @json.FromJson::{from_json}

///|
pub extend StepRow with Eq::{equal, not_equal}

///|
pub extend StepRow with @debug.Debug::{to_repr}

///|
pub extend StepRow with ToJson::{to_json}

///|
pub extend StepRow with @json.FromJson::{from_json}

///|
pub extend Steps with Eq::{equal, not_equal}

///|
pub extend Steps with @debug.Debug::{to_repr}

///|
pub extend Steps with ToJson::{to_json}

///|
pub extend Steps with @json.FromJson::{from_json}

///|
pub extend Request with Eq::{equal, not_equal}

///|
pub extend Request with @debug.Debug::{to_repr}

///|
pub extend Request with ToJson::{to_json}

///|
pub extend Request with @json.FromJson::{from_json}

///|
pub extend Response with Eq::{equal, not_equal}

///|
pub extend Response with @debug.Debug::{to_repr}

///|
pub extend Response with ToJson::{to_json}

///|
pub extend Response with @json.FromJson::{from_json}

///|
pub extend EvaluationError with Eq::{equal, not_equal}

///|
pub extend EvaluationError with @debug.Debug::{to_repr}

///|
pub extend EvaluationError with ToJson::{to_json}

///|
pub extend EvaluationError with @json.FromJson::{from_json}

///|
/// Validate compiled callbacks before invoking any evaluator. Native code is explicitly registered.
pub fn validate_evaluators(
  providers : Array[Provider],
  registrations : Array[EvaluatorRegistration],
) -> Array[String] {
  let problems = []
  let ids : Map[String, Bool] = Map([])
  for registration in registrations {
    if ids.contains(registration.provider) {
      problems.push("duplicate evaluator " + registration.provider)
    }
    ids[registration.provider] = true
    match providers.iter().find_first(p => p.id == registration.provider) {
      None =>
        problems.push("unknown evaluator provider " + registration.provider)
      Some(provider) => {
        if registration.contract_version != provider.contract_version ||
          registration.engine_version != provider.engine_version {
          problems.push("evaluator version mismatch for " + provider.id)
        }
        let wanted = provider.operations.copy()
        let found = registration.operations.copy()
        wanted.sort()
        found.sort()
        if wanted != found {
          problems.push("evaluator capability mismatch for " + provider.id)
        }
      }
    }
  }
  problems
}

///|
/// JavaScript Object.keys(...).sort() uses lexicographic UTF-16 code units.
fn lexical_compare(a : String, b : String) -> Int32 {
  for i in 0..<Int32::min(a.length(), b.length()) {
    if a.at(i) < b.at(i) {
      return -1
    }
    if a.at(i) > b.at(i) {
      return 1
    }
  }
  a.length().compare(b.length())
}
