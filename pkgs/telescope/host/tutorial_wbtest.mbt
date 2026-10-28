///|
fn tutorial_manifest() -> String {
  (
    #|schema_version = 1
    #|root = "learning"
    #|[[providers]]
    #|id = "sample.text"
    #|contract_version = 1
    #|engine_version = "1.0.0"
    #|operations = ["evaluate"]
    #|worker = "worker.js"
    #|assets = ["worker.js"]
    #|[[courses]]
    #|id = "first"
    #|title = "First course"
    #|route = "/learn/"
    #|[[courses.lessons]]
    #|slug = "reading"
    #|title = "Reading"
    #|prose = "reading.md"
    #|[[courses.lessons]]
    #|slug = "editing"
    #|title = "Editing"
    #|prose = "editing.md"
    #|editor = "plain"
    #|files = [{name="input.txt",source="input.txt",language="text"}]
    #|execution = {provider="sample.text",operation="evaluate",options={}}
    #|cases = [{id="start",expect="start.json"}]
    #|[[courses]]
    #|id = "second"
    #|title = "Second course"
    #|route = "/more/"
    #|[[courses.lessons]]
    #|slug = "reading"
    #|title = "Other reading"
    #|prose = "another.md"
  )
}

///|
async fn tutorial_fixture() -> String {
  let root = @fs.realpath(@fs.tmpdir(prefix="telescope-tutorial-test"))
  write(
    root + "/site.json",
    "{\"title\":\"Example\",\"description\":\"Tutorial fixture\",\"base_path\":\"/\",\"site_url\":\"https://example.test/\",\"repo_url\":\"https://example.test/repo\",\"tutorials\":\"tutorials.toml\"}",
  )
  write(root + "/tutorials.toml", tutorial_manifest())
  write(
    root + "/learning/reading.md",
    "Static searchable lesson. [Next](editing.md) [Guide](../docs/guide.md)\n\n```tutorial-include\nCLI = tested.md#cli\n```\n",
  )
  write(
    root + "/learning/editing.md",
    "Edit the supplied text. [Back](reading.md)",
  )
  write(root + "/learning/another.md", "Other course prose")
  write(root + "/learning/input.txt", "sample <script>alert(1)</script>")
  write(root + "/learning/worker.js", "self.onmessage = () => {};")
  write(
    root + "/learning/start.json",
    "{\"diagnostic_keys\":[],\"outputs\":[{\"id\":\"text\",\"contains\":[\"sample\"]}]}",
  )
  write(
    root + "/learning/tested.md",
    "<!-- tutorial:start cli -->\n```shell\nprintf 'sample source'\n```\n<!-- tutorial:end cli -->\n",
  )
  write(root + "/docs/guide.md", "# Guide\n\n[Read](../learning/reading.md)")
  root
}

///|
fn test_policies() -> Array[@tutorial_check.SourcePolicy] {
  [
    @tutorial_check.source_policy(
      "tested.md",
      ["cli"],
      ["shell"],
      "fixture-tests",
    ),
  ]
}

///|
async fn output_snapshot(root : String) -> Array[(String, Bytes)] {
  let result = []
  for path in files(root) {
    result.push((path, @fs.read_file(root + "/" + path).binary()))
  }
  result
}

