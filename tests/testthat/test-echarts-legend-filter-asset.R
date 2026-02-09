library(testthat)

test_that("echarts filter asset keeps legend in sync with visible series", {
  asset_path <- testthat::test_path("..", "..", "inst", "assets", "input_filter.js")
  expect_true(file.exists(asset_path))

  js <- paste(readLines(asset_path, warn = FALSE), collapse = "\n")

  expect_match(js, "option\\.series\\s*=\\s*optionSeries\\.map\\([\\s\\S]*?return null;[\\s\\S]*?\\)\\.filter\\(Boolean\\);", perl = TRUE)
  expect_match(js, "const visibleSeries = allSeries\\.filter\\(name => !switchHidden\\.has\\(name\\) \\|\\| switchShown\\.has\\(name\\)\\);", perl = TRUE)
  expect_match(js, "syncEchartsLegend\\(option, visibleSeries\\);", perl = TRUE)
  expect_match(js, "syncEchartsLegend\\(option, visibleGroupValues\\);", perl = TRUE)
})
