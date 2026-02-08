# =================================================================
# Dumbbell Chart Visualization
# =================================================================

#' Create a Dumbbell Chart
#'
#' Creates an interactive dumbbell (dot plot range) chart using highcharter.
#' Dumbbell charts show the difference between two values per category,
#' useful for before/after comparisons, ranges, or gaps.
#'
#' @param data A data frame containing the data.
#' @param x_var Character string. Name of the categorical variable (category labels).
#' @param low_var Character string. Name of the numeric column for the lower value.
#' @param high_var Character string. Name of the numeric column for the higher value.
#' @param title Optional main title for the chart.
#' @param subtitle Optional subtitle for the chart.
#' @param x_label Optional label for the category axis.
#' @param y_label Optional label for the value axis.
#' @param horizontal Logical. If TRUE (default), creates horizontal dumbbells.
#' @param low_label Character string. Label for the low-value series. Default "Low".
#' @param high_label Character string. Label for the high-value series. Default "High".
#' @param low_color Character string. Color for the low-value dots. Default "#E15759".
#' @param high_color Character string. Color for the high-value dots. Default "#4E79A7".
#' @param connector_color Character string. Color for the connecting line. Default "#999999".
#' @param connector_width Numeric. Width of the connecting line in pixels. Default 2.
#' @param dot_size Numeric. Radius of the dots in pixels. Default 6.
#' @param x_order Optional character vector specifying the order of categories.
#' @param sort_by_gap Logical. If TRUE, sort by the gap between high and low values.
#'   Default FALSE.
#' @param sort_desc Logical. Sort direction. Default TRUE (largest gap first).
#' @param data_labels_enabled Logical. If TRUE, show value labels. Default FALSE.
#' @param color_palette Optional named vector of two colors: c(low = "...", high = "...").
#' @param tooltip A tooltip configuration created with \code{\link{tooltip}()},
#'   OR a format string with \{placeholders\}.
#' @param tooltip_prefix Optional string prepended to tooltip values.
#' @param tooltip_suffix Optional string appended to tooltip values.
#'
#' @param backend Rendering backend: "highcharter" (default), "plotly", "echarts4r", or "ggiraph".
#' @return A highcharter plot object.
#'
#' @examples
#' \dontrun{
#' df <- data.frame(
#'   country = c("US", "UK", "DE", "FR"),
#'   score_2020 = c(65, 58, 72, 60),
#'   score_2024 = c(78, 65, 75, 70)
#' )
#' viz_dumbbell(df, x_var = "country",
#'              low_var = "score_2020", high_var = "score_2024",
#'              low_label = "2020", high_label = "2024",
#'              title = "Score Changes 2020-2024")
#' }
#' @export
viz_dumbbell <- function(data,
                         x_var,
                         low_var,
                         high_var,
                         title = NULL,
                         subtitle = NULL,
                         x_label = NULL,
                         y_label = NULL,
                         horizontal = TRUE,
                         low_label = "Low",
                         high_label = "High",
                         low_color = "#E15759",
                         high_color = "#4E79A7",
                         connector_color = "#999999",
                         connector_width = 2,
                         dot_size = 6,
                         x_order = NULL,
                         sort_by_gap = FALSE,
                         sort_desc = TRUE,
                         data_labels_enabled = FALSE,
                         color_palette = NULL,
                         tooltip = NULL,
                         tooltip_prefix = "",
                         tooltip_suffix = "",
                         backend = "highcharter") {

  # Convert variable arguments to strings
  x_var <- .as_var_string(rlang::enquo(x_var))
  low_var <- .as_var_string(rlang::enquo(low_var))
  high_var <- .as_var_string(rlang::enquo(high_var))

  # Input validation
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }

  if (is.null(x_var)) {
    .stop_with_hint("x_var", example = 'viz_dumbbell(data, x_var = "category", low_var = "start", high_var = "end")')
  }

  for (col in c(x_var, low_var, high_var)) {
    if (!col %in% names(data)) {
      stop(paste0("Column '", col, "' not found in data."), call. = FALSE)
    }
  }

  if (!is.numeric(data[[low_var]])) {
    stop(paste0("'", low_var, "' must be a numeric column."), call. = FALSE)
  }
  if (!is.numeric(data[[high_var]])) {
    stop(paste0("'", high_var, "' must be a numeric column."), call. = FALSE)
  }

  # Apply color_palette override
  if (!is.null(color_palette)) {
    if (length(color_palette) >= 2) {
      low_color <- color_palette[1]
      high_color <- color_palette[2]
    }
    if (!is.null(names(color_palette))) {
      if ("low" %in% names(color_palette)) low_color <- color_palette["low"]
      if ("high" %in% names(color_palette)) high_color <- color_palette["high"]
    }
  }

  # Prepare data
  plot_data <- data %>%
    dplyr::select(dplyr::all_of(c(x_var, low_var, high_var))) %>%
    dplyr::filter(!is.na(!!rlang::sym(x_var)),
                  !is.na(!!rlang::sym(low_var)),
                  !is.na(!!rlang::sym(high_var))) %>%
    dplyr::mutate(
      category = as.character(!!rlang::sym(x_var)),
      low = !!rlang::sym(low_var),
      high = !!rlang::sym(high_var),
      gap = high - low
    )

  # Handle haven_labelled
  if (requireNamespace("haven", quietly = TRUE)) {
    if (inherits(plot_data[[x_var]], "haven_labelled")) {
      plot_data <- plot_data %>%
        dplyr::mutate(category = as.character(haven::as_factor(!!rlang::sym(x_var), levels = "labels")))
    }
  }

  # Ordering
  if (!is.null(x_order)) {
    plot_data <- plot_data %>%
      dplyr::mutate(category = factor(category, levels = x_order)) %>%
      dplyr::arrange(category)
  } else if (isTRUE(sort_by_gap)) {
    plot_data <- plot_data %>%
      dplyr::arrange(if (sort_desc) dplyr::desc(gap) else gap)
  }

  categories <- as.character(plot_data$category)

  # Set labels
  final_x_label <- x_label %||% x_var
  final_y_label <- y_label %||% ""

  # Build config for backend dispatch
  config <- list(
    title = title, subtitle = subtitle,
    x_label = final_x_label, y_label = final_y_label,
    horizontal = horizontal,
    low_label = low_label, high_label = high_label,
    low_color = low_color, high_color = high_color,
    connector_color = connector_color, connector_width = connector_width,
    dot_size = dot_size,
    data_labels_enabled = data_labels_enabled,
    tooltip = tooltip, tooltip_prefix = tooltip_prefix,
    tooltip_suffix = tooltip_suffix,
    categories = categories
  )

  # Dispatch to backend renderer
  backend <- .normalize_backend(backend)
  backend <- match.arg(backend, c("highcharter", "plotly", "echarts4r", "ggiraph"))
  .assert_backend_supported("dumbbell", backend)
  render_fn <- switch(backend,
    highcharter = .viz_dumbbell_highcharter,
    plotly      = .viz_dumbbell_plotly,
    echarts4r   = .viz_dumbbell_echarts,
    ggiraph     = .viz_dumbbell_ggiraph
  )
  result <- render_fn(plot_data, config)
  result <- .register_chart_widget(result, backend = backend)
  return(result)
}

