# =================================================================
# mcp_server.R — Model Context Protocol server for dashboardr
# =================================================================
#
# Exposes dashboardr documentation, function help, runnable examples,
# and visualization guides to LLM-powered coding assistants (Claude,
# Copilot, Cursor, etc.) via the Model Context Protocol (MCP).
#
# Architecture
# ────────────
# The server provides 5 read-only tools (no side effects):
#
#   Tool                       Source                    Purpose
#   ─────────────────────────  ────────────────────────  ─────────────────────
#   dashboardr_guide           inst/mcp/guide.md         Full API guide
#   dashboardr_function_help   man/*.Rd (parsed)         Per-function docs
#   dashboardr_list_functions  .mcp_function_categories  Categorised function index
#   dashboardr_example         inst/mcp/examples.R       Copy-paste code patterns
#   dashboardr_viz_types       inline text               Chart type reference
#
# Dependencies (all optional, loaded at runtime):
#   - ellmer:    Tool definitions (tool(), type_string(), type_enum())
#   - mcptools:  Primary MCP backend (Posit-maintained)
#   - mcpr:      Alternative MCP backend (devOpifex)
#
# Backend resolution:
#   Preferred backend → try it → if missing, fall back to the other → if
#   both missing, abort with install instructions.
#
# Transport modes:
#   "stdio" — standard input/output (default, used by Claude Code / Desktop)
#   "http"  — HTTP server on a configurable port
# =================================================================


# ── ellmer runtime wrappers ────────────────────────────────────────────────
# ellmer is not in Suggests (it's an optional enhancement), so we use
# getExportedValue() to avoid R CMD check NOTEs about missing imports.
# Each wrapper simply forwards arguments to the real ellmer function.

.e_tool <- function(...) getExportedValue("ellmer", "tool")(...)
.e_type_string <- function(...) getExportedValue("ellmer", "type_string")(...)
.e_type_enum <- function(...) getExportedValue("ellmer", "type_enum")(...)

#' Start dashboardr MCP Server
#'
#' Launches an MCP server that exposes dashboardr documentation, function
#' reference, example code, and visualization guides to LLM-powered coding
#' assistants like Claude Desktop, Claude Code, Cursor, and VS Code Copilot.
#'
#' Tools are defined using \code{ellmer::tool()} and served via
#' \code{mcptools::mcp_server()} (default) or \code{mcpr::serve_io()} as a fallback.
#'
#' @param backend Character, which MCP backend to use. `"mcptools"` (default,
#'   Posit-maintained) or `"mcpr"` (alternative). If the chosen backend is not
#'   installed, falls back to the other.
#' @param transport Character, either `"stdio"` (default) or `"http"`.
#' @param port Integer, port for HTTP transport (default 8080). Ignored when
#'   `transport = "stdio"`.
#'
#' @details
#' The server exposes five tools:
#' \describe{
#'   \item{dashboardr_guide}{Returns the full dashboardr API guide covering
#'     the three-layer architecture, function index, and quick start.}
#'   \item{dashboardr_function_help}{Look up detailed help for any exported
#'     dashboardr function.}
#'   \item{dashboardr_list_functions}{List exported functions, optionally
#'     filtered by category.}
#'   \item{dashboardr_example}{Get runnable example code for common dashboard
#'     patterns.}
#'   \item{dashboardr_viz_types}{Quick reference of all visualization types
#'     with key parameters and use cases.}
#' }
#'
#' @section Configuration:
#'
#' **Claude Code:**
#' ```
#' claude mcp add dashboardr -- Rscript -e "dashboardr::dashboardr_mcp_server()"
#' ```
#'
#' **Claude Desktop** (`claude_desktop_config.json`):
#' ```json
#' {
#'   "mcpServers": {
#'     "dashboardr": {
#'       "command": "Rscript",
#'       "args": ["-e", "dashboardr::dashboardr_mcp_server()"]
#'     }
#'   }
#' }
#' ```
#'
#' **VS Code / Cursor:**
#' ```json
#' {
#'   "mcp": {
#'     "servers": {
#'       "dashboardr": {
#'         "type": "stdio",
#'         "command": "Rscript",
#'         "args": ["-e", "dashboardr::dashboardr_mcp_server()"]
#'       }
#'     }
#'   }
#' }
#' ```
#'
#' @return Called for its side effect (starts a blocking MCP server). Does not
#'   return.
#' @export
dashboardr_mcp_server <- function(
    backend = c("mcptools", "mcpr"),
    transport = c("stdio", "http"),
    port = 8080L
) {
  rlang::check_installed("ellmer", reason = "to define MCP tools")

  backend <- match.arg(backend)
  transport <- match.arg(transport)

  # Step 1: Resolve which backend package is available
  backend <- .mcp_resolve_backend(backend)

  # Step 2: Build the list of 5 ellmer::tool() objects
  tools <- .mcp_tools()

  # Step 3: Start the server (blocking — does not return)
  if (backend == "mcptools") {
    .mcp_serve_mcptools(tools, transport, port)
  } else {
    .mcp_serve_mcpr(tools, transport, port)
  }
}

