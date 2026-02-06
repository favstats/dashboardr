# =================================================================
# Funnel Chart Visualization
# =================================================================

#' Create a Funnel Chart
#'
#' Creates an interactive funnel chart using highcharter. Funnel charts
#' show sequential stages in a process, with each stage narrower than
#' the previous, representing drop-off or conversion rates.
#'
#' @param data A data frame containing the data.
#' @param x_var Character string. Name of the categorical variable (stage names).
#' @param y_var Character string. Name of the numeric column with values per stage.
#' @param title Optional main title for the chart.
#' @param subtitle Optional subtitle for the chart.
#' @param color_palette Optional character vector of colors for the stages.
#' @param x_order Optional character vector specifying the order of stages
#'   (top to bottom). If NULL, uses the order in the data.
#' @param neck_width Character string. Width of the funnel neck as percentage.
#'   Default "30%". Set to "0%" for a pyramid shape.
#' @param neck_height Character string. Height of the neck section as percentage.
#'   Default "25%".
#' @param show_conversion Logical. If TRUE (default), show conversion rates
#'   between stages in tooltips.
#' @param data_labels_enabled Logical. If TRUE (default), show labels on stages.
#' @param data_labels_format Character string. Format for data labels.
#'   Default "\{point.name\}: \{point.y:,.0f\}".
#' @param show_in_legend Logical. If TRUE, show a legend. Default FALSE.
#' @param reversed Logical. If TRUE, reverse the funnel (pyramid). Default FALSE.
#' @param weight_var Optional character string. Name of weight variable for aggregation.
#' @param tooltip A tooltip configuration created with \code{\link{tooltip}()},
#'   OR a format string.
#' @param tooltip_prefix Optional string prepended to tooltip values.
#' @param tooltip_suffix Optional string appended to tooltip values.
#' @param height Numeric. Chart height in pixels. Default 400.
#'
#' @return A highcharter plot object.
#'
#' @examples
#' \dontrun{
#' df <- data.frame(
#'   stage = c("Visits", "Signups", "Trial", "Purchase"),
#'   count = c(10000, 3000, 800, 200)
#' )
#' viz_funnel(df, x_var = "stage", y_var = "count",
#'            title = "Conversion Funnel")
#' }
#' @export
viz_funnel <- function(data,
                       x_var,
                       y_var,
                       title = NULL,
                       subtitle = NULL,
                       color_palette = NULL,
                       x_order = NULL,
                       neck_width = "30%",
                       neck_height = "25%",
                       show_conversion = TRUE,
                       data_labels_enabled = TRUE,
                       data_labels_format = "{point.name}: {point.y:,.0f}",
                       show_in_legend = FALSE,
                       reversed = FALSE,
                       weight_var = NULL,
                       tooltip = NULL,
                       tooltip_prefix = "",
                       tooltip_suffix = "",
                       height = 400) {

  # Convert variable arguments to strings
  x_var <- .as_var_string(rlang::enquo(x_var))
  y_var <- .as_var_string(rlang::enquo(y_var))
  weight_var <- .as_var_string(rlang::enquo(weight_var))

  # Input validation
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }

  if (is.null(x_var)) {
    .stop_with_hint("x_var", example = 'viz_funnel(data, x_var = "stage", y_var = "count")')
  }

  if (is.null(y_var)) {
    .stop_with_hint("y_var", example = 'viz_funnel(data, x_var = "stage", y_var = "count")')
  }

  for (col in c(x_var, y_var)) {
    if (!col %in% names(data)) {
      stop(paste0("Column '", col, "' not found in data."), call. = FALSE)
    }
  }

  if (!is.numeric(data[[y_var]])) {
    stop(paste0("'", y_var, "' must be a numeric column."), call. = FALSE)
  }

  # Prepare data
  plot_data <- data %>%
    dplyr::select(dplyr::all_of(c(x_var, y_var))) %>%
    dplyr::filter(!is.na(!!rlang::sym(x_var)), !is.na(!!rlang::sym(y_var)))

  # Handle haven_labelled
  if (requireNamespace("haven", quietly = TRUE)) {
    if (inherits(plot_data[[x_var]], "haven_labelled")) {
      plot_data <- plot_data %>%
        dplyr::mutate(!!rlang::sym(x_var) := haven::as_factor(!!rlang::sym(x_var), levels = "labels"))
    }
  }

  # Apply ordering
  if (!is.null(x_order)) {
    plot_data <- plot_data %>%
      dplyr::mutate(!!rlang::sym(x_var) := factor(!!rlang::sym(x_var), levels = x_order)) %>%
      dplyr::arrange(!!rlang::sym(x_var))
  }

  # Build data points
  stages <- as.character(plot_data[[x_var]])
  values <- plot_data[[y_var]]

  hc_data <- lapply(seq_along(stages), function(i) {
    list(name = stages[i], y = values[i])
  })

  # Create funnel chart
  chart_type <- if (reversed) "pyramid" else "funnel"

  hc <- highcharter::highchart() %>%
    highcharter::hc_chart(type = chart_type, height = height) %>%
    highcharter::hc_add_series(
      name = x_var,
      data = hc_data,
      neckWidth = neck_width,
      neckHeight = neck_height,
      showInLegend = show_in_legend,
      reversed = reversed,
      dataLabels = list(
        enabled = data_labels_enabled,
        format = data_labels_format,
        softConnector = TRUE
      )
    )

  # Title & subtitle
  if (!is.null(title)) hc <- hc %>% highcharter::hc_title(text = title)
  if (!is.null(subtitle)) hc <- hc %>% highcharter::hc_subtitle(text = subtitle)

  # Color palette
  if (!is.null(color_palette)) {
    hc <- hc %>% highcharter::hc_colors(color_palette)
  }

  # Tooltip
  if (!is.null(tooltip)) {
    tooltip_result <- .process_tooltip_config(
      tooltip = tooltip,
      tooltip_prefix = tooltip_prefix,
      tooltip_suffix = tooltip_suffix,
      x_tooltip_suffix = NULL,
      chart_type = "funnel",
      context = list()
    )
    hc <- .apply_tooltip_to_hc(hc, tooltip_result)
  } else {
    pre <- if (is.null(tooltip_prefix) || tooltip_prefix == "") "" else tooltip_prefix
    suf <- if (is.null(tooltip_suffix) || tooltip_suffix == "") "" else tooltip_suffix

    if (show_conversion) {
      # Include conversion rate in tooltip
      tooltip_fn <- sprintf(
        "function() {
           var series = this.series;
           var idx = this.point.index;
           var prevVal = idx > 0 ? series.data[idx - 1].y : null;
           var convRate = prevVal ? ((this.y / prevVal) * 100).toFixed(1) : null;
           var tip = '<b>' + this.point.name + '</b><br/>' +
                     '%s' + this.y.toLocaleString() + '%s';
           if (convRate !== null) {
             tip += '<br/><span style=\"color:#666;font-size:0.9em\">Conversion: ' + convRate + '%%</span>';
           }
           return tip;
         }",
        pre, suf
      )
    } else {
      tooltip_fn <- sprintf(
        "function() {
           return '<b>' + this.point.name + '</b><br/>' +
                  '%s' + this.y.toLocaleString() + '%s';
         }",
        pre, suf
      )
    }
    hc <- hc %>% highcharter::hc_tooltip(
      formatter = highcharter::JS(tooltip_fn),
      useHTML = TRUE
    )
  }

  # Credits
  hc <- hc %>% highcharter::hc_credits(enabled = FALSE)

  return(hc)
}
