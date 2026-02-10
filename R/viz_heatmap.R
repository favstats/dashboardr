# --------------------------------------------------------------------------
# Function: viz_heatmap
# --------------------------------------------------------------------------
#' @title Create a Heatmap
#' @description This function creates a heatmap for bivariate data, visualizing
#'   the relationship between two categorical variables and a numeric value
#'   using color intensity. It handles ordered factors, ensures all combinations
#'   are plotted, and allows for extensive customization. It also includes
#'   robust handling of missing values (NA) by allowing them to be displayed
#'   as explicit categories.
#'
#' @param data A data frame containing the variables to plot.
#' @param x_var String. Name of the column for the X-axis categories.
#' @param y_var String. Name of the column for the Y-axis categories.
#' @param value_var String. Name of the numeric column whose values will
#'   determine the color intensity.
#' @param title Optional string. Main chart title.
#' @param subtitle Optional string. Chart subtitle.
#' @param x_label Optional string. X-axis label. Defaults to `x_var`.
#' @param y_label Optional string. Y-axis label. Defaults to `y_var`.
#' @param value_label Optional string. Label for the color axis. Defaults to `value_var`.
#' @param tooltip A tooltip configuration created with \code{\link{tooltip}()}, 
#'   OR a format string with \{placeholders\}. Available placeholders: 
#'   \code{\{x\}}, \code{\{y\}}, \code{\{value\}}, \code{\{name\}}.
#'   See \code{\link{tooltip}} for full customization options.
#' @param tooltip_prefix Optional string prepended in the tooltip value (simple customization).
#' @param tooltip_suffix Optional string appended in the tooltip value (simple customization).
#' @param x_tooltip_suffix Optional string appended to x value in tooltip.
#' @param y_tooltip_suffix Optional string appended to y value in tooltip.
#' @param x_tooltip_prefix Optional string prepended to x value in tooltip.
#' @param y_tooltip_prefix Optional string prepended to y value in tooltip.
#' @param x_order Optional character vector to order the factor levels of `x_var`.
#'   Alternatively, use `x_order_by` to order by aggregated values.
#' @param y_order Optional character vector to order the factor levels of `y_var`.
#'   Alternatively, use `y_order_by` to order by aggregated values.
#' @param x_order_by Optional. Order x-axis categories by aggregated value.
#'   Can be "asc" (ascending), "desc" (descending), or NULL (default, no reordering).
#'   When set, categories are sorted by their mean value across all y categories.
#' @param y_order_by Optional. Order y-axis categories by aggregated value.
#'   Can be "asc" (ascending), "desc" (descending), or NULL (default, no reordering).
#'   When set, categories are sorted by their mean value across all x categories.
#' @param color_min Optional numeric. Minimum value for the color axis. If NULL, defaults to data min.
#' @param color_max Optional numeric. Maximum value for the color axis. If NULL, defaults to data max.
#' @param color_palette Optional character vector of colors for the color gradient.
#'   Example: `c("#FFFFFF", "#7CB5EC")` for white to light blue. Can also be a single color for gradient start.
#' @param na_color Optional string. Color for NA values in `value_var` cells. Default "transparent".
#' @param data_labels_enabled Logical. If TRUE, display data labels on each cell. Default TRUE.
#' @param label_decimals Integer. Number of decimal places for data labels and tooltips.
#'   Default is 1. Set to 0 for whole numbers, 2 for two decimal places, etc.
#'   Ignored if `tooltip_labels_format` is explicitly provided.
#' @param tooltip_labels_format Optional string. Format for data labels. Default NULL
#'   (auto-generated from `label_decimals`). If provided, overrides `label_decimals`.
#' @param include_na Logical. If TRUE, treats NA values in `x_var` or `y_var`
#'   as explicit categories using `na_label_x` and `na_label_y`. If FALSE (default),
#'   rows with NA in `x_var` or `y_var` are excluded from aggregation.
#' @param na_label_x Optional string. Custom label for NA values in `x_var`. Defaults to "(Missing)".
#' @param na_label_y Optional string. Custom label for NA values in `y_var`. Defaults to "(Missing)".
#' @param x_map_values Optional named list to recode x_var values for display.
#' @param y_map_values Optional named list to recode y_var values for display.
#' @param agg_fun Function to aggregate duplicate x/y combinations. Default is `mean`.
#'   Note: If `weight_var` is provided, weighted mean is used instead and this parameter is ignored.
#' @param weight_var Optional string. Name of a weight variable to use for weighted mean aggregation.
#'   When provided, the function uses `weighted.mean()` instead of the `agg_fun` parameter.
#' @param pre_aggregated Logical. If TRUE, skips aggregation and uses `value_var` directly.
#'   Use this when your data is already aggregated (one row per x/y combination).
#'   Default is FALSE.
#'
#' @param backend Rendering backend: "highcharter" (default), "plotly", "echarts4r", or "ggiraph".
#' @return A `highcharter` heatmap object.
#'
#' @examples
#' \dontrun{
#' # Load the dataset
#' data(gss_panel20)
#'
#' # Example 1: Basic heatmap - no mapped values or other customization
#' viz_heatmap(
#'   data = gss_panel20,
#'   x_var = "degree_1a",
#'   y_var = "sex_1a",
#'   value_var = "age_1a",
#'   title = "Average Age by Education and Sex",
#'   x_label = "Education Level",
#'   y_label = "Sex",
#'   value_label = "Mean Age"
#' )
#'
#'
#' # Example 2: Heatmap With Custom Variable Mapping and Colors
#'
#' region_map <- list("1" = "New England",
#' "2" = "Mid-Atlantic",
#' "3" = "East North Central",
#' "4" = "West North Central",
#' "5" = "South Atlantic",
#' "6" = "Deep South",
#' "7" = "West South Central",
#' "8" = "Mountain",
#' "9" = "West Coast"
#' )
#' sex_map <- list("1" = "Male",
#'                "2" = "Female")
#'
#' viz_heatmap(
#'   data = gss_panel20,
#'   x_var = "region_1a",
#'   y_var = "sex_1a",
#'   value_var = "satfin_1a",
#'   x_map_values = region_map,
#'   y_map_values = sex_map,
#'   value_label = "Satisfaction",
#'   x_label = "U.S. Region",
#'   y_label = "Gender",
#'   title = "Satisfaction with Financial Situation",
#'   subtitle = "Per U.S. Region and Gender",
#'   color_palette = c("#f7fbff", "darkgreen"),
#'   color_min = 1,
#'   color_max = 3
#' )
#'
#'
#' # Example 3: Handling missing categories explicitly
#'
#' edu_map = list("0" = "less than high school",
#' "1" =  "high school",
#' "2" = "associate/junior college",
#' "3" = "bachelor's",
#' "4" = "graduate")
#'
#' viz_heatmap(
#' data = gss_panel20,
#' x_var = "region_1a",
#' y_var = "degree_1a",
#' value_var = "income_1a",
#' x_map_values = region_map,
#' y_map_values = edu_map,
#' color_min = 8,
#' color_max = 12,
#' value_label = "Income",
#' x_label = "U.S. Region",
#' y_label = "Education",
#' include_na = TRUE,
#' na_label_x = "Region Missing",
#' na_label_y = "Degree Missing",
#' na_color = "grey",
#' title = "Average Income by Region and Education (Including Missing)"
#' )
#'
#'
#' # Example 4: Custom order of education levels and relabeling of sex
#' viz_heatmap(
#' data = gss_panel20,
#' x_var = "degree_1a",
#' y_var = "sex_1a",
#' value_var = "income_1a",
#' x_map_values = edu_map,
#' x_order = c("less than high school", "high school", "associate/junior college",
#' "bachelor's", "graduate"),
#' y_map_values = sex_map,
#' y_label = "Gender",
#' x_label = "Education Level",
#' value_label = "Income Level",
#' title = "Average Income by Education Level and Sex",
#' subtitle = "Custom order and relabeled categories",
#' color_palette = c("#ffffe0", "#31a354")
#' )
#' }
#'
#' @details
#' This function performs the following steps:
#' \enumerate{
#'    \item **Input validation:** Checks `data`, `x_var`, `y_var`, and `value_var`.
#'    \item **Data Preparation:**
#'      \itemize{
#'        \item Handles `haven_labelled` columns by converting them to factors.
#'        \item Applies value mapping if `x_map_values` or `y_map_values` (new parameter) are provided.
#'        \item Processes NA values in `x_var` and `y_var`: if `include_na = TRUE`, NAs are converted to a specified label; otherwise, rows with NAs in these variables are filtered out.
#'        \item Converts `x_var` and `y_var` to factors and applies `x_order` and `y_order`.
#'        \item If `weight_var` is provided, uses `weighted.mean()` for aggregation; otherwise uses `agg_fun` (default `mean()`).
#'        \item Uses `tidyr::complete` to ensure all `x_var`/`y_var` combinations are present,
#'              filling missing `value_var` with `NA_real_` (which will appear as `na_color` in the heatmap).
#'      }
#'    \item **Chart Construction:**
#'      \itemize{
#'        \item Initializes a `highchart` object.
#'        \item Configures `title`, `subtitle`, axis labels.
#'        \item Sets up `hc_colorAxis` based on `color_min`, `color_max`, and `color_palette`.
#'        \item Adds the heatmap series using `hc_add_series`, mapping `x_var`, `y_var`, and `value_var`.
#'        \item Customizes `plotOptions` for heatmap, including data labels and `nullColor`.
#'      }
#'    \item **Tooltip Customization:** Defines a JavaScript `tooltip.formatter` for detailed hover information.
#'    }
#'
#' @param legend_position Position of the legend ("top", "bottom", "left", "right", "none")
#' @export
#'


