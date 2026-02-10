# --------------------------------------------------------------------------
# Sparkline Card Functions
# --------------------------------------------------------------------------

#' Add a sparkline card
#'
#' Adds a metric card with an embedded sparkline chart. The sparkline uses the
#' page's data (same as add_viz) and aggregates it by the x_var (typically a
#' date/time variable). The metric value is derived from the aggregated data
#' unless overridden.
#'
#' @param content Content collection, page_object, or sparkline_card_row_container
#' @param x_var Column name for x-axis (typically a date or time variable)
#' @param y_var Column name for y-axis values to aggregate
#' @param value Main value to display. If NULL, automatically computed as the
#'   last value of the aggregated series.
#' @param subtitle Subtitle text below the value
#' @param agg Aggregation function: "count", "sum", "mean", "cumsum", "cumcount"
#'   (default "count")
#' @param line_color Color of the sparkline line (default "#2b74ff")
#' @param bg_color Background color of the card (default "#ffffff")
#' @param text_color Text color (default "#111827"; use "#ffffff" for dark backgrounds)
#' @param height Sparkline height in pixels (default 130)
#' @param smooth Smoothing factor for the line, 0-1 (default 0.6)
#' @param area_opacity Opacity of the fill area under the line, 0-1 (default 0.18)
#' @param filter_expr Optional filter expression as a string (e.g. "region == 'West'")
#' @param value_prefix Text to prepend to the displayed value (e.g. "$")
#' @param value_suffix Text to append to the displayed value (e.g. "%")
#' @param tabgroup Optional tabgroup
#' @param show_when Optional conditional display formula
#' @keywords internal
#' @export
#' @examples
#' \dontrun{
#' page <- create_page(name = "Dashboard", data = survey) %>%
#'   add_sparkline_card_row() %>%
#'     add_sparkline_card(
#'       x_var = "year", y_var = "id",
#'       agg = "cumcount",
#'       subtitle = "Total responses tracked"
#'     ) %>%
#'     add_sparkline_card(
#'       x_var = "year", y_var = "score",
#'       agg = "mean",
#'       subtitle = "Average satisfaction",
#'       line_color = "#ffffff",
#'       bg_color = "#1f8cff",
#'       text_color = "#ffffff"
#'     ) %>%
#'   end_sparkline_card_row()
#' }
add_sparkline_card <- function(content, x_var, y_var = NULL,
                               value = NULL, subtitle = "",
                               agg = "count",
                               line_color = "#2b74ff", bg_color = "#ffffff",
                               text_color = "#111827", height = 130,
                               smooth = 0.6, area_opacity = 0.18,
                               filter_expr = NULL,
                               value_prefix = "", value_suffix = "",
                               connect_group = NULL,
                               tabgroup = NULL, show_when = NULL) {
  card_spec <- list(
    x_var = x_var,
    y_var = y_var,
    value = value,
    subtitle = subtitle,
    agg = agg,
    line_color = line_color,
    bg_color = bg_color,
    text_color = text_color,
    height = height,
    smooth = smooth,
    area_opacity = area_opacity,
    filter_expr = filter_expr,
    value_prefix = value_prefix,
    value_suffix = value_suffix,
    connect_group = connect_group
  )

  # Check if we're adding to a row container
  if (inherits(content, "sparkline_card_row_container")) {
    content$cards <- c(content$cards, list(card_spec))
    return(content)
  }

  # Standalone card
  block <- structure(
    c(list(type = "sparkline_card", tabgroup = tabgroup, show_when = show_when), card_spec),
    class = "content_block"
  )

  if (inherits(content, "page_object")) {
    content$.items <- c(content$.items, list(block))
    return(content)
  }

  if (!inherits(content, "content_collection")) {
    stop("First argument must be a content_collection, page_object, or sparkline_card_row_container", call. = FALSE)
  }

  insertion_idx <- length(content$items) + 1
  block$.insertion_index <- insertion_idx
  content$items <- c(content$items, list(block))
  content
}

