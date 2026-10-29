///|
fn rebasable(path : String) -> Bool {
  !path.has_prefix("gallery/artifacts/") &&
  [".html", ".xml", ".json", ".css"].iter().any(ext => path.has_suffix(ext))
}

///|
/// Rebase URL-bearing attributes and CSS without rewriting HTML closing tags at base `/`.
fn rebase_tree(text : String, from : String, to : String) -> String {
  let mut result = text
  for key in ["href", "src", "poster", "data-base"] {
    for quote in ["\"", "'"] {
      result = result.replace_all(
        old=key + "=" + quote + from,
        new=key + "=" + quote + to,
      )
    }
  }
  for value in attributes(result, "srcset") {
    let rebased = value
      .split(",")
      .map(candidate => {
        let candidate = candidate.trim().to_owned()
        let mut end = 0
        while end < candidate.length() &&
              ![9, 10, 12, 13, 32].contains(
                candidate.code_unit_at(end).to_int(),
              ) {
          end += 1
        }
        let url = candidate[:end].to_owned()
        (if url.has_prefix(from) {
          to + url[from.length():].to_owned()
        } else {
          url
        }) +
        candidate[end:].to_owned()
      })
      .collect()
      .join(", ")
    for quote in ["\"", "'"] {
      result = result.replace_all(
        old="srcset=" + quote + value + quote,
        new="srcset=" + quote + rebased + quote,
      )
    }
  }
  for start in ["url(", "url(\"", "url('", "@import \"", "@import '"] {
    result = result.replace_all(old=start + from, new=start + to)
  }
  result
}

///|
pub async fn assemble(manifest_path : String, out : String) -> Unit {
  let manifest = @json.parse(@fs.read_file(manifest_path).text())
  guard manifest is Object(fields) &&
    fields.get("schema_version") is Some(Number(1, ..)) &&
    fields.get("trees") is Some(Array(trees)) else {
    raise @model.Invalid([
      @model.problem(manifest_path, "expected schema_version 1 and trees array"),
    ])
  }
  let base = string_field(manifest, "base_path", "/")
  guard base.has_prefix("/") && base.has_suffix("/") && !base.contains("..") else {
    raise @model.Invalid([@model.problem(manifest_path, "invalid base_path")])
  }
  let root = canonical_path(parent(manifest_path))
  let out = destination(out)
  let latest = string_field(manifest, "latest", "")
  let planned : Map[String, (String, String)] = Map([])
  for tree in trees {
    let id = string_field(tree, "id", "")
    guard id == "next" || @model.is_minor_line(id) else {
      raise @model.Invalid([
        @model.problem(manifest_path, "tree id must be next or a minor version"),
      ])
    }
    guard !planned.contains(id) else {
      raise @model.Invalid([
        @model.problem(manifest_path, "duplicate tree \{id}"),
      ])
    }
    let rel = string_field(tree, "path", "")
    guard relative(rel) else {
      raise @model.Invalid([@model.problem(rel, "invalid supplied tree path")])
    }
    let from = canonical_path(root + "/" + rel)
    guard within(root, from) && !within(from, out) && !within(out, from) else {
      raise @model.Invalid([
        @model.problem(rel, "tree escapes input root or overlaps output"),
      ])
    }
    let from_base = string_field(tree, "base_path", base + @model.tree_path(id))
    for path in files(from) {
      if ["next", "v", "latest"].contains(
          path.split("/").next().unwrap_or("").to_owned(),
        ) {
        raise @model.Invalid([
          @model.problem(path, "reserved version prefix in supplied tree"),
        ])
      }
    }
    let problems = check(from, from_base)
    guard problems.is_empty() else { raise @model.Invalid(problems) }
    planned[id] = (from, from_base)
  }
  guard planned.contains("next") && (latest == "" || planned.contains(latest)) else {
    raise @model.Invalid([
      @model.problem(
        manifest_path, "requires next and the supplied latest tree",
      ),
    ])
  }
  let stage = stage_for(out)
  defer (if @fs.exists(stage) { @fs.rmdir(stage, recursive=true) })
  let lines = trees
    .map(tree => string_field(tree, "id", ""))
    .filter(id => id != "next")
  let site_url = string_field(manifest, "site_url", "")
  for id, (from, from_base) in planned {
    let destinations = [@model.tree_path(id)]
    if id == (if latest == "" { "next" } else { latest }) {
      destinations.push("")
    }
    if id == latest {
      destinations.push("latest/")
    }
    for tree_path in destinations {
      let to_base = base + tree_path
      for path in files(from) {
        let data = @fs.read_file(checked_file(from, path))
        if rebasable(path) {
          let mut text = if path == "search-index.json" {
            data.text()
          } else {
            rebase_tree(data.text(), from_base, to_base)
          }
          if site_url != "" && path != "search-index.json" {
            let from_url = site_url + @model.tree_path(id)
            text = text.replace_all(old=from_url, new=site_url + tree_path)
          }
          if path.has_suffix(".html") {
            if latest != "" &&
              site_url != "" &&
              @fs.exists(planned[latest].0 + "/" + path) &&
              !attributes(text, "rel").contains("canonical") {
              let route = if path == "index.html" ||
                path.has_suffix("/index.html") {
                path[:path.length() - "index.html".length()].to_owned()
              } else {
                path
              }
              let canonical = @content.escape(site_url + "latest/" + route)
              text = text.replace(
                old="</head>",
                new="<link rel=\"canonical\" href=\"" + canonical + "\"></head>",
              )
            }
            let banner = if latest == "" {
              "Pre-release docs. No version is released yet."
            } else if id == "next" {
              "Unreleased docs."
            } else if id != latest {
              let route = if path == "index.html" {
                ""
              } else if path.has_suffix("/index.html") {
                path[:path.length() - "index.html".length()].to_owned()
              } else {
                path
              }
              let latest_dir = planned[latest].0
              let target = @model.switch_url(
                to_base + route,
                to_base,
                base + "latest/",
                @fs.exists(latest_dir + "/" + path),
              )
              "Older documentation. Latest version: " +
              latest +
              " <a href=\"" +
              target +
              "\">Open latest docs</a>"
            } else {
              ""
            }
            text = text.replace(
              old=@model.banner_start + "</div>",
              new=@model.banner_start + "<p>" + banner + "</p></div>",
            )
          }
          write(stage + "/" + tree_path + path, text)
        } else {
          write(stage + "/" + tree_path + path, data.binary())
        }
      }
    }
  }
  let versions : @model.VersionsFile = {
    latest: if latest == "" {
      None
    } else {
      Some(latest)
    },
    next: true,
    versions: lines,
  }
  write(stage + "/versions.json", versions.to_text())
  let problems = check(stage, base)
  guard problems.is_empty() else { raise @model.Invalid(problems) }
  promote(stage, out)
}
