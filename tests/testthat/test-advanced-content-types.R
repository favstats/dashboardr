# Comprehensive tests for all advanced content types
# Following TEST-DRIVEN DEVELOPMENT

library(testthat)
library(dashboardr)

test_that("add_callout creates proper content block", {
  content <- create_content() %>%
    add_callout("This is important", type = "important", title = "Alert")
  
  expect_equal(length(content$items), 1)
  
  block <- content$items[[1]]
  expect_s3_class(block, "content_block")
  expect_equal(block$type, "callout")
  expect_equal(block$callout_type, "important")
  expect_equal(block$content, "This is important")
  expect_equal(block$title, "Alert")
})

test_that("add_callout supports all callout types", {
  types <- c("note", "tip", "warning", "caution", "important")
  
  for (callout_type in types) {
    content <- create_content() %>%
      add_callout("Test", type = callout_type)
    
    expect_equal(content$items[[1]]$callout_type, callout_type)
  }
})

test_that("add_divider creates proper content block", {
  content <- create_content() %>%
    add_divider()
  
  expect_equal(length(content$items), 1)
  
  block <- content$items[[1]]
  expect_s3_class(block, "content_block")
  expect_equal(block$type, "divider")
})

test_that("add_divider supports style parameter", {
  styles <- c("default", "thick", "dashed", "dotted")
  
  for (style in styles) {
    content <- create_content() %>%
      add_divider(style = style)
    
    expect_equal(content$items[[1]]$style, style)
  }
})

test_that("add_code creates proper content block", {
  content <- create_content() %>%
    add_code("print('hello')", language = "r")
  
  expect_equal(length(content$items), 1)
  
  block <- content$items[[1]]
  expect_s3_class(block, "content_block")
  expect_equal(block$type, "code")
  expect_equal(block$code, "print('hello')")
  expect_equal(block$language, "r")
})

test_that("add_card creates proper content block", {
  content <- create_content() %>%
    add_card("Card content", title = "Card Title")
  
  expect_equal(length(content$items), 1)
  
  block <- content$items[[1]]
  expect_s3_class(block, "content_block")
  expect_equal(block$type, "card")
  expect_equal(block$text, "Card content")
  expect_equal(block$title, "Card Title")
})

test_that("add_accordion creates proper content block", {
  content <- create_content() %>%
    add_accordion("Section Title", "Content here")
  
  expect_equal(length(content$items), 1)
  
  block <- content$items[[1]]
  expect_s3_class(block, "content_block")
  expect_equal(block$type, "accordion")
  expect_equal(block$title, "Section Title")
  expect_equal(block$text, "Content here")
})

test_that("add_spacer creates proper content block", {
  content <- create_content() %>%
    add_spacer(height = "3rem")
  
  expect_equal(length(content$items), 1)
  
  block <- content$items[[1]]
  expect_s3_class(block, "content_block")
  expect_equal(block$type, "spacer")
  expect_equal(block$height, "3rem")
})

test_that("add_iframe creates proper content block", {
  content <- create_content() %>%
    add_iframe("https://example.com", height = "400px")
  
  expect_equal(length(content$items), 1)
  
  block <- content$items[[1]]
  expect_s3_class(block, "content_block")
  expect_equal(block$type, "iframe")
  expect_equal(block$url, "https://example.com")
  expect_equal(block$height, "400px")
})

test_that("add_video creates proper content block", {
  content <- create_content() %>%
    add_video("https://youtube.com/watch?v=12345")
  
  expect_equal(length(content$items), 1)
  
  block <- content$items[[1]]
  expect_s3_class(block, "content_block")
  expect_equal(block$type, "video")
  expect_equal(block$url, "https://youtube.com/watch?v=12345")
})

test_that("add_table creates proper content block", {
  content <- create_content() %>%
    add_table(mtcars)
  
  expect_equal(length(content$items), 1)
  
  block <- content$items[[1]]
  expect_s3_class(block, "content_block")
  expect_equal(block$type, "table")
  expect_true(!is.null(block$table_object))
})

test_that("multiple content types can be chained", {
  content <- create_content() %>%
    add_text("# Heading") %>%
    add_callout("Important note", type = "important") %>%
    add_divider(style = "thick") %>%
    add_code("x <- 1", language = "r") %>%
    add_spacer(height = "2rem") %>%
    add_card("Card text", title = "Title") %>%
    add_accordion("Details", "Hidden content") %>%
    add_iframe("https://example.com") %>%
    add_video("https://youtube.com/watch?v=xyz")
  
  expect_equal(length(content$items), 9)
  
  # Check each item has content_block class
  for (i in 1:9) {
    expect_s3_class(content$items[[i]], "content_block")
  }
  
  # Check types
  expect_equal(content$items[[1]]$type, "text")
  expect_equal(content$items[[2]]$type, "callout")
  expect_equal(content$items[[3]]$type, "divider")
  expect_equal(content$items[[4]]$type, "code")
  expect_equal(content$items[[5]]$type, "spacer")
  expect_equal(content$items[[6]]$type, "card")
  expect_equal(content$items[[7]]$type, "accordion")
  expect_equal(content$items[[8]]$type, "iframe")
  expect_equal(content$items[[9]]$type, "video")
})

