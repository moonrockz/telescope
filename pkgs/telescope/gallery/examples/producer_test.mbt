///|
test "consumer-owned typed producer plans supplied fixture and planned entry" {
  let plan = @gallery.plan(@examples.manifest("fixture-ref"), "/demo/").unwrap()
  assert_eq(plan.pages.length(), 3)
  assert_eq(plan.copies.length(), 4)
  assert_true(
    plan.pages[1].body_html.contains(
      "/demo/gallery/artifacts/player/index.html",
    ),
  )
  assert_true(plan.pages[2].body_html.contains("Planned"))
  assert_false(plan.pages[2].body_html.contains("<img"))
}
