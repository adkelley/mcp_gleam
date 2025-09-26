import gleeunit
import mcp/server

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn stdio_test() {
  let mcp_server =
    server.configuration()
    |> server.name("server-everything")
  let assert Ok(port) = server.open(mcp_server)
  let assert Ok(True) = server.close(port)
}
