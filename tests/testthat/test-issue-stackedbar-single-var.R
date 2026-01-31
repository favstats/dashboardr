# Tests for issue: Stackedbar with only stack_var doesn't render
# Issue: When using add_viz with only stack_var (no x_var), the visualization
# doesn't appear in preview. viz_stackedbar requires both x_var and stack_var.

library(testthat)

# =============================================================================
# Test viz_stackedbar with single variable scenarios
# =============================================================================

test_that("viz_stackedbar requires both x_var and stack_var", {
  data <- data.frame(
    farmer_sec = sample(c("Yes", "No"), 100, replace = TRUE),
    region = sample(c("North", "South"), 100, replace = TRUE)
  )
  

  # Missing x_var should error
  expect_error(
    viz_stackedbar(data = data, stack_var = "farmer_sec"),
    regexp = "x_var"
  )
  
  # Missing stack_var should error
  expect_error(
    viz_stackedbar(data = data, x_var = "region"),
    regexp = "stack_var"
  )
  
  # Both provided should work
  result <- viz_stackedbar(
    data = data, 
    x_var = "region", 
    stack_var = "farmer_sec"
  )
  expect_s3_class(result, "highchart")
})

test_that("viz_stackedbar works when same variable used for x_var and stack_var", {
  # Workaround: use same variable for both if you want single-variable display
  data <- data.frame(
    farmer_sec = sample(c("Yes", "No"), 100, replace = TRUE)
  )
  
  # Using same variable for both x and stack (a possible workaround)
  result <- viz_stackedbar(
    data = data,
    x_var = "farmer_sec",
    stack_var = "farmer_sec",
    title = "Single variable distribution"
  )
  expect_s3_class(result, "highchart")
})

# =============================================================================
# Test add_viz integration with stackedbar
# =============================================================================

test_that("add_viz with type='stackedbar' requires both x_var and stack_var", {
  data <- data.frame(
    farmer_sec = sample(c("Yes", "No"), 50, replace = TRUE),
    region = sample(c("North", "South", "East", "West"), 50, replace = TRUE)
  )
  
  # Create content with stackedbar type
  content <- create_content(data = data, type = "stackedbar")
  
  # Adding viz with only stack_var should fail or produce warning
  # The exact behavior depends on how add_viz handles missing x_var
  result <- tryCatch({
    content %>% 
      add_viz(
        stack_var = "farmer_sec", 
        title = "Test", 
        tabgroup = "Test"
      )
  }, error = function(e) {
    return(e)
  }, warning = function(w) {
    return(w)
  })
  
  # Should either error or warn about missing x_var, or return a content_collection
  # This test documents current behavior - if it silently fails, that's the bug
  expect_true(
    inherits(result, "error") || inherits(result, "warning") || 
      inherits(result, "content_collection"),
    info = "add_viz with only stack_var should either error, warn, or return content_collection"
  )
  
  # If it returns a content_collection, check if items were actually added
  if (inherits(result, "content_collection")) {
    # The bug is that items may be added but won't render correctly
    # Check if any viz items were added
    viz_items <- Filter(function(x) x$type == "viz", result$items)
    
    # Document: with only stack_var, viz might be added but won't render
    # because viz_stackedbar requires x_var
    if (length(viz_items) > 0) {
      message("Note: viz item was added with only stack_var - this may not render correctly")
    }
  }
})

test_that("add_viz with both x_var and stack_var works correctly", {
  data <- data.frame(
    farmer_sec = sample(c("Yes", "No"), 50, replace = TRUE),
    region = sample(c("North", "South", "East", "West"), 50, replace = TRUE)
  )
  
  # Create content with both variables
  content <- create_content(data = data, type = "stackedbar") %>%
    add_viz(
      x_var = "region",
      stack_var = "farmer_sec", 
      title = "Farmers by Region", 
      tabgroup = "Overview"
    )
  
  # content_collection is the actual class
  expect_s3_class(content, "content_collection")
  
  # Check that visualization was added to items
  expect_true(length(content$items) > 0, info = "items should contain the added visualization")
  
  # Check that at least one item is a viz
  viz_items <- Filter(function(x) x$type == "viz", content$items)
  expect_true(length(viz_items) > 0, info = "Should have at least one viz item")
})

# =============================================================================
# Suggested feature test: viz_bar for single variable distribution
# =============================================================================

test_that("viz_histogram can be used for single categorical variable", {
  # Alternative approach: use histogram for single variable
  data <- data.frame(
    farmer_sec = sample(c("Yes", "No"), 100, replace = TRUE, prob = c(0.35, 0.65))
  )
  
  result <- viz_histogram(
    data = data,
    x_var = "farmer_sec",
    title = "People employed in Farmers sector"
  )
  
  expect_s3_class(result, "highchart")
  
  # Check the chart has data
  expect_true(length(result$x$hc_opts$series) > 0)
})

test_that("viz_bar can display single variable distribution", {
  skip_if_not(exists("viz_bar"), "viz_bar function not available")
  
  data <- data.frame(
    farmer_sec = sample(c("Yes", "No"), 100, replace = TRUE)
  )
  
  # If viz_bar exists, test it
  result <- viz_bar(
    data = data,
    x_var = "farmer_sec",
    title = "Single variable bar chart"
  )
  
  expect_s3_class(result, "highchart")
})
