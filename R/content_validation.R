# =================================================================
# content_validation
# =================================================================

.validate_show_when <- function(show_when) {
  if (is.null(show_when)) return(invisible(NULL))
  if (!inherits(show_when, "formula")) {
    stop("show_when must be a formula (e.g., ~ time_period == \"Over Time\") or NULL", call. = FALSE)
  }
  if (length(show_when) != 2) {
    stop("show_when formula must have the form ~ condition (one-sided formula)", call. = FALSE)
  }
  invisible(NULL)
}

.normalize_filter_vars <- function(filter_vars) {
  if (is.null(filter_vars)) return(NULL)
  if (is.character(filter_vars)) return(filter_vars)
  if (is.factor(filter_vars)) return(as.character(filter_vars))
  stop("filter_vars must be a character vector or NULL", call. = FALSE)
}
