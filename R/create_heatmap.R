# Load dependencies
library(highcharter)
library(tidyverse)
library(dplyr)
library(rlang)
library(roxygen2)
library(tidyr)
library(gssr)

# Helper function
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

# --------------------------------------------------------------------------
# Function: create_heatmap
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
#' @param tooltip_prefix Optional string prepended in the tooltip value.
#' @param tooltip_suffix Optional string appended in the tooltip value.
#' @param x_tooltip_suffix Optional string appended to x value in tooltip.
#' @param y_tooltip_suffix Optional string appended to y value in tooltip.
#' @param x_tooltip_prefix Optional string prepended to x value in tooltip.
#' @param y_tooltip_prefix Optional string prepended to y value in tooltip.
#' @param x_order Optional character vector to order the factor levels of `x_var`.
#' @param y_order Optional character vector to order the factor levels of `y_var`.
#' @param color_min Optional numeric. Minimum value for the color axis. If NULL, defaults to data min.
#' @param color_max Optional numeric. Maximum value for the color axis. If NULL, defaults to data max.
#' @param color_palette Optional character vector of colors for the color gradient.
#'   Example: `c("#FFFFFF", "#7CB5EC")` for white to light blue. Can also be a single color for gradient start.
#' @param na_color Optional string. Color for NA values in `value_var` cells. Default "transparent".
#' @param data_labels_enabled Logical. If TRUE, display data labels on each cell. Default TRUE.
#' @param data_labels_format Optional string. Format for data labels. Default "{point.value}".
#' @param include_na Logical. If TRUE, treats NA values in `x_var` or `y_var`
#'   as explicit categories using `na_label_x` and `na_label_y`. If FALSE (default),
#'   rows with NA in `x_var` or `y_var` are excluded from aggregation.
#' @param na_label_x Optional string. Custom label for NA values in `x_var`. Defaults to "(Missing)".
#' @param na_label_y Optional string. Custom label for NA values in `y_var`. Defaults to "(Missing)".
#' @param x_map_values Optional named list to recode x_var values for display.
#' @param y_map_values Optional named list to recode y_var values for display.
#' @param agg_fun Function to aggregate duplicate x/y combinations. Default is `mean`.
#'
#' @return A `highcharter` heatmap object.
#'
#' @examples
#' #TODO: something is off here so will comment out for now
#' # Example 1: Average Age by Education and Gender
#' # Let's create a heatmap showing the average age across education levels and gender.
#' # We will use the GSS dataset from 2020
#'
#' # Step 1: Prepare data for heatmap
#' #age_education_data <- gss_clean %>%
#' #   filter(!is.na(degree_3), !is.na(sex_3), !is.na(age_3)) %>%
#' #   group_by(degree_3, sex_3) %>%
#' #   summarise(avg_age = mean(age_3, na.rm = TRUE), .groups = 'drop')
#'
#' # Step 2: Create basic heatmap
#' # plot1 <- create_heatmap(
#' #   data = age_education_data,
#' #   x_var = "degree_3",
#' #   y_var = "sex_3",
#' #   value_var = "avg_age",
#' #   title = "Average Age by Education Level and Gender",
#' #   subtitle = "GSS Panel 2020 - Wave 3",
#' #   x_label = "Education Level",
#' #   y_label = "Gender",
#' #   value_label = "Average Age",
#' #   color_palette = c("#ffffff", "#2E86AB")
#' # )
#'
#' plot1
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
#' @export
#'


