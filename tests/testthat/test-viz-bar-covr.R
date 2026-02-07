# Tests for viz_bar.R — lightweight, covr-safe
library(testthat)

df <- data.frame(
  category = c("A", "B", "C", "A", "B", "C", "A", "A", "B", "C"),
  group = c("X", "X", "X", "Y", "Y", "Y", "X", "Y", "X", "Y"),
  value = c(10, 20, 30, 15, 25, 35, 12, 18, 22, 28),
  weight = c(1.0, 1.5, 0.8, 1.2, 0.9, 1.1, 1.0, 1.3, 0.7, 1.4),
  stringsAsFactors = FALSE
)

test_that("viz_bar basic count", {
  hc <- viz_bar(df, x_var = "category")
  expect_s3_class(hc, "highchart")
})

test_that("viz_bar with title and labels", {
  hc <- viz_bar(df, x_var = "category", title = "My Bar",
                subtitle = "Sub", x_label = "Cat", y_label = "Count")
  expect_s3_class(hc, "highchart")
})

test_that("viz_bar percent mode", {
  hc <- viz_bar(df, x_var = "category", bar_type = "percent")
  expect_s3_class(hc, "highchart")
})

test_that("viz_bar horizontal", {
  hc <- viz_bar(df, x_var = "category", horizontal = TRUE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_bar with group_var", {
  hc <- viz_bar(df, x_var = "category", group_var = "group")
  expect_s3_class(hc, "highchart")
})

test_that("viz_bar with group_var percent", {
  hc <- viz_bar(df, x_var = "category", group_var = "group", bar_type = "percent")
  expect_s3_class(hc, "highchart")
})

test_that("viz_bar with value_var (mean)", {
  hc <- viz_bar(df, x_var = "category", value_var = "value")
  expect_s3_class(hc, "highchart")
})

test_that("viz_bar with value_var and group_var", {
  hc <- viz_bar(df, x_var = "category", value_var = "value", group_var = "group")
  expect_s3_class(hc, "highchart")
})

test_that("viz_bar with weight_var", {
  hc <- viz_bar(df, x_var = "category", weight_var = "weight")
  expect_s3_class(hc, "highchart")
})

test_that("viz_bar sort_by_value", {
  hc <- viz_bar(df, x_var = "category", sort_by_value = TRUE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_bar sort ascending", {
  hc <- viz_bar(df, x_var = "category", sort_by_value = TRUE, sort_desc = FALSE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_bar with color_palette", {
  hc <- viz_bar(df, x_var = "category", color_palette = c("red", "blue", "green"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_bar with x_order", {
  hc <- viz_bar(df, x_var = "category", x_order = c("C", "B", "A"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_bar with group_order", {
  hc <- viz_bar(df, x_var = "category", group_var = "group",
                group_order = c("Y", "X"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_bar with tooltip_prefix and suffix", {
  hc <- viz_bar(df, x_var = "category",
                tooltip_prefix = "Count: ", tooltip_suffix = " items")
  expect_s3_class(hc, "highchart")
})

test_that("viz_bar with tooltip string", {
  hc <- viz_bar(df, x_var = "category",
                tooltip = "{category}: {value}")
  expect_s3_class(hc, "highchart")
})

test_that("viz_bar data_labels disabled", {
  hc <- viz_bar(df, x_var = "category", data_labels_enabled = FALSE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_bar label_decimals", {
  hc <- viz_bar(df, x_var = "category", value_var = "value",
                label_decimals = 2)
  expect_s3_class(hc, "highchart")
})

test_that("viz_bar include_na", {
  df_na <- df
  df_na$category[1] <- NA
  hc <- viz_bar(df_na, x_var = "category", include_na = TRUE, na_label = "Missing")
  expect_s3_class(hc, "highchart")
})

test_that("viz_bar with pre-aggregated y_var", {
  agg_df <- data.frame(category = c("A", "B", "C"), count = c(10, 20, 30))
  hc <- viz_bar(agg_df, x_var = "category", y_var = "count")
  expect_s3_class(hc, "highchart")
})

test_that("viz_bar with error_bars sd", {
  hc <- viz_bar(df, x_var = "category", value_var = "value", error_bars = "sd")
  expect_s3_class(hc, "highchart")
})

test_that("viz_bar with error_bars se", {
  hc <- viz_bar(df, x_var = "category", value_var = "value", error_bars = "se")
  expect_s3_class(hc, "highchart")
})

test_that("viz_bar with error_bars ci", {
  hc <- viz_bar(df, x_var = "category", value_var = "value",
                error_bars = "ci", ci_level = 0.99)
  expect_s3_class(hc, "highchart")
})

test_that("viz_bar complete_groups FALSE", {
  hc <- viz_bar(df, x_var = "category", group_var = "group",
                complete_groups = FALSE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_bar horizontal with group_var", {
  hc <- viz_bar(df, x_var = "category", group_var = "group", horizontal = TRUE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_bar horizontal sort_by_value", {
  hc <- viz_bar(df, x_var = "category", horizontal = TRUE, sort_by_value = TRUE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_bar with haven_labelled x_var", {
  df_lab <- df
  df_lab$category <- structure(c(1,2,3,1,2,3,1,1,2,3),
                               labels = c("A" = 1, "B" = 2, "C" = 3),
                               class = "haven_labelled")
  hc <- viz_bar(df_lab, x_var = "category")
  expect_s3_class(hc, "highchart")
})

test_that("viz_bar error: missing column", {
  expect_error(viz_bar(df, x_var = "nonexistent"))
})

test_that("viz_bar error: non-data.frame input", {
  expect_error(viz_bar("not_a_df", x_var = "category"))
})
