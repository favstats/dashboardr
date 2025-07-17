#’ @title Likert‐Style Stacked Bar Chart
#’ @description
#’ Turns wide survey data (one column per question) into long format and then
#’ creates a stacked‐bar chart where each bar is a question and each stack is
#’ a Likert‐type response category.
#’
#’ @param data A data.frame with one column per survey question (one row per
#’   respondent).
#’ @param questions Character vector of column names to pivot (the survey
#’   questions).
#’ @param question_labels Optional character vector of labels for the
#’   questions. Must be the same length as `questions`. If `NULL`, `questions`
#’   are used as labels.
#’ @param response_levels Optional character vector of factor levels for the
#’   Likert responses (e.g. `c("Strongly Disagree", …, "Strongly Agree")`).
#’ @param title Optional main title for the chart.
#’ @param subtitle Optional subtitle for the chart.
#’ @param x_label Optional label for the X‐axis. Defaults to “Questions”.
#’ @param y_label Optional label for the Y‐axis. Defaults to “Number of Respondents” or
#’   “Percentage of Respondents” if `stacked_type = "percent"`.
#’ @param stack_label Optional title for the stack legend. Defaults to “Response”.
#’ @param stacked_type Type of stacking: `"normal"` (counts) or `"percent"`
#’   (100% stacked). Defaults to `"normal"`.
#’ @param tooltip_prefix Optional string prepended to tooltip values.
#’ @param tooltip_suffix Optional string appended to tooltip values.
#’ @param x_tooltip_suffix Optional string appended to X‐axis tooltip values.
#’ @param color_palette Optional character vector of colors for the stacks.
#’ @param stack_order Optional character vector specifying the order of response levels.
#’ @param x_order Optional character vector specifying the order of questions.
#’ @param include_na Logical. If `TRUE`, `(NA)` is shown as a category; if `FALSE`,
#’   rows with `NA` in question or response are dropped. Default `FALSE`.
#’ @param x_breaks Optional numeric vector of cut points to bin the questions
#’   (if they are numeric). Not typical for Likert.
#’ @param x_bin_labels Optional character vector of labels for `x_breaks`.
#’ @param x_map_values Optional named list to rename question values.
#’ @param stack_breaks Optional numeric vector of cut points to bin the responses.
#’ @param stack_bin_labels Optional character vector of labels for `stack_breaks`.
#’ @param stack_map_values Optional named list to rename response values.
#’
#’ @return A `highcharter` stacked bar chart object.
#’ @export
#’ @export
#’ @export
#’ @export
create_stackedbars <- function(data,
                                     questions,
                                     question_labels   = NULL,
                                     response_levels   = NULL,
                                     title             = NULL,
                                     subtitle          = NULL,
                                     x_label           = NULL,
                                     y_label           = NULL,
                                     stack_label       = NULL,
                                     stacked_type      = c("normal","percent"),
                                     tooltip_prefix    = "",
                                     tooltip_suffix    = "",
                                     x_tooltip_suffix  = "",
                                     color_palette     = NULL,
                                     stack_order       = NULL,
                                     x_order           = NULL,
                                     include_na        = FALSE,
                                     x_breaks          = NULL,
                                     x_bin_labels      = NULL,
                                     x_map_values      = NULL,
                                     stack_breaks      = NULL,
                                     stack_bin_labels  = NULL,
                                     stack_map_values  = NULL,
                                     show_question_tooltip = TRUE) {
  stacked_type <- match.arg(stacked_type)

  # 1. pivot wide → long
  data_long <- tidyr::pivot_longer(
    data,
    cols      = tidyr::all_of(questions),
    names_to  = "question",
    values_to = "response"
  )

  # 2. apply question_labels or default to raw names
  if (is.null(question_labels)) {
    data_long$question <- factor(data_long$question, levels = questions)
    # we will use the raw questions as axis‐categories
    axis_categories <- questions
  } else {
    if (length(question_labels) != length(questions)) {
      stop("`question_labels` must be same length as `questions`", call.=FALSE)
    }
    data_long$question <- factor(
      data_long$question,
      levels = questions,
      labels = question_labels
    )
    # here are the human‐readable labels
    axis_categories <- question_labels
  }

  # 3. enforce response_levels if provided
  if (!is.null(response_levels)) {
    data_long$response <- factor(
      data_long$response,
      levels = response_levels
    )
  }

  # 4. build the core chart
  hc <- create_stackedbar(
    data             = data_long,
    x_var            = "question",
    stack_var        = "response",
    title            = title,
    subtitle         = subtitle,
    x_label          = if (is.null(x_label)) "Question" else x_label,
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
    x_breaks         = x_breaks,
    x_bin_labels     = x_bin_labels,
    x_map_values     = x_map_values,
    stack_breaks     = stack_breaks,
    stack_bin_labels = stack_bin_labels,
    stack_map_values = stack_map_values
  )

  # 5. set the xAxis categories explicitly so JS knows them
  hc <- hc %>% highcharter::hc_xAxis(categories = axis_categories)

  if (show_question_tooltip) {
    # 6. override/force the JS tooltip formatter
    hc$x$hc_opts$tooltip <- list(
      useHTML   = TRUE,
      formatter = htmlwidgets::JS("
        function() {
          // pull the question label from the axis categories array
          var q = this.series.chart.xAxis[0].categories[this.point.x];
          // the response (series name)
          var r = this.series.name;
          // format as percentage if percent‐stacked, else point.y
          var v = (this.point.percentage !== undefined)
                  ? Highcharts.numberFormat(this.point.percentage,1) + '%'
                  : this.point.y;
          return '<b>' + q + '</b><br/>' +
                 r + ': <b>' + v + '</b>';
        }
      ")
    )
  }

  hc
}
