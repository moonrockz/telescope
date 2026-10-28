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
fn[T : ToJson] wire_option(value : T?) -> Json {
  match value {
    None => Json::null()
    Some(value) => Json(value)
  }
}

///|
pub impl ToJson for Expectation with fn to_json(self) {
  {
    "diagnostic_keys": Json(self.diagnostic_keys),
    "outputs": Json(self.outputs),
    "blocked": wire_option(self.blocked),
    "verdict": wire_option(self.verdict),
    "steps": wire_option(self.steps),
  }
}

///|
pub impl @json.FromJson for Expectation with fn from_json(value, path) {
  let fields = wire_fields(value, path, [
    "diagnostic_keys", "outputs", "blocked", "verdict", "steps",
  ])
  {
    diagnostic_keys: wire_required(fields, "diagnostic_keys", path),
    outputs: wire_required(fields, "outputs", path),
    blocked: wire_optional(fields, "blocked", path),
    verdict: wire_optional(fields, "verdict", path),
    steps: wire_optional(fields, "steps", path),
  }
}

///|
pub impl ToJson for ReferenceEvidence with fn to_json(self) {
  {
    "source": Json(self.source),
    "source_revision": Json(self.source_revision),
    "input_revision": Json(self.input_revision),
    "differences": Json(self.differences),
    "required": Json(self.required),
  }
}

///|
pub impl @json.FromJson for ReferenceEvidence with fn from_json(value, path) {
  let fields = wire_fields(value, path, [
    "source", "source_revision", "input_revision", "differences", "required",
  ])
  {
    source: wire_required(fields, "source", path),
    source_revision: wire_required(fields, "source_revision", path),
    input_revision: wire_required(fields, "input_revision", path),
    differences: wire_required(fields, "differences", path),
    required: wire_required(fields, "required", path),
  }
}

///|
pub impl ToJson for CaseReport with fn to_json(self) {
  {
    "source": Json(self.source),
    "course": Json(self.course),
    "lesson": Json(self.lesson),
    "case_id": Json(self.case_id),
    "provider": Json(self.provider),
    "engine_version": Json(self.engine_version),
    "input_revision": Json(self.input_revision),
    "passed": Json(self.passed),
    "mismatches": Json(self.mismatches),
    "reference": wire_option(self.reference),
  }
}

///|
pub impl @json.FromJson for CaseReport with fn from_json(value, path) {
  let fields = wire_fields(value, path, [
    "source", "course", "lesson", "case_id", "provider", "engine_version", "input_revision",
    "passed", "mismatches", "reference",
  ])
  {
    source: wire_required(fields, "source", path),
    course: wire_required(fields, "course", path),
    lesson: wire_required(fields, "lesson", path),
    case_id: wire_required(fields, "case_id", path),
    provider: wire_required(fields, "provider", path),
    engine_version: wire_required(fields, "engine_version", path),
    input_revision: wire_required(fields, "input_revision", path),
    passed: wire_required(fields, "passed", path),
    mismatches: wire_required(fields, "mismatches", path),
    reference: wire_optional(fields, "reference", path),
  }
}

///|
pub impl ToJson for SourceEvidence with fn to_json(self) {
  {
    "runner": Json(self.runner),
    "source_revision": Json(self.source_revision),
    "input_revision": Json(self.input_revision),
    "success": Json(self.success),
    "required": Json(self.required),
  }
}

///|
pub impl @json.FromJson for SourceEvidence with fn from_json(value, path) {
  let fields = wire_fields(value, path, [
    "runner", "source_revision", "input_revision", "success", "required",
  ])
  {
    runner: wire_required(fields, "runner", path),
    source_revision: wire_required(fields, "source_revision", path),
    input_revision: wire_required(fields, "input_revision", path),
    success: wire_required(fields, "success", path),
    required: wire_required(fields, "required", path),
  }
}

///|
pub impl ToJson for SourcePolicy with fn to_json(self) {
  {
    "source": Json(self.source),
    "regions": Json(self.regions),
    "languages": Json(self.languages),
    "runner": Json(self.runner),
    "marker_start": Json(self.marker_start),
    "marker_end": Json(self.marker_end),
    "evidence": wire_option(self.evidence),
    "evidence_by_input": Json(self.evidence_by_input),
  }
}

///|
pub impl @json.FromJson for SourcePolicy with fn from_json(value, path) {
  let fields = wire_fields(value, path, [
    "source", "regions", "languages", "runner", "marker_start", "marker_end", "evidence",
    "evidence_by_input",
  ])
  {
    source: wire_required(fields, "source", path),
    regions: wire_required(fields, "regions", path),
    languages: wire_required(fields, "languages", path),
    runner: wire_required(fields, "runner", path),
    marker_start: wire_required(fields, "marker_start", path),
    marker_end: wire_required(fields, "marker_end", path),
    evidence: wire_optional(fields, "evidence", path),
    evidence_by_input: wire_required(fields, "evidence_by_input", path),
  }
}

///|
pub impl ToJson for IncludedRegion with fn to_json(self) {
  {
    "source": Json(self.source),
    "region": Json(self.region),
    "language": Json(self.language),
    "text": Json(self.text),
    "blocks": Json(self.blocks),
    "runner": Json(self.runner),
    "source_revision": Json(self.source_revision),
    "verified": Json(self.verified),
  }
}

///|
pub impl @json.FromJson for IncludedRegion with fn from_json(value, path) {
  let fields = wire_fields(value, path, [
    "source", "region", "language", "text", "blocks", "runner", "source_revision",
    "verified",
  ])
  {
    source: wire_required(fields, "source", path),
    region: wire_required(fields, "region", path),
    language: wire_required(fields, "language", path),
    text: wire_required(fields, "text", path),
    blocks: wire_required(fields, "blocks", path),
    runner: wire_required(fields, "runner", path),
    source_revision: wire_required(fields, "source_revision", path),
    verified: wire_required(fields, "verified", path),
  }
}
