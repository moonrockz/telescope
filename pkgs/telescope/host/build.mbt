///|
fn string_field(value : Json, key : String, default : String) -> String {
  match value {
    Object(fields) =>
      match fields.get(key) {
        Some(String(s)) => s
        _ => default
      }
    _ => default
  }
}

///|
pub async fn configuration(path : String, base? : String) -> @model.SiteConfig {
  let config = @model.SiteConfig::parse(path, @fs.read_file(path).text())
  match base {
    Some(base_path) => {
      guard base_path.has_prefix("/") &&
        base_path.has_suffix("/") &&
        !base_path.contains("..") &&
        !base_path.contains("\\") else {
        raise @model.Invalid([
          @model.problem(path, "invalid deployment base path"),
        ])
      }
      { ..config, base_path, }
    }
    None => config
  }
}

///|
async fn destination(out : String) -> String {
  let name = out.split("/").last().unwrap_or("").to_owned()
  guard relative(name) else {
    raise @model.Invalid([@model.problem(out, "invalid output directory")])
  }
  @fs.mkdir(parent(out), recursive=true, allow_exist=true)
  let parent_dir = @fs.realpath(parent(out))
  let path = "\{parent_dir}/\{name}"
  if @fs.exists(path) && @fs.kind(path, follow_symlink=false) != Directory {
    raise @model.Invalid([
      @model.problem(out, "output must be a directory, not a symlink or file"),
    ])
  }
  path
}

///|
async fn promote(stage : String, out : String) -> Unit {
  @async.protect_from_cancel(() => promote_uncancelled(stage, out))
}

///|
async fn promote_uncancelled(stage : String, out : String) -> Unit {
  let backup = stage + "-previous"
  let existed = @fs.exists(out)
  if existed {
    @fs.rename(out, backup)
  }
  errdefer (if existed && @fs.exists(backup) && !@fs.exists(out) {
    @fs.rename(backup, out)
  })
  @fs.rename(stage, out)
  if existed {
    @fs.rmdir(backup, recursive=true) catch {
      error =>
        eprintln(
          "warning: output promoted; old output cleanup failed at \{backup}: \{error}",
        )
    }
  }
}

///|
async fn stage_for(out : String) -> String {
  let unique = @fs.tmpdir(prefix="telescope")
  defer @fs.rmdir(unique)
  let name = unique.split("/").last().unwrap().to_owned()
  let stage = parent(out) + "/." + name
  @fs.mkdir(stage)
  stage
}

///|
async fn api_input(
  root : String,
  config : @model.SiteConfig,
  value : Json,
  out : String,
) -> @site.ApiSite {
  if config.api.is_empty() {
    return @site.no_api
  }
  let api_root = string_field(value, "api_output", "_build/site-api")
  guard relative(api_root) else {
    raise @model.Invalid([@model.problem(api_root, "invalid API metadata root")])
  }
  let modules = []
  for dir in config.api {
    guard relative(dir) else {
      raise @model.Invalid([@model.problem(dir, "invalid API module directory")])
    }
    let source = @fs.realpath("\{root}/\{dir}")
    guard within(root, source) && !within(source, out) && !within(out, source) else {
      raise @model.Invalid([
        @model.problem(dir, "API module escapes project root"),
      ])
    }
    let target = bounded_path(root, api_root + "/" + dir)
    guard !within(target, out) && !within(out, target) else {
      raise @model.Invalid([
        @model.problem(api_root, "API metadata and output roots overlap"),
      ])
    }
    let generate = match value {
      Object(fields) => fields.get("api_generate") is Some(True)
      _ => false
    }
    if generate || string_field(value, "api_generate", "false") == "true" {
      let (code, _, stderr) = @process.collect_output(
        "moon",
        ["doc", "--target-dir", target],
        cwd=source,
      )
      guard code == 0 else {
        raise @model.Invalid([
          @model.problem(dir, "moon doc failed: \{stderr.text()}"),
        ])
      }
    }
    let doc = @fs.realpath("\{root}/\{api_root}/\{dir}/doc")
    guard within(root, doc) else {
      raise @model.Invalid([
        @model.problem(doc, "API metadata escapes project root"),
      ])
    }
    let index = files(doc)
      .iter()
      .find_first(f => f.has_suffix("/module_index.json"))
    guard index is Some(index) else {
      raise @model.Invalid([@model.problem(doc, "missing module_index.json")])
    }
    let name = index[:index.length() - "/module_index.json".length()].to_owned()
    let order = @model.api_index_packages(
      index,
      @fs.read_file(checked_file(doc, index)).text(),
    )
    let packages = []
    let readmes : Map[String, String] = Map([])
    for path in order {
      let data = checked_file(doc, path + "/package_data.json")
      packages.push(@model.ApiPackage::parse(data, @fs.read_file(data).text()))
      let readme = path + "/README.md"
      if @fs.exists("\{doc}/\{readme}") {
        readmes[path] = @fs.read_file(checked_file(doc, readme)).text()
      }
    }
    modules.push(@site.ApiModule::{ dir, name, packages, readmes, })
  }
  { commit: string_field(value, "repo_ref", "main"), modules, }
}

