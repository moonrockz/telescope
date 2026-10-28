///|
using @html {type Html}

///|
pub(all) struct PageMeta {
  config : @model.SiteConfig
  route : String
  title : String
  description : String
  section : @model.Section
}

///|
/// Sets the stored theme before the first paint, so the page does not flash. It is in `<head>`
/// before the stylesheet link.
pub let theme_script : String = "try{var t=localStorage.getItem('site-theme');if(t==='light'||t==='dark')document.documentElement.dataset.theme=t}catch(e){}"

///|
/// A block of reviewed HTML.
pub fn raw(html : String, class~ : String = "prose") -> Html {
  @html.div(class~, attrs=@html.Attrs::build().inner_html(html), @html.nothing)
}

///|
/// An empty mount element for a client island. `inner_html` keeps it free of the
/// hydration comments that an empty child list would add.
fn island(id : String) -> Html {
  @html.div(id~, attrs=@html.Attrs::build().inner_html(""), @html.nothing)
}

///|
fn nav_link(
  meta : PageMeta,
  section : @model.Section,
  route : String,
  label : String,
  tutorial_nav~ : Array[(String, String)] = [],
) -> Html {
  if meta.section == section &&
    !(section == Docs &&
    (
      meta.route.has_prefix("/gallery/") ||
      tutorial_nav.iter().any(item => meta.route.has_prefix(item.0))
    )) {
    @html.a(
      href=meta.config.href(route),
      class="current",
      attrs=@html.Attrs::build().aria_current("page"),
      label,
    )
  } else {
    @html.a(href=meta.config.href(route), label)
  }
}

///|
/// The page frame: head, header, main content and footer. Every link starts with the base path, and
/// the page works without JavaScript: the islands script only fills the empty mount elements of the
/// search box, the version switcher, the theme control and the menu button.
pub fn layout(
  meta : PageMeta,
  main : Html,
  gallery~ : Bool = false,
  tutorial_nav~ : Array[(String, String)] = [],
) -> Html {
  let config = meta.config
  let title = if meta.section == Home {
    config.title
  } else {
    "\{meta.title} · \{config.title}"
  }
  @html.html(
    lang="en",
    attrs=@html.Attrs::build()
      .data_set("base", config.base_path)
      .data_set("site-root", @model.site_root(config.base_path)),
    [
      @html.head(
        [
          @html.meta(charset="utf-8"),
          @html.meta(
            name="viewport",
            content="width=device-width, initial-scale=1",
          ),
          @html.title(title),
          @html.meta(name="description", content=meta.description),
          @html.script(
            attrs=@html.Attrs::build().inner_html(theme_script),
            @html.nothing,
          ),
          @html.link(rel="stylesheet", href=config.href("/assets/site.css")),
        ] +
        (if config.favicon == "" {
          []
        } else {
          [@html.link(rel="icon", href=config.href("/" + config.favicon))]
        }) +
        (if meta.route.has_prefix("/gallery/") {
          [
            @html.link(rel="stylesheet", href=config.href("/assets/viewer.css")),
            @html.script(
              src=config.href("/assets/viewer.js"),
              attrs=@html.Attrs::build().defer_(true),
              @html.nothing,
            ),
          ] +
          (if config.gallery_raster_adapter == "" {
            []
          } else {
            [
              @html.script(
                src=config.href("/" + config.gallery_raster_adapter),
                attrs=@html.Attrs::build().defer_(true),
                @html.nothing,
              ),
              @html.script(
                src=config.href("/assets/gallery-export.js"),
                attrs=@html.Attrs::build().defer_(true),
                @html.nothing,
              ),
            ]
          })
        } else {
          []
        }) +
        [
          @html.link(
            rel="alternate",
            type_="application/atom+xml",
            href=config.href("/articles/atom.xml"),
            title="\{config.title} articles",
          ),
          @html.script(
            src=config.href("/assets/islands.js"),
            type_="module",
            @html.nothing,
          ),
        ],
      ),
      @html.body([
        @html.a(href="#content", class="skip-link", "Skip to content"),
        @html.header(class="site-header", [
          @html.a(
            href=config.href("/"),
            class="brand",
            (if config.header_logo == "" {
              []
            } else {
              [
                @html.img(
                  src=config.href("/" + config.header_logo),
                  alt="",
                  width=32,
                  height=32,
                ),
              ]
            }) +
            [@html.text(config.title)],
          ),
          @html.nav(
            id="site-links",
            class="site-links",
            attrs=@html.Attrs::build().aria_label("Main"),
            [
              nav_link(meta, Docs, "/docs/", "Docs", tutorial_nav~),
              nav_link(meta, Articles, "/articles/", "Articles"),
            ] +
            (if gallery {
              [
                if meta.route.has_prefix("/gallery/") {
                  @html.a(
                    href=config.href("/gallery/"),
                    class="current",
                    attrs=@html.Attrs::build().aria_current("page"),
                    "Gallery",
                  )
                } else {
                  @html.a(href=config.href("/gallery/"), "Gallery")
                },
              ]
            } else {
              []
            }) +
            (if config.api.is_empty() {
              []
            } else {
              [nav_link(meta, Api, "/api/", "API")]
            }) +
            tutorial_nav.map(item => {
              @html.a(
                href=config.href(item.0),
                attrs=if meta.route.has_prefix(item.0) {
                  @html.Attrs::build().aria_current("page")
                } else {
                  @html.Attrs::build()
                },
                item.1,
              )
            }) +
            [@html.a(href=config.repo_url, "GitHub")],
          ),
          island("site-search"),
          island("site-version"),
          island("site-theme"),
          island("site-nav"),
        ]),
        // The deploy fills the banner of an older or unreleased version tree (design D22), so it
        // shows without JavaScript. A build writes it empty.
        @html.div(
          class="version-banner",
          attrs=@html.Attrs::build().inner_html(""),
          @html.nothing,
        ),
        @html.main_(id="content", [main]),
        @html.footer(class="site-footer", [@html.p(config.footer)]),
      ]),
    ],
  )
}

///|
pub async fn render(
  meta : PageMeta,
  main : Html,
  gallery~ : Bool = false,
  tutorial_nav~ : Array[(String, String)] = [],
) -> String {
  let page = layout(meta, main, gallery~, tutorial_nav~)
  @rabbita.new(() => @rabbita.Val::constant(page)).render(
    url=meta.config.absolute(meta.route),
  )
}
