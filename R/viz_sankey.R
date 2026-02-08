# =================================================================
# Sankey / Alluvial Diagram Visualization
# =================================================================

#' Create a Sankey Diagram
#'
#' Creates an interactive Sankey (alluvial flow) diagram using highcharter.
#' Sankey diagrams show flows between nodes, where the width of each
#' link is proportional to the flow quantity.
#'
#' @param data A data frame containing the flow data.
#' @param from_var Character string. Name of the column with source node names.
#' @param to_var Character string. Name of the column with target node names.
#' @param value_var Character string. Name of the numeric column with flow values/weights.
#' @param title Optional main title for the chart.
#' @param subtitle Optional subtitle for the chart.
#' @param color_palette Optional character vector of colors for the nodes.
#' @param node_width Numeric. Width of the node rectangles in pixels. Default 20.
#' @param node_padding Numeric. Vertical padding between nodes in pixels. Default 10.
#' @param link_opacity Numeric. Opacity of the flow links (0-1). Default 0.5.
#' @param data_labels_enabled Logical. If TRUE (default), show labels on nodes.
#' @param curvature Numeric. Curvature factor for links (0-1). Default 0.33.
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
#'   from = c("A", "A", "B", "B"),
#'   to = c("X", "Y", "X", "Y"),
#'   flow = c(30, 20, 10, 40)
#' )
#' viz_sankey(df, from_var = "from", to_var = "to", value_var = "flow",
#'            title = "Flow Diagram")
#' }
#' @export
viz_sankey <- function(data,
                       from_var,
                       to_var,
                       value_var,
                       title = NULL,
                       subtitle = NULL,
                       color_palette = NULL,
                       node_width = 20,
                       node_padding = 10,
                       link_opacity = 0.5,
                       data_labels_enabled = TRUE,
                       curvature = 0.33,
                       tooltip = NULL,
                       tooltip_prefix = "",
                       tooltip_suffix = "",
                       height = 400,
                       backend = "highcharter") {

  # Convert variable arguments to strings
  from_var <- .as_var_string(rlang::enquo(from_var))
  to_var <- .as_var_string(rlang::enquo(to_var))
  value_var <- .as_var_string(rlang::enquo(value_var))

  # Input validation
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }

  if (is.null(from_var)) {
    .stop_with_hint("from_var", example = 'viz_sankey(data, from_var = "source", to_var = "target", value_var = "flow")')
  }
  if (is.null(to_var)) {
    .stop_with_hint("to_var", example = 'viz_sankey(data, from_var = "source", to_var = "target", value_var = "flow")')
  }
  if (is.null(value_var)) {
    .stop_with_hint("value_var", example = 'viz_sankey(data, from_var = "source", to_var = "target", value_var = "flow")')
  }

  for (col in c(from_var, to_var, value_var)) {
    if (!col %in% names(data)) {
      stop(paste0("Column '", col, "' not found in data."), call. = FALSE)
    }
  }

  if (!is.numeric(data[[value_var]])) {
    stop(paste0("'", value_var, "' must be a numeric column."), call. = FALSE)
  }

  # Prepare data
  plot_data <- data %>%
    dplyr::select(dplyr::all_of(c(from_var, to_var, value_var))) %>%
    dplyr::filter(!is.na(!!rlang::sym(from_var)),
                  !is.na(!!rlang::sym(to_var)),
                  !is.na(!!rlang::sym(value_var)))

  # Handle haven_labelled
  if (requireNamespace("haven", quietly = TRUE)) {
    if (inherits(plot_data[[from_var]], "haven_labelled")) {
      plot_data[[from_var]] <- as.character(haven::as_factor(plot_data[[from_var]], levels = "labels"))
    }
    if (inherits(plot_data[[to_var]], "haven_labelled")) {
      plot_data[[to_var]] <- as.character(haven::as_factor(plot_data[[to_var]], levels = "labels"))
    }
  }

  # Build Sankey data format: list of named [from, to, weight]
  sankey_data <- lapply(seq_len(nrow(plot_data)), function(i) {
    list(
      from = as.character(plot_data[[from_var]][i]),
      to = as.character(plot_data[[to_var]][i]),
      weight = plot_data[[value_var]][i]
    )
  })

  # Build node list with optional colors
  all_nodes <- unique(c(as.character(plot_data[[from_var]]),
                        as.character(plot_data[[to_var]])))

  nodes <- lapply(seq_along(all_nodes), function(i) {
    node <- list(id = all_nodes[i], name = all_nodes[i])
    if (!is.null(color_palette)) {
      if (!is.null(names(color_palette)) && all_nodes[i] %in% names(color_palette)) {
        node$color <- unname(color_palette[all_nodes[i]])
      } else if (i <= length(color_palette)) {
        node$color <- color_palette[i]
      }
    }
    node
  })

  # Build config for backend dispatch
  config <- list(
    title = title, subtitle = subtitle,
    color_palette = color_palette, node_width = node_width,
    node_padding = node_padding, link_opacity = link_opacity,
    data_labels_enabled = data_labels_enabled, curvature = curvature,
    tooltip = tooltip, tooltip_prefix = tooltip_prefix,
    tooltip_suffix = tooltip_suffix, height = height,
    from_var = from_var, to_var = to_var, value_var = value_var,
    sankey_data = sankey_data, all_nodes = all_nodes, nodes = nodes
  )

  # Dispatch to backend renderer
  backend <- .normalize_backend(backend)
  backend <- match.arg(backend, c("highcharter", "plotly", "echarts4r", "ggiraph"))
  .assert_backend_supported("sankey", backend)
  render_fn <- switch(backend,
    highcharter = .viz_sankey_highcharter,
    plotly      = .viz_sankey_plotly,
    echarts4r   = .viz_sankey_echarts,
    ggiraph     = .viz_sankey_ggiraph
  )
  result <- render_fn(plot_data, config)
  result <- .register_chart_widget(result, backend = backend)
  return(result)
}

