# =================================================================
# Waffle Chart Visualization
# =================================================================

#' Create a Waffle Chart
#'
#' Creates an interactive waffle (square pie) chart using highcharter.
#' Waffle charts display proportional data as a grid of colored squares,
#' providing an intuitive alternative to pie charts.
#'
#' @param data A data frame containing the data.
#' @param x_var Character string. Name of the categorical variable (category labels).
#' @param y_var Optional character string. Name of a numeric column with pre-aggregated
#'   values (counts or percentages). If NULL, counts are computed from the data.
#' @param title Optional main title for the chart.
#' @param subtitle Optional subtitle for the chart.
#' @param total Numeric. Total number of squares in the waffle grid. Default 100.
#'   Each square represents \code{total_value / total} of the data.
#' @param rows Numeric. Number of rows in the waffle grid. Default 10.
#' @param color_palette Optional character vector of colors for the categories.
#' @param x_order Optional character vector specifying the order of categories.
#' @param data_labels_enabled Logical. If TRUE, show category labels. Default FALSE
#'   (legend is shown instead).
#' @param show_in_legend Logical. If TRUE (default), show a legend.
#' @param weight_var Optional character string. Name of weight variable.
#' @param border_color Character string. Color of the square borders. Default "white".
#' @param border_width Numeric. Width of square borders in pixels. Default 1.
#' @param tooltip A tooltip configuration created with \code{\link{tooltip}()}.
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
#'   category = c("Agree", "Neutral", "Disagree"),
#'   count = c(45, 30, 25)
#' )
#' viz_waffle(df, x_var = "category", y_var = "count",
#'            title = "Survey Responses", total = 100)
#' }
#' @export
viz_waffle <- function(data,
                       x_var,
                       y_var = NULL,
                       title = NULL,
                       subtitle = NULL,
                       total = 100,
                       rows = 10,
                       color_palette = NULL,
                       x_order = NULL,
                       data_labels_enabled = FALSE,
                       show_in_legend = TRUE,
                       weight_var = NULL,
                       border_color = "white",
                       border_width = 1,
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
    .stop_with_hint("x_var", example = 'viz_waffle(data, x_var = "category")')
  }

  if (!x_var %in% names(data)) {
    stop(paste0("Column '", x_var, "' not found in data."), call. = FALSE)
  }

  if (!is.null(y_var) && !y_var %in% names(data)) {
    stop(paste0("Column '", y_var, "' not found in data."), call. = FALSE)
  }

  # Prepare & aggregate data
  plot_data <- data %>%
    dplyr::select(dplyr::all_of(c(x_var, y_var, weight_var))) %>%
    dplyr::filter(!is.na(!!rlang::sym(x_var)))

  # Handle haven_labelled
  if (requireNamespace("haven", quietly = TRUE)) {
    if (inherits(plot_data[[x_var]], "haven_labelled")) {
      plot_data <- plot_data %>%
        dplyr::mutate(!!rlang::sym(x_var) := haven::as_factor(!!rlang::sym(x_var), levels = "labels"))
    }
  }

  # Aggregate
  if (!is.null(y_var)) {
    agg_data <- plot_data %>%
      dplyr::mutate(name = as.character(!!rlang::sym(x_var)),
                    value = !!rlang::sym(y_var))
  } else if (!is.null(weight_var)) {
    agg_data <- plot_data %>%
      dplyr::count(!!rlang::sym(x_var), wt = !!rlang::sym(weight_var), name = "value") %>%
      dplyr::mutate(name = as.character(!!rlang::sym(x_var)))
  } else {
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

  # Compute proportions and number of squares per category
  total_value <- sum(agg_data$value, na.rm = TRUE)
  agg_data <- agg_data %>%
    dplyr::mutate(
      proportion = value / total_value,
      squares = round(proportion * total)
    )

  # Adjust rounding to ensure squares sum to total
  diff <- total - sum(agg_data$squares)
  if (diff != 0) {
    # Add/subtract from the largest category
    idx <- which.max(agg_data$squares)
    agg_data$squares[idx] <- agg_data$squares[idx] + diff
  }

  # Compute grid dimensions
  cols <- ceiling(total / rows)

  # Build waffle grid data: each square is a cell in a rows x cols grid
  waffle_data <- list()
  square_idx <- 0
  for (cat_i in seq_len(nrow(agg_data))) {
    n_squares <- agg_data$squares[cat_i]
    for (s in seq_len(n_squares)) {
      col_pos <- square_idx %% cols
      row_pos <- rows - 1 - (square_idx %/% cols)
      waffle_data[[length(waffle_data) + 1]] <- list(
        x = col_pos,
        y = row_pos,
        value = cat_i,
        name = agg_data$name[cat_i],
        count = agg_data$value[cat_i],
        pct = round(agg_data$proportion[cat_i] * 100, 1)
      )
      square_idx <- square_idx + 1
    }
  }

  # Build config for backend dispatch
  config <- list(
    title = title, subtitle = subtitle,
    total = total, rows = rows, cols = cols,
    color_palette = color_palette, x_order = x_order,
    data_labels_enabled = data_labels_enabled,
    show_in_legend = show_in_legend,
    border_color = border_color, border_width = border_width,
    tooltip = tooltip, tooltip_prefix = tooltip_prefix,
    tooltip_suffix = tooltip_suffix, height = height,
    waffle_data = waffle_data
  )

  # Dispatch to backend renderer
  backend <- .normalize_backend(backend)
  backend <- match.arg(backend, c("highcharter", "plotly", "echarts4r", "ggiraph"))
  .assert_backend_supported("waffle", backend)
  render_fn <- switch(backend,
    highcharter = .viz_waffle_highcharter,
    plotly      = .viz_waffle_plotly,
    echarts4r   = .viz_waffle_echarts,
    ggiraph     = .viz_waffle_ggiraph
  )
  result <- render_fn(agg_data, config)
  result <- .register_chart_widget(result, backend = backend)
  return(result)
}

