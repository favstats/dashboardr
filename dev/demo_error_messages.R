# =================================================================
# dashboardr Error Message Showcase
# =================================================================
# This script demonstrates ALL improved error messages in the
# dashboardr package. Run it after devtools::load_all() to see
# every category of validation error in action.
#
# Author: dashboardr dev team
# Purpose: QA / review of error message quality
# =================================================================

devtools::load_all()
library(dplyr)

# ---- Helper function ----
error_count <- 0L

show_error <- function(description, expr) {
  error_count <<- error_count + 1L
  cat("\n", paste(rep("=", 70), collapse = ""), "\n")
  cat("  [", error_count, "] ", description, "\n", sep = "")
  cat(paste(rep("-", 70), collapse = ""), "\n")
  tryCatch(
    expr,
    error = function(e) cat("  ERROR:", conditionMessage(e), "\n")
  )
}


# #################################################################
#
#  CATEGORY 1: Missing Required Parameters (.stop_with_hint)
#
# #################################################################
cat("\n\n")
cat(paste(rep("#", 70), collapse = ""), "\n")
cat("  CATEGORY 1: Missing Required Parameters (.stop_with_hint)\n")
cat(paste(rep("#", 70), collapse = ""), "\n")

# ---- 1.1 viz_bar: missing x_var ----
show_error(
  "viz_bar(mtcars) -- missing x_var",
  viz_bar(mtcars)
)

# ---- 1.2 viz_scatter: missing x_var ----
show_error(
  "viz_scatter(mtcars) -- missing x_var",
  viz_scatter(mtcars)
)

# ---- 1.3 viz_scatter: missing y_var ----
show_error(
  "viz_scatter(mtcars, x_var = 'mpg') -- missing y_var",
  viz_scatter(mtcars, x_var = "mpg")
)

# ---- 1.4 viz_histogram: missing x_var ----
show_error(
  "viz_histogram(mtcars) -- missing x_var",
  viz_histogram(mtcars)
)

# ---- 1.5 viz_density: missing x_var ----
show_error(
  "viz_density(mtcars) -- missing x_var",
  viz_density(mtcars)
)

# ---- 1.6 viz_boxplot: missing y_var ----
show_error(
  "viz_boxplot(mtcars) -- missing y_var",
  viz_boxplot(mtcars)
)

# ---- 1.7 viz_heatmap: missing x_var ----
show_error(
  "viz_heatmap(mtcars) -- missing x_var",
  viz_heatmap(mtcars)
)

# ---- 1.8 viz_heatmap: missing y_var ----
show_error(
  "viz_heatmap(mtcars, x_var = 'cyl') -- missing y_var",
  viz_heatmap(mtcars, x_var = "cyl")
)

# ---- 1.9 viz_heatmap: missing value_var ----
show_error(
  "viz_heatmap(mtcars, x_var = 'cyl', y_var = 'gear') -- missing value_var",
  viz_heatmap(mtcars, x_var = "cyl", y_var = "gear")
)

# ---- 1.10 viz_timeline: missing time_var ----
show_error(
  "viz_timeline(mtcars) -- missing time_var",
  viz_timeline(mtcars)
)

# ---- 1.11 viz_timeline: missing y_var ----
show_error(
  "viz_timeline(mtcars, time_var = 'year') -- missing y_var",
  viz_timeline(mtcars, time_var = "year")
)

# ---- 1.12 viz_pie: missing x_var ----
show_error(
  "viz_pie(mtcars) -- missing x_var",
  viz_pie(mtcars)
)

# ---- 1.13 viz_lollipop: missing x_var ----
show_error(
  "viz_lollipop(mtcars) -- missing x_var",
  viz_lollipop(mtcars)
)

# ---- 1.14 viz_dumbbell: missing x_var ----
show_error(
  "viz_dumbbell(mtcars) -- missing x_var",
  viz_dumbbell(mtcars)
)

# ---- 1.15 viz_gauge: missing value ----
show_error(
  "viz_gauge() -- missing value (no data, no value)",
  viz_gauge()
)

