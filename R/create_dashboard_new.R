# ===================================================================
# Dashboard Creation System with Piping Workflow
# ===================================================================
# 
# This file implements a complete dashboard generation system that supports
# a fluent piping interface for building Quarto-based dashboards with
# interactive visualizations.
#
# Main workflow:
#   1. Create visualizations with create_viz() %>% add_viz() 
#   2. Build dashboard with create_dashboard() %>% add_landingpage() %>% add_page()
#   3. Generate files with generate_dashboard()
#
# Key features:
#   - Automatic tab grouping for related visualizations
#   - Data deduplication across pages
#   - Descriptive file naming
#   - Custom print methods for clarity
# ===================================================================

# Load required libraries
library(highcharter)
library(tidyverse)
library(dplyr)
library(rlang)
library(tidyr)
library(magrittr)
library(digest)

# ===================================================================
# Internal Utility Functions
# ===================================================================

# Find package root by walking up directory tree looking for DESCRIPTION
.pkg_root <- function(start = getwd()) {
  cur <- normalizePath(start, winslash = "/", mustWork = TRUE)
  repeat {
    if (file.exists(file.path(cur, "DESCRIPTION"))) return(cur)
    parent <- dirname(cur)
    if (identical(parent, cur)) return(NULL)
    cur <- parent
  }
}

# Check if one path is a subdirectory of another
.is_subpath <- function(path, root) {
  path <- normalizePath(path, winslash = "/", mustWork = FALSE)
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  startsWith(paste0(path, "/"), paste0(root, "/"))
}

# Resolve output directory, relocating if inside package to avoid build issues
.resolve_output_dir <- function(output_dir, allow_inside_pkg = FALSE) {
  out_abs <- normalizePath(output_dir, winslash = "/", mustWork = FALSE)
  pkg_root <- .pkg_root()

  if (!allow_inside_pkg && !is.null(pkg_root) && .is_subpath(out_abs, pkg_root)) {
    relocated <- file.path(dirname(pkg_root), basename(out_abs))
    message(
      "Detected package repo at: ", pkg_root, "\n",
      "Writing output outside the package at: ", relocated,
      " (set allow_inside_pkg = TRUE to disable relocation)"
    )
    out_abs <- relocated
  }
  out_abs
}

# Default value operator: return y if x is NULL
`%||%` <- function(x, y) if (is.null(x)) y else x

# Copy template files from package resources or create basic defaults
.copy_template <- function(template_name, output_dir) {
  template_path <- system.file(
    file.path("extdata/templates", template_name),
    package = "dashboardr"
  )

  if (template_path == "" || !file.exists(template_path)) {
    # Fallback: create basic templates if package resources are missing
    if (template_name == "index.qmd") {
      basic_template <- c(
        "---",
        "title: \"Welcome\"",
        "format: html",
        "---",
        "",
        "# Welcome to the Dashboard",
        "",
        "This is the home page of your dashboard."
      )
    } else if (template_name == "tutorial.qmd") {
      basic_template <- c(
        "---",
        "title: \"Tutorial\"",
        "format: html",
        "---",
        "",
        "# Tutorial",
        "",
        "This page contains tutorial information."
      )
    } else {
      stop("Missing template: ", template_name, " in package resources.")
    }

    target <- file.path(output_dir, template_name)
    writeLines(basic_template, target)
    return(target)
  }

  target <- file.path(output_dir, template_name)

  if (!file.exists(target)) {
    if (!file.copy(template_path, target)) {
      stop("Failed to copy template: ", template_name)
    }
  }

  target
}

# Convert R objects to proper R code strings for generating .qmd files
# Handles characters, numbers, logicals, lists, and preserves special cases
.serialize_arg <- function(arg, arg_name = NULL) {
  if (is.null(arg)) {
    return("NULL")
  } else if (is.character(arg)) {
    if (length(arg) == 1) {
      # Don't quote special identifiers like 'data' or R expressions
      if (arg %in% c("data", "readRDS('dashboard_data.rds')")) {
        return(arg)
      }
      # Quote string literals and escape internal quotes
      return(paste0('"', gsub('"', '\\"', arg, fixed = TRUE), '"'))
    } else {
      # Create c() vector for multiple strings
      quoted_args <- paste0('"', gsub('"', '\\"', arg, fixed = TRUE), '"')
      return(paste0("c(", paste(quoted_args, collapse = ", "), ")"))
    }
  } else if (is.numeric(arg)) {
    if (length(arg) == 1) {
      return(as.character(arg))
    } else {
      return(paste0("c(", paste(arg, collapse = ", "), ")"))
    }
  } else if (is.logical(arg)) {
    if (length(arg) == 1) {
      return(as.character(toupper(arg)))
    } else {
      return(paste0("c(", paste(toupper(arg), collapse = ", "), ")"))
    }
  } else if (is.list(arg)) {
    # Handle named lists (like value mappings: list("Male" = "M", "Female" = "F"))
    if (!is.null(names(arg))) {
      items <- character(0)
      for (name in names(arg)) {
        value <- .serialize_arg(arg[[name]])
        items <- c(items, paste0('"', name, '" = ', value))
      }
      return(paste0("list(", paste(items, collapse = ", "), ")"))
    } else {
      # Unnamed lists
      items <- sapply(arg, .serialize_arg)
      return(paste0("list(", paste(items, collapse = ", "), ")"))
    }
  } else {
    # Fallback for complex objects: use deparse
    deparsed <- deparse(arg, width.cutoff = 500)
    if (length(deparsed) == 1) {
      return(deparsed)
    } else {
      return(paste(deparsed, collapse = " "))
    }
  }
}

