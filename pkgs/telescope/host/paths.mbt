// Adapted from diagrams.mbt apps/site/generate and scripts/serve-site.mbtx.
// Apache-2.0; see NOTICE for source revisions.

///|
pub let version : String = "0.2.1"

///|
pub fn relative(path : String) -> Bool {
  path != "" &&
  !path.has_prefix("/") &&
  !path.contains("\\") &&
  !path.contains(":") &&
  !path.contains("\u{0}") &&
  !path.split("/").any(p => p == ".." || p == "." || p == "")
}

///|
fn within(root : String, path : String) -> Bool {
  path == root || path.has_prefix(root + "/")
}

///|
pub fn parent(path : String) -> String {
  match path.rev_find("/") {
    Some(0) => "/"
    Some(i) => path[:i].to_owned()
    None => "."
  }
}

///|
async fn checked_file(root : String, rel : String) -> String {
  guard relative(rel) else {
    raise @model.Invalid([@model.problem(rel, "invalid relative input path")])
  }
  let path = "\{root}/\{rel}"
  let real = @fs.realpath(path)
  guard within(root, real) && @fs.kind(real) is Regular else {
    raise @model.Invalid([
      @model.problem(
        rel, "input is not a regular file inside its declared root",
      ),
    ])
  }
  real
}

///|
async fn files(
  root : String,
  prefix~ : String = "",
  excluded~ : Array[String] = [],
) -> Array[String] {
  let out = []
  let dir = if prefix == "" { root } else { "\{root}/\{prefix}" }
  for name in @fs.readdir(dir, sort=true, include_hidden=true) {
    let rel = if prefix == "" { name } else { "\{prefix}/\{name}" }
    if excluded.contains(rel) ||
      [
        ".git", ".mooncakes", "node_modules", "_build", "_site", ".agents", "openspec",
      ].contains(name) ||
      rel == "docs/templates" ||
      rel == "docs/superpowers" {
      continue
    }
    match @fs.kind("\{root}/\{rel}", follow_symlink=false) {
      Directory => out.append(files(root, prefix=rel, excluded~))
      Regular => out.push(rel)
      SymLink => {
        let real = @fs.realpath("\{root}/\{rel}")
        guard within(root, real) && @fs.kind(real) is Regular else {
          raise @model.Invalid([
            @model.problem(
              rel, "symlink escapes input root or does not name a regular file",
            ),
          ])
        }
        out.push(rel)
      }
      _ =>
        raise @model.Invalid([
          @model.problem(rel, "unsupported input file kind"),
        ])
    }
  }
  out
}

///|
async fn write(path : String, data : &@io.Data) -> Unit {
  @fs.mkdir(parent(path), recursive=true, allow_exist=true)
  @fs.write_file(path, data, create_mode=CreateOrTruncate)
}

///|
fn hex_value(c : Int32) -> Int32? {
  if c >= '0' && c <= '9' {
    Some(c - '0')
  } else if c >= 'a' && c <= 'f' {
    Some(c - 'a' + 10)
  } else if c >= 'A' && c <= 'F' {
    Some(c - 'A' + 10)
  } else {
    None
  }
}

///|
/// Decode paths as UTF-8, rejecting malformed escapes and invalid byte sequences.
fn decode_url(text : String) -> String? {
  let bytes = @utf8.encode(text)
  let out = []
  let mut i = 0
  while i < bytes.length() {
    if bytes[i] == b'%' {
      guard i + 2 < bytes.length() &&
        hex_value(bytes[i + 1].to_int()) is Some(hi) &&
        hex_value(bytes[i + 2].to_int()) is Some(lo) else {
        return None
      }
      out.push((hi * 16 + lo).to_byte())
      i += 3
    } else {
      out.push(bytes[i])
      i += 1
    }
  }
  try @utf8.decode(Bytes::from_array(out)) catch {
    _ => None
  } noraise {
    text => Some(text)
  }
}

///|
/// Resolve existing ancestors before allowing host-generated metadata directories.
async fn bounded_path(root : String, rel : String) -> String {
  guard relative(rel) else {
    raise @model.Invalid([@model.problem(rel, "invalid relative host path")])
  }
  let mut path = root
  for part in rel.split("/") {
    path = path + "/" + part.to_owned()
    let kind = Some(@fs.kind(path, follow_symlink=false)) catch { _ => None }
    if kind is Some(_) {
      path = @fs.realpath(path)
      guard within(root, path) else {
        raise @model.Invalid([
          @model.problem(rel, "host metadata path escapes project root"),
        ])
      }
    }
  }
  path
}
