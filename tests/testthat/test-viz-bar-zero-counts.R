# Tests for viz_bar zero counts handling with complete_groups parameter
# Issue: When using viz_bar() with group_var, if a group has 0 counts for a category,
# the bars would "shift" and become misaligned. Fixed by adding complete_groups parameter.

library(testthat)

# =============================================================================
# Test complete_groups = TRUE (default) fills missing combinations with zeros
# =============================================================================

test_that("viz_bar with group_var handles zero counts correctly (default complete_groups = TRUE)", {
  # Create data where "Group A" has no observations for category "C"
  data <- data.frame(
    category = c("A", "A", "B", "B", "C"),
    group = c("Group A", "Group B", "Group A", "Group B", "Group B")
  )
  
  # Group A has: A=1, B=1, C=0 (missing)
  # Group B has: A=1, B=1, C=1
  
  result <- viz_bar(
    data = data,
    x_var = "category",
    group_var = "group"
  )
  
  expect_s3_class(result, "highchart")
  
  # Check that we have 2 series (one per group)
  expect_equal(length(result$x$hc_opts$series), 2)
  
  # Each series should have 3 data points (one per category)
  # This is the key test - with complete_groups = TRUE, missing combinations are filled with 0
  for (series in result$x$hc_opts$series) {
    expect_equal(length(series$data), 3, 
                 info = paste("Series", series$name, "should have 3 data points"))
  }
})

test_that("viz_bar with complete_groups = TRUE fills zeros for missing group-category combinations", {
  # Explicit test with known zero combination
  data <- data.frame(
    x = c("Cat1", "Cat1", "Cat2"),
    g = c("G1", "G2", "G1")
    # G2 has no observations for Cat2
  )
  
  result <- viz_bar(
    data = data,
    x_var = "x",
    group_var = "g",
    complete_groups = TRUE
  )
  
  expect_s3_class(result, "highchart")
  
  # Both series should have 2 data points
  for (series in result$x$hc_opts$series) {
    expect_equal(length(series$data), 2)
  }
  
  # Find G2 series and check it has a 0 for Cat2
  g2_series <- result$x$hc_opts$series[[which(sapply(result$x$hc_opts$series, function(s) s$name == "G2"))]]
  # The second value (Cat2) should be 0
  expect_equal(g2_series$data[[2]], 0)
})

# =============================================================================
# Test complete_groups = FALSE preserves sparse data
# =============================================================================

test_that("viz_bar with complete_groups = FALSE shows only observed combinations", {
  data <- data.frame(
    category = c("A", "A", "B", "B", "C"),
    group = c("Group A", "Group B", "Group A", "Group B", "Group B")
  )
  
  result <- viz_bar(
    data = data,
    x_var = "category",
    group_var = "group",
    complete_groups = FALSE
  )
  
  expect_s3_class(result, "highchart")
  
  # Find Group A series
  group_a_series <- result$x$hc_opts$series[[which(sapply(result$x$hc_opts$series, function(s) s$name == "Group A"))]]
  
  # Group A should have 2 data points (A and B only, not C)
  expect_equal(length(group_a_series$data), 2,
               info = "With complete_groups = FALSE, Group A should only have 2 data points")
})

# =============================================================================
# Test complete_groups works with bar_type = "percent"
# =============================================================================

test_that("viz_bar complete_groups works with bar_type = 'percent'", {
  data <- data.frame(
    category = c("A", "A", "B"),
    group = c("G1", "G2", "G1")
    # G2 has no observations for B
  )
  
  result <- viz_bar(
    data = data,
    x_var = "category",
    group_var = "group",
    bar_type = "percent",
    complete_groups = TRUE
  )
  
  expect_s3_class(result, "highchart")
  
  # Both series should have 2 data points
  for (series in result$x$hc_opts$series) {
    expect_equal(length(series$data), 2)
  }
})

