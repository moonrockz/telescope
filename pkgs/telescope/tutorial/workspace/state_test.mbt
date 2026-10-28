///|
fn provider() -> @tutorial.Provider {
  {
    id: "sample",
    contract_version: 1,
    engine_version: "1",
    operations: ["evaluate"],
    worker: "worker.js",
    assets: ["worker.js"],
    workbench: None,
  }
}

///|
test "revision edits coalesce and stale results cannot appear" {
  let state = @workspace.State::new("first")
  let request = state
    .request(provider(), "evaluate", [], Json::empty_object())
    .unwrap()
  state.edit("second")
  state.edit("third")
  assert_true(
    state.request(provider(), "evaluate", [], Json::empty_object()) is None,
  )
  assert_false(state.receive(@tutorial.response_for(request)))
  let newest = state
    .request(provider(), "evaluate", [], Json::empty_object())
    .unwrap()
  assert_eq(newest.input_revision, "third")
  assert_true(state.receive(@tutorial.response_for(newest)))
  assert_eq(state.status, "success")
}

///|
test "timeouts retry exactly once and reset/dispose invalidate workers" {
  let state = @workspace.State::new("first")
  let request = state
    .request(provider(), "evaluate", [], Json::empty_object())
    .unwrap()
  assert_true(state.timeout())
  let retry = state
    .request(provider(), "evaluate", [], Json::empty_object())
    .unwrap()
  assert_true(retry.generation > request.generation)
  assert_false(state.receive(@tutorial.response_for(request)))
  assert_false(state.timeout())
  assert_eq(state.status, "timeout")
  state.reset("first")
  assert_false(state.receive(@tutorial.response_for(retry)))
  state.dispose()
  assert_true(
    state.request(provider(), "evaluate", [], Json::empty_object()) is None,
  )
}
