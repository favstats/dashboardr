# Tests for viz_gauge — lightweight, covr-safe (no skip_on_covr_ci)
library(testthat)

test_that("viz_gauge basic with static value", {
  hc <- viz_gauge(value = 73, title = "Score")
  expect_s3_class(hc, "highchart")
})

test_that("viz_gauge from data with value_var", {
  hc <- viz_gauge(data = mtcars, value_var = "mpg", min = 10, max = 35)
  expect_s3_class(hc, "highchart")
})

test_that("viz_gauge custom min/max", {
  hc <- viz_gauge(value = 500, min = 0, max = 1000)
  expect_s3_class(hc, "highchart")
})

test_that("viz_gauge with color bands", {
  hc <- viz_gauge(value = 65, bands = list(
    list(from = 0, to = 40, color = "#E15759"),
    list(from = 40, to = 70, color = "#F28E2B"),
    list(from = 70, to = 100, color = "#59A14F")
  ))
  expect_s3_class(hc, "highchart")
})

test_that("viz_gauge with data_labels_format", {
  hc <- viz_gauge(value = 73, data_labels_format = "{y}%")
  expect_s3_class(hc, "highchart")
})

test_that("viz_gauge with target line", {
  hc <- viz_gauge(value = 73, target = 80, target_color = "red")
  expect_s3_class(hc, "highchart")
})

test_that("viz_gauge with subtitle", {
  hc <- viz_gauge(value = 50, title = "KPI", subtitle = "Current quarter")
  expect_s3_class(hc, "highchart")
})

test_that("viz_gauge with custom color", {
  hc <- viz_gauge(value = 42, color = "#E15759")
  expect_s3_class(hc, "highchart")
})

test_that("viz_gauge with custom background_color", {
  hc <- viz_gauge(value = 42, background_color = "#f0f0f0")
  expect_s3_class(hc, "highchart")
})

test_that("viz_gauge with inner_radius", {
  hc <- viz_gauge(value = 60, inner_radius = "80%")
  expect_s3_class(hc, "highchart")
})

test_that("viz_gauge with rounded = FALSE", {
  hc <- viz_gauge(value = 60, rounded = FALSE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_gauge errors when neither data nor value provided", {
  expect_error(viz_gauge(), "required")
})

test_that("viz_gauge errors on invalid gauge_type", {
  expect_error(viz_gauge(value = 50, gauge_type = "invalid"), "solid")
})
