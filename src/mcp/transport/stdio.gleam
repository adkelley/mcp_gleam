import gleam/erlang/port.{type Port}
import gleam/result
import mcp/error.{type McpError}

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

@external(erlang, "mcp_ffi", "port_open")
fn port_open(
  name: PortName,
  settings: List(ErlPortSettings),
) -> Result(Port, McpError)

@external(erlang, "mcp_ffi", "port_close")
fn port_close(port: Port) -> Result(Bool, McpError)

pub fn close_port(port: Port) -> Result(Bool, McpError) {
  use res <- result.try(port_close(port))
  Ok(res)
}

/// Return a Port to communicate with the MCP Server
/// 
/// If a server name is empty, the program will panic
/// Otherwise if the command is incorrect, return Error(Badarg)
/// 
pub fn open_port(command: String) -> Result(Port, McpError) {
  let port_settings = [Stream, UseStdio, StderrToStdout, ExitStatus, Binary]
  use res <- result.try(port_open(Spawn(command), port_settings))
  Ok(res)
}
