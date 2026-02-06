# =================================================================
# Gauge / Bullet Chart Visualization
# =================================================================

#' Create a Gauge or Bullet Chart
#'
#' Creates an interactive gauge (speedometer) or bullet chart using highcharter.
#' Gauges show a single value against a scale, ideal for KPIs and scores.
#'
#' @param data Optional data frame. If provided, `value_var` is used to extract the value.
#' @param value Numeric. The value to display on the gauge. Used when `data` is NULL.
#' @param value_var Optional character string. Column name in `data` to use as the value.
#'   The mean/first value is extracted.
#' @param min Numeric. Minimum value of the gauge scale. Default 0.
#' @param max Numeric. Maximum value of the gauge scale. Default 100.
#' @param title Optional main title for the chart.
#' @param subtitle Optional subtitle for the chart.
#' @param gauge_type Character string. Type of gauge: "solid" (default) or "activity".
#'   "solid" creates a solid gauge (filled arc). "activity" creates an activity-style gauge.
#' @param bands Optional list of band definitions for color zones. Each band is a list with:
#'   `from`, `to`, `color`, and optionally `label`. Example:
#'   \code{list(list(from = 0, to = 50, color = "red"), list(from = 50, to = 100, color = "green"))}.
#' @param inner_radius Character string. Inner radius of the gauge arc as percentage.
#'   Default "60%". Increase for thinner arc, decrease for thicker.
#' @param rounded Logical. If TRUE (default), use rounded ends on the gauge arc.
#' @param data_labels_format Character string. Format for the center label.
#'   Default "\{y\}". Use "\{y\}%" for percentage, "$\{y\}" for currency, etc.
#' @param data_labels_style Optional list of CSS styles for the center label.
#'   Default: large bold text.
#' @param color Character string. Color of the gauge fill. Default "#4E79A7".
#'   Ignored if `bands` are specified (band colors are used instead).
#' @param background_color Character string. Color of the gauge background track.
#'   Default "#e6e6e6".
#' @param target Optional numeric. Target/goal value to show as a marker on the gauge.
#' @param target_color Character string. Color of the target marker. Default "#333333".
#' @param height Numeric. Chart height in pixels. Default 300.
#'
#' @return A highcharter plot object.
#'
#' @examples
#' \dontrun{
#' # Simple gauge
#' viz_gauge(value = 73, title = "Completion Rate", data_labels_format = "{y}%")
#'
#' # Gauge with color bands
#' viz_gauge(value = 65, min = 0, max = 100,
#'           bands = list(
#'             list(from = 0, to = 40, color = "#E15759"),
#'             list(from = 40, to = 70, color = "#F28E2B"),
#'             list(from = 70, to = 100, color = "#59A14F")
#'           ),
#'           title = "Performance Score")
#'
#' # From data
#' viz_gauge(data = mtcars, value_var = "mpg", min = 10, max = 35,
#'           title = "Average MPG")
#' }
#' @export
viz_gauge <- function(data = NULL,
                      value = NULL,
                      value_var = NULL,
                      min = 0,
                      max = 100,
                      title = NULL,
                      subtitle = NULL,
                      gauge_type = "solid",
                      bands = NULL,
                      inner_radius = "60%",
                      rounded = TRUE,
                      data_labels_format = "{y}",
                      data_labels_style = NULL,
                      color = "#4E79A7",
                      background_color = "#e6e6e6",
                      target = NULL,
                      target_color = "#333333",
                      height = 300) {

  # Convert value_var
  if (!is.null(data)) {
    value_var <- .as_var_string(rlang::enquo(value_var))
  }

  # Input validation
  if (is.null(data) && is.null(value)) {
    .stop_with_hint("value", example = 'viz_gauge(value = 73, title = "Score")')
  }

  # Extract value from data if needed
  if (!is.null(data) && !is.null(value_var)) {
    if (!value_var %in% names(data)) {
      stop(paste0("Column '", value_var, "' not found in data."), call. = FALSE)
    }
    if (!is.numeric(data[[value_var]])) {
      stop(paste0("'", value_var, "' must be a numeric column."), call. = FALSE)
    }
    value <- round(mean(data[[value_var]], na.rm = TRUE), 1)
  }

  if (!is.numeric(value)) {
    stop("`value` must be numeric.", call. = FALSE)
  }

  if (!gauge_type %in% c("solid", "activity")) {
    .stop_with_hint("gauge_type", valid_options = c("solid", "activity"))
  }

  # Default label style
  if (is.null(data_labels_style)) {
    data_labels_style <- list(
      fontSize = "24px",
      fontWeight = "bold",
      textOutline = "none"
    )
  }

  # Build bands for yAxis plotBands
  plot_bands <- NULL
  if (!is.null(bands)) {
    plot_bands <- lapply(bands, function(band) {
      list(
        from = band$from,
        to = band$to,
        color = band$color,
        thickness = "100%"
      )
    })
  }

  # Create solid gauge
  hc <- highcharter::highchart() %>%
    highcharter::hc_chart(
      type = "solidgauge",
      height = height
    ) %>%
    highcharter::hc_pane(
      startAngle = -90,
      endAngle = 90,
      background = list(
        list(
          backgroundColor = background_color,
          innerRadius = inner_radius,
          outerRadius = "100%",
          shape = "arc",
          borderWidth = 0
        )
      ),
      center = list("50%", "70%"),
      size = "100%"
    ) %>%
    highcharter::hc_yAxis(
      min = min,
      max = max,
      lineWidth = 0,
      tickWidth = 0,
      minorTickWidth = 0,
      labels = list(enabled = FALSE),
      plotBands = plot_bands,
      stops = if (is.null(bands)) NULL else NULL
    ) %>%
    highcharter::hc_add_series(
      name = title %||% "Value",
      data = list(list(
        y = value,
        color = if (is.null(bands)) color else NULL
      )),
      innerRadius = inner_radius,
      radius = "100%",
      rounded = rounded,
      dataLabels = list(
        enabled = TRUE,
        format = data_labels_format,
        borderWidth = 0,
        style = data_labels_style,
        y = -20
      )
    )

  # Title & subtitle
  if (!is.null(title)) hc <- hc %>% highcharter::hc_title(text = title)
  if (!is.null(subtitle)) hc <- hc %>% highcharter::hc_subtitle(text = subtitle)

  # Target line
  if (!is.null(target)) {
    hc <- hc %>%
      highcharter::hc_yAxis(
        plotLines = list(
          list(
            value = target,
            color = target_color,
            width = 3,
            zIndex = 5,
            label = list(
              text = paste("Target:", target),
              style = list(fontSize = "11px", color = target_color)
            )
          )
        )
      )
  }

  # Tooltip
  hc <- hc %>%
    highcharter::hc_tooltip(
      pointFormat = paste0(
        '<span style="font-size:1.2em; font-weight:bold">{point.y}</span>',
        '<br/><span style="color:#666">Range: ', min, ' - ', max, '</span>'
      )
    )

  # Disable credits
  hc <- hc %>% highcharter::hc_credits(enabled = FALSE)

  return(hc)
}
