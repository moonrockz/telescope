///|
extern "js" fn install(callback : (String) -> String) -> Unit =
  #| callback => { self.onmessage = event => { self.postMessage(JSON.parse(callback(JSON.stringify(event.data)))); }; }

///|
fn main {
  install(text => {
    let value = @json.parse(text) catch { _ => abort("invalid request JSON") }
    let request : @tutorial.Request = @json.from_json(value) catch {
      _ => abort("invalid request envelope")
    }
    let response = match @engine.evaluate(request) {
      Ok(response) => response
      Err(error) =>
        {
          ..@tutorial.response_for(request),
          status: "error",
          outputs: [
            {
              id: "error",
              label: error.code,
              language: "text",
              text: error.message,
            },
          ],
        }
    }
    Json(response).stringify()
  })
}