# --- Highcharter backend (original implementation) ---
#' @keywords internal
.viz_dumbbell_highcharter <- function(plot_data, config) {
  # Unpack config
  title <- config$title; subtitle <- config$subtitle
  final_x_label <- config$x_label; final_y_label <- config$y_label
  horizontal <- config$horizontal
  low_label <- config$low_label; high_label <- config$high_label
  low_color <- config$low_color; high_color <- config$high_color
  connector_color <- config$connector_color; connector_width <- config$connector_width
  dot_size <- config$dot_size
  data_labels_enabled <- config$data_labels_enabled
  tooltip <- config$tooltip; tooltip_prefix <- config$tooltip_prefix
  tooltip_suffix <- config$tooltip_suffix
  categories <- config$categories

  # Build dumbbell using Highcharts dumbbell type
  # Highcharts has a native dumbbell chart type (requires highcharts-more)
  hc <- highcharter::highchart() %>%
    highcharter::hc_chart(
      type = if (horizontal) "dumbbell" else "dumbbell",
      inverted = horizontal
    )

  if (!is.null(title)) hc <- hc %>% highcharter::hc_title(text = title)
  if (!is.null(subtitle)) hc <- hc %>% highcharter::hc_subtitle(text = subtitle)

  # Build data points for dumbbell series
  dumbbell_data <- lapply(seq_len(nrow(plot_data)), function(i) {
    list(
      name = categories[i],
      low = plot_data$low[i],
      high = plot_data$high[i]
    )
  })

  hc <- hc %>%
    highcharter::hc_xAxis(
      categories = categories,
      title = list(text = final_x_label)
    ) %>%
    highcharter::hc_yAxis(
      title = list(text = final_y_label)
    ) %>%
    highcharter::hc_add_series(
      name = paste(low_label, "-", high_label),
      data = dumbbell_data,
      type = "dumbbell",
      lowColor = low_color,
      color = high_color,
      connectorColor = connector_color,
      connectorWidth = connector_width,
      marker = list(radius = dot_size),
      dataLabels = list(enabled = data_labels_enabled)
    )

  # Legend entries to explain the two colors
  hc <- hc %>%
    highcharter::hc_legend(enabled = TRUE)

  # Tooltip
  if (!is.null(tooltip)) {
    tooltip_result <- .process_tooltip_config(
      tooltip = tooltip,
      tooltip_prefix = tooltip_prefix,
      tooltip_suffix = tooltip_suffix,
      x_tooltip_suffix = NULL,
      chart_type = "dumbbell",
      context = list()
    )
    hc <- .apply_tooltip_to_hc(hc, tooltip_result)
  } else {
    pre <- if (is.null(tooltip_prefix) || tooltip_prefix == "") "" else tooltip_prefix
    suf <- if (is.null(tooltip_suffix) || tooltip_suffix == "") "" else tooltip_suffix

    tooltip_fn <- sprintf(
      "function() {
         var cat = this.point.name || this.point.category || '';
         var low = this.point.low;
         var high = this.point.high;
         var diff = (high - low).toFixed(1);
         return '<b>' + cat + '</b><br/>' +
                '%s: %s' + low.toLocaleString() + '%s<br/>' +
                '%s: %s' + high.toLocaleString() + '%s<br/>' +
                '<span style=\"color:#666;font-size:0.9em\">Difference: ' + diff + '</span>';
       }",
      low_label, pre, suf, high_label, pre, suf
    )
    hc <- hc %>% highcharter::hc_tooltip(
      formatter = highcharter::JS(tooltip_fn),
      useHTML = TRUE
    )
  }

  return(hc)
}

