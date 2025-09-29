import gleam/dynamic.{type Dynamic}
import gleam/erlang/port.{type Port}
import gleam/erlang/process
import gleam/erlang/reference.{type Reference}
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/string
import mcp/error.{type McpError}
import mcp/transport/stdio

pub opaque type TransportHandle {
  /// Stdio
  Port(Port)
  /// SSE
  RequestId(Reference)
}

pub type TransportResponse {
  StdioResponse(Port, BitArray)
  StdioExitResponse(Port)
  StdioOtherResponse
}

pub opaque type StdioTransportConfig {
  Builder(command: String, args: List(String), cwd: Option(String))
}

pub fn stdio_config() -> StdioTransportConfig {
  Builder(command: "", args: [], cwd: option.None)
}

pub fn stdio_command(
  config: StdioTransportConfig,
  which: String,
) -> StdioTransportConfig {
  Builder(..config, command: which)
}

pub fn stdio_args(
  config: StdioTransportConfig,
  which: List(String),
) -> StdioTransportConfig {
  Builder(..config, args: which)
}

pub fn stdio_connect(
  config: StdioTransportConfig,
) -> Result(TransportHandle, McpError) {
  let assert False = string.is_empty(config.command)
    as "Server command cannot be empty"
  let command =
    config.command
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

pub fn stdio_disconnect(handle: TransportHandle) -> Result(Nil, McpError) {
  let assert Port(port) = handle as "Server handle must be stdio"
  stdio.close_port(port)
}

/// Send a message to the MCP server
pub fn send(handle: TransportHandle, message: BitArray) -> Result(Nil, McpError) {
  case handle {
    Port(port) -> stdio.send(port, message)
    RequestId(_) -> Error(error.UnSupportedOption)
  }
}

@external(erlang, "mcp_ffi", "coerce_message")
fn decode_stream_message(msg: Dynamic) -> TransportResponse

pub fn response_mapper() -> fn(TransportResponse) -> TransportResponse {
  fn(msg: TransportResponse) { msg }
}

pub fn select_response(
  selector: process.Selector(t),
  mapper: fn(TransportResponse) -> t,
) -> process.Selector(t) {
  let map_stream_message = fn(mapper) {
    fn(message) { mapper(decode_stream_message(message)) }
  }

  selector
  |> process.select_other(map_stream_message(mapper))
}
