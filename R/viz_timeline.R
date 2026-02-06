
# --------------------------------------------------------------------------
# Function: viz_timeline
# --------------------------------------------------------------------------
#' @title Create a Timeline Chart
#' @description
#' Creates interactive timeline visualizations showing changes in survey
#' responses over time, or simple line charts for pre-aggregated time series data.
#' Supports multiple chart types including stacked areas, line charts, and 
#' diverging bar charts.
#'
#' @param data A data frame containing time series data.
#' @param time_var Character string. Name of the time variable (e.g., "year", "wave").
#' @param y_var Character string. Name of the response/value variable.
#' @param group_var Optional character string. Name of grouping variable for separate series
#'   (e.g., "country", "gender"). Creates separate lines/areas for each group.
#' @param agg Character string specifying aggregation method:
#'   \itemize{
#'     \item \code{"percentage"} (default): Count responses and calculate percentages per time period.
#'       Use for survey data with categorical responses.
#'     \item \code{"mean"}: Calculate mean of y_var per time period (and group if specified).
#'     \item \code{"sum"}: Calculate sum of y_var per time period (and group if specified).
#'     \item \code{"none"}: Use values directly without aggregation. Use for pre-aggregated data
#'       where each row represents one observation per time/group combination.
#'   }
#' @param chart_type Character string. Type of chart: "line" (default) or "stacked_area".
#' @param title Optional main title for the chart.
#' @param subtitle Optional subtitle for the chart.
#' @param x_label Optional character string. Label for the x-axis. Defaults to time_var name.
#' @param y_label Optional character string. Label for the y-axis. Defaults to "Percentage" for
#'   \code{agg = "percentage"}, or y_var name for other modes.
#' @param y_max Optional numeric value. Maximum value for the Y-axis.
#' @param y_min Optional numeric value. Minimum value for the Y-axis.
#' @param color_palette Optional character vector of color hex codes for the series.
#' @param y_levels Optional character vector specifying order of response categories.
#' @param y_breaks Optional numeric vector for binning numeric response values
#'   (e.g., `c(0, 2.5, 5, 7)` to create bins 0-2.5, 2.5-5, 5-7).
#' @param y_bin_labels Optional character vector of labels for response bins
#'   (e.g., `c("Low (1-2)", "Medium (3-5)", "High (6-7)")`).
#' @param y_map_values Optional named list to rename response values for display
#'   (e.g., `list("1" = "Correct", "0" = "Incorrect")`). Applied to legend labels and data.
#' @param y_filter Optional numeric or character vector specifying which response values to include.
#'   For numeric responses, use a range like `5:7` to show only values 5, 6, and 7.
#'   For categorical responses, use category names like `c("Agree", "Strongly Agree")`.
#'   Applied BEFORE binning (filters raw values first, then bins the filtered data).
#' @param y_filter_combine Logical. When `y_filter` is used, should filtered values be combined
#'   into a single percentage? Defaults to `TRUE` (show combined % of all filtered values).
#'   Set to `FALSE` to show separate lines for each filtered value.
#' @param y_filter_label Character string. Custom label for the filtered responses in the legend.
#'   Only used when `y_filter` and `y_filter_combine = TRUE`.
#'   If `NULL` (default) and `group_var` is provided, shows only group names in legend (e.g., "AgeGroup1").
#'   If `NULL` and no `group_var`, uses auto-generated label (e.g., "5-7" for `y_filter = 5:7`).
#' @param time_breaks Optional numeric vector for binning continuous time variables.
#' @param time_bin_labels Optional character vector of labels for time bins.
#' @param tooltip A tooltip configuration created with \code{\link{tooltip}()}, 
#'   OR a format string with \{placeholders\}. Available placeholders: 
#'   \code{\{x\}}, \code{\{y\}}, \code{\{value\}}, \code{\{series\}}, \code{\{percent\}}.
#'   See \code{\link{tooltip}} for full customization options.
#' @param tooltip_prefix Optional string prepended to values in tooltip.
#' @param tooltip_suffix Optional string appended to values in tooltip.
#' @param weight_var Optional string. Name of a weight variable for weighted calculations.
#' @param include_na Logical. If TRUE, NA values are included as explicit categories. Default FALSE.
#' @param na_label_y Character string. Label for NA values in the response variable. Default "(Missing)".
#' @param na_label_group Character string. Label for NA values in the group variable. Default "(Missing)".
#' @param group_order Optional character vector specifying display order of group levels.
#' @param cross_tab_filter_vars Character vector. Variables for cross-tab filtering
#'   (typically auto-detected from sidebar inputs).
#' @param title_map Named list mapping variable names to custom display titles
#'   for dynamic title updates when filtering by cross-tab variables.
#'
#' @return A highcharter plot object.
#'
#' @examples
#' \dontrun{
#' # Load GSS data
#' data(gss_all)
#'
#' # Basic timeline - confidence in institutions over time
#' plot1 <- viz_timeline(
#'   data = gss_all,
#'   time_var = "year",
#'   y_var = "confinan",
#'   title = "Confidence in Financial Institutions Over Time",
#'   y_max = 100
#' )
#' plot1
#'
#' # Line chart by gender
#' plot2 <- viz_timeline(
#'   data = gss_all,
#'   time_var = "year",
#'   y_var = "happy",
#'   group_var = "sex",
#'   chart_type = "line",
#'   title = "Happiness Trends by Gender",
#'   y_levels = c("very happy", "pretty happy", "not too happy")
#' )
#' plot2
#'
#' # Show only high responses (5-7 on a 1-7 scale) - COMBINED
#' plot3 <- viz_timeline(
#'   data = survey_data,
#'   time_var = "wave",
#'   y_var = "agreement",
#'   group_var = "age_group",
#'   chart_type = "line",
#'   y_filter = 5:7,
#'   title = "% High Agreement (5-7) Over Time"
#' )
#' plot3
#' }
#'
#' @export


