# --------------------------------------------------------------------------
# Function: create_bar
# --------------------------------------------------------------------------
#' @title Create Bar Chart
#' @description
#' Creates horizontal or vertical bar charts showing counts or percentages.
#' Supports simple bars or grouped bars (when `group_var` is provided).
#'
#' @param data A data frame containing the survey data.
#' @param x_var Character string. Name of the categorical variable for the x-axis.
#' @param group_var Optional character string. Name of grouping variable to create separate bars
#'   (e.g., score ranges, categories). Creates grouped/clustered bars.
#' @param title Optional main title for the chart.
#' @param subtitle Optional subtitle for the chart.
#' @param x_label Optional label for the x-axis. Defaults to `x_var` name.
#' @param y_label Optional label for the y-axis.
#' @param horizontal Logical. If `TRUE`, creates horizontal bars. Defaults to `TRUE`.
#' @param bar_type Character string. Type of bar chart: "count" or "percent". Defaults to "percent".
#' @param color_palette Optional character vector of colors for the bars.
#' @param group_order Optional character vector specifying the order of groups (for `group_var`).
#' @param x_order Optional character vector specifying the order of x categories.
#' @param x_breaks Optional numeric vector for binning continuous x variables.
#' @param x_bin_labels Optional character vector of labels for x bins.
#' @param include_na Logical. Whether to include NA values as a separate category. Defaults to `FALSE`.
#' @param na_label Character string. Label for NA category if `include_na = TRUE`. Defaults to "Missing".
#' @param weight_var Optional character string. Name of a weight variable to use for weighted
#'   aggregation. When provided, counts are computed as the sum of weights instead of simple counts.
#'
#' @return A highcharter plot object.
#'
#' @examples
#' # Simple bar chart showing distribution
#' plot1 <- create_bar(
#'   data = survey_data,
#'   x_var = "category",
#'   horizontal = TRUE,
#'   bar_type = "percent"
#' )
#' plot1
#'
#' # Grouped bars - like the user's image!
#' plot2 <- create_bar(
#'   data = survey_data,
#'   x_var = "question",           # "Knowledge Score"
#'   group_var = "score_range",    # "Low (1-9)", "Middle (10-19)", "High (20-29)"
#'   horizontal = TRUE,
#'   bar_type = "percent",
#'   color_palette = c("#D2691E", "#4682B4", "#228B22"),
#'   group_order = c("Low (1-9)", "Middle (10-19)", "High (20-29)")
#' )
#' plot2
#'
#' @export