# ===================================================================
# Visualization Specification System
# ===================================================================

#' Create a new visualization collection
#' 
#' Initializes an empty collection for building up multiple visualizations
#' using the piping workflow. Optionally accepts custom display labels for
#' tab groups.
#' 
#' @param tabgroup_labels Named vector/list mapping tabgroup IDs to display names
#' @return A viz_collection object
#' @export
#' @examples
#' \dontrun{
#' # Create viz collection with custom group labels
#' vizzes <- create_viz(tabgroup_labels = c("demo" = "Demographics", 
#'                                           "pol" = "Political Views"))
#' }
create_viz <- function(tabgroup_labels = NULL) {
  structure(list(
    visualizations = list(),
    tabgroup_labels = tabgroup_labels
  ), class = "viz_collection")
}

#' Add a visualization to the collection
#' 
#' Adds a single visualization specification to an existing collection.
#' Visualizations with the same tabgroup value will be organized into
#' tabs on the generated page.
#' 
#' @param viz_collection A viz_collection object
#' @param type Visualization type: "stackedbar", "heatmap", "histogram", "timeline"
#' @param ... Additional parameters passed to the visualization function
#' @param tabgroup Optional group ID for organizing related visualizations
#' @param title Display title for the visualization
#' @return The updated viz_collection object
#' @export
#' @examples
#' \dontrun{
#' page1_viz <- create_viz() %>%
#'   add_viz(type = "stackedbar", x_var = "education", stack_var = "gender",
#'           title = "Education by Gender", tabgroup = "demographics")
#' }
add_viz <- function(viz_collection, type, ..., tabgroup = NULL, title = NULL) {
  if (!inherits(viz_collection, "viz_collection")) {
    stop("First argument must be a viz_collection object")
  }
  
  # Bundle all parameters into a spec
  viz_spec <- list(
    type = type,
    tabgroup = tabgroup,
    title = title,
    ...
  )
  
  # Append to the collection
  viz_collection$visualizations <- c(viz_collection$visualizations, list(viz_spec))
  
  viz_collection
}

#' Set or update tabgroup display labels
#'
#' Updates the display labels for tab groups in a visualization collection.
#' Useful when you want to change the section headers after creating the collection.
#'
#' @param viz_collection A viz_collection object
#' @param labels Named character vector or list mapping tabgroup IDs to labels
#' @return The updated viz_collection
#' @export
#' @examples
#' \dontrun{
#' vizzes <- create_viz() %>%
#'   add_viz(type = "heatmap", tabgroup = "demo") %>%
#'   set_tabgroup_labels(c("demo" = "Demographic Breakdowns"))
#' }
set_tabgroup_labels <- function(viz_collection, labels) {
  if (!inherits(viz_collection, "viz_collection")) {
    stop("First argument must be a viz_collection object")
  }
  viz_collection$tabgroup_labels <- labels
  viz_collection
}

#' Create a single visualization specification
#' 
#' Helper function to create individual viz specs that can be combined
#' into a list or used directly in add_page().
#' 
#' @param type Visualization type
#' @param ... Additional parameters
#' @param tabgroup Optional group ID
#' @param title Display title
#' @return A list containing the visualization specification
#' @export
#' @examples
#' \dontrun{
#' viz1 <- spec_viz(type = "heatmap", x_var = "party", y_var = "ideology")
#' viz2 <- spec_viz(type = "histogram", x_var = "age")
#' page_viz <- list(viz1, viz2)
#' }
spec_viz <- function(type, ..., tabgroup = NULL, title = NULL) {
  list(
    type = type,
    tabgroup = tabgroup,
    title = title,
    ...
  )
}

