# Tests for create_viz() defaults feature
library(testthat)

test_that("defaults in create_viz propagate to add_viz", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value",
    bins = 30,
    color = "blue"
  ) %>%
    add_viz(title = "Chart 1") %>%
    add_viz(title = "Chart 2")
  
  # Both visualizations should have the defaults
  expect_equal(viz$items[[1]]$viz_type, "histogram")
  expect_equal(viz$items[[1]]$x_var, "value")
  expect_equal(viz$items[[1]]$bins, 30)
  expect_equal(viz$items[[1]]$color, "blue")
  
  expect_equal(viz$items[[2]]$viz_type, "histogram")
  expect_equal(viz$items[[2]]$x_var, "value")
  expect_equal(viz$items[[2]]$bins, 30)
  expect_equal(viz$items[[2]]$color, "blue")
})

test_that("add_viz parameters override defaults", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value",
    bins = 30,
    color = "blue"
  ) %>%
    add_viz(title = "Default Colors") %>%
    add_viz(title = "Custom Colors", color = "red", bins = 50)
  
  # First viz uses defaults
  expect_equal(viz$items[[1]]$color, "blue")
  expect_equal(viz$items[[1]]$bins, 30)
  
  # Second viz overrides defaults
  expect_equal(viz$items[[2]]$color, "red")
  expect_equal(viz$items[[2]]$bins, 50)
  
  # But keeps other defaults
  expect_equal(viz$items[[2]]$x_var, "value")
  expect_equal(viz$items[[1]]$viz_type, "histogram")
})

test_that("defaults work with different viz types", {
  # Stackedbar defaults
  viz_stacked <- create_viz(
    type = "stackedbar",
    stacked_type = "percent",
    horizontal = TRUE,
    color_palette = c("#FF0000", "#00FF00")
  ) %>%
    add_viz(x_var = "category", stack_var = "group")
  
  expect_equal(viz_stacked$items[[1]]$stacked_type, "percent")
  expect_equal(viz_stacked$items[[1]]$horizontal, TRUE)
  expect_equal(viz_stacked$items[[1]]$color_palette, c("#FF0000", "#00FF00"))
  
  # Timeline defaults
  viz_timeline <- create_viz(
    type = "timeline",
    chart_type = "line",
    time_var = "year"
  ) %>%
    add_viz(response_var = "sales") %>%
    add_viz(response_var = "profit")
  
  expect_equal(viz_timeline$items[[1]]$time_var, "year")
  expect_equal(viz_timeline$items[[1]]$chart_type, "line")
  expect_equal(viz_timeline$items[[2]]$time_var, "year")
  expect_equal(viz_timeline$items[[2]]$chart_type, "line")
})

test_that("defaults work with combine_viz", {
  viz1 <- create_viz(
    type = "histogram",
    bins = 20
  ) %>%
    add_viz(x_var = "value1", title = "Viz 1")
  
  viz2 <- create_viz(
    type = "histogram",
    bins = 40
  ) %>%
    add_viz(x_var = "value2", title = "Viz 2")
  
  combined <- combine_viz(viz1, viz2)
  
  # Each should retain its own defaults
  expect_equal(combined$items[[1]]$bins, 20)
  expect_equal(combined$items[[2]]$bins, 40)
})

test_that("empty defaults in create_viz still allows add_viz params", {
  viz <- create_viz() %>%
    add_viz(
      type = "histogram",
      x_var = "value",
      bins = 30
    )
  
  expect_equal(viz$items[[1]]$viz_type, "histogram")
  expect_equal(viz$items[[1]]$x_var, "value")
  expect_equal(viz$items[[1]]$bins, 30)
})

