///|
/// Pure worker bridge around an external Formatter implementation. The browser
/// transport owns deadlines and state. Every response echoes its request.
pub fn[F : Formatter] formatter_reply(formatter : F, request : Json) -> Json {
  let input : FormatInput = match request {
    Object(fields) => {
      guard fields.get("contract_version") is Some(Number(1, ..)) else {
        return {
          "request": request,
          "error": {
            "code": "protocol",
            "message": "unsupported formatter contract version",
          },
        }
      }
      guard fields.get("input") is Some(input) else {
        return {
          "request": request,
          "error": { "code": "protocol", "message": "missing formatting input" },
        }
      }
      @json.from_json(input) catch {
        _ =>
          return {
            "request": request,
            "error": {
              "code": "protocol",
              "message": "invalid formatting input",
            },
          }
      }
    }
    _ =>
      return {
        "request": request,
        "error": {
          "code": "protocol",
          "message": "expected formatting request",
        },
      }
  }
  match formatter.format(input) {
    Ok(output) => { "request": request, "output": output.to_json() }
    Err(error) => { "request": request, "error": error.to_json() }
  }
}