# Determine which MCP backend package to use.
# Tries the user's preference first; if unavailable, falls back to the other.
# Aborts with install instructions if neither is found.
#
# @param backend Character, "mcptools" or "mcpr"
# @return Character, the resolved backend name
.mcp_resolve_backend <- function(backend) {
  has_mcptools <- nzchar(system.file(package = "mcptools"))
  has_mcpr <- nzchar(system.file(package = "mcpr"))

  if (backend == "mcptools" && has_mcptools) {
    return("mcptools")
  }
  if (backend == "mcpr" && has_mcpr) {
    return("mcpr")
  }
  # Fallback: try the other

  if (backend == "mcptools" && has_mcpr) {
    cli::cli_alert_info("mcptools not found, using mcpr backend instead.")
    return("mcpr")
  }
  if (backend == "mcpr" && has_mcptools) {
    cli::cli_alert_info("mcpr not found, using mcptools backend instead.")
    return("mcptools")
  }
  cli::cli_abort(c(
    "No MCP backend available.",
    "i" = "Install {.pkg mcptools} (recommended): {.code install.packages('mcptools')}",
    "i" = "Or install {.pkg mcpr}: {.code pak::pak('devOpifex/mcpr')}"
  ))
}

# Launch the MCP server using the mcptools backend (Posit-maintained).
# mcptools::mcp_server() is a blocking call that runs until the client disconnects.
#
# @param tools List of ellmer::tool() objects
# @param transport "stdio" or "http"
# @param port Integer, HTTP port (ignored for stdio)
.mcp_serve_mcptools <- function(tools, transport, port) {
  getExportedValue("mcptools", "mcp_server")(
    tools = tools,
    type = transport,
    port = port,
    session_tools = FALSE
  )
}

# Launch the MCP server using the mcpr backend (devOpifex).
# Creates a named server, registers all tools as capabilities,
# then starts the appropriate transport (stdio or HTTP).
#
# @param tools List of ellmer::tool() objects
# @param transport "stdio" or "http"
# @param port Integer, HTTP port (ignored for stdio)
.mcp_serve_mcpr <- function(tools, transport, port) {
  server <- getExportedValue("mcpr", "new_server")(
    name = "dashboardr",
    description = paste(
      "dashboardr API reference, examples, and code generation helpers.",
      "Build interactive HTML dashboards from R using a composable grammar."
    ),
    version = as.character(utils::packageVersion("dashboardr"))
  )

  for (tool in tools) {
    server <- getExportedValue("mcpr", "add_capability")(server, tool)
  }

  switch(transport,
    stdio = getExportedValue("mcpr", "serve_io")(server),
    http = getExportedValue("mcpr", "serve_http")(server, port = port)
  )
}


# ── Tool Registry ──────────────────────────────────────────────────────────
# Central registry that instantiates all 5 MCP tools.
# Each .tool_*() function returns an ellmer::tool() with:
#   - fun:         R handler function (called when the LLM invokes the tool)
#   - description: Prompt text that helps the LLM decide when to call it
#   - name:        Stable tool name (must not change — clients cache it)
#   - arguments:   Optional typed parameters (type_string, type_enum, etc.)

.mcp_tools <- function() {
  list(
    .tool_guide(),
    .tool_function_help(),
    .tool_list_functions(),
    .tool_example(),
    .tool_viz_types()
  )
}


# ── Tool 1: dashboardr_guide ──────────────────────────────────────────────
# Returns the full API guide from inst/mcp/guide.md.
# No parameters — the LLM should call this first to understand the framework.

.tool_guide <- function() {
  .e_tool(
    fun = .mcp_guide_handler,
    description = paste(
      "Get the complete dashboardr API guide.",
      "Returns the full reference covering the three-layer architecture",
      "(Content -> Page -> Dashboard), all exported functions organized by",
      "category, quick start examples, visualization types, and common",
      "patterns. Call this first to understand dashboardr before writing code."
    ),
    name = "dashboardr_guide"
  )
}

