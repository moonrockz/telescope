///|
pub(all) struct OutputExpectation {
  id : String
  contains : Array[String]
} derive(Eq, Debug, ToJson, FromJson)

///|
pub(all) struct StepExpectation {
  checked : Int32
  complete : Bool
  diagnostic_keys : Array[String]
} derive(Eq, Debug, ToJson, FromJson)

///|
pub(all) struct Expectation {
  diagnostic_keys : Array[String]
  outputs : Array[OutputExpectation]
  blocked : String?
  verdict : String?
  steps : StepExpectation?
} derive(Eq, Debug)

///|
fn invalid(
  file : String,
  path : String,
  message : String,
) -> Unit raise @base.Invalid {
  raise @base.Invalid([@base.problem(file, path + ": " + message)])
}

///|
fn fields(
  file : String,
  path : String,
  value : Json,
  allowed : Array[String],
) -> Map[String, Json] raise @base.Invalid {
  guard value is Object(found) else {
    invalid(file, path, "expected an object")
    return Map([])
  }
  for key, _ in found {
    if !allowed.contains(key) {
      invalid(file, path + "." + key, "unknown assertion")
    }
  }
  found
}

///|
fn texts(
  file : String,
  path : String,
  value : Json,
) -> Array[String] raise @base.Invalid {
  guard value is Array(values) else {
    invalid(file, path, "expected an array")
    return []
  }
  values.map(value => {
    match value {
      String(text) if text != "" => text
      _ => {
        invalid(file, path, "expected nonempty strings")
        ""
      }
    }
  })
}

///|
fn optional_text(
  file : String,
  path : String,
  value : Json?,
) -> String? raise @base.Invalid {
  value.map(v => {
    match v {
      String(text) if text != "" => text
      _ => {
        invalid(file, path, "expected a nonempty string")
        ""
      }
    }
  })
}

///|
pub fn Expectation::parse(
  file : String,
  text : String,
) -> Expectation raise @base.Invalid {
  let value = @json.parse(text) catch {
    error =>
      raise @base.Invalid([
        @base.problem(file, "invalid expectation JSON: \{error}"),
      ])
  }
  let root = fields(file, "expect", value, [
    "diagnostic_keys", "outputs", "blocked", "verdict", "steps",
  ])
  let diagnostic_keys = match root.get("diagnostic_keys") {
    Some(value) => texts(file, "expect.diagnostic_keys", value)
    None => {
      invalid(
        file, "expect.diagnostic_keys", "complete diagnostic key array is required",
      )
      []
    }
  }
  let outputs = match root.get("outputs") {
    None => []
    Some(Array(values)) =>
      values.mapi((i, value) => {
        let at = "expect.outputs[\{i}]"
        let item = fields(file, at, value, ["id", "contains"])
        let id = optional_text(file, at + ".id", item.get("id")).unwrap_or("")
        if id == "" {
          invalid(file, at + ".id", "required")
        }
        let contains = match item.get("contains") {
          Some(value) => texts(file, at + ".contains", value)
          None => {
            invalid(file, at + ".contains", "required")
            []
          }
        }
        if contains.is_empty() {
          invalid(
            file,
            at + ".contains",
            "at least one nonempty needle is required",
          )
        }
        OutputExpectation::{ id, contains, }
      })
    _ => {
      invalid(file, "expect.outputs", "expected an array")
      []
    }
  }
  let seen : Map[String, Bool] = Map([])
  for output in outputs {
    if seen.contains(output.id) {
      invalid(file, "expect.outputs", "duplicate output id " + output.id)
    }
    seen[output.id] = true
  }
  let steps = root
    .get("steps")
    .map(value => {
      let item = fields(file, "expect.steps", value, [
        "checked", "complete", "diagnostic_keys",
      ])
      let checked = match item.get("checked") {
        Some(Number(value, ..)) if value >= 0.0 &&
          value == value.to_int().to_double() => value.to_int()
        _ => {
          invalid(
            file, "expect.steps.checked", "expected a nonnegative integer",
          )
          0
        }
      }
      let complete = match item.get("complete") {
        Some(True) => true
        Some(False) => false
        _ => {
          invalid(file, "expect.steps.complete", "expected a boolean")
          false
        }
      }
      let keys = match item.get("diagnostic_keys") {
        Some(value) => texts(file, "expect.steps.diagnostic_keys", value)
        None => {
          invalid(file, "expect.steps.diagnostic_keys", "required")
          []
        }
      }
      StepExpectation::{ checked, complete, diagnostic_keys: keys, }
    })
  let blocked = optional_text(file, "expect.blocked", root.get("blocked"))
  if blocked is Some(_) && !outputs.is_empty() {
    invalid(file, "expect", "blocked and successful output assertions conflict")
  }
  {
    diagnostic_keys,
    outputs,
    blocked,
    verdict: optional_text(file, "expect.verdict", root.get("verdict")),
    steps,
  }
}

///|
fn compare_keys(
  expected : Array[String],
  actual : Array[String],
  path : String,
  problems : Array[String],
) -> Unit {
  let wanted = expected.copy()
  let found = actual.copy()
  wanted.sort()
  found.sort()
  if wanted != found {
    problems.push(
      path +
      ": expected " +
      Json(wanted).stringify() +
      ", found " +
      Json(found).stringify(),
    )
  }
}

