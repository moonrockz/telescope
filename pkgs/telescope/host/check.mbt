///|
fn attributes(html : String, name : String) -> Array[String] {
  let found = []
  for quote in ["\"", "'"] {
    let marker = name + "=" + quote
    let mut offset = 0
    while offset < html.length() {
      let rest = html[offset:]
      guard rest.find(marker) is Some(start) else { break }
      let begin = offset + start + marker.length()
      guard html[begin:].find(quote) is Some(end) else { break }
      found.push(html[begin:begin + end].to_owned())
      offset = begin + end + 1
    }
  }
  found
}

///|
fn resolve(
  base : String,
  origin : String,
  link : String,
) -> Result[(String, String), String] {
  let raw = link.replace_all(old="&amp;", new="&")
  let (url, fragment) = match raw.find("#") {
    Some(i) => (raw[:i].to_owned(), raw[i + 1:].to_owned())
    None => (raw, "")
  }
  let url = match url.find("?") {
    Some(i) => url[:i].to_owned()
    None => url
  }
  guard decode_url(url) is Some(url) && decode_url(fragment) is Some(fragment) else {
    return Err("invalid URL encoding")
  }
  let path = if url == "" {
    origin
  } else if url.has_prefix("/") {
    guard url.has_prefix(base) else {
      return Err("leaves deployment base \{base}")
    }
    url[base.length():].to_owned()
  } else {
    parent(origin) + "/" + url
  }
  let parts : Array[String] = []
  for part in path.split("/") {
    if part == "" || part == "." {
      continue
    }
    if part == ".." {
      if parts.is_empty() {
        return Err("leaves output tree")
      }
      ignore(parts.pop())
    } else {
      if part.contains("\\") || part.contains("\u{0}") {
        return Err("unsafe resource path")
      }
      parts.push(part.to_owned())
    }
  }
  let normalized = parts.join("/")
  let file = if normalized == "" {
    "index.html"
  } else if url.has_suffix("/") {
    normalized + "/index.html"
  } else {
    normalized
  }
  Ok((file, fragment))
}

///|
pub async fn check(out : String, base : String) -> Array[@model.Problem] {
  if @fs.exists(out + "/versions.json") {
    let versions = @model.VersionsFile::parse(
      "versions.json",
      @fs.read_file(out + "/versions.json").text(),
    )
    let problems = []
    for (path, tree_base) in versions.trees(base) {
      let tree = if path == "" {
        out
      } else {
        out + "/" + path[:path.length() - 1].to_owned()
      }
      let skip = if path == "" { ["next/", "latest/", "v/"] } else { [] }
      problems.append(check_tree(tree, tree_base, skip~, assembled=true))
    }
    return problems
  }
  check_tree(out, base)
}

///|
fn existing_target(known : Map[String, Bool], target : String) -> String {
  if known.contains(target) {
    target
  } else if known.contains(target + "/index.html") {
    target + "/index.html"
  } else {
    target
  }
}

///|
/// Separate generated download anchors from loaded/navigated resource links.
/// Gallery planning escapes attribute delimiters and emits `download` last.
fn gallery_download_links(text : String) -> (Array[String], String) {
  let downloads = []
  let active = StringBuilder()
  let mut offset = 0
  while offset < text.length() {
    guard text[offset:].find("<a ") is Some(start) else { break }
    let begin = offset + start
    guard text[begin:].find(">") is Some(end) else { break }
    let finish = begin + end
    let tag = text[begin:finish].to_owned()
    active.write_string(text[offset:begin].to_owned())
    if tag.has_suffix(" download") {
      downloads.append(attributes(tag, "href"))
    } else {
      active.write_string(text[begin:finish + 1].to_owned())
    }
    offset = finish + 1
  }
  active.write_string(text[offset:].to_owned())
  (downloads, active.to_string())
}

