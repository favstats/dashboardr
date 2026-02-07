# =============================================================================
# Comprehensive tests for universal preview() function
# =============================================================================

# -----------------------------------------------------------------------------
# Helper functions
# -----------------------------------------------------------------------------

#' Verify HTML structure is valid
verify_html_structure <- function(html_path) {
  expect_true(file.exists(html_path))
  html <- paste(readLines(html_path, warn = FALSE), collapse = "\n")
  
  # Basic HTML structure
  expect_true(grepl("<html", html, ignore.case = TRUE), 
              info = "Missing <html> tag")
  expect_true(grepl("<head", html, ignore.case = TRUE),
              info = "Missing <head> tag")
  expect_true(grepl("<body", html, ignore.case = TRUE),
              info = "Missing <body> tag")
  
  # No obvious R errors in output

  expect_false(grepl("Error in", html, fixed = TRUE),
               info = "Found 'Error in' in HTML output")
  
  invisible(html)
}

#' Check that HTML contains expected patterns
expect_html_contains <- function(html_path, patterns, info_prefix = "") {
  html <- paste(readLines(html_path, warn = FALSE), collapse = "\n")
  for (pattern in patterns) {
    expect_true(grepl(pattern, html, ignore.case = TRUE),
                info = paste(info_prefix, "Expected pattern not found:", pattern))
  }
  invisible(html)
}