///|
pub async fn build(
  root : String,
  config_path : String,
  out : String,
  base? : String,
  providers~ : @extensions.Registry = @extensions.empty_registry(),
  main_build~ : Bool = false,
) -> Array[@model.Problem] {
  let root = @fs.realpath(root)
  let out = destination(out)
  let config_real = @fs.realpath(config_path)
  guard within(root, config_real) && !within(out, config_real) else {
    raise @model.Invalid([
      @model.problem(
        config_path, "config escapes project or lies inside output",
      ),
    ])
  }
  let config = configuration(config_path, base?)
  let value = @json.parse(@fs.read_file(config_path).text())
  let roots = config.source_roots
  let sources = []
  let seen : Map[String, Bool] = Map([])
  for rel in roots {
    guard relative(rel) else {
      raise @model.Invalid([@model.problem(rel, "invalid public source root")])
    }
    if !@fs.exists("\{root}/\{rel}") {
      continue
    }
    let source_root = @fs.realpath("\{root}/\{rel}")
    guard within(root, source_root) &&
      !within(source_root, out) &&
      !within(out, source_root) else {
      raise @model.Invalid([
        @model.problem(rel, "input and output roots overlap or escape project"),
      ])
    }
    for file in files(source_root) {
      let path = rel + "/" + file
      if !config.includes(path) || seen.contains(path) {
        continue
      }
      seen[path] = true
      let text = if @site.needs_text(path, config) {
        Some(@fs.read_file(checked_file(root, path)).text())
      } else {
        None
      }
      sources.push(@site.SourceFile::{ path, text, })
    }
  }
  let api = api_input(root, config, value, out)
  let gallery = gallery_outputs(root, config, value, out~)
  let external_routes = gallery.filter_map(output => {
    match output {
      Text(path, _) =>
        if path.has_suffix("index.html") {
          Some("/" + path[:path.length() - "index.html".length()].to_owned())
        } else {
          None
        }
      _ => None
    }
  })
  let built = @site.build(
    config,
    sources,
    main_build~,
    api~,
    external_routes~,
    providers~,
  )
  let outputs = built.outputs.copy()
  outputs.append(gallery)
  for (path, text) in shell_assets {
    outputs.push(Text(path, text))
  }
  let extensions : Array[Json] = match value {
    Object(fields) =>
      match fields.get("gallery") {
        Some(gallery) => [{ "id": "gallery", "input": gallery }]
        None => []
      }
    _ => []
  }
  let provenance : Json = {
    "toolkit_version": version,
    "extensions": extensions,
    "api_modules": config.api,
    "repo_ref": config.repo_ref,
    "providers": {
      "pages": providers.pages.map(provider => provider.id),
      "fences": providers.fences.map(provider => provider.id),
      "islands": providers.islands.map(provider => provider.id),
    },
  }
  outputs.push(Text("telescope-build.json", provenance.stringify()))
  let paths : Map[String, Bool] = Map([])
  for output in outputs {
    let path = match output {
      Text(p, _) | Copy(p, _) => p
    }
    guard relative(path) && !paths.contains(path) else {
      raise @model.Invalid([
        @model.problem(path, "invalid or duplicate output path"),
      ])
    }
    if paths
      .keys()
      .any(p => p.has_prefix(path + "/") || path.has_prefix(p + "/")) {
      raise @model.Invalid([
        @model.problem(path, "file/directory output collision"),
      ])
    }
    paths[path] = true
    if output is Copy(_, from) {
      ignore(checked_file(root, from))
    }
  }
  let stage = stage_for(out)
  defer (if @fs.exists(stage) { @fs.rmdir(stage, recursive=true) })
  for output in outputs {
    match output {
      Text(path, text) => write("\{stage}/\{path}", text)
      Copy(path, from) =>
        write(
          "\{stage}/\{path}",
          @fs.read_file(checked_file(root, from)).binary(),
        )
    }
  }
  let problems = check(stage, config.base_path)
  guard problems.is_empty() else { raise @model.Invalid(problems) }
  promote(stage, out)
  built.warnings
}
