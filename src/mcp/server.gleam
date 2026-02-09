import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode.{type Decoder}
import gleam/option.{type Option, None, Some}

pub type Annotations {
  Annotations(
    audience: Option(List(String)),
    priority: Option(Int),
    last_modified: Option(String),
  )
}

pub type Content {
  TextContent(
    text: String,
    annotations: Option(Annotations),
    meta: Option(Dynamic),
  )
}

pub type TextResourceContent {
  TextResourceContent(
    uri: String,
    mime_type: Option(String),
    meta: Option(Dynamic),
    text: String,
  )
}

pub type ReadResourceResult {
  ReadResourceResult(
    id: Int,
    jsonrpc: String,
    meta: Option(Dynamic),
    contents: List(TextResourceContent),
  )
}

pub type StructuredContent {
  StructuredContent(Dict(String, Dynamic))
}

pub type CallToolResult {
  CallToolResult(
    content: List(Content),
    meta: Option(Dynamic),
    structured_content: Option(StructuredContent),
    is_error: Bool,
  )
}

/// The server’s response to a resources/templates/list request from the
/// client.
/// 
/// `https://modelcontextprotocol.io/specification/2025-11-25/schema#
/// resourcetemplate`
/// 
pub type ListResourceTemplatesResult {
  ListResourceTemplatesResult(
    meta: Option(Dynamic),
    next_cursor: Option(String),
    resource_templates: List(ResourceTemplate),
    id: Int,
    jsonrpc: String,
  )
}

pub type Root {
  Root(uri: String, name: Option(String), meta: Option(Dynamic))
}

/// Sent from the server to request a list of root URIs from the client. Roots
/// allow servers to ask for specific directories or files to operate on. A i
/// common example for roots is providing a set of repositories or directories
/// a server should operate on.
///
/// This request is typically used when the server needs to understand the
/// file system structure or access specific locations that the client has i
/// permission to read from.
///
pub type ListRootsRequest {
  ListRootsRequest(json_rpc: String, id: Int, params: Option(Dynamic))
}

pub type Notification {
  Notification(method: String, params: Option(Dynamic), jsonrpc: String)
}

pub type Icon {
  Icon(src: String, mime_type: String, sizes: List(String))
}

pub type ServerInfo {
  ServerInfo(
    name: String,
    title: Option(String),
    version: Option(String),
    description: Option(String),
    icons: Option(List(Icon)),
    website_url: Option(String),
  )
}

pub type InputSchema {
  InputSchema(type_: String, properties: Dynamic, required: List(String))
}

pub type OutputSchema {
  OutputSchema(type_: String, properties: Dynamic, required: List(String))
}

pub type Tool {
  Tool(
    name: String,
    title: String,
    description: String,
    input_schema: InputSchema,
    output_schema: Option(OutputSchema),
  )
}

pub type ToolList {
  ToolList(List(Tool))
}

pub type Tools {
  Tools(
    // indicates whether the server will emit notifications when the list of
    // available tools changes.
    list_changed: Bool,
  )
}

pub type Resource {
  Resource(
    uri: String,
    name: String,
    mime_type: Option(String),
    title: Option(String),
    description: Option(String),
    icons: Option(List(Icon)),
    annotations: Option(Annotations),
    meta: Option(Dynamic),
    size: Option(Int),
  )
}

/// The server’s response to a resources/list request from the client.
/// `https://modelcontextprotocol.io/specification/2025-11-25/schema#listresourcesresult`
/// 
pub type ListResourcesResult {
  ListResourcesResult(
    meta: Option(Dynamic),
    next_cursor: Option(String),
    resources: List(Resource),
    id: Int,
    jsonrpc: String,
  )
}

/// A template description for resources available on the server.
/// /// `https://modelcontextprotocol.io/specification/2025-11-25/schema#resourcetemplate`
/// 
pub type ResourceTemplate {
  ResourceTemplate(
    name: String,
    uri_template: String,
    mime_type: Option(String),
    title: Option(String),
    description: Option(String),
    icons: Option(List(Icon)),
    annotations: Option(Annotations),
    meta: Option(Dynamic),
  )
}

// Both subscribe and listChanged are optional—servers can support neither, 
// either, or both:
pub type Resources {
  Resources(
    /// indicates whether the client can subscribe to be notified of changes to
    /// individual resources.
    subscribe: Option(Bool),
    /// indicates whether the server will emit notifications when the list of
    /// available resources changes.
    list_changed: Option(Bool),
  )
}

