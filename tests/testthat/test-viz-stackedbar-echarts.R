library(testthat)

extract_echarts_numeric <- function(x) {
  if (is.null(x)) return(NA_real_)
  if (is.list(x) && !is.null(x$value)) {
    # $value can be c("category", "numeric_value") — take the last element
    v <- x$value
    return(suppressWarnings(as.numeric(v[length(v)])))
  }
  val <- unlist(x)
  suppressWarnings(as.numeric(val[length(val)]))
}

test_that("echarts stackedbar percent mode normalizes each stack to ~100", {
  skip_if_not_installed("echarts4r")

  df <- data.frame(
    category = c("A", "A", "A", "B", "B"),
    group = c("G1", "G2", "G3", "G1", "G2"),
    stringsAsFactors = FALSE
  )

  e <- viz_stackedbar(
    data = df,
    x_var = "category",
    stack_var = "group",
    backend = "echarts4r",
    stacked_type = "percent"
  )

  series <- e$x$opts$series
  expect_true(length(series) >= 2)

  values_by_series <- lapply(series, function(s) {
    vapply(s$data, extract_echarts_numeric, numeric(1))
  })
  mat <- do.call(cbind, values_by_series)
  expect_equal(nrow(mat), 2)

  row_totals <- rowSums(mat, na.rm = TRUE)
  # Display values are rounded to 1 decimal before reaching echarts,

  # so 3 x round(33.333, 1) = 3 x 33.3 = 99.9 — tolerate rounding gap
  expect_equal(row_totals, c(100, 100), tolerance = 0.5)
})

test_that("echarts stackedbar applies data_labels_enabled to series labels", {
  skip_if_not_installed("echarts4r")

  df <- data.frame(
    category = c("A", "A", "B", "B"),
    group = c("G1", "G2", "G1", "G2"),
    stringsAsFactors = FALSE
  )

  e_on <- viz_stackedbar(
    data = df,
    x_var = "category",
    stack_var = "group",
    backend = "echarts4r",
    data_labels_enabled = TRUE
  )
  e_off <- viz_stackedbar(
    data = df,
    x_var = "category",
    stack_var = "group",
    backend = "echarts4r",
    data_labels_enabled = FALSE
  )

  expect_true(isTRUE(e_on$x$opts$series[[1]]$label$show))
  expect_true(identical(e_off$x$opts$series[[1]]$label$show, FALSE))
})