#' Start a sparkline card row
#'
#' Creates a container for sparkline cards displayed side by side.
#'
#' @param content Content collection or page_object
#' @param tabgroup Optional tabgroup
#' @param show_when Optional conditional display formula
#' @keywords internal
#' @export
add_sparkline_card_row <- function(content, tabgroup = NULL, show_when = NULL) {
  if (inherits(content, "page_object")) {
    row_container <- structure(list(
      type = "sparkline_card_row",
      cards = list(),
      tabgroup = tabgroup,
      show_when = show_when,
      .parent_page = content
    ), class = "sparkline_card_row_container")
    return(row_container)
  }

  if (!inherits(content, "content_collection")) {
    stop("First argument must be a content_collection or page_object", call. = FALSE)
  }

  row_container <- structure(list(
    type = "sparkline_card_row",
    cards = list(),
    tabgroup = tabgroup,
    show_when = show_when,
    .parent_content = content
  ), class = "sparkline_card_row_container")
  row_container
}

#' End a sparkline card row
#'
#' Closes a sparkline card row and returns to the parent content.
#'
#' @param row_container Sparkline card row container
#' @keywords internal
#' @export
end_sparkline_card_row <- function(row_container) {
  if (!inherits(row_container, "sparkline_card_row_container")) {
    stop("end_sparkline_card_row() must be called on a sparkline_card_row_container", call. = FALSE)
  }

  row_block <- structure(list(
    type = "sparkline_card_row",
    cards = row_container$cards,
    tabgroup = row_container$tabgroup,
    show_when = row_container$show_when
  ), class = "content_block")

  if (!is.null(row_container$.parent_page)) {
    parent <- row_container$.parent_page
    parent$.items <- c(parent$.items, list(row_block))
    return(parent)
  }
  if (!is.null(row_container$.parent_content)) {
    parent <- row_container$.parent_content
    insertion_idx <- length(parent$items) + 1
    row_block$.insertion_index <- insertion_idx
    parent$items <- c(parent$items, list(row_block))
    return(parent)
  }
  stop("sparkline_card_row_container has no parent", call. = FALSE)
}


# --------------------------------------------------------------------------
# Render functions (called at QMD render time)
# --------------------------------------------------------------------------

#' Aggregate data for sparkline
#' @keywords internal
.sparkline_aggregate <- function(data, x_var, y_var, agg, filter_expr) {
  # Apply filter if provided
  if (!is.null(filter_expr) && nzchar(filter_expr)) {
    data <- data[eval(parse(text = filter_expr), envir = data), , drop = FALSE]
  }

  # Aggregate by x_var
  agg_data <- switch(agg,
    "count" = {
      df <- as.data.frame(table(data[[x_var]]), stringsAsFactors = FALSE)
      names(df) <- c(x_var, ".value")
      df
    },
    "cumcount" = {
      df <- as.data.frame(table(data[[x_var]]), stringsAsFactors = FALSE)
      names(df) <- c(x_var, ".value")
      df$.value <- cumsum(df$.value)
      df
    },
    "sum" = {
      df <- stats::aggregate(
        stats::as.formula(paste0(y_var, " ~ ", x_var)),
        data = data, FUN = sum, na.rm = TRUE
      )
      names(df)[2] <- ".value"
      df
    },
    "cumsum" = {
      df <- stats::aggregate(
        stats::as.formula(paste0(y_var, " ~ ", x_var)),
        data = data, FUN = sum, na.rm = TRUE
      )
      names(df)[2] <- ".value"
      df$.value <- cumsum(df$.value)
      df
    },
    "mean" = {
      df <- stats::aggregate(
        stats::as.formula(paste0(y_var, " ~ ", x_var)),
        data = data, FUN = mean, na.rm = TRUE
      )
      names(df)[2] <- ".value"
      df
    },
    stop("Unknown agg type: ", agg, call. = FALSE)
  )

  # Sort by x_var
  agg_data <- agg_data[order(agg_data[[x_var]]), , drop = FALSE]

  # Convert x_var to character so echarts4r uses a category axis (not value axis)
  agg_data[[x_var]] <- as.character(agg_data[[x_var]])

  agg_data
}

