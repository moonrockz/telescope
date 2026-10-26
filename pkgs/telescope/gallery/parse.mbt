///|
fn issue(source : String, field : String, message : String) -> @model.Problem {
  @model.problem(source, "gallery \{field}: \{message}")
}

///|
fn required_text(
  fields : Map[String, Json],
  key : String,
  source : String,
  at : String,
  problems : Array[@model.Problem],
) -> String {
  match fields.get(key) {
    Some(String(value)) if value.trim() != "" => value
    _ => {
      problems.push(issue(source, "\{at}.\{key}", "requires a nonempty string"))
      ""
    }
  }
}

///|
fn optional_text(
  fields : Map[String, Json],
  key : String,
  source : String,
  at : String,
  problems : Array[@model.Problem],
) -> String? {
  match fields.get(key) {
    None => None
    Some(String(value)) => Some(value)
    _ => {
      problems.push(
        issue(source, "\{at}.\{key}", "must be a string when supplied"),
      )
      None
    }
  }
}

///|
fn file_ref(
  value : Json,
  source : String,
  at : String,
  problems : Array[@model.Problem],
) -> FileRef? {
  guard value is Object(fields) else {
    problems.push(issue(source, at, "must be a path/media_type object"))
    return None
  }
  Some({
    path: required_text(fields, "path", source, at, problems),
    media_type: required_text(fields, "media_type", source, at, problems),
  })
}

///|
fn optional_file(
  fields : Map[String, Json],
  key : String,
  source : String,
  at : String,
  problems : Array[@model.Problem],
) -> FileRef? {
  match fields.get(key) {
    None => None
    Some(value) => file_ref(value, source, "\{at}.\{key}", problems)
  }
}

///|
fn file_list(
  fields : Map[String, Json],
  key : String,
  source : String,
  at : String,
  problems : Array[@model.Problem],
) -> Array[FileRef] {
  match fields.get(key) {
    None => []
    Some(Array(items)) => {
      let files = []
      for i, item in items {
        if file_ref(item, source, "\{at}.\{key}[\{i}]", problems) is Some(file) {
          files.push(file)
        }
      }
      files
    }
    _ => {
      problems.push(issue(source, "\{at}.\{key}", "must be an array"))
      []
    }
  }
}

///|
/// Parse the version 1 data contract. Filesystem existence belongs to the host.
pub fn parse_manifest(
  text : String,
  source~ : String = "gallery.json",
) -> Result[Manifest, Array[@model.Problem]] {
  let value = @json.parse(text) catch {
    error => return Err([issue(source, "manifest", "invalid JSON: \{error}")])
  }
  guard value is Object(fields) else {
    return Err([issue(source, "manifest", "must be an object")])
  }
  let problems = []
  let schema_version = match fields.get("schema_version") {
    Some(Number(n, ..)) if n == 1.0 => 1
    _ => {
      problems.push(issue(source, "schema_version", "supported version is 1"))
      0
    }
  }
  let producer = match fields.get("producer") {
    None => None
    Some(Object(p)) =>
      Some({
        project: required_text(p, "project", source, "producer", problems),
        source_ref: required_text(p, "ref", source, "producer", problems),
        pipeline: required_text(p, "pipeline", source, "producer", problems),
      })
    _ => {
      problems.push(
        issue(source, "producer", "requires project, ref and pipeline"),
      )
      None
    }
  }
  let root = optional_text(fields, "root", source, "manifest", problems)
  let entries = []
  match fields.get("entries") {
    Some(Array(items)) =>
      for i, item in items {
        let at = "entries[\{i}]"
        guard item is Object(e) else {
          problems.push(issue(source, at, "must be an object"))
          continue
        }
        let status = match e.get("status") {
          Some(String("implemented")) => Implemented
          Some(String("planned")) => Planned
          _ => {
            problems.push(
              issue(source, "\{at}.status", "must be implemented or planned"),
            )
            Planned
          }
        }
        entries.push({
          id: required_text(e, "id", source, at, problems),
          family: required_text(e, "family", source, at, problems),
          title: required_text(e, "title", source, at, problems),
          status,
          description: optional_text(e, "description", source, at, problems),
          scope: optional_text(e, "scope", source, at, problems),
          sources: file_list(e, "sources", source, at, problems),
          preview: optional_file(e, "preview", source, at, problems),
          preview_dark: optional_file(e, "preview_dark", source, at, problems),
          player: optional_file(e, "player", source, at, problems),
          companions: file_list(e, "companions", source, at, problems),
        })
      }
    _ => problems.push(issue(source, "entries", "must be an array"))
  }
  let manifest = { schema_version, producer, root, entries, }
  problems.append(validate(manifest, source~))
  if problems.is_empty() {
    Ok(manifest)
  } else {
    Err(problems)
  }
}