# ---- 1.16 viz_gauge: invalid gauge_type ----
show_error(
  "viz_gauge(value = 50, gauge_type = 'invalid') -- invalid gauge_type with hint",
  viz_gauge(value = 50, gauge_type = "invalid")
)

# ---- 1.17 viz_funnel: missing x_var ----
show_error(
  "viz_funnel(mtcars) -- missing x_var",
  viz_funnel(mtcars)
)

# ---- 1.18 viz_funnel: missing y_var ----
show_error(
  "viz_funnel(mtcars, x_var = 'cyl') -- missing y_var",
  viz_funnel(mtcars, x_var = "cyl")
)

# ---- 1.19 viz_sankey: missing from_var ----
show_error(
  "viz_sankey(mtcars) -- missing from_var",
  viz_sankey(mtcars)
)

# ---- 1.20 viz_sankey: missing to_var ----
show_error(
  "viz_sankey(mtcars, from_var = 'a') -- missing to_var",
  viz_sankey(mtcars, from_var = "a")
)

# ---- 1.21 viz_sankey: missing value_var ----
show_error(
  "viz_sankey(mtcars, from_var = 'a', to_var = 'b') -- missing value_var",
  viz_sankey(mtcars, from_var = "a", to_var = "b")
)

# ---- 1.22 viz_waffle: missing x_var ----
show_error(
  "viz_waffle(mtcars) -- missing x_var",
  viz_waffle(mtcars)
)


# #################################################################
#
#  CATEGORY 2: Typo Detection (.stop_with_suggestion)
#
# #################################################################
cat("\n\n")
cat(paste(rep("#", 70), collapse = ""), "\n")
cat("  CATEGORY 2: Typo Detection (.stop_with_suggestion)\n")
cat(paste(rep("#", 70), collapse = ""), "\n")

# ---- 2.1 'bart' -> 'bar' ----
show_error(
  "add_viz(type = 'bart') -- typo, suggests 'bar'",
  create_content() %>% add_viz(type = "bart")
)

# ---- 2.2 'scater' -> 'scatter' ----
show_error(
  "add_viz(type = 'scater') -- typo, suggests 'scatter'",
  create_content() %>% add_viz(type = "scater")
)

# ---- 2.3 'histo' -> 'histogram' ----
show_error(
  "add_viz(type = 'histo') -- typo, suggests 'histogram'",
  create_content() %>% add_viz(type = "histo")
)

# ---- 2.4 'tmlne' -> 'timeline' ----
show_error(
  "add_viz(type = 'tmlne') -- typo, suggests 'timeline'",
  create_content() %>% add_viz(type = "tmlne")
)

# ---- 2.5 'piee' -> 'pie' ----
show_error(
  "add_viz(type = 'piee') -- typo, suggests 'pie'",
  create_content() %>% add_viz(type = "piee")
)

# ---- 2.6 'wafle' -> 'waffle' ----
show_error(
  "add_viz(type = 'wafle') -- typo, suggests 'waffle'",
  create_content() %>% add_viz(type = "wafle")
)

# ---- 2.7 'snakey' -> 'sankey' ----
show_error(
  "add_viz(type = 'snakey') -- typo, suggests 'sankey'",
  create_content() %>% add_viz(type = "snakey")
)

# ---- 2.8 tabset_theme typo: 'modrn' -> 'modern' ----
show_error(
  "create_dashboard(tabset_theme = 'modrn') -- typo, suggests 'modern'",
  create_dashboard(tabset_theme = "modrn")
)

# ---- 2.9 'densty' -> 'density' ----
show_error(
  "add_viz(type = 'densty') -- typo, suggests 'density'",
  create_content() %>% add_viz(type = "densty")
)

# ---- 2.10 'boxplt' -> 'boxplot' ----
show_error(
  "add_viz(type = 'boxplt') -- typo, suggests 'boxplot'",
  create_content() %>% add_viz(type = "boxplt")
)

