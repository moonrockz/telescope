///|
async test "gallery reads verified text sources and preserves every downloaded byte" {
  let root = canonical_path(@fs.tmpdir(prefix="telescope-gallery-sources"))
  defer @fs.rmdir(root, recursive=true)
  write(
    root + "/site.json",
    "{\"title\":\"Gallery\",\"description\":\"Fixture\",\"base_path\":\"/\",\"site_url\":\"https://example.test/\",\"repo_url\":\"https://example.test/repo\",\"packages\":[],\"gallery\":{\"manifest\":\"gallery.json\",\"root\":\"artifacts\"}}",
  )
  let source = "<script>window.sourceRan = true</script>\n& \"literal\" café\r\nbody { background: url(missing.png); }\n"
  write(root + "/artifacts/source.txt", source)
  write(root + "/artifacts/code.html", "<script src=\"missing.js\"></script>")
  write(
    root + "/artifacts/source.css",
    "body { background: url(missing.png); }",
  )
  write(root + "/artifacts/second.json", "{\"literal\":\"<tag>\"}\n")
  write(root + "/artifacts/unsupported.bin", "Unsupported secret")
  write(root + "/artifacts/invalid.css", b"\xff\xfe\x00")
  write(root + "/artifacts/nul.txt", "binary\u{0}data")
  write(
    root + "/artifacts/preview.svg",
    "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 1 1'/>",
  )
  write(
    root + "/artifacts/player.html",
    "<!doctype html><title>Separate offline player</title>",
  )
  write(
    root + "/gallery.json",
    "{\"schema_version\":1,\"entries\":[{\"id\":\"one\",\"family\":\"Text\",\"title\":\"Text example\",\"status\":\"implemented\",\"sources\":[{\"path\":\"source.txt\",\"media_type\":\"text/plain; charset=utf-8\"},{\"path\":\"code.html\",\"media_type\":\"text/html\"},{\"path\":\"source.css\",\"media_type\":\"text/css\"},{\"path\":\"second.json\",\"media_type\":\"Application/JSON\"},{\"path\":\"unsupported.bin\",\"media_type\":\"application/octet-stream\"},{\"path\":\"invalid.css\",\"media_type\":\"text/plain\"},{\"path\":\"nul.txt\",\"media_type\":\"text/plain\"}],\"preview\":{\"path\":\"preview.svg\",\"media_type\":\"image/svg+xml\"},\"player\":{\"path\":\"player.html\",\"media_type\":\"text/html\"}}]}",
  )
  for base in ["/", "/example/next/"] {
    ignore(build(root, root + "/site.json", root + "/out", base~))
    let html = @fs.read_file(root + "/out/gallery/one/index.html").text()
    assert_true(
      html.contains(
        "&lt;script&gt;window.sourceRan = true&lt;&#47;script&gt;\n&amp; &quot;literal&quot; café&#13;\nbody { background: url&#40;missing.png&#41;; }\n",
      ),
    )
    assert_true(html.contains("{&quot;literal&quot;:&quot;&lt;tag&gt;&quot;}"))
    assert_false(html.contains("Unsupported secret"))
    assert_false(html.contains("binary\u{0}data"))
    for
      name in [
        "source.txt", "code.html", "source.css", "second.json", "unsupported.bin",
        "invalid.css", "nul.txt", "preview.svg", "player.html",
      ] {
      assert_eq(
        @fs.read_file(root + "/out/gallery/artifacts/" + name).binary(),
        @fs.read_file(root + "/artifacts/" + name).binary(),
      )
      assert_true(html.contains(base + "gallery/artifacts/" + name))
    }
    assert_true(html.contains("Open offline player"))
    assert_true(html.contains(base + "gallery/#family-one"))
  }
}

///|
async test "gallery source symlinks outside artifact root remain rejected" {
  let root = canonical_path(
    @fs.tmpdir(prefix="telescope-gallery-source-boundary"),
  )
  defer @fs.rmdir(root, recursive=true)
  write(
    root + "/site.json",
    "{\"title\":\"Gallery\",\"description\":\"Fixture\",\"base_path\":\"/\",\"site_url\":\"https://example.test/\",\"repo_url\":\"https://example.test/repo\",\"packages\":[]}",
  )
  write(root + "/secret.txt", "private outside artifact root")
  write(
    root + "/artifacts/preview.svg",
    "<svg xmlns='http://www.w3.org/2000/svg'/>",
  )
  @fs.symlink(target=root + "/secret.txt", root + "/artifacts/source.txt")
  write(
    root + "/gallery.json",
    "{\"schema_version\":1,\"entries\":[{\"id\":\"one\",\"family\":\"Text\",\"title\":\"Text example\",\"status\":\"implemented\",\"sources\":[{\"path\":\"source.txt\",\"media_type\":\"text/plain\"}],\"preview\":{\"path\":\"preview.svg\",\"media_type\":\"image/svg+xml\"}}]}",
  )
  let config = configuration(root + "/site.json")
  let problems = try {
    ignore(
      gallery_outputs(root, config, {
        "gallery": { "manifest": "gallery.json", "root": "artifacts" },
      }),
    )
    []
  } catch {
    @model.Invalid(problems) => problems
    error => fail("unexpected error: \{error}")
  }
  assert_true(
    problems.any(p => {
      p.file == "source.txt" && p.message.contains("inside its declared root")
    }),
  )
}

