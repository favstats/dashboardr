# --------------------------------------------------------------------------
# Function: viz_bar
# --------------------------------------------------------------------------
#' @title Create Bar Chart
#' @description
#' Creates horizontal or vertical bar charts showing counts, percentages, or means.
#' Supports simple bars or grouped bars (when `group_var` is provided).
#' Can display error bars (standard deviation, standard error, or confidence intervals)
#' when showing means via `value_var`.
#'
#' @param data A data frame containing the survey data.
#' @param x_var Character string. Name of the categorical variable for the x-axis.
#' @param group_var Optional character string. Name of grouping variable to create separate bars
#'   (e.g., score ranges, categories). Creates grouped/clustered bars.
#' @param value_var Optional character string. Name of a numeric variable to aggregate.
#'   When provided, bars show the mean of this variable per category (instead of counts).
#'   Required for error bars with "sd", "se", or "ci".
#' @param title Optional main title for the chart.
#' @param subtitle Optional subtitle for the chart.
#' @param x_label Optional label for the x-axis. Defaults to `x_var` name.
#' @param y_label Optional label for the y-axis.
#' @param horizontal Logical. If `TRUE`, creates horizontal bars. Defaults to `FALSE`.
#' @param bar_type Character string. Type of bar chart: "count", "percent", or "mean".
#'   Defaults to "count". When `value_var` is provided, automatically switches to "mean".
#' @param color_palette Optional character vector of colors for the bars.
#' @param group_order Optional character vector specifying the order of groups (for `group_var`).
#' @param x_order Optional character vector specifying the order of x categories.
#' @param sort_by_value Logical. If `TRUE`, sort categories by their value (highest on top for horizontal bars).
#' @param sort_desc Logical. If `sort_by_value = TRUE`, sort descending (default) or ascending.
#' @param x_breaks Optional numeric vector for binning continuous x variables.
#' @param x_bin_labels Optional character vector of labels for x bins.
#' @param include_na Logical. Whether to include NA values as a separate category. Defaults to `FALSE`.
#' @param na_label Character string. Label for NA category if `include_na = TRUE`. Defaults to "(Missing)".
#' @param weight_var Optional character string. Name of a weight variable to use for weighted
#'   aggregation. When provided, counts are computed as the sum of weights instead of simple counts.
#' @param error_bars Character string. Type of error bars to display: "none" (default), "sd" 
#'   (standard deviation), "se" (standard error), or "ci" (confidence interval).
#'   Requires `value_var` to be specified.
#' @param ci_level Numeric. Confidence level for confidence intervals. Defaults to 0.95 (95% CI).
#'   Only used when `error_bars = "ci"`.
#' @param error_bar_color Character string. Color for error bars. Defaults to "black".
#' @param error_bar_width Numeric. Width of error bar whiskers as percentage (0-100). Defaults to 50.
#' @param tooltip A tooltip configuration created with \code{\link{tooltip}()}, 
#'   OR a format string with \{placeholders\}. Available placeholders: 
#'   \code{\{category\}}, \code{\{value\}}, \code{\{percent\}}, \code{\{series\}}.
#'   For simple cases, use \code{tooltip_prefix} and \code{tooltip_suffix} instead.
#'   See \code{\link{tooltip}} for full customization options.
#' @param tooltip_prefix Optional string prepended to tooltip values (simple customization).
#' @param tooltip_suffix Optional string appended to tooltip values (simple customization).
#' @param x_tooltip_suffix Optional string appended to x-axis category in tooltips.
#' @param data_labels_enabled Logical. If TRUE, show value labels on bars.
#'   Default TRUE.
#' @param label_decimals Optional integer. Number of decimal places for data labels.
#'   When NULL (default), uses smart defaults: 0 for counts/percent, 1 for means.
#'   Set explicitly to override (e.g., `label_decimals = 2` for two decimal places).
#' @param complete_groups Logical. When TRUE (default), ensures all x_var/group_var
#'   combinations are present in the output, filling missing combinations with 0.
#'   This prevents bar misalignment when some groups have no observations for 
#'   certain categories. Set to FALSE to show only observed combinations.
#'   Only applies when `group_var` is specified.
#' @param y_var Optional character string. Name of a column containing pre-aggregated
#'   counts or values. When provided, skips aggregation and uses these values directly.
#'   Useful when working with already-aggregated data (e.g., Column 1: Group, Column 2: Count).
#'
#' @param backend Rendering backend: "highcharter" (default), "plotly", "echarts4r", or "ggiraph".
#' @return A highcharter plot object.
#'
#' @examples
#' \dontrun{
#' # Simple bar chart showing counts (default)
#' plot1 <- viz_bar(
#'   data = survey_data,
#'   x_var = "category"
#' )
#' plot1
#'
#' # Horizontal bars with percentages
#' plot2 <- viz_bar(
#'   data = survey_data,
#'   x_var = "category",
#'   horizontal = TRUE,
#'   bar_type = "percent"
#' )
#' plot2
#'
#' # Grouped bars
#' plot3 <- viz_bar(
#'   data = survey_data,
#'   x_var = "question",
#'   group_var = "score_range",
#'   color_palette = c("#D2691E", "#4682B4", "#228B22"),
#'   group_order = c("Low (1-9)", "Middle (10-19)", "High (20-29)")
#' )
#' plot3
#' }
#'
#' # Bar chart with means and error bars (95% CI)
#' plot4 <- viz_bar(
#'   data = mtcars,
#'   x_var = "cyl",
#'   value_var = "mpg",
#'   error_bars = "ci",
#'   title = "Mean MPG by Cylinders",
#'   y_label = "Miles per Gallon"
#' )
#' plot4
#'
#' # Grouped means with standard error bars
#' plot5 <- viz_bar(
#'   data = mtcars,
#'   x_var = "cyl",
#'   group_var = "am",
#'   value_var = "mpg",
#'   error_bars = "se",
#'   title = "Mean MPG by Cylinders and Transmission"
#' )
#' plot5
#'
#' @export

