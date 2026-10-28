///|
/// Pure scheduling state. The host supplies clocks, transport and storage.
pub(all) struct State {
  mut generation : Int32
  mut next_id : Int32
  mut revision : String
  mut active : @tutorial.Request?
  mut pending : Bool
  mut retries : Int32
  mut requested_position : Int32
  mut session : String?
  mut status : String
  mut disposed : Bool
}

///|
pub fn State::new(revision : String) -> State {
  {
    generation: 1,
    next_id: 0,
    revision,
    active: None,
    pending: true,
    retries: 0,
    requested_position: 0,
    session: None,
    status: "pending",
    disposed: false,
  }
}

///|
pub fn State::edit(self : State, revision : String) -> Unit {
  if self.disposed || self.revision == revision {
    return
  }
  self.revision = revision
  self.pending = true
  self.retries = 0
  self.session = None
  self.status = "pending"
}

///|
pub fn State::request(
  self : State,
  provider : @tutorial.Provider,
  operation : String,
  files : Array[@tutorial.File],
  options : Json,
) -> @tutorial.Request? {
  if self.disposed || self.active is Some(_) || !self.pending {
    return None
  }
  self.next_id += 1
  let request : @tutorial.Request = {
    contract_version: 1,
    provider: provider.id,
    engine_version: provider.engine_version,
    generation: self.generation,
    request_id: self.next_id,
    input_revision: self.revision,
    operation,
    files,
    options,
    session: self.session,
    position: Some(self.requested_position),
  }
  self.active = Some(request)
  self.pending = false
  self.status = "pending"
  Some(request)
}

///|
pub fn State::receive(self : State, response : @tutorial.Response) -> Bool {
  guard !self.disposed && self.active is Some(request) else { return false }
  if response.generation != request.generation ||
    response.request_id != request.request_id {
    return false
  }
  self.active = None
  if self.revision != request.input_revision {
    self.pending = true
    return false
  }
  let errors = @tutorial.response_problems(request, response)
  if !errors.is_empty() {
    self.status = "error"
    return false
  }
  self.status = response.status
  self.session = response.steps.map(steps => steps.session)
  true
}

///|
/// A timeout starts a new runtime and retries a current revision only once.
pub fn State::timeout(self : State) -> Bool {
  guard !self.disposed && self.active is Some(request) else { return false }
  self.active = None
  self.generation += 1
  self.session = None
  if request.input_revision != self.revision {
    self.pending = true
    return true
  }
  if self.retries == 0 {
    self.retries = 1
    self.pending = true
    return true
  }
  self.pending = false
  self.status = "timeout"
  false
}

///|
pub fn State::reset(self : State, revision : String) -> Unit {
  self.generation += 1
  self.active = None
  self.revision = revision
  self.pending = true
  self.retries = 0
  self.requested_position = 0
  self.session = None
  self.status = "pending"
}

///|
pub fn State::dispose(self : State) -> Unit {
  self.disposed = true
  self.generation += 1
  self.active = None
  self.pending = false
}

///|
/// Tutorials translate ordinary editor changes; the editor owns document history.
pub fn documents(files : Array[@tutorial.File]) -> Array[@editor.Document] {
  files.map(file => {
    id: file.name,
    name: file.name,
    text: file.text,
    language: file.language,
  })
}