# --- Plotly backend ---
#' @keywords internal
.viz_dumbbell_plotly <- function(plot_data, config) {
  rlang::check_installed("plotly", reason = "to use backend = 'plotly'")

  title <- config$title
  final_x_label <- config$x_label; final_y_label <- config$y_label
  horizontal <- config$horizontal
  low_label <- config$low_label; high_label <- config$high_label
  low_color <- config$low_color; high_color <- config$high_color
  connector_color <- config$connector_color; connector_width <- config$connector_width
  dot_size <- config$dot_size
  categories <- config$categories

  p <- plotly::plot_ly()

  if (horizontal) {
    # Connector lines
    for (i in seq_len(nrow(plot_data))) {
      p <- p |> plotly::add_segments(
        x = plot_data$low[i], xend = plot_data$high[i],
        y = categories[i], yend = categories[i],
        line = list(color = connector_color, width = connector_width),
        showlegend = FALSE
      )
    }
    # Low dots
    p <- p |> plotly::add_markers(
      x = plot_data$low, y = categories,
      name = low_label,
      marker = list(color = low_color, size = dot_size)
    )
    # High dots
    p <- p |> plotly::add_markers(
      x = plot_data$high, y = categories,
      name = high_label,
      marker = list(color = high_color, size = dot_size)
    )
  } else {
    # Connector lines
    for (i in seq_len(nrow(plot_data))) {
      p <- p |> plotly::add_segments(
        x = categories[i], xend = categories[i],
        y = plot_data$low[i], yend = plot_data$high[i],
        line = list(color = connector_color, width = connector_width),
        showlegend = FALSE
      )
    }
    # Low dots
    p <- p |> plotly::add_markers(
      x = categories, y = plot_data$low,
      name = low_label,
      marker = list(color = low_color, size = dot_size)
    )
    # High dots
    p <- p |> plotly::add_markers(
      x = categories, y = plot_data$high,
      name = high_label,
      marker = list(color = high_color, size = dot_size)
    )
  }

  layout_args <- list(p = p)
  if (!is.null(title)) layout_args$title <- title
  if (horizontal) {
    layout_args$xaxis <- list(title = final_y_label)
    layout_args$yaxis <- list(title = final_x_label, categoryorder = "trace")
  } else {
    layout_args$xaxis <- list(title = final_x_label)
    layout_args$yaxis <- list(title = final_y_label)
  }
  p <- do.call(plotly::layout, layout_args)

  p
}

