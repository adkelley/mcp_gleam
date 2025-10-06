import gleam/dynamic/decode
import gleam/erlang/process
import gleam/json
import gleeunit
import mcp/client
import mcp/transport
import mcp/types

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn stdio_open_close_test() {
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
  let message = process.selector_receive_forever(selector)
  echo message

  // Logs
  let message = process.selector_receive_forever(selector)
  echo message

  let assert Ok(Nil) =
    client.configuration("stdio_call_tools", "0.1.0")
    |> client.initialize()
    |> transport.send(port, _)
  echo process.selector_receive_forever(selector)

  let assert Ok(Nil) = client.initialized() |> transport.send(port, _)
  echo process.selector_receive_forever(selector)

  let assert Ok(Nil) = client.list_tools() |> transport.send(port, _)
  echo process.selector_receive_forever(selector)

  let assert Ok(Nil) =
    client.call_tool("echo")
    |> client.append_object(
      "arguments",
      "message",
      types.JsonString("Hello Live Coding"),
    )
    |> transport.send(port, _)
  echo process.selector_receive_forever(selector)

  let assert Ok(Nil) = transport.disconnect(port)
}

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
  let message = process.selector_receive_forever(selector)
  echo message

  // Logs
  let message = process.selector_receive_forever(selector)
  echo message

  let assert Ok(Nil) =
    client.configuration("stdio_call_tools", "0.1.0")
    |> client.initialize()
    |> transport.send(port, _)
  echo process.selector_receive_forever(selector)

  let assert Ok(Nil) = client.initialized() |> transport.send(port, _)
  echo process.selector_receive_forever(selector)

  let assert Ok(Nil) =
    client.call_tool("add")
    |> client.append_object("arguments", "a", types.JsonInt(35))
    |> client.append_object("arguments", "b", types.JsonInt(35))
    |> transport.send(port, _)
  echo process.selector_receive_forever(selector)

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
  let message = process.selector_receive_forever(selector)
  echo message

  // Logs
  let message = process.selector_receive_forever(selector)
  echo message

  let assert Ok(Nil) =
    client.configuration("stdio_call_tools", "0.1.0")
    |> client.roots(True)
    |> client.sampling()
    |> client.initialize()
    |> transport.send(port, _)
  echo process.selector_receive_forever(selector)

  // Server sends a `roots/list` request
  let assert Ok(Nil) = client.initialized() |> transport.send(port, _)
  let assert transport.StdioResponse(_port, payload) =
    process.selector_receive_forever(selector)
  echo payload

  let decoder = fn() {
    use method <- decode.field("method", decode.string)
    use id <- decode.field("id", decode.int)
    decode.success(#(method, id))
  }
  let assert Ok(#(_method, id)) = json.parse(payload, decoder())
  let roots = [#("uri", "file:///cores/my_project"), #("name", "My Project")]
  let assert Ok(Nil) =
    client.list_roots(id, roots)
    |> transport.send(port, _)
  echo process.selector_receive_forever(selector)

  // Sampling test

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
  let message = process.selector_receive_forever(selector)
  echo message

  // Logs
  let message = process.selector_receive_forever(selector)
  echo message

  let assert Ok(Nil) =
    client.configuration("stdio_call_tools", "0.1.0")
    |> client.initialize()
    |> transport.send(port, _)
  echo process.selector_receive_forever(selector)

  let assert Ok(Nil) = client.initialized() |> transport.send(port, _)
  echo process.selector_receive_forever(selector)

  let assert Ok(Nil) =
    client.list_resources("10")
    |> transport.send(port, _)
  echo process.selector_receive_forever(selector)

  let assert Ok(Nil) =
    client.read_resources("test://static/resource/1")
    |> transport.send(port, _)
  echo process.selector_receive_forever(selector)

  let assert Ok(Nil) =
    client.subscribe_resources("test://static/resource/1")
    |> transport.send(port, _)
  echo process.selector_receive_forever(selector)

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
  let message = process.selector_receive_forever(selector)
  echo message

  // Logs
  let message = process.selector_receive_forever(selector)
  echo message

  let assert Ok(Nil) =
    client.configuration("stdio_call_tools", "0.1.0")
    |> client.initialize()
    |> transport.send(port, _)
  echo process.selector_receive_forever(selector)

  let assert Ok(Nil) = client.initialized() |> transport.send(port, _)
  echo process.selector_receive_forever(selector)

  let assert Ok(Nil) =
    client.list_resources_templates()
    |> transport.send(port, _)
  echo process.selector_receive_forever(selector)

  let assert Ok(Nil) = transport.disconnect(port)
}
