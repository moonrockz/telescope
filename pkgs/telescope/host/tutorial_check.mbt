///|
/// A native runner can isolate consumer code in a cancellable subprocess.
pub(all) struct TutorialRunner {
  provider : String
  engine_version : String
  contract_version : Int32
  operations : Array[String]
  evaluate : async (@tutorial.Request) -> Result[@tutorial.Response, String]
}

///|
/// Execute a compiled consumer driver, passing one JSON request on stdin.
/// No shell interpretation or manifest-selected executable is involved.
pub fn process_runner(
  provider : @tutorial.Provider,
  command : String,
  args : Array[String],
  cwd~ : String = ".",
) -> TutorialRunner {
  {
    provider: provider.id,
    engine_version: provider.engine_version,
    contract_version: provider.contract_version,
    operations: provider.operations,
    evaluate: request => {
      let temp = @fs.tmpdir(prefix="telescope-case-input")
      defer @fs.rmdir(temp, recursive=true)
      @fs.write_file(temp + "/request.json", request.to_json().stringify())
      let stdin = @process.redirect_from_file(temp + "/request.json")
      let (code, stdout, stderr) = @process.collect_output(
        command,
        args,
        cwd~,
        stdin~,
      )
      if code != 0 {
        return Err("evaluator exited \{code}: " + stderr.text())
      }
      try @json.from_json(@json.parse(stdout.text())) catch {
        error => Err("invalid evaluator response: \{error}")
      } noraise {
        result => Ok(result)
      }
    },
  }
}

///|
pub(all) struct TutorialReference {
  course : String
  lesson : String
  case_id : String
  evidence : @tutorial_check.ReferenceEvidence
  registration : @tutorial_check.ReferenceRegistration
}

