# Tests for drop_na_vars feature
library(testthat)

test_that("drop_na_vars basic functionality", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value"
  ) %>%
    add_viz(
      title = "Clean Data",
      drop_na_vars = TRUE
    )
  
  expect_true(viz$visualizations[[1]]$drop_na_vars)
})

test_that("drop_na_vars defaults to FALSE", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value"
  ) %>%
    add_viz(title = "Chart")
  
  expect_false(viz$visualizations[[1]]$drop_na_vars %||% FALSE)
})

test_that("drop_na_vars generates tidyr::drop_na call for histogram", {
  viz <- create_viz(
    type = "histogram",
    x_var = "score"
  ) %>%
    add_viz(
      title = "Distribution",
      drop_na_vars = TRUE
    )
  
  dashboard <- create_dashboard(
    output_dir = tempfile("drop_na_hist"),
    title = "Test"
  ) %>%
    add_page(
      "Analysis",
      data = data.frame(
        score = c(1, 2, NA, 4, 5, NA, 7)
      ),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  qmd_file <- file.path(dashboard$output_dir, "index.qmd")
  qmd_content <- paste(readLines(qmd_file, warn = FALSE), collapse = "\n")
  
  # Should have drop_na call
  expect_true(grepl("drop_na", qmd_content))
  expect_true(grepl("score", qmd_content))
  
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("drop_na_vars with stackedbar removes NAs from x_var and stack_var", {
  viz <- create_viz(
    type = "stackedbar",
    x_var = "question",
    stack_var = "response"
  ) %>%
    add_viz(
      title = "Clean Survey",
      drop_na_vars = TRUE
    )
  
  dashboard <- create_dashboard(
    output_dir = tempfile("drop_na_stacked"),
    title = "Test"
  ) %>%
    add_page(
      "Analysis",
      data = data.frame(
        question = c("Q1", "Q2", NA, "Q1"),
        response = c(1, NA, 3, 2)
      ),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  qmd_file <- file.path(dashboard$output_dir, "index.qmd")
  qmd_content <- paste(readLines(qmd_file, warn = FALSE), collapse = "\n")
  
  # Should drop NA from both variables
  expect_true(grepl("drop_na", qmd_content))
  expect_true(grepl("question", qmd_content))
  expect_true(grepl("response", qmd_content))
  
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("drop_na_vars with timeline removes NAs from time_var and response_var", {
  viz <- create_viz(
    type = "timeline",
    time_var = "year",
    response_var = "value"
  ) %>%
    add_viz(
      title = "Clean Timeline",
      drop_na_vars = TRUE
    )
  
  dashboard <- create_dashboard(
    output_dir = tempfile("drop_na_timeline"),
    title = "Test"
  ) %>%
    add_page(
      "Analysis",
      data = data.frame(
        year = c(2020, NA, 2022, 2023),
        value = c(10, 20, NA, 40)
      ),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  qmd_file <- file.path(dashboard$output_dir, "index.qmd")
  qmd_content <- paste(readLines(qmd_file, warn = FALSE), collapse = "\n")
  
  # Should drop NA from both variables
  expect_true(grepl("drop_na", qmd_content))
  expect_true(grepl("year", qmd_content))
  expect_true(grepl("value", qmd_content))
  
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("drop_na_vars with group_var includes group in drop_na", {
  viz <- create_viz(
    type = "histogram",
    x_var = "score",
    group_var = "category"
  ) %>%
    add_viz(
      title = "Grouped Distribution",
      drop_na_vars = TRUE
    )
  
  dashboard <- create_dashboard(
    output_dir = tempfile("drop_na_group"),
    title = "Test"
  ) %>%
    add_page(
      "Analysis",
      data = data.frame(
        score = c(1, 2, 3, NA, 5),
        category = c("A", NA, "B", "A", "B")
      ),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  qmd_file <- file.path(dashboard$output_dir, "index.qmd")
  qmd_content <- paste(readLines(qmd_file, warn = FALSE), collapse = "\n")
  
  # Should include group_var
  expect_true(grepl("drop_na", qmd_content))
  expect_true(grepl("category", qmd_content))
  
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("drop_na_vars with bar chart", {
  viz <- create_viz(
    type = "bar",
    x_var = "category",
    group_var = "segment"
  ) %>%
    add_viz(
      title = "Clean Bars",
      drop_na_vars = TRUE
    )
  
  dashboard <- create_dashboard(
    output_dir = tempfile("drop_na_bar"),
    title = "Test"
  ) %>%
    add_page(
      "Analysis",
      data = data.frame(
        category = c("A", "B", NA, "C"),
        segment = c("X", NA, "Y", "Z")
      ),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  qmd_file <- file.path(dashboard$output_dir, "index.qmd")
  qmd_content <- paste(readLines(qmd_file, warn = FALSE), collapse = "\n")
  
  # Should have drop_na
  expect_true(grepl("drop_na", qmd_content))
  
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("drop_na_vars works with defaults", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value",
    drop_na_vars = TRUE  # Default
  ) %>%
    add_viz(title = "Chart 1") %>%
    add_viz(title = "Chart 2")
  
  # Both should inherit drop_na_vars
  expect_true(viz$visualizations[[1]]$drop_na_vars)
  expect_true(viz$visualizations[[2]]$drop_na_vars)
})

test_that("drop_na_vars can be overridden in add_viz", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value",
    drop_na_vars = TRUE  # Default: drop NAs
  ) %>%
    add_viz(title = "Clean", drop_na_vars = TRUE) %>%
    add_viz(title = "With NAs", drop_na_vars = FALSE)  # Override
  
  expect_true(viz$visualizations[[1]]$drop_na_vars)
  expect_false(viz$visualizations[[2]]$drop_na_vars)
})

test_that("drop_na_vars with stackedbars includes all questions", {
  viz <- create_viz(
    type = "stackedbars",
    questions = c("q1", "q2", "q3")
  ) %>%
    add_viz(
      title = "Multiple Questions",
      drop_na_vars = TRUE
    )
  
  dashboard <- create_dashboard(
    output_dir = tempfile("drop_na_questions"),
    title = "Test"
  ) %>%
    add_page(
      "Analysis",
      data = data.frame(
        q1 = c(1, 2, NA, 4),
        q2 = c(1, NA, 3, 4),
        q3 = c(NA, 2, 3, 4)
      ),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  qmd_file <- file.path(dashboard$output_dir, "index.qmd")
  qmd_content <- paste(readLines(qmd_file, warn = FALSE), collapse = "\n")
  
  # Should drop NA from all questions
  expect_true(grepl("drop_na", qmd_content))
  expect_true(grepl("q1.*q2.*q3|c\\(.*q1.*q2.*q3.*\\)", qmd_content))
  
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("drop_na_vars works with filter parameter", {
  viz <- create_viz(
    type = "histogram",
    x_var = "score"
  ) %>%
    add_viz(
      title = "Wave 1 Clean",
      filter = ~ wave == 1,
      drop_na_vars = TRUE
    )
  
  dashboard <- create_dashboard(
    output_dir = tempfile("drop_na_filter"),
    title = "Test"
  ) %>%
    add_page(
      "Analysis",
      data = data.frame(
        wave = c(1, 1, 2, 2, 1),
        score = c(10, NA, 30, 40, 50)
      ),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  qmd_file <- file.path(dashboard$output_dir, "index.qmd")
  qmd_content <- paste(readLines(qmd_file, warn = FALSE), collapse = "\n")
  
  # Should have both filter and drop_na
  expect_true(grepl("wave == 1", qmd_content))
  expect_true(grepl("drop_na", qmd_content))
  
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("drop_na_vars with heatmap removes NAs from all three vars", {
  viz <- create_viz(
    type = "heatmap",
    x_var = "category",
    y_var = "group",
    value_var = "score"
  ) %>%
    add_viz(
      title = "Clean Heatmap",
      drop_na_vars = TRUE
    )
  
  dashboard <- create_dashboard(
    output_dir = tempfile("drop_na_heatmap"),
    title = "Test"
  ) %>%
    add_page(
      "Analysis",
      data = data.frame(
        category = c("A", "B", NA, "D"),
        group = c("X", NA, "Y", "Z"),
        score = c(10, 20, NA, 40)
      ),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  qmd_file <- file.path(dashboard$output_dir, "index.qmd")
  qmd_content <- paste(readLines(qmd_file, warn = FALSE), collapse = "\n")
  
  # Should drop NA from all three variables
  expect_true(grepl("drop_na", qmd_content))
  expect_true(grepl("category", qmd_content))
  expect_true(grepl("group", qmd_content))
  expect_true(grepl("score", qmd_content))
  
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("drop_na_vars FALSE does not generate drop_na call", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value"
  ) %>%
    add_viz(
      title = "With NAs",
      drop_na_vars = FALSE
    )
  
  dashboard <- create_dashboard(
    output_dir = tempfile("no_drop_na"),
    title = "Test"
  ) %>%
    add_page(
      "Analysis",
      data = data.frame(value = c(1, 2, NA, 4)),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  qmd_file <- file.path(dashboard$output_dir, "index.qmd")
  qmd_content <- paste(readLines(qmd_file, warn = FALSE), collapse = "\n")
  
  # Should NOT have drop_na call
  expect_false(grepl("drop_na", qmd_content))
  
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("drop_na_vars with add_vizzes", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value",
    drop_na_vars = TRUE
  ) %>%
    add_viz(title = "Wave 1", filter = ~ wave == 1) %>%
    add_viz(title = "Wave 2", filter = ~ wave == 2) %>%
    add_viz(title = "Wave 3", filter = ~ wave == 3)
  
  # All should have drop_na_vars
  expect_true(viz$visualizations[[1]]$drop_na_vars)
  expect_true(viz$visualizations[[2]]$drop_na_vars)
  expect_true(viz$visualizations[[3]]$drop_na_vars)
})

test_that("drop_na_vars with multi-dataset", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value"
  ) %>%
    add_viz(
      title = "Dataset 1",
      data = "data1",
      drop_na_vars = TRUE
    ) %>%
    add_viz(
      title = "Dataset 2",
      data = "data2",
      drop_na_vars = TRUE
    )
  
  dashboard <- create_dashboard(
    output_dir = tempfile("drop_na_multi"),
    title = "Test"
  ) %>%
    add_page(
      "Analysis",
      data = list(
        data1 = data.frame(value = c(1, NA, 3)),
        data2 = data.frame(value = c(10, 20, NA))
      ),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  qmd_file <- file.path(dashboard$output_dir, "index.qmd")
  qmd_content <- paste(readLines(qmd_file, warn = FALSE), collapse = "\n")
  
  # Should have drop_na for both datasets
  expect_true(grepl("drop_na", qmd_content))
  
  unlink(dashboard$output_dir, recursive = TRUE)
})

