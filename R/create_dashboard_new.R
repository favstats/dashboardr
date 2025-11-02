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

# ===================================================================
# Error Message Helpers
# ===================================================================

# Find closest match using string distance
.suggest_alternative <- function(input, valid_options) {
  if (is.null(input) || length(valid_options) == 0) return(NULL)
  
  distances <- sapply(valid_options, function(opt) {
    adist(tolower(input), tolower(opt))[1,1]
  })
  
  min_dist <- min(distances)
  
  # Only suggest if distance is small (likely typo)
  if (min_dist <= 2) {
    return(valid_options[which.min(distances)])
  }
  
  NULL
}

# Stop with helpful error message
.stop_with_hint <- function(param_name, valid_options = NULL, example = NULL) {
  msg <- paste0("'", param_name, "' parameter is required")
  
  if (!is.null(valid_options) && length(valid_options) > 0) {
    msg <- paste0(msg, "\n\u2139 Available ", param_name, "s: ", 
                  paste(head(valid_options, 6), collapse = ", "))
    if (length(valid_options) > 6) {
      msg <- paste0(msg, ", ...")
    }
  }
  
  if (!is.null(example)) {
    msg <- paste0(msg, "\n\u2139 Example: ", example)
  }
  
  stop(msg, call. = FALSE)
}

# Stop with typo suggestion
.stop_with_suggestion <- function(param_name, input, valid_options) {
  suggestion <- .suggest_alternative(input, valid_options)
  
  msg <- paste0("Unknown ", param_name, " '", input, "'")
  
  if (!is.null(suggestion)) {
    msg <- paste0(msg, "\n\u2139 Did you mean '", suggestion, "'?")
  }
  
  msg <- paste0(msg, "\n\u2139 Available ", param_name, "s: ", 
                paste(head(valid_options, 6), collapse = ", "))
  
  if (length(valid_options) > 6) {
    msg <- paste0(msg, ", ...")
  }
  
  stop(msg, call. = FALSE)
}

# ===================================================================
# Incremental Build System
# ===================================================================

# Compute hash of an R object
.compute_hash <- function(obj) {
  digest::digest(obj, algo = "xxhash64")
}

# Save build manifest
.save_manifest <- function(manifest, output_dir) {
  manifest_file <- file.path(output_dir, ".dashboardr_manifest.rds")
  saveRDS(manifest, manifest_file)
}

# Load build manifest
.load_manifest <- function(output_dir) {
  manifest_file <- file.path(output_dir, ".dashboardr_manifest.rds")
  if (file.exists(manifest_file)) {
    return(readRDS(manifest_file))
  }
  NULL
}

# Check if page needs rebuild
.needs_rebuild <- function(page_name, page_config, manifest) {
  if (is.null(manifest) || is.null(manifest$pages)) {
    return(TRUE)  # First build
  }
  
  if (!page_name %in% names(manifest$pages)) {
    return(TRUE)  # New page
  }
  
  old_hash <- manifest$pages[[page_name]]$hash
  new_hash <- .compute_hash(page_config)
  
  return(old_hash != new_hash)
}

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

#' Convert R objects to proper R code strings for generating .qmd files
#'
#' Internal function that converts R objects into properly formatted R code strings
#' for inclusion in generated Quarto markdown files. Handles various data types
#' and preserves special cases like data references.
#'
#' @param arg The R object to serialize
#' @param arg_name Optional name of the argument (for debugging)
#' @return Character string containing properly formatted R code
#' @keywords internal
#' @details
#' This function handles:
#' - NULL values → "NULL"
#' - Character strings → quoted strings with escaped quotes
#' - Numeric values → unquoted numbers
#' - Logical values → "TRUE"/"FALSE"
#' - Named lists → "list(name1 = value1, name2 = value2)"
#' - Unnamed lists → "list(value1, value2)"
#' - Special identifiers like "data" → unquoted
#' - Complex objects → deparsed representation
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
#' tab groups and default parameters that apply to all visualizations.
#'
#' @param tabgroup_labels Named vector/list mapping tabgroup IDs to display names
#' @param ... Default parameters to apply to all subsequent add_viz() calls.
#'   Any parameter specified in add_viz() will override the default.
#'   Useful for setting common parameters like type, color_palette, stacked_type, etc.
#' @return A viz_collection object
#' @export
#' @examples
#' \dontrun{
#' # Create viz collection with custom group labels
#' vizzes <- create_viz(tabgroup_labels = c("demo" = "Demographics",
#'                                           "pol" = "Political Views"))
#'                                           
#' # Create viz collection with shared defaults
#' vizzes <- create_viz(
#'   type = "stackedbars",
#'   stacked_type = "percent",
#'   color_palette = c("#d7191c", "#fdae61", "#2b83ba"),
#'   horizontal = TRUE,
#'   x_label = ""
#' ) %>%
#'   add_viz(title = "Wave 1", filter = ~ wave == 1) %>%  # Uses defaults
#'   add_viz(title = "Wave 2", filter = ~ wave == 2, horizontal = FALSE)  # Overrides horizontal
#' }
create_viz <- function(tabgroup_labels = NULL, ...) {
  defaults <- list(...)
  
  structure(list(
    visualizations = list(),
    tabgroup_labels = tabgroup_labels,
    defaults = defaults
  ), class = "viz_collection")
}

#' Combine Visualization Collections with + Operator
#'
#' S3 method that allows combining two viz_collection objects using the `+` operator.
#' This is a convenient shorthand for \code{\link{combine_viz}}.
#'
#' @param e1 First viz_collection object (left operand).
#' @param e2 Second viz_collection object (right operand).
#'
#' @return A new viz_collection containing all visualizations from both collections,
#'   with merged tabgroup labels and renumbered insertion indices.
#'
#' @details
#' The `+` operator provides an intuitive way to combine visualization collections:
#' \itemize{
#'   \item All visualizations from both collections are merged
#'   \item Tabgroup labels are combined (e2 labels take precedence for duplicates)
#'   \item Insertion indices are renumbered to maintain proper ordering
#' }
#'
#' @seealso \code{\link{combine_viz}} for the underlying function.
#'
#' @method + viz_collection
#' @export
#'
#' @examples
#' \dontrun{
#' # Create two separate visualization collections
#' viz1 <- create_viz() %>%
#'   add_viz(type = "histogram", x_var = "age", title = "Age Distribution")
#'
#' viz2 <- create_viz() %>%
#'   add_viz(type = "histogram", x_var = "income", title = "Income Distribution")
#'
#' # Combine using + operator
#' combined <- viz1 + viz2
#'
#' # Equivalent to:
#' combined <- combine_viz(viz1, viz2)
#' }
`+.viz_collection` <- function(e1, e2) {
  # Validate inputs
  if (!inherits(e1, "viz_collection")) {
    stop("Left operand must be a viz_collection object")
  }
  if (missing(e2) || !inherits(e2, "viz_collection")) {
    stop("Right operand must be a viz_collection object")
  }
  
  # Combine visualizations and renumber insertion indices to preserve order
  combined_viz <- list()
  
  # Add e1's visualizations first
  for (i in seq_along(e1$visualizations)) {
    viz <- e1$visualizations[[i]]
    # Remove old index and set new one
    viz[[".insertion_index"]] <- NULL
    viz[[".insertion_index"]] <- i
    combined_viz[[length(combined_viz) + 1]] <- viz
  }
  
  # Renumber e2's visualizations to come after e1's
  offset <- length(e1$visualizations)
  for (i in seq_along(e2$visualizations)) {
    viz <- e2$visualizations[[i]]
    # Remove old index and set new one
    viz[[".insertion_index"]] <- NULL
    viz[[".insertion_index"]] <- offset + i
    combined_viz[[length(combined_viz) + 1]] <- viz
  }
  
  # Merge tabgroup labels (e2 takes precedence for conflicts)
  combined_labels <- list()
  if (!is.null(e1$tabgroup_labels)) {
    combined_labels <- e1$tabgroup_labels
  }
  if (!is.null(e2$tabgroup_labels)) {
    for (label_name in names(e2$tabgroup_labels)) {
      combined_labels[[label_name]] <- e2$tabgroup_labels[[label_name]]
    }
  }
  
  # Combine defaults (e2 takes precedence)
  combined_defaults <- list()
  if (!is.null(e1$defaults) && length(e1$defaults) > 0) {
    combined_defaults <- e1$defaults
  }
  if (!is.null(e2$defaults) && length(e2$defaults) > 0) {
    for (default_name in names(e2$defaults)) {
      combined_defaults[[default_name]] <- e2$defaults[[default_name]]
    }
  }
  
  # Return new combined collection
  structure(list(
    visualizations = combined_viz,
    tabgroup_labels = if (length(combined_labels) > 0) combined_labels else NULL,
    defaults = if (length(combined_defaults) > 0) combined_defaults else list()
  ), class = "viz_collection")
}

#' Combine visualization collections
#'
#' Alternative function to combine viz_collection objects.
#' Use this if the `+` operator doesn't work (e.g., with devtools::load_all()).
#'
#' @param ... One or more viz_collection objects to combine
#' @return A combined viz_collection
#' @export
#' @examples
#' \dontrun{
#' viz1 <- create_viz() %>% add_viz(type = "histogram", x_var = "age")
#' viz2 <- create_viz() %>% add_viz(type = "histogram", x_var = "income")
#' combined <- combine_viz(viz1, viz2)  # Combines both
#' }
combine_viz <- function(...) {
  collections <- list(...)
  
  if (length(collections) == 0) {
    return(create_viz())
  }
  
  # Validate all are viz_collection
  for (i in seq_along(collections)) {
    if (!inherits(collections[[i]], "viz_collection")) {
      stop("All arguments must be viz_collection objects")
    }
  }
  
  # Combine all visualizations and renumber insertion indices
  combined_viz <- list()
  combined_labels <- list()
  combined_defaults <- list()
  
  for (col in collections) {
    # Renumber indices to maintain global order
    offset <- length(combined_viz)
    for (i in seq_along(col$visualizations)) {
      viz <- col$visualizations[[i]]
      # Remove old insertion index and add new one
      viz[[".insertion_index"]] <- NULL
      viz[[".insertion_index"]] <- offset + i
      combined_viz[[length(combined_viz) + 1]] <- viz
    }
    
    if (!is.null(col$tabgroup_labels)) {
      for (label_name in names(col$tabgroup_labels)) {
        combined_labels[[label_name]] <- col$tabgroup_labels[[label_name]]
      }
    }
    
    if (!is.null(col$defaults) && length(col$defaults) > 0) {
      for (default_name in names(col$defaults)) {
        combined_defaults[[default_name]] <- col$defaults[[default_name]]
      }
    }
  }
  
  # Sort visualizations by tabgroup hierarchy so nested tabs appear after their parent tabs
  # This ensures the order is intuitive (parent, then nested children with matching filter)
  combined_viz <- .sort_viz_by_tabgroup_hierarchy(combined_viz)
  
  structure(list(
    visualizations = combined_viz,
    tabgroup_labels = if (length(combined_labels) > 0) combined_labels else NULL,
    defaults = if (length(combined_defaults) > 0) combined_defaults else list()
  ), class = "viz_collection")
}

#' Sort visualizations by tabgroup hierarchy
#'
#' Internal helper to ensure nested tabs appear after their parent tabs.
#' Groups visualizations so that children appear immediately after their parent
#' at the same hierarchy level. For example:
#' - "sis" (Wave 1)
#' - "sis/age/item1" (Wave 1) - nested under first "sis"
#' - "sis" (Wave 2)
#' - "sis/age/item1" (Wave 2) - nested under second "sis"
#'
#' @param viz_list List of visualization specifications
#' @return Sorted list of visualizations
#' @noRd
.sort_viz_by_tabgroup_hierarchy <- function(viz_list) {
  if (length(viz_list) == 0) {
    return(viz_list)
  }
  
  # SIMPLIFIED APPROACH: Just sort by insertion_index!
  # The hierarchy builder will handle grouping and nesting correctly.
  # We don't need to pre-sort by tabgroup hierarchy here.
  
  # Extract insertion indices
  sort_order <- order(sapply(viz_list, function(v) v$.insertion_index %||% Inf))
  
  # Return sorted by insertion index
  viz_list[sort_order]
}

#' Parse tabgroup into normalized hierarchy
#'
#' Internal helper to parse tabgroup parameter from various formats into a
#' standardized character vector representing the hierarchy.
#'
#' @param tabgroup Can be:
#'   - NULL: no tabgroup
#'   - Character string: "level1" or "level1/level2/level3" (slash notation)
#'   - Named numeric vector: c("1" = "level1", "2" = "level2", "3" = "level3")
#' @return Character vector of hierarchy levels, or NULL
#' @noRd
.parse_tabgroup <- function(tabgroup) {
  if (is.null(tabgroup)) {
    return(NULL)
  }
  
  # Case 1: Character string - check for slash notation
  if (is.character(tabgroup)) {
    if (length(tabgroup) == 1) {
      # Single string - split by "/" if present
      if (grepl("/", tabgroup, fixed = TRUE)) {
        # Slash notation: "demographics/details/regional"
        levels <- strsplit(tabgroup, "/", fixed = TRUE)[[1]]
        levels <- trimws(levels)  # Remove whitespace
        levels <- levels[nzchar(levels)]  # Remove empty strings
        if (length(levels) == 0) {
          stop("tabgroup cannot be empty after parsing")
        }
        return(levels)
      } else {
        # Simple string: "demographics"
        return(tabgroup)
      }
    } else if (length(tabgroup) > 1) {
      # Named or unnamed vector of strings
      if (!is.null(names(tabgroup))) {
        # Named vector - check if names are numeric strings like "1", "2", "3"
        if (all(grepl("^[0-9]+$", names(tabgroup)))) {
          # Named numeric vector: c("1" = "demographics", "2" = "details")
          # Sort by numeric names
          sorted_idx <- order(as.integer(names(tabgroup)))
          return(as.character(tabgroup[sorted_idx]))
        }
      }
      # Fallback: use as-is (unnamed vector)
      return(as.character(tabgroup))
    }
  }
  
  stop("tabgroup must be either:\n",
       "  - A string: 'demographics' or 'demographics/details/regional'\n",
       "  - A named numeric vector: c('1' = 'demographics', '2' = 'details')")
}

#' Add a visualization to the collection
#'
#' Adds a single visualization specification to an existing collection.
#' Visualizations with the same tabgroup value will be organized into
#' tabs on the generated page. Supports nested tabsets through hierarchy notation.
#'
#' @param viz_collection A viz_collection object
#' @param type Visualization type: "stackedbar", "heatmap", "histogram", "timeline"
#' @param ... Additional parameters passed to the visualization function
#' @param tabgroup Optional group ID for organizing related visualizations. Supports:
#'   - Simple string: `"demographics"` for a single tab group
#'   - Slash notation: `"demographics/details"` or `"demographics/details/regional"` for nested tabs
#'   - Named numeric vector: `c("1" = "demographics", "2" = "details", "3" = "regional")` for explicit hierarchy
#' @param title Display title for the visualization (shown above the chart)
#' @param title_tabset Optional tab label. If NULL, uses `title` for the tab label. 
#'   Use this when you want a short tab name but a longer, descriptive visualization title.
#' @param text Optional markdown text to display above the visualization
#' @param icon Optional iconify icon shortcode for the visualization
#' @param text_position Position of text relative to visualization ("above" or "below")
#' @param height Optional height in pixels for highcharter visualizations (numeric value)
#' @param filter Optional filter expression to subset data for this visualization. Use formula syntax:
#'   `~ condition`. Examples: `~ wave == 1`, `~ age > 18`, `~ wave %in% c(1, 2, 3)`
#' @param data Optional dataset name when using multiple datasets. Can be:
#'   - NULL: Uses default dataset (or only dataset if single)
#'   - String: Name of dataset from named list (e.g., "survey", "demographics")
#' @return The updated viz_collection object
#' @export
#' @examples
#' \dontrun{
#' # Simple tabgroup
#' page1_viz <- create_viz() %>%
#'   add_viz(type = "stackedbar", x_var = "education", stack_var = "gender",
#'           title = "Education by Gender", tabgroup = "demographics")
#'           
#' # Nested tabgroups using slash notation
#' page2_viz <- create_viz() %>%
#'   add_viz(type = "stackedbar", title = "Overview", 
#'           tabgroup = "demographics") %>%
#'   add_viz(type = "stackedbar", title = "Details",
#'           tabgroup = "demographics/details")
#'           
#' # Nested tabgroups using named numeric vector
#' page3_viz <- create_viz() %>%
#'   add_viz(type = "stackedbar", title = "Regional Details",
#'           tabgroup = c("1" = "demographics", "2" = "details", "3" = "regional"))
#'           
#' # Filter data per visualization
#' page4_viz <- create_viz() %>%
#'   add_viz(type = "histogram", x_var = "response", 
#'           title = "Wave 1", filter = ~ wave == 1) %>%
#'   add_viz(type = "histogram", x_var = "response",
#'           title = "Wave 2", filter = ~ wave == 2) %>%
#'   add_viz(type = "histogram", x_var = "response",
#'           title = "All Waves", filter = ~ wave %in% c(1, 2, 3))
#'           
#' # Multiple datasets
#' page5_viz <- create_viz() %>%
#'   add_viz(type = "histogram", x_var = "age", data = "demographics") %>%
#'   add_viz(type = "histogram", x_var = "response", data = "survey") %>%
#'   add_viz(type = "histogram", x_var = "outcome", data = "outcomes")
#'   
#' # Separate tab label from visualization title
#' page6_viz <- create_viz() %>%
#'   add_viz(
#'     type = "histogram",
#'     x_var = "age",
#'     tabgroup = "demographics",
#'     title_tabset = "Age",  # Short tab label
#'     title = "Age Distribution of Survey Respondents by Gender and Region"  # Long viz title
#'   )
#' }
add_viz <- function(viz_collection, type = NULL, ..., tabgroup = NULL, title = NULL, title_tabset = NULL, text = NULL, icon = NULL, text_position = NULL, height = NULL, filter = NULL, data = NULL, drop_na_vars = FALSE) {
  # Validate first argument
  if (!inherits(viz_collection, "viz_collection")) {
    stop("First argument must be a viz_collection object")
  }

  # Get explicitly provided arguments (not defaults)
  call_args <- as.list(match.call())[-1]  # Remove function name
  call_args$viz_collection <- NULL  # Remove viz_collection from the list
  
  # Get defaults from viz_collection
  # Note: Don't use %||% as it may have unexpected behavior with lists
  if (is.null(viz_collection$defaults)) {
    defaults <- list()
  } else {
    defaults <- viz_collection$defaults
  }
  
  # Get additional parameters from ...
  dot_args <- list(...)
  
  # Merge parameters: explicitly provided > dots > defaults
  # Start with defaults
  merged_params <- defaults
  
  # Override with dot args
  for (name in names(dot_args)) {
    merged_params[[name]] <- dot_args[[name]]
  }
  
  # Override with explicitly provided named parameters
  if ("type" %in% names(call_args)) merged_params$type <- type
  if ("tabgroup" %in% names(call_args)) merged_params$tabgroup <- tabgroup
  if ("title" %in% names(call_args)) merged_params$title <- title
  if ("title_tabset" %in% names(call_args)) merged_params$title_tabset <- title_tabset
  if ("text" %in% names(call_args)) merged_params$text <- text
  if ("icon" %in% names(call_args)) merged_params$icon <- icon
  if ("text_position" %in% names(call_args)) merged_params$text_position <- text_position
  if ("height" %in% names(call_args)) merged_params$height <- height
  if ("filter" %in% names(call_args)) merged_params$filter <- filter
  if ("data" %in% names(call_args)) merged_params$data <- data
  if ("drop_na_vars" %in% names(call_args)) {
    merged_params$drop_na_vars <- drop_na_vars
  }
  
  # Extract final values from merged_params
  type <- merged_params$type
  tabgroup <- merged_params$tabgroup
  title <- merged_params$title
  title_tabset <- merged_params$title_tabset
  text <- merged_params$text
  icon <- merged_params$icon
  text_position <- merged_params$text_position %||% "above"
  height <- merged_params$height
  filter <- merged_params$filter
  data <- merged_params$data
  # Note: Using if/else instead of %||% due to unexpected behavior with FALSE values
  drop_na_vars <- if (is.null(merged_params$drop_na_vars)) FALSE else merged_params$drop_na_vars
  
  # Now apply merged_params from dots to the ... parameters
  dot_args <- merged_params[!names(merged_params) %in% c("type", "tabgroup", "title", "title_tabset", "text", "icon", "text_position", "height", "filter", "data", "drop_na_vars")]

  # Validate supported visualization types
  supported_types <- c("stackedbar", "stackedbars", "heatmap", "histogram", "timeline", "bar")
  
  # Validate type parameter
  if (is.null(type) || !is.character(type) || length(type) != 1 || nchar(type) == 0) {
    .stop_with_hint("type", supported_types, "add_viz(type = \"histogram\", x_var = \"age\")")
  }
  
  if (!type %in% supported_types) {
    .stop_with_suggestion("type", type, supported_types)
  }

  # Parse and validate tabgroup parameter
  tabgroup_parsed <- NULL
  if (!is.null(tabgroup)) {
    tabgroup_parsed <- tryCatch(
      .parse_tabgroup(tabgroup),
      error = function(e) {
        stop("Invalid tabgroup format: ", e$message, call. = FALSE)
      }
    )
  }

  # Validate title parameter
  if (!is.null(title)) {
    if (!is.character(title) || length(title) != 1) {
      stop("title must be a character string or NULL")
    }
  }

  # Validate text parameter
  if (!is.null(text)) {
    if (!is.character(text) || length(text) != 1) {
      stop("text must be a character string or NULL")
    }
  }

  # Validate icon parameter
  if (!is.null(icon)) {
    if (!is.character(icon) || length(icon) != 1) {
      stop("icon must be a character string or NULL")
    }
    # Validate icon format (should be "collection:name" or already formatted shortcode)
    if (!grepl("^[a-zA-Z0-9_-]+:[a-zA-Z0-9_-]+$", icon) &&
        !grepl("\\{\\{< iconify", icon, fixed = TRUE)) {
      warning("Icon '", icon, "' should be in format 'collection:name' (e.g., 'ph:users-three') ",
              "or a pre-formatted iconify shortcode")
    }
  }

  # Validate text_position
  if (!text_position %in% c("above", "below")) {
    stop("text_position must be either 'above' or 'below'")
  }

  # Validate height parameter
  if (!is.null(height)) {
    if (!is.numeric(height) || length(height) != 1 || height <= 0) {
      stop("height must be a positive numeric value or NULL")
    }
  }

  # Validate filter parameter
  if (!is.null(filter)) {
    if (!inherits(filter, "formula")) {
      stop("filter must be a formula (e.g., ~ wave == 1) or NULL")
    }
    if (length(filter) != 2) {
      stop("filter formula must have the form ~ condition (one-sided formula)")
    }
  }

  # Validate data parameter
  if (!is.null(data)) {
    if (!is.character(data) || length(data) != 1 || nchar(data) == 0) {
      stop("data must be a non-empty character string (dataset name) or NULL")
    }
  }

  # Bundle all parameters into a spec
  viz_spec <- c(
    list(
      type = type,
      tabgroup = tabgroup_parsed,
      title = title,
      title_tabset = title_tabset,
      text = text,
      icon = icon,
      text_position = text_position,
      height = height,
      filter = filter,
      data = data,
      drop_na_vars = drop_na_vars
    ),
    dot_args  # Add remaining parameters from defaults/dots
  )

  # Add insertion index to preserve order
  insertion_idx <- length(viz_collection$visualizations) + 1
  viz_spec$.insertion_index <- insertion_idx
  
  # Append to the collection
  viz_collection$visualizations <- c(viz_collection$visualizations, list(viz_spec))

  viz_collection
}