# ---- 2.11 'heatmapp' -> 'heatmap' ----
show_error(
  "add_viz(type = 'heatmapp') -- typo, suggests 'heatmap'",
  create_content() %>% add_viz(type = "heatmapp")
)

# ---- 2.12 'funnle' -> 'funnel' ----
show_error(
  "add_viz(type = 'funnle') -- typo, suggests 'funnel'",
  create_content() %>% add_viz(type = "funnle")
)

# ---- 2.13 'lollpop' -> 'lollipop' ----
show_error(
  "add_viz(type = 'lollpop') -- typo, suggests 'lollipop'",
  create_content() %>% add_viz(type = "lollpop")
)

# ---- 2.14 'dumbell' -> 'dumbbell' ----
show_error(
  "add_viz(type = 'dumbell') -- typo, suggests 'dumbbell'",
  create_content() %>% add_viz(type = "dumbell")
)

# ---- 2.15 'gaug' -> 'gauge' ----
show_error(
  "add_viz(type = 'gaug') -- typo, suggests 'gauge'",
  create_content() %>% add_viz(type = "gaug")
)

# ---- 2.16 tabset_theme typo: 'pils' -> 'pills' ----
show_error(
  "create_dashboard(tabset_theme = 'pils') -- typo, suggests 'pills'",
  create_dashboard(tabset_theme = "pils")
)

# ---- 2.17 Completely invalid type (no close match) ----
show_error(
  "add_viz(type = 'zzzzz') -- no close match, shows available types",
  create_content() %>% add_viz(type = "zzzzz")
)


# #################################################################
#
#  CATEGORY 3: Column Not Found Errors
#
# #################################################################
cat("\n\n")
cat(paste(rep("#", 70), collapse = ""), "\n")
cat("  CATEGORY 3: Column Not Found Errors\n")
cat(paste(rep("#", 70), collapse = ""), "\n")

# ---- 3.1 viz_bar: x_var not in data ----
show_error(
  "viz_bar(mtcars, x_var = 'nonexistent') -- column not found",
  viz_bar(mtcars, x_var = "nonexistent")
)

# ---- 3.2 viz_scatter: y_var not in data ----
show_error(
  "viz_scatter(mtcars, x_var = 'mpg', y_var = 'nonexistent') -- column not found",
  viz_scatter(mtcars, x_var = "mpg", y_var = "nonexistent")
)

# ---- 3.3 viz_pie: x_var not in data ----
show_error(
  "viz_pie(mtcars, x_var = 'nonexistent') -- column not found",
  viz_pie(mtcars, x_var = "nonexistent")
)

# ---- 3.4 viz_sankey: from_var not in data ----
show_error(
  "viz_sankey(data.frame(a=1), from_var = 'nonexistent', to_var = 'b', value_var = 'c') -- column not found",
  viz_sankey(data.frame(a = 1), from_var = "nonexistent", to_var = "b", value_var = "c")
)

# ---- 3.5 viz_histogram: x_var not in data ----
show_error(
  "viz_histogram(mtcars, x_var = 'nonexistent') -- column not found",
  viz_histogram(mtcars, x_var = "nonexistent")
)

# ---- 3.6 viz_lollipop: x_var not in data ----
show_error(
  "viz_lollipop(mtcars, x_var = 'nonexistent') -- column not found",
  viz_lollipop(mtcars, x_var = "nonexistent")
)

# ---- 3.7 viz_waffle: x_var not in data ----
show_error(
  "viz_waffle(mtcars, x_var = 'nonexistent') -- column not found",
  viz_waffle(mtcars, x_var = "nonexistent")
)

# ---- 3.8 viz_heatmap: x_var not in data ----
show_error(
  "viz_heatmap(mtcars, x_var = 'nonexistent', y_var = 'cyl', value_var = 'mpg') -- column not found",
  viz_heatmap(mtcars, x_var = "nonexistent", y_var = "cyl", value_var = "mpg")
)

