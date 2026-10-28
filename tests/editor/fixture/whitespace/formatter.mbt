///|
/// Consumer-owned Formatter. This package imports no tutorial types.
pub(all) struct WhitespaceFormatter {}

///|
pub impl @editor.Formatter for WhitespaceFormatter with fn format(_, input) {
  let lines = input.target.text
    .split("\n")
    .map(line => line.trim_end().to_owned())
    .to_array()
  Ok({ text: lines.join("\n"), })
}

///|
pub extend WhitespaceFormatter with @editor.Formatter::{format}
