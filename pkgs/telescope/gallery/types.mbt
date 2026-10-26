///|
/// A supplied artifact. Paths are normalized, relative to the declared artifact root.
pub(all) struct FileRef {
  path : String
  media_type : String
} derive(Eq, Debug)

///|
pub(all) enum Status {
  Implemented
  Planned
} derive(Eq, Debug)

///|
pub(all) struct Producer {
  project : String
  source_ref : String
  pipeline : String
} derive(Eq, Debug)

///|
/// Family and scope are consumer metadata, never renderer capability declarations.
pub(all) struct Entry {
  id : String
  family : String
  title : String
  status : Status
  description : String?
  scope : String?
  sources : Array[FileRef]
  preview : FileRef?
  preview_dark : FileRef?
  player : FileRef?
  companions : Array[FileRef]
} derive(Eq, Debug)

///|
pub(all) struct Manifest {
  schema_version : Int32
  producer : Producer?
  root : String?
  entries : Array[Entry]
} derive(Eq, Debug)

///|
/// Body is escaped HTML for the shared Rabbita shell, not a standalone document.
pub(all) struct GalleryPage {
  route : String
  title : String
  body_html : String
} derive(Eq, Debug)

///|
/// The host must validate regular files and realpath containment before copying.
pub(all) struct ArtifactCopy {
  source_path : String
  output_path : String
  media_type : String
} derive(Eq, Debug)

///|
pub(all) struct GalleryPlan {
  pages : Array[GalleryPage]
  copies : Array[ArtifactCopy]
} derive(Eq, Debug)

///|
pub extend FileRef with Eq::{equal, not_equal}

///|
pub extend FileRef with @debug.Debug::{to_repr}

///|
pub extend Status with Eq::{equal, not_equal}

///|
pub extend Status with @debug.Debug::{to_repr}

///|
pub extend Producer with Eq::{equal, not_equal}

///|
pub extend Producer with @debug.Debug::{to_repr}

///|
pub extend Entry with Eq::{equal, not_equal}

///|
pub extend Entry with @debug.Debug::{to_repr}

///|
pub extend Manifest with Eq::{equal, not_equal}

///|
pub extend Manifest with @debug.Debug::{to_repr}

///|
pub extend GalleryPage with Eq::{equal, not_equal}

///|
pub extend GalleryPage with @debug.Debug::{to_repr}

///|
pub extend ArtifactCopy with Eq::{equal, not_equal}

///|
pub extend ArtifactCopy with @debug.Debug::{to_repr}

///|
pub extend GalleryPlan with Eq::{equal, not_equal}

///|
pub extend GalleryPlan with @debug.Debug::{to_repr}
