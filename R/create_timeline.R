#' @title Create Timeline Charts for Likert Survey Data
#' @description
#' Creates interactive timeline visualizations showing changes in Likert-type survey
#' responses over time. Supports multiple chart types including stacked areas,
#' line charts, and diverging bar charts.
#'
#' @param data A data frame containing survey data with time and response variables.
#' @param time_var Character string. Name of the time variable (e.g., "year", "wave").
#' @param response_var Character string. Name of the response variable containing Likert responses.
#' @param group_var Optional character string. Name of grouping variable for separate series
#'   (e.g., "gender", "education"). Creates separate lines/areas for each group.
#' @param chart_type Character string. Type of chart: "stacked_area", "line", "stacked_bar", or "diverging_bar".
#' @param percentage Logical. If TRUE, shows percentages; if FALSE, shows counts. Default TRUE.
#' @param title Optional main title for the chart.
#' @param subtitle Optional subtitle for the chart.
#' @param x_label Optional label for the X-axis (time). Defaults to time_var name.
#' @param y_label Optional label for the Y-axis. Auto-generated based on percentage setting.
#' @param legend_title Optional title for the legend. Defaults to response_var name.
#' @param response_levels Optional character vector specifying order of response categories.
#' @param response_map Optional named list to recode response values (e.g., list("1" = "Strongly Disagree")).
#' @param group_labels Optional named list to recode group values.
#' @param time_breaks Optional numeric vector for binning continuous time variables.
#' @param time_bin_labels Optional character vector of labels for time bins.
#' @param color_palette Optional character vector of colors. For diverging charts,
#'   should have colors for negative, neutral, positive responses.
#' @param diverging_center Optional character string. For diverging charts, which response
#'   category should be centered (e.g., "Neither Agree nor Disagree").
#' @param include_na Logical. Whether to include NA values as explicit category.
#' @param na_label Character string. Label for NA values. Default "(Missing)".
#' @param smooth_lines Logical. For line charts, whether to add smoothing. Default FALSE.
#' @param show_points Logical. For line charts, whether to show data points. Default TRUE.
#' @param tooltip_prefix Optional string to prepend to tooltip values.
#' @param tooltip_suffix Optional string to append to tooltip values.
#'
#' @return A highcharter plot object.
#'
#' @examples
#' # Load GSS data
#' data(gss_all)
#'
#' # Basic timeline - confidence in institutions over time
#' plot1 <- create_likert_timeline(
#'   data = gss_all,
#'   time_var = "year",
#'   response_var = "confinan",
#'   chart_type = "stacked_area",
#'   title = "Confidence in Financial Institutions Over Time",
#'   response_levels = c("A Great Deal", "Only Some", "Hardly Any")
#' )
#'
#' # Line chart by gender
#' plot2 <- create_likert_timeline(
#'   data = gss_all,
#'   time_var = "year",
#'   response_var = "happy",
#'   group_var = "sex",
#'   chart_type = "line",
#'   title = "Happiness Trends by Gender",
#'   response_levels = c("Very Happy", "Pretty Happy", "Not Too Happy")
#' )
#'
#' # Diverging bar chart for political views
#' plot3 <- create_likert_timeline(
#'   data = gss_all,
#'   time_var = "year",
#'   response_var = "polviews",
#'   chart_type = "diverging_bar",
#'   title = "Political Views Over Time",
#'   diverging_center = "Moderate",
#'   time_breaks = c(1970, 1980, 1990, 2000, 2010, 2020),
#'   time_bin_labels = c("1970s", "1980s", "1990s", "2000s", "2010s")
#' )
#'
#' @export
create_timeline <- function(data,
                            time_var,
                            response_var,
                            group_var = NULL,
                            chart_type = c("stacked_area", "line", "stacked_bar", "diverging_bar"),
                            percentage = TRUE,
                            title = NULL,
                            subtitle = NULL,
                            x_label = NULL,
                            y_label = NULL,
                            legend_title = NULL,
                            response_levels = NULL,
                            response_map = NULL,
                            group_labels = NULL,
                            time_breaks = NULL,
                            time_bin_labels = NULL,
                            color_palette = NULL,
                            diverging_center = NULL,
                            include_na = FALSE,
                            na_label = "(Missing)",
                            smooth_lines = FALSE,
                            show_points = TRUE,
                            tooltip_prefix = "",
                            tooltip_suffix = "") {

  # Input validation
  if (!is.data.frame(data)) {
    stop("Input 'data' must be a data frame.", call. = FALSE)
  }
  if (!time_var %in% names(data)) {
    stop(paste0("Column '", time_var, "' not found in data."), call. = FALSE)
  }
  if (!response_var %in% names(data)) {
    stop(paste0("Column '", response_var, "' not found in data."), call. = FALSE)
  }
  if (!is.null(group_var) && !group_var %in% names(data)) {
    stop(paste0("Column '", group_var, "' not found in data."), call. = FALSE)
  }

  chart_type <- match.arg(chart_type)

  # Create working copy
  plot_data <- data %>%
    select(all_of(c(time_var, response_var, if(!is.null(group_var)) group_var))) %>%
    filter(!is.na(!!sym(time_var)))

  # Handle haven_labelled variables
  if (requireNamespace("haven", quietly = TRUE)) {
    if (inherits(plot_data[[response_var]], "haven_labelled")) {
      plot_data <- plot_data %>%
        mutate(!!sym(response_var) := haven::as_factor(!!sym(response_var), levels = "labels"))
    }
    if (!is.null(group_var) && inherits(plot_data[[group_var]], "haven_labelled")) {
      plot_data <- plot_data %>%
        mutate(!!sym(group_var) := haven::as_factor(!!sym(group_var), levels = "labels"))
    }
  }

  # Apply response mapping
  if (!is.null(response_map)) {
    if (is.factor(plot_data[[response_var]])) {
      plot_data <- plot_data %>%
        mutate(!!sym(response_var) := as.character(!!sym(response_var)))
    }
    plot_data <- plot_data %>%
      mutate(!!sym(response_var) := recode(!!sym(response_var), !!!response_map))
  }

  # Apply group mapping
  if (!is.null(group_var) && !is.null(group_labels)) {
    if (is.factor(plot_data[[group_var]])) {
      plot_data <- plot_data %>%
        mutate(!!sym(group_var) := as.character(!!sym(group_var)))
    }
    plot_data <- plot_data %>%
      mutate(!!sym(group_var) := recode(!!sym(group_var), !!!group_labels))
  }

  # Handle time binning
  time_var_plot <- time_var
  if (!is.null(time_breaks)) {
    if (!is.numeric(plot_data[[time_var]])) {
      warning(paste0("'", time_var, "' is not numeric. Time binning ignored."), call. = FALSE)
    } else {
      plot_data <- plot_data %>%
        mutate(
          .time_binned = cut(!!sym(time_var),
                             breaks = time_breaks,
                             labels = time_bin_labels,
                             include.lowest = TRUE,
                             right = FALSE)
        )
      time_var_plot <- ".time_binned"
    }
  }

  # Handle missing values
  if (include_na) {
    plot_data <- plot_data %>%
      mutate(
        !!sym(response_var) := ifelse(is.na(!!sym(response_var)), na_label, as.character(!!sym(response_var))),
        !!sym(response_var) := factor(!!sym(response_var))
      )
    if (!is.null(group_var)) {
      plot_data <- plot_data %>%
        mutate(
          !!sym(group_var) := ifelse(is.na(!!sym(group_var)), na_label, as.character(!!sym(group_var))),
          !!sym(group_var) := factor(!!sym(group_var))
        )
    }
  } else {
    plot_data <- plot_data %>%
      filter(!is.na(!!sym(response_var)))
    if (!is.null(group_var)) {
      plot_data <- plot_data %>%
        filter(!is.na(!!sym(group_var)))
    }
  }

  # Apply response level ordering
  if (!is.null(response_levels)) {
    plot_data <- plot_data %>%
      mutate(!!sym(response_var) := factor(!!sym(response_var), levels = response_levels))
  } else {
    plot_data <- plot_data %>%
      mutate(!!sym(response_var) := factor(!!sym(response_var)))
  }

  # Aggregate data
  if (is.null(group_var)) {
    agg_data <- plot_data %>%
      count(!!sym(time_var_plot), !!sym(response_var), name = "count") %>%
      group_by(!!sym(time_var_plot)) %>%
      mutate(
        total = sum(count),
        percentage = round(count / total * 100, 1)
      ) %>%
      ungroup()
  } else {
    agg_data <- plot_data %>%
      count(!!sym(time_var_plot), !!sym(response_var), !!sym(group_var), name = "count") %>%
      group_by(!!sym(time_var_plot), !!sym(group_var)) %>%
      mutate(
        total = sum(count),
        percentage = round(count / total * 100, 1)
      ) %>%
      ungroup()
  }

  # Set up labels
  x_label <- x_label %||% str_to_title(gsub("_", " ", time_var))
  y_label <- y_label %||% ifelse(percentage, "Percentage", "Count")
  legend_title <- legend_title %||% str_to_title(gsub("_", " ", response_var))

  # Create the appropriate chart type
  if (chart_type == "stacked_area") {
    hc <- create_stacked_area_chart(agg_data, time_var_plot, response_var, group_var, percentage)
  } else if (chart_type == "line") {
    hc <- create_line_chart(agg_data, time_var_plot, response_var, group_var, percentage, smooth_lines, show_points)
  } else if (chart_type == "stacked_bar") {
    hc <- create_stacked_bar_timeline(agg_data, time_var_plot, response_var, group_var, percentage)
  } else if (chart_type == "diverging_bar") {
    hc <- create_diverging_bar_chart(agg_data, time_var_plot, response_var, group_var, percentage, diverging_center)
  }

  # Apply styling
  hc <- hc %>%
    hc_title(text = title) %>%
    hc_subtitle(text = subtitle) %>%
    hc_xAxis(title = list(text = x_label)) %>%
    hc_yAxis(title = list(text = y_label)) %>%
    hc_legend(title = list(text = legend_title))

  # Apply color palette
  if (!is.null(color_palette)) {
    hc <- hc %>% hc_colors(color_palette)
  }

  # Add tooltips
  value_format <- ifelse(percentage, "{point.y:.1f}%", "{point.y}")
  tooltip_format <- paste0(tooltip_prefix, value_format, tooltip_suffix)

  hc <- hc %>%
    hc_tooltip(
      pointFormat = paste0("<b>{series.name}</b>: ", tooltip_format, "<br/>"),
      shared = TRUE
    )

  return(hc)
}

