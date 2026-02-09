import gleam/dynamic/decode
import gleam/erlang/process
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import mcp/client
import mcp/server
import mcp/transport
import mcp/types

/// Run the Gleeunit test suite for the MCP client using the Everything MCP Server
/// 'https://github.com/modelcontextprotocol/servers/blob/main/src/everything/README.md'.
pub fn main() -> Nil {
  gleeunit.main()
}

/// Ensure the stdio transport can connect and disconnect cleanly.
pub fn stdio_open_close_test() {
  echo "****** STDIO Open Close Test ******"
  let config =
    transport.stdio_config()
    |> transport.stdio_command("npx")
    |> transport.stdio_cwd("/opt/homebrew/bin/")
    |> transport.stdio_args(["-y", "@modelcontextprotocol/server-everything"])
  let assert Ok(port) = transport.connect(config)
  let assert Ok(Nil) = transport.disconnect(port)
}

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

  let assert Ok(Nil) =
    client.configuration("stdio_call_tools", "0.1.0")
    |> client.initialize()
    |> transport.send(port, _)

  let _message = process.selector_receive_forever(selector)
  // echo message

  let assert Ok(Nil) = client.initialized() |> transport.send(port, _)
  let _message = process.selector_receive_forever(selector)
  // echo message

  let assert Ok(Nil) = client.list_tools() |> transport.send(port, _)
  let assert transport.StdioResponse(_, message) =
    process.selector_receive_forever(selector)
  // echo message
  let assert Ok(tools) = json.parse(message, server.result_tools_decoder())
  // echo tools

  let assert Ok(_echo_tool) = list.find(tools, fn(tool) { tool.name == "echo" })

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
  // echo message

  let assert Ok(result) = json.parse(message, server.call_tool_result_decoder())
  // echo result
  let assert Ok(content) = list.first(result.content)
  assert content.text == "Echo: Hello Live Coding"
  let assert Ok(Nil) = transport.disconnect(port)
}

pub fn server_initialized_test() {
  echo "****** Server Initialized Test ******"
  let config =
    transport.stdio_config()
    |> transport.stdio_command("npx")
    |> transport.stdio_cwd("/opt/homebrew/bin/")
    |> transport.stdio_args(["-y", "@modelcontextprotocol/server-everything"])
  let assert Ok(port) = transport.connect(config)

  let mapper = transport.response_mapper()
  let selector = process.new_selector() |> transport.select_response(mapper)

  // Starting default (STDIO) server...\n
  let _message = process.selector_receive_forever(selector)
  // echo message

  // Send an initialize request to server
  let assert Ok(Nil) =
    client.configuration("stdio_call_tools", "0.1.0")
    |> client.initialize()
    |> transport.send(port, _)

  // After receiving an initialize request from the client, the server sends
  // this response.
  let assert transport.StdioResponse(_port, message) =
    process.selector_receive_forever(selector)
  let assert Ok(_configuration) =
    json.parse(message, server.result_configuration_decoder())

  // echo configuration

  let assert Ok(Nil) = transport.disconnect(port)
}

