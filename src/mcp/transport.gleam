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

/// Handle for an established connection to an MCP transport.
pub opaque type TransportHandle {
  /// Connection backed by a stdio `Port`.
  Port(Port)
  /// Unique reference used when generating request identifiers.
  RequestId(Reference)
}

/// Raw transport payloads emitted from the underlying Erlang port.
pub type RawTransportResponse {
  RawStdioResponse(#(Port, BitArray))
  RawStdioExit(Port)
  RawStdioOther
}

/// Transport responses decoded into friendly data structures.
pub type TransportResponse {
  StdioResponse(Port, String)
  StdioExit(Port)
  StdioOther
}

/// Configuration builder for opening transport connections.
pub opaque type TransportConfig {
  StdioBuilder(command: String, args: List(String), cwd: Option(String))
  SSEBuilder(uri: String)
}

/// Begin constructing a stdio transport configuration.
pub fn stdio_config() -> TransportConfig {
  StdioBuilder(command: "", args: [], cwd: option.None)
}

/// Begin constructing an SSE transport configuration.
pub fn sse_config() -> TransportConfig {
  SSEBuilder(uri: "")
}

/// Set the command used to spawn an MCP server for stdio transports.
pub fn stdio_command(config: TransportConfig, which: String) -> TransportConfig {
  let assert StdioBuilder(_, _, _) = config
    as "Error: Use transport.sse_uri() for SSE servers"
  StdioBuilder(..config, command: which)
}

/// Set the command-line arguments for a stdio transport.
pub fn stdio_args(
  config: TransportConfig,
  which: List(String),
) -> TransportConfig {
  let assert StdioBuilder(_, _, _) = config
    as "Error: Use transport.sse_uri() for SSE servers"
  StdioBuilder(..config, args: which)
}

/// Set the working directory for a stdio transport.
pub fn stdio_cwd(config: TransportConfig, which: String) -> TransportConfig {
  let assert StdioBuilder(_, _, _) = config
    as "Error: Use transport.sse_uri() for SSE servers"
  StdioBuilder(..config, cwd: option.Some(which))
}

// TODO Shall we run initialize & initilized here?
/// Open a transport connection using the provided configuration.
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

/// Terminate an active transport connection.
pub fn disconnect(handle: TransportHandle) -> Result(Nil, McpError) {
  let assert Port(port) = handle as "Server handle must be stdio"
  stdio.close_port(port)
}

/// Send a JSON-RPC message to the MCP server over the transport.
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
// FFI helper converting raw port messages into transport responses.
fn decode_stream_message(msg: Dynamic) -> RawTransportResponse

/// Build a mapper that converts raw responses into structured transport responses.
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

/// Attach a transport response mapper onto a process selector.
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