# --- Highcharter backend (original implementation) ---
#' @keywords internal
.viz_waffle_highcharter <- function(agg_data, config) {
  # Unpack config
  title <- config$title; subtitle <- config$subtitle
  total <- config$total; rows <- config$rows; cols <- config$cols
  color_palette <- config$color_palette
  show_in_legend <- config$show_in_legend
  border_color <- config$border_color; border_width <- config$border_width
  tooltip <- config$tooltip; tooltip_prefix <- config$tooltip_prefix
  tooltip_suffix <- config$tooltip_suffix; height <- config$height
  waffle_data <- config$waffle_data

  # Build color stops
  categories <- agg_data$name
  n_cats <- length(categories)

  if (!is.null(color_palette)) {
    colors <- color_palette
  } else {
    # Default Highcharts-like palette
    colors <- c("#4E79A7", "#F28E2B", "#E15759", "#76B7B2", "#59A14F",
                "#EDC948", "#B07AA1", "#FF9DA7", "#9C755F", "#BAB0AC")
  }

  # Build colorAxis stops (one color per category)
  color_stops <- lapply(seq_len(n_cats), function(i) {
    list((i - 0.5) / n_cats, colors[((i - 1) %% length(colors)) + 1])
  })

  hc <- highcharter::highchart() %>%
    highcharter::hc_chart(type = "heatmap", height = height) %>%
    highcharter::hc_add_series(
      data = waffle_data,
      borderColor = border_color,
      borderWidth = border_width,
      dataLabels = list(enabled = FALSE),
      colsize = 1,
      rowsize = 1
    ) %>%
    highcharter::hc_xAxis(
      visible = FALSE,
      min = -0.5,
      max = cols - 0.5
    ) %>%
    highcharter::hc_yAxis(
      visible = FALSE,
      min = -0.5,
      max = rows - 0.5
    ) %>%
    highcharter::hc_colorAxis(
      min = 0.5,
      max = n_cats + 0.5,
      dataClasses = lapply(seq_len(n_cats), function(i) {
        list(
          from = i - 0.5,
          to = i + 0.5,
          color = colors[((i - 1) %% length(colors)) + 1],
          name = categories[i]
        )
      })
    ) %>%
    highcharter::hc_legend(
      enabled = show_in_legend,
      layout = "horizontal",
      align = "center",
      verticalAlign = "bottom"
    ) %>%
    highcharter::hc_plotOptions(
      heatmap = list(
        borderRadius = 2,
        pointPadding = 1
      )
    )

  # Title & subtitle
  if (!is.null(title)) hc <- hc %>% highcharter::hc_title(text = title)
  if (!is.null(subtitle)) hc <- hc %>% highcharter::hc_subtitle(text = subtitle)

  # Tooltip
  if (!is.null(tooltip)) {
    tooltip_result <- .process_tooltip_config(
      tooltip = tooltip,
      tooltip_prefix = tooltip_prefix,
      tooltip_suffix = tooltip_suffix,
      x_tooltip_suffix = NULL,
      chart_type = "waffle",
      context = list()
    )
    hc <- .apply_tooltip_to_hc(hc, tooltip_result)
  } else {
    pre <- if (is.null(tooltip_prefix) || tooltip_prefix == "") "" else tooltip_prefix
    suf <- if (is.null(tooltip_suffix) || tooltip_suffix == "") "" else tooltip_suffix

    tooltip_fn <- sprintf(
      "function() {
         return '<b>' + this.point.name + '</b><br/>' +
                '%s' + this.point.count.toLocaleString() + '%s<br/>' +
                '<span style=\"color:#666;font-size:0.9em\">' +
                this.point.pct + '%% of total</span>';
       }",
      pre, suf
    )
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
.viz_waffle_plotly <- function(agg_data, config) {
  rlang::check_installed("plotly", reason = "to use backend = 'plotly'")

  title <- config$title
  total <- config$total; rows <- config$rows; cols <- config$cols
  color_palette <- config$color_palette
  show_in_legend <- config$show_in_legend
  height <- config$height

  # Default colors
  if (!is.null(color_palette)) {
    colors <- color_palette
  } else {
    colors <- c("#4E79A7", "#F28E2B", "#E15759", "#76B7B2", "#59A14F",
                "#EDC948", "#B07AA1", "#FF9DA7", "#9C755F", "#BAB0AC")
  }

  # Build grid data frame
  grid_rows <- list()
  square_idx <- 0
  for (cat_i in seq_len(nrow(agg_data))) {
    n_squares <- agg_data$squares[cat_i]
    cat_color <- colors[((cat_i - 1) %% length(colors)) + 1]
    for (s in seq_len(n_squares)) {
      col_pos <- square_idx %% cols
      row_pos <- rows - 1 - (square_idx %/% cols)
      grid_rows[[length(grid_rows) + 1]] <- data.frame(
        x = col_pos, y = row_pos,
        category = agg_data$name[cat_i],
        color = cat_color,
        count = agg_data$value[cat_i],
        pct = round(agg_data$proportion[cat_i] * 100, 1),
        stringsAsFactors = FALSE
      )
      square_idx <- square_idx + 1
    }
  }
  grid_df <- do.call(rbind, grid_rows)

  # Build hover text
  grid_df$hover <- paste0(
    "<b>", grid_df$category, "</b><br>",
    "Count: ", grid_df$count, "<br>",
    grid_df$pct, "% of total"
  )

  p <- plotly::plot_ly(
    data = grid_df,
    x = ~x, y = ~y,
    color = ~category,
    colors = colors[seq_len(nrow(agg_data))],
    text = ~hover,
    hoverinfo = "text",
    type = "scatter",
    mode = "markers",
    marker = list(
      symbol = "square",
      size = max(8, min(30, 300 / max(rows, cols))),
      line = list(width = 0.5, color = "white")
    )
  )

  p <- plotly::layout(p,
    title = title,
    xaxis = list(visible = FALSE, scaleanchor = "y"),
    yaxis = list(visible = FALSE),
    showlegend = show_in_legend,
    height = height
  )

  p
}

# --- echarts4r backend ---
#' @keywords internal
.viz_waffle_echarts <- function(agg_data, config) {
  stop("backend = 'echarts4r' is not supported for viz_waffle(). ",
       "echarts4r does not have a native waffle chart type. ",
       "Use backend = 'highcharter', 'plotly', or 'ggiraph' instead.",
       call. = FALSE)
}

# --- ggiraph backend ---
#' @keywords internal
.viz_waffle_ggiraph <- function(agg_data, config) {
  rlang::check_installed("ggiraph", reason = "to use backend = 'ggiraph'")
  rlang::check_installed("ggplot2", reason = "to use backend = 'ggiraph'")

  title <- config$title; subtitle <- config$subtitle
  total <- config$total; rows <- config$rows; cols <- config$cols
  color_palette <- config$color_palette
  show_in_legend <- config$show_in_legend
  height <- config$height

  # Default colors
  if (!is.null(color_palette)) {
    colors <- color_palette
  } else {
    colors <- c("#4E79A7", "#F28E2B", "#E15759", "#76B7B2", "#59A14F",
                "#EDC948", "#B07AA1", "#FF9DA7", "#9C755F", "#BAB0AC")
  }

  # Build grid data
  grid_rows <- list()
  square_idx <- 0
  for (cat_i in seq_len(nrow(agg_data))) {
    n_squares <- agg_data$squares[cat_i]
    for (s in seq_len(n_squares)) {
      col_pos <- square_idx %% cols
      row_pos <- rows - 1 - (square_idx %/% cols)
      grid_rows[[length(grid_rows) + 1]] <- data.frame(
        x = col_pos, y = row_pos,
        category = agg_data$name[cat_i],
        count = agg_data$value[cat_i],
        pct = round(agg_data$proportion[cat_i] * 100, 1),
        stringsAsFactors = FALSE
      )
      square_idx <- square_idx + 1
    }
  }
  grid_df <- do.call(rbind, grid_rows)

  grid_df$category <- factor(grid_df$category, levels = agg_data$name)
  grid_df$.tooltip <- paste0(
    grid_df$category, ": ", grid_df$count,
    " (", grid_df$pct, "%)"
  )

  p <- ggplot2::ggplot(grid_df, ggplot2::aes(
    x = .data$x, y = .data$y, fill = .data$category
  )) +
    ggiraph::geom_tile_interactive(
      ggplot2::aes(tooltip = .data$.tooltip, data_id = .data$category),
      width = 0.9, height = 0.9
    ) +
    ggplot2::scale_fill_manual(values = colors[seq_len(nrow(agg_data))]) +
    ggplot2::coord_equal() +
    ggplot2::labs(title = title, subtitle = subtitle, fill = NULL) +
    ggplot2::theme_void() +
    ggplot2::theme(
      legend.position = if (show_in_legend) "bottom" else "none"
    )

  ggiraph::girafe(ggobj = p)
}
