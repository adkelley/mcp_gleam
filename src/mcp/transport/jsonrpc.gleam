import gleam/bit_array
import gleam/dict
import gleam/json.{type Json}
import gleam/list
import gleam/string
import mcp/types

/// Encode a JSON-RPC request message from a client message.
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
  |> echo
  |> bit_array.from_string
}

@external(erlang, "mcp_ffi", "request_id")
// FFI helper returning the next JSON-RPC request identifier.
fn request_id() -> Int

/// Encode a JSON-RPC notification message from a client message.
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

/// Encode a JSON-RPC response message from a client message.
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

// Convert typed parameters to their JSON representation.
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
