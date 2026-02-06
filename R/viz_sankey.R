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
                       height = 400) {

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

  # Build Sankey data format: list of [from, to, weight]
  sankey_data <- lapply(seq_len(nrow(plot_data)), function(i) {
    list(
      as.character(plot_data[[from_var]][i]),
      as.character(plot_data[[to_var]][i]),
      plot_data[[value_var]][i]
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