# ===================================================================
# Core Dashboard Functions
# ===================================================================

#' Create a new dashboard project
#' 
#' Initializes a dashboard project object that can be built up using
#' the piping workflow with add_landingpage() and add_page().
#' 
#' @param output_dir Directory for generated files
#' @param title Overall title for the dashboard site
#' @param allow_inside_pkg Allow output directory inside package (default FALSE)
#' @param warn_before_overwrite Warn before overwriting existing files (default TRUE)
#' @return A dashboard_project object
#' @export
#' @examples
#' \dontrun{
#' dashboard <- create_dashboard("my_dashboard", "My Analysis Dashboard")
#' }
create_dashboard <- function(output_dir = "site",
                              title = "Dashboard",
                              allow_inside_pkg = FALSE,
                              warn_before_overwrite = TRUE) {
  
  output_dir <- .resolve_output_dir(output_dir, allow_inside_pkg)
  
  # Create output directory if it doesn't exist
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  } else if (warn_before_overwrite) {
    message(
      "Output directory already exists: ", output_dir, "\n",
      "Files may be overwritten when generate_dashboard() is called."
    )
  }
  
  message("Dashboard project initialized at: ", output_dir)
  
  # Return project object for piping
  structure(list(
    output_dir = output_dir,
    title = title,
    allow_inside_pkg = allow_inside_pkg,
    warn_before_overwrite = warn_before_overwrite,
    pages = list(),
    landing_page = NULL,
    data_files = NULL
  ), class = "dashboard_project")
}

#' Add a page to the dashboard
#' 
#' Adds an analysis page to the dashboard project. Handles data storage,
#' deduplication, and visualization generation.
#' 
#' @param proj A dashboard_project object
#' @param name Page display name
#' @param data Optional data frame to save for this page
#' @param data_path Path to existing data file (alternative to data parameter)
#' @param template Optional custom template file path
#' @param params Parameters for template substitution
#' @param visualizations viz_collection or list of visualization specs
#' @return The updated dashboard_project object
#' @export
#' @examples
#' \dontrun{
#' dashboard <- create_dashboard("test") %>%
#'   add_page("Demographics", data = survey_data, visualizations = demo_viz)
#' }
add_dashboard_page <- function(proj, name, data = NULL, data_path = NULL,
                                template = NULL, params = list(), 
                                visualizations = NULL) {
  if (!inherits(proj, "dashboard_project")) {
    stop("proj must be a dashboard_project object")
  }
  
  # Handle data storage with deduplication
  if (!is.null(data)) {
    if (is.null(data_path)) {
      # Check if we've already saved this exact dataset
      data_hash <- digest::digest(data)
      existing_data <- proj$data_files %||% list()
      
      data_path <- NULL
      for (existing_path in names(existing_data)) {
        if (existing_data[[existing_path]] == data_hash) {
          data_path <- existing_path
          break
        }
      }
      
      # If not found, create a new descriptive filename
      if (is.null(data_path)) {
        data_name <- "gss_data"
        if (nrow(data) < 1000) {
          data_name <- paste0(data_name, "_small")
        } else if (nrow(data) > 5000) {
          data_name <- paste0(data_name, "_large")
        }
        data_name <- paste0(data_name, "_", nrow(data), "obs")
        data_path <- paste0(data_name, ".rds")
        
        # Track this dataset
        if (is.null(proj$data_files)) {
          proj$data_files <- list()
        }
        proj$data_files[[data_path]] <- data_hash
      }
    }
    
    # Save the data file
    output_dir <- .resolve_output_dir(proj$output_dir, proj$allow_inside_pkg)
    if (!dir.exists(output_dir)) {
      dir.create(output_dir, recursive = TRUE)
    }
    saveRDS(data, file.path(output_dir, basename(data_path)))
    data_path <- basename(data_path)
  }

  # Process visualization specifications
  viz_specs <- NULL
  if (!is.null(visualizations)) {
    if (inherits(visualizations, "viz_collection")) {
      viz_specs <- .process_viz_collection(visualizations, data_path)
    } else if (is.list(visualizations)) {
      # Handle list of individual viz specs
      viz_specs <- .process_viz_list(visualizations, data_path)
    }
  }

  # Create page record
  page <- list(
    name = name,
    data_path = data_path,
    template = template,
    params = params,
    visualizations = viz_specs
  )

  proj$pages[[name]] <- page
  proj
}

# Convenient alias for add_dashboard_page
add_page <- add_dashboard_page

