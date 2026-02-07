# Tests for viz_waffle — lightweight, covr-safe (no skip_on_covr_ci)
library(testthat)

test_that("viz_waffle basic chart from raw data", {
  hc <- viz_waffle(mtcars, x_var = "cyl", title = "Waffle")
  expect_s3_class(hc, "highchart")
})

test_that("viz_waffle with pre-aggregated data", {
  df <- data.frame(
    category = c("Agree", "Neutral", "Disagree"),
    count = c(45, 30, 25)
  )
  hc <- viz_waffle(df, x_var = "category", y_var = "count", total = 100)
  expect_s3_class(hc, "highchart")
})

test_that("viz_waffle with custom grid dimensions", {
  hc <- viz_waffle(mtcars, x_var = "cyl", total = 50, rows = 5)
  expect_s3_class(hc, "highchart")
})

test_that("viz_waffle with x_order", {
  df <- data.frame(cat = c("C", "B", "A"), val = c(10, 20, 30))
  hc <- viz_waffle(df, x_var = "cat", y_var = "val",
                   x_order = c("A", "B", "C"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_waffle with color_palette", {
  hc <- viz_waffle(mtcars, x_var = "cyl",
                   color_palette = c("#ff0000", "#00ff00", "#0000ff"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_waffle with title and subtitle", {
  hc <- viz_waffle(mtcars, x_var = "cyl",
                   title = "Main Title", subtitle = "Sub Title")
  expect_s3_class(hc, "highchart")
})

test_that("viz_waffle with data_labels_enabled", {
  hc <- viz_waffle(mtcars, x_var = "cyl", data_labels_enabled = TRUE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_waffle with show_in_legend FALSE", {
  hc <- viz_waffle(mtcars, x_var = "cyl", show_in_legend = FALSE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_waffle with custom border_color and border_width", {
  hc <- viz_waffle(mtcars, x_var = "cyl",
                   border_color = "#cccccc", border_width = 2)
  expect_s3_class(hc, "highchart")
})

test_that("viz_waffle with weight_var", {
  df <- data.frame(
    category = c("A", "A", "B", "B"),
    weight = c(1.5, 2.0, 1.0, 3.0)
  )
  hc <- viz_waffle(df, x_var = "category", weight_var = "weight")
  expect_s3_class(hc, "highchart")
})

test_that("viz_waffle errors on missing column", {
  expect_error(viz_waffle(mtcars, x_var = "nope"), "not found")
})