///|
pub fn compare(
  expect : Expectation,
  actual : @tutorial.Response,
) -> Array[String] {
  let problems = []
  if actual.status == "error" {
    problems.push("evaluator returned error status")
  }
  compare_keys(
    expect.diagnostic_keys,
    actual.diagnostics.map(d => d.key),
    "diagnostic_keys",
    problems,
  )
  match (expect.blocked, actual.blocked) {
    (Some(needle), Some(reason)) =>
      if actual.status != "blocked" || !reason.contains(needle) {
        problems.push("blocked reason/status mismatch")
      }
    (Some(_), None) => problems.push("expected blocked output")
    (None, Some(_)) => problems.push("unexpected blocked output")
    _ => ()
  }
  if expect.verdict is Some(verdict) && actual.verdict != Some(verdict) {
    problems.push("verdict mismatch")
  }
  for output in expect.outputs {
    match actual.outputs.iter().find_first(item => item.id == output.id) {
      None => problems.push("missing output " + output.id)
      Some(found) =>
        for needle in output.contains {
          if !found.text.contains(needle) {
            problems.push("output " + output.id + " missing needle " + needle)
          }
        }
    }
  }
  if expect.steps is Some(wanted) {
    match actual.steps {
      None => problems.push("step assertion unsupported by actual result")
      Some(found) => {
        if wanted.checked != found.checked || wanted.complete != found.complete {
          problems.push("step progress mismatch")
        }
        let keys = []
        for row in found.rows {
          keys.append(row.diagnostics.map(d => d.key))
        }
        compare_keys(
          wanted.diagnostic_keys,
          keys,
          "steps.diagnostic_keys",
          problems,
        )
      }
    }
  }
  problems
}

///|
pub(all) struct ReferenceDifference {
  reason : String
  tracking : String
} derive(Eq, Debug, ToJson, FromJson)

///|
pub(all) struct ReferenceEvidence {
  source : String
  source_revision : String
  input_revision : String
  differences : Array[ReferenceDifference]
  required : Bool
} derive(Eq, Debug)

///|
pub(all) struct ReferenceRegistration {
  id : String
  compare : (@tutorial.Request, @tutorial.Response, ReferenceEvidence) -> Result[
    Array[String],
    String,
  ]
}

///|
pub fn reference_problems(
  evidence : ReferenceEvidence,
  input_revision : String,
) -> Array[String] {
  let problems = []
  if evidence.source == "" || evidence.source_revision == "" {
    problems.push("reference evidence requires pinned source identity")
  }
  if evidence.input_revision != input_revision && evidence.required {
    problems.push("required reference evidence is stale")
  }
  for difference in evidence.differences {
    if difference.reason == "" || difference.tracking == "" {
      problems.push(
        "reference differences require reason and tracking reference",
      )
    }
  }
  problems
}

///|
pub(all) struct CaseReport {
  source : String
  course : String
  lesson : String
  case_id : String
  provider : String
  engine_version : String
  input_revision : String
  passed : Bool
  mismatches : Array[String]
  reference : ReferenceEvidence?
} derive(Eq, Debug)

///|
pub fn reports_text(reports : Array[CaseReport]) -> String {
  reports
  .map(report => {
    "\{report.source}: \{report.course}/\{report.lesson}/\{report.case_id}: " +
    (if report.passed { "PASS" } else { "FAIL" }) +
    " [\{report.provider}@\{report.engine_version}] input_revision=" +
    report.input_revision +
    "\n" +
    report.mismatches.map(m => "  " + m + "\n").join("")
  })
  .join("")
}

///|
pub extend OutputExpectation with Eq::{equal, not_equal}

///|
pub extend OutputExpectation with @debug.Debug::{to_repr}

///|
pub extend OutputExpectation with ToJson::{to_json}

///|
pub extend OutputExpectation with @json.FromJson::{from_json}

///|
pub extend StepExpectation with Eq::{equal, not_equal}

///|
pub extend StepExpectation with @debug.Debug::{to_repr}

///|
pub extend StepExpectation with ToJson::{to_json}

///|
pub extend StepExpectation with @json.FromJson::{from_json}

///|
pub extend Expectation with Eq::{equal, not_equal}

///|
pub extend Expectation with @debug.Debug::{to_repr}

///|
pub extend Expectation with ToJson::{to_json}

///|
pub extend Expectation with @json.FromJson::{from_json}

///|
pub extend ReferenceDifference with Eq::{equal, not_equal}

///|
pub extend ReferenceDifference with @debug.Debug::{to_repr}

///|
pub extend ReferenceDifference with ToJson::{to_json}

///|
pub extend ReferenceDifference with @json.FromJson::{from_json}

///|
pub extend ReferenceEvidence with Eq::{equal, not_equal}

///|
pub extend ReferenceEvidence with @debug.Debug::{to_repr}

///|
pub extend ReferenceEvidence with ToJson::{to_json}

///|
pub extend ReferenceEvidence with @json.FromJson::{from_json}

///|
pub extend CaseReport with Eq::{equal, not_equal}

///|
pub extend CaseReport with @debug.Debug::{to_repr}

///|
pub extend CaseReport with ToJson::{to_json}

///|
pub extend CaseReport with @json.FromJson::{from_json}