viz_heatmap <- function(data,
                           x_var,
                           y_var,
                           value_var,
                           title = NULL,
                           subtitle = NULL,
                           x_label = NULL,
                           y_label = NULL,
                           value_label = NULL,
                           tooltip = NULL,
                           tooltip_prefix = "",
                           tooltip_suffix = "",
                           x_tooltip_suffix = "",
                           y_tooltip_suffix = "",
                           x_tooltip_prefix = "",
                           y_tooltip_prefix = "",
                           x_order = NULL,
                           y_order = NULL,
                           x_order_by = NULL,
                           y_order_by = NULL,
                           color_min = NULL,
                           color_max = NULL,
                           color_palette = c("#FFFFFF", "#7CB5EC"), # Default: white to light blue
                           na_color = "transparent",
                           data_labels_enabled = TRUE,
                           label_decimals = 1,
                           tooltip_labels_format = NULL,
                           include_na = FALSE,
                           na_label_x = "(Missing)",
                           na_label_y = "(Missing)",
                           x_map_values = NULL,
                           y_map_values = NULL,
                           agg_fun = mean,
                           weight_var = NULL,
                           pre_aggregated = FALSE,
                           legend_position = NULL,
                           backend = "highcharter"
) {

  # Convert variable arguments to strings (supports both quoted and unquoted)
  x_var <- .as_var_string(rlang::enquo(x_var))
  y_var <- .as_var_string(rlang::enquo(y_var))
  value_var <- .as_var_string(rlang::enquo(value_var))
  weight_var <- .as_var_string(rlang::enquo(weight_var))

  # Input Validation
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  if (is.null(x_var)) {
    .stop_with_hint("x_var", example = "viz_heatmap(data, x_var = \"country\", y_var = \"year\", value_var = \"population\")")
  }
  if (is.null(y_var)) {
    .stop_with_hint("y_var", example = "viz_heatmap(data, x_var = \"country\", y_var = \"year\", value_var = \"population\")")
  }
  if (is.null(value_var)) {
    .stop_with_hint("value_var", example = "viz_heatmap(data, x_var = \"country\", y_var = \"year\", value_var = \"population\")")
  }
  required_vars <- c(x_var, y_var, value_var)
  if (!all(required_vars %in% names(data))) {
    missing_vars <- setdiff(required_vars, names(data))
    stop(paste0("Missing required columns: ", paste(missing_vars, collapse = ", ")), call. = FALSE)
  }
  if (!is.numeric(data[[value_var]])) {
    stop(paste0("`value_var` (", value_var, ") must be numeric."), call. = FALSE)
  }

  # Select columns including weight_var if provided
  vars_to_select <- c(x_var, y_var, value_var)
  if (!is.null(weight_var)) {
    if (!weight_var %in% names(data)) {
      stop("`weight_var` '", weight_var, "' not found in data.", call. = FALSE)
    }
    vars_to_select <- c(vars_to_select, weight_var)
  }

  df_plot <- tibble::as_tibble(data) |>
    dplyr::select(dplyr::all_of(vars_to_select)) |>
    dplyr::rename(
      .x_raw = !!rlang::sym(x_var), # Use _raw to differentiate before processing
      .y_raw = !!rlang::sym(y_var), # Use _raw to differentiate before processing
      .value_plot = !!rlang::sym(value_var)
    )

  # Rename weight_var if provided
  if (!is.null(weight_var)) {
    df_plot <- df_plot |>
      dplyr::rename(.weight = !!rlang::sym(weight_var))
  }

  # Helper function for handling factor levels
  apply_factor_ordering <- function(values, custom_order = NULL, na_label = NULL, include_na = FALSE) {
    unique_vals <- unique(values)

    if (!is.null(custom_order)) {
      ordered_vals <- custom_order[custom_order %in% unique_vals]
      remaining_vals <- setdiff(unique_vals, ordered_vals)
      final_levels <- c(ordered_vals, remaining_vals)
    } else {
      final_levels <- sort(unique_vals)
    }

    # Move NA label to end if present and not explicitly ordered
    if (include_na && !is.null(na_label) && na_label %in% final_levels) {
      if (is.null(custom_order) || !na_label %in% custom_order) {
        final_levels <- c(setdiff(final_levels, na_label), na_label)
      }
    }

    return(final_levels)
  }

  # Handle 'haven_labelled' columns for x and y raw
  if (requireNamespace("haven", quietly = TRUE)) {
    if (inherits(df_plot$.x_raw, "haven_labelled")) {
      df_plot <- df_plot |>
        dplyr::mutate(.x_raw = haven::as_factor(.x_raw, levels = "values"))
      if (isTRUE(getOption("dashboardr.verbose"))) message(paste0("Note: Column '", x_var, "' was 'haven_labelled' and converted to factor (levels = values)."))
    }
    if (inherits(df_plot$.y_raw, "haven_labelled")) {
      df_plot <- df_plot |>
        dplyr::mutate(.y_raw = haven::as_factor(.y_raw, levels = "values"))
      if (isTRUE(getOption("dashboardr.verbose"))) message(paste0("Note: Column '", y_var, "' was 'haven_labelled' and converted to factor (levels = values)."))
    }
  }

  # X_VAR VALUE MAPPING
  if (!is.null(x_map_values)) {
    if (!is.list(x_map_values) || is.null(names(x_map_values))) {
      stop("'x_map_values' must be a named list (e.g., list('1'='Male', '2'='Female')).", call. = FALSE)
    }
    if (is.factor(df_plot$.x_raw)) {
      df_plot <- df_plot |>
        dplyr::mutate(.x_raw = as.character(.x_raw))
    }
    df_plot <- df_plot |>
      dplyr::mutate(.x_raw = dplyr::recode(.x_raw, !!!x_map_values))
    if (!is.null(x_order)) {
      warning("x_order provided with x_map_values. Ensure x_order refers to the *new* mapped labels.", call. = FALSE)
    }
  }

  # Y_VAR VALUE MAPPING
  if (!is.null(y_map_values)) {
    if (!is.list(y_map_values) || is.null(names(y_map_values))) {
      stop("'y_map_values' must be a named list (e.g., list('1'='Strongly Disagree')).", call. = FALSE)
    }
    if (is.factor(df_plot$.y_raw)) {
      df_plot <- df_plot |>
        dplyr::mutate(.y_raw = as.character(.y_raw))
    }
    df_plot <- df_plot |>
      dplyr::mutate(.y_raw = dplyr::recode(.y_raw, !!!y_map_values))
    if (!is.null(y_order)) {
      warning("y_order provided with y_map_values. Ensure y_order refers to the *new* mapped labels.", call. = FALSE)
    }
  }

  # Handle NAs for x_var and y_var BEFORE converting to factor and setting levels
  df_processed <- df_plot |>
    dplyr::mutate(
      .x_plot_temp = if (include_na) {
        temp_x <- as.character(.x_raw) # Convert to char to replace NA
        temp_x[is.na(temp_x)] <- na_label_x
        temp_x
      } else {
        as.character(.x_raw) # Just convert to char
      },
      .y_plot_temp = if (include_na) {
        temp_y <- as.character(.y_raw) # Convert to char to replace NA
        temp_y[is.na(temp_y)] <- na_label_y
        temp_y
      } else {
        as.character(.y_raw) # Just convert to char
      }
    )

  # FILTER OUT NAs if include_na = FALSE
  if (!include_na) {
    df_plot <- df_plot |>
      dplyr::filter(!is.na(.x_raw) & !is.na(.y_raw))
  }

  # CREATE FACTORS using helper function
  df_processed <- df_plot |>
    dplyr::mutate(
      .x_plot = handle_na_for_plotting(
        data = df_plot,
        var_name = ".x_raw",
        include_na = include_na,
        na_label = na_label_x,
        custom_order = x_order
      ),
      .y_plot = handle_na_for_plotting(
        data = df_plot,
        var_name = ".y_raw",
        include_na = include_na,
        na_label = na_label_y,
        custom_order = y_order
      )
    )

  # Get initial levels (may be reordered by x_order_by/y_order_by)
  initial_x_levels <- levels(df_processed$.x_plot)
  initial_y_levels <- levels(df_processed$.y_plot)

  # AGGREGATION with complete (or skip if pre_aggregated)
  if (pre_aggregated) {
    # Skip aggregation - use values directly, just ensure all combinations exist
    df_plot_complete <- df_processed |>
      dplyr::select(.x_plot, .y_plot, .value_plot) |>
      tidyr::complete(.x_plot, .y_plot, fill = list(.value_plot = NA_real_)) |>
      dplyr::arrange(.x_plot, .y_plot)
  } else if (!is.null(weight_var)) {
    # Weighted aggregation using weighted mean
    df_plot_complete <- df_processed |>
      dplyr::group_by(.x_plot, .y_plot) |>
      dplyr::summarise(
        .value_plot = stats::weighted.mean(.value_plot, w = .weight, na.rm = TRUE),
        .groups = 'drop'
      ) |>
      tidyr::complete(.x_plot, .y_plot, fill = list(.value_plot = NA_real_)) |>
      dplyr::arrange(.x_plot, .y_plot)
  } else {
    # Standard aggregation without weights
    df_plot_complete <- df_processed |>
      dplyr::group_by(.x_plot, .y_plot) |>
      dplyr::summarise(.value_plot = agg_fun(.value_plot, na.rm = TRUE), .groups = 'drop') |>
      tidyr::complete(.x_plot, .y_plot, fill = list(.value_plot = NA_real_)) |>
      dplyr::arrange(.x_plot, .y_plot)
  }


  # Apply value-based ordering if requested (overrides x_order/y_order)
  # x_order_by: order x-axis categories by their mean value
  if (!is.null(x_order_by)) {
    x_order_by <- match.arg(x_order_by, c("asc", "desc"))
    x_means <- df_plot_complete |>
      dplyr::group_by(.x_plot) |>
      dplyr::summarise(.mean_val = mean(.value_plot, na.rm = TRUE), .groups = "drop") |>
      dplyr::arrange(if (x_order_by == "desc") dplyr::desc(.mean_val) else .mean_val)
    new_x_levels <- as.character(x_means$.x_plot)
    df_plot_complete <- df_plot_complete |>
      dplyr::mutate(.x_plot = factor(.x_plot, levels = new_x_levels))
  }

  # y_order_by: order y-axis categories by their mean value
  if (!is.null(y_order_by)) {
    y_order_by <- match.arg(y_order_by, c("asc", "desc"))
    y_means <- df_plot_complete |>
      dplyr::group_by(.y_plot) |>
      dplyr::summarise(.mean_val = mean(.value_plot, na.rm = TRUE), .groups = "drop") |>
      dplyr::arrange(if (y_order_by == "desc") dplyr::desc(.mean_val) else .mean_val)
    new_y_levels <- as.character(y_means$.y_plot)
    df_plot_complete <- df_plot_complete |>
      dplyr::mutate(.y_plot = factor(.y_plot, levels = new_y_levels))
  }

  # Get final levels (after potential reordering)
  final_x_levels <- levels(df_plot_complete$.x_plot)
  final_y_levels <- levels(df_plot_complete$.y_plot)

  # Axis labels
  final_x_label <- x_label %||% x_var
  final_y_label <- y_label %||% y_var
  final_value_label <- value_label %||% value_var

  # Build config for backend dispatch
  config <- list(
    title = title, subtitle = subtitle,
    x_label = final_x_label, y_label = final_y_label,
    value_label = final_value_label,
    color_palette = color_palette, color_min = color_min, color_max = color_max,
    na_color = na_color, data_labels_enabled = data_labels_enabled,
    label_decimals = label_decimals, tooltip_labels_format = tooltip_labels_format,
    tooltip = tooltip, tooltip_prefix = tooltip_prefix, tooltip_suffix = tooltip_suffix,
    x_tooltip_suffix = x_tooltip_suffix, y_tooltip_suffix = y_tooltip_suffix,
    x_tooltip_prefix = x_tooltip_prefix, y_tooltip_prefix = y_tooltip_prefix,
    final_x_levels = final_x_levels, final_y_levels = final_y_levels,
    legend_position = legend_position
  )

  # Dispatch to backend renderer
  backend <- .normalize_backend(backend)
  backend <- match.arg(backend, c("highcharter", "plotly", "echarts4r", "ggiraph"))
  .assert_backend_supported("heatmap", backend)
  render_fn <- switch(backend,
    highcharter = .viz_heatmap_highcharter,
    plotly      = .viz_heatmap_plotly,
    echarts4r   = .viz_heatmap_echarts,
    ggiraph     = .viz_heatmap_ggiraph
  )
  result <- render_fn(df_plot_complete, config)
  result <- .register_chart_widget(result, backend = backend)
  return(result)
}

