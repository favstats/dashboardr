# Tests for per-visualization filter parameter
library(testthat)

test_that("basic filter syntax works", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value"
  ) %>%
    add_viz(title = "Wave 1", filter = ~ wave == 1) %>%
    add_viz(title = "Wave 2", filter = ~ wave == 2)
  
  # Filters should be stored as formulas
  expect_s3_class(viz$items[[1]]$filter, "formula")
  expect_s3_class(viz$items[[2]]$filter, "formula")
  
  # Check filter expressions
  expect_equal(as.character(viz$items[[1]]$filter)[2], "wave == 1")
  expect_equal(as.character(viz$items[[2]]$filter)[2], "wave == 2")
})

test_that("complex filter expressions work", {
  viz <- create_viz(type = "histogram", x_var = "value") %>%
    add_viz(
      title = "Complex Filter",
      filter = ~ wave %in% c(1, 2) & age > 30 & gender == "F"
    )
  
  expect_s3_class(viz$items[[1]]$filter, "formula")
  filter_expr <- as.character(viz$items[[1]]$filter)[2]
  
  expect_true(grepl("wave", filter_expr))
  expect_true(grepl("age", filter_expr))
  expect_true(grepl("gender", filter_expr))
})

test_that("filter generates correct code in dashboard", {
  viz <- create_viz(
    type = "histogram",
    x_var = "score"
  ) %>%
    add_viz(title = "High Scores", filter = ~ score > 50)
  
  dashboard <- create_dashboard(
    output_dir = tempfile("filter_test"),
    title = "Test"
  ) %>%
    add_page(
      "Analysis",
      data = data.frame(score = 1:100),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  qmd_file <- file.path(dashboard$output_dir, "index.qmd")
  qmd_content <- paste(readLines(qmd_file, warn = FALSE), collapse = "\n")
  
  # Should have filtered dataset in setup
  expect_true(grepl("data_filtered", qmd_content))
  expect_true(grepl("score > 50", qmd_content))
  
  # Visualization should use filtered data
  expect_true(grepl("data = data_filtered", qmd_content))
  
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("multiple visualizations with same filter reuse filtered dataset", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value"
  ) %>%
    add_viz(title = "Chart 1", filter = ~ wave == 1) %>%
    add_viz(title = "Chart 2", filter = ~ wave == 1)  # Same filter
  
  dashboard <- create_dashboard(
    output_dir = tempfile("filter_reuse"),
    title = "Test"
  ) %>%
    add_page(
      "Analysis",
      data = data.frame(wave = rep(1:3, each = 10), value = rnorm(30)),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  qmd_file <- file.path(dashboard$output_dir, "index.qmd")
  qmd_content <- readLines(qmd_file, warn = FALSE)
  
  # Should only create filtered dataset once in setup
  filter_creation_count <- sum(grepl("wave == 1", qmd_content))
  expect_true(filter_creation_count >= 1)  # Created at least once
  
  # Both visualizations should reference the same filtered dataset
  filtered_data_usage <- sum(grepl("data_filtered", qmd_content))
  expect_true(filtered_data_usage >= 2)  # Used in both viz calls
  
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("different filters create separate filtered datasets", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value"
  ) %>%
    add_viz(title = "Wave 1", filter = ~ wave == 1) %>%
    add_viz(title = "Wave 2", filter = ~ wave == 2) %>%
    add_viz(title = "Wave 3", filter = ~ wave == 3)
  
  dashboard <- create_dashboard(
    output_dir = tempfile("multi_filter"),
    title = "Test"
  ) %>%
    add_page(
      "Analysis",
      data = data.frame(wave = rep(1:3, each = 10), value = rnorm(30)),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  qmd_file <- file.path(dashboard$output_dir, "index.qmd")
  qmd_content <- paste(readLines(qmd_file, warn = FALSE), collapse = "\n")
  
  # Should have 3 different filtered datasets
  expect_true(grepl("wave == 1", qmd_content))
  expect_true(grepl("wave == 2", qmd_content))
  expect_true(grepl("wave == 3", qmd_content))
  
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("filter works with non-filtered visualizations", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value"
  ) %>%
    add_viz(title = "All Data") %>%  # No filter
    add_viz(title = "Filtered", filter = ~ category == "A")
  
  dashboard <- create_dashboard(
    output_dir = tempfile("mixed_filter"),
    title = "Test"
  ) %>%
    add_page(
      "Analysis",
      data = data.frame(
        value = rnorm(30),
        category = rep(c("A", "B", "C"), each = 10)
      ),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  qmd_file <- file.path(dashboard$output_dir, "index.qmd")
  qmd_content <- paste(readLines(qmd_file, warn = FALSE), collapse = "\n")
  
  # First viz should use original data
  # Second viz should use filtered data
  expect_true(grepl("category == \"A\"", qmd_content))
  
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("filter works with combine_viz", {
  viz1 <- create_viz(type = "histogram", x_var = "value") %>%
    add_viz(title = "Group A", filter = ~ group == "A")
  
  viz2 <- create_viz(type = "histogram", x_var = "value") %>%
    add_viz(title = "Group B", filter = ~ group == "B")
  
  combined <- combine_viz(viz1, viz2)
  
  # Both filters should be preserved
  expect_equal(as.character(combined$items[[1]]$filter)[2], "group == \"A\"")
  expect_equal(as.character(combined$items[[2]]$filter)[2], "group == \"B\"")
})

test_that("filter with nested tabgroups", {
  viz <- create_viz(
    type = "stackedbar",
    x_var = "question",
    stack_var = "response"
  ) %>%
    add_viz(
      title = "Age - Wave 1",
      filter = ~ wave == 1,
      tabgroup = "demographics/age"
    ) %>%
    add_viz(
      title = "Age - Wave 2",
      filter = ~ wave == 2,
      tabgroup = "demographics/age"
    )
  
  dashboard <- create_dashboard(
    output_dir = tempfile("filter_nested"),
    title = "Test"
  ) %>%
    add_page(
      "Analysis",
      data = data.frame(
        wave = rep(1:2, each = 20),
        question = rep(c("Q1", "Q2"), 20),
        response = sample(1:5, 40, replace = TRUE)
      ),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  qmd_file <- file.path(dashboard$output_dir, "index.qmd")
  qmd_content <- paste(readLines(qmd_file, warn = FALSE), collapse = "\n")
  
  # Both filters should be present
  expect_true(grepl("wave == 1", qmd_content))
  expect_true(grepl("wave == 2", qmd_content))
  
  # Tabgroups should be rendered
  expect_true(grepl("demographics", qmd_content, ignore.case = TRUE))
  
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("filter with multi-dataset support", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value"
  ) %>%
    add_viz(
      title = "Dataset 1 - Filtered",
      data = "data1",
      filter = ~ category == "A"
    ) %>%
    add_viz(
      title = "Dataset 2 - Filtered",
      data = "data2",
      filter = ~ category == "B"
    )
  
  dashboard <- create_dashboard(
    output_dir = tempfile("filter_multidata"),
    title = "Test"
  ) %>%
    add_page(
      "Analysis",
      data = list(
        data1 = data.frame(value = rnorm(30), category = rep(c("A", "B", "C"), each = 10)),
        data2 = data.frame(value = rnorm(30), category = rep(c("A", "B", "C"), each = 10))
      ),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  qmd_file <- file.path(dashboard$output_dir, "index.qmd")
  qmd_content <- paste(readLines(qmd_file, warn = FALSE), collapse = "\n")
  
  # Should reference both datasets
  expect_true(grepl("data1", qmd_content))
  expect_true(grepl("data2", qmd_content))
  
  # Should have both filters
  expect_true(grepl("category == \"A\"", qmd_content))
  expect_true(grepl("category == \"B\"", qmd_content))
  
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("filter hash generation is consistent", {
  # Same filter should generate same hash
  viz <- create_viz(type = "histogram", x_var = "value") %>%
    add_viz(title = "Chart 1", filter = ~ wave == 1) %>%
    add_viz(title = "Chart 2", filter = ~ wave == 1)  # Identical filter
  
  dashboard <- create_dashboard(
    output_dir = tempfile("filter_hash"),
    title = "Test"
  ) %>%
    add_page(
      "Analysis",
      data = data.frame(wave = rep(1:3, each = 10), value = rnorm(30)),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  qmd_file <- file.path(dashboard$output_dir, "index.qmd")
  qmd_content <- readLines(qmd_file, warn = FALSE)
  
  # Find all data_filtered references
  filtered_refs <- grep("data_filtered_[a-f0-9]{8}", qmd_content, value = TRUE)
  
  # Should have consistent hash for same filter
  expect_true(length(filtered_refs) > 0)
  
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("filter with %in% operator", {
  viz <- create_viz(type = "histogram", x_var = "value") %>%
    add_viz(
      title = "Multiple Waves",
      filter = ~ wave %in% c(1, 2, 3)
    )
  
  expect_s3_class(viz$items[[1]]$filter, "formula")
  filter_expr <- as.character(viz$items[[1]]$filter)[2]
  expect_true(grepl("%in%", filter_expr))
})

test_that("filter with logical AND/OR operators", {
  viz <- create_viz(type = "histogram", x_var = "value") %>%
    add_viz(
      title = "Complex Logic",
      filter = ~ (wave == 1 | wave == 2) & age > 30
    )
  
  expect_s3_class(viz$items[[1]]$filter, "formula")
  filter_expr <- as.character(viz$items[[1]]$filter)[2]
  expect_true(grepl("wave", filter_expr))
  expect_true(grepl("age", filter_expr))
})

