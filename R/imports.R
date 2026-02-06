#' @importFrom dplyr select filter if_any everything mutate pull bind_rows rename distinct group_by ungroup summarise arrange count
#' @importFrom tidyr drop_na
#' @importFrom tidyselect all_of
#' @importFrom magrittr %>%
#' @importFrom rlang %||% sym
#' @importFrom digest digest
#' @importFrom highcharter highchart hc_chart hc_title hc_xAxis hc_yAxis hc_plotOptions hc_add_series list_parse2
#' @importFrom htmltools div img h5 tagAppendChild
#' @importFrom utils data adist capture.output head modifyList tail
#' @importFrom graphics hist
#' @importFrom stats density na.omit quantile runif setNames
NULL

# Declare NSE variables and data.table/rlang operators as global variables
# to avoid R CMD check NOTEs about "no visible binding for global variable"
if (getRversion() >= "2.15.1") utils::globalVariables(c(
  ".data", ".filtered", ".mean_val", ".stack_var_col", ".value_plot", ".weight",
  ".x_factor", ".x_plot", ".x_raw", ".x_var_col", ".y_plot", ".y_raw",
  ":=", "across",
  "age", "age_1a", "category", "class_1a", "class_raw",
  "degree", "degree_1a", "degree_raw",
  "error_point", "fair_1a", "gap",
  "gss_all", "gss_panel20",
  "happy", "happy_1a", "happy_raw", "helpful_1a", "high",
  "low", "n", "parent",
  "partyid_1a", "percentage", "point_data", "polviews_1a", "proportion",
  "region_1a",
  "sex", "sex_1a", "summarize",
  "trust_1a", "x", "y", "year"
))
