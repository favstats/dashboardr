library(testthat)

test_that("plotly stackedbar filter rebuild handles horizontal orientation", {
  asset_path <- system.file("assets", "input_filter.js", package = "dashboardr")
  if (!nzchar(asset_path)) {
    # Fallback for devtools::test() (not installed)
    asset_path <- testthat::test_path("..", "..", "inst", "assets", "input_filter.js")
  }
  expect_true(file.exists(asset_path))

  js <- paste(readLines(asset_path, warn = FALSE), collapse = "\n")

  expect_match(js, "const isHorizontal = data\\.some\\(t => t && t\\.orientation === 'h'\\);", perl = TRUE)
  expect_match(js, "if \\(isHorizontal\\) \\{\\s*trace\\.y = orderedX;\\s*trace\\.x = values;", perl = TRUE)
  expect_match(js, "layout\\.yaxis\\.categoryarray = orderedX;", perl = TRUE)
})
