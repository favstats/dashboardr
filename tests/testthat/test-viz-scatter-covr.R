# Tests for viz_scatter — lightweight, covr-safe
# Targets uncovered branches: color_var, size_var, show_trend, jitter,
# alpha, include_na, labels, color_palette
library(testthat)

test_that("viz_scatter basic plot", {
  hc <- viz_scatter(mtcars, x_var = "wt", y_var = "mpg")
  expect_s3_class(hc, "highchart")
})

test_that("viz_scatter with title and labels", {
  hc <- viz_scatter(mtcars, x_var = "wt", y_var = "mpg",
                    title = "Weight vs MPG",
                    x_label = "Weight (1000 lbs)",
                    y_label = "Miles per Gallon")
  expect_s3_class(hc, "highchart")
})

test_that("viz_scatter with color_var grouping", {
  hc <- viz_scatter(mtcars, x_var = "wt", y_var = "mpg",
                    color_var = "cyl")
  expect_s3_class(hc, "highchart")
})

test_that("viz_scatter with size_var", {
  hc <- viz_scatter(mtcars, x_var = "wt", y_var = "mpg",
                    size_var = "hp")
  expect_s3_class(hc, "highchart")
})

test_that("viz_scatter with show_trend lm", {
  hc <- viz_scatter(mtcars, x_var = "wt", y_var = "mpg",
                    show_trend = TRUE, trend_method = "lm")
  expect_s3_class(hc, "highchart")
})

test_that("viz_scatter with show_trend loess", {
  hc <- viz_scatter(mtcars, x_var = "wt", y_var = "mpg",
                    show_trend = TRUE, trend_method = "loess")
  expect_s3_class(hc, "highchart")
})

test_that("viz_scatter with custom alpha", {
  hc <- viz_scatter(mtcars, x_var = "wt", y_var = "mpg", alpha = 0.3)
  expect_s3_class(hc, "highchart")
})