.mcp_guide_handler <- function() {
  guide_path <- system.file("mcp", "guide.md", package = "dashboardr")
  if (guide_path == "") {
    return("dashboardr guide not found. Is dashboardr properly installed?")
  }
  paste(readLines(guide_path, warn = FALSE), collapse = "\n")
}


# ── Tool 2: dashboardr_function_help ──────────────────────────────────────
# Looks up a single function by name in the dashboardr namespace.
# Falls back to parsing the .Rd file directly (works even without
# help() database, e.g., in minimal R installations or containers).
# Returns fuzzy-matched suggestions if the function isn't found.

.tool_function_help <- function() {
  .e_tool(
    fun = .mcp_function_help_handler,
    description = paste(
      "Look up detailed help for a specific dashboardr function.",
      "Returns the full documentation including description, usage,",
      "arguments, details, and examples. Use this when you need to",
      "understand a specific function's parameters and behavior.",
      "Example function names: 'viz_bar', 'add_input', 'create_dashboard',",
      "'add_text', 'theme_modern', 'add_sidebar'."
    ),
    name = "dashboardr_function_help",
    arguments = list(
      function_name = .e_type_string(
        "The name of the dashboardr function to look up (without parentheses). Examples: 'viz_bar', 'create_content', 'add_input'."
      )
    )
  )
}

# Handler for dashboardr_function_help tool.
# Strategy: check namespace → parse .Rd → render as plain text.
# If not found, uses agrep() for fuzzy matching (Levenshtein distance ≤ 0.3).
.mcp_function_help_handler <- function(function_name) {
  ns <- asNamespace("dashboardr")
  if (!exists(function_name, envir = ns)) {
    exported <- getNamespaceExports("dashboardr")
    candidates <- agrep(function_name, exported, value = TRUE, max.distance = 0.3)
    msg <- paste0("Function '", function_name, "' not found in dashboardr.")
    if (length(candidates) > 0) {
      msg <- paste0(msg, "\nDid you mean: ", paste(candidates, collapse = ", "), "?")
    }
    return(msg)
  }

  help_text <- .mcp_help_fallback(function_name)

  if (is.null(help_text) || length(help_text) == 0) {
    return(paste0(
      "Function '", function_name, "' exists in dashboardr but help ",
      "could not be retrieved. Try using dashboardr_list_functions to ",
      "see available functions with descriptions."
    ))
  }

  paste(help_text, collapse = "\n")
}

# Parse an .Rd file from inst/man and render it as plain text.
# First tries exact filename match (function_name.Rd), then scans all .Rd
# files for an \alias{} match (handles functions documented together).
# Returns NULL if not found or on any parsing error.
.mcp_help_fallback <- function(function_name) {
  man_dir <- system.file("man", package = "dashboardr")
  if (man_dir == "") return(NULL)

  rd_file <- file.path(man_dir, paste0(function_name, ".Rd"))
  if (!file.exists(rd_file)) {
    rd_files <- list.files(man_dir, pattern = "\\.Rd$", full.names = TRUE)
    for (f in rd_files) {
      content <- readLines(f, warn = FALSE)
      if (any(grepl(paste0("\\\\alias\\{", function_name, "\\}"), content))) {
        rd_file <- f
        break
      }
    }
  }

  if (!file.exists(rd_file)) return(NULL)

  tryCatch({
    rd <- tools::parse_Rd(rd_file)
    utils::capture.output(tools::Rd2txt(rd, width = 80))
  }, error = function(e) NULL)
}


# ── Tool 3: dashboardr_list_functions ─────────────────────────────────────
# Lists exported functions grouped by category.
# The category taxonomy is defined in .mcp_function_categories() below.
# Supports filtering to a single category or returning all.

.tool_list_functions <- function() {
  .e_tool(
    fun = .mcp_list_functions_handler,
    description = paste(
      "List dashboardr exported functions, optionally filtered by category.",
      "Returns function names with short descriptions. Useful for discovering",
      "what's available or finding the right function for a task.",
      "Categories: 'all', 'dashboard', 'page', 'content', 'viz', 'table',",
      "'input', 'layout', 'theme', 'metric', 'modal', 'embed', 'content_blocks'."
    ),
    name = "dashboardr_list_functions",
    arguments = list(
      category = .e_type_enum(
        "Filter functions by category. Use 'all' to see everything.",
        values = c(
          "all", "dashboard", "page", "content", "viz", "table",
          "input", "layout", "theme", "metric", "modal", "embed",
          "content_blocks"
        ),
        required = FALSE
      )
    )
  )
}

