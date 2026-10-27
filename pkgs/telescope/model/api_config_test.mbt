///|
fn with_api(api : String) -> String {
  site_json().replace(
    old="\"packages\": [\"notebooks\"]",
    new="\"packages\": [\"notebooks\"],\n  \"api\": \{api}",
  )
}

///|
test "api lists module directories below pkgs/" {
  let config = @model.SiteConfig::parse(
    "site/site.json",
    with_api("[\"pkgs/lander\", \"pkgs/notebooks\"]"),
  )
  @expect.expect(config.api).to_equal(["pkgs/lander", "pkgs/notebooks"])
}

///|
test "API modules may live in consumer supplied directories" {
  let custom = @model.SiteConfig::parse(
    "site/site.json",
    with_api("[\"apps/site\", \"tests\"]"),
  )
  assert_eq(custom.api, ["apps/site", "tests"])
  @expect.expect(
    problems_of(
      with_api("[\"pkgs/../apps/site\", \"pkgs/\", \"pkgs/x\", \"pkgs/x\"]"),
    ),
  ).to_equal([
    "site/site.json: `api` lists `pkgs/../apps/site`: expected a normalized relative module directory",
    "site/site.json: `api` lists `pkgs/`: expected a normalized relative module directory",
    "site/site.json: `api` lists `pkgs/x` more than once",
  ])
  @expect.expect(problems_of(with_api("\"pkgs/x\""))).to_equal([
    "site/site.json: `api` must be an array of module directories",
  ])
}