///|
async test "tutorial pages share routes links search and stable deterministic output" {
  let root = tutorial_fixture()
  defer @fs.rmdir(root, recursive=true)
  for base in ["/", "/sample/v/1/"] {
    ignore(
      build(
        root,
        root + "/site.json",
        root + "/out",
        base~,
        tutorial_policies=test_policies(),
      ),
    )
    let reading = @fs.read_file(root + "/out/learn/reading/index.html").text()
    let editing = @fs.read_file(root + "/out/learn/editing/index.html").text()
    let guide = @fs.read_file(root + "/out/docs/guide/index.html").text()
    assert_true(reading.contains(base + "learn/editing/"))
    assert_true(reading.contains("aria-current=\"page\""))
    assert_true(
      reading.contains("printf &#39;sample source&#39;") ||
      reading.contains("printf 'sample source'"),
    )
    assert_false(reading.contains("workspace.js"))
    assert_false(reading.contains("editor.js"))
    assert_false(reading.contains("worker.js"))
    assert_true(editing.contains("data-tutorial-workspace"))
    let config_marker = "data-tutorial-config>"
    let config_start = editing.find(config_marker).unwrap() +
      config_marker.length()
    let config_body = editing[config_start:]
    let config_end = config_body.find("</script>").unwrap()
    let runtime = @json.parse(config_body[:config_end].to_owned())
    guard runtime is Object(fields) else {
      abort("runtime config must be an object")
    }
    assert_true(fields.get("execution") is Some(Object(_)))
    assert_false(config_body[:config_end].contains("<script>"))
    assert_true(editing.contains("sample &lt;script&gt;"))
    assert_true(
      editing.contains(base + "assets/tutorial/files/first/editing/input.txt"),
    )
    assert_true(guide.contains(base + "learn/reading/"))
    assert_true(@fs.exists(root + "/out/more/reading/index.html"))
    let search = @fs.read_file(root + "/out/search-index.json").text()
    assert_true(search.contains("Static searchable"))
    assert_true(search.contains("sample source"))
    assert_false(search.contains("diagnostic_keys"))
    let before = output_snapshot(root + "/out")
    write(
      root + "/tutorials.toml",
      "# A harmless comment\n" + tutorial_manifest(),
    )
    ignore(
      build(
        root,
        root + "/site.json",
        root + "/out",
        base~,
        tutorial_policies=test_policies(),
      ),
    )
    assert_eq(output_snapshot(root + "/out"), before)
  }
}

///|
async test "tutorial containment collision and bad expectations preserve completed output" {
  let root = tutorial_fixture()
  defer @fs.rmdir(root, recursive=true)
  ignore(
    build(
      root,
      root + "/site.json",
      root + "/out",
      tutorial_policies=test_policies(),
    ),
  )
  let before = output_snapshot(root + "/out")
  for
    manifest in [
      tutorial_manifest().replace(
        old="source=\"input.txt\"",
        new="source=\"../outside.txt\"",
      ),
      tutorial_manifest().replace(
        old="route = \"/learn/\"",
        new="route = \"/docs/\"",
      ),
    ] {
    write(root + "/tutorials.toml", manifest)
    let failed = try {
      ignore(
        build(
          root,
          root + "/site.json",
          root + "/out",
          tutorial_policies=test_policies(),
        ),
      )
      false
    } catch {
      _ => true
    }
    assert_true(failed)
    assert_eq(output_snapshot(root + "/out"), before)
  }
  write(root + "/tutorials.toml", tutorial_manifest())
  write(
    root + "/learning/start.json",
    "{\"diagnostic_keys\":[],\"outputs\":[{\"id\":\"text\",\"contains\":[\"\"]}]}",
  )
  let failed = try {
    ignore(
      build(
        root,
        root + "/site.json",
        root + "/out",
        tutorial_policies=test_policies(),
      ),
    )
    false
  } catch {
    _ => true
  }
  assert_true(failed)
  assert_eq(output_snapshot(root + "/out"), before)
}

///|
async test "tutorial symlinks cannot escape declared root" {
  let root = tutorial_fixture()
  defer @fs.rmdir(root, recursive=true)
  write(root + "/outside.txt", "outside")
  @fs.remove(root + "/learning/input.txt")
  @fs.symlink(target=root + "/outside.txt", root + "/learning/input.txt")
  let failed = try {
    ignore(
      build(
        root,
        root + "/site.json",
        root + "/out",
        tutorial_policies=test_policies(),
      ),
    )
    false
  } catch {
    _ => true
  }
  assert_true(failed)
  assert_false(@fs.exists(root + "/out"))
}

///|
fn successful_test_runner() -> TutorialRunner {
  {
    provider: "sample.text",
    engine_version: "1.0.0",
    contract_version: 1,
    operations: ["evaluate"],
    evaluate: request => {
      Ok({
        ..@tutorial.response_for(request),
        outputs: [
          {
            id: "text",
            label: "Output",
            language: "text",
            text: request.files[0].text,
          },
        ],
      })
    },
  }
}

