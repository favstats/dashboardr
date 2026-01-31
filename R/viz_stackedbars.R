#' @title Stacked Bar Charts for Multiple Variables (Legacy)
#' @description
#' \lifecycle{soft-deprecated}
#'
#' This function has been superseded by \code{\link{viz_stackedbar}}, which now

#' supports both single-variable crosstabs and multi-variable comparisons through
#' a unified interface.
#'
#' **Migration:** Replace `viz_stackedbars(data, x_vars = ...)` with
#' `viz_stackedbar(data, x_vars = ...)`. All parameters work the same way.
#'
#' @inheritParams viz_stackedbar
#' @param x_vars Character vector of column names to pivot (the variables to compare).
#' @param x_var_labels Optional character vector of display labels for the variables.
#'   Must be the same length as `x_vars`. If `NULL`, column names are used as labels.
#' @param response_levels Optional character vector of factor levels for the
#'   response categories (e.g. `c("Strongly Disagree", ..., "Strongly Agree")`).
#' @param show_var_tooltip Logical. If `TRUE`, shows custom tooltip with variable labels.
#'
#' @return A `highcharter` stacked bar chart object.
#'
#' @examples
#' # The old way (still works):
#' # viz_stackedbars(data, x_vars = c("q1", "q2", "q3"))
#'
#' # The new preferred way:
#' # viz_stackedbar(data, x_vars = c("q1", "q2", "q3"))
#'
#' @seealso \code{\link{viz_stackedbar}} for the unified function
#'
#' @export
viz_stackedbars <- function(data,
                            x_vars,
                            x_var_labels = NULL,
                            response_levels = NULL,
                            title = NULL,
                            subtitle = NULL,
                            x_label = NULL,
                            y_label = NULL,
                            stack_label = NULL,
                            stacked_type = c("normal", "percent", "counts"),
                            tooltip = NULL,
                            tooltip_prefix = "",
                            tooltip_suffix = "",
                            x_tooltip_suffix = "",
                            color_palette = NULL,
                            stack_order = NULL,
                            x_order = NULL,
                            include_na = FALSE,
                            na_label_x = "(Missing)",
                            na_label_stack = "(Missing)",
                            x_breaks = NULL,
                            x_bin_labels = NULL,
                            x_map_values = NULL,
                            stack_breaks = NULL,
                            stack_bin_labels = NULL,
                            stack_map_values = NULL,
                            show_var_tooltip = TRUE,
                            horizontal = FALSE,
                            weight_var = NULL,
                            data_labels_enabled = TRUE) {


  # Soft deprecation message (only show once per session)
  if (is.null(getOption("dashboardr.stackedbars.warned"))) {
    message(
      "Note: viz_stackedbars() is now part of viz_stackedbar().\n",
      "You can use viz_stackedbar(data, x_vars = ...) for the same functionality.\n",
      "viz_stackedbars() will continue to work but consider updating your code."
    )
    options(dashboardr.stackedbars.warned = TRUE)
  }

  # Convert x_vars to strings (supports both quoted and unquoted)
  x_vars <- .as_var_strings(rlang::enquo(x_vars))
  weight_var_str <- .as_var_string(rlang::enquo(weight_var))

  # Match stacked_type before passing
  stacked_type <- match.arg(stacked_type)

  # Build args list for do.call to properly pass converted strings
  args <- list(
    data = data,
    x_vars = x_vars,
    x_var_labels = x_var_labels,
    response_levels = response_levels,
    show_var_tooltip = show_var_tooltip,
    title = title,
    subtitle = subtitle,
    x_label = x_label,
    y_label = y_label,
    stack_label = stack_label,
    stacked_type = stacked_type,
    tooltip = tooltip,
    tooltip_prefix = tooltip_prefix,
    tooltip_suffix = tooltip_suffix,
    x_tooltip_suffix = x_tooltip_suffix,
    color_palette = color_palette,
    stack_order = stack_order,
    x_order = x_order,
    include_na = include_na,
    na_label_x = na_label_x,
    na_label_stack = na_label_stack,
    x_breaks = x_breaks,
    x_bin_labels = x_bin_labels,
    x_map_values = x_map_values,
    stack_breaks = stack_breaks,
    stack_bin_labels = stack_bin_labels,
    stack_map_values = stack_map_values,
    horizontal = horizontal,
    weight_var = weight_var_str,
    data_labels_enabled = data_labels_enabled
  )

  # Call the unified function using do.call
  do.call(viz_stackedbar, args)
}