#' Render a sparkline card
#'
#' @param data Data frame (page data)
#' @param x_var X variable name
#' @param y_var Y variable name (NULL for count/cumcount)
#' @param value Main value to display (auto-computed if NULL)
#' @param subtitle Subtitle text
#' @param agg Aggregation: "count", "cumcount", "sum", "cumsum", "mean"
#' @param line_color Line color
#' @param bg_color Background color
#' @param text_color Text color
#' @param height Sparkline height in pixels
#' @param smooth Smoothing factor
#' @param area_opacity Area fill opacity
#' @param filter_expr Optional filter expression string
#' @param value_prefix Prefix for displayed value
#' @param value_suffix Suffix for displayed value
#' @param backend Chart backend
#' @keywords internal
#' @export
render_sparkline_card <- function(data, x_var, y_var = NULL,
                                  value = NULL, subtitle = "",
                                  agg = "count",
                                  line_color = "#2b74ff", bg_color = "#ffffff",
                                  text_color = "#111827", height = 130,
                                  smooth = 0.6, area_opacity = 0.18,
                                  filter_expr = NULL,
                                  value_prefix = "", value_suffix = "",
                                  connect_group = NULL,
                                  backend = "echarts4r") {
  # Aggregate data
  agg_data <- .sparkline_aggregate(data, x_var, y_var, agg, filter_expr)

  # Auto-compute value if not provided
  if (is.null(value)) {
    value <- agg_data$.value[nrow(agg_data)]
  }

  # Format value
  val_display <- if (is.numeric(value)) {
    format(round(value, 1), big.mark = ",", scientific = FALSE)
  } else {
    as.character(value)
  }
  val_display <- paste0(value_prefix, val_display, value_suffix)

  # Create sparkline widget based on backend
  spark_widget <- switch(backend,
    "echarts4r" = .sparkline_echarts(agg_data, x_var, ".value", line_color, height, smooth, area_opacity, connect_group),
    "plotly"    = .sparkline_plotly(agg_data, x_var, ".value", line_color, height, smooth, area_opacity),
    "ggiraph"   = .sparkline_ggiraph(agg_data, x_var, ".value", line_color, height, smooth, area_opacity),
    "highcharter" = .sparkline_highcharter(agg_data, x_var, ".value", line_color, height, smooth, area_opacity),
    stop("Unsupported backend: ", backend, call. = FALSE)
  )

  # Build card HTML using htmltools
  card_html <- htmltools::div(
    class = "sparkline-card",
    style = paste0(
      "border-radius: 18px; ",
      "padding: 18px 18px 10px 18px; ",
      "box-shadow: 0 10px 30px rgba(0,0,0,.12); ",
      "overflow: hidden; ",
      "min-height: 180px; ",
      "background: ", bg_color, "; ",
      "color: ", text_color, ";"
    ),
    htmltools::div(
      class = "sparkline-metric",
      style = "font-weight: 800; font-size: 48px; line-height: 1; margin: 0 0 6px 0;",
      val_display
    ),
    htmltools::div(
      class = "sparkline-subtitle",
      style = "font-size: 18px; opacity: 0.85; margin: 0 0 10px 0;",
      subtitle
    ),
    htmltools::div(
      class = "sparkline-chart",
      style = "margin-top: 6px;",
      spark_widget
    )
  )

  card_html
}

