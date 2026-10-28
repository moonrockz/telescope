///|
let manifest_sample : String =
  #|# Authored TOML, with explicitly ordered lessons.
  #|schema_version = 1
  #|root = "site/learning"
  #|[[providers]]
  #|id = "sample.text"
  #|contract_version = 1
  #|engine_version = "1.0.0"
  #|operations = ["evaluate"]
  #|worker = "assets/check.js"
  #|assets = ["assets/check.js"]
  #|[[courses]]
  #|id = "first"
  #|title = "First"
  #|route = "/learn/"
  #|[[courses.lessons]]
  #|slug = "reading"
  #|title = "Reading"
  #|prose = "read.md"
  #|[[courses.lessons]]
  #|slug = "edit"
  #|title = "Editing"
  #|prose = "edit.md"
  #|files = [{name="input.txt",source="input.txt",language="text"}]
  #|execution = {provider="sample.text",operation="evaluate",options={a=1,z=true}}
  #|cases = [{id="start",expect="cases/start.json"}]

///|
fn manifest_error(text : String) -> String {
  try {
    ignore(Manifest::parse("tutorials.toml", text))
    ""
  } catch {
    @base.Invalid(problems) => problems.map(p => p.render()).join("\n")
  }
}

///|
test "commented TOML preserves order routes and normalized semantic identity" {
  let manifest = Manifest::parse("tutorials.toml", manifest_sample)
  assert_eq(manifest.courses[0].lessons.map(l => l.slug), ["reading", "edit"])
  assert_eq(
    manifest.courses[0].lesson_route(manifest.courses[0].lessons[1]),
    "/learn/edit/",
  )
  assert_eq(manifest.courses[0].neighbors("reading").0, None)
  assert_eq(manifest.courses[0].neighbors("edit").1, None)
  let equivalent = manifest_sample.replace_all(
      old="options={a=1,z=true}",
      new="options={ z = true, a = 1 }",
    ) +
    "\n# Additional explanation\n"
  assert_eq(
    canonical(Json(manifest)),
    canonical(Json(Manifest::parse("tutorials.toml", equivalent))),
  )
}

///|
test "strict TOML syntax duplicate keys and unsupported values identify source" {
  for bad in ["schema_version=1\nschema_version=1", "schema_version=[", "{}"] {
    assert_true(manifest_error(bad).contains("tutorials.toml"))
    assert_true(manifest_error(bad).contains("invalid TOML"))
  }
  assert_true(
    manifest_error(manifest_sample.replace_all(old="a=1", new="a=1979-05-27")).contains(
      "options.a",
    ),
  )
  assert_true(
    manifest_error(manifest_sample.replace_all(old="a=1", new="a=nan")).contains(
      "non-finite",
    ),
  )
  assert_true(
    manifest_error(manifest_sample.replace_all(old="a=1", new="a=inf")).contains(
      "non-finite",
    ),
  )
}

///|
test "manifest rejects unknown fields versions types duplicate identities and missing prose" {
  for
    (old, new, needle) in [
      ("schema_version = 1", "schema_version = 2", "schema_version"),
      ("schema_version = 1", "schema_version = 1.0", "integer version"),
      ("root = \"site/learning\"", "root = 7", "root"),
      (
        "root = \"site/learning\"", "root = \"site/learning\"\nunknown = true", "unknown",
      ),
      ("contract_version = 1", "contract_version = 7", "contract_version"),
      ("prose = \"read.md\"", "", "prose"),
      ("slug = \"edit\"", "slug = \"reading\"", "duplicate lesson"),
      ("operation=\"evaluate\"", "operation=\"step\"", "does not support"),
      ("provider=\"sample.text\"", "provider=\"missing\"", "unknown provider"),
      ("source=\"input.txt\"", "source=\"../escape\"", "normalized relative"),
      ("name=\"input.txt\"", "name=\"/absolute\"", "normalized relative"),
      ("id=\"start\"", "id=\"other\"", "start case"),
    ] {
    assert_true(
      manifest_error(manifest_sample.replace_all(old~, new~)).contains(needle),
    )
  }
}

///|
test "static lessons reject execution-only fields and duplicate file names" {
  assert_true(
    manifest_error(
      manifest_sample.replace_all(
        old="prose = \"read.md\"",
        new="prose = \"read.md\"\nfiles=[]",
      ),
    ).contains("static lessons"),
  )
  assert_true(
    manifest_error(
      manifest_sample.replace_all(
        old="source=\"input.txt\",language=\"text\"}",
        new="source=\"input.txt\",language=\"text\"},{name=\"input.txt\",source=\"other\"}",
      ),
    ).contains("duplicate virtual"),
  )
}