# --- Highcharter backend (original implementation) ---
#' @keywords internal
.viz_sankey_highcharter <- function(plot_data, config) {
  # Unpack config
  title <- config$title; subtitle <- config$subtitle
  color_palette <- config$color_palette; node_width <- config$node_width
  node_padding <- config$node_padding; link_opacity <- config$link_opacity
  data_labels_enabled <- config$data_labels_enabled; curvature <- config$curvature
  tooltip <- config$tooltip; tooltip_prefix <- config$tooltip_prefix
  tooltip_suffix <- config$tooltip_suffix; height <- config$height
  sankey_data <- config$sankey_data; nodes <- config$nodes

  # Create Sankey chart
  hc <- highcharter::highchart() %>%
    highcharter::hc_chart(height = height) %>%
    highcharter::hc_add_series(
      type = "sankey",
      data = sankey_data,
      nodes = nodes,
      nodeWidth = node_width,
      nodePadding = node_padding,
      linkOpacity = link_opacity,
      curveFactor = curvature,
      dataLabels = list(
        enabled = data_labels_enabled,
        style = list(
          fontSize = "11px",
          textOutline = "none"
        )
      )
    )

  # Title & subtitle
  if (!is.null(title)) hc <- hc %>% highcharter::hc_title(text = title)
  if (!is.null(subtitle)) hc <- hc %>% highcharter::hc_subtitle(text = subtitle)

  # Color palette (for nodes without explicit colors)
  if (!is.null(color_palette) && is.null(names(color_palette))) {
    hc <- hc %>% highcharter::hc_colors(color_palette)
  }

  # Tooltip
  if (!is.null(tooltip)) {
    tooltip_result <- .process_tooltip_config(
      tooltip = tooltip,
      tooltip_prefix = tooltip_prefix,
      tooltip_suffix = tooltip_suffix,
      x_tooltip_suffix = NULL,
      chart_type = "sankey",
      context = list()
    )
    hc <- .apply_tooltip_to_hc(hc, tooltip_result)
  } else {
    # Default sankey tooltip handled by Highcharts
    hc <- hc %>% highcharter::hc_tooltip(
      nodeFormat = "<b>{point.name}</b><br/>Total: {point.sum:,.0f}",
      pointFormat = "{point.fromNode.name} \u2192 {point.toNode.name}: <b>{point.weight:,.0f}</b>"
    )
  }

  # Credits
  hc <- hc %>% highcharter::hc_credits(enabled = FALSE)

  return(hc)
}