///|
async test "case checking requires matching evaluator and is separate from structural build" {
  let root = tutorial_fixture()
  defer @fs.rmdir(root, recursive=true)
  ignore(
    build(
      root,
      root + "/site.json",
      root + "/out",
      tutorial_policies=test_policies(),
    ),
  )
  let missing = check_tutorials(
    root,
    root + "/site.json",
    policies=test_policies(),
  )
  assert_false(missing[0].passed)
  assert_true(missing[0].mismatches[0].contains("missing compiled evaluator"))
  let reports = check_tutorials(
    root,
    root + "/site.json",
    policies=test_policies(),
    runners=[successful_test_runner()],
  )
  assert_true(reports[0].passed)
  assert_true(@tutorial_check.reports_text(reports).contains("PASS"))
  let mismatched = { ..successful_test_runner(), engine_version: "wrong", }
  assert_false(
    check_tutorials(root, root + "/site.json", policies=test_policies(), runners=[
      mismatched,
    ])[0].passed,
  )
  let stalled = {
    ..successful_test_runner(),
    evaluate: _ => {
      @async.sleep(1000)
      Err("late")
    },
  }
  let timeout = check_tutorials(
    root,
    root + "/site.json",
    runners=[stalled],
    timeout_ms=5,
    policies=test_policies(),
  )
  assert_false(timeout[0].passed)
  assert_true(timeout[0].mismatches[0].contains("timed out"))
}

///|
async test "missing include policy never makes a test claim" {
  let root = tutorial_fixture()
  defer @fs.rmdir(root, recursive=true)
  let failed = try {
    ignore(build(root, root + "/site.json", root + "/out"))
    false
  } catch {
    _ => true
  }
  assert_true(failed)
}

///|
async test "source reports distinguish policy coverage from matching runner evidence" {
  let root = tutorial_fixture()
  defer @fs.rmdir(root, recursive=true)
  let structural = check_tutorial_sources(
    root,
    root + "/site.json",
    policies=test_policies(),
  )
  assert_true(structural[0].covered)
  assert_false(structural[0].verified)
  let policy = {
    ..test_policies()[0],
    evidence: Some(@tutorial_check.SourceEvidence::{
      runner: "fixture-tests",
      source_revision: structural[0].source_revision,
      input_revision: structural[0].input_revision,
      success: true,
      required: true,
    }),
  }
  assert_true(
    check_tutorial_sources(root, root + "/site.json", policies=[policy])[0].verified,
  )
  let stale = {
    ..policy,
    evidence: Some({ ..policy.evidence.unwrap(), input_revision: "stale", }),
  }
  assert_false(
    check_tutorial_sources(root, root + "/site.json", policies=[stale])[0].problems.is_empty(),
  )
  let failed = try {
    ignore(
      check_tutorials(root, root + "/site.json", policies=[stale], runners=[
        successful_test_runner(),
      ]),
    )
    false
  } catch {
    _ => true
  }
  assert_true(failed)
}

