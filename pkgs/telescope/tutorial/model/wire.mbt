///|
fn wire_fields(
  value : Json,
  path : @json.JsonPath,
  allowed : Array[String],
) -> Map[String, Json] raise @json.JsonDecodeError {
  guard value is Object(fields) else {
    raise @json.JsonDecodeError((path, "expected an object"))
  }
  for key, _ in fields {
    if !allowed.contains(key) {
      raise @json.JsonDecodeError((path.add_key(key), "unknown field"))
    }
  }
  fields
}

///|
fn[T : @json.FromJson] wire_required(
  fields : Map[String, Json],
  key : String,
  path : @json.JsonPath,
) -> T raise @json.JsonDecodeError {
  guard fields.get(key) is Some(value) else {
    raise @json.JsonDecodeError(
      (path.add_key(key), "required field is missing"),
    )
  }
  @json.from_json(value, path=path.add_key(key))
}

///|
fn[T : @json.FromJson] wire_optional(
  fields : Map[String, Json],
  key : String,
  path : @json.JsonPath,
) -> T? raise @json.JsonDecodeError {
  match fields.get(key) {
    None | Some(Null) => None
    Some(value) => Some(@json.from_json(value, path=path.add_key(key)))
  }
}

///|
fn wire_integer(
  fields : Map[String, Json],
  key : String,
  path : @json.JsonPath,
) -> Int32 raise @json.JsonDecodeError {
  guard fields.get(key) is Some(Number(number, ..)) &&
    !number.is_inf() &&
    !number.is_nan() &&
    number >= -2147483648.0 &&
    number <= 2147483647.0 &&
    number == number.floor() else {
    raise @json.JsonDecodeError((path.add_key(key), "expected an integer"))
  }
  number.to_int()
}

///|
fn wire_optional_integer(
  fields : Map[String, Json],
  key : String,
  path : @json.JsonPath,
) -> Int32? raise @json.JsonDecodeError {
  match fields.get(key) {
    None | Some(Null) => None
    Some(_) => Some(wire_integer(fields, key, path))
  }
}

///|
fn[T : ToJson] wire_option(value : T?) -> Json {
  match value {
    None => Json::null()
    Some(value) => Json(value)
  }
}

///|
pub impl ToJson for Provider with fn to_json(self) {
  {
    "id": Json(self.id),
    "contract_version": Json(self.contract_version),
    "engine_version": Json(self.engine_version),
    "operations": Json(self.operations),
    "worker": Json(self.worker),
    "assets": Json(self.assets),
    "workbench": wire_option(self.workbench),
  }
}

///|
pub impl @json.FromJson for Provider with fn from_json(value, path) {
  let fields = wire_fields(value, path, [
    "id", "contract_version", "engine_version", "operations", "worker", "assets",
    "workbench",
  ])
  {
    id: wire_required(fields, "id", path),
    contract_version: wire_integer(fields, "contract_version", path),
    engine_version: wire_required(fields, "engine_version", path),
    operations: wire_required(fields, "operations", path),
    worker: wire_required(fields, "worker", path),
    assets: wire_required(fields, "assets", path),
    workbench: wire_optional(fields, "workbench", path),
  }
}

///|
pub impl ToJson for FileSource with fn to_json(self) {
  {
    "name": Json(self.name),
    "source": Json(self.source),
    "language": Json(self.language),
    "group": Json(self.group),
    "formatter": wire_option(self.formatter),
  }
}

///|
pub impl @json.FromJson for FileSource with fn from_json(value, path) {
  let fields = wire_fields(value, path, [
    "name", "source", "language", "group", "formatter",
  ])
  {
    name: wire_required(fields, "name", path),
    source: wire_required(fields, "source", path),
    language: wire_required(fields, "language", path),
    group: wire_required(fields, "group", path),
    formatter: wire_optional(fields, "formatter", path),
  }
}

///|
pub impl ToJson for Lesson with fn to_json(self) {
  {
    "slug": Json(self.slug),
    "title": Json(self.title),
    "section": Json(self.section),
    "prose": Json(self.prose),
    "references": Json(self.references),
    "files": Json(self.files),
    "execution": wire_option(self.execution),
    "cases": Json(self.cases),
    "editor": wire_option(self.editor),
  }
}

///|
pub impl @json.FromJson for Lesson with fn from_json(value, path) {
  let fields = wire_fields(value, path, [
    "slug", "title", "section", "prose", "references", "files", "execution", "cases",
    "editor",
  ])
  {
    slug: wire_required(fields, "slug", path),
    title: wire_required(fields, "title", path),
    section: wire_required(fields, "section", path),
    prose: wire_required(fields, "prose", path),
    references: wire_required(fields, "references", path),
    files: wire_required(fields, "files", path),
    execution: wire_optional(fields, "execution", path),
    cases: wire_required(fields, "cases", path),
    editor: wire_optional(fields, "editor", path),
  }
}

