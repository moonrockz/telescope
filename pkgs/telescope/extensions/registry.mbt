///|
fn problem(id : String, message : String) -> @model.Problem {
  @model.problem("extensions", "adapter \{id}: \{message}")
}

///|
fn token(value : String) -> Bool {
  value != "" &&
  value
  .iter()
  .all(c => {
    (c >= 'a' && c <= 'z') ||
    (c >= 'A' && c <= 'Z') ||
    (c >= '0' && c <= '9') ||
    c == '-' ||
    c == '_'
  })
}

///|
fn route_valid(route : String) -> Bool {
  route == "/" ||
  (
    route.has_prefix("/") &&
    route.has_suffix("/") &&
    route.length() > 2 &&
    resource_path(route[1:route.length() - 1].to_owned())
  )
}

///|
/// Keep extension registration independent of the optional gallery package.
fn resource_path(path : String) -> Bool {
  @model.relative_path(path) &&
  path
  .iter()
  .all(c => {
    (c >= 'a' && c <= 'z') ||
    (c >= 'A' && c <= 'Z') ||
    (c >= '0' && c <= '9') ||
    c == '-' ||
    c == '_' ||
    c == '.' ||
    c == '~' ||
    c == '/'
  })
}

///|
fn register_id(
  id : String,
  version : Int32,
  ids : Map[String, Bool],
  problems : Array[@model.Problem],
) -> Unit {
  if !token(id) {
    problems.push(
      problem(id, "id must be a nonempty letter/digit/hyphen/underscore token"),
    )
  }
  if ids.contains(id) {
    problems.push(problem(id, "duplicate adapter id"))
  }
  ids[id] = true
  if version != contract_version {
    problems.push(
      problem(
        id,
        "unsupported contract version \{version}; supported version is 1",
      ),
    )
  }
}

///|
fn validate_asset(
  id : String,
  artifact : Artifact,
  problems : Array[@model.Problem],
) -> Unit {
  if !resource_path(artifact.path) {
    problems.push(
      problem(
        id,
        "asset path must be normalized and relative: \{artifact.path}",
      ),
    )
  }
  if !artifact.media_type.contains("/") ||
    artifact.media_type.contains("\n") ||
    artifact.media_type.contains("\r") {
    problems.push(problem(id, "asset \{artifact.path} requires media_type"))
  }
}

///|
/// Validate registration before executing any consumer callback.
pub fn validate_registry(registry : Registry) -> Array[@model.Problem] {
  let problems = []
  let ids : Map[String, Bool] = Map([])
  let routes : Map[String, Bool] = Map([])
  let labels : Map[String, Bool] = Map([])
  let mounts : Map[String, Bool] = Map([])
  for adapter in registry.pages {
    register_id(adapter.id, adapter.contract_version, ids, problems)
    if !route_valid(adapter.route) {
      problems.push(problem(adapter.id, "invalid page route \{adapter.route}"))
    }
    if routes.contains(adapter.route) {
      problems.push(
        problem(adapter.id, "duplicate page route \{adapter.route}"),
      )
    }
    routes[adapter.route] = true
  }
  for adapter in registry.fences {
    register_id(adapter.id, adapter.contract_version, ids, problems)
    if adapter.labels.is_empty() {
      problems.push(problem(adapter.id, "requires at least one fence label"))
    }
    for label in adapter.labels {
      if !token(label) {
        problems.push(problem(adapter.id, "invalid fence label \{label}"))
      }
      if labels.contains(label) {
        problems.push(problem(adapter.id, "duplicate fence label \{label}"))
      }
      labels[label] = true
    }
  }
  for adapter in registry.islands {
    register_id(adapter.id, adapter.contract_version, ids, problems)
    if adapter.routes.is_empty() {
      problems.push(problem(adapter.id, "requires explicit island routes"))
    }
    if !token(adapter.mount_id) {
      problems.push(problem(adapter.id, "requires a valid mount_id"))
    }
    if adapter.fallback_html.trim() == "" {
      problems.push(problem(adapter.id, "requires readable fallback_html"))
    }
    validate_asset(adapter.id, adapter.script, problems)
    if adapter.script.media_type != "text/javascript" &&
      adapter.script.media_type != "application/javascript" {
      problems.push(
        problem(adapter.id, "script must have a JavaScript media_type"),
      )
    }
    if adapter.stylesheet is Some(asset) {
      validate_asset(adapter.id, asset, problems)
      if asset.media_type != "text/css" {
        problems.push(
          problem(adapter.id, "stylesheet must have media_type text/css"),
        )
      }
    }
    for route in adapter.routes {
      if !route_valid(route) {
        problems.push(problem(adapter.id, "invalid island route \{route}"))
      }
      let key = route + "#" + adapter.mount_id
      if mounts.contains(key) {
        problems.push(problem(adapter.id, "duplicate island mount \{key}"))
      }
      mounts[key] = true
    }
  }
  problems
}

