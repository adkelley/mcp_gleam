import gleam/dict
import mcp/types

pub type Client {
  Client(name: String, version: String)
}

pub fn new_client(name: String, version: String) -> Client {
  Client(name: name, version: version)
}

fn new_request(method: String, params: types.Params) -> types.Message {
  types.Request(method: method, params: params)
}

fn new_notification(method: String, params: types.Params) -> types.Message {
  types.Notification(method: method, params: params)
}

pub fn append_argument(
  message: types.Message,
  key: String,
  value: types.JsonData,
) -> types.Message {
  let merge_arguments = fn(
    params: types.Params,
    key: String,
    value: types.JsonData,
  ) {
    let assert Ok(types.JsonObject(args)) = dict.get(params, "arguments")
    dict.new()
    |> dict.insert("arguments", types.JsonObject(dict.insert(args, key, value)))
    |> dict.merge(params, _)
  }

  case message {
    types.Request(method, params) ->
      types.Request(method, params: merge_arguments(params, key, value))
    types.Notification(method, params) ->
      types.Notification(method, params: merge_arguments(params, key, value))
  }
}

pub fn initialize(
  client: Client,
  protocol_version: String,
  capabilities: types.Params,
) -> types.Message {
  let method = "initialize"
  let client_info =
    dict.new()
    |> dict.insert("name", types.JsonString(client.name))
    |> dict.insert("version", types.JsonString(client.version))

  let params =
    dict.new()
    |> dict.insert("protocolVersion", types.JsonString(protocol_version))
    |> dict.insert("capabilities", types.JsonObject(capabilities))
    |> dict.insert("clientInfo", types.JsonObject(client_info))

  new_request(method, params)
}

pub fn initialized() -> types.Message {
  let method = "notifications/initialized"
  new_notification(method, dict.new())
}

pub fn list_tools() -> types.Message {
  let method = "tools/list"
  new_request(method, dict.new())
}

pub fn call_tool(tool_name: String) -> types.Message {
  let method = "tools/call"
  let params =
    dict.new()
    |> dict.insert("name", types.JsonString(tool_name))
    |> dict.insert("arguments", types.JsonObject(dict.new()))
  new_request(method, params)
}