# ---- 3.9 viz_dumbbell: low_var not in data ----
show_error(
  "viz_dumbbell(mtcars, x_var = 'cyl', low_var = 'nonexistent', high_var = 'mpg') -- column not found",
  viz_dumbbell(mtcars, x_var = "cyl", low_var = "nonexistent", high_var = "mpg")
)

# ---- 3.10 viz_gauge: value_var not in data ----
show_error(
  "viz_gauge(data = mtcars, value_var = 'nonexistent') -- column not found",
  viz_gauge(data = mtcars, value_var = "nonexistent")
)

# ---- 3.11 viz_funnel: x_var not in data ----
show_error(
  "viz_funnel(mtcars, x_var = 'nonexistent', y_var = 'mpg') -- column not found",
  viz_funnel(mtcars, x_var = "nonexistent", y_var = "mpg")
)


# #################################################################
#
#  CATEGORY 4: Type Validation Errors
#
# #################################################################
cat("\n\n")
cat(paste(rep("#", 70), collapse = ""), "\n")
cat("  CATEGORY 4: Type Validation Errors\n")
cat(paste(rep("#", 70), collapse = ""), "\n")

# ---- 4.1 data must be a data frame ----
show_error(
  "viz_bar('not_a_dataframe', x_var = 'x') -- data must be data frame",
  viz_bar("not_a_dataframe", x_var = "x")
)

# ---- 4.2 viz_scatter: data must be a data frame ----
show_error(
  "viz_scatter(42, x_var = 'x', y_var = 'y') -- data must be data frame",
  viz_scatter(42, x_var = "x", y_var = "y")
)

# ---- 4.3 viz_gauge: value must be numeric ----
show_error(
  "viz_gauge(value = 'not_numeric') -- value must be numeric",
  viz_gauge(value = "not_numeric")
)

# ---- 4.4 title must be character string ----
show_error(
  "add_viz(type = 'bar', title = 123) -- title must be character",
  create_content() %>% add_viz(type = "bar", title = 123)
)

# ---- 4.5 filter must be formula ----
show_error(
  "add_viz(type = 'bar', filter = 'not_formula') -- filter must be formula",
  create_content() %>% add_viz(type = "bar", filter = "not_formula")
)

# ---- 4.6 show_when must be formula ----
show_error(
  "add_viz(type = 'bar', show_when = 'not_formula') -- show_when must be formula",
  create_content() %>% add_viz(type = "bar", show_when = "not_formula")
)

# ---- 4.7 viz_pie: data must be a data frame ----
show_error(
  "viz_pie(list(a = 1), x_var = 'a') -- data must be data frame",
  viz_pie(list(a = 1), x_var = "a")
)

# ---- 4.8 viz_funnel: y_var must be numeric column ----
show_error(
  "viz_funnel with non-numeric y_var -- must be numeric column",
  viz_funnel(
    data.frame(stage = c("A", "B"), val = c("x", "y")),
    x_var = "stage", y_var = "val"
  )
)

# ---- 4.9 viz_sankey: value_var must be numeric ----
show_error(
  "viz_sankey with non-numeric value_var -- must be numeric column",
  viz_sankey(
    data.frame(from = "A", to = "B", val = "not_numeric"),
    from_var = "from", to_var = "to", value_var = "val"
  )
)

# ---- 4.10 viz_dumbbell: low_var must be numeric ----
show_error(
  "viz_dumbbell with non-numeric low_var -- must be numeric",
  viz_dumbbell(
    data.frame(cat = "A", lo = "x", hi = 5),
    x_var = "cat", low_var = "lo", high_var = "hi"
  )
)

# ---- 4.11 viz_gauge: value_var must be numeric column ----
show_error(
  "viz_gauge(data, value_var) with non-numeric column",
  viz_gauge(data = data.frame(x = c("a", "b")), value_var = "x")
)

# ---- 4.12 height must be positive numeric ----
show_error(
  "add_viz(type = 'bar', height = -10) -- height must be positive",
  create_content() %>% add_viz(type = "bar", height = -10)
)