///|
async test "unconfigured gallery produces no gallery output" {
  let root = canonical_path(@fs.tmpdir(prefix="telescope-no-gallery"))
  defer @fs.rmdir(root, recursive=true)
  write(
    root + "/site.json",
    "{\"title\":\"Plain\",\"description\":\"Fixture\",\"base_path\":\"/\",\"site_url\":\"https://example.test/\",\"repo_url\":\"https://example.test/repo\",\"packages\":[]}",
  )
  assert_true(
    gallery_outputs(root, configuration(root + "/site.json"), {}).is_empty(),
  )
}

///|
async test "gallery source declaration never exempts a loaded companion from UTF8 validation" {
  let root = canonical_path(
    @fs.tmpdir(prefix="telescope-gallery-active-source"),
  )
  defer @fs.rmdir(root, recursive=true)
  write(
    root + "/site.json",
    "{\"title\":\"Gallery\",\"description\":\"Fixture\",\"base_path\":\"/\",\"site_url\":\"https://example.test/\",\"repo_url\":\"https://example.test/repo\",\"packages\":[]}",
  )
  write(root + "/artifacts/bad.css", b"\xff\xfe")
  write(
    root + "/artifacts/preview.svg",
    "<svg xmlns='http://www.w3.org/2000/svg'/>",
  )
  write(
    root + "/artifacts/player.html",
    "<title>Player</title><link rel='stylesheet' href='bad.css'>",
  )
  let config = configuration(root + "/site.json")
  for explicit_companion in [false, true] {
    let companions = if explicit_companion {
      ",\"companions\":[{\"path\":\"bad.css\",\"media_type\":\"text/css\"}]"
    } else {
      ""
    }
    write(
      root + "/gallery.json",
      "{\"schema_version\":1,\"entries\":[{\"id\":\"one\",\"family\":\"Text\",\"title\":\"Text example\",\"status\":\"implemented\",\"sources\":[{\"path\":\"bad.css\",\"media_type\":\"text/css\"}],\"preview\":{\"path\":\"preview.svg\",\"media_type\":\"image/svg+xml\"},\"player\":{\"path\":\"player.html\",\"media_type\":\"text/html\"}\{companions}}]}",
    )
    let problems = try {
      ignore(
        gallery_outputs(root, config, {
          "gallery": { "manifest": "gallery.json", "root": "artifacts" },
        }),
      )
      []
    } catch {
      @model.Invalid(problems) => problems
      error => fail("unexpected error: \{error}")
    }
    assert_true(
      problems.any(p => p.file == "bad.css" && p.message.contains("UTF-8")),
    )
  }
}

///|
async test "gallery checker distinguishes opaque source downloads from active resources" {
  let root = canonical_path(
    @fs.tmpdir(prefix="telescope-gallery-check-download"),
  )
  defer @fs.rmdir(root, recursive=true)
  write(
    root + "/index.html",
    "<title>Home</title><a href='/gallery/example/'>Example</a>",
  )
  write(
    root + "/gallery/example/index.html",
    "<title>Example</title><article data-gallery-detail><a href='/gallery/artifacts/source.css' download>Download source</a><a href='/gallery/artifacts/code.html' download>Download markup</a></article>",
  )
  write(root + "/gallery/artifacts/source.css", b"\xff\xfe")
  write(
    root + "/gallery/artifacts/code.html",
    "<script src='illustrative-missing.js'></script>",
  )
  assert_eq(check(root, "/"), [])
  // An ordinary active dependency, even through another stylesheet, restores
  // validation for the same bytes that also have a download link.
  write(
    root + "/assets/loader.css",
    "@import '../gallery/artifacts/source.css';",
  )
  let problems = check(root, "/")
  assert_true(
    problems.any(p => {
      p.file == "gallery/artifacts/source.css" && p.message.contains("UTF-8")
    }),
  )
  // Normal invalid pages still produce diagnostics rather than being treated
  // as downloads just because another gallery artifact is opaque.
  write(root + "/broken.html", b"\xff")
  assert_true(
    check(root, "/").any(p => {
      p.file == "broken.html" && p.message.contains("UTF-8")
    }),
  )
}

///|
async test "gallery checker activates folder index downloads through extensionless navigation" {
  let root = canonical_path(@fs.tmpdir(prefix="telescope-gallery-check-alias"))
  defer @fs.rmdir(root, recursive=true)
  write(root + "/index.html", "<title>Home</title>")
  write(
    root + "/gallery/example/index.html",
    "<title>Example</title><article data-gallery-detail><a href='/gallery/artifacts/folder/index.html' download>Download source</a></article>",
  )
  write(
    root + "/gallery/artifacts/folder/index.html",
    "<p>Literal source without a document title.</p>",
  )
  assert_eq(check(root, "/"), [])
  write(
    root + "/index.html",
    "<title>Home</title><a href='/gallery/artifacts/folder'>Open document</a>",
  )
  assert_true(
    check(root, "/").any(p => {
      p.file == "gallery/artifacts/folder/index.html" &&
      p.message.contains("missing nonempty title")
    }),
  )
}
