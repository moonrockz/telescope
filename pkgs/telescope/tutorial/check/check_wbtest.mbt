///|
fn expect_error(text : String) -> String {
  try {
    ignore(Expectation::parse("case.json", text))
    ""
  } catch {
    @base.Invalid(errors) => errors.map(p => p.render()).join("\n")
  }
}

///|
fn sample_response() -> @tutorial.Response {
  {
    contract_version: 1,
    provider: "text",
    engine_version: "1",
    generation: 1,
    request_id: 1,
    input_revision: "current",
    status: "success",
    diagnostics: [],
    outputs: [],
    blocked: None,
    verdict: None,
    steps: None,
  }
}

///|
fn diagnostic(key : String) -> @tutorial.Diagnostic {
  {
    key,
    code: "E1",
    severity: "error",
    message: "<script>literal</script>",
    file: Some("input.txt"),
    line: Some(1),
    column: Some(2),
    end_line: None,
    end_column: None,
  }
}

///|
test "diagnostic keys compare as a multiset and negative inputs pass" {
  let expect = Expectation::parse(
    "case.json", "{\"diagnostic_keys\":[\"a\",\"a\",\"b\"]}",
  )
  let actual = {
    ..sample_response(),
    diagnostics: [diagnostic("b"), diagnostic("a"), diagnostic("a")],
  }
  assert_true(compare(expect, actual).is_empty())
  assert_true(
    !compare(expect, {
      ..actual,
      diagnostics: [diagnostic("a"), diagnostic("b")],
    }).is_empty(),
  )
  assert_true(
    !compare(expect, {
      ..actual,
      diagnostics: actual.diagnostics + [diagnostic("c")],
    }).is_empty(),
  )
}

///|
test "expectation structure rejects empty needles unknown assertions and incompatible states" {
  for
    text in [
      "{}", "{\"diagnostic_keys\":[],\"ignore\":true}", "{\"diagnostic_keys\":[],\"outputs\":[{\"id\":\"result\",\"contains\":[\"\"]}]}",
      "{\"diagnostic_keys\":[],\"outputs\":[{\"id\":\"result\",\"contains\":[]}]}",
      "{\"diagnostic_keys\":[],\"steps\":{\"checked\":-1,\"complete\":true,\"diagnostic_keys\":[]}}",
      "{\"diagnostic_keys\":[],\"blocked\":\"reason\",\"outputs\":[{\"id\":\"x\",\"contains\":[\"needle\"]}]}",
    ] {
    assert_true(expect_error(text).contains("case.json"))
  }
}

///|
test "outputs blocked states verdict and step findings are observable assertions" {
  let expect = Expectation::parse(
    "case.json", "{\"diagnostic_keys\":[],\"outputs\":[{\"id\":\"out\",\"contains\":[\"<script>\",\"line two\"]}],\"verdict\":\"valid\",\"steps\":{\"checked\":2,\"complete\":true,\"diagnostic_keys\":[\"step\"]}}",
  )
  let actual = {
    ..sample_response(),
    outputs: [
      {
        id: "out",
        label: "Output",
        language: "text",
        text: "<script>\nline two",
      },
    ],
    verdict: Some("valid"),
    steps: Some({
      session: "s",
      rows: [
        {
          id: "1",
          label: "first",
          diagnostics: [diagnostic("step")],
          text: "",
        },
        { id: "2", label: "second", diagnostics: [], text: "", },
      ],
      checked: 2,
      complete: true,
      summary: None,
    }),
  }
  assert_true(compare(expect, actual).is_empty())
  assert_true(!compare(expect, { ..actual, steps: None, }).is_empty())
  assert_true(
    !compare(expect, { ..actual, verdict: Some("invalid"), }).is_empty(),
  )
  let blocked = Expectation::parse(
    "blocked.json", "{\"diagnostic_keys\":[],\"blocked\":\"cannot convert\"}",
  )
  assert_true(
    compare(blocked, {
      ..sample_response(),
      status: "blocked",
      blocked: Some("cannot convert input"),
    }).is_empty(),
  )
  assert_true(!compare(blocked, sample_response()).is_empty())
  assert_true(
    !compare(blocked, {
      ..sample_response(),
      blocked: Some("cannot convert input"),
    }).is_empty(),
  )
}

///|
let tested_source : String =
  #|Outside
  #|<!-- tutorial:start cli -->
  #|```sh
  #|printf 'hello'
  #|# tutorial:end pretend
  #|```
  #|<!-- tutorial:end cli -->

///|
fn region_error(text : String, policy : SourcePolicy) -> String {
  try {
    ignore(extract_region("tests/source.md", text, "cli", policy))
    ""
  } catch {
    @base.Invalid(errors) => errors.map(p => p.render()).join("\n")
  }
}

///|
test "source regions preserve exact code and ignore marker-shaped lines inside fences" {
  let policy = source_policy("tests/source.md", ["cli"], ["sh"], "sample-tests")
  let included = extract_region("tests/source.md", tested_source, "cli", policy)
  assert_eq(included.language, "sh")
  assert_eq(included.text, "printf 'hello'\n# tutorial:end pretend\n")
  assert_true(!included.verified)
  assert_eq(included.blocks.length(), 1)
  let evidence : SourceEvidence = {
    runner: "sample-tests",
    source_revision: included.source_revision,
    input_revision: "r",
    success: true,
    required: true,
  }
  let contextual_policy = { ..policy, evidence: Some(evidence), }
  assert_true(
    !extract_region("tests/source.md", tested_source, "cli", contextual_policy).verified,
  )
  let verified = extract_region(
    "tests/source.md",
    tested_source,
    "cli",
    contextual_policy,
    input_revision=Some("r"),
  )
  assert_true(verified.verified)
  assert_true(
    !extract_region(
      "tests/source.md",
      tested_source,
      "cli",
      contextual_policy,
      input_revision=Some("old"),
    ).verified,
  )
  assert_true(
    source_evidence_problems(
      { ..policy, evidence: Some(evidence), },
      included.source_revision,
      "r",
    ).is_empty(),
  )
  assert_true(
    !source_evidence_problems(
      { ..policy, evidence: Some(evidence), },
      included.source_revision,
      "old",
    ).is_empty(),
  )
}

