# Tests for viz_stackedbar.R — lightweight, covr-safe
library(testthat)

# Mode 1: Grouped/Crosstab data
df_crosstab <- data.frame(
  category = rep(c("A", "B", "C"), each = 6),
  response = rep(c("Agree", "Neutral", "Disagree"), times = 6),
  weight = runif(18, 0.5, 2.0),
  stringsAsFactors = FALSE
)

# Mode 2: Multi-variable/Battery data
df_battery <- data.frame(
  q1 = sample(c("Strongly Agree", "Agree", "Neutral", "Disagree", "Strongly Disagree"), 50, replace = TRUE),
  q2 = sample(c("Strongly Agree", "Agree", "Neutral", "Disagree", "Strongly Disagree"), 50, replace = TRUE),
  q3 = sample(c("Strongly Agree", "Agree", "Neutral", "Disagree", "Strongly Disagree"), 50, replace = TRUE),
  stringsAsFactors = FALSE
)

# --- Mode 1: Crosstab (x_var + stack_var) ---

test_that("viz_stackedbar crosstab basic counts", {
  hc <- viz_stackedbar(df_crosstab, x_var = "category", stack_var = "response")
  expect_s3_class(hc, "highchart")
})

test_that("viz_stackedbar crosstab percent", {
  hc <- viz_stackedbar(df_crosstab, x_var = "category", stack_var = "response",
                       stacked_type = "percent")
  expect_s3_class(hc, "highchart")
})

test_that("viz_stackedbar with title and labels", {
  hc <- viz_stackedbar(df_crosstab, x_var = "category", stack_var = "response",
                       title = "Responses by Category",
                       subtitle = "Survey",
                       x_label = "Category", y_label = "Count",
                       stack_label = "Response")
  expect_s3_class(hc, "highchart")
})

test_that("viz_stackedbar horizontal", {
  hc <- viz_stackedbar(df_crosstab, x_var = "category", stack_var = "response",
                       horizontal = TRUE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_stackedbar with stack_order", {
  hc <- viz_stackedbar(df_crosstab, x_var = "category", stack_var = "response",
                       stack_order = c("Disagree", "Neutral", "Agree"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_stackedbar with x_order", {
  hc <- viz_stackedbar(df_crosstab, x_var = "category", stack_var = "response",
                       x_order = c("C", "B", "A"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_stackedbar with color_palette", {
  hc <- viz_stackedbar(df_crosstab, x_var = "category", stack_var = "response",
                       color_palette = c("red", "gray", "blue"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_stackedbar with weight_var", {
  hc <- viz_stackedbar(df_crosstab, x_var = "category", stack_var = "response",
                       weight_var = "weight")
  expect_s3_class(hc, "highchart")
})

test_that("viz_stackedbar with tooltip prefix/suffix", {
  hc <- viz_stackedbar(df_crosstab, x_var = "category", stack_var = "response",
                       tooltip_prefix = "N = ", tooltip_suffix = " people")
  expect_s3_class(hc, "highchart")
})

test_that("viz_stackedbar with tooltip string", {
  hc <- viz_stackedbar(df_crosstab, x_var = "category", stack_var = "response",
                       tooltip = "{category} - {series}: {value}")
  expect_s3_class(hc, "highchart")
})

test_that("viz_stackedbar data_labels disabled", {
  hc <- viz_stackedbar(df_crosstab, x_var = "category", stack_var = "response",
                       data_labels_enabled = FALSE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_stackedbar label_decimals", {
  hc <- viz_stackedbar(df_crosstab, x_var = "category", stack_var = "response",
                       stacked_type = "percent", label_decimals = 2)
  expect_s3_class(hc, "highchart")
})

test_that("viz_stackedbar include_na", {
  df_na <- df_crosstab
  df_na$category[1] <- NA
  df_na$response[5] <- NA
  hc <- viz_stackedbar(df_na, x_var = "category", stack_var = "response",
                       include_na = TRUE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_stackedbar with x_map_values", {
  hc <- viz_stackedbar(df_crosstab, x_var = "category", stack_var = "response",
                       x_map_values = list("A" = "Alpha"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_stackedbar with stack_map_values", {
  hc <- viz_stackedbar(df_crosstab, x_var = "category", stack_var = "response",
                       stack_map_values = list("Agree" = "Yes"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_stackedbar hide stack_label", {
  hc <- viz_stackedbar(df_crosstab, x_var = "category", stack_var = "response",
                       stack_label = NULL)
  expect_s3_class(hc, "highchart")
})

test_that("viz_stackedbar with pre-aggregated y_var", {
  agg <- data.frame(
    category = rep(c("A", "B", "C"), each = 3),
    response = rep(c("Agree", "Neutral", "Disagree"), 3),
    count = c(10, 5, 3, 8, 7, 4, 12, 3, 2)
  )
  hc <- viz_stackedbar(agg, x_var = "category", stack_var = "response",
                       y_var = "count")
  expect_s3_class(hc, "highchart")
})

# --- Mode 2: Multi-variable/Battery (x_vars) ---

test_that("viz_stackedbar battery basic", {
  hc <- viz_stackedbar(df_battery, x_vars = c("q1", "q2", "q3"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_stackedbar battery percent", {
  hc <- viz_stackedbar(df_battery, x_vars = c("q1", "q2", "q3"),
                       stacked_type = "percent")
  expect_s3_class(hc, "highchart")
})

test_that("viz_stackedbar battery with labels", {
  hc <- viz_stackedbar(df_battery, x_vars = c("q1", "q2", "q3"),
                       x_var_labels = c("Question 1", "Question 2", "Question 3"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_stackedbar battery with response_levels", {
  hc <- viz_stackedbar(df_battery, x_vars = c("q1", "q2", "q3"),
                       response_levels = c("Strongly Disagree", "Disagree", "Neutral",
                                          "Agree", "Strongly Agree"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_stackedbar battery with color_palette", {
  hc <- viz_stackedbar(df_battery, x_vars = c("q1", "q2", "q3"),
                       color_palette = c("#d32f2f", "#f57c00", "#fdd835", "#66bb6a", "#2e7d32"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_stackedbar battery horizontal", {
  hc <- viz_stackedbar(df_battery, x_vars = c("q1", "q2", "q3"),
                       horizontal = TRUE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_stackedbar with haven_labelled x_var", {
  df_lab <- df_crosstab
  df_lab$category <- structure(rep(1:3, each = 6),
                               labels = c("A" = 1, "B" = 2, "C" = 3),
                               class = "haven_labelled")
  hc <- viz_stackedbar(df_lab, x_var = "category", stack_var = "response")
  expect_s3_class(hc, "highchart")
})

test_that("viz_stackedbar error: missing column", {
  expect_error(viz_stackedbar(df_crosstab, x_var = "nonexistent", stack_var = "response"))
})

test_that("viz_stackedbar error: non-data.frame", {
  expect_error(viz_stackedbar("not_a_df", x_var = "category", stack_var = "response"))
})
