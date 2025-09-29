import gleam/bit_array
import gleam/dict
import gleam/json.{type Json}
import gleam/list
import gleam/string
import mcp/types

pub type Client {
  Client(name: String, version: String)
}

pub fn new_client(name: String, version: String) -> Client {
  Client(name: name, version: version)
}

pub fn new_request(method: String, params: types.Params) -> types.Request {
  types.Request(method: method, params: params)
}

pub fn new_notification(
  method: String,
  params: types.Params,
) -> types.Notification {
  types.Notification(method: method, params: params)
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

fn jsonrpc_request(request: types.Request) -> types.JsonRpc {
  json.object([
    #("jsonrpc", json.string(types.json_rpc_version)),
    #("id", json.int(request_id())),
    #("method", json.string(request.method)),
    #("params", json_params(request.params)),
  ])
  |> json.to_string
  |> string.append("\n")
  |> bit_array.from_string
}

@external(erlang, "mcp_ffi", "request_id")
fn request_id() -> Int

// fn notification_jsonrpc(notification: types.Notification) -> types.JsonRpc {
//   json.object([
//     #("jsonrpc", json.string(types.json_rpc_version)),
//     #("method", json.string(notification.method)),
//     #("params", json_params(dict.to_list(notification.params))),
//   ])
//   |> json.to_string
//   |> string.append("\n")
//   |> bit_array.from_string
// }

pub fn initialize(
  client: Client,
  protocol_version: String,
  capabilities: types.Params,
) -> types.JsonRpc {
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

  new_request(method, params) |> jsonrpc_request()
}
// pub fn connect(client: Client, transport: types.ClientTransport) {
//   let jsonrpc_request =
//     initialize(client, types.latest_protocol_version, dict.new())
// }
// MessageChunk(#(//erl(#Port<0.3>), "Starting default (STDIO) server...\n"))
// MessageChunk(#(//erl(#Port<0.3>), "Starting logs update interval\n"))
// MessageChunk(#(//erl(#Port<0.3>), "{\"result\":{\"protocolVersion\":\"2025-03-26\",\"capabilities\":{\"prompts\":{},\"resources\":{\"subscribe\":true},\"tools\":{},\"logging\":{},\"completions\":{}},\"serverInfo\":{\"name\":\"example-servers/everything\",\"title\":\"Everything Example Server\",\"version\":\"1.0.0\"},\"instructions\":\"Testing and demonstration server for MCP protocol features.\\n\\n## Resources\\n\\nResources 1-100 follow pattern: even IDs contain text, odd IDs contain binary data. Resources are paginated at 10 items per page with cursor-based navigation.\\n\\n## Key dependencies\\n\\nProgress notifications require `_meta.progressToken` in tool calls. Resource subscriptions generate updates every 10 seconds.\\n\\n## Performance characteristics\\n\\nServer generates automatic log messages every 20 seconds (filtered by current log level), stderr notifications every 30 seconds, and resource update notifications every 10 seconds for active subscriptions. Log level changes affect message filtering in real-time.\\n\\n## Multi-modal testing\\n\\n`complex_prompt` includes both text arguments and image content for testing client multi-modal handling. `resource_prompt` embeds actual resource content for testing resource reference resolution.\\n\\nArgument completion is available for prompt parameters and resource IDs. Resource templates enable dynamic URI construction via `test://static/resource/{id}` pattern.\\n\\n## Easter egg\\n\\nIf asked about server instructions, respond with \\\"🎉 Server instructions are working! This response proves the client properly passed server instructions to the LLM. This demonstrates MCP's instructions feature in action.\\\"\\n\"},\"jsonrpc\":\"2.0\",\"id\":1}\n"))