# --- Highcharter backend (original implementation) ---
#' @keywords internal
.viz_heatmap_highcharter <- function(df_plot_complete, config) {
  # Unpack config
  title <- config$title; subtitle <- config$subtitle
  final_x_label <- config$x_label; final_y_label <- config$y_label
  final_value_label <- config$value_label
  color_palette <- config$color_palette; color_min <- config$color_min
  color_max <- config$color_max; na_color <- config$na_color
  data_labels_enabled <- config$data_labels_enabled
  label_decimals <- config$label_decimals
  tooltip_labels_format <- config$tooltip_labels_format
  tooltip <- config$tooltip; tooltip_prefix <- config$tooltip_prefix
  tooltip_suffix <- config$tooltip_suffix
  x_tooltip_suffix <- config$x_tooltip_suffix; y_tooltip_suffix <- config$y_tooltip_suffix
  x_tooltip_prefix <- config$x_tooltip_prefix; y_tooltip_prefix <- config$y_tooltip_prefix
  final_x_levels <- config$final_x_levels; final_y_levels <- config$final_y_levels

  # Chart construction
  hc <- highcharter::highchart() %>%
    highcharter::hc_chart(type = "heatmap") %>%
    highcharter::hc_title(text = title) %>%
    highcharter::hc_subtitle(text = subtitle)

  hc <- hc %>%
    highcharter::hc_xAxis(
      categories = final_x_levels, # Use final_x_levels as categories
      title = list(text = final_x_label),
      opposite = FALSE # X-axis at bottom
    ) %>%
    highcharter::hc_yAxis(
      categories = final_y_levels, # Use final_y_levels as categories
      title = list(text = final_y_label)
    )

  # Color Axis configuration
  color_stops <- list()
  if (length(color_palette) == 1) {
    color_stops <- list(
      list(0, "white"), # Start white
      list(1, color_palette[1]) # End with the provided color
    )
  } else {
    n_colors <- length(color_palette)
    for (i in seq_along(color_palette)) {
      color_stops[[i]] <- list((i - 1) / (n_colors - 1), color_palette[i])
    }
  }

  hc <- hc %>%
    highcharter::hc_colorAxis(
      min = color_min %||% min(df_plot_complete$.value_plot, na.rm = TRUE),
      max = color_max %||% max(df_plot_complete$.value_plot, na.rm = TRUE),
      stops = color_stops,
      title = list(text = final_value_label)
    )

  # Resolve data label format: explicit tooltip_labels_format > label_decimals

  data_label_fmt <- if (!is.null(tooltip_labels_format)) {
    tooltip_labels_format
  } else {
    sprintf("{point.value:.%df}", as.integer(label_decimals))
  }

  # Add heatmap series
  hc <- hc %>%
    highcharter::hc_add_series(
      data = df_plot_complete,
      type = "heatmap",
      highcharter::hcaes(x = .x_plot, y = .y_plot, value = .value_plot),
      name = final_value_label # Name for legend/series
    ) %>%
    # plotOptions must be set separately (not inside hc_add_series)
    highcharter::hc_plotOptions(
      heatmap = list(
        dataLabels = list(
          enabled = data_labels_enabled,
          format = data_label_fmt,
          color = "#000000", # Label color, e.g., black
          style = list(textOutline = "none")
        ),
        nullColor = na_color # Color for NA values
      )
    )

  # \u2500\u2500\u2500 TOOLTIP \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
  if (!is.null(tooltip)) {
    # Use new unified tooltip system
    tooltip_result <- .process_tooltip_config(
      tooltip = tooltip,
      tooltip_prefix = tooltip_prefix,
      tooltip_suffix = tooltip_suffix,
      x_tooltip_suffix = NULL,
      chart_type = "heatmap",
      context = list(
        x_label = final_x_label,
        y_label = final_y_label,
        value_label = final_value_label
      )
    )
    hc <- .apply_tooltip_to_hc(hc, tooltip_result)
  } else {
    # Use legacy tooltip construction with all prefix/suffix parameters
    pre_val <- tooltip_prefix %||% ""
    suf_val <- tooltip_suffix %||% ""
    xpre_tip <- x_tooltip_prefix %||% ""
    xsuf_tip <- x_tooltip_suffix %||% ""
    ypre_tip <- y_tooltip_prefix %||% ""
    ysuf_tip <- y_tooltip_suffix %||% ""

    tooltip_fn <- sprintf(
      "function() {
        // Access categories using this.series.xAxis.categories and this.series.yAxis.categories
        // this.point.x and this.point.y are the numerical indices
        var x_cat = this.series.xAxis.categories[this.point.x];
        var y_cat = this.series.yAxis.categories[this.point.y];
        var value = this.point.value;

        var value_str = Highcharts.numberFormat(value, %d); // Format value
        if (value === null) {
            value_str = 'N/A'; // Display N/A for null values in tooltip
        }

        return '<b>' + '%s' + x_cat + '%s</b><br/>' + // Using x_tooltip_prefix here
               '<b>' + '%s' + y_cat + '%s</b><br/>' + // Using y_tooltip_prefix here
               '<b>%s: </b>' + '%s' + value_str + '%s';
      }",
      as.integer(label_decimals), # Corresponds to the %d (numberFormat decimals)
      xpre_tip, # Corresponds to the first %s
      xsuf_tip, # Corresponds to the second %s
      ypre_tip, # Corresponds to the third %s
      ysuf_tip, # Corresponds to the fourth %s
      final_value_label, # Corresponds to the fifth %s
      pre_val, # Corresponds to the sixth %s
      suf_val  # Corresponds to the seventh %s
    )

    hc <- hc %>% highcharter::hc_tooltip(
      formatter = highcharter::JS(tooltip_fn),
      valueDecimals = as.integer(label_decimals)
    )
  }

  # --- Legend position ---
  hc <- .apply_legend_highcharter(hc, config$legend_position, default_show = FALSE)

  return(hc)
}

