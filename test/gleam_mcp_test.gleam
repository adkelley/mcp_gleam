import gleam/dict.{type Dict}
import gleam/dynamic/decode.{type Decoder}
import gleam/erlang/process
import gleam/json
import gleam/list
import gleeunit
import mcp/client
import mcp/transport
import mcp/types

/// Run the Gleeunit test suite for the MCP client using the Everything MCP Server
/// 'https://github.com/modelcontextprotocol/servers/blob/main/src/everything/README.md'.
pub fn main() -> Nil {
  gleeunit.main()
}

/// Ensure the stdio transport can connect and disconnect cleanly.
pub fn stdio_open_close_test() {
  let config =
    transport.stdio_config()
    |> transport.stdio_command("npx")
    |> transport.stdio_cwd("/opt/homebrew/bin/")
    |> transport.stdio_args(["-y", "@modelcontextprotocol/server-everything"])
  let assert Ok(port) = transport.connect(config)
  let assert Ok(Nil) = transport.disconnect(port)
}

/// Exercise the echo tool end-to-end over the stdio transport.
pub fn stdio_echo_tool_test() {
  echo "****** Stdio Echo Tool Test ******"
  let config =
    transport.stdio_config()
    |> transport.stdio_command("npx")
    |> transport.stdio_cwd("/opt/homebrew/bin/")
    |> transport.stdio_args(["-y", "@modelcontextprotocol/server-everything"])
  let assert Ok(port) = transport.connect(config)

  let mapper = transport.response_mapper()
  let selector = process.new_selector() |> transport.select_response(mapper)

  // Starting server
  let _message = process.selector_receive_forever(selector)
  // echo message

  // Logs
  let _message = process.selector_receive_forever(selector)
  // echo message

  let assert Ok(Nil) =
    client.configuration("stdio_call_tools", "0.1.0")
    |> client.initialize()
    |> transport.send(port, _)
  let _message = process.selector_receive_forever(selector)
  // echo message

  let assert Ok(Nil) = client.initialized() |> transport.send(port, _)
  let _message = process.selector_receive_forever(selector)

  let assert Ok(Nil) =
    client.call_tool("echo")
    |> client.append_object(
      "arguments",
      "message",
      types.JsonString("Hello Live Coding"),
    )
    |> transport.send(port, _)
  let assert transport.StdioResponse(_port, message) =
    process.selector_receive_forever(selector)

  let assert Ok(content_list) = json.parse(message, content_decoder())
  let assert Ok(content) = list.first(content_list)
  let assert Ok("Echo: Hello Live Coding") = dict.get(content, "text")
  let assert Ok("text") = dict.get(content, "type")
  let assert Ok(Nil) = transport.disconnect(port)
}

/// Exercise the add tool to verify argument handling over stdio.
/// Verify advertised capabilities trigger the roots flow and decoding helpers.
/// Validate resource list/read/subscribe requests round-trip over stdio.
/// Confirm resource template listing works via the stdio transport.
pub fn stdio_add_tool_test() {
  echo "****** Stdio Add Tool Test ******"
  let config =
    transport.stdio_config()
    |> transport.stdio_command("npx")
    |> transport.stdio_cwd("/opt/homebrew/bin/")
    |> transport.stdio_args(["-y", "@modelcontextprotocol/server-everything"])
  let assert Ok(port) = transport.connect(config)

  let mapper = transport.response_mapper()
  let selector = process.new_selector() |> transport.select_response(mapper)

  // Starting server
  let _message = process.selector_receive_forever(selector)
  // echo message

  // Logs
  let _message = process.selector_receive_forever(selector)
  // echo message

  let assert Ok(Nil) =
    client.configuration("stdio_call_tools", "0.1.0")
    |> client.initialize()
    |> transport.send(port, _)
  let _message = process.selector_receive_forever(selector)
  // echo message

  let assert Ok(Nil) = client.initialized() |> transport.send(port, _)
  let _message = process.selector_receive_forever(selector)
  // echo message

  let assert Ok(Nil) =
    client.call_tool("add")
    |> client.append_object("arguments", "a", types.JsonInt(35))
    |> client.append_object("arguments", "b", types.JsonInt(35))
    |> transport.send(port, _)
  let assert transport.StdioResponse(_port, message) =
    process.selector_receive_forever(selector)
  let assert Ok(content_list) = json.parse(message, content_decoder())
  let assert Ok(content) = list.first(content_list)
  let assert Ok("The sum of 35 and 35 is 70.") = dict.get(content, "text")
  let assert Ok("text") = dict.get(content, "type")

  let assert Ok(Nil) = transport.disconnect(port)
}

