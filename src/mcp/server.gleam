import gleam/erlang/port.{type Port}
import gleam/erlang/reference.{type Reference}
import gleam/io
import gleam/string
import mcp/error.{type McpError}
import mcp/transport/stdio

pub opaque type Server {
  Port(Port)
  RequestIdetifier(Reference)
}

pub type PackageRunner {
  NPX
  UVX
  // LocalHost
  // RemoteHost
}

pub type Transport {
  Stdio
  SSE
}

pub opaque type Configuration {
  Builder(
    name: String,
    package_runner: PackageRunner,
    path_to_runner: String,
    transport: Transport,
  )
}

pub fn configuration() -> Configuration {
  Builder(
    name: "",
    package_runner: NPX,
    path_to_runner: "/opt/homebrew/bin/",
    transport: Stdio,
  )
}

pub fn name(server: Configuration, which: String) -> Configuration {
  Builder(..server, name: which)
}

pub fn package_runner(
  server: Configuration,
  which: PackageRunner,
) -> Configuration {
  Builder(..server, package_runner: which)
}

pub fn path_to_runner(server: Configuration, which: String) -> Configuration {
  let append_slash = case string.last(which) {
    Ok("/") -> which
    _ -> string.append(which, "/")
  }
  Builder(..server, path_to_runner: append_slash)
}

pub fn transport(server: Configuration, which: Transport) -> Configuration {
  Builder(..server, transport: which)
}

pub fn open(server: Configuration) -> Result(Server, McpError) {
  let assert False = string.is_empty(server.name)
    as "Server name cannot be empty"
  let method = case server.package_runner {
    NPX ->
      server.path_to_runner <> "npx -y @modelcontextprotocol/" <> server.name
    UVX -> server.path_to_runner <> "/uvx @modelcontextprotocol/" <> server.name
  }
  case server.transport {
    Stdio -> {
      stdio.open_port(method)
      |> fn(res) {
        case res {
          Error(e) -> Error(e)
          Ok(port) -> Ok(Port(port))
        }
      }
    }
    SSE -> {
      io.println_error("SSE is not supported")
      Error(error.Other)
    }
  }
}

pub fn close(server_id: Server) -> Result(Bool, McpError) {
  case server_id {
    Port(port) -> stdio.close_port(port)
    RequestIdetifier(_) -> Error(error.UnSupportedOption)
  }
}