/// The Model Context Protocol (MCP) provides a standardized way for servers to
/// expose prompt templates to clients. Prompts allow servers to provide
/// structured messages and instructions for interacting with language models.
/// Clients can discover available prompts, retrieve their contents, and
/// provide arguments to customize them.
pub type Prompts {
  Prompts(list_changed: Bool)
}

/// The Model Context Protocol (MCP) allows requestors — which can be either
/// clients or servers, depending on the direction of communication — to 
/// augment their requests with tasks. see
/// `https://modelcontextprotocol.io/specification/2025-11-25/basic/utilities/tasks`
pub type Requests {
  Requests(tools_call: Bool)
}

pub type Tasks {
  Tasks(
    // Server supports the tasks/list operation
    list: Bool,
    // Server supports the tasks/cancel operation
    cancel: Bool,
    // Server supports task-augmented tools/call requests
    requests: Option(Requests),
  )
}

pub type Capabilities {
  Capabilities(
    tools: Tools,
    resources: Resources,
    prompts: Prompts,
    completions: Bool,
    logging: Bool,
    // Experimental
    tasks: Option(Tasks),
  )
}

pub type Server {
  Server(
    server_info: ServerInfo,
    protocol_version: String,
    capabilites: Capabilities,
    instructions: Option(String),
  )
}

/// Create the server information.
pub fn server_info(
  name name: String,
  title title: Option(String),
  version version: Option(String),
  description description: Option(String),
  icons icons: Option(List(Icon)),
  url website_url: Option(String),
) -> ServerInfo {
  ServerInfo(name:, version:, title:, description:, icons:, website_url:)
}

fn info_decoder() -> Decoder(ServerInfo) {
  use name <- decode.field("name", decode.string)
  use version <- decode.optional_field(
    "version",
    None,
    decode.optional(decode.string),
  )
  use title <- decode.optional_field(
    "title",
    None,
    decode.optional(decode.string),
  )
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use website_url <- decode.optional_field(
    "websiteUrl",
    None,
    decode.optional(decode.string),
  )

  decode.success(ServerInfo(
    name:,
    title:,
    version:,
    description:,
    website_url:,
    icons: None,
  ))
}

fn capabilities_decoder() -> Decoder(Capabilities) {
  // Tools
  let tools_decoder = fn() {
    use list_changed <- decode.field("listChanged", decode.bool)
    decode.success(Tools(list_changed:))
  }

  // Resources
  let resources_decoder = fn() {
    use subscribe <- decode.optional_field(
      "subscribe",
      None,
      decode.optional(decode.bool),
    )
    use list_changed <- decode.optional_field(
      "listChanged",
      None,
      decode.optional(decode.bool),
    )
    decode.success(Resources(subscribe:, list_changed:))
  }

  // Prompts
  let prompts_decoder = fn() {
    use list_changed <- decode.field("listChanged", decode.bool)
    decode.success(Prompts(list_changed:))
  }

  // Tasks
  let tasks_decoder = fn() {
    let requests_decoder = fn() {
      use tools_call <- decode.subfield(["tools", "call"], decode.success(True))
      decode.success(Some(Requests(tools_call:)))
    }
    use list <- decode.optional_field("list", False, decode.success(True))
    use cancel <- decode.optional_field("cancel", False, decode.success(True))
    use requests <- decode.optional_field("requests", None, requests_decoder())
    decode.success(Some(Tasks(list:, cancel:, requests:)))
  }

  use tools <- decode.field("tools", tools_decoder())
  use resources <- decode.field("resources", resources_decoder())
  use prompts <- decode.field("prompts", prompts_decoder())
  use completions <- decode.optional_field(
    "completions",
    False,
    decode.success(True),
  )
  use logging <- decode.optional_field("logging", False, decode.success(True))
  use tasks <- decode.optional_field("tasks", None, tasks_decoder())

  decode.success(Capabilities(
    tools:,
    resources:,
    prompts:,
    completions:,
    logging:,
    tasks:,
  ))
}

