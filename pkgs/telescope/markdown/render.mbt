///|
/// Render CommonMark with tables, strikethrough and task lists to HTML, then add
/// heading anchors and collect the document facts. Raw HTML is kept, because site
/// content is reviewed in pull requests.
pub fn render_markdown(
  file : String,
  source : String,
) -> @content.Document raise @model.Invalid {
  let html = @cmark_html.render(safe=false, strict=false, source) catch {
    error =>
      raise @model.Invalid([
        @model.problem(file, "Markdown does not render: \{error}"),
      ])
  }
  @content.analyse_html(html)
}
