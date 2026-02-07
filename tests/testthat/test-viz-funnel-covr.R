# Tests for viz_funnel — lightweight, covr-safe (no skip_on_covr_ci)
library(testthat)

test_that("viz_funnel basic chart", {
  df <- data.frame(
    stage = c("Visits", "Signups", "Trial", "Purchase"),
    count = c(10000, 3000, 800, 200)
  )
  hc <- viz_funnel(df, x_var = "stage", y_var = "count")
  expect_s3_class(hc, "highchart")
  expect_true(length(hc$x$hc_opts$series) >= 1)
})

test_that("viz_funnel with title and subtitle", {
  df <- data.frame(
    stage = c("Visits", "Signups", "Purchase"),
    count = c(10000, 3000, 200)
  )
  hc <- viz_funnel(df, x_var = "stage", y_var = "count",
                   title = "Conversion Funnel",
                   subtitle = "Q1 2024")
  expect_s3_class(hc, "highchart")
})

test_that("viz_funnel reversed (pyramid)", {
  df <- data.frame(
    stage = c("Visits", "Signups", "Purchase"),
    count = c(10000, 3000, 200)
  )
  hc <- viz_funnel(df, x_var = "stage", y_var = "count", reversed = TRUE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_funnel custom neck dimensions", {
  df <- data.frame(
    stage = c("Visits", "Signups", "Purchase"),
    count = c(10000, 3000, 200)
  )
  hc <- viz_funnel(df, x_var = "stage", y_var = "count",
                   neck_width = "20%", neck_height = "30%")
  expect_s3_class(hc, "highchart")
})

test_that("viz_funnel with show_conversion", {
  df <- data.frame(
    stage = c("Visits", "Signups", "Purchase"),
    count = c(10000, 3000, 200)
  )
  hc <- viz_funnel(df, x_var = "stage", y_var = "count",
                   show_conversion = TRUE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_funnel with color_palette", {
  df <- data.frame(
    stage = c("A", "B", "C"),
    count = c(100, 60, 20)
  )
  hc <- viz_funnel(df, x_var = "stage", y_var = "count",
                   color_palette = c("#4E79A7", "#F28E2B", "#E15759"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_funnel with x_order", {
  df <- data.frame(
    stage = c("C", "A", "B"),
    count = c(20, 100, 60)
  )
  hc <- viz_funnel(df, x_var = "stage", y_var = "count",
                   x_order = c("A", "B", "C"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_funnel with data_labels_enabled FALSE", {
  df <- data.frame(
    stage = c("A", "B", "C"),
    count = c(100, 60, 20)
  )
  hc <- viz_funnel(df, x_var = "stage", y_var = "count",
                   data_labels_enabled = FALSE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_funnel with show_in_legend TRUE", {
  df <- data.frame(
    stage = c("A", "B", "C"),
    count = c(100, 60, 20)
  )
  hc <- viz_funnel(df, x_var = "stage", y_var = "count",
                   show_in_legend = TRUE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_funnel errors on missing columns", {
  df <- data.frame(stage = c("A", "B"), count = c(100, 50))
  expect_error(viz_funnel(df, x_var = "nope", y_var = "count"), "not found")
})

test_that("viz_funnel errors on non-numeric y_var", {
  df <- data.frame(a = c("x", "y"), b = c("a", "b"))
  expect_error(viz_funnel(df, x_var = "a", y_var = "b"), "numeric")
})
