///|
test "path and URL boundaries reject escapes while nested links resolve" {
  assert_false(relative("../secret"))
  assert_false(relative("/etc/passwd"))
  assert_false(relative("a\\b"))
  assert_true(relative("assets/x.svg"))
  assert_eq(
    resolve("/example/", "docs/a/index.html", "../b/#item"),
    Ok(("docs/b/index.html", "item")),
  )
  assert_eq(
    resolve("/example/", "index.html", "/outside/a"),
    Err("leaves deployment base /example/"),
  )
  assert_eq(
    resolve("/example/", "index.html", "%2e%2e/secret"),
    Err("leaves output tree"),
  )
}

///|
async test "checks aggregate missing assets and fragments and JSON origins" {
  let root = @fs.realpath(@fs.tmpdir(prefix="telescope-check"))
  defer @fs.rmdir(root, recursive=true)
  write(
    root + "/index.html",
    "<title>Fixture</title><h1 id='ok'>Home</h1><a href='#bad'>Bad</a><img src='missing.svg'><a href='/outside/'>Escape</a>",
  )
  let problems = check(root, "/example/")
  assert_eq(problems.length(), 3)
  assert_true(diagnostics(problems, "json").contains("index.html"))
  assert_true(diagnostics(problems, "text").contains("missing fragment"))
}

///|
async test "promotion replaces old tree and removes stale files" {
  let root = @fs.realpath(@fs.tmpdir(prefix="telescope-promote"))
  defer @fs.rmdir(root, recursive=true)
  let out = root + "/site"
  write(out + "/stale.txt", "old")
  let stage = stage_for(out)
  write(stage + "/index.html", "new")
  promote(stage, out)
  assert_false(@fs.exists(out + "/stale.txt"))
  assert_eq(@fs.read_file(out + "/index.html").text(), "new")
}

///|
async test "symlinks outside declared input root fail" {
  let root = @fs.realpath(@fs.tmpdir(prefix="telescope-boundary"))
  defer @fs.rmdir(root, recursive=true)
  @fs.mkdir(root + "/inputs")
  write(root + "/secret", "private")
  @fs.symlink(target=root + "/secret", root + "/inputs/link")
  let rejected = try {
    ignore(checked_file(root + "/inputs", "link"))
    false
  } catch {
    _ => true
  }
  assert_true(rejected)
}

///|
test "percent paths decode UTF-8 and reject malformed sequences" {
  assert_eq(decode_url("/a%20b/%C3%A9"), Some("/a b/é"))
  assert_eq(decode_url("/%FF"), None)
  assert_eq(decode_url("/%zz"), None)
  assert_eq(
    resolve("/example/", "index.html", "%2e%2e/secret"),
    Err("leaves output tree"),
  )
}

///|
async test "gallery aggregates missing files and rejects undeclared CSS companion" {
  let root = @fs.realpath(@fs.tmpdir(prefix="telescope-gallery"))
  defer @fs.rmdir(root, recursive=true)
  write(
    root + "/site.json",
    "{\"title\":\"Example\",\"description\":\"Example\",\"base_path\":\"/\",\"site_url\":\"https://example.test/\",\"repo_url\":\"https://example.test/repo\",\"packages\":[]}",
  )
  let config = configuration(root + "/site.json")
  write(
    root + "/artifacts/preview.svg",
    "<svg xmlns='http://www.w3.org/2000/svg'><style>@import 'missing.css';</style></svg>",
  )
  write(
    root + "/gallery.json",
    "{\"schema_version\":1,\"producer\":{\"project\":\"test\",\"ref\":\"r1\",\"pipeline\":\"test\"},\"entries\":[{\"id\":\"one\",\"family\":\"sequence\",\"title\":\"One\",\"status\":\"implemented\",\"sources\":[{\"path\":\"source.txt\",\"media_type\":\"text/plain\"}],\"preview\":{\"path\":\"preview.svg\",\"media_type\":\"image/svg+xml\"},\"player\":{\"path\":\"player.html\",\"media_type\":\"text/html\"}}]}",
  )
  let value : Json = {
    "gallery": { "manifest": "gallery.json", "root": "artifacts" },
  }
  let problems = try {
    ignore(gallery_outputs(root, config, value))
    []
  } catch {
    @model.Invalid(found) => found
    error => fail("unexpected gallery failure: \{error}")
  }
  assert_eq(problems.length(), 3)
  assert_true(
    problems.iter().any(p => p.message.contains("undeclared companion")),
  )
}

