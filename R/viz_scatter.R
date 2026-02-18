# --------------------------------------------------------------------------
# Function: viz_scatter
# --------------------------------------------------------------------------
#' @title Create Scatter Plot
#' @description
#' Creates interactive scatter plots showing relationships between two continuous variables.
#' Supports optional color grouping, custom sizing, and trend lines.
#'
#' @param data A data frame containing the data.
#' @param x_var Character string. Name of the variable for the x-axis (continuous or categorical).
#' @param y_var Character string. Name of the variable for the y-axis (continuous).
#' @param color_var Optional character string. Name of grouping variable for coloring points.
#' @param size_var Optional character string. Name of variable to control point sizes.
#' @param title Optional main title for the chart.
#' @param subtitle Optional subtitle for the chart.
#' @param x_label Optional label for the x-axis. Defaults to `x_var` name.
#' @param y_label Optional label for the y-axis. Defaults to `y_var` name.
#' @param color_palette Optional character vector of colors for the points.
#' @param point_size Numeric. Default size for points when `size_var` is not specified. Defaults to 4.
#' @param show_trend Logical. Whether to add a trend line. Defaults to `FALSE`.
#' @param trend_method Character string. Method for trend line: "lm" (linear) or "loess". Defaults to "lm".
#' @param alpha Numeric between 0 and 1. Transparency of points. Defaults to 0.7.
#' @param include_na Logical. Whether to include NA values in color grouping. Defaults to `FALSE`.
#' @param na_label Character string. Label for NA category if `include_na = TRUE`. Defaults to "(Missing)".
#' @param tooltip A tooltip configuration created with \code{\link{tooltip}()}, 
#'   OR a format string with \{placeholders\}. Available placeholders: 
#'   \code{\{x\}}, \code{\{y\}}, \code{\{name\}}, \code{\{series\}}.
#'   See \code{\link{tooltip}} for full customization options.
#' @param tooltip_format Character string. Custom format for tooltips using Highcharts 
#'   placeholders like \{point.x\}, \{point.y\}. For the simpler dashboardr placeholder 
#'   syntax, use the \code{tooltip} parameter instead.
#' @param jitter Logical. Whether to add jittering to reduce overplotting. Defaults to `FALSE`.
#' @param jitter_amount Numeric. Amount of jittering if `jitter = TRUE`. Defaults to 0.2.
#' @param cross_tab_filter_vars Optional character vector of variable names to use for
#'   client-side cross-tab filtering when dashboard inputs are present.
#'
#' @param backend Rendering backend: "highcharter" (default), "plotly", "echarts4r", or "ggiraph".
#' @return A highcharter plot object.
#'
#' @examples
#' # Simple scatter plot
#' plot1 <- viz_scatter(
#'   data = mtcars,
#'   x_var = "wt",
#'   y_var = "mpg",
#'   title = "Car Weight vs MPG"
#' )
#' plot1
#'
#' # Scatter plot with color grouping
#' plot2 <- viz_scatter(
#'   data = iris,
#'   x_var = "Sepal.Length",
#'   y_var = "Sepal.Width",
#'   color_var = "Species",
#'   title = "Iris Sepal Measurements"
#' )
#' plot2
#'
#' # Scatter with trend line and custom colors
#' plot3 <- viz_scatter(
#'   data = mtcars,
#'   x_var = "hp",
#'   y_var = "mpg",
#'   color_var = "cyl",
#'   show_trend = TRUE,
#'   title = "Horsepower vs MPG by Cylinders",
#'   color_palette = c("#FF6B6B", "#4ECDC4", "#45B7D1")
#' )
#' plot3
#'
#' @param legend_position Position of the legend ("top", "bottom", "left", "right", "none")
#' @export

