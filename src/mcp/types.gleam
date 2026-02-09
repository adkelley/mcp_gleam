import gleam/dict.{type Dict}

/// Latest MCP protocol version this client targets by default.
pub const latest_protocol_version = "2025-11-25"

/// JSON-RPC version string emitted in transport messages.
pub const json_rpc_version = "2.0"

/// Binary encoded JSON-RPC payload.
pub type JsonRpc =
  BitArray

/// Structured representation of JSON payload values used by the client.
pub type JsonData {
  JsonObject(Params)
  JsonString(String)
  JsonInt(Int)
  JsonBool(Bool)
  JsonNil(Nil)
  JsonArray(List(Params))
}

/// JSON object wrapper mapping string keys to JSON data.
pub type Params =
  Dict(String, JsonData)

// TODO separate these into individual records?
/// All JSON-RPC messages the client can emit.
pub type ClientMessage {
  Notification(method: String, params: Params)
  Request(method: String, params: Params)
  // Note method is not used here, purely for uniformity
  Response(method: Nil, id: Int, params: Params)
}
