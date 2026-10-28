///|
struct TrimFormatter {}

///|
impl @editor.Formatter for TrimFormatter with fn format(_, input) {
  Ok({ text: input.target.text.trim().to_owned(), })
}

///|
test "formatter is externally implementable without tutorial imports" {
  let formatter = TrimFormatter::{ }
  let input : @editor.FormatInput = {
    target: {
      id: "one",
      name: "any.mbt",
      language: "mbt",
      text: "  let x = 1  ",
    },
    context: [],
    options: {},
  }
  assert_eq(
    @editor.Formatter::format(formatter, input),
    Ok({ text: "let x = 1", }),
  )
}

///|
test "independent histories selections formatting no-op and replacement" {
  let a = @editor.DocumentState::new({
    id: "a",
    name: "a",
    text: "abc",
    language: "text",
  })
  let b = @editor.DocumentState::new({
    id: "b",
    name: "b",
    text: "xyz",
    language: "text",
  })
  a.set_selection({ anchor: 2, head: 3, })
  assert_true(a.edit("abcdef"))
  assert_true(b.edit("XYZ"))
  assert_true(a.undo())
  assert_eq(a.document().text, "abc")
  assert_eq(a.selection(), { anchor: 2, head: 3, })
  assert_eq(b.document().text, "XYZ")
  assert_false(a.edit("abc"))
  assert_false(a.undo())
  assert_true(a.redo())
  a.set_language("moonbit")
  assert_eq(a.document().text, "abcdef")
  assert_true(a.undo())
  a.replace({ id: "a", name: "a", text: "start", language: "mbt", })
  assert_false(a.undo())
  assert_false(a.redo())
  assert_eq(a.selection(), { anchor: 0, head: 0, })
}

///|
test "registry validation and document override" {
  let registration : @editor.FormatterRegistration = {
    id: "trim",
    contract_version: 1,
    formatter_version: "1",
    languages: ["text"],
    worker: "trim.js",
    assets: ["trim.js"],
  }
  let registry : @editor.Registry = {
    editors: [],
    formatters: [registration],
    languages: Map::from_array([("text", { provider: "trim", options: {}, })]),
  }
  assert_true(@editor.validate_registry(registry).is_empty())
  let doc : @editor.Document = {
    id: "a",
    name: "input.txt",
    language: "text",
    text: "a",
  }
  assert_eq(
    @editor.resolve_binding(registry, doc),
    Some({ provider: "trim", options: {}, }),
  )
  assert_eq(
    @editor.resolve_binding(
      registry,
      doc,
      document_binding=Some({ provider: "other", options: { "custom": true }, }),
    ),
    Some({ provider: "other", options: { "custom": true }, }),
  )
  assert_false(
    @editor.validate_binding([registration], "mbt", {
      provider: "trim",
      options: {},
    }).is_empty(),
  )
  assert_false(
    @editor.validate_binding([registration], "text", {
      provider: "unknown",
      options: {},
    }).is_empty(),
  )
  assert_false(
    @editor.validate_registry({
      ..registry,
      formatters: [registration, registration],
    }).is_empty(),
  )
  assert_false(
    @editor.validate_registry({
      ..registry,
      formatters: [{ ..registration, contract_version: 2, }],
    }).is_empty(),
  )
}

///|
test "captured target and context revisions reject stale replies" {
  let a = @editor.DocumentState::new({
    id: "a",
    name: "a",
    text: "a",
    language: "text",
  })
  let b = @editor.DocumentState::new({
    id: "b",
    name: "b",
    text: "b",
    language: "text",
  })
  let formatter : @editor.FormatterRegistration = {
    id: "trim",
    contract_version: 1,
    formatter_version: "1",
    languages: ["text"],
    worker: "trim.js",
    assets: ["trim.js"],
  }
  let request : @editor.FormatRequest = {
    contract_version: 1,
    instance: "one",
    formatter: "trim",
    formatter_version: "1",
    generation: 0,
    request_id: 1,
    target: "a",
    revisions: [{ id: "a", revision: 0, }, { id: "b", revision: 0, }],
    input: { target: a.document(), context: [b.document()], options: {}, },
  }
  assert_true(@editor.request_is_current(request, "one", 0, formatter, [a, b]))
  assert_false(@editor.request_is_current(request, "two", 0, formatter, [a, b]))
  assert_false(@editor.request_is_current(request, "one", 1, formatter, [a, b]))
  assert_false(
    @editor.request_is_current(
      request,
      "one",
      0,
      { ..formatter, formatter_version: "2", },
      [a, b],
    ),
  )
  assert_false(
    @editor.request_is_current(
      { ..request, target: "other", },
      "one",
      0,
      formatter,
      [a, b],
    ),
  )
  assert_false(
    @editor.request_is_current(
      { ..request, revisions: [{ id: "a", revision: 0, }], },
      "one",
      0,
      formatter,
      [a, b],
    ),
  )
  b.set_language("mbt")
  assert_false(@editor.request_is_current(request, "one", 0, formatter, [a, b]))
  ignore(b.edit("new context"))
  assert_false(@editor.request_is_current(request, "one", 0, formatter, [a, b]))
}

///|
test "declarative editor and language registrations validate capabilities" {
  let custom : @editor.EditorRegistration = {
    id: "custom",
    contract_version: 1,
    kind: "editor",
    module_path: "assets/custom.js",
    languages: ["text"],
    assets: ["assets/custom.js"],
  }
  let language = {
    ..custom,
    id: "language",
    kind: "language",
    languages: ["moonbit"],
  }
  let registry : @editor.Registry = {
    editors: [custom, language],
    formatters: [],
    languages: Map([]),
  }
  assert_true(@editor.validate_registry(registry).is_empty())
  assert_true(
    @editor.validate_editor_binding(registry.editors, "custom", ["text"]).is_empty(),
  )
  assert_false(
    @editor.validate_editor_binding(registry.editors, "custom", ["moonbit"]).is_empty(),
  )
  assert_false(
    @editor.validate_editor_binding(registry.editors, "missing", ["text"]).is_empty(),
  )
  assert_false(
    @editor.validate_registry({
      ..registry,
      editors: [language, { ..language, id: "duplicate", }],
    }).is_empty(),
  )
  assert_false(
    @editor.validate_registry({
      ..registry,
      editors: [{ ..custom, module_path: "../escape.js", }],
    }).is_empty(),
  )
  assert_false(
    @editor.validate_registry({
      ..registry,
      editors: [{ ..custom, assets: [], }],
    }).is_empty(),
  )
  assert_false(
    @editor.validate_registry({
      ..registry,
      editors: [{ ..custom, kind: "unknown", }],
    }).is_empty(),
  )
  assert_eq(custom.to_json(), {
    "id": "custom",
    "contract_version": 1,
    "kind": "editor",
    "module": "assets/custom.js",
    "languages": ["text"],
    "assets": ["assets/custom.js"],
  })
}
