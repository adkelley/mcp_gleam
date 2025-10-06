import gleam/bit_array
import gleam/dict
import gleam/json.{type Json}
import gleam/list
import gleam/string
import mcp/types

pub fn request(request: types.ClientMessage) -> types.JsonRpc {
  let assert types.Request(method, params) = request
  json.object([
    #("jsonrpc", json.string(types.json_rpc_version)),
    #("id", json.int(request_id())),
    #("method", json.string(method)),
    #("params", json_params(params)),
  ])
  |> json.to_string
  |> string.append("\n")
  |> bit_array.from_string
}

@external(erlang, "mcp_ffi", "request_id")
fn request_id() -> Int

pub fn notification(notification: types.ClientMessage) -> types.JsonRpc {
  let assert types.Notification(method, params) = notification
  json.object([
    #("jsonrpc", json.string(types.json_rpc_version)),
    #("method", json.string(method)),
    #("params", json_params(params)),
  ])
  |> json.to_string
  |> string.append("\n")
  |> bit_array.from_string
}

pub fn response(response: types.ClientMessage) -> types.JsonRpc {
  let assert types.Response(_method, id, params) = response
  json.object([
    #("jsonrpc", json.string(types.json_rpc_version)),
    #("id", json.int(id)),
    #("result", json_params(params)),
  ])
  |> json.to_string
  |> string.append("\n")
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
        types.JsonBool(v) -> #(key, json.bool(v))
        types.JsonNil(_) -> #(key, json.null())
        types.JsonArray(v) -> #(key, json.array(v, fn(a) { json_params(a) }))
      }
    }),
  )
}
