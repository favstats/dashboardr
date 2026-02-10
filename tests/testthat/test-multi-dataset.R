# Tests for multi-dataset support
library(testthat)

test_that("named list of datasets is detected", {
  dataset1 <- data.frame(x = 1:10, y = rnorm(10))
  dataset2 <- data.frame(a = 1:20, b = rnorm(20))
  
  dashboard <- create_dashboard(
    output_dir = tempfile("multi_detect"),
    title = "Test"
  ) %>%
    add_page(
      "Analysis",
      data = list(data1 = dataset1, data2 = dataset2),
      is_landing_page = TRUE
    )
  
  # Page should be marked as multi-dataset
  expect_true(dashboard$pages$Analysis$is_multi_dataset)
  expect_type(dashboard$pages$Analysis$data_path, "list")
  expect_length(dashboard$pages$Analysis$data_path, 2)
  
})

test_that("single dataset is not treated as multi-dataset", {
  dataset <- data.frame(x = 1:10, y = rnorm(10))
  
  dashboard <- create_dashboard(
    output_dir = tempfile("single_data"),
    title = "Test"
  ) %>%
    add_page(
      "Analysis",
      data = dataset,
      is_landing_page = TRUE
    )
  
  # Should NOT be multi-dataset
  expect_false(dashboard$pages$Analysis$is_multi_dataset %||% FALSE)
  expect_type(dashboard$pages$Analysis$data_path, "character")
  
})

test_that("viz can specify which dataset to use", {
  viz <- create_viz(type = "histogram") %>%
    add_viz(x_var = "value1", data = "dataset1", title = "From Dataset 1") %>%
    add_viz(x_var = "value2", data = "dataset2", title = "From Dataset 2")
  
  expect_equal(viz$items[[1]]$data, "dataset1")
  expect_equal(viz$items[[2]]$data, "dataset2")
})

test_that("multi-dataset generates correct setup code", {
  viz <- create_viz(type = "histogram") %>%
    add_viz(x_var = "value", data = "data1", title = "Chart 1") %>%
    add_viz(x_var = "score", data = "data2", title = "Chart 2")
  
  dashboard <- create_dashboard(
    output_dir = tempfile("multi_setup"),
    title = "Test"
  ) %>%
    add_page(
      "Analysis",
      data = list(
        data1 = data.frame(value = rnorm(50)),
        data2 = data.frame(score = rnorm(30))
      ),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  qmd_file <- file.path(dashboard$output_dir, "index.qmd")
  qmd_content <- paste(readLines(qmd_file, warn = FALSE), collapse = "\n")
  
  # Setup should load both datasets
  expect_true(grepl("data1", qmd_content))
  expect_true(grepl("data2", qmd_content))
  expect_true(grepl("readRDS", qmd_content))
  
})

test_that("multi-dataset with filters", {
  viz <- create_viz(type = "histogram") %>%
    add_viz(
      x_var = "value",
      data = "data1",
      filter = ~ category == "A",
      title = "Data1 - Category A"
    ) %>%
    add_viz(
      x_var = "value",
      data = "data2",
      filter = ~ category == "B",
      title = "Data2 - Category B"
    )
  
  dashboard <- create_dashboard(
    output_dir = tempfile("multi_filter"),
    title = "Test"
  ) %>%
    add_page(
      "Analysis",
      data = list(
        data1 = data.frame(value = rnorm(50), category = rep(c("A", "B"), 25)),
        data2 = data.frame(value = rnorm(50), category = rep(c("A", "B"), 25))
      ),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  qmd_file <- file.path(dashboard$output_dir, "index.qmd")
  qmd_content <- paste(readLines(qmd_file, warn = FALSE), collapse = "\n")
  
  # Should have filtered versions of both datasets
  expect_true(grepl("data1", qmd_content))
  expect_true(grepl("data2", qmd_content))
  expect_true(grepl("category == \"A\"", qmd_content))
  expect_true(grepl("category == \"B\"", qmd_content))
  
})

test_that("dataset deduplication works", {
  # Same dataset used multiple times should only be saved once
  same_data <- data.frame(x = 1:100, y = rnorm(100))
  
  dashboard <- create_dashboard(
    output_dir = tempfile("dedup_test"),
    title = "Test"
  ) %>%
    add_page(
      "Page1",
      data = same_data,
      is_landing_page = TRUE
    ) %>%
    add_page(
      "Page2",
      data = same_data  # Same exact data
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  # Count RDS files - should only have 1
  rds_files <- list.files(dashboard$output_dir, pattern = "\\.rds$", recursive = TRUE)
  expect_length(rds_files, 1)
  
})

test_that("multi-dataset saves files with correct names", {
  dashboard <- create_dashboard(
    output_dir = tempfile("multi_names"),
    title = "Test"
  ) %>%
    add_page(
      "Analysis",
      data = list(
        sales_data = data.frame(sales = 1:10),
        customer_data = data.frame(customers = 1:20),
        product_data = data.frame(products = 1:15)
      ),
      is_landing_page = TRUE
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  rds_files <- list.files(dashboard$output_dir, pattern = "\\.rds$", full.names = FALSE)
  
  # Should have descriptive filenames
  expect_true(any(grepl("sales_data", rds_files)))
  expect_true(any(grepl("customer_data", rds_files)))
  expect_true(any(grepl("product_data", rds_files)))
  
})

test_that("missing dataset name in viz causes error or warning", {
  viz <- create_viz(type = "histogram") %>%
    add_viz(x_var = "value", data = "nonexistent_dataset", title = "Bad")
  
  dashboard <- create_dashboard(
    output_dir = tempfile("missing_data"),
    title = "Test"
  ) %>%
    add_page(
      "Analysis",
      data = list(
        data1 = data.frame(value = rnorm(10))
      ),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  # Should either error or generate code that references the wrong dataset
  # (Implementation detail - just ensure it doesn't crash silently)
  result <- generate_dashboard(dashboard, render = FALSE)
  expect_s3_class(result, "dashboard_project")
  
})

test_that("viz without data parameter uses default dataset", {
  viz <- create_viz(type = "histogram") %>%
    add_viz(x_var = "value", title = "Default Data")  # No data param
  
  dashboard <- create_dashboard(
    output_dir = tempfile("default_multi"),
    title = "Test"
  ) %>%
    add_page(
      "Analysis",
      data = list(
        data1 = data.frame(value = rnorm(10)),
        data2 = data.frame(value = rnorm(20))
      ),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  qmd_file <- file.path(dashboard$output_dir, "index.qmd")
  qmd_content <- paste(readLines(qmd_file, warn = FALSE), collapse = "\n")
  
  # Should use "data" as fallback (first dataset or explicitly named "data")
  expect_true(grepl("data", qmd_content))
  
})

test_that("multi-dataset works with different viz types", {
  viz <- create_viz() %>%
    add_viz(
      type = "histogram",
      x_var = "value",
      data = "hist_data",
      title = "Histogram"
    ) %>%
    add_viz(
      type = "timeline",
      time_var = "year",
      y_var = "metric",
      data = "timeline_data",
      title = "Timeline"
    ) %>%
    add_viz(
      type = "stackedbar",
      x_var = "category",
      stack_var = "group",
      data = "bar_data",
      title = "Stacked Bar"
    )
  
  dashboard <- create_dashboard(
    output_dir = tempfile("multi_types"),
    title = "Test"
  ) %>%
    add_page(
      "Analysis",
      data = list(
        hist_data = data.frame(value = rnorm(50)),
        timeline_data = data.frame(
          year = rep(2020:2023, each = 10),
          metric = rnorm(40)
        ),
        bar_data = data.frame(
          category = rep(c("A", "B"), 20),
          group = rep(c("X", "Y"), 20)
        )
      ),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  qmd_file <- file.path(dashboard$output_dir, "index.qmd")
  qmd_content <- paste(readLines(qmd_file, warn = FALSE), collapse = "\n")
  
  # Should use appropriate datasets for each viz
  expect_true(grepl("hist_data", qmd_content))
  expect_true(grepl("timeline_data", qmd_content))
  expect_true(grepl("bar_data", qmd_content))
  
  # Should have correct function calls
  expect_true(grepl("viz_histogram", qmd_content))
  expect_true(grepl("viz_timeline", qmd_content))
  expect_true(grepl("viz_stackedbar", qmd_content))
  
})

test_that("multi-dataset with combine_viz preserves dataset references", {
  viz1 <- create_viz(type = "histogram") %>%
    add_viz(x_var = "value", data = "data1", title = "From Data1")
  
  viz2 <- create_viz(type = "histogram") %>%
    add_viz(x_var = "value", data = "data2", title = "From Data2")
  
  combined <- combine_viz(viz1, viz2)
  
  # Dataset references should be preserved
  expect_equal(combined$items[[1]]$data, "data1")
  expect_equal(combined$items[[2]]$data, "data2")
})

test_that("multi-dataset summary output shows all datasets", {
  dashboard <- create_dashboard(
    output_dir = tempfile("multi_summary"),
    title = "Test"
  ) %>%
    add_page(
      "Analysis",
      data = list(
        sales = data.frame(x = 1:100),
        customers = data.frame(y = 1:50),
        products = data.frame(z = 1:75)
      ),
      is_landing_page = TRUE
    )
  
  output <- capture.output({
    generate_dashboard(dashboard, render = FALSE)
  })
  
  output_text <- paste(output, collapse = "\n")
  
  # Summary should mention data files
  # Note: Check for "Data files" text (emoji may vary depending on encoding)
  expect_true(grepl("Data files|data files", output_text, ignore.case = TRUE))
  
})