viz_scatter <- function(data,
                           x_var,
                           y_var,
                           color_var = NULL,
                           size_var = NULL,
                           title = NULL,
                           subtitle = NULL,
                           x_label = NULL,
                           y_label = NULL,
                           color_palette = NULL,
                           point_size = 4,
                           show_trend = FALSE,
                           trend_method = "lm",
                           alpha = 0.7,
                           include_na = FALSE,
                           na_label = "(Missing)",
                           tooltip = NULL,
                           tooltip_format = NULL,
                           jitter = FALSE,
                           jitter_amount = 0.2,
                           legend_position = NULL,
                           backend = "highcharter",
                           cross_tab_filter_vars = NULL) {
  
  # Convert variable arguments to strings (supports both quoted and unquoted)
  x_var <- .as_var_string(rlang::enquo(x_var))
  y_var <- .as_var_string(rlang::enquo(y_var))
  color_var <- .as_var_string(rlang::enquo(color_var))
  size_var <- .as_var_string(rlang::enquo(size_var))
  
  # Input validation
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  
  if (is.null(x_var)) {
    .stop_with_hint("x_var", example = "viz_scatter(data, x_var = \"var1\", y_var = \"var2\")")
  }
  
  if (is.null(y_var)) {
    .stop_with_hint("y_var", example = "viz_scatter(data, x_var = \"var1\", y_var = \"var2\")")
  }
  
  if (!x_var %in% names(data)) {
    stop(paste0("Column '", x_var, "' not found in data."), call. = FALSE)
  }
  
  if (!y_var %in% names(data)) {
    stop(paste0("Column '", y_var, "' not found in data."), call. = FALSE)
  }
  
  if (!is.null(color_var) && !color_var %in% names(data)) {
    stop(paste0("Column '", color_var, "' not found in data."), call. = FALSE)
  }
  
  if (!is.null(size_var) && !size_var %in% names(data)) {
    stop(paste0("Column '", size_var, "' not found in data."), call. = FALSE)
  }
  
  if (!trend_method %in% c("lm", "loess")) {
    stop("`trend_method` must be either 'lm' or 'loess'.", call. = FALSE)
  }
  
  # Select relevant variables
  vars_to_select <- c(x_var, y_var)
  if (!is.null(color_var)) vars_to_select <- c(vars_to_select, color_var)
  if (!is.null(size_var)) vars_to_select <- c(vars_to_select, size_var)
  if (!is.null(cross_tab_filter_vars) && length(cross_tab_filter_vars) > 0) {
    vars_to_select <- c(vars_to_select, cross_tab_filter_vars)
  }
  vars_to_select <- unique(vars_to_select)
  
  plot_data <- data %>%
    dplyr::select(dplyr::all_of(vars_to_select)) %>%
    dplyr::filter(!is.na(!!rlang::sym(x_var)) & !is.na(!!rlang::sym(y_var)))
  
  # Handle haven_labelled variables
  if (requireNamespace("haven", quietly = TRUE)) {
    if (inherits(plot_data[[x_var]], "haven_labelled")) {
      plot_data <- plot_data %>%
        dplyr::mutate(!!rlang::sym(x_var) := haven::as_factor(!!rlang::sym(x_var), levels = "labels"))
    }
    if (inherits(plot_data[[y_var]], "haven_labelled")) {
      plot_data <- plot_data %>%
        dplyr::mutate(!!rlang::sym(y_var) := as.numeric(haven::as_factor(!!rlang::sym(y_var), levels = "values")))
    }
    if (!is.null(color_var) && inherits(plot_data[[color_var]], "haven_labelled")) {
      plot_data <- plot_data %>%
        dplyr::mutate(!!rlang::sym(color_var) := haven::as_factor(!!rlang::sym(color_var), levels = "labels"))
    }
    if (!is.null(size_var) && inherits(plot_data[[size_var]], "haven_labelled")) {
      plot_data <- plot_data %>%
        dplyr::mutate(!!rlang::sym(size_var) := as.numeric(!!rlang::sym(size_var)))
    }
  }
  
  # Handle NA values in color_var
  if (!is.null(color_var)) {
    if (include_na) {
      plot_data <- plot_data %>%
        dplyr::mutate(
          !!rlang::sym(color_var) := forcats::fct_na_value_to_level(!!rlang::sym(color_var), level = na_label)
        )
    } else {
      plot_data <- plot_data %>%
        dplyr::filter(!is.na(!!rlang::sym(color_var)))
    }
  }
  
  # Apply jitter if requested
  if (jitter) {
    plot_data <- plot_data %>%
      dplyr::mutate(
        .x_jittered = !!rlang::sym(x_var) + stats::runif(dplyr::n(), -jitter_amount, jitter_amount),
        .y_jittered = !!rlang::sym(y_var) + stats::runif(dplyr::n(), -jitter_amount, jitter_amount)
      )
    x_var_plot <- ".x_jittered"
    y_var_plot <- ".y_jittered"
  } else {
    x_var_plot <- x_var
    y_var_plot <- y_var
  }
  
  # Ensure numeric for plotting
  if (!is.numeric(plot_data[[x_var_plot]])) {
    # Convert factor/character to numeric for x-axis
    plot_data <- plot_data %>%
      dplyr::mutate(.x_numeric = as.numeric(as.factor(!!rlang::sym(x_var_plot))))
    x_var_numeric <- ".x_numeric"
  } else {
    x_var_numeric <- x_var_plot
  }
  
  if (!is.numeric(plot_data[[y_var_plot]])) {
    plot_data <- plot_data %>%
      dplyr::mutate(!!rlang::sym(y_var_plot) := as.numeric(!!rlang::sym(y_var_plot)))
  }
  
  # Set up axis labels
  final_x_label <- x_label %||% x_var
  final_y_label <- y_label %||% y_var
  
  # Build config for backend dispatch
  config <- list(
    x_var = x_var,
    y_var = y_var,
    x_var_numeric = x_var_numeric,
    y_var_plot = y_var_plot,
    color_var = color_var,
    size_var = size_var,
    title = title,
    subtitle = subtitle,
    final_x_label = final_x_label,
    final_y_label = final_y_label,
    color_palette = color_palette,
    point_size = point_size,
    show_trend = show_trend,
    trend_method = trend_method,
    alpha = alpha,
    tooltip = tooltip,
    tooltip_format = tooltip_format,
    legend_position = legend_position
  )

  # Prepare cross-tab data for client-side filtering (all backends)
  cross_tab_attrs <- NULL
  if (!is.null(cross_tab_filter_vars) && length(cross_tab_filter_vars) > 0) {
    valid_filter_vars <- cross_tab_filter_vars[cross_tab_filter_vars %in% names(plot_data)]
    if (length(valid_filter_vars) > 0) {
      keep_cols <- unique(c(valid_filter_vars, x_var_numeric, y_var_plot, color_var, size_var))
      cross_tab <- plot_data %>%
        dplyr::select(dplyr::all_of(keep_cols)) %>%
        dplyr::mutate(
          .dashboardr_x = as.numeric(.data[[x_var_numeric]]),
          .dashboardr_y = as.numeric(.data[[y_var_plot]]),
          .dashboardr_group = if (!is.null(color_var)) as.character(.data[[color_var]]) else "__all__",
          .dashboardr_size = if (!is.null(size_var)) as.numeric(.data[[size_var]]) else NA_real_
        ) %>%
        dplyr::select(dplyr::all_of(valid_filter_vars), .dashboardr_x, .dashboardr_y, .dashboardr_group, .dashboardr_size)

      chart_id <- .next_crosstab_id()
      chart_config <- list(
        chartId = chart_id,
        chartType = "scatter",
        xVar = ".dashboardr_x",
        yVar = ".dashboardr_y",
        groupVar = if (!is.null(color_var)) ".dashboardr_group" else NULL,
        sizeVar = if (!is.null(size_var)) ".dashboardr_size" else NULL,
        filterVars = valid_filter_vars,
        groupOrder = if (!is.null(color_var)) unique(as.character(plot_data[[color_var]])) else NULL,
        pointSize = point_size,
        alpha = alpha
      )
      if (!is.null(color_palette) && !is.null(names(color_palette))) {
        chart_config$colorMap <- as.list(color_palette)
      }
      if (!is.null(title) && grepl("\\{\\w+\\}", title)) {
        chart_config$titleTemplate <- title
      }
      cross_tab_attrs <- list(data = cross_tab, config = chart_config, id = chart_id)
    }
  }

  # Dispatch to backend renderer
  backend <- .normalize_backend(backend)
  backend <- match.arg(backend, c("highcharter", "plotly", "echarts4r", "ggiraph"))
  .assert_backend_supported("scatter", backend)
  render_fn <- switch(backend,
    highcharter = .viz_scatter_highcharter,
    plotly      = .viz_scatter_plotly,
    echarts4r   = .viz_scatter_echarts,
    ggiraph     = .viz_scatter_ggiraph
  )
  result <- render_fn(plot_data, config)
  if (!is.null(cross_tab_attrs)) {
    attr(result, "cross_tab_data") <- cross_tab_attrs$data
    attr(result, "cross_tab_config") <- cross_tab_attrs$config
    attr(result, "cross_tab_id") <- cross_tab_attrs$id
    if (identical(backend, "highcharter")) {
      result <- highcharter::hc_chart(result, id = cross_tab_attrs$id)
    }
  }
  result <- .register_chart_widget(result, backend = backend)
  return(result)
}

