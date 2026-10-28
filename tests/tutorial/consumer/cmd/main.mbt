// Original independent packaged-consumer driver, Apache-2.0.

///|
async fn main {
  let args = @env.args()[1:].to_owned()
  guard args.length() == 4 else { abort("usage: consumer CONFIG BASE OUT ENGINE") }
  let root = @fs.realpath(".")
  let config = args[0]
  let base = args[1]
  let out = args[2]
  let manifest = @tutorial.Manifest::parse("tutorials.toml",@fs.read_file("tutorials.toml").text())
  let policies = [@checks.source_policy("tested.md",["cli","api"],["shell","moonbit"],"sample.tested-source")]
  ignore(@host.build(root,config,out,base=base,tutorial_policies=policies))
  let runner = @host.process_runner(manifest.providers[0],args[3],[])
  let reports = @host.check_tutorials(root,config,runners=[runner],policies~)
  assert_true(!reports.is_empty())
  guard reports.iter().all(report => report.passed) else { abort(@checks.reports_text(reports)) }
  // Reports stay outside public output because they contain private case revisions.
  @fs.write_file("case-reports.json",Json(reports).stringify(),create_mode=CreateOrTruncate)
  let static_page = @fs.read_file(out + "/learn/reading/index.html").text()
  let editable_page = @fs.read_file(out + "/learn/editing/index.html").text()
  assert_true(static_page.contains("printf 'A tested command"))
  assert_true(static_page.contains("let answer = 42"))
  assert_true(!static_page.contains("assets/editor/"))
  assert_true(!static_page.contains("assets/tutorial/workspace.js"))
  assert_true(editable_page.contains(base + "assets/tutorial/workspace.js"))
  assert_true(!@fs.read_file(out + "/search-index.json").text().contains("case-reports"))
  println("Packaged tutorial cases passed: \{reports.length()}")
}
