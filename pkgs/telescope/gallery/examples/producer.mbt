///|
/// Original Telescope fixture, licensed under Apache-2.0.
/// The consumer runs its own generation/check pipeline before supplying this record.
pub fn manifest(source_ref : String) -> @gallery.Manifest {
  {
    schema_version: 1,
    producer: Some({
      project: "Example project",
      source_ref,
      pipeline: "checked-example",
    }),
    root: Some("site/artifacts"),
    entries: [
      {
        id: "review-sequence",
        family: "sequence",
        title: "Review sequence",
        status: Implemented,
        description: Some("Original static fixture"),
        scope: Some("Illustration only"),
        sources: [{ path: "review.mmd", media_type: "text/plain", }],
        preview: Some({ path: "review.svg", media_type: "image/svg+xml", }),
        preview_dark: None,
        player: Some({ path: "player/index.html", media_type: "text/html", }),
        companions: [{ path: "player/player.css", media_type: "text/css", }],
      },
      {
        id: "general-plantuml",
        family: "general PlantUML",
        title: "General PlantUML",
        status: Planned,
        description: Some("Consumer implementation is planned"),
        scope: None,
        sources: [],
        preview: None,
        preview_dark: None,
        player: None,
        companions: [],
      },
    ],
  }
}
