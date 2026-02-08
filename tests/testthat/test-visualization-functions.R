# Tests for individual visualization creation functions
library(testthat)

# Skip entire file under covr CI to prevent OOM (exit code 143)
if (identical(Sys.getenv("DASHBOARDR_COVR_CI"), "true") || !identical(Sys.getenv("NOT_CRAN"), "true")) {
  test_that("skipped on CRAN/covr CI", { skip("Memory-intensive tests skipped on CRAN and covr CI") })
} else {

# ===================================================================
# viz_histogram
# ===================================================================

test_that("viz_histogram works with basic inputs", {
  data <- data.frame(value = rnorm(100))
  
  result <- viz_histogram(data = data, x_var = "value")
  expect_s3_class(result, "highchart")
})

test_that("viz_histogram with bins parameter", {
  data <- data.frame(value = rnorm(100))
  
  result <- viz_histogram(data = data, x_var = "value", bins = 20)
  expect_s3_class(result, "highchart")
})

test_that("viz_histogram with title", {
  data <- data.frame(value = rnorm(100))
  
  result <- viz_histogram(data = data, x_var = "value", title = "Distribution")
  expect_s3_class(result, "highchart")
})

# ===================================================================
# viz_timeline
# ===================================================================

test_that("viz_timeline works with basic inputs", {
  data <- data.frame(
    year = rep(2020:2023, each = 10),
    value = rnorm(40)
  )
  
  result <- viz_timeline(data = data, time_var = "year", y_var = "value")
  expect_s3_class(result, "highchart")
})

test_that("viz_timeline with group_var", {
  data <- data.frame(
    year = rep(2020:2023, each = 20),
    value = rnorm(80),
    category = rep(c("A", "B"), 40)
  )
  
  result <- viz_timeline(
    data = data,
    time_var = "year",
    y_var = "value",
    group_var = "category"
  )
  expect_s3_class(result, "highchart")
})

test_that("viz_timeline with response_filter", {
  data <- data.frame(
    year = rep(2020:2023, each = 10),
    score = sample(1:7, 40, replace = TRUE)
  )
  
  result <- viz_timeline(
    data = data,
    time_var = "year",
    y_var = "score",
    y_filter = 5:7,
    y_filter_combine = TRUE
  )
  expect_s3_class(result, "highchart")
})

# ===================================================================
# viz_stackedbar
# ===================================================================

test_that("viz_stackedbar works with basic inputs", {
  data <- data.frame(
    question = c("Q1", "Q1", "Q2", "Q2"),
    response = c(1, 2, 1, 2)
  )
  
  result <- viz_stackedbar(
    data = data,
    x_var = "question",
    stack_var = "response"
  )
  expect_s3_class(result, "highchart")
})

test_that("viz_stackedbar with horizontal orientation", {
  data <- data.frame(
    question = rep(c("Q1", "Q2"), each = 5),
    response = sample(1:5, 10, replace = TRUE)
  )
  
  result <- viz_stackedbar(
    data = data,
    x_var = "question",
    stack_var = "response",
    horizontal = TRUE
  )
  expect_s3_class(result, "highchart")
})

test_that("viz_stackedbar with percent type", {
  data <- data.frame(
    question = rep(c("Q1", "Q2"), each = 10),
    response = sample(1:5, 20, replace = TRUE)
  )
  
  result <- viz_stackedbar(
    data = data,
    x_var = "question",
    stack_var = "response",
    stacked_type = "percent"
  )
  expect_s3_class(result, "highchart")
})

# ===================================================================
# viz_stackedbar with x_vars (unified multi-variable mode)
# ===================================================================

test_that("viz_stackedbar works with x_vars (multi-variable mode)", {
  data <- data.frame(
    q1 = sample(1:5, 100, replace = TRUE),
    q2 = sample(1:5, 100, replace = TRUE),
    q3 = sample(1:5, 100, replace = TRUE)
  )
  
  # Using the unified function with x_vars
  result <- viz_stackedbar(
    data = data,
    x_vars = c("q1", "q2", "q3"),
    x_var_labels = c("Question 1", "Question 2", "Question 3"),
    stacked_type = "counts"
  )
  expect_s3_class(result, "highchart")
})

test_that("viz_stackedbar x_vars mode with percent type", {
  data <- data.frame(
    q1 = sample(1:5, 100, replace = TRUE),
    q2 = sample(1:5, 100, replace = TRUE)
  )
  
  result <- viz_stackedbar(
    data = data,
    x_vars = c("q1", "q2"),
    x_var_labels = c("Q1", "Q2"),
    stacked_type = "percent"
  )
  expect_s3_class(result, "highchart")
})

test_that("viz_stackedbar gives helpful error for missing params", {
  data <- data.frame(x = 1:10)
  
  expect_error(
    viz_stackedbar(data = data, x_var = "x"),
    "stack_var"
  )
  
  expect_error(
    viz_stackedbar(data = data),
    "x_var.*x_vars"
  )
})

test_that("viz_stackedbar gives error for conflicting params", {
  data <- data.frame(
    q1 = 1:10,
    response = c("A", "B")
  )
  
  expect_error(
    viz_stackedbar(data = data, x_var = "q1", x_vars = c("q1")),
    "Cannot use both"
  )
})

# ===================================================================
# viz_stackedbars (legacy wrapper)
# ===================================================================

test_that("viz_stackedbars works with multiple questions", {
  data <- data.frame(
    q1 = sample(1:5, 100, replace = TRUE),
    q2 = sample(1:5, 100, replace = TRUE),
    q3 = sample(1:5, 100, replace = TRUE)
  )
  
  result <- viz_stackedbars(
    data = data,
    x_vars = c("q1", "q2", "q3"),
    x_var_labels = c("Question 1", "Question 2", "Question 3"),
    stacked_type = "counts"
  )
  expect_s3_class(result, "highchart")
})

test_that("viz_stackedbars with percent type", {
  data <- data.frame(
    q1 = sample(1:5, 100, replace = TRUE),
    q2 = sample(1:5, 100, replace = TRUE)
  )
  
  result <- viz_stackedbars(
    data = data,
    x_vars = c("q1", "q2"),
    x_var_labels = c("Q1", "Q2"),
    stacked_type = "percent"
  )
  expect_s3_class(result, "highchart")
})

# ===================================================================
# viz_heatmap
# ===================================================================

test_that("viz_heatmap works with basic inputs", {
  data <- expand.grid(
    x = c("A", "B", "C"),
    y = c("X", "Y", "Z")
  )
  data$value <- rnorm(9)
  
  result <- viz_heatmap(
    data = data,
    x_var = "x",
    y_var = "y",
    value_var = "value"
  )
  expect_s3_class(result, "highchart")
})

test_that("viz_heatmap with title and labels", {
  data <- expand.grid(
    category = c("Cat1", "Cat2"),
    group = c("G1", "G2", "G3")
  )
  data$score <- runif(6, 0, 100)
  
  result <- viz_heatmap(
    data = data,
    x_var = "category",
    y_var = "group",
    value_var = "score",
    title = "Heatmap",
    x_label = "Categories",
    y_label = "Groups"
  )
  expect_s3_class(result, "highchart")
})

# ===================================================================
# Multi-backend support tests
# ===================================================================

# --- viz_bar backends ---
test_that("viz_bar works with plotly backend", {
  skip_if_not_installed("plotly")
  data <- data.frame(
    category = c("A", "B", "C", "A", "B", "C"),
    value = c(10, 20, 30, 15, 25, 35)
  )
  result <- viz_bar(data = data, x_var = "category", backend = "plotly")
  expect_s3_class(result, "plotly")
})

test_that("viz_bar works with echarts4r backend", {
  skip_if_not_installed("echarts4r")
  data <- data.frame(
    category = c("A", "B", "C", "A", "B", "C"),
    value = c(10, 20, 30, 15, 25, 35)
  )
  result <- viz_bar(data = data, x_var = "category", backend = "echarts4r")
  expect_s3_class(result, "echarts4r")
})

test_that("viz_bar works with ggiraph backend", {
  skip_if_not_installed("ggiraph")
  skip_if_not_installed("ggplot2")
  data <- data.frame(
    category = c("A", "B", "C", "A", "B", "C"),
    value = c(10, 20, 30, 15, 25, 35)
  )
  result <- viz_bar(data = data, x_var = "category", backend = "ggiraph")
  expect_s3_class(result, "girafe")
})

test_that("viz_bar default backend unchanged (highcharter)", {
  data <- data.frame(
    category = c("A", "B", "C", "A", "B", "C"),
    value = c(10, 20, 30, 15, 25, 35)
  )
  result <- viz_bar(data = data, x_var = "category")
  expect_s3_class(result, "highchart")
})

# --- viz_histogram backends ---
test_that("viz_histogram works with plotly backend", {
  skip_if_not_installed("plotly")
  data <- data.frame(value = sample(c("A", "B", "C"), 100, replace = TRUE))
  result <- viz_histogram(data = data, x_var = "value", backend = "plotly")
  expect_s3_class(result, "plotly")
})

test_that("viz_histogram works with echarts4r backend", {
  skip_if_not_installed("echarts4r")
  data <- data.frame(value = sample(c("A", "B", "C"), 100, replace = TRUE))
  result <- viz_histogram(data = data, x_var = "value", backend = "echarts4r")
  expect_s3_class(result, "echarts4r")
})

test_that("viz_histogram works with ggiraph backend", {
  skip_if_not_installed("ggiraph")
  skip_if_not_installed("ggplot2")
  data <- data.frame(value = sample(c("A", "B", "C"), 100, replace = TRUE))
  result <- viz_histogram(data = data, x_var = "value", backend = "ggiraph")
  expect_s3_class(result, "girafe")
})

# --- viz_timeline backends ---
test_that("viz_timeline works with plotly backend", {
  skip_if_not_installed("plotly")
  data <- data.frame(
    year = rep(2020:2023, each = 10),
    value = rnorm(40)
  )
  result <- viz_timeline(data = data, time_var = "year", y_var = "value", backend = "plotly")
  expect_s3_class(result, "plotly")
})

test_that("viz_timeline works with echarts4r backend", {
  skip_if_not_installed("echarts4r")
  data <- data.frame(
    year = rep(2020:2023, each = 10),
    value = rnorm(40)
  )
  result <- viz_timeline(data = data, time_var = "year", y_var = "value", backend = "echarts4r")
  expect_s3_class(result, "echarts4r")
})

# --- viz_heatmap backends ---
test_that("viz_heatmap works with plotly backend", {
  skip_if_not_installed("plotly")
  data <- expand.grid(x = c("A", "B", "C"), y = c("X", "Y", "Z"))
  data$value <- rnorm(9)
  result <- viz_heatmap(data = data, x_var = "x", y_var = "y", value_var = "value", backend = "plotly")
  expect_s3_class(result, "plotly")
})

# --- backend parameter validation ---
test_that("viz_bar rejects invalid backend", {
  data <- data.frame(category = c("A", "B"), value = c(10, 20))
  expect_error(
    viz_bar(data = data, x_var = "category", backend = "invalid_backend"),
    "arg"
  )
})

test_that("viz_histogram rejects invalid backend", {
  data <- data.frame(value = c("A", "B", "C"))
  expect_error(
    viz_histogram(data = data, x_var = "value", backend = "nonexistent"),
    "arg"
  )
})

# --- create_dashboard backend parameter ---
test_that("create_dashboard accepts backend parameter", {
  temp_dir <- tempfile("backend_test")
  suppressMessages({
    proj <- create_dashboard(
      title = "Test",
      output_dir = temp_dir,
      backend = "plotly"
    )
  })
  expect_equal(proj$backend, "plotly")
  unlink(temp_dir, recursive = TRUE)
})

test_that("create_dashboard defaults to highcharter backend", {
  temp_dir <- tempfile("backend_default_test")
  suppressMessages({
    proj <- create_dashboard(
      title = "Test",
      output_dir = temp_dir
    )
  })
  expect_equal(proj$backend, "highcharter")
  unlink(temp_dir, recursive = TRUE)
})

test_that("create_dashboard rejects invalid backend", {
  temp_dir <- tempfile("backend_invalid_test")
  expect_error(
    suppressMessages({
      create_dashboard(
        title = "Test",
        output_dir = temp_dir,
        backend = "d3js"
      )
    }),
    "arg"
  )
  unlink(temp_dir, recursive = TRUE)
})

} # end covr CI skip