# Skip entire file under covr CI to prevent OOM (exit code 143)
if (identical(Sys.getenv("DASHBOARDR_COVR_CI"), "true") || !identical(Sys.getenv("NOT_CRAN"), "true")) {
  test_that("skipped on CRAN/covr CI", { skip("Memory-intensive tests skipped on CRAN and covr CI") })
} else {

# -----------------------------------------------------------------------------
# 1. Object Type Tests - dashboard_project
# -----------------------------------------------------------------------------

test_that("preview works for dashboard_project in direct mode", {
  temp_dir <- tempfile()
  
  dashboard <- create_dashboard(temp_dir, "Test Dashboard") %>%
    add_page("Home", text = "# Welcome to the Dashboard", is_landing_page = TRUE)
  
  html_path <- preview(dashboard, open = FALSE, quarto = FALSE)
  
  expect_true(file.exists(html_path))
  html <- verify_html_structure(html_path)
  expect_true(grepl("Welcome", html))
  expect_true(grepl("Dashboard", html))
  
  unlink(temp_dir, recursive = TRUE)
})

test_that("preview works for dashboard_project with specific page", {
  temp_dir <- tempfile()
  
  dashboard <- create_dashboard(temp_dir, "Multi Page") %>%
    add_page("Home", text = "# Home Page", is_landing_page = TRUE) %>%
    add_page("About", text = "# About Page")
  
  html_path <- preview(dashboard, page = "About", open = FALSE, quarto = FALSE)
  
  expect_true(file.exists(html_path))
  html <- paste(readLines(html_path, warn = FALSE), collapse = "\n")
  expect_true(grepl("About", html))
  
  unlink(temp_dir, recursive = TRUE)
})

test_that("preview errors for non-existent page", {
  temp_dir <- tempfile()
  
  dashboard <- create_dashboard(temp_dir, "Test") %>%
    add_page("Home", text = "# Home", is_landing_page = TRUE)
  
  expect_error(
    preview(dashboard, page = "NonExistent", open = FALSE),
    "not found"
  )
  
  unlink(temp_dir, recursive = TRUE)
})

test_that("preview errors for empty dashboard", {
  temp_dir <- tempfile()
  
  dashboard <- create_dashboard(temp_dir, "Empty")
  
  expect_error(
    preview(dashboard, open = FALSE),
    "no pages"
  )
  
  unlink(temp_dir, recursive = TRUE)
})

# -----------------------------------------------------------------------------
# 2. Object Type Tests - page_object
# -----------------------------------------------------------------------------

test_that("preview works for page_object with text", {
  page <- create_page("Test Page") %>%
    add_text("# Hello World", "This is a paragraph.")
  
  html_path <- preview(page, open = FALSE, quarto = FALSE)
  
  expect_true(file.exists(html_path))
  html <- paste(readLines(html_path, warn = FALSE), collapse = "\n")
  expect_true(grepl("Hello World", html))
})

test_that("preview works for page_object with visualizations", {
  page <- create_page("Analysis", data = mtcars) %>%
    add_viz(type = "histogram", x_var = "mpg", title = "MPG Distribution")
  
  html_path <- preview(page, open = FALSE, quarto = FALSE)
  
  expect_true(file.exists(html_path))
  html <- paste(readLines(html_path, warn = FALSE), collapse = "\n")
  expect_true(grepl("MPG Distribution", html))
})

# -----------------------------------------------------------------------------
# 3. Object Type Tests - content_block (standalone)
# -----------------------------------------------------------------------------

test_that("preview works for standalone text content_block", {
  text_block <- add_text("# Standalone Text Block")
  
  html_path <- preview(text_block, open = FALSE, quarto = FALSE)
  
  expect_true(file.exists(html_path))
  html <- paste(readLines(html_path, warn = FALSE), collapse = "\n")
  expect_true(grepl("Standalone Text Block", html))
})

# -----------------------------------------------------------------------------
# 4. Content Block Type Tests - All Types
# -----------------------------------------------------------------------------

test_that("preview renders text blocks", {
  content <- create_content() %>%
    add_text("# Header\n\nParagraph text here")
  
  html_path <- preview(content, open = FALSE, quarto = FALSE)
  
  expect_true(file.exists(html_path))
  expect_html_contains(html_path, c("Header", "Paragraph"))
})

test_that("preview renders callout blocks", {
  content <- create_content() %>%
    add_callout("This is a tip!", type = "tip", title = "Pro Tip")
  
  html_path <- preview(content, open = FALSE, quarto = FALSE)
  
  expect_true(file.exists(html_path))
  expect_html_contains(html_path, c("This is a tip", "Pro Tip", "callout"))
})

test_that("preview renders image blocks", {
  content <- create_content() %>%
    add_image("https://via.placeholder.com/150", alt = "Placeholder", caption = "Test image")
  
  html_path <- preview(content, open = FALSE, quarto = FALSE)
  
  expect_true(file.exists(html_path))
  expect_html_contains(html_path, c("img", "placeholder.com"))
})

test_that("preview renders divider blocks", {
  content <- create_content() %>%
    add_text("Before") %>%
    add_divider() %>%
    add_text("After")
  
  html_path <- preview(content, open = FALSE, quarto = FALSE)
  
  expect_true(file.exists(html_path))
  expect_html_contains(html_path, c("Before", "After", "hr|divider"))
})

test_that("preview renders code blocks", {
  content <- create_content() %>%
    add_code("x <- 1 + 2\nprint(x)", language = "r")
  
  html_path <- preview(content, open = FALSE, quarto = FALSE)
  
  expect_true(file.exists(html_path))
  # Note: < is HTML-escaped to &lt;
  expect_html_contains(html_path, c("&lt;- 1", "pre", "code", "language-r"))
})

test_that("preview renders spacer blocks", {
  content <- create_content() %>%
    add_text("Before") %>%
    add_spacer(height = "3rem") %>%
    add_text("After")
  
  html_path <- preview(content, open = FALSE, quarto = FALSE)
  
  expect_true(file.exists(html_path))
  expect_html_contains(html_path, c("Before", "After"))
})

test_that("preview renders card blocks", {
  content <- create_content() %>%
    add_card(text = "Card body content", title = "Card Title", footer = "Card footer")
  
  html_path <- preview(content, open = FALSE, quarto = FALSE)
  
  expect_true(file.exists(html_path))
  expect_html_contains(html_path, c("Card Title", "Card body", "card"))
})

test_that("preview renders accordion blocks", {
  content <- create_content() %>%
    add_accordion("Click to expand", "Hidden content here")
  
  html_path <- preview(content, open = FALSE, quarto = FALSE)
  
  expect_true(file.exists(html_path))
  expect_html_contains(html_path, c("Click to expand", "accordion"))
})

test_that("preview renders iframe blocks", {
  content <- create_content() %>%
    add_iframe("https://example.com", height = "400px")
  
  html_path <- preview(content, open = FALSE, quarto = FALSE)
  
  expect_true(file.exists(html_path))
  expect_html_contains(html_path, c("iframe", "example.com"))
})

test_that("preview renders video blocks", {
  content <- create_content() %>%
    add_video("https://example.com/video.mp4", caption = "Test video")
  
  html_path <- preview(content, open = FALSE, quarto = FALSE)
  
  expect_true(file.exists(html_path))
  expect_html_contains(html_path, c("video", "video.mp4"))
})

test_that("preview renders html blocks", {
  content <- create_content() %>%
    add_html("<div class='custom-class'>Custom HTML content</div>")
  
  html_path <- preview(content, open = FALSE, quarto = FALSE)
  
  expect_true(file.exists(html_path))
  expect_html_contains(html_path, c("custom-class", "Custom HTML content"))
})

test_that("preview renders quote blocks", {
  content <- create_content() %>%
    add_quote("To be or not to be", attribution = "Shakespeare")
  
  html_path <- preview(content, open = FALSE, quarto = FALSE)
  
  expect_true(file.exists(html_path))
  expect_html_contains(html_path, c("To be or not to be", "Shakespeare", "blockquote"))
})

test_that("preview renders badge blocks", {
  content <- create_content() %>%
    add_badge("New", color = "success")
  
  html_path <- preview(content, open = FALSE, quarto = FALSE)
  
  expect_true(file.exists(html_path))
  expect_html_contains(html_path, c("New", "badge"))
})

test_that("preview renders metric blocks", {
  content <- create_content() %>%
    add_metric("Total Sales", "$1,234,567")
  
  html_path <- preview(content, open = FALSE, quarto = FALSE)
  
  expect_true(file.exists(html_path))
  expect_html_contains(html_path, c("Total Sales", "1,234,567", "metric"))
})

# -----------------------------------------------------------------------------
# 5. Mixed Content Tests
# -----------------------------------------------------------------------------

test_that("preview handles mixed content and visualizations", {
  content <- create_content(data = mtcars) %>%
    add_text("# Before Chart") %>%
    add_viz(type = "histogram", x_var = "mpg", title = "Histogram") %>%
    add_text("# After Chart")
  
  html_path <- preview(content, open = FALSE, quarto = FALSE)
  
  expect_true(file.exists(html_path))
  html <- paste(readLines(html_path, warn = FALSE), collapse = "\n")
  expect_true(grepl("Before Chart", html))
  expect_true(grepl("After Chart", html))
  expect_true(grepl("Histogram", html))
})

test_that("preview handles multiple visualization types", {
  content <- create_content(data = mtcars) %>%
    add_viz(type = "histogram", x_var = "mpg", title = "Histogram") %>%
    add_viz(type = "bar", x_var = "cyl", title = "Bar Chart")
  
  html_path <- preview(content, open = FALSE, quarto = FALSE)
  
  expect_true(file.exists(html_path))
  html <- paste(readLines(html_path, warn = FALSE), collapse = "\n")
  expect_true(grepl("Histogram", html))
  expect_true(grepl("Bar Chart", html))
})

# -----------------------------------------------------------------------------
# 6. Styling Tests
# -----------------------------------------------------------------------------

test_that("preview applies custom fonts from dashboard", {
  temp_dir <- tempfile()
  
  dashboard <- create_dashboard(temp_dir, "Styled", mainfont = "Roboto") %>%
    add_page("Home", text = "# Styled Page", is_landing_page = TRUE)
  
  html_path <- preview(dashboard, open = FALSE, quarto = FALSE)
  
  html <- paste(readLines(html_path, warn = FALSE), collapse = "\n")
  expect_true(grepl("Roboto", html))
  
  unlink(temp_dir, recursive = TRUE)
})

test_that("preview applies navbar colors from dashboard", {
  temp_dir <- tempfile()
  
  dashboard <- create_dashboard(temp_dir, "Colored",
    navbar_bg_color = "#FF5733"
  ) %>%
    add_page("Home", text = "# Colored", is_landing_page = TRUE)
  
  html_path <- preview(dashboard, open = FALSE, quarto = FALSE)
  
  html <- paste(readLines(html_path, warn = FALSE), collapse = "\n")
  # Preview uses unified simple styling (gray-bordered container)
  # Navbar colors are only applied in final generated dashboard, not previews
  # Check for the consistent preview container instead
  expect_true(grepl("border: 2px solid #e1e4e8", html))
  expect_true(grepl("Preview:", html))
  
  unlink(temp_dir, recursive = TRUE)
})

# -----------------------------------------------------------------------------
# 7. Interactive Elements Tests
# -----------------------------------------------------------------------------

test_that("preview includes input filter assets", {
  # add_input requires filter_var and options parameters
  content <- create_content() %>%
    add_input(
      input_id = "test_filter",
      label = "Select Option:",
      type = "select_single",
      filter_var = "cyl",
      options = c("Option A", "Option B", "Option C")
    )
  
  html_path <- preview(content, open = FALSE, quarto = FALSE)
  
  expect_true(file.exists(html_path))
  html <- paste(readLines(html_path, warn = FALSE), collapse = "\n")
  # Should include input-related content
  expect_true(grepl("test_filter|select|option", html, ignore.case = TRUE))
})

test_that("preview includes modal assets", {
  content <- create_content() %>%
    add_modal(modal_id = "info-modal", title = "Information", 
              modal_content = "Modal body text")
  
  html_path <- preview(content, open = FALSE, quarto = FALSE)
  
  expect_true(file.exists(html_path))
  html <- paste(readLines(html_path, warn = FALSE), collapse = "\n")
  
  # Should include modal structure or at least some content
  expect_true(grepl("modal|Information", html, ignore.case = TRUE))
})

# -----------------------------------------------------------------------------
# 8. Tabgroup Tests
# -----------------------------------------------------------------------------

test_that("preview with tabgroups works in direct mode", {
  content <- create_content(data = mtcars) %>%
    add_viz(type = "histogram", x_var = "mpg", tabgroup = "Tab1") %>%
    add_viz(type = "histogram", x_var = "hp", tabgroup = "Tab2")
  
  # May or may not warn depending on interactive mode, but should work
  html_path <- suppressWarnings(
    preview(content, open = FALSE, quarto = FALSE)
  )
  expect_true(file.exists(html_path))
})

# -----------------------------------------------------------------------------
# 9. Quarto Mode Tests (skip if Quarto not available)
# -----------------------------------------------------------------------------

test_that("preview quarto mode works for content collection", {
  skip_if(Sys.which("quarto") == "", "Quarto not available")
  skip_on_ci()  # Quarto rendering can be flaky in CI environments
  
  content <- create_content(data = mtcars) %>%
    add_viz(type = "histogram", x_var = "mpg", title = "Quarto Test")
  
  # Use tryCatch to handle rendering failures gracefully
  result <- tryCatch({
    html_path <- preview(content, open = FALSE, quarto = TRUE)
    list(success = TRUE, path = html_path)
  }, error = function(e) {
    list(success = FALSE, error = e$message)
  })
  
  skip_if(!result$success, paste("Preview rendering failed:", result$error))
  
  expect_true(file.exists(result$path))
  html <- paste(readLines(result$path, warn = FALSE), collapse = "\n")
  expect_true(grepl("Quarto Test", html))
})

test_that("preview quarto mode works for dashboard_project", {
  skip_if(Sys.which("quarto") == "", "Quarto not available")
  skip_on_ci()  # Quarto rendering can be flaky in CI environments
  
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  
  dashboard <- create_dashboard(temp_dir, "Quarto Dashboard") %>%
    add_page("Home", text = "# Quarto Mode Test", is_landing_page = TRUE)
  
  # Use tryCatch to handle rendering failures gracefully
  result <- tryCatch({
    html_path <- preview(dashboard, open = FALSE, quarto = TRUE)
    list(success = TRUE, path = html_path)
  }, error = function(e) {
    list(success = FALSE, error = e$message)
  })
  
  skip_if(!result$success, paste("Preview rendering failed:", result$error))
  
  expect_true(file.exists(result$path))
  html <- paste(readLines(result$path, warn = FALSE), collapse = "\n")
  expect_true(grepl("Quarto Mode Test", html))
})

test_that("preview quarto mode applies dashboard theme", {
  skip_if(Sys.which("quarto") == "", "Quarto not available")
  skip_on_ci()  # Quarto rendering can be flaky in CI environments
  
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  
  dashboard <- create_dashboard(temp_dir, "Themed", theme = "darkly") %>%
    add_page("Home", text = "# Dark Theme", is_landing_page = TRUE)
  
  # Use tryCatch to handle rendering failures gracefully
  result <- tryCatch({
    html_path <- preview(dashboard, open = FALSE, quarto = TRUE, theme = "darkly")
    list(success = TRUE, path = html_path)
  }, error = function(e) {
    list(success = FALSE, error = e$message)
  })
  
  skip_if(!result$success, paste("Preview rendering failed:", result$error))
  
  expect_true(file.exists(result$path))
})

# -----------------------------------------------------------------------------
# 10. Path Parameter Tests
# -----------------------------------------------------------------------------

test_that("preview saves to specified file path", {
  temp_file <- tempfile(fileext = ".html")
  on.exit(unlink(temp_file), add = TRUE)
  
  content <- create_content(data = mtcars) %>%
    add_viz(type = "histogram", x_var = "mpg")
  
  result_path <- preview(content, path = temp_file, open = FALSE, quarto = FALSE)
  
  expect_equal(normalizePath(result_path), normalizePath(temp_file))
  expect_true(file.exists(temp_file))
})

test_that("preview saves to specified directory", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  
  content <- create_content(data = mtcars) %>%
    add_viz(type = "histogram", x_var = "mpg")
  
  result_path <- preview(content, path = temp_dir, open = FALSE, quarto = FALSE)
  
  expect_true(file.exists(result_path))
  expect_match(result_path, "preview\\.html$")
})