test_that("content types are rendered in page generation", {
  proj <- create_dashboard("test", output_dir = tempdir())
  
  test_content <- create_content() %>%
    add_callout("Test callout", type = "note", title = "Note") %>%
    add_divider(style = "thick") %>%
    add_code("print('test')", language = "r") %>%
    add_spacer(height = "2rem")
  
  proj <- add_page(proj, "Test", content = test_content)
  
  # Check content blocks were added
  expect_equal(length(proj$pages[[1]]$content_blocks), 4)
  
  # Generate without rendering
  generate_dashboard(proj, render = FALSE)
  
  # Read generated QMD
  qmd_path <- file.path(tempdir(), "test.qmd")
  expect_true(file.exists(qmd_path))
  
  qmd_content <- paste(readLines(qmd_path), collapse = "\n")
  
  # Check for rendered content
  expect_true(grepl("::: \\{.callout-note\\}", qmd_content, fixed = FALSE))
  expect_true(grepl("## Note", qmd_content, fixed = TRUE))
  expect_true(grepl("Test callout", qmd_content, fixed = TRUE))
  expect_true(grepl("<hr style=", qmd_content, fixed = TRUE))
  expect_true(grepl("```r", qmd_content, fixed = TRUE))
  expect_true(grepl("print\\('test'\\)", qmd_content, fixed = FALSE))
  expect_true(grepl("height: 2rem", qmd_content, fixed = TRUE))
})

test_that("iframe renders correctly in QMD", {
  proj <- create_dashboard("test_iframe", output_dir = tempdir())
  
  test_content <- create_content() %>%
    add_iframe("https://example.com", height = "400px", width = "100%")
  
  proj <- add_page(proj, "Test", content = test_content)
  generate_dashboard(proj, render = FALSE)
  
  qmd_path <- file.path(tempdir(), "test.qmd")
  qmd_content <- paste(readLines(qmd_path), collapse = "\n")
  
  # Check iframe tag is present
  expect_true(grepl("<iframe", qmd_content, fixed = TRUE))
  expect_true(grepl("https://example.com", qmd_content, fixed = TRUE))
  expect_true(grepl("height: 400px", qmd_content, fixed = TRUE))
  expect_true(grepl("width: 100%", qmd_content, fixed = TRUE))
})

test_that("video (YouTube) renders correctly in QMD", {
  proj <- create_dashboard("test_video", output_dir = tempdir())
  
  test_content <- create_content() %>%
    add_video("https://youtube.com/watch?v=dQw4w9WgXcQ")
  
  proj <- add_page(proj, "Test", content = test_content)
  generate_dashboard(proj, render = FALSE)
  
  qmd_path <- file.path(tempdir(), "test.qmd")
  qmd_content <- paste(readLines(qmd_path), collapse = "\n")
  
  # Check YouTube embed using Quarto video shortcode
  expect_true(grepl("youtube.com/embed/dQw4w9WgXcQ", qmd_content, fixed = TRUE))
  expect_true(grepl("{{< video", qmd_content, fixed = TRUE))
})

test_that("table (data.frame) renders correctly in QMD", {
  proj <- create_dashboard("test_table", output_dir = tempdir())
  
  test_content <- create_content() %>%
    add_table(head(mtcars, 3), caption = "Test table")
  
  proj <- add_page(proj, "Test", content = test_content)
  generate_dashboard(proj, render = FALSE)
  
  qmd_path <- file.path(tempdir(), "test.qmd")
  qmd_content <- paste(readLines(qmd_path), collapse = "\n")
  
  # Check for knitr::kable output
  expect_true(grepl("knitr::kable", qmd_content, fixed = TRUE))
  expect_true(grepl("Test table", qmd_content, fixed = TRUE))
})

test_that("add_DT creates DT content block", {
  content <- create_content() %>%
    add_DT(mtcars)
  
  expect_equal(length(content$items), 1)
  
  block <- content$items[[1]]
  expect_s3_class(block, "content_block")
  expect_equal(block$type, "DT")
  expect_true(!is.null(block$table_data))
})