#' Add a landing page to the dashboard
#' 
#' Sets or updates the landing page (home page) for the dashboard.
#' 
#' @param proj A dashboard_project object
#' @param title Landing page title
#' @param md Markdown content for the landing page body
#' @return The updated dashboard_project object
#' @export
#' @examples
#' \dontrun{
#' dashboard <- create_dashboard("test") %>%
#'   add_landingpage("Welcome", "This dashboard shows survey results.")
#' }
add_dashboard_landingpage <- function(proj, title = "Welcome", md = "") {
  if (!inherits(proj, "dashboard_project")) {
    stop("proj must be a dashboard_project object")
  }

  proj$landing_page <- list(
    title = title,
    md = md
  )

  proj
}

# Convenient alias for add_dashboard_landingpage
add_landingpage <- add_dashboard_landingpage

# ===================================================================
# Internal Visualization Processing
# ===================================================================

# Process a viz_collection into organized specs with tab groups
.process_viz_collection <- function(viz_collection, data_path) {
  if (is.null(viz_collection) || length(viz_collection$visualizations) == 0) {
    return(NULL)
  }
  
  # Separate visualizations by tabgroup
  tabgroups <- list()
  standalone_viz <- list()
  
  for (i in seq_along(viz_collection$visualizations)) {
    viz <- viz_collection$visualizations[[i]]
    viz$data_path <- data_path
    
    if (is.null(viz$tabgroup)) {
      standalone_viz <- c(standalone_viz, list(viz))
    } else {
      if (is.null(tabgroups[[viz$tabgroup]])) {
        tabgroups[[viz$tabgroup]] <- list()
      }
      tabgroups[[viz$tabgroup]] <- c(tabgroups[[viz$tabgroup]], list(viz))
    }
  }
  
  # Build result: standalone first, then tab groups
  result <- list()
  
  for (viz in standalone_viz) {
    result <- c(result, list(viz))
  }
  
  # Process tab groups: even single-viz groups get a header
  for (group_name in names(tabgroups)) {
    group_viz <- tabgroups[[group_name]]
    
    # Look up custom display label if provided
    display_label <- NULL
    if (!is.null(viz_collection$tabgroup_labels) && length(viz_collection$tabgroup_labels) > 0) {
      if (!is.null(names(viz_collection$tabgroup_labels))) {
        display_label <- viz_collection$tabgroup_labels[[group_name]]
      } else if (is.list(viz_collection$tabgroup_labels)) {
        display_label <- viz_collection$tabgroup_labels[[group_name]]
      }
    }
    
    # Create tabgroup spec (tabs appear only if >1 viz)
    result <- c(result, list(list(
      type = "tabgroup",
      name = group_name,
      label = display_label,
      visualizations = group_viz
    )))
  }
  
  result
}

# Process a plain list of viz specs
.process_viz_list <- function(viz_list, data_path) {
  if (is.null(viz_list) || length(viz_list) == 0) {
    return(NULL)
  }
  
  # Attach data path to each viz and group them
  for (i in seq_along(viz_list)) {
    viz_list[[i]]$data_path <- data_path
  }
  
  # Group by tabgroup
  tabgroups <- list()
  standalone_viz <- list()
  
  for (viz in viz_list) {
    if (is.null(viz$tabgroup)) {
      standalone_viz <- c(standalone_viz, list(viz))
    } else {
      if (is.null(tabgroups[[viz$tabgroup]])) {
        tabgroups[[viz$tabgroup]] <- list()
      }
      tabgroups[[viz$tabgroup]] <- c(tabgroups[[viz$tabgroup]], list(viz))
    }
  }
  
  # Combine standalone and grouped
  result <- list()
  
  for (viz in standalone_viz) {
    result <- c(result, list(viz))
  }
  
  for (group_name in names(tabgroups)) {
    group_viz <- tabgroups[[group_name]]
    if (length(group_viz) == 1) {
      result <- c(result, list(group_viz[[1]]))
    } else {
      result <- c(result, list(list(
        type = "tabgroup",
        name = group_name,
        visualizations = group_viz
      )))
    }
  }
  
  result
}

# Process custom template files
.process_template <- function(template_path, params, output_dir) {
  if (is.null(template_path) || !file.exists(template_path)) {
    return(NULL)
  }
  
  content <- readLines(template_path, warn = FALSE)
  
  # Substitute template variables
  content <- .substitute_template_vars(content, params)
  
  content
}

# Replace {{variable}} placeholders in templates
.substitute_template_vars <- function(content, params) {
  for (param_name in names(params)) {
    pattern <- paste0("\\{\\{", param_name, "\\}\\}")
    replacement <- as.character(params[[param_name]])
    content <- gsub(pattern, replacement, content)
  }
  content
}