# --- Highcharter backend (original implementation) ---
#' @keywords internal
.viz_scatter_highcharter <- function(plot_data, config) {
  # Unpack config
  x_var <- config$x_var
  y_var <- config$y_var
  x_var_numeric <- config$x_var_numeric
  y_var_plot <- config$y_var_plot
  color_var <- config$color_var
  size_var <- config$size_var
  title <- config$title
  subtitle <- config$subtitle
  final_x_label <- config$final_x_label
  final_y_label <- config$final_y_label
  color_palette <- config$color_palette
  point_size <- config$point_size
  show_trend <- config$show_trend
  trend_method <- config$trend_method
  alpha <- config$alpha
  tooltip <- config$tooltip
  tooltip_format <- config$tooltip_format

  # Create base chart
  hc <- highcharter::highchart() %>%
    highcharter::hc_chart(type = "scatter", zoomType = "xy")

  if (!is.null(title)) hc <- hc %>% highcharter::hc_title(text = title)
  if (!is.null(subtitle)) hc <- hc %>% highcharter::hc_subtitle(text = subtitle)

  # Set up axes
  hc <- hc %>%
    highcharter::hc_xAxis(
      title = list(text = final_x_label),
      gridLineWidth = 1
    ) %>%
    highcharter::hc_yAxis(
      title = list(text = final_y_label),
      gridLineWidth = 1
    )

  # Prepare tooltip format (for legacy tooltip_format parameter)
  if (is.null(tooltip) && is.null(tooltip_format)) {
    tooltip_format <- paste0(
      "<b>", final_x_label, ":</b> {point.x}<br/>",
      "<b>", final_y_label, ":</b> {point.y}",
      if (!is.null(color_var)) paste0("<br/><b>", color_var, ":</b> {series.name}") else ""
    )
  }

  # Add series
  if (is.null(color_var)) {
    # Single series - all points same color
    series_data <- plot_data %>%
      dplyr::mutate(
        x = !!rlang::sym(x_var_numeric),
        y = !!rlang::sym(y_var_plot)
      ) %>%
      dplyr::select(x, y)

    if (!is.null(size_var)) {
      series_data <- series_data %>%
        dplyr::mutate(z = plot_data[[size_var]])
    }

    hc <- hc %>%
      highcharter::hc_add_series(
        name = final_y_label,
        data = series_data,
        marker = list(
          radius = point_size,
          fillOpacity = alpha
        )
      )

    # Apply color if specified
    if (!is.null(color_palette) && length(color_palette) >= 1) {
      hc <- hc %>% highcharter::hc_colors(color_palette[1])
    }

  } else {
    # Multiple series - one per color group
    color_levels <- unique(plot_data[[color_var]])

    for (i in seq_along(color_levels)) {
      color_level <- color_levels[i]

      series_data <- plot_data %>%
        dplyr::filter(!!rlang::sym(color_var) == color_level) %>%
        dplyr::mutate(
          x = !!rlang::sym(x_var_numeric),
          y = !!rlang::sym(y_var_plot)
        ) %>%
        dplyr::select(x, y)

      if (!is.null(size_var)) {
        series_data <- series_data %>%
          dplyr::mutate(z = plot_data %>%
                          dplyr::filter(!!rlang::sym(color_var) == color_level) %>%
                          dplyr::pull(!!rlang::sym(size_var)))
      }

      hc <- hc %>%
        highcharter::hc_add_series(
          name = as.character(color_level),
          data = series_data,
          marker = list(
            radius = point_size,
            fillOpacity = alpha
          )
        )
    }

    # Apply color palette if specified
    if (!is.null(color_palette)) {
      hc <- hc %>% highcharter::hc_colors(color_palette)
    }
  }

  # Add trend line if requested
  if (show_trend) {
    if (trend_method == "lm") {
      # Linear model
      lm_model <- stats::lm(
        stats::as.formula(paste(y_var_plot, "~", x_var_numeric)),
        data = plot_data
      )

      # Generate prediction line
      x_range <- range(plot_data[[x_var_numeric]], na.rm = TRUE)
      x_pred <- seq(x_range[1], x_range[2], length.out = 100)
      y_pred <- stats::predict(lm_model, newdata = data.frame(setNames(list(x_pred), x_var_numeric)))

      trend_data <- data.frame(x = x_pred, y = y_pred)

    } else if (trend_method == "loess") {
      # Loess smoothing
      loess_model <- stats::loess(
        stats::as.formula(paste(y_var_plot, "~", x_var_numeric)),
        data = plot_data
      )

      x_range <- range(plot_data[[x_var_numeric]], na.rm = TRUE)
      x_pred <- seq(x_range[1], x_range[2], length.out = 100)
      y_pred <- stats::predict(loess_model, newdata = data.frame(setNames(list(x_pred), x_var_numeric)))

      trend_data <- data.frame(x = x_pred, y = y_pred)
    }

    hc <- hc %>%
      highcharter::hc_add_series(
        name = "Trend",
        data = trend_data,
        type = "line",
        marker = list(enabled = FALSE),
        color = "#FF4444",
        dashStyle = "dash",
        enableMouseTracking = FALSE,
        showInLegend = TRUE
      )
  }

  # Configure tooltip
  if (!is.null(tooltip)) {
    # Use new unified tooltip system
    tooltip_result <- .process_tooltip_config(
      tooltip = tooltip,
      tooltip_prefix = NULL,
      tooltip_suffix = NULL,
      x_tooltip_suffix = NULL,
      chart_type = "scatter",
      context = list(
        x_label = final_x_label,
        y_label = final_y_label
      )
    )
    hc <- .apply_tooltip_to_hc(hc, tooltip_result)
  } else {
    # Use legacy tooltip_format (Highcharts pointFormat syntax)
    hc <- hc %>%
      highcharter::hc_tooltip(
        useHTML = TRUE,
        headerFormat = "",
        pointFormat = tooltip_format
      )
  }

  # --- Legend position ---
  hc <- .apply_legend_highcharter(hc, config$legend_position, default_show = !is.null(color_var))

  return(hc)
}

