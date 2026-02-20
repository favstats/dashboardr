# =================================================================
# Non-Standard Evaluation (NSE) Helpers
# =================================================================
#
# dashboardr lets users refer to data columns with bare names (NSE)
# instead of quoted strings. For example:
#
#   add_viz(type = "bar", x_var = age_group)   # bare name
#   add_viz(type = "bar", x_var = "age_group") # quoted string
#
# Both forms are supported because default parameters passed via `...`
# are captured as unevaluated expressions and then selectively
# converted to strings by `.capture_nse_defaults()`.
#
# Two categories of parameters receive NSE treatment:
#
#   1. **var_params** — single column names (e.g. x_var, y_var).
#      Bare symbols are converted to strings: `age` -> "age".
#
#   2. **var_vector_params** — vectors of column names (e.g. x_vars).
#      Calls like `c(q1, q2, q3)` have each element converted
#      individually so both `c(q1, q2)` and `c("q1", "q2")` work.
#
# Called from: viz_collection.R (create_viz and add_viz defaults)
# =================================================================

#' Capture and resolve NSE default parameters from `...`
#'
#' Processes the raw (unevaluated) dot-arguments from a collection
#' constructor and converts column-reference parameters from symbols
#' to strings while evaluating everything else normally.
#'
#' @param dot_args_raw Named list of unevaluated expressions from
#'   `match.call(expand.dots = FALSE)$...`.
#' @param call_env The calling environment, used to `eval()` non-NSE
#'   arguments.
#' @param var_params Character vector of parameter names that accept a
#'   single column name (e.g. `"x_var"`, `"y_var"`).
#' @param var_vector_params Character vector of parameter names that
#'   accept a vector of column names (e.g. `"x_vars"`).
#' @return Named list of evaluated defaults.
#' @keywords internal
.capture_nse_defaults <- function(dot_args_raw,
                                  call_env,
                                  var_params,
                                  var_vector_params = character()) {
  if (is.null(dot_args_raw)) {
    return(list())
  }

  defaults <- lapply(names(dot_args_raw), function(nm) {
    val <- dot_args_raw[[nm]]

    if (nm %in% var_params && is.symbol(val)) {
      # Single column reference: symbol -> string  (e.g. age -> "age")
      as.character(val)
    } else if (nm %in% var_vector_params) {
      # Vector of column names: c(q1, q2) -> c("q1", "q2")
      if (is.call(val) && identical(val[[1]], as.symbol("c"))) {
        vapply(as.list(val)[-1], function(x) {
          if (is.symbol(x)) {
            as.character(x)
          } else if (is.character(x)) {
            x
          } else {
            eval(x, envir = call_env)
          }
        }, character(1))
      } else {
        eval(val, envir = call_env)
      }
    } else {
      # All other parameters: evaluate normally
      eval(val, envir = call_env)
    }
  })

  names(defaults) <- names(dot_args_raw)
  defaults
}

#' Default single-column NSE parameter names for visualizations
#'
#' These parameter names are treated as bare-name column references
#' when passed through `...` in `create_viz()` / `add_viz()`.
#'
#' @return Character vector.
#' @keywords internal
.default_viz_var_params <- function() {
  c(
    "x_var", "y_var", "group_var", "stack_var", "weight_var",
    "time_var", "region_var", "value_var", "color_var", "size_var",
    "join_var", "click_var", "subgroup_var", "from_var", "to_var",
    "low_var", "high_var"
  )
}

#' Default single-column NSE parameter names for pages
#'
#' Subset of `.default_viz_var_params()` relevant at the page level.
#'
#' @return Character vector.
#' @keywords internal
.default_page_var_params <- function() {
  c(
    "x_var", "y_var", "group_var", "stack_var",
    "region_var", "value_var", "color_var", "size_var",
    "join_var", "click_var", "subgroup_var"
  )
}

#' Default multi-column NSE parameter names
#'
#' Parameters that accept `c(col1, col2, ...)` style vectors.
#'
#' @return Character vector.
#' @keywords internal
.default_vector_var_params <- function() {
  c("x_vars", "tooltip_vars")
}