# Insert generated visualization code into template
.process_viz_specs <- function(content, viz_specs) {
  if (is.null(viz_specs) || length(viz_specs) == 0) {
    return(content)
  }

  viz_placeholder <- "{{visualizations}}"
  
  if (any(grepl(viz_placeholder, content, fixed = TRUE))) {
    viz_content <- .generate_viz_from_specs(viz_specs)
    new_content <- character(0)
    for (line in content) {
      if (grepl(viz_placeholder, line, fixed = TRUE)) {
        new_content <- c(new_content, viz_content)
      } else {
        new_content <- c(new_content, line)
      }
    }
    content <- new_content
  }

  content
}

# ===================================================================
# Code Generation for Visualizations
# ===================================================================

# Generate R code chunks for all visualizations in a page
.generate_viz_from_specs <- function(viz_specs) {
  lines <- character(0)

  for (i in seq_along(viz_specs)) {
    spec <- viz_specs[[i]]
    spec_name <- if (!is.null(names(viz_specs)[i]) && names(viz_specs)[i] != "") {
      names(viz_specs)[i]
    } else {
      paste0("viz_", i)
    }
    
    # Generate either single viz or tab group
    if (is.null(spec$type) || spec$type != "tabgroup") {
      lines <- c(lines, .generate_single_viz(spec_name, spec))
    } else {
      lines <- c(lines, .generate_tabgroup_viz(spec))
    }
  }

  lines
}

# Generate a single visualization R code chunk
.generate_single_viz <- function(spec_name, spec) {
  lines <- c(
    "",
    "```{r}",
    "#| echo: false",
    "#| warning: false"
  )

  # Add descriptive comment
  if ("title" %in% names(spec)) {
    lines <- c(lines, paste0("# ", spec$title))
  } else if ("type" %in% names(spec)) {
    lines <- c(lines, paste0("# ", spec$type, " visualization"))
  } else {
    lines <- c(lines, "# Visualization")
  }
  
  lines <- c(lines, "")

  # Dispatch to appropriate generator
  if ("type" %in% names(spec)) {
    lines <- c(lines, .generate_typed_viz(spec))
  } else if ("fn" %in% names(spec)) {
    lines <- c(lines, .generate_function_viz(spec))
  } else {
    lines <- c(lines, .generate_auto_viz(spec_name, spec))
  }

  lines <- c(lines, "```", "")
  lines
}

# Generate code for typed visualizations (stackedbar, heatmap, etc.)
.generate_typed_viz <- function(spec) {
  lines <- character(0)

  # Map type to function name
  viz_function <- switch(spec$type,
                         "stackedbars" = "create_stackedbars",
                         "stackedbar" = "create_stackedbar",
                         "histogram" = "create_histogram",
                         "heatmap" = "create_heatmap",
                         "timeline" = "create_timeline",
                         spec$type
  )

  # Build argument list (exclude internal params)
  args <- list()

  if ("data_path" %in% names(spec) && !is.null(spec$data_path)) {
    args$data <- "data"  # Reference page-level data object
  }

  for (param in names(spec)) {
    if (!param %in% c("type", "data_path", "tabgroup")) {
      args[[param]] <- .serialize_arg(spec[[param]])
    }
  }

  # Format function call with proper indentation
  if (length(args) == 0) {
    call_str <- paste0(viz_function, "()")
  } else {
    arg_lines <- character(0)
    arg_lines <- c(arg_lines, paste0(viz_function, "("))
    
    for (i in seq_along(args)) {
      arg_name <- names(args)[i]
      arg_value <- args[[i]]
      comma <- if (i < length(args)) "," else ""
      arg_lines <- c(arg_lines, paste0("  ", arg_name, " = ", arg_value, comma))
    }
    
    arg_lines <- c(arg_lines, ")")
    call_str <- arg_lines
  }

  c(lines, call_str)
}

# Generate code for custom function-based visualizations
.generate_function_viz <- function(spec) {
  lines <- character(0)

  # Load data if needed
  if ("data_path" %in% names(spec) && !is.null(spec$data_path)) {
    data_file <- basename(spec$data_path)
    lines <- c(lines, paste0("data <- readRDS('", data_file, "')"))
  }

  fn_name <- spec$fn
  args <- spec$args %||% list()

  if ("data" %in% names(args) && "data_path" %in% names(spec) && !is.null(spec$data_path)) {
    args$data <- "data"
  }

  if (length(args) == 0) {
    call_str <- paste0(fn_name, "()")
  } else {
    serialized_args <- character(0)
    for (arg_name in names(args)) {
      serialized_args <- c(serialized_args,
                           paste0(arg_name, " = ", .serialize_arg(args[[arg_name]])))
    }
    args_str <- paste(serialized_args, collapse = ", ")
    call_str <- paste0(fn_name, "(", args_str, ")")
  }

  c(lines, call_str)
}