#' Render a row of sparkline cards
#'
#' @param data Data frame (page data)
#' @param cards List of card specifications
#' @param backend Chart backend
#' @keywords internal
#' @export
render_sparkline_card_row <- function(data, cards, backend = "echarts4r") {
  card_widgets <- lapply(cards, function(card) {
    render_sparkline_card(
      data = data,
      x_var = card$x_var,
      y_var = card$y_var,
      value = card$value,
      subtitle = card$subtitle %||% "",
      agg = card$agg %||% "count",
      line_color = card$line_color %||% "#2b74ff",
      bg_color = card$bg_color %||% "#ffffff",
      text_color = card$text_color %||% "#111827",
      height = card$height %||% 130,
      smooth = card$smooth %||% 0.6,
      area_opacity = card$area_opacity %||% 0.18,
      filter_expr = card$filter_expr,
      value_prefix = card$value_prefix %||% "",
      value_suffix = card$value_suffix %||% "",
      connect_group = card$connect_group,
      backend = backend
    )
  })

  # Wrap in a responsive grid
  n_cards <- length(card_widgets)
  grid_cols <- if (n_cards <= 2) {
    paste0("repeat(", n_cards, ", 1fr)")
  } else {
    "repeat(auto-fit, minmax(300px, 1fr))"
  }

  grid_container <- htmltools::div(
    class = "sparkline-card-row",
    style = paste0(
      "display: grid; ",
      "grid-template-columns: ", grid_cols, "; ",
      "gap: 18px; ",
      "align-items: stretch;"
    ),
    card_widgets
  )

  grid_container
}


# --------------------------------------------------------------------------
# Backend-specific sparkline implementations
# --------------------------------------------------------------------------

#' @keywords internal
.sparkline_echarts <- function(data, x_var, y_var, line_color, height, smooth, area_opacity, connect_group = NULL) {
  rlang::check_installed("echarts4r", reason = "to create sparkline charts with echarts4r backend")

  # Boost area opacity for light-colored lines (e.g., white on colored bg)
  rgb_vals <- grDevices::col2rgb(line_color)[, 1]
  is_light <- (rgb_vals[1] * 0.299 + rgb_vals[2] * 0.587 + rgb_vals[3] * 0.114) > 186
  effective_area_opacity <- if (is_light) max(area_opacity, 0.45) else area_opacity
  area_fill <- paste0("rgba(", paste(rgb_vals, collapse = ","), ",", effective_area_opacity, ")")

  # Tooltip formatter: show x value and formatted y value
  tooltip_fmt <- paste0(
    "function(params) {",
    "  if (!params || !params.length) return '';",
    "  var p = params[0];",
    "  var v = Array.isArray(p.value) ? p.value[1] : p.value;",
    "  var x = Array.isArray(p.value) ? p.value[0] : p.name;",
    "  var txt = typeof v === 'number' ? v.toLocaleString(undefined, {maximumFractionDigits: 1}) : v;",
    "  return '<b>' + x + '</b><br/>' + txt;",
    "}"
  )

  e <- data |>
    echarts4r::e_charts_(x_var, height = height, renderer = "canvas") |>
    echarts4r::e_line_(y_var,
      smooth = smooth,
      symbol = "none",
      itemStyle = list(color = line_color),
      lineStyle = list(width = if (is_light) 4 else 3, color = line_color),
      areaStyle = list(opacity = effective_area_opacity, color = area_fill)
    ) |>
    echarts4r::e_color(line_color) |>
    echarts4r::e_x_axis(show = FALSE) |>
    echarts4r::e_y_axis(show = FALSE, min = .echarts_padded_min()) |>
    echarts4r::e_grid(left = 0, right = 0, top = 5, bottom = 0) |>
    echarts4r::e_tooltip(trigger = "axis", formatter = htmlwidgets::JS(tooltip_fmt)) |>
    echarts4r::e_animation(duration = 400) |>
    echarts4r::e_legend(show = FALSE)

  # Link tooltips across sparkline cards in the same group
  if (!is.null(connect_group)) {
    e <- e |> echarts4r::e_connect_group(connect_group)
  }

  e
}

