# Tests for print methods - just ensure they don't error
library(testthat)

test_that("print.viz_collection doesn't error", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value"
  ) %>%
    add_viz(title = "Chart 1") %>%
    add_viz(title = "Chart 2")
  
  output <- capture.output(print(viz))
  expect_true(length(output) > 0)
})

test_that("print.viz_collection works with tabgroups", {
  viz <- create_viz(
    type = "stackedbar",
    x_var = "question",
    stack_var = "response"
  ) %>%
    add_viz(title = "Item 1", tabgroup = "demographics/age/item1") %>%
    add_viz(title = "Item 2", tabgroup = "demographics/gender/item2")
  
  output <- capture.output(print(viz))
  expect_true(length(output) > 0)
})

test_that("print.viz_collection works with combine_viz", {
  viz1 <- create_viz(type = "histogram", x_var = "value") %>%
    add_viz(title = "Chart 1")
  
  viz2 <- create_viz(type = "timeline", time_var = "year", y_var = "score") %>%
    add_viz(title = "Chart 2")
  
  combined <- combine_viz(viz1, viz2)
  
  output <- capture.output(print(combined))
  expect_true(length(output) > 0)
})

test_that("print.dashboard_project doesn't error", {
  dashboard <- create_dashboard(
    output_dir = tempfile("print_test"),
    title = "Test Dashboard"
  ) %>%
    add_page("Home", text = "Welcome", is_landing_page = TRUE)
  
  output <- capture.output(print(dashboard))
  expect_true(length(output) > 0)
})

test_that("print.dashboard_project works with visualizations", {
  viz <- create_viz(type = "histogram", x_var = "value") %>%
    add_viz(title = "Chart")
  
  dashboard <- create_dashboard(
    output_dir = tempfile("viz_test"),
    title = "Dashboard"
  ) %>%
    add_page(
      "Analysis",
      data = data.frame(value = rnorm(100)),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  output <- capture.output(print(dashboard))
  expect_true(length(output) > 0)
})