///|
fn escaped(value : String) -> String {
  value
  .replace_all(old="&", new="&amp;")
  .replace_all(old="<", new="&lt;")
  .replace_all(old=">", new="&gt;")
  .replace_all(old="\"", new="&quot;")
  .replace_all(old="'", new="&#39;")
}

///|
fn invoke(
  id : String,
  render : (RenderInput) -> Result[RenderOutput, AdapterError],
  input : RenderInput,
) -> Result[RenderOutput, Array[@model.Problem]] {
  match render(input) {
    Err(error) =>
      Err([
        @model.problem(
          input.source,
          "adapter \{id} at \{error.stage}: \{error.message}",
        ),
      ])
    Ok(output) => {
      let problems = []
      let headings : Map[String, Bool] = Map([])
      for asset in output.assets {
        validate_asset(id, asset, problems)
      }
      for heading in output.headings {
        if !token(heading.id) ||
          heading.level < 1 ||
          heading.level > 6 ||
          headings.contains(heading.id) {
          problems.push(
            @model.problem(
              input.source,
              "adapter \{id} at render: invalid or duplicate heading \{heading.id}",
            ),
          )
        }
        headings[heading.id] = true
      }
      if problems.is_empty() {
        Ok(output)
      } else {
        Err(
          problems.map(p => {
            if p.file == "extensions" {
              @model.problem(input.source, "render stage: \{p.message}")
            } else {
              p
            }
          }),
        )
      }
    }
  }
}

///|
/// Unhandled languages retain escaped source with no guessed renderer.
pub fn render_fence(
  registry : Registry,
  input : RenderInput,
) -> Result[RenderOutput, Array[@model.Problem]] {
  let problems = validate_registry(registry)
  if !problems.is_empty() {
    return Err(problems)
  }
  for adapter in registry.fences {
    if adapter.labels.contains(input.language) {
      return invoke(adapter.id, adapter.render, input)
    }
  }
  Ok({
    body_html: "<pre><code class=\"language-\{escaped(input.language)}\">\{escaped(input.body)}</code></pre>",
    text: input.body,
    headings: [],
    assets: [],
    problems: [],
  })
}

///|
pub fn render_page(
  registry : Registry,
  input : RenderInput,
) -> Result[RenderOutput?, Array[@model.Problem]] {
  let problems = validate_registry(registry)
  if !problems.is_empty() {
    return Err(problems)
  }
  for adapter in registry.pages {
    if adapter.route == input.route {
      return match invoke(adapter.id, adapter.render, input) {
        Ok(value) => Ok(Some(value))
        Err(errors) => Err(errors)
      }
    }
  }
  Ok(None)
}

///|
/// Call after validate_registry; route equality keeps ordinary docs free of island assets.
pub fn islands_for_route(
  registry : Registry,
  route : String,
) -> Array[IslandAdapter] {
  registry.islands.filter(adapter => adapter.routes.contains(route))
}
