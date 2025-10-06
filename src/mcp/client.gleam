import gleam/dict
import gleam/list
import gleam/string
import mcp/types

pub opaque type Client {
  Builder(
    name: String,
    version: String,
    protocol_version: String,
    capabilities: types.Params,
  )
}

/// Default client configuration
/// 
pub fn configuration(name: String, version: String) -> Client {
  Builder(
    name: name,
    version: version,
    capabilities: dict.new(),
    protocol_version: types.latest_protocol_version,
  )
}

pub fn roots(client: Client, list_changed: Bool) -> Client {
  let roots =
    dict.new()
    |> dict.insert(
      "roots",
      types.JsonObject(
        dict.new() |> dict.insert("listChanged", types.JsonBool(list_changed)),
      ),
    )
  Builder(..client, capabilities: dict.merge(client.capabilities, roots))
}

pub fn sampling(client: Client) -> Client {
  let sampling =
    dict.new() |> dict.insert("sampling", types.JsonObject(dict.new()))
  Builder(..client, capabilities: dict.merge(client.capabilities, sampling))
}

pub fn new_request(method: String) -> types.ClientMessage {
  types.Request(method: method, params: dict.new())
}

pub fn append_object(
  message: types.ClientMessage,
  parent_key: String,
  key: String,
  value: types.JsonData,
) -> types.ClientMessage {
  case message {
    types.Request(method, params) ->
      types.Request(
        method,
        params: merge_objects(params, parent_key, key, value),
      )
    types.Notification(method, params) ->
      types.Notification(
        method,
        params: merge_objects(params, parent_key, key, value),
      )
    types.Response(method, id, params) ->
      types.Response(method, id, merge_objects(params, parent_key, key, value))
  }
}

fn merge_objects(
  params: types.Params,
  parent_key: String,
  key: String,
  value: types.JsonData,
) -> types.Params {
  case dict.get(params, parent_key) {
    Ok(types.JsonObject(obj)) -> {
      dict.new()
      |> dict.insert(parent_key, types.JsonObject(dict.insert(obj, key, value)))
      |> dict.merge(params, _)
    }
    Error(_) -> dict.new() |> dict.insert(key, value)
    _ -> panic
  }
  // let assert Ok(types.JsonObject(obj)) = dict.get(params, parent_key)
  //   as "Error: arguments object is missing, aborting append_argument"
  // dict.new()
  // |> dict.insert(parent_key, types.JsonObject(dict.insert(obj, key, value)))
  // |> dict.merge(params, _)
}

pub fn initialize(client client: Client) -> types.ClientMessage {
  let method = "initialize"
  let client_info =
    dict.new()
    |> dict.insert("name", types.JsonString(client.name))
    |> dict.insert("version", types.JsonString(client.version))

  let params =
    dict.new()
    |> dict.insert("protocolVersion", types.JsonString(client.protocol_version))
    |> dict.insert("clientInfo", types.JsonObject(client_info))
    |> dict.insert("capabilities", types.JsonObject(client.capabilities))

  types.Request(method: method, params: params)
}

pub fn initialized() -> types.ClientMessage {
  types.Notification("notifications/initialized", dict.new())
}

pub fn list_tools() -> types.ClientMessage {
  let params = dict.new() |> dict.insert("params", types.JsonObject(dict.new()))
  types.Request(method: "tools/list", params: params)
}

pub fn call_tool(tool_name: String) -> types.ClientMessage {
  let method = "tools/call"
  let params =
    dict.new()
    |> dict.insert("name", types.JsonString(tool_name))
    |> dict.insert("arguments", types.JsonObject(dict.new()))
  types.Request(method: method, params: params)
}

pub fn list_roots(
  id: Int,
  roots: List(#(String, String)),
) -> types.ClientMessage {
  let roots =
    dict.new()
    |> dict.insert(
      "roots",
      types.JsonArray([
        list.fold(roots, dict.new(), fn(acc, t) {
          dict.insert(acc, t.0, types.JsonString(t.1))
        }),
      ]),
    )
  types.Response(method: Nil, id: id, params: roots)
}

pub fn list_resources(cursor_value: String) -> types.ClientMessage {
  let params = case string.is_empty(cursor_value) {
    False ->
      dict.new()
      |> dict.insert("cursor", types.JsonString(cursor_value))
    True -> dict.new()
  }
  types.Request(method: "resources/list", params: params)
}

pub fn read_resources(uri: String) -> types.ClientMessage {
  let params = dict.new() |> dict.insert("uri", types.JsonString(uri))
  types.Request(method: "resources/read", params: params)
}

pub fn subscribe_resources(uri: String) -> types.ClientMessage {
  let params = dict.new() |> dict.insert("uri", types.JsonString(uri))
  types.Request(method: "resources/subscribe", params: params)
}

pub fn list_resources_templates() -> types.ClientMessage {
  types.Request(method: "resources/templates/list", params: dict.new())
}
