import gleam/bit_array
import gleam/dynamic.{type Dynamic}
import gleam/erlang/port.{type Port}
import gleam/erlang/process
import gleam/erlang/reference.{type Reference}
import gleam/list
import gleam/option.{type Option}
import gleam/result

import mcp/error.{type McpError}
import mcp/transport/jsonrpc
import mcp/transport/stdio
import mcp/types

pub opaque type TransportHandle {
  /// Stdio
  Port(Port)
  RequestId(Reference)
}

/// SSE
pub type RawTransportResponse {
  RawStdioResponse(#(Port, BitArray))
  RawStdioExit(Port)
  RawStdioOther
}

pub type TransportResponse {
  StdioResponse(Port, String)
  StdioExit(Port)
  StdioOther
}

pub opaque type TransportConfig {
  StdioBuilder(command: String, args: List(String), cwd: Option(String))
  SSEBuilder(uri: String)
}

pub fn stdio_config() -> TransportConfig {
  StdioBuilder(command: "", args: [], cwd: option.None)
}

pub fn sse_config() -> TransportConfig {
  SSEBuilder(uri: "")
}

pub fn stdio_command(config: TransportConfig, which: String) -> TransportConfig {
  let assert StdioBuilder(_, _, _) = config
    as "Error: Use transport.sse_uri() for SSE servers"
  StdioBuilder(..config, command: which)
}

pub fn stdio_args(
  config: TransportConfig,
  which: List(String),
) -> TransportConfig {
  let assert StdioBuilder(_, _, _) = config
    as "Error: Use transport.sse_uri() for SSE servers"
  StdioBuilder(..config, args: which)
}

pub fn stdio_cwd(config: TransportConfig, which: String) -> TransportConfig {
  let assert StdioBuilder(_, _, _) = config
    as "Error: Use transport.sse_uri() for SSE servers"
  StdioBuilder(..config, cwd: option.Some(which))
}

// TODO Shall we run initialize & initilized here?
pub fn connect(config: TransportConfig) -> Result(TransportHandle, McpError) {
  let assert StdioBuilder(_, _, _) = config
    as "Error: SSE transport is currently unsupported "
  let command =
    case config.cwd {
      option.Some(cwd) -> cwd
      option.None -> ""
    }
    <> config.command
    <> list.fold(config.args, "", fn(acc, arg) { acc <> " " <> arg })
  use port <- result.try(
    stdio.open_port(command)
    |> fn(res) {
      case res {
        Error(e) -> Error(e)
        Ok(port) -> Ok(Port(port))
      }
    },
  )
  Ok(port)
}

pub fn disconnect(handle: TransportHandle) -> Result(Nil, McpError) {
  let assert Port(port) = handle as "Server handle must be stdio"
  stdio.close_port(port)
}

/// Send a jsonrpc message to the MCP server
pub fn send(
  handle: TransportHandle,
  message: types.ClientMessage,
) -> Result(Nil, McpError) {
  let assert Port(port) = handle
    as "Error: SSE transport is currently unsupported "

  case message {
    types.Request(_method, _params) -> jsonrpc.request(message)
    types.Notification(_method, _params) -> jsonrpc.notification(message)
    types.Response(_method, _id, _params) -> jsonrpc.response(message)
  }
  |> stdio.send(port, _)
}

@external(erlang, "mcp_ffi", "coerce_message")
fn decode_stream_message(msg: Dynamic) -> RawTransportResponse

pub fn response_mapper() -> fn(RawTransportResponse) -> TransportResponse {
  fn(msg: RawTransportResponse) {
    case msg {
      RawStdioResponse(#(port, payload)) -> {
        let assert Ok(payload_) = bit_array.to_string(payload)
        StdioResponse(port, payload_)
      }
      RawStdioExit(port) -> StdioExit(port)
      RawStdioOther -> StdioOther
    }
  }
}

pub fn select_response(
  selector: process.Selector(t),
  mapper: fn(RawTransportResponse) -> t,
) -> process.Selector(t) {
  let map_stream_message = fn(mapper) {
    fn(message) { mapper(decode_stream_message(message)) }
  }

  selector
  |> process.select_other(map_stream_message(mapper))
}