# --- Plotly backend ---
#' @keywords internal
.viz_heatmap_plotly <- function(df_plot_complete, config) {
  rlang::check_installed("plotly", reason = "to use backend = 'plotly'")

  title <- config$title
  final_x_label <- config$x_label; final_y_label <- config$y_label
  final_value_label <- config$value_label
  color_palette <- config$color_palette
  color_min <- config$color_min; color_max <- config$color_max
  final_x_levels <- config$final_x_levels; final_y_levels <- config$final_y_levels
  label_decimals <- config$label_decimals

  # Pivot to matrix form for plotly heatmap
  mat <- df_plot_complete |>
    dplyr::select(.x_plot, .y_plot, .value_plot) |>
    tidyr::pivot_wider(names_from = .x_plot, values_from = .value_plot) |>
    dplyr::arrange(match(.y_plot, final_y_levels))

  y_labels <- as.character(mat$.y_plot)
  mat$.y_plot <- NULL
  z_matrix <- as.matrix(mat[, final_x_levels, drop = FALSE])

  # Build colorscale from color_palette
  colorscale <- NULL
  if (!is.null(color_palette) && length(color_palette) >= 2) {
    n <- length(color_palette)
    colorscale <- lapply(seq_along(color_palette), function(i) {
      list((i - 1) / (n - 1), color_palette[i])
    })
  }

  p <- plotly::plot_ly(
    x = final_x_levels,
    y = y_labels,
    z = z_matrix,
    type = "heatmap",
    colorscale = colorscale,
    zmin = color_min,
    zmax = color_max,
    colorbar = list(title = final_value_label),
    hovertemplate = paste0(
      final_x_label, ": %{x}<br>",
      final_y_label, ": %{y}<br>",
      final_value_label, ": %{z:.", label_decimals, "f}<extra></extra>"
    )
  )

  layout_args <- list(
    p = p,
    xaxis = list(title = final_x_label),
    yaxis = list(title = final_y_label)
  )
  if (!is.null(title)) layout_args$title <- title

  p <- do.call(plotly::layout, layout_args)

  # --- Legend position ---
  p <- .apply_legend_plotly(p, config$legend_position, default_show = FALSE)

  p
}