.mcp_list_functions_handler <- function(category = "all") {
  cats <- .mcp_function_categories()

  if (category != "all" && category %in% names(cats)) {
    cats <- cats[category]
  }

  lines <- character()
  for (cat_name in names(cats)) {
    lines <- c(lines, paste0("## ", cat_name))
    fns <- cats[[cat_name]]
    for (i in seq_along(fns)) {
      lines <- c(lines, paste0("- ", names(fns)[i], "() - ", fns[[i]]))
    }
    lines <- c(lines, "")
  }

  paste(lines, collapse = "\n")
}

# Canonical function-to-category mapping.
# This is the single source of truth for the function index served by the
# list_functions tool. When adding new exported functions to dashboardr,
# add them here too so LLM assistants can discover them.
#
# Categories mirror the 3-layer architecture:
#   dashboard → page → content/viz  (core creation flow)
#   input, layout, theme, metric, modal, embed, content_blocks  (features)
.mcp_function_categories <- function() {
  list(
    dashboard = c(
      create_dashboard = "Create a new dashboard project",
      add_page = "Add a page to the dashboard",
      add_pages = "Add multiple pages to a dashboard",
      generate_dashboard = "Generate all dashboard files and optionally render",
      generate_dashboards = "Generate multiple dashboards",
      publish_dashboard = "Publish dashboard to GitHub Pages",
      update_dashboard = "Update dashboard on GitHub"
    ),
    page = c(
      create_page = "Create a page object",
      add_content = "Add content collection(s) to a page",
      add_text = "Add text/markdown to content collection or page",
      add_callout = "Add a callout box",
      add_pagination = "Add pagination break"
    ),
    content = c(
      create_content = "Create a new content/visualization collection",
      create_viz = "Create a new visualization collection (alias)",
      add_viz = "Add a visualization to the collection",
      add_vizzes = "Add multiple visualizations at once",
      combine_content = "Combine content collections",
      merge_collections = "Merge two collections",
      preview = "Preview any dashboardr object",
      set_tabgroup_labels = "Set or update tabgroup display labels"
    ),
    viz = c(
      viz_bar = "Bar charts (horizontal/vertical, grouped)",
      viz_histogram = "Distribution histograms",
      viz_density = "Density plots",
      viz_boxplot = "Box plots",
      viz_stackedbar = "Stacked bar charts (crosstabs or multi-var)",
      viz_timeline = "Time series line charts",
      viz_heatmap = "2D heatmaps",
      viz_scatter = "Scatter plots",
      viz_map = "Choropleth maps",
      viz_treemap = "Treemap visualizations",
      viz_lollipop = "Lollipop charts",
      viz_dumbbell = "Dumbbell charts",
      viz_funnel = "Funnel charts",
      viz_gauge = "Gauge/bullet charts",
      viz_pie = "Pie/donut charts",
      viz_sankey = "Sankey diagrams",
      viz_waffle = "Waffle charts"
    ),
    table = c(
      add_table = "Add generic table (data frame)",
      add_gt = "Add gt table",
      add_reactable = "Add reactable table",
      add_DT = "Add DT datatable"
    ),
    input = c(
      add_input = "Add an interactive input filter",
      add_filter = "Add a filter control (simplified)",
      add_input_row = "Start an input row",
      end_input_row = "End an input row",
      add_reset_button = "Add a reset button for filters",
      add_linked_inputs = "Add cascading parent-child dropdowns",
      enable_inputs = "Enable input filter functionality",
      enable_show_when = "Enable conditional visibility",
      enable_chart_export = "Enable chart export buttons",
      show_when_open = "Open a conditional-visibility wrapper",
      show_when_close = "Close a conditional-visibility wrapper",
      add_sidebar = "Add a sidebar to a page",
      end_sidebar = "End a sidebar",
      enable_sidebar = "Enable sidebar styling"
    ),
    layout = c(
      add_layout_column = "Start a manual layout column",
      add_layout_row = "Start a manual layout row",
      end_layout_row = "End a layout row",
      end_layout_column = "End a layout column",
      navbar_section = "Create a navbar section for hybrid navigation",
      navbar_menu = "Create a navbar dropdown menu",
      sidebar_group = "Create a sidebar group for hybrid navigation",
      icon = "Create iconify icon shortcode"
    ),
    theme = c(
      apply_theme = "Apply theme to dashboard",
      theme_modern = "Modern tech theme",
      theme_clean = "Clean minimal theme",
      theme_academic = "Professional academic theme",
      theme_ascor = "ASCoR/UvA theme",
      theme_uva = "UvA theme (alias)"
    ),
    metric = c(
      add_metric = "Add a metric/value box",
      add_value_box = "Add a custom styled value box",
      add_value_box_row = "Start a value box row",
      end_value_box_row = "End a value box row",
      add_sparkline_card = "Add a sparkline metric card",
      add_sparkline_card_row = "Start a sparkline card row"
    ),
    modal = c(
      add_modal = "Add modal to content collection",
      enable_modals = "Enable modal functionality"
    ),
    embed = c(
      add_widget = "Add a generic htmlwidget",
      add_plotly = "Add a plotly chart",
      add_leaflet = "Add a leaflet map",
      add_iframe = "Add an iframe",
      add_video = "Add a video"
    ),
    content_blocks = c(
      add_image = "Add an image",
      add_divider = "Add horizontal divider",
      add_code = "Add code block",
      add_card = "Add a card",
      add_accordion = "Add collapsible accordion section",
      add_spacer = "Add vertical spacer",
      add_html = "Add raw HTML content",
      add_quote = "Add a blockquote",
      add_badge = "Add a status badge"
    )
  )
}


