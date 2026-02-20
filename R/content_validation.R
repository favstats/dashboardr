# =================================================================
# Content Validation Helpers
# =================================================================
#
# Validation utilities shared across the content and visualization
# pipelines. These ensure user-supplied parameters (like show_when
# formulas and filter_var vectors) are well-formed before they reach
# the JavaScript runtime.
#
# Called from: page_creation.R, content_collection.R, viz_collection.R
# =================================================================

#' Validate a show_when formula
#'
#' `show_when` controls conditional visibility of content blocks and
#' inputs. It must be a **one-sided R formula** (e.g. `~ topic == "AI"`).
#' The formula body is later translated to a JavaScript expression
#' evaluated by `show_when.js` on the client.
#'
#' @param show_when A formula or NULL.
#' @return Invisible NULL (called for its side-effect of stopping on
#'   invalid input).
#' @keywords internal
.validate_show_when <- function(show_when) {
  if (is.null(show_when)) return(invisible(NULL))
  if (!inherits(show_when, "formula")) {
    stop("show_when must be a formula (e.g., ~ time_period == \"Over Time\") or NULL", call. = FALSE)
  }
  # One-sided formulas have length 2: `~` and the body
  if (length(show_when) != 2) {
    stop("show_when formula must have the form ~ condition (one-sided formula)", call. = FALSE)
  }
  invisible(NULL)
}

#' Normalize filter_vars to a character vector
#'
#' Accepts character vectors, factors (coerced to character), or NULL.
#' Stops with a clear message on unexpected types.
#'
#' @param filter_vars A character vector, factor, or NULL.
#' @return Character vector or NULL.
#' @keywords internal
.normalize_filter_vars <- function(filter_vars) {
  if (is.null(filter_vars)) return(NULL)
  if (is.character(filter_vars)) return(filter_vars)
  if (is.factor(filter_vars)) return(as.character(filter_vars))
  stop("filter_vars must be a character vector or NULL", call. = FALSE)
}
