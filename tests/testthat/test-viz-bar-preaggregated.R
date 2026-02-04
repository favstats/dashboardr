# Tests for viz_bar with pre-aggregated data using y_var parameter
# Issue: Users with pre-aggregated data (Column 1: Group, Column 2: Count/Proportion)
# could not use viz_bar() directly. Fixed by adding y_var parameter.

library(testthat)

# =============================================================================
# Basic pre-aggregated data tests
# =============================================================================

test_that("viz_bar with y_var uses pre-aggregated values directly", {
  # Pre-aggregated data
  agg_data <- data.frame(
    category = c("A", "B", "C"),
    count = c(100, 200, 150)
  )
  
  result <- viz_bar(
    data = agg_data,
    x_var = "category",
    y_var = "count"
  )
  
  expect_s3_class(result, "highchart")
  
  # Check that the values match our pre-aggregated data
  series_data <- result$x$hc_opts$series[[1]]$data
  expect_equal(as.numeric(series_data), c(100, 200, 150))
})

test_that("viz_bar with y_var works with named proportions", {
  agg_data <- data.frame(
    group = c("Treatment", "Control"),
    proportion = c(0.65, 0.35)
  )
  
  result <- viz_bar(
    data = agg_data,
    x_var = "group",
    y_var = "proportion"
  )
  
  expect_s3_class(result, "highchart")
  expect_equal(length(result$x$hc_opts$series[[1]]$data), 2)
})

# =============================================================================
# Pre-aggregated data with bar_type = "percent"
# =============================================================================

test_that("viz_bar with y_var and bar_type = 'percent' calculates percentages", {
  agg_data <- data.frame(
    category = c("A", "B", "C"),
    count = c(100, 200, 200)  # Total = 500
  )
  
  result <- viz_bar(
    data = agg_data,
    x_var = "category",
    y_var = "count",
    bar_type = "percent"
  )
  
  expect_s3_class(result, "highchart")
  
  # Values should be percentages: 20%, 40%, 40%
  series_data <- result$x$hc_opts$series[[1]]$data
  expect_equal(as.numeric(series_data), c(20, 40, 40))
})

# =============================================================================
# Pre-aggregated data with group_var
# =============================================================================

test_that("viz_bar with y_var and group_var uses pre-aggregated grouped data", {
  agg_data <- data.frame(
    category = c("A", "A", "B", "B"),
    group = c("G1", "G2", "G1", "G2"),
    count = c(50, 75, 100, 25)
  )
  
  result <- viz_bar(
    data = agg_data,
    x_var = "category",
    group_var = "group",
    y_var = "count"
  )
  
  expect_s3_class(result, "highchart")
  
  # Should have 2 series (one per group)
  expect_equal(length(result$x$hc_opts$series), 2)
})

test_that("viz_bar with y_var, group_var and bar_type = 'percent' calculates percentages", {
  agg_data <- data.frame(
    category = c("A", "A", "B", "B"),
    group = c("G1", "G2", "G1", "G2"),
    count = c(50, 50, 75, 25)  # A: 50/50 split, B: 75/25 split
  )
  
  result <- viz_bar(
    data = agg_data,
    x_var = "category",
    group_var = "group",
    y_var = "count",
    bar_type = "percent"
  )
  
  expect_s3_class(result, "highchart")
})

# =============================================================================
# Pre-aggregated data with custom ordering
# =============================================================================

test_that("viz_bar with y_var respects x_order", {
  agg_data <- data.frame(
    category = c("Z", "A", "M"),
    count = c(10, 30, 20)
  )
  
  result <- viz_bar(
    data = agg_data,
    x_var = "category",
    y_var = "count",
    x_order = c("A", "M", "Z")
  )
  
  expect_s3_class(result, "highchart")
  expect_equal(result$x$hc_opts$xAxis$categories, c("A", "M", "Z"))
})

# =============================================================================
# Pre-aggregated data with horizontal bars
# =============================================================================

test_that("viz_bar with y_var works with horizontal = TRUE", {
  agg_data <- data.frame(
    category = c("Long Category Name A", "Long Category Name B"),
    count = c(150, 250)
  )
  
  result <- viz_bar(
    data = agg_data,
    x_var = "category",
    y_var = "count",
    horizontal = TRUE
  )
  
  expect_s3_class(result, "highchart")
  expect_equal(result$x$hc_opts$chart$type, "bar")
})

# =============================================================================
# Error handling for y_var
# =============================================================================

test_that("viz_bar errors when y_var column does not exist", {
  agg_data <- data.frame(
    category = c("A", "B"),
    count = c(100, 200)
  )
  
  expect_error(
    viz_bar(
      data = agg_data,
      x_var = "category",
      y_var = "nonexistent"
    ),
    "not found in data"
  )
})

test_that("viz_bar errors when y_var is not numeric", {
  agg_data <- data.frame(
    category = c("A", "B"),
    count = c("high", "low")  # Character, not numeric
  )
  
  expect_error(
    viz_bar(
      data = agg_data,
      x_var = "category",
      y_var = "count"
    ),
    "must be a numeric column"
  )
})

# =============================================================================
# Integration test with add_viz
# =============================================================================

test_that("y_var works through add_viz pipeline", {
  viz <- create_viz(
    type = "bar",
    x_var = "category",
    y_var = "count"
  ) %>%
    add_viz(title = "Pre-aggregated Chart")
  
  expect_equal(viz$items[[1]]$y_var, "count")
  expect_equal(viz$items[[1]]$viz_type, "bar")
})

# =============================================================================
# Real-world use case: Survey results already summarized
# =============================================================================

test_that("viz_bar handles real-world pre-aggregated survey data", {
  # Simulating data that might come from an aggregated table
  survey_summary <- data.frame(
    response = c("Strongly Disagree", "Disagree", "Neutral", "Agree", "Strongly Agree"),
    n = c(15, 25, 30, 45, 35)
  )
  
  result <- viz_bar(
    data = survey_summary,
    x_var = "response",
    y_var = "n",
    x_order = c("Strongly Disagree", "Disagree", "Neutral", "Agree", "Strongly Agree"),
    title = "Survey Responses",
    bar_type = "percent"
  )
  
  expect_s3_class(result, "highchart")
  
  # Total = 150, so percentages should sum to 100
  series_data <- result$x$hc_opts$series[[1]]$data
  expect_equal(sum(as.numeric(series_data)), 100)
})

# =============================================================================
# Sort by value with pre-aggregated data
# =============================================================================

test_that("viz_bar with y_var supports sort_by_value", {
  agg_data <- data.frame(
    category = c("Low", "High", "Medium"),
    count = c(50, 200, 100)
  )
  
  result <- viz_bar(
    data = agg_data,
    x_var = "category",
    y_var = "count",
    sort_by_value = TRUE,
    sort_desc = TRUE
  )
  
  expect_s3_class(result, "highchart")
  # Categories should be sorted by value: High, Medium, Low
  expect_equal(result$x$hc_opts$xAxis$categories, c("High", "Medium", "Low"))
})