///|
/// Case execution is separate from build and from the built-site link checker.
/// Each case receives fresh input and its own process/session. Runners must yield
/// to cancellation; process_runner provides an isolated cancellable boundary.
pub async fn check_tutorials(
  root : String,
  config_path : String,
  runners~ : Array[TutorialRunner] = [],
  policies~ : Array[@tutorial_check.SourcePolicy] = [],
  references~ : Array[TutorialReference] = [],
  timeout_ms~ : Int32 = 10000,
  max_cases~ : Int32 = 1000,
  max_steps~ : Int32 = 1000,
) -> Array[@tutorial_check.CaseReport] {
  guard timeout_ms > 0 && max_cases > 0 && max_steps > 0 else {
    raise @model.Invalid([
      @model.problem(config_path, "case runner limits must be positive"),
    ])
  }
  let root = canonical_path(root)
  let config_real = canonical_path(config_path)
  guard within(root, config_real) else {
    raise @model.Invalid([
      @model.problem(config_path, "configuration escapes project root"),
    ])
  }
  let input = tutorial_input(
    root,
    @json.parse(@fs.read_file(config_real).text()),
  )
  guard input is Some(input) else { return [] }
  let source_reports = check_tutorial_sources(root, config_path, policies~)
  let source_problems = []
  for report in source_reports {
    source_problems.append(
      report.problems.map(message => @model.problem(report.source, message)),
    )
  }
  if !source_problems.is_empty() {
    raise @model.Invalid(source_problems)
  }
  let reports = []
  let seen : Map[String, Bool] = Map([])
  for runner in runners {
    if seen.contains(runner.provider) {
      raise @model.Invalid([
        @model.problem(
          input.source,
          "duplicate compiled runner " + runner.provider,
        ),
      ])
    }
    seen[runner.provider] = true
  }
  for course in input.manifest.courses {
    for lesson in course.lessons {
      guard lesson.execution is Some(execution) else { continue }
      let provider = input.manifest.providers
        .iter()
        .find_first(p => p.id == execution.provider)
        .unwrap()
      let starting = tutorial_files(input, lesson.files)
      let cases = lesson.cases.copy()
      cases.sort_by((a, b) => a.id.compare(b.id))
      for case in cases {
        guard reports.length() < max_cases else {
          raise @model.Invalid([
            @model.problem(
              input.source,
              "case count exceeds finite runner limit",
            ),
          ])
        }
        let files = @tutorial.overlay_files(
          starting,
          tutorial_files(input, case.files),
        )
        let input_revision = @tutorial.input_revision(
          provider,
          execution.operation,
          execution.options,
          files,
        )
        let expectation = @tutorial_check.Expectation::parse(
          case.expect,
          @fs.read_file(checked_file(input.root, case.expect)).text(),
        )
        let mismatches = []
        let runner = runners.iter().find_first(r => r.provider == provider.id)
        let mut reference = None
        let request : @tutorial.Request = {
          contract_version: 1,
          provider: provider.id,
          engine_version: provider.engine_version,
          generation: 1,
          request_id: 1,
          input_revision,
          operation: execution.operation,
          files,
          options: execution.options,
          session: None,
          position: expectation.steps.map(s => s.checked),
        }
        if runner is Some(runner) {
          if runner.contract_version != 1 ||
            runner.engine_version != provider.engine_version ||
            !provider.operations
            .iter()
            .all(op => runner.operations.contains(op)) {
            mismatches.push(
              "compiled evaluator provider/version/capability mismatch",
            )
          } else {
            let result = @async.with_timeout(timeout_ms, () => {
              let initial = (runner.evaluate)(request)
              guard initial is Ok(initial) else { return initial }
              let mut response = initial
              let mut round = 0
              if expectation.steps is Some(expected) {
                if execution.operation != "start" {
                  return Err("step assertions require start capability")
                }
                while response.steps is Some(steps) &&
                      !steps.complete &&
                      steps.checked < expected.checked {
                  if round >= max_steps || !provider.operations.contains("step") {
                    return Err(
                      "step replay exceeds limit or provider capability",
                    )
                  }
                  let next = {
                    ..request,
                    operation: "step",
                    session: Some(steps.session),
                    request_id: round + 2,
                  }
                  let checked = @tutorial.response_problems(
                    if round == 0 {
                      request
                    } else {
                      {
                        ..request,
                        operation: "step",
                        request_id: round + 1,
                        session: Some(steps.session),
                      }
                    },
                    response,
                  )
                  if !checked.is_empty() {
                    return Err(checked.join("; "))
                  }
                  let next_result = (runner.evaluate)(next)
                  guard next_result is Ok(value) else { return next_result }
                  let errors = @tutorial.response_problems(next, value)
                  if !errors.is_empty() {
                    return Err(errors.join("; "))
                  }
                  if value.steps is Some(next_steps) &&
                    next_steps.checked <= steps.checked &&
                    !next_steps.complete {
                    return Err("step evaluator made no progress")
                  }
                  response = value
                  round += 1
                }
              }
              // Validate the final response against its latest request identity.
              let final_request = if round == 0 {
                request
              } else {
                { ..request, request_id: round + 1, }
              }
              let errors = @tutorial.response_problems(final_request, response)
              if !errors.is_empty() {
                return Err(errors.join("; "))
              }
              Ok(response)
            }) catch {
              error => Err("evaluator failed or timed out: \{error}")
            }
            match result {
              Err(message) => mismatches.push(message)
              Ok(response) => {
                mismatches.append(
                  @tutorial_check.compare(expectation, response),
                )
                for hook in references {
                  if hook.course == course.id &&
                    hook.lesson == lesson.slug &&
                    hook.case_id == case.id {
                    reference = Some(hook.evidence)
                    mismatches.append(
                      @tutorial_check.reference_problems(
                        hook.evidence,
                        input_revision,
                      ),
                    )
                    match
                      (hook.registration.compare)(
                        request,
                        response,
                        hook.evidence,
                      ) {
                      Ok(found) => mismatches.append(found)
                      Err(message) =>
                        mismatches.push(
                          "reference comparison unavailable: " + message,
                        )
                    }
                  }
                }
              }
            }
          }
        } else {
          mismatches.push("missing compiled evaluator for " + provider.id)
        }
        let prose = @fs.read_file(checked_file(input.root, lesson.prose)).text()
        for entry in @tutorial_check.parse_includes(lesson.prose, prose) {
          match policies.iter().find_first(p => p.source == entry.path) {
            None =>
              mismatches.push(
                "include has no consumer source policy: " + entry.path,
              )
            Some(policy) => {
              let text = @fs.read_file(checked_file(input.root, entry.path)).text()
              let region = @tutorial_check.extract_region(
                entry.path,
                text,
                entry.region,
                policy,
              )
              mismatches.append(
                @tutorial_check.source_evidence_problems(
                  policy,
                  region.source_revision,
                  input_revision,
                ),
              )
            }
          }
        }
        reports.push(@tutorial_check.CaseReport::{
          source: input.source,
          course: course.id,
          lesson: lesson.slug,
          case_id: case.id,
          provider: provider.id,
          engine_version: provider.engine_version,
          input_revision,
          passed: mismatches.is_empty(),
          mismatches,
          reference,
        })
      }
    }
  }
  reports
}