pub fn stdio_capabilities_test() {
  echo "****** Stdio Capabilities Test ******"
  let config =
    transport.stdio_config()
    |> transport.stdio_command("npx")
    |> transport.stdio_cwd("/opt/homebrew/bin/")
    |> transport.stdio_args(["-y", "@modelcontextprotocol/server-everything"])
  let assert Ok(port) = transport.connect(config)

  let mapper = transport.response_mapper()
  let selector = process.new_selector() |> transport.select_response(mapper)

  // Starting server
  let _message = process.selector_receive_forever(selector)
  // echo message

  // Logs
  let _message = process.selector_receive_forever(selector)
  // echo message

  let assert Ok(Nil) =
    client.configuration("stdio_call_tools", "0.1.0")
    |> client.roots(True)
    |> client.sampling()
    |> client.initialize()
    |> transport.send(port, _)
  let _message = process.selector_receive_forever(selector)
  // echo message

  // Server sends a `roots/list` request
  let assert Ok(Nil) = client.initialized() |> transport.send(port, _)
  let assert transport.StdioResponse(_port, payload) =
    process.selector_receive_forever(selector)

  let assert Ok(#(_method, id)) = json.parse(payload, method_decoder())

  let roots = [#("uri", "file:///cores/my_project"), #("name", "My Project")]
  let assert Ok(Nil) =
    client.list_roots(id, roots)
    |> transport.send(port, _)

  let assert transport.StdioResponse(_, message) =
    process.selector_receive_forever(selector)
  let assert Ok(data) = json.parse(message, data_decoder())
  assert data == "Initial roots received: 1 root(s) from client"
  let assert Ok(Nil) = transport.disconnect(port)
}

pub fn stdio_list_resources_test() {
  echo "****** Stdio List Resources Test ******"
  let config =
    transport.stdio_config()
    |> transport.stdio_command("npx")
    |> transport.stdio_cwd("/opt/homebrew/bin/")
    |> transport.stdio_args(["-y", "@modelcontextprotocol/server-everything"])
  let assert Ok(port) = transport.connect(config)

  let mapper = transport.response_mapper()
  let selector = process.new_selector() |> transport.select_response(mapper)

  // Starting server
  let _message = process.selector_receive_forever(selector)
  // echo message

  // Logs
  let _message = process.selector_receive_forever(selector)
  // echo message

  let assert Ok(Nil) =
    client.configuration("stdio_call_tools", "0.1.0")
    |> client.initialize()
    |> transport.send(port, _)
  let _message = process.selector_receive_forever(selector)
  // echo message

  let assert Ok(Nil) = client.initialized() |> transport.send(port, _)
  let _message = process.selector_receive_forever(selector)
  // echo message

  let assert Ok(Nil) =
    client.list_resources("10")
    |> transport.send(port, _)
  let _message = process.selector_receive_forever(selector)
  // echo message

  let assert Ok(Nil) =
    client.read_resources("test://static/resource/1")
    |> transport.send(port, _)
  let _message = process.selector_receive_forever(selector)
  // echo message

  let assert Ok(Nil) =
    client.subscribe_resources("test://static/resource/1")
    |> transport.send(port, _)
  let assert transport.StdioResponse(_, message) =
    process.selector_receive_forever(selector)
  let assert Ok(create_message) = json.parse(message, messages_decoder())
  assert create_message == "sampling/createMessage"

  let assert Ok(Nil) = transport.disconnect(port)
}

pub fn stdio_templates_resources_test() {
  echo "****** Stdio  Templates Resources Test ******"
  let config =
    transport.stdio_config()
    |> transport.stdio_command("npx")
    |> transport.stdio_cwd("/opt/homebrew/bin/")
    |> transport.stdio_args(["-y", "@modelcontextprotocol/server-everything"])
  let assert Ok(port) = transport.connect(config)

  let mapper = transport.response_mapper()
  let selector = process.new_selector() |> transport.select_response(mapper)

  // Starting server
  let _message = process.selector_receive_forever(selector)
  // echo message

  // Logs
  let _message = process.selector_receive_forever(selector)
  // echo message

  let assert Ok(Nil) =
    client.configuration("stdio_call_tools", "0.1.0")
    |> client.initialize()
    |> transport.send(port, _)
  let _message = process.selector_receive_forever(selector)
  // echo message

  let assert Ok(Nil) = client.initialized() |> transport.send(port, _)
  let _message = process.selector_receive_forever(selector)
  // echo message

  let assert Ok(Nil) =
    client.list_resources_templates()
    |> transport.send(port, _)
  let assert transport.StdioResponse(_port, message) =
    process.selector_receive_forever(selector)
  let assert Ok(_resource_templates) =
    json.parse(message, static_resource_decoder())

  let assert Ok(Nil) = transport.disconnect(port)
}

// region:    --- decoders
// "{\"result\":{\"content\":[{\"type\":\"text\",\"text\":\"Echo: Hello Live Coding\"}]},...")
fn content_decoder() -> Decoder(List(Dict(String, String))) {
  use content <- decode.subfield(
    ["result", "content"],
    decode.list(decode.dict(decode.string, decode.string)),
  )
  decode.success(content)
}

fn method_decoder() -> Decoder(#(String, Int)) {
  use method <- decode.field("method", decode.string)
  use id <- decode.field("id", decode.int)
  decode.success(#(method, id))
}

// "{_, \"params\":{_, \"data\":\"Initial roots received: 1 root(s) from client\"}, _")
fn data_decoder() -> Decoder(String) {
  use data <- decode.subfield(["params", "data"], decode.string)
  decode.success(data)
}

// StdioResponse(_, "{\"method\":\"sampling/createMessage\",
// _, _, _,\"maxTokens\":100, \"temperature\":0.7, ...")
fn messages_decoder() -> Decoder(String) {
  use content <- decode.field("method", decode.string)
  decode.success(content)
}

// StdioResponse(_, "{\"result\":{\"resourceTemplates\":[{\"uriTemplate\":\"test://static/resource/{id}\",
// \"name\":\"Static Resource\",\"description\":\"A static resource with a numeric ID\"}]},...")
fn static_resource_decoder() -> Decoder(List(Dict(String, String))) {
  use resource_templates <- decode.subfield(
    ["result", "resourceTemplates"],
    decode.list(decode.dict(decode.string, decode.string)),
  )
  { decode.success(resource_templates) }
}
// endregion: --- decoders