# --- echarts4r backend ---
#' @keywords internal
.viz_heatmap_echarts <- function(df_plot_complete, config) {
  rlang::check_installed("echarts4r", reason = "to use backend = 'echarts4r'")

  title <- config$title; subtitle <- config$subtitle
  final_x_label <- config$x_label; final_y_label <- config$y_label
  final_value_label <- config$value_label
  color_palette <- config$color_palette
  color_min <- config$color_min; color_max <- config$color_max

  # echarts4r heatmap needs character x/y
  plot_df <- df_plot_complete |>
    dplyr::mutate(
      .x_plot = as.character(.x_plot),
      .y_plot = as.character(.y_plot)
    )

  data_labels_enabled <- config$data_labels_enabled %||% TRUE
  label_decimals <- config$label_decimals %||% 0L

  e <- plot_df |>
    echarts4r::e_charts(.x_plot) |>
    echarts4r::e_heatmap(.y_plot, .value_plot) |>
    echarts4r::e_visual_map(
      .value_plot,
      inRange = list(color = color_palette),
      min = color_min %||% min(df_plot_complete$.value_plot, na.rm = TRUE),
      max = color_max %||% max(df_plot_complete$.value_plot, na.rm = TRUE)
    )

  if (!is.null(title) || !is.null(subtitle)) {
    e <- e |> echarts4r::e_title(text = title %||% "", subtext = subtitle %||% "")
  }

  e <- e |>
    echarts4r::e_x_axis(name = final_x_label) |>
    echarts4r::e_y_axis(name = final_y_label) |>
    echarts4r::e_tooltip(trigger = "item")

  # Data labels on heatmap cells
  if (isTRUE(data_labels_enabled)) {
    label_fmt <- paste0(
      "function(params) {",
      "  var v = Array.isArray(params.value) ? params.value[2] : params.value;",
      "  if (v === null || v === undefined) return '';",
      "  return Number(v).toFixed(", label_decimals, ");",
      "}"
    )
    e <- e |> echarts4r::e_labels(
      show = TRUE,
      position = "inside",
      formatter = htmlwidgets::JS(label_fmt),
      fontSize = 12,
      color = "#333"
    )
  }

  # --- Legend position ---
  e <- .apply_legend_echarts(e, config$legend_position, default_show = FALSE)

  e
}

