// Original qualification engine, Apache-2.0. No domain compiler dependencies.

///|
pub(all) struct TextEvaluator {}

///|
pub impl @tutorial.Evaluator for TextEvaluator with fn evaluate(_, request) {
  evaluate(request)
}

///|
pub extend TextEvaluator with @tutorial.Evaluator::{evaluate}

///|
pub fn registration() -> @tutorial.EvaluatorRegistration {
  {
    provider: "sample.text",
    engine_version: "1.0.0",
    contract_version: 1,
    operations: ["evaluate", "start", "step", "run-all"],
    evaluate,
  }
}

///|
fn flag(options : Json, key : String) -> Bool {
  match options {
    Object(fields) => fields.get(key) is Some(True)
    _ => false
  }
}

///|
fn finding(
  key : String,
  code : String,
  message : String,
  file : String?,
  line : Int32?,
) -> @tutorial.Diagnostic {
  {
    key,
    code,
    severity: "error",
    message,
    file,
    line,
    column: if line is Some(_) {
      Some(1)
    } else {
      None
    },
    end_line: None,
    end_column: None,
  }
}

///|
fn file_findings(file : @tutorial.File) -> Array[@tutorial.Diagnostic] {
  file.text
  .split("\n")
  .to_array()
  .mapi((i, line) => {
    if line.contains("ERROR") {
      Some(
        finding(
          file.name + ":ERROR",
          "ERROR",
          "ERROR marker in " + file.name,
          Some(file.name),
          Some(i + 1),
        ),
      )
    } else {
      None
    }
  })
  .filter_map(item => item)
}

///|
pub fn evaluate(
  request : @tutorial.Request,
) -> Result[@tutorial.Response, @tutorial.EvaluationError] {
  if request.contract_version != 1 ||
    request.provider != "sample.text" ||
    request.engine_version != "1.0.0" {
    return Err({
      code: "VERSION",
      message: "unsupported text engine protocol or version",
    })
  }
  if !["evaluate", "start", "step", "run-all"].contains(request.operation) {
    return Err({ code: "OPERATION", message: "unsupported text operation", })
  }
  let base = @tutorial.response_for(request)
  if flag(request.options, "uppercase") && flag(request.options, "lowercase") {
    return Ok({
      ..base,
      status: "blocked",
      diagnostics: [
        finding(
          "options:conflict",
          "OPTIONS",
          "uppercase and lowercase are mutually exclusive",
          None,
          None,
        ),
      ],
      blocked: Some("conflicting text options"),
      verdict: Some("invalid"),
    })
  }
  let raw = request.files.map(file => file.text).join("\n")
  let text = if flag(request.options, "uppercase") {
    raw.to_upper()
  } else if flag(request.options, "lowercase") {
    raw.to_lower()
  } else {
    raw
  }
  let outputs : Array[@tutorial.Output] = [
    { id: "text", label: "Text", language: "text", text, },
  ]
  let diagnostics = []
  for file in request.files {
    diagnostics.append(file_findings(file))
  }
  let old = request.files.filter(f => f.group.to_lower() == "old")
  let new = request.files.filter(f => f.group.to_lower() == "new")
  if !old.is_empty() || !new.is_empty() {
    let old_text = old.map(f => f.text).join("\n")
    let new_text = new.map(f => f.text).join("\n")
    outputs.push({
      id: "comparison",
      label: "Comparison",
      language: "text",
      text: if old_text == new_text {
        "same"
      } else {
        "changed\n- " + old_text + "\n+ " + new_text
      },
    })
  }
  if request.operation == "evaluate" {
    return Ok({
      ..base,
      diagnostics,
      outputs,
      verdict: Some(if diagnostics.is_empty() { "valid" } else { "invalid" }),
    })
  }
  let entries : Array[(String, String, Int32)] = []
  for file in request.files {
    let lines = file.text.split("\n").to_array()
    for i, line in lines {
      if file.text == "" || (i == lines.length() - 1 && line == "") {
        continue
      }
      entries.push((file.name, line.to_owned(), i + 1))
    }
  }
  let previous = request.session.map_or(0, session => {
    if session.has_prefix("text:") {
      @string.parse_int(session[5:]) catch {
        _ => 0
      }
    } else {
      0
    }
  })
  let checked = if request.operation == "run-all" {
    entries.length()
  } else if request.operation == "start" {
    0
  } else {
    Int32::min(
      entries.length(),
      Int32::max(0, request.position.unwrap_or(previous + 1)),
    )
  }
  let findings = []
  let rows = entries.mapi((i, entry) => {
    let diagnostics = if i < checked && entry.1.contains("ERROR") {
      [
        finding(
          entry.0 + ":ERROR",
          "ERROR",
          "ERROR marker in " + entry.0,
          Some(entry.0),
          Some(entry.2),
        ),
      ]
    } else {
      []
    }
    findings.append(diagnostics)
    @tutorial.StepRow::{
      id: "\{i+1}",
      label: "Line \{i+1}",
      text: entry.1,
      diagnostics,
    }
  })
  Ok({
    ..base,
    diagnostics: findings,
    outputs,
    verdict: Some(if findings.is_empty() { "valid" } else { "invalid" }),
    steps: Some({
      session: "text:\{checked}",
      rows,
      checked,
      complete: checked == entries.length(),
      summary: Some("Checked \{checked} of \{entries.length()} lines"),
    }),
  })
}