///|
async test "required source evidence covers independent overlay revisions explicitly" {
  let root = tutorial_fixture()
  defer @fs.rmdir(root, recursive=true)
  write(
    root + "/learning/editing.md",
    "```tutorial-include\nCLI = tested.md#cli\n```\n",
  )
  write(root + "/learning/overlay.txt", "sample overlay")
  let manifest_text = tutorial_manifest().replace(
    old="cases = [{id=\"start\",expect=\"start.json\"}]",
    new="cases = [{id=\"start\",expect=\"start.json\"},{id=\"overlay\",expect=\"start.json\",files=[{name=\"input.txt\",source=\"overlay.txt\",language=\"text\"}]}]",
  )
  write(root + "/tutorials.toml", manifest_text)
  let source_reports = check_tutorial_sources(
    root,
    root + "/site.json",
    policies=test_policies(),
  )
  let input = tutorial_input(
    root,
    @json.parse(@fs.read_file(root + "/site.json").text()),
  ).unwrap()
  let lesson = input.manifest.courses[0].lessons[1]
  let overlay = lesson.cases[1]
  let overlay_revision = @tutorial.input_revision(
    input.manifest.providers[0],
    "evaluate",
    lesson.execution.unwrap().options,
    @tutorial.overlay_files(
      tutorial_files(input, lesson.files),
      tutorial_files(input, overlay.files),
    ),
  )
  let evidence : @tutorial_check.SourceEvidence = {
    runner: "fixture-tests",
    source_revision: source_reports[0].source_revision,
    input_revision: source_reports[0].input_revision,
    success: true,
    required: true,
  }
  let policy = {
    ..test_policies()[0],
    evidence: Some(evidence),
    evidence_by_input: Map::from_array([
      (
        source_reports[1].input_revision,
        { ..evidence, input_revision: source_reports[1].input_revision, },
      ),
      (overlay_revision, { ..evidence, input_revision: overlay_revision, }),
    ]),
  }
  let reports = check_tutorials(root, root + "/site.json", policies=[policy], runners=[
    successful_test_runner(),
  ])
  assert_eq(reports.length(), 2)
  assert_true(reports.iter().all(report => report.passed))
  let missing_overlay = {
    ..policy,
    evidence_by_input: Map::from_array([
      (
        source_reports[1].input_revision,
        { ..evidence, input_revision: source_reports[1].input_revision, },
      ),
    ]),
  }
  assert_true(
    check_tutorials(root, root + "/site.json", policies=[missing_overlay], runners=[
      successful_test_runner(),
    ])
    .iter()
    .any(report => !report.passed),
  )
}

///|
async test "reference hooks retain tracking metadata and reject stale required evidence" {
  let root = tutorial_fixture()
  defer @fs.rmdir(root, recursive=true)
  let hook : TutorialReference = {
    course: "first",
    lesson: "editing",
    case_id: "start",
    evidence: {
      source: "synthetic-reference",
      source_revision: "pinned",
      input_revision: "stale",
      required: true,
      differences: [{ reason: "known difference", tracking: "issue-1", }],
    },
    registration: { id: "synthetic", compare: (_, _, _) => Ok([]), },
  }
  let reports = check_tutorials(
    root,
    root + "/site.json",
    policies=test_policies(),
    runners=[successful_test_runner()],
    references=[hook],
  )
  assert_false(reports[0].passed)
  assert_true(Json(reports).stringify().contains("known difference"))
  assert_true(Json(reports).stringify().contains("issue-1"))
  assert_true(
    @tutorial_check.reports_text(reports).contains(reports[0].input_revision),
  )
}

///|
async test "consumer source guards reject unapproved prose and rendering executes no shell fences" {
  let root = tutorial_fixture()
  defer @fs.rmdir(root, recursive=true)
  write(
    root + "/learning/tested.md",
    "<!-- tutorial:start cli -->\n```shell\ntouch never-executed\n```\n<!-- tutorial:end cli -->\n",
  )
  ignore(
    build(
      root,
      root + "/site.json",
      root + "/out",
      tutorial_policies=test_policies(),
    ),
  )
  assert_false(@fs.exists(root + "/never-executed"))
  assert_false(@fs.exists(root + "/learning/never-executed"))
  let before = output_snapshot(root + "/out")
  write(
    root + "/learning/editing.md",
    "Unapproved consumer-tool --check example",
  )
  let consumer_guard : TutorialGuard = {
    id: "fixture-command-guard",
    validate: (source, text, _) => {
      if text.contains("consumer-tool") {
        [
          @model.problem(
            source, "consumer command examples must use approved tested regions",
          ),
        ]
      } else {
        []
      }
    },
  }
  let failed = try {
    ignore(
      build(
        root,
        root + "/site.json",
        root + "/out",
        tutorial_policies=test_policies(),
        tutorial_guards=[consumer_guard],
      ),
    )
    false
  } catch {
    _ => true
  }
  assert_true(failed)
  assert_eq(output_snapshot(root + "/out"), before)
  let expectations = @fs.read_file(root + "/learning/start.json").binary()
  ignore(
    check_tutorials(root, root + "/site.json", policies=test_policies(), runners=[
      successful_test_runner(),
    ]),
  )
  assert_eq(@fs.read_file(root + "/learning/start.json").binary(), expectations)
}
