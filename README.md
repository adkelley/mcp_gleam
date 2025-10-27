# gleam_mcp

`gleam_mcp` is an experimental Model Context Protocol (MCP) client written in
Gleam. It focuses on offering typed constructors for the MCP handshake, common
requests, and a thin transport abstraction for stdio-based servers.

The project is a work in progress and currently targets the 2025-06-18 MCP
protocol draft. Contributions, suggestions, and bug reports are very welcome.

## Features
- Typed builders for MCP client configuration and JSON-RPC messages
- Stdio transport helpers backed by Erlang ports
- JSON-RPC encoding utilities that hide the low-level JSON plumbing
- Gleam-friendly data structures for MCP request parameters

## Quickstart

Add the dependency to your `gleam.toml`:

```toml
[dependencies]
mcp = { path = "." }
```

Compose a minimal client and send the initial handshake:

```gleam
import mcp/client
import mcp/transport

pub fn main() {
  let client =
    client.configuration("demo-client", "0.1.0")
    |> client.roots(False)

  let initialize = client |> client.initialize
  let initialized = client.initialized()

  let config =
    transport.stdio_config()
    |> transport.stdio_command("npx @modelcontextprotocol/server-everything")

  let Ok(handle) = transport.connect(config)

  // TODO wire the transport up to your process mailbox and forward the
  // messages created above.
}
```

## Development

```sh
gleam deps download
gleam format
gleam test
```

## Reference Links

- [MCP specification draft](https://modelcontextprotocol.io/docs/getting-started/intro)
- [Community MCP servers](https://github.com/modelcontextprotocol/servers)