#' Add Multiple Visualizations at Once
#'
#' @description
#' Convenience function to add multiple visualizations in a loop by expanding
#' vector parameters. Automatically detects which parameters should be expanded
#' to create multiple visualizations. This is useful when creating many similar
#' visualizations that differ only in one or two parameters.
#'
#' @param viz_collection A viz_collection object from create_viz()
#' @param ... Visualization parameters. Parameters with multiple values will be
#'   expanded to create multiple visualizations. Common parameters with single
#'   values will be applied to all visualizations.
#' @param .tabgroup_template Optional. Template string for tabgroup with `{i}` placeholder
#'   for the iteration index (e.g., `"skills/age/item{i}"`). You can also use
#'   parameter names in the template (e.g., `"skills/{response_var}"`).
#'   If NULL, tabgroup must be provided as a vector of the same length as expandable parameters.
#' @param .title_template Optional. Template string for title with `{i}` placeholder.
#'
#' @details
#' The function identifies "expandable" parameters (response_var, x_var, y_var,
#' stack_var, questions) and creates one visualization per value. Other parameters
#' are applied to all visualizations. All expandable vector parameters must have
#' the same length.
#'
#' Templates use glue syntax:
#' - `{i}` is replaced with the iteration number (1, 2, 3, ...)
#' - `{param_name}` is replaced with the current value of that parameter
#'
#' @return The updated viz_collection object with multiple visualizations added
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Basic expansion - create 3 timeline visualizations
#' viz <- create_viz(type = "timeline", time_var = "wave", chart_type = "line") |>
#'   add_vizzes(
#'     response_var = c("SInfo1", "SInfo2", "SInfo3"),
#'     group_var = "AgeGroup",  # Same for all
#'     .tabgroup_template = "skills/age/item{i}"
#'   )
#'
#' # Parallel expansion - titles match the variables
#' viz <- create_viz(type = "stackedbar") |>
#'   add_vizzes(
#'     x_var = c("Age", "Gender", "Education"),
#'     title = c("By Age", "By Gender", "By Education"),
#'     .tabgroup_template = "demographics/demo{i}"
#'   )
#'
#' # Use variable names in template
#' viz <- create_viz(type = "timeline") |>
#'   add_vizzes(
#'     response_var = c("SInfo1", "SInfo2", "SInfo3"),
#'     .tabgroup_template = "skills/{response_var}"
#'   )
#'
#' # Helper function pattern
#' add_all_questions <- function(viz, vars, group_var, tbgrp, demographic, wave) {
#'   wave_path <- tolower(gsub(" ", "", wave))
#'   viz |> add_vizzes(
#'     response_var = vars,
#'     group_var = group_var,
#'     .tabgroup_template = glue::glue("{tbgrp}/{wave_path}/{demographic}/item{{i}}")
#'   )
#' }
#'
#' viz <- create_viz(type = "timeline", time_var = "wave") |>
#'   add_all_questions(
#'     vars = c("var1", "var2", "var3"),
#'     group_var = "AgeGroup",
#'     tbgrp = "skills",
#'     demographic = "age",
#'     wave = "Over Time"
#'   )
#' }
add_vizzes <- function(viz_collection, ..., 
                       .tabgroup_template = NULL,
                       .title_template = NULL) {
  
  # Validate first argument
  if (!inherits(viz_collection, "viz_collection")) {
    stop("First argument must be a viz_collection object", call. = FALSE)
  }
  
  # Get parameters
  params <- list(...)
  
  # Define which parameters trigger expansion (primary viz parameters)
  EXPANDABLE_PARAMS <- c("response_var", "x_var", "y_var", "stack_var", 
                         "questions", "group_var", "title")
  
  # Find expandable params that have vectors (length > 1)
  expandable <- intersect(names(params), EXPANDABLE_PARAMS)
  vector_params <- expandable[sapply(params[expandable], length) > 1]
  
  # Check if we have anything to expand
  if (length(vector_params) == 0) {
    stop("No expandable parameters found with length > 1. ",
         "Use add_viz() for single visualizations. ",
         "Expandable parameters: ", paste(EXPANDABLE_PARAMS, collapse = ", "),
         call. = FALSE)
  }
  
  # Get number of iterations from first expandable param
  n <- length(params[[vector_params[1]]])
  
  # Validate all vector params have same length
  lengths <- sapply(params[vector_params], length)
  if (!all(lengths == n)) {
    stop("All expandable vector parameters must have the same length. Found: ",
         paste(names(lengths), "=", lengths, collapse = ", "), call. = FALSE)
  }
  
  # Special handling for tabgroup if provided as vector
  if ("tabgroup" %in% names(params) && length(params$tabgroup) == n) {
    # Tabgroup is a vector matching expansion length - treat specially
    tabgroup_vector <- params$tabgroup
    params$tabgroup <- NULL  # Remove from params
  } else {
    tabgroup_vector <- NULL
  }
  
  # Loop and call add_viz() for each iteration
  for (i in seq_len(n)) {
    # Build params for this iteration
    iter_params <- lapply(names(params), function(nm) {
      p <- params[[nm]]
      if (nm %in% vector_params) {
        p[[i]]  # Extract i-th value for expandable params
      } else {
        p  # Use same value for all (including color_palette, etc.)
      }
    })
    names(iter_params) <- names(params)
    
    # Handle tabgroup template or vector
    if (!is.null(.tabgroup_template)) {
      # Use template with glue - convert list to environment for glue
      template_data <- c(list(i = i), iter_params)
      template_env <- list2env(template_data, parent = emptyenv())
      iter_params$tabgroup <- as.character(glue::glue(.tabgroup_template, .envir = template_env))
    } else if (!is.null(tabgroup_vector)) {
      # Use pre-provided tabgroup vector
      iter_params$tabgroup <- tabgroup_vector[[i]]
    }
    # else: tabgroup might be in iter_params already as a single value
    
    # Handle title template
    if (!is.null(.title_template)) {
      template_data <- c(list(i = i), iter_params)
      template_env <- list2env(template_data, parent = emptyenv())
      iter_params$title <- as.character(glue::glue(.title_template, .envir = template_env))
    }
    
    # Call the existing add_viz() function!
    # Use do.call to pass all params including ...
    viz_collection <- do.call(add_viz, c(list(viz_collection), iter_params))
  }
  
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
#' @param logo Optional logo filename (will be copied to output directory)
#' @param favicon Optional favicon filename (will be copied to output directory)
#' @param github GitHub repository URL (optional)
#' @param twitter Twitter profile URL (optional)
#' @param linkedin LinkedIn profile URL (optional)
#' @param email Email address (optional)
#' @param website Website URL (optional)
#' @param search Enable search functionality (default: TRUE)
#' @param theme Bootstrap theme (cosmo, flatly, journal, etc.) (optional)
#' @param custom_css Path to custom CSS file (optional)
#' @param custom_scss Path to custom SCSS file (optional)
#' @param author Author name for the site (optional)
#' @param description Site description for SEO (optional)
#' @param page_footer Custom footer text (optional)
#' @param date Site creation/update date (optional)
#' @param sidebar Enable/disable global sidebar (default: FALSE)
#' @param sidebar_style Sidebar style (floating, docked, etc.) (optional)
#' @param sidebar_background Sidebar background color (optional)
#' @param navbar_style Navbar style (default, dark, light) (optional)
#' @param navbar_brand Custom brand text (optional)
#' @param navbar_toggle Mobile menu toggle behavior (optional)
#' @param math Enable/disable math rendering (katex, mathjax) (optional)
#' @param code_folding Code folding behavior (none, show, hide) (optional)
#' @param code_tools Code tools (copy, download, etc.) (optional)
#' @param toc Table of contents (floating, left, right) (optional)
#' @param toc_depth TOC depth level (default: 3)
#' @param google_analytics Google Analytics ID (optional)
#' @param plausible Plausible analytics domain (optional)
#' @param gtag Google Tag Manager ID (optional)
#' @param value_boxes Enable value box styling (default: FALSE)
#' @param metrics_style Metrics display style (optional)
#' @param shiny Enable Shiny interactivity (default: FALSE)
#' @param observable Enable Observable JS (default: FALSE)
#' @param jupyter Enable Jupyter widgets (default: FALSE)
#' @param publish_dir Custom publish directory (optional)
#' @param github_pages GitHub Pages configuration (optional)
#' @param netlify Netlify deployment settings (optional)
#' @param allow_inside_pkg Allow output directory inside package (default FALSE)
#' @param warn_before_overwrite Warn before overwriting existing files (default TRUE)
#' @param sidebar_groups List of sidebar groups for hybrid navigation (optional)
#' @param navbar_sections List of navbar sections that link to sidebar groups (optional)
#' @return A dashboard_project object
#' @export
#' @examples
#' \dontrun{
#' # Basic dashboard
#' dashboard <- create_dashboard("my_dashboard", "My Analysis Dashboard")
#'
#' # Comprehensive dashboard with all features
#' dashboard <- create_dashboard(
#'   "my_dashboard",
#'   "My Analysis Dashboard",
#'   logo = "logo.png",
#'   github = "https://github.com/username/repo",
#'   twitter = "https://twitter.com/username",
#'   theme = "cosmo",
#'   author = "Dr. Jane Smith",
#'   description = "Comprehensive data analysis dashboard",
#'   page_footer = "© 2024 Company Name",
#'   sidebar = TRUE,
#'   toc = "floating",
#'   google_analytics = "GA-XXXXXXXXX",
#'   value_boxes = TRUE,
#'   shiny = TRUE
#' )
#' }
create_dashboard <- function(output_dir = "site",
                            title = "Dashboard",
                            logo = NULL,
                            favicon = NULL,
                            github = NULL,
                            twitter = NULL,
                            linkedin = NULL,
                            email = NULL,
                            website = NULL,
                            search = TRUE,
                            theme = NULL,
                            custom_css = NULL,
                            custom_scss = NULL,
                            tabset_theme = "modern",
                            tabset_colors = NULL,
                            author = NULL,
                            description = NULL,
                            page_footer = NULL,
                            date = NULL,
                            sidebar = FALSE,
                            sidebar_style = "docked",
                            sidebar_background = "light",
                            sidebar_foreground = NULL,
                            sidebar_border = TRUE,
                            sidebar_alignment = "left",
                            sidebar_collapse_level = 2,
                            sidebar_pinned = FALSE,
                            sidebar_tools = NULL,
                            sidebar_contents = NULL,
                            breadcrumbs = TRUE,
                            page_navigation = FALSE,
                            back_to_top = FALSE,
                            reader_mode = FALSE,
                            repo_url = NULL,
                            repo_actions = NULL,
                            navbar_style = NULL,
                            navbar_brand = NULL,
                            navbar_toggle = NULL,
                            math = NULL,
                            code_folding = NULL,
                            code_tools = NULL,
                            toc = NULL,
                            toc_depth = 3,
                            google_analytics = NULL,
                            plausible = NULL,
                            gtag = NULL,
                            value_boxes = FALSE,
                            metrics_style = NULL,
                            page_layout = NULL,
                            shiny = FALSE,
                            observable = FALSE,
                            jupyter = FALSE,
                            publish_dir = NULL,
                            github_pages = NULL,
                            netlify = NULL,
                             allow_inside_pkg = FALSE,
                             warn_before_overwrite = TRUE,
                             sidebar_groups = NULL,
                             navbar_sections = NULL) {

  output_dir <- .resolve_output_dir(output_dir, allow_inside_pkg)

  # Validate tabset_theme
  valid_themes <- c("modern", "minimal", "pills", "classic", "underline", "segmented", "none")
  if (!is.null(tabset_theme) && !tabset_theme %in% valid_themes) {
    .stop_with_suggestion("tabset_theme", tabset_theme, valid_themes)
  }
  
  # Validate tabset_colors if provided
  if (!is.null(tabset_colors)) {
    if (!is.list(tabset_colors)) {
      stop("tabset_colors must be a named list (e.g., list(active_bg = '#2563eb', active_text = '#fff'))")
    }
    valid_color_keys <- c("inactive_bg", "inactive_text", "active_bg", "active_text", "hover_bg", "hover_text")
    invalid_keys <- setdiff(names(tabset_colors), valid_color_keys)
    if (length(invalid_keys) > 0) {
      warning("Unknown tabset_colors keys: ", paste(invalid_keys, collapse = ", "),
              "\nValid keys: ", paste(valid_color_keys, collapse = ", "))
    }
  }

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
    logo = logo,
    favicon = favicon,
    github = github,
    twitter = twitter,
    linkedin = linkedin,
    email = email,
    website = website,
    search = search,
    theme = theme,
    custom_css = custom_css,
    custom_scss = custom_scss,
    tabset_theme = tabset_theme,
    tabset_colors = tabset_colors,
    author = author,
    description = description,
    page_footer = page_footer,
    date = date,
    sidebar = sidebar,
    sidebar_style = sidebar_style,
    sidebar_background = sidebar_background,
    sidebar_foreground = sidebar_foreground,
    sidebar_border = sidebar_border,
    sidebar_alignment = sidebar_alignment,
    sidebar_collapse_level = sidebar_collapse_level,
    sidebar_pinned = sidebar_pinned,
    sidebar_tools = sidebar_tools,
    sidebar_contents = sidebar_contents,
    breadcrumbs = breadcrumbs,
    page_navigation = page_navigation,
    back_to_top = back_to_top,
    reader_mode = reader_mode,
    repo_url = repo_url,
    repo_actions = repo_actions,
    navbar_style = navbar_style,
    navbar_brand = navbar_brand,
    navbar_toggle = navbar_toggle,
    math = math,
    code_folding = code_folding,
    code_tools = code_tools,
    toc = toc,
    toc_depth = toc_depth,
    google_analytics = google_analytics,
    plausible = plausible,
    gtag = gtag,
    value_boxes = value_boxes,
    metrics_style = metrics_style,
    page_layout = page_layout,
    shiny = shiny,
    observable = observable,
    jupyter = jupyter,
    publish_dir = publish_dir,
    github_pages = github_pages,
    netlify = netlify,
    allow_inside_pkg = allow_inside_pkg,
    warn_before_overwrite = warn_before_overwrite,
    sidebar_groups = sidebar_groups,
    navbar_sections = navbar_sections,
    pages = list(),
    data_files = NULL
  ), class = "dashboard_project")
}

#' Add a page to the dashboard
#'
#' Universal function for adding any type of page to the dashboard. Can create
#' landing pages, analysis pages, about pages, or any combination of text and
#' visualizations. All content is markdown-compatible.
#'
#' @param proj A dashboard_project object
#' @param name Page display name
#' @param data Optional data frame to save for this page. Can also be a named list of data frames
#'   for using multiple datasets: `list(survey = df1, demographics = df2)`
#' @param data_path Path to existing data file (alternative to data parameter). Can also be a named
#'   list of file paths for multiple datasets
#' @param template Optional custom template file path
#' @param params Parameters for template substitution
#' @param visualizations viz_collection or list of visualization specs
#' @param text Optional markdown text content for the page
#' @param icon Optional iconify icon shortcode (e.g., "ph:users-three")
#' @param is_landing_page Whether this should be the landing page (default: FALSE)
#' @param tabset_theme Optional tabset theme for this page (overrides dashboard-level theme)
#' @param tabset_colors Optional tabset colors for this page (overrides dashboard-level colors)
#' @param navbar_align Position of page in navbar: "left" (default) or "right"
#' @param overlay Whether to show a loading overlay on page load (default: FALSE)
#' @param overlay_theme Theme for loading overlay: "light", "glass", "dark", or "accent" (default: "light")
#' @param overlay_text Text to display in loading overlay (default: "Loading")
#' @return The updated dashboard_project object
#' @export
#' @examples
#' \dontrun{
#' # Landing page
#' dashboard <- create_dashboard("test") %>%
#'   add_page("Welcome", text = "# Welcome\n\nThis is the main page.", is_landing_page = TRUE)
#'
#' # Analysis page with data and visualizations
#' dashboard <- dashboard %>%
#'   add_page("Demographics", data = survey_data, visualizations = demo_viz)
#'
#' # Text-only about page
#' dashboard <- dashboard %>%
#'   add_page("About", text = "# About This Study\n\nThis dashboard shows...")
#'
#' # Mixed content page
#' dashboard <- dashboard %>%
#'   add_page("Results", text = "# Key Findings\n\nHere are the results:",
#'            visualizations = results_viz, icon = "ph:chart-line")
#' }
add_dashboard_page <- function(proj, name, data = NULL, data_path = NULL,
                               template = NULL, params = list(),
                               visualizations = NULL, text = NULL, icon = NULL,
                               is_landing_page = FALSE,
                               tabset_theme = NULL, tabset_colors = NULL,
                               navbar_align = c("left", "right"),
                               overlay = FALSE,
                               overlay_theme = c("light", "glass", "dark", "accent"),
                               overlay_text = "Loading") {
  if (!inherits(proj, "dashboard_project")) {
    stop("proj must be a dashboard_project object")
  }
  
  # Validate and match navbar alignment
  navbar_align <- match.arg(navbar_align)
  
  # Validate overlay parameters
  if (overlay) {
    overlay_theme <- match.arg(overlay_theme)
  }
  
  # Use dashboard-level tabset theme if page-level not specified
  if (is.null(tabset_theme)) {
    tabset_theme <- proj$tabset_theme
  }
  
  # Use dashboard-level tabset colors if page-level not specified
  if (is.null(tabset_colors)) {
    tabset_colors <- proj$tabset_colors
  }

  # Handle data storage with deduplication
  # Check if data is a named list (multiple datasets)
  # Must check all conditions explicitly to avoid issues
  is_multi_dataset <- FALSE
  if (!is.null(data)) {
    if (is.list(data)) {
      if (!is.data.frame(data)) {
        if (!is.null(names(data)) && length(names(data)) > 0) {
          is_multi_dataset <- TRUE
        }
      }
    }
  }
  
  if (is_multi_dataset) {
    # Multiple datasets - save each one
    if (is.null(data_path)) {
      data_path <- list()
      
      for (dataset_name in names(data)) {
        dataset <- data[[dataset_name]]
        
        # Validate that each dataset is actually a data frame
        if (!is.data.frame(dataset)) {
          stop("Dataset '", dataset_name, "' must be a data frame, got: ", class(dataset)[1])
        }
        
        # Check if we've already saved this exact dataset
        data_hash <- digest::digest(dataset)
        existing_data <- proj$data_files %||% list()
        
        dataset_path <- NULL
        for (existing_path in names(existing_data)) {
          if (existing_data[[existing_path]] == data_hash) {
            dataset_path <- existing_path
            break
          }
        }
        
        # If not found, create a new descriptive filename
        if (is.null(dataset_path)) {
          data_file_name <- paste0(dataset_name, "_", nrow(dataset), "obs.rds")
          dataset_path <- data_file_name
          
          # Track this dataset
          if (is.null(proj$data_files)) {
            proj$data_files <- list()
          }
          proj$data_files[[dataset_path]] <- data_hash
        }
        
        # Save the data file
        output_dir <- .resolve_output_dir(proj$output_dir, proj$allow_inside_pkg)
        if (!dir.exists(output_dir)) {
          dir.create(output_dir, recursive = TRUE)
        }
        saveRDS(dataset, file.path(output_dir, basename(dataset_path)))
        
        data_path[[dataset_name]] <- basename(dataset_path)
      }
    }
  } else if (!is.null(data)) {
    # Single dataset (original logic)
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
        data_name <- "dataset"
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
    viz_specs <- .process_visualizations(visualizations, data_path)
  }

  # Create page record
  page <- list(
    name = name,
    data_path = data_path,
    is_multi_dataset = is_multi_dataset,
    template = template,
    params = params,
    visualizations = viz_specs,
    text = text,
    icon = icon,
    is_landing_page = is_landing_page,
    tabset_theme = tabset_theme,
    tabset_colors = tabset_colors,
    navbar_align = navbar_align,
    overlay = overlay,
    overlay_theme = if(overlay) overlay_theme else NULL,
    overlay_text = if(overlay) overlay_text else NULL
  )

  proj$pages[[name]] <- page

  # Store landing page info if this is the landing page
  if (is_landing_page) {
    proj$landing_page <- name
  }

  proj
}

#' Add Page to Dashboard (Alias)
#'
#' Convenient alias for \code{\link{add_dashboard_page}}. Adds a new page to a dashboard project.
#'
#' @param proj Dashboard project object created by \code{\link{create_dashboard}}.
#' @param ... All arguments passed to \code{\link{add_dashboard_page}}.
#'
#' @return Modified dashboard project with the new page added.
#'
#' @seealso \code{\link{add_dashboard_page}} for full parameter documentation.
#'
#' @export
add_page <- add_dashboard_page


#' Create iconify icon shortcode
#'
#' Helper function to generate iconify icon shortcodes for use in pages and visualizations.
#'
#' @param icon_name Icon name in format "collection:name" (e.g., "ph:users-three")
#' @return Iconify shortcode string
#' @export
#' @examples
#' \dontrun{
#' icon("ph:users-three")  # Returns iconify shortcode
#' icon("emojione:flag-for-united-states")  # Returns iconify shortcode
#' }
icon <- function(icon_name) {
  # Convert "collection:name" to "{{< iconify collection name >}}"
  parts <- strsplit(icon_name, ":", fixed = TRUE)[[1]]
  if (length(parts) != 2) {
    stop("Icon name must be in format 'collection:name' (e.g., 'ph:users-three')")
  }
  paste0("{{< iconify ", parts[1], " ", parts[2], " >}}")
}

#' Create a Bootstrap card component
#'
#' Helper function to create Bootstrap card components for displaying content in a structured way.
#' Useful for author profiles, feature highlights, or any content that benefits from card layout.
#'
#' @param content Card content (text, HTML, or other elements)
#' @param title Optional card title
#' @param image Optional image URL or path
#' @param image_alt Alt text for the image
#' @param footer Optional card footer content
#' @param class Additional CSS classes for the card
#' @param style Additional inline styles for the card
#' @return HTML div element with Bootstrap card classes
#' @export
#' @examples
#' \dontrun{
#' # Simple text card
#' card("This is a simple card with just text content")
#'
#' # Card with title and image
#' card(
#'   content = "This is the card body content",
#'   title = "Card Title",
#'   image = "https://example.com/image.jpg",
#'   image_alt = "Description of image"
#' )
#'
#' # Author card
#' card(
#'   content = "Dr. Jane Smith is a researcher specializing in data science and visualization.",
#'   title = "Dr. Jane Smith",
#'   image = "https://example.com/jane.jpg",
#'   footer = "Website: janesmith.com"
#' )
#' }
card <- function(content, title = NULL, image = NULL, image_alt = NULL,
                footer = NULL, class = NULL, style = NULL) {

  # Start building the card
  card_classes <- c("card", class)
  card_style <- style

  # Create the card structure
  card_div <- htmltools::div(
    class = paste(card_classes, collapse = " "),
    style = card_style
  )

  # Add image if provided
  if (!is.null(image)) {
    image_div <- htmltools::div(
      class = "card-img-top",
      htmltools::img(
        src = image,
        alt = image_alt %||% "",
        class = "img-fluid",
        style = "width: 100%; height: auto;"
      )
    )
    card_div <- htmltools::tagAppendChild(card_div, image_div)
  }

  # Create card body
  card_body <- htmltools::div(class = "card-body")

  # Add title if provided
  if (!is.null(title)) {
    title_div <- htmltools::div(
      class = "card-title",
      htmltools::h5(title)
    )
    card_body <- htmltools::tagAppendChild(card_body, title_div)
  }

  # Add content
  content_div <- htmltools::div(
    class = "card-text",
    content
  )
  card_body <- htmltools::tagAppendChild(card_body, content_div)

  # Add card body to card
  card_div <- htmltools::tagAppendChild(card_div, card_body)

  # Add footer if provided
  if (!is.null(footer)) {
    footer_div <- htmltools::div(
      class = "card-footer text-muted",
      footer
    )
    card_div <- htmltools::tagAppendChild(card_div, footer_div)
  }

  return(card_div)
}

#' Display cards in a Bootstrap row
#'
#' Helper function to display multiple cards in a responsive Bootstrap row layout.
#'
#' @param ... Card objects to display
#' @param cols Number of columns per row (default: 2)
#' @param class Additional CSS classes for the row
#' @return HTML div element with Bootstrap row classes containing the cards
#' @export
#' @examples
#' \dontrun{
#' # Display two cards in a row
#' card_row(card1, card2)
#'
#' # Display three cards in a row (3 columns)
#' card_row(card1, card2, card3, cols = 3)
#' }
card_row <- function(..., cols = 2, class = NULL) {
  cards <- list(...)

  # Calculate Bootstrap column class
  col_class <- paste0("col-md-", 12 %/% cols)

  # Create row with cards
  row_div <- htmltools::div(
    class = paste(c("row", class), collapse = " "),
    lapply(cards, function(card) {
      htmltools::div(class = col_class, card)
    })
  )

  return(row_div)
}

#' Create multi-line markdown text content
#'
#' Helper function to create readable multi-line markdown text content for pages.
#' Automatically handles line breaks and formatting for better readability.
#'
#' @param ... Text content as separate arguments or character vectors
#' @return Single character string with proper line breaks
#' @export
#' @examples
#' \dontrun{
#' # Method 1: Separate arguments
#' text_content <- md_text(
#'   "# Welcome",
#'   "",
#'   "This is a multi-line text block.",
#'   "",
#'   "## Features",
#'   "- Feature 1",
#'   "- Feature 2"
#' )
#'
#' # Method 2: Character vectors
#' lines <- c("# About", "", "This is about our study.")
#' text_content <- md_text(lines)
#'
#' # Use in add_page
#' add_page("About", text = text_content)
#' }
md_text <- function(...) {
  # Combine all arguments into a single character vector
  args <- list(...)
  content <- character(0)

  for (arg in args) {
    if (is.character(arg)) {
      content <- c(content, arg)
    } else {
      content <- c(content, as.character(arg))
    }
  }

  # Join with newlines
  paste(content, collapse = "\n")
}

#' Create text content from a character vector
#'
#' Alternative helper for creating text content from existing character vectors.
#'
#' @param lines Character vector of text lines
#' @return Single character string with proper line breaks
#' @export
#' @examples
#' \dontrun{
#' lines <- c("# Title", "", "Content here")
#' text_content <- text_lines(lines)
#' add_page("Page", text = text_content)
#' }
text_lines <- function(lines) {
  paste(lines, collapse = "\n")
}

# ===================================================================
# Automatic Iconify Extension Installation
# ===================================================================

