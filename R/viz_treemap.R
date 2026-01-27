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
#' @param show_labels Whether to show data labels (default TRUE)
#' @param label_style List of label styling options
#' @param tooltip_format Custom tooltip format
#' @param credits Whether to show Highcharts credits (default FALSE)
#' @param ... Additional parameters passed to highcharter
#'
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
    show_labels = TRUE,
    label_style = NULL,
    tooltip_format = NULL,
    credits = FALSE,
    ...
) {
  # Convert variable arguments to strings (supports both quoted and unquoted)
  group_var <- .as_var_string(rlang::enquo(group_var))
  subgroup_var <- .as_var_string(rlang::enquo(subgroup_var))
  value_var <- .as_var_string(rlang::enquo(value_var))
  color_var <- .as_var_string(rlang::enquo(color_var))
  
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
    
    # 1. Aggregate for level 2 (subgroups)
    l2_data <- plot_data %>%
      dplyr::group_by(across(all_of(c(group_var, subgroup_var)))) %>%
      dplyr::summarize(value = sum(.data[[value_var]], na.rm = TRUE), .groups = "drop") %>%
      dplyr::mutate(
        parent = as.character(.data[[group_var]]),
        name = as.character(.data[[subgroup_var]]),
        id = paste0(parent, "_", name)
      )
    
    # 2. Aggregate for level 1 (groups)
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
            enabled = show_labels,
            style = label_style %||% list(fontSize = "14px", fontWeight = "bold")
          ),
          borderWidth = 2,
          borderColor = "#FFFFFF"
        ),
        list(
          level = 2,
          dataLabels = list(
            enabled = show_labels,
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
  
  # Configure tooltip
  if (!is.null(tooltip_format)) {
    hc <- hc %>% highcharter::hc_tooltip(
      pointFormat = tooltip_format
    )
  } else {
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
  
  hc
}
