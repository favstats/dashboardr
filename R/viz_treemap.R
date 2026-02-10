# =================================================================
# Treemap Visualization
# =================================================================

# Declare global variables for NSE (non-standard evaluation)
utils::globalVariables(c("name", "value", "colorValue"))

#' Create a treemap visualization
#'
#' Creates an interactive treemap using highcharter for hierarchical data.
#' Treemaps are useful for showing proportional data in a space-efficient way.
#'
#' @param data Data frame containing the data
#' @param group_var Primary grouping variable (e.g., "region")
#' @param subgroup_var Optional secondary grouping variable (e.g., "city")
#' @param value_var Variable for sizing the rectangles (e.g., "spend")
#' @param color_var Optional variable for coloring (defaults to group_var)
#' @param title Chart title
#' @param subtitle Chart subtitle
#' @param color_palette Named vector of colors or palette name
#' @param height Chart height in pixels (default 500)
#' @param allow_drill_down Whether to allow drilling into subgroups (default TRUE)
#' @param layout_algorithm Layout algorithm: "squarified" (default), "strip", "sliceAndDice", "stripes"
#' @param data_labels_enabled Logical. If TRUE, show data labels on cells. Default TRUE.
#' @param show_labels Deprecated. Use `data_labels_enabled` instead.
#' @param label_style List of label styling options
#' @param tooltip A tooltip configuration created with \code{\link{tooltip}()},
#'   OR a format string with \{placeholders\}. Available placeholders:
#'   \code{\{name\}}, \code{\{value\}}.
#'   See \code{\link{tooltip}} for full customization options.
#' @param tooltip_format Custom tooltip format using Highcharts syntax (legacy).
#'   For the simpler dashboardr placeholder syntax, use \code{tooltip} instead.
#' @param credits Whether to show Highcharts credits (default FALSE)
#' @param pre_aggregated Logical. If TRUE, skips summing and uses `value_var` directly.
#'   Use this when your data is already aggregated (one row per leaf node).
#'   Default is FALSE.
#' @param backend Rendering backend: "highcharter" (default), "plotly", "echarts4r", or "ggiraph".
#' @param ... Additional parameters passed to highcharter
#'
#' @param legend_position Position of the legend ("top", "bottom", "left", "right", "none")
#' @return A highcharter treemap object
#' @export
#'
#' @examples
#' \dontrun{
#' # Simple treemap
#' data <- data.frame(
#'   region = c("North", "North", "South", "South"),
#'   city = c("NYC", "Boston", "Miami", "Atlanta"),
#'   spend = c(1000, 500, 800, 600)
#' )
#' viz_treemap(data, group_var = "region", subgroup_var = "city", value_var = "spend")
#'
#' # Single-level treemap
#' viz_treemap(data, group_var = "city", value_var = "spend", title = "Spend by City")
#' }
viz_treemap <- function(
    data,
    group_var,
    subgroup_var = NULL,
    value_var,
    color_var = NULL,
    title = NULL,
    subtitle = NULL,
    color_palette = NULL,
    height = 500,
    allow_drill_down = TRUE,
    layout_algorithm = "squarified",
    data_labels_enabled = TRUE,
    show_labels = NULL,
    label_style = NULL,
    tooltip = NULL,
    tooltip_format = NULL,
    credits = FALSE,
    pre_aggregated = FALSE,
    legend_position = NULL,
    backend = "highcharter",
    ...
) {
  # Convert variable arguments to strings (supports both quoted and unquoted)
  group_var <- .as_var_string(rlang::enquo(group_var))
  subgroup_var <- .as_var_string(rlang::enquo(subgroup_var))
  value_var <- .as_var_string(rlang::enquo(value_var))
  color_var <- .as_var_string(rlang::enquo(color_var))


  # Handle deprecated show_labels parameter
  if (!is.null(show_labels)) {
    warning("show_labels is deprecated. Use data_labels_enabled instead.", call. = FALSE)
    data_labels_enabled <- show_labels
  }

  # Validate required parameters
  if (missing(data) || is.null(data)) {
    stop("data is required for viz_treemap()", call. = FALSE)
  }
  if (is.null(group_var)) {
    stop("group_var is required for viz_treemap()", call. = FALSE)
  }
  if (is.null(value_var)) {
    stop("value_var is required for viz_treemap()", call. = FALSE)
  }

  # Check that columns exist
  if (!group_var %in% names(data)) {
    stop(paste0("group_var '", group_var, "' not found in data"), call. = FALSE)
  }
  if (!value_var %in% names(data)) {
    stop(paste0("value_var '", value_var, "' not found in data"), call. = FALSE)
  }
  if (!is.null(subgroup_var) && !subgroup_var %in% names(data)) {
    stop(paste0("subgroup_var '", subgroup_var, "' not found in data"), call. = FALSE)
  }

  # Prepare data
  plot_data <- data %>%
    dplyr::select(dplyr::all_of(c(group_var, value_var, subgroup_var, color_var)))

  # Handle haven_labelled variables
  if (requireNamespace("haven", quietly = TRUE)) {
    # value_var should be numeric
    if (inherits(plot_data[[value_var]], "haven_labelled")) {
      plot_data[[value_var]] <- as.numeric(plot_data[[value_var]])
    }

    # group_var and subgroup_var should be factors/labels
    if (inherits(plot_data[[group_var]], "haven_labelled")) {
      plot_data[[group_var]] <- haven::as_factor(plot_data[[group_var]], levels = "labels")
    }

    if (!is.null(subgroup_var) && inherits(plot_data[[subgroup_var]], "haven_labelled")) {
      plot_data[[subgroup_var]] <- haven::as_factor(plot_data[[subgroup_var]], levels = "labels")
    }

    if (!is.null(color_var) && inherits(plot_data[[color_var]], "haven_labelled")) {
      plot_data[[color_var]] <- haven::as_factor(plot_data[[color_var]], levels = "labels")
    }
  }

  # Ensure value_var is numeric
  plot_data[[value_var]] <- as.numeric(plot_data[[value_var]])

  # Remove NA values
  plot_data <- plot_data[!is.na(plot_data[[value_var]]) & !is.na(plot_data[[group_var]]), ]

  if (nrow(plot_data) == 0) {
    warning("No data remaining after removing NA values")
    return(highcharter::highchart() %>%
             highcharter::hc_title(text = title %||% "No Data") %>%
             highcharter::hc_subtitle(text = "No valid data to display"))
  }

  # Build hierarchical data structure
  if (!is.null(subgroup_var)) {
    # Two-level hierarchy - manually build to avoid highcharter::data_to_hierarchical stack issues

    # 1. Aggregate for level 2 (subgroups) - or use directly if pre-aggregated
    if (pre_aggregated) {
      # Data is already aggregated - use value_var directly
      l2_data <- plot_data %>%
        dplyr::mutate(
          parent = as.character(.data[[group_var]]),
          name = as.character(.data[[subgroup_var]]),
          value = .data[[value_var]],
          id = paste0(parent, "_", name)
        )
    } else {
      l2_data <- plot_data %>%
        dplyr::group_by(across(all_of(c(group_var, subgroup_var)))) %>%
        dplyr::summarize(value = sum(.data[[value_var]], na.rm = TRUE), .groups = "drop") %>%
        dplyr::mutate(
          parent = as.character(.data[[group_var]]),
          name = as.character(.data[[subgroup_var]]),
          id = paste0(parent, "_", name)
        )
    }

    # 2. Aggregate for level 1 (groups) - always sum child values
    l1_data <- l2_data %>%
      dplyr::group_by(parent) %>%
      dplyr::summarize(value = sum(value, na.rm = TRUE), .groups = "drop") %>%
      dplyr::mutate(
        name = parent,
        id = parent
      )

    # 3. Combine into Highcharts format
    hc_data <- list()

    # Add level 1 points
    for (i in seq_len(nrow(l1_data))) {
      hc_data[[length(hc_data) + 1]] <- list(
        id = l1_data$id[i],
        name = l1_data$name[i],
        value = l1_data$value[i],
        colorValue = l1_data$value[i] # For gradient coloring
      )
    }

    # Add level 2 points
    for (i in seq_len(nrow(l2_data))) {
      hc_data[[length(hc_data) + 1]] <- list(
        name = l2_data$name[i],
        parent = l2_data$parent[i],
        value = l2_data$value[i]
      )
    }
  } else {
    # Single-level - create simple list format
    if (pre_aggregated) {
      # Data is already aggregated - use value_var directly
      hc_data <- plot_data %>%
        dplyr::mutate(
          name = as.character(.data[[group_var]]),
          value = .data[[value_var]],
          colorValue = .data[[value_var]]
        ) %>%
        dplyr::select(name, value, colorValue) %>%
        as.list() %>%
        purrr::transpose()
    } else {
      hc_data <- plot_data %>%
        dplyr::group_by(.data[[group_var]]) %>%
        dplyr::summarize(value = sum(.data[[value_var]], na.rm = TRUE), .groups = "drop") %>%
        dplyr::mutate(
          name = as.character(.data[[group_var]]),
          colorValue = .data$value
        ) %>%
        dplyr::select(name, value, colorValue) %>%
        as.list() %>%
        purrr::transpose()
    }
  }

  # Build config for backend dispatch
  config <- list(
    group_var = group_var,
    subgroup_var = subgroup_var,
    value_var = value_var,
    color_var = color_var,
    title = title,
    subtitle = subtitle,
    color_palette = color_palette,
    height = height,
    allow_drill_down = allow_drill_down,
    layout_algorithm = layout_algorithm,
    data_labels_enabled = data_labels_enabled,
    label_style = label_style,
    tooltip = tooltip,
    tooltip_format = tooltip_format,
    credits = credits,
    hc_data = hc_data,
    legend_position = legend_position
  )

  # Dispatch to backend renderer
  backend <- .normalize_backend(backend)
  backend <- match.arg(backend, c("highcharter", "plotly", "echarts4r", "ggiraph"))
  .assert_backend_supported("treemap", backend)
  render_fn <- switch(backend,
    highcharter = .viz_treemap_highcharter,
    plotly      = .viz_treemap_plotly,
    echarts4r   = .viz_treemap_echarts,
    ggiraph     = .viz_treemap_ggiraph
  )
  result <- render_fn(plot_data, config)
  result <- .register_chart_widget(result, backend = backend)
  return(result)
}

