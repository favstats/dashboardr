# Tests for helper functions
library(testthat)

# ===================================================================
# md_text
# ===================================================================

test_that("md_text creates text output", {
  result <- md_text("# Header", "Some text", "More text")
  
  # Just check it produces output without error
  expect_true(length(result) > 0)
})

test_that("md_text with single line", {
  result <- md_text("Single line of text")
  
  expect_true(length(result) > 0)
})

test_that("md_text with multiple lines", {
  result <- md_text(
    "Line 1",
    "Line 2",
    "Line 3"
  )
  
  expect_true(length(result) > 0)
})

# ===================================================================
# text_lines
# ===================================================================

test_that("text_lines creates text output", {
  result <- text_lines("Text content")
  
  expect_true(length(result) > 0)
})

test_that("text_lines with vector input", {
  result <- text_lines(c("Line 1", "Line 2"))
  
  expect_true(length(result) > 0)
})

# ===================================================================
# create_blockquote
# ===================================================================

test_that("create_blockquote creates HTML", {
  result <- create_blockquote("Quote text")
  
  expect_s3_class(result, "html")
})

test_that("create_blockquote with preset", {
  result <- create_blockquote("Important", preset = "warning")
  
  expect_s3_class(result, "html")
})

test_that("create_blockquote with custom styles", {
  result <- create_blockquote(
    "Custom",
    text_color = "#FF0000",
    border_width = "3px"
  )
  
  expect_s3_class(result, "html")
})

# ===================================================================
# card and card_row
# ===================================================================

test_that("card creates card structure", {
  result <- card(content = "Card content")
  
  expect_s3_class(result, "shiny.tag")
})

test_that("card with title", {
  result <- card(content = "Content", title = "Card Title")
  
  expect_s3_class(result, "shiny.tag")
})

test_that("card with image", {
  result <- card(
    content = "Card with image",
    image = "path/to/image.jpg",
    image_alt = "Alt text"
  )
  
  expect_s3_class(result, "shiny.tag")
})

test_that("card_row creates row structure", {
  card1 <- card(content = "Card 1")
  card2 <- card(content = "Card 2")
  
  result <- card_row(card1, card2)
  
  expect_s3_class(result, "shiny.tag")
})

test_that("card_row with single card", {
  card1 <- card(content = "Single")
  
  result <- card_row(card1)
  
  expect_s3_class(result, "shiny.tag")
})

# ===================================================================
# spec_viz
# ===================================================================

test_that("spec_viz creates visualization spec", {
  result <- spec_viz(
    type = "histogram",
    x_var = "value",
    title = "Test"
  )
  
  expect_type(result, "list")
  expect_equal(result$type, "histogram")
  expect_equal(result$x_var, "value")
  expect_equal(result$title, "Test")
})

test_that("spec_viz with multiple parameters", {
  result <- spec_viz(
    type = "stackedbar",
    x_var = "question",
    stack_var = "response",
    horizontal = TRUE,
    stacked_type = "percent"
  )
  
  expect_type(result, "list")
  expect_equal(result$type, "stackedbar")
  expect_true(result$horizontal)
  expect_equal(result$stacked_type, "percent")
})

test_that("spec_viz preserves NULL values", {
  result <- spec_viz(
    type = "histogram",
    x_var = "value",
    bins = NULL
  )
  
  expect_type(result, "list")
  expect_null(result$bins)
})