create_bar <- function(data,
                       x_var,
                       group_var = NULL,
                       title = NULL,
                       subtitle = NULL,
                       x_label = NULL,
                       y_label = NULL,
                       horizontal = TRUE,
                       bar_type = "percent",
                       color_palette = NULL,
                       group_order = NULL,
                       x_order = NULL,
                       x_breaks = NULL,
                       x_bin_labels = NULL,
                       include_na = FALSE,
                       na_label = "Missing",
                       weight_var = NULL) {
  
  # Input validation
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  
  if (missing(x_var) || is.null(x_var)) {
    dashboardr:::.stop_with_hint("x_var", example = "create_bar(data, x_var = \"category\")")
  }
  
  if (!x_var %in% names(data)) {
    stop(paste0("Column '", x_var, "' not found in data."), call. = FALSE)
  }
  
  if (!is.null(group_var) && !group_var %in% names(data)) {
    stop(paste0("Column '", group_var, "' not found in data."), call. = FALSE)
  }
  
  if (!bar_type %in% c("count", "percent")) {
    stop("`bar_type` must be either 'count' or 'percent'.", call. = FALSE)
  }
  
  # Select relevant variables
  vars_to_select <- x_var
  if (!is.null(group_var)) vars_to_select <- c(vars_to_select, group_var)
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
  
  # Handle x binning if specified
  x_var_plot <- x_var
  if (!is.null(x_breaks)) {
    if (!is.numeric(plot_data[[x_var]])) {
      warning(paste0("'", x_var, "' is not numeric. Binning ignored."), call. = FALSE)
    } else {
      if (is.null(x_bin_labels)) {
        stop("When `x_breaks` is provided, `x_bin_labels` must also be provided.", call. = FALSE)
      }
      if (length(x_bin_labels) != (length(x_breaks) - 1)) {
        stop("Length of `x_bin_labels` must be `length(x_breaks) - 1`.", call. = FALSE)
      }
      plot_data <- plot_data %>%
        dplyr::mutate(
          .x_binned = cut(!!rlang::sym(x_var),
                          breaks = x_breaks,
                          labels = x_bin_labels,
                          include.lowest = TRUE,
                          right = FALSE)
        )
      x_var_plot <- ".x_binned"
    }
  }
  
  # Handle NA values
  if (include_na) {
    plot_data <- plot_data %>%
      dplyr::mutate(
        !!rlang::sym(x_var_plot) := forcats::fct_explicit_na(!!rlang::sym(x_var_plot), na_level = na_label)
      )
    if (!is.null(group_var)) {
      plot_data <- plot_data %>%
        dplyr::mutate(
          !!rlang::sym(group_var) := forcats::fct_explicit_na(!!rlang::sym(group_var), na_level = na_label)
        )
    }
  }
  
  # Apply custom ordering if specified
  if (!is.null(x_order)) {
    plot_data <- plot_data %>%
      dplyr::mutate(!!rlang::sym(x_var_plot) := factor(!!rlang::sym(x_var_plot), levels = x_order))
  }
  
  if (!is.null(group_var) && !is.null(group_order)) {
    plot_data <- plot_data %>%
      dplyr::mutate(!!rlang::sym(group_var) := factor(!!rlang::sym(group_var), levels = group_order))
  }
  
  # Aggregate data
  if (is.null(group_var)) {
    # Simple bar chart - count by x_var
    if (!is.null(weight_var)) {
      if (!weight_var %in% names(plot_data)) {
        stop("`weight_var` '", weight_var, "' not found in data.", call. = FALSE)
      }
      agg_data <- plot_data %>%
        dplyr::count(!!rlang::sym(x_var_plot), wt = !!rlang::sym(weight_var), name = "count")
    } else {
      agg_data <- plot_data %>%
        dplyr::count(!!rlang::sym(x_var_plot), name = "count")
    }
    
    if (bar_type == "percent") {
      agg_data <- agg_data %>%
        dplyr::mutate(value = round(count / sum(count) * 100, 1))
    } else {
      agg_data <- agg_data %>%
        dplyr::mutate(value = count)
    }
  } else {
    # Grouped bar chart - count by x_var and group_var
    if (!is.null(weight_var)) {
      if (!weight_var %in% names(plot_data)) {
        stop("`weight_var` '", weight_var, "' not found in data.", call. = FALSE)
      }
      agg_data <- plot_data %>%
        dplyr::count(!!rlang::sym(x_var_plot), !!rlang::sym(group_var), wt = !!rlang::sym(weight_var), name = "count")
    } else {
      agg_data <- plot_data %>%
        dplyr::count(!!rlang::sym(x_var_plot), !!rlang::sym(group_var), name = "count")
    }
    
    if (bar_type == "percent") {
      # Calculate percentage within each x_var category
      agg_data <- agg_data %>%
        dplyr::group_by(!!rlang::sym(x_var_plot)) %>%
        dplyr::mutate(value = round(count / sum(count) * 100, 1)) %>%
        dplyr::ungroup()
    } else {
      agg_data <- agg_data %>%
        dplyr::mutate(value = count)
    }
  }
  
  # Set up axis labels
  final_x_label <- x_label %||% x_var
  final_y_label <- y_label %||% if (bar_type == "percent") "Percentage" else "Count"
  
  # Create base chart
  hc <- highcharter::highchart()
  
  if (!is.null(title)) hc <- hc %>% highcharter::hc_title(text = title)
  if (!is.null(subtitle)) hc <- hc %>% highcharter::hc_subtitle(text = subtitle)
  
  # Configure chart type and orientation
  chart_type <- if (horizontal) "bar" else "column"
  hc <- hc %>% highcharter::hc_chart(type = chart_type)
  
  # Set up axes
  if (horizontal) {
    # For horizontal bars, x-axis is categories (vertical), y-axis is values (horizontal)
    hc <- hc %>%
      highcharter::hc_xAxis(
        categories = unique(as.character(agg_data[[x_var_plot]])),
        title = list(text = final_x_label)
      ) %>%
      highcharter::hc_yAxis(title = list(text = final_y_label))
  } else {
    # For vertical bars, x-axis is categories (horizontal), y-axis is values (vertical)
    hc <- hc %>%
      highcharter::hc_xAxis(
        categories = unique(as.character(agg_data[[x_var_plot]])),
        title = list(text = final_x_label)
      ) %>%
      highcharter::hc_yAxis(title = list(text = final_y_label))
  }
  
  # Add series
  if (is.null(group_var)) {
    # Simple bars - single series with multiple colors per bar
    series_data <- agg_data %>%
      dplyr::arrange(!!rlang::sym(x_var_plot)) %>%
      dplyr::pull(value)
    
    hc <- hc %>%
      highcharter::hc_add_series(
        name = final_y_label,
        data = series_data,
        showInLegend = FALSE,
        colorByPoint = TRUE  # Enable different colors for each bar
      )
    
    # Apply color palette to individual bars
    if (!is.null(color_palette) && length(color_palette) >= 1) {
      hc <- hc %>%
        highcharter::hc_colors(color_palette)
    }
  } else {
    # Grouped bars - one series per group
    group_levels <- if (!is.null(group_order)) {
      group_order
    } else {
      unique(agg_data[[group_var]])
    }
    
    for (i in seq_along(group_levels)) {
      group_level <- group_levels[i]
      
      series_data <- agg_data %>%
        dplyr::filter(!!rlang::sym(group_var) == group_level) %>%
        dplyr::arrange(!!rlang::sym(x_var_plot)) %>%
        dplyr::pull(value)
      
      hc <- hc %>%
        highcharter::hc_add_series(
          name = as.character(group_level),
          data = series_data
        )
    }
    
    # Apply color palette if specified
    if (!is.null(color_palette)) {
      hc <- hc %>% highcharter::hc_colors(color_palette)
    }
  }
  
  # Enable data labels
  hc <- hc %>%
    highcharter::hc_plotOptions(
      series = list(
        dataLabels = list(
          enabled = TRUE,
          format = if (bar_type == "percent") "{point.y:.0f}%" else "{point.y}"
        )
      )
    )
  
  return(hc)
}