viz_bar <- function(data,
                       x_var,
                       group_var = NULL,
                       value_var = NULL,
                       title = NULL,
                       subtitle = NULL,
                       x_label = NULL,
                       y_label = NULL,
                       horizontal = FALSE,
                       bar_type = "count",
                       color_palette = NULL,
                       group_order = NULL,
                       x_order = NULL,
                       sort_by_value = FALSE,
                       sort_desc = TRUE,
                       x_breaks = NULL,
                       x_bin_labels = NULL,
                       include_na = FALSE,
                       na_label = "(Missing)",
                       weight_var = NULL,
                       error_bars = "none",
                       ci_level = 0.95,
                       error_bar_color = "black",
                       error_bar_width = 50,
                       tooltip = NULL,
                       tooltip_prefix = "",
                       tooltip_suffix = "",
                       x_tooltip_suffix = "",
                       data_labels_enabled = TRUE,
                       label_decimals = NULL,
                       complete_groups = TRUE,
                       y_var = NULL,
                       backend = "highcharter") {
  
  # Convert variable arguments to strings (supports both quoted and unquoted)
  x_var <- .as_var_string(rlang::enquo(x_var))
  group_var <- .as_var_string(rlang::enquo(group_var))
  value_var <- .as_var_string(rlang::enquo(value_var))
  weight_var <- .as_var_string(rlang::enquo(weight_var))
  y_var <- .as_var_string(rlang::enquo(y_var))
  
  # Input validation
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  
  if (is.null(x_var)) {
    .stop_with_hint("x_var", example = "viz_bar(data, x_var = \"category\")")
  }

  if (!x_var %in% names(data)) {
    stop(paste0("Column '", x_var, "' not found in data."), call. = FALSE)
  }
  
  if (!is.null(group_var) && !group_var %in% names(data)) {
    stop(paste0("Column '", group_var, "' not found in data."), call. = FALSE)
  }
  
  if (!is.null(value_var) && !value_var %in% names(data)) {
    stop(paste0("Column '", value_var, "' not found in data."), call. = FALSE)
  }
  
  if (!is.null(value_var) && !is.numeric(data[[value_var]])) {
    stop(paste0("'", value_var, "' must be a numeric column for computing means."), call. = FALSE)
  }
  
  if (!is.null(y_var) && !y_var %in% names(data)) {
    stop(paste0("Column '", y_var, "' not found in data."), call. = FALSE)
  }
  
  if (!is.null(y_var) && !is.numeric(data[[y_var]])) {
    stop(paste0("'", y_var, "' must be a numeric column for pre-aggregated values."), call. = FALSE)
  }
  
  # If value_var is provided, automatically switch to mean mode
  if (!is.null(value_var) && bar_type == "count") {
    bar_type <- "mean"
  }
  
  if (!bar_type %in% c("count", "percent", "mean")) {
    stop("`bar_type` must be 'count', 'percent', or 'mean'.", call. = FALSE)
  }
  
  # Validate error_bars parameter
  if (!error_bars %in% c("none", "sd", "se", "ci")) {
    stop("`error_bars` must be 'none', 'sd', 'se', or 'ci'.", call. = FALSE)
  }
  
  # Error bars require value_var for sd/se/ci

  if (error_bars %in% c("sd", "se", "ci") && is.null(value_var)) {
    stop(paste0("`error_bars = '", error_bars, "'` requires `value_var` to be specified."), 
         call. = FALSE)
  }
  
  # Validate ci_level

  if (!is.numeric(ci_level) || ci_level <= 0 || ci_level >= 1) {
    stop("`ci_level` must be a number between 0 and 1 (e.g., 0.95 for 95% CI).", call. = FALSE)
  }
  
  # Select relevant variables
  vars_to_select <- x_var
  if (!is.null(group_var)) vars_to_select <- c(vars_to_select, group_var)
  if (!is.null(value_var)) vars_to_select <- c(vars_to_select, value_var)
  if (!is.null(weight_var)) vars_to_select <- c(vars_to_select, weight_var)
  if (!is.null(y_var)) vars_to_select <- c(vars_to_select, y_var)
  
  plot_data <- data %>%
    dplyr::select(dplyr::all_of(vars_to_select)) %>%
    dplyr::filter(!is.na(!!rlang::sym(x_var)))
  
  if (!is.null(group_var)) {
    plot_data <- plot_data %>% dplyr::filter(!is.na(!!rlang::sym(group_var)))
  }
  
  # Handle haven_labelled variables
  if (requireNamespace("haven", quietly = TRUE)) {
    if (inherits(plot_data[[x_var]], "haven_labelled")) {
      plot_data <- plot_data %>%
        dplyr::mutate(!!rlang::sym(x_var) := haven::as_factor(!!rlang::sym(x_var), levels = "labels"))
    }
    if (!is.null(group_var) && inherits(plot_data[[group_var]], "haven_labelled")) {
      plot_data <- plot_data %>%
        dplyr::mutate(!!rlang::sym(group_var) := haven::as_factor(!!rlang::sym(group_var), levels = "labels"))
    }
  }
  
  # Handle x binning if specified
  x_var_plot <- x_var
  if (!is.null(x_breaks)) {
    if (!is.numeric(plot_data[[x_var]])) {
      warning(paste0("'", x_var, "' is not numeric. Binning ignored."), call. = FALSE)
    } else {
      if (is.null(x_bin_labels)) {
        stop("When `x_breaks` is provided, `x_bin_labels` must also be provided.", call. = FALSE)
      }
      if (length(x_bin_labels) != (length(x_breaks) - 1)) {
        stop("Length of `x_bin_labels` must be `length(x_breaks) - 1`.", call. = FALSE)
      }
      plot_data <- plot_data %>%
        dplyr::mutate(
          .x_binned = cut(!!rlang::sym(x_var),
                          breaks = x_breaks,
                          labels = x_bin_labels,
                          include.lowest = TRUE,
                          right = FALSE)
        )
      x_var_plot <- ".x_binned"
    }
  }
  
  # Handle NA values
  if (include_na) {
    plot_data <- plot_data %>%
      dplyr::mutate(
        !!rlang::sym(x_var_plot) := forcats::fct_explicit_na(!!rlang::sym(x_var_plot), na_level = na_label)
      )
    if (!is.null(group_var)) {
      plot_data <- plot_data %>%
        dplyr::mutate(
          !!rlang::sym(group_var) := forcats::fct_explicit_na(!!rlang::sym(group_var), na_level = na_label)
        )
    }
  }
  
  # Apply custom ordering if specified
  if (!is.null(x_order)) {
    plot_data <- plot_data %>%
      dplyr::mutate(!!rlang::sym(x_var_plot) := factor(!!rlang::sym(x_var_plot), levels = x_order))
  }
  
  if (!is.null(group_var) && !is.null(group_order)) {
    plot_data <- plot_data %>%
      dplyr::mutate(!!rlang::sym(group_var) := factor(!!rlang::sym(group_var), levels = group_order))
  }
  
  # Aggregate data
  # Helper function to compute error metrics
  .compute_error_metrics <- function(df, val_col, error_type, ci_lvl) {
    df %>%
      dplyr::summarize(
        n = dplyr::n(),
        mean_val = mean(!!rlang::sym(val_col), na.rm = TRUE),
        sd_val = stats::sd(!!rlang::sym(val_col), na.rm = TRUE),
        .groups = "drop"
      ) %>%
      dplyr::mutate(
        se_val = .data$sd_val / sqrt(.data$n),
        # t-value for confidence interval
        t_val = stats::qt((1 + ci_lvl) / 2, df = pmax(.data$n - 1, 1)),
        ci_val = .data$t_val * .data$se_val,
        # Compute low/high based on error type
        error_amount = dplyr::case_when(
          error_type == "sd" ~ .data$sd_val,
          error_type == "se" ~ .data$se_val,
          error_type == "ci" ~ .data$ci_val,
          TRUE ~ 0
        ),
        low = .data$mean_val - .data$error_amount,
        high = .data$mean_val + .data$error_amount,
        value = round(.data$mean_val, 2)
      )
  }
  
  if (bar_type == "mean" && !is.null(value_var)) {
    # Mean aggregation with optional error bars
    if (is.null(group_var)) {
      # Simple mean by x_var
      agg_data <- plot_data %>%
        dplyr::filter(!is.na(!!rlang::sym(value_var))) %>%
        dplyr::group_by(!!rlang::sym(x_var_plot)) %>%
        .compute_error_metrics(value_var, error_bars, ci_level)
    } else {
      # Grouped means by x_var and group_var
      agg_data <- plot_data %>%
        dplyr::filter(!is.na(!!rlang::sym(value_var))) %>%
        dplyr::group_by(!!rlang::sym(x_var_plot), !!rlang::sym(group_var)) %>%
        .compute_error_metrics(value_var, error_bars, ci_level)
      
      # Complete all x_var/group_var combinations with zeros to prevent bar misalignment
      if (isTRUE(complete_groups)) {
        agg_data <- agg_data %>%
          tidyr::complete(
            !!rlang::sym(x_var_plot),
            !!rlang::sym(group_var),
            fill = list(n = 0, mean_val = NA_real_, sd_val = NA_real_, 
                        se_val = NA_real_, t_val = NA_real_, ci_val = NA_real_,
                        error_amount = NA_real_, low = NA_real_, high = NA_real_, 
                        value = NA_real_)
          )
      }
    }
  } else if (!is.null(y_var)) {
    # Pre-aggregated data - use y_var directly without aggregation
    agg_data <- plot_data %>%
      dplyr::rename(count = !!rlang::sym(y_var))
    
    if (bar_type == "percent") {
      # Calculate percentage from pre-aggregated values
      if (!is.null(group_var)) {
        agg_data <- agg_data %>%
          dplyr::group_by(!!rlang::sym(x_var_plot)) %>%
          dplyr::mutate(value = round(count / sum(count) * 100, 1)) %>%
          dplyr::ungroup()
      } else {
        agg_data <- agg_data %>%
          dplyr::mutate(value = round(count / sum(count) * 100, 1))
      }
    } else {
      agg_data <- agg_data %>%
        dplyr::mutate(value = count)
    }
  } else if (is.null(group_var)) {
    # Simple bar chart - count by x_var
    if (!is.null(weight_var)) {
      if (!weight_var %in% names(plot_data)) {
        stop("`weight_var` '", weight_var, "' not found in data.", call. = FALSE)
      }
      agg_data <- plot_data %>%
        dplyr::count(!!rlang::sym(x_var_plot), wt = !!rlang::sym(weight_var), name = "count")
    } else {
      agg_data <- plot_data %>%
        dplyr::count(!!rlang::sym(x_var_plot), name = "count")
    }
    
    if (bar_type == "percent") {
      agg_data <- agg_data %>%
        dplyr::mutate(value = round(count / sum(count) * 100, 1))
    } else if (!is.null(weight_var)) {
      # Round weighted counts to whole numbers (weights can produce fractional values)
      agg_data <- agg_data %>%
        dplyr::mutate(value = round(count, 0))
    } else {
      agg_data <- agg_data %>%
        dplyr::mutate(value = count)
    }
  } else {
    # Grouped bar chart - count by x_var and group_var
    if (!is.null(weight_var)) {
      if (!weight_var %in% names(plot_data)) {
        stop("`weight_var` '", weight_var, "' not found in data.", call. = FALSE)
      }
      agg_data <- plot_data %>%
        dplyr::count(!!rlang::sym(x_var_plot), !!rlang::sym(group_var), wt = !!rlang::sym(weight_var), name = "count")
    } else {
      agg_data <- plot_data %>%
        dplyr::count(!!rlang::sym(x_var_plot), !!rlang::sym(group_var), name = "count")
    }
    
    # Complete all x_var/group_var combinations with zeros to prevent bar misalignment
    if (isTRUE(complete_groups)) {
      agg_data <- agg_data %>%
        tidyr::complete(
          !!rlang::sym(x_var_plot),
          !!rlang::sym(group_var),
          fill = list(count = 0)
        )
    }
    
    if (bar_type == "percent") {
      # Calculate percentage within each x_var category
      agg_data <- agg_data %>%
        dplyr::group_by(!!rlang::sym(x_var_plot)) %>%
        dplyr::mutate(value = round(count / sum(count) * 100, 1)) %>%
        dplyr::ungroup()
    } else if (!is.null(weight_var)) {
      # Round weighted counts to whole numbers (weights can produce fractional values)
      agg_data <- agg_data %>%
        dplyr::mutate(value = round(count, 0))
    } else {
      agg_data <- agg_data %>%
        dplyr::mutate(value = count)
    }
  }
  
  # Auto-sort when weight_var is used (unless explicitly disabled)
  if (!is.null(weight_var) && !isTRUE(sort_by_value) && !isFALSE(sort_by_value)) {
    sort_by_value <- TRUE
  }
  
  # Optional sorting by value (highest on top for horizontal bars)
  if (isTRUE(sort_by_value)) {
    if (is.null(group_var)) {
      # Simple case: sort by single series values
      agg_data <- agg_data %>%
        dplyr::arrange(if (sort_desc) dplyr::desc(.data$value) else .data$value) %>%
        dplyr::mutate(!!rlang::sym(x_var_plot) := factor(
          !!rlang::sym(x_var_plot),
          levels = !!rlang::sym(x_var_plot)
        ))
    } else {
      # Grouped bars: sort categories by total value across groups
      cat_order <- agg_data %>%
        dplyr::group_by(.data[[x_var_plot]]) %>%
        dplyr::summarize(total_value = sum(.data$value, na.rm = TRUE), .groups = "drop") %>%
        dplyr::arrange(if (sort_desc) dplyr::desc(.data$total_value) else .data$total_value) %>%
        dplyr::pull(.data[[x_var_plot]])

      agg_data <- agg_data %>%
        dplyr::mutate(
          !!rlang::sym(x_var_plot) := factor(!!rlang::sym(x_var_plot), levels = cat_order)
        )
    }
  }

  # Set up axis labels
  final_x_label <- x_label %||% x_var
  final_y_label <- y_label %||% switch(bar_type,
    "percent" = "Percentage",
    "mean" = paste0("Mean ", value_var),
    "Count"
  )

  # Build config for backend dispatch
  config <- list(
    title = title, subtitle = subtitle,
    x_label = final_x_label, y_label = final_y_label,
    horizontal = horizontal, bar_type = bar_type,
    color_palette = color_palette, group_var = group_var,
    group_order = group_order, x_var_plot = x_var_plot,
    error_bars = error_bars, ci_level = ci_level,
    error_bar_color = error_bar_color, error_bar_width = error_bar_width,
    tooltip = tooltip, tooltip_prefix = tooltip_prefix,
    tooltip_suffix = tooltip_suffix, x_tooltip_suffix = x_tooltip_suffix,
    data_labels_enabled = data_labels_enabled, label_decimals = label_decimals,
    value_var = value_var, weight_var = weight_var
  )

  # Dispatch to backend renderer
  backend <- .normalize_backend(backend)
  backend <- match.arg(backend, c("highcharter", "plotly", "echarts4r", "ggiraph"))
  .assert_backend_supported("bar", backend)
  render_fn <- switch(backend,
    highcharter = .viz_bar_highcharter,
    plotly      = .viz_bar_plotly,
    echarts4r   = .viz_bar_echarts,
    ggiraph     = .viz_bar_ggiraph
  )
  result <- render_fn(agg_data, config)
  result <- .register_chart_widget(result, backend = backend)
  return(result)
}