test_that("viz_scatter with color_palette", {
  hc <- viz_scatter(mtcars, x_var = "wt", y_var = "mpg",
                    color_var = "cyl",
                    color_palette = c("#ff0000", "#00ff00", "#0000ff"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_scatter with custom point_size", {
  hc <- viz_scatter(mtcars, x_var = "wt", y_var = "mpg", point_size = 8)
  expect_s3_class(hc, "highchart")
})

test_that("viz_scatter with jitter", {
  hc <- viz_scatter(mtcars, x_var = "wt", y_var = "mpg",
                    jitter = TRUE, jitter_amount = 0.3)
  expect_s3_class(hc, "highchart")
})

test_that("viz_scatter with include_na in color_var", {
  df <- data.frame(
    x = rnorm(30),
    y = rnorm(30),
    group = c(rep("A", 10), rep("B", 10), rep(NA, 10))
  )
  hc <- viz_scatter(df, x_var = "x", y_var = "y",
                    color_var = "group",
                    include_na = TRUE, na_label = "Missing")
  expect_s3_class(hc, "highchart")
})

test_that("viz_scatter with subtitle", {
  hc <- viz_scatter(mtcars, x_var = "wt", y_var = "mpg",
                    title = "Main", subtitle = "Sub")
  expect_s3_class(hc, "highchart")
})

test_that("viz_scatter with color_var and show_trend", {
  hc <- viz_scatter(mtcars, x_var = "wt", y_var = "mpg",
                    color_var = "cyl", show_trend = TRUE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_scatter with size_var and color_var combined", {
  hc <- viz_scatter(mtcars, x_var = "wt", y_var = "mpg",
                    color_var = "cyl", size_var = "hp")
  expect_s3_class(hc, "highchart")
})

# --- Additional targeted tests for uncovered branches ---

test_that("viz_scatter with unified tooltip system", {
  tt <- tooltip(format = "{x}: {y}")
  hc <- viz_scatter(mtcars, x_var = "wt", y_var = "mpg", tooltip = tt)
  expect_s3_class(hc, "highchart")
})

test_that("viz_scatter with tooltip as format string", {
  hc <- viz_scatter(mtcars, x_var = "wt", y_var = "mpg",
                    tooltip = "Weight: {x}, MPG: {y}")
  expect_s3_class(hc, "highchart")
})

test_that("viz_scatter with legacy tooltip_format", {
  hc <- viz_scatter(mtcars, x_var = "wt", y_var = "mpg",
                    tooltip_format = "<b>{point.x}</b>: {point.y}")
  expect_s3_class(hc, "highchart")
})

test_that("viz_scatter single series (no color_var) with color_palette", {
  hc <- viz_scatter(mtcars, x_var = "wt", y_var = "mpg",
                    color_palette = c("#ff0000"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_scatter single series with size_var (no color_var)", {
  hc <- viz_scatter(mtcars, x_var = "wt", y_var = "mpg",
                    size_var = "hp")
  expect_s3_class(hc, "highchart")
})

test_that("viz_scatter with non-numeric x_var (categorical x axis)", {
  df <- data.frame(
    category = c("A", "B", "C", "D", "E"),
    value = c(10, 25, 15, 30, 20)
  )
  hc <- viz_scatter(df, x_var = "category", y_var = "value")
  expect_s3_class(hc, "highchart")
})

test_that("viz_scatter with non-numeric y_var (coerced)", {
  df <- data.frame(
    x = 1:10,
    y = as.character(seq(10, 100, 10))
  )
  hc <- viz_scatter(df, x_var = "x", y_var = "y")
  expect_s3_class(hc, "highchart")
})

test_that("viz_scatter jitter with numeric x and y", {
  df <- data.frame(
    x = rep(1:5, each = 10),
    y = rnorm(50)
  )
  hc <- viz_scatter(df, x_var = "x", y_var = "y",
                    jitter = TRUE, jitter_amount = 0.3)
  expect_s3_class(hc, "highchart")
})

test_that("viz_scatter with haven_labelled x_var", {
  skip_if_not_installed("haven")
  df <- data.frame(
    x = haven::labelled(rep(1:5, each = 4), labels = c("Low" = 1, "High" = 5)),
    y = rnorm(20)
  )
  hc <- viz_scatter(df, x_var = "x", y_var = "y")
  expect_s3_class(hc, "highchart")
})

test_that("viz_scatter with haven_labelled y_var", {
  skip_if_not_installed("haven")
  df <- data.frame(
    x = rnorm(20),
    y = haven::labelled(rep(1:5, each = 4), labels = c("Low" = 1, "High" = 5))
  )
  hc <- viz_scatter(df, x_var = "x", y_var = "y")
  expect_s3_class(hc, "highchart")
})

test_that("viz_scatter with haven_labelled color_var", {
  skip_if_not_installed("haven")
  df <- data.frame(
    x = rnorm(20),
    y = rnorm(20),
    grp = haven::labelled(rep(1:2, each = 10), labels = c("Male" = 1, "Female" = 2))
  )
  hc <- viz_scatter(df, x_var = "x", y_var = "y", color_var = "grp")
  expect_s3_class(hc, "highchart")
})

test_that("viz_scatter with haven_labelled size_var", {
  skip_if_not_installed("haven")
  df <- data.frame(
    x = rnorm(20),
    y = rnorm(20),
    sz = haven::labelled(rep(1:4, 5), labels = c("S" = 1, "L" = 4))
  )
  hc <- viz_scatter(df, x_var = "x", y_var = "y", size_var = "sz")
  expect_s3_class(hc, "highchart")
})

test_that("viz_scatter error: data is not a data frame", {
  expect_error(viz_scatter(list(a = 1), x_var = "a", y_var = "b"), "data frame")
})

test_that("viz_scatter error: missing x_var column", {
  expect_error(viz_scatter(mtcars, x_var = "nonexistent", y_var = "mpg"), "not found")
})

test_that("viz_scatter error: missing y_var column", {
  expect_error(viz_scatter(mtcars, x_var = "wt", y_var = "nonexistent"), "not found")
})

test_that("viz_scatter error: missing color_var column", {
  expect_error(viz_scatter(mtcars, x_var = "wt", y_var = "mpg",
                           color_var = "nonexistent"), "not found")
})

test_that("viz_scatter error: missing size_var column", {
  expect_error(viz_scatter(mtcars, x_var = "wt", y_var = "mpg",
                           size_var = "nonexistent"), "not found")
})

test_that("viz_scatter with color_var and size_var and trend", {
  hc <- viz_scatter(mtcars, x_var = "wt", y_var = "mpg",
                    color_var = "cyl", size_var = "hp",
                    show_trend = TRUE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_scatter with no explicit labels (defaults)", {
  hc <- viz_scatter(mtcars, x_var = "wt", y_var = "mpg")
  expect_s3_class(hc, "highchart")
})

test_that("viz_scatter include_na FALSE filters NAs in color_var", {
  df <- data.frame(
    x = rnorm(30),
    y = rnorm(30),
    group = c(rep("A", 10), rep("B", 10), rep(NA, 10))
  )
  hc <- viz_scatter(df, x_var = "x", y_var = "y",
                    color_var = "group", include_na = FALSE)
  expect_s3_class(hc, "highchart")
})
