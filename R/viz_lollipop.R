# =================================================================
# Lollipop Chart Visualization
# =================================================================

#' Create a Lollipop Chart
#'
#' Creates an interactive lollipop chart using highcharter. A lollipop chart
#' is a bar chart variant that uses a line (stem) and dot instead of a full bar,
#' making it easier to read when there are many categories.
#'
#' @param data A data frame containing the data.
#' @param x_var Character string. Name of the categorical variable for the axis.
#' @param y_var Optional character string. Name of a numeric column with pre-aggregated
#'   values. When provided, skips counting and uses these values directly.
#' @param group_var Optional character string. Name of grouping variable for separate
#'   series (creates multiple dots per category).
#' @param value_var Optional character string. Name of a numeric variable to aggregate
#'   (shows mean per category instead of counts).
#' @param title Optional main title for the chart.
#' @param subtitle Optional subtitle for the chart.
#' @param x_label Optional label for the category axis.
#' @param y_label Optional label for the value axis.
#' @param horizontal Logical. If TRUE (default), creates horizontal lollipops.
#' @param bar_type Character string. "count" (default), "percent", or "mean".
#' @param color_palette Optional character vector of colors.
#' @param x_order Optional character vector specifying the order of categories.
#' @param group_order Optional character vector specifying the order of groups.
#' @param sort_by_value Logical. If TRUE, sort categories by value. Default FALSE.
#' @param sort_desc Logical. Sort direction when sort_by_value = TRUE. Default TRUE.
#' @param weight_var Optional character string. Name of weight variable.
#' @param dot_size Numeric. Size of the dots in pixels. Default 8.
#' @param stem_width Numeric. Width of the stem lines in pixels. Default 2.
#' @param data_labels_enabled Logical. If TRUE (default), show value labels.
#' @param label_decimals Optional integer. Number of decimal places for data labels.
#'   When NULL (default), uses smart defaults: 0 for counts, 1 for percent.
#'   Set explicitly to override (e.g., `label_decimals = 2`).
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
#' # Simple lollipop chart
#' viz_lollipop(mtcars, x_var = "cyl", title = "Cars by Cylinders")
#'
#' # Horizontal with pre-aggregated data
#' df <- data.frame(country = c("US", "UK", "DE"), score = c(85, 72, 68))
#' viz_lollipop(df, x_var = "country", y_var = "score", horizontal = TRUE)
#' }
#' @export
viz_lollipop <- function(data,
                         x_var,
                         y_var = NULL,
                         group_var = NULL,
                         value_var = NULL,
                         title = NULL,
                         subtitle = NULL,
                         x_label = NULL,
                         y_label = NULL,
                         horizontal = TRUE,
                         bar_type = "count",
                         color_palette = NULL,
                         x_order = NULL,
                         group_order = NULL,
                         sort_by_value = FALSE,
                         sort_desc = TRUE,
                         weight_var = NULL,
                         dot_size = 8,
                         stem_width = 2,
                         data_labels_enabled = TRUE,
                         label_decimals = NULL,
                         tooltip = NULL,
                         tooltip_prefix = "",
                         tooltip_suffix = "",
                         backend = "highcharter") {

  # Convert variable arguments to strings
  x_var <- .as_var_string(rlang::enquo(x_var))
  y_var <- .as_var_string(rlang::enquo(y_var))
  group_var <- .as_var_string(rlang::enquo(group_var))
  value_var <- .as_var_string(rlang::enquo(value_var))
  weight_var <- .as_var_string(rlang::enquo(weight_var))

  # Input validation
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }

  if (is.null(x_var)) {
    .stop_with_hint("x_var", example = 'viz_lollipop(data, x_var = "category")')
  }

  if (!x_var %in% names(data)) {
    stop(paste0("Column '", x_var, "' not found in data."), call. = FALSE)
  }

  if (!is.null(y_var) && !y_var %in% names(data)) {
    stop(paste0("Column '", y_var, "' not found in data."), call. = FALSE)
  }

  if (!is.null(group_var) && !group_var %in% names(data)) {
    stop(paste0("Column '", group_var, "' not found in data."), call. = FALSE)
  }

  if (!is.null(value_var) && !value_var %in% names(data)) {
    stop(paste0("Column '", value_var, "' not found in data."), call. = FALSE)
  }

  # If value_var is provided, switch to mean mode
  if (!is.null(value_var) && bar_type == "count") {
    bar_type <- "mean"
  }

  # Select relevant variables
  vars_to_select <- x_var
  if (!is.null(y_var)) vars_to_select <- c(vars_to_select, y_var)
  if (!is.null(group_var)) vars_to_select <- c(vars_to_select, group_var)
  if (!is.null(value_var)) vars_to_select <- c(vars_to_select, value_var)
  if (!is.null(weight_var)) vars_to_select <- c(vars_to_select, weight_var)

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

  # Apply ordering
  if (!is.null(x_order)) {
    plot_data <- plot_data %>%
      dplyr::mutate(!!rlang::sym(x_var) := factor(!!rlang::sym(x_var), levels = x_order))
  }
  if (!is.null(group_var) && !is.null(group_order)) {
    plot_data <- plot_data %>%
      dplyr::mutate(!!rlang::sym(group_var) := factor(!!rlang::sym(group_var), levels = group_order))
  }

  # Aggregate data
  if (!is.null(y_var)) {
    # Pre-aggregated
    agg_data <- plot_data %>%
      dplyr::rename(value = !!rlang::sym(y_var))
  } else if (bar_type == "mean" && !is.null(value_var)) {
    # Mean aggregation
    if (is.null(group_var)) {
      agg_data <- plot_data %>%
        dplyr::group_by(!!rlang::sym(x_var)) %>%
        dplyr::summarize(value = round(mean(!!rlang::sym(value_var), na.rm = TRUE), 2),
                         .groups = "drop")
    } else {
      agg_data <- plot_data %>%
        dplyr::group_by(!!rlang::sym(x_var), !!rlang::sym(group_var)) %>%
        dplyr::summarize(value = round(mean(!!rlang::sym(value_var), na.rm = TRUE), 2),
                         .groups = "drop")
    }
  } else {
    # Count aggregation
    if (is.null(group_var)) {
      if (!is.null(weight_var)) {
        agg_data <- plot_data %>%
          dplyr::count(!!rlang::sym(x_var), wt = !!rlang::sym(weight_var), name = "count")
      } else {
        agg_data <- plot_data %>%
          dplyr::count(!!rlang::sym(x_var), name = "count")
      }
      if (bar_type == "percent") {
        agg_data <- agg_data %>%
          dplyr::mutate(value = round(count / sum(count) * 100, 1))
      } else {
        agg_data <- agg_data %>%
          dplyr::mutate(value = count)
      }
    } else {
      if (!is.null(weight_var)) {
        agg_data <- plot_data %>%
          dplyr::count(!!rlang::sym(x_var), !!rlang::sym(group_var),
                       wt = !!rlang::sym(weight_var), name = "count")
      } else {
        agg_data <- plot_data %>%
          dplyr::count(!!rlang::sym(x_var), !!rlang::sym(group_var), name = "count")
      }
      if (bar_type == "percent") {
        agg_data <- agg_data %>%
          dplyr::group_by(!!rlang::sym(x_var)) %>%
          dplyr::mutate(value = round(count / sum(count) * 100, 1)) %>%
          dplyr::ungroup()
      } else {
        agg_data <- agg_data %>%
          dplyr::mutate(value = count)
      }
    }
  }

  # Sort by value
  if (isTRUE(sort_by_value) && is.null(group_var)) {
    agg_data <- agg_data %>%
      dplyr::arrange(if (sort_desc) dplyr::desc(value) else value) %>%
      dplyr::mutate(!!rlang::sym(x_var) := factor(!!rlang::sym(x_var),
                                                    levels = !!rlang::sym(x_var)))
  }

  # Set up axis labels
  final_x_label <- x_label %||% x_var
  final_y_label <- y_label %||% switch(bar_type,
    "percent" = "Percentage",
    "mean" = paste0("Mean ", value_var),
    "Count"
  )

  # Get categories
  x_categories <- if (is.factor(agg_data[[x_var]])) {
    levels(agg_data[[x_var]])
  } else {
    as.character(unique(agg_data[[x_var]]))
  }

  # Build config for backend dispatch
  config <- list(
    title = title, subtitle = subtitle,
    x_label = final_x_label, y_label = final_y_label,
    horizontal = horizontal, bar_type = bar_type,
    color_palette = color_palette, group_var = group_var,
    group_order = group_order, x_var = x_var,
    x_categories = x_categories,
    dot_size = dot_size, stem_width = stem_width,
    data_labels_enabled = data_labels_enabled,
    label_decimals = label_decimals,
    tooltip = tooltip, tooltip_prefix = tooltip_prefix,
    tooltip_suffix = tooltip_suffix,
    value_var = value_var
  )

  # Dispatch to backend renderer
  backend <- .normalize_backend(backend)
  backend <- match.arg(backend, c("highcharter", "plotly", "echarts4r", "ggiraph"))
  .assert_backend_supported("lollipop", backend)
  render_fn <- switch(backend,
    highcharter = .viz_lollipop_highcharter,
    plotly      = .viz_lollipop_plotly,
    echarts4r   = .viz_lollipop_echarts,
    ggiraph     = .viz_lollipop_ggiraph
  )
  result <- render_fn(agg_data, config)
  result <- .register_chart_widget(result, backend = backend)
  return(result)
}

