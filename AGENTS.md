# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Project Overview
`mcp_bleam` is an SDK for the Model Context Protocol (MCP) implementation written in the Gleam programming language.  The offical MCP documentation can be found [here](https://modelcontextprotocol.io/docs/getting-started/intro)

## Best Coding Practices
### Documentation
- Documentation lines for public functions and public types are prefixed with '/// '
- Documentation lines for private functions and types are prefixed witn '//'
- Todos are prefixed witn '// TODO '
### Functions
- If a function is called by just one other function, then embed that function insides the calling function using a `let` statement. For example
```gleam
pub fn outer_function() {
  let helper_function = fn() {
    ...
  }
}
```


## Essential Commands

### Development
- `gleam deps download` - Install dependencies
- `gleam format` - Format the code
- `gleam test` - Run all tests