# --- Highcharter backend (original implementation) ---
#' @keywords internal
.viz_treemap_highcharter <- function(plot_data, config) {
  # Unpack config
  title <- config$title
  subtitle <- config$subtitle
  color_palette <- config$color_palette
  height <- config$height
  allow_drill_down <- config$allow_drill_down
  subgroup_var <- config$subgroup_var
  layout_algorithm <- config$layout_algorithm
  data_labels_enabled <- config$data_labels_enabled
  label_style <- config$label_style
  tooltip <- config$tooltip
  tooltip_format <- config$tooltip_format
  credits <- config$credits
  hc_data <- config$hc_data

  # Create the treemap
  hc <- highcharter::highchart() %>%
    highcharter::hc_chart(type = "treemap", height = height) %>%
    highcharter::hc_add_series(
      data = hc_data,
      type = "treemap",
      layoutAlgorithm = layout_algorithm,
      allowDrillToNode = allow_drill_down && !is.null(subgroup_var),
      levelIsConstant = FALSE,
      levels = list(
        list(
          level = 1,
          dataLabels = list(
            enabled = data_labels_enabled,
            style = label_style %||% list(fontSize = "14px", fontWeight = "bold")
          ),
          borderWidth = 2,
          borderColor = "#FFFFFF"
        ),
        list(
          level = 2,
          dataLabels = list(
            enabled = data_labels_enabled,
            style = label_style %||% list(fontSize = "11px")
          ),
          borderWidth = 1,
          borderColor = "#FFFFFF"
        )
      )
    )

  # Add title
  if (!is.null(title)) {
    hc <- hc %>% highcharter::hc_title(text = title)
  }

  # Add subtitle
  if (!is.null(subtitle)) {
    hc <- hc %>% highcharter::hc_subtitle(text = subtitle)
  }

  # --- TOOLTIP ---
  if (!is.null(tooltip) && !is.null(tooltip_format)) {
    # Prefer tooltip_format if both are provided (for backwards compat)
    hc <- hc %>% highcharter::hc_tooltip(pointFormat = tooltip_format)
  } else if (!is.null(tooltip)) {
    # Use new unified tooltip system
    tooltip_result <- .process_tooltip_config(
      tooltip = tooltip,
      tooltip_prefix = NULL,
      tooltip_suffix = NULL,
      x_tooltip_suffix = NULL,
      chart_type = "treemap",
      context = list()
    )
    hc <- .apply_tooltip_to_hc(hc, tooltip_result)
  } else if (!is.null(tooltip_format)) {
    # Use legacy tooltip_format (Highcharts pointFormat syntax)
    hc <- hc %>% highcharter::hc_tooltip(pointFormat = tooltip_format)
  } else {
    # Default tooltip
    hc <- hc %>% highcharter::hc_tooltip(
      pointFormat = "<b>{point.name}</b>: {point.value:,.0f}"
    )
  }

  # Apply color palette
  if (!is.null(color_palette)) {
    if (is.character(color_palette) && length(color_palette) == 1) {
      # Named palette - use colorAxis
      hc <- hc %>% highcharter::hc_colorAxis(
        minColor = "#FFFFFF",
        maxColor = color_palette
      )
    } else {
      # Vector of colors
      hc <- hc %>% highcharter::hc_colors(color_palette)
    }
  } else {
    # Default colorAxis for gradient coloring
    hc <- hc %>% highcharter::hc_colorAxis(
      minColor = "#e8f4fc",
      maxColor = "#1a5276"
    )
  }

  # Credits
  hc <- hc %>% highcharter::hc_credits(enabled = credits)

  # --- Legend position ---
  hc <- .apply_legend_highcharter(hc, config$legend_position, default_show = FALSE)

  hc
}