///|
async fn check_tree(
  out : String,
  base : String,
  skip~ : Array[String] = [],
  assembled~ : Bool = false,
) -> Array[@model.Problem] {
  let root = @fs.realpath(out)
  let problems = []
  let all = files(root).filter(file => {
    !skip.iter().any(prefix => file.has_prefix(prefix))
  })
  let known : Map[String, Bool] = Map([])
  let ids : Map[String, Array[String]] = Map([])
  for file in all {
    known[file] = true
  }
  if !known.contains("index.html") {
    problems.push(@model.problem(out, "missing index.html"))
  }
  let documents : Map[String, String] = Map([])
  let active_text : Map[String, String] = Map([])
  let downloads : Map[String, Bool] = Map([])
  let checkable : Array[String] = []
  for file in all {
    if ![".html", ".xml", ".svg", ".css"].any(ext => file.has_suffix(ext)) {
      continue
    }
    checkable.push(file)
    let data = @fs.read_file(checked_file(root, file))
    let text = try @utf8.decode(data.binary()) catch {
      _ => None
    } noraise {
      text => Some(text)
    }
    if text is Some(text) && !text.contains("\u{0}") {
      documents[file] = text
      let (links, active) = gallery_download_links(text)
      active_text[file] = active
      // Only generated gallery detail downloads qualify for opaque treatment.
      if file.has_prefix("gallery/") &&
        !file.has_prefix("gallery/artifacts/") &&
        text.contains("data-gallery-detail") {
        for link in links {
          if resolve(base, file, link) is Ok((target, _)) &&
            target.has_prefix("gallery/artifacts/") {
            downloads[target] = true
          }
        }
      }
    }
  }
  // A download used by a player, preview or any ordinary resource is active.
  // Walk from non-download documents so literal source files do not create
  // dependencies merely because they contain markup or CSS examples.
  let active : Map[String, Bool] = Map([])
  let pending = checkable.filter(file => !downloads.contains(file))
  let mut next = 0
  while next < pending.length() {
    let file = pending[next]
    next += 1
    for link in resource_links(active_text.get(file).unwrap_or("")) {
      if link == "" || link.contains(":") || link.has_prefix("//") {
        continue
      }
      if resolve(base, file, link) is Ok((target, _)) {
        let target = existing_target(known, target)
        if downloads.contains(target) && !active.contains(target) {
          active[target] = true
          pending.push(target)
        }
      }
    }
  }
  for file in checkable {
    if downloads.contains(file) && !active.contains(file) {
      continue
    }
    if documents.get(file) is Some(text) &&
      (file.has_suffix(".html") || file.has_suffix(".svg")) {
      ids[file] = @content.ids_in(text)
    }
  }
  for file in checkable {
    if downloads.contains(file) && !active.contains(file) {
      continue
    }
    guard documents.get(file) is Some(text) else {
      problems.push(@model.problem(file, "resource is not valid UTF-8 text"))
      continue
    }
    if file.has_suffix(".html") && !@model.has_title(text) {
      problems.push(@model.problem(file, "missing nonempty title"))
    }
    if file.has_suffix(".xml") {
      if @model.xml_problem(text) is Some(message) {
        problems.push(@model.problem(file, "malformed feed: \{message}"))
      }
    }
    let links = resource_links(
      if assembled {
        @model.without_banner(text)
      } else {
        text
      },
    )
    for link in links {
      if link == "" || link.contains(":") || link.has_prefix("//") {
        continue
      }
      match resolve(base, file, link) {
        Err(message) =>
          problems.push(@model.problem(file, "\{link}: \{message}"))
        Ok((target, fragment)) => {
          let target = existing_target(known, target)
          if !known.contains(target) {
            problems.push(
              @model.problem(file, "broken resource \{link} -> \{target}"),
            )
          } else if fragment != "" &&
            ids.get(target) is Some(anchors) &&
            !anchors.contains(fragment) {
            problems.push(@model.problem(file, "missing fragment \{link}"))
          }
        }
      }
    }
  }
  problems
}

///|
pub fn diagnostics(problems : Array[@model.Problem], format : String) -> String {
  if format == "json" {
    let data : Array[Json] = problems.map(p => {
      "source": p.file,
      "line": p.line,
      "message": p.message,
    })
    Json::array(data).stringify()
  } else {
    problems.map(p => p.render()).join("\n")
  }
}