# ── Tool 4: dashboardr_example ────────────────────────────────────────────
# Returns runnable R code for common dashboard patterns.
# Examples are stored externally in inst/mcp/examples.R (a named list)
# so they can be maintained and tested independently of mcp_server.R.

.tool_example <- function() {
  .e_tool(
    fun = .mcp_example_handler,
    description = paste(
      "Get runnable example code for common dashboardr patterns.",
      "Returns complete, copy-paste-ready R code for building dashboards.",
      "Available patterns: 'basic_dashboard', 'bar_chart', 'multi_chart',",
      "'inputs_filters', 'sidebar', 'value_boxes', 'multi_page',",
      "'stacked_bars', 'tables', 'custom_layout', 'modals'.",
      "Use this to get started quickly with a specific pattern."
    ),
    name = "dashboardr_example",
    arguments = list(
      pattern = .e_type_enum(
        "The dashboard pattern to get example code for.",
        values = c(
          "basic_dashboard", "bar_chart", "multi_chart",
          "inputs_filters", "sidebar", "value_boxes", "multi_page",
          "stacked_bars", "tables", "custom_layout", "modals"
        )
      )
    )
  )
}

.mcp_example_handler <- function(pattern) {
  examples <- .mcp_examples()
  if (!pattern %in% names(examples)) {
    return(paste0(
      "Unknown pattern '", pattern, "'. Available patterns:\n",
      paste("-", names(examples), collapse = "\n")
    ))
  }
  examples[[pattern]]
}

# Load examples from inst/mcp/examples.R.
# The file is source()'d into a local environment so its last expression
# (a named list) becomes $value. Each list element is a string of R code.
.mcp_examples <- function() {
  examples_path <- system.file("mcp", "examples.R", package = "dashboardr")
  if (examples_path == "") {
    return(list(
      basic_dashboard = "# examples file not found - is dashboardr installed?"
    ))
  }
  source(examples_path, local = TRUE)$value
}


# ── Tool 5: dashboardr_viz_types ──────────────────────────────────────────
# Quick reference of all chart types with key parameters and data shapes.
# Content is inline (not in a file) because it's structured text that
# maps directly to the viz_*() function signatures.

.tool_viz_types <- function() {
  .e_tool(
    fun = .mcp_viz_types_handler,
    description = paste(
      "Quick reference of all dashboardr visualization types.",
      "Returns a table of all viz_*() functions with their key parameters,",
      "typical use cases, and required data shapes. Use this to decide which",
      "chart type is best for your data."
    ),
    name = "dashboardr_viz_types"
  )
}

