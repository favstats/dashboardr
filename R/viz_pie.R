# =================================================================
# Pie & Donut Chart Visualization
# =================================================================

#' Create a Pie or Donut Chart
#'
#' Creates an interactive pie or donut chart using highcharter.
#' Pie charts show proportional data as slices of a circle.
#' Donut charts are pie charts with a hollow center.
#'
#' @param data A data frame containing the data.
#' @param x_var Character string. Name of the categorical variable (slice labels).
#' @param y_var Optional character string. Name of a numeric column with pre-aggregated
#'   values. When provided, skips counting and uses these values directly.
#' @param title Optional main title for the chart.
#' @param subtitle Optional subtitle for the chart.
#' @param inner_size Character string. Size of the inner hole as percentage (e.g., "50%").
#'   Set to "0%" for a standard pie chart (default), or "40%"-"70%" for a donut chart.
#' @param color_palette Optional character vector of colors for the slices.
#' @param x_order Optional character vector specifying the order of slices.
#' @param sort_by_value Logical. If TRUE, sort slices by value (largest first). Default FALSE.
#' @param data_labels_enabled Logical. If TRUE (default), show labels on slices.
#' @param data_labels_format Character string. Format for data labels.
#'   Default shows name and percentage: "\{point.name\}: \{point.percentage:.1f\}%".
#' @param show_in_legend Logical. If TRUE (default), show a legend.
#' @param weight_var Optional character string. Name of a weight variable for weighted counts.
#' @param include_na Logical. Whether to include NA as a category. Default FALSE.
#' @param na_label Character string. Label for the NA category. Default "(Missing)".
#' @param tooltip A tooltip configuration created with \code{\link{tooltip}()},
#'   OR a format string with \{placeholders\}. Available placeholders:
#'   \code{\{name\}}, \code{\{value\}}, \code{\{percent\}}.
#'   See \code{\link{tooltip}} for full customization options.
#' @param tooltip_prefix Optional string prepended to tooltip values.
#' @param tooltip_suffix Optional string appended to tooltip values.
#' @param center_text Optional character string. Text to display in the center of a donut chart.
#'   Only visible when inner_size > "0%".
#'
#' @return A highcharter plot object.
#'
#' @examples
#' \dontrun{
#' # Simple pie chart
#' viz_pie(mtcars, x_var = "cyl", title = "Cars by Cylinders")
#'
#' # Donut chart
#' viz_pie(mtcars, x_var = "cyl", inner_size = "50%", title = "Donut Chart")
#'
#' # Pre-aggregated data
#' df <- data.frame(category = c("A", "B", "C"), count = c(40, 35, 25))
#' viz_pie(df, x_var = "category", y_var = "count")
#' }
#' @export
viz_pie <- function(data,
                    x_var,
                    y_var = NULL,
                    title = NULL,
                    subtitle = NULL,
                    inner_size = "0%",
                    color_palette = NULL,
                    x_order = NULL,
                    sort_by_value = FALSE,
                    data_labels_enabled = TRUE,
                    data_labels_format = "{point.name}: {point.percentage:.1f}%",
                    show_in_legend = TRUE,
                    weight_var = NULL,
                    include_na = FALSE,
                    na_label = "(Missing)",
                    tooltip = NULL,
                    tooltip_prefix = "",
                    tooltip_suffix = "",
                    center_text = NULL) {

  # Convert variable arguments to strings (supports both quoted and unquoted)
  x_var <- .as_var_string(rlang::enquo(x_var))
  y_var <- .as_var_string(rlang::enquo(y_var))
  weight_var <- .as_var_string(rlang::enquo(weight_var))

  # Input validation
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }

  if (is.null(x_var)) {
    .stop_with_hint("x_var", example = 'viz_pie(data, x_var = "category")')
  }

  if (!x_var %in% names(data)) {
    stop(paste0("Column '", x_var, "' not found in data."), call. = FALSE)
  }

  if (!is.null(y_var) && !y_var %in% names(data)) {
    stop(paste0("Column '", y_var, "' not found in data."), call. = FALSE)
  }

  if (!is.null(y_var) && !is.numeric(data[[y_var]])) {
    stop(paste0("'", y_var, "' must be a numeric column."), call. = FALSE)
  }

  # Select relevant variables
  vars_to_select <- x_var
  if (!is.null(y_var)) vars_to_select <- c(vars_to_select, y_var)
  if (!is.null(weight_var)) vars_to_select <- c(vars_to_select, weight_var)

  plot_data <- data %>%
    dplyr::select(dplyr::all_of(vars_to_select))

  # Handle NA values
  if (!include_na) {
    plot_data <- plot_data %>%
      dplyr::filter(!is.na(!!rlang::sym(x_var)))
  } else {
    plot_data <- plot_data %>%
      dplyr::mutate(
        !!rlang::sym(x_var) := forcats::fct_explicit_na(
          factor(!!rlang::sym(x_var)), na_level = na_label
        )
      )
  }

  # Handle haven_labelled variables
  if (requireNamespace("haven", quietly = TRUE)) {
    if (inherits(plot_data[[x_var]], "haven_labelled")) {
      plot_data <- plot_data %>%
        dplyr::mutate(!!rlang::sym(x_var) := haven::as_factor(!!rlang::sym(x_var), levels = "labels"))
    }
  }

  # Aggregate data
  if (!is.null(y_var)) {
    # Pre-aggregated data
    agg_data <- plot_data %>%
      dplyr::rename(value = !!rlang::sym(y_var)) %>%
      dplyr::mutate(name = as.character(!!rlang::sym(x_var)))
  } else if (!is.null(weight_var)) {
    # Weighted counts
    agg_data <- plot_data %>%
      dplyr::count(!!rlang::sym(x_var), wt = !!rlang::sym(weight_var), name = "value") %>%
      dplyr::mutate(
        name = as.character(!!rlang::sym(x_var)),
        value = round(value, 0)
      )
  } else {
    # Simple counts
    agg_data <- plot_data %>%
      dplyr::count(!!rlang::sym(x_var), name = "value") %>%
      dplyr::mutate(name = as.character(!!rlang::sym(x_var)))
  }

  # Apply ordering
  if (!is.null(x_order)) {
    agg_data <- agg_data %>%
      dplyr::mutate(name = factor(name, levels = x_order)) %>%
      dplyr::arrange(name) %>%
      dplyr::mutate(name = as.character(name))
  }

  # Sort by value
  if (isTRUE(sort_by_value)) {
    agg_data <- agg_data %>%
      dplyr::arrange(dplyr::desc(value))
  }

  # Build data points for Highcharts
  hc_data <- lapply(seq_len(nrow(agg_data)), function(i) {
    list(name = agg_data$name[i], y = agg_data$value[i])
  })

  # Create chart
  hc <- highcharter::highchart() %>%
    highcharter::hc_chart(type = "pie") %>%
    highcharter::hc_add_series(
      name = x_var,
      data = hc_data,
      innerSize = inner_size,
      showInLegend = show_in_legend,
      dataLabels = list(
        enabled = data_labels_enabled,
        format = data_labels_format
      )
    )

  # Title & subtitle
  if (!is.null(title)) hc <- hc %>% highcharter::hc_title(text = title)
  if (!is.null(subtitle)) hc <- hc %>% highcharter::hc_subtitle(text = subtitle)

  # Color palette
  if (!is.null(color_palette)) {
    hc <- hc %>% highcharter::hc_colors(color_palette)
  }

  # Center text for donut charts
  if (!is.null(center_text) && inner_size != "0%") {
    hc <- hc %>%
      highcharter::hc_subtitle(
        text = center_text,
        verticalAlign = "middle",
        floating = TRUE,
        style = list(fontSize = "18px", fontWeight = "bold")
      )
  }

  # Tooltip
  if (!is.null(tooltip)) {
    tooltip_result <- .process_tooltip_config(
      tooltip = tooltip,
      tooltip_prefix = tooltip_prefix,
      tooltip_suffix = tooltip_suffix,
      x_tooltip_suffix = NULL,
      chart_type = "pie",
      context = list()
    )
    hc <- .apply_tooltip_to_hc(hc, tooltip_result)
  } else {
    pre <- if (is.null(tooltip_prefix) || tooltip_prefix == "") "" else tooltip_prefix
    suf <- if (is.null(tooltip_suffix) || tooltip_suffix == "") "" else tooltip_suffix

    tooltip_fn <- sprintf(
      "function() {
         return '<b>' + this.point.name + '</b><br/>' +
                '%s' + this.y.toLocaleString() + '%s<br/>' +
                '<span style=\"color:#666;font-size:0.9em\">' +
                this.point.percentage.toFixed(1) + '%% of total</span>';
       }",
      pre, suf
    )

    hc <- hc %>% highcharter::hc_tooltip(
      formatter = highcharter::JS(tooltip_fn),
      useHTML = TRUE
    )
  }

  # Plot options
  hc <- hc %>%
    highcharter::hc_plotOptions(
      pie = list(
        allowPointSelect = TRUE,
        cursor = "pointer"
      )
    )

  return(hc)
}