# --- Highcharter backend (original implementation) ---
#' @keywords internal
.viz_bar_highcharter <- function(agg_data, config) {
  # Unpack config
  title <- config$title; subtitle <- config$subtitle
  final_x_label <- config$x_label; final_y_label <- config$y_label
  horizontal <- config$horizontal; bar_type <- config$bar_type
  color_palette <- config$color_palette; group_var <- config$group_var
  group_order <- config$group_order; x_var_plot <- config$x_var_plot
  error_bars <- config$error_bars; ci_level <- config$ci_level
  error_bar_color <- config$error_bar_color; error_bar_width <- config$error_bar_width
  tooltip <- config$tooltip; tooltip_prefix <- config$tooltip_prefix
  tooltip_suffix <- config$tooltip_suffix; x_tooltip_suffix <- config$x_tooltip_suffix
  data_labels_enabled <- config$data_labels_enabled; label_decimals <- config$label_decimals
  value_var <- config$value_var; weight_var <- config$weight_var

  # Create base chart
  hc <- highcharter::highchart()
  
  if (!is.null(title)) hc <- hc %>% highcharter::hc_title(text = title)
  if (!is.null(subtitle)) hc <- hc %>% highcharter::hc_subtitle(text = subtitle)
  
  # Configure chart type and orientation
  chart_type <- if (horizontal) "bar" else "column"
  hc <- hc %>% highcharter::hc_chart(type = chart_type)
  
  # Get categories respecting factor level order if present
  x_categories <- if (is.factor(agg_data[[x_var_plot]])) {
    levels(agg_data[[x_var_plot]])
  } else {
    as.character(unique(agg_data[[x_var_plot]]))
  }
  
  # Set up axes
  if (horizontal) {
    # For horizontal bars, x-axis is categories (vertical), y-axis is values (horizontal)
    hc <- hc %>%
      highcharter::hc_xAxis(
        categories = x_categories,
        title = list(text = final_x_label)
      ) %>%
      highcharter::hc_yAxis(title = list(text = final_y_label))
  } else {
    # For vertical bars, x-axis is categories (horizontal), y-axis is values (vertical)
    hc <- hc %>%
      highcharter::hc_xAxis(
        categories = x_categories,
        title = list(text = final_x_label)
      ) %>%
      highcharter::hc_yAxis(title = list(text = final_y_label))
  }
  
  # Check if we need error bars
  has_error_bars <- error_bars != "none" && "low" %in% names(agg_data) && "high" %in% names(agg_data)
  
  # Add series
  if (is.null(group_var)) {
    # Simple bars - single series with multiple colors per bar
    # Store both value (for display) and raw value (for tooltips when bar_type = "percent")
    # When bar_type = "percent" and weight_var is used, we need to store the raw dollar amount
    if (bar_type == "percent" && !is.null(weight_var) && "count" %in% names(agg_data)) {
      # For percent bars with weight_var, store raw values (sum of weights = dollar amounts)
      series_data_list <- agg_data %>%
        dplyr::arrange(!!rlang::sym(x_var_plot)) %>%
        dplyr::rowwise() %>%
        dplyr::mutate(
          point_data = list(list(
            y = value,
            rawValue = count  # count is the sum of weights (dollar amounts)
          ))
        ) %>%
        dplyr::pull(point_data)
    } else {
      # For regular bars, just use values
      series_data_list <- agg_data %>%
        dplyr::arrange(!!rlang::sym(x_var_plot)) %>%
        dplyr::pull(value)
    }
    
    hc <- hc %>%
      highcharter::hc_add_series(
        name = final_y_label,
        id = "main_series",
        data = series_data_list,
        showInLegend = FALSE,
        colorByPoint = TRUE  # Enable different colors for each bar
      )
    
    # Add error bars for simple bars (if applicable)
    if (has_error_bars) {
      error_data <- agg_data %>%
        dplyr::arrange(!!rlang::sym(x_var_plot)) %>%
        dplyr::rowwise() %>%
        dplyr::mutate(
          error_point = list(list(low = round(low, 2), high = round(high, 2)))
        ) %>%
        dplyr::pull(error_point)
      
      hc <- hc %>%
        highcharter::hc_add_series(
          type = "errorbar",
          name = paste0(toupper(error_bars), " Error"),
          data = error_data,
          linkedTo = "main_series",
          showInLegend = FALSE,
          enableMouseTracking = TRUE,
          whiskerLength = paste0(error_bar_width, "%"),
          color = error_bar_color,
          stemWidth = 1.5,
          dataLabels = list(enabled = FALSE)
        )
    }
    
    # Apply color palette to individual bars
    if (!is.null(color_palette) && length(color_palette) >= 1) {
      hc <- hc %>%
        highcharter::hc_colors(color_palette)
    }
  } else {
    # Grouped bars - one series per group
    group_levels <- if (!is.null(group_order)) {
      group_order
    } else {
      unique(agg_data[[group_var]])
    }
    
    # Create series IDs for linking error bars
    series_ids <- paste0("series_", seq_along(group_levels))
    
    for (i in seq_along(group_levels)) {
      group_level <- group_levels[i]
      
      series_data <- agg_data %>%
        dplyr::filter(!!rlang::sym(group_var) == group_level) %>%
        dplyr::arrange(!!rlang::sym(x_var_plot)) %>%
        dplyr::pull(value)
      
      hc <- hc %>%
        highcharter::hc_add_series(
          name = as.character(group_level),
          id = series_ids[i],
          data = series_data
        )
    }
    
    # Add error bars for grouped bars (if applicable)
    if (has_error_bars) {
      for (i in seq_along(group_levels)) {
        group_level <- group_levels[i]
        
        error_data <- agg_data %>%
          dplyr::filter(!!rlang::sym(group_var) == group_level) %>%
          dplyr::arrange(!!rlang::sym(x_var_plot)) %>%
          dplyr::rowwise() %>%
          dplyr::mutate(
            error_point = list(list(low = round(low, 2), high = round(high, 2)))
          ) %>%
          dplyr::pull(error_point)
        
        hc <- hc %>%
          highcharter::hc_add_series(
            type = "errorbar",
            name = paste0(as.character(group_level), " ", toupper(error_bars)),
            data = error_data,
            linkedTo = series_ids[i],
            showInLegend = FALSE,
            enableMouseTracking = TRUE,
            whiskerLength = paste0(error_bar_width, "%"),
            color = error_bar_color,
            stemWidth = 1.5,
            dataLabels = list(enabled = FALSE)
          )
      }
    }
    
    # Apply color palette if specified
    if (!is.null(color_palette)) {
      hc <- hc %>% highcharter::hc_colors(color_palette)
    }
  }
  
  # Enable data labels
  # Use appropriate decimal places based on bar_type (or explicit label_decimals)
  if (!is.null(label_decimals)) {
    dec <- as.integer(label_decimals)
    data_label_format <- switch(bar_type,
      "percent" = sprintf("{point.y:.%df}%%", dec),
      sprintf("{point.y:.%df}", dec)
    )
  } else {
    data_label_format <- switch(bar_type,
      "percent" = "{point.y:.0f}%",
      "mean" = "{point.y:.1f}",  # One decimal for means
      "{point.y:.0f}"  # Whole numbers for counts
    )
  }
  
  hc <- hc %>%
    highcharter::hc_plotOptions(
      series = list(
        dataLabels = list(
          enabled = data_labels_enabled,
          format = data_label_format
        )
      )
    )
  
  # \u2500\u2500\u2500 TOOLTIP \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
  # Calculate total for percentage calculation in tooltips
  total_value <- if (bar_type == "percent") {
    100  # For percent type, total is always 100
  } else {
    sum(agg_data$value, na.rm = TRUE)
  }
  
  if (!is.null(tooltip)) {
    # Use new unified tooltip system when custom tooltip is provided
    tooltip_result <- .process_tooltip_config(
      tooltip = tooltip,
      tooltip_prefix = tooltip_prefix,
      tooltip_suffix = tooltip_suffix,
      x_tooltip_suffix = x_tooltip_suffix,
      chart_type = "bar",
      context = list(
        bar_type = bar_type,
        is_grouped = !is.null(group_var),
        total_value = total_value,
        x_label = final_x_label,
        y_label = final_y_label
      )
    )
    hc <- .apply_tooltip_to_hc(hc, tooltip_result)
  } else {
    # Use original working tooltip code
    pre <- if (is.null(tooltip_prefix) || tooltip_prefix == "") "" else tooltip_prefix
    suf <- if (is.null(tooltip_suffix) || tooltip_suffix == "") "" else tooltip_suffix
    xsuf <- if (is.null(x_tooltip_suffix) || x_tooltip_suffix == "") "" else x_tooltip_suffix
    
    # Error bar type label for tooltip
    error_label <- switch(error_bars,
      "sd" = "SD",
      "se" = "SE", 
      "ci" = paste0(round(ci_level * 100), "% CI"),
      ""
    )
    
    if (is.null(group_var)) {
      # Simple bars - single series
      if (bar_type == "percent") {
        tooltip_fn <- sprintf(
          "function() {
             var cat = this.point.category || this.series.chart.xAxis[0].categories[this.point.x] || this.x;
             var pct = this.y.toFixed(1);
             var rawVal = this.point.rawValue || this.point.options.rawValue;
             var tooltipText = '<b>' + cat + '%s</b><br/>';
             if (rawVal !== undefined && rawVal !== null) {
               tooltipText += '%s' + rawVal.toLocaleString('en-US', {maximumFractionDigits: 1}) + '%s<br/>';
               tooltipText += '<span style=\"color:#666;font-size:0.9em\">' + pct + '%% of total</span>';
             } else {
               tooltipText += '%s' + pct + '%%' + '%s';
             }
             return tooltipText;
           }",
          xsuf, pre, suf, pre, suf
        )
      } else if (bar_type == "mean" && has_error_bars) {
        # Mean with error bars - show range in tooltip
        tooltip_fn <- sprintf(
          "function() {
             if (this.series.type === 'errorbar') {
               return '<b>' + this.series.chart.xAxis[0].categories[this.point.x] + '</b><br/>' +
                      '%s: ' + this.point.low.toFixed(2) + ' - ' + this.point.high.toFixed(2);
             }
             var cat = this.point.category || this.series.chart.xAxis[0].categories[this.point.x] || this.x;
             return '<b>' + cat + '%s</b><br/>' +
                    'Mean: %s' + this.y.toFixed(2) + '%s';
           }",
          error_label, xsuf, pre, suf
        )
      } else {
        tooltip_fn <- sprintf(
          "function() {
             var cat = this.point.category || this.series.chart.xAxis[0].categories[this.point.x] || this.x;
             var val = this.y;
             var total = %s;
             var pct = total > 0 ? (val / total * 100).toFixed(1) : 0;
             return '<b>' + cat + '%s</b><br/>' +
                    '%s' + val.toLocaleString() + '%s<br/>' +
                    '<span style=\"color:#666;font-size:0.9em\">' + pct + '%% of total</span>';
           }",
          total_value, xsuf, pre, suf
        )
      }
    } else {
      # Grouped bars - multiple series
      if (bar_type == "mean" && has_error_bars) {
        # Grouped means with error bars
        tooltip_fn <- sprintf(
          "function() {
             if (this.series.type === 'errorbar') {
               var cat = this.series.chart.xAxis[0].categories[this.point.x];
               return '<b>' + cat + '</b><br/>' +
                      '%s: ' + this.point.low.toFixed(2) + ' - ' + this.point.high.toFixed(2);
             }
             var cat = this.point.category || this.series.chart.xAxis[0].categories[this.point.x] || this.x;
             return '<b>' + cat + '%s</b><br/>' +
                    this.series.name + ': %s' + this.y.toFixed(2) + '%s';
           }",
          error_label, xsuf, pre, suf
        )
      } else {
        tooltip_fn <- sprintf(
          "function() {
             var cat = this.point.category || this.series.chart.xAxis[0].categories[this.point.x] || this.x;
             var val = %s;
             return '<b>' + cat + '%s</b><br/>' +
                    this.series.name + ': %s' + val + '%s';
           }",
          if (bar_type == "percent") "this.y.toFixed(1)" else "this.y",
          xsuf, pre, suf
        )
      }
    }
    
    hc <- hc %>% highcharter::hc_tooltip(formatter = highcharter::JS(tooltip_fn), useHTML = TRUE)
  }
  
  return(hc)
}