# Auto-detect visualization type from parameters and generate code
.generate_auto_viz <- function(spec_name, spec) {
  lines <- character(0)

  # Load data if specified
  if ("data_path" %in% names(spec) && !is.null(spec$data_path)) {
    data_file <- basename(spec$data_path)
    lines <- c(lines, paste0("data <- readRDS('", data_file, "')"))
  }

  # Infer function name from parameters
  if ("questions" %in% names(spec)) {
    fn_name <- "create_stackedbars"
  } else if ("x_var" %in% names(spec) && "stack_var" %in% names(spec)) {
    fn_name <- "create_stackedbar"
  } else if ("x_var" %in% names(spec) && "y_var" %in% names(spec) && "value_var" %in% names(spec)) {
    fn_name <- "create_heatmap"
  } else if ("time_var" %in% names(spec)) {
    fn_name <- "create_timeline"
  } else if ("x_var" %in% names(spec)) {
    fn_name <- "create_histogram"
  } else {
    fn_name <- spec_name
  }

  # Clean up arguments
  args <- spec
  if ("data_path" %in% names(args) && !is.null(args$data_path)) {
    args$data_path <- NULL
    args$data <- "data"
  }
  if ("tabgroup" %in% names(args)) {
    args$tabgroup <- NULL
  }

  # Format function call
  if (length(args) == 0) {
    call_str <- paste0(fn_name, "()")
  } else {
    arg_lines <- character(0)
    arg_lines <- c(arg_lines, paste0(fn_name, "("))
    
    for (i in seq_along(args)) {
      arg_name <- names(args)[i]
      arg_value <- .serialize_arg(args[[arg_name]])
      comma <- if (i < length(args)) "," else ""
      arg_lines <- c(arg_lines, paste0("  ", arg_name, " = ", arg_value, comma))
    }
    
    arg_lines <- c(arg_lines, ")")
    call_str <- arg_lines
  }

  c(lines, call_str)
}

# Generate Quarto tabset markup with visualizations
.generate_tabgroup_viz <- function(tabgroup_spec) {
  lines <- character(0)
  
  # Add section header if a label is provided
  if (!is.null(tabgroup_spec$label) && nzchar(tabgroup_spec$label)) {
    lines <- c(lines, paste0("## ", tabgroup_spec$label), "")
  } else if (!is.null(tabgroup_spec$name) && nzchar(tabgroup_spec$name)) {
    lines <- c(lines, paste0("## ", tabgroup_spec$name), "")
  }

  # Start tabset (only shows tabs if >1 viz)
  lines <- c(lines, "", "::: {.panel-tabset}", "")
  
  # Generate each tab
  for (i in seq_along(tabgroup_spec$visualizations)) {
    viz <- tabgroup_spec$visualizations[[i]]
    
    # Tab header: use viz title or default
    viz_title <- if (is.null(viz$title) || length(viz$title) == 0 || viz$title == "") {
      paste0("Chart ", i)
    } else {
      viz$title
    }
    
    lines <- c(lines, paste0("### ", viz_title), "")
    
    # Generate visualization code
    viz_lines <- .generate_single_viz(paste0("tab_", i), viz)
    lines <- c(lines, viz_lines)
    
    if (i < length(tabgroup_spec$visualizations)) {
      lines <- c(lines, "")
    }
  }
  
  # Close tabset
  lines <- c(lines, "", ":::", "")
  
  lines
}

# ===================================================================
# Quarto File Generation
# ===================================================================

# Generate _quarto.yml configuration file
.generate_quarto_yml <- function(title, pages) {
  yaml_lines <- c(
    "project:",
    "  type: website",
    "  output-dir: docs",
    "",
    "website:",
    paste0("  title: \"", title, "\""),
    "  navbar:",
    "    left:",
    "      - href: index.qmd",
    "        text: \"Home\"",
    "      - href: tutorial.qmd",
    "        text: \"Tutorial\""
  )

  # Add navigation links for each page
  for (page_name in names(pages)) {
    # Use lowercase with underscores for filenames
    filename <- tolower(gsub("[^a-zA-Z0-9]", "_", page_name))
    yaml_lines <- c(yaml_lines,
                    paste0("      - href: ", filename, ".qmd"),
                    paste0("        text: \"", page_name, "\"")
    )
  }

  yaml_lines
}

