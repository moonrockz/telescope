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
  ignore(@host.build(args[2], args[0], args[1], providers~))
}
