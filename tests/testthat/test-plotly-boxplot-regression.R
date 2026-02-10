# Regression tests for plotly boxplot/filter behavior seen in Playwright failures.
library(testthat)

`%||%` <- function(x, y) if (is.null(x)) y else x

test_that("viz_boxplot(plotly) keeps non-empty raw-value traces per category", {
  skip_if_not_installed("plotly")

  set.seed(123)
  categories <- c("High School", "Some College", "Bachelor's", "Graduate")
  df <- data.frame(
    education = rep(categories, each = 35),
    income = c(
      rnorm(35, 50000, 7000),
      rnorm(35, 58000, 8000),
      rnorm(35, 68000, 9000),
      rnorm(35, 76000, 10000)
    ),
    stringsAsFactors = FALSE
  )

  p <- viz_boxplot(
    data = df,
    x_var = "education",
    y_var = "income",
    backend = "plotly"
  )

  expect_s3_class(p, "plotly")
  traces <- p$x$attrs %||% list()
  box_traces <- Filter(function(tr) {
    is.list(tr) && identical(as.character(tr$type %||% ""), "box")
  }, traces)

  expect_equal(length(box_traces), length(categories))
  trace_names <- vapply(box_traces, function(tr) as.character(tr$name %||% ""), character(1))
  expect_setequal(trace_names, categories)

  for (tr in box_traces) {
    x_vals <- unlist(tr$x %||% list(), use.names = FALSE)
    y_vals <- suppressWarnings(as.numeric(unlist(tr$y %||% list(), use.names = FALSE)))
    y_vals <- y_vals[is.finite(y_vals)]

    expect_true(length(x_vals) >= 5)
    expect_true(length(y_vals) >= 5)
    expect_equal(length(unique(as.character(x_vals))), 1)
  }
})

test_that("plotly filter asset derives visible categories from all traces", {
  asset_path <- system.file("assets", "input_filter.js", package = "dashboardr")
  if (!nzchar(asset_path)) {
    asset_path <- testthat::test_path("..", "..", "inst", "assets", "input_filter.js")
  }
  expect_true(file.exists(asset_path))

  js <- paste(readLines(asset_path, warn = FALSE), collapse = "\n")

  expect_match(js, "const allCategoryValues = \\[];", perl = TRUE)
  expect_match(js, "allCategoryValues\\.push\\(v\\)", perl = TRUE)
})