# --- Plotly backend ---
#' @keywords internal
.viz_treemap_plotly <- function(plot_data, config) {
  rlang::check_installed("plotly", reason = "for plotly treemap backend")

  group_var <- config$group_var
  subgroup_var <- config$subgroup_var
  value_var <- config$value_var
  title <- config$title
  color_palette <- config$color_palette
  height <- config$height

  if (!is.null(subgroup_var)) {
    # Two-level treemap
    p <- plotly::plot_ly(
      data = plot_data,
      type = "treemap",
      labels = stats::as.formula(paste0("~`", subgroup_var, "`")),
      parents = stats::as.formula(paste0("~`", group_var, "`")),
      values = stats::as.formula(paste0("~`", value_var, "`")),
      textinfo = "label+value"
    )
  } else {
    # Single-level treemap
    p <- plotly::plot_ly(
      data = plot_data,
      type = "treemap",
      labels = stats::as.formula(paste0("~`", group_var, "`")),
      parents = "",
      values = stats::as.formula(paste0("~`", value_var, "`")),
      textinfo = "label+value"
    )
  }

  if (!is.null(color_palette)) {
    p <- p %>% plotly::layout(colorway = color_palette)
  }

  p <- p %>% plotly::layout(title = title, height = height)

  # --- Legend position ---
  p <- .apply_legend_plotly(p, config$legend_position, default_show = FALSE)

  p
}

