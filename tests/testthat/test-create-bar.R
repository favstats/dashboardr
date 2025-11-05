# Tests for create_bar function (grouped/clustered bar charts)
library(testthat)

test_that("create_bar basic functionality", {
  data <- data.frame(
    category = c("A", "B", "C", "A", "B", "B")
  )
  
  result <- create_bar(
    data = data,
    x_var = "category"
  )
  
  expect_s3_class(result, "highchart")
})

test_that("create_bar with group_var creates grouped bars", {
  data <- data.frame(
    category = rep(c("A", "B", "C"), each = 4),
    group = rep(c("Group1", "Group2"), 6)
  )
  
  result <- create_bar(
    data = data,
    x_var = "category",
    group_var = "group"
  )
  
  expect_s3_class(result, "highchart")
})

test_that("create_bar horizontal orientation", {
  data <- data.frame(
    category = c("A", "B", "C", "A", "B")
  )
  
  result <- create_bar(
    data = data,
    x_var = "category",
    horizontal = TRUE
  )
  
  expect_s3_class(result, "highchart")
})

test_that("create_bar percent type", {
  data <- data.frame(
    category = rep(c("A", "B"), each = 5),
    group = rep(c("X", "Y"), 5)
  )
  
  result <- create_bar(
    data = data,
    x_var = "category",
    group_var = "group",
    bar_type = "percent"
  )
  
  expect_s3_class(result, "highchart")
})

test_that("create_bar with color_palette", {
  data <- data.frame(
    category = rep(c("A", "B"), each = 5),
    group = rep(c("X", "Y"), 5)
  )
  
  colors <- c("#FF0000", "#00FF00")
  
  result <- create_bar(
    data = data,
    x_var = "category",
    group_var = "group",
    color_palette = colors
  )
  
  expect_s3_class(result, "highchart")
})

test_that("create_bar with numeric x_var", {
  data <- data.frame(
    score = sample(1:10, 100, replace = TRUE)
  )
  
  result <- create_bar(
    data = data,
    x_var = "score"
  )
  
  expect_s3_class(result, "highchart")
})

test_that("create_bar aggregates counts automatically", {
  data <- data.frame(
    category = c("A", "A", "B", "B", "B", "C")
  )
  
  result <- create_bar(
    data = data,
    x_var = "category"
  )
  
  expect_s3_class(result, "highchart")
})

test_that("create_bar with title", {
  data <- data.frame(
    category = c("A", "B", "C", "A", "B")
  )
  
  result <- create_bar(
    data = data,
    x_var = "category",
    title = "My Bar Chart"
  )
  
  expect_s3_class(result, "highchart")
})

test_that("create_bar with custom labels", {
  data <- data.frame(
    category = c("A", "B", "C", "A")
  )
  
  result <- create_bar(
    data = data,
    x_var = "category",
    x_label = "Categories",
    y_label = "Count"
  )
  
  expect_s3_class(result, "highchart")
})

test_that("create_bar with group_order", {
  data <- data.frame(
    category = rep(c("A", "B"), each = 6),
    group = rep(c("High", "Medium", "Low"), 4)
  )
  
  result <- create_bar(
    data = data,
    x_var = "category",
    group_var = "group",
    group_order = c("Low", "Medium", "High")
  )
  
  expect_s3_class(result, "highchart")
})

test_that("create_bar works in viz_collection", {
  viz <- create_viz(
    type = "bar",
    x_var = "category"
  ) %>%
    add_viz(title = "Bar Chart")
  
  expect_equal(viz$items[[1]]$viz_type, "bar")
  expect_equal(viz$items[[1]]$x_var, "category")
})