viz_timeline <- function(data,
                            time_var,
                            y_var,
                            group_var = NULL,
                            agg = c("percentage", "mean", "sum", "none"),
                            chart_type = "line",
                            title = NULL,
                            subtitle = NULL,
                            x_label = NULL,
                            y_label = NULL,
                            y_max = NULL,
                            y_min = NULL,
                            color_palette = NULL,
                            y_levels = NULL,
                            y_breaks = NULL,
                            y_bin_labels = NULL,
                            y_map_values = NULL,
                            y_filter = NULL,
                            y_filter_combine = TRUE,
                            y_filter_label = NULL,
                            time_breaks = NULL,
                            time_bin_labels = NULL,
                            weight_var = NULL,
                            include_na = FALSE,
                            na_label_y = "(Missing)",
                            na_label_group = "(Missing)",
                            tooltip = NULL,
                            tooltip_prefix = "",
                            tooltip_suffix = "",
                            group_order = NULL,
                            # Cross-tab filtering for sidebar inputs (auto-detected)
                            cross_tab_filter_vars = NULL,
                            title_map = NULL) {

  # Convert variable arguments to strings (supports both quoted and unquoted)
  time_var <- .as_var_string(rlang::enquo(time_var))
  y_var <- .as_var_string(rlang::enquo(y_var))

  group_var <- .as_var_string(rlang::enquo(group_var))
  weight_var <- .as_var_string(rlang::enquo(weight_var))
  
  # Validate and set aggregation mode
  agg <- match.arg(agg)

  # INPUT VALIDATION
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  if (is.null(time_var)) {
    .stop_with_hint("time_var", example = "viz_timeline(data, time_var = \"year\", y_var = \"score\")")
  }
  if (is.null(y_var)) {
    .stop_with_hint("y_var", example = "viz_timeline(data, time_var = \"year\", y_var = \"score\")")
  }

  # Basic data processing
  vars_to_select <- c(time_var, y_var)
  if (!is.null(group_var)) vars_to_select <- c(vars_to_select, group_var)
  if (!is.null(weight_var)) vars_to_select <- c(vars_to_select, weight_var)

  plot_data <- data %>%
    select(all_of(vars_to_select)) %>%
    filter(!is.na(!!sym(time_var)), !is.na(!!sym(y_var)))

  if (!is.null(group_var)) {
    plot_data <- plot_data %>% filter(!is.na(!!sym(group_var)))
  }

  # Handle haven_labelled variables
  if (requireNamespace("haven", quietly = TRUE)) {
    if (inherits(plot_data[[time_var]], "haven_labelled")) {
      plot_data <- plot_data %>%
        mutate(!!sym(time_var) := as.numeric(!!sym(time_var)))
    }
    if (inherits(plot_data[[y_var]], "haven_labelled")) {
      plot_data <- plot_data %>%
        mutate(!!sym(y_var) := haven::as_factor(!!sym(y_var), levels = "labels"))
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
  if (!is.null(y_map_values)) {
    # Convert factor to character to ensure recode works
    if (is.factor(plot_data[[y_var]])) {
      plot_data <- plot_data %>%
        mutate(!!sym(y_var) := as.character(!!sym(y_var)))
    }
    # Apply the mapping
    plot_data <- plot_data %>%
      mutate(!!sym(y_var) := dplyr::recode(as.character(!!sym(y_var)), !!!y_map_values))
  }

  # Handle response filtering - mark filtered values before aggregation
  # This ensures percentages are calculated correctly (out of ALL responses, not just filtered ones)
  filter_applied <- !is.null(y_filter)
  filter_label <- NULL

  if (filter_applied) {
    # Create a label for the filtered values
    # Use custom label if provided, otherwise auto-generate
    if (!is.null(y_filter_label) && y_filter_combine) {
      # User provided custom label
      filter_label <- y_filter_label
    } else if (is.numeric(y_filter) && length(y_filter) > 1) {
      # For numeric ranges, create a label like "5-7"
      filter_label <- paste0(min(y_filter), "-", max(y_filter))
    } else if (length(y_filter) > 1) {
      # For multiple categorical values, join them
      filter_label <- paste(y_filter, collapse = ", ")
    } else {
      # Single value
      filter_label <- as.character(y_filter)
    }

    # Mark which rows match the filter (don't filter yet!)
    if (is.numeric(plot_data[[y_var]]) && is.numeric(y_filter)) {
      plot_data <- plot_data %>%
        mutate(.filtered = !!sym(y_var) %in% y_filter)
    } else {
      y_filter_chr <- as.character(y_filter)
      plot_data <- plot_data %>%
        mutate(.filtered = as.character(!!sym(y_var)) %in% y_filter_chr)
    }

    # If combining, replace the y_var for filtered rows
    if (y_filter_combine) {
      plot_data <- plot_data %>%
        mutate(!!sym(y_var) := ifelse(.filtered, filter_label, as.character(!!sym(y_var))))
    }
  }

  # Handle response binning (applied AFTER filtering)
  if (!is.null(y_breaks)) {
    if (!is.numeric(plot_data[[y_var]])) {
      warning(paste0("'", y_var, "' is not numeric. Response binning ignored."), call. = FALSE)
    } else {
      plot_data <- plot_data %>%
        mutate(
          !!sym(y_var) := cut(!!sym(y_var),
                                     breaks = y_breaks,
                                     labels = y_bin_labels,
                                     include.lowest = TRUE,
                                     right = TRUE)
        )
    }
  }

  # Apply response level ordering if specified
  if (!is.null(y_levels)) {
    plot_data <- plot_data %>%
      mutate(!!sym(y_var) := factor(!!sym(y_var), levels = y_levels))
  }

  # Aggregate data based on agg mode
  if (agg == "none") {
    # No aggregation - use values directly (for pre-aggregated data)
    # Rename y_var to 'value' for consistency with chart generation
    if (is.null(group_var)) {
      agg_data <- plot_data %>%
        select(!!sym(time_var_plot), value = !!sym(y_var))
    } else {
      agg_data <- plot_data %>%
        select(!!sym(time_var_plot), !!sym(group_var), value = !!sym(y_var))
    }
  } else if (agg == "mean") {
    # Calculate mean per time period (and group if specified)
    if (is.null(group_var)) {
      agg_data <- plot_data %>%
        group_by(!!sym(time_var_plot)) %>%
        summarize(value = mean(!!sym(y_var), na.rm = TRUE), .groups = "drop")
    } else {
      agg_data <- plot_data %>%
        group_by(!!sym(time_var_plot), !!sym(group_var)) %>%
        summarize(value = mean(!!sym(y_var), na.rm = TRUE), .groups = "drop")
    }
  } else if (agg == "sum") {
    # Calculate sum per time period (and group if specified)
    if (is.null(group_var)) {
      agg_data <- plot_data %>%
        group_by(!!sym(time_var_plot)) %>%
        summarize(value = sum(!!sym(y_var), na.rm = TRUE), .groups = "drop")
    } else {
      agg_data <- plot_data %>%
        group_by(!!sym(time_var_plot), !!sym(group_var)) %>%
        summarize(value = sum(!!sym(y_var), na.rm = TRUE), .groups = "drop")
    }
  } else {
    # agg == "percentage" - original behavior: count and calculate percentages
    if (is.null(group_var)) {
      if (!is.null(weight_var)) {
        if (!weight_var %in% names(plot_data)) {
          stop("`weight_var` '", weight_var, "' not found in data.", call. = FALSE)
        }
        agg_data <- plot_data %>%
          count(!!sym(time_var_plot), !!sym(y_var), wt = !!sym(weight_var), name = "count") %>%
          group_by(!!sym(time_var_plot)) %>%
          mutate(percentage = round(count / sum(count) * 100, 1)) %>%
          ungroup()
      } else {
        agg_data <- plot_data %>%
          count(!!sym(time_var_plot), !!sym(y_var), name = "count") %>%
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
          count(!!sym(time_var_plot), !!sym(y_var), !!sym(group_var), wt = !!sym(weight_var), name = "count") %>%
          group_by(!!sym(time_var_plot), !!sym(group_var)) %>%
          mutate(percentage = round(count / sum(count) * 100, 1)) %>%
          ungroup()
      } else {
        agg_data <- plot_data %>%
          count(!!sym(time_var_plot), !!sym(y_var), !!sym(group_var), name = "count") %>%
          group_by(!!sym(time_var_plot), !!sym(group_var)) %>%
          mutate(percentage = round(count / sum(count) * 100, 1)) %>%
          ungroup()
      }
    }
  }

  # NOW filter to show only the desired response values
  if (filter_applied) {
    if (y_filter_combine) {
      # Show only the combined label
      agg_data <- agg_data %>%
        filter(!!sym(y_var) == filter_label)
    } else {
      # Show only the filtered individual values
      if (is.numeric(y_filter)) {
        y_filter_chr <- as.character(y_filter)
      } else {
        y_filter_chr <- y_filter
      }
      agg_data <- agg_data %>%
        filter(as.character(!!sym(y_var)) %in% y_filter_chr)
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

  y_axis_title <- if (!is.null(y_label)) {
    y_label
  } else if (agg == "percentage") {
    "Percentage"
  } else if (agg == "mean") {
    paste0("Mean ", y_var)
  } else if (agg == "sum") {
    paste0("Total ", y_var)
  } else {
    # agg == "none"
    y_var
  }
  
  # Determine the value column to use for charting
  value_col <- if (agg == "percentage") "percentage" else "value"

  # NA HANDLING - Apply AFTER mapping/filtering/binning
  if (!include_na) {
    # Filter out NAs
    plot_data <- plot_data %>%
      filter(!is.na(!!sym(y_var)))

    if (!is.null(group_var)) {
      plot_data <- plot_data %>%
        filter(!is.na(!!sym(group_var)))
    }
  } else {
    # Use helper function for explicit NA handling
    plot_data <- plot_data %>%
      mutate(
        !!sym(y_var) := handle_na_for_plotting(
          data = plot_data,
          var_name = y_var,
          include_na = TRUE,
          na_label = na_label_y,
          custom_order = y_levels
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
    hc <- hc %>% highcharter::hc_subtitle(text = subtitle)
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
    # For numeric time (e.g., years), prevent decimal ticks
    hc <- hc %>%
      hc_xAxis(
        title = list(text = x_axis_title),
        allowDecimals = FALSE
      )
  }

  # Apply color palette if provided
  # Named vector = per-series color map; unnamed = positional color cycle
  .color_named <- if (!is.null(color_palette) && !is.null(names(color_palette))) color_palette else NULL
  if (!is.null(color_palette) && is.null(names(color_palette))) {
    hc <- hc %>% highcharter::hc_colors(color_palette)
  }
  .sc <- function(nm) {
    nm <- as.character(nm)
    if (!is.null(.color_named) && nm %in% names(.color_named)) .color_named[[nm]] else NULL
  }

  # Create chart based on type
  if (chart_type == "stacked_area") {
    hc <- hc %>%
      hc_chart(type = "area") %>%
      hc_plotOptions(area = list(stacking = "normal"))

    if (is.null(group_var)) {
      # SPECIAL CASE: agg = "none" with no group_var - create single series
      # (pre-aggregated data where each row is a data point, not a category)
      if (agg == "none") {
        series_data <- agg_data %>%
          arrange(!!sym(time_var_plot))
        
        if (is_time_categorical) {
          series_data <- series_data %>%
            mutate(x = as.character(!!sym(time_var_plot))) %>%
            select(x, y = value)
        } else {
          series_data <- series_data %>%
            select(x = !!sym(time_var_plot), y = value)
        }
        
        hc <- hc %>%
          hc_add_series(
            name = y_var,
            data = list_parse2(series_data),
            type = "area"
          )
      } else {
        # Standard case: loop over unique y_var levels (for categorical responses)
        y_levels_to_use <- if (!is.null(y_levels)) y_levels else unique(agg_data[[y_var]])
        for(level in y_levels_to_use) {
          series_data <- agg_data %>%
            filter(!!sym(y_var) == level) %>%
            arrange(!!sym(time_var_plot))

          # For categorical time, use category names; for numeric, use values
          if (is_time_categorical) {
            series_data <- series_data %>%
              mutate(x = as.character(!!sym(time_var_plot))) %>%
              select(x, y = !!sym(value_col))
          } else {
            series_data <- series_data %>%
              select(x = !!sym(time_var_plot), y = !!sym(value_col))
          }

          hc <- hc %>%
            hc_add_series(
              name = as.character(level),
              data = list_parse2(series_data),
              type = "area",
              color = .sc(level)
            )
        }
      }
    } else {
      # group_var is present - create one series per group
      if (agg == "none") {
        # Pre-aggregated data with groups - one series per group_var level
        group_levels <- unique(agg_data[[group_var]])
        if (!is.null(group_order)) {
          group_levels <- intersect(group_order, group_levels)
        }
        
        for (group_level in group_levels) {
          series_data <- agg_data %>%
            filter(!!sym(group_var) == group_level) %>%
            arrange(!!sym(time_var_plot))
          
          if (nrow(series_data) == 0) next
          
          if (is_time_categorical) {
            series_data <- series_data %>%
              mutate(x = as.character(!!sym(time_var_plot))) %>%
              select(x, y = value)
          } else {
            series_data <- series_data %>%
              select(x = !!sym(time_var_plot), y = value)
          }
          
          hc <- hc %>%
            hc_add_series(
              name = as.character(group_level),
              data = list_parse2(series_data),
              type = "area",
              color = .sc(group_level)
            )
        }
      }
      # Note: other agg modes with group_var are handled by existing code below
    }

  } else if (chart_type == "line") {
    hc <- hc %>% hc_chart(type = "line")

    # SPECIAL CASE: numeric response with grouping in percentage mode -> weighted mean per group
    # This is ONLY for percentage mode - other modes already have the correct agg_data
    if (agg == "percentage" && !is.null(group_var) && is.numeric(plot_data[[y_var]])) {
      if (!is.null(weight_var)) {
        if (!weight_var %in% names(plot_data)) {
          stop("`weight_var` '", weight_var, "' not found in data.", call. = FALSE)
        }
        agg_data <- plot_data %>%
          group_by(!!sym(time_var_plot), !!sym(group_var)) %>%
          summarise(
            value = {
              w <- !!sym(weight_var)
              v <- !!sym(y_var)
              if (sum(w, na.rm = TRUE) == 0) NA_real_ else sum(v * w, na.rm = TRUE) / sum(w, na.rm = TRUE)
            },
            .groups = "drop"
          )
      } else {
        agg_data <- plot_data %>%
          group_by(!!sym(time_var_plot), !!sym(group_var)) %>%
          summarise(
            value = mean(!!sym(y_var), na.rm = TRUE),
            .groups = "drop"
          )
      }

      group_levels <- unique(agg_data[[group_var]])
      if (!is.null(group_order)) {
        group_levels <- intersect(group_order, group_levels)
      }

      for (group_level in group_levels) {
        series_data <- agg_data %>%
          filter(!!sym(group_var) == group_level) %>%
          arrange(!!sym(time_var_plot))

        if (nrow(series_data) == 0) next

        # For categorical time, use category names; for numeric, use values
        if (is_time_categorical) {
          series_data <- series_data %>%
            mutate(x = as.character(!!sym(time_var_plot))) %>%
            select(x, y = value)
        } else {
          series_data <- series_data %>%
            select(x = !!sym(time_var_plot), y = value)
        }

        hc <- hc %>%
          hc_add_series(
            name = as.character(group_level),
            data = list_parse2(series_data),
            type = "line",
            color = .sc(group_level)
          )
      }

    }
    # For non-percentage modes (none, mean, sum), use simpler chart generation
    else if (agg != "percentage") {
      if (is.null(group_var)) {
        # Single series - just plot value over time
        series_data <- agg_data %>%
          arrange(!!sym(time_var_plot))
        
        if (is_time_categorical) {
          series_data <- series_data %>%
            mutate(x = as.character(!!sym(time_var_plot))) %>%
            select(x, y = value)
        } else {
          series_data <- series_data %>%
            select(x = !!sym(time_var_plot), y = value)
        }
        
        hc <- hc %>%
          hc_add_series(
            name = y_var,
            data = list_parse2(series_data),
            type = "line"
          )
      } else {
        # Multiple series - one per group
        group_levels <- unique(agg_data[[group_var]])
        if (!is.null(group_order)) {
          group_levels <- intersect(group_order, group_levels)
        }
        
        for (group_level in group_levels) {
          series_data <- agg_data %>%
            filter(!!sym(group_var) == group_level) %>%
            arrange(!!sym(time_var_plot))
          
          if (nrow(series_data) == 0) next
          
          if (is_time_categorical) {
            series_data <- series_data %>%
              mutate(x = as.character(!!sym(time_var_plot))) %>%
              select(x, y = value)
          } else {
            series_data <- series_data %>%
              select(x = !!sym(time_var_plot), y = value)
          }
          
          hc <- hc %>%
            hc_add_series(
              name = as.character(group_level),
              data = list_parse2(series_data),
              type = "line",
              color = .sc(group_level)
            )
        }
      }
      
    }
    # Percentage mode: original behavior with y_var levels
    else
    if (is.null(group_var)) {
      y_levels_to_use <- if (!is.null(y_levels)) y_levels else unique(agg_data[[y_var]])
      for(level in y_levels_to_use) {
        series_data <- agg_data %>%
          filter(!!sym(y_var) == level) %>%
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
            type = "line",
            color = .sc(level)
          )
      }
    } else {
      y_levels_to_use <- if (!is.null(y_levels)) y_levels else unique(agg_data[[y_var]])
      group_levels <- unique(agg_data[[group_var]])
      if (!is.null(group_order)) {
        group_levels <- intersect(group_order, group_levels)
      }

      for(resp_level in y_levels_to_use) {
        for(group_level in group_levels) {
          series_data <- agg_data %>%
            filter(!!sym(y_var) == resp_level, !!sym(group_var) == group_level) %>%
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
            # If y_filter_label is NULL/NA/empty AND there's only one response level (e.g., from y_filter),
            # show only the group name. Otherwise, show "response - group".
            series_name <- if (is.null(y_filter_label) && length(y_levels_to_use) == 1) {
              as.character(group_level)
            } else {
              paste(resp_level, "-", group_level)
            }

            hc <- hc %>%
              hc_add_series(
                name = series_name,
                data = list_parse2(series_data),
                type = "line",
                color = .sc(group_level)
              )
          }
        }
      }
    }
  }

  # \u2500\u2500\u2500 TOOLTIP \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
  if (!is.null(tooltip)) {
    # Use new unified tooltip system
    tooltip_result <- .process_tooltip_config(
      tooltip = tooltip,
      tooltip_prefix = tooltip_prefix,
      tooltip_suffix = tooltip_suffix,
      x_tooltip_suffix = NULL,
      chart_type = "timeline",
      context = list(
        x_label = x_label %||% time_var,
        y_label = y_label %||% "Percentage"
      )
    )
    hc <- .apply_tooltip_to_hc(hc, tooltip_result)
  } else {
    # Default tooltip with prefix/suffix
    pre <- if (is.null(tooltip_prefix) || tooltip_prefix == "") "" else tooltip_prefix
    suf <- if (is.null(tooltip_suffix) || tooltip_suffix == "") "%" else tooltip_suffix
    
    hc <- hc %>%
      highcharter::hc_tooltip(
        useHTML = TRUE,
        headerFormat = "<b>{point.x}</b><br>",
        pointFormat = paste0("{series.name}: ", pre, "{point.y:.1f}", suf)
      )
  }

  # Generate cross-tab for client-side filtering if filter_vars are provided
  if (!is.null(cross_tab_filter_vars) && length(cross_tab_filter_vars) > 0) {
    valid_filter_vars <- cross_tab_filter_vars[cross_tab_filter_vars %in% names(data)]

    if (length(valid_filter_vars) > 0) {
      # Build cross-tab: group by time + group + filter vars, keep y_var
      ct_group_vars <- c(time_var, valid_filter_vars)
      if (!is.null(group_var)) ct_group_vars <- c(ct_group_vars, group_var)

      cross_tab <- data %>%
        dplyr::group_by(dplyr::across(dplyr::all_of(ct_group_vars))) %>%
        dplyr::summarise(value = mean(!!rlang::sym(y_var), na.rm = TRUE), .groups = "drop")

      chart_id <- paste0("crosstab_", substr(digest::digest(
        paste(time_var, group_var %||% "", collapse = "_")), 1, 8))

      chart_config <- list(
        chartId    = chart_id,
        chartType  = "timeline",
        timeVar    = time_var,
        yVar       = y_var,
        groupVar   = group_var,
        filterVars = valid_filter_vars,
        groupOrder = if (!is.null(group_order)) as.list(group_order) else NULL,
        colorMap = if (!is.null(.color_named)) as.list(.color_named) else NULL
      )

      # Dynamic title: if title contains {var} placeholders, store the template
      if (!is.null(title) && grepl("\\{\\w+\\}", title)) {
        chart_config$titleTemplate <- title
      }

      # Title map: derived placeholders from named vectors
      # e.g. title_map = list(key_response = c("Marijuana" = "Legal", ...))
      if (!is.null(title_map) && is.list(title_map)) {
        tl_js <- lapply(names(title_map), function(nm) {
          list(values = as.list(title_map[[nm]]))
        })
        names(tl_js) <- names(title_map)
        chart_config$titleLookups <- tl_js
      }

      attr(hc, "cross_tab_data")   <- cross_tab
      attr(hc, "cross_tab_config") <- chart_config
      attr(hc, "cross_tab_id")     <- chart_id

      hc <- highcharter::hc_chart(hc, id = chart_id)
    }
  }

  return(hc)
}
