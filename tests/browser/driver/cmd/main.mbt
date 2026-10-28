// Original Telescope browser qualification driver, Apache-2.0.
// This consumer compiles explicit adapters through the public library API.

///|
async fn main {
  let args = @env.args()[1:].to_owned()
  guard args.length() == 3 else {
    abort("usage: browser-driver CONFIG OUT ROOT")
  }
  let providers : @extensions.Registry = {
    fences: [],
    pages: [
      {
        id: "standalone-editor",
        contract_version: 1,
        route: "/editor/",
        render: input => {
          Ok({
            body_html: editor_page(input.base_path),
            text: "Standalone MoonBit editor with optional text formatting.",
            headings: [],
            assets: [
              {
                path: "consumer/custom-editor.js",
                media_type: "text/javascript",
              },
              {
                path: "consumer/custom-language.js",
                media_type: "text/javascript",
              },
              {
                path: "consumer/moonbit-language.js",
                media_type: "text/javascript",
              },
              {
                path: "consumer/editor-whitespace-worker.js",
                media_type: "text/javascript",
              },
            ],
            problems: [],
          })
        },
      },
      {
        id: "observatory-workbench",
        contract_version: 1,
        route: "/workbench/",
        render: _ => {
          Ok({
            body_html: "<h1 id=\"registered-workbench\">Registered workbench</h1><p>A consumer page rendered by Telescope.</p>",
            text: "A consumer page rendered by Telescope.",
            headings: [
              {
                id: "registered-workbench",
                text: "Registered workbench",
                level: 1,
              },
            ],
            assets: [],
            problems: [],
          })
        },
      },
    ],
    islands: [
      {
        id: "observatory-counter",
        contract_version: 1,
        routes: ["/workbench/"],
        mount_id: "registered-counter",
        script: { path: "consumer/counter.js", media_type: "text/javascript", },
        stylesheet: Some({
          path: "consumer/counter.css",
          media_type: "text/css",
        }),
        fallback_html: "<p>The registered counter starts at zero. Its instructions remain readable without JavaScript.</p>",
      },
    ],
  }
  let tutorial_policies = [
    @tutorial_check.source_policy(
      "tested.md",
      ["cli", "api"],
      ["shell", "moonbit"],
      "sample.tested-source",
    ),
  ]
  ignore(@host.build(args[2], args[0], args[1], providers~, tutorial_policies~))
  let runner : @host.TutorialRunner = {
    provider: "sample.text",
    engine_version: "1.0.0",
    contract_version: 1,
    operations: ["evaluate", "start", "step", "run-all"],
    evaluate: request => {
      match @sample.evaluate(request) {
        Ok(value) => Ok(value)
        Err(error) => Err(error.message)
      }
    },
  }
  let reports = @host.check_tutorials(
    args[2],
    args[0],
    runners=[runner],
    policies=tutorial_policies,
  )
  let failures = reports.filter(report => !report.passed)
  if !failures.is_empty() {
    abort(@tutorial_check.reports_text(failures))
  }
}
