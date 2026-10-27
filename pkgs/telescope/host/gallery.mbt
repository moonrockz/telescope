///|
async fn gallery_outputs(
  root : String,
  config : @model.SiteConfig,
  value : Json,
  out? : String,
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
    @fs.realpath("\{root}/\{artifact_rel}")
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
    if [".html", ".svg", ".css"]
      .iter()
      .any(ext => copy.source_path.has_suffix(ext)) {
      let html = @fs.read_file(source).text()
      for link in resource_links(html) {
        if link == "" ||
          link.has_prefix("#") ||
          link.contains(":") ||
          link.has_prefix("//") {
          continue
        }
        match resolve("/", copy.source_path, link) {
          Err(message) =>
            problems.push(@model.problem(copy.source_path, message))
          Ok((path, _)) =>
            if !declared.contains(path) {
              problems.push(
                @model.problem(copy.source_path, "undeclared companion \{link}"),
              )
            }
        }
      }
    }
    outputs.push(Copy(copy.output_path, artifact_rel + "/" + copy.source_path))
  }
  guard problems.is_empty() else { raise @model.Invalid(problems) }
  for page in plan.pages {
    let meta : @views.PageMeta = {
      config,
      route: page.route,
      title: page.title,
      description: page.title,
      section: Docs,
    }
    let html = @views.render(meta, @views.raw(page.body_html))
    outputs.push(Text(@model.route_file(page.route), html))
  }
  outputs
}