///|
async test "planned gallery needs no artifact directory" {
  let root = @fs.realpath(@fs.tmpdir(prefix="telescope-planned"))
  defer @fs.rmdir(root, recursive=true)
  write(
    root + "/site.json",
    "{\"title\":\"Example\",\"description\":\"Example\",\"base_path\":\"/\",\"site_url\":\"https://example.test/\",\"repo_url\":\"https://example.test/repo\",\"packages\":[]}",
  )
  let config = configuration(root + "/site.json")
  write(
    root + "/gallery.json",
    "{\"schema_version\":1,\"producer\":{\"project\":\"test\",\"ref\":\"r1\",\"pipeline\":\"test\"},\"entries\":[{\"id\":\"dot\",\"family\":\"dot\",\"title\":\"DOT\",\"status\":\"planned\"}]}",
  )
  let value : Json = { "gallery": { "manifest": "gallery.json" } }
  let outputs = gallery_outputs(root, config, value)
  assert_true(outputs.length() > 0)
  assert_true(
    outputs
    .iter()
    .all(output => {
      match output {
        Text(_, _) => true
        Copy(_, _) => false
      }
    }),
  )
}

///|
async test "offline supplied trees retain HTML and isolate links at root base" {
  let root = @fs.realpath(@fs.tmpdir(prefix="telescope-versions"))
  defer @fs.rmdir(root, recursive=true)
  write(
    root + "/trees/next/index.html",
    "<html><head><title>Next</title></head><body><div class=\"version-banner\"></div><a href=\"/next/docs/\">Docs</a></body></html>",
  )
  write(
    root + "/trees/next/docs/index.html",
    "<title>Docs</title><a href=\"/next/\">Home</a>",
  )
  write(
    root + "/versions.json",
    "{\"schema_version\":1,\"base_path\":\"/\",\"trees\":[{\"id\":\"next\",\"path\":\"trees/next\",\"base_path\":\"/next/\"}]}",
  )
  assemble(root + "/versions.json", root + "/out")
  assert_eq(check(root + "/out", "/"), [])
  let home = @fs.read_file(root + "/out/index.html").text()
  assert_true(home.contains("</html>"))
  assert_true(home.contains("href=\"/docs/\""))
  assert_true(home.contains("No version is released yet"))
  assert_false(@fs.exists(root + "/out/latest"))
  assert_eq(
    rebase_tree("<a href='/docs/'>x</a>", "/", "/next/"),
    "<a href='/next/docs/'>x</a>",
  )
}

///|
async test "host metadata creation rejects a symlinked ancestor before writing" {
  let root = @fs.realpath(@fs.tmpdir(prefix="telescope-host-path"))
  defer @fs.rmdir(root, recursive=true)
  let outside = @fs.realpath(@fs.tmpdir(prefix="telescope-outside"))
  defer @fs.rmdir(outside, recursive=true)
  @fs.symlink(target=outside, root + "/escape")
  let rejected = try {
    ignore(bounded_path(root, "escape/new/module"))
    false
  } catch {
    _ => true
  }
  assert_true(rejected)
  assert_false(@fs.exists(outside + "/new"))
}

///|
async test "version assembly preserves offline gallery source and player bytes" {
  let root = @fs.realpath(@fs.tmpdir(prefix="telescope-version-artifact"))
  defer @fs.rmdir(root, recursive=true)
  write(
    root + "/tree/index.html",
    "<title>Next</title><div class=\"version-banner\"></div>",
  )
  let player = "<title>Offline</title><script>const site='https://example.test/example/next/';</script>"
  let source = "{\"source\":\"https://example.test/example/next/\"}"
  write(root + "/tree/gallery/artifacts/player.html", player)
  write(root + "/tree/gallery/artifacts/source.json", source)
  write(
    root + "/manifest.json",
    "{\"schema_version\":1,\"base_path\":\"/example/\",\"site_url\":\"https://example.test/example/\",\"trees\":[{\"id\":\"next\",\"path\":\"tree\",\"base_path\":\"/example/next/\"}]}",
  )
  assemble(root + "/manifest.json", root + "/out")
  for tree in ["", "next/"] {
    assert_eq(
      @fs.read_file(root + "/out/" + tree + "gallery/artifacts/player.html").text(),
      player,
    )
    assert_eq(
      @fs.read_file(root + "/out/" + tree + "gallery/artifacts/source.json").text(),
      source,
    )
  }
}
