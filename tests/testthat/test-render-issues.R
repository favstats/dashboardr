test_that("detects remnant .rmarkdown files with helpful error", {
  # Skip if Quarto is not available (rendering won't happen, so error won't be thrown)
  skip_if(Sys.which("quarto") == "", "Quarto not available")
  
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  
  # Create a dashboard
  dashboard <- create_dashboard(
    "test_rmd",
    "Test",
    output_dir = temp_dir
  ) %>%
    add_dashboard_page("Home", text = "Test", is_landing_page = TRUE)
  
  # Generate the dashboard
  generate_dashboard(dashboard, render = FALSE)
  
  # Create a remnant .rmarkdown file
  rmarkdown_file <- file.path(temp_dir, "test.rmarkdown")
  writeLines("# Test", rmarkdown_file)
  
  # Should detect and give helpful error
  expect_error(
    generate_dashboard(dashboard, render = TRUE),
    "rmarkdown"
  )
})

test_that("open parameter is passed to render function", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  
  dashboard <- create_dashboard(
    "test_browse",
    "Test",
    output_dir = temp_dir
  ) %>%
    add_dashboard_page("Home", text = "Test", is_landing_page = TRUE)
  
  # Just verify it doesn't error with open parameter
  result <- generate_dashboard(dashboard, render = FALSE, open = "browser")
  expect_s3_class(result, "dashboard_project")
})

test_that("open parameter is respected", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  
  dashboard <- create_dashboard(
    "test_open",
    "Test",
    output_dir = temp_dir
  ) %>%
    add_dashboard_page("Home", text = "Test", is_landing_page = TRUE)
  
  # Should accept different open values
  expect_no_error(
    generate_dashboard(dashboard, render = FALSE, open = "browser")
  )
  
  expect_no_error(
    generate_dashboard(dashboard, render = FALSE, open = FALSE)
  )
  
  expect_no_error(
    generate_dashboard(dashboard, render = FALSE, open = "viewer")
  )
})

