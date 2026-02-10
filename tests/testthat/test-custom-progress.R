test_that("custom progress display can be enabled/disabled", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  
  dashboard <- create_dashboard(
    "test_progress",
    "Progress Test",
    output_dir = temp_dir
  ) %>%
    add_dashboard_page("Home", text = "Test", is_landing_page = TRUE)
  
  # Should accept show_progress parameter
  result1 <- generate_dashboard(dashboard, render = FALSE, show_progress = TRUE)
  expect_s3_class(result1, "dashboard_project")

  result2 <- generate_dashboard(dashboard, render = FALSE, show_progress = FALSE)
  expect_s3_class(result2, "dashboard_project")
})

test_that("custom progress tracks page generation", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  
  dashboard <- create_dashboard(
    "test_progress",
    "Progress Test",
    output_dir = temp_dir
  ) %>%
    add_dashboard_page("Home", text = "Home", is_landing_page = TRUE) %>%
    add_dashboard_page("Page1", text = "P1") %>%
    add_dashboard_page("Page2", text = "P2")
  
  # Capture output
  output <- capture.output({
    result <- generate_dashboard(dashboard, render = FALSE, show_progress = TRUE)
  })
  
  # Should mention pages
  expect_true(any(grepl("Home|Page1|Page2", output)))
})

test_that("progress display shows file generation steps", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  
  test_data <- data.frame(x = 1:10)
  viz <- create_viz() %>%
    add_viz(type = "histogram", x_var = "x", title = "Test")
  
  dashboard <- create_dashboard(
    "test_progress",
    "Progress Test",
    output_dir = temp_dir
  ) %>%
    add_dashboard_page(
      "Analysis",
      data = test_data,
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  output <- capture.output({
    result <- generate_dashboard(dashboard, render = FALSE, show_progress = TRUE)
  })
  
  # Should show generation steps
  expect_true(any(grepl("Generating|Creating|Writing", output)))
})

test_that("progress display includes timing information", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  
  dashboard <- create_dashboard(
    "test_progress",
    "Progress Test",
    output_dir = temp_dir
  ) %>%
    add_dashboard_page("Home", text = "Test", is_landing_page = TRUE)
  
  output <- capture.output({
    result <- generate_dashboard(dashboard, render = FALSE, show_progress = TRUE)
  })
  
  # Should show elapsed time
  expect_true(any(grepl("ms|sec|time", output, ignore.case = TRUE)))
})

test_that("progress display works with preview mode", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  
  dashboard <- create_dashboard(
    "test_progress",
    "Progress Test",
    output_dir = temp_dir
  ) %>%
    add_dashboard_page("Home", text = "Home", is_landing_page = TRUE) %>%
    add_dashboard_page("About", text = "About")
  
  output <- capture.output({
    result <- generate_dashboard(dashboard, 
                                 preview = "About", 
                                 render = FALSE,
                                 show_progress = TRUE)
  })
  
  # Should indicate preview mode
  expect_true(any(grepl("Preview|About", output)))
})

test_that("progress display works with incremental builds", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  
  dashboard <- create_dashboard(
    "test_progress",
    "Progress Test",
    output_dir = temp_dir
  ) %>%
    add_dashboard_page("Home", text = "Test", is_landing_page = TRUE)
  
  # First build
  generate_dashboard(dashboard, render = FALSE, incremental = TRUE, show_progress = FALSE)
  
  # Second build with progress
  output <- capture.output({
    result <- generate_dashboard(dashboard, 
                                 render = FALSE, 
                                 incremental = TRUE,
                                 show_progress = TRUE)
  })
  
  # Should show skipped info
  expect_true(any(grepl("Skipped|unchanged", output, ignore.case = TRUE)))
})

test_that("progress display has visual elements", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  
  dashboard <- create_dashboard(
    "test_progress",
    "Progress Test",
    output_dir = temp_dir
  ) %>%
    add_dashboard_page("Home", text = "Test", is_landing_page = TRUE)
  
  output <- capture.output({
    result <- generate_dashboard(dashboard, render = FALSE, show_progress = TRUE)
  })
  
  output_text <- paste(output, collapse = "\n")
  
  # Should have visual elements (emojis, boxes, etc.)
  # Check for any common progress indicators
  has_visual <- grepl("✓|✔|▪|●|○|█|▓|░|—|─|┃|║|│", output_text) ||
                grepl("\\[|\\]|\\(|\\)", output_text)
  
  expect_true(has_visual)
})

test_that("quiet mode suppresses all output", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  
  dashboard <- create_dashboard(
    "test_progress",
    "Progress Test",
    output_dir = temp_dir
  ) %>%
    add_dashboard_page("Home", text = "Test", is_landing_page = TRUE)
  
  output <- capture.output({
    result <- generate_dashboard(dashboard, 
                                 render = FALSE, 
                                 show_progress = FALSE,
                                 quiet = TRUE)
  }, type = "message")
  
  # Should have minimal or no output
  expect_true(length(output) < 5)
})

