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

