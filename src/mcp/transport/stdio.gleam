import gleam/erlang/port.{type Port}
import gleam/result
import mcp/error.{type McpError}

// Internal representation of the port command to spawn.
type PortName {
  Spawn(String)
}

// Port = open_port({spawn, "/opt/homebrew/bin/npx -y @modelcontextprotocol/server-everything"}, [
//        use_stdio,
//        stderr_to_stdout,
//        exit_status,
//        binary,
//        stream
//    ]),
//    {ok, Port}.
// Erlang port flags used when spawning the MCP server.
type ErlPortSettings {
  // Output messages are sent without packet lengths
  Stream
  // Allow stdio of the spawned process
  UseStdio
  // Redirect stderr to stdout
  StderrToStdout
  // Send exit status to port
  ExitStatus
  // All I/O is binary data objects
  Binary
}

/// Spawn an MCP server process and return the connected port.
///
/// The command must not be empty; validation happens inside the Erlang FFI.
/// Any error retrieving the port is mapped into an `McpError`.
pub fn open_port(command: String) -> Result(Port, McpError) {
  let port_settings = [Stream, UseStdio, StderrToStdout, ExitStatus, Binary]
  use res <- result.try(port_open(Spawn(command), port_settings))
  Ok(res)
}

@external(erlang, "mcp_ffi", "port_open")
fn port_open(
  name: PortName,
  settings: List(ErlPortSettings),
) -> Result(Port, McpError)

/// Close an MCP server port gracefully.
pub fn close_port(port: Port) -> Result(Nil, McpError) {
  use res <- result.try(port_close(port))
  Ok(res)
}

@external(erlang, "mcp_ffi", "port_close")
fn port_close(port: Port) -> Result(Nil, McpError)

/// Send a binary payload to the MCP server port.
pub fn send(port: Port, data: BitArray) -> Result(Nil, McpError) {
  port_send(port, data)
}

@external(erlang, "mcp_ffi", "port_send")
// FFI wrapper that writes raw data to the Erlang port.
fn port_send(port: Port, data: BitArray) -> Result(Nil, McpError)
