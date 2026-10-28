///|
pub(all) struct SourceEvidence {
  runner : String
  source_revision : String
  input_revision : String
  success : Bool
  required : Bool
} derive(Eq, Debug)

///|
pub(all) struct SourcePolicy {
  source : String
  regions : Array[String]
  languages : Array[String]
  runner : String
  marker_start : String
  marker_end : String
  evidence : SourceEvidence?
  evidence_by_input : Map[String, SourceEvidence]
} derive(Eq, Debug)

///|
pub(all) struct IncludedBlock {
  language : String
  text : String
} derive(Eq, Debug, ToJson, FromJson)

///|
pub(all) struct IncludedRegion {
  source : String
  region : String
  language : String
  text : String
  blocks : Array[IncludedBlock]
  runner : String
  source_revision : String
  verified : Bool
} derive(Eq, Debug)

///|
pub(all) struct Include {
  label : String
  path : String
  region : String
  line : Int32
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn source_policy(
  source : String,
  regions : Array[String],
  languages : Array[String],
  runner : String,
) -> SourcePolicy {
  {
    source,
    regions,
    languages,
    runner,
    marker_start: "tutorial:start",
    marker_end: "tutorial:end",
    evidence: None,
    evidence_by_input: Map([]),
  }
}

///|
fn trim(text : String) -> String {
  text.trim().to_owned()
}

///|
fn marker(line : String, tag : String) -> String? {
  // Only comment-shaped complete lines are marker declarations.
  let line = trim(line)
  let body = if line.has_prefix("<!--") && line.has_suffix("-->") {
    trim(line[4:line.length() - 3].to_owned())
  } else if line.has_prefix("//") {
    trim(line[2:].to_owned())
  } else if line.has_prefix("#") {
    trim(line[1:].to_owned())
  } else {
    return None
  }
  if body == tag {
    Some("")
  } else if body.has_prefix(tag + " ") {
    Some(trim(body[tag.length() + 1:].to_owned()))
  } else {
    None
  }
}

///|
fn fence_start(line : String) -> (String, Int32, String)? {
  let line = trim(line)
  let token = if line.has_prefix("```") {
    "`"
  } else if line.has_prefix("~~~") {
    "~"
  } else {
    return None
  }
  let mut count = 0
  for c in line {
    if c.to_string() == token {
      count += 1
    } else {
      break
    }
  }
  Some((token, count, trim(line[count:].to_owned())))
}

///|
fn closes(line : String, token : String, count : Int32) -> Bool {
  let line = trim(line)
  line.length() >= count && line.iter().all(c => c.to_string() == token)
}

///|
pub fn extract_region(
  source_path : String,
  source_text : String,
  region : String,
  policy : SourcePolicy,
  input_revision~ : String? = None,
) -> IncludedRegion raise @base.Invalid {
  if policy.source != source_path ||
    !policy.regions.contains(region) ||
    policy.runner == "" ||
    policy.marker_start == "" ||
    policy.marker_end == "" ||
    policy.marker_start == policy.marker_end {
    invalid(
      source_path, region, "region is not covered by a valid source policy",
    )
  }
  let lines = source_text.split("\n").to_array().map(s => s.to_owned())
  let seen : Map[String, Bool] = Map([])
  let mut active : String? = None
  let mut selected = false
  let mut fence : (String, Int32, String)? = None
  let mut code : Array[String] = []
  let blocks : Array[IncludedBlock] = []
  for i, line in lines {
    match fence {
      Some((token, count, language)) =>
        if closes(line, token, count) {
          if selected {
            if !policy.languages.contains(language) {
              invalid(
                source_path,
                "line \{i+1}",
                "unapproved fence language " + language,
              )
            }
            blocks.push({
              language,
              text: code.join("\n") + (if code.is_empty() { "" } else { "\n" }),
            })
          }
          code = []
          fence = None
        } else if selected {
          code.push(line)
        }
      None =>
        if marker(line, policy.marker_start) is Some(name) {
          if name == "" || active is Some(_) || seen.contains(name) {
            invalid(
              source_path,
              "line \{i+1}",
              "nested, empty or repeated source region " + name,
            )
          }
          seen[name] = true
          active = Some(name)
          selected = name == region
        } else if marker(line, policy.marker_end) is Some(name) {
          if active != Some(name) {
            invalid(
              source_path,
              "line \{i+1}",
              "unmatched source region end " + name,
            )
          }
          active = None
          selected = false
        } else if fence_start(line) is Some(found) {
          fence = Some(found)
        }
    }
  }
  if active is Some(_) || fence is Some(_) {
    invalid(source_path, region, "unclosed region or code fence")
  }
  if !seen.contains(region) || blocks.is_empty() {
    invalid(
      source_path, region, "missing region or no approved tested code block",
    )
  }
  let source_revision = @tutorial.revision(Json(source_text))
  let verified = match input_revision {
    None => false
    Some(expected) =>
      match source_evidence(policy, expected) {
        Some(evidence) =>
          evidence.runner == policy.runner &&
          evidence.source_revision == source_revision &&
          evidence.input_revision == expected &&
          evidence.success
        None => false
      }
  }
  {
    source: source_path,
    region,
    language: blocks[0].language,
    text: blocks[0].text,
    blocks,
    runner: policy.runner,
    source_revision,
    verified,
  }
}

///|
/// Revision-specific evidence overrides a default report; unmatched required defaults fail.
pub fn source_evidence(
  policy : SourcePolicy,
  input_revision : String,
) -> SourceEvidence? {
  match policy.evidence_by_input.get(input_revision) {
    Some(evidence) => Some(evidence)
    None => policy.evidence
  }
}

///|
pub fn source_evidence_problems(
  policy : SourcePolicy,
  source_revision : String,
  input_revision : String,
) -> Array[String] {
  match source_evidence(policy, input_revision) {
    None => []
    Some(evidence) => {
      let problems = []
      if evidence.required &&
        (
          !evidence.success ||
          evidence.runner != policy.runner ||
          evidence.source_revision != source_revision ||
          evidence.input_revision != input_revision
        ) {
        problems.push(
          "required tested-source runner evidence failed or is stale",
        )
      }
      problems
    }
  }
}

///|
/// Label = relative/path#region inside an explicit tutorial-include fence.
pub fn parse_includes(
  source : String,
  text : String,
) -> Array[Include] raise @base.Invalid {
  let includes = []
  let mut fence : (String, Int32, String)? = None
  let mut labels : Map[String, Bool] = Map([])
  for i, line in text.split("\n").to_array() {
    let line = line.to_owned()
    match fence {
      None =>
        if fence_start(line) is Some(found) {
          fence = Some(found)
          labels = Map([])
        }
      Some((token, count, language)) => {
        if closes(line, token, count) {
          fence = None
          continue
        }
        if language != "tutorial-include" {
          continue
        }
        let value = trim(line)
        if value == "" {
          continue
        }
        let pair = value.split("=").to_array()
        if pair.length() != 2 {
          invalid(
            source,
            "line \{i+1}",
            "include entry must be Label = path#region",
          )
        }
        let label = trim(pair[0].to_owned())
        let target = trim(pair[1].to_owned()).split("#").to_array()
        if label == "" || labels.contains(label) || target.length() != 2 {
          invalid(
            source,
            "line \{i+1}",
            "invalid or duplicate include label/target",
          )
        }
        let path = target[0].to_owned()
        let region = target[1].to_owned()
        if !@base.relative_path(path) || region == "" {
          invalid(
            source,
            "line \{i+1}",
            "include target must be a contained relative path and nonempty region",
          )
        }
        labels[label] = true
        includes.push({ label, path, region, line: i + 1, })
      }
    }
  }
  if fence is Some((_, _, "tutorial-include")) {
    invalid(source, "include", "unclosed include fence")
  }
  includes
}

///|
pub extend SourceEvidence with Eq::{equal, not_equal}

///|
pub extend SourceEvidence with @debug.Debug::{to_repr}

///|
pub extend SourceEvidence with ToJson::{to_json}

///|
pub extend SourceEvidence with @json.FromJson::{from_json}

///|
pub extend SourcePolicy with Eq::{equal, not_equal}

///|
pub extend SourcePolicy with @debug.Debug::{to_repr}

///|
pub extend SourcePolicy with ToJson::{to_json}

///|
pub extend SourcePolicy with @json.FromJson::{from_json}

///|
pub extend IncludedBlock with Eq::{equal, not_equal}

///|
pub extend IncludedBlock with @debug.Debug::{to_repr}

///|
pub extend IncludedBlock with ToJson::{to_json}

///|
pub extend IncludedBlock with @json.FromJson::{from_json}

///|
pub extend IncludedRegion with Eq::{equal, not_equal}

///|
pub extend IncludedRegion with @debug.Debug::{to_repr}

///|
pub extend IncludedRegion with ToJson::{to_json}

///|
pub extend IncludedRegion with @json.FromJson::{from_json}

///|
pub extend Include with Eq::{equal, not_equal}

///|
pub extend Include with @debug.Debug::{to_repr}

///|
pub extend Include with ToJson::{to_json}

///|
pub extend Include with @json.FromJson::{from_json}
