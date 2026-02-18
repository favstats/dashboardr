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
#' @param cross_tab_filter_vars Optional character vector of variable names to use for
#'   client-side cross-tab filtering when dashboard inputs are present.
#'
#' @param backend Rendering backend: "highcharter" (default), "plotly", "echarts4r", or "ggiraph".
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
#' @param legend_position Position of the legend ("top", "bottom", "left", "right", "none")
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
                    center_text = NULL,
                    legend_position = NULL,
                    backend = "highcharter",
                    cross_tab_filter_vars = NULL) {

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
        !!rlang::sym(x_var) := forcats::fct_na_value_to_level(
          factor(!!rlang::sym(x_var)), level = na_label
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

  # Build config for backend dispatch
  config <- list(
    x_var = x_var, title = title, subtitle = subtitle,
    inner_size = inner_size, color_palette = color_palette,
    data_labels_enabled = data_labels_enabled,
    data_labels_format = data_labels_format,
    show_in_legend = show_in_legend,
    tooltip = tooltip, tooltip_prefix = tooltip_prefix,
    tooltip_suffix = tooltip_suffix,
    center_text = center_text,
    legend_position = legend_position
  )

  # Prepare cross-tab data for client-side filtering (all backends)
  cross_tab_attrs <- NULL
  if (!is.null(cross_tab_filter_vars) && length(cross_tab_filter_vars) > 0) {
    valid_filter_vars <- cross_tab_filter_vars[cross_tab_filter_vars %in% names(data)]
    if (length(valid_filter_vars) > 0) {
      group_vars <- c(x_var, valid_filter_vars)
      if (!is.null(y_var) && y_var %in% names(data) && is.numeric(data[[y_var]])) {
        cross_tab <- data %>%
          dplyr::group_by(dplyr::across(dplyr::all_of(group_vars))) %>%
          dplyr::summarise(n = sum(.data[[y_var]], na.rm = TRUE), .groups = "drop")
      } else if (!is.null(weight_var) && weight_var %in% names(data) && is.numeric(data[[weight_var]])) {
        cross_tab <- data %>%
          dplyr::group_by(dplyr::across(dplyr::all_of(group_vars))) %>%
          dplyr::summarise(n = sum(.data[[weight_var]], na.rm = TRUE), .groups = "drop")
      } else {
        cross_tab <- data %>%
          dplyr::count(dplyr::across(dplyr::all_of(group_vars)), name = "n")
      }
      chart_id <- .next_crosstab_id()
      chart_config <- list(
        chartId = chart_id,
        chartType = "pie",
        xVar = x_var,
        filterVars = valid_filter_vars,
        xOrder = if (!is.null(x_order)) as.character(x_order) else unique(as.character(agg_data$name))
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
  .assert_backend_supported("pie", backend)
  render_fn <- switch(backend,
    highcharter = .viz_pie_highcharter,
    plotly      = .viz_pie_plotly,
    echarts4r   = .viz_pie_echarts,
    ggiraph     = .viz_pie_ggiraph
  )
  result <- render_fn(agg_data, config)
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
.viz_pie_highcharter <- function(agg_data, config) {
  # Unpack config
  x_var <- config$x_var; title <- config$title; subtitle <- config$subtitle
  inner_size <- config$inner_size; color_palette <- config$color_palette
  data_labels_enabled <- config$data_labels_enabled
  data_labels_format <- config$data_labels_format
  show_in_legend <- config$show_in_legend
  tooltip <- config$tooltip; tooltip_prefix <- config$tooltip_prefix
  tooltip_suffix <- config$tooltip_suffix; center_text <- config$center_text

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

  # --- Legend position ---
  hc <- .apply_legend_highcharter(hc, config$legend_position, default_show = TRUE)

  return(hc)
}

# --- Plotly backend ---
#' @keywords internal
.viz_pie_plotly <- function(agg_data, config) {
  rlang::check_installed("plotly", reason = "to use backend = 'plotly'")

  title <- config$title
  color_palette <- config$color_palette
  inner_size <- config$inner_size
  data_labels_enabled <- config$data_labels_enabled

  # Determine hole size from inner_size string (e.g. "50%" -> 0.5)
  hole <- as.numeric(gsub("%", "", inner_size)) / 100

  p <- plotly::plot_ly(
    labels = agg_data$name,
    values = agg_data$value,
    type = "pie",
    hole = hole,
    textinfo = if (data_labels_enabled) "label+percent" else "none"
  )

  if (!is.null(color_palette)) {
    p <- plotly::layout(p, colorway = color_palette)
  }

  layout_args <- list(p = p)
  if (!is.null(title)) layout_args$title <- title

  p <- do.call(plotly::layout, layout_args)

  # --- Legend position ---
  p <- .apply_legend_plotly(p, config$legend_position, default_show = TRUE)

  p
}

# --- echarts4r backend ---
#' @keywords internal
.viz_pie_echarts <- function(agg_data, config) {
  rlang::check_installed("echarts4r", reason = "to use backend = 'echarts4r'")

  title <- config$title
  subtitle <- config$subtitle
  color_palette <- config$color_palette
  inner_size <- config$inner_size

  # Convert inner_size percentage string to radius spec
  inner_pct <- as.numeric(gsub("%", "", inner_size))
  radius <- if (inner_pct > 0) {
    c(paste0(inner_pct, "%"), "75%")
  } else {
    c("0%", "75%")
  }

  e <- agg_data |>
    echarts4r::e_charts(name) |>
    echarts4r::e_pie(value, radius = radius)

  if (!is.null(title) || !is.null(subtitle)) {
    e <- e |> echarts4r::e_title(text = title %||% "", subtext = subtitle %||% "")
  }

  e <- e |> echarts4r::e_tooltip(trigger = "item")

  if (!is.null(color_palette)) {
    e <- e |> echarts4r::e_color(color_palette)
  }

  # --- Data labels ---
  if (isTRUE(config$data_labels_enabled)) {
    label_dec <- config$label_decimals %||% 1L
    label_fmt <- paste0(
      "function(params) {",
      "  if (!params.percent) return '';",
      "  return params.name + ': ' + params.percent.toFixed(", label_dec, ") + '%';",
      "}"
    )
    e <- e |> echarts4r::e_labels(
      show = TRUE,
      formatter = htmlwidgets::JS(label_fmt)
    )
  }

  # --- Legend position ---
  e <- .apply_legend_echarts(e, config$legend_position, default_show = TRUE)

  e
}

# --- ggiraph backend ---
#' @keywords internal
.viz_pie_ggiraph <- function(agg_data, config) {
  rlang::check_installed("ggiraph", reason = "to use backend = 'ggiraph'")
  rlang::check_installed("ggplot2", reason = "to use backend = 'ggiraph'")

  title <- config$title
  subtitle <- config$subtitle
  color_palette <- config$color_palette
  inner_size <- config$inner_size

  # Compute percentage for tooltips
  agg_data$pct <- round(agg_data$value / sum(agg_data$value) * 100, 1)
  agg_data$.tooltip <- paste0(agg_data$name, ": ", agg_data$value,
                               " (", agg_data$pct, "%)")

  # Determine ymin for donut hole
  inner_pct <- as.numeric(gsub("%", "", inner_size))
  xlim_min <- if (inner_pct > 0) inner_pct / 100 * 4 else 0

  p <- ggplot2::ggplot(agg_data, ggplot2::aes(
    x = 2, y = .data$value, fill = .data$name
  )) +
    ggiraph::geom_bar_interactive(
      ggplot2::aes(tooltip = .data$.tooltip, data_id = .data$name),
      stat = "identity", width = 1
    ) +
    ggplot2::coord_polar(theta = "y") +
    ggplot2::xlim(c(xlim_min, 2.5)) +
    ggplot2::labs(title = title, subtitle = subtitle, fill = NULL) +
    ggplot2::theme_void()

  if (!is.null(color_palette)) {
    p <- p + ggplot2::scale_fill_manual(values = color_palette)
  }

  # --- Legend position ---
  p <- .apply_legend_ggplot(p, config$legend_position, default_show = TRUE)

  ggiraph::girafe(ggobj = p)
}