# Returns a markdown-formatted reference of all visualization types.
# Organised by chart family (Comparison, Distribution, Composition,
# Time Series, Relationship, Geographic, Metrics).
.mcp_viz_types_handler <- function() {
  paste(
    "# dashboardr Visualization Types",
    "",
    "All viz_*() functions are used inside create_content() %>% add_viz().",
    "The `type` argument of create_content() determines which viz function is used.",
    "",
    "## Comparison Charts",
    "",
    "### viz_bar() - type = 'bar'",
    "Bar charts (horizontal or vertical). Counts, percentages, or means.",
    "Key params: x_var, group_var, value_var, horizontal, bar_type ('count'|'percent'|'mean')",
    "Data: categorical x_var column",
    "",
    "### viz_lollipop() - type = 'lollipop'",
    "Lollipop charts. Like bar charts but with dots on stems.",
    "Key params: x_var, value_var, horizontal, sort_by_value",
    "Data: categorical x_var column",
    "",
    "### viz_dumbbell() - type = 'dumbbell'",
    "Dumbbell charts. Compare two values per category.",
    "Key params: x_var, value_var, group_var",
    "Data: categorical x_var, numeric value_var, 2-level group_var",
    "",
    "## Distribution Charts",
    "",
    "### viz_histogram() - type = 'histogram'",
    "Histograms for continuous data.",
    "Key params: x_var, bins, group_var",
    "Data: numeric x_var column",
    "",
    "### viz_density() - type = 'density'",
    "Kernel density plots.",
    "Key params: x_var, group_var, bandwidth",
    "Data: numeric x_var column",
    "",
    "### viz_boxplot() - type = 'boxplot'",
    "Box plots for distribution comparison.",
    "Key params: x_var, y_var, group_var",
    "Data: categorical x_var, numeric y_var",
    "",
    "## Composition Charts",
    "",
    "### viz_stackedbar() - type = 'stackedbar'",
    "Stacked bar charts. Crosstabs (x_var + stack_var) or multi-variable.",
    "Key params: x_var, stack_var OR x_vars, percent, horizontal",
    "Data: categorical columns",
    "",
    "### viz_pie() - type = 'pie'",
    "Pie or donut charts.",
    "Key params: x_var, value_var, donut (TRUE for donut)",
    "Data: categorical x_var",
    "",
    "### viz_waffle() - type = 'waffle'",
    "Waffle charts (square pie charts).",
    "Key params: x_var, value_var, n_rows",
    "Data: categorical x_var",
    "",
    "### viz_treemap() - type = 'treemap'",
    "Hierarchical treemaps.",
    "Key params: x_var, value_var, group_var (for nesting)",
    "Data: categorical x_var, numeric value_var",
    "",
    "### viz_funnel() - type = 'funnel'",
    "Funnel charts for sequential stages.",
    "Key params: x_var, value_var",
    "Data: categorical x_var (stages), numeric value_var",
    "",
    "## Time Series",
    "",
    "### viz_timeline() - type = 'timeline'",
    "Time series line charts.",
    "Key params: x_var (date/time), y_var, group_var, line_type",
    "Data: date/numeric x_var, numeric y_var",
    "",
    "## Relationship Charts",
    "",
    "### viz_scatter() - type = 'scatter'",
    "Scatter plots.",
    "Key params: x_var, y_var, group_var, size_var, regression_line",
    "Data: numeric x_var and y_var",
    "",
    "### viz_heatmap() - type = 'heatmap'",
    "2D heatmaps for correlations or matrices.",
    "Key params: x_var, y_var, value_var, cluster",
    "Data: categorical x_var and y_var, numeric value_var",
    "",
    "### viz_sankey() - type = 'sankey'",
    "Sankey flow diagrams.",
    "Key params: from_var, to_var, value_var",
    "Data: categorical from/to columns, numeric value_var",
    "",
    "## Geographic",
    "",
    "### viz_map() - type = 'map'",
    "Choropleth maps.",
    "Key params: location_var, value_var, map_type ('world'|'europe'|...)",
    "Data: location names/codes, numeric value_var",
    "",
    "## Metrics",
    "",
    "### viz_gauge() - type = 'gauge'",
    "Gauge or bullet charts for KPIs.",
    "Key params: value, min, max, thresholds",
    "Data: single numeric value",
    "",
    "## Common Pattern",
    "",
    "```r",
    "# All chart types follow the same pattern:",
    "create_content(data = my_data, type = 'bar') %>%",
    "  add_viz(x_var = 'category', title = 'My Chart')",
    "```",
    "",
    "The `type` argument in create_content() maps directly to these viz functions.",
    "Additional parameters from the viz_*() function can be passed through add_viz().",
    sep = "\n"
  )
}
