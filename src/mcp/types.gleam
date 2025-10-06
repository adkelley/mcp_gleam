import gleam/dict.{type Dict}

pub const latest_protocol_version = "2025-06-18"

pub const json_rpc_version = "2.0"

pub type JsonRpc =
  BitArray

pub type JsonData {
  JsonObject(Params)
  JsonString(String)
  JsonInt(Int)
  JsonBool(Bool)
  JsonNil(Nil)
  JsonArray(List(Params))
}

pub type Params =
  Dict(String, JsonData)

// TODO separate these into individual records?
pub type ClientMessage {
  Notification(method: String, params: Params)
  Request(method: String, params: Params)
  // Note method is not used here, purely for uniformity
  Response(method: Nil, id: Int, params: Params)
}