# --- echarts4r backend ---
#' @keywords internal
.viz_treemap_echarts <- function(plot_data, config) {
  rlang::check_installed("echarts4r", reason = "for echarts4r treemap backend")

  group_var <- config$group_var
  value_var <- config$value_var
  title <- config$title
  color_palette <- config$color_palette

  # Build tree data
  tree_data <- plot_data %>%
    dplyr::group_by(.data[[group_var]]) %>%
    dplyr::summarize(.value = sum(.data[[value_var]], na.rm = TRUE), .groups = "drop")

  # Build treemap series data as list for e_list
  tree_children <- lapply(seq_len(nrow(tree_data)), function(i) {
    list(
      name = as.character(tree_data[[group_var]][i]),
      value = tree_data$.value[i]
    )
  })

  opts <- list(
    series = list(list(
      type = "treemap",
      data = tree_children,
      leafDepth = 1
    )),
    tooltip = list(trigger = "item")
  )

  if (!is.null(title)) {
    opts$title <- list(text = title)
  }

  if (!is.null(color_palette)) {
    opts$color <- as.list(color_palette)
  }

  e <- echarts4r::e_charts() |> echarts4r::e_list(opts)

  # --- Legend position ---
  # Note: legend hidden for treemaps
  e <- .apply_legend_echarts(e, config$legend_position, default_show = FALSE)

  e
}

# --- ggiraph backend ---
#' @keywords internal
.viz_treemap_ggiraph <- function(plot_data, config) {
  stop("backend = 'ggiraph' is not supported for viz_treemap(). ",
       "ggiraph does not have native treemap geoms. ",
       "Use backend = 'highcharter', 'plotly', or 'echarts4r' instead.",
       call. = FALSE)
}
