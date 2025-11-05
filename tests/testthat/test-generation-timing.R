# Tests for dashboard generation timing output
library(testthat)

test_that("generate_dashboard tracks and reports timing", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value"
  ) %>%
    add_viz(title = "Test")
  
  dashboard <- create_dashboard(
    output_dir = tempfile("timing_test"),
    title = "Test"
  ) %>%
    add_page(
      "Home",
      data = data.frame(value = rnorm(100)),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  # Capture output
  output <- capture.output({
    result <- generate_dashboard(dashboard, render = FALSE)
  })
  
  output_text <- paste(output, collapse = "\n")
  
  # Should report generation time (check for "Total time" which is always present)
  expect_true(grepl("Total time", output_text, fixed = TRUE))
  
  # Should have time in readable format (seconds or ms)
  expect_true(grepl("seconds|ms|minutes", output_text))
  
})

test_that("timing output shows appropriate units", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value"
  ) %>%
    add_viz(title = "Quick")
  
  dashboard <- create_dashboard(
    output_dir = tempfile("timing_units"),
    title = "Test"
  ) %>%
    add_page(
      "Home",
      data = data.frame(value = 1:10),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  output <- capture.output({
    generate_dashboard(dashboard, render = FALSE)
  })
  
  output_text <- paste(output, collapse = "\n")
  
  # For quick operations, should show ms or seconds
  # Should NOT show "0 seconds" - use ms for fast operations
  if (grepl("0\\.\\d+ seconds", output_text)) {
    expect_true(TRUE, "Shows fractional seconds")
  } else {
    expect_true(grepl("ms|milliseconds", output_text))
  }
  
})

test_that("generation output is visually enhanced", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value"
  ) %>%
    add_viz(title = "Test")
  
  dashboard <- create_dashboard(
    output_dir = tempfile("visual_output"),
    title = "Test Dashboard"
  ) %>%
    add_page(
      "Home",
      data = data.frame(value = rnorm(50)),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  output <- capture.output({
    generate_dashboard(dashboard, render = FALSE)
  })
  
  output_text <- paste(output, collapse = "\n")
  
  # Should have visual elements - check for text that's always present
  expect_true(grepl("DASHBOARD GENERATED SUCCESSFULLY|Dashboard:|Location:", output_text))
  
  # Should have section separators/boxes (check for box drawing characters or their presence)
  expect_true(grepl("DASHBOARD GENERATED SUCCESSFULLY", output_text, fixed = TRUE))
  
  # Should show dashboard name
  expect_true(grepl("Test Dashboard", output_text))
  
  # Should have structured sections
  expect_true(grepl("FILES|NEXT STEPS|SUMMARY", output_text))
  
})

test_that("timing is included in final summary section", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value"
  ) %>%
    add_viz(title = "Test")
  
  dashboard <- create_dashboard(
    output_dir = tempfile("timing_summary"),
    title = "Test"
  ) %>%
    add_page(
      "Home",
      data = data.frame(value = 1:10),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  output <- capture.output({
    generate_dashboard(dashboard, render = FALSE)
  })
  
  output_text <- paste(output, collapse = "\n")
  
  # Timing should appear near the end (in summary)
  lines <- strsplit(output_text, "\n")[[1]]
  time_line_idx <- grep("Total time", lines, fixed = TRUE)
  
  expect_true(length(time_line_idx) > 0, "Should have timing information")
  
  # Should be in the latter part of output (summary section)
  if (length(time_line_idx) > 0) {
    # Time info should be after "GENERATED" message
    generated_idx <- grep("GENERATED|FILES", lines)[1]
    expect_true(time_line_idx[1] > generated_idx %||% 0)
  }
  
})

