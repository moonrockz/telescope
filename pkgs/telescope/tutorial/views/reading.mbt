///|
pub fn contents(
  config : @model.SiteConfig,
  course : @tutorial.Course,
  current~ : String = "",
) -> String {
  let out = StringBuilder()
  out.write_string(
    "<nav class=\"tutorial-contents\" aria-label=\"Course contents\"><h2>" +
    @content.escape(course.title) +
    "</h2><ol>",
  )
  let mut section = ""
  for lesson in course.lessons {
    if lesson.section != section {
      section = lesson.section
      out.write_string("</ol><h3>" + @content.escape(section) + "</h3><ol>")
    }
    let selected = if current == lesson.slug {
      " aria-current=\"page\""
    } else {
      ""
    }
    out.write_string(
      "<li><a" +
      selected +
      " href=\"" +
      @content.escape(config.href(course.lesson_route(lesson))) +
      "\">" +
      @content.escape(lesson.title) +
      "</a></li>",
    )
  }
  out.write_string("</ol></nav>")
  out.to_string()
}

///|
pub fn lesson(
  config : @model.SiteConfig,
  course : @tutorial.Course,
  lesson : @tutorial.Lesson,
  prose : String,
  files : Array[@tutorial.File],
  downloads : Array[String],
) -> String {
  let out = StringBuilder()
  out.write_string("<h1>" + @content.escape(lesson.title) + "</h1>")
  out.write_string(contents(config, course, current=lesson.slug))
  out.write_string(prose)
  if !lesson.references.is_empty() {
    out.write_string(
      "<section aria-label=\"References\"><h2>References</h2><ul>",
    )
    for reference in lesson.references {
      out.write_string(
        "<li><a href=\"" +
        @content.escape(reference.url) +
        "\">" +
        @content.escape(reference.label) +
        "</a></li>",
      )
    }
    out.write_string("</ul></section>")
  }
  if !files.is_empty() {
    out.write_string(
      "<section class=\"tutorial-starting\" aria-label=\"Starting files\"><h2>Starting files</h2>",
    )
    for i, file in files {
      out.write_string(
        "<details open><summary>" +
        @content.escape(file.name) +
        "</summary><pre><code>" +
        @content.escape(file.text) +
        "</code></pre><a download href=\"" +
        @content.escape(config.href(downloads[i])) +
        "\">Download " +
        @content.escape(file.name) +
        "</a></details>",
      )
    }
    out.write_string("</section>")
  }
  let (previous, next) = course.neighbors(lesson.slug)
  out.write_string("<nav aria-label=\"Lesson navigation\">")
  if previous is Some(item) {
    out.write_string(
      "<a rel=\"prev\" href=\"" +
      config.href(course.lesson_route(item)) +
      "\">Previous: " +
      @content.escape(item.title) +
      "</a> ",
    )
  }
  if next is Some(item) {
    out.write_string(
      "<a rel=\"next\" href=\"" +
      config.href(course.lesson_route(item)) +
      "\">Next: " +
      @content.escape(item.title) +
      "</a>",
    )
  }
  out.write_string("</nav>")
  out.to_string()
}