#' Check if any icons are used in the dashboard
#'
#' Internal function to detect if iconify shortcodes are present
#' in the dashboard content.
#'
#' @param proj A dashboard_project object
#' @return Logical indicating if icons are present
#' @keywords internal
.check_for_icons <- function(proj) {

  # Check all pages
  for (page in proj$pages) {
    if (!is.null(page$icon)) {
      return(TRUE)
    }

    # Check visualizations
    if (!is.null(page$visualizations)) {
      for (viz in page$visualizations) {
        if (!is.null(viz$icon)) {
          return(TRUE)
        }
        # Check nested visualizations in tab groups
        if (viz$type == "tabgroup" && !is.null(viz$visualizations)) {
          for (nested_viz in viz$visualizations) {
            if (!is.null(nested_viz$icon)) {
              return(TRUE)
            }
          }
        }
      }
    }
  }

  # Check navbar sections for icons
  if (!is.null(proj$navbar_sections)) {
    for (section in proj$navbar_sections) {
      if (!is.null(section$icon)) {
        return(TRUE)
      }
    }
  }

  FALSE
}

#' Install iconify extension automatically
#'
#' Downloads and installs the official iconify extension to the project directory
#' if icons are detected in the dashboard.
#'
#' @param output_dir The dashboard output directory
#' @return Logical indicating if installation was successful
#' @keywords internal
.install_iconify_extension <- function(output_dir) {
  # Check if Quarto is available
  quarto_result <- tryCatch({
    system2("quarto", "--version", stdout = TRUE, stderr = TRUE)
  }, error = function(e) {
    NULL
  })

  if (is.null(quarto_result) || length(quarto_result) == 0) {
    warning("Quarto is not installed. Cannot install iconify extension automatically.")
    message("To install Quarto: https://quarto.org/docs/get-started/")
    message("Or install the extension manually:")
    message("  quarto add mcanouil/quarto-iconify")
    return(FALSE)
  }

  # Check if iconify extension is already installed
  iconify_dir <- file.path(output_dir, "_extensions", "mcanouil", "iconify")
  if (dir.exists(iconify_dir) && file.exists(file.path(iconify_dir, "_extension.yml"))) {
    message("Iconify extension already installed")
    return(TRUE)
  }

  # Try to install using Quarto CLI
  tryCatch({
    message("Installing iconify extension using Quarto CLI...")

    # Save current working directory
    old_wd <- getwd()
    setwd(output_dir)
    on.exit(setwd(old_wd), add = TRUE)

    # Use Quarto's official extension installation command
    # The --no-prompt flag avoids interactive prompts
    result <- system2("quarto",
                     c("add", "mcanouil/quarto-iconify", "--no-prompt"),
                     stdout = TRUE,
                     stderr = TRUE)

    # Check for errors
    if (!is.null(attr(result, "status")) && attr(result, "status") != 0) {
      warning("Failed to install iconify extension via Quarto CLI")
      message("Output: ", paste(result, collapse = "\n"))
      message("\nTry installing manually from the output directory:")
      message("  cd ", output_dir)
      message("  quarto add mcanouil/quarto-iconify")
      return(FALSE)
    }

    # Verify installation
    if (dir.exists(iconify_dir) && file.exists(file.path(iconify_dir, "_extension.yml"))) {
      message("Iconify extension installed successfully")
      return(TRUE)
    } else {
      warning("Iconify extension files not found after installation")
      message("Please install manually:")
      message("  cd ", output_dir)
      message("  quarto add mcanouil/quarto-iconify")
      return(FALSE)
    }

  }, error = function(e) {
    warning("Failed to install iconify extension: ", e$message)
    message("Please install manually:")
    message("  cd ", output_dir)
    message("  quarto add mcanouil/quarto-iconify")
    return(FALSE)
  })
}

# ===================================================================
# CLI Output and Display Functions
# ===================================================================

#' Show beautiful dashboard summary
#'
#' Internal function that displays a comprehensive summary of the generated
#' dashboard files and provides helpful guidance to users.
#'
#' @param proj A dashboard_project object
#' @param output_dir Path to the output directory
#' @return Invisible NULL
#' @keywords internal
.show_dashboard_summary <- function(proj, output_dir, elapsed_time = NULL, build_info = NULL, show_progress = TRUE) {
  if (!show_progress) return(invisible(NULL))
  
  cat("\n")
  cat("╔═══════════════════════════════════════════════════╗\n")
  cat("║     🎉 DASHBOARD GENERATED SUCCESSFULLY! 🎉      ║\n")
  cat("╚═══════════════════════════════════════════════════╝\n")
  cat("\n")

  # Dashboard info with enhanced formatting
  cat("📊 Dashboard:", proj$title, "\n")
  cat("📁 Location:", output_dir, "\n")
  cat("📄 Pages:", length(proj$pages), "\n")

  # Count visualizations
  total_viz <- 0
  for (page in proj$pages) {
    if (!is.null(page$visualizations)) {
      total_viz <- total_viz + length(page$visualizations)
    }
  }
  cat("📈 Visualizations:", total_viz, "\n")
  
  # Show build info if available (incremental builds)
  if (!is.null(build_info)) {
    if (length(build_info$regenerated) > 0) {
      cat("🔄 Regenerated:", length(build_info$regenerated), "page(s)\n")
    }
    if (length(build_info$skipped) > 0) {
      cat("⏭️  Skipped:", length(build_info$skipped), "unchanged page(s)\n")
    }
  }
  
  # Display generation time if available
  if (!is.null(elapsed_time)) {
    time_str <- if (elapsed_time < 1) {
      paste0(round(elapsed_time * 1000, 1), " ms")
    } else if (elapsed_time < 60) {
      paste0(round(elapsed_time, 2), " seconds")
    } else {
      mins <- floor(elapsed_time / 60)
      secs <- round(elapsed_time %% 60, 1)
      paste0(mins, " min ", secs, " sec")
    }
    cat("⏱️  Total time:", time_str, "\n")
  }

  cat("\n")
  cat("📁 GENERATED FILES:\n")
  cat(paste(rep("─", 30), collapse = ""), "\n")

  # List all generated files (exclude site_libs and hidden files)
  files <- list.files(output_dir, recursive = TRUE, full.names = FALSE)
  files <- files[!grepl("^\\.", files)] # Exclude hidden files
  files <- files[!grepl("^docs/site_libs/", files)] # Exclude site_libs files

  # Group files by type
  qmd_files <- files[grepl("\\.qmd$", files)]
  rds_files <- files[grepl("\\.rds$", files)]
  yml_files <- files[grepl("\\.yml$", files)]
  other_files <- files[!grepl("\\.(qmd|rds|yml)$", files)]

  # Display QMD files (pages)
  if (length(qmd_files) > 0) {
    cat("📄 Pages (QMD files):\n")
    for (file in sort(qmd_files)) {
      page_name <- gsub("\\.qmd$", "", file)
      page_name <- gsub("_", " ", page_name)
      page_name <- tools::toTitleCase(page_name)
      cat("   • ", file, " → ", page_name, "\n", sep = "")
    }
    cat("\n")
  }

  # Display data files with page mapping
  if (length(rds_files) > 0) {
    cat("💾 Data files:\n")
    
    # Build mapping from data files to pages
    data_to_pages <- list()
    for (page_name in names(proj$pages)) {
      page <- proj$pages[[page_name]]
      if (!is.null(page$data_path)) {
        if (is.list(page$data_path)) {
          # Multiple datasets
          for (dataset_name in names(page$data_path)) {
            data_file <- basename(page$data_path[[dataset_name]])
            if (is.null(data_to_pages[[data_file]])) {
              data_to_pages[[data_file]] <- list(pages = c(), dataset_name = dataset_name)
            }
            data_to_pages[[data_file]]$pages <- c(data_to_pages[[data_file]]$pages, page_name)
          }
        } else {
          # Single dataset
          data_file <- basename(page$data_path)
          if (is.null(data_to_pages[[data_file]])) {
            data_to_pages[[data_file]] <- list(pages = c(), dataset_name = NULL)
          }
          data_to_pages[[data_file]]$pages <- c(data_to_pages[[data_file]]$pages, page_name)
        }
      }
    }
    
    for (file in sort(rds_files)) {
      file_size <- file.size(file.path(output_dir, file))
      size_str <- if (file_size > 1024*1024) {
        paste0(round(file_size/(1024*1024), 1), " MB")
      } else if (file_size > 1024) {
        paste0(round(file_size/1024, 1), " KB")
      } else {
        paste0(file_size, " B")
      }
      
      # Show which pages use this data
      if (!is.null(data_to_pages[[file]]) && length(data_to_pages[[file]]$pages) > 0) {
        pages_str <- paste(data_to_pages[[file]]$pages, collapse = ", ")
        cat("   • ", file, " (", size_str, ") → Used by: ", pages_str, "\n", sep = "")
      } else {
        cat("   • ", file, " (", size_str, ")\n", sep = "")
      }
    }
    cat("\n")
  }

  # Display configuration files
  if (length(yml_files) > 0) {
    cat("⚙️  Configuration:\n")
    for (file in sort(yml_files)) {
      cat("   • ", file, "\n", sep = "")
    }
    cat("\n")
  }

  # Display other files
  if (length(other_files) > 0) {
    cat("📎 Other files:\n")
    for (file in sort(other_files)) {
      cat("   • ", file, "\n", sep = "")
    }
    cat("\n")
  }

  # Next steps
  cat("🚀 NEXT STEPS:\n")
  cat(paste(rep("─", 30), collapse = ""), "\n")
  cat("1. Edit your dashboard:\n")
  cat("   • Modify QMD files to customize content and styling\n")
  cat("   • Add more visualizations using add_viz() with height parameters\n")
  cat("   • Customize the _quarto.yml configuration file\n")
  cat("\n")
  cat("2. Generate a new dashboard:\n")
  cat("   • Use create_dashboard() %>% add_page() %>% generate_dashboard()\n")
  cat("   • Try different themes, layouts, and features\n")
  cat("   • Experiment with height parameters for better proportions\n")
  cat("\n")
  cat("3. Deploy your dashboard:\n")
  cat("   • Use Quarto's publishing features (GitHub Pages, Netlify, etc.)\n")
  cat("   • Share the docs/ folder contents\n")
  cat("\n")


  cat("🎯 Happy dashing!\n")
  cat(paste(rep("═", 50), collapse = ""), "\n")
  cat("\n")

  invisible(NULL)
}

# ===================================================================
# Internal Visualization Processing
# ===================================================================

#' Process visualizations into organized specs with tab groups
#'
#' Unified internal function that handles both viz_collection and plain list inputs,
#' organizing visualizations into standalone items and tab groups based on their
#' tabgroup parameter.
#'
#' @param viz_input Either a viz_collection object or a plain list of visualization specs
#' @param data_path Path to the data file for this page (will be attached to each viz)
#' @param tabgroup_labels Optional named list/vector of custom display labels for tab groups
#' @return List of processed visualization specs, with standalone visualizations first,
#'         followed by tab group objects
#' @details
#' Build a hierarchy key from a tabgroup vector
#' @noRd
.build_hierarchy_key <- function(tabgroup_vec) {
  if (is.null(tabgroup_vec) || length(tabgroup_vec) == 0) {
    return(NULL)
  }
  paste(tabgroup_vec, collapse = "/")
}

#' Get filter signature for matching
#'
#' Internal helper to get a comparable string representation of a filter.
#'
#' @param viz A visualization specification
#' @return Character string representation of the filter
#' @noRd
.get_filter_signature <- function(viz) {
  if (is.null(viz$filter)) {
    return("")
  }
  paste(deparse(viz$filter[[2]]), collapse = " ")
}

#' Reorganize nested tabs to match with filter-matched parents
#' 
#' When we have multiple parent tabs with different filters (e.g., Wave 1, Wave 2),
#' and nested tabs with matching filters, we need to nest each child under its
#' matching parent, not create a shared nested structure.
#' @noRd
.reorganize_nested_tabs_by_filter <- function(tree) {
  if (is.null(tree$children) || length(tree$children) == 0) {
    return(tree)
  }
  
  # Process each child level
  for (child_name in names(tree$children)) {
    child_node <- tree$children[[child_name]]
    
    # Check if this level has visualizations (parent tabs) and nested children
    has_parent_viz <- !is.null(child_node$visualizations) && length(child_node$visualizations) > 0
    has_nested_children <- !is.null(child_node$children) && length(child_node$children) > 0
    
    if (has_parent_viz && has_nested_children && length(child_node$visualizations) > 1) {
      # Multiple parent tabs - need to reorganize nested children per parent
      
      # Group parent visualizations by filter
      parent_groups <- list()
      for (viz in child_node$visualizations) {
        filter_sig <- .get_filter_signature(viz)
        if (is.null(parent_groups[[filter_sig]])) {
          parent_groups[[filter_sig]] <- list()
        }
        parent_groups[[filter_sig]] <- c(parent_groups[[filter_sig]], list(viz))
      }
      
      # For each nested child level, match to parent groups
      nested_children <- child_node$children
      child_node$children <- list()
      
      # Create separate nested structures for each parent group
      for (filter_sig in names(parent_groups)) {
        parent_viz_list <- parent_groups[[filter_sig]]
        
        # Find nested children with matching filters
        matching_nested <- list()
        for (nested_name in names(nested_children)) {
          nested_node <- nested_children[[nested_name]]
          
          # Check if any visualization in nested node matches the filter
          if (!is.null(nested_node$visualizations)) {
            for (nested_viz in nested_node$visualizations) {
              nested_filter_sig <- .get_filter_signature(nested_viz)
              if (nested_filter_sig == filter_sig || nested_filter_sig == "") {
                # Match found - include this nested node
                if (is.null(matching_nested[[nested_name]])) {
                  matching_nested[[nested_name]] <- nested_node
                } else {
                  # Merge visualizations if node already exists
                  matching_nested[[nested_name]]$visualizations <- c(
                    matching_nested[[nested_name]]$visualizations,
                    nested_node$visualizations
                  )
                }
                break
              }
            }
          }
        }
        
        # Attach matching nested children to first parent viz
        # We'll create separate tabgroup structures for each parent group
        if (length(matching_nested) > 0) {
          # Store nested structure reference in parent visualization
          # The first parent viz will carry the nested structure
          if (length(parent_viz_list) > 0) {
            parent_viz_list[[1]]$nested_children <- matching_nested
          }
        }
        
        # Add all parent visualizations to this group
        for (parent_viz in parent_viz_list) {
          child_node$visualizations <- c(child_node$visualizations, list(parent_viz))
        }
      }
    } else {
      # Recursively process nested levels
      child_node <- .reorganize_nested_tabs_by_filter(child_node)
    }
    
    tree$children[[child_name]] <- child_node
  }
  
  return(tree)
}

#' Merge filtered trees into final structure
#'
#' Takes trees grouped by root name and filter, and merges them so that
#' each filter group becomes a separate parent tab with its own nested structure.
#'
#' @param all_trees List of trees grouped by root name, then by filter
#' @param tabgroup_labels Custom labels for tabgroups
#' @return Final list of visualization specifications with nested tabgroups
#' @noRd
.merge_filtered_trees <- function(all_trees, tabgroup_labels = NULL) {
  result <- list()
  
  # Handle root-level visualizations first
  if (!is.null(all_trees[["__root__"]])) {
    root_result <- .tree_to_viz_list(all_trees[["__root__"]], tabgroup_labels)
    result <- c(result, root_result)
  }
  
  # Process each root tabgroup
  for (root_name in names(all_trees)) {
    if (root_name == "__root__") next
    
    root_data <- all_trees[[root_name]]
    
    # If only one filter group, process normally
    if (is.list(root_data) && !is.null(root_data$visualizations)) {
      # Single tree - process normally
      root_result <- .tree_to_viz_list(root_data, tabgroup_labels)
      
      # Look up custom display label
      display_label <- NULL
      if (!is.null(tabgroup_labels) && length(tabgroup_labels) > 0) {
        if (!is.null(names(tabgroup_labels)) && root_name %in% names(tabgroup_labels)) {
          display_label <- tabgroup_labels[[root_name]]
        } else if (is.list(tabgroup_labels) && root_name %in% names(tabgroup_labels)) {
          display_label <- tabgroup_labels[[root_name]]
        }
      }
      
      # Add as tabgroup
      result <- c(result, list(list(
        type = "tabgroup",
        name = root_name,
        label = display_label,
        visualizations = root_result
      )))
    } else {
      # Multiple filter groups - each gets its own structure
      # Collect all parent tabs and their nested structures
      parent_tabs <- list()
      
      # Separate filtered and non-filtered items
      # Empty filter signature means no filter - these should be added directly to tabgroup
      non_filtered_items <- list()
      
      for (filter_sig in names(root_data)) {
        filter_tree <- root_data[[filter_sig]]
        
        # Handle non-filtered items separately
        # Check for the sentinel value we use for non-filtered items
        is_no_filter <- isTRUE(filter_sig == "__no_filter__")
        
        if (is_no_filter) {
          # No filter - check if this has nested structure or just visualizations
          has_nested_children <- !is.null(filter_tree$children) && length(filter_tree$children) > 0
          has_root_viz <- !is.null(filter_tree$visualizations) && length(filter_tree$visualizations) > 0
          
          if (has_nested_children && !has_root_viz) {
            # This is a nested structure without a parent viz (like timeline items)
            # We need to create a parent tab for it
            # Convert the tree and wrap it as a parent tab
            nested_content <- .tree_to_viz_list(filter_tree, tabgroup_labels)
            
            # Create a virtual parent visualization that will hold these nested items
            # The tab label will be "Over Time" (or can be customized in the future)
            parent_viz <- list(
              type = "placeholder",  # Won't render content, just holds nested_children
              title_tabset = "Over Time",  # Use title_tabset for tab label
              nested_children = nested_content
            )
            
            non_filtered_items <- c(non_filtered_items, list(parent_viz))
          } else {
            # Standard non-filtered items - convert tree directly
            non_filtered_result <- .tree_to_viz_list(filter_tree, tabgroup_labels)
            non_filtered_items <- c(non_filtered_items, non_filtered_result)
          }
          next  # Skip to next filter group
        }
        
        # The filter_tree structure (after removing root prefix):
        # - visualizations: [parent viz]  (for tabgroup = "sis")
        # - children: { "age": { children: { "item1": { visualizations: [nested_viz] } } } }
        
        # Get parent visualizations from root level
        if (!is.null(filter_tree$visualizations) && length(filter_tree$visualizations) > 0) {
          parent_viz_list <- filter_tree$visualizations
          
          # Process each parent viz (usually just one, but handle multiple)
          for (parent_viz in parent_viz_list) {
            # Process nested children if they exist
            if (!is.null(filter_tree$children) && length(filter_tree$children) > 0) {
              # Create a tree with just this parent and its nested children
              parent_tree <- list(
                visualizations = list(parent_viz),
                children = filter_tree$children
              )
              
              # Convert to viz list - this will handle nested structures correctly
              # We're processing nested children, so pass is_nested_context = TRUE
              parent_result <- .tree_to_viz_list(parent_tree, tabgroup_labels, is_nested_context = TRUE)
              
              # If parent_result has the parent viz first, followed by nested tabgroups,
              # attach the nested tabgroups to the parent viz so they appear INSIDE the parent tab
              if (length(parent_result) > 0) {
                # Separate visualizations and tabgroups
                vizes <- list()
                tabgroups <- list()
                
                for (item in parent_result) {
                  if (!is.null(item$type) && item$type == "tabgroup") {
                    tabgroups <- c(tabgroups, list(item))
                  } else {
                    vizes <- c(vizes, list(item))
                  }
                }
                
                # If we have visualizations AND tabgroups, attach tabgroups to first viz
                if (length(vizes) > 0 && length(tabgroups) > 0) {
                  parent_viz_with_nested <- vizes[[1]]
                  parent_viz_with_nested$nested_children <- tabgroups
                  parent_tabs <- c(parent_tabs, list(parent_viz_with_nested))
                  # Add remaining visualizations if any
                  if (length(vizes) > 1) {
                    for (i in 2:length(vizes)) {
                      parent_tabs <- c(parent_tabs, list(vizes[[i]]))
                    }
                  }
                } else {
                  # Standard case - add all items as they are
                  for (item in parent_result) {
                    parent_tabs <- c(parent_tabs, list(item))
                  }
                }
              }
            } else {
              # No nested children - just add the parent viz
              parent_tabs <- c(parent_tabs, list(parent_viz))
            }
          }
        }
      }
      
      # Add non-filtered items to parent tabs
      # These appear alongside filtered items (e.g., "Over Time" alongside "Wave 1", "Wave 2")
      if (length(non_filtered_items) > 0) {
        parent_tabs <- c(parent_tabs, non_filtered_items)
      }
      
      # Look up custom display label
      display_label <- NULL
      if (!is.null(tabgroup_labels) && length(tabgroup_labels) > 0) {
        if (!is.null(names(tabgroup_labels)) && root_name %in% names(tabgroup_labels)) {
          display_label <- tabgroup_labels[[root_name]]
        } else if (is.list(tabgroup_labels) && root_name %in% names(tabgroup_labels)) {
          display_label <- tabgroup_labels[[root_name]]
        }
      }
      
      # Create tabgroup with all parent tabs (filtered + non-filtered)
      result <- c(result, list(list(
        type = "tabgroup",
        name = root_name,
        label = display_label,
        visualizations = parent_tabs
      )))
    }
  }
  
  result
}

.insert_into_hierarchy <- function(tree, tabgroup_vec, viz) {
  if (is.null(tabgroup_vec) || length(tabgroup_vec) == 0) {
    # No tabgroup - add to root level
    tree$visualizations <- c(tree$visualizations, list(viz))
    return(tree)
  }
  
  # Recursive helper to insert at the right level
  .insert_recursive <- function(node, path, viz_to_insert) {
    if (length(path) == 0) {
      # We've reached the target level - add the viz here
      node$visualizations <- c(node$visualizations, list(viz_to_insert))
      return(node)
    }
    
    # Get the first level name and remaining path
    level_name <- path[1]
    remaining_path <- if (length(path) > 1) path[-1] else character(0)
    
    # Initialize children list if needed
    if (is.null(node$children)) {
      node$children <- list()
    }
    
    # Get or create child node
    if (is.null(node$children[[level_name]])) {
      node$children[[level_name]] <- list(
        name = level_name,
        visualizations = list(),
        children = list(),
        .min_index = Inf  # Track minimum insertion index for sorting
      )
    }
    
    # Update minimum index for this node
    if (!is.null(viz_to_insert$.insertion_index)) {
      current_min <- node$children[[level_name]]$.min_index %||% Inf
      node$children[[level_name]]$.min_index <- min(current_min, viz_to_insert$.insertion_index)
    }
    
    # Recursively insert into child node
    node$children[[level_name]] <- .insert_recursive(
      node$children[[level_name]], 
      remaining_path, 
      viz_to_insert
    )
    
    return(node)
  }
  
  # Use recursive helper
  tree <- .insert_recursive(tree, tabgroup_vec, viz)
  return(tree)
}