# ---- 4.13 height must be numeric, not character ----
show_error(
  "add_viz(type = 'bar', height = 'tall') -- height must be numeric",
  create_content() %>% add_viz(type = "bar", height = "tall")
)

# ---- 4.14 text_position must be 'above' or 'below' ----
show_error(
  "add_viz(type = 'bar', text = 'hi', text_position = 'middle') -- invalid text_position",
  create_content() %>% add_viz(type = "bar", text = "hi", text_position = "middle")
)

# ---- 4.15 data param in add_viz must be data.frame or character ----
show_error(
  "add_viz(type = 'bar', data = 42) -- data must be data.frame or character",
  create_content() %>% add_viz(type = "bar", data = 42)
)


# #################################################################
#
#  CATEGORY 5: Pipeline / Object Type Errors
#
# #################################################################
cat("\n\n")
cat(paste(rep("#", 70), collapse = ""), "\n")
cat("  CATEGORY 5: Pipeline / Object Type Errors\n")
cat(paste(rep("#", 70), collapse = ""), "\n")

# ---- 5.1 add_viz: first arg must be content collection ----
show_error(
  "add_viz('not_collection', type = 'bar') -- first arg must be content collection",
  add_viz("not_collection", type = "bar")
)

# ---- 5.2 add_text: first arg must be content collection (numeric) ----
show_error(
  "add_text(42, text = 'hello') -- first arg must be content collection",
  add_text(42, text = "hello")
)

# ---- 5.3 end_sidebar: must be sidebar_container ----
show_error(
  "end_sidebar(create_content()) -- must be sidebar_container",
  end_sidebar(create_content())
)

# ---- 5.4 end_value_box_row: must be value_box_row_container ----
show_error(
  "end_value_box_row(create_content()) -- must be value_box_row_container",
  end_value_box_row(create_content())
)

# ---- 5.5 add_vizzes: first arg must be content collection ----
show_error(
  "add_vizzes('not_collection') -- first arg must be content collection",
  add_vizzes("not_collection")
)

# ---- 5.6 combine_content: all must be content collections ----
show_error(
  "combine_content(create_content(), 'not_collection') -- all must be collections",
  combine_content(create_content(), "not_collection")
)

# ---- 5.7 + operator on non-collections ----
show_error(
  "create_content() + 'not_a_collection' -- right operand must be collection",
  create_content() + "not_a_collection"
)


# #################################################################
#
#  CATEGORY 6: Input Helper Errors
#
# #################################################################
cat("\n\n")
cat(paste(rep("#", 70), collapse = ""), "\n")
cat("  CATEGORY 6: Input Helper Errors\n")
cat(paste(rep("#", 70), collapse = ""), "\n")

# ---- 6.1 add_input: missing input_id ----
show_error(
  "add_input() missing input_id -- required parameter",
  create_content() %>% add_input(filter_var = "x")
)

# ---- 6.2 add_input: missing filter_var ----
show_error(
  "add_input() missing filter_var -- required parameter",
  create_content() %>% add_input(input_id = "test")
)

# ---- 6.3 Unknown input type via match.arg ----
show_error(
  "add_input(type = 'dropdown') -- unknown type (match.arg error with valid types)",
  create_content() %>% add_input(
    input_id = "test", filter_var = "x",
    type = "dropdown", options = c("A", "B")
  )
)

# ---- 6.4 render_input: unknown type via match.arg ----
show_error(
  "render_input(type = 'textfield') -- unknown type via match.arg",
  render_input(input_id = "test", filter_var = "x", type = "textfield")
)


# #################################################################
#
#  CATEGORY 7: Dashboard Creation Errors
#
# #################################################################
cat("\n\n")
cat(paste(rep("#", 70), collapse = ""), "\n")
cat("  CATEGORY 7: Dashboard Creation Errors\n")
cat(paste(rep("#", 70), collapse = ""), "\n")

