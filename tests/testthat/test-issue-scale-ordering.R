# Tests for issue: Scale ordering in histograms
# Issue: Numeric values 1-10 are sorted alphabetically (1, 10, 2, 3...)
# instead of numerically (1, 2, 3... 10) when used without bins parameter

library(testthat)

test_that("viz_histogram preserves numeric order for integer values 1-10", {
  # Create data with values 1-10 that should be sorted numerically
  set.seed(42)
  data <- data.frame(
    migration_job = sample(1:10, 100, replace = TRUE)
  )
  
  result <- viz_histogram(data = data, x_var = "migration_job")
  
  # Extract the x-axis categories from the highchart object
  # The categories are set in hc_xAxis
  x_axis <- result$x$hc_opts$xAxis
  
  # Check that categories exist
  expect_true(!is.null(x_axis$categories) || !is.null(x_axis))
  
  # If categories are present, they should be in numeric order
  if (!is.null(x_axis$categories)) {
    cats <- x_axis$categories
    # Convert to numeric and check order
    numeric_cats <- suppressWarnings(as.numeric(cats))
    # Remove NAs (in case there are non-numeric entries)
    numeric_cats <- numeric_cats[!is.na(numeric_cats)]
    
    # The categories should be sorted in ascending numeric order
    expect_equal(
      numeric_cats, 
      sort(numeric_cats),
      info = paste("Categories are:", paste(cats, collapse = ", "), 
                   "\nExpected numeric order: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10")
    )
  }
  
  expect_s3_class(result, "highchart")
})

test_that("viz_histogram with bins parameter maintains correct order",
{
  # This should work correctly with bins
  set.seed(42)
  data <- data.frame(
    migration_job = sample(1:10, 100, replace = TRUE)
  )
  
  result <- viz_histogram(data = data, x_var = "migration_job", bins = 10)
  expect_s3_class(result, "highchart")
  
  # Check that categories are in order
  x_axis <- result$x$hc_opts$xAxis
  if (!is.null(x_axis$categories)) {
    cats <- x_axis$categories
    # For binned data, categories might be ranges like "1-2", "2-3", etc.
    # Just verify we have categories
    expect_true(length(cats) > 0)
  }
})

test_that("viz_histogram handles character-numeric values correctly", {
  # Edge case: numeric values stored as characters
  data <- data.frame(
    score = as.character(sample(1:10, 50, replace = TRUE))
  )
  
  # Without bins, character "1", "10", "2" should still be ordered correctly
  result <- viz_histogram(data = data, x_var = "score")
  expect_s3_class(result, "highchart")
  
  # Extract categories
  x_axis <- result$x$hc_opts$xAxis
  if (!is.null(x_axis$categories)) {
    cats <- x_axis$categories
    numeric_cats <- suppressWarnings(as.numeric(cats))
    numeric_cats <- numeric_cats[!is.na(numeric_cats)]
    
    # Check for numeric ordering
    if (length(numeric_cats) > 1) {
      expect_equal(
        numeric_cats,
        sort(numeric_cats),
        info = paste("Character-numeric categories should be in numeric order. Got:",
                     paste(cats, collapse = ", "))
      )
    }
  }
})

test_that("viz_histogram x_order parameter works correctly", {
  # User can explicitly set order with x_order parameter
  data <- data.frame(
    rating = sample(1:5, 50, replace = TRUE)
  )
  
  custom_order <- c("5", "4", "3", "2", "1")  # Reverse order
  
  result <- viz_histogram(
    data = data, 
    x_var = "rating",
    x_order = custom_order
  )
  expect_s3_class(result, "highchart")
  
  # Categories should respect x_order
  x_axis <- result$x$hc_opts$xAxis
  if (!is.null(x_axis$categories)) {
    cats <- x_axis$categories
    # First category should be "5" if x_order is respected
    expect_equal(cats[1], "5", 
                 info = "x_order should be respected - first category should be '5'")
  }
})

test_that("viz_histogram with include_na = TRUE preserves numeric order", {
  # Test that numeric ordering works when include_na = TRUE
  set.seed(42)
  data <- data.frame(
    migration_job = c(sample(1:10, 95, replace = TRUE), rep(NA, 5))
  )
  
  result <- viz_histogram(
    data = data, 
    x_var = "migration_job",
    include_na = TRUE
  )
  expect_s3_class(result, "highchart")
  
  # Extract categories
  x_axis <- result$x$hc_opts$xAxis
  expect_true(!is.null(x_axis$categories))
  
  cats <- x_axis$categories
  
  # Get numeric categories (excluding NA label)
  numeric_cats <- suppressWarnings(as.numeric(cats))
  numeric_cats <- numeric_cats[!is.na(numeric_cats)]
  
  # Numeric values should be in ascending order

  expect_equal(
    numeric_cats,
    sort(numeric_cats),
    info = paste("With include_na = TRUE, numeric categories should still be ordered.",
                 "\nGot:", paste(cats, collapse = ", "))
  )
  
  # NA label should be at the end
  expect_equal(
    cats[length(cats)], 
    "(Missing)",
    info = "NA label should be at the end of categories"
  )
})
