///|
/// Deliberately portable URL-safe paths. Reject non-normalized inputs rather than rewriting them.
pub fn valid_relative_path(path : String) -> Bool {
  if path == "" {
    return false
  }
  for part in path.split("/") {
    if part == "" || part == "." || part == ".." {
      return false
    }
    for c in part {
      if !((c >= 'a' && c <= 'z') ||
        (c >= 'A' && c <= 'Z') ||
        (c >= '0' && c <= '9') ||
        c == '-' ||
        c == '_' ||
        c == '.' ||
        c == '~') {
        return false
      }
    }
  }
  true
}

///|
fn valid_id(id : String) -> Bool {
  if id == "" || id == "artifacts" {
    return false
  }
  for c in id {
    if !((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '-') {
      return false
    }
  }
  id[0] != '-' && !id.has_suffix("-")
}

///|
pub fn Entry::artifacts(self : Entry) -> Array[FileRef] {
  let files = self.sources.copy()
  if self.preview is Some(file) {
    files.push(file)
  }
  if self.preview_dark is Some(file) {
    files.push(file)
  }
  if self.player is Some(file) {
    files.push(file)
  }
  files.append(self.companions)
  files
}

///|
/// Revalidate public records as well as parsed JSON before any output is planned.
pub fn validate(
  manifest : Manifest,
  source~ : String = "gallery.json",
) -> Array[@model.Problem] {
  let problems = []
  if manifest.schema_version != 1 {
    problems.push(issue(source, "schema_version", "supported version is 1"))
  }
  if manifest.producer is Some(producer) &&
    (
      producer.project.trim() == "" ||
      producer.source_ref.trim() == "" ||
      producer.pipeline.trim() == ""
    ) {
    problems.push(
      issue(source, "producer", "requires nonempty project, ref and pipeline"),
    )
  }
  if manifest.root is Some(root) && !valid_relative_path(root) {
    problems.push(issue(source, "root", "must be a normalized relative path"))
  }
  let ids : Map[String, Bool] = Map([])
  let paths : Map[String, String] = Map([])
  for entry in manifest.entries {
    let at = "entry \{entry.id}"
    if !valid_id(entry.id) {
      problems.push(
        issue(
          source, at, "id must use lowercase letters, digits and internal hyphens; artifacts is reserved",
        ),
      )
    }
    if ids.contains(entry.id) {
      problems.push(
        issue(source, at, "duplicate id and output route /gallery/\{entry.id}/"),
      )
    }
    ids[entry.id] = true
    if entry.title.trim() == "" || entry.family.trim() == "" {
      problems.push(issue(source, at, "requires nonempty title and family"))
    }
    match entry.status {
      Implemented => {
        if entry.sources.is_empty() {
          problems.push(issue(source, at, "implemented entry requires sources"))
        }
        if entry.preview is None {
          problems.push(
            issue(source, at, "implemented entry requires SVG preview"),
          )
        }
      }
      Planned =>
        if !entry.artifacts().is_empty() {
          problems.push(
            issue(
              source, at, "planned entry must not declare runnable artifacts",
            ),
          )
        }
    }
    for preview in [entry.preview, entry.preview_dark] {
      if preview is Some(file) && file.media_type != "image/svg+xml" {
        problems.push(
          issue(
            source,
            at,
            "preview \{file.path} must have media_type image/svg+xml",
          ),
        )
      }
    }
    if entry.player is Some(file) && file.media_type != "text/html" {
      problems.push(
        issue(source, at, "player \{file.path} must have media_type text/html"),
      )
    }
    for file in entry.artifacts() {
      if !valid_relative_path(file.path) {
        problems.push(
          issue(
            source,
            at,
            "artifact path \{file.path} must be normalized and relative without traversal or URL metacharacters",
          ),
        )
      }
      if !file.media_type.contains("/") ||
        file.media_type.contains("\n") ||
        file.media_type.contains("\r") {
        problems.push(
          issue(source, at, "artifact \{file.path} requires a valid media_type"),
        )
      }
      match paths.get(file.path) {
        Some(media) if media != file.media_type =>
          problems.push(
            issue(source, at, "conflicting media types for output \{file.path}"),
          )
        _ => ()
      }
      for previous, _ in paths {
        if file.path.has_prefix(previous + "/") ||
          previous.has_prefix(file.path + "/") {
          problems.push(
            issue(
              source,
              at,
              "artifact output collision: \{file.path} and \{previous}",
            ),
          )
        }
      }
      paths[file.path] = file.media_type
    }
  }
  problems
}