# --- Plotly backend ---
#' @keywords internal
.viz_scatter_plotly <- function(plot_data, config) {
  rlang::check_installed("plotly", reason = "to use the plotly backend")
  x_var_numeric <- config$x_var_numeric
  y_var_plot <- config$y_var_plot
  color_var <- config$color_var
  size_var <- config$size_var
  title <- config$title
  final_x_label <- config$final_x_label
  final_y_label <- config$final_y_label
  color_palette <- config$color_palette
  alpha <- config$alpha

  if (!is.null(color_var)) {
    p <- plotly::plot_ly(plot_data,
      x = ~get(x_var_numeric), y = ~get(y_var_plot),
      color = ~get(color_var),
      colors = color_palette,
      type = "scatter", mode = "markers",
      marker = list(opacity = alpha,
                    size = if (!is.null(size_var)) ~get(size_var) else config$point_size)
    )
  } else {
    p <- plotly::plot_ly(plot_data,
      x = ~get(x_var_numeric), y = ~get(y_var_plot),
      type = "scatter", mode = "markers",
      marker = list(opacity = alpha,
                    size = if (!is.null(size_var)) ~get(size_var) else config$point_size,
                    color = if (!is.null(color_palette)) color_palette[1] else NULL)
    )
  }
  p <- p %>% plotly::layout(
    title = title,
    xaxis = list(title = final_x_label),
    yaxis = list(title = final_y_label)
  )
  # --- Legend position ---
  p <- .apply_legend_plotly(p, config$legend_position, default_show = !is.null(config$color_var))
  p
}

