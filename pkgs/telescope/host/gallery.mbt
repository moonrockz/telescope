///|
async fn gallery_outputs(
  root : String,
  config : @model.SiteConfig,
  value : Json,
  out? : String,
  tutorial_nav~ : Array[(String, String)] = [],
) -> Array[@site.Output] {
  guard value is Object(fields) &&
    fields.get("gallery") is Some(Object(gallery)) else {
    return []
  }
  let gallery = Json::object(gallery)
  let manifest_path = string_field(gallery, "manifest", "")
  let manifest_file = checked_file(root, manifest_path)
  if out is Some(out) && within(out, manifest_file) {
    raise @model.Invalid([
      @model.problem(manifest_path, "gallery manifest lies inside output"),
    ])
  }
  let text = @fs.read_file(manifest_file).text()
  let manifest = match @gallery.parse_manifest(text, source=manifest_path) {
    Ok(m) => m
    Err(p) => raise @model.Invalid(p)
  }
  let plan = match @gallery.plan(manifest, config.base_path) {
    Ok(p) => p
    Err(p) => raise @model.Invalid(p)
  }
  let artifact_rel = string_field(
    gallery,
    "root",
    string_field(@json.parse(text), "root", ""),
  )
  guard plan.copies.is_empty() || relative(artifact_rel) else {
    raise @model.Invalid([
      @model.problem(manifest_path, "gallery requires a relative artifact root"),
    ])
  }
  let artifact_root = if plan.copies.is_empty() {
    root
  } else {
    canonical_path("\{root}/\{artifact_rel}")
  }
  guard within(root, artifact_root) else {
    raise @model.Invalid([
      @model.problem(artifact_rel, "gallery root escapes project"),
    ])
  }
  if !plan.copies.is_empty() &&
    out is Some(out) &&
    (within(artifact_root, out) || within(out, artifact_root)) {
    raise @model.Invalid([
      @model.problem(artifact_rel, "gallery input and output roots overlap"),
    ])
  }
  let outputs : Array[@site.Output] = []
  let problems = []
  let declared : Map[String, Bool] = Map([])
  for copy in plan.copies {
    declared[copy.source_path] = true
  }
  // Only declared sources with supported textual media types are read for display.
  let required_resources : Map[String, Bool] = Map([])
  let readable : Map[String, Bool] = Map([])
  for entry in manifest.entries {
    for file in [entry.preview, entry.preview_dark, entry.player] {
      if file is Some(file) {
        required_resources[file.path] = true
      }
    }
    for file in entry.companions {
      required_resources[file.path] = true
    }
    for file in [entry.preview, entry.preview_dark] {
      if file is Some(file) && file.media_type == "image/svg+xml" {
        readable[file.path] = true
      }
    }
    for file in entry.sources {
      let media = file.media_type
        .split(";")
        .next()
        .unwrap_or("")
        .trim()
        .to_owned()
        .to_lower()
      if media.has_prefix("text/") ||
        [
          "application/json", "application/xml", "application/yaml", "application/x-yaml",
          "application/javascript", "image/svg+xml",
        ].contains(media) ||
        media.has_suffix("+json") ||
        media.has_suffix("+xml") {
        readable[file.path] = true
      }
    }
  }
  let source_text : Map[String, String] = Map([])
  let verified : Map[String, String] = Map([])
  for copy in plan.copies {
    let source = checked_file(artifact_root, copy.source_path) catch {
      @model.Invalid(found) => {
        problems.append(found)
        continue
      }
      error => {
        problems.push(
          @model.problem(
            copy.source_path,
            "missing or unreadable artifact: \{error}",
          ),
        )
        continue
      }
    }
    verified[copy.source_path] = source
    if readable.contains(copy.source_path) {
      let bytes = @fs.read_file(source)
      let text = try @utf8.decode(bytes.binary()) catch {
        _ => None
      } noraise {
        text => Some(text)
      }
      if text is Some(text) {
        // NUL-bearing data is binary even when every byte is valid UTF-8.
        if !text.contains("\u{0}") {
          source_text[copy.source_path] = text
        }
      }
    }
    outputs.push(Copy(copy.output_path, artifact_rel + "/" + copy.source_path))
  }
  // Sources are inert downloads unless a supplied preview/player/companion
  // actually loads them. Follow that graph so source declarations cannot exempt
  // an active dependency, regardless of its position in the manifest.
  let pending = required_resources.keys().to_array()
  let mut next = 0
  while next < pending.length() {
    let path = pending[next]
    next += 1
    guard verified.get(path) is Some(source) else { continue }
    if ![".html", ".svg", ".css"].any(ext => path.has_suffix(ext)) {
      continue
    }
    let data = @fs.read_file(source)
    let text = try @utf8.decode(data.binary()) catch {
      _ => None
    } noraise {
      text => Some(text)
    }
    guard text is Some(text) && !text.contains("\u{0}") else {
      problems.push(@model.problem(path, "resource is not valid UTF-8 text"))
      continue
    }
    for link in resource_links(text) {
      if link == "" ||
        link.has_prefix("#") ||
        link.contains(":") ||
        link.has_prefix("//") {
        continue
      }
      match resolve("/", path, link) {
        Err(message) => problems.push(@model.problem(path, message))
        Ok((target, _)) =>
          if !declared.contains(target) {
            problems.push(@model.problem(path, "undeclared companion \{link}"))
          } else if !required_resources.contains(target) {
            required_resources[target] = true
            pending.push(target)
          }
      }
    }
  }
  guard problems.is_empty() else { raise @model.Invalid(problems) }
  let rendered = match @gallery.plan(manifest, config.base_path, source_text~) {
    Ok(p) => p
    Err(p) => raise @model.Invalid(p)
  }
  for page in rendered.pages {
    let meta : @views.PageMeta = {
      config,
      route: page.route,
      title: page.title,
      description: page.title,
      section: Docs,
    }
    let html = @views.render(
      meta,
      @views.raw(page.body_html),
      gallery=true,
      tutorial_nav~,
    )
    outputs.push(Text(@model.route_file(page.route), html))
  }
  outputs
}