#' Convert hierarchy tree to flat list of viz specs and nested tabgroups
#' @param tree Hierarchy tree to convert
#' @param tabgroup_labels Custom labels for tabgroups
#' @param is_nested_context Whether we're in a nested context (processing children)
#' @noRd
.tree_to_viz_list <- function(tree, tabgroup_labels = NULL, is_nested_context = FALSE) {
  result <- list()
  
  # Add standalone visualizations at this level
  if (!is.null(tree$visualizations) && length(tree$visualizations) > 0) {
    for (viz in tree$visualizations) {
      result <- c(result, list(viz))
    }
  }
  
  # Process children (nested tabgroups)
  if (!is.null(tree$children) && length(tree$children) > 0) {
    # Sort children by insertion order (min_index) instead of alphabetically
    child_names <- names(tree$children)
    child_indices <- sapply(child_names, function(nm) {
      tree$children[[nm]]$.min_index %||% Inf
    })
    child_names_sorted <- child_names[order(child_indices)]
    
    for (child_name in child_names_sorted) {
      child_node <- tree$children[[child_name]]
      
      # Look up custom display label if provided
      display_label <- NULL
      if (!is.null(tabgroup_labels) && length(tabgroup_labels) > 0) {
        if (!is.null(names(tabgroup_labels))) {
          display_label <- tabgroup_labels[[child_name]]
        } else if (is.list(tabgroup_labels)) {
          display_label <- tabgroup_labels[[child_name]]
        }
      }
      
      # Check if this node has multiple parent visualizations with different filters
      # and nested children - if so, create per-parent nested structures
      has_viz <- !is.null(child_node$visualizations) && length(child_node$visualizations) > 0
      has_children <- !is.null(child_node$children) && length(child_node$children) > 0
      
      if (has_viz && has_children && length(child_node$visualizations) > 1) {
        # Multiple parent tabs with nested children - attach matching nested children to each parent
        parent_viz_list <- child_node$visualizations
        nested_children <- child_node$children
        
        # Process each parent viz and attach its matching nested children
        parent_results <- list()
        for (parent_viz in parent_viz_list) {
          parent_filter_sig <- .get_filter_signature(parent_viz)
          
          # Find nested children with matching filter
          matching_nested <- list()
          for (nested_name in names(nested_children)) {
            nested_node <- nested_children[[nested_name]]
            # Check if any viz in nested node matches this parent's filter
            if (!is.null(nested_node$visualizations)) {
              for (nested_viz in nested_node$visualizations) {
                nested_filter_sig <- .get_filter_signature(nested_viz)
                if (nested_filter_sig == parent_filter_sig || nested_filter_sig == "") {
                  # Create a modified nested node with only matching visualizations
                  matching_node <- list(
                    name = nested_name,
                    visualizations = Filter(function(v) {
                      v_sig <- .get_filter_signature(v)
                      v_sig == parent_filter_sig || v_sig == ""
                    }, nested_node$visualizations),
                    children = nested_node$children
                  )
                  if (length(matching_node$visualizations) > 0) {
                    matching_nested[[nested_name]] <- matching_node
                  }
                  break
                }
              }
            }
          }
          
          # Create a mini-tree for this parent with its matching nested children
          parent_tree <- list(
            visualizations = list(parent_viz),
            children = matching_nested
          )
          
          # Convert to viz list - this will create nested structures
          parent_result <- .tree_to_viz_list(parent_tree, tabgroup_labels, is_nested_context = TRUE)
          
          # Add each item from parent_result
          for (item in parent_result) {
            parent_results <- c(parent_results, list(item))
          }
        }
        
        # Create one tabgroup containing all parent tabs (each with their nested children)
        result <- c(result, list(list(
          type = "tabgroup",
          name = child_name,
          label = display_label,
          visualizations = parent_results
        )))
      } else {
        # Standard case - process normally
        # Pass is_nested_context = TRUE since we're processing children
        child_result <- .tree_to_viz_list(child_node, tabgroup_labels, is_nested_context = TRUE)
        
        if (has_viz || has_children) {
          # In nested contexts (is_nested_context = TRUE), always preserve named levels as tabgroups
          # to maintain the explicit hierarchy the user specified.
          # Only flatten at the absolute root level when there's truly a single item with no structure.
          
          if (has_children) {
            # Has nested children - always create tabgroup to preserve hierarchy
            result <- c(result, list(list(
              type = "tabgroup",
              name = child_name,
              label = display_label,
              visualizations = child_result
            )))
          } else if (length(child_result) == 1 && !is_nested_context) {
            # Single visualization, no nested children, and we're at root level
            # Can flatten only if not in nested context
            single_viz <- child_result[[1]]
            if (is.null(single_viz$title) || single_viz$title == "") {
              single_viz$title <- display_label %||% child_name
            }
            result <- c(result, list(single_viz))
          } else {
            # In nested context OR multiple visualizations - always create tabgroup
            # This preserves explicit hierarchy levels like "age/item1" even when item1 only has one viz
            result <- c(result, list(list(
              type = "tabgroup",
              name = child_name,
              label = display_label,
              visualizations = child_result
            )))
          }
        }
      }
    }
  }
  
  result
}

