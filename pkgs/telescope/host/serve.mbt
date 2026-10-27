// Adapted from diagrams.mbt scripts/serve-site.mbtx, Apache-2.0.

///|
fn content_type(name : String) -> String {
  for
    (ext, mime) in [
      (".html", "text/html; charset=utf-8"),
      (".css", "text/css"),
      (".js", "text/javascript"),
      (".json", "application/json"),
      (".xml", "application/atom+xml"),
      (".svg", "image/svg+xml"),
      (".png", "image/png"),
    ] {
    if name.has_suffix(ext) {
      return mime
    }
  }
  "application/octet-stream"
}

///|
async fn error_response(
  conn : @http.ServerConnection,
  meth : @http.RequestMethod,
  code : Int32,
  reason : String,
) -> Unit {
  conn.send_response(code, reason)
  if meth != Head {
    conn.write(reason)
  }
}

///|
pub async fn serve(out : String, base : String, port : Int32) -> Unit {
  guard port > 0 && port <= 65535 else {
    raise @model.Invalid([
      @model.problem("--port", "must be between 1 and 65535"),
    ])
  }
  let root = @fs.realpath(out)
  @signal.set_global_cancellation_signals([SIGINT, SIGTERM])
  let server = @http.Server(
    @socket.Addr::parse("127.0.0.1:\{port}"),
    reuse_addr=true,
  )
  println("http://127.0.0.1:\{port}\{base}")
  server.run_forever(allow_failure=true, (request, _body, conn) => {
    if request.meth != Get && request.meth != Head {
      error_response(conn, request.meth, 405, "Method Not Allowed")
      return
    }
    guard decode_url(request.path) is Some(target) else {
      error_response(conn, request.meth, 403, "Forbidden")
      return
    }
    if !target.has_prefix(base) {
      conn.send_response(
        302,
        "Found",
        extra_headers=Map::from_array([
          (@http.CaseInsensitiveString("Location"), base),
        ]),
      )
      return
    }
    let rel = target[base.length():].to_owned()
    let rel = match rel.find("?") {
      Some(i) => rel[:i].to_owned()
      None => rel
    }
    if rel.contains("\\") ||
      rel.contains("\u{0}") ||
      rel.split("/").any(p => p == ".." || p == ".") ||
      rel.has_prefix("/") {
      error_response(conn, request.meth, 403, "Forbidden")
      return
    }
    let file = if rel == "" || rel.has_suffix("/") {
      rel + "index.html"
    } else {
      rel
    }
    if !@fs.exists("\{root}/\{file}") {
      error_response(conn, request.meth, 404, "Not Found")
      return
    }
    let path = checked_file(root, file) catch {
      _ => {
        error_response(conn, request.meth, 403, "Forbidden")
        return
      }
    }
    conn.send_response(
      200,
      "OK",
      extra_headers=Map::from_array([
        (@http.CaseInsensitiveString("Content-Type"), content_type(file)),
        (
          @http.CaseInsensitiveString("Content-Length"),
          @fs.file_size(path).to_string(),
        ),
      ]),
    )
    if request.meth != Head {
      conn.write(@fs.read_file(path).binary())
    }
  })
}
