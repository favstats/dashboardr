#' @title Stacked Bar Charts (Multiple Variables)
#' @description
#' Turns wide data (one column per variable) into long format and then
#' creates a stacked-bar chart where each bar represents a variable and each 
#' stack segment represents a response category.
#'
#' This is useful for comparing distributions across multiple related variables,
#' such as survey questions, rating scales, or any set of categorical variables
#' with shared response options.
#'
#' @param data A data frame with one column per variable to compare.
#' @param x_vars Character vector of column names to pivot (the variables to compare).
#' @param x_var_labels Optional character vector of display labels for the variables.
#'   Must be the same length as `x_vars`. If `NULL`, column names are used as labels.
#' @param response_levels Optional character vector of factor levels for the
#'   response categories (e.g. `c("Strongly Disagree", ..., "Strongly Agree")`).
#' @param title Optional main title for the chart.
#' @param subtitle Optional subtitle for the chart.
#' @param x_label Optional label for the X-axis. Defaults to "Variable".
#' @param y_label Optional label for the Y-axis. Defaults to "Count" or
#'   "Percentage" if `stacked_type = "percent"`.
#' @param stack_label Optional title for the stack legend.
#'   Set to NULL, NA, FALSE, or "" to hide the legend title completely.
#' @param stacked_type Type of stacking: `"normal"` or `"counts"` (raw counts) or `"percent"`
#'   (100% stacked). Defaults to `"normal"`. Note: "counts" is an alias for "normal".
#' @param tooltip_prefix Optional string prepended to tooltip values.
#' @param tooltip_suffix Optional string appended to tooltip values.
#' @param x_tooltip_suffix Optional string appended to X-axis tooltip values.
#' @param color_palette Optional character vector of colors for the stacks.
#' @param stack_order Optional character vector specifying the order of response levels.
#' @param x_order Optional character vector specifying the order of variables on the x-axis.
#' @param include_na Logical. If `TRUE`, NA values are shown as explicit categories; if `FALSE`,
#'   rows with `NA` are dropped. Default `FALSE`.
#' @param na_label_x Optional string. Custom label for NA values in variables. Defaults to "(Missing)".
#' @param na_label_stack Optional string. Custom label for NA values in responses. Defaults to "(Missing)".
#' @param x_breaks Optional numeric vector of cut points to bin the variables
#'   (if they are numeric).
#' @param x_bin_labels Optional character vector of labels for `x_breaks`.
#' @param x_map_values Optional named list to rename variable values.
#' @param stack_breaks Optional numeric vector of cut points to bin the responses.
#' @param stack_bin_labels Optional character vector of labels for `stack_breaks`.
#' @param stack_map_values Optional named list to rename response values.
#' @param show_var_tooltip Logical. If `TRUE`, shows custom tooltip with variable labels.
#' @param horizontal Logical. If `TRUE`, creates a horizontal bar chart (bars extend from left to right).
#'   If `FALSE` (default), creates a vertical column chart (bars extend from bottom to top).
#'   Note: When horizontal = TRUE, the stack order is automatically reversed so that
#'   the visual order of the stacks matches the legend order.
#' @param weight_var Optional. Column name for weighting observations.
#'
#' @return A `highcharter` stacked bar chart object.
#'
#' @examples
#'
#' # Load GSS data
#' data(gss_all)
#'
#' # Filter to recent years and select confidence variables
#' gss_recent <- gss_all %>%
#'   filter(year >= 2010) %>%
#'   select(year, confinan, confed, conmedic, conjudge, consci, conlegis)
#'
#' # Example 1: Basic chart comparing confidence across institutions
#' confidence_vars <- c("confinan", "confed", "conmedic", "conjudge", "consci", "conlegis")
#' confidence_labels <- c(
#'   "Financial Institutions",
#'   "Education",
#'   "Medicine",
#'   "Courts/Justice",
#'   "Scientific Community",
#'   "Congress"
#' )
#'
#' # Define response order (typical GSS confidence scale)
#' confidence_order <- c("A Great Deal", "Only Some", "Hardly Any")
#'
#' plot1 <- viz_stackedbars(
#'   data = gss_recent,
#'   x_vars = confidence_vars,
#'   x_var_labels = confidence_labels,
#'   title = "Confidence in American Institutions",
#'   subtitle = "GSS respondents 2010-present",
#'   x_label = "Institution",
#'   stack_label = "Level of Confidence",
#'   response_levels = confidence_order,
#'   stacked_type = "percent",
#'   color_palette = c("#2E8B57", "#FFD700", "#CD5C5C")
#' )
#' plot1
#'
#' # Example 2: Including NA values with custom labels
#' plot2 <- viz_stackedbars(
#'   data = gss_recent,
#'   x_vars = confidence_vars,
#'   x_var_labels = confidence_labels,
#'   title = "Confidence in Institutions (Including Non-Responses)",
#'   subtitle = "Showing missing data explicitly",
#'   x_label = "Institution",
#'   stack_label = "Response",
#'   include_na = TRUE,
#'   na_label_stack = "No Opinion/Refused",
#'   stacked_type = "percent",
#'   tooltip_suffix = "%",
#'   color_palette = c("#2E8B57", "#FFD700", "#CD5C5C", "#808080")
#' )
#' plot2
#'
#' # Example 3: Custom response mapping and ordering
#' # Map GSS codes to more descriptive labels
#' confidence_map <- list(
#'   "A Great Deal" = "High Confidence",
#'   "Only Some" = "Moderate Confidence",
#'   "Hardly Any" = "Low Confidence"
#' )
#'
#' plot3 <- viz_stackedbars(
#'   data = gss_recent,
#'   x_vars = confidence_vars[1:4],  # Just first 4 institutions
#'   x_var_labels = confidence_labels[1:4],
#'   title = "Institutional Confidence with Custom Labels",
#'   subtitle = "Remapped response categories",
#'   stack_map_values = confidence_map,
#'   stack_order = c("High Confidence", "Moderate Confidence", "Low Confidence"),
#'   stacked_type = "normal",
#'   color_palette = c("#1f77b4", "#ff7f0e", "#d62728")
#' )
#' plot3
#'
#' # Example 4: Custom ordering and tooltips
#' # Reorder by typical confidence levels (highest to lowest)
#' custom_order <- c(
#'   "Scientific Community",
#'   "Medicine",
#'   "Education",
#'   "Courts/Justice",
#'   "Financial Institutions",
#'   "Congress"
#' )
#'
#' plot4 <- viz_stackedbars(
#'   data = gss_recent,
#'   x_vars = confidence_vars,
#'   x_var_labels = confidence_labels,
#'   title = "Institutional Confidence (Reordered)",
#'   subtitle = "Ordered from typically highest to lowest confidence",
#'   x_order = custom_order,
#'   response_levels = confidence_order,
#'   stacked_type = "percent",
#'   tooltip_prefix = "Response: ",
#'   tooltip_suffix = "% of respondents",
#'   x_tooltip_suffix = " institution",
#'   color_palette = c("#2E8B57", "#FFD700", "#CD5C5C")
#' )
#' plot4
#'
#' # Example 5: Horizontal bar chart
#' plot5 <- viz_stackedbars(
#'   data = gss_recent,
#'   x_vars = confidence_vars,
#'   x_var_labels = confidence_labels,
#'   title = "Confidence in American Institutions (Horizontal)",
#'   subtitle = "GSS respondents 2010-present",
#'   x_label = "Institution",
#'   stack_label = "Level of Confidence",
#'   response_levels = confidence_order,
#'   stacked_type = "percent",
#'   horizontal = TRUE,
#'   color_palette = c("#2E8B57", "#FFD700", "#CD5C5C")
#' )
#' plot5
#'
#' # Example 6: Working with different variable types
#' # Using happiness and satisfaction variables
#' if (all(c("happy", "satfin", "satjob") %in% names(gss_all))) {
#'   satisfaction_data <- gss_all %>%
#'     filter(year >= 2010) %>%
#'     select(happy, satfin, satjob) %>%
#'     mutate(across(everything(), as.character))
#'
#'   satisfaction_vars <- c("happy", "satfin", "satjob")
#'   satisfaction_labels <- c("General Happiness", "Financial Satisfaction", "Job Satisfaction")
#'
#'   plot6 <- viz_stackedbars(
#'     data = satisfaction_data,
#'     x_vars = satisfaction_vars,
#'     x_var_labels = satisfaction_labels,
#'     title = "Life Satisfaction Measures",
#'     subtitle = "Multiple satisfaction domains",
#'     x_label = "Life Domain",
#'     stack_label = "Satisfaction Level",
#'     stacked_type = "percent",
#'     include_na = TRUE,
#'     na_label_stack = "Not Asked/No Answer"
#'   )
#'   plot6
#'}
#'
#'
#' @export
viz_stackedbars <- function(data,
                               x_vars,
                               x_var_labels      = NULL,
                               response_levels   = NULL,
                               title             = NULL,
                               subtitle          = NULL,
                               x_label           = NULL,
                               y_label           = NULL,
                               stack_label       = NULL,
                               stacked_type      = c("normal", "percent", "counts"),
                               tooltip_prefix    = "",
                               tooltip_suffix    = "",
                               x_tooltip_suffix  = "",
                               color_palette     = NULL,
                               stack_order       = NULL,
                               x_order           = NULL,
                               include_na        = FALSE,
                               na_label_x        = "(Missing)",
                               na_label_stack    = "(Missing)",
                               x_breaks          = NULL,
                               x_bin_labels      = NULL,
                               x_map_values      = NULL,
                               stack_breaks      = NULL,
                               stack_bin_labels  = NULL,
                               stack_map_values  = NULL,
                               show_var_tooltip  = TRUE,
                               horizontal        = FALSE,
                               weight_var        = NULL) {
  # Convert variable arguments to strings (supports both quoted and unquoted)
  x_vars <- .as_var_strings(rlang::enquo(x_vars))
  weight_var <- .as_var_string(rlang::enquo(weight_var))
  
  stacked_type <- match.arg(stacked_type)
  
  # Normalize "normal" to "counts" for viz_stackedbar
  if (stacked_type == "normal") {
    stacked_type <- "counts"
  }

  # 1. pivot wide -> long
  data_long <- tidyr::pivot_longer(
    data,
    cols      = tidyr::all_of(x_vars),
    names_to  = "variable",
    values_to = "response"
  )

  # 2. apply x_var_labels or default to raw names
  # Special case: when there's only one variable and horizontal = TRUE,
  # blank the category label to avoid truncation (use title instead)
  if (length(x_vars) == 1 && horizontal && !is.null(x_var_labels)) {
    # Force blank label for single variable in horizontal mode
    data_long$variable <- factor(data_long$variable, levels = x_vars, labels = "")
    axis_categories <- ""
  } else if (is.null(x_var_labels)) {
    data_long$variable <- factor(data_long$variable, levels = x_vars)
    # we will use the raw variable names as axis-categories
    axis_categories <- x_vars
  } else {
    if (length(x_var_labels) != length(x_vars)) {
      stop("`x_var_labels` must be same length as `x_vars`", call. = FALSE)
    }
    data_long$variable <- factor(
      data_long$variable,
      levels = x_vars,
      labels = x_var_labels
    )
    # here are the human-readable labels
    axis_categories <- x_var_labels
  }

  # 3. enforce response_levels if provided
  if (!is.null(response_levels)) {
    data_long$response <- factor(
      data_long$response,
      levels = response_levels
    )
  }

  # 4. build the core chart
  hc <- viz_stackedbar(
    data             = data_long,
    x_var            = "variable",
    stack_var        = "response",
    title            = title,
    subtitle         = subtitle,
    x_label          = if (is.null(x_label)) "Variable" else x_label,
    y_label          = y_label,
    stack_label      = stack_label,
    stacked_type     = stacked_type,
    tooltip_prefix   = tooltip_prefix,
    tooltip_suffix   = tooltip_suffix,
    x_tooltip_suffix = x_tooltip_suffix,
    color_palette    = color_palette,
    stack_order      = stack_order,
    x_order          = x_order,
    include_na       = include_na,
    na_label_x       = na_label_x,
    na_label_stack   = na_label_stack,
    x_breaks         = x_breaks,
    x_bin_labels     = x_bin_labels,
    x_map_values     = x_map_values,
    stack_breaks     = stack_breaks,
    stack_bin_labels = stack_bin_labels,
    stack_map_values = stack_map_values,
    horizontal       = horizontal,
    weight_var       = weight_var
  )

  # 5. set the xAxis categories explicitly so JS knows them
  hc <- hc %>% highcharter::hc_xAxis(categories = axis_categories)

  if (show_var_tooltip) {
    # 6. override/force the JS tooltip formatter
    hc$x$hc_opts$tooltip <- list(
      useHTML   = TRUE,
      formatter = htmlwidgets::JS("
        function() {
          // pull the variable label from the axis categories array
          var v = this.series.chart.xAxis[0].categories[this.point.x];
          // If category is empty/undefined (single variable case), use chart title instead
          if (!v || v === '') {
            v = this.series.chart.title ? this.series.chart.title.textStr : '';
          }
          // the response (series name)
          var r = this.series.name;
          // format as percentage if percent-stacked, else point.y
          var val = (this.point.percentage !== undefined)
                  ? Highcharts.numberFormat(this.point.percentage,1) + '%'
                  : this.point.y;
          return '<b>' + v + '</b><br/>' +
                 r + ': <b>' + val + '</b>';
        }
      ")
    )
  }

  hc
}
