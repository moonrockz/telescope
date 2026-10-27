///|
fn option(args : Array[String], name : String, default : String) -> String {
  for i in 0..<args.length() {
    if args[i] == name && i + 1 < args.length() {
      return args[i + 1]
    }
  }
  default
}

///|
async fn main {
  let args = @env.args()[1:].to_owned()
  if args == ["--version"] {
    println(@host.version)
    return
  }
  let usage = "telescope build|check|serve --config site/site.json --out _site [--base /] [--format text|json] [--port 4173]\ntelescope assemble --manifest site/versions.json --out _site"
  if args.is_empty() || args == ["--help"] {
    println(usage)
    return
  }
  let command = args[0]
  let valid = [
    "--config", "--out", "--base", "--format", "--port", "--root", "--manifest",
  ]
  let mut i = 1
  while i < args.length() {
    if !valid.contains(args[i]) || i + 1 >= args.length() {
      eprintln("invalid option \{args[i]}\n\{usage}")
      @sys.exit(2)
      return
    }
    i += 2
  }
  let config_path = option(args, "--config", "site/site.json")
  let out = option(args, "--out", "_site")
  let base = if args.contains("--base") {
    Some(option(args, "--base", "/"))
  } else {
    None
  }
  let format = option(args, "--format", "text")
  if format != "text" && format != "json" {
    eprintln("--format must be text or json")
    @sys.exit(2)
    return
  }
  try {
    match command {
      "build" => {
        let warnings = @host.build(
          option(args, "--root", "."),
          config_path,
          out,
          base?,
        )
        if !warnings.is_empty() {
          eprintln(@host.diagnostics(warnings, format))
        }
        println("Built \{out}")
      }
      "check" => {
        let config = @host.configuration(config_path, base?)
        let problems = @host.check(out, config.base_path)
        println(@host.diagnostics(problems, format))
        if !problems.is_empty() {
          @sys.exit(1)
        }
      }
      "serve" => {
        let config = @host.configuration(config_path, base?)
        let port = @string.parse_int(option(args, "--port", "4173"))
        @host.serve(out, config.base_path, port)
      }
      "assemble" =>
        @host.assemble(option(args, "--manifest", "site/versions.json"), out)
      _ => {
        eprintln(usage)
        @sys.exit(2)
      }
    }
  } catch {
    @model.Invalid(problems) => {
      eprintln(@host.diagnostics(problems, format))
      @sys.exit(1)
    }
    error => {
      eprintln("\{command}: \{config_path}: \{error}")
      @sys.exit(1)
    }
  }
}
