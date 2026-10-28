///|
test "request and response wire use standard JSON null and optional fields" {
  let standard = @json.parse(
    "{\"contract_version\":1,\"provider\":\"sample\",\"engine_version\":\"1\",\"generation\":1,\"request_id\":2,\"input_revision\":\"r\",\"operation\":\"evaluate\",\"files\":[],\"options\":{},\"session\":null,\"position\":null}",
  )
  let request : Request = @json.from_json(standard)
  assert_eq(request.session, None)
  assert_eq(Json(request), standard)
  let omitted = match standard {
    Object(fields) => {
      let copy = fields.copy()
      copy.remove("session")
      copy.remove("position")
      Json::object(copy)
    }
    _ => abort("object")
  }
  assert_eq((@json.from_json(omitted) : Request), request)
  let response = response_for(request)
  let encoded = Json(response)
  assert_true(
    encoded is { "blocked": Null, "verdict": Null, "steps": Null, .. },
  )
  assert_eq((@json.from_json(encoded) : Response), response)
}

///|
test "diagnostic and steps optional locations and summary are scalar or null" {
  let diagnostic : Diagnostic = @json.from_json(
    @json.parse(
      "{\"key\":\"key\",\"code\":\"code\",\"severity\":\"info\",\"message\":\"literal\",\"file\":\"input.txt\",\"line\":1,\"column\":2}",
    ),
  )
  let encoded = Json(diagnostic)
  assert_true(
    encoded
    is {
      "file": "input.txt",
      "line": 1,
      "column": 2,
      "end_line": Null,
      "end_column": Null,
      ..
    },
  )
  assert_eq((@json.from_json(encoded) : Diagnostic), diagnostic)
  let steps : Steps = @json.from_json(
    @json.parse(
      "{\"session\":\"s\",\"rows\":[],\"checked\":0,\"complete\":true,\"summary\":\"done\"}",
    ),
  )
  assert_true(Json(steps) is { "summary": "done", .. })
  assert_eq((@json.from_json(Json(steps)) : Steps), steps)
}

///|
test "wire rejects option array representation unknown fields and fractional identities" {
  let base = Json(Request::{
    contract_version: 1,
    provider: "p",
    engine_version: "1",
    generation: 1,
    request_id: 1,
    input_revision: "r",
    operation: "evaluate",
    files: [],
    options: {},
    session: None,
    position: None,
  })
  guard base is Object(fields) else { abort("object") }
  for
    (key, value) in [
      ("session", Json::array([])),
      ("position", Json(1.5)),
      ("request_id", Json(1.5)),
      ("unknown", Json(true)),
    ] {
    let copy = fields.copy()
    copy[key] = value
    let failed = try {
      ignore((@json.from_json(Json::object(copy)) : Request))
      false
    } catch {
      _ => true
    }
    assert_true(failed)
  }
}

///|
test "canonical keys use JavaScript lexical UTF16 ordering" {
  assert_eq(
    canonical({
      "schema_version": 1,
      "provider": "sample",
      "files": [],
      "z": 1,
      "aa": 2,
    }),
    "{\"aa\":2,\"files\":[],\"provider\":\"sample\",\"schema_version\":1,\"z\":1}",
  )
  assert_eq(
    canonical({ "😀": 1, "\uE000": 2, "a": 3 }),
    "{\"a\":3,\"😀\":1,\"\uE000\":2}",
  )
}
