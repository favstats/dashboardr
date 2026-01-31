# =================================================================
# utils_core
# =================================================================

.pkg_root <- function(start = getwd()) {
  cur <- normalizePath(start, winslash = "/", mustWork = TRUE)
  repeat {
    if (file.exists(file.path(cur, "DESCRIPTION"))) return(cur)
    parent <- dirname(cur)
    if (identical(parent, cur)) return(NULL)
    cur <- parent
  }
}

.is_subpath <- function(path, root) {
  path <- normalizePath(path, winslash = "/", mustWork = FALSE)
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  startsWith(paste0(path, "/"), paste0(root, "/"))
}

.resolve_output_dir <- function(output_dir, allow_inside_pkg = FALSE, quiet = FALSE) {
  out_abs <- normalizePath(output_dir, winslash = "/", mustWork = FALSE)
  pkg_root <- .pkg_root()

  if (!allow_inside_pkg && !is.null(pkg_root) && .is_subpath(out_abs, pkg_root)) {
    relocated <- file.path(dirname(pkg_root), basename(out_abs))
    # Only show message if not quiet and in interactive session
    if (!quiet && interactive()) {
      message(
        "Detected package repo at: ", pkg_root, "\n",
        "Writing output outside the package at: ", relocated,
        " (set allow_inside_pkg = TRUE to disable relocation)"
      )
    }
    out_abs <- relocated
  }
  out_abs
}

