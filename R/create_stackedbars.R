#' @title Stacked Bar Charts
#' @description
#' Turns wide survey data (one column per question) into long format and then
#' creates a stacked‐bar chart where each bar is a question and each stack is
#' a Likert‐type response category.
#'
#' @param data A data frame with one column per survey question (one row per
#'   respondent).
#' @param questions Character vector of column names to pivot (the survey
#'   questions).
#' @param question_labels Optional character vector of labels for the
#'   questions. Must be the same length as `questions`. If `NULL`, `questions`
#'   are used as labels.
#' @param response_levels Optional character vector of factor levels for the
#'   Likert responses (e.g. `c("Strongly Disagree", …, "Strongly Agree")`).
#' @param title Optional main title for the chart.
#' @param subtitle Optional subtitle for the chart.
#' @param x_label Optional label for the X‐axis. Defaults to "Questions".
#' @param y_label Optional label for the Y‐axis. Defaults to "Number of Respondents" or
#'   "Percentage of Respondents" if `stacked_type = "percent"`.
#' @param stack_label Optional title for the stack legend.
#'   Set to NULL, NA, FALSE, or "" to hide the legend title completely.
#' @param stacked_type Type of stacking: `"normal"` or `"counts"` (raw counts) or `"percent"`
#'   (100% stacked). Defaults to `"normal"`. Note: "counts" is an alias for "normal".
#' @param tooltip_prefix Optional string prepended to tooltip values.
#' @param tooltip_suffix Optional string appended to tooltip values.
#' @param x_tooltip_suffix Optional string appended to X‐axis tooltip values.
#' @param color_palette Optional character vector of colors for the stacks.
#' @param stack_order Optional character vector specifying the order of response levels.
#' @param x_order Optional character vector specifying the order of questions.
#' @param include_na Logical. If `TRUE`, NA values are shown as explicit categories; if `FALSE`,
#'   rows with `NA` in question or response are dropped. Default `FALSE`.
#' @param na_label_x Optional string. Custom label for NA values in questions. Defaults to "(Missing)".
#' @param na_label_stack Optional string. Custom label for NA values in responses. Defaults to "(Missing)".
#' @param x_breaks Optional numeric vector of cut points to bin the questions
#'   (if they are numeric). Not typical for Likert.
#' @param x_bin_labels Optional character vector of labels for `x_breaks`.
#' @param x_map_values Optional named list to rename question values.
#' @param stack_breaks Optional numeric vector of cut points to bin the responses.
#' @param stack_bin_labels Optional character vector of labels for `stack_breaks`.
#' @param stack_map_values Optional named list to rename response values.
#' @param show_question_tooltip Logical. If `TRUE`, shows custom tooltip with question labels.
#' @param horizontal Logical. If `TRUE`, creates a horizontal bar chart (bars extend from left to right).
#'   If `FALSE` (default), creates a vertical column chart (bars extend from bottom to top).
#'   Note: When horizontal = TRUE, the stack order is automatically reversed so that
#'   the visual order of the stacks matches the legend order.
#'
#' @return A `highcharter` stacked bar chart object.
#'
#' @examples
#'
#' # Load GSS data
#' data(gss_all)
#'
#' # Filter to recent years and select Likert-style questions
#' gss_recent <- gss_all %>%
#'   filter(year >= 2010) %>%
#'   select(year, confinan, confed, conmedic, conjudge, consci, conlegis)
#'
#' # Example 1: Basic Likert chart - Confidence in institutions
#' confidence_questions <- c("confinan", "confed", "conmedic", "conjudge", "consci", "conlegis")
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
#' plot1 <- create_stackedbars(
#'   data = gss_recent,
#'   questions = confidence_questions,
#'   question_labels = confidence_labels,
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
#' plot2 <- create_stackedbars(
#'   data = gss_recent,
#'   questions = confidence_questions,
#'   question_labels = confidence_labels,
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
#' plot3 <- create_stackedbars(
#'   data = gss_recent,
#'   questions = confidence_questions[1:4],  # Just first 4 institutions
#'   question_labels = confidence_labels[1:4],
#'   title = "Institutional Confidence with Custom Labels",
#'   subtitle = "Remapped response categories",
#'   stack_map_values = confidence_map,
#'   stack_order = c("High Confidence", "Moderate Confidence", "Low Confidence"),
#'   stacked_type = "normal",
#'   color_palette = c("#1f77b4", "#ff7f0e", "#d62728")
#' )
#' plot3
#'
#' # Example 4: Custom question ordering and tooltips
#' # Reorder questions by typical confidence levels (highest to lowest)
#' custom_question_order <- c(
#'   "Scientific Community",
#'   "Medicine",
#'   "Education",
#'   "Courts/Justice",
#'   "Financial Institutions",
#'   "Congress"
#' )
#'
#' plot4 <- create_stackedbars(
#'   data = gss_recent,
#'   questions = confidence_questions,
#'   question_labels = confidence_labels,
#'   title = "Institutional Confidence (Reordered)",
#'   subtitle = "Ordered from typically highest to lowest confidence",
#'   x_order = custom_question_order,
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
#' plot5 <- create_stackedbars(
#'   data = gss_recent,
#'   questions = confidence_questions,
#'   question_labels = confidence_labels,
#'   title = "Confidence in American Institutions (Horizontal)",
#'   subtitle = "GSS respondents 2010-present",
#'   x_label = "Institution",
#'   stack_label = "Level of Confidence",
#'   response_levels = confidence_order,
#'   stacked_type = "percent",
#'   horizontal = TRUE,  # Creates horizontal bars
#'   color_palette = c("#2E8B57", "#FFD700", "#CD5C5C")
#' )
#' plot5
#'
#' # Example 6: Working with different Likert scales
#' # Using happiness and life satisfaction questions if available
#' if (all(c("happy", "satfin", "satjob") %in% names(gss_all))) {
#'   satisfaction_data <- gss_all %>%
#'     filter(year >= 2010) %>%
#'     select(happy, satfin, satjob) %>%
#'     # Convert to consistent scale for demonstration
#'     mutate(across(everything(), as.character))
#'
#'   satisfaction_questions <- c("happy", "satfin", "satjob")
#'   satisfaction_labels <- c("General Happiness", "Financial Satisfaction", "Job Satisfaction")
#'
#'   plot6 <- create_stackedbars(
#'     data = satisfaction_data,
#'     questions = satisfaction_questions,
#'     question_labels = satisfaction_labels,
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
create_stackedbars <- function(data,
                                     questions,
                                    question_labels   = NULL,
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
                                     include_na = FALSE,
                                     na_label_x = "(Missing)",
                                     na_label_stack = "(Missing)",
                                     x_breaks          = NULL,
                                     x_bin_labels      = NULL,
                                     x_map_values      = NULL,
                                     stack_breaks      = NULL,
                                     stack_bin_labels  = NULL,
                                     stack_map_values  = NULL,
                                     show_question_tooltip = TRUE,
                                     horizontal = FALSE,
                                     weight_var = NULL) {
  stacked_type <- match.arg(stacked_type)
  
  # Normalize "normal" to "counts" for create_stackedbar
  if (stacked_type == "normal") {
    stacked_type <- "counts"
  }

  # 1. pivot wide → long
  data_long <- tidyr::pivot_longer(
    data,
    cols      = tidyr::all_of(questions),
    names_to  = "question",
    values_to = "response"
  )

  # 2. apply question_labels or default to raw names
  # Special case: when there's only one question and horizontal = TRUE,
  # blank the category label to avoid truncation (use title instead)
  if (length(questions) == 1 && horizontal && !is.null(question_labels)) {
    # Force blank label for single question in horizontal mode
    data_long$question <- factor(data_long$question, levels = questions, labels = "")
    axis_categories <- ""
  } else if (is.null(question_labels)) {
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