# --- echarts4r backend ---
#' @keywords internal
.viz_scatter_echarts <- function(plot_data, config) {
  rlang::check_installed("echarts4r", reason = "to use the echarts4r backend")
  x_var_numeric <- config$x_var_numeric
  y_var_plot <- config$y_var_plot
  color_var <- config$color_var
  title <- config$title
  final_x_label <- config$final_x_label
  final_y_label <- config$final_y_label

  if (!is.null(color_var)) {
    ec <- plot_data |>
      dplyr::group_by(!!rlang::sym(color_var)) |>
      echarts4r::e_charts_(x_var_numeric) |>
      echarts4r::e_scatter_(y_var_plot)
  } else {
    ec <- plot_data |>
      echarts4r::e_charts_(x_var_numeric) |>
      echarts4r::e_scatter_(y_var_plot)
  }
  ec <- ec |>
    echarts4r::e_title(text = title) |>
    echarts4r::e_x_axis(name = final_x_label) |>
    echarts4r::e_y_axis(name = final_y_label, min = .echarts_padded_min()) |>
    echarts4r::e_tooltip(trigger = "item")
  # --- Color palette ---
  if (!is.null(config$color_palette)) {
    ec <- ec |> echarts4r::e_color(config$color_palette)
  }

  # --- Legend position ---
  ec <- .apply_legend_echarts(ec, config$legend_position, default_show = !is.null(config$color_var))
  ec
}

