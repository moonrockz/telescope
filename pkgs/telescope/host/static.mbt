///|
/// Explicit directory mappings preserve consumer-owned stable resource URLs.
async fn static_outputs(
  root : String,
  config : @model.SiteConfig,
  value : Json,
  out : String,
) -> Array[@site.Output] {
  let mappings = match value {
    Object(fields) =>
      match fields.get("static") {
        None => return []
        Some(Array(mappings)) => mappings
        _ =>
          raise @model.Invalid([
            @model.problem("static", "expected an array of directory mappings"),
          ])
      }
    _ => return []
  }
  let outputs : Array[@site.Output] = []
  for mapping in mappings {
    let from = string_field(mapping, "from", "")
    let to = string_field(mapping, "to", "")
    guard relative(from) && relative(to) else {
      raise @model.Invalid([
        @model.problem(
          "static", "from and to must be normalized relative directories",
        ),
      ])
    }
    let source = @fs.realpath(root + "/" + from)
    guard within(root, source) &&
      @fs.kind(source) is Directory &&
      !within(source, out) &&
      !within(out, source) else {
      raise @model.Invalid([
        @model.problem(from, "static root escapes project or overlaps output"),
      ])
    }
    let selected = { ..config, source_roots: [from], }
    for file in files(source) {
      let path = from + "/" + file
      if selected.includes(path) {
        ignore(checked_file(source, file))
        outputs.push(Copy(to + "/" + file, path))
      }
    }
  }
  outputs
}
