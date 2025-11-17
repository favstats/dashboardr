
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
#' @param subtitle Optional subtitle for the chart.
#' @param x_label Optional character string. Label for the x-axis. Defaults to time_var name.
#' @param y_label Optional character string. Label for the y-axis. Defaults to "Percentage".
#' @param y_max Optional numeric value. Maximum value for the Y-axis.
#' @param y_min Optional numeric value. Minimum value for the Y-axis.
#' @param color_palette Optional character vector of color hex codes for the series.
#' @param response_levels Optional character vector specifying order of response categories.
#' @param response_breaks Optional numeric vector for binning numeric response values
#'   (e.g., `c(0, 2.5, 5, 7)` to create bins 0-2.5, 2.5-5, 5-7).
#' @param response_bin_labels Optional character vector of labels for response bins
#'   (e.g., `c("Low (1-2)", "Medium (3-5)", "High (6-7)")`).
#' @param response_map_values Optional named list to rename response values for display
#'   (e.g., `list("1" = "Correct", "0" = "Incorrect")`). Applied to legend labels and data.
#' @param response_filter Optional numeric or character vector specifying which response values to include.
#'   For numeric responses, use a range like `5:7` to show only values 5, 6, and 7.
#'   For categorical responses, use category names like `c("Agree", "Strongly Agree")`.
#'   Applied BEFORE binning (filters raw values first, then bins the filtered data).
#' @param response_filter_combine Logical. When `response_filter` is used, should filtered values be combined
#'   into a single percentage? Defaults to `TRUE` (show combined % of all filtered values).
#'   Set to `FALSE` to show separate lines for each filtered value.
#' @param response_filter_label Character string. Custom label for the filtered responses in the legend.
#'   Only used when `response_filter` and `response_filter_combine = TRUE`.
#'   If `NULL` (default) and `group_var` is provided, shows only group names in legend (e.g., "AgeGroup1").
#'   If `NULL` and no `group_var`, uses auto-generated label (e.g., "5-7" for `response_filter = 5:7`).
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
#' plot1 <- create_timeline(
#'            data = gss_all,
#'            time_var = "year",
#'            response_var = "confinan",
#'            title = "Confidence in Financial Institutions Over Time",
#'            y_max = 100
#'            )
#' plot1
#'
#' # Line chart by gender
#' plot2 <- create_timeline(
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
#' # Show only high responses (5-7 on a 1-7 scale) - COMBINED
#' plot3 <- create_timeline(
#'    data = survey_data,
#'    time_var = "wave",
#'    response_var = "agreement",  # 1-7 scale
#'    group_var = "age_group",
#'    chart_type = "line",
#'    response_filter = 5:7,  # Show combined % who responded 5-7
#'    title = "% High Agreement (5-7) Over Time"
#' )
#' plot3
#'
#' # Custom legend label
#' plot4 <- create_timeline(
#'    data = survey_data,
#'    time_var = "wave",
#'    response_var = "agreement",
#'    group_var = "age_group",
#'    chart_type = "line",
#'    response_filter = 5:7,
#'    response_filter_label = "High Agreement",  # Custom label instead of "5-7"
#'    title = "High Agreement Trends"
#' )
#' plot4
#'
#' # Show individual filtered values (not combined)
#' plot5 <- create_timeline(
#'    data = survey_data,
#'    time_var = "wave",
#'    response_var = "agreement",
#'    chart_type = "line",
#'    response_filter = 5:7,
#'    response_filter_combine = FALSE,  # Show separate lines for 5, 6, 7
#'    title = "Individual High Responses"
#' )
#' plot5
#'
#' # Custom styling with colors and labels
#' plot6 <- create_timeline(
#'    data = survey_data,
#'    time_var = "wave_time_label",
#'    response_var = "agreement",
#'    group_var = "age_group",
#'    chart_type = "line",
#'    response_filter = 4:5,
#'    title = "High Agreement Over Time",
#'    subtitle = "By Age Group",
#'    x_label = "Survey Wave",
#'    y_label = "% High Agreement",
#'    y_min = 0,
#'    y_max = 100,
#'    color_palette = c("#E41A1C", "#377EB8", "#4DAF4A", "#984EA3")
#' )
#' plot6
#'
#' # Custom legend labels with response_map_values
#' plot7 <- create_timeline(
#'    data = survey_data,
#'    time_var = "wave_time_label",
#'    response_var = "knowledge_item",
#'    chart_type = "line",
#'    response_filter = 1,
#'    response_map_values = list("1" = "Correct", "0" = "Incorrect"),
#'    title = "Knowledge Score Over Time",
#'    x_label = "Survey Wave",
#'    y_label = "% Correct",
#'    y_min = 0,
#'    y_max = 100
#' )
#' plot7
#'
#' @export


