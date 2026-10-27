///|
/// Original Telescope fixture, Apache-2.0. Consumer-owned, with no domain engine.
pub fn registry() -> @extensions.Registry {
  {
    pages: [],
    fences: [
      {
        id: "consumer-note",
        contract_version: 1,
        labels: ["consumer-note"],
        render: input => {
          let body = input.body
            .replace_all(old="&", new="&amp;")
            .replace_all(old="<", new="&lt;")
            .replace_all(old=">", new="&gt;")
          Ok({
            body_html: "<aside><h2 id=\"consumer-note\">Consumer note</h2><pre>\{body}</pre></aside>",
            text: input.body,
            headings: [
              { id: "consumer-note", text: "Consumer note", level: 2, },
            ],
            assets: [],
            problems: [],
          })
        },
      },
    ],
    islands: [
      {
        id: "consumer-counter",
        contract_version: 1,
        routes: ["/example/"],
        mount_id: "consumer-counter",
        script: { path: "assets/counter.js", media_type: "text/javascript", },
        stylesheet: None,
        fallback_html: "<p>This example is readable without JavaScript.</p>",
      },
    ],
  }
}
