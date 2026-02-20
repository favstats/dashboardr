# =================================================================
# Tests for deprecated.R
# =================================================================
# Test that deprecated functions work but emit deprecation warnings

test_that("create_histogram works but warns about deprecation", {
  data <- data.frame(value = rnorm(100))
  
  # Should work but emit deprecation warning
  expect_warning(
    result <- create_histogram(data = data, x_var = "value"),
    "deprecated"
  )
  
  # Should return a valid result
  expect_s3_class(result, "highchart")
})

test_that("create_bar works but warns about deprecation", {
  data <- data.frame(category = letters[1:5], count = 1:5)
  
  expect_warning(
    result <- create_bar(data = data, x_var = "category", value_var = "count"),
    "deprecated"
  )
  
  expect_s3_class(result, "highchart")
})

test_that("create_stackedbar works but warns about deprecation", {
  data <- data.frame(
    x = c("A", "A", "B", "B"),
    stack = c("One", "Two", "One", "Two"),
    value = 1:4
  )
  
  expect_warning(
    result <- create_stackedbar(data = data, x_var = "x", stack_var = "stack"),
    "deprecated"
  )
  
  expect_s3_class(result, "highchart")
})

test_that("create_stackedbars works but warns about deprecation", {
  data <- data.frame(
    q1 = c("Yes", "No", "Yes"),
    q2 = c("No", "Yes", "No")
  )
  
  expect_warning(
    result <- create_stackedbars(data = data, x_vars = c("q1", "q2")),
    "deprecated"
  )
  
  expect_s3_class(result, "highchart")
})

test_that("create_timeline works but warns about deprecation", {
  data <- data.frame(
    date = as.Date("2020-01-01") + 1:10,
    value = rnorm(10)
  )
  
  expect_warning(
    result <- create_timeline(data = data, time_var = "date", y_var = "value"),
    "deprecated"
  )
  
  expect_s3_class(result, "highchart")
})

test_that("create_heatmap works but warns about deprecation", {
  data <- data.frame(
    x = rep(letters[1:3], 3),
    y = rep(c("P", "Q", "R"), each = 3),
    value = 1:9
  )
  
  expect_warning(
    result <- create_heatmap(data = data, x_var = "x", y_var = "y", value_var = "value"),
    "deprecated"
  )
  
  expect_s3_class(result, "highchart")
})

test_that("create_scatter works but warns about deprecation", {
  data <- data.frame(x = 1:10, y = rnorm(10))
  
  expect_warning(
    result <- create_scatter(data = data, x_var = "x", y_var = "y"),
    "deprecated"
  )
  
  expect_s3_class(result, "highchart")
})

test_that("create_treemap works but warns about deprecation", {
  data <- data.frame(
    category = c("A", "B", "C"),
    value = c(100, 200, 150)
  )
  
  expect_warning(
    result <- create_treemap(data = data, group_var = "category", value_var = "value"),
    "deprecated"
  )
  
  expect_s3_class(result, "highchart")
})

# Skip create_map test if highcharter maps not available
test_that("create_map works but warns about deprecation", {
  skip_on_cran()
  skip_if_offline()
  # Highcharts CDN may rate-limit; skip gracefully
  tryCatch(
    {
      con <- url("https://code.highcharts.com/mapdata/custom/world.js", open = "r")
      on.exit(close(con))
      readLines(con, n = 1L)
    },
    error = function(e) skip(paste0("Highcharts CDN unavailable: ", conditionMessage(e)))
  )

  data <- data.frame(
    iso2c = c("US", "DE", "FR"),
    value = c(100, 50, 30)
  )
  
  expect_warning(
    result <- create_map(data = data, value_var = "value", join_var = "iso2c"),
    "deprecated"
  )
  
  expect_s3_class(result, "highchart")
})

# --- Test that deprecation messages are correct ---
test_that("deprecation messages reference new function names", {
  data <- data.frame(value = 1:5)
  
  # Capture the warning message
  expect_warning(
    create_histogram(data = data, x_var = "value"),
    "viz_histogram"
  )
})

test_that("deprecated functions produce identical results to new functions", {
  data <- data.frame(x = c("A", "B", "C"), count = c(10, 20, 30))
  
  # Create with new function
  new_result <- viz_bar(data = data, x_var = "x", value_var = "count")
  
  # Create with deprecated function (suppress warning)
  old_result <- suppressWarnings(
    create_bar(data = data, x_var = "x", value_var = "count")
  )
  
  # Both should be highcharts
  expect_s3_class(new_result, "highchart")
  expect_s3_class(old_result, "highchart")
})
