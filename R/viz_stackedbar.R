# --------------------------------------------------------------------------
# Function: viz_stackedbar (Unified)
# --------------------------------------------------------------------------
#' @export
#' @title Create a Stacked Bar Chart
#'
#' @description
#' A unified function for creating stacked bar charts that supports two modes:
#'
#' **Mode 1: Grouped/Crosstab Mode** (use `x_var` + `stack_var`)
#'
#' Creates a stacked bar chart from long/tidy data where one column provides
#' the x-axis categories and another column provides the stack segments.
#' This is ideal for cross-tabulating responses by demographic groups.
#'
#' **Mode 2: Multi-Variable/Battery Mode** (use `x_vars`)
#'
#' Creates a stacked bar chart from wide data where multiple columns become
#' the x-axis bars, and their values become the stacks. This is ideal for
#' comparing response distributions across multiple survey questions.
#'
#' The function automatically detects which mode to use based on the parameters
#' provided.
#'
#' @param data A data frame containing the survey data.
#' @param x_var String. Name of the column for X-axis categories (Mode 1: Grouped/Crosstab).
#'   Use this together with `stack_var` for crosstab-style charts.
#' @param stack_var String. Name of the column whose values define the stacks.
#'   Required when using `x_var`.
#' @param y_var Optional string. Name of a pre-computed count column. If NULL
#'   (default), the function counts occurrences.
#' @param x_vars Character vector of column names to compare (Mode 2: Multi-Variable/Battery).
#'   Each column becomes a bar on the x-axis, and the values within each column become the stacks.
#'   Use this for comparing multiple survey questions with the same response scale.
#' @param x_var_labels Optional character vector of display labels for the variables.
#'   Must be the same length as `x_vars`. If NULL, column names are used.
#' @param response_levels Optional character vector of factor levels for the
#'   response categories (e.g., `c("Strongly Disagree", ..., "Strongly Agree")`).
#'   This sets the order of the stacks in multi-variable mode.
#' @param show_var_tooltip Logical. If TRUE (default), shows enhanced tooltips
#'   with variable labels in multi-variable mode.
#' @param title Optional string. Main chart title.
#' @param subtitle Optional string. Chart subtitle.
#' @param x_label Optional string. X-axis label. Defaults to empty in crosstab mode
#'   or "Variable" in multi-variable mode.
#' @param y_label Optional string. Y-axis label. Defaults to "Count" or "Percentage".
#' @param stack_label Optional string. Title for the stack legend.
#'   Set to NULL, NA, FALSE, or "" to hide the legend title.
#' @param stacked_type One of "normal", "counts" (both show raw counts), or
#'   "percent" (100% stacked). Defaults to "counts".
#' @param tooltip A tooltip configuration created with \code{\link{tooltip}()},
#'   OR a format string with \{placeholders\}. Available placeholders:
#'   \code{\{category\}}, \code{\{value\}}, \code{\{series\}}, \code{\{percent\}}.
#' @param tooltip_prefix Optional string prepended to tooltip values.
#' @param tooltip_suffix Optional string appended to tooltip values.
#' @param x_tooltip_suffix Optional string appended to x-axis values in tooltips.
#' @param color_palette Optional character vector of colors for the stacks.
#' @param stack_order Optional character vector specifying order of stack levels.
#' @param x_order Optional character vector specifying order of x-axis levels.
#' @param include_na Logical. If TRUE, NA values are shown as explicit categories.
#'   If FALSE (default), rows with NA are excluded.
#' @param na_label_x String. Label for NA values on x-axis. Default "(Missing)".
#' @param na_label_stack String. Label for NA values in stacks. Default "(Missing)".
#' @param x_breaks Optional numeric vector of cut points for binning `x_var`.
#' @param x_bin_labels Optional character vector of labels for `x_breaks` bins.
#' @param x_map_values Optional named list to remap x-axis values for display.
#' @param stack_breaks Optional numeric vector of cut points for binning stack variable.
#' @param stack_bin_labels Optional character vector of labels for `stack_breaks` bins.
#' @param stack_map_values Optional named list to remap stack values for display.
#' @param horizontal Logical. If TRUE, creates horizontal bars. Default FALSE.
#' @param weight_var Optional string. Name of a weight variable for weighted counts.
#' @param data_labels_enabled Logical. If TRUE, show value labels on bars. Default TRUE.
#' @param cross_tab_filter_vars Character vector. Variables for cross-tab filtering
#'   (typically auto-detected from sidebar inputs).
#' @param title_map Named list mapping variable names to custom display titles
#'   for dynamic title updates when filtering by cross-tab variables.
#'
#' @return An interactive `highcharter` bar chart plot object.
#'
#' @examples
#' \dontrun{
#' library(gssr)
#' data(gss_panel20)
#'
#' # MODE 1: Grouped/Crosstab - One variable broken down by another
#'
#' # Example 1: Education by Gender (counts)
#' plot1 <- viz_stackedbar(
#'   data = gss_panel20,
#'   x_var = "degree_1a",
#'   stack_var = "sex_1a",
#'   title = "Educational Attainment by Gender",
#'   x_label = "Highest Degree",
#'   stack_label = "Gender"
#' )
#'
#' # Example 2: Happiness by Education (percentages)
#' plot2 <- viz_stackedbar(
#'   data = gss_panel20,
#'   x_var = "degree_1a",
#'   stack_var = "happy_1a",
#'   title = "Happiness by Education Level",
#'   stacked_type = "percent",
#'   tooltip_suffix = "%"
#' )
#'
#' # MODE 2: Multi-Variable/Battery - Compare multiple questions
#'
#' # Example 3: Compare multiple attitude questions
#' plot3 <- viz_stackedbar(
#'   data = gss_panel20,
#'   x_vars = c("trust_1a", "fair_1a", "helpful_1a"),
#'   x_var_labels = c("Trust Others", "Others Are Fair",
#'     "Others Are Helpful"),
#'   title = "Social Trust Battery",
#'   stacked_type = "percent",
#'   tooltip_suffix = "%"
#' )
#'
#' # Example 4: Single question horizontal (compact display)
#' plot4 <- viz_stackedbar(
#'   data = gss_panel20,
#'   x_vars = "happy_1a",
#'   title = "General Happiness",
#'   stacked_type = "percent",
#'   horizontal = TRUE
#' )
#' }
#'
#' @seealso
#' \code{\link{viz_bar}} for simple (non-stacked) bar charts
#'
#' @details
#' **Choosing the Right Mode:**
#'
#' Use **Mode 1** (`x_var` + `stack_var`) when you want to:
#' - Show how one variable breaks down by another (e.g., education by gender)
#' - Create a cross-tabulation visualization
#' - Your data is already in long/tidy format
#'
#' Use **Mode 2** (`x_vars`) when you want to:
#' - Compare response distributions across multiple survey questions
#' - Visualize a Likert scale battery
#' - Your questions share the same response categories
#' - Your data is in wide format (one column per question)
#'
#' **Data Handling Features:**
#' - Automatically handles `haven_labelled` columns from SPSS/Stata/SAS
#' - Supports value mapping to rename categories for display
#' - Supports binning of continuous variables
#' - Handles missing values explicitly or implicitly
#'
viz_stackedbar <- function(data,
                           # Mode 1 parameters (crosstab)
                           x_var = NULL,
                           y_var = NULL,
                           stack_var = NULL,
                           # Mode 2 parameters (multi-variable)
                           x_vars = NULL,
                           x_var_labels = NULL,
                           response_levels = NULL,
                           show_var_tooltip = TRUE,
                           # Common parameters
                           title = NULL,
                           subtitle = NULL,
                           x_label = NULL,
                           y_label = NULL,
                           stack_label = NULL,
                           stacked_type = c("counts", "percent", "normal"),
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
                           horizontal = FALSE,
                           weight_var = NULL,
                           data_labels_enabled = TRUE,
                           # Cross-tab filtering for sidebar inputs (auto-detected)
                           cross_tab_filter_vars = NULL,
                           title_map = NULL) {

  # Convert variable arguments to strings (supports both quoted and unquoted)
  x_var <- .as_var_string(rlang::enquo(x_var))
  y_var <- .as_var_string(rlang::enquo(y_var))
  stack_var <- .as_var_string(rlang::enquo(stack_var))
  x_vars <- .as_var_strings(rlang::enquo(x_vars))
  weight_var <- .as_var_string(rlang::enquo(weight_var))

  # INPUT VALIDATION
  if (!is.data.frame(data)) {
    stop("Input 'data' must be a data frame.", call. = FALSE)
  }

  stacked_type <- match.arg(stacked_type)

  # Normalize "normal" to "counts" for internal consistency
  if (stacked_type == "normal") {
    stacked_type <- "counts"
  }

  # =========================================================================
  # MODE DETECTION: Determine which mode to use based on parameters

  # =========================================================================
  has_x_var <- !is.null(x_var)
  has_stack_var <- !is.null(stack_var)
  has_x_vars <- !is.null(x_vars) && length(x_vars) > 0

  # Validate parameter combinations and provide helpful error messages
  if (has_x_vars && has_x_var) {
    stop(
      "Cannot use both 'x_var' and 'x_vars' together.\n",
      "- Use 'x_var' + 'stack_var' to show one variable broken down by another (e.g., education by gender)\n",
      "- Use 'x_vars' to compare multiple columns/questions side by side",
      call. = FALSE
    )
  }

  if (has_x_vars && has_stack_var) {
    stop(
      "'stack_var' is not used with 'x_vars'.\n",
      "When using 'x_vars', the values within each column automatically become the stacks.\n",
      "Use 'response_levels' to control the order of stack categories.",
      call. = FALSE
    )
  }

  if (!has_x_vars && !has_x_var) {
    stop(
      "Please specify either:\n",
      "- 'x_var' + 'stack_var' for crosstab charts (one variable by another)\n",
      "- 'x_vars' for comparing multiple columns/questions\n\n",
      "Examples:\n",
      "  viz_stackedbar(data, x_var = \"education\", stack_var = \"gender\")\n",
      "  viz_stackedbar(data, x_vars = c(\"q1\", \"q2\", \"q3\"))",
      call. = FALSE
    )
  }

  if (has_x_var && !has_stack_var) {
    stop(
      "'stack_var' is required when using 'x_var'.\n",
      "- Specify the column that defines the stacked segments.\n\n",
      "Example:\n",
      "  viz_stackedbar(data, x_var = \"education\", stack_var = \"gender\")",
      call. = FALSE
    )
  }

  # =========================================================================
  # MODE 2: Multi-Variable Mode (x_vars provided)
  # =========================================================================
  if (has_x_vars) {
    # Validate x_vars columns exist
    missing_cols <- setdiff(x_vars, names(data))
    if (length(missing_cols) > 0) {
      stop("Column(s) not found in data: ", paste(missing_cols, collapse = ", "), call. = FALSE)
    }

    # Pivot wide -> long
    data_long <- tidyr::pivot_longer(
      data,
      cols = tidyr::all_of(x_vars),
      names_to = "variable",
      values_to = "response"
    )

    # Apply x_var_labels or default to raw names
    # Special case: when there's only one variable and horizontal = TRUE,
    # blank the category label to avoid truncation (use title instead)
    if (length(x_vars) == 1 && horizontal && !is.null(x_var_labels)) {
      data_long$variable <- factor(data_long$variable, levels = x_vars, labels = "")
      axis_categories <- ""
    } else if (is.null(x_var_labels)) {
      data_long$variable <- factor(data_long$variable, levels = x_vars)
      axis_categories <- x_vars
    } else {
      if (length(x_var_labels) != length(x_vars)) {
        stop("`x_var_labels` must be same length as `x_vars`", call. = FALSE)
      }
      data_long$variable <- factor(
        data_long$variable,
        levels = x_vars,
        labels = x_var_labels
      )
      axis_categories <- x_var_labels
    }

    # Enforce response_levels if provided
    if (!is.null(response_levels)) {
      data_long$response <- factor(
        data_long$response,
        levels = response_levels
      )
    }

    # Build the core chart using internal crosstab logic
    hc <- .viz_stackedbar_core(
      data = data_long,
      x_var = "variable",
      stack_var = "response",
      y_var = y_var,
      title = title,
      subtitle = subtitle,
      x_label = if (is.null(x_label)) "Variable" else x_label,
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
      weight_var = weight_var,
      data_labels_enabled = data_labels_enabled
    )

    # Set the xAxis categories explicitly so JS knows them
    hc <- hc %>% highcharter::hc_xAxis(categories = axis_categories)

    # Override with show_var_tooltip if no custom tooltip was provided
    if (show_var_tooltip && is.null(tooltip)) {
      hc$x$hc_opts$tooltip <- list(
        useHTML = TRUE,
        formatter = htmlwidgets::JS("
          function() {
            // pull the variable label from the axis categories array
            var v = this.series.chart.xAxis[0].categories[this.point.x];
            // If category is empty/undefined (single variable case), use chart title instead
            if (!v || v === '') {
              v = this.series.chart.title ? this.series.chart.title.textStr : '';
            }
            // the response (series name)
            var r = this.series.name;
            // format as percentage if percent-stacked, else point.y
            var val = (this.point.percentage !== undefined)
                    ? Highcharts.numberFormat(this.point.percentage,1) + '%'
                    : this.point.y;
            return '<b>' + v + '</b><br/>' +
                   r + ': <b>' + val + '</b>';
          }
        ")
      )
    }

    return(hc)
  }

  # =========================================================================
  # MODE 1: Crosstab Mode (x_var + stack_var provided)
  # =========================================================================
  .viz_stackedbar_core(
    data = data,
    x_var = x_var,
    stack_var = stack_var,
    y_var = y_var,
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
    weight_var = weight_var,
    data_labels_enabled = data_labels_enabled,
    cross_tab_filter_vars = cross_tab_filter_vars,
    title_map = title_map
  )
}


########################################################################
# Internal core function for crosstab-style stacked bar charts
########################################################################

.viz_stackedbar_core <- function(data,
                                  x_var,
                                  stack_var,
                                  y_var = NULL,
                                  title = NULL,
                                  subtitle = NULL,
                                  x_label = NULL,
                                  y_label = NULL,
                                  stack_label = NULL,
                                  stacked_type = "counts",
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
                                  horizontal = FALSE,
                                  weight_var = NULL,
                                  data_labels_enabled = TRUE,
                                  cross_tab_filter_vars = NULL,
                                  title_map = NULL) {

  # Validation for core function (x_var and stack_var are already strings)
  if (!x_var %in% names(data)) {
    stop(paste0("Column '", x_var, "' not found in data."), call. = FALSE)
  }
  if (!stack_var %in% names(data)) {
    stop(paste0("Column '", stack_var, "' not found in data."), call. = FALSE)
  }

  # Create a mutable copy of the data
  plot_data_temp <- tibble::as_tibble(data)

  # DATA HANDLING (BASIC)
  # Handle 'haven_labelled' columns
  if (requireNamespace("haven", quietly = TRUE)) {
    if (inherits(plot_data_temp[[x_var]], "haven_labelled")) {
      plot_data_temp <- plot_data_temp |>
        dplyr::mutate(!!rlang::sym(x_var) := haven::as_factor(!!rlang::sym(x_var), levels = "labels"))
      if (isTRUE(getOption("dashboardr.verbose"))) message(paste0("Note: Column '", x_var, "' was 'haven_labelled' and converted to factor (levels = values)."))
    }
    if (inherits(plot_data_temp[[stack_var]], "haven_labelled")) {
      plot_data_temp <- plot_data_temp |>
        dplyr::mutate(!!rlang::sym(stack_var) := haven::as_factor(!!rlang::sym(stack_var), levels = "labels"))
      if (isTRUE(getOption("dashboardr.verbose"))) message(paste0("Note: Column '", stack_var, "' was 'haven_labelled' and converted to factor (levels = values)."))
    }
  }

  # X VAR VALUE MAPPING
  if (!is.null(x_map_values)) {
    if (!is.list(x_map_values) || is.null(names(x_map_values))) {
      stop("'x_map_values' must be a named list (e.g., list('1'='Male', '2'='Female')).", call. = FALSE)
    }
    if (is.factor(plot_data_temp[[x_var]])) {
      plot_data_temp <- plot_data_temp |>
        dplyr::mutate(!!rlang::sym(x_var) := as.character(!!rlang::sym(x_var)))
    }
    plot_data_temp <- plot_data_temp |>
      dplyr::mutate(!!rlang::sym(x_var) := dplyr::recode(!!rlang::sym(x_var), !!!x_map_values))
    if (!is.null(x_order)) {
      warning("x_order provided with x_map_values. Ensure x_order refers to the *new* mapped labels.", call. = FALSE)
    }
  }

  # STACK VAR VALUE MAPPING
  if (!is.null(stack_map_values)) {
    if (!is.list(stack_map_values) || is.null(names(stack_map_values))) {
      stop("'stack_map_values' must be a named list (e.g., list('1'='Strongly Disagree', '7'='Strongly Agree')).", call. = FALSE)
    }
    if (is.factor(plot_data_temp[[stack_var]])) {
      plot_data_temp <- plot_data_temp |>
        dplyr::mutate(!!rlang::sym(stack_var) := as.character(!!rlang::sym(stack_var)))
    }
    plot_data_temp <- plot_data_temp |>
      dplyr::mutate(!!rlang::sym(stack_var) := dplyr::recode(!!rlang::sym(stack_var), !!!stack_map_values))
    if (!is.null(stack_order)) {
      warning("stack_order provided with stack_map_values. Ensure stack_order refers to the *new* mapped labels.", call. = FALSE)
    }
  }

  # X_VAR BINNING
  x_var_for_plot <- x_var
  if (!is.null(x_breaks)) {
    if (!is.numeric(plot_data_temp[[x_var]])) {
      warning(paste0("'", x_var, "' is not a numeric column. 'x_breaks' will be ignored."), call. = FALSE)
      x_breaks <- NULL
      x_bin_labels <- NULL
    } else {
      if (!is.numeric(x_breaks) || length(x_breaks) < 2) {
        stop("When provided, 'x_breaks' must be a numeric vector with at least two values.", call. = FALSE)
      }
      if (!is.null(x_bin_labels) && length(x_bin_labels) != (length(x_breaks) - 1)) {
        stop("The length of 'x_bin_labels' must be one less than the length of 'x_breaks'.", call. = FALSE)
      }
      plot_data_temp <- plot_data_temp |>
        dplyr::mutate(
          .x_var_binned = cut(
            !!rlang::sym(x_var),
            breaks = x_breaks,
            labels = x_bin_labels,
            include.lowest = TRUE,
            right = FALSE
          )
        )
      x_var_for_plot <- ".x_var_binned"
      if (!is.null(x_order) && (is.null(x_bin_labels) || !all(x_order %in% x_bin_labels))) {
        warning("x_order provided with x_breaks. Ensure x_order refers to the *correct* bin labels (either auto-generated or custom 'x_bin_labels').", call. = FALSE)
      }
    }
  }

  # STACK_VAR BINNING
  stack_var_for_plot <- stack_var
  if (!is.null(stack_breaks)) {
    if (!is.numeric(plot_data_temp[[stack_var]])) {
      warning(paste0("'", stack_var, "' is not a numeric column. 'stack_breaks' will be ignored."), call. = FALSE)
      stack_breaks <- NULL
      stack_bin_labels <- NULL
    } else {
      if (!is.numeric(stack_breaks) || length(stack_breaks) < 2) {
        stop("When provided, 'stack_breaks' must be a numeric vector with at least two values.", call. = FALSE)
      }
      if (!is.null(stack_bin_labels) && length(stack_bin_labels) != (length(stack_breaks) - 1)) {
        stop("The length of 'stack_bin_labels' must be one less than the length of 'stack_breaks'.", call. = FALSE)
      }
      plot_data_temp <- plot_data_temp |>
        dplyr::mutate(
          .stack_var_binned = cut(
            !!rlang::sym(stack_var),
            breaks = stack_breaks,
            labels = stack_bin_labels,
            include.lowest = TRUE,
            right = FALSE
          )
        )
      stack_var_for_plot <- ".stack_var_binned"
      if (!is.null(stack_order) && (is.null(stack_bin_labels) || !all(stack_order %in% stack_bin_labels))) {
        warning("stack_order provided with stack_breaks. Ensure stack_order refers to the *correct* bin labels (either auto-generated or custom 'stack_bin_labels').", call. = FALSE)
      }
    }
  }

  # FILTER OUT NAs if include_na = FALSE
  if (!include_na) {
    plot_data_temp <- plot_data_temp |>
      dplyr::filter(
        !is.na(!!rlang::sym(x_var_for_plot)) &
          !is.na(!!rlang::sym(stack_var_for_plot))
      )
  }

  # CREATE FACTORS using helper function
  plot_data <- plot_data_temp |>
    dplyr::mutate(
      .x_var_col = handle_na_for_plotting(
        data = plot_data_temp,
        var_name = x_var_for_plot,
        include_na = include_na,
        na_label = na_label_x,
        custom_order = x_order
      ),
      .stack_var_col = handle_na_for_plotting(
        data = plot_data_temp,
        var_name = stack_var_for_plot,
        include_na = include_na,
        na_label = na_label_stack,
        custom_order = stack_order
      )
    )

  # AGGREGATION
  if (is.null(y_var)) {
    if (!is.null(weight_var)) {
      if (!weight_var %in% names(plot_data)) {
        stop("`weight_var` '", weight_var, "' not found in data.", call. = FALSE)
      }
      plot_data <- plot_data |>
        dplyr::count(.x_var_col, .stack_var_col, wt = !!rlang::sym(weight_var), name = "n") |>
        dplyr::mutate(n = round(n, 0))
    } else {
      plot_data <- plot_data |>
        dplyr::count(.x_var_col, .stack_var_col, name = "n")
    }
  } else {
    # When y_var is provided (pre-aggregated counts), aggregate by summing
    # across x/stack groups.  This is essential when extra columns exist
    # (e.g. cross_tab_filter_vars like dimension, question, time_period)
    # because the data may contain multiple rows per x/stack combination.
    plot_data <- plot_data |>
      dplyr::group_by(.x_var_col, .stack_var_col) |>
      dplyr::summarise(n = sum(!!rlang::sym(y_var), na.rm = TRUE), .groups = "drop")
  }

  # HIGHCHARTER
  chart_type <- if (horizontal) "bar" else "column"

  hchart_obj <- highcharter::hchart(
    object = plot_data,
    type = chart_type,
    highcharter::hcaes(x = .x_var_col, y = n, group = .stack_var_col)
  )

  # Titles and subtitles
  if (!is.null(title)) {
    hchart_obj <- highcharter::hc_title(hchart_obj, text = title)
  }
  if (!is.null(subtitle)) {
    hchart_obj <- highcharter::hc_subtitle(hchart_obj, text = subtitle)
  }

  # Axes labels
  final_x_label <- x_label
  if (is.null(final_x_label)) {
    final_x_label <- ""
  }

  final_y_label <- y_label
  if (is.null(final_y_label)) {
    if (stacked_type == "percent") {
      final_y_label <- "Percentage"
    } else {
      final_y_label <- "Count"
    }
  }

  x_categories <- levels(plot_data$.x_var_col)
  hchart_obj <- highcharter::hc_xAxis(hchart_obj,
                                       title = list(text = final_x_label),
                                       categories = x_categories)
  hchart_obj <- highcharter::hc_yAxis(hchart_obj, title = list(text = final_y_label))

  # Stacking and data labels
  data_label_format <- if (stacked_type == "percent") '{point.percentage:.1f}%' else '{point.y:.0f}'
  stacking_type_hc <- if (stacked_type == "percent") "percent" else "normal"

  series_type <- if (horizontal) "bar" else "column"

  plot_options <- list()
  plot_options[[series_type]] <- list(
    stacking = stacking_type_hc,
    dataLabels = list(
      enabled = data_labels_enabled,
      format = data_label_format,
      style = list(textOutline = "none", fontSize = "10px")
    )
  )

  hchart_obj <- do.call(highcharter::hc_plotOptions, c(list(hchart_obj), plot_options))

  # Legend
  if (is.null(stack_label) || (length(stack_label) == 1 && (is.na(stack_label) || isFALSE(stack_label) || stack_label == ""))) {
    hchart_obj <- highcharter::hc_legend(hchart_obj, title = list(text = NULL))
  } else {
    hchart_obj <- highcharter::hc_legend(hchart_obj, title = list(text = stack_label))
  }

  if (horizontal) {
    hchart_obj <- highcharter::hc_legend(hchart_obj, reversed = TRUE)
  }

  # TOOLTIP
  if (!is.null(tooltip)) {
    tooltip_result <- .process_tooltip_config(
      tooltip = tooltip,
      tooltip_prefix = tooltip_prefix,
      tooltip_suffix = tooltip_suffix,
      x_tooltip_suffix = x_tooltip_suffix,
      chart_type = "stackedbar",
      context = list(
        stacked_type = stacked_type,
        x_label = x_label %||% x_var,
        y_label = y_label %||% if (stacked_type == "percent") "Percentage" else "Count"
      )
    )
    hchart_obj <- .apply_tooltip_to_hc(hchart_obj, tooltip_result)
  } else {
    tooltip_prefix_js <- if (is.null(tooltip_prefix) || tooltip_prefix == "") "" else tooltip_prefix
    tooltip_suffix_js <- if (is.null(tooltip_suffix) || tooltip_suffix == "") "" else tooltip_suffix
    x_tooltip_suffix_js <- if (is.null(x_tooltip_suffix) || x_tooltip_suffix == "") "" else x_tooltip_suffix

    hchart_obj <- highcharter::hc_tooltip(
      hchart_obj,
      formatter = highcharter::JS(
        paste0(
          "function() {
          var value = ", if (stacked_type == "percent") "this.percentage.toFixed(1)" else "this.y", ";
          var categoryLabel = this.point.category || this.series.chart.xAxis[0].categories[this.point.x] || this.x;
          return '<b>' + categoryLabel + '", x_tooltip_suffix_js, "</b><br/>' +
                 this.series.name + ': ", tooltip_prefix_js, "' + value + '", tooltip_suffix_js, "<br/>' +
                 'Total: ' + ", if (stacked_type == "percent") "100" else "this.point.stackTotal", ";
        }"
        )
      )
    )
  }

  # Colors: named vector = per-series color map; unnamed = positional cycle
  if (!is.null(color_palette)) {
    if (!is.null(names(color_palette))) {
      # Named: resolve to positional order matching stack levels
      stack_levels <- levels(plot_data$.stack_var_col)
      resolved_colors <- vapply(stack_levels, function(lv) {
        if (lv %in% names(color_palette)) color_palette[[lv]] else NA_character_
      }, character(1))
      resolved_colors <- resolved_colors[!is.na(resolved_colors)]
      if (length(resolved_colors) > 0) {
        hchart_obj <- highcharter::hc_colors(hchart_obj, colors = unname(resolved_colors))
      }
    } else {
      hchart_obj <- highcharter::hc_colors(hchart_obj, colors = color_palette)
    }
  }
  
  # Generate cross-tab for client-side filtering if filter_vars are provided
  if (!is.null(cross_tab_filter_vars) && length(cross_tab_filter_vars) > 0) {
    # Filter to valid columns that exist in data
    valid_filter_vars <- cross_tab_filter_vars[cross_tab_filter_vars %in% names(data)]
    
    if (length(valid_filter_vars) > 0) {
      # Compute cross-tab including filter variables
      # Use sum(y_var) when data already has a count/value column; fall back to counting rows
      group_vars <- c(x_var, stack_var, valid_filter_vars)
      if (!is.null(y_var) && y_var %in% names(data) && is.numeric(data[[y_var]])) {
        cross_tab <- data %>%
          dplyr::group_by(dplyr::across(dplyr::all_of(group_vars))) %>%
          dplyr::summarise(n = sum(.data[[y_var]], na.rm = TRUE), .groups = "drop")
      } else {
        cross_tab <- data %>%
          dplyr::count(dplyr::across(dplyr::all_of(group_vars)), name = "n")
      }
      
      # Generate unique chart ID
      chart_id <- paste0("crosstab_", substr(digest::digest(paste(x_var, stack_var, collapse = "_")), 1, 8))
      
      # Chart config for JS
      chart_config <- list(
        chartId = chart_id,
        xVar = x_var,
        stackVar = stack_var,
        filterVars = valid_filter_vars,
        stackedType = stacked_type,
        stackOrder = if (!is.null(stack_order)) stack_order else unique(as.character(cross_tab[[stack_var]])),
        xOrder = if (!is.null(x_order)) x_order else unique(as.character(cross_tab[[x_var]])),
        colorMap = if (!is.null(color_palette) && !is.null(names(color_palette))) as.list(color_palette) else NULL
      )

      # Dynamic title: if title contains {var} placeholders, store the template
      if (!is.null(title) && grepl("\\{\\w+\\}", title)) {
        chart_config$titleTemplate <- title
      }

      # Title map: derived placeholders from named vectors
      if (!is.null(title_map) && is.list(title_map)) {
        tl_js <- lapply(names(title_map), function(nm) {
          list(values = as.list(title_map[[nm]]))
        })
        names(tl_js) <- names(title_map)
        chart_config$titleLookups <- tl_js
      }
      
      # Store cross-tab and config as attributes on the chart
      attr(hchart_obj, "cross_tab_data") <- cross_tab
      attr(hchart_obj, "cross_tab_config") <- chart_config
      attr(hchart_obj, "cross_tab_id") <- chart_id
      
      # Add the chart ID to the Highcharts options so JS can find it
      hchart_obj <- highcharter::hc_chart(hchart_obj, id = chart_id)
    }
  }

  return(hchart_obj)
}