create_heatmap <- function(data,
                           x_var,
                           y_var,
                           value_var,
                           title = NULL,
                           subtitle = NULL,
                           x_label = NULL,
                           y_label = NULL,
                           value_label = NULL,
                           tooltip_prefix = "",
                           tooltip_suffix = "",
                           x_tooltip_suffix = "",
                           y_tooltip_suffix = "",
                           x_tooltip_prefix = "",
                           y_tooltip_prefix = "",
                           x_order = NULL,
                           y_order = NULL,
                           color_min = NULL,
                           color_max = NULL,
                           color_palette = c("#FFFFFF", "#7CB5EC"), # Default: white to light blue
                           na_color = "transparent",
                           data_labels_enabled = TRUE,
                           data_labels_format = "{point.value}",
                           include_na = FALSE,
                           na_label_x = "(Missing)",
                           na_label_y = "(Missing)",
                           x_map_values = NULL,
                           y_map_values = NULL,
                           agg_fun = mean
) {

  # Input Validation
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  required_vars <- c(x_var, y_var, value_var)
  if (!all(required_vars %in% names(data))) {
    missing_vars <- setdiff(required_vars, names(data))
    stop(paste0("Missing required columns: ", paste(missing_vars, collapse = ", ")), call. = FALSE)
  }
  if (!is.numeric(data[[value_var]])) {
    stop(paste0("`value_var` (", value_var, ") must be numeric."), call. = FALSE)
  }

  df_plot <- tibble::as_tibble(data) |>
    dplyr::select(!!rlang::sym(x_var), !!rlang::sym(y_var), !!rlang::sym(value_var)) |>
    dplyr::rename(
      .x_raw = !!rlang::sym(x_var), # Use _raw to differentiate before processing
      .y_raw = !!rlang::sym(y_var), # Use _raw to differentiate before processing
      .value_plot = !!rlang::sym(value_var)
    )

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
      message(paste0("Note: Column '", x_var, "' was 'haven_labelled' and converted to factor (levels = values)."))
    }
    if (inherits(df_plot$.y_raw, "haven_labelled")) {
      df_plot <- df_plot |>
        dplyr::mutate(.y_raw = haven::as_factor(.y_raw, levels = "values"))
      message(paste0("Note: Column '", y_var, "' was 'haven_labelled' and converted to factor (levels = values)."))
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

  # Filter out NAs from .x_plot_temp or .y_plot_temp if include_na is FALSE
  if (!include_na) {
    df_processed <- df_processed |>
      dplyr::filter(!is.na(.x_raw) & !is.na(.y_raw)) # Filter original NAs if not including
  }

  # Apply custom ordering and convert to factors
  final_x_levels <- apply_factor_ordering(
    values = df_processed$.x_plot_temp,
    custom_order = x_order,
    na_label = na_label_x,
    include_na = include_na
  )

  final_y_levels <- apply_factor_ordering(
    values = df_processed$.y_plot_temp,
    custom_order = y_order,
    na_label = na_label_y,
    include_na = include_na
  )


  df_processed <- df_processed |>
    dplyr::mutate(
      .x_plot = factor(.x_plot_temp, levels = final_x_levels),
      .y_plot = factor(.y_plot_temp, levels = final_y_levels)
    )

  # Use complete data to ensure all combinations exist, filling missing values with NA for value_var
  # This uses the factors directly to generate all combinations
  df_plot_complete <- df_processed |>
    dplyr::group_by(.x_plot, .y_plot) |>
    dplyr::summarise(.value_plot = agg_fun(.value_plot, na.rm = TRUE), .groups = 'drop') |>
    tidyr::complete(
      .x_plot = factor(final_x_levels, levels = final_x_levels),
      .y_plot = factor(final_y_levels, levels = final_y_levels),
      fill = list(.value_plot = NA_real_)
    ) |>
    # Re-order to ensure consistency for hcaes mapping
    dplyr::arrange(.x_plot, .y_plot)


  # Chart construction
  hc <- highcharter::highchart() %>%
    highcharter::hc_chart(type = "heatmap") %>%
    highcharter::hc_title(text = title) %>%
    highcharter::hc_subtitle(text = subtitle)

  # Axis labels
  final_x_label <- x_label %||% x_var
  final_y_label <- y_label %||% y_var
  final_value_label <- value_label %||% value_var

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

  # Add heatmap series
  hc <- hc %>%
    highcharter::hc_add_series(
      data = df_plot_complete,
      type = "heatmap",
      highcharter::hcaes(x = .x_plot, y = .y_plot, value = .value_plot),
      name = final_value_label, # Name for legend/series
      plotOptions = list(
        heatmap = list(
          dataLabels = list(
            enabled = data_labels_enabled,
            format = data_labels_format,
            color = "#000000", # Label color, e.g., black
            style = list(textOutline = "none")
          ),
          nullColor = na_color # Color for NA values
        )
      )
    )

  # Tooltip
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

      var value_str = Highcharts.numberFormat(value, 0); // Format value (e.g., 0 decimals)
      if (value === null) {
          value_str = 'N/A'; // Display N/A for null values in tooltip
      }

      return '<b>' + '%s' + x_cat + '%s</b><br/>' + // Using x_tooltip_prefix here
             '<b>' + '%s' + y_cat + '%s</b><br/>' + // Using y_tooltip_prefix here
             '<b>%s: </b>' + '%s' + value_str + '%s';
    }",
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
    valueDecimals = 0 # This line might conflict with JS formatting, but helpful for default behavior
  )

  return(hc)
}
