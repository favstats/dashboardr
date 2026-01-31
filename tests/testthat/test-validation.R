# Tests for visualization spec validation system

test_that("validate_specs returns TRUE for valid collection", {
  viz <- create_viz(data = mtcars) %>%
    add_viz(type = "histogram", x_var = "mpg") %>%
    add_viz(type = "scatter", x_var = "wt", y_var = "mpg")
  
  result <- validate_specs(viz, verbose = FALSE)
  expect_true(result)
})

test_that("validate_specs detects missing required params for stackedbar", {
  viz <- create_viz(data = mtcars) %>%
    add_viz(type = "stackedbar", x_var = "cyl")  # Missing stack_var
  
  result <- validate_specs(viz, verbose = FALSE)
  expect_false(result)
  
  issues <- attr(result, "issues")
  expect_true(length(issues) > 0)
  
  # Should mention stack_var is required
  issue_text <- paste(unlist(issues), collapse = " ")
  expect_true(grepl("stack_var", issue_text))
})

test_that("validate_specs detects missing required params for scatter", {
  viz <- create_viz(data = mtcars) %>%
    add_viz(type = "scatter", x_var = "wt")  # Missing y_var
  
  result <- validate_specs(viz, verbose = FALSE)
  expect_false(result)
  
  issues <- attr(result, "issues")
  issue_text <- paste(unlist(issues), collapse = " ")
  expect_true(grepl("y_var", issue_text))
})

test_that("validate_specs detects missing required params for heatmap", {
  viz <- create_viz(data = mtcars) %>%
    add_viz(type = "heatmap", x_var = "cyl", y_var = "gear")  # Missing value_var
  
  result <- validate_specs(viz, verbose = FALSE)
  expect_false(result)
  
  issues <- attr(result, "issues")
  issue_text <- paste(unlist(issues), collapse = " ")
  expect_true(grepl("value_var", issue_text))
})

test_that("validate_specs detects missing required params for timeline", {
  viz <- create_viz(data = mtcars) %>%
    add_viz(type = "timeline", time_var = "cyl")  # Missing y_var
  
  result <- validate_specs(viz, verbose = FALSE)
  expect_false(result)
  
  issues <- attr(result, "issues")
  issue_text <- paste(unlist(issues), collapse = " ")
  expect_true(grepl("y_var", issue_text))
})

test_that("validate_specs detects missing required params for treemap", {
  viz <- create_viz(data = mtcars) %>%
    add_viz(type = "treemap", group_var = "cyl")  # Missing value_var
  
  result <- validate_specs(viz, verbose = FALSE)
  expect_false(result)
  
  issues <- attr(result, "issues")
  issue_text <- paste(unlist(issues), collapse = " ")
  expect_true(grepl("value_var", issue_text))
})

test_that("validate_specs detects invalid column names", {
  viz <- create_viz(data = mtcars) %>%
    add_viz(type = "histogram", x_var = "nonexistent_column")
  
  result <- validate_specs(viz, verbose = FALSE)
  expect_false(result)
  
  issues <- attr(result, "issues")
  issue_text <- paste(unlist(issues), collapse = " ")
  expect_true(grepl("not found in data", issue_text))
})

test_that("validate_specs suggests similar column names for typos", {
  viz <- create_viz(data = mtcars) %>%
    add_viz(type = "histogram", x_var = "mpgg")  # Typo for "mpg"
  
  result <- validate_specs(viz, verbose = FALSE)
  expect_false(result)
  
  issues <- attr(result, "issues")
  issue_text <- paste(unlist(issues), collapse = " ")
  expect_true(grepl("mpg", issue_text))  # Should suggest correct name
})

test_that("preview() catches validation errors early", {
  viz <- create_viz(data = mtcars) %>%
    add_viz(type = "stackedbar", x_var = "cyl")  # Missing stack_var
  
  # Should error with validation message, not cryptic quarto error
  err <- tryCatch(
    preview(viz, open = FALSE),
    error = function(e) e$message
  )
  
  # Error message indicates stack_var is required when using x_var
  expect_true(grepl("stack_var|required", err))
})

test_that("print with check = TRUE runs validation", {
  viz <- create_viz(data = mtcars) %>%
    add_viz(type = "histogram", x_var = "mpg")
  
  # Valid collection - should print without error (may produce messages)
  result <- NULL
  expect_no_error({
    result <- suppressMessages(capture.output(print(viz, check = TRUE)))
  })
  expect_true(is.character(result))
})

