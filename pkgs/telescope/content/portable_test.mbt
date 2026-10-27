///|
test "explicit IDs and heading attributes contribute portable facts" {
  let doc = @content.analyse_html(
    "<h1 class='title' id='intro'>Introduction</h1><h2 class=\"x\">Setup</h2><h2>Setup</h2>",
  )
  assert_eq(doc.title, Some("Introduction"))
  assert_eq(doc.ids, ["intro", "setup", "setup-2"])
  assert_eq(doc.headings.map(h => h.id), ["intro", "setup", "setup-2"])
  assert_true(doc.html.contains("<h1 class='title' id='intro'>"))
  assert_true(doc.html.contains("<h2 class=\"x\" id=\"setup\">"))
}