# --- Highcharter backend (original implementation) ---
#' @keywords internal
.viz_lollipop_highcharter <- function(agg_data, config) {
  # Unpack config
  title <- config$title; subtitle <- config$subtitle
  final_x_label <- config$x_label; final_y_label <- config$y_label
  horizontal <- config$horizontal; bar_type <- config$bar_type
  color_palette <- config$color_palette; group_var <- config$group_var
  group_order <- config$group_order; x_var <- config$x_var
  x_categories <- config$x_categories
  dot_size <- config$dot_size; stem_width <- config$stem_width
  data_labels_enabled <- config$data_labels_enabled
  label_decimals <- config$label_decimals
  tooltip <- config$tooltip; tooltip_prefix <- config$tooltip_prefix
  tooltip_suffix <- config$tooltip_suffix

  # Create chart - lollipop is a line chart with markers and lineWidth=0 stems
  # We use a combination approach: scatter for dots + column with very thin width for stems
  hc <- highcharter::highchart()

  if (!is.null(title)) hc <- hc %>% highcharter::hc_title(text = title)
  if (!is.null(subtitle)) hc <- hc %>% highcharter::hc_subtitle(text = subtitle)

  # Configure axes
  chart_type <- if (horizontal) "bar" else "column"

  hc <- hc %>%
    highcharter::hc_chart(type = chart_type) %>%
    highcharter::hc_xAxis(
      categories = x_categories,
      title = list(text = final_x_label)
    ) %>%
    highcharter::hc_yAxis(title = list(text = final_y_label))

  # Resolve data label format
  if (!is.null(label_decimals)) {
    dec <- as.integer(label_decimals)
    lollipop_label_fmt <- if (bar_type == "percent") {
      sprintf("{point.y:.%df}%%", dec)
    } else {
      sprintf("{point.y:.%df}", dec)
    }
  } else {
    lollipop_label_fmt <- if (bar_type == "percent") "{point.y:.1f}%" else "{point.y:.0f}"
  }

  # Add series - use column type with very narrow pointWidth for stems,
  # and overlay with marker-only series for dots
  if (is.null(group_var)) {
    series_data <- agg_data %>%
      dplyr::arrange(match(as.character(!!rlang::sym(x_var)), x_categories)) %>%
      dplyr::pull(value)

    # Stem series (thin bars)
    hc <- hc %>%
      highcharter::hc_add_series(
        name = final_y_label,
        data = series_data,
        type = chart_type,
        pointWidth = stem_width,
        showInLegend = FALSE,
        colorByPoint = TRUE,
        dataLabels = list(enabled = FALSE)
      )

    # Dot series (scatter overlay)
    dot_data <- lapply(seq_along(series_data), function(i) {
      list(x = i - 1, y = series_data[i])
    })

    hc <- hc %>%
      highcharter::hc_add_series(
        name = final_y_label,
        data = dot_data,
        type = "scatter",
        showInLegend = FALSE,
        marker = list(
          radius = dot_size / 2,
          symbol = "circle"
        ),
        colorByPoint = TRUE,
        dataLabels = list(
          enabled = data_labels_enabled,
          format = lollipop_label_fmt
        )
      )

    if (!is.null(color_palette)) {
      hc <- hc %>% highcharter::hc_colors(color_palette)
    }
  } else {
    # Grouped lollipops
    group_levels <- if (!is.null(group_order)) {
      group_order
    } else {
      unique(agg_data[[group_var]])
    }

    for (i in seq_along(group_levels)) {
      grp <- group_levels[i]
      grp_data <- agg_data %>%
        dplyr::filter(!!rlang::sym(group_var) == grp) %>%
        dplyr::arrange(match(as.character(!!rlang::sym(x_var)), x_categories)) %>%
        dplyr::pull(value)

      # Stem
      hc <- hc %>%
        highcharter::hc_add_series(
          name = as.character(grp),
          data = grp_data,
          type = chart_type,
          pointWidth = stem_width,
          showInLegend = FALSE,
          dataLabels = list(enabled = FALSE)
        )
    }

    # Dots for each group
    for (i in seq_along(group_levels)) {
      grp <- group_levels[i]
      grp_data <- agg_data %>%
        dplyr::filter(!!rlang::sym(group_var) == grp) %>%
        dplyr::arrange(match(as.character(!!rlang::sym(x_var)), x_categories)) %>%
        dplyr::pull(value)

      dot_data <- lapply(seq_along(grp_data), function(j) {
        list(x = j - 1, y = grp_data[j])
      })

      hc <- hc %>%
        highcharter::hc_add_series(
          name = as.character(grp),
          data = dot_data,
          type = "scatter",
          marker = list(radius = dot_size / 2, symbol = "circle"),
          dataLabels = list(
            enabled = data_labels_enabled,
            format = lollipop_label_fmt
          )
        )
    }

    if (!is.null(color_palette)) {
      hc <- hc %>% highcharter::hc_colors(color_palette)
    }
  }

  # Tooltip
  if (!is.null(tooltip)) {
    tooltip_result <- .process_tooltip_config(
      tooltip = tooltip,
      tooltip_prefix = tooltip_prefix,
      tooltip_suffix = tooltip_suffix,
      x_tooltip_suffix = NULL,
      chart_type = "lollipop",
      context = list(bar_type = bar_type, x_label = final_x_label, y_label = final_y_label)
    )
    hc <- .apply_tooltip_to_hc(hc, tooltip_result)
  } else {
    pre <- if (is.null(tooltip_prefix) || tooltip_prefix == "") "" else tooltip_prefix
    suf <- if (is.null(tooltip_suffix) || tooltip_suffix == "") "" else tooltip_suffix

    tooltip_fn <- sprintf(
      "function() {
         var cat = this.point.category || this.series.chart.xAxis[0].categories[this.point.x] || this.x;
         return '<b>' + cat + '</b><br/>' +
                '%s' + this.y.toLocaleString() + '%s';
       }",
      pre, suf
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
.viz_lollipop_plotly <- function(agg_data, config) {
  rlang::check_installed("plotly", reason = "to use backend = 'plotly'")

  x_var <- config$x_var
  group_var <- config$group_var
  group_order <- config$group_order
  horizontal <- config$horizontal
  bar_type <- config$bar_type
  color_palette <- config$color_palette
  title <- config$title
  final_x_label <- config$x_label
  final_y_label <- config$y_label
  dot_size <- config$dot_size
  stem_width <- config$stem_width

  if (is.null(group_var)) {
    cats <- as.character(agg_data[[x_var]])
    vals <- agg_data$value

    if (horizontal) {
      p <- plotly::plot_ly() |>
        plotly::add_segments(
          x = rep(0, length(vals)), xend = vals,
          y = cats, yend = cats,
          line = list(width = stem_width, color = "#999"),
          showlegend = FALSE
        ) |>
        plotly::add_markers(
          x = vals, y = cats,
          marker = list(size = dot_size),
          name = final_y_label
        )
    } else {
      p <- plotly::plot_ly() |>
        plotly::add_segments(
          x = cats, xend = cats,
          y = rep(0, length(vals)), yend = vals,
          line = list(width = stem_width, color = "#999"),
          showlegend = FALSE
        ) |>
        plotly::add_markers(
          x = cats, y = vals,
          marker = list(size = dot_size),
          name = final_y_label
        )
    }

    if (!is.null(color_palette)) {
      p <- plotly::layout(p, colorway = color_palette)
    }
  } else {
    group_levels <- if (!is.null(group_order)) group_order else unique(agg_data[[group_var]])
    p <- plotly::plot_ly()

    for (grp in group_levels) {
      grp_data <- agg_data[agg_data[[group_var]] == grp, ]
      cats <- as.character(grp_data[[x_var]])
      vals <- grp_data$value

      if (horizontal) {
        p <- p |>
          plotly::add_segments(
            x = rep(0, length(vals)), xend = vals,
            y = cats, yend = cats,
            line = list(width = stem_width),
            showlegend = FALSE
          ) |>
          plotly::add_markers(
            x = vals, y = cats,
            marker = list(size = dot_size),
            name = as.character(grp)
          )
      } else {
        p <- p |>
          plotly::add_segments(
            x = cats, xend = cats,
            y = rep(0, length(vals)), yend = vals,
            line = list(width = stem_width),
            showlegend = FALSE
          ) |>
          plotly::add_markers(
            x = cats, y = vals,
            marker = list(size = dot_size),
            name = as.character(grp)
          )
      }
    }

    if (!is.null(color_palette)) {
      p <- plotly::layout(p, colorway = color_palette)
    }
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
.viz_lollipop_echarts <- function(agg_data, config) {
  rlang::check_installed("echarts4r", reason = "to use backend = 'echarts4r'")

  x_var <- config$x_var
  group_var <- config$group_var
  horizontal <- config$horizontal
  color_palette <- config$color_palette
  title <- config$title
  subtitle <- config$subtitle
  final_x_label <- config$x_label
  final_y_label <- config$y_label
  dot_size <- config$dot_size

  # Ensure x variable is character for echart categories
  agg_data[[x_var]] <- as.character(agg_data[[x_var]])

  if (is.null(group_var)) {
    # Use scatter type for lollipop dots with custom rendering
    e <- agg_data |>
      echarts4r::e_charts_(x_var) |>
      echarts4r::e_bar_("value", name = final_y_label, barWidth = 2) |>
      echarts4r::e_scatter_("value", name = final_y_label,
                             symbol_size = dot_size, legend = FALSE)
  } else {
    agg_data[[group_var]] <- as.character(agg_data[[group_var]])
    e <- agg_data |>
      dplyr::group_by(.data[[group_var]]) |>
      echarts4r::e_charts_(x_var) |>
      echarts4r::e_bar_("value", barWidth = 2) |>
      echarts4r::e_scatter_("value", symbol_size = dot_size, legend = FALSE)
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
.viz_lollipop_ggiraph <- function(agg_data, config) {
  rlang::check_installed("ggiraph", reason = "to use backend = 'ggiraph'")
  rlang::check_installed("ggplot2", reason = "to use backend = 'ggiraph'")

  x_var <- config$x_var
  group_var <- config$group_var
  horizontal <- config$horizontal
  color_palette <- config$color_palette
  title <- config$title
  subtitle <- config$subtitle
  final_x_label <- config$x_label
  final_y_label <- config$y_label
  dot_size <- config$dot_size
  stem_width <- config$stem_width

  # Build tooltip text
  agg_data$.tooltip <- paste0(
    agg_data[[x_var]],
    if (!is.null(group_var)) paste0(" (", agg_data[[group_var]], ")") else "",
    ": ", round(agg_data$value, 2)
  )

  if (is.null(group_var)) {
    p <- ggplot2::ggplot(agg_data, ggplot2::aes(
      x = .data[[x_var]], y = .data$value
    )) +
      ggplot2::geom_segment(
        ggplot2::aes(x = .data[[x_var]], xend = .data[[x_var]], y = 0, yend = .data$value),
        linewidth = stem_width * 0.3, color = "#999999"
      ) +
      ggiraph::geom_point_interactive(
        ggplot2::aes(tooltip = .data$.tooltip, data_id = .data[[x_var]]),
        size = dot_size * 0.5
      )
  } else {
    p <- ggplot2::ggplot(agg_data, ggplot2::aes(
      x = .data[[x_var]], y = .data$value, color = .data[[group_var]]
    )) +
      ggplot2::geom_segment(
        ggplot2::aes(x = .data[[x_var]], xend = .data[[x_var]], y = 0, yend = .data$value),
        linewidth = stem_width * 0.3,
        position = ggplot2::position_dodge(0.5)
      ) +
      ggiraph::geom_point_interactive(
        ggplot2::aes(tooltip = .data$.tooltip, data_id = .data[[x_var]]),
        size = dot_size * 0.5,
        position = ggplot2::position_dodge(0.5)
      )
  }

  if (!is.null(color_palette)) {
    p <- p + ggplot2::scale_color_manual(values = color_palette)
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