#' @keywords internal
.sparkline_plotly <- function(data, x_var, y_var, line_color, height, smooth, area_opacity) {
  rlang::check_installed("plotly", reason = "to create sparkline charts with plotly backend")

  x_vals <- data[[x_var]]
  y_vals <- data[[y_var]]

  fill_color <- paste0("rgba(",
    paste(grDevices::col2rgb(line_color), collapse = ","),
    ",", area_opacity, ")")

  p <- plotly::plot_ly(
    x = x_vals, y = y_vals,
    type = "scatter", mode = "lines",
    line = list(color = line_color, width = 3,
                shape = if (smooth > 0.3) "spline" else "linear"),
    fill = "tozeroy",
    fillcolor = fill_color,
    hoverinfo = "x+y"
  ) |>
    plotly::layout(
      xaxis = list(visible = FALSE, showgrid = FALSE),
      yaxis = list(visible = FALSE, showgrid = FALSE),
      margin = list(l = 0, r = 0, t = 5, b = 0),
      height = height,
      showlegend = FALSE,
      paper_bgcolor = "rgba(0,0,0,0)",
      plot_bgcolor = "rgba(0,0,0,0)"
    ) |>
    plotly::config(displayModeBar = FALSE)

  p
}

#' @keywords internal
.sparkline_ggiraph <- function(data, x_var, y_var, line_color, height, smooth, area_opacity) {
  rlang::check_installed("ggiraph", reason = "to create sparkline charts with ggiraph backend")
  rlang::check_installed("ggplot2", reason = "to create sparkline charts with ggiraph backend")

  fill_color <- grDevices::adjustcolor(line_color, alpha.f = area_opacity)

  p <- ggplot2::ggplot(data, ggplot2::aes(x = .data[[x_var]], y = .data[[y_var]])) +
    ggplot2::geom_area(fill = fill_color) +
    ggplot2::geom_line(color = line_color, linewidth = 1) +
    ggplot2::theme_void() +
    ggplot2::theme(
      plot.margin = ggplot2::margin(5, 0, 0, 0),
      panel.background = ggplot2::element_rect(fill = "transparent", color = NA),
      plot.background = ggplot2::element_rect(fill = "transparent", color = NA)
    )

  ggiraph::girafe(
    ggobj = p,
    width_svg = 6,
    height_svg = height / 72
  )
}

#' @keywords internal
.sparkline_highcharter <- function(data, x_var, y_var, line_color, height, smooth, area_opacity) {
  rlang::check_installed("highcharter", reason = "to create sparkline charts with highcharter backend")

  x_vals <- data[[x_var]]
  y_vals <- data[[y_var]]

  if (inherits(x_vals, "Date") || inherits(x_vals, "POSIXt")) {
    ts_data <- lapply(seq_along(x_vals), function(i) {
      list(highcharter::datetime_to_timestamp(x_vals[i]), y_vals[i])
    })
    hc <- highcharter::highchart() |>
      highcharter::hc_chart(type = "areaspline", height = height) |>
      highcharter::hc_add_series(data = ts_data, color = line_color,
                                  fillOpacity = area_opacity,
                                  marker = list(enabled = FALSE),
                                  lineWidth = 3)
  } else {
    hc <- highcharter::highchart() |>
      highcharter::hc_chart(type = "areaspline", height = height) |>
      highcharter::hc_add_series(data = y_vals, color = line_color,
                                  fillOpacity = area_opacity,
                                  marker = list(enabled = FALSE),
                                  lineWidth = 3)
  }

  hc |>
    highcharter::hc_xAxis(visible = FALSE) |>
    highcharter::hc_yAxis(visible = FALSE) |>
    highcharter::hc_legend(enabled = FALSE) |>
    highcharter::hc_tooltip(enabled = TRUE) |>
    highcharter::hc_plotOptions(series = list(animation = list(duration = 400))) |>
    highcharter::hc_chart(
      spacing = c(5, 0, 0, 0),
      backgroundColor = "transparent"
    )
}