/// Exercise the add tool to verify argument handling over stdio.
/// Verify advertised capabilities trigger the roots flow and decoding helpers.
/// Validate resource list/read/subscribe requests round-trip over stdio.
/// Confirm resource template listing works via the stdio transport.
pub fn stdio_get_sum_tool_test() {
  echo "****** Stdio Get Sum Tool Test ******"
  let config =
    transport.stdio_config()
    |> transport.stdio_command("npx")
    |> transport.stdio_cwd("/opt/homebrew/bin/")
    |> transport.stdio_args(["-y", "@modelcontextprotocol/server-everything"])
  let assert Ok(port) = transport.connect(config)

  let mapper = transport.response_mapper()
  let selector = process.new_selector() |> transport.select_response(mapper)

  // Starting default (STDIO) server ...
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

  let assert Ok(Nil) = client.list_tools() |> transport.send(port, _)
  let assert transport.StdioResponse(_port, message) =
    process.selector_receive_forever(selector)
  let assert Ok(tools) = json.parse(message, server.result_tools_decoder())
  let assert Ok(_tool) = list.find(tools, fn(tool) { tool.name == "get-sum" })

  let assert Ok(Nil) =
    client.call_tool("get-sum")
    |> client.append_object("arguments", "a", types.JsonInt(35))
    |> client.append_object("arguments", "b", types.JsonInt(35))
    |> transport.send(port, _)
  let assert transport.StdioResponse(_port, message) =
    process.selector_receive_forever(selector)
  let assert Ok(result) = json.parse(message, server.call_tool_result_decoder())
  let assert Ok(content) = list.first(result.content)
  assert content.text == "The sum of 35 and 35 is 70."

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

  // Starting default (STDIO) server ...
  let _message = process.selector_receive_forever(selector)
  // echo message

  // Client initiates the initialize phase by sending an initialize request
  // containing
  // - Protocol version supported
  // - Client capabilities
  // - Client implementation information
  let assert Ok(Nil) =
    client.configuration("stdio_call_tools", "0.1.0")
    |> client.roots(True)
    // |> client.sampling()
    |> client.initialize()
    |> transport.send(port, _)

  // Server responds with it's own capabilities
  let _message = process.selector_receive_forever(selector)
  // echo message

  let assert Ok(Nil) = client.initialized() |> transport.send(port, _)

  // Server will send 2 list_changed notifications
  // TODO why? Is this repeatable or let over from previous tests?
  let assert transport.StdioResponse(_, message) =
    process.selector_receive_forever(selector)
  let assert Ok(server_message) =
    json.parse(message, server.notifications_decoder())
  assert server_message.method == "notifications/tools/list_changed"
  let assert transport.StdioResponse(_, message) =
    process.selector_receive_forever(selector)
  let assert Ok(server_message) =
    json.parse(message, server.notifications_decoder())
  assert server_message.method == "notifications/tools/list_changed"
  // Server sends a roots/list request
  let assert transport.StdioResponse(_, message) =
    process.selector_receive_forever(selector)
  // echo message
  let assert Ok(request) =
    json.parse(message, server.list_roots_request_decoder())
  // echo request

  let roots = [#("uri", "file:///cores/my_project"), #("name", "My Project")]
  let assert Ok(Nil) =
    client.list_roots_result(request.id, roots, None)
    |> transport.send(port, _)

  let assert transport.StdioResponse(_, message) =
    process.selector_receive_forever(selector)
  // echo message
  let assert Ok(notification) =
    json.parse(message, server.notifications_decoder())
  let data_decoder = fn() {
    use data <- decode.field("data", decode.string)
    decode.success(data)
  }
  let assert Ok(data) = case notification.params {
    Some(params) -> {
      decode.run(params, data_decoder())
    }
    None -> panic as "data not found"
  }
  assert data == "Roots updated: 1 root(s) received from client"

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
    client.list_resources_request("10")
    |> transport.send(port, _)
  let assert transport.StdioResponse(_, message) =
    process.selector_receive_forever(selector)
  // echo message

  let assert Ok(result) =
    json.parse(message, server.list_resources_result_decoder())
  let assert Ok(resource) = list.first(result.resources)
  // echo resource

  let assert Ok(Nil) =
    client.read_resource_request(resource.uri)
    |> transport.send(port, _)
  let assert transport.StdioResponse(_, message) =
    process.selector_receive_forever(selector)
  // echo message
  let assert Ok(_result) =
    json.parse(message, server.read_resource_result_decoder())
  // echo result

  let assert Ok(Nil) =
    client.subscribe_resources(resource.uri)
    |> transport.send(port, _)

  // Server notifies client of subscribe resource request
  // by sending both a notification and an empty result
  let assert transport.StdioResponse(_, message) =
    process.selector_receive_forever(selector)
  let assert Ok(#(msg1, _result)) = string.split_once(message, "\n")

  let assert Ok(_server_msg) = json.parse(msg1, server.notifications_decoder())
  // echo _server_msg

  let assert Ok(Nil) = transport.disconnect(port)
}

pub fn stdio_resource_templates_test() {
  echo "****** Stdio  Resource Templates Test ******"
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
    client.list_resources_templates_request()
    |> transport.send(port, _)
  let assert transport.StdioResponse(_port, message) =
    process.selector_receive_forever(selector)
  // echo message
  let assert Ok(_result) =
    json.parse(message, server.list_resource_templates_result_decoder())
  // echo result

  let assert Ok(Nil) = transport.disconnect(port)
}
