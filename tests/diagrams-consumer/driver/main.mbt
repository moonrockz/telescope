// Original source-level qualification driver, Apache-2.0.

///|
fn demand(ok : Bool, message : String) -> Unit {
  guard ok else {
    eprintln(message)
    abort(message)
  }
}

///|
fn source_literal(html : String, id : String) -> Bool {
  let mut rest = html[:]
  while rest.find("<code") is Some(start) {
    let code = rest[start:]
    guard code.find(">") is Some(begin) && code.find("</code>") is Some(end) else {
      break
    }
    if code[begin + 1:end].contains(" id='" + id + "'") {
      return true
    }
    rest = code[end + "</code>".length():]
  }
  false
}

///|
fn recorded_source_literals() -> Map[String, Array[String]] {
  {
    "docs/packages/bpmn/index.html": ["A", "B", "C", "P", "AB", "BC"],
    "docs/packages/diagrams-bpmn/index.html": ["P", "T", "Other"],
  }
}

///|
async fn compare_baseline(
  out : String,
  legacy : String,
  baseline : Json,
) -> Int32 {
  guard baseline is Object(fields) && fields.get("pages") is Some(Object(pages)) else {
    abort("Invalid attributed route/anchor baseline")
  }
  demand(pages.length() == 77, "Expected the reviewed 77-page baseline")
  let mut anchors = 0
  let missing = []
  for path, expected in pages {
    if !@fs.exists(out + "/" + path) {
      missing.push(path + ": missing page")
      continue
    }
    let html = @fs.read_file(out + "/" + path).text()
    let original = @fs.read_file(legacy + "/" + path).text()
    let ids = @content.ids_in(html)
    let original_ids = @content.ids_in(original)
    guard expected is Array(expected) else { abort("Invalid anchor list") }
    for anchor in expected {
      guard anchor is String(anchor) else { abort("Invalid anchor") }
      if original_ids.contains(anchor) {
        anchors += 1
        if !ids.contains(anchor) {
          missing.push(path + "#" + anchor)
        }
      } else {
        demand(
          recorded_source_literals().get(path).unwrap_or([]).contains(anchor),
          "Unclassified baseline ID absent from original DOM: " +
          path +
          "#" +
          anchor,
        )
      }
    }
  }
  // The legacy capture split all text on ` id=` and mistook these escaped XML
  // strings for anchors. Prove each was never a DOM ID and retain its code text.
  for path, literals in recorded_source_literals() {
    let original = @fs.read_file(legacy + "/" + path).text()
    let html = @fs.read_file(out + "/" + path).text()
    for id in literals {
      demand(
        !@content.ids_in(original).contains(id),
        "Expected legacy code literal became a DOM anchor: " + path + "#" + id,
      )
      demand(
        !@content.ids_in(html).contains(id),
        "Escaped code literal became a DOM anchor: " + path + "#" + id,
      )
      demand(
        source_literal(original, id) && source_literal(html, id),
        "Escaped source literal disappeared: " + path + " id='" + id + "'",
      )
    }
  }
  demand(
    missing.is_empty(),
    "Missing baseline routes/anchors:\n" + missing.join("\n"),
  )
  demand(
    anchors == 5376,
    "Reviewed baseline must retain exactly 5376 genuine DOM anchors",
  )
  anchors
}

