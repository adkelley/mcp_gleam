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
  let assert Ok(port) = transport.stdio_connect(config)
  let assert Ok(Nil) = transport.stdio_disconnect(port)
}

// Payload =
//     new_request(Id,
//                 <<"tools/call">>,
//                 #{<<"name">> => <<"echo">>,
//                   <<"arguments">> => #{<<"message">> => <<"hello echo!">>}}),
// Transport:send(Conn, Payload),
// {noreply, State#state{pending = P#{Id => From}}};
//
// Payload =
//     new_request(Id,
//                 <<"initialize">>,
//                 #{<<"protocolVersion">> => <<"2025-03-26">>,
//                   <<"capabilities">> => #{},
//                   <<"clientInfo">> =>
//                       #{<<"name">> => <<"Example Client">>, <<"version">> => <<"1.0.0">>}}),
// 

pub fn stdio_notification_test() {
  let config =
    transport.stdio_config()
    |> transport.stdio_command("/opt/homebrew/bin/npx")
    |> transport.stdio_args(["-y", "@modelcontextprotocol/server-everything"])
  let assert Ok(port) = transport.stdio_connect(config)

  let mapper = transport.response_mapper()
  let selector = process.new_selector() |> transport.select_response(mapper)

  let message = process.selector_receive_forever(selector)
  echo message

  let message = process.selector_receive_forever(selector)
  echo message

  let client = client.new_client("stdio_notification", "0.1.0")
  let jsonrpc_request =
    client.initialize(client, types.latest_protocol_version, dict.new())
  let assert Ok(Nil) = transport.send(port, jsonrpc_request)

  let message = process.selector_receive_forever(selector)
  echo message

  // let assert Ok(message) = process.selector_receive(selector, 5000)
  // echo message
  // process.sleep(5000)

  let assert Ok(Nil) = transport.stdio_disconnect(port)
}
