import gleam/dict
import gleam/erlang/process
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
    |> transport.stdio_command("/opt/homebrew/bin/npx")
    |> transport.stdio_args(["-y", "@modelcontextprotocol/server-everything"])
  let assert Ok(port) = transport.connect(config)
  let assert Ok(Nil) = transport.disconnect(port)
}

pub fn stdio_call_tool_test() {
  let config =
    transport.stdio_config()
    |> transport.stdio_command("npx")
    |> transport.stdio_cwd("/opt/homebrew/bin/")
    |> transport.stdio_args(["-y", "@modelcontextprotocol/server-everything"])
  let assert Ok(port) = transport.connect(config)

  let mapper = transport.response_mapper()
  let selector = process.new_selector() |> transport.select_response(mapper)

  let message = process.selector_receive_forever(selector)
  echo message

  let message = process.selector_receive_forever(selector)
  echo message

  let assert Ok(Nil) =
    client.new_client("stdio_notification", "0.1.0")
    |> client.initialize(types.latest_protocol_version, dict.new())
    |> transport.send(port, _)
  echo process.selector_receive_forever(selector)

  let assert Ok(Nil) = client.initialized() |> transport.send(port, _)
  echo process.selector_receive_forever(selector)

  let assert Ok(Nil) = client.list_tools() |> transport.send(port, _)
  echo process.selector_receive_forever(selector)

  let assert Ok(Nil) =
    client.call_tool("echo")
    |> client.append_argument("message", types.JsonString("Hello Live Coding"))
    |> transport.send(port, _)
  echo process.selector_receive_forever(selector)

  let assert Ok(Nil) = transport.disconnect(port)
}
