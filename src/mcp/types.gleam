import gleam/dict.{type Dict}

pub const latest_protocol_version = "2025-06-18"

pub const json_rpc_version = "2.0"

pub type JsonRpc =
  BitArray

pub type JsonData {
  JsonObject(Params)
  JsonString(String)
  JsonInt(Int)
}

pub type Params =
  Dict(String, JsonData)

pub type Message {
  Notification(method: String, params: Params)
  Request(method: String, params: Params)
}