# --- Plotly backend ---
#' @keywords internal
.viz_sankey_plotly <- function(plot_data, config) {
  rlang::check_installed("plotly", reason = "to use backend = 'plotly'")

  title <- config$title
  color_palette <- config$color_palette
  height <- config$height
  from_var <- config$from_var
  to_var <- config$to_var
  value_var <- config$value_var
  all_nodes <- config$all_nodes
  link_opacity <- config$link_opacity

  # Map node names to integer indices (0-based)
  from_indices <- match(as.character(plot_data[[from_var]]), all_nodes) - 1L
  to_indices <- match(as.character(plot_data[[to_var]]), all_nodes) - 1L
  values <- plot_data[[value_var]]

  # Node colors
  n_nodes <- length(all_nodes)
  if (!is.null(color_palette)) {
    node_colors <- rep_len(color_palette, n_nodes)
  } else {
    node_colors <- rep_len(
      c("#4E79A7", "#F28E2B", "#E15759", "#76B7B2", "#59A14F",
        "#EDC948", "#B07AA1", "#FF9DA7", "#9C755F", "#BAB0AC"),
      n_nodes
    )
  }

  # Link colors (lighter versions of source node colors)
  link_colors <- paste0("rgba(",
    paste(
      grDevices::col2rgb(node_colors[from_indices + 1L])[1, ],
      grDevices::col2rgb(node_colors[from_indices + 1L])[2, ],
      grDevices::col2rgb(node_colors[from_indices + 1L])[3, ],
      link_opacity,
      sep = ","
    ),
  ")")

  p <- plotly::plot_ly(
    type = "sankey",
    orientation = "h",
    node = list(
      label = all_nodes,
      color = node_colors,
      pad = 10,
      thickness = 20
    ),
    link = list(
      source = from_indices,
      target = to_indices,
      value = values,
      color = link_colors
    )
  )

  if (!is.null(title)) {
    p <- plotly::layout(p, title = title)
  }

  if (!is.null(height)) {
    p <- plotly::layout(p, height = height)
  }

  p
}

# --- echarts4r backend ---
#' @keywords internal
.viz_sankey_echarts <- function(plot_data, config) {
  rlang::check_installed("echarts4r", reason = "to use backend = 'echarts4r'")

  title <- config$title; subtitle <- config$subtitle
  color_palette <- config$color_palette
  height <- config$height
  from_var <- config$from_var
  to_var <- config$to_var
  value_var <- config$value_var
  all_nodes <- config$all_nodes

  # Build nodes as list of lists for e_list
  nodes_list <- lapply(all_nodes, function(nm) list(name = nm))

  # Build links as list of lists for e_list
  links_list <- lapply(seq_len(nrow(plot_data)), function(i) {
    list(
      source = as.character(plot_data[[from_var]][i]),
      target = as.character(plot_data[[to_var]][i]),
      value = plot_data[[value_var]][i]
    )
  })

  opts <- list(
    series = list(list(
      type = "sankey",
      data = nodes_list,
      links = links_list,
      layoutIterations = 32,
      emphasis = list(focus = "adjacency")
    )),
    tooltip = list(trigger = "item")
  )

  if (!is.null(title) || !is.null(subtitle)) {
    opts$title <- list(text = title %||% "", subtext = subtitle %||% "")
  }

  if (!is.null(color_palette)) {
    opts$color <- as.list(color_palette)
  }

  echarts4r::e_charts() |> echarts4r::e_list(opts)
}

# --- ggiraph backend ---
#' @keywords internal
.viz_sankey_ggiraph <- function(plot_data, config) {
  rlang::check_installed("ggiraph", reason = "to use backend = 'ggiraph'")
  rlang::check_installed("ggplot2", reason = "to use backend = 'ggiraph'")
  rlang::check_installed("ggalluvial", reason = "to use backend = 'ggiraph' for sankey diagrams")

  title <- config$title; subtitle <- config$subtitle
  color_palette <- config$color_palette
  from_var <- config$from_var
  to_var <- config$to_var
  value_var <- config$value_var

  # Build alluvial-style data
  alluvial_data <- data.frame(
    from = as.character(plot_data[[from_var]]),
    to = as.character(plot_data[[to_var]]),
    value = plot_data[[value_var]],
    stringsAsFactors = FALSE
  )

  alluvial_data$.tooltip <- paste0(
    alluvial_data$from, " \u2192 ", alluvial_data$to,
    ": ", round(alluvial_data$value, 2)
  )

  p <- ggplot2::ggplot(alluvial_data,
    ggplot2::aes(y = .data$value, axis1 = .data$from, axis2 = .data$to)
  ) +
    ggalluvial::geom_alluvium(
      ggplot2::aes(fill = .data$from),
      width = 1/12
    ) +
    ggalluvial::geom_stratum(width = 1/12, fill = "grey80", color = "grey50") +
    ggplot2::geom_text(
      stat = ggalluvial::StatStratum,
      ggplot2::aes(label = ggplot2::after_stat(.data$stratum)),
      size = 3
    ) +
    ggplot2::labs(title = title, subtitle = subtitle) +
    ggplot2::theme_minimal() +
    ggplot2::theme(axis.text.x = ggplot2::element_blank(),
                   axis.ticks.x = ggplot2::element_blank())

  if (!is.null(color_palette)) {
    p <- p + ggplot2::scale_fill_manual(values = color_palette)
  }

  ggiraph::girafe(ggobj = p)
}
