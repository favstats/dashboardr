# Tests for viz_histogram.R — lightweight, covr-safe
library(testthat)

df <- data.frame(
  age = c(20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 22, 28, 33, 38, 42, 48, 53, 58, 63, 68),
  category = rep(c("A", "B", "C", "D", "E"), 4),
  weight = runif(20, 0.5, 2.0),
  stringsAsFactors = FALSE
)

test_that("viz_histogram basic count", {
  hc <- viz_histogram(df, x_var = "age")
  expect_s3_class(hc, "highchart")
})

test_that("viz_histogram with title and labels", {
  hc <- viz_histogram(df, x_var = "age", title = "Age Distribution",
                      subtitle = "Sample data",
                      x_label = "Age (years)", y_label = "Count")
  expect_s3_class(hc, "highchart")
})

test_that("viz_histogram percent mode", {
  hc <- viz_histogram(df, x_var = "age", histogram_type = "percent")
  expect_s3_class(hc, "highchart")
})

test_that("viz_histogram with bins", {
  hc <- viz_histogram(df, x_var = "age", bins = 5)
  expect_s3_class(hc, "highchart")
})

test_that("viz_histogram with bin_breaks", {
  hc <- viz_histogram(df, x_var = "age",
                      bin_breaks = c(20, 30, 40, 50, 60, 70))
  expect_s3_class(hc, "highchart")
})

test_that("viz_histogram with bin_breaks and labels", {
  hc <- viz_histogram(df, x_var = "age",
                      bin_breaks = c(20, 40, 60, 80),
                      bin_labels = c("Young", "Middle", "Senior"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_histogram categorical x_var", {
  hc <- viz_histogram(df, x_var = "category")
  expect_s3_class(hc, "highchart")
})

test_that("viz_histogram with color_palette", {
  hc <- viz_histogram(df, x_var = "category", color_palette = "steelblue")
  expect_s3_class(hc, "highchart")
})

test_that("viz_histogram with color_palette vector", {
  hc <- viz_histogram(df, x_var = "category",
                      color_palette = c("#ff0000", "#00ff00", "#0000ff", "#ff00ff", "#00ffff"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_histogram with x_order", {
  hc <- viz_histogram(df, x_var = "category",
                      x_order = c("E", "D", "C", "B", "A"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_histogram with x_map_values", {
  hc <- viz_histogram(df, x_var = "category",
                      x_map_values = list("A" = "Alpha", "B" = "Beta"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_histogram with weight_var", {
  hc <- viz_histogram(df, x_var = "category", weight_var = "weight")
  expect_s3_class(hc, "highchart")
})

test_that("viz_histogram include_na", {
  df_na <- df
  df_na$category[c(1, 5, 10)] <- NA
  hc <- viz_histogram(df_na, x_var = "category", include_na = TRUE,
                      na_label = "No Response")
  expect_s3_class(hc, "highchart")
})

test_that("viz_histogram exclude_na (default)", {
  df_na <- df
  df_na$category[1] <- NA
  hc <- viz_histogram(df_na, x_var = "category")
  expect_s3_class(hc, "highchart")
})

test_that("viz_histogram data_labels disabled", {
  hc <- viz_histogram(df, x_var = "category", data_labels_enabled = FALSE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_histogram label_decimals", {
  hc <- viz_histogram(df, x_var = "age", histogram_type = "percent",
                      label_decimals = 2)
  expect_s3_class(hc, "highchart")
})

test_that("viz_histogram with tooltip_prefix and suffix", {
  hc <- viz_histogram(df, x_var = "category",
                      tooltip_prefix = "N = ", tooltip_suffix = " people")
  expect_s3_class(hc, "highchart")
})

test_that("viz_histogram with tooltip string", {
  hc <- viz_histogram(df, x_var = "category",
                      tooltip = "{category}: {value}")
  expect_s3_class(hc, "highchart")
})

test_that("viz_histogram with y_var pre-aggregated", {
  agg <- data.frame(cat = c("A", "B", "C"), n = c(10, 20, 15))
  hc <- viz_histogram(agg, x_var = "cat", y_var = "n")
  expect_s3_class(hc, "highchart")
})

test_that("viz_histogram with haven_labelled", {
  df_lab <- data.frame(
    edu = structure(c(1, 2, 3, 1, 2, 3, 1, 2, 3, 1),
                    labels = c("Low" = 1, "Med" = 2, "High" = 3),
                    class = "haven_labelled")
  )
  hc <- viz_histogram(df_lab, x_var = "edu")
  expect_s3_class(hc, "highchart")
})

test_that("viz_histogram error: missing column", {
  expect_error(viz_histogram(df, x_var = "nonexistent"))
})

test_that("viz_histogram error: non-data.frame", {
  expect_error(viz_histogram("not_a_df", x_var = "age"))
})
