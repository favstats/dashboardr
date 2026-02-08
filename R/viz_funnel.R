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
#' @param backend Rendering backend: "highcharter" (default), "plotly", "echarts4r", or "ggiraph".
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
                       height = 400,
                       backend = "highcharter") {

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

  # Build config for backend dispatch
  config <- list(
    title = title, subtitle = subtitle,
    x_var = x_var, color_palette = color_palette,
    neck_width = neck_width, neck_height = neck_height,
    show_conversion = show_conversion,
    data_labels_enabled = data_labels_enabled,
    data_labels_format = data_labels_format,
    show_in_legend = show_in_legend,
    reversed = reversed,
    tooltip = tooltip, tooltip_prefix = tooltip_prefix,
    tooltip_suffix = tooltip_suffix,
    height = height,
    stages = stages, values = values, hc_data = hc_data
  )

  # Dispatch to backend renderer
  backend <- .normalize_backend(backend)
  backend <- match.arg(backend, c("highcharter", "plotly", "echarts4r", "ggiraph"))
  .assert_backend_supported("funnel", backend)
  render_fn <- switch(backend,
    highcharter = .viz_funnel_highcharter,
    plotly      = .viz_funnel_plotly,
    echarts4r   = .viz_funnel_echarts,
    ggiraph     = .viz_funnel_ggiraph
  )
  result <- render_fn(plot_data, config)
  result <- .register_chart_widget(result, backend = backend)
  return(result)
}

# --- Highcharter backend (original implementation) ---
#' @keywords internal
.viz_funnel_highcharter <- function(plot_data, config) {
  # Unpack config
  title <- config$title; subtitle <- config$subtitle
  x_var <- config$x_var; color_palette <- config$color_palette
  neck_width <- config$neck_width; neck_height <- config$neck_height
  show_conversion <- config$show_conversion
  data_labels_enabled <- config$data_labels_enabled
  data_labels_format <- config$data_labels_format
  show_in_legend <- config$show_in_legend
  reversed <- config$reversed
  tooltip <- config$tooltip; tooltip_prefix <- config$tooltip_prefix
  tooltip_suffix <- config$tooltip_suffix
  height <- config$height
  hc_data <- config$hc_data

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

# --- Plotly backend ---
#' @keywords internal
.viz_funnel_plotly <- function(plot_data, config) {
  rlang::check_installed("plotly", reason = "to use backend = 'plotly'")

  stages <- config$stages
  values <- config$values
  title <- config$title
  color_palette <- config$color_palette
  tooltip_prefix <- config$tooltip_prefix
  tooltip_suffix <- config$tooltip_suffix
  show_conversion <- config$show_conversion

  pre <- if (is.null(tooltip_prefix) || tooltip_prefix == "") "" else tooltip_prefix
  suf <- if (is.null(tooltip_suffix) || tooltip_suffix == "") "" else tooltip_suffix

  # Build hover text
  hover_text <- vapply(seq_along(stages), function(i) {
    base <- paste0("<b>", stages[i], "</b><br/>", pre,
                   formatC(values[i], format = "f", big.mark = ",", digits = 0), suf)
    if (show_conversion && i > 1) {
      conv <- round(values[i] / values[i - 1] * 100, 1)
      base <- paste0(base, "<br/><span style='color:#666;font-size:0.9em'>Conversion: ",
                      conv, "%</span>")
    }
    base
  }, character(1))

  p <- plotly::plot_ly(
    type = "funnel",
    y = stages,
    x = values,
    textinfo = "value+percent initial",
    hovertext = hover_text,
    hoverinfo = "text"
  )

  if (!is.null(color_palette)) {
    p <- plotly::layout(p, colorway = color_palette)
  }

  layout_args <- list(p = p)
  if (!is.null(title)) layout_args$title <- title
  layout_args$yaxis <- list(categoryorder = "array", categoryarray = rev(stages))
  p <- do.call(plotly::layout, layout_args)

  p
}

# --- echarts4r backend ---
#' @keywords internal
.viz_funnel_echarts <- function(plot_data, config) {
  rlang::check_installed("echarts4r", reason = "to use backend = 'echarts4r'")

  stages <- config$stages
  values <- config$values
  title <- config$title
  subtitle <- config$subtitle
  color_palette <- config$color_palette
  show_conversion <- config$show_conversion

  # echarts4r funnel expects a data frame with name and value columns
  funnel_df <- data.frame(name = stages, value = values, stringsAsFactors = FALSE)

  e <- funnel_df |>
    echarts4r::e_charts() |>
    echarts4r::e_funnel(value, name)

  if (!is.null(title) || !is.null(subtitle)) {
    e <- e |> echarts4r::e_title(text = title %||% "", subtext = subtitle %||% "")
  }

  e <- e |> echarts4r::e_tooltip(trigger = "item")

  if (!is.null(color_palette)) {
    e <- e |> echarts4r::e_color(color_palette)
  }

  e
}

# --- ggiraph backend ---
#' @keywords internal
.viz_funnel_ggiraph <- function(plot_data, config) {
  rlang::check_installed("ggiraph", reason = "to use backend = 'ggiraph'")
  rlang::check_installed("ggplot2", reason = "to use backend = 'ggiraph'")

  stages <- config$stages
  values <- config$values
  title <- config$title
  subtitle <- config$subtitle
  color_palette <- config$color_palette
  show_conversion <- config$show_conversion

  # Build data frame for plotting - simulate funnel with horizontal bar chart sorted by value

  funnel_df <- data.frame(
    stage = factor(stages, levels = rev(stages)),
    value = values,
    stringsAsFactors = FALSE
  )

  # Build tooltip text
  funnel_df$.tooltip <- vapply(seq_along(stages), function(i) {
    base <- paste0(stages[i], ": ", formatC(values[i], format = "f", big.mark = ",", digits = 0))
    if (show_conversion && i > 1) {
      conv <- round(values[i] / values[i - 1] * 100, 1)
      base <- paste0(base, "\nConversion: ", conv, "%")
    }
    base
  }, character(1))

  p <- ggplot2::ggplot(funnel_df, ggplot2::aes(
    x = .data$stage, y = .data$value
  )) +
    ggiraph::geom_bar_interactive(
      ggplot2::aes(tooltip = .data$.tooltip, data_id = .data$stage, fill = .data$stage),
      stat = "identity", width = 0.7
    ) +
    ggplot2::coord_flip() +
    ggplot2::labs(title = title, subtitle = subtitle, x = NULL, y = NULL) +
    ggplot2::theme_minimal() +
    ggplot2::theme(legend.position = "none")

  if (!is.null(color_palette)) {
    p <- p + ggplot2::scale_fill_manual(values = color_palette)
  }

  ggiraph::girafe(ggobj = p)
}