# --- ggiraph backend ---
#' @keywords internal
.viz_scatter_ggiraph <- function(plot_data, config) {
  rlang::check_installed("ggiraph", reason = "to use the ggiraph backend")
  rlang::check_installed("ggplot2", reason = "to use the ggiraph backend")
  x_var_numeric <- config$x_var_numeric
  y_var_plot <- config$y_var_plot
  color_var <- config$color_var
  title <- config$title
  final_x_label <- config$final_x_label
  final_y_label <- config$final_y_label
  alpha <- config$alpha

  p <- ggplot2::ggplot(plot_data, ggplot2::aes(
    x = .data[[x_var_numeric]], y = .data[[y_var_plot]],
    tooltip = paste0(final_x_label, ": ", .data[[x_var_numeric]], "\n",
                     final_y_label, ": ", .data[[y_var_plot]])
  ))
  if (!is.null(color_var)) {
    p <- p + ggiraph::geom_point_interactive(
      ggplot2::aes(color = .data[[color_var]]), alpha = alpha
    )
  } else {
    p <- p + ggiraph::geom_point_interactive(alpha = alpha)
  }
  p <- p +
    ggplot2::labs(title = title, x = final_x_label, y = final_y_label)
  # --- Color palette ---
  if (!is.null(config$color_var) && !is.null(config$color_palette)) {
    p <- p + ggplot2::scale_color_manual(values = config$color_palette)
  }

  # --- Legend position ---
  p <- .apply_legend_ggplot(p, config$legend_position, default_show = !is.null(config$color_var))
  ggiraph::girafe(ggobj = p)
}
