///|
extern "js" fn install_handler(handler : (String) -> String) -> Unit =
  #| handler => { self.onmessage = event => { self.postMessage(JSON.parse(handler(JSON.stringify(event.data)))); }; }

///|
/// Call once from a consumer's worker main. Compile and bundle that worker and
/// register its prebuilt assets with the general editor.
pub fn[F : @editor.Formatter] install_formatter(formatter : F) -> Unit {
  install_handler(encoded => {
    let request = @json.parse(encoded) catch {
      _ =>
        return Json::object({
          "error": { "code": "protocol", "message": "invalid JSON" },
        }).stringify()
    }
    @editor.formatter_reply(formatter, request).stringify()
  })
}
