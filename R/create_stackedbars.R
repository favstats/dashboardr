#' @title Create Multiple Stacked Bar Charts
#' @description This function creates multiple stacked barchart for survey data. It
#'              handles raw (unaggregated) data, counting the occurrences of
#'              categories, supporting ordered factors, allowing numerical x-axis
#'              and stacked variables to be binned into custom groups, and
#'              enables renaming of categorical values for display. It can also
#'              handle SPSS (.sav) columns automatically.
#'
#' @param data A data frame containing the raw survey data (e.g., one row per respondent).
#' @param x_var The name of the column to be plotted on the X-axis (as a string).
#'              This typically represents a demographic variable or a question.
#' @param y_var Optional. The name of the column that already contains the counts
#'              or values for the y-axis (as a string). If `NULL` (default),
#'              the function will internally count the occurrences of `x_var` and `stack_var`.
#'              Only provide this if your `data` is already aggregated.
#' @param stack_var The name of the column whose unique values will define the
#'                stacks within each bar (as a string). This is often a
#'                Likert scale, an agreement level, or another categorical response.
#' @param title Optional. The main title of the chart (as a string).
#' @param subtitle Optional. A subtitle for the chart (as a string).
#' @param x_label Optional. The label for the X-axis (as a string). Defaults
#'                to `x_var` or `x_var (Binned)`.
#' @param y_label Optional. The label for the Y-axis (as a string). Defaults
#'                to "Number of Respondents" or "Percentage of Respondents".
#' @param stack_label Optional. The title for the stack legend (as a string).
#'                   Defaults to `stack_var` or `stack_var (Binned)`.
#' @param stacked_type Optional. The type of stacking. Can be "normal" (counts)
#'                   or "percent" (100% stacked). Defaults to "normal".
#' @param tooltip_prefix Optional. A string to prepend to values in tooltips.
#' @param tooltip_suffix Optional. A string to append to values in tooltips.
#' @param x_tooltip_suffix Optional. A string to append to values in tooltips.
#' @param color_palette Optional. A character vector of colors to use for the
#'                    stacks. If NULL, highcharter's default palette is used.
#'                    Consider ordering colors to match `stack_order`.
#' @param stack_order Optional. A character vector specifying the desired order
#'                    of the `stack_var` levels. This is crucial for ordinal
#'                    scales (e.g., Likert 1-7). If NULL, default factor order
#'                    or alphabetical will be used. Levels not found in data
#'                    will be ignored.
#' @param x_order Optional. A character vector specifying the desired order
#'                    of the `x_var` levels. If NULL, default factor order
#'                    or alphabetical will be used.
#' @param include_na Logical. If TRUE, explicit "(NA)" categories will be shown
#'                   in counts for `x_var` and `stack_var`. If FALSE (default),
#'                   rows with NA in `x_var` or `stack_var` are dropped.
#' @param x_breaks Optional. A numeric vector of cut points for `x_var` if
#'                 it is a continuous variable and you want to bin it.
#'                 e.g., `c(16, 24, 33, 42, 51, 60, Inf)`.
#' @param x_bin_labels Optional. A character vector of labels for the bins
#'                     created by `x_breaks`. Must be one less than the number
#'                     of breaks (or same if Inf is last break).
#' @param x_map_values Optional. A named list (e.g., `list("1" = "Female", "2" = "Male")`)
#'                     to rename values within `x_var` for display. Original values
#'                     should be names, new labels should be values.
#' @param stack_breaks Optional. A numeric vector of cut points for `stack_var` if
#'                     it is a continuous variable and you want to bin it.
#' @param stack_bin_labels Optional. A character vector of labels for the bins
#'                         created by `stack_breaks`. Must be one less than the number
#'                         of breaks (or same if Inf is last break).
#' @param stack_map_values Optional. A named list (e.g., `list("1" = "Strongly Disagree", "7" = "Strongly Agree")`)
#'                         to rename values within `stack_var` for display.
#'
#' @return An interactive `highcharter` bar chart plot object.
#'
#' @return An HTML tag list: a Quarto tabset of highcharter widgets.
#' @export
create_stackedbar_tabs <- function(data,
                                   x_var,
                                   stack_vars,
                                   stack_var_labels     = NULL,
                                   common_title         = NULL,
                                   title                = NULL,
                                   subtitle             = NULL,
                                   x_label              = NULL,
                                   y_label              = NULL,
                                   stack_label          = NULL,
                                   stacked_type         = c("normal", "percent"),
                                   tooltip_prefix       = "",
                                   tooltip_suffix       = "",
                                   x_tooltip_suffix     = "",
                                   color_palette        = NULL,
                                   stack_order          = NULL,
                                   x_order              = NULL,
                                   include_na           = FALSE,
                                   x_breaks             = NULL,
                                   x_bin_labels         = NULL,
                                   x_map_values         = NULL,
                                   stack_breaks         = NULL,
                                   stack_bin_labels     = NULL,
                                   stack_map_values     = NULL) {
  
  stacked_type <- match.arg(stacked_type)
  
  if (is.null(stack_var_labels)) {
    stack_var_labels <- stack_vars
  }
  if (length(stack_vars) != length(stack_var_labels)) {
    stop("`stack_vars` and `stack_var_labels` must be the same length.", call. = FALSE)
  }
  
  tabs <- lapply(seq_along(stack_vars), function(i) {
    sv  <- stack_vars[[i]]
    lbl <- stack_var_labels[[i]]
    
    # Build per-tab title
    this_title <- if (!is.null(common_title)) {
      paste(common_title, "-", lbl)
    } else {
      title
    }
    
    # Call core single-chart function
    chart <- create_stackedbar(
      data               = data,
      x_var              = x_var,
      stack_var          = sv,
      title              = this_title,
      subtitle           = subtitle,
      x_label            = x_label,
      y_label            = y_label,
      stack_label        = stack_label,
      stacked_type       = stacked_type,
      tooltip_prefix     = tooltip_prefix,
      tooltip_suffix     = tooltip_suffix,
      x_tooltip_suffix   = x_tooltip_suffix,
      color_palette      = color_palette,
      stack_order        = stack_order,
      x_order            = x_order,
      include_na         = include_na,
      x_breaks           = x_breaks,
      x_bin_labels       = x_bin_labels,
      x_map_values       = x_map_values,
      stack_breaks       = stack_breaks,
      stack_bin_labels   = stack_bin_labels,
      stack_map_values   = stack_map_values
    )
    
    # Quarto requires an <h3> before each tab panel
    list(
      htmltools::h3(lbl),
      chart
    )
  })
  
  htmltools::div(class = "tabset", do.call(htmltools::tagList, tabs))
}
