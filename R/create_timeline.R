# Load dependencies
library(highcharter)
library(tidyverse)
library(timetk)
library(dplyr)
library(rlang)
library(roxygen2)
library(gssr)

# Helper function (from rlang or magrittr)
`%||%` <- function(x, y) {
  if (is.null(x)) y else y
}

# --------------------------------------------------------------------------
# Function: create_timeline
# --------------------------------------------------------------------------
#' @title Create a Timeline Chart
#' @description
#' Creates interactive timeline visualizations showing changes in survey
#' responses over time. Supports multiple chart types including stacked areas,
#' line charts, and diverging bar charts.
#'
#' @param data A data frame containing survey data with time and response variables.
#' @param time_var Character string. Name of the time variable (e.g., "year", "wave").
#' @param response_var Character string. Name of the response variable containing Likert responses.
#' @param group_var Optional character string. Name of grouping variable for separate series
#'   (e.g., "gender", "education"). Creates separate lines/areas for each group.
#' @param chart_type Character string. Type of chart: "stacked_area" or "line".
#' @param title Optional main title for the chart.
#' @param y_max Optional numeric value. Maximum value for the Y-axis.
#' @param response_levels Optional character vector specifying order of response categories.
#' @param time_breaks Optional numeric vector for binning continuous time variables.
#' @param time_bin_labels Optional character vector of labels for time bins.
#'
#' @return A highcharter plot object.
#'
#' @examples
#' # Load GSS data
#' data(gss_all)
#'
#' # Basic timeline - confidence in institutions over time
#' plot1 <- create_timeline_(
#'            data = gss_all,
#'            time_var = "year",
#'            response_var = "confinan",
#'            title = "Confidence in Financial Institutions Over Time",
#'            y_max = 100
#'            )
#' plot1
#'
#' # Line chart by gender
#' plot2 <- create_timeline_fixed(
#'    data = gss_all,
#'    time_var = "year",
#'    response_var = "happy",
#'    group_var = "sex",
#'    chart_type = "line",
#'    title = "Happiness Trends by Gender",
#'    response_levels = c("very happy", "pretty happy", "not too happy")
#' )
#' plot2
#'
#' @export


create_timeline <- function(data,
                            time_var,
                            response_var,
                            group_var = NULL,
                            chart_type = "stacked_area",
                            title = NULL,
                            y_max = NULL,
                            response_levels = NULL,
                            time_breaks = NULL,
                            time_bin_labels = NULL) {

  # Basic data processing
  vars_to_select <- c(time_var, response_var)
  if (!is.null(group_var)) vars_to_select <- c(vars_to_select, group_var)

  plot_data <- data %>%
    select(all_of(vars_to_select)) %>%
    filter(!is.na(!!sym(time_var)), !is.na(!!sym(response_var)))

  if (!is.null(group_var)) {
    plot_data <- plot_data %>% filter(!is.na(!!sym(group_var)))
  }

  # Handle haven_labelled variables
  if (requireNamespace("haven", quietly = TRUE)) {
    if (inherits(plot_data[[time_var]], "haven_labelled")) {
      plot_data <- plot_data %>%
        mutate(!!sym(time_var) := as.numeric(!!sym(time_var)))
    }
    if (inherits(plot_data[[response_var]], "haven_labelled")) {
      plot_data <- plot_data %>%
        mutate(!!sym(response_var) := haven::as_factor(!!sym(response_var), levels = "labels"))
    }
    if (!is.null(group_var) && inherits(plot_data[[group_var]], "haven_labelled")) {
      plot_data <- plot_data %>%
        mutate(!!sym(group_var) := haven::as_factor(!!sym(group_var), levels = "labels"))
    }
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

  # Apply response level ordering if specified
  if (!is.null(response_levels)) {
    plot_data <- plot_data %>%
      mutate(!!sym(response_var) := factor(!!sym(response_var), levels = response_levels))
  }

  # Aggregate data
  if (is.null(group_var)) {
    agg_data <- plot_data %>%
      count(!!sym(time_var_plot), !!sym(response_var), name = "count") %>%
      group_by(!!sym(time_var_plot)) %>%
      mutate(percentage = round(count / sum(count) * 100, 1)) %>%
      ungroup()
  } else {
    agg_data <- plot_data %>%
      count(!!sym(time_var_plot), !!sym(response_var), !!sym(group_var), name = "count") %>%
      group_by(!!sym(time_var_plot), !!sym(group_var)) %>%
      mutate(percentage = round(count / sum(count) * 100, 1)) %>%
      ungroup()
  }

  # Create base chart
  hc <- highchart() %>%
    hc_title(text = title) %>%
    hc_yAxis(title = list(text = "Percentage"), max = y_max) %>%
    hc_xAxis(title = list(text = if(!is.null(time_breaks)) "Time Period" else "Year"))

  # Create chart based on type
  if (chart_type == "stacked_area") {
    hc <- hc %>%
      hc_chart(type = "area") %>%
      hc_plotOptions(area = list(stacking = "normal"))

    if (is.null(group_var)) {
      response_levels_to_use <- if (!is.null(response_levels)) response_levels else unique(agg_data[[response_var]])
      for(level in response_levels_to_use) {
        series_data <- agg_data %>%
          filter(!!sym(response_var) == level) %>%
          arrange(!!sym(time_var_plot)) %>%
          select(x = !!sym(time_var_plot), y = percentage)

        hc <- hc %>%
          hc_add_series(
            name = as.character(level),
            data = list_parse2(series_data),
            type = "area"
          )
      }
    }

  } else if (chart_type == "line") {
    hc <- hc %>% hc_chart(type = "line")

    if (is.null(group_var)) {
      response_levels_to_use <- if (!is.null(response_levels)) response_levels else unique(agg_data[[response_var]])
      for(level in response_levels_to_use) {
        series_data <- agg_data %>%
          filter(!!sym(response_var) == level) %>%
          arrange(!!sym(time_var_plot)) %>%
          select(x = !!sym(time_var_plot), y = percentage)

        hc <- hc %>%
          hc_add_series(
            name = as.character(level),
            data = list_parse2(series_data),
            type = "line"
          )
      }
    } else {
      response_levels_to_use <- if (!is.null(response_levels)) response_levels else unique(agg_data[[response_var]])
      group_levels <- unique(agg_data[[group_var]])

      for(resp_level in response_levels_to_use) {
        for(group_level in group_levels) {
          series_data <- agg_data %>%
            filter(!!sym(response_var) == resp_level, !!sym(group_var) == group_level) %>%
            arrange(!!sym(time_var_plot)) %>%
            select(x = !!sym(time_var_plot), y = percentage)

          if(nrow(series_data) > 0) {
            hc <- hc %>%
              hc_add_series(
                name = paste(resp_level, "-", group_level),
                data = list_parse2(series_data),
                type = "line"
              )
          }
        }
      }
    }
  }

  return(hc)
}