# Generate landing page .qmd file
.generate_landing_page <- function(landing_spec, output_dir) {
  content <- c(
    "---",
    paste0("title: \"", landing_spec$title, "\""),
    "format: html",
    "---",
    "",
    landing_spec$md
  )
  
  writeLines(content, file.path(output_dir, "index.qmd"))
}

# Generate default page content when no custom template is used
.generate_default_page_content <- function(page) {
  content <- c(
    "---",
    paste0("title: \"", page$name, "\""),
    "format: html",
    "---",
    "",
    "```{r}",
    "#| echo: false",
    "#| warning: false",
    "library(dashboardr)",
    "```",
    ""
  )
  
  # Load data once at the top if specified
  if (!is.null(page$data_path)) {
    data_file <- basename(page$data_path)
    content <- c(content,
      "```{r}",
      "#| echo: false",
      "#| warning: false",
      paste0("# Load data"),
      paste0("data <- readRDS('", data_file, "')"),
      "```",
      ""
    )
  }
  
  # Add visualizations
  if (!is.null(page$visualizations)) {
    viz_content <- .generate_viz_from_specs(page$visualizations)
    content <- c(content, viz_content)
  } else {
    content <- c(content, "This page was generated without a template.")
  }
  
  content
}

# ===================================================================
# Dashboard Generation and Rendering
# ===================================================================

#' Generate all dashboard files
#' 
#' Writes out all .qmd files, _quarto.yml, and optionally renders the dashboard
#' to HTML using Quarto.
#' 
#' @param proj A dashboard_project object
#' @param render Whether to render to HTML (requires Quarto CLI)
#' @param open How to open the result: "browser", "viewer", or FALSE
#' @return Invisibly returns the project object
#' @export
#' @examples
#' \dontrun{
#' dashboard %>% generate_dashboard(render = TRUE, open = "browser")
#' }
generate_dashboard <- function(proj, render = TRUE, open = "browser") {
  if (!inherits(proj, "dashboard_project")) {
    stop("proj must be a dashboard_project object")
  }
  
  output_dir <- .resolve_output_dir(proj$output_dir, proj$allow_inside_pkg)
  
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  tryCatch({
    # Generate _quarto.yml
    yaml_content <- .generate_quarto_yml(proj$title, proj$pages)
    writeLines(yaml_content, file.path(output_dir, "_quarto.yml"))
    
    # Generate landing page
    if (!is.null(proj$landing_page)) {
      .generate_landing_page(proj$landing_page, output_dir)
    } else {
      # Default landing page
      .generate_landing_page(list(title = "Welcome", md = ""), output_dir)
    }
    
    # Copy tutorial template
    .copy_template("tutorial.qmd", output_dir)
    
    # Generate each analysis page
    for (page_name in names(proj$pages)) {
      page <- proj$pages[[page_name]]
      
      # Use lowercase with underscores for filenames
      filename <- tolower(gsub("[^a-zA-Z0-9]", "_", page_name))
      page_file <- file.path(output_dir, paste0(filename, ".qmd"))
      
      if (!is.null(page$template)) {
        # Custom template
        content <- .process_template(page$template, page$params, output_dir)
        if (!is.null(page$visualizations)) {
          content <- .process_viz_specs(content, page$visualizations)
        }
      } else {
        # Default page generation
        content <- .generate_default_page_content(page)
      }
      
      writeLines(content, page_file)
      
      # Copy data file if needed
      if (!is.null(page$data_path)) {
        data_file_path <- file.path(output_dir, basename(page$data_path))
        target_path <- file.path(output_dir, basename(page$data_path))
        
        # Only copy if source and target are different
        if (normalizePath(data_file_path, mustWork = FALSE) != normalizePath(target_path, mustWork = FALSE)) {
          if (file.exists(data_file_path) && !file.copy(data_file_path, target_path, overwrite = TRUE)) {
            warning("Failed to copy data file: ", basename(page$data_path))
          }
        }
      }
    }
    
    message("Dashboard files generated successfully")
    
    # Render to HTML if requested
    if (render) {
      .render_dashboard(output_dir, open)
    }
    
  }, error = function(e) {
    stop("Failed to generate dashboard: ", e$message)
  })
  
  invisible(proj)
}