///|
async fn verify_gallery(root : String, out : String) -> Int32 {
  let manifest = match
    @gallery.parse_manifest(@fs.read_file(root + "/site/gallery.json").text()) {
    Ok(manifest) => manifest
    Err(problems) => abort(@host.diagnostics(problems, "human"))
  }
  let expected = [
    ("sequence-basic", "sequence"),
    ("zenuml-symbols", "ZenUML"),
    ("architecture-cloud", "architecture"),
    ("bpmn-process", "BPMN"),
    ("bpmn-collaboration", "BPMN"),
    ("swimlane-review", "swimlane"),
    ("regex-date", "regex"),
    ("regex-evidence", "regex"),
    ("ebnf-arithmetic", "EBNF"),
    ("ebnf-evidence", "EBNF"),
    ("json-order", "JSON"),
    ("yaml-service", "YAML"),
  ]
  demand(manifest.entries.length() == 12, "Expected 12 current gallery entries")
  for (id, family) in expected {
    let found = manifest.entries.iter().find_first(entry => entry.id == id)
    demand(found is Some(_), "Missing gallery entry " + id)
    let entry = found.unwrap()
    demand(
      entry.family == family && entry.status == Implemented,
      "Gallery family/status changed for " + id,
    )
    let html = @fs.read_file(out + "/gallery/" + id + "/index.html").text()
    demand(
      html.contains(family) && html.contains("Implemented"),
      "Gallery detail omitted family/status " + id,
    )
  }
  let plan = match @gallery.plan(manifest, "/diagrams.mbt/") {
    Ok(plan) => plan
    Err(problems) => abort(@host.diagnostics(problems, "human"))
  }
  for copy in plan.copies {
    demand(
      @fs.read_file(root + "/apps/site/assets/examples/" + copy.source_path).binary() ==
      @fs.read_file(out + "/" + copy.output_path).binary(),
      "Artifact bytes changed: " + copy.source_path,
    )
  }
  plan.copies.length()
}

///|
async fn main {
  execute() catch {
    @model.Invalid(problems) => {
      eprintln(@host.diagnostics(problems, "human"))
      abort("Diagrams consumer compatibility failed")
    }
    error => {
      eprintln("Diagrams consumer failed: \{error}")
      abort("Consumer failed")
    }
  }
}

///|
async fn execute() -> Unit {
  let args = @env.args()[1:].to_owned()
  guard args.length() == 2 else {
    abort("usage: diagrams-consumer INPUT_ROOT REPORT")
  }
  let root = args[0]
  let baseline = @json.parse(@fs.read_file(root + "/baseline.json").text())
  let out = root + "/built"
  let warnings = @host.build(
    root,
    root + "/site/site.json",
    out,
    providers=providers(),
    main_build=true,
  )
  let anchors = compare_baseline(out, root + "/legacy", baseline)
  let artifacts = verify_gallery(root, out)
  demand(
    @host.check(out, "/diagrams.mbt/").is_empty(),
    "Built internal link check failed",
  )
  let manifest : Json = {
    "schema_version": 1,
    "base_path": "/diagrams.mbt/",
    "latest": "0.2",
    "trees": [
      { "id": "next", "path": "built", "base_path": "/diagrams.mbt/" },
      { "id": "0.2", "path": "built", "base_path": "/diagrams.mbt/" },
    ],
  }
  @fs.write_file(root + "/versions-input.json", manifest.stringify())
  @host.assemble(root + "/versions-input.json", root + "/assembled")
  demand(
    @host.check(root + "/assembled", "/diagrams.mbt/").is_empty(),
    "Assembled internal link check failed",
  )
  for prefix in ["", "/next", "/v/0.2", "/latest"] {
    ignore(
      compare_baseline(root + "/assembled" + prefix, root + "/legacy", baseline),
    )
    ignore(verify_gallery(root, root + "/assembled" + prefix))
  }
  let evidence : Json = {
    "qualification": "source-level prerelease compatibility proof",
    "published": false,
    "registry_install": false,
    "baseline_pages": 77,
    "baseline_anchors": anchors,
    "comparison": "Every recorded public page and genuine DOM anchor must remain present; additive anchors are allowed",
    "retained_escaped_source_literals": 9,
    "baseline_qualification": "Nine legacy inventory IDs are escaped XML inside code, not DOM anchors; verified against original output and retained as code literals",
    "gallery_entries": 12,
    "byte_preserved_artifacts": artifacts,
    "internal_links": "passed on built and assembled trees",
    "trees": ["root", "next", "v/0.2", "latest"],
    "version_policy": "Supplied synthetic 0.2 tree tests offline assembly only; no publication or released-install claim",
    "warnings": {
      "total": warnings.length(),
      "missing_api_prose": warnings
      .filter(p => p.message.contains("has no doc prose"))
      .length(),
      "examples": warnings.iter().take(5).map(p => p.message).to_array(),
      "other": warnings
      .filter(p => !p.message.contains("has no doc prose"))
      .map(p => p.message),
    },
  }
  @fs.write_file(
    args[1],
    evidence.stringify(indent=2),
    create_mode=CreateOrTruncate,
  )
  println(evidence.stringify(indent=2))
}