///|
test "same slug in distinct courses is allowed but course identities and prefixes remain unique" {
  let second =
    #|
    #|[[courses]]
    #|id="second"
    #|title="Second"
    #|route="/second/"
    #|[[courses.lessons]]
    #|slug="reading"
    #|title="Another reading"
    #|prose="another.md"
  let manifest = Manifest::parse("tutorials.toml", manifest_sample + second)
  assert_eq(manifest.courses.length(), 2)
  assert_true(
    manifest_error(
      manifest_sample +
      second.replace_all(old="id=\"second\"", new="id=\"first\""),
    ).contains("duplicate course id"),
  )
  assert_true(
    manifest_error(
      manifest_sample + second.replace_all(old="/second/", new="/learn/"),
    ).contains("duplicate course route"),
  )
}

///|
test "input revisions include ordered files provider options and semantic key normalization" {
  let provider = Manifest::parse("tutorials.toml", manifest_sample).providers[0]
  let file : File = {
    name: "input",
    text: "hello",
    language: "text",
    group: "",
  }
  let original = input_revision(provider, "evaluate", { "a": 1, "z": true }, [
    file,
  ])
  assert_eq(
    original,
    input_revision(provider, "evaluate", { "z": true, "a": 1 }, [file]),
  )
  assert_true(
    original !=
    input_revision(provider, "evaluate", { "a": 2, "z": true }, [file]),
  )
  assert_true(
    original !=
    input_revision(
      { ..provider, engine_version: "2", },
      "evaluate",
      { "a": 1, "z": true },
      [file],
    ),
  )
  assert_true(
    original !=
    input_revision(provider, "evaluate", { "a": 1, "z": true }, [
      { ..file, text: "changed", },
    ]),
  )
}

///|
test "overlays replace and add without mutating other cases" {
  let a : File = { name: "a", text: "a", language: "text", group: "", }
  let b : File = { ..a, name: "b", text: "b", }
  let start = [a]
  assert_eq(
    overlay_files(start, [{ ..a, text: "changed", }, b]).map(f => f.text),
    ["changed", "b"],
  )
  assert_eq(start, [a])
  assert_eq(overlay_files(start, []), [a])
}

///|
test "response protocol freshness status and steps are validated" {
  let request : Request = {
    contract_version: 1,
    provider: "sample",
    engine_version: "1",
    generation: 1,
    request_id: 1,
    input_revision: "r",
    operation: "evaluate",
    files: [],
    options: {},
    session: None,
    position: None,
  }
  let response = response_for(request)
  assert_true(response_problems(request, response).is_empty())
  for
    invalid in [
      { ..response, generation: 0, },
      { ..response, contract_version: 2, },
      { ..response, engine_version: "2", },
      { ..response, status: "maybe", },
      { ..response, status: "blocked", },
    ] {
    assert_true(!response_problems(request, invalid).is_empty())
  }
}

///|
test "formatter language defaults and per-document overrides use general editor contracts" {
  let declaration =
    #|[formatting.languages.text]
    #|provider="sample.whitespace"
    #|options={indent=2}
    #|[[formatters]]
    #|id="sample.whitespace"
    #|contract_version=1
    #|formatter_version="1.0.0"
    #|languages=["text"]
    #|worker="assets/format.js"
    #|assets=["assets/format.js"]
    #|
  let sample = manifest_sample.replace_all(
    old="[[providers]]",
    new=declaration + "[[providers]]",
  )
  let manifest = Manifest::parse("tutorials.toml", sample)
  assert_eq(manifest.formatters[0].id, "sample.whitespace")
  assert_eq(manifest.languages["text"].provider, "sample.whitespace")
  assert_true(
    manifest_error(
      sample.replace_all(
        old="provider=\"sample.whitespace\"",
        new="provider=\"unknown\"",
      ),
    ).contains("unknown"),
  )
  assert_true(
    manifest_error(
      sample.replace_all(
        old="languages=[\"text\"]",
        new="languages=[\"moonbit\"]",
      ),
    ).contains("text"),
  )
  let overridden = sample.replace_all(
    old="source=\"input.txt\",language=\"text\"",
    new="source=\"input.txt\",language=\"text\",formatter={provider=\"sample.whitespace\",options={indent=4}}",
  )
  assert_eq(
    Manifest::parse("tutorials.toml", overridden).courses[0].lessons[1].files[0].formatter.unwrap().options,
    { "indent": 4 },
  )
  for
    (provider, language, needle) in [
      ("missing", "text", "unknown"),
      ("sample.whitespace", "moonbit", "moonbit"),
    ] {
    let overlay = sample.replace_all(
      old="expect=\"cases/start.json\"",
      new="expect=\"cases/start.json\",files=[{name=\"overlay.txt\",source=\"overlay.txt\",language=\"" +
        language +
        "\",formatter={provider=\"" +
        provider +
        "\"}}]",
    )
    let error = manifest_error(overlay)
    assert_true(
      error.contains("courses[0].lessons[1].cases[0].files[0].formatter"),
    )
    assert_true(error.contains(needle))
  }
}