# --- echarts4r backend ---
#' @keywords internal
.viz_dumbbell_echarts <- function(plot_data, config) {
  rlang::check_installed("echarts4r", reason = "to use backend = 'echarts4r'")

  title <- config$title; subtitle <- config$subtitle
  final_x_label <- config$x_label; final_y_label <- config$y_label
  horizontal <- config$horizontal
  low_label <- config$low_label; high_label <- config$high_label
  low_color <- config$low_color; high_color <- config$high_color
  dot_size <- config$dot_size
  categories <- config$categories

  # echarts4r: use custom series with scatter for low/high dots and a line for connector
  # We build a data frame with low and high columns
  chart_df <- data.frame(
    category = categories,
    low = plot_data$low,
    high = plot_data$high,
    stringsAsFactors = FALSE
  )

  e <- chart_df |>
    echarts4r::e_charts(category) |>
    echarts4r::e_scatter(low, name = low_label, symbol_size = dot_size,
                          itemStyle = list(color = low_color)) |>
    echarts4r::e_scatter(high, name = high_label, symbol_size = dot_size,
                          itemStyle = list(color = high_color))

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

  e
}

# --- ggiraph backend ---
#' @keywords internal
.viz_dumbbell_ggiraph <- function(plot_data, config) {
  rlang::check_installed("ggiraph", reason = "to use backend = 'ggiraph'")
  rlang::check_installed("ggplot2", reason = "to use backend = 'ggiraph'")

  title <- config$title; subtitle <- config$subtitle
  final_x_label <- config$x_label; final_y_label <- config$y_label
  horizontal <- config$horizontal
  low_label <- config$low_label; high_label <- config$high_label
  low_color <- config$low_color; high_color <- config$high_color
  connector_color <- config$connector_color; connector_width <- config$connector_width
  dot_size <- config$dot_size
  categories <- config$categories

  plot_data$category <- factor(plot_data$category, levels = rev(categories))

  # Build tooltip
  plot_data$.tooltip <- paste0(
    plot_data$category,
    "\n", low_label, ": ", round(plot_data$low, 1),
    "\n", high_label, ": ", round(plot_data$high, 1),
    "\nDifference: ", round(plot_data$gap, 1)
  )

  p <- ggplot2::ggplot(plot_data) +
    ggplot2::geom_segment(
      ggplot2::aes(x = .data$category, xend = .data$category,
                    y = .data$low, yend = .data$high),
      color = connector_color, linewidth = connector_width * 0.3
    ) +
    ggiraph::geom_point_interactive(
      ggplot2::aes(x = .data$category, y = .data$low,
                    tooltip = .data$.tooltip, data_id = .data$category),
      color = low_color, size = dot_size * 0.5
    ) +
    ggiraph::geom_point_interactive(
      ggplot2::aes(x = .data$category, y = .data$high,
                    tooltip = .data$.tooltip, data_id = .data$category),
      color = high_color, size = dot_size * 0.5
    ) +
    ggplot2::labs(title = title, subtitle = subtitle,
                  x = final_x_label, y = final_y_label) +
    ggplot2::theme_minimal()

  if (horizontal) {
    p <- p + ggplot2::coord_flip()
  }

  ggiraph::girafe(ggobj = p)
}
