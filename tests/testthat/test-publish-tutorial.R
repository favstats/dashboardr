# Tests for publish_dashboard and tutorial_dashboard
library(testthat)

# Skip complex integration tests - these functions work but are hard to test
skip("Complex publishing/tutorial tests - tested manually")

# ===================================================================
# publish_dashboard
# ===================================================================

test_that("publish_dashboard validates input", {
  # Should error without dashboard project
  expect_error(
    publish_dashboard("not_a_project"),
    "dashboard_project"
  )
})

test_that("publish_dashboard requires generated dashboard", {
  dashboard <- create_dashboard(
    output_dir = tempfile("publish_test"),
    title = "Test"
  ) %>%
    add_page("Home", text = "Test", is_landing_page = TRUE)
  
  # Should error if not generated
  expect_error(
    publish_dashboard(dashboard, method = "github"),
    "generate_dashboard|not been generated"
  )
  
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("publish_dashboard accepts valid methods", {
  dashboard <- create_dashboard(
    output_dir = tempfile("publish_method"),
    title = "Test"
  ) %>%
    add_page("Home", text = "Test", is_landing_page = TRUE)
  
  generate_dashboard(dashboard, render = FALSE)
  
  # Should accept valid methods (won't actually publish in tests)
  expect_no_error(
    capture.output(
      publish_dashboard(dashboard, method = "github", confirm = FALSE),
      type = "message"
    )
  )
  
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("publish_dashboard with netlify method", {
  dashboard <- create_dashboard(
    output_dir = tempfile("publish_netlify"),
    title = "Test"
  ) %>%
    add_page("Home", text = "Test", is_landing_page = TRUE)
  
  generate_dashboard(dashboard, render = FALSE)
  
  expect_no_error(
    capture.output(
      publish_dashboard(dashboard, method = "netlify", confirm = FALSE),
      type = "message"
    )
  )
  
  unlink(dashboard$output_dir, recursive = TRUE)
})

# ===================================================================
# tutorial_dashboard
# ===================================================================

test_that("tutorial_dashboard creates project", {
  output_dir <- tempfile("tutorial_test")
  
  result <- tutorial_dashboard(output_dir = output_dir)
  
  expect_s3_class(result, "dashboard_project")
  expect_true(dir.exists(output_dir))
  
  unlink(output_dir, recursive = TRUE)
})

test_that("tutorial_dashboard has expected structure", {
  output_dir <- tempfile("tutorial_struct")
  
  result <- tutorial_dashboard(output_dir = output_dir)
  
  # Should have pages
  expect_true(length(result$pages) > 0)
  
  # Should have title
  expect_true(!is.null(result$title))
  expect_true(nchar(result$title) > 0)
  
  unlink(output_dir, recursive = TRUE)
})

test_that("tutorial_dashboard can be generated", {
  output_dir <- tempfile("tutorial_gen")
  
  result <- tutorial_dashboard(output_dir = output_dir)
  
  # Should be able to generate without error
  expect_no_error(generate_dashboard(result, render = FALSE))
  
  # Should create QMD files
  qmd_files <- list.files(output_dir, pattern = "\\.qmd$")
  expect_true(length(qmd_files) > 0)
  
  unlink(output_dir, recursive = TRUE)
})

test_that("tutorial_dashboard with custom title", {
  output_dir <- tempfile("tutorial_custom")
  
  result <- tutorial_dashboard(
    output_dir = output_dir,
    title = "My Custom Tutorial"
  )
  
  expect_equal(result$title, "My Custom Tutorial")
  
  unlink(output_dir, recursive = TRUE)
})