`%||%` <- function(x, y) if (is.null(x)) y else x

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
      # Note: Curly braces don't need escaping in R strings
      escaped <- gsub('"', '\\"', arg, fixed = TRUE)
      return(paste0('"', escaped, '"'))
    } else {
      # Create c() vector for multiple strings
      escaped_args <- sapply(arg, function(x) {
        escaped <- gsub('"', '\\"', x, fixed = TRUE)
        paste0('"', escaped, '"')
      })
      return(paste0("c(", paste(escaped_args, collapse = ", "), ")"))
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

#' Convert a variable argument to a string (supports both quoted and unquoted syntax)
#'
#' Internal helper that enables tidy evaluation for variable parameters.
#' Accepts both `x_var = "degree"` (quoted) and `x_var = degree` (unquoted).
#'
#' @param var A quosure captured with `rlang::enquo()`
#' @return Character string of the variable name, or NULL if the input was NULL
#' @keywords internal
#' @examples
#' \dontrun{
#' # Inside a function:
#' my_func <- function(x_var) {
#'   x_var <- .as_var_string(rlang::enquo(x_var))
#'   # x_var is now always a character string
#' }
#' 
#' my_func("degree")  # returns "degree"
#' my_func(degree)    # returns "degree"
#' }
.as_var_string <- function(var) {
  # Handle NULL/missing
  if (rlang::quo_is_null(var) || rlang::quo_is_missing(var)) {
    return(NULL)
  }
  
  expr <- rlang::quo_get_expr(var)
  
  # Already a string - return as-is
  if (is.character(expr)) {
    return(expr)
  }
  
  # A symbol - first try to evaluate it (handles internal calls with param = param)
  # If evaluation succeeds, use that value; if fails, convert symbol to string
  if (rlang::is_symbol(expr)) {
    result <- tryCatch(
      rlang::eval_tidy(var),
      error = function(e) NULL
    )
    # If evaluation returned a string, use it
    if (is.character(result)) {
      return(result)
    }
    # If evaluation returned NULL, return NULL (for internal calls with NULL values)
    if (is.null(result)) {
      return(NULL)
    }
    # Otherwise, this is a bare column name - convert symbol to string
    return(rlang::as_string(expr))
  }
  
  # Fallback: evaluate the quosure (handles cases like variables containing strings)
  result <- rlang::eval_tidy(var)
  if (is.character(result)) {
    return(result)
  }
  if (is.null(result)) {
    return(NULL)
  }
  
  # Last resort: deparse the expression
  deparse(expr)
}

#' Convert multiple variable arguments to strings (for x_vars vector)
#'
#' Internal helper for parameters that accept vectors of variable names.
#' Supports `x_vars = c("var1", "var2")` and `x_vars = c(var1, var2)`.
#'
#' @param vars A quosure captured with `rlang::enquo()`
#' @return Character vector of variable names, or NULL if input was NULL
#' @keywords internal
.as_var_strings <- function(vars) {
  if (rlang::quo_is_null(vars) || rlang::quo_is_missing(vars)) {
    return(NULL)
  }
  
  expr <- rlang::quo_get_expr(vars)
  env <- rlang::quo_get_env(vars)
  
  # Already a character vector - return as-is
  if (is.character(expr)) {
    return(expr)
  }
  
  # A single symbol - first try to evaluate it (handles internal calls)
  if (rlang::is_symbol(expr)) {
    result <- tryCatch(
      rlang::eval_tidy(vars),
      error = function(e) NULL
    )
    if (is.character(result)) {
      return(result)
    }
    if (is.null(result)) {
      return(NULL)
    }
    # Bare column name - convert symbol to string
    return(rlang::as_string(expr))
  }
  
  # A c() call - extract each element
  if (rlang::is_call(expr, "c")) {
    args <- rlang::call_args(expr)
    result <- vapply(args, function(arg) {
      if (is.character(arg)) {
        return(arg)
      } else if (rlang::is_symbol(arg)) {
        # Try to evaluate first
        val <- tryCatch(eval(arg, envir = env), error = function(e) NULL)
        if (is.character(val)) return(val)
        return(rlang::as_string(arg))
      } else {
        # Try to evaluate
        val <- eval(arg, envir = env)
        if (is.character(val)) return(val)
        return(deparse(arg))
      }
    }, character(1))
    return(result)
  }
  
  # Fallback: evaluate and hope it's a character vector
  result <- rlang::eval_tidy(vars)
  if (is.character(result)) {
    return(result)
  }
  
  stop("Could not convert variable argument to character string(s)", call. = FALSE)
}

# =================================================================
# Visualization Validation System
# =================================================================

#' Registry of visualization parameter requirements
#' 
#' Internal list defining required and optional parameters for each viz type,
#' along with which parameters represent column names that should be validated.
#' @keywords internal
.viz_param_registry <- list(
  bar = list(
    required = c("x_var"),
    column_params = c("x_var", "group_var", "weight_var"),
    example = 'add_viz(type = "bar", x_var = "category")'
  ),
  scatter = list(
    required = c("x_var", "y_var"),
    column_params = c("x_var", "y_var", "color_var", "size_var"),
    example = 'add_viz(type = "scatter", x_var = "weight", y_var = "mpg")'
  ),
  histogram = list(
    required = c("x_var"),
    column_params = c("x_var", "y_var", "group_var", "weight_var"),
    example = 'add_viz(type = "histogram", x_var = "age")'
  ),

density = list(
    required = c("x_var"),
    column_params = c("x_var", "group_var", "weight_var"),
    example = 'add_viz(type = "density", x_var = "income")'
  ),
  treemap = list(
    required = c("group_var", "value_var"),
    column_params = c("group_var", "subgroup_var", "value_var", "color_var"),
    example = 'add_viz(type = "treemap", group_var = "category", value_var = "count")'
  ),
  boxplot = list(
    required = c("y_var"),
    column_params = c("y_var", "x_var", "weight_var"),
    example = 'add_viz(type = "boxplot", y_var = "score")'
  ),
  stackedbars = list(
    required = c("x_vars"),
    column_params = c("x_vars"),
    example = 'add_viz(type = "stackedbars", x_vars = c("q1", "q2", "q3"))'
  ),
  stackedbar = list(
    required = c("x_var", "stack_var"),
    column_params = c("x_var", "y_var", "stack_var", "weight_var"),
    example = 'add_viz(type = "stackedbar", x_var = "age_group", stack_var = "gender")'
  ),
  map = list(
    required = c("value_var"),
    column_params = c("value_var", "join_var", "click_var"),
    example = 'add_viz(type = "map", value_var = "population", join_var = "country_code")'
  ),
  heatmap = list(
    required = c("x_var", "y_var", "value_var"),
    column_params = c("x_var", "y_var", "value_var"),
    example = 'add_viz(type = "heatmap", x_var = "hour", y_var = "day", value_var = "count")'
  ),
  timeline = list(
    required = c("time_var", "y_var"),
    column_params = c("time_var", "y_var", "group_var"),
    example = 'add_viz(type = "timeline", time_var = "date", y_var = "value")'
  )
)

#' Validate a single visualization specification
#'
#' Internal function that validates a visualization spec against its requirements.
#' Checks for missing required parameters and optionally validates column existence.
#'
#' @param spec List containing the visualization specification
#' @param data Optional data frame to validate column names against
#' @param item_index Optional index of the item in the collection (for error messages)
#' @param stop_on_error If TRUE, stops with an error. If FALSE, returns list of issues.
#' @return If stop_on_error=FALSE, returns a list with `valid` (logical) and `issues` (character vector).
#'         If stop_on_error=TRUE and invalid, throws an error with helpful message.
#' @keywords internal
.validate_viz_spec <- function(spec, data = NULL, item_index = NULL, stop_on_error = TRUE) {
  issues <- character(0)
  

  # Skip non-viz items
  if (is.null(spec$viz_type) && (is.null(spec$type) || spec$type != "viz")) {
    return(list(valid = TRUE, issues = character(0)))
  }
  
  viz_type <- spec$viz_type %||% spec$type
  
  # Check if viz type is known
  if (!viz_type %in% names(.viz_param_registry)) {
    # Unknown viz type - can't validate further, but don't error
    # The actual viz function will handle this
    return(list(valid = TRUE, issues = character(0)))
  }
  
  registry <- .viz_param_registry[[viz_type]]
  
  # Check required parameters
  missing_params <- character(0)
  for (param in registry$required) {
    value <- spec[[param]]
    if (is.null(value) || (is.character(value) && length(value) == 1 && value == "")) {
      missing_params <- c(missing_params, param)
    }
  }
  
  if (length(missing_params) > 0) {
    for (param in missing_params) {
      issues <- c(issues, paste0("'", param, "' parameter is required for viz_", viz_type))
    }
  }
  
  # Validate column existence if data is provided
  if (!is.null(data) && is.data.frame(data)) {
    data_cols <- names(data)
    
    for (param in registry$column_params) {
      col_value <- spec[[param]]
      
      if (!is.null(col_value)) {
        # Handle vector of column names (like x_vars in stackedbars)
        cols_to_check <- if (is.character(col_value)) col_value else character(0)
        
        for (col in cols_to_check) {
          if (!col %in% data_cols) {
            # Try to suggest a similar column name
            suggestion <- .suggest_alternative(col, data_cols)
            issue_msg <- paste0("Column '", col, "' (", param, ") not found in data")
            if (!is.null(suggestion)) {
              issue_msg <- paste0(issue_msg, ". Did you mean '", suggestion, "'?")
            }
            issues <- c(issues, issue_msg)
          }
        }
      }
    }
  }
  
  # If there are issues and we should stop, format a helpful error message
  if (length(issues) > 0 && stop_on_error) {
    # Build informative error message
    item_label <- if (!is.null(item_index)) paste0(" (item ", item_index, ")") else ""
    
    msg <- paste0("\n", cli::symbol$cross, " Validation error in viz_", viz_type, item_label, ":\n")
    
    for (issue in issues) {
      msg <- paste0(msg, "  ", cli::symbol$bullet, " ", issue, "\n")
    }
    
    # Add example
    if (!is.null(registry$example)) {
      msg <- paste0(msg, "\n", cli::symbol$info, " Example: ", registry$example, "\n")
    }
    
    # Show current spec values for debugging
    msg <- paste0(msg, "\n", cli::symbol$info, " Current specification:\n")
    for (param in registry$required) {
      value <- spec[[param]]
      value_str <- if (is.null(value)) "(missing)" else paste0('"', value, '"')
      msg <- paste0(msg, "    ", param, ": ", value_str, "\n")
    }
    
    stop(msg, call. = FALSE)
  }
  
  list(valid = length(issues) == 0, issues = issues)
}

#' Validate all visualization specs in a collection
#'
#' Internal function that validates all viz specs in a content/viz collection.
#' Collects all validation issues and reports them together.
#'
#' @param collection A content_collection or viz_collection object
#' @param data Optional data frame to validate column names against
#' @param stop_on_error If TRUE, stops on first error. If FALSE, collects all issues.
#' @return If stop_on_error=FALSE, returns a list with `valid` (logical), `issues` (list of issues by item).
#'         If stop_on_error=TRUE and invalid, throws an error.
#' @keywords internal
.validate_all_viz_specs <- function(collection, data = NULL, stop_on_error = TRUE) {
  if (is.null(collection$items) || length(collection$items) == 0) {
    return(list(valid = TRUE, issues = list()))
  }
  
  # Use collection data if not provided
  if (is.null(data)) {
    data <- collection$data
  }
  
  all_issues <- list()
  has_errors <- FALSE
  
  for (i in seq_along(collection$items)) {
    item <- collection$items[[i]]
    
    # Only validate viz items
    is_viz <- (!is.null(item$viz_type)) || 
              (!is.null(item$type) && item$type == "viz")
    
    if (is_viz) {
      result <- .validate_viz_spec(item, data = data, item_index = i, stop_on_error = stop_on_error)
      
      if (!result$valid) {
        has_errors <- TRUE
        all_issues[[as.character(i)]] <- list(
          viz_type = item$viz_type %||% item$type,
          issues = result$issues
        )
      }
    }
  }
  
  # If we collected issues without stopping, format a summary error
  if (has_errors && stop_on_error) {
    # This shouldn't happen since stop_on_error=TRUE stops in .validate_viz_spec
    # But just in case, throw an error
    stop("Validation errors found in collection", call. = FALSE)
  }
  
  list(valid = !has_errors, issues = all_issues)
}

# =================================================================
# Page configuration helpers
# =================================================================

#' Convert haven_labelled columns to factors
#' 
#' Internal helper that converts haven_labelled columns to factors for filtering.
#' Used in generated QMD files when data might contain haven-style labels.
#' 
#' @param df A data frame
#' @return The data frame with haven_labelled columns converted to factors
#' @keywords internal
.convert_haven <- function(df) {
  if (requireNamespace("haven", quietly = TRUE)) {
    for (col in names(df)) {
      if (inherits(df[[col]], "haven_labelled")) {
        df[[col]] <- haven::as_factor(df[[col]])
      }
    }
  }
  df
}

#' Generate page configuration HTML
#' 
#' Internal helper that outputs CSS and JavaScript for chart containers and reflow.
#' Called from generated QMD setup chunks.
#' 
#' @return Invisible NULL (outputs HTML via knitr)
#' @keywords internal
.page_config <- function() {
  css <- "
<style>
/* Ensure chart containers expand to fit content */
.cell-output-display,
.cell-output,
.panel-tabset-tabby > .tab-content,
.panel-tabset > .tab-content,
.tab-pane,
.tab-pane.active,
.card-body,
.quarto-figure,
section {
  overflow: visible !important;
  height: auto !important;
  max-height: none !important;
}
.highcharts-container,
.html-widget,
.htmlwidget {
  overflow: visible !important;
}
</style>
<script>
(function() {
  function reflowCharts() {
    if (typeof Highcharts !== 'undefined' && Highcharts.charts) {
      Highcharts.charts.forEach(function(c) { if (c) try { c.reflow(); } catch(e) {} });
    }
  }
  [0, 100, 250, 500, 1000, 2000].forEach(function(d) {
    setTimeout(function() { window.dispatchEvent(new Event('resize')); requestAnimationFrame(reflowCharts); }, d);
  });
  document.addEventListener('click', function(e) {
    if (e.target.matches('.nav-link, [data-bs-toggle=\"tab\"]')) setTimeout(reflowCharts, 50);
  });
})();
</script>
"
  knitr::asis_output(css)
}