# Tests for viz_pie — lightweight, covr-safe (no skip_on_covr_ci)
library(testthat)

test_that("viz_pie basic pie chart from raw data", {
  hc <- viz_pie(mtcars, x_var = "cyl", title = "Cylinders")
  expect_s3_class(hc, "highchart")
  # Should have one series with data

  expect_true(length(hc$x$hc_opts$series) >= 1)
})

test_that("viz_pie with pre-aggregated data", {
  df <- data.frame(
    category = c("A", "B", "C"),
    count = c(40, 35, 25)
  )
  hc <- viz_pie(df, x_var = "category", y_var = "count")
  expect_s3_class(hc, "highchart")
})

test_that("viz_pie donut chart with inner_size", {
  hc <- viz_pie(mtcars, x_var = "cyl", inner_size = "50%", title = "Donut")
  expect_s3_class(hc, "highchart")
})

test_that("viz_pie respects x_order parameter", {
  hc <- viz_pie(mtcars, x_var = "cyl", x_order = c("8", "6", "4"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_pie sorts by value", {
  hc <- viz_pie(mtcars, x_var = "cyl", sort_by_value = TRUE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_pie applies color palette", {
  hc <- viz_pie(mtcars, x_var = "cyl",
                color_palette = c("#ff0000", "#00ff00", "#0000ff"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_pie errors on missing x_var column", {
  expect_error(viz_pie(mtcars, x_var = "nonexistent"), "not found")
})

test_that("viz_pie errors when y_var is not numeric", {
  df <- data.frame(a = c("x", "y"), b = c("a", "b"))
  expect_error(viz_pie(df, x_var = "a", y_var = "b"), "numeric")
})

test_that("viz_pie with subtitle", {
  hc <- viz_pie(mtcars, x_var = "cyl", title = "Main", subtitle = "Sub")
  expect_s3_class(hc, "highchart")
})

test_that("viz_pie with weight_var", {
  df <- data.frame(
    category = c("A", "A", "B", "B", "C"),
    weight = c(1.5, 2.0, 1.0, 3.0, 2.5)
  )
  hc <- viz_pie(df, x_var = "category", weight_var = "weight")
  expect_s3_class(hc, "highchart")
})

test_that("viz_pie with include_na", {
  df <- data.frame(
    category = c("A", "B", NA, "A", NA)
  )
  hc <- viz_pie(df, x_var = "category", include_na = TRUE, na_label = "Missing")
  expect_s3_class(hc, "highchart")
})

test_that("viz_pie with data_labels_format", {
  hc <- viz_pie(mtcars, x_var = "cyl",
                data_labels_format = "{point.name}: {point.percentage:.0f}%")
  expect_s3_class(hc, "highchart")
})

test_that("viz_pie with show_in_legend FALSE", {
  hc <- viz_pie(mtcars, x_var = "cyl", show_in_legend = FALSE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_pie with center_text for donut", {
  hc <- viz_pie(mtcars, x_var = "cyl", inner_size = "50%",
                center_text = "Total: 32")
  expect_s3_class(hc, "highchart")
})
