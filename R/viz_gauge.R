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
#' @param backend Rendering backend: "highcharter" (default), "plotly", "echarts4r", or "ggiraph".
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
                      height = 300,
                      backend = "highcharter") {

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

  # Build config for backend dispatch
  config <- list(
    value = value, min = min, max = max,
    title = title, subtitle = subtitle,
    gauge_type = gauge_type, bands = bands,
    inner_radius = inner_radius, rounded = rounded,
    data_labels_format = data_labels_format,
    data_labels_style = data_labels_style,
    color = color, background_color = background_color,
    target = target, target_color = target_color,
    height = height, plot_bands = plot_bands
  )

  # Dispatch to backend renderer
  backend <- .normalize_backend(backend)
  backend <- match.arg(backend, c("highcharter", "plotly", "echarts4r", "ggiraph"))
  .assert_backend_supported("gauge", backend)
  render_fn <- switch(backend,
    highcharter = .viz_gauge_highcharter,
    plotly      = .viz_gauge_plotly,
    echarts4r   = .viz_gauge_echarts,
    ggiraph     = .viz_gauge_ggiraph
  )
  result <- render_fn(config)
  result <- .register_chart_widget(result, backend = backend)
  return(result)
}

# --- Highcharter backend (original implementation) ---
#' @keywords internal
.viz_gauge_highcharter <- function(config) {
  # Unpack config
  value <- config$value; min <- config$min; max <- config$max
  title <- config$title; subtitle <- config$subtitle
  bands <- config$bands
  inner_radius <- config$inner_radius; rounded <- config$rounded
  data_labels_format <- config$data_labels_format
  data_labels_style <- config$data_labels_style
  color <- config$color; background_color <- config$background_color
  target <- config$target; target_color <- config$target_color
  height <- config$height; plot_bands <- config$plot_bands

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

# --- Plotly backend ---
#' @keywords internal
.viz_gauge_plotly <- function(config) {
  rlang::check_installed("plotly", reason = "to use backend = 'plotly'")

  value <- config$value; min <- config$min; max <- config$max
  title <- config$title
  bands <- config$bands
  color <- config$color
  target <- config$target; target_color <- config$target_color
  height <- config$height

  # Build gauge steps from bands
  steps <- NULL
  if (!is.null(bands)) {
    steps <- lapply(bands, function(band) {
      list(range = c(band$from, band$to), color = band$color)
    })
  }

  # Build threshold for target
  threshold <- NULL
  if (!is.null(target)) {
    threshold <- list(
      line = list(color = target_color, width = 4),
      thickness = 0.75,
      value = target
    )
  }

  p <- plotly::plot_ly(
    type = "indicator",
    mode = "gauge+number",
    value = value,
    gauge = list(
      axis = list(range = list(min, max)),
      bar = list(color = color),
      bgcolor = config$background_color,
      steps = steps,
      threshold = threshold
    )
  )

  layout_args <- list(p = p, height = height)
  if (!is.null(title)) {
    layout_args$title <- list(text = title)
  }

  p <- do.call(plotly::layout, layout_args)

  p
}

# --- echarts4r backend ---
#' @keywords internal
.viz_gauge_echarts <- function(config) {
  rlang::check_installed("echarts4r", reason = "to use backend = 'echarts4r'")

  value <- config$value; min <- config$min; max <- config$max
  title <- config$title; subtitle <- config$subtitle
  bands <- config$bands
  color <- config$color
  height <- config$height

  # Build axis line colors from bands
  axis_line_colors <- NULL
  if (!is.null(bands)) {
    axis_line_colors <- lapply(bands, function(band) {
      list(band$to / max, band$color)
    })
  }

  gauge_data <- data.frame(name = title %||% "Value", value = value)

  e <- gauge_data |>
    echarts4r::e_charts() |>
    echarts4r::e_gauge(
      value,
      name = title %||% "Value",
      min = min,
      max = max,
      startAngle = 180,
      endAngle = 0,
      splitNumber = 5,
      detail = list(
        formatter = "{value}",
        fontSize = 24,
        fontWeight = "bold",
        offsetCenter = c(0, "20%")
      ),
      axisLine = if (!is.null(axis_line_colors)) {
        list(
          lineStyle = list(
            width = 20,
            color = axis_line_colors
          )
        )
      } else {
        list(
          lineStyle = list(
            width = 20,
            color = list(list(1, color))
          )
        )
      }
    ) |>
    echarts4r::e_tooltip(trigger = "item")

  if (!is.null(title) || !is.null(subtitle)) {
    e <- e |> echarts4r::e_title(text = title %||% "", subtext = subtitle %||% "")
  }

  e
}

# --- ggiraph backend ---
#' @keywords internal
.viz_gauge_ggiraph <- function(config) {
  stop("backend = 'ggiraph' is not supported for viz_gauge(). ",
       "ggiraph/ggplot2 does not have native gauge geoms. ",
       "Use backend = 'highcharter', 'plotly', or 'echarts4r' instead.",
       call. = FALSE)
}