# --- Plotly backend ---
#' @keywords internal
.viz_bar_plotly <- function(agg_data, config) {
  rlang::check_installed("plotly", reason = "to use backend = 'plotly'")

  x_var_plot <- config$x_var_plot
  group_var <- config$group_var
  horizontal <- config$horizontal
  bar_type <- config$bar_type
  color_palette <- config$color_palette
  group_order <- config$group_order
  title <- config$title
  final_x_label <- config$x_label
  final_y_label <- config$y_label
  data_labels_enabled <- config$data_labels_enabled
  label_decimals <- config$label_decimals
  error_bars <- config$error_bars

  has_error_bars <- error_bars != "none" && "low" %in% names(agg_data) && "high" %in% names(agg_data)

  if (is.null(group_var)) {
    # Simple bars
    x_vals <- agg_data[[x_var_plot]]
    y_vals <- agg_data$value

    if (horizontal) {
      p <- plotly::plot_ly(x = y_vals, y = x_vals, type = "bar", orientation = "h")
    } else {
      p <- plotly::plot_ly(x = x_vals, y = y_vals, type = "bar")
    }

    if (!is.null(color_palette)) {
      p <- plotly::layout(p, colorway = color_palette)
    }

    if (has_error_bars) {
      error_amount <- agg_data$high - agg_data$value
      if (horizontal) {
        p <- plotly::plot_ly(x = y_vals, y = x_vals, type = "bar", orientation = "h",
                             error_x = list(type = "data", array = error_amount, visible = TRUE))
      } else {
        p <- plotly::plot_ly(x = x_vals, y = y_vals, type = "bar",
                             error_y = list(type = "data", array = error_amount, visible = TRUE))
      }
    }
  } else {
    # Grouped bars
    group_levels <- if (!is.null(group_order)) group_order else unique(agg_data[[group_var]])

    p <- plotly::plot_ly()
    for (i in seq_along(group_levels)) {
      grp <- group_levels[i]
      grp_data <- agg_data[agg_data[[group_var]] == grp, ]
      x_vals <- grp_data[[x_var_plot]]
      y_vals <- grp_data$value

      trace_args <- list(
        p = p, x = if (horizontal) y_vals else x_vals,
        y = if (horizontal) x_vals else y_vals,
        type = "bar", name = as.character(grp)
      )
      if (horizontal) trace_args$orientation <- "h"

      if (has_error_bars) {
        err_amount <- grp_data$high - grp_data$value
        if (horizontal) {
          trace_args$error_x <- list(type = "data", array = err_amount, visible = TRUE)
        } else {
          trace_args$error_y <- list(type = "data", array = err_amount, visible = TRUE)
        }
      }

      p <- do.call(plotly::add_trace, trace_args)
    }
    p <- plotly::layout(p, barmode = "group")

    if (!is.null(color_palette)) {
      p <- plotly::layout(p, colorway = color_palette)
    }
  }

  # Labels and title
  layout_args <- list(p = p)
  if (!is.null(title)) layout_args$title <- title
  if (horizontal) {
    layout_args$xaxis <- list(title = final_y_label)
    layout_args$yaxis <- list(title = final_x_label)
  } else {
    layout_args$xaxis <- list(title = final_x_label)
    layout_args$yaxis <- list(title = final_y_label)
  }
  p <- do.call(plotly::layout, layout_args)

  p
}