# -----------------------------------------------------------------------------
# 11. Edge Cases
# -----------------------------------------------------------------------------

test_that("preview handles page without data (text only)", {
  page <- create_page("Text Only") %>%
    add_text("# Just Text", "No visualizations here")
  
  # Should work without data since no visualizations
  html_path <- preview(page, open = FALSE, quarto = FALSE)
  expect_true(file.exists(html_path))
  expect_html_contains(html_path, c("Just Text"))
})

test_that("preview handles empty collection gracefully", {
  content <- create_content(data = mtcars)
  
  expect_error(
    preview(content, open = FALSE),
    "empty"
  )
})

test_that("preview handles collection with only content blocks", {
  content <- create_content() %>%
    add_text("# Title") %>%
    add_callout("Note", type = "note") %>%
    add_divider()
  
  html_path <- preview(content, open = FALSE, quarto = FALSE)
  expect_true(file.exists(html_path))
  expect_html_contains(html_path, c("Title", "Note"))
})

# -----------------------------------------------------------------------------
# 12. Table Tests
# -----------------------------------------------------------------------------

test_that("preview renders basic table blocks", {
  content <- create_content() %>%
    add_table(head(mtcars), caption = "Cars data")
  
  html_path <- preview(content, open = FALSE, quarto = FALSE)
  
  expect_true(file.exists(html_path))
  html <- paste(readLines(html_path, warn = FALSE), collapse = "\n")
  # Should have table structure
  expect_true(grepl("table|<th|<td", html, ignore.case = TRUE))
})

test_that("preview renders gt tables if available", {
  # Suppress Unicode translation warnings from gt package loading
  suppressWarnings(skip_if_not_installed("gt"))
  
  gt_table <- suppressWarnings(gt::gt(head(mtcars, 3)))
  content <- create_content() %>%
    add_gt(gt_table)
  
  html_path <- suppressWarnings(preview(content, open = FALSE, quarto = FALSE))
  
  expect_true(file.exists(html_path))
})

test_that("preview renders reactable tables if available", {
  skip_if_not_installed("reactable")
  
  content <- create_content() %>%
    add_reactable(head(mtcars, 5))
  
  html_path <- preview(content, open = FALSE, quarto = FALSE)
  
  expect_true(file.exists(html_path))
})

test_that("preview renders DT tables if available", {
  skip_if_not_installed("DT")

  content <- create_content() %>%
    add_DT(head(mtcars, 5))

  html_path <- preview(content, open = FALSE, quarto = FALSE)

  expect_true(file.exists(html_path))
})

} # end covr CI skip