# Render Quarto project to HTML
.render_dashboard <- function(output_dir, open = FALSE) {
  if (!requireNamespace("quarto", quietly = TRUE)) {
    message("quarto package not available. Skipping render.")
    message("Install with: install.packages('quarto')")
    return()
  }

  # Create docs folder even if rendering fails
  docs_dir <- file.path(output_dir, "docs")
  if (!dir.exists(docs_dir)) {
    dir.create(docs_dir, recursive = TRUE)
    message("Created docs folder. Note: Quarto rendering may have failed.")
  }

  owd <- setwd(normalizePath(output_dir))
  on.exit(setwd(owd), add = TRUE)

  tryCatch({
    quarto::quarto_render(".", as_job = FALSE)
    message("Dashboard rendered successfully")

    if (open == "browser") {
      index_file <- file.path(output_dir, "docs", "index.html")
      if (file.exists(index_file)) {
        utils::browseURL(index_file)
      }
    }
  }, error = function(e) {
    warning("Failed to render dashboard: ", e$message)
    message("To fix this issue:")
    message("1. Install Quarto command-line tools from: https://quarto.org/docs/get-started/")
    message("2. Or run 'quarto install' in R to install via the quarto package")
    message("3. The QMD files are ready for manual rendering with: quarto render")
  })
}

# ===================================================================
# Custom Print Methods for Better User Experience
# ===================================================================

#' Print method for dashboard projects
#' 
#' Displays a concise summary of the dashboard structure instead of
#' the raw list internals.
#' 
#' @param x A dashboard_project object
#' @param ... Additional arguments (ignored)
#' @export
print.dashboard_project <- function(x, ...) {
  cat("Dashboard Project\n")
  cat("  Title: ", x$title, "\n", sep = "")
  cat("  Output: ", .resolve_output_dir(x$output_dir, x$allow_inside_pkg), "\n", sep = "")
  if (!is.null(x$landing_page)) {
    cat("  Landing: ", x$landing_page$title %||% "Welcome", "\n", sep = "")
  }
  if (!is.null(x$data_files)) {
    cat("  Data files: ", length(x$data_files), "\n", sep = "")
  }
  cat("  Pages (", length(x$pages), "):\n", sep = "")
  if (length(x$pages) > 0) {
    for (page_name in names(x$pages)) {
      page <- x$pages[[page_name]]
      viz <- page$visualizations %||% list()
      num_viz <- length(viz)
      # Count tab groups vs standalone visualizations
      num_tabgroups <- sum(vapply(viz, function(v) identical(v$type, "tabgroup"), logical(1)))
      num_standalone <- num_viz - num_tabgroups
      cat("    • ", page_name, "\n", sep = "")
      if (!is.null(page$data_path)) cat("      data: ", page$data_path, "\n", sep = "")
      cat("      visualizations: ", num_viz,
          if (num_viz > 0) paste0(" (", num_standalone, " standalone, ", num_tabgroups, " tabgroup)") else "",
          "\n", sep = "")
      # Show compact list of visualizations
      if (num_viz > 0) {
        for (i in seq_along(viz)) {
          v <- viz[[i]]
          if (!identical(v$type, "tabgroup")) {
            title <- v$title %||% v$type
            group <- v$tabgroup %||% "-"
            cat("        - [", group, "] ", v$type, if (!is.null(v$title)) paste0(" — ", v$title) else "", "\n", sep = "")
          } else {
            cat("        - <tabgroup> ", v$name, " (", length(v$visualizations), " tabs)\n", sep = "")
          }
        }
      }
    }
  }
  invisible(x)
}

#' Print method for visualization collections
#' 
#' Displays a summary of visualizations in the collection grouped by tabgroup.
#' 
#' @param x A viz_collection object
#' @param ... Additional arguments (ignored)
#' @export
print.viz_collection <- function(x, ...) {
  total <- length(x$visualizations)
  cat("Visualization Collection\n")
  cat("  Count: ", total, "\n", sep = "")
  if (total == 0) return(invisible(x))
  
  # Summarize by tabgroup
  groups <- vapply(x$visualizations, function(v) v$tabgroup %||% "(none)", character(1))
  group_table <- sort(table(groups), decreasing = TRUE)
  cat("  Groups:\n")
  for (g in names(group_table)) {
    cat("    • ", g, ": ", group_table[[g]], "\n", sep = "")
  }
  cat("  Items:\n")
  for (i in seq_along(x$visualizations)) {
    v <- x$visualizations[[i]]
    title <- v$title %||% v$type
    group <- v$tabgroup %||% "(none)"
    cat("    ", sprintf("%2d", i), ") ", "[", group, "] ", v$type,
        if (!is.null(v$title)) paste0(" — ", v$title) else "",
        "\n", sep = "")
  }
  invisible(x)
}

# ===================================================================
# Pipe Operator Support
# ===================================================================

# Import pipe operator from magrittr for fluent workflows
`%>%` <- magrittr::`%>%`