test_that("incremental build detects unchanged pages", {
  # Create dashboard
  dashboard <- create_dashboard(
    title = "Test Dashboard",
    output_dir = tempfile()
  ) %>%
    add_page("Page1", text = "Content 1", is_landing_page = TRUE) %>%
    add_page("Page2", text = "Content 2")
  
  # First build
  result1 <- generate_dashboard(dashboard, render = FALSE, incremental = TRUE)
  
  # Second build (nothing changed)
  result2 <- generate_dashboard(dashboard, render = FALSE, incremental = TRUE)
  
  # Should have build info
  expect_true("build_info" %in% names(result2))
  expect_true("skipped" %in% names(result2$build_info))
})

test_that("incremental build detects changed page content", {
  dashboard <- create_dashboard(
    title = "Test Dashboard",
    output_dir = tempfile()
  ) %>%
    add_page("Page1", text = "Content 1", is_landing_page = TRUE)
  
  # First build
  generate_dashboard(dashboard, render = FALSE, incremental = TRUE)
  
  # Modify page
  dashboard <- create_dashboard(
    title = "Test Dashboard",
    output_dir = dashboard$output_dir
  ) %>%
    add_page("Page1", text = "Modified Content", is_landing_page = TRUE)
  
  # Second build
  result <- generate_dashboard(dashboard, render = FALSE, incremental = TRUE)
  
  expect_true("build_info" %in% names(result))
  expect_true(length(result$build_info$regenerated) > 0)
})

test_that("incremental build detects changed data", {
  data1 <- data.frame(x = 1:10)
  data2 <- data.frame(x = 1:20)
  
  output_dir <- tempfile()
  
  # First build
  dashboard1 <- create_dashboard(
    title = "Test",
    output_dir = output_dir
  ) %>%
    add_page("Analysis", data = data1, text = "Analysis", is_landing_page = TRUE)
  
  generate_dashboard(dashboard1, render = FALSE, incremental = TRUE)
  
  # Second build with different data
  dashboard2 <- create_dashboard(
    title = "Test",
    output_dir = output_dir
  ) %>%
    add_page("Analysis", data = data2, text = "Analysis", is_landing_page = TRUE)
  
  result <- generate_dashboard(dashboard2, render = FALSE, incremental = TRUE)
  
  expect_true("build_info" %in% names(result))
  expect_true("Analysis" %in% result$build_info$regenerated)
})

test_that("incremental build detects changed visualizations", {
  data <- data.frame(x = rnorm(100), y = rnorm(100))
  
  viz1 <- create_viz(type = "histogram", x_var = "x") %>%
    add_viz(title = "X Distribution")
  
  viz2 <- create_viz(type = "histogram", x_var = "y") %>%
    add_viz(title = "Y Distribution")
  
  output_dir <- tempfile()
  
  # First build
  dashboard1 <- create_dashboard(
    title = "Test",
    output_dir = output_dir
  ) %>%
    add_page("Analysis", data = data, visualizations = viz1, is_landing_page = TRUE)
  
  generate_dashboard(dashboard1, render = FALSE, incremental = TRUE)
  
  # Second build with different viz
  dashboard2 <- create_dashboard(
    title = "Test",
    output_dir = output_dir
  ) %>%
    add_page("Analysis", data = data, visualizations = viz2, is_landing_page = TRUE)
  
  result <- generate_dashboard(dashboard2, render = FALSE, incremental = TRUE)
  
  expect_true("Analysis" %in% result$build_info$regenerated)
})

test_that("incremental = FALSE forces full rebuild", {
  dashboard <- create_dashboard(
    title = "Test Dashboard",
    output_dir = tempfile()
  ) %>%
    add_page("Page1", text = "Content", is_landing_page = TRUE)
  
  # First build
  generate_dashboard(dashboard, render = FALSE, incremental = TRUE)
  
  # Force full rebuild
  result <- generate_dashboard(dashboard, render = FALSE, incremental = FALSE)
  
  # Should regenerate everything
  expect_true(is.null(result$build_info$skipped) || length(result$build_info$skipped) == 0)
})

test_that("incremental build handles new pages", {
  output_dir <- tempfile()
  
  # First build with one page
  dashboard1 <- create_dashboard(
    title = "Test",
    output_dir = output_dir
  ) %>%
    add_page("Page1", text = "Content 1", is_landing_page = TRUE)
  
  generate_dashboard(dashboard1, render = FALSE, incremental = TRUE)
  
  # Add new page
  dashboard2 <- create_dashboard(
    title = "Test",
    output_dir = output_dir
  ) %>%
    add_page("Page1", text = "Content 1", is_landing_page = TRUE) %>%
    add_page("Page2", text = "Content 2")
  
  result <- generate_dashboard(dashboard2, render = FALSE, incremental = TRUE)
  
  expect_true("Page2" %in% result$build_info$regenerated)
  expect_true("Page1" %in% result$build_info$skipped || "Page1" %in% result$build_info$regenerated)
})

test_that("incremental build handles deleted pages", {
  output_dir <- tempfile()
  
  # First build with two pages
  dashboard1 <- create_dashboard(
    title = "Test",
    output_dir = output_dir
  ) %>%
    add_page("Page1", text = "Content 1", is_landing_page = TRUE) %>%
    add_page("Page2", text = "Content 2")
  
  generate_dashboard(dashboard1, render = FALSE, incremental = TRUE)
  
  # Remove page
  dashboard2 <- create_dashboard(
    title = "Test",
    output_dir = output_dir
  ) %>%
    add_page("Page1", text = "Content 1", is_landing_page = TRUE)
  
  result <- generate_dashboard(dashboard2, render = FALSE, incremental = TRUE)
  
  # Page2 QMD should be deleted
  page2_file <- file.path(output_dir, "page2.qmd")
  expect_false(file.exists(page2_file))
})

test_that("incremental build stores build manifest", {
  dashboard <- create_dashboard(
    title = "Test",
    output_dir = tempfile()
  ) %>%
    add_page("Page1", text = "Content", is_landing_page = TRUE)
  
  generate_dashboard(dashboard, render = FALSE, incremental = TRUE)
  
  # Check manifest exists
  manifest_file <- file.path(dashboard$output_dir, ".dashboardr_manifest.rds")
  expect_true(file.exists(manifest_file))
  
  # Read and validate manifest
  manifest <- readRDS(manifest_file)
  expect_true("pages" %in% names(manifest))
  expect_true("timestamp" %in% names(manifest))
})

test_that("incremental build handles missing manifest gracefully", {
  dashboard <- create_dashboard(
    title = "Test",
    output_dir = tempfile()
  ) %>%
    add_page("Page1", text = "Content", is_landing_page = TRUE)
  
  # First build without manifest (should create it)
  result <- generate_dashboard(dashboard, render = FALSE, incremental = TRUE)
  
  # Should regenerate all pages
  expect_true(length(result$build_info$regenerated) > 0)
})

test_that("incremental builds skip Quarto rendering when nothing changed", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  
  dashboard <- create_dashboard(
    "test_render_skip",
    "Test",
    output_dir = temp_dir
  ) %>%
    add_page("Home", text = "Test", is_landing_page = TRUE)
  
  # First build
  result1 <- generate_dashboard(dashboard, render = FALSE, incremental = TRUE)
  expect_equal(length(result1$build_info$regenerated), 1)
  
  # Second build - should skip everything
  result2 <- generate_dashboard(dashboard, render = FALSE, incremental = TRUE)
  
  expect_equal(length(result2$build_info$skipped), 1)
  expect_equal(length(result2$build_info$regenerated), 0)
})