test_that("validate_specs handles empty collections", {
  viz <- create_viz(data = mtcars)
  
  result <- validate_specs(viz, verbose = FALSE)
  expect_true(result)  # Empty is valid (nothing to validate)
})

test_that("validate_specs handles content-only collections", {
  content <- create_content() %>%
    add_text("Hello World") %>%
    add_callout("This is a note", type = "note")
  
  result <- validate_specs(content, verbose = FALSE)
  expect_true(result)  # Content blocks don't need validation
})

test_that("validate_specs handles mixed content and viz", {
  viz <- create_viz(data = mtcars) %>%
    add_text("# Analysis") %>%
    add_viz(type = "histogram", x_var = "mpg") %>%
    add_text("Conclusion")
  
  result <- validate_specs(viz, verbose = FALSE)
  expect_true(result)
})

test_that("validate_specs validates all items and reports all issues", {
  viz <- create_viz(data = mtcars) %>%
    add_viz(type = "stackedbar", x_var = "cyl") %>%  # Missing stack_var
    add_viz(type = "scatter", x_var = "wt") %>%  # Missing y_var
    add_viz(type = "histogram", x_var = "mpg")  # Valid
  
  result <- validate_specs(viz, verbose = FALSE)
  expect_false(result)
  
  issues <- attr(result, "issues")
  # Should have issues for 2 items
  expect_equal(length(issues), 2)
})

test_that(".validate_viz_spec returns valid for unknown viz types", {
  # Unknown types are passed through - actual viz function will handle
  spec <- list(viz_type = "custom_unknown_type", x_var = "test")
  result <- dashboardr:::.validate_viz_spec(spec, data = NULL, stop_on_error = FALSE)
  expect_true(result$valid)
})

test_that("validate_specs works with page_object", {
  # Create a page object via dashboard workflow
  proj <- create_dashboard(
    title = "Test",
    output_dir = tempdir()
  ) %>% add_page(
    name = "test",
    data = mtcars,
    content = create_viz() %>% add_viz(type = "histogram", x_var = "mpg")
  )
  
  # Get the page and validate it
  page <- proj$pages[["test"]]
  result <- validate_specs(page, verbose = FALSE)
  expect_true(result)
})

test_that("validate_specs handles stackedbars x_vars validation", {
  data <- data.frame(q1 = 1:5, q2 = 1:5, q3 = 1:5)
  
  # Valid
  viz_valid <- create_viz(data = data) %>%
    add_viz(type = "stackedbars", x_vars = c("q1", "q2", "q3"))
  
  result_valid <- validate_specs(viz_valid, verbose = FALSE)
  expect_true(result_valid)
  
  # Invalid - missing column
  viz_invalid <- create_viz(data = data) %>%
    add_viz(type = "stackedbars", x_vars = c("q1", "q2", "nonexistent"))
  
  result_invalid <- validate_specs(viz_invalid, verbose = FALSE)
  expect_false(result_invalid)
})

test_that("validate_specs with verbose = TRUE prints messages", {
  viz <- create_viz(data = mtcars) %>%
    add_viz(type = "histogram", x_var = "mpg")
  
  # cli package output may go to stderr or message
  expect_message(
    validate_specs(viz, verbose = TRUE),
    regexp = "validated successfully|All.*items"
  )
})

test_that("validate_specs detects boxplot missing y_var", {
  viz <- create_viz(data = mtcars) %>%
    add_viz(type = "boxplot", x_var = "cyl")  # Missing required y_var
  
  result <- validate_specs(viz, verbose = FALSE)
  expect_false(result)
  
  issues <- attr(result, "issues")
  issue_text <- paste(unlist(issues), collapse = " ")
  expect_true(grepl("y_var", issue_text))
})

test_that("validate_specs detects density missing x_var", {
  viz <- create_viz(data = mtcars) %>%
    add_viz(type = "density", group_var = "cyl")  # Missing required x_var
  
  result <- validate_specs(viz, verbose = FALSE)
  expect_false(result)
  
  issues <- attr(result, "issues")
  issue_text <- paste(unlist(issues), collapse = " ")
  expect_true(grepl("x_var", issue_text))
})
