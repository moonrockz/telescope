///|
test "Windows filesystem spellings share a canonical path representation" {
  for
    (input, expected) in [
      ("C:\\site\\docs", "C:/site/docs"),
      ("\\\\?\\C:\\site\\docs", "C:/site/docs"),
      ("\\\\server\\share\\site", "//server/share/site"),
      ("\\\\?\\UNC\\server\\share\\site", "//server/share/site"),
      ("\\\\?\\unc\\server\\share\\site", "//server/share/site"),
      ("C:/site/docs", "C:/site/docs"),
    ] {
    assert_eq(native_path_text(input, true), expected)
  }
}

///|
test "POSIX filenames and site-relative restrictions remain unchanged" {
  assert_eq(native_path_text("/site/a\\b", false), "/site/a\\b")
  assert_eq(native_path_text("/site/docs", false), "/site/docs")
  assert_false(relative("docs\\guide.md"))
  assert_false(relative("C:/site/docs"))
  assert_true(relative("docs/guide.md"))
}

///|
test "normalized drive and UNC containment rejects sibling roots and shares" {
  for
    root in [
      "C:\\site", "\\\\?\\C:\\site", "\\\\server\\share\\site", "\\\\?\\UNC\\server\\share\\site",
    ] {
    let root = native_path_text(root, true)
    assert_true(within(root, root + "/docs/guide.md"))
    assert_false(within(root, root + "-outside/guide.md"))
  }
  assert_false(within("C:/site", "D:/site/docs"))
  assert_false(within("//server/share/site", "//server/other/site/docs"))
  assert_true(within("C:/", "C:/site"))
  assert_false(within("C:/", "D:/site"))
  assert_true(within("/", "/site"))
}

///|
test "Windows parents preserve drive roots and UNC shares" {
  assert_eq(native_parent("C:\\out", true), "C:/")
  assert_eq(native_parent("C:\\site\\out", true), "C:/site")
  assert_eq(native_parent("\\\\?\\C:\\site\\out", true), "C:/site")
  assert_eq(native_parent("\\\\server\\share\\out", true), "//server/share")
  assert_eq(native_parent("out", true), ".")
  assert_eq(native_parent("/site/a\\b", false), "/site")
}

///|
async test "native preview serves contained paths on an allocated loopback port" {
  let root = canonical_path(@fs.tmpdir(prefix="telescope-native-preview"))
  defer @fs.rmdir(root, recursive=true)
  write(root + "/index.html", "<title>Preview</title>")
  write(root + "/assets/example.txt", "preview bytes")
  let server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
  defer server.close()
  @async.with_task_group() <| group => {
    group.spawn_bg(no_wait=true, () => serve_tree(root, "/example/", server))
    let url = "http://127.0.0.1:\{server.addr.port()}/example/"
    let (response, body) = @http.get(url)
    assert_eq(response.code, 200)
    assert_eq(body.text(), "<title>Preview</title>")
    let (response, body) = @http.get(url + "assets/example.txt")
    assert_eq(response.code, 200)
    assert_eq(body.text(), "preview bytes")
    let (response, _) = @http.get(url + "%2e%2e/secret.txt")
    assert_eq(response.code, 403)
  }
}