#' This function handles both viz_collection objects and plain lists of visualization
#' specifications. It:
#' - Attaches data_path to each visualization
#' - Groups visualizations by their tabgroup parameter (supports nested hierarchies)
#' - Converts single-item groups to standalone visualizations with group titles
#' - Creates tab group objects for multi-item groups
#' - Applies custom tab group labels if provided
#' @keywords internal
.process_visualizations <- function(viz_input, data_path, tabgroup_labels = NULL) {
  # Handle different input types
  if (inherits(viz_input, "viz_collection")) {
    if (is.null(viz_input) || length(viz_input$visualizations) == 0) {
      return(NULL)
    }
    viz_list <- viz_input$visualizations
    tabgroup_labels <- viz_input$tabgroup_labels
  } else if (is.list(viz_input)) {
    if (length(viz_input) == 0) {
      return(NULL)
    }
    viz_list <- viz_input
  } else {
    return(NULL)
  }

  # Attach data path to each visualization
  # Only attach if data_path is a single path (not a list of paths for multi-dataset)
  if (!is.null(data_path) && !is.list(data_path)) {
    for (i in seq_along(viz_list)) {
      viz_list[[i]]$data_path <- data_path
    }
  } else if (is.list(data_path)) {
    # For multi-dataset pages, mark that data exists but don't attach specific path
    # The viz's `data` parameter will determine which dataset to use
    for (i in seq_along(viz_list)) {
      viz_list[[i]]$has_data <- TRUE
      viz_list[[i]]$multi_dataset <- TRUE
    }
  }

  # SMART APPROACH: Only use filter grouping when needed
  # Detect if we have multiple parent tabs with same root but different filters
  
  # Step 1: Analyze structure - check for multiple parents with same root but different filters
  root_parents <- list()  # Track parent tabs by root name
  root_nested <- list()   # Track nested tabs by root name
  
  for (viz in viz_list) {
    if (!is.null(viz$tabgroup) && length(viz$tabgroup) > 0) {
      root_name <- viz$tabgroup[1]
      
      if (length(viz$tabgroup) == 1) {
        # This is a parent tab
        if (is.null(root_parents[[root_name]])) {
          root_parents[[root_name]] <- list()
        }
        root_parents[[root_name]] <- c(root_parents[[root_name]], list(viz))
      } else {
        # This is a nested tab
        if (is.null(root_nested[[root_name]])) {
          root_nested[[root_name]] <- list()
        }
        root_nested[[root_name]] <- c(root_nested[[root_name]], list(viz))
      }
    }
  }
  
  # Step 2: Determine which roots need filter-based grouping
  needs_filter_grouping <- list()
  for (root_name in names(root_parents)) {
    parents <- root_parents[[root_name]]
    
    # Check if there are nested tabs at this root
    has_nested <- !is.null(root_nested[[root_name]]) && length(root_nested[[root_name]]) > 0
    
    if (length(parents) > 1) {
      # Multiple parents - check if they have different filters
      filters <- sapply(parents, function(v) .get_filter_signature(v))
      unique_filters <- unique(filters)
      if (length(unique_filters) > 1) {
        # Multiple parents with different filters - needs special handling
        needs_filter_grouping[[root_name]] <- TRUE
      } else {
        needs_filter_grouping[[root_name]] <- FALSE
      }
    } else if (length(parents) == 1 && has_nested) {
      # Single parent but with nested children
      # If the parent has a filter AND there are nested children with filters,
      # we need filter grouping to properly nest them
      parent_filter <- .get_filter_signature(parents[[1]])
      if (nzchar(parent_filter)) {
        # Parent has a filter - check if any nested items also have filters
        nested_items <- root_nested[[root_name]]
        nested_has_filters <- any(sapply(nested_items, function(v) {
          !is.null(v$filter)
        }))
        needs_filter_grouping[[root_name]] <- nested_has_filters
      } else {
        needs_filter_grouping[[root_name]] <- FALSE
      }
    } else {
      needs_filter_grouping[[root_name]] <- FALSE
    }
  }
  
  # Step 3: Build hierarchy using appropriate strategy
  if (any(unlist(needs_filter_grouping))) {
    # Use filter-based grouping for roots that need it
    tree <- list(visualizations = list(), children = list())
    
    # Group by root+filter for roots that need it
    root_groups <- list()
    
    for (viz in viz_list) {
      if (is.null(viz$tabgroup)) {
        # No tabgroup - add to root level
        tree$visualizations <- c(tree$visualizations, list(viz))
      } else {
        root_name <- viz$tabgroup[1]
        
        if (isTRUE(needs_filter_grouping[[root_name]])) {
          # This root needs filter grouping
          # Non-filtered items should still be grouped under this root, just with empty filter signature
          # This keeps them nested under the correct parent (e.g., sis/time under sis)
          filter_sig <- .get_filter_signature(viz)  # Will be "" for items without filter
          group_key <- paste0(root_name, "::", filter_sig)
          
          if (is.null(root_groups[[group_key]])) {
            root_groups[[group_key]] <- list()
          }
          root_groups[[group_key]] <- c(root_groups[[group_key]], list(viz))
        } else {
          # Standard hierarchy building
          tree <- .insert_into_hierarchy(tree, viz$tabgroup, viz)
        }
      }
    }
    
    # Build separate trees for filter groups
    # First, process standard items into tree
    standard_tree <- tree
    
    # Then create filter-grouped structure
    filter_grouped_trees <- list()
    
    # Add standard tree items (roots that don't need filter grouping) to result directly
    standard_result <- .tree_to_viz_list(standard_tree, tabgroup_labels)
    
    # Now build filter-grouped structures
    for (group_key in names(root_groups)) {
      parts <- strsplit(group_key, "::", fixed = TRUE)[[1]]
      root_name <- parts[1]
      # Handle empty filter signature (when group_key ends with "::")
      # Note: R cannot use "" as a list key, so we use a sentinel value
      filter_sig <- if (length(parts) > 1) parts[2] else "__no_filter__"
      
      # Build tree for this filter group
      # For filter groups, we remove the root prefix since all items share the same root
      filter_tree <- list(visualizations = list(), children = list())
      for (viz in root_groups[[group_key]]) {
        # Remove root prefix from tabgroup path for filter tree
        if (length(viz$tabgroup) > 1 && viz$tabgroup[1] == root_name) {
          relative_path <- viz$tabgroup[-1]
        } else if (length(viz$tabgroup) == 1 && viz$tabgroup[1] == root_name) {
          relative_path <- character(0)  # Parent viz goes at root of filter tree
        } else {
          relative_path <- viz$tabgroup  # Fallback - shouldn't happen
        }
        filter_tree <- .insert_into_hierarchy(filter_tree, relative_path, viz)
      }
      
      if (is.null(filter_grouped_trees[[root_name]])) {
        filter_grouped_trees[[root_name]] <- list()
      }
      filter_grouped_trees[[root_name]][[filter_sig]] <- filter_tree
    }
    
    # Merge standard result with filter-grouped results
    filter_result <- .merge_filtered_trees(filter_grouped_trees, tabgroup_labels)
    result <- c(standard_result, filter_result)
  } else {
    # Standard approach - no filter grouping needed
    tree <- list(visualizations = list(), children = list())
    
    for (viz in viz_list) {
      tree <- .insert_into_hierarchy(tree, viz$tabgroup, viz)
    }
    
    result <- .tree_to_viz_list(tree, tabgroup_labels)
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

# Generate meaningful chunk label for R chunks
.generate_chunk_label <- function(spec, spec_name = NULL) {
  label <- NULL
  
  # Priority 1: Use tabgroup (most specific context)
  if (!is.null(spec$tabgroup) && length(spec$tabgroup) > 0) {
    # Collapse tabgroup vector into single path
    tabgroup_path <- if (is.character(spec$tabgroup) && length(spec$tabgroup) > 1) {
      paste(spec$tabgroup, collapse = "/")
    } else {
      as.character(spec$tabgroup)
    }
    label <- tabgroup_path
  }
  
  # Priority 2: Use relevant variable names
  if (is.null(label)) {
    vars <- character(0)
    
    if (!is.null(spec$type)) {
      # Type-specific variable extraction
      if (spec$type == "stackedbar" || spec$type == "bar") {
        if (!is.null(spec$x_var)) vars <- c(vars, spec$x_var)
        if (!is.null(spec$stack_var)) vars <- c(vars, spec$stack_var)
        if (!is.null(spec$group_var)) vars <- c(vars, spec$group_var)
      } else if (spec$type == "stackedbars") {
        if (!is.null(spec$questions) && length(spec$questions) > 0) {
          vars <- c(vars, spec$questions[1])  # Use first question
        }
      } else if (spec$type == "timeline") {
        if (!is.null(spec$response_var)) vars <- c(vars, spec$response_var)
        if (!is.null(spec$group_var)) vars <- c(vars, spec$group_var)
      } else if (spec$type == "histogram") {
        if (!is.null(spec$x_var)) vars <- c(vars, spec$x_var)
      } else if (spec$type == "heatmap") {
        if (!is.null(spec$x_var)) vars <- c(vars, spec$x_var)
        if (!is.null(spec$y_var)) vars <- c(vars, spec$y_var)
        if (!is.null(spec$value_var)) vars <- c(vars, spec$value_var)
      }
      
      # Construct label from type + variables
      if (length(vars) > 0) {
        # Limit to first 2 variables to keep reasonable length
        vars_label <- paste(head(vars, 2), collapse = "-")
        label <- paste(spec$type, vars_label, sep = "-")
      }
    }
  }
  
  # Priority 3: Use title
  if (is.null(label) && !is.null(spec$title)) {
    label <- spec$title
  }
  
  # Priority 4: Use type or fallback
  if (is.null(label)) {
    if (!is.null(spec$type)) {
      label <- spec$type
    } else if (!is.null(spec_name)) {
      label <- spec_name
    } else {
      label <- "viz"
    }
  }
  
  # Sanitize label
  label <- tolower(label)
  # Replace slashes with dashes (for tabgroup hierarchy)
  label <- gsub("/", "-", label, fixed = TRUE)
  # Replace underscores, dots, hashes, spaces with dashes
  label <- gsub("[_. #]", "-", label)
  # Replace any other non-alphanumeric with dash
  label <- gsub("[^a-z0-9-]", "-", label)
  # Remove consecutive dashes
  label <- gsub("-+", "-", label)
  # Remove leading/trailing dashes
  label <- gsub("^-|-$", "", label)
  
  # Limit length
  if (nchar(label) > 50) {
    label <- substr(label, 1, 50)
    # Remove trailing dash if any
    label <- gsub("-$", "", label)
  }
  
  # Ensure uniqueness by tracking used labels
  # Store in a package environment to persist across function calls within a generation
  if (!exists(".chunk_label_tracker", envir = .GlobalEnv)) {
    assign(".chunk_label_tracker", list(), envir = .GlobalEnv)
  }
  
  tracker <- get(".chunk_label_tracker", envir = .GlobalEnv)
  
  # Check if label already used
  if (label %in% names(tracker)) {
    # Increment counter
    tracker[[label]] <- tracker[[label]] + 1
    label <- paste0(label, "-", tracker[[label]])
  } else {
    # First use of this label
    tracker[[label]] <- 1
  }
  
  # Update tracker
  assign(".chunk_label_tracker", tracker, envir = .GlobalEnv)
  
  label
}

# Generate a single visualization R code chunk
.generate_single_viz <- function(spec_name, spec, skip_header = FALSE) {
  lines <- character(0)

  # Remove nested_children from spec - it's only for structure, not for visualization generation
  spec <- spec[names(spec) != "nested_children"]

  # Determine text position (default to "above" if not specified)
  text_position <- spec$text_position %||% "above"

  # Add section header with icon if provided (skip if in tabgroup)
  if (!skip_header && !is.null(spec$title)) {
    header_text <- spec$title
    if (!is.null(spec$icon)) {
      icon_shortcode <- if (grepl("{{< iconify", spec$icon, fixed = TRUE)) {
        spec$icon
      } else {
        icon(spec$icon)
      }
      header_text <- paste0(icon_shortcode, " ", spec$title)
    }
    lines <- c(lines, paste0("## ", header_text), "")
  }

  # Add custom text content if provided (above chart by default)
  if (!is.null(spec$text) && nzchar(spec$text) && text_position == "above") {
    lines <- c(lines, "", spec$text, "")
  }

  # Generate meaningful chunk label
  chunk_label <- .generate_chunk_label(spec, spec_name)
  
  # Simple R chunk - caching enabled for performance
  lines <- c(lines,
    paste0("```{r ", chunk_label, "}"),
    paste0("# ", spec$title %||% paste(spec$type, "visualization"))
  )

  # Dispatch to appropriate generator
  if ("type" %in% names(spec)) {
    lines <- c(lines, .generate_typed_viz(spec))
  } else if ("fn" %in% names(spec)) {
    lines <- c(lines, .generate_function_viz(spec))
  } else {
    lines <- c(lines, .generate_auto_viz(spec_name, spec))
  }

  lines <- c(lines, "```")

  # Add custom text content if provided (below chart)
  if (!is.null(spec$text) && nzchar(spec$text) && text_position == "below") {
    lines <- c(lines, "", spec$text, "")
  }

  lines <- c(lines, "")
  lines
}

#' Generate R code for typed visualizations
#'
#' Internal function that generates R code for specific visualization types
#' (stackedbar, heatmap, histogram, timeline) by mapping type names to
#' function names and serializing parameters.
#'
#' @param spec Visualization specification list containing type and parameters
#' @return Character vector of R code lines for the visualization
#' @keywords internal
#' @details
#' This function:
#' - Maps visualization types to function names (e.g., "stackedbar" → "create_stackedbar")
#' - Excludes internal parameters (type, data_path, tabgroup, text, icon, text_position)
#' - Serializes all other parameters using .serialize_arg()
#' - Formats the function call with proper indentation
.generate_typed_viz <- function(spec) {
  lines <- character(0)

  ## TODO: this needs to create from some list of available visualizations (maybe!)
  # Map type to function name
  viz_function <- switch(spec$type,
                         "stackedbars" = "create_stackedbars",
                         "stackedbar" = "create_stackedbar",
                         "histogram" = "create_histogram",
                         "heatmap" = "create_heatmap",
                         "timeline" = "create_timeline",
                         "bar" = "create_bar",
                         spec$type
  )

  # Determine which dataset to use
  source_dataset <- spec$data %||% "data"  # Check if viz specifies a dataset
  
  if (!is.null(spec$filter)) {
    # Use pre-filtered dataset created in setup chunk
    filter_expr <- deparse(spec$filter[[2]], width.cutoff = 500L)
    filter_key <- paste(filter_expr, collapse = " ")
    filter_hash <- substr(digest::digest(filter_key), 1, 8)
    data_var <- paste0(source_dataset, "_filtered_", filter_hash)
  } else {
    # Use the source dataset (named dataset or default "data")
    data_var <- source_dataset
  }

  # Build argument list (exclude internal params)
  args <- list()

  # Add data argument if page has data (either single or multi-dataset)
  if (("data_path" %in% names(spec) && !is.null(spec$data_path)) || 
      ("has_data" %in% names(spec) && isTRUE(spec$has_data))) {
    
    # Check if we should drop NAs for relevant variables
    if (isTRUE(spec$drop_na_vars)) {
      # Determine which variables are used in this visualization
      vars_to_clean <- character(0)
      
      if (spec$type == "stackedbar") {
        if (!is.null(spec$x_var)) vars_to_clean <- c(vars_to_clean, spec$x_var)
        if (!is.null(spec$stack_var)) vars_to_clean <- c(vars_to_clean, spec$stack_var)
      } else if (spec$type == "stackedbars") {
        if (!is.null(spec$questions)) vars_to_clean <- c(vars_to_clean, spec$questions)
      } else if (spec$type == "timeline") {
        if (!is.null(spec$response_var)) vars_to_clean <- c(vars_to_clean, spec$response_var)
        if (!is.null(spec$group_var)) vars_to_clean <- c(vars_to_clean, spec$group_var)
        if (!is.null(spec$time_var)) vars_to_clean <- c(vars_to_clean, spec$time_var)
      } else if (spec$type == "histogram") {
        if (!is.null(spec$x_var)) vars_to_clean <- c(vars_to_clean, spec$x_var)
        if (!is.null(spec$group_var)) vars_to_clean <- c(vars_to_clean, spec$group_var)
      } else if (spec$type == "bar") {
        if (!is.null(spec$x_var)) vars_to_clean <- c(vars_to_clean, spec$x_var)
        if (!is.null(spec$group_var)) vars_to_clean <- c(vars_to_clean, spec$group_var)
      } else if (spec$type == "heatmap") {
        if (!is.null(spec$x_var)) vars_to_clean <- c(vars_to_clean, spec$x_var)
        if (!is.null(spec$y_var)) vars_to_clean <- c(vars_to_clean, spec$y_var)
        if (!is.null(spec$fill_var)) vars_to_clean <- c(vars_to_clean, spec$fill_var)
      }
      
      # Build data pipeline with drop_na if we have variables
      if (length(vars_to_clean) > 0) {
        vars_str <- paste(vars_to_clean, collapse = ", ")
        args$data <- paste0(data_var, " %>% tidyr::drop_na(", vars_str, ")")
      } else {
        args$data <- data_var
      }
    } else {
      args$data <- data_var  # Reference filtered or named dataset
    }
  }

  for (param in names(spec)) {
    if (!param %in% c("type", "data_path", "tabgroup", "text", "icon", "text_position", "height", "filter", "data", "has_data", "multi_dataset", "title_tabset", "nested_children", "drop_na_vars", ".insertion_index", ".min_index")) { # Exclude internal parameters
      args[[param]] <- .serialize_arg(spec[[param]])
    }
  }

  # Format function call with proper indentation
  if (length(args) == 0) {
    call_str <- paste0("result <- ", viz_function, "()")
  } else {
    arg_lines <- character(0)
    arg_lines <- c(arg_lines, paste0("result <- ", viz_function, "("))

    for (i in seq_along(args)) {
      arg_name <- names(args)[i]
      arg_value <- args[[i]]
      comma <- if (i < length(args)) "," else ""
      arg_lines <- c(arg_lines, paste0("  ", arg_name, " = ", arg_value, comma))
    }

    arg_lines <- c(arg_lines, ")")
    call_str <- arg_lines
  }

  # Add height support if specified
  if (!is.null(spec$height)) {
    height_lines <- c(
      "",
      "# Apply height to highcharter object",
      paste0("if (inherits(result, 'highchart')) {"),
      paste0("  result <- highcharter::hc_chart(result, height = ", spec$height, ")"),
      paste0("}")
    )
    call_str <- c(call_str, height_lines)
  }

  # Always print the result
  call_str <- c(call_str, "", "result")

  c(lines, call_str)
}

# Generate code for custom function-based visualizations
.generate_function_viz <- function(spec) {
  lines <- character(0)

  # Determine which dataset to use
  source_dataset <- spec$data %||% "data"  # Check if viz specifies a dataset
  
  if (!is.null(spec$filter)) {
    # Use pre-filtered dataset created in setup chunk
    filter_expr <- deparse(spec$filter[[2]], width.cutoff = 500L)
    filter_key <- paste(filter_expr, collapse = " ")
    filter_hash <- substr(digest::digest(filter_key), 1, 8)
    data_var <- paste0(source_dataset, "_filtered_", filter_hash)
  } else {
    # Use the source dataset (named dataset or default "data")
    data_var <- source_dataset
  }

  # Load data if needed (shouldn't happen in normal flow, but kept for compatibility)
  if ("data_path" %in% names(spec) && !is.null(spec$data_path) && data_var == source_dataset && source_dataset == "data") {
    data_file <- basename(spec$data_path)
    lines <- c(lines, paste0("data <- readRDS('", data_file, "')"))
  }

  fn_name <- spec$fn
  args <- spec$args %||% list()

  # Add data argument if page has data (either single or multi-dataset)
  if ("data" %in% names(args) && 
      (("data_path" %in% names(spec) && !is.null(spec$data_path)) || 
       ("has_data" %in% names(spec) && isTRUE(spec$has_data)))) {
    args$data <- data_var
  }

  if (length(args) == 0) {
    call_str <- paste0("result <- ", fn_name, "()")
  } else {
    serialized_args <- character(0)
    for (arg_name in names(args)) {
      serialized_args <- c(serialized_args,
                           paste0(arg_name, " = ", .serialize_arg(args[[arg_name]])))
    }
    args_str <- paste(serialized_args, collapse = ", ")
    call_str <- paste0("result <- ", fn_name, "(", args_str, ")")
  }

  # Add height support if specified
  if (!is.null(spec$height)) {
    height_lines <- c(
      "",
      "# Apply height to highcharter object",
      paste0("if (inherits(result, 'highchart')) {"),
      paste0("  result <- highcharter::hc_chart(result, height = ", spec$height, ")"),
      paste0("}")
    )
    call_str <- c(call_str, height_lines)
  }

  # Always print the result
  call_str <- c(call_str, "", "result")

  c(lines, call_str)
}

# Auto-detect visualization type from parameters and generate code
.generate_auto_viz <- function(spec_name, spec) {
  lines <- character(0)

  # Determine which dataset to use
  source_dataset <- spec$data %||% "data"  # Check if viz specifies a dataset
  
  if (!is.null(spec$filter)) {
    # Use pre-filtered dataset created in setup chunk
    filter_expr <- deparse(spec$filter[[2]], width.cutoff = 500L)
    filter_key <- paste(filter_expr, collapse = " ")
    filter_hash <- substr(digest::digest(filter_key), 1, 8)
    data_var <- paste0(source_dataset, "_filtered_", filter_hash)
  } else {
    # Use the source dataset (named dataset or default "data")
    data_var <- source_dataset
  }

  # Load data if specified (shouldn't happen in normal flow, but kept for compatibility)
  if ("data_path" %in% names(spec) && !is.null(spec$data_path) && data_var == source_dataset && source_dataset == "data") {
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
  
  # Add or replace data argument if page has data
  if (("data_path" %in% names(args) && !is.null(args$data_path)) || 
      ("has_data" %in% names(args) && isTRUE(args$has_data))) {
    args$data <- data_var  # Use filtered or named dataset
  }
  
  # Remove internal parameters
  args$data_path <- NULL
  args$tabgroup <- NULL
  args$text <- NULL
  args$icon <- NULL
  args$text_position <- NULL
  args$height <- NULL
  args$filter <- NULL
  args$has_data <- NULL
  args$multi_dataset <- NULL
  args$title_tabset <- NULL
  
  # Remove the data argument if it's the source dataset name (internal param that was passed to add_viz)
  if ("data" %in% names(args) && is.character(args$data) && args$data == spec$data) {
    # This was the source dataset name parameter, not actual data
    # It will be added back as data_var above
  }

  # Format function call
  if (length(args) == 0) {
    call_str <- paste0("result <- ", fn_name, "()")
  } else {
    arg_lines <- character(0)
    arg_lines <- c(arg_lines, paste0("result <- ", fn_name, "("))

    for (i in seq_along(args)) {
      arg_name <- names(args)[i]
      arg_value <- .serialize_arg(args[[arg_name]])
      comma <- if (i < length(args)) "," else ""
      arg_lines <- c(arg_lines, paste0("  ", arg_name, " = ", arg_value, comma))
    }

    arg_lines <- c(arg_lines, ")")
    call_str <- arg_lines
  }

  # Add height support if specified
  if (!is.null(spec$height)) {
    height_lines <- c(
      "",
      "# Apply height to highcharter object",
      paste0("if (inherits(result, 'highchart')) {"),
      paste0("  result <- highcharter::hc_chart(result, height = ", spec$height, ")"),
      paste0("}")
    )
    call_str <- c(call_str, height_lines)
  }

  # Always print the result
  call_str <- c(call_str, "", "result")

  c(lines, call_str)
}

# Generate Quarto tabset markup with visualizations (supports nested tabsets)
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
  # First, collect all nested_children tabgroup names to avoid double-rendering
  nested_children_names <- character(0)
  for (viz_item in tabgroup_spec$visualizations) {
    if (!is.null(viz_item$nested_children)) {
      for (nc in viz_item$nested_children) {
        if (!is.null(nc$type) && nc$type == "tabgroup" && !is.null(nc$name)) {
          nested_children_names <- c(nested_children_names, nc$name)
        }
      }
    }
  }
  
  for (i in seq_along(tabgroup_spec$visualizations)) {
    viz <- tabgroup_spec$visualizations[[i]]

    # Check if this is a nested tabgroup
    # Skip if this tabgroup is already rendered as a nested_child (to avoid duplicate headers)
    if (!is.null(viz$type) && viz$type == "tabgroup") {
      if (!is.null(viz$name) && viz$name %in% nested_children_names) {
        # This tabgroup is already rendered as nested_child, skip it here
        next
      }
      
      # This is a nested tabgroup - recursively generate it
      # Tab header: use label or name
      tab_title <- if (!is.null(viz$label) && nzchar(viz$label)) {
        viz$label
      } else if (!is.null(viz$name) && nzchar(viz$name)) {
        viz$name
      } else {
        paste0("Section ", i)
      }
      
      lines <- c(lines, paste0("### ", tab_title), "")
      
      # Recursively generate nested tabset (without the ## header, since we have ### tab)
      # Temporarily remove label so it doesn't add ## header
      nested_spec <- viz
      nested_spec$label <- NULL
      nested_spec$name <- NULL
      
      # Generate nested content
      nested_lines <- .generate_tabgroup_viz_content(nested_spec, depth = 1)
      lines <- c(lines, nested_lines)
      
    } else {
      # Regular visualization
      # Tab header: use title_tabset if provided, otherwise fall back to title
      viz_title <- if (!is.null(viz$title_tabset) && nzchar(viz$title_tabset)) {
        viz$title_tabset
      } else if (!is.null(viz$title) && length(viz$title) > 0 && nzchar(viz$title)) {
        viz$title
      } else {
        paste0("Chart ", i)
      }

      # Add icon to tab header if provided
      if (!is.null(viz$icon)) {
        icon_shortcode <- if (grepl("{{< iconify", viz$icon, fixed = TRUE)) {
          viz$icon
        } else {
          icon(viz$icon)
        }
        viz_title <- paste0(icon_shortcode, " ", viz_title)
      }

      lines <- c(lines, paste0("### ", viz_title), "")

      # Check if this visualization has nested children
      has_nested <- !is.null(viz$nested_children) && length(viz$nested_children) > 0
      
      # Generate visualization code ONLY if:
      # 1. It's not a placeholder type, AND
      # 2. It doesn't have nested children (if it has nested children, it's just a container tab)
      if (!has_nested && (is.null(viz$type) || viz$type != "placeholder")) {
        viz_lines <- .generate_single_viz(paste0("tab_", i), viz, skip_header = TRUE)
        lines <- c(lines, viz_lines)
      }
      
      # Check if this visualization has nested children (nested tabgroups that should appear inside this tab)
      if (has_nested) {
        # Check if we have tabgroups as nested children - these should become tabs, not headers
        nested_tabgroups <- Filter(function(x) !is.null(x$type) && x$type == "tabgroup", viz$nested_children)
        
        if (length(nested_tabgroups) > 0) {
          # Create a tabset where each nested tabgroup becomes a TAB
          # This makes "Age" and "Gender" appear as clickable tabs, not static headers
          lines <- c(lines, "", "::: {.panel-tabset}", "")
          
          for (j in seq_along(nested_tabgroups)) {
            nested_tabgroup <- nested_tabgroups[[j]]
            
            # Tab title for the nested tabgroup (e.g., "Age", "Gender")
            tab_title <- if (!is.null(nested_tabgroup$label) && nzchar(nested_tabgroup$label)) {
              nested_tabgroup$label
            } else if (!is.null(nested_tabgroup$name) && nzchar(nested_tabgroup$name)) {
              nested_tabgroup$name
            } else {
              paste0("Section ", j)
            }
            
            # Add icon if provided in tabgroup label
            if (!is.null(nested_tabgroup$label) && grepl("{{< iconify", nested_tabgroup$label, fixed = TRUE)) {
              # Label already has icon
            } else if (!is.null(nested_tabgroup$icon)) {
              icon_shortcode <- if (grepl("{{< iconify", nested_tabgroup$icon, fixed = TRUE)) {
                nested_tabgroup$icon
              } else {
                icon(nested_tabgroup$icon)
              }
              tab_title <- paste0(icon_shortcode, " ", tab_title)
            }
            
            # Create the tab
            lines <- c(lines, paste0("#### ", tab_title), "")
            
            # Generate the content of this nested tabgroup (this will contain the Question tabs)
            # Don't add header since we already have the tab header
            nested_content <- .generate_tabgroup_viz_content(nested_tabgroup, depth = 1, skip_header = TRUE)
            lines <- c(lines, nested_content)
            
            if (j < length(nested_tabgroups)) {
              lines <- c(lines, "")
            }
          }
          
          # Close the nested tabset
          lines <- c(lines, "", ":::", "")
        }
      }
    }

    if (i < length(tabgroup_spec$visualizations)) {
      lines <- c(lines, "")
    }
  }

  # Close tabset
  lines <- c(lines, "", ":::", "")

  lines
}

# Helper function to generate tabset content without the ## header
# (used for nested tabsets)
.generate_tabgroup_viz_content <- function(tabgroup_spec, depth = 0, skip_header = FALSE) {
  lines <- character(0)
  
  # Add header for this tabgroup if it has a label (for nested tabgroups like "Age")
  # This makes the tabgroup label visible before the tabs
  # Skip header if skip_header is TRUE (when we're creating this as a tab, not a header)
  if (!skip_header && !is.null(tabgroup_spec$label) && nzchar(tabgroup_spec$label) && depth > 0) {
    header_level <- paste0(rep("#", 4 + depth - 1), collapse = "")
    lines <- c(lines, "", paste0(header_level, " ", tabgroup_spec$label), "")
  }
  
  # Check if this tabgroup only contains a single visualization (no nested tabgroups)
  # If so, render the visualization directly without wrapping in a tabset
  has_nested_tabgroups <- any(sapply(tabgroup_spec$visualizations, function(v) {
    !is.null(v$type) && v$type == "tabgroup"
  }))
  
  single_viz_only <- length(tabgroup_spec$visualizations) == 1 && !has_nested_tabgroups
  
  if (single_viz_only) {
    # Single visualization - render it directly without tabset wrapper
    viz <- tabgroup_spec$visualizations[[1]]
    viz_lines <- .generate_single_viz(paste0("viz_", depth), viz, skip_header = TRUE)
    lines <- c(lines, "", viz_lines)
    return(lines)
  }
  
  # Multiple items or contains nested tabgroups - create tabset
  lines <- c(lines, "", "::: {.panel-tabset}", "")

  # Generate each tab
  for (i in seq_along(tabgroup_spec$visualizations)) {
    viz <- tabgroup_spec$visualizations[[i]]

    # Check if this is a nested tabgroup
    if (!is.null(viz$type) && viz$type == "tabgroup") {
      # This is a nested tabgroup - recursively generate it
      tab_title <- if (!is.null(viz$label) && nzchar(viz$label)) {
        viz$label
      } else if (!is.null(viz$name) && nzchar(viz$name)) {
        viz$name
      } else {
        paste0("Section ", i)
      }
      
      # Use appropriate header level based on depth
      header_level <- paste0(rep("#", 4 + depth), collapse = "")
      lines <- c(lines, paste0(header_level, " ", tab_title), "")
      
      # Recursively generate nested tabset
      nested_spec <- viz
      nested_spec$label <- NULL
      nested_spec$name <- NULL
      
      nested_lines <- .generate_tabgroup_viz_content(nested_spec, depth = depth + 1)
      lines <- c(lines, nested_lines)
      
    } else {
      # Regular visualization
      # When inside nested tabgroups (depth > 0), don't create an extra header
      # The tab name (from title_tabset or tabgroup label) is sufficient
      # Only create a header if explicitly requested via title_tabset or if at root level
      
      # Check if this should have a header
      # Skip header if: we're nested (depth > 0) AND no title_tabset specified
      # This prevents "Strategic Information Skills" from appearing as an extra tab level
      should_add_header <- depth == 0 || !is.null(viz$title_tabset)
      
      if (should_add_header) {
        viz_title <- if (!is.null(viz$title_tabset) && nzchar(viz$title_tabset)) {
          viz$title_tabset
        } else if (is.null(viz$title) || length(viz$title) == 0 || viz$title == "") {
          paste0("Chart ", i)
        } else {
          viz$title
        }

        # Add icon to tab header if provided
        if (!is.null(viz$icon)) {
          icon_shortcode <- if (grepl("{{< iconify", viz$icon, fixed = TRUE)) {
            viz$icon
          } else {
            icon(viz$icon)
          }
          viz_title <- paste0(icon_shortcode, " ", viz_title)
        }

        # Use appropriate header level based on depth
        header_level <- paste0(rep("#", 4 + depth), collapse = "")
        lines <- c(lines, paste0(header_level, " ", viz_title), "")
      }

      # Generate visualization code
      viz_lines <- .generate_single_viz(paste0("tab_", depth, "_", i), viz, skip_header = TRUE)
      lines <- c(lines, viz_lines)
    }

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

#' Generate _quarto.yml configuration file
#'
#' Internal function that generates the complete Quarto website configuration
#' file based on the dashboard project settings. Handles all Quarto website
#' features including navigation, styling, analytics, and deployment options.
#'
#' @param proj A dashboard_project object containing all configuration settings
#' @return Character vector of YAML lines for the _quarto.yml file
#' @details
#' This function generates a comprehensive Quarto configuration including:
#' - Project type and output directory
#' - Website title, favicon, and branding
#' - Navbar with social media links and search
#' - Sidebar with auto-generated navigation
#' - Format settings (theme, CSS, math, code features)
#' - Analytics (Google Analytics, Plausible, GTag)
#' - Deployment settings (GitHub Pages, Netlify)
#' - Iconify filter for icon support
#' @keywords internal
.generate_quarto_yml <- function(proj) {
  yaml_lines <- c(
    "project:",
    "  type: website"
  )

  # Add output directory
  if (!is.null(proj$publish_dir)) {
    yaml_lines <- c(yaml_lines, paste0("  output-dir: ", proj$publish_dir))
  } else {
    yaml_lines <- c(yaml_lines, "  output-dir: docs")
  }

  yaml_lines <- c(yaml_lines, "")

  # Website configuration
  yaml_lines <- c(yaml_lines, "website:")
  yaml_lines <- c(yaml_lines, paste0("  title: \"", proj$title, "\""))

  # Add favicon if provided
  if (!is.null(proj$favicon)) {
    yaml_lines <- c(yaml_lines, paste0("  favicon: ", proj$favicon))
  }

  # Navbar configuration
  yaml_lines <- c(yaml_lines, "  navbar:")

  # Navbar style
  if (!is.null(proj$navbar_style)) {
    yaml_lines <- c(yaml_lines, paste0("    style: ", proj$navbar_style))
  }

  # Navbar brand
  if (!is.null(proj$navbar_brand)) {
    yaml_lines <- c(yaml_lines, paste0("    brand: \"", proj$navbar_brand, "\""))
  }

  # Navbar toggle
  if (!is.null(proj$navbar_toggle)) {
    yaml_lines <- c(yaml_lines, paste0("    toggle: ", proj$navbar_toggle))
  }

  # Separate pages by navbar alignment
  pages_left <- list()
  pages_right <- list()
  
  # Find landing page
  landing_page_name <- NULL
  for (page_name in names(proj$pages)) {
    if (proj$pages[[page_name]]$is_landing_page) {
      landing_page_name <- page_name
      break
    }
  }
  
  # Group pages by alignment
  for (page_name in names(proj$pages)) {
    page <- proj$pages[[page_name]]
    # Skip landing page as it becomes "Home"
    if (page$is_landing_page) {
      next
    }
    
    # Determine alignment (default to "left")
    if (is.null(page$navbar_align)) {
      align <- "left"
    } else {
      align <- page$navbar_align
    }
    
    if (align == "right") {
      pages_right[[page_name]] <- page
    } else {
      pages_left[[page_name]] <- page
    }
  }

  # Left navigation
  yaml_lines <- c(yaml_lines, "    left:")

  # Add Home link if there's a landing page (only if not using navbar sections)
  if (!is.null(landing_page_name) && (is.null(proj$navbar_sections) || length(proj$navbar_sections) == 0)) {
    yaml_lines <- c(yaml_lines,
    "      - href: index.qmd",
      "        text: \"Home\""
  )
  }

  # Add logo if provided
  if (!is.null(proj$logo)) {
    yaml_lines <- c(yaml_lines,
      paste0("    logo: ", proj$logo)
    )
  }

  # Add navigation links - support both regular pages and navbar sections
  if (!is.null(proj$navbar_sections) && length(proj$navbar_sections) > 0) {
    # Collect pages that are in menus or sidebars
    pages_in_sections <- character(0)
    
    # Hybrid navigation mode - add navbar sections that link to sidebar groups
    for (section in proj$navbar_sections) {
      if (!is.null(section$sidebar)) {
        # This is a sidebar reference (hybrid navigation)
        yaml_lines <- c(yaml_lines, paste0("      - sidebar:", section$sidebar))
        
        # Track pages in this sidebar
        if (!is.null(proj$sidebar_groups)) {
          for (sg in proj$sidebar_groups) {
            if (!is.null(sg$id) && sg$id == section$sidebar) {
              pages_in_sections <- c(pages_in_sections, sg$pages)
              break
            }
          }
        }
      } else if (!is.null(section$menu_pages)) {
        # Track pages in this menu
        pages_in_sections <- c(pages_in_sections, section$menu_pages)
        
        # This is a dropdown menu
        text_content <- paste0("\"", section$text, "\"")
        if (!is.null(section$icon)) {
          icon_shortcode <- if (grepl("{{< iconify", section$icon, fixed = TRUE)) {
            section$icon
          } else {
            icon(section$icon)
          }
          text_content <- paste0("\"", icon_shortcode, " ", section$text, "\"")
        }
        yaml_lines <- c(yaml_lines,
          paste0("      - text: ", text_content),
          "        menu:"
        )
        
        # Add menu items for each page
        for (page_name in section$menu_pages) {
          if (!is.null(proj$pages[[page_name]])) {
            page <- proj$pages[[page_name]]
            
            # Generate filename same way as other pages
            filename <- tolower(gsub("[^a-zA-Z0-9]", "_", page_name))
            page_qmd <- paste0(filename, ".qmd")
            
            # Get page text with icon if available
            page_text_content <- paste0("\"", page_name, "\"")
            if (!is.null(page$icon)) {
              page_icon <- if (grepl("{{< iconify", page$icon, fixed = TRUE)) {
                page$icon
              } else {
                icon(page$icon)
              }
              page_text_content <- paste0("\"", page_icon, " ", page_name, "\"")
            }
            
            yaml_lines <- c(yaml_lines,
              paste0("          - href: ", page_qmd),
              paste0("            text: ", page_text_content)
            )
          }
        }
      } else if (!is.null(section$href)) {
        # This is a regular link
        text_content <- paste0("\"", section$text, "\"")
        if (!is.null(section$icon)) {
          icon_shortcode <- if (grepl("{{< iconify", section$icon, fixed = TRUE)) {
            section$icon
          } else {
            icon(section$icon)
          }
          text_content <- paste0("\"", icon_shortcode, " ", section$text, "\"")
        }
        yaml_lines <- c(yaml_lines,
          paste0("      - href: ", section$href),
          paste0("        text: ", text_content)
        )
      }
    }
    
    # Now add any left-aligned pages that are NOT in any menu or sidebar
    for (page_name in names(pages_left)) {
      if (!page_name %in% pages_in_sections) {
        page <- pages_left[[page_name]]
        
        # Use lowercase with underscores for filenames
        filename <- tolower(gsub("[^a-zA-Z0-9]", "_", page_name))
        
        # Build text with icon if provided
        text_content <- paste0("\"", page_name, "\"")
        if (!is.null(page$icon)) {
          icon_shortcode <- if (grepl("{{< iconify", page$icon, fixed = TRUE)) {
            page$icon
          } else {
            icon(page$icon)
          }
          text_content <- paste0("\"", icon_shortcode, " ", page_name, "\"")
        }
        
        yaml_lines <- c(yaml_lines,
                        paste0("      - href: ", filename, ".qmd"),
                        paste0("        text: ", text_content)
        )
      }
    }
  } else {
    # Simple navigation mode - add left-aligned pages
    for (page_name in names(pages_left)) {
      page <- pages_left[[page_name]]

      # Use lowercase with underscores for filenames
      filename <- tolower(gsub("[^a-zA-Z0-9]", "_", page_name))

      # Build text with icon if provided
      text_content <- paste0("\"", page_name, "\"")
      if (!is.null(page$icon)) {
        # Convert icon shortcode to proper format
        icon_shortcode <- if (grepl("{{< iconify", page$icon, fixed = TRUE)) {
          page$icon
        } else {
          icon(page$icon)
        }
        text_content <- paste0("\"", icon_shortcode, " ", page_name, "\"")
      }

      yaml_lines <- c(yaml_lines,
                      paste0("      - href: ", filename, ".qmd"),
                      paste0("        text: ", text_content)
      )
    }
  }
  
  # Right navigation - add right-aligned pages before tools
  if (length(pages_right) > 0) {
    has_right_pages <- TRUE
  } else {
    has_right_pages <- FALSE
  }

  # Add tools section (right side of navbar)
  tools <- list()

  # Add social media and other tools
  if (!is.null(proj$github)) {
    tools <- c(tools, list(list(icon = "github", href = proj$github)))
  }
  if (!is.null(proj$twitter)) {
    tools <- c(tools, list(list(icon = "twitter", href = proj$twitter)))
  }
  if (!is.null(proj$linkedin)) {
    tools <- c(tools, list(list(icon = "linkedin", href = proj$linkedin)))
  }
  if (!is.null(proj$email)) {
    tools <- c(tools, list(list(icon = "envelope", href = paste0("mailto:", proj$email))))
  }
  if (!is.null(proj$website)) {
    tools <- c(tools, list(list(icon = "globe", href = proj$website)))
  }

  # Add right section if we have right-aligned pages OR tools
  if (has_right_pages || length(tools) > 0) {
    yaml_lines <- c(yaml_lines, "    right:")
    
    # First, add right-aligned pages
    if (has_right_pages) {
      for (page_name in names(pages_right)) {
        page <- pages_right[[page_name]]

        # Use lowercase with underscores for filenames
        filename <- tolower(gsub("[^a-zA-Z0-9]", "_", page_name))

        # Build text with icon if provided
        text_content <- paste0("\"", page_name, "\"")
        if (!is.null(page$icon)) {
          # Convert icon shortcode to proper format
          icon_shortcode <- if (grepl("{{< iconify", page$icon, fixed = TRUE)) {
            page$icon
          } else {
            icon(page$icon)
          }
          text_content <- paste0("\"", icon_shortcode, " ", page_name, "\"")
        }

        yaml_lines <- c(yaml_lines,
                        paste0("      - href: ", filename, ".qmd"),
                        paste0("        text: ", text_content)
        )
      }
    }
    
    # Then, add tools
    for (tool in tools) {
      yaml_lines <- c(yaml_lines,
        paste0("      - icon: ", tool$icon),
        paste0("        href: ", tool$href)
      )
    }
  }

  # Add search if enabled
  if (proj$search) {
    yaml_lines <- c(yaml_lines, "    search: true")
  }

  # Sidebar configuration - supports both simple and hybrid navigation
  if (proj$sidebar || (!is.null(proj$sidebar_groups) && length(proj$sidebar_groups) > 0)) {
    yaml_lines <- c(yaml_lines, "  sidebar:")

    # Check if we're using hybrid navigation (sidebar groups)
    if (!is.null(proj$sidebar_groups) && length(proj$sidebar_groups) > 0) {
      # Hybrid navigation mode - multiple sidebar groups
      for (i in seq_along(proj$sidebar_groups)) {
        group <- proj$sidebar_groups[[i]]

        # Add group with ID
        yaml_lines <- c(yaml_lines, paste0("    - id: ", group$id))
        yaml_lines <- c(yaml_lines, paste0("      title: \"", group$title, "\""))

        # Add styling options (inherit from first group if not specified)
        if (!is.null(group$style)) {
          yaml_lines <- c(yaml_lines, paste0("      style: \"", group$style, "\""))
        } else if (i == 1 && !is.null(proj$sidebar_style)) {
          yaml_lines <- c(yaml_lines, paste0("      style: \"", proj$sidebar_style, "\""))
        }

        if (!is.null(group$background)) {
          yaml_lines <- c(yaml_lines, paste0("      background: \"", group$background, "\""))
        } else if (i == 1 && !is.null(proj$sidebar_background)) {
          yaml_lines <- c(yaml_lines, paste0("      background: \"", proj$sidebar_background, "\""))
        }

        if (!is.null(group$foreground)) {
          yaml_lines <- c(yaml_lines, paste0("      foreground: \"", group$foreground, "\""))
        } else if (i == 1 && !is.null(proj$sidebar_foreground)) {
          yaml_lines <- c(yaml_lines, paste0("      foreground: \"", group$foreground, "\""))
        }

        if (!is.null(group$border)) {
          yaml_lines <- c(yaml_lines, paste0("      border: ", tolower(group$border)))
        } else if (i == 1 && !is.null(proj$sidebar_border)) {
          yaml_lines <- c(yaml_lines, paste0("      border: ", tolower(proj$sidebar_border)))
        }

        if (!is.null(group$alignment)) {
          yaml_lines <- c(yaml_lines, paste0("      alignment: \"", group$alignment, "\""))
        } else if (i == 1 && !is.null(proj$sidebar_alignment)) {
          yaml_lines <- c(yaml_lines, paste0("      alignment: \"", proj$sidebar_alignment, "\""))
        }

        if (!is.null(group$collapse_level)) {
          yaml_lines <- c(yaml_lines, paste0("      collapse-level: ", group$collapse_level))
        } else if (i == 1 && !is.null(proj$sidebar_collapse_level)) {
          yaml_lines <- c(yaml_lines, paste0("      collapse-level: ", proj$sidebar_collapse_level))
        }

        if (!is.null(group$pinned)) {
          yaml_lines <- c(yaml_lines, paste0("      pinned: ", tolower(group$pinned)))
        } else if (i == 1 && !is.null(proj$sidebar_pinned)) {
          yaml_lines <- c(yaml_lines, paste0("      pinned: ", tolower(proj$sidebar_pinned)))
        }

        # Add tools if specified
        if (!is.null(group$tools) && length(group$tools) > 0) {
          yaml_lines <- c(yaml_lines, "      tools:")
          for (tool in group$tools) {
            if (is.list(tool) && "icon" %in% names(tool) && "href" %in% names(tool)) {
              yaml_lines <- c(yaml_lines, paste0("        - icon: ", tool$icon))
              yaml_lines <- c(yaml_lines, paste0("          href: ", tool$href))
              if ("text" %in% names(tool)) {
                yaml_lines <- c(yaml_lines, paste0("          text: \"", tool$text, "\""))
              }
            }
          }
        } else if (i == 1 && !is.null(proj$sidebar_tools) && length(proj$sidebar_tools) > 0) {
          yaml_lines <- c(yaml_lines, "      tools:")
          for (tool in proj$sidebar_tools) {
            if (is.list(tool) && "icon" %in% names(tool) && "href" %in% names(tool)) {
              yaml_lines <- c(yaml_lines, paste0("        - icon: ", tool$icon))
              yaml_lines <- c(yaml_lines, paste0("          href: ", tool$href))
              if ("text" %in% names(tool)) {
                yaml_lines <- c(yaml_lines, paste0("          text: \"", tool$text, "\""))
              }
            }
          }
        }

        # Add contents for this group (only if there are pages)
        pages_added <- 0
        for (page_name in group$pages) {
          # Find matching page (case-insensitive)
          matching_page <- NULL
          for (actual_page_name in names(proj$pages)) {
            if (tolower(gsub("[^a-zA-Z0-9]", "_", actual_page_name)) == tolower(gsub("[^a-zA-Z0-9]", "_", page_name))) {
              matching_page <- actual_page_name
              break
            }
          }

          if (!is.null(matching_page)) {
            # Skip landing pages in sidebar groups (they're already in navbar)
            if (proj$pages[[matching_page]]$is_landing_page) {
              next
            }

            if (pages_added == 0) {
              yaml_lines <- c(yaml_lines, "      contents:")
            }
            pages_added <- pages_added + 1

            # Use lowercase with underscores for filenames
            filename <- tolower(gsub("[^a-zA-Z0-9]", "_", matching_page))

            # Build text with icon if provided
            text_content <- paste0("\"", matching_page, "\"")
            if (!is.null(proj$pages[[matching_page]]$icon)) {
              icon_shortcode <- if (grepl("{{< iconify", proj$pages[[matching_page]]$icon, fixed = TRUE)) {
                proj$pages[[matching_page]]$icon
              } else {
                icon(proj$pages[[matching_page]]$icon)
              }
              text_content <- paste0("\"", icon_shortcode, " ", matching_page, "\"")
            }

            yaml_lines <- c(yaml_lines,
              paste0("        - text: ", text_content),
              paste0("          href: ", filename, ".qmd")
            )
          }
        }

        # If no pages were added, add a placeholder to avoid empty contents
        if (pages_added == 0) {
          yaml_lines <- c(yaml_lines, "      contents:")
          yaml_lines <- c(yaml_lines, "        - text: \"No pages in this group\"")
          yaml_lines <- c(yaml_lines, "          href: #")
        }
      }
    } else {
      # Simple sidebar mode - single sidebar (existing behavior)

      # Sidebar style
      if (!is.null(proj$sidebar_style)) {
        yaml_lines <- c(yaml_lines, paste0("    style: \"", proj$sidebar_style, "\""))
      }

      # Sidebar background
      if (!is.null(proj$sidebar_background)) {
        yaml_lines <- c(yaml_lines, paste0("    background: \"", proj$sidebar_background, "\""))
      }

      # Sidebar foreground
      if (!is.null(proj$sidebar_foreground)) {
        yaml_lines <- c(yaml_lines, paste0("    foreground: \"", proj$sidebar_foreground, "\""))
      }

      # Sidebar border
      if (!is.null(proj$sidebar_border)) {
        yaml_lines <- c(yaml_lines, paste0("    border: ", tolower(proj$sidebar_border)))
      }

      # Sidebar alignment
      if (!is.null(proj$sidebar_alignment)) {
        yaml_lines <- c(yaml_lines, paste0("    alignment: \"", proj$sidebar_alignment, "\""))
      }

      # Sidebar collapse level
      if (!is.null(proj$sidebar_collapse_level)) {
        yaml_lines <- c(yaml_lines, paste0("    collapse-level: ", proj$sidebar_collapse_level))
      }

      # Sidebar pinned
      if (!is.null(proj$sidebar_pinned)) {
        yaml_lines <- c(yaml_lines, paste0("    pinned: ", tolower(proj$sidebar_pinned)))
      }

      # Sidebar tools
      if (!is.null(proj$sidebar_tools) && length(proj$sidebar_tools) > 0) {
        yaml_lines <- c(yaml_lines, "    tools:")
        for (tool in proj$sidebar_tools) {
          if (is.list(tool) && "icon" %in% names(tool) && "href" %in% names(tool)) {
            yaml_lines <- c(yaml_lines, paste0("      - icon: ", tool$icon))
            yaml_lines <- c(yaml_lines, paste0("        href: ", tool$href))
            if ("text" %in% names(tool)) {
              yaml_lines <- c(yaml_lines, paste0("        text: \"", tool$text, "\""))
            }
          }
        }
      }

      # Sidebar contents - auto-generate from pages if not specified
      if (!is.null(proj$sidebar_contents)) {
        yaml_lines <- c(yaml_lines, "    contents:")
        for (item in proj$sidebar_contents) {
          if (is.list(item)) {
            if ("text" %in% names(item) && "href" %in% names(item)) {
              yaml_lines <- c(yaml_lines, paste0("      - text: \"", item$text, "\""))
              yaml_lines <- c(yaml_lines, paste0("        href: ", item$href))
            } else if ("section" %in% names(item)) {
              yaml_lines <- c(yaml_lines, paste0("      - section: \"", item$section, "\""))
              if ("contents" %in% names(item)) {
                yaml_lines <- c(yaml_lines, "        contents:")
                for (subitem in item$contents) {
                  if (is.character(subitem)) {
                    yaml_lines <- c(yaml_lines, paste0("          - ", subitem))
                  } else if (is.list(subitem)) {
                    yaml_lines <- c(yaml_lines, paste0("          - text: \"", subitem$text, "\""))
                    yaml_lines <- c(yaml_lines, paste0("            href: ", subitem$href))
                  }
                }
              }
            }
          } else if (is.character(item)) {
            yaml_lines <- c(yaml_lines, paste0("      - ", item))
          }
        }
      } else {
        # Auto-generate sidebar contents from pages
        yaml_lines <- c(yaml_lines, "    contents:")

        # Add landing page first if it exists
        landing_page_name <- NULL
        for (page_name in names(proj$pages)) {
          if (proj$pages[[page_name]]$is_landing_page) {
            landing_page_name <- page_name
            break
          }
        }

        if (!is.null(landing_page_name)) {
          yaml_lines <- c(yaml_lines, "      - text: \"Home\"")
          yaml_lines <- c(yaml_lines, "        href: index.qmd")
        }

        # Add other pages
        for (page_name in names(proj$pages)) {
          if (!is.null(proj$landing_page) && page_name == proj$landing_page) {
            next  # Skip landing page as it's already added
          }

          # Use lowercase with underscores for filenames
          filename <- tolower(gsub("[^a-zA-Z0-9]", "_", page_name))

          # Build text with icon if provided
          text_content <- paste0("\"", page_name, "\"")
          if (!is.null(proj$pages[[page_name]]$icon)) {
            icon_shortcode <- if (grepl("{{< iconify", proj$pages[[page_name]]$icon, fixed = TRUE)) {
              proj$pages[[page_name]]$icon
            } else {
              icon(proj$pages[[page_name]]$icon)
            }
            text_content <- paste0("\"", icon_shortcode, " ", page_name, "\"")
          }

          yaml_lines <- c(yaml_lines,
            paste0("      - text: ", text_content),
            paste0("        href: ", filename, ".qmd")
          )
        }
      }
    }
  }

  # Add breadcrumbs
  if (!is.null(proj$breadcrumbs)) {
    yaml_lines <- c(yaml_lines, paste0("  bread-crumbs: ", tolower(proj$breadcrumbs)))
  }

  # Add page navigation
  if (!is.null(proj$page_navigation)) {
    yaml_lines <- c(yaml_lines, paste0("  page-navigation: ", tolower(proj$page_navigation)))
  }

  # Add back to top
  if (!is.null(proj$back_to_top)) {
    yaml_lines <- c(yaml_lines, paste0("  back-to-top-navigation: ", tolower(proj$back_to_top)))
  }

  # Add reader mode
  if (!is.null(proj$reader_mode)) {
    yaml_lines <- c(yaml_lines, paste0("  reader-mode: ", tolower(proj$reader_mode)))
  }

  # Add repository URL and actions
  if (!is.null(proj$repo_url)) {
    yaml_lines <- c(yaml_lines, paste0("  repo-url: ", proj$repo_url))
    if (!is.null(proj$repo_actions) && length(proj$repo_actions) > 0) {
      actions_str <- paste(proj$repo_actions, collapse = ", ")
      yaml_lines <- c(yaml_lines, paste0("  repo-actions: [", actions_str, "]"))
    }
  }

  # Add page footer if provided
  if (!is.null(proj$page_footer)) {
    yaml_lines <- c(yaml_lines, paste0("  page-footer: \"", proj$page_footer, "\""))
  }

  # Add format section with theme and SCSS
  yaml_lines <- c(yaml_lines,
    "",
    "format:",
    "  html:",
    "    theme:"
  )
  
  # Add base theme
  yaml_lines <- c(yaml_lines, paste0("      - ", proj$theme %||% "default"))
  
  # Add tabset theme SCSS if specified
  if (!is.null(proj$tabset_theme) && proj$tabset_theme != "none") {
    tabset_scss_file <- paste0("_tabset_", proj$tabset_theme, ".scss")
    yaml_lines <- c(yaml_lines, paste0("      - ", tabset_scss_file))
  }
  
  # Add generated color override SCSS if colors are customized
  if (!is.null(proj$tabset_colors) && length(proj$tabset_colors) > 0) {
    yaml_lines <- c(yaml_lines, "      - _tabset_colors.scss")
  }
  
  # Add custom SCSS if provided
  if (!is.null(proj$custom_scss)) {
    yaml_lines <- c(yaml_lines, paste0("      - ", proj$custom_scss))
  }
  
  yaml_lines <- c(yaml_lines, "")

  # Add custom CSS if provided
  if (!is.null(proj$custom_css)) {
    yaml_lines <- c(yaml_lines, "    css:")
    yaml_lines <- c(yaml_lines, paste0("      - ", proj$custom_css))
  }

  # Add table of contents (simplified)
  if (!is.null(proj$toc)) {
    yaml_lines <- c(yaml_lines, "    toc: true")
  }

  # Add math rendering
  if (!is.null(proj$math)) {
    yaml_lines <- c(yaml_lines, "    math:")
    yaml_lines <- c(yaml_lines, paste0("      engine: ", proj$math))
  }

  # Add code folding
  if (!is.null(proj$code_folding)) {
    yaml_lines <- c(yaml_lines, "    code-fold: true")
  }

  # Add code tools
  if (!is.null(proj$code_tools)) {
    yaml_lines <- c(yaml_lines, "    code-tools: true")
  }

  # Add value boxes
  if (proj$value_boxes) {
    yaml_lines <- c(yaml_lines, "    value-boxes: true")
  }

  # Add page layout
  if (!is.null(proj$page_layout)) {
    yaml_lines <- c(yaml_lines, paste0("    page-layout: ", proj$page_layout))
  }

  # Add Shiny
  if (proj$shiny) {
    yaml_lines <- c(yaml_lines, "    shiny: true")
  }

  # Add Observable
  if (proj$observable) {
    yaml_lines <- c(yaml_lines, "    observable: true")
  }

  # Add Jupyter
  if (proj$jupyter) {
    yaml_lines <- c(yaml_lines, "    jupyter: true")
  }

  # Add analytics
  if (!is.null(proj$google_analytics)) {
    yaml_lines <- c(yaml_lines, "    google-analytics:")
    yaml_lines <- c(yaml_lines, paste0("      id: \"", proj$google_analytics, "\""))
  }

  if (!is.null(proj$plausible)) {
    yaml_lines <- c(yaml_lines, "    plausible:")
    yaml_lines <- c(yaml_lines, paste0("      domain: \"", proj$plausible, "\""))
  }

  if (!is.null(proj$gtag)) {
    yaml_lines <- c(yaml_lines, "    gtag:")
    yaml_lines <- c(yaml_lines, paste0("      id: \"", proj$gtag, "\""))
  }

  # Add GitHub Pages
  if (!is.null(proj$github_pages)) {
    yaml_lines <- c(yaml_lines, "    github-pages:")
    if (is.character(proj$github_pages)) {
      yaml_lines <- c(yaml_lines, paste0("      branch: ", proj$github_pages))
    } else if (is.list(proj$github_pages)) {
      for (key in names(proj$github_pages)) {
        yaml_lines <- c(yaml_lines, paste0("      ", key, ": ", proj$github_pages[[key]]))
      }
    }
  }

  # Add Netlify
  if (!is.null(proj$netlify)) {
    yaml_lines <- c(yaml_lines, "    netlify:")
    if (is.list(proj$netlify)) {
      for (key in names(proj$netlify)) {
        yaml_lines <- c(yaml_lines, paste0("      ", key, ": ", proj$netlify[[key]]))
      }
    }
  }

  # Note: iconify extension is installed as a shortcode extension, not a filter
  # It will be automatically available once installed in _extensions/
  # No need to add it to the filters section

  yaml_lines
}


# Generate default page content when no custom template is used
# Generate loading overlay chunk
.generate_loading_overlay_chunk <- function(theme = "light", text = "Loading") {
  c(
    "",
    "```{r, echo=FALSE, message=FALSE, warning=FALSE, results='asis'}",
    "library(htmltools)",
    "",
    "add_loading_overlay <- function(",
    "  text = \"Loading…\",",
    "  timeout_ms = 2200,",
    "  theme = c(\"light\", \"glass\", \"dark\", \"accent\")",
    ") {",
    "  theme <- match.arg(theme)",
    "  css <- switch(",
    "    theme,",
    "    light = \"",
    "      #page-loading-overlay {",
    "        position: fixed; inset: 0; z-index: 9999;",
    "        display: flex; align-items: center; justify-content: center;",
    "        background: rgba(255,255,255,0.98);",
    "        backdrop-filter: blur(10px);",
    "        transition: opacity .35s ease, visibility .35s ease;",
    "      }",
    "      #page-loading-overlay.hide { opacity: 0; visibility: hidden; }",
    "      .plo-card {",
    "        background: rgba(255,255,255,0.85);",
    "        border: 1px solid rgba(0,0,0,0.03);",
    "        border-radius: 18px;",
    "        padding: 1rem 1.2rem .9rem 1.2rem;",
    "        display: flex; flex-direction: column; gap: .5rem; align-items: center;",
    "        box-shadow: 0 14px 38px rgba(15,23,42,0.05);",
    "        min-width: 185px;",
    "      }",
    "      .plo-spinner {",
    "        width: 38px; height: 38px; border-radius: 9999px;",
    "        border: 3px solid rgba(148,163,184,0.32);",
    "        border-top-color: rgba(15,23,42,0.9);",
    "        animation: plo-spin 1s linear infinite;",
    "      }",
    "      @keyframes plo-spin { to { transform: rotate(360deg); } }",
    "      .plo-title { font-size: .8rem; font-weight: 500; color: rgba(15,23,42,0.85); }",
    "      .plo-sub { font-size: .68rem; color: rgba(15,23,42,0.4); }",
    "    \",",
    "    glass = \"",
    "      #page-loading-overlay {",
    "        position: fixed; inset: 0; z-index: 9999;",
    "        display: flex; align-items: center; justify-content: center;",
    "        background: rgba(255,255,255,0.45);",
    "        backdrop-filter: blur(16px);",
    "        transition: opacity .35s ease, visibility .35s ease;",
    "      }",
    "      #page-loading-overlay.hide { opacity: 0; visibility: hidden; }",
    "      .plo-card {",
    "        background: rgba(255,255,255,0.25);",
    "        border: 1px solid rgba(255,255,255,0.55);",
    "        border-radius: 20px;",
    "        padding: 1.1rem 1.3rem 1rem 1.3rem;",
    "        display: flex; flex-direction: column; gap: .5rem; align-items: center;",
    "        box-shadow: 0 18px 45px rgba(15,23,42,0.08);",
    "        min-width: 190px;",
    "      }",
    "      .plo-spinner {",
    "        width: 40px; height: 40px;",
    "        border-radius: 9999px;",
    "        border: 3px solid rgba(255,255,255,0.4);",
    "        border-top-color: rgba(15,23,42,0.75);",
    "        animation: plo-spin 1s linear infinite;",
    "      }",
    "      @keyframes plo-spin { to { transform: rotate(360deg); } }",
    "      .plo-title { font-size: .78rem; font-weight: 500; color: rgba(15,23,42,0.88); }",
    "      .plo-sub { font-size: .65rem; color: rgba(15,23,42,0.5); }",
    "    \",",
    "    dark = \"",
    "      #page-loading-overlay {",
    "        position: fixed; inset: 0; z-index: 9999;",
    "        display: flex; align-items: center; justify-content: center;",
    "        background: radial-gradient(circle at top, #0f172a 0%, #020617 45%, #000 100%);",
    "        backdrop-filter: blur(10px);",
    "        transition: opacity .35s ease, visibility .35s ease;",
    "      }",
    "      #page-loading-overlay.hide { opacity: 0; visibility: hidden; }",
    "      .plo-card {",
    "        background: rgba(15,23,42,0.2);",
    "        border: 1px solid rgba(255,255,255,0.06);",
    "        border-radius: 18px;",
    "        padding: 1rem 1.1rem .85rem 1.1rem;",
    "        display: flex; flex-direction: column; gap: .45rem; align-items: center;",
    "        box-shadow: 0 18px 45px rgba(0,0,0,0.3);",
    "        min-width: 180px;",
    "      }",
    "      .plo-spinner {",
    "        width: 36px; height: 36px;",
    "        border-radius: 9999px;",
    "        border: 3px solid rgba(15,23,42,0.45);",
    "        border-top-color: rgba(255,255,255,0.85);",
    "        animation: plo-spin 1s linear infinite;",
    "      }",
    "      @keyframes plo-spin { to { transform: rotate(360deg); } }",
    "      .plo-title { font-size: .78rem; font-weight: 500; color: #fff; }",
    "      .plo-sub { font-size: .64rem; color: rgba(255,255,255,0.4); }",
    "    \",",
    "    accent = \"",
    "      #page-loading-overlay {",
    "        position: fixed; inset: 0; z-index: 9999;",
    "        display: flex; align-items: center; justify-content: center;",
    "        background: radial-gradient(circle, rgba(255,255,255,0.98) 0%, rgba(245,248,255,0.95) 60%);",
    "        backdrop-filter: blur(10px);",
    "        transition: opacity .35s ease, visibility .35s ease;",
    "      }",
    "      #page-loading-overlay.hide { opacity: 0; visibility: hidden; }",
    "      .plo-card {",
    "        background: #fff;",
    "        border: 1px solid rgba(59,130,246,0.12);",
    "        border-radius: 16px;",
    "        padding: .95rem 1.25rem .75rem 1.25rem;",
    "        display: flex; flex-direction: column; gap: .45rem; align-items: center;",
    "        box-shadow: 0 14px 30px rgba(59,130,246,0.12);",
    "        min-width: 180px;",
    "      }",
    "      .plo-spinner {",
    "        width: 34px; height: 34px;",
    "        border-radius: 9999px;",
    "        border: 3px solid rgba(59,130,246,0.15);",
    "        border-top-color: rgba(59,130,246,0.9);",
    "        animation: plo-spin .85s linear infinite;",
    "      }",
    "      @keyframes plo-spin { to { transform: rotate(360deg); } }",
    "      .plo-title { font-size: .78rem; font-weight: 500; color: rgba(15,23,42,0.88); }",
    "      .plo-sub { font-size: .64rem; color: rgba(15,23,42,0.35); }",
    "    \"",
    "  )",
    "  tags$div(",
    "    tags$style(HTML(css)),",
    "    tags$div(",
    "      id = \"page-loading-overlay\",",
    "      tags$div(",
    "        class = \"plo-card\",",
    "        tags$div(class = \"plo-spinner\"),",
    "        tags$div(class = \"plo-title\", text),",
    "        tags$div(class = \"plo-sub\", \"Even geduld.\")",
    "      )",
    "    ),",
    "    tags$script(HTML(sprintf(\"",
    "      window.addEventListener('load', function() {",
    "        setTimeout(function() {",
    "          var el = document.getElementById('page-loading-overlay');",
    "          if (el) el.classList.add('hide');",
    "        }, %d);",
    "      });",
    "    \", timeout_ms)))",
    "  )",
    "}",
    "",
    paste0("add_loading_overlay(\"", text, "\", theme = \"", theme, "\")"),
    "```",
    ""
  )
}

.generate_default_page_content <- function(page) {
  # Build title with icon if provided
  title_content <- page$name
  if (!is.null(page$icon)) {
    icon_shortcode <- if (grepl("{{< iconify", page$icon, fixed = TRUE)) {
      page$icon
    } else {
      icon(page$icon)
    }
    title_content <- paste0(icon_shortcode, " ", page$name)
  }

  content <- c(
    "---",
    paste0("title: \"", title_content, "\""),
    "format: html",
    "---",
    ""
  )

  # Add custom text content if provided
  if (!is.null(page$text) && nzchar(page$text)) {
    content <- c(content, page$text, "")
  }

  # Add global setup chunk with libraries, data, and settings
  if (!is.null(page$data_path) || !is.null(page$visualizations)) {
    content <- c(content, .generate_global_setup_chunk(page))
  }
  
  # Add loading overlay chunk if enabled
  if (!is.null(page$overlay) && page$overlay) {
    # Get overlay settings with explicit defaults
    if (is.null(page$overlay_theme)) {
      overlay_theme <- "light"
    } else {
      overlay_theme <- page$overlay_theme
    }
    
    if (is.null(page$overlay_text)) {
      overlay_text <- "Loading"
    } else {
      overlay_text <- page$overlay_text
    }
    
    content <- c(content, .generate_loading_overlay_chunk(overlay_theme, overlay_text))
  }

  # Add visualizations
  if (!is.null(page$visualizations)) {
    viz_content <- .generate_viz_from_specs(page$visualizations)
    content <- c(content, viz_content)
  } else if (is.null(page$text) || !nzchar(page$text)) {
    content <- c(content, "This page was generated without a template.")
  }

  content
}

#' Collect unique filters from all visualizations
#'
#' @param visualizations List of visualization specifications
#' @return List of unique filter formulas with generated names, including source dataset
#' @noRd
.collect_unique_filters <- function(visualizations) {
  if (is.null(visualizations) || length(visualizations) == 0) {
    return(list())
  }
  
  filters <- list()
  
  # Recursive function to extract filters from nested structures
  .extract_filters <- function(viz_list) {
    for (viz in viz_list) {
      if (!is.null(viz$type) && viz$type == "tabgroup") {
        # Nested tabgroup - recurse
        .extract_filters(viz$visualizations)
      } else if (!is.null(viz$filter)) {
        # Has a filter - add it with dataset context
        filter_expr <- deparse(viz$filter[[2]], width.cutoff = 500L)
        filter_key <- paste(filter_expr, collapse = " ")
        
        # Get source dataset - default to "data" if not specified
        if (!is.null(viz$data) && nzchar(viz$data)) {
          source_dataset <- viz$data
        } else {
          source_dataset <- "data"
        }
        
        # Create composite key: dataset + filter
        composite_key <- paste0(source_dataset, "::", filter_key)
        
        if (!composite_key %in% names(filters)) {
          filters[[composite_key]] <<- list(
            formula = viz$filter,
            source_dataset = source_dataset,
            filter_expr = filter_key
          )
        }
      }
    }
  }
  
  .extract_filters(visualizations)
  
  # Generate unique names for each filter
  result <- list()
  for (composite_key in names(filters)) {
    filter_info <- filters[[composite_key]]
    filter_formula <- filter_info$formula
    source_dataset <- filter_info$source_dataset
    filter_expr <- filter_info$filter_expr
    
    # Create a short hash for the filter
    filter_hash <- substr(digest::digest(filter_expr), 1, 8)
    filtered_dataset_name <- paste0(source_dataset, "_filtered_", filter_hash)
    
    result[[filtered_dataset_name]] <- list(
      name = filtered_dataset_name,
      formula = filter_formula,
      expr = deparse(filter_formula[[2]], width.cutoff = 500L),
      source_dataset = source_dataset
    )
  }
  
  result
}

#' Find the dataset name for a given filter
#'
#' @param filter Formula filter to find
#' @param filter_map List of filter mappings from .collect_unique_filters()
#' @return Character string of dataset name, or "data" if no filter
#' @noRd
.get_filter_dataset_name <- function(filter, filter_map) {
  if (is.null(filter)) {
    return("data")
  }
  
  filter_expr <- deparse(filter[[2]], width.cutoff = 500L)
  filter_key <- paste(filter_expr, collapse = " ")
  filter_hash <- substr(digest::digest(filter_key), 1, 8)
  dataset_name <- paste0("data_filtered_", filter_hash)
  
  # Verify it exists in the map
  if (dataset_name %in% names(filter_map)) {
    return(dataset_name)
  }
  
  # Fallback to data (shouldn't happen)
  return("data")
}

#' Generate global setup chunk for QMD files
#'
#' Creates a comprehensive setup chunk that includes libraries, data loading,
#' filtered datasets, and global settings to avoid repetition in individual visualizations.
#'
#' @param page Page object containing data_path and visualizations
#' @return Character vector of setup chunk lines
#' @keywords internal
.generate_global_setup_chunk <- function(page) {
  lines <- c(
    "```{r setup}",
    "#| echo: false",
    "#| warning: false",
    "#| message: false",
    "#| error: false",
    "#| results: 'hide'",
    "",
    "# Load required libraries",
    "library(dashboardr)",
    "library(dplyr)",
    "library(highcharter)",
    "",
    "# Global chunk options",
    "knitr::opts_chunk$set(",
    "  echo = FALSE,",
    "  warning = FALSE,",
    "  message = FALSE,",
    "  error = FALSE,",
    "  fig.width = 12,",
    "  fig.height = 8,",
    "  dpi = 300",
    ")",
    ""
  )

  # Add data loading if data_path is present
  if (!is.null(page$data_path)) {
    # Check if data_path is a list (multi-dataset) regardless of is_multi_dataset flag
    if (is.list(page$data_path)) {
      # Multiple datasets
      lines <- c(lines, "# Load multiple datasets", "")
      
      for (dataset_name in names(page$data_path)) {
        data_file <- basename(page$data_path[[dataset_name]])
        lines <- c(lines,
          paste0("# Load ", dataset_name, " from ", data_file),
          paste0(dataset_name, " <- readRDS('", data_file, "')"),
          paste0("cat('", dataset_name, " loaded:', nrow(", dataset_name, "), 'rows,', ncol(", dataset_name, "), 'columns\\n')"),
          ""
        )
      }
    } else {
      # Single dataset (data_path is a string)
      data_file <- basename(page$data_path)
      lines <- c(lines,
        paste0("# Load data from ", data_file),
        paste0("data <- readRDS('", data_file, "')"),
        "",
        "# Data summary",
        "cat('Dataset loaded:', nrow(data), 'rows,', ncol(data), 'columns\\n')",
        ""
      )
    }
  }

  # Collect and create all filtered datasets
  if (!is.null(page$visualizations) && !is.null(page$data_path)) {
    filter_map <- .collect_unique_filters(page$visualizations)
    
    if (length(filter_map) > 0) {
      lines <- c(lines,
        "# Create filtered datasets",
        "# Each filter is applied once and reused across visualizations",
        ""
      )
      
      for (filter_info in filter_map) {
        filter_expr <- paste(filter_info$expr, collapse = " ")
        
        # Get source dataset - default to "data" if not specified
        if (!is.null(filter_info$source_dataset) && nzchar(filter_info$source_dataset)) {
          source_dataset <- filter_info$source_dataset
        } else {
          source_dataset <- "data"
        }
        
        lines <- c(lines,
          paste0(filter_info$name, " <- ", source_dataset, " %>% dplyr::filter(", filter_expr, ")")
        )
      }
      
      lines <- c(lines, "")
    }
  }

  lines <- c(lines, "```", "")
  lines
}

# ===================================================================
# Tabset Theme Helpers
# ===================================================================

#' Generate SCSS for custom tabset colors
#'
#' Internal helper to generate SCSS code that overrides tabset colors
#'
#' @param colors Named list of color values
#' @return Character vector of SCSS lines
#' @noRd
.generate_tabset_color_scss <- function(colors) {
  scss_lines <- c(
    "/*-- scss:rules --*/",
    "",
    "/* Custom tabset color overrides */",
    ""
  )
  
  # Map color keys to CSS selectors and properties
  if (!is.null(colors$inactive_bg)) {
    scss_lines <- c(scss_lines,
      ".panel-tabset .nav-item {",
      paste0("  background-color: ", colors$inactive_bg, " !important;"),
      "}"
    )
  }
  
  if (!is.null(colors$inactive_text)) {
    scss_lines <- c(scss_lines,
      ".panel-tabset .nav-item {",
      paste0("  color: ", colors$inactive_text, " !important;"),
      "}"
    )
  }
  
  if (!is.null(colors$active_bg)) {
    scss_lines <- c(scss_lines,
      ".panel-tabset .nav-tabs .nav-link.active {",
      paste0("  background-color: ", colors$active_bg, " !important;"),
      "}"
    )
  }
  
  if (!is.null(colors$active_text)) {
    scss_lines <- c(scss_lines,
      ".panel-tabset .nav-tabs .nav-link.active {",
      paste0("  color: ", colors$active_text, " !important;"),
      "}"
    )
  }
  
  if (!is.null(colors$hover_bg)) {
    scss_lines <- c(scss_lines,
      ".panel-tabset .nav-item:hover {",
      paste0("  background-color: ", colors$hover_bg, " !important;"),
      "}"
    )
  }
  
  if (!is.null(colors$hover_text)) {
    scss_lines <- c(scss_lines,
      ".panel-tabset .nav-item:hover {",
      paste0("  color: ", colors$hover_text, " !important;"),
      "}"
    )
  }
  
  scss_lines
}

# ===================================================================
# Custom Progress Display
# ===================================================================

#' Show custom progress message
#'
#' @param msg Message to display
#' @param icon Emoji or symbol to prefix
#' @param show_progress Whether to show progress
#' @keywords internal
.progress_msg <- function(msg, icon = "▪", show_progress = TRUE) {
  if (show_progress) {
    cat(icon, msg, "\n")
  }
}

#' Show custom progress step
#'
#' @param msg Step message
#' @param elapsed Optional elapsed time in seconds
#' @param show_progress Whether to show progress
#' @keywords internal
.progress_step <- function(msg, elapsed = NULL, show_progress = TRUE, is_last = FALSE, use_page_style = FALSE) {
  if (show_progress) {
    time_str <- if (!is.null(elapsed)) {
      if (elapsed < 1) {
        sprintf("  (%.0f ms)", elapsed * 1000)
      } else {
        sprintf("  (%.0f ms)", elapsed * 1000)
      }
    } else {
      ""
    }
    
    if (use_page_style) {
      # Use print method style for pages
      prefix <- if (is_last) "║ └─ 📄 " else "║ ├─ 📄 "
      cat(prefix, msg, time_str, "\n", sep = "")
    } else {
      # Use regular style for setup/config steps
      cat("  ✓", msg, time_str, "\n")
    }
  }
}

#' Show progress header
#'
#' @param title Header title
#' @param show_progress Whether to show progress
#' @keywords internal
.progress_header <- function(title, show_progress = TRUE) {
  if (show_progress) {
    cat("\n")
    cat("╔═══════════════════════════════════════════════════╗\n")
    cat("║  ", title, sprintf("%*s", max(0, 45 - nchar(title)), ""), "║\n")
    cat("╚═══════════════════════════════════════════════════╝\n")
  }
}

#' Show progress section
#'
#' @param title Section title
#' @param show_progress Whether to show progress
#' @keywords internal
.progress_section <- function(title, show_progress = TRUE) {
  if (show_progress) {
    cat("\n")
    cat("┌─", title, "\n")
  }
}

#' Show progress bar
#'
#' @param current Current step
#' @param total Total steps
#' @param label Optional label
#' @param show_progress Whether to show progress
#' @keywords internal
.progress_bar <- function(current, total, label = "", show_progress = TRUE) {
  if (show_progress) {
    pct <- round((current / total) * 100)
    filled <- round(pct / 5)  # 20 chars total
    empty <- 20 - filled
    
    bar <- paste0(
      "[",
      paste(rep("█", filled), collapse = ""),
      paste(rep("░", empty), collapse = ""),
      "] ",
      sprintf("%3d%%", pct),
      if (nzchar(label)) paste0(" - ", label) else ""
    )
    
    cat("\r", bar)
    if (current == total) cat("\n")
  }
}

# ===================================================================
# Dashboard Generation and Rendering
# ===================================================================

#' Generate all dashboard files
#'
#' Writes out all .qmd files, _quarto.yml, and optionally renders the dashboard
#' to HTML using Quarto. Supports incremental builds to skip unchanged pages and
#' preview mode to generate only specific pages.
#'
#' @param proj A dashboard_project object
#' @param render Whether to render to HTML (requires Quarto CLI)
#' @param open How to open the result: "browser", "viewer", or FALSE
#' @param incremental Whether to use incremental builds (default: FALSE). When TRUE, skips 
#'   regenerating QMD files for unchanged pages and skips Quarto rendering if nothing changed.
#'   Uses MD5 hashing to detect changes.
#' @param preview Optional character vector of page names to generate. When specified, only
#'   the listed pages will be generated, skipping all others. Useful for quick testing of
#'   specific pages without waiting for the entire dashboard to generate. Page names are
#'   case-insensitive. If a page name doesn't exist, the function will suggest alternatives
#'   based on typo detection. Default: NULL (generates all pages).
#' @param show_progress Whether to display custom progress indicators (default: TRUE). When
#'   TRUE, shows a beautiful progress display with timing information, progress bars, and
#'   visual indicators for each generation stage. Set to FALSE for minimal output.
#' @param quiet Whether to suppress all output (default: FALSE). When TRUE, completely
#'   silences all messages, progress indicators, and Quarto rendering output. Useful for
#'   scripts and automated workflows. Overrides show_progress.
#' @return Invisibly returns the project object with build_info attached
#' @export
#' @examples
#' \dontrun{
#' # Generate and render dashboard
#' dashboard %>% generate_dashboard(render = TRUE, open = "browser")
#' 
#' # Generate without rendering (faster for quick iterations)
#' dashboard %>% generate_dashboard(render = FALSE)
#' 
#' # Incremental builds (skip unchanged pages)
#' dashboard %>% generate_dashboard(render = TRUE, incremental = TRUE)
#' 
#' # Preview specific page
#' dashboard %>% generate_dashboard(preview = "Analysis")
#' 
#' # Quiet mode for scripts
#' dashboard %>% generate_dashboard(render = FALSE, quiet = TRUE)
#' }
generate_dashboard <- function(proj, render = TRUE, open = "browser", incremental = FALSE, preview = NULL, 
                              show_progress = TRUE, quiet = FALSE) {
  # Start timing
  start_time <- Sys.time()
  
  # Quiet mode overrides show_progress
  if (quiet) {
    show_progress <- FALSE
  }
  
  if (!inherits(proj, "dashboard_project")) {
    stop("proj must be a dashboard_project object")
  }
  
  # Validate preview parameter
  preview_pages <- NULL
  if (!is.null(preview)) {
    # Normalize preview page names (case-insensitive)
    preview <- tolower(preview)
    available_pages <- tolower(names(proj$pages))
    
    # Check each preview page exists
    for (p in preview) {
      if (!p %in% available_pages) {
        # Try to suggest alternatives
        suggestion <- .suggest_alternative(p, names(proj$pages))
        if (!is.null(suggestion)) {
          stop("Page '", preview[1], "' not found in dashboard. Did you mean '", suggestion, "'?\n",
               "Available pages: ", paste(names(proj$pages), collapse = ", "))
        } else {
          stop("Page '", preview[1], "' not found in dashboard.\n",
               "Available pages: ", paste(names(proj$pages), collapse = ", "))
        }
      }
    }
    
    # Map preview names to actual page names
    preview_pages <- names(proj$pages)[tolower(names(proj$pages)) %in% preview]
    
    if (!quiet) {
      message("📄 Preview mode: Generating only ", length(preview_pages), " page(s): ", 
              paste(preview_pages, collapse = ", "))
    }
  }
  
  # Show progress header
  .progress_header(paste0("🚀 Generating Dashboard: ", proj$title), show_progress)
  
  # Reset chunk label tracker for new generation
  if (exists(".chunk_label_tracker", envir = .GlobalEnv)) {
    rm(".chunk_label_tracker", envir = .GlobalEnv)
  }

  output_dir <- .resolve_output_dir(proj$output_dir, proj$allow_inside_pkg)
  .progress_msg("Output directory:", "📁", show_progress)
  if (show_progress) cat("   ", output_dir, "\n")

  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  # Load previous build manifest for incremental builds
  manifest <- if (incremental) .load_manifest(output_dir) else NULL
  new_manifest <- list(
    timestamp = Sys.time(),
    pages = list()
  )
  
  # Track which pages were regenerated vs skipped
  build_info <- list(
    regenerated = character(),
    skipped = character(),
    preview_mode = !is.null(preview_pages)
  )

  tryCatch({
    # Setup phase
    .progress_section("⚙️  Setup", show_progress)
    setup_start <- Sys.time()
    
    # Check if icons are used and install iconify extension if needed
    if (.check_for_icons(proj)) {
      # Check if iconify extension is already installed
      iconify_dir <- file.path(output_dir, "_extensions", "mcanouil", "iconify")
      if (!dir.exists(iconify_dir) || !file.exists(file.path(iconify_dir, "_extension.yml"))) {
        if (!quiet) message("Icons detected in dashboard. Installing iconify extension...")

        # Attempt to install iconify extension with proper error handling
        install_success <- .install_iconify_extension(output_dir)
        if (!install_success) {
          warning("Failed to install iconify extension automatically. Icons may not display correctly.")
          if (!quiet) {
            message("To fix this manually:")
            message("  cd ", output_dir)
            message("  quarto add mcanouil/quarto-iconify")
            message("\nOr remove icons from your dashboard to render without them")
          }
        }
      } else {
        if (!quiet) message("Iconify extension already installed")
      }
    }

    # Copy logo and favicon if provided
    if (!is.null(proj$logo) && file.exists(proj$logo)) {
      file.copy(proj$logo, file.path(output_dir, basename(proj$logo)), overwrite = TRUE)
    }
    if (!is.null(proj$favicon) && file.exists(proj$favicon)) {
      file.copy(proj$favicon, file.path(output_dir, basename(proj$favicon)), overwrite = TRUE)
    }

    # Copy tabset theme SCSS file if using a built-in theme
    if (!is.null(proj$tabset_theme) && proj$tabset_theme != "none") {
      theme_scss_name <- paste0("tabset_", proj$tabset_theme, ".scss")
      theme_scss_path <- system.file("extdata", "themes", theme_scss_name, package = "dashboardr")
      
      if (file.exists(theme_scss_path)) {
        target_path <- file.path(output_dir, paste0("_tabset_", proj$tabset_theme, ".scss"))
        file.copy(theme_scss_path, target_path, overwrite = TRUE)
        if (!quiet) message("Using tabset theme: ", proj$tabset_theme)
      } else {
        warning("Tabset theme file not found: ", theme_scss_name)
      }
    }
    
    # Generate color override SCSS if tabset_colors are specified
    if (!is.null(proj$tabset_colors) && length(proj$tabset_colors) > 0) {
      color_scss <- .generate_tabset_color_scss(proj$tabset_colors)
      writeLines(color_scss, file.path(output_dir, "_tabset_colors.scss"))
      if (!quiet) message("Applied custom tabset colors")
    }

    # Generate _quarto.yml
    yaml_content <- .generate_quarto_yml(proj)
    writeLines(yaml_content, file.path(output_dir, "_quarto.yml"))
    
    setup_elapsed <- as.numeric(difftime(Sys.time(), setup_start, units = "secs"))
    .progress_step("Configuration files ready", setup_elapsed, show_progress)

    # Page generation
    if (show_progress) {
      cat("\n")
      cat("║\n")
      cat("║ 📄 GENERATING PAGES:\n")
    }
    
    # Calculate total pages to generate
    pages_to_generate <- names(proj$pages)
    if (!is.null(proj$landing_page)) {
      # Exclude landing page from count as it's handled separately
      pages_to_generate <- setdiff(pages_to_generate, proj$landing_page)
    }
    if (!is.null(preview_pages)) {
      pages_to_generate <- intersect(pages_to_generate, preview_pages)
    }
    
    total_pages <- length(pages_to_generate)
    current_page <- 0
    
    # Determine if we'll also show landing page for last detection
    will_show_landing <- !is.null(proj$landing_page) && 
                         (is.null(preview_pages) || proj$landing_page %in% preview_pages)
    
    # Generate each page
    for (page_name in names(proj$pages)) {
      page <- proj$pages[[page_name]]

      # Skip landing page in regular pages loop - it's handled separately
      if (!is.null(proj$landing_page) && page_name == proj$landing_page) {
        next
      }
      
      # Skip if in preview mode and page is not in preview list
      if (!is.null(preview_pages) && !page_name %in% preview_pages) {
        next
      }

      # Track progress (no progress bar - page generation is fast)
      current_page <- current_page + 1
      page_start <- Sys.time()
      
      # Check if this is the last page (only if no landing page will be shown after)
      is_last_page <- (current_page == total_pages && !will_show_landing)

      # Use lowercase with underscores for filenames
      filename <- tolower(gsub("[^a-zA-Z0-9]", "_", page_name))
      page_file <- file.path(output_dir, paste0(filename, ".qmd"))

      # Check if page needs rebuild
      needs_rebuild <- .needs_rebuild(page_name, page, manifest)
      
      if (incremental && !needs_rebuild) {
        # Skip this page - it hasn't changed
        build_info$skipped <- c(build_info$skipped, page_name)
        # Store hash in new manifest
        new_manifest$pages[[page_name]] <- list(hash = .compute_hash(page))
        
        page_elapsed <- as.numeric(difftime(Sys.time(), page_start, units = "secs"))
        .progress_step(paste0(page_name, " (skipped)"), page_elapsed, show_progress, is_last_page, use_page_style = TRUE)
        next
      }
      
      # Mark as regenerated
      build_info$regenerated <- c(build_info$regenerated, page_name)

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
      
      # Store hash in new manifest
      new_manifest$pages[[page_name]] <- list(hash = .compute_hash(page))
      
      page_elapsed <- as.numeric(difftime(Sys.time(), page_start, units = "secs"))
      .progress_step(page_name, page_elapsed, show_progress, is_last_page, use_page_style = TRUE)

      # Copy data file(s) if needed
      if (!is.null(page$data_path)) {
        if (is.list(page$data_path)) {
          # Multiple datasets - copy each one
          for (dataset_name in names(page$data_path)) {
            data_file <- page$data_path[[dataset_name]]
            data_file_path <- file.path(output_dir, basename(data_file))
            target_path <- file.path(output_dir, basename(data_file))
            
            # Only copy if source and target are different
            if (normalizePath(data_file_path, mustWork = FALSE) != normalizePath(target_path, mustWork = FALSE)) {
              if (file.exists(data_file_path) && !file.copy(data_file_path, target_path, overwrite = TRUE)) {
                warning("Failed to copy data file for ", dataset_name, ": ", basename(data_file))
              }
            }
          }
        } else {
          # Single dataset
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
    }

    # Generate landing page as index.qmd if specified
    if (!is.null(proj$landing_page)) {
      landing_page_name <- proj$landing_page
      
      # Skip landing page if in preview mode and not in preview list
      if (is.null(preview_pages) || landing_page_name %in% preview_pages) {
        landing_start <- Sys.time()
        landing_page <- proj$pages[[landing_page_name]]
        index_file <- file.path(output_dir, "index.qmd")

        # Check if landing page needs rebuild
        needs_rebuild <- .needs_rebuild(landing_page_name, landing_page, manifest)
        
        if (incremental && !needs_rebuild) {
          build_info$skipped <- c(build_info$skipped, landing_page_name)
          new_manifest$pages[[landing_page_name]] <- list(hash = .compute_hash(landing_page))
          
          landing_elapsed <- as.numeric(difftime(Sys.time(), landing_start, units = "secs"))
          .progress_step(paste0(landing_page_name, " [🏠 Landing] (skipped)"), landing_elapsed, show_progress, is_last = TRUE, use_page_style = TRUE)
        } else {
          build_info$regenerated <- c(build_info$regenerated, landing_page_name)
          
          if (!is.null(landing_page$template)) {
            # Custom template
            content <- .process_template(landing_page$template, landing_page$params, output_dir)
            if (!is.null(landing_page$visualizations)) {
              viz_content <- .generate_viz_from_specs(landing_page$visualizations)
              content <- c(content, "", viz_content)
            }
          } else {
            # Default content
            content <- .generate_default_page_content(landing_page)
          }

          writeLines(content, index_file)
          new_manifest$pages[[landing_page_name]] <- list(hash = .compute_hash(landing_page))
          
          landing_elapsed <- as.numeric(difftime(Sys.time(), landing_start, units = "secs"))
          .progress_step(paste0(landing_page_name, " [🏠 Landing]"), landing_elapsed, show_progress, is_last = TRUE, use_page_style = TRUE)
        }
      }
    }
    
    # Delete pages that no longer exist
    if (incremental && !is.null(manifest)) {
      old_pages <- names(manifest$pages)
      new_pages <- names(proj$pages)
      deleted_pages <- setdiff(old_pages, new_pages)
      
      for (deleted_name in deleted_pages) {
        filename <- tolower(gsub("[^a-zA-Z0-9]", "_", deleted_name))
        page_file <- file.path(output_dir, paste0(filename, ".qmd"))
        if (file.exists(page_file)) {
          file.remove(page_file)
          message("Removed deleted page: ", deleted_name)
        }
      }
    }
    
    # Save manifest for next incremental build
    if (incremental) {
      .save_manifest(new_manifest, output_dir)
    }

    # Show build summary
    if (incremental && !quiet) {
      if (length(build_info$skipped) > 0) {
        message("Skipped ", length(build_info$skipped), " unchanged page(s): ",
                paste(head(build_info$skipped, 3), collapse = ", "),
                if (length(build_info$skipped) > 3) "..." else "")
      }
      if (length(build_info$regenerated) > 0) {
        message("Regenerated ", length(build_info$regenerated), " page(s): ",
                paste(head(build_info$regenerated, 3), collapse = ", "),
                if (length(build_info$regenerated) > 3) "..." else "")
      }
    }
    
    if (!quiet) message("Dashboard files generated successfully")

    # Render to HTML if requested
    render_success <- FALSE
    render_was_skipped <- FALSE
    if (render) {
      # Skip rendering if incremental and nothing changed
      if (incremental && length(build_info$regenerated) == 0) {
        if (!quiet) {
          message("✓ All pages unchanged - skipping Quarto rendering (incremental mode)")
          message("  Use render = TRUE, incremental = FALSE to force re-render")
          if (open == "browser") {
            message("  Note: Opening existing HTML (if available)")
          }
        }
        render_success <- TRUE  # Consider it successful since nothing needed rendering
        render_was_skipped <- TRUE
      } else {
        .progress_section("🎨 Rendering Dashboard", show_progress)
        render_start <- Sys.time()
        render_success <- .render_dashboard(output_dir, open, quiet, show_progress)
        render_elapsed <- as.numeric(difftime(Sys.time(), render_start, units = "secs"))
        
        if (render_success) {
          .progress_step("Rendering complete", render_elapsed, show_progress)
        } else {
          if (!quiet) {
            message("\n❌ Rendering FAILED")
            message("   QMD files were generated successfully, but Quarto rendering failed")
            message("   Check the error/warning messages above for details")
            message("\n   Common causes:")
            message("   • Quarto not installed: https://quarto.org/docs/get-started/")
            message("   • Missing iconify extension: cd ", output_dir, " && quarto add mcanouil/quarto-iconify")
          }
        }
      }
    }

    # Open browser if rendering was skipped but user requested it
    if (render_was_skipped && open == "browser") {
      output_dir_abs <- normalizePath(output_dir, mustWork = FALSE)
      index_file <- file.path(output_dir_abs, "docs", "index.html")
      if (file.exists(index_file)) {
        if (!quiet) message("Opening existing dashboard in browser...")
        utils::browseURL(index_file)
      } else {
        if (!quiet) {
          warning("Cannot open browser - no HTML files exist yet. Run with render = TRUE to create them.")
        }
      }
    }
    
    # Calculate elapsed time
    elapsed_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
    
    # Show beautiful CLI output after rendering (only if successful or not rendering)
    if (!quiet && (render_success || !render)) {
      .show_dashboard_summary(proj, output_dir, elapsed_time, build_info, show_progress)
    }

  }, error = function(e) {
    stop("Failed to generate dashboard: ", e$message)
  })

  # Return project with build info
  result <- proj
  result$build_info <- build_info
  invisible(result)
}

# Render Quarto project to HTML
.render_dashboard <- function(output_dir, open = FALSE, quiet = FALSE, show_progress = TRUE) {
  if (!requireNamespace("quarto", quietly = TRUE)) {
    if (!quiet) {
      message("quarto package not available. Skipping render.")
      message("Install with: install.packages('quarto')")
    }
    return(FALSE)
  }

  # Create docs folder even if rendering fails
  docs_dir <- file.path(output_dir, "docs")
  if (!dir.exists(docs_dir)) {
    dir.create(docs_dir, recursive = TRUE)
    if (!quiet) message("Created docs folder.")
  }

  owd <- setwd(normalizePath(output_dir))
  on.exit(setwd(owd), add = TRUE)
  
  # Check for remnant .rmarkdown files that cause cryptic errors
  rmarkdown_files <- list.files(output_dir, pattern = "\\.rmarkdown$", recursive = TRUE)
  if (length(rmarkdown_files) > 0) {
    stop(
      "\n❌ REMNANT .rmarkdown FILE DETECTED\n\n",
      "Found .rmarkdown file(s) in output directory:\n",
      paste("  •", rmarkdown_files, collapse = "\n"), "\n\n",
      "These files cause Quarto rendering to fail with cryptic errors.\n\n",
      "To fix:\n",
      "  1. Delete the .rmarkdown file(s)\n",
      "  2. Make sure you're using .qmd files (not .Rmd or .rmarkdown)\n",
      "  3. Try rendering again\n\n",
      "Command to remove: rm ", rmarkdown_files[1], "\n"
    )
  }

  tryCatch({
    # Render with Quarto
    if (quiet) {
      # Completely silent
      invisible(capture.output(quarto::quarto_render(".", as_job = FALSE), type = "message"))
    } else {
      # Show Quarto's normal output
      quarto::quarto_render(".", as_job = FALSE)
    }
    
    if (!quiet) message("Dashboard rendered successfully")

    # Open in browser if requested and render succeeded
    if (open == "browser") {
      # Normalize output_dir to absolute path to handle relative paths like "../docs"
      output_dir_abs <- normalizePath(output_dir, mustWork = FALSE)
      index_file <- file.path(output_dir_abs, "docs", "index.html")
      
      if (file.exists(index_file)) {
        if (!quiet) message("Opening dashboard in browser...")
        utils::browseURL(index_file)
      } else {
        # Check what files exist in docs/ for helpful error message
        docs_dir <- file.path(output_dir_abs, "docs")
        if (dir.exists(docs_dir)) {
          docs_files <- list.files(docs_dir, pattern = "\\.html$", full.names = FALSE)
        } else {
          docs_files <- character(0)
        }
        
        if (!quiet) {
          warning(
            "Could not find index.html to open in browser\n",
            "  Expected: ", index_file, "\n",
            "  docs/ exists: ", dir.exists(docs_dir), "\n",
            "  HTML files in docs/: ", if (length(docs_files) > 0) paste(docs_files, collapse = ", ") else "(none)", "\n",
            "\n",
            "  Possible reasons:\n",
            "  1. Rendering failed (check error messages above)\n",
            "  2. Quarto output directory mismatch\n",
            "  3. Landing page has different name\n",
            "\n",
            "  Try:\n",
            "  • Check for errors in Quarto output above\n",
            "  • Look in: ", docs_dir
          )
        }
      }
    }
    return(TRUE)
  }, error = function(e) {
    warning("Failed to render dashboard: ", e$message)

    # Check if it's an iconify extension error
    # if (grepl("iconify", e$message, ignore.case = TRUE)) {
    #   message("\n=== ICONIFY EXTENSION ERROR ===")
    #   message("The iconify extension is not installed. To fix this:")
    #   message("1. Install Quarto CLI: https://quarto.org/docs/get-started/")
    #   message("2. Run in your dashboard directory: quarto add mcanouil/quarto-iconify")
    #   message("3. Or run the provided script: ./install_iconify_manual.sh")
    #   message("\nAlternative: Remove icons from your dashboard calls to render without icons")
    # } else {
    #   message("To fix this issue:")
    #   message("1. Install Quarto command-line tools from: https://quarto.org/docs/get-started/")
    #   message("2. Or run 'quarto install' in R to install via the quarto package")
    # }
    # message("3. The QMD files are ready for manual rendering with: quarto render")
    return(FALSE)
  })
}

# ===================================================================
# Custom Print Methods for Better User Experience
# ===================================================================

#' Print Dashboard Project
#'
#' Displays a comprehensive summary of a dashboard project, including metadata,
#' features, pages, visualizations, and integrations.
#'
#' @param x A dashboard_project object created by \code{\link{create_dashboard}}.
#' @param ... Additional arguments (currently ignored).
#'
#' @return Invisibly returns the input object \code{x}.
#'
#' @details
#' The print method displays:
#' \itemize{
#'   \item Project metadata (title, author, description)
#'   \item Output directory
#'   \item Enabled features (sidebar, search, themes, Shiny, Observable)
#'   \item Integrations (GitHub, Twitter, LinkedIn, Analytics)
#'   \item Page structure with properties:
#'     \itemize{
#'       \item 🏠 Landing page indicator
#'       \item ⏳ Loading overlay indicator
#'       \item → Right-aligned navbar indicator
#'       \item 💾 Associated datasets
#'       \item Nested visualization hierarchies
#'     }
#' }
#'
#' @export
print.dashboard_project <- function(x, ...) {
  # Helper function to print page badges
  .print_page_badges <- function(page) {
    badges <- c()
    if (!is.null(page$is_landing_page) && page$is_landing_page) badges <- c(badges, "🏠 Landing")
    if (!is.null(page$icon)) badges <- c(badges, paste0("🎯 Icon"))
    if (!is.null(page$overlay) && page$overlay) badges <- c(badges, paste0("⏳ Overlay"))
    if (!is.null(page$navbar_align) && page$navbar_align == "right") badges <- c(badges, "→ Right")
    if (!is.null(page$data_path)) {
      num_datasets <- if (is.list(page$data_path)) length(page$data_path) else 1
      badges <- c(badges, paste0("💾 ", num_datasets, " dataset", if (num_datasets > 1) "s" else ""))
    }
    
    if (length(badges) > 0) {
      cat(" [", paste(badges, collapse = ", "), "]", sep = "")
    }
  }
  
  cat("\n")
  cat("╔══════════════════════════════════════════════════════════════════════════\n")
  cat("║ 🎨 DASHBOARD PROJECT\n")
  cat("╠══════════════════════════════════════════════════════════════════════════\n")
  cat("║ 📝 Title: ", x$title, "\n", sep = "")
  
  if (!is.null(x$author)) {
    cat("║ 👤 Author: ", x$author, "\n", sep = "")
  }
  
  if (!is.null(x$description)) {
    cat("║ 📄 Description: ", x$description, "\n", sep = "")
  }
  
  cat("║ 📁 Output: ", .resolve_output_dir(x$output_dir, x$allow_inside_pkg), "\n", sep = "")
  
  # Show key features in a compact grid
  features <- c()
  if (x$sidebar) features <- c(features, "📚 Sidebar")
  if (x$search) features <- c(features, "🔍 Search")
  if (!is.null(x$theme)) features <- c(features, paste0("🎨 Theme: ", x$theme))
  if (!is.null(x$tabset_theme)) features <- c(features, paste0("🗂️  Tabs: ", x$tabset_theme))
  if (x$shiny) features <- c(features, "⚡ Shiny")
  if (x$observable) features <- c(features, "👁️  Observable")
  
  if (length(features) > 0) {
    cat("║\n")
    cat("║ ⚙️  FEATURES:\n")
    for (feat in features) {
      cat("║    • ", feat, "\n", sep = "")
    }
  }
  
  # Show social/analytics
  links <- c()
  if (!is.null(x$github)) links <- c(links, paste0("🔗 GitHub"))
  if (!is.null(x$twitter)) links <- c(links, paste0("🐦 Twitter"))
  if (!is.null(x$linkedin)) links <- c(links, paste0("💼 LinkedIn"))
  if (!is.null(x$google_analytics)) links <- c(links, paste0("📊 Analytics"))
  
  if (length(links) > 0) {
    cat("║\n")
    cat("║ 🌐 INTEGRATIONS: ", paste(links, collapse = ", "), "\n", sep = "")
  }
  
  # Build page structure tree
  cat("║\n")
  cat("║ 📄 PAGES (", length(x$pages), "):\n", sep = "")
  
  if (length(x$pages) == 0) {
    cat("║    (no pages yet)\n")
  } else {
    # Check if there are navbar sections/menus with actual pages
    has_navbar_structure <- FALSE
    if (!is.null(x$navbar_sections) && length(x$navbar_sections) > 0) {
      # Check if any section has pages
      for (sec in x$navbar_sections) {
        if (!is.null(sec$type) && length(sec$type) > 0) {
          if ((sec$type == "sidebar" && length(sec$pages) > 0) ||
              (sec$type == "menu" && length(sec$menu_pages) > 0)) {
            has_navbar_structure <- TRUE
            break
          }
        }
      }
    }
    
    if (has_navbar_structure) {
      # Show pages organized by navbar structure
      pages_in_structure <- c()
      
      for (i in seq_along(x$navbar_sections)) {
        section <- x$navbar_sections[[i]]
        is_last_section <- (i == length(x$navbar_sections))
        
        # Skip if section type is missing
        if (is.null(section$type) || length(section$type) == 0) {
          next
        }
        
        if (section$type == "sidebar") {
          # Sidebar group - find the actual sidebar group by ID
          cat("║ ", if (is_last_section) "└─" else "├─", " 📚 ", section$text, " (Sidebar)\n", sep = "")
          section_prefix <- paste0("║ ", if (is_last_section) "   " else "│  ")
          
          # Find the sidebar group with matching ID
          sidebar_group <- NULL
          if (!is.null(x$sidebar_groups)) {
            for (sg in x$sidebar_groups) {
              if (!is.null(sg$id) && sg$id == section$sidebar) {
                sidebar_group <- sg
                break
              }
            }
          }
          
          # Display pages if sidebar group found
          if (!is.null(sidebar_group) && !is.null(sidebar_group$pages)) {
            for (j in seq_along(sidebar_group$pages)) {
              page_name <- sidebar_group$pages[j]
              pages_in_structure <- c(pages_in_structure, page_name)
              page <- x$pages[[page_name]]
              is_last_page <- (j == length(sidebar_group$pages))
              
              cat(section_prefix, if (is_last_page) "└─" else "├─", " 📄 ", page_name, sep = "")
              .print_page_badges(page)
              cat("\n")
            }
          }
        } else if (section$type == "menu") {
          # Dropdown menu
          cat("║ ", if (is_last_section) "└─" else "├─", " 📑 ", section$text, " (Menu)\n", sep = "")
          section_prefix <- paste0("║ ", if (is_last_section) "   " else "│  ")
          
          for (j in seq_along(section$menu_pages)) {
            page_name <- section$menu_pages[j]
            pages_in_structure <- c(pages_in_structure, page_name)
            page <- x$pages[[page_name]]
            is_last_page <- (j == length(section$menu_pages))
            
            cat(section_prefix, if (is_last_page) "└─" else "├─", " 📄 ", page_name, sep = "")
            .print_page_badges(page)
            cat("\n")
          }
        }
      }
      
      # Show any pages NOT in navbar structure
      all_page_names <- names(x$pages)
      pages_not_in_structure <- setdiff(all_page_names, pages_in_structure)
      
      if (length(pages_not_in_structure) > 0) {
        for (i in seq_along(pages_not_in_structure)) {
          page_name <- pages_not_in_structure[i]
          page <- x$pages[[page_name]]
          is_last <- (i == length(pages_not_in_structure)) && length(x$navbar_sections) == 0
          
          cat("║ ", if (is_last) "└─" else "├─", " 📄 ", page_name, sep = "")
          .print_page_badges(page)
          cat("\n")
        }
      }
    } else {
      # Flat list of pages (no navbar structure)
      page_names <- names(x$pages)
      
      for (i in seq_along(page_names)) {
        page_name <- page_names[i]
        page <- x$pages[[page_name]]
        is_last_page <- (i == length(page_names))
      
        # Page branch
        if (is_last_page) {
          cat("║ └─ 📄 ", page_name, sep = "")
          page_prefix <- "║    "
        } else {
          cat("║ ├─ 📄 ", page_name, sep = "")
          page_prefix <- "║ │  "
        }
        
        # Page badges
        .print_page_badges(page)
        cat("\n")
      
      # Show visualizations
      viz_list <- page$visualizations %||% list()
      if (length(viz_list) > 0) {
        # Build tree for this page's visualizations
        viz_tree <- list()
        for (v in viz_list) {
          if (identical(v$type, "tabgroup")) {
            # Skip tabgroup wrappers, we'll show the actual viz hierarchy
            next
          }
          
          path <- if (is.null(v$tabgroup)) {
            c("(root)")
          } else if (is.character(v$tabgroup)) {
            v$tabgroup
          } else {
            c("(root)")
          }
          
          # Navigate to correct position
          current <- viz_tree
          for (j in seq_along(path)) {
            level_name <- path[j]
            if (is.null(current[[level_name]])) {
              current[[level_name]] <- list(.items = list(), .children = list())
            }
            if (j == length(path)) {
              current[[level_name]]$.items[[length(current[[level_name]]$.items) + 1]] <- v
            } else {
              current <- current[[level_name]]$.children
            }
          }
        }
        
        # Print visualization tree for this page
        .print_page_viz_tree <- function(node, prefix) {
          if (length(node) == 0) return()
          
          node_names <- setdiff(names(node), c(".items", ".children"))
          
          for (k in seq_along(node_names)) {
            name <- node_names[k]
            is_last <- (k == length(node_names))
            
            # Only show tabgroup folders if not root
            if (name != "(root)") {
              if (is_last) {
                cat(prefix, "└─ 📁 ", name, "\n", sep = "")
                new_prefix <- paste0(prefix, "   ")
              } else {
                cat(prefix, "├─ 📁 ", name, "\n", sep = "")
                new_prefix <- paste0(prefix, "│  ")
              }
            } else {
              new_prefix <- prefix
            }
            
            # Print items
            items <- node[[name]]$.items
            children <- node[[name]]$.children
            has_children <- length(children) > 0
            
            if (length(items) > 0) {
              for (m in seq_along(items)) {
                v <- items[[m]]
                is_last_item <- (m == length(items)) && !has_children
                
                type_icon <- switch(v$type,
                  "timeline" = "📈",
                  "stackedbar" = "📊",
                  "stackedbars" = "📊",
                  "heatmap" = "🗺️",
                  "histogram" = "📉",
                  "bar" = "📊",
                  "📊"
                )
                
                type_label <- v$type
                title_text <- if (!is.null(v$title)) paste0(": ", substr(v$title, 1, 40)) else ""
                if (!is.null(v$title) && nchar(v$title) > 40) title_text <- paste0(title_text, "...")
                
                if (is_last_item) {
                  cat(new_prefix, "└─ ", type_icon, " ", type_label, title_text, "\n", sep = "")
                } else {
                  cat(new_prefix, "├─ ", type_icon, " ", type_label, title_text, "\n", sep = "")
                }
              }
            }
            
            # Recursively print children
            if (has_children) {
              .print_page_viz_tree(children, new_prefix)
            }
          }
        }
        
        .print_page_viz_tree(viz_tree, page_prefix)
        }
      }
    }
  }
  
  cat("╚══════════════════════════════════════════════════════════════════════════\n\n")
  invisible(x)
}

#' Print Visualization Collection
#'
#' Displays a formatted summary of a visualization collection, including hierarchical
#' tabgroup structure, visualization types, titles, filters, and defaults.
#'
#' @param x A viz_collection object created by \code{\link{create_viz}}.
#' @param ... Additional arguments (currently ignored).
#'
#' @return Invisibly returns the input object \code{x}.
#'
#' @details
#' The print method displays:
#' \itemize{
#'   \item Total number of visualizations
#'   \item Default parameters (if set)
#'   \item Hierarchical tree structure showing tabgroup organization
#'   \item Visualization types with emoji indicators
#'   \item Filter status for each visualization
#' }
#'
#' @export
print.viz_collection <- function(x, ...) {
  total <- length(x$visualizations)
  cat("\n")
  cat("╔══════════════════════════════════════════════════════════════════════════\n")
  cat("║ 📊 VISUALIZATION COLLECTION\n")
  cat("╠══════════════════════════════════════════════════════════════════════════\n")
  cat("║ Total visualizations: ", total, "\n", sep = "")
  
  if (total == 0) {
    cat("║ (empty collection)\n")
    cat("╚══════════════════════════════════════════════════════════════════════════\n\n")
    return(invisible(x))
  }

  # Build hierarchical tree structure
  tree <- list()
  for (i in seq_along(x$visualizations)) {
    v <- x$visualizations[[i]]
    path <- if (is.null(v$tabgroup)) {
      c("(no tabgroup)")
    } else if (is.character(v$tabgroup) && length(v$tabgroup) > 0) {
      v$tabgroup
    } else {
      c("(no tabgroup)")
    }
    
    # Build path string for direct access
    if (length(path) == 1) {
      # Single level
      level_name <- path[1]
      if (is.null(tree[[level_name]])) {
        tree[[level_name]] <- list(.items = list(), .children = list())
      }
      tree[[level_name]]$.items[[length(tree[[level_name]]$.items) + 1]] <- v
    } else {
      # Multiple levels - build nested structure
      # First ensure all intermediate levels exist
      for (j in seq_len(length(path) - 1)) {
        level_path <- path[1:j]
        
        # Navigate to this level and ensure it exists
        if (j == 1) {
          if (is.null(tree[[level_path[1]]])) {
            tree[[level_path[1]]] <- list(.items = list(), .children = list())
          }
        } else {
          # Build nested access
          current <- tree[[level_path[1]]]$.children
          for (k in 2:(j-1)) {
            current <- current[[level_path[k]]]$.children
          }
          if (is.null(current[[level_path[j]]])) {
            current[[level_path[j]]] <- list(.items = list(), .children = list())
          }
        }
      }
      
      # Now add the item at the final level
      if (length(path) == 2) {
        # Two levels: tree[[path[1]]]$.children[[path[2]]]
        if (is.null(tree[[path[1]]]$.children[[path[2]]])) {
          tree[[path[1]]]$.children[[path[2]]] <- list(.items = list(), .children = list())
        }
        tree[[path[1]]]$.children[[path[2]]]$.items[[
          length(tree[[path[1]]]$.children[[path[2]]]$.items) + 1
        ]] <- v
      } else if (length(path) == 3) {
        # Three levels
        if (is.null(tree[[path[1]]]$.children[[path[2]]]$.children[[path[3]]])) {
          tree[[path[1]]]$.children[[path[2]]]$.children[[path[3]]] <- list(.items = list(), .children = list())
        }
        tree[[path[1]]]$.children[[path[2]]]$.children[[path[3]]]$.items[[
          length(tree[[path[1]]]$.children[[path[2]]]$.children[[path[3]]]$.items) + 1
        ]] <- v
      } else {
        # More than 3 levels - iterate (rare case)
        eval_str <- paste0("tree[[\"", path[1], "\"]]")
        for (j in 2:length(path)) {
          eval_str <- paste0(eval_str, "$.children[[\"", path[j], "\"]]")
        }
        eval_str_items <- paste0(eval_str, "$.items")
        
        # Ensure path exists
        if (is.null(eval(parse(text = eval_str)))) {
          assign_str <- paste0(eval_str, " <- list(.items = list(), .children = list())")
          eval(parse(text = assign_str))
        }
        
        # Add item
        current_items <- eval(parse(text = eval_str_items))
        current_items[[length(current_items) + 1]] <- v
        assign_str <- paste0(eval_str_items, " <- current_items")
        eval(parse(text = assign_str))
      }
    }
  }
  
  # Print tree recursively
  .print_tree_level <- function(node, prefix = "║ ", is_last_sibling = TRUE, parent_prefix = "║ ") {
    if (length(node) == 0) return()
    
    node_names <- setdiff(names(node), c(".items", ".children"))
    
    for (i in seq_along(node_names)) {
      name <- node_names[i]
      is_last <- (i == length(node_names))
      
      # Draw branch
      if (is_last) {
        cat(prefix, "└─ 📁 ", name, "\n", sep = "")
        new_prefix <- paste0(prefix, "   ")
      } else {
        cat(prefix, "├─ 📁 ", name, "\n", sep = "")
        new_prefix <- paste0(prefix, "│  ")
      }
      
      # Print items at this level
      items <- node[[name]]$.items
      children <- node[[name]]$.children
      
      has_children <- length(children) > 0
      
      if (length(items) > 0) {
        for (j in seq_along(items)) {
          v <- items[[j]]
          is_last_item <- (j == length(items)) && !has_children
          
          # Get visualization details
          type_icon <- switch(v$type,
            "timeline" = "📈",
            "stackedbar" = "📊",
            "stackedbars" = "📊",
            "heatmap" = "🗺️",
            "histogram" = "📉",
            "bar" = "📊",
            "📊"
          )
          
          type_label <- toupper(v$type)
          title_text <- if (!is.null(v$title)) paste0(": ", v$title) else ""
          filter_text <- if (!is.null(v$filter)) " [filtered]" else ""
          
          if (is_last_item) {
            cat(new_prefix, "└─ ", type_icon, " ", type_label, title_text, filter_text, "\n", sep = "")
          } else {
            cat(new_prefix, "├─ ", type_icon, " ", type_label, title_text, filter_text, "\n", sep = "")
          }
        }
      }
      
      # Recursively print children
      if (has_children) {
        .print_tree_level(children, new_prefix, TRUE, new_prefix)
      }
    }
  }
  
  cat("║\n")
  cat("║ STRUCTURE:\n")
  .print_tree_level(tree, "║ ")
  
  cat("╚══════════════════════════════════════════════════════════════════════════\n\n")
  invisible(x)
}

# ===================================================================
# Hybrid Navigation Helper Functions
# ===================================================================

#' Create a sidebar group for hybrid navigation
#'
#' Helper function to create a sidebar group configuration for use with
#' hybrid navigation. Each group can have its own styling and contains
#' a list of pages.
#'
#' @param id Unique identifier for the sidebar group
#' @param title Display title for the sidebar group
#' @param pages Character vector of page names to include in this group
#' @param style Sidebar style (docked, floating, etc.) (optional)
#' @param background Background color (optional)
#' @param foreground Foreground color (optional)
#' @param border Show border (optional)
#' @param alignment Alignment (left, right) (optional)
#' @param collapse_level Collapse level for navigation (optional)
#' @param pinned Whether sidebar is pinned (optional)
#' @param tools List of tools to add to sidebar (optional)
#' @return List containing sidebar group configuration
#' @export
#' @examples
#' \dontrun{
#' # Create a sidebar group for analysis pages
#' analysis_group <- sidebar_group(
#'   id = "analysis",
#'   title = "Data Analysis",
#'   pages = c("overview", "demographics", "findings"),
#'   style = "docked",
#'   background = "light"
#' )
#' }
sidebar_group <- function(id, title, pages, style = NULL, background = NULL,
                         foreground = NULL, border = NULL, alignment = NULL,
                         collapse_level = NULL, pinned = NULL, tools = NULL) {

  # Validate required parameters
  if (is.null(id) || !is.character(id) || length(id) != 1 || nchar(id) == 0) {
    stop("id must be a non-empty character string")
  }
  if (is.null(title) || !is.character(title) || length(title) != 1 || nchar(title) == 0) {
    stop("title must be a non-empty character string")
  }
  if (is.null(pages) || !is.character(pages) || length(pages) == 0) {
    stop("pages must be a non-empty character vector")
  }

  # Build the sidebar group configuration
  group <- list(
    id = id,
    title = title,
    pages = pages
  )

  # Add optional styling parameters
  if (!is.null(style)) group$style <- style
  if (!is.null(background)) group$background <- background
  if (!is.null(foreground)) group$foreground <- foreground
  if (!is.null(border)) group$border <- border
  if (!is.null(alignment)) group$alignment <- alignment
  if (!is.null(collapse_level)) group$collapse_level <- collapse_level
  if (!is.null(pinned)) group$pinned <- pinned
  if (!is.null(tools)) group$tools <- tools

  group
}

#' Create a navbar section for hybrid navigation
#'
#' Helper function to create a navbar section that links to a sidebar group
#' for hybrid navigation. This creates dropdown-style navigation.
#'
#' @param text Display text for the navbar item
#' @param sidebar_id ID of the sidebar group to link to
#' @param icon Optional icon for the navbar item
#' @return List containing navbar section configuration
#' @export
#' @examples
#' \dontrun{
#' # Create navbar sections that link to sidebar groups
#' analysis_section <- navbar_section("Analysis", "analysis", "ph:chart-bar")
#' reference_section <- navbar_section("Reference", "reference", "ph:book")
#' }
navbar_section <- function(text, sidebar_id, icon = NULL) {

  # Validate required parameters
  if (is.null(text) || !is.character(text) || length(text) != 1 || nchar(text) == 0) {
    stop("text must be a non-empty character string")
  }
  if (is.null(sidebar_id) || !is.character(sidebar_id) || length(sidebar_id) != 1 || nchar(sidebar_id) == 0) {
    stop("sidebar_id must be a non-empty character string")
  }

  # Build the navbar section configuration
  section <- list(
    type = "sidebar",
    text = text,
    sidebar = sidebar_id
  )

  # Add icon if provided
  if (!is.null(icon)) {
    section$icon <- icon
  }

  section
}

#' Create a navbar dropdown menu
#'
#' Creates a dropdown menu in the navbar without requiring sidebar groups.
#' This is a simple nested menu structure.
#'
#' @param text Display text for the dropdown menu button
#' @param pages Character vector of page names to include in the dropdown
#' @param icon Optional icon for the menu button
#' @return List containing navbar menu configuration
#' @export
#' @examples
#' \dontrun{
#' # Create a simple dropdown menu
#' dimensions_menu <- navbar_menu(
#'   text = "Dimensions",
#'   pages = c("Strategic Information", "Critical Information"),
#'   icon = "ph:book"
#' )
#' 
#' dashboard <- create_dashboard(
#'   navbar_sections = list(dimensions_menu)
#' )
#' }
navbar_menu <- function(text, pages, icon = NULL) {
  
  # Validate required parameters
  if (is.null(text) || !is.character(text) || length(text) != 1 || nchar(text) == 0) {
    stop("text must be a non-empty character string")
  }
  if (is.null(pages) || !is.character(pages) || length(pages) == 0) {
    stop("pages must be a non-empty character vector")
  }
  
  # Build the navbar menu configuration
  menu <- list(
    type = "menu",
    text = text,
    menu_pages = pages  # Use menu_pages to distinguish from sidebar reference
  )
  
  # Add icon if provided
  if (!is.null(icon)) {
    menu$icon <- icon
  }
  
  menu
}