# ---- 7.1 invalid tabset_theme (with suggestion) ----
show_error(
  "create_dashboard(tabset_theme = 'invalid_theme') -- shows valid themes",
  create_dashboard(tabset_theme = "invalid_theme")
)

# ---- 7.2 invalid pagination_position ----
show_error(
  "create_dashboard(pagination_position = 'invalid') -- must be bottom/top/both",
  create_dashboard(pagination_position = "invalid")
)

# ---- 7.3 tabset_colors must be a named list ----
show_error(
  "create_dashboard(tabset_colors = 'red') -- must be named list",
  create_dashboard(tabset_colors = "red")
)

# ---- 7.4 tabset_theme typo: 'clasic' -> 'classic' ----
show_error(
  "create_dashboard(tabset_theme = 'clasic') -- typo, suggests 'classic'",
  create_dashboard(tabset_theme = "clasic")
)

# ---- 7.5 tabset_theme typo: 'undeline' -> 'underline' ----
show_error(
  "create_dashboard(tabset_theme = 'undeline') -- typo, suggests 'underline'",
  create_dashboard(tabset_theme = "undeline")
)


# #################################################################
#
#  CATEGORY 8: Missing Parameter with Example Hint
#
# #################################################################
cat("\n\n")
cat(paste(rep("#", 70), collapse = ""), "\n")
cat("  CATEGORY 8: Missing Parameter with Example Hint\n")
cat("  (.stop_with_hint includes example usage code)\n")
cat(paste(rep("#", 70), collapse = ""), "\n")

# ---- 8.1 add_viz: missing type (shows valid types AND example) ----
show_error(
  "add_viz() with no type -- shows available types AND example code",
  create_content() %>% add_viz()
)

# ---- 8.2 viz_bar: missing x_var (shows example code) ----
show_error(
  "viz_bar(mtcars) -- hint includes example: viz_bar(data, x_var = \"category\")",
  viz_bar(mtcars)
)

# ---- 8.3 viz_scatter: missing y_var (shows example code) ----
show_error(
  "viz_scatter(mtcars, x_var = 'mpg') -- hint includes scatter example",
  viz_scatter(mtcars, x_var = "mpg")
)

# ---- 8.4 viz_heatmap: missing value_var (shows example) ----
show_error(
  "viz_heatmap(mtcars, x_var = 'cyl', y_var = 'gear') -- hint includes heatmap example",
  viz_heatmap(mtcars, x_var = "cyl", y_var = "gear")
)

# ---- 8.5 viz_sankey: missing value_var (shows full example) ----
show_error(
  "viz_sankey(mtcars, from_var = 'a', to_var = 'b') -- hint includes sankey example",
  viz_sankey(mtcars, from_var = "a", to_var = "b")
)

# ---- 8.6 viz_gauge: hint includes gauge example ----
show_error(
  "viz_gauge() -- hint includes: viz_gauge(value = 73, title = \"Score\")",
  viz_gauge()
)

# ---- 8.7 viz_funnel: missing y_var (shows full example) ----
show_error(
  "viz_funnel(mtcars, x_var = 'cyl') -- hint includes funnel example",
  viz_funnel(mtcars, x_var = "cyl")
)

# ---- 8.8 viz_dumbbell: missing x_var (shows full example) ----
show_error(
  "viz_dumbbell(mtcars) -- hint includes dumbbell example",
  viz_dumbbell(mtcars)
)


# #################################################################
#
#  CATEGORY 9: Collection Validation Errors
#
# #################################################################
cat("\n\n")
cat(paste(rep("#", 70), collapse = ""), "\n")
cat("  CATEGORY 9: Collection Validation Errors\n")
cat(paste(rep("#", 70), collapse = ""), "\n")

# ---- 9.1 preview() on empty collection ----
show_error(
  "preview() on empty collection -- collection is empty",
  create_content() %>% preview()
)

# ---- 9.2 preview() on collection without data ----
show_error(
  "preview() on collection without data -- no data attached",
  create_content() %>% add_viz(type = "bar", x_var = "x") %>% preview()
)

