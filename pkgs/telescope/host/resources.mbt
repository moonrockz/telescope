///|
/// Links from reviewed HTML/SVG and CSS. CSS URLs may occur in style attributes.
fn resource_links(text : String) -> Array[String] {
  let extra = []
  for value in attributes(text, "srcset") {
    for item in value.split(",") {
      extra.push(item.trim().split(" ").next().unwrap_or("").to_owned())
    }
  }
  let links = attributes(text, "href") +
    attributes(text, "src") +
    attributes(text, "poster")
  let mut offset = 0
  while offset < text.length() {
    guard text[offset:].find("url(") is Some(start) else { break }
    let begin = offset + start + 4
    guard text[begin:].find(")") is Some(end) else { break }
    let raw = text[begin:begin + end].trim().to_owned()
    let url = if raw.length() >= 2 &&
      (
        (raw.has_prefix("\"") && raw.has_suffix("\"")) ||
        (raw.has_prefix("'") && raw.has_suffix("'"))
      ) {
      raw[1:raw.length() - 1].to_owned()
    } else {
      raw
    }
    links.push(url)
    offset = begin + end + 1
  }
  for quote in ["\"", "'"] {
    let marker = "@import " + quote
    let mut offset = 0
    while offset < text.length() {
      guard text[offset:].find(marker) is Some(start) else { break }
      let begin = offset + start + marker.length()
      guard text[begin:].find(quote) is Some(end) else { break }
      links.push(text[begin:begin + end].to_owned())
      offset = begin + end + 1
    }
  }
  links + extra
}
