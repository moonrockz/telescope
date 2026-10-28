///|
/// Static, readable source. A caller may retain this until mounting succeeds.
pub fn fallback(documents : Array[@editor.Document]) -> @html.Html {
  @html.div(
    class="editor-fallback",
    documents.map(document => {
      @html.section([
        @html.h3(@html.text(document.name)),
        @html.pre(@html.code(@html.text(document.text))),
      ])
    }),
  )
}