# --- ggiraph backend ---
#' @keywords internal
.viz_heatmap_ggiraph <- function(df_plot_complete, config) {
  rlang::check_installed("ggiraph", reason = "to use backend = 'ggiraph'")
  rlang::check_installed("ggplot2", reason = "to use backend = 'ggiraph'")

  title <- config$title; subtitle <- config$subtitle
  final_x_label <- config$x_label; final_y_label <- config$y_label
  final_value_label <- config$value_label
  color_palette <- config$color_palette
  color_min <- config$color_min; color_max <- config$color_max
  label_decimals <- config$label_decimals

  # Build tooltip text
  df_plot_complete$.tooltip <- paste0(
    final_x_label, ": ", df_plot_complete$.x_plot, "<br>",
    final_y_label, ": ", df_plot_complete$.y_plot, "<br>",
    final_value_label, ": ", round(df_plot_complete$.value_plot, label_decimals)
  )

  p <- ggplot2::ggplot(df_plot_complete, ggplot2::aes(
    x = .data$.x_plot, y = .data$.y_plot, fill = .data$.value_plot
  )) +
    ggiraph::geom_tile_interactive(
      ggplot2::aes(tooltip = .data$.tooltip, data_id = paste(.data$.x_plot, .data$.y_plot)),
      color = "white"
    ) +
    ggplot2::labs(
      title = title, subtitle = subtitle,
      x = final_x_label, y = final_y_label, fill = final_value_label
    ) +
    ggplot2::theme_minimal()

  # Apply color gradient
  if (length(color_palette) == 2) {
    fill_args <- list(low = color_palette[1], high = color_palette[2])
    if (!is.null(color_min) && !is.null(color_max)) fill_args$limits <- c(color_min, color_max)
    p <- p + do.call(ggplot2::scale_fill_gradient, fill_args)
  } else if (length(color_palette) >= 3) {
    fill_args <- list(colours = color_palette)
    if (!is.null(color_min) && !is.null(color_max)) fill_args$limits <- c(color_min, color_max)
    p <- p + do.call(ggplot2::scale_fill_gradientn, fill_args)
  }

  # --- Legend position ---
  p <- .apply_legend_ggplot(p, config$legend_position, default_show = FALSE)

  ggiraph::girafe(ggobj = p)
}