fn configuration_decoder() {
  use server_info <- decode.field("serverInfo", info_decoder())
  use protocol_version <- decode.field("protocolVersion", decode.string)
  use capabilites <- decode.field("capabilities", capabilities_decoder())

  use instructions <- decode.optional_field(
    "instructions",
    None,
    decode.optional(decode.string),
  )

  decode.success(Server(
    server_info:,
    protocol_version:,
    capabilites:,
    instructions:,
  ))
}

pub fn result_configuration_decoder() {
  use result <- decode.field("result", configuration_decoder())
  decode.success(result)
}

fn tool_decoder() {
  let input_schema_decoder = fn() {
    use type_ <- decode.field("type", decode.string)
    use properties <- decode.field("properties", decode.dynamic)
    use required <- decode.optional_field(
      "required",
      [],
      decode.list(decode.string),
    )
    decode.success(InputSchema(type_:, properties:, required:))
  }

  let output_schema_decoder = fn() {
    use type_ <- decode.field("type", decode.string)
    use properties <- decode.field("properties", decode.dynamic)
    use required <- decode.optional_field(
      "required",
      [],
      decode.list(decode.string),
    )
    decode.success(OutputSchema(type_:, properties:, required:))
  }

  use name <- decode.field("name", decode.string)
  use title <- decode.field("title", decode.string)
  use description <- decode.field("description", decode.string)
  use input_schema <- decode.field("inputSchema", input_schema_decoder())
  use output_schema <- decode.optional_field(
    "outputSchema",
    None,
    decode.optional(output_schema_decoder()),
  )
  decode.success(Tool(
    name:,
    title:,
    description:,
    input_schema:,
    output_schema:,
  ))
}

pub fn result_tools_decoder() {
  use tools <- decode.subfield(["result", "tools"], decode.list(tool_decoder()))
  decode.success(tools)
}

fn resource_template_decoder() {
  let icon_decoder = fn() {
    use src <- decode.field("src", decode.string)
    use mime_type <- decode.field("mimeType", decode.string)
    use sizes <- decode.field("sizes", decode.list(decode.string))
    decode.success(Icon(src:, mime_type:, sizes:))
  }
  use name <- decode.field("name", decode.string)
  use title <- decode.optional_field(
    "title",
    None,
    decode.optional(decode.string),
  )
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use mime_type <- decode.optional_field(
    "mimeType",
    None,
    decode.optional(decode.string),
  )
  use icons <- decode.optional_field(
    "icons",
    None,
    decode.optional(decode.list(icon_decoder())),
  )
  use uri_template <- decode.field("uriTemplate", decode.string)
  use annotations <- decode.optional_field(
    "annotations",
    None,
    decode.optional(annotations_decoder()),
  )
  use meta <- decode.optional_field(
    "meta",
    None,
    decode.optional(decode.dynamic),
  )

  decode.success(ResourceTemplate(
    name:,
    mime_type:,
    description:,
    title:,
    icons:,
    uri_template:,
    annotations:,
    meta:,
  ))
}

pub fn list_resource_templates_result_decoder() {
  use resource_templates <- decode.subfield(
    ["result", "resourceTemplates"],
    decode.list(resource_template_decoder()),
  )
  use id <- decode.field("id", decode.int)
  use jsonrpc <- decode.field("jsonrpc", decode.string)
  use next_cursor <- decode.optional_field(
    "nextCursor",
    None,
    decode.optional(decode.string),
  )
  use meta <- decode.optional_field(
    "_meta",
    None,
    decode.optional(decode.dynamic),
  )
  decode.success(ListResourceTemplatesResult(
    meta:,
    next_cursor:,
    resource_templates:,
    id:,
    jsonrpc:,
  ))
}

pub fn notifications_decoder() -> Decoder(Notification) {
  use method <- decode.field("method", decode.string)
  use jsonrpc <- decode.field("jsonrpc", decode.string)
  use params <- decode.optional_field(
    "params",
    None,
    decode.optional(decode.dynamic),
  )
  decode.success(Notification(method, params, jsonrpc))
}

fn annotations_decoder() {
  use audience <- decode.optional_field(
    "audience",
    None,
    decode.optional(decode.list(decode.string)),
  )
  use priority <- decode.optional_field(
    "priority",
    None,
    decode.optional(decode.int),
  )
  use last_modified <- decode.optional_field(
    "lastModified",
    None,
    decode.optional(decode.string),
  )
  decode.success(Annotations(audience:, priority:, last_modified:))
}