///|
pub impl ToJson for Diagnostic with fn to_json(self) {
  {
    "key": Json(self.key),
    "code": Json(self.code),
    "severity": Json(self.severity),
    "message": Json(self.message),
    "file": wire_option(self.file),
    "line": wire_option(self.line),
    "column": wire_option(self.column),
    "end_line": wire_option(self.end_line),
    "end_column": wire_option(self.end_column),
  }
}

///|
pub impl @json.FromJson for Diagnostic with fn from_json(value, path) {
  let fields = wire_fields(value, path, [
    "key", "code", "severity", "message", "file", "line", "column", "end_line", "end_column",
  ])
  {
    key: wire_required(fields, "key", path),
    code: wire_required(fields, "code", path),
    severity: wire_required(fields, "severity", path),
    message: wire_required(fields, "message", path),
    file: wire_optional(fields, "file", path),
    line: wire_optional_integer(fields, "line", path),
    column: wire_optional_integer(fields, "column", path),
    end_line: wire_optional_integer(fields, "end_line", path),
    end_column: wire_optional_integer(fields, "end_column", path),
  }
}

///|
pub impl ToJson for Steps with fn to_json(self) {
  {
    "session": Json(self.session),
    "rows": Json(self.rows),
    "checked": Json(self.checked),
    "complete": Json(self.complete),
    "summary": wire_option(self.summary),
  }
}

///|
pub impl @json.FromJson for Steps with fn from_json(value, path) {
  let fields = wire_fields(value, path, [
    "session", "rows", "checked", "complete", "summary",
  ])
  {
    session: wire_required(fields, "session", path),
    rows: wire_required(fields, "rows", path),
    checked: wire_integer(fields, "checked", path),
    complete: wire_required(fields, "complete", path),
    summary: wire_optional(fields, "summary", path),
  }
}

///|
pub impl ToJson for Request with fn to_json(self) {
  {
    "contract_version": Json(self.contract_version),
    "provider": Json(self.provider),
    "engine_version": Json(self.engine_version),
    "generation": Json(self.generation),
    "request_id": Json(self.request_id),
    "input_revision": Json(self.input_revision),
    "operation": Json(self.operation),
    "files": Json(self.files),
    "options": Json(self.options),
    "session": wire_option(self.session),
    "position": wire_option(self.position),
  }
}

///|
pub impl @json.FromJson for Request with fn from_json(value, path) {
  let fields = wire_fields(value, path, [
    "contract_version", "provider", "engine_version", "generation", "request_id",
    "input_revision", "operation", "files", "options", "session", "position",
  ])
  {
    contract_version: wire_integer(fields, "contract_version", path),
    provider: wire_required(fields, "provider", path),
    engine_version: wire_required(fields, "engine_version", path),
    generation: wire_integer(fields, "generation", path),
    request_id: wire_integer(fields, "request_id", path),
    input_revision: wire_required(fields, "input_revision", path),
    operation: wire_required(fields, "operation", path),
    files: wire_required(fields, "files", path),
    options: wire_required(fields, "options", path),
    session: wire_optional(fields, "session", path),
    position: wire_optional_integer(fields, "position", path),
  }
}

///|
pub impl ToJson for Response with fn to_json(self) {
  {
    "contract_version": Json(self.contract_version),
    "provider": Json(self.provider),
    "engine_version": Json(self.engine_version),
    "generation": Json(self.generation),
    "request_id": Json(self.request_id),
    "input_revision": Json(self.input_revision),
    "status": Json(self.status),
    "diagnostics": Json(self.diagnostics),
    "outputs": Json(self.outputs),
    "blocked": wire_option(self.blocked),
    "verdict": wire_option(self.verdict),
    "steps": wire_option(self.steps),
  }
}

///|
pub impl @json.FromJson for Response with fn from_json(value, path) {
  let fields = wire_fields(value, path, [
    "contract_version", "provider", "engine_version", "generation", "request_id",
    "input_revision", "status", "diagnostics", "outputs", "blocked", "verdict", "steps",
  ])
  {
    contract_version: wire_integer(fields, "contract_version", path),
    provider: wire_required(fields, "provider", path),
    engine_version: wire_required(fields, "engine_version", path),
    generation: wire_integer(fields, "generation", path),
    request_id: wire_integer(fields, "request_id", path),
    input_revision: wire_required(fields, "input_revision", path),
    status: wire_required(fields, "status", path),
    diagnostics: wire_required(fields, "diagnostics", path),
    outputs: wire_required(fields, "outputs", path),
    blocked: wire_optional(fields, "blocked", path),
    verdict: wire_optional(fields, "verdict", path),
    steps: wire_optional(fields, "steps", path),
  }
}
