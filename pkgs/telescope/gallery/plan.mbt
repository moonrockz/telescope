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
/// Theme selection belongs to CSS, including when scripting is unavailable.
fn previews(entry : Entry, base_path : String, card~ : Bool = false) -> String {
  guard entry.preview is Some(light) else {
    return "<p class=\"gallery-placeholder\">Planned example. No preview supplied.</p>"
  }
  let frame = if card { "gallery-card-preview" } else { "gallery-preview" }
  let light_class = if entry.preview_dark is Some(_) {
    "gallery-light"
  } else {
    "gallery-light-only"
  }
  let alt = escape(entry.title + " preview")
  let light_html = "<figure class=\"\{frame} \{light_class}\"><img src=\"\{escape(artifact_url(base_path, light))}\" alt=\"\{alt}\" loading=\"lazy\"></figure>"
  let dark_html = match entry.preview_dark {
    Some(file) =>
      "<figure class=\"\{frame} gallery-dark\"><img src=\"\{escape(artifact_url(base_path, file))}\" alt=\"\{alt} (dark)\" loading=\"lazy\"></figure>"
    None => ""
  }
  light_html + dark_html
}

///|
fn detail_body(
  entry : Entry,
  base_path : String,
  family_id : String,
  source_text : Map[String, String],
) -> String {
  let description = match entry.description {
    Some(text) => "<p>\{escape(text)}</p>"
    None => ""
  }
  let scope = match entry.scope {
    Some(text) => "<p class=\"gallery-scope\">Scope: \{escape(text)}</p>"
    None => ""
  }
  let heading = "<article class=\"gallery-detail\" data-gallery-detail><p><a href=\"\{base_path}gallery/\">Gallery</a> / <a href=\"\{base_path}gallery/#\{family_id}\">\{escape(entry.family)}</a></p><h1>\{escape(entry.title)}</h1><p class=\"gallery-card-meta\">Family: <a href=\"\{base_path}gallery/#\{family_id}\">\{escape(entry.family)}</a>. Status: <strong class=\"gallery-badge\">\{status_label(entry.status)}</strong>.</p>\{description}\{scope}"
  if entry.status == Planned {
    return heading +
      "<p>This example is planned. No generated preview or offline player is supplied.</p></article>"
  }
  let sources = entry.sources
    .mapi((i, file) => {
      let content = match source_text.get(file.path) {
        Some(text) => {
          let literal = escape(text)
            .replace_all(old="\r", new="&#13;")
            .replace_all(old="(", new="&#40;")
            .replace_all(old=")", new="&#41;")
          "<pre tabindex=\"0\" aria-label=\"\{escape(file.path)} source\"><code>\{literal}</code></pre>"
        }
        None =>
          "<p>Inline source unavailable. Download this source to inspect it.</p>"
      }
      "<section class=\"gallery-source-file\" aria-labelledby=\"gallery-source-\{i}\"><h3 class=\"gallery-source-heading\" id=\"gallery-source-\{i}\">\{escape(file.path)}</h3><p>\{escape(file.media_type)}</p>\{content}<p class=\"gallery-actions\"><a href=\"\{escape(artifact_url(base_path, file))}\" download>Download source: \{escape(file.path)}</a></p></section>"
    })
    .join("")
  let downloads = [entry.preview, entry.preview_dark]
    .mapi((i, file) => {
      match file {
        Some(file) =>
          "<a href=\"\{escape(artifact_url(base_path, file))}\" download>\{if i == 0 { "Download SVG" } else { "Download dark SVG" }}</a>"
        None => ""
      }
    })
    .filter(link => link != "")
    .join(" ")
  let player = match entry.player {
    Some(file) =>
      "<a href=\"\{escape(artifact_url(base_path, file))}\">Open offline player</a>"
    None => ""
  }
  heading +
  "<div class=\"gallery-workbench\"><div class=\"gallery-tabs\"></div><section class=\"gallery-panel\" id=\"gallery-preview\"><h2>Preview</h2>\{previews(entry, base_path)}</section><section class=\"gallery-panel gallery-source\" id=\"gallery-source\"><h2>Source</h2>\{sources}</section></div><p class=\"gallery-actions\">\{downloads} \{player}</p></article>"
}

///|
/// Return shell inputs and a byte-preserving copy plan, without IO. Source text is
/// optional and keyed by declared source path. Existing two-argument calls work.
pub fn plan(
  manifest : Manifest,
  base_path : String,
  source_text~ : Map[String, String] = Map([]),
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
    .map(family => {
      "<a href=\"#\{family_ids[family]}\" data-gallery-family=\"\{family_ids[family]}\">\{escape(family)}</a>"
    })
    .join(" ")
  let groups = families
    .map(family => {
      let cards = manifest.entries
        .filter(entry => entry.family == family)
        .map(entry => {
          let description = entry.description.unwrap_or("")
          let terms = escape(
            entry.title + " " + entry.family + " " + description,
          )
          "<li class=\"gallery-card\" data-gallery-search=\"\{terms}\"><a class=\"gallery-card-link\" aria-label=\"\{escape(entry.title)}\" href=\"\{base_path}gallery/\{entry.id}/\">\{previews(entry, base_path, card=true)}<div class=\"gallery-card-body\"><span class=\"gallery-card-title\">\{escape(entry.title)}</span><p class=\"gallery-card-meta\">\{escape(entry.family)} <strong class=\"gallery-badge\">\{status_label(entry.status)}</strong></p><p>\{escape(description)}</p></div></a></li>"
        })
        .join("")
      "<section class=\"gallery-group\" id=\"\{family_ids[family]}\"><h2>\{escape(family)}</h2><ul class=\"gallery-grid\">\{cards}</ul></section>"
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
      body_html: "<div class=\"gallery-index\" data-gallery-index id=\"gallery-all\"><h1>Gallery</h1>\{provenance}<div class=\"gallery-layout\"><nav class=\"gallery-rail\" aria-label=\"Gallery families\">\{navigation}</nav><div class=\"gallery-main\"><div class=\"gallery-tools\"></div><div class=\"gallery-groups\">\{groups}</div></div></div></div>",
    },
  ]
  let copies : Array[ArtifactCopy] = []
  let seen : Map[String, Bool] = Map([])
  for entry in manifest.entries {
    pages.push({
      route: "/gallery/\{entry.id}/",
      title: entry.title,
      body_html: detail_body(
        entry,
        base_path,
        family_ids[entry.family],
        source_text,
      ),
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