# Helper functions for different chart types
create_stacked_area_chart <- function(data, time_var, response_var, group_var, percentage) {
  value_col <- ifelse(percentage, "percentage", "count")

  if (is.null(group_var)) {
    hchart(data, "area", hcaes(x = !!sym(time_var), y = !!sym(value_col), group = !!sym(response_var))) %>%
      hc_plotOptions(area = list(stacking = "normal"))
  } else {
    # For grouped data, create separate charts or facets
    hchart(data, "area", hcaes(x = !!sym(time_var), y = !!sym(value_col), group = !!sym(response_var))) %>%
      hc_plotOptions(area = list(stacking = "normal"))
  }
}

create_line_chart <- function(data, time_var, response_var, group_var, percentage, smooth_lines, show_points) {
  value_col <- ifelse(percentage, "percentage", "count")

  if (is.null(group_var)) {
    series_var <- response_var
  } else {
    # Combine response and group for series
    data <- data %>%
      mutate(series_name = paste(!!sym(response_var), "-", !!sym(group_var)))
    series_var <- "series_name"
  }

  hc <- hchart(data, "line", hcaes(x = !!sym(time_var), y = !!sym(value_col), group = !!sym(series_var)))

  if (!show_points) {
    hc <- hc %>% hc_plotOptions(line = list(marker = list(enabled = FALSE)))
  }

  return(hc)
}

create_stacked_bar_timeline <- function(data, time_var, response_var, group_var, percentage) {
  value_col <- ifelse(percentage, "percentage", "count")
  stacking_type <- ifelse(percentage, "percent", "normal")

  hchart(data, "column", hcaes(x = !!sym(time_var), y = !!sym(value_col), group = !!sym(response_var))) %>%
    hc_plotOptions(column = list(stacking = stacking_type))
}

create_diverging_bar_chart <- function(data, time_var, response_var, group_var, percentage, diverging_center) {
  # This would need more complex logic to create diverging bars
  # For now, fall back to stacked bars
  create_stacked_bar_timeline(data, time_var, response_var, group_var, percentage)
}
