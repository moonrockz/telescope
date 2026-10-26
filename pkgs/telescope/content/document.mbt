///|
pub(all) struct Heading {
  level : Int32
  id : String
  text : String
} derive(Eq, Debug)

///|
pub extend Heading with Eq::{equal, not_equal}

///|
pub extend Heading with @debug.Debug::{to_repr}

///|
/// An HTML body with the facts the site needs from it.
pub(all) struct Document {
  html : String
  title : String?
  summary : String
  headings : Array[Heading]
  ids : Array[String]
  text : String
}

///|
/// Add missing IDs to headings, preserve explicit IDs and attributes, then
/// collect the title (first `h1`), summary (first paragraph), headings, ids and text.
pub fn analyse_html(source : String) -> Document {
  let out = StringBuilder()
  let headings : Array[Heading] = []
  let used : Map[String, Bool] = Map([])
  for existing in ids_in(source) {
    used.set(existing, true)
  }
  let mut rest = source[:]
  while rest.find("<h") is Some(start) {
    let after = rest[start:]
    let level = if after.length() >= 4 &&
      (
        after[3] == '>' ||
        after[3] == ' ' ||
        after[3] == '\t' ||
        after[3] == '\n'
      ) &&
      after[2] >= '1' &&
      after[2] <= '6' {
      after[2].to_int() - '0'.to_int()
    } else {
      0
    }
    if level == 0 {
      out.write_view(rest[:start + 2])
      rest = rest[start + 2:]
      continue
    }
    let close = "</h\{level}>"
    guard after.find(close) is Some(end) else { break }
    guard after.find(">") is Some(tag_end) && tag_end < end else { break }
    let tag = after[:tag_end].to_owned()
    let inner = after[tag_end + 1:end].to_owned()
    let text = inline_text(inner)
    let explicit = heading_id(tag)
    let id = explicit.unwrap_or_else(() => unique_id(slug(text), used))
    used.set(id, true)
    headings.push({ level, id, text, })
    out.write_view(rest[:start])
    if explicit is Some(_) {
      out.write_string("\{tag}>\{inner}\{close}")
    } else {
      out.write_string("\{tag} id=\"\{id}\">\{inner}\{close}")
    }
    rest = after[end + close.length():]
  }
  out.write_view(rest)
  let html = out.to_string()
  let title = headings.search_by(h => h.level == 1).map(i => headings[i].text)
  let summary = match html.find("<p>") {
    Some(start) =>
      match html[start:].find("</p>") {
        Some(end) => plain_text(html[start + 3:start + end].to_owned())
        None => ""
      }
    None => ""
  }
  { html, title, summary, headings, ids: ids_in(html), text: plain_text(html), }
}

///|
/// `base` if no id uses it yet, otherwise the first `base-n` (n >= 2) that is free.
fn unique_id(base : String, used : Map[String, Bool]) -> String {
  if !used.contains(base) {
    return base
  }
  let mut n = 2
  while used.contains("\{base}-\{n}") {
    n += 1
  }
  "\{base}-\{n}"
}

///|
fn heading_id(tag : String) -> String? {
  for quote in ["\"", "'"] {
    let marker = " id=" + quote
    if tag.find(marker) is Some(start) {
      let value = tag[start + marker.length():]
      if value.find(quote) is Some(end) {
        return Some(unescape(value[:end].to_owned()))
      }
    }
  }
  None
}

///|
/// Every quoted ID attribute in document order.
pub fn ids_in(html : String) -> Array[String] {
  let ids = []
  let mut rest = html[:]
  while rest.find("<") is Some(start) {
    let tag = rest[start:]
    guard tag.find(">") is Some(end) else { break }
    if heading_id(tag[:end].to_owned()) is Some(id) {
      ids.push(id)
    }
    rest = tag[end + 1:]
  }
  ids
}
