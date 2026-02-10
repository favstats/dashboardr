# Tests for tutorial_dashboard
library(testthat)

# Skip on CRAN
skip_on_cran()

test_that("tutorial_dashboard creates a directory", {
  output_dir <- tempfile("tutorial_test")
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

  result <- suppressWarnings(suppressMessages(
    tutorial_dashboard(directory = output_dir, open = FALSE)
  ))

  expect_true(dir.exists(output_dir))
})

test_that("tutorial_dashboard returns a dashboard_project", {
  output_dir <- tempfile("tutorial_struct")
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

  result <- suppressWarnings(suppressMessages(
    tutorial_dashboard(directory = output_dir, open = FALSE)
  ))

  expect_s3_class(result, "dashboard_project")
  # Should have pages

  expect_true(length(result$pages) > 0)
})

test_that("tutorial_dashboard can be generated without error", {
  output_dir <- tempfile("tutorial_gen")
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

  result <- suppressWarnings(suppressMessages(
    tutorial_dashboard(directory = output_dir, open = FALSE)
  ))

  expect_no_error(suppressWarnings(suppressMessages(
    generate_dashboard(result, render = FALSE, quiet = TRUE)
  )))

  # Should create QMD files
  qmd_files <- list.files(output_dir, pattern = "\\.qmd$")
  expect_true(length(qmd_files) > 0)
})