create_timeline <- function(data,
                            time_var,
                            response_var,
                            group_var = NULL,
                            chart_type = "stacked_area",
                            title = NULL,
                            subtitle = NULL,
                            x_label = NULL,
                            y_label = NULL,
                            y_max = NULL,
                            y_min = NULL,
                            color_palette = NULL,
                            response_levels = NULL,
                            response_breaks = NULL,
                            response_bin_labels = NULL,
                            response_map_values = NULL,
                            response_filter = NULL,
                            response_filter_combine = TRUE,
                            response_filter_label = NULL,
                            time_breaks = NULL,
                            time_bin_labels = NULL,
                            weight_var = NULL,
                            include_na = FALSE,
                            na_label_response = "(Missing)",
                            na_label_group = "(Missing)") {

  # INPUT VALIDATION
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  if (missing(time_var) || is.null(time_var)) {
    dashboardr:::.stop_with_hint("time_var", example = "create_timeline(data, time_var = \"year\", response_var = \"score\")")
  }
  if (missing(response_var) || is.null(response_var)) {
    dashboardr:::.stop_with_hint("response_var", example = "create_timeline(data, time_var = \"year\", response_var = \"score\")")
  }

  # Basic data processing
  vars_to_select <- c(time_var, response_var)
  if (!is.null(group_var)) vars_to_select <- c(vars_to_select, group_var)
  if (!is.null(weight_var)) vars_to_select <- c(vars_to_select, weight_var)

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

  # Apply response value mapping if provided (e.g., "1" -> "Correct")
  if (!is.null(response_map_values)) {
    # Convert factor to character to ensure recode works
    if (is.factor(plot_data[[response_var]])) {
      plot_data <- plot_data %>%
        mutate(!!sym(response_var) := as.character(!!sym(response_var)))
    }
    # Apply the mapping
    plot_data <- plot_data %>%
      mutate(!!sym(response_var) := dplyr::recode(as.character(!!sym(response_var)), !!!response_map_values))
  }

  # Handle response filtering - mark filtered values before aggregation
  # This ensures percentages are calculated correctly (out of ALL responses, not just filtered ones)
  filter_applied <- !is.null(response_filter)
  filter_label <- NULL

  if (filter_applied) {
    # Create a label for the filtered values
    # Use custom label if provided, otherwise auto-generate
    if (!is.null(response_filter_label) && response_filter_combine) {
      # User provided custom label
      filter_label <- response_filter_label
    } else if (is.numeric(response_filter) && length(response_filter) > 1) {
      # For numeric ranges, create a label like "5-7"
      filter_label <- paste0(min(response_filter), "-", max(response_filter))
    } else if (length(response_filter) > 1) {
      # For multiple categorical values, join them
      filter_label <- paste(response_filter, collapse = ", ")
    } else {
      # Single value
      filter_label <- as.character(response_filter)
    }

    # Mark which rows match the filter (don't filter yet!)
    if (is.numeric(plot_data[[response_var]]) && is.numeric(response_filter)) {
      plot_data <- plot_data %>%
        mutate(.filtered = !!sym(response_var) %in% response_filter)
    } else {
      response_filter_chr <- as.character(response_filter)
      plot_data <- plot_data %>%
        mutate(.filtered = as.character(!!sym(response_var)) %in% response_filter_chr)
    }

    # If combining, replace the response_var for filtered rows
    if (response_filter_combine) {
      plot_data <- plot_data %>%
        mutate(!!sym(response_var) := ifelse(.filtered, filter_label, as.character(!!sym(response_var))))
    }
  }

  # Handle response binning (applied AFTER filtering)
  if (!is.null(response_breaks)) {
    if (!is.numeric(plot_data[[response_var]])) {
      warning(paste0("'", response_var, "' is not numeric. Response binning ignored."), call. = FALSE)
    } else {
      plot_data <- plot_data %>%
        mutate(
          !!sym(response_var) := cut(!!sym(response_var),
                                     breaks = response_breaks,
                                     labels = response_bin_labels,
                                     include.lowest = TRUE,
                                     right = TRUE)
        )
    }
  }

  # Apply response level ordering if specified
  if (!is.null(response_levels)) {
    plot_data <- plot_data %>%
      mutate(!!sym(response_var) := factor(!!sym(response_var), levels = response_levels))
  }

  # Aggregate data - calculate percentages from ALL data (before filtering)
  if (is.null(group_var)) {
    if (!is.null(weight_var)) {
      if (!weight_var %in% names(plot_data)) {
        stop("`weight_var` '", weight_var, "' not found in data.", call. = FALSE)
      }
      agg_data <- plot_data %>%
        count(!!sym(time_var_plot), !!sym(response_var), wt = !!sym(weight_var), name = "count") %>%
        group_by(!!sym(time_var_plot)) %>%
        mutate(percentage = round(count / sum(count) * 100, 1)) %>%
        ungroup()
    } else {
      agg_data <- plot_data %>%
        count(!!sym(time_var_plot), !!sym(response_var), name = "count") %>%
        group_by(!!sym(time_var_plot)) %>%
        mutate(percentage = round(count / sum(count) * 100, 1)) %>%
        ungroup()
    }
  } else {
    if (!is.null(weight_var)) {
      if (!weight_var %in% names(plot_data)) {
        stop("`weight_var` '", weight_var, "' not found in data.", call. = FALSE)
      }
      agg_data <- plot_data %>%
        count(!!sym(time_var_plot), !!sym(response_var), !!sym(group_var), wt = !!sym(weight_var), name = "count") %>%
        group_by(!!sym(time_var_plot), !!sym(group_var)) %>%
        mutate(percentage = round(count / sum(count) * 100, 1)) %>%
        ungroup()
    } else {
      agg_data <- plot_data %>%
        count(!!sym(time_var_plot), !!sym(response_var), !!sym(group_var), name = "count") %>%
        group_by(!!sym(time_var_plot), !!sym(group_var)) %>%
        mutate(percentage = round(count / sum(count) * 100, 1)) %>%
        ungroup()
    }
  }

  # NOW filter to show only the desired response values
  if (filter_applied) {
    if (response_filter_combine) {
      # Show only the combined label
      agg_data <- agg_data %>%
        filter(!!sym(response_var) == filter_label)
    } else {
      # Show only the filtered individual values
      if (is.numeric(response_filter)) {
        response_filter_chr <- as.character(response_filter)
      } else {
        response_filter_chr <- response_filter
      }
      agg_data <- agg_data %>%
        filter(as.character(!!sym(response_var)) %in% response_filter_chr)
    }
  }

  # Determine if time_var is categorical
  is_time_categorical <- is.factor(plot_data[[time_var_plot]]) || is.character(plot_data[[time_var_plot]])

  # Get unique time categories if categorical (for proper x-axis ordering)
  if (is_time_categorical) {
    if (is.factor(plot_data[[time_var_plot]])) {
      time_categories <- levels(plot_data[[time_var_plot]])
    } else {
      time_categories <- unique(plot_data[[time_var_plot]])
    }
  }

  # Determine axis labels (use custom or defaults)
  x_axis_title <- if (!is.null(x_label)) {
    x_label
  } else if (is_time_categorical) {
    time_var
  } else if (!is.null(time_breaks)) {
    "Time Period"
  } else {
    time_var
  }

  y_axis_title <- if (!is.null(y_label)) y_label else "Percentage"

  # NA HANDLING - Apply AFTER mapping/filtering/binning
  if (!include_na) {
    # Filter out NAs
    plot_data <- plot_data %>%
      filter(!is.na(!!sym(response_var)))

    if (!is.null(group_var)) {
      plot_data <- plot_data %>%
        filter(!is.na(!!sym(group_var)))
    }
  } else {
    # Use helper function for explicit NA handling
    plot_data <- plot_data %>%
      mutate(
        !!sym(response_var) := handle_na_for_plotting(
          data = plot_data,
          var_name = response_var,
          include_na = TRUE,
          na_label = na_label_response,
          custom_order = response_levels
        )
      )

    if (!is.null(group_var)) {
      plot_data <- plot_data %>%
        mutate(
          !!sym(group_var) := handle_na_for_plotting(
            data = plot_data,
            var_name = group_var,
            include_na = TRUE,
            na_label = na_label_group,
            custom_order = NULL
          )
        )
    }
  }

  # Create base chart
  hc <- highchart() %>%
    hc_title(text = title) %>%
    hc_yAxis(title = list(text = y_axis_title), max = y_max, min = y_min)

  # Add subtitle if provided
  if (!is.null(subtitle)) {
    hc <- hc %>% hc_subtitle(text = subtitle)
  }

  # Configure x-axis based on whether time is categorical or numeric
  if (is_time_categorical) {
    hc <- hc %>%
      hc_xAxis(
        title = list(text = x_axis_title),
        categories = time_categories,
        type = "category"
      )
  } else {
    hc <- hc %>%
      hc_xAxis(title = list(text = x_axis_title))
  }

  # Apply color palette if provided
  if (!is.null(color_palette)) {
    hc <- hc %>% hc_colors(color_palette)
  }

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
          arrange(!!sym(time_var_plot))

        # For categorical time, use category names; for numeric, use values
        if (is_time_categorical) {
          series_data <- series_data %>%
            mutate(x = as.character(!!sym(time_var_plot))) %>%
            select(x, y = percentage)
        } else {
          series_data <- series_data %>%
            select(x = !!sym(time_var_plot), y = percentage)
        }

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
          arrange(!!sym(time_var_plot))

        # For categorical time, use category names; for numeric, use values
        if (is_time_categorical) {
          series_data <- series_data %>%
            mutate(x = as.character(!!sym(time_var_plot))) %>%
            select(x, y = percentage)
        } else {
          series_data <- series_data %>%
            select(x = !!sym(time_var_plot), y = percentage)
        }

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
            arrange(!!sym(time_var_plot))

          if(nrow(series_data) > 0) {
            # For categorical time, use category names; for numeric, use values
            if (is_time_categorical) {
              series_data <- series_data %>%
                mutate(x = as.character(!!sym(time_var_plot))) %>%
                select(x, y = percentage)
            } else {
              series_data <- series_data %>%
                select(x = !!sym(time_var_plot), y = percentage)
            }

            # Determine series name
            # If response_filter_label is NULL/NA/empty AND there's only one response level (e.g., from response_filter),
            # show only the group name. Otherwise, show "response - group".
            series_name <- if (is.null(response_filter_label) && length(response_levels_to_use) == 1) {
              as.character(group_level)
            } else {
              paste(resp_level, "-", group_level)
            }

            hc <- hc %>%
              hc_add_series(
                name = series_name,
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