test_that("create_bar in dashboard generation", {
  viz <- create_viz(
    type = "bar",
    x_var = "category"
  ) %>%
    add_viz(title = "Category Counts")
  
  dashboard <- create_dashboard(
    output_dir = tempfile("bar_dashboard"),
    title = "Test"
  ) %>%
    add_page(
      "Analysis",
      data = data.frame(
        category = c("A", "B", "C", "D", "A", "B", "B", "C")
      ),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  qmd_file <- file.path(dashboard$output_dir, "index.qmd")
  qmd_content <- paste(readLines(qmd_file, warn = FALSE), collapse = "\n")
  
  # Should contain create_bar call
  expect_true(grepl("create_bar", qmd_content))
  expect_true(grepl("x_var", qmd_content))
  
})

test_that("create_bar with all parameters", {
  data <- data.frame(
    question = rep(c("Q1", "Q2", "Q3"), each = 10),
    score_range = rep(c("Low", "High"), 15)
  )
  
  result <- create_bar(
    data = data,
    x_var = "question",
    group_var = "score_range",
    horizontal = TRUE,
    bar_type = "percent",
    color_palette = c("#E74C3C", "#3498DB"),
    group_order = c("Low", "High"),
    title = "Survey Results",
    x_label = "Questions",
    y_label = "Percentage"
  )
  
  expect_s3_class(result, "highchart")
})

test_that("create_bar color works without group_var", {
  data <- data.frame(
    category = c("A", "B", "C", "D", "A", "B", "C")
  )
  
  result <- create_bar(
    data = data,
    x_var = "category",
    color_palette = c("#FF0000", "#00FF00", "#0000FF", "#FFFF00")
  )
  
  expect_s3_class(result, "highchart")
})

test_that("create_bar with numeric binning", {
  data <- data.frame(
    age = sample(18:65, 100, replace = TRUE)
  )
  
  result <- create_bar(
    data = data,
    x_var = "age"
  )
  
  expect_s3_class(result, "highchart")
})

test_that("create_bar with x_breaks for binning", {
  data <- data.frame(
    age = sample(18:65, 100, replace = TRUE)
  )
  
  result <- create_bar(
    data = data,
    x_var = "age",
    x_breaks = c(18, 30, 45, 65),
    x_bin_labels = c("18-29", "30-44", "45-64")
  )
  
  expect_s3_class(result, "highchart")
})

test_that("create_bar with defaults in create_viz", {
  viz <- create_viz(
    type = "bar",
    horizontal = TRUE,
    bar_type = "percent",
    color_palette = c("#E74C3C", "#3498DB")
  ) %>%
    add_viz(
      x_var = "category",
      group_var = "group",
      title = "Chart 1"
    ) %>%
    add_viz(
      x_var = "category",
      group_var = "group",
      title = "Chart 2"
    )
  
  # Both should inherit defaults
  expect_true(viz$items[[1]]$horizontal)
  expect_true(viz$items[[2]]$horizontal)
  expect_equal(viz$items[[1]]$bar_type, "percent")
  expect_equal(viz$items[[2]]$bar_type, "percent")
})

test_that("create_bar with filter parameter", {
  viz <- create_viz(
    type = "bar",
    x_var = "category"
  ) %>%
    add_viz(
      title = "Wave 1",
      filter = ~ wave == 1
    )
  
  expect_s3_class(viz$items[[1]]$filter, "formula")
  expect_equal(as.character(viz$items[[1]]$filter)[2], "wave == 1")
})

test_that("create_bar with x_order", {
  data <- data.frame(
    category = c("Z", "A", "M", "Z", "A", "A")
  )
  
  result <- create_bar(
    data = data,
    x_var = "category",
    x_order = c("A", "M", "Z")
  )
  
  expect_s3_class(result, "highchart")
})

test_that("create_bar with include_na", {
  data <- data.frame(
    category = c("A", "B", NA, "A", NA, "B")
  )
  
  result <- create_bar(
    data = data,
    x_var = "category",
    include_na = TRUE,
    na_label = "Missing"
  )
  
  expect_s3_class(result, "highchart")
})

test_that("create_bar count type", {
  data <- data.frame(
    category = rep(c("A", "B", "C"), each = 3)
  )
  
  result <- create_bar(
    data = data,
    x_var = "category",
    bar_type = "count"
  )
  
  expect_s3_class(result, "highchart")
})

test_that("create_bar error handling for missing x_var", {
  data <- data.frame(
    category = c("A", "B", "C")
  )
  
  expect_error(
    create_bar(data = data),
    "x_var"
  )
})

test_that("create_bar works with drop_na_vars", {
  viz <- create_viz(
    type = "bar",
    x_var = "category"
  ) %>%
    add_viz(
      title = "Clean Data",
      drop_na_vars = TRUE
    )
  
  expect_true(viz$items[[1]]$drop_na_vars)
})