# --- echarts4r backend ---
#' @keywords internal
.viz_bar_echarts <- function(agg_data, config) {
  rlang::check_installed("echarts4r", reason = "to use backend = 'echarts4r'")

  x_var_plot <- config$x_var_plot
  group_var <- config$group_var
  horizontal <- config$horizontal
  bar_type <- config$bar_type
  color_palette <- config$color_palette
  title <- config$title
  subtitle <- config$subtitle
  final_x_label <- config$x_label
  final_y_label <- config$y_label
  error_bars <- config$error_bars

  has_error_bars <- error_bars != "none" && "low" %in% names(agg_data) && "high" %in% names(agg_data)

  # Ensure x variable is character for echart categories
  agg_data[[x_var_plot]] <- as.character(agg_data[[x_var_plot]])

  if (is.null(group_var)) {
    e <- agg_data |>
      echarts4r::e_charts_(x_var_plot) |>
      echarts4r::e_bar_("value", name = final_y_label)

    if (has_error_bars) {
      e <- e |> echarts4r::e_error_bar_("low", "high")
    }
  } else {
    agg_data[[group_var]] <- as.character(agg_data[[group_var]])
    e <- agg_data |>
      dplyr::group_by(.data[[group_var]]) |>
      echarts4r::e_charts_(x_var_plot) |>
      echarts4r::e_bar_("value")
  }

  if (horizontal) {
    e <- e |> echarts4r::e_flip_coords()
  }

  if (!is.null(title) || !is.null(subtitle)) {
    e <- e |> echarts4r::e_title(text = title %||% "", subtext = subtitle %||% "")
  }

  e <- e |>
    echarts4r::e_x_axis(name = final_x_label) |>
    echarts4r::e_y_axis(name = final_y_label) |>
    echarts4r::e_tooltip(trigger = "axis")

  if (!is.null(color_palette)) {
    e <- e |> echarts4r::e_color(color_palette)
  }

  e
}

