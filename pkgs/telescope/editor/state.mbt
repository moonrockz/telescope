///|
struct Snapshot {
  text : String
  selection : Selection
}

///|
/// Independent state for one document. Replacement clears history and advances
/// the generation even when the new text is identical.
pub struct DocumentState {
  mut document : Document
  mut selection : Selection
  mut revision : Int32
  mut generation : Int32
  undo_stack : Array[Snapshot]
  redo_stack : Array[Snapshot]
}

///|
pub fn DocumentState::new(document : Document) -> DocumentState {
  {
    document,
    selection: { anchor: 0, head: 0, },
    revision: 0,
    generation: 0,
    undo_stack: [],
    redo_stack: [],
  }
}

///|
pub fn DocumentState::document(self : DocumentState) -> Document {
  self.document
}

///|
pub fn DocumentState::selection(self : DocumentState) -> Selection {
  self.selection
}

///|
pub fn DocumentState::revision(self : DocumentState) -> Int32 {
  self.revision
}

///|
pub fn DocumentState::generation(self : DocumentState) -> Int32 {
  self.generation
}

///|
pub fn DocumentState::set_selection(
  self : DocumentState,
  selection : Selection,
) -> Unit {
  let limit = self.document.text.length()
  self.selection = {
    anchor: Int32::max(0, Int32::min(limit, selection.anchor)),
    head: Int32::max(0, Int32::min(limit, selection.head)),
  }
}

///|
/// Returns whether a normal content change occurred. Unchanged formatting is a
/// no-op, including selection and undo history.
pub fn DocumentState::edit(self : DocumentState, text : String) -> Bool {
  if text == self.document.text {
    return false
  }
  self.undo_stack.push({ text: self.document.text, selection: self.selection, })
  self.redo_stack.clear()
  self.document = { ..self.document, text, }
  self.revision += 1
  self.set_selection(self.selection)
  true
}

///|
pub fn DocumentState::undo(self : DocumentState) -> Bool {
  guard self.undo_stack.pop() is Some(previous) else { return false }
  self.redo_stack.push({ text: self.document.text, selection: self.selection, })
  self.document = { ..self.document, text: previous.text, }
  self.selection = previous.selection
  self.revision += 1
  true
}

///|
pub fn DocumentState::redo(self : DocumentState) -> Bool {
  guard self.redo_stack.pop() is Some(next) else { return false }
  self.undo_stack.push({ text: self.document.text, selection: self.selection, })
  self.document = { ..self.document, text: next.text, }
  self.selection = next.selection
  self.revision += 1
  true
}

///|
pub fn DocumentState::replace(
  self : DocumentState,
  document : Document,
) -> Unit {
  self.document = document
  self.selection = { anchor: 0, head: 0, }
  self.revision += 1
  self.generation += 1
  self.undo_stack.clear()
  self.redo_stack.clear()
}

///|
/// Changes highlighting without touching document text, selection or history.
pub fn DocumentState::set_language(
  self : DocumentState,
  language : String,
) -> Unit {
  self.document = { ..self.document, language, }
  self.generation += 1
  self.revision += 1
}

///|
/// A request may update its originating document after tab switches, but only
/// while every captured input is current.
pub fn request_is_current(
  request : FormatRequest,
  instance : String,
  generation : Int32,
  formatter : FormatterRegistration,
  documents : Array[DocumentState],
) -> Bool {
  let input_ids = [request.input.target.id] +
    request.input.context.map(document => document.id)
  let captured_ids = request.revisions.map(input => input.id)
  let seen : Map[String, Bool] = Map([])
  for id in captured_ids {
    if seen.contains(id) {
      return false
    }
    seen[id] = true
  }
  request.input.target.id == request.target &&
  input_ids.length() == captured_ids.length() &&
  input_ids.all(id => captured_ids.contains(id)) &&
  request.contract_version == contract_version &&
  request.instance == instance &&
  request.generation == generation &&
  request.formatter == formatter.id &&
  request.formatter_version == formatter.formatter_version &&
  request.revisions.all(input => {
    documents.any(document => {
      document.document.id == input.id && document.revision == input.revision
    })
  })
}
