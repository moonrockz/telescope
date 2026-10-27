///|
/// Run explicitly registered providers over CommonMark's escaped fence HTML.
fn render_fences(
  file : String,
  route : String,
  config : @model.SiteConfig,
  providers : @extensions.Registry,
  html : String,
  problems : Array[@model.Problem],
  assets : Array[(String, String)],
) -> String {
  let out = StringBuilder()
  let occurrences : Map[String, Int32] = Map([])
  let mut rest = html[:]
  let marker = "<pre><code class=\"language-"
  while rest.find(marker) is Some(start) {
    let label = rest[start + marker.length():]
    guard label.find("\">") is Some(label_end) else { break }
    let body = label[label_end + 2:]
    guard body.find("</code></pre>") is Some(end) else { break }
    let language = label[:label_end].to_owned()
    out.write_view(rest[:start])
    if providers.fences
      .iter()
      .find_first(adapter => adapter.labels.contains(language))
      is Some(adapter) {
      let ordinal = occurrences.get(adapter.id).unwrap_or(0) + 1
      occurrences[adapter.id] = ordinal
      match
        @extensions.render_fence(providers, {
          source: file,
          route,
          base_path: config.base_path,
          body: @content.unescape(body[:end].to_owned()),
          language,
          ordinal,
        }) {
        Err(found) => problems.append(found)
        Ok(rendered) => {
          problems.append(rendered.problems)
          for asset in rendered.assets {
            assets.push((asset.path, asset.path))
          }
          out.write_string(rendered.body_html)
        }
      }
    } else {
      out.write_string(marker)
      out.write_view(label[:label_end + 2 + end + "</code></pre>".length()])
    }
    rest = body[end + "</code></pre>".length():]
  }
  out.write_view(rest)
  out.to_string()
}

///|
/// Route-local mounts retain their reviewed static fallback without JavaScript.
fn add_islands(
  config : @model.SiteConfig,
  providers : @extensions.Registry,
  route : String,
  html : String,
) -> String {
  let head = StringBuilder()
  let body = StringBuilder()
  for island in @extensions.islands_for_route(providers, route) {
    if island.stylesheet is Some(asset) {
      head.write_string(
        "<link rel=\"stylesheet\" href=\"\{@content.escape(config.href("/" + asset.path))}\">",
      )
    }
    body.write_string(
      "<div id=\"\{island.mount_id}\">\{island.fallback_html}</div><script type=\"module\" src=\"\{@content.escape(config.href("/" + island.script.path))}\"></script>",
    )
  }
  html
  .replace(old="</head>", new=head.to_string() + "</head>")
  .replace(old="</body>", new=body.to_string() + "</body>")
}