pub fn call_tool_result_decoder() -> Decoder(CallToolResult) {
  let text_decoder = fn() {
    use type_ <- decode.field("type", decode.string)
    assert type_ == "text"
    use text <- decode.field("text", decode.string)
    use annotations <- decode.optional_field(
      "annotations",
      None,
      decode.optional(annotations_decoder()),
    )
    // TODO implement meta decoder
    use meta <- decode.optional_field("_meta", None, decode.success(None))

    decode.success(TextContent(text:, annotations:, meta:))
  }

  use content <- decode.subfield(
    ["result", "content"],
    decode.list(decode.one_of(text_decoder(), [])),
  )
  use meta <- decode.optional_field("meta", None, decode.success(None))
  use _id <- decode.field("id", decode.int)
  use _json <- decode.field("jsonrpc", decode.string)
  use is_error <- decode.optional_field("isError", False, decode.success(True))
  use structured_content <- decode.optional_field(
    "structuredContent",
    None,
    decode.success(None),
  )
  decode.success(CallToolResult(content:, meta:, structured_content:, is_error:))
}

pub fn list_roots_request_decoder() -> Decoder(ListRootsRequest) {
  use method <- decode.field("method", decode.string)
  assert method == "roots/list"
  use json_rpc <- decode.field("jsonrpc", decode.string)
  use id <- decode.field("id", decode.int)
  use params <- decode.optional_field(
    "params",
    None,
    decode.optional(decode.dynamic),
  )

  decode.success(ListRootsRequest(json_rpc:, id:, params:))
}

fn resource_decoder() {
  let icon_decoder = fn() {
    use src <- decode.field("src", decode.string)
    use mime_type <- decode.field("mimeType", decode.string)
    use sizes <- decode.field("sizes", decode.list(decode.string))
    decode.success(Icon(src:, mime_type:, sizes:))
  }
  use uri <- decode.field("uri", decode.string)
  use name <- decode.field("name", decode.string)
  use title <- decode.optional_field(
    "title",
    None,
    decode.optional(decode.string),
  )
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use mime_type <- decode.optional_field(
    "mimeType",
    None,
    decode.optional(decode.string),
  )
  use icons <- decode.optional_field(
    "icons",
    None,
    decode.optional(decode.list(icon_decoder())),
  )
  use annotations <- decode.optional_field(
    "annotations",
    None,
    decode.optional(annotations_decoder()),
  )
  use meta <- decode.optional_field(
    "meta",
    None,
    decode.optional(decode.dynamic),
  )
  use size <- decode.optional_field("size", None, decode.optional(decode.int))

  decode.success(Resource(
    uri:,
    name:,
    mime_type:,
    description:,
    title:,
    icons:,
    annotations:,
    meta:,
    size:,
  ))
}

pub fn list_resources_result_decoder() {
  use resources <- decode.subfield(
    ["result", "resources"],
    decode.list(resource_decoder()),
  )
  use id <- decode.field("id", decode.int)
  use jsonrpc <- decode.field("jsonrpc", decode.string)
  use next_cursor <- decode.optional_field(
    "nextCursor",
    None,
    decode.optional(decode.string),
  )
  use meta <- decode.optional_field(
    "_meta",
    None,
    decode.optional(decode.dynamic),
  )
  decode.success(ListResourcesResult(
    meta:,
    next_cursor:,
    resources:,
    id:,
    jsonrpc:,
  ))
}

pub fn read_resource_result_decoder() {
  let text_resource_content_decoder = fn() {
    use uri <- decode.field("uri", decode.string)
    use mime_type <- decode.optional_field(
      "mimeType",
      None,
      decode.optional(decode.string),
    )
    use text <- decode.field("text", decode.string)
    use meta <- decode.optional_field(
      "_meta",
      None,
      decode.optional(decode.dynamic),
    )
    decode.success(TextResourceContent(uri:, mime_type:, meta:, text:))
  }
  use id <- decode.field("id", decode.int)
  use jsonrpc <- decode.field("jsonrpc", decode.string)
  use meta <- decode.optional_field(
    "_meta",
    None,
    decode.optional(decode.dynamic),
  )
  use contents <- decode.subfield(
    ["result", "contents"],
    decode.list(text_resource_content_decoder()),
  )
  decode.success(ReadResourceResult(id:, jsonrpc:, meta:, contents:))
}
