///|
fn escape(value : String) -> String {
  value
  .replace_all(old="&", new="&amp;")
  .replace_all(old="<", new="&lt;")
  .replace_all(old=">", new="&gt;")
  .replace_all(old="\"", new="&quot;")
  .replace_all(old="'", new="&#39;")
}

///|
fn status_label(status : Status) -> String {
  match status {
    Implemented => "Implemented"
    Planned => "Planned"
  }
}

///|
fn artifact_url(base_path : String, file : FileRef) -> String {
  base_path + "gallery/artifacts/" + file.path
}

///|
/// Explicit surfaces keep supplied light and dark SVGs readable even with no JS.
fn previews(entry : Entry, base_path : String) -> String {
  guard entry.preview is Some(light) else { return "" }
  let alt = escape(entry.title + " preview")
  let light_url = escape(artifact_url(base_path, light))
  let dark = match entry.preview_dark {
    Some(file) =>
      "<figure class=\"gallery-preview gallery-dark\" style=\"background:#161b22;color:#f0f6fc;padding:1rem;overflow:auto\"><img style=\"max-width:100%;height:auto\" src=\"\{escape(artifact_url(base_path, file))}\" alt=\"\{alt} (dark)\" loading=\"lazy\"><figcaption>Dark preview. <a href=\"\{escape(artifact_url(base_path, file))}\" download>Download dark SVG</a></figcaption></figure>"
    None => ""
  }
  "<figure class=\"gallery-preview gallery-light\" style=\"background:#fff;color:#161b22;padding:1rem;overflow:auto\"><img style=\"max-width:100%;height:auto\" src=\"\{light_url}\" alt=\"\{alt}\" loading=\"lazy\"><figcaption>\{if dark == "" { "Preview" } else { "Light preview" }}. <a href=\"\{light_url}\" download>Download SVG</a></figcaption></figure>\{dark}"
}

///|
fn detail_body(entry : Entry, base_path : String, family_id : String) -> String {
  let description = match entry.description {
    Some(text) => "<p>\{escape(text)}</p>"
    None => ""
  }
  let scope = match entry.scope {
    Some(text) => "<p>Scope: \{escape(text)}</p>"
    None => ""
  }
  let heading = "<p><a href=\"\{base_path}gallery/\">Gallery</a></p><h1>\{escape(entry.title)}</h1><p>Family: <a href=\"\{base_path}gallery/#\{family_id}\">\{escape(entry.family)}</a>. Status: <strong>\{status_label(entry.status)}</strong>.</p>\{description}\{scope}"
  if entry.status == Planned {
    return heading +
      "<p>This example is planned. No generated preview or offline player is supplied.</p>"
  }
  let links = entry.sources
    .map(file => {
      "<li><a href=\"\{escape(artifact_url(base_path, file))}\" download>\{escape(file.path)}</a> <span>\{escape(file.media_type)}</span></li>"
    })
    .join("")
  let player = match entry.player {
    Some(file) =>
      "<p><a href=\"\{escape(artifact_url(base_path, file))}\">Open offline player</a></p>"
    None => ""
  }
  heading +
  previews(entry, base_path) +
  "<h2>Source downloads</h2><ul>\{links}</ul>" +
  player
}

///|
/// Return shell inputs and a byte-preserving copy plan. This function performs no IO.
pub fn plan(
  manifest : Manifest,
  base_path : String,
) -> Result[GalleryPlan, Array[@model.Problem]] {
  let problems = validate(manifest)
  if !(base_path == "/" ||
    (
      base_path.has_prefix("/") &&
      base_path.has_suffix("/") &&
      base_path.length() > 2 &&
      valid_relative_path(base_path[1:base_path.length() - 1].to_owned())
    )) {
    problems.push(
      issue("gallery.json", "base_path", "must be / or a normalized /path/"),
    )
  }
  if !problems.is_empty() {
    return Err(problems)
  }
  let families : Array[String] = []
  let family_ids : Map[String, String] = Map([])
  for entry in manifest.entries {
    if !family_ids.contains(entry.family) {
      families.push(entry.family)
      family_ids[entry.family] = "family-" + entry.id
    }
  }
  let navigation = families
    .map(family => "<a href=\"#\{family_ids[family]}\">\{escape(family)}</a>")
    .join(" · ")
  let groups = families
    .map(family => {
      let cards = manifest.entries
        .filter(entry => entry.family == family)
        .map(entry => {
          "<li><a href=\"\{base_path}gallery/\{entry.id}/\">\{escape(entry.title)}</a> <span>\{escape(entry.family)}</span> <strong>\{status_label(entry.status)}</strong></li>"
        })
        .join("")
      "<section id=\"\{family_ids[family]}\"><h2>\{escape(family)}</h2><ul>\{cards}</ul></section>"
    })
    .join("")
  let provenance = match manifest.producer {
    Some(producer) =>
      "<p>Examples supplied by \{escape(producer.project)}. Source ref: <code>\{escape(producer.source_ref)}</code>. Pipeline: \{escape(producer.pipeline)}.</p>"
    None => ""
  }
  let pages : Array[GalleryPage] = [
    {
      route: "/gallery/",
      title: "Gallery",
      body_html: "<h1>Gallery</h1>\{provenance}<nav aria-label=\"Gallery families\">\{navigation}</nav>\{groups}",
    },
  ]
  let copies : Array[ArtifactCopy] = []
  let seen : Map[String, Bool] = Map([])
  for entry in manifest.entries {
    pages.push({
      route: "/gallery/\{entry.id}/",
      title: entry.title,
      body_html: detail_body(entry, base_path, family_ids[entry.family]),
    })
    for file in entry.artifacts() {
      if !seen.contains(file.path) {
        seen[file.path] = true
        copies.push({
          source_path: file.path,
          output_path: "gallery/artifacts/" + file.path,
          media_type: file.media_type,
        })
      }
    }
  }
  Ok({ pages, copies, })
}
