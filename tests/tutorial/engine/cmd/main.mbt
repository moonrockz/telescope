///|
async fn main {
  let text = @stdio.stdin.read_all().text()
  let request : @tutorial.Request = @json.from_json(@json.parse(text))
  if @env.args().contains("--input-revision") {
    let provider : @tutorial.Provider = {
      id: request.provider,
      engine_version: request.engine_version,
      contract_version: request.contract_version,
      operations: [request.operation],
      worker: "assets/worker.js",
      assets: ["assets/worker.js"],
      workbench: None,
    }
    @stdio.stdout.write(
      @tutorial.input_revision(
        provider,
        request.operation,
        request.options,
        request.files,
      ),
    )
    return
  }
  match @engine.evaluate(request) {
    Ok(response) => @stdio.stdout.write(Json(response).stringify())
    Err(error) => {
      eprintln(error.code + ": " + error.message)
      @sys.exit(1)
    }
  }
}
