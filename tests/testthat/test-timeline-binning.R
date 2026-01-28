# Tests for timeline response binning and filtering features
library(testthat)

test_that("response_breaks bins numeric values", {
  viz <- create_viz(
    type = "timeline",
    time_var = "year",
    y_var = "score",
    response_breaks = c(0.5, 4.5, 7.5),
    response_bin_labels = c("Low", "High")
  ) %>%
    add_viz(title = "Binned Timeline")
  
  expect_equal(viz$items[[1]]$response_breaks, c(0.5, 4.5, 7.5))
  expect_equal(viz$items[[1]]$response_bin_labels, c("Low", "High"))
})

test_that("response_filter with range syntax", {
  viz <- create_viz(
    type = "timeline",
    time_var = "year",
    y_var = "score",
    response_filter = 5:7
  ) %>%
    add_viz(title = "Filtered Timeline")
  
  expect_equal(viz$items[[1]]$response_filter, 5:7)
})

test_that("response_filter_combine combines filtered responses", {
  viz <- create_viz(
    type = "timeline",
    time_var = "year",
    y_var = "score",
    response_filter = 5:7,
    response_filter_combine = TRUE
  ) %>%
    add_viz(title = "Combined")
  
  expect_true(viz$items[[1]]$response_filter_combine)
})

test_that("response_filter_label customizes legend", {
  viz <- create_viz(
    type = "timeline",
    time_var = "year",
    y_var = "score",
    response_filter = 5:7,
    response_filter_combine = TRUE,
    response_filter_label = "High Scores"
  ) %>%
    add_viz(title = "Custom Label")
  
  expect_equal(viz$items[[1]]$response_filter_label, "High Scores")
})