///|
test "unsafe route slugs and undeclared assets fail before host IO" {
  for
    (old, new) in [
      ("slug = \"reading\"", "slug = \"..\""),
      ("route = \"/learn/\"", "route = \"/learn/?bad/\""),
      ("route = \"/learn/\"", "route = \"/v/1/\""),
      ("assets = [\"assets/check.js\"]", "assets = [\"assets/other.js\"]"),
      ("id = \"sample.text\"", "id = \"bad/id\""),
    ] {
    assert_true(manifest_error(manifest_sample.replace_all(old~, new~)) != "")
  }
}

///|
test "compiled evaluator registry validates exact declarative identity versions and capabilities" {
  let provider = Manifest::parse("tutorials.toml", manifest_sample).providers[0]
  let registration : EvaluatorRegistration = {
    provider: provider.id,
    engine_version: provider.engine_version,
    contract_version: 1,
    operations: provider.operations,
    evaluate: request => Ok(response_for(request)),
  }
  assert_true(validate_evaluators([provider], [registration]).is_empty())
  assert_true(
    !validate_evaluators([provider], [registration, registration]).is_empty(),
  )
  assert_true(
    !validate_evaluators([provider], [{ ..registration, engine_version: "2", }]).is_empty(),
  )
  assert_true(
    !validate_evaluators([provider], [{ ..registration, operations: ["step"], }]).is_empty(),
  )
  assert_true(
    !validate_evaluators([provider], [{ ..registration, provider: "other", }]).is_empty(),
  )
}

///|
test "declarative editor and language registrations are strict and capability checked" {
  let declarations =
    #|[[editors]]
    #|id="sample.editor"
    #|contract_version=1
    #|kind="editor"
    #|module="assets/editor.js"
    #|languages=["text"]
    #|assets=["assets/editor.js"]
    #|[[editors]]
    #|id="sample.language"
    #|contract_version=1
    #|kind="language"
    #|module="assets/language.js"
    #|languages=["custom"]
    #|assets=["assets/language.js"]
    #|
  let sample = manifest_sample
    .replace_all(old="[[providers]]", new=declarations + "[[providers]]")
    .replace_all(
      old="prose = \"edit.md\"",
      new="prose = \"edit.md\"\neditor=\"sample.editor\"",
    )
  let manifest = Manifest::parse("tutorials.toml", sample)
  assert_eq(manifest.editors.length(), 2)
  assert_eq(manifest.courses[0].lessons[1].editor, Some("sample.editor"))
  for
    (old, new, needle) in [
      ("editor=\"sample.editor\"", "editor=\"missing\"", "editor"),
      ("editor=\"sample.editor\"", "editor=\"sample.language\"", "editor"),
      ("languages=[\"text\"]", "languages=[\"unsupported\"]", "text"),
      (
        "assets=[\"assets/editor.js\"]", "assets=[\"assets/other.js\"]", "module",
      ),
      ("kind=\"language\"", "kind=\"unknown\"", "kind"),
      ("id=\"sample.language\"", "id=\"sample.editor\"", "duplicate"),
      ("module=\"assets/editor.js\"", "module=\"../outside.js\"", "module"),
      ("contract_version=1", "contract_version=2", "contract_version"),
      ("kind=\"language\"", "kind=\"language\"\nextra=true", "extra"),
    ] {
    assert_true(manifest_error(sample.replace_all(old~, new~)).contains(needle))
  }
}

///|
test "each lesson prose source has exactly one published route" {
  let second =
    #|
    #|[[courses]]
    #|id="another"
    #|title="Another"
    #|route="/another/"
    #|[[courses.lessons]]
    #|slug="reading"
    #|title="Duplicate prose"
    #|prose="read.md"
  let error = manifest_error(manifest_sample + second)
  assert_true(error.contains("courses[1].lessons[0].prose"))
  assert_true(error.contains("/learn/reading/"))
}