# --- ggiraph backend ---
#' @keywords internal
.viz_bar_ggiraph <- function(agg_data, config) {
  rlang::check_installed("ggiraph", reason = "to use backend = 'ggiraph'")
  rlang::check_installed("ggplot2", reason = "to use backend = 'ggiraph'")

  x_var_plot <- config$x_var_plot
  group_var <- config$group_var
  horizontal <- config$horizontal
  bar_type <- config$bar_type
  color_palette <- config$color_palette
  title <- config$title
  subtitle <- config$subtitle
  final_x_label <- config$x_label
  final_y_label <- config$y_label
  error_bars <- config$error_bars

  has_error_bars <- error_bars != "none" && "low" %in% names(agg_data) && "high" %in% names(agg_data)

  # Build tooltip text
  agg_data$.tooltip <- paste0(
    agg_data[[x_var_plot]],
    if (!is.null(group_var)) paste0(" (", agg_data[[group_var]], ")") else "",
    ": ", round(agg_data$value, 2)
  )

  if (is.null(group_var)) {
    p <- ggplot2::ggplot(agg_data, ggplot2::aes(
      x = .data[[x_var_plot]], y = .data$value
    )) +
      ggiraph::geom_bar_interactive(
        ggplot2::aes(tooltip = .data$.tooltip, data_id = .data[[x_var_plot]]),
        stat = "identity"
      )
  } else {
    p <- ggplot2::ggplot(agg_data, ggplot2::aes(
      x = .data[[x_var_plot]], y = .data$value, fill = .data[[group_var]]
    )) +
      ggiraph::geom_bar_interactive(
        ggplot2::aes(tooltip = .data$.tooltip, data_id = .data[[x_var_plot]]),
        stat = "identity", position = "dodge"
      )
  }

  if (has_error_bars) {
    p <- p + ggplot2::geom_errorbar(
      ggplot2::aes(ymin = .data$low, ymax = .data$high),
      width = 0.2,
      position = if (!is.null(group_var)) ggplot2::position_dodge(0.9) else "identity"
    )
  }

  if (!is.null(color_palette)) {
    p <- p + ggplot2::scale_fill_manual(values = color_palette)
  }

  p <- p +
    ggplot2::labs(title = title, subtitle = subtitle,
                  x = final_x_label, y = final_y_label) +
    ggplot2::theme_minimal()

  if (horizontal) {
    p <- p + ggplot2::coord_flip()
  }

  ggiraph::girafe(ggobj = p)
}