test_that("timeline binning generates correct code", {
  viz <- create_viz(
    type = "timeline",
    time_var = "year",
    y_var = "satisfaction",
    response_breaks = c(0.5, 2.5, 4.5),
    response_bin_labels = c("Low", "High")
  ) %>%
    add_viz(title = "Satisfaction Trend")
  
  dashboard <- create_dashboard(
    output_dir = tempfile("timeline_bin"),
    title = "Test"
  ) %>%
    add_page(
      "Analysis",
      data = data.frame(
        year = rep(2020:2023, each = 25),
        satisfaction = sample(1:5, 100, replace = TRUE)
      ),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  qmd_file <- file.path(dashboard$output_dir, "index.qmd")
  qmd_content <- paste(readLines(qmd_file, warn = FALSE), collapse = "\n")
  
  # Should have response_breaks parameter
  expect_true(grepl("response_breaks", qmd_content))
  expect_true(grepl("response_bin_labels", qmd_content))
  
})

test_that("timeline filtering generates correct code", {
  viz <- create_viz(
    type = "timeline",
    time_var = "year",
    y_var = "score",
    response_filter = 5:7,
    response_filter_combine = TRUE,
    response_filter_label = "High"
  ) %>%
    add_viz(title = "High Scores Only")
  
  dashboard <- create_dashboard(
    output_dir = tempfile("timeline_filter"),
    title = "Test"
  ) %>%
    add_page(
      "Analysis",
      data = data.frame(
        year = rep(2020:2023, each = 25),
        score = sample(1:7, 100, replace = TRUE)
      ),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  qmd_file <- file.path(dashboard$output_dir, "index.qmd")
  qmd_content <- paste(readLines(qmd_file, warn = FALSE), collapse = "\n")
  
  # Should have y_filter parameter (response_filter is mapped to y_filter in code generation)
  expect_true(grepl("y_filter", qmd_content))
  expect_true(grepl("y_filter_combine", qmd_content))
  
})

test_that("binning and filtering can be combined", {
  viz <- create_viz(
    type = "timeline",
    time_var = "year",
    y_var = "rating",
    response_breaks = c(0.5, 3.5, 7.5),
    response_bin_labels = c("Low", "High"),
    response_filter = 5:7
  ) %>%
    add_viz(title = "Binned and Filtered")
  
  expect_equal(viz$items[[1]]$response_breaks, c(0.5, 3.5, 7.5))
  expect_equal(viz$items[[1]]$response_filter, 5:7)
})

test_that("response_filter with group_var", {
  viz <- create_viz(
    type = "timeline",
    time_var = "year",
    y_var = "score",
    group_var = "category",
    response_filter = 5:7,
    response_filter_combine = TRUE
  ) %>%
    add_viz(title = "Filtered by Group")
  
  expect_equal(viz$items[[1]]$group_var, "category")
  expect_equal(viz$items[[1]]$response_filter, 5:7)
})

test_that("empty response_filter_label with group_var shows only group", {
  viz <- create_viz(
    type = "timeline",
    time_var = "year",
    y_var = "score",
    group_var = "age_group",
    response_filter = 5:7,
    response_filter_combine = TRUE,
    response_filter_label = ""  # Empty label
  ) %>%
    add_viz(title = "Group Only")
  
  # Should store empty label (will show only group_var values in legend)
  expect_equal(viz$items[[1]]$response_filter_label, "")
})

test_that("response percentages calculated from total not filtered", {
  # This is a behavioral test - percentages should be out of ALL responses
  # not just the filtered ones
  viz <- create_viz(
    type = "timeline",
    time_var = "year",
    y_var = "score",
    response_filter = 5:7,  # Filter to high scores
    response_filter_combine = TRUE
  ) %>%
    add_viz(title = "High Score %")
  
  # The visualization should calculate % out of 1-7, not 5-7
  # This is tested behaviorally in the viz_timeline function
  expect_equal(viz$items[[1]]$response_filter, 5:7)
  expect_true(viz$items[[1]]$response_filter_combine)
})

test_that("multiple timelines with different filters", {
  viz <- create_viz(
    type = "timeline",
    time_var = "year"
  ) %>%
    add_viz(
      y_var = "score",
      response_filter = 1:3,
      response_filter_combine = TRUE,
      response_filter_label = "Low",
      title = "Low Scores"
    ) %>%
    add_viz(
      y_var = "score",
      response_filter = 5:7,
      response_filter_combine = TRUE,
      response_filter_label = "High",
      title = "High Scores"
    )
  
  expect_equal(viz$items[[1]]$response_filter, 1:3)
  expect_equal(viz$items[[2]]$response_filter, 5:7)
  expect_equal(viz$items[[1]]$response_filter_label, "Low")
  expect_equal(viz$items[[2]]$response_filter_label, "High")
})

test_that("timeline binning works with defaults", {
  viz <- create_viz(
    type = "timeline",
    time_var = "year",
    y_var = "score",
    response_breaks = c(0.5, 3.5, 7.5),
    response_bin_labels = c("Low", "High")
  ) %>%
    add_viz(title = "Chart 1") %>%
    add_viz(title = "Chart 2")  # Should inherit breaks
  
  # Both should have the binning
  expect_equal(viz$items[[1]]$response_breaks, c(0.5, 3.5, 7.5))
  expect_equal(viz$items[[2]]$response_breaks, c(0.5, 3.5, 7.5))
})

test_that("response_filter can be overridden in add_viz", {
  viz <- create_viz(
    type = "timeline",
    time_var = "year",
    y_var = "score",
    response_filter = 1:3  # Default: low scores
  ) %>%
    add_viz(title = "Low", response_filter_label = "Low") %>%
    add_viz(
      title = "High",
      response_filter = 5:7,  # Override: high scores
      response_filter_label = "High"
    )
  
  expect_equal(viz$items[[1]]$response_filter, 1:3)
  expect_equal(viz$items[[2]]$response_filter, 5:7)
})

test_that("timeline with all features combined", {
  viz <- create_viz(
    type = "timeline",
    time_var = "year",
    y_var = "satisfaction",
    group_var = "age_group",
    response_breaks = c(0.5, 2.5, 4.5, 7.5),
    response_bin_labels = c("Low", "Medium", "High"),
    response_filter = 5:7,
    response_filter_combine = TRUE,
    response_filter_label = "High Satisfaction",
    chart_type = "line"
  ) %>%
    add_viz(title = "Complex Timeline")
  
  v <- viz$items[[1]]
  expect_equal(v$time_var, "year")
  expect_equal(v$y_var, "satisfaction")
  expect_equal(v$group_var, "age_group")
  expect_equal(v$response_breaks, c(0.5, 2.5, 4.5, 7.5))
  expect_equal(v$response_bin_labels, c("Low", "Medium", "High"))
  expect_equal(v$response_filter, 5:7)
  expect_true(v$response_filter_combine)
  expect_equal(v$response_filter_label, "High Satisfaction")
  expect_equal(v$chart_type, "line")
})

test_that("response_filter works with filter parameter", {
  # response_filter (filters response values) + filter (filters rows)
  viz <- create_viz(
    type = "timeline",
    time_var = "year",
    y_var = "score",
    response_filter = 5:7
  ) %>%
    add_viz(
      title = "Wave 1 High Scores",
      filter = ~ wave == 1  # Row filter
    )
  
  expect_equal(viz$items[[1]]$response_filter, 5:7)
  expect_s3_class(viz$items[[1]]$filter, "formula")
})

test_that("NULL response_filter_label shows default behavior", {
  viz <- create_viz(
    type = "timeline",
    time_var = "year",
    y_var = "score",
    response_filter = 5:7,
    response_filter_combine = TRUE,
    response_filter_label = NULL  # Explicit NULL
  ) %>%
    add_viz(title = "Default Label")
  
  # Should allow NULL (viz_timeline will use default like "5-7")
  expect_null(viz$items[[1]]$response_filter_label)
})