///|
/// Structural source coverage and runner evidence are separate from case results.
pub(all) struct TutorialSourceReport {
  source : String
  course : String
  lesson : String
  region : String
  runner : String
  source_revision : String
  input_revision : String
  covered : Bool
  verified : Bool
  problems : Array[String]
} derive(ToJson)

///|
pub extend TutorialSourceReport with ToJson::{to_json}

///|
pub async fn check_tutorial_sources(
  root : String,
  config_path : String,
  policies~ : Array[@tutorial_check.SourcePolicy] = [],
) -> Array[TutorialSourceReport] {
  let root = canonical_path(root)
  let config_real = canonical_path(config_path)
  guard within(root, config_real) else {
    raise @model.Invalid([
      @model.problem(config_path, "configuration escapes project root"),
    ])
  }
  let input = tutorial_input(
    root,
    @json.parse(@fs.read_file(config_real).text()),
  )
  guard input is Some(input) else { return [] }
  let reports = []
  for course in input.manifest.courses {
    for lesson in course.lessons {
      let prose = @fs.read_file(checked_file(input.root, lesson.prose)).text()
      let revision = match lesson.execution {
        Some(execution) => {
          let provider = input.manifest.providers
            .iter()
            .find_first(p => p.id == execution.provider)
            .unwrap()
          @tutorial.input_revision(
            provider,
            execution.operation,
            execution.options,
            tutorial_files(input, lesson.files),
          )
        }
        None => @tutorial.revision(Json(prose))
      }
      for entry in @tutorial_check.parse_includes(lesson.prose, prose) {
        let policy = policies
          .iter()
          .find_first(policy => policy.source == entry.path)
        let problems = []
        let mut source_revision = ""
        let mut verified = false
        let mut runner = ""
        if policy is Some(policy) {
          runner = policy.runner
          let region = @tutorial_check.extract_region(
            entry.path,
            @fs.read_file(checked_file(input.root, entry.path)).text(),
            entry.region,
            policy,
          )
          source_revision = region.source_revision
          problems.append(
            @tutorial_check.source_evidence_problems(
              policy, source_revision, revision,
            ),
          )
          verified = @tutorial_check.source_evidence(policy, revision)
            is Some(evidence) &&
            evidence.success &&
            evidence.runner == runner &&
            evidence.source_revision == source_revision &&
            evidence.input_revision == revision
        } else {
          problems.push("include has no consumer source policy")
        }
        reports.push({
          source: entry.path,
          course: course.id,
          lesson: lesson.slug,
          region: entry.region,
          runner,
          source_revision,
          input_revision: revision,
          covered: policy is Some(_),
          verified,
          problems,
        })
      }
    }
  }
  reports
}
