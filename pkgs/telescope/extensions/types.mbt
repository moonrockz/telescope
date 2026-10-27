///|
/// The contract is a compile-time API, not a dynamic plugin ABI.
pub let contract_version : Int32 = 1

///|
pub(all) struct Artifact {
  path : String
  media_type : String
} derive(Eq, Debug)

///|
pub(all) struct Heading {
  id : String
  text : String
  level : Int32
} derive(Eq, Debug)

///|
/// Text and paths are supplied explicitly. Adapters receive no ambient IO handle.
pub(all) struct RenderInput {
  source : String
  route : String
  base_path : String
  body : String
  language : String
  /// One-based occurrence within a fence adapter in this document; zero for pages.
  ordinal : Int32
} derive(Eq, Debug)

///|
/// Reviewed body HTML follows the same trust model as repository HTML inputs.
pub(all) struct RenderOutput {
  body_html : String
  text : String
  headings : Array[Heading]
  assets : Array[Artifact]
  problems : Array[@model.Problem]
} derive(Eq, Debug)

///|
pub(all) struct AdapterError {
  message : String
  stage : String
} derive(Eq, Debug)

///|
pub(all) struct PageAdapter {
  id : String
  contract_version : Int32
  route : String
  render : (RenderInput) -> Result[RenderOutput, AdapterError]
}

///|
pub(all) struct FenceAdapter {
  id : String
  contract_version : Int32
  labels : Array[String]
  render : (RenderInput) -> Result[RenderOutput, AdapterError]
}

///|
/// A route-local script, mount and readable no-JS fallback. Assets are root-relative files.
pub(all) struct IslandAdapter {
  id : String
  contract_version : Int32
  routes : Array[String]
  mount_id : String
  script : Artifact
  stylesheet : Artifact?
  fallback_html : String
} derive(Eq, Debug)

///|
pub(all) struct Registry {
  pages : Array[PageAdapter]
  fences : Array[FenceAdapter]
  islands : Array[IslandAdapter]
}

///|
pub fn empty_registry() -> Registry {
  { pages: [], fences: [], islands: [], }
}

///|
pub extend Artifact with Eq::{equal, not_equal}

///|
pub extend Artifact with @debug.Debug::{to_repr}

///|
pub extend Heading with Eq::{equal, not_equal}

///|
pub extend Heading with @debug.Debug::{to_repr}

///|
pub extend RenderInput with Eq::{equal, not_equal}

///|
pub extend RenderInput with @debug.Debug::{to_repr}

///|
pub extend RenderOutput with Eq::{equal, not_equal}

///|
pub extend RenderOutput with @debug.Debug::{to_repr}

///|
pub extend AdapterError with Eq::{equal, not_equal}

///|
pub extend AdapterError with @debug.Debug::{to_repr}

///|
pub extend IslandAdapter with Eq::{equal, not_equal}

///|
pub extend IslandAdapter with @debug.Debug::{to_repr}