test_that("defaults work with complex stackedbars parameters", {
  viz <- create_viz(
    type = "stackedbars",
    questions = c("q1", "q2", "q3"),
    question_labels = c("Question 1", "Question 2", "Question 3"),
    stacked_type = "percent",
    horizontal = TRUE,
    stack_breaks = c(0.5, 2.5, 4.5),
    stack_bin_labels = c("Low", "Medium", "High")
  ) %>%
    add_viz(title = "Wave 1", filter = ~ wave == 1) %>%
    add_viz(title = "Wave 2", filter = ~ wave == 2)
  
  # Both should have all the complex defaults
  for (i in 1:2) {
    expect_equal(viz$items[[1]]$viz_type, "stackedbars")
    expect_equal(viz$items[[i]]$questions, c("q1", "q2", "q3"))
    expect_equal(viz$items[[i]]$question_labels, 
                 c("Question 1", "Question 2", "Question 3"))
    expect_equal(viz$items[[i]]$stacked_type, "percent")
    expect_equal(viz$items[[i]]$horizontal, TRUE)
    expect_equal(viz$items[[i]]$stack_breaks, c(0.5, 2.5, 4.5))
    expect_equal(viz$items[[i]]$stack_bin_labels, c("Low", "Medium", "High"))
  }
  
  # But different filters
  expect_equal(as.character(viz$items[[1]]$filter)[2], "wave == 1")
  expect_equal(as.character(viz$items[[2]]$filter)[2], "wave == 2")
})

test_that("defaults with tabgroup parameter", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value"
  ) %>%
    add_viz(title = "Chart 1", tabgroup = "group1") %>%
    add_viz(title = "Chart 2", tabgroup = "group2")
  
  expect_equal(viz$items[[1]]$x_var, "value")
  expect_equal(viz$items[[1]]$tabgroup, "group1")
  expect_equal(viz$items[[2]]$x_var, "value")
  expect_equal(viz$items[[2]]$tabgroup, "group2")
})

test_that("NULL defaults don't override add_viz parameters", {
  viz <- create_viz(
    type = "histogram",
    bins = NULL  # Explicitly NULL
  ) %>%
    add_viz(x_var = "value", bins = 30)
  
  # Should use the add_viz parameter, not NULL
  expect_equal(viz$items[[1]]$bins, 30)
})

test_that("defaults work in dashboard generation", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value",
    bins = 25
  ) %>%
    add_viz(title = "Distribution")
  
  dashboard <- create_dashboard(
    output_dir = tempfile("defaults_test"),
    title = "Test"
  ) %>%
    add_page(
      "Analysis",
      data = data.frame(value = rnorm(100)),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  # Read generated QMD
  qmd_file <- file.path(dashboard$output_dir, "index.qmd")
  qmd_content <- paste(readLines(qmd_file, warn = FALSE), collapse = "\n")
  
  # Should contain create_histogram call with bins parameter
  expect_true(grepl("create_histogram", qmd_content))
  expect_true(grepl("bins = 25", qmd_content))
  
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("defaults with data parameter", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value",
    data = "dataset2"  # Reference to named dataset
  ) %>%
    add_viz(title = "From Dataset 2") %>%
    add_viz(title = "From Dataset 1", data = "dataset1")  # Override
  
  expect_equal(viz$items[[1]]$data, "dataset2")
  expect_equal(viz$items[[2]]$data, "dataset1")
})

test_that("defaults preserve all parameter types", {
  viz <- create_viz(
    type = "timeline",
    # String parameters
    time_var = "year",
    response_var = "value",
    # Numeric parameters
    response_breaks = c(1.5, 3.5, 5.5),
    # Character vector
    response_bin_labels = c("Low", "Medium", "High"),
    # Logical
    response_filter_combine = TRUE,
    # NULL (should not override)
    title = NULL
  ) %>%
    add_viz(title = "Trend", group_var = "category")
  
  v <- viz$items[[1]]
  expect_equal(v$time_var, "year")
  expect_equal(v$response_var, "value")
  expect_equal(v$response_breaks, c(1.5, 3.5, 5.5))
  expect_equal(v$response_bin_labels, c("Low", "Medium", "High"))
  expect_equal(v$response_filter_combine, TRUE)
  expect_equal(v$title, "Trend")  # Not NULL
  expect_equal(v$group_var, "category")  # New parameter
})

