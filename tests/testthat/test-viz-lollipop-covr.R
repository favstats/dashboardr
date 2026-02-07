# Tests for viz_lollipop — lightweight, covr-safe (no skip_on_covr_ci)
library(testthat)

test_that("viz_lollipop basic chart from raw data", {
  hc <- viz_lollipop(mtcars, x_var = "cyl", title = "Lollipop")
  expect_s3_class(hc, "highchart")
  expect_true(length(hc$x$hc_opts$series) >= 1)
})

test_that("viz_lollipop horizontal (default)", {
  hc <- viz_lollipop(mtcars, x_var = "cyl")
  expect_s3_class(hc, "highchart")
})

test_that("viz_lollipop vertical", {
  hc <- viz_lollipop(mtcars, x_var = "cyl", horizontal = FALSE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_lollipop with pre-aggregated data", {
  df <- data.frame(country = c("US", "UK", "DE"), score = c(85, 72, 68))
  hc <- viz_lollipop(df, x_var = "country", y_var = "score")
  expect_s3_class(hc, "highchart")
})

test_that("viz_lollipop with group_var", {
  df <- data.frame(
    category = rep(c("A", "B"), each = 3),
    group = rep(c("X", "Y", "Z"), 2),
    value = c(10, 20, 30, 15, 25, 35)
  )
  hc <- viz_lollipop(df, x_var = "category", group_var = "group", y_var = "value")
  expect_s3_class(hc, "highchart")
})

test_that("viz_lollipop percent mode", {
  hc <- viz_lollipop(mtcars, x_var = "cyl", bar_type = "percent")
  expect_s3_class(hc, "highchart")
})

test_that("viz_lollipop sort_by_value", {
  hc <- viz_lollipop(mtcars, x_var = "cyl", sort_by_value = TRUE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_lollipop sort_by_value descending", {
  hc <- viz_lollipop(mtcars, x_var = "cyl", sort_by_value = TRUE, sort_desc = FALSE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_lollipop with color_palette", {
  hc <- viz_lollipop(mtcars, x_var = "cyl",
                     color_palette = c("#ff0000", "#00ff00", "#0000ff"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_lollipop with x_order", {
  hc <- viz_lollipop(mtcars, x_var = "cyl", x_order = c("4", "6", "8"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_lollipop with weight_var", {
  df <- data.frame(
    category = c("A", "A", "B", "B"),
    weight = c(1.5, 2.0, 1.0, 3.0)
  )
  hc <- viz_lollipop(df, x_var = "category", weight_var = "weight")
  expect_s3_class(hc, "highchart")
})

test_that("viz_lollipop with title, x_label, y_label", {
  hc <- viz_lollipop(mtcars, x_var = "cyl",
                     title = "Cars", x_label = "Cylinders", y_label = "Count")
  expect_s3_class(hc, "highchart")
})

test_that("viz_lollipop with custom dot_size and stem_width", {
  hc <- viz_lollipop(mtcars, x_var = "cyl", dot_size = 12, stem_width = 4)
  expect_s3_class(hc, "highchart")
})

test_that("viz_lollipop errors on missing x_var", {
  expect_error(viz_lollipop(mtcars, x_var = "nope"), "not found")
})

test_that("viz_lollipop with value_var (mean aggregation)", {
  hc <- viz_lollipop(mtcars, x_var = "cyl", value_var = "mpg")
  expect_s3_class(hc, "highchart")
})
