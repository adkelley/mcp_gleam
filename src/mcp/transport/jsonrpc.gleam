import gleam/bit_array
import gleam/dict
import gleam/json.{type Json}
import gleam/list
import gleam/string
import mcp/types

pub fn request(request: types.Message) -> types.JsonRpc {
  json.object([
    #("jsonrpc", json.string(types.json_rpc_version)),
    #("id", json.int(request_id())),
    #("method", json.string(request.method)),
    #("params", json_params(request.params)),
  ])
  |> json.to_string
  |> string.append("\n")
  |> echo
  |> bit_array.from_string
}

@external(erlang, "mcp_ffi", "request_id")
fn request_id() -> Int

pub fn notification(notification: types.Message) -> types.JsonRpc {
  json.object([
    #("jsonrpc", json.string(types.json_rpc_version)),
    #("method", json.string(notification.method)),
    #("params", json_params(notification.params)),
  ])
  |> json.to_string
  |> string.append("\n")
  |> echo
  |> bit_array.from_string
}

fn json_params(params: types.Params) -> Json {
  json.object(
    list.map(dict.to_list(params), fn(x) {
      let #(key, value) = x
      case value {
        types.JsonString(v) -> #(key, json.string(v))
        types.JsonObject(v) -> #(key, json_params(v))
        types.JsonInt(v) -> #(key, json.int(v))
      }
    }),
  )
}
