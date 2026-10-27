///|
test "configuration aggregates normalized path and schema errors" {
  let text = config_json.replace(
    old="\"base_path\": \"/moon-lander/\"",
    new="\"base_path\": \"/../bad/\", \"schema_version\": 2, \"source_roots\": [\"../private\"]",
  )
  let problems = try
    @model.SiteConfig::parse("consumer/site.json", text)
  catch {
    @model.Invalid(problems) => problems
  } noraise {
    _ => []
  }
  assert_eq(problems.length(), 3)
  assert_true(problems.iter().all(p => p.file == "consumer/site.json"))
}

///|
test "consumer roots and default exclusions are portable" {
  let config = @model.SiteConfig::parse(
    "site.json",
    config_json.replace(
      old="\"packages\": [\"notebooks\"]",
      new="\"packages\": [], \"docs_dir\": \"guide\", \"repo_ref\": \"release-ref\"",
    ),
  )
  assert_true(config.includes("guide/start.html"))
  assert_false(config.includes("guide/templates/design.html"))
  assert_false(config.includes("guide/superpowers/plan.md"))
  assert_false(config.includes("guide/../secret.md"))
  assert_false(config.includes("docs/old.md"))
  assert_eq(config.repo_ref, "release-ref")
}