# ---- 9.3 icon format warning (not fatal, but shows validation) ----
error_count <- error_count + 1L
cat("\n", paste(rep("=", 70), collapse = ""), "\n")
cat("  [", error_count, "] add_viz(icon = 'bad-format') -- icon format warning\n", sep = "")
cat(paste(rep("-", 70), collapse = ""), "\n")
tryCatch({
  w <- NULL
  withCallingHandlers(
    create_content() %>% add_viz(type = "bar", icon = "bad_format_no_colon"),
    warning = function(w_) { w <<- w_; invokeRestart("muffleWarning") }
  )
  if (!is.null(w)) cat("  WARNING:", conditionMessage(w), "\n")
}, error = function(e) cat("  ERROR:", conditionMessage(e), "\n"))


# #################################################################
#
#  CATEGORY 10: Miscellaneous Validation Errors
#
# #################################################################
cat("\n\n")
cat(paste(rep("#", 70), collapse = ""), "\n")
cat("  CATEGORY 10: Miscellaneous Validation Errors\n")
cat(paste(rep("#", 70), collapse = ""), "\n")

# ---- 10.1 viz_scatter: invalid trend_method ----
show_error(
  "viz_scatter(trend_method = 'cubic') -- must be 'lm' or 'loess'",
  viz_scatter(mtcars, x_var = "mpg", y_var = "wt", trend_method = "cubic")
)

# ---- 10.2 add_viz: text params must be character strings ----
show_error(
  "add_viz(text_before_tabset = 123) -- must be character",
  create_content() %>% add_viz(type = "bar", text_before_tabset = 123)
)

# ---- 10.3 add_viz: text_after_tabset must be character ----
show_error(
  "add_viz(text_after_tabset = TRUE) -- must be character",
  create_content() %>% add_viz(type = "bar", text_after_tabset = TRUE)
)

# ---- 10.4 add_viz: text_before_viz must be character ----
show_error(
  "add_viz(text_before_viz = list()) -- must be character",
  create_content() %>% add_viz(type = "bar", text_before_viz = list())
)

# ---- 10.5 add_viz: text_after_viz must be character ----
show_error(
  "add_viz(text_after_viz = 42) -- must be character",
  create_content() %>% add_viz(type = "bar", text_after_viz = 42)
)

# ---- 10.6 add_viz: icon must be character ----
show_error(
  "add_viz(type = 'bar', icon = 99) -- icon must be character",
  create_content() %>% add_viz(type = "bar", icon = 99)
)

# ---- 10.7 add_viz: filter formula must be one-sided ----
show_error(
  "add_viz(filter = y ~ x) -- filter must be one-sided (~condition)",
  create_content() %>% add_viz(type = "bar", filter = y ~ x)
)

# ---- 10.8 add_viz: show_when formula must be one-sided ----
show_error(
  "add_viz(show_when = y ~ x) -- show_when must be one-sided (~condition)",
  create_content() %>% add_viz(type = "bar", show_when = y ~ x)
)


# =================================================================
# Summary
# =================================================================
cat("\n\n")
cat(paste(rep("=", 70), collapse = ""), "\n")
cat(paste(rep("=", 70), collapse = ""), "\n")
cat("  DEMO COMPLETE\n")
cat("  Total error scenarios demonstrated: ", error_count, "\n")
cat(paste(rep("=", 70), collapse = ""), "\n")
cat("\n")
cat("  Categories covered:\n")
cat("    1. Missing Required Parameters (.stop_with_hint)\n")
cat("    2. Typo Detection (.stop_with_suggestion)\n")
cat("    3. Column Not Found Errors\n")
cat("    4. Type Validation Errors\n")
cat("    5. Pipeline / Object Type Errors\n")
cat("    6. Input Helper Errors\n")
cat("    7. Dashboard Creation Errors\n")
cat("    8. Missing Parameter with Example Hint\n")
cat("    9. Collection Validation Errors\n")
cat("   10. Miscellaneous Validation Errors\n")
cat("\n")

