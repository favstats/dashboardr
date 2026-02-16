# Start dashboardr MCP Server

Launches an MCP server that exposes dashboardr documentation, function
reference, example code, and visualization guides to LLM-powered coding
assistants like Claude Desktop, Claude Code, Cursor, and VS Code
Copilot.

## Usage

``` r
dashboardr_mcp_server(
  backend = c("mcptools", "mcpr"),
  transport = c("stdio", "http"),
  port = 8080L
)
```

## Arguments

- backend:

  Character, which MCP backend to use. `"mcptools"` (default,
  Posit-maintained) or `"mcpr"` (alternative). If the chosen backend is
  not installed, falls back to the other.

- transport:

  Character, either `"stdio"` (default) or `"http"`.

- port:

  Integer, port for HTTP transport (default 8080). Ignored when
  `transport = "stdio"`.

## Value

Called for its side effect (starts a blocking MCP server). Does not
return.

## Details

Tools are defined using
[`ellmer::tool()`](https://ellmer.tidyverse.org/reference/tool.html) and
served via
[`mcptools::mcp_server()`](https://posit-dev.github.io/mcptools/reference/server.html)
(default) or
[`mcpr::serve_io()`](https://mcpr.opifex.org/reference/serve_io.html) as
a fallback.

The server exposes five tools:

- dashboardr_guide:

  Returns the full dashboardr API guide covering the three-layer
  architecture, function index, and quick start.

- dashboardr_function_help:

  Look up detailed help for any exported dashboardr function.

- dashboardr_list_functions:

  List exported functions, optionally filtered by category.

- dashboardr_example:

  Get runnable example code for common dashboard patterns.

- dashboardr_viz_types:

  Quick reference of all visualization types with key parameters and use
  cases.

## Configuration

**Claude Code:**

    claude mcp add dashboardr -- Rscript -e "dashboardr::dashboardr_mcp_server()"

**Claude Desktop** (`claude_desktop_config.json`):

    {
      "mcpServers": {
        "dashboardr": {
          "command": "Rscript",
          "args": ["-e", "dashboardr::dashboardr_mcp_server()"]
        }
      }
    }

**VS Code / Cursor:**

    {
      "mcp": {
        "servers": {
          "dashboardr": {
            "type": "stdio",
            "command": "Rscript",
            "args": ["-e", "dashboardr::dashboardr_mcp_server()"]
          }
        }
      }
    }