///|
test "source policy rejects missing duplicate nested malformed unapproved and unfenced regions" {
  let policy = source_policy("tests/source.md", ["cli"], ["sh"], "tests")
  for
    bad in [
      tested_source + "\n" + tested_source,
      tested_source.replace_all(old="<!-- tutorial:end cli -->", new=""),
      tested_source.replace_all(
        old="<!-- tutorial:end cli -->",
        new="<!-- tutorial:end other -->",
      ),
      tested_source.replace_all(
        old="```sh",
        new="<!-- tutorial:start nested -->\n```sh",
      ),
      tested_source.replace_all(old="```sh", new="```unknown"),
      "<!-- tutorial:start cli -->\nplain\n<!-- tutorial:end cli -->",
    ] {
    assert_true(region_error(bad, policy) != "")
  }
  assert_true(
    region_error(tested_source, { ..policy, regions: [], }).contains(
      "not covered",
    ),
  )
  let mapped = tested_source.replace_all(old="tutorial:", new="tour:")
  assert_eq(
    extract_region("tests/source.md", mapped, "cli", {
      ..policy,
      marker_start: "tour:start",
      marker_end: "tour:end",
    }).text,
    "printf 'hello'\n# tour:end pretend\n",
  )
}

///|
test "multiple included fences preserve each language and source byte sequence" {
  let source = "<!-- tutorial:start cli -->\n```sh\none\n```\n```moonbit\ntwo\n```\n<!-- tutorial:end cli -->"
  let included = extract_region(
    "tests/source.md",
    source,
    "cli",
    source_policy("tests/source.md", ["cli"], ["sh", "moonbit"], "runner"),
  )
  assert_eq(included.blocks.map(b => (b.language, b.text)), [
    ("sh", "one\n"),
    ("moonbit", "two\n"),
  ])
}

///|
test "include directives are explicit labeled contained references and do not parse ordinary code" {
  let includes = parse_includes(
    "lesson.md", "```sh\nignored = ../escape#x\n```\n```tutorial-include\nCLI = tests/source.md#cli\nAPI = tests/api.md#api\n```\n",
  )
  assert_eq(includes.map(i => (i.label, i.path, i.region)), [
    ("CLI", "tests/source.md", "cli"),
    ("API", "tests/api.md", "api"),
  ])
  for
    bad in [
      "CLI = ../outside#cli", "CLI = /absolute#cli", "CLI = tests/a.md", "CLI = tests/a.md#",
      "CLI = tests/a.md#a\nCLI = tests/b.md#b",
    ] {
    let error = try {
      ignore(
        parse_includes("lesson.md", "```tutorial-include\n" + bad + "\n```"),
      )
      ""
    } catch {
      @base.Invalid(errors) => errors[0].render()
    }
    assert_true(error.contains("lesson.md"))
  }
}

///|
test "reference checks retain reasons tracking and pinned freshness" {
  let evidence : ReferenceEvidence = {
    source: "external",
    source_revision: "abc",
    input_revision: "r",
    differences: [{ reason: "tracked difference", tracking: "issue-1", }],
    required: true,
  }
  assert_true(reference_problems(evidence, "r").is_empty())
  assert_true(!reference_problems(evidence, "other").is_empty())
  assert_true(
    !reference_problems(
      { ..evidence, differences: [{ reason: "", tracking: "", }], },
      "r",
    ).is_empty(),
  )
  assert_true(
    !reference_problems({ ..evidence, source_revision: "", }, "r").is_empty(),
  )
}

///|
test "source evidence selects complete starting and overlay revisions independently" {
  let policy = source_policy("tests/source.md", ["cli"], ["sh"], "runner")
  let start : SourceEvidence = {
    runner: "runner",
    source_revision: "source",
    input_revision: "start",
    success: true,
    required: true,
  }
  let overlay = { ..start, input_revision: "overlay", }
  let policy = {
    ..policy,
    evidence: Some(start),
    evidence_by_input: Map::from_array([("overlay", overlay)]),
  }
  assert_eq(source_evidence(policy, "start"), Some(start))
  assert_eq(source_evidence(policy, "overlay"), Some(overlay))
  assert_true(source_evidence_problems(policy, "source", "start").is_empty())
  assert_true(source_evidence_problems(policy, "source", "overlay").is_empty())
  assert_true(
    !source_evidence_problems(policy, "source", "unmatched").is_empty(),
  )
  assert_true(
    !source_evidence_problems(policy, "changed-source", "overlay").is_empty(),
  )
  let encoded = Json(policy)
  assert_eq((@json.from_json(encoded) : SourcePolicy), policy)
}

///|
test "text reports retain complete input revision alongside case and provider" {
  let report : CaseReport = {
    source: "tutorials.toml",
    course: "course",
    lesson: "lesson",
    case_id: "start",
    provider: "sample.text",
    engine_version: "1",
    input_revision: "complete-revision",
    passed: true,
    mismatches: [],
    reference: None,
  }
  let text = reports_text([report])
  assert_true(text.contains("input_revision=complete-revision"))
  assert_true(text.contains("course/lesson/start"))
  assert_true(text.contains("sample.text@1"))
}