# =============================================================================
# Test complete_groups works with weight_var
# =============================================================================

test_that("viz_bar complete_groups works with weight_var", {
  data <- data.frame(
    category = c("A", "A", "B"),
    group = c("G1", "G2", "G1"),
    weight = c(1.5, 2.0, 1.0)
    # G2 has no observations for B
  )
  
  result <- viz_bar(
    data = data,
    x_var = "category",
    group_var = "group",
    weight_var = "weight",
    complete_groups = TRUE
  )
  
  expect_s3_class(result, "highchart")
  
  # Both series should have 2 data points
  for (series in result$x$hc_opts$series) {
    expect_equal(length(series$data), 2)
  }
})

# =============================================================================
# Test complete_groups with custom x_order and group_order
# =============================================================================

test_that("viz_bar complete_groups respects custom ordering", {
  data <- data.frame(
    category = c("Z", "A", "M"),
    group = c("G1", "G2", "G1")
    # G2 has no observations for Z and M
  )
  
  result <- viz_bar(
    data = data,
    x_var = "category",
    group_var = "group",
    x_order = c("A", "M", "Z"),
    group_order = c("G2", "G1"),
    complete_groups = TRUE
  )
  
  expect_s3_class(result, "highchart")
  
  # Check x-axis categories are in correct order
  expect_equal(result$x$hc_opts$xAxis$categories, c("A", "M", "Z"))
  
  # Both series should have 3 data points
  for (series in result$x$hc_opts$series) {
    expect_equal(length(series$data), 3)
  }
})

# =============================================================================
# Test complete_groups with value_var (mean mode)
# =============================================================================

test_that("viz_bar complete_groups works with value_var (mean aggregation)", {
  data <- data.frame(
    category = c("A", "A", "B", "B"),
    group = c("G1", "G2", "G1", "G1"),
    score = c(10, 20, 15, 25)
    # G2 has no observations for B
  )
  
  result <- viz_bar(
    data = data,
    x_var = "category",
    group_var = "group",
    value_var = "score",
    complete_groups = TRUE
  )
  
  expect_s3_class(result, "highchart")
  
  # Both series should have 2 data points (checking only non-errorbar series)
  for (series in result$x$hc_opts$series) {
    series_type <- series$type %||% "column"
    if (series_type != "errorbar") {
      expect_equal(length(series$data), 2)
    }
  }
})

# =============================================================================
# Test that simple bars (no group_var) are not affected by complete_groups
# =============================================================================

test_that("viz_bar without group_var is not affected by complete_groups", {
  data <- data.frame(
    category = c("A", "B", "A", "C")
  )
  
  result1 <- viz_bar(
    data = data,
    x_var = "category",
    complete_groups = TRUE
  )
  
  result2 <- viz_bar(
    data = data,
    x_var = "category",
    complete_groups = FALSE
  )
  
  # Both should produce the same result (3 categories)
  expect_equal(
    length(result1$x$hc_opts$series[[1]]$data),
    length(result2$x$hc_opts$series[[1]]$data)
  )
})

# =============================================================================
# Integration test with add_viz
# =============================================================================

test_that("complete_groups works through add_viz pipeline", {
  data <- data.frame(
    category = c("A", "A", "B"),
    group = c("G1", "G2", "G1")
  )
  
  viz <- create_viz(
    type = "bar",
    x_var = "category",
    group_var = "group",
    complete_groups = TRUE
  ) %>%
    add_viz(title = "Test Chart")
  
  expect_true(viz$items[[1]]$complete_groups)
  expect_equal(viz$items[[1]]$viz_type, "bar")
})

test_that("complete_groups = FALSE can be passed through add_viz", {
  viz <- create_viz(
    type = "bar",
    x_var = "category",
    group_var = "group",
    complete_groups = FALSE
  ) %>%
    add_viz(title = "Sparse Chart")
  
  expect_false(viz$items[[1]]$complete_groups)
})
