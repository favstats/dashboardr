# Tests for viz_dumbbell — lightweight, covr-safe (no skip_on_covr_ci)
library(testthat)

test_that("viz_dumbbell basic chart", {
  df <- data.frame(
    country = c("US", "UK", "DE", "FR"),
    score_2020 = c(65, 58, 72, 60),
    score_2024 = c(78, 65, 75, 70)
  )
  hc <- viz_dumbbell(df, x_var = "country",
                     low_var = "score_2020", high_var = "score_2024")
  expect_s3_class(hc, "highchart")
  expect_true(length(hc$x$hc_opts$series) >= 1)
})

test_that("viz_dumbbell with custom labels", {
  df <- data.frame(
    country = c("US", "UK", "DE"),
    low = c(60, 55, 70),
    high = c(80, 65, 75)
  )
  hc <- viz_dumbbell(df, x_var = "country",
                     low_var = "low", high_var = "high",
                     low_label = "2020", high_label = "2024")
  expect_s3_class(hc, "highchart")
})

test_that("viz_dumbbell horizontal orientation", {
  df <- data.frame(
    item = c("A", "B", "C"),
    start = c(10, 20, 30),
    end = c(40, 50, 60)
  )
  hc <- viz_dumbbell(df, x_var = "item",
                     low_var = "start", high_var = "end",
                     horizontal = TRUE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_dumbbell vertical orientation", {
  df <- data.frame(
    item = c("A", "B", "C"),
    start = c(10, 20, 30),
    end = c(40, 50, 60)
  )
  hc <- viz_dumbbell(df, x_var = "item",
                     low_var = "start", high_var = "end",
                     horizontal = FALSE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_dumbbell sort_by_gap", {
  df <- data.frame(
    country = c("US", "UK", "DE", "FR"),
    score_2020 = c(65, 58, 72, 60),
    score_2024 = c(78, 65, 75, 70)
  )
  hc <- viz_dumbbell(df, x_var = "country",
                     low_var = "score_2020", high_var = "score_2024",
                     sort_by_gap = TRUE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_dumbbell sort_by_gap descending", {
  df <- data.frame(
    country = c("US", "UK", "DE"),
    low = c(60, 55, 70),
    high = c(80, 65, 75)
  )
  hc <- viz_dumbbell(df, x_var = "country",
                     low_var = "low", high_var = "high",
                     sort_by_gap = TRUE, sort_desc = FALSE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_dumbbell with color_palette", {
  df <- data.frame(
    country = c("US", "UK"),
    low = c(60, 55),
    high = c(80, 65)
  )
  hc <- viz_dumbbell(df, x_var = "country",
                     low_var = "low", high_var = "high",
                     color_palette = c(low = "red", high = "blue"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_dumbbell with x_order", {
  df <- data.frame(
    country = c("US", "UK", "DE"),
    low = c(60, 55, 70),
    high = c(80, 65, 75)
  )
  hc <- viz_dumbbell(df, x_var = "country",
                     low_var = "low", high_var = "high",
                     x_order = c("DE", "UK", "US"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_dumbbell with title and labels", {
  df <- data.frame(
    country = c("US", "UK"),
    low = c(60, 55),
    high = c(80, 65)
  )
  hc <- viz_dumbbell(df, x_var = "country",
                     low_var = "low", high_var = "high",
                     title = "Score Changes",
                     x_label = "Country",
                     y_label = "Score")
  expect_s3_class(hc, "highchart")
})

test_that("viz_dumbbell with data_labels_enabled", {
  df <- data.frame(
    country = c("US", "UK"),
    low = c(60, 55),
    high = c(80, 65)
  )
  hc <- viz_dumbbell(df, x_var = "country",
                     low_var = "low", high_var = "high",
                     data_labels_enabled = TRUE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_dumbbell errors on missing columns", {
  df <- data.frame(a = 1:3, b = 4:6)
  expect_error(
    viz_dumbbell(df, x_var = "a", low_var = "nope", high_var = "b"),
    "not found"
  )
})

test_that("viz_dumbbell errors on non-numeric columns", {
  df <- data.frame(a = c("x", "y"), b = c("a", "b"), c = c("c", "d"))
  expect_error(
    viz_dumbbell(df, x_var = "a", low_var = "b", high_var = "c"),
    "numeric"
  )
})
