///|
test "standalone Formatter compiles and runs without tutorial configuration" {
  let formatter = @whitespace.WhitespaceFormatter::{ }
  let target : @editor.Document = {
    id: "standalone",
    name: "notes.txt",
    language: "text",
    text: "first  \nsecond\t",
  }
  let result = @editor.Formatter::format(formatter, {
    target,
    context: [],
    options: {},
  })
  assert_eq(result, Ok({ text: "first\nsecond", }))
}
