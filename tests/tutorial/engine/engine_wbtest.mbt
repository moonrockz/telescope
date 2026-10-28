///|
fn request(
  operation : String,
  files : Array[@tutorial.File],
  options~ : Json = {},
) -> @tutorial.Request {
  {
    contract_version: 1,
    provider: "sample.text",
    engine_version: "1.0.0",
    generation: 7,
    request_id: 9,
    input_revision: "revision",
    operation,
    files,
    options,
    session: None,
    position: None,
  }
}

///|
fn file(
  text : String,
  name~ : String = "input.txt",
  group~ : String = "",
) -> @tutorial.File {
  { name, text, language: "text", group, }
}

///|
test "ordinary text and literal output preserve input and protocol identity" {
  let input = request("evaluate", [file("<script>literal</script>\n")])
  let actual = evaluate(input).unwrap()
  assert_eq(actual.outputs[0].text, "<script>literal</script>\n")
  assert_true(@tutorial.response_problems(input, actual).is_empty())
  assert_eq(actual.verdict, Some("valid"))
  assert_eq(TextEvaluator::{ }.evaluate(input), Ok(actual))
}

///|
test "consumer text options stay outside common schema and reject conflicts" {
  assert_eq(
    evaluate(
      request("evaluate", [file("Hello")], options={ "uppercase": true }),
    ).unwrap().outputs[0].text,
    "HELLO",
  )
  assert_eq(
    evaluate(
      request("evaluate", [file("Hello")], options={ "lowercase": true }),
    ).unwrap().outputs[0].text,
    "hello",
  )
  let blocked = evaluate(
    request("evaluate", [file("Hello")], options={
      "uppercase": true,
      "lowercase": true,
    }),
  ).unwrap()
  assert_eq(blocked.status, "blocked")
  assert_eq(blocked.diagnostics[0].key, "options:conflict")
  assert_eq(blocked.blocked, Some("conflicting text options"))
}

///|
test "negative cases retain diagnostic multiplicity file and line" {
  let result = evaluate(
    request("evaluate", [file("ERROR first\nokay\nERROR second")]),
  ).unwrap()
  assert_eq(result.diagnostics.map(d => (d.key, d.line)), [
    ("input.txt:ERROR", Some(1)),
    ("input.txt:ERROR", Some(3)),
  ])
  assert_eq(result.verdict, Some("invalid"))
}

///|
test "old new comparison is neutral grouped data" {
  let same = evaluate(
    request("evaluate", [
      file("one", name="old/a", group="Old"),
      file("one", name="new/a", group="New"),
    ]),
  ).unwrap()
  assert_eq(same.outputs[1].id, "comparison")
  assert_eq(same.outputs[1].text, "same")
  let changed = evaluate(
    request("evaluate", [
      file("one", name="old/a", group="old"),
      file("two", name="new/a", group="new"),
    ]),
  ).unwrap()
  assert_true(changed.outputs[1].text.has_prefix("changed"))
}

///|
test "step sessions reconstruct independently and clamp shorter edited input" {
  let start = evaluate(request("start", [file("first\nERROR second\nthird\n")])).unwrap()
  assert_eq(start.steps.unwrap().checked, 0)
  let step = evaluate({
    ..request("step", [file("first\nERROR second\nthird\n")]),
    session: Some(start.steps.unwrap().session),
  }).unwrap()
  assert_eq(step.steps.unwrap().checked, 1)
  assert_true(step.diagnostics.is_empty())
  let second = evaluate({
    ..request("step", [file("first\nERROR second\nthird\n")]),
    session: Some(step.steps.unwrap().session),
  }).unwrap()
  assert_eq(second.steps.unwrap().checked, 2)
  assert_eq(second.diagnostics.length(), 1)
  let replay = evaluate({
    ..request("step", [file("short")]),
    position: Some(2),
  }).unwrap()
  assert_eq(replay.steps.unwrap().checked, 1)
  assert_true(replay.steps.unwrap().complete)
  let all = evaluate(request("run-all", [file("first\nsecond\nthird")])).unwrap()
  assert_eq(all.steps.unwrap().checked, 3)
  assert_true(all.steps.unwrap().complete)
  assert_eq(
    evaluate(request("start", [file("")])).unwrap().steps.unwrap().checked,
    0,
  )
  assert_true(
    evaluate(request("start", [file("")])).unwrap().steps.unwrap().complete,
  )
}

///|
test "versions operations and compiled registration are explicit" {
  let input = request("evaluate", [])
  assert_true(evaluate({ ..input, contract_version: 2, }) is Err(_))
  assert_true(evaluate({ ..input, engine_version: "new", }) is Err(_))
  assert_true(evaluate({ ..input, operation: "compile", }) is Err(_))
  let registered = registration()
  assert_eq(registered.provider, "sample.text")
  assert_eq((registered.evaluate)(input), evaluate(input))
}
