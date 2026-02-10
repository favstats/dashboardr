
# --------------------------------------------------------------------------
# Function: viz_timeline
# --------------------------------------------------------------------------
#' @title Create a Timeline Chart
#' @importFrom stats weighted.mean
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
#' @param backend Rendering backend: "highcharter" (default), "plotly", "echarts4r", or "ggiraph".
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
#' @param legend_position Position of the legend ("top", "bottom", "left", "right", "none")
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
                            title_map = NULL,
                            legend_position = NULL,
                            backend = "highcharter") {

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
        summarise(value = mean(!!sym(y_var), na.rm = TRUE), .groups = "drop")
    } else {
      agg_data <- plot_data %>%
        group_by(!!sym(time_var_plot), !!sym(group_var)) %>%
        summarise(value = mean(!!sym(y_var), na.rm = TRUE), .groups = "drop")
    }
  } else if (agg == "sum") {
    # Calculate sum per time period (and group if specified)
    if (is.null(group_var)) {
      agg_data <- plot_data %>%
        group_by(!!sym(time_var_plot)) %>%
        summarise(value = sum(!!sym(y_var), na.rm = TRUE), .groups = "drop")
    } else {
      agg_data <- plot_data %>%
        group_by(!!sym(time_var_plot), !!sym(group_var)) %>%
        summarise(value = sum(!!sym(y_var), na.rm = TRUE), .groups = "drop")
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

  # Build config for backend dispatch
  config <- list(
    title = title, subtitle = subtitle,
    x_axis_title = x_axis_title, y_axis_title = y_axis_title,
    y_max = y_max, y_min = y_min,
    color_palette = color_palette, chart_type = chart_type,
    y_levels = y_levels, group_var = group_var,
    group_order = group_order,
    is_time_categorical = is_time_categorical,
    time_categories = if (is_time_categorical) time_categories else NULL,
    time_var_plot = time_var_plot, y_var = y_var,
    value_col = value_col, agg = agg,
    tooltip = tooltip, tooltip_prefix = tooltip_prefix,
    tooltip_suffix = tooltip_suffix,
    cross_tab_filter_vars = cross_tab_filter_vars,
    title_map = title_map,
    filter_label = filter_label, filter_applied = filter_applied,
    plot_data = plot_data, data = data,
    weight_var = weight_var,
    time_var = time_var,
    x_label = x_label, y_label = y_label,
    y_filter_label = y_filter_label,
    legend_position = legend_position
  )

  # Prepare cross-tab data for client-side filtering (all backends)
  cross_tab_attrs <- NULL
  if (!is.null(cross_tab_filter_vars) && length(cross_tab_filter_vars) > 0) {
    valid_filter_vars <- cross_tab_filter_vars[cross_tab_filter_vars %in% names(data)]
    if (length(valid_filter_vars) > 0) {
      group_vars <- c(time_var, y_var, valid_filter_vars)
      if (!is.null(group_var)) group_vars <- c(group_vars, group_var)
      if (!is.null(weight_var) && weight_var %in% names(data) && is.numeric(data[[weight_var]])) {
        cross_tab <- data %>%
          dplyr::group_by(dplyr::across(dplyr::all_of(group_vars))) %>%
          dplyr::summarise(
            value = weighted.mean(.data[[y_var]], w = .data[[weight_var]], na.rm = TRUE),
            .groups = "drop"
          )
      } else {
        cross_tab <- data %>%
          dplyr::group_by(dplyr::across(dplyr::all_of(group_vars))) %>%
          dplyr::summarise(value = mean(.data[[y_var]], na.rm = TRUE), .groups = "drop")
      }
      chart_id <- paste0("crosstab_", substr(digest::digest(
        paste(time_var, y_var, group_var %||% "", collapse = "_")
      ), 1, 8))
      chart_config <- list(
        chartId = chart_id,
        chartType = "timeline",
        timeVar = time_var,
        yVar = y_var,
        groupVar = group_var,
        agg = agg,
        filterVars = valid_filter_vars,
        groupOrder = if (!is.null(group_order)) group_order else unique(as.character(cross_tab[[group_var %||% "group"]])),
        colorMap = if (!is.null(color_palette) && !is.null(names(color_palette))) as.list(color_palette) else NULL
      )
      if (!is.null(title) && grepl("\\{\\w+\\}", title)) {
        chart_config$titleTemplate <- title
      }
      if (!is.null(title_map) && is.list(title_map)) {
        tl_js <- lapply(names(title_map), function(nm) {
          list(values = as.list(title_map[[nm]]))
        })
        names(tl_js) <- names(title_map)
        chart_config$titleLookups <- tl_js
      }
      cross_tab_attrs <- list(data = cross_tab, config = chart_config, id = chart_id)
    }
  }

  # Dispatch to backend renderer
  backend <- .normalize_backend(backend)
  backend <- match.arg(backend, c("highcharter", "plotly", "echarts4r", "ggiraph"))
  .assert_backend_supported("timeline", backend)
  render_fn <- switch(backend,
    highcharter = .viz_timeline_highcharter,
    plotly      = .viz_timeline_plotly,
    echarts4r   = .viz_timeline_echarts,
    ggiraph     = .viz_timeline_ggiraph
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
.viz_timeline_highcharter <- function(agg_data, config) {
  # Unpack config
  title <- config$title; subtitle <- config$subtitle
  x_axis_title <- config$x_axis_title; y_axis_title <- config$y_axis_title
  y_max <- config$y_max; y_min <- config$y_min
  color_palette <- config$color_palette; chart_type <- config$chart_type
  y_levels <- config$y_levels; group_var <- config$group_var
  group_order <- config$group_order
  is_time_categorical <- config$is_time_categorical
  time_categories <- config$time_categories
  time_var_plot <- config$time_var_plot; y_var <- config$y_var
  value_col <- config$value_col; agg <- config$agg
  tooltip <- config$tooltip; tooltip_prefix <- config$tooltip_prefix
  tooltip_suffix <- config$tooltip_suffix
  cross_tab_filter_vars <- config$cross_tab_filter_vars
  title_map <- config$title_map
  filter_label <- config$filter_label; filter_applied <- config$filter_applied
  plot_data <- config$plot_data; data <- config$data
  weight_var <- config$weight_var
  time_var <- config$time_var
  x_label <- config$x_label; y_label <- config$y_label
  y_filter_label <- config$y_filter_label

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

  # --- Legend position ---
  hc <- .apply_legend_highcharter(hc, config$legend_position, default_show = TRUE)

  return(hc)
}

# --- Plotly backend ---
#' @keywords internal
.viz_timeline_plotly <- function(agg_data, config) {
  rlang::check_installed("plotly", reason = "to use backend = 'plotly'")

  time_var_plot <- config$time_var_plot
  y_var <- config$y_var
  group_var <- config$group_var
  value_col <- config$value_col
  chart_type <- config$chart_type
  agg <- config$agg
  color_palette <- config$color_palette
  title <- config$title
  x_axis_title <- config$x_axis_title
  y_axis_title <- config$y_axis_title
  y_max <- config$y_max
  y_min <- config$y_min
  group_order <- config$group_order

  mode <- switch(chart_type,
    "line" = "lines+markers",
    "spline" = "lines+markers",
    "area" =, "stacked_area" = "lines",
    "column" = NULL,
    "lines+markers"
  )
  is_bar <- chart_type %in% c("column", "bar")
  is_stacked <- chart_type == "stacked_area"
  fill_mode <- if (chart_type %in% c("area", "stacked_area")) "tozeroy" else "none"

  # For percentage mode without group_var, the y_var column acts as the grouping
  effective_group <- group_var
  if (is.null(effective_group) && agg == "percentage" && y_var %in% names(agg_data)) {
    effective_group <- y_var
  }

  if (is.null(effective_group)) {
    # Single series
    if (is_bar) {
      p <- plotly::plot_ly(agg_data, x = ~get(time_var_plot), y = ~get(value_col),
                           type = "bar", name = y_var)
    } else {
      p <- plotly::plot_ly(agg_data, x = ~get(time_var_plot), y = ~get(value_col),
                           type = "scatter", mode = mode, name = y_var,
                           fill = fill_mode)
    }
  } else {
    # Grouped series
    group_levels <- if (!is.null(group_order)) group_order else unique(agg_data[[effective_group]])
    p <- plotly::plot_ly()
    stackgroup <- if (is_stacked) "one" else NULL
    for (grp in group_levels) {
      grp_data <- agg_data[agg_data[[effective_group]] == grp, ]
      if (is_bar) {
        p <- plotly::add_trace(p, x = grp_data[[time_var_plot]], y = grp_data[[value_col]],
                               type = "bar", name = as.character(grp))
      } else {
        trace_args <- list(p = p, x = grp_data[[time_var_plot]], y = grp_data[[value_col]],
                           type = "scatter", mode = mode, name = as.character(grp),
                           fill = if (is_stacked) "tonexty" else fill_mode)
        if (!is.null(stackgroup)) trace_args$stackgroup <- stackgroup
        p <- do.call(plotly::add_trace, trace_args)
      }
    }
  }

  layout_args <- list(p = p, title = title)
  layout_args$xaxis <- list(title = x_axis_title)
  y_axis_cfg <- list(title = y_axis_title)
  if (!is.null(y_max)) y_axis_cfg$range <- c(y_min %||% 0, y_max)
  layout_args$yaxis <- y_axis_cfg
  p <- do.call(plotly::layout, layout_args)

  if (!is.null(color_palette)) {
    p <- plotly::layout(p, colorway = color_palette)
  }

  # --- Legend position ---
  p <- .apply_legend_plotly(p, config$legend_position, default_show = TRUE)

  p
}

# --- echarts4r backend ---
#' @keywords internal
.viz_timeline_echarts <- function(agg_data, config) {
  rlang::check_installed("echarts4r", reason = "to use backend = 'echarts4r'")

  time_var_plot <- config$time_var_plot
  group_var <- config$group_var
  y_var <- config$y_var
  value_col <- config$value_col
  chart_type <- config$chart_type
  agg <- config$agg
  color_palette <- config$color_palette
  title <- config$title
  subtitle <- config$subtitle
  x_axis_title <- config$x_axis_title
  y_axis_title <- config$y_axis_title
  y_max <- config$y_max
  y_min <- config$y_min

  agg_data[[time_var_plot]] <- as.character(agg_data[[time_var_plot]])

  # For percentage mode without group_var, the y_var column (e.g. happiness levels)

  # acts as the implicit grouping variable for separate series
  effective_group <- group_var
  if (is.null(effective_group) && agg == "percentage" && y_var %in% names(agg_data)) {
    effective_group <- y_var
  }

  if (is.null(effective_group)) {
    e <- agg_data |>
      echarts4r::e_charts_(time_var_plot)
  } else {
    agg_data[[effective_group]] <- as.character(agg_data[[effective_group]])
    e <- agg_data |>
      dplyr::group_by(.data[[effective_group]]) |>
      echarts4r::e_charts_(time_var_plot)
  }

  is_stacked <- chart_type == "stacked_area"

  e <- switch(chart_type,
    "line" =, "spline" = e |> echarts4r::e_line_(value_col, smooth = chart_type == "spline"),
    "area" = e |> echarts4r::e_area_(value_col),
    "stacked_area" = e |> echarts4r::e_area_(value_col, stack = "total"),
    "column" =, "bar" = e |> echarts4r::e_bar_(value_col),
    e |> echarts4r::e_line_(value_col)
  )

  if (!is.null(title) || !is.null(subtitle)) {
    e <- e |> echarts4r::e_title(text = title %||% "", subtext = subtitle %||% "")
  }

  e <- e |>
    echarts4r::e_x_axis(name = x_axis_title) |>
    echarts4r::e_y_axis(name = y_axis_title, max = y_max, min = y_min %||% .echarts_padded_min()) |>
    echarts4r::e_tooltip(trigger = "axis")

  if (!is.null(color_palette)) {
    e <- e |> echarts4r::e_color(color_palette)
  }

  # --- Legend position ---
  e <- .apply_legend_echarts(e, config$legend_position, default_show = TRUE)

  e
}

# --- ggiraph backend ---
#' @keywords internal
.viz_timeline_ggiraph <- function(agg_data, config) {
  rlang::check_installed("ggiraph", reason = "to use backend = 'ggiraph'")
  rlang::check_installed("ggplot2", reason = "to use backend = 'ggiraph'")

  time_var_plot <- config$time_var_plot
  group_var <- config$group_var
  y_var <- config$y_var
  value_col <- config$value_col
  chart_type <- config$chart_type
  agg <- config$agg
  color_palette <- config$color_palette
  title <- config$title
  subtitle <- config$subtitle
  x_axis_title <- config$x_axis_title
  y_axis_title <- config$y_axis_title
  y_max <- config$y_max
  y_min <- config$y_min

  # For percentage mode without group_var, the y_var column acts as the grouping
  effective_group <- group_var
  if (is.null(effective_group) && agg == "percentage" && y_var %in% names(agg_data)) {
    effective_group <- y_var
  }

  # Build tooltip
  agg_data$.tooltip <- paste0(
    agg_data[[time_var_plot]],
    if (!is.null(effective_group)) paste0(" (", agg_data[[effective_group]], ")") else "",
    ": ", round(agg_data[[value_col]], 2)
  )

  is_stacked <- chart_type == "stacked_area"

  aes_base <- if (is.null(effective_group)) {
    ggplot2::aes(x = .data[[time_var_plot]], y = .data[[value_col]])
  } else {
    ggplot2::aes(x = .data[[time_var_plot]], y = .data[[value_col]],
                 color = .data[[effective_group]], group = .data[[effective_group]])
  }

  p <- ggplot2::ggplot(agg_data, aes_base)

  if (chart_type %in% c("column", "bar")) {
    fill_aes <- if (!is.null(effective_group)) {
      ggplot2::aes(fill = .data[[effective_group]], tooltip = .data$.tooltip, data_id = .data[[time_var_plot]])
    } else {
      ggplot2::aes(tooltip = .data$.tooltip, data_id = .data[[time_var_plot]])
    }
    p <- p + ggiraph::geom_bar_interactive(fill_aes, stat = "identity",
                                            position = if (!is.null(effective_group)) "dodge" else "identity")
  } else if (chart_type %in% c("area", "stacked_area")) {
    fill_aes <- if (!is.null(effective_group)) {
      ggplot2::aes(fill = .data[[effective_group]])
    } else {
      NULL
    }
    position_arg <- if (is_stacked) "stack" else "identity"
    p <- p +
      ggplot2::geom_area(fill_aes, alpha = 0.3, position = position_arg) +
      ggiraph::geom_point_interactive(ggplot2::aes(tooltip = .data$.tooltip, data_id = .data[[time_var_plot]]))
  } else {
    p <- p +
      ggplot2::geom_line() +
      ggiraph::geom_point_interactive(ggplot2::aes(tooltip = .data$.tooltip, data_id = .data[[time_var_plot]]))
  }

  if (!is.null(color_palette)) {
    p <- p + ggplot2::scale_color_manual(values = color_palette)
    if (is_stacked || chart_type == "area") {
      p <- p + ggplot2::scale_fill_manual(values = color_palette)
    }
  }

  p <- p +
    ggplot2::labs(title = title, subtitle = subtitle,
                  x = x_axis_title, y = y_axis_title) +
    ggplot2::theme_minimal()

  if (!is.null(y_max) || !is.null(y_min)) {
    p <- p + ggplot2::coord_cartesian(ylim = c(y_min, y_max))
  }

  # --- Legend position ---
  p <- .apply_legend_ggplot(p, config$legend_position, default_show = TRUE)

  ggiraph::girafe(ggobj = p)
}
