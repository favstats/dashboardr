# =============================================================================
# Targeted tests for dashboard preview functionality
# Tests for knit_print.dashboard_project and related fixes
# =============================================================================

# Skip entire file under covr CI to prevent OOM (exit code 143)
if (identical(Sys.getenv("DASHBOARDR_COVR_CI"), "true") || !identical(Sys.getenv("NOT_CRAN"), "true")) {
  # skipped on CRAN/covr CI
} else {

# Helper function to render dashboard preview and extract HTML
.render_dashboard_preview_html <- function(dashboard) {
  # Capture the knit_print output
  output <- knit_print.dashboard_project(dashboard)
  
  # Convert to character
  if (inherits(output, "knit_asis")) {
    html <- as.character(output)
  } else if (inherits(output, "shiny.tag") || inherits(output, "shiny.tag.list")) {
    html <- as.character(htmltools::renderTags(output)$html)
  } else {
    html <- as.character(output)
  }
  
  html
}

# -----------------------------------------------------------------------------
# Test 1: Dashboard preview with text-only pages
# -----------------------------------------------------------------------------

test_that("dashboard preview renders text-only pages correctly", {
  temp_dir <- tempfile("dashboard_test_")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Create a dashboard with a text-only home page
  home <- create_page("Home", is_landing_page = TRUE) %>%
    add_text("# Welcome!", "This is the home page content.")
  
  my_dashboard <- create_dashboard(
    title = "Test Dashboard",
    output_dir = temp_dir,
    warn_before_overwrite = FALSE
  ) %>%
    add_pages(home)
  
  # Get the HTML output
  html <- .render_dashboard_preview_html(my_dashboard)
  
  # Should NOT show "Empty page"
  expect_false(grepl("Empty page", html), 
               info = "Home page should not show 'Empty page'")
  
  # Should contain the text content
  expect_true(grepl("Welcome", html), 
              info = "Home page should contain 'Welcome' text")
  expect_true(grepl("home page content", html),
              info = "Home page should contain the paragraph text")
})

test_that("dashboard preview renders add_text with multiple arguments", {
  temp_dir <- tempfile("dashboard_test_")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Create page with multi-argument add_text
  home <- create_page("Home", is_landing_page = TRUE) %>%
    add_text("# Header", "", "First paragraph.", "", "Second paragraph.")
  
  my_dashboard <- create_dashboard(
    title = "Test Dashboard",
    output_dir = temp_dir,
    warn_before_overwrite = FALSE
  ) %>%
    add_pages(home)
  
  html <- .render_dashboard_preview_html(my_dashboard)
  
  expect_true(grepl("Header", html))
  expect_true(grepl("First paragraph", html))
  expect_true(grepl("Second paragraph", html))
})

# -----------------------------------------------------------------------------
# Test 2: Dashboard preview with callout content
# -----------------------------------------------------------------------------

test_that("dashboard preview renders callout content", {
  temp_dir <- tempfile("dashboard_test_")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  home <- create_page("Home", is_landing_page = TRUE) %>%
    add_callout("This is an important note!", type = "note", title = "Note")
  
  my_dashboard <- create_dashboard(
    title = "Test Dashboard",
    output_dir = temp_dir,
    warn_before_overwrite = FALSE
  ) %>%
    add_pages(home)
  
  html <- .render_dashboard_preview_html(my_dashboard)
  
  expect_true(grepl("important note", html),
              info = "Callout content should be rendered")
})

# -----------------------------------------------------------------------------
# Test 3: Dashboard preview with mixed content (text + visualizations)
# -----------------------------------------------------------------------------

test_that("dashboard preview renders mixed content with text and viz", {
  temp_dir <- tempfile("dashboard_test_")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Create a content collection with text and viz
  content <- create_content(type = "bar") %>%
    add_text("## Analysis Overview") %>%
    add_viz(x_var = "cyl", title = "Cylinders")
  
  # Create a page with data and add the mixed content
  analysis <- create_page("Analysis", data = mtcars) %>%
    add_content(content)
  
  home <- create_page("Home", is_landing_page = TRUE) %>%
    add_text("# Welcome")
  
  # We need to generate the dashboard first to save data files
  my_dashboard <- create_dashboard(
    title = "Test Dashboard",
    output_dir = temp_dir,
    warn_before_overwrite = FALSE
  ) %>%
    add_pages(home, analysis)
  
  # Save the data file manually for the preview to work
  data_dir <- file.path(temp_dir, "data")
  dir.create(data_dir, showWarnings = FALSE)
  saveRDS(mtcars, file.path(temp_dir, "data_analysis.rds"))
  
  html <- .render_dashboard_preview_html(my_dashboard)
  
  # Should have tabs for both pages
  expect_true(grepl("Home", html), info = "Should have Home tab")
  expect_true(grepl("Analysis", html), info = "Should have Analysis tab")
  
  # Home page text should be present
  expect_true(grepl("Welcome", html), info = "Home content should be present")
})

# -----------------------------------------------------------------------------
# Test 4: Dashboard preview with tabbed visualizations
# -----------------------------------------------------------------------------

test_that("dashboard preview renders tabbed visualizations", {
  temp_dir <- tempfile("dashboard_test_")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Create content with tabgroups
  demographics <- create_content(type = "bar") %>%
    add_viz(x_var = "cyl", title = "Cylinders", tabgroup = "engine") %>%
    add_viz(x_var = "gear", title = "Gears", tabgroup = "transmission")
  
  analysis <- create_page("Analysis", data = mtcars) %>%
    add_content(demographics)
  
  home <- create_page("Home", is_landing_page = TRUE) %>%
    add_text("# Welcome")
  
  my_dashboard <- create_dashboard(
    title = "Test Dashboard",
    output_dir = temp_dir,
    warn_before_overwrite = FALSE
  ) %>%
    add_pages(home, analysis)
  
  # Save the data file for the preview
  saveRDS(mtcars, file.path(temp_dir, "data_analysis.rds"))
  
  html <- .render_dashboard_preview_html(my_dashboard)
  
  # Should have page tabs
  expect_true(grepl("Home", html))
  expect_true(grepl("Analysis", html))
  
  # Home should have content
  expect_true(grepl("Welcome", html))
})

# -----------------------------------------------------------------------------
# Test 5: content_block class is properly set
# -----------------------------------------------------------------------------

test_that("add_text.page_object creates content_block class items", {
  page <- create_page("Test") %>%
    add_text("Hello world")
  
  expect_equal(length(page$.items), 1)
  expect_true(inherits(page$.items[[1]], "content_block"),
              info = "Text items should have content_block class")
  expect_equal(page$.items[[1]]$type, "text")
})

test_that("add_callout.page_object creates content_block class items", {
  page <- create_page("Test") %>%
    add_callout("Important message", type = "warning")
  
  expect_equal(length(page$.items), 1)
  expect_true(inherits(page$.items[[1]], "content_block"),
              info = "Callout items should have content_block class")
  expect_equal(page$.items[[1]]$type, "callout")
})

# -----------------------------------------------------------------------------
# Test 6: Multiple pages with different content types
# -----------------------------------------------------------------------------

test_that("dashboard preview handles multiple pages with different content", {
  temp_dir <- tempfile("dashboard_test_")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Page 1: Text only
  home <- create_page("Home", is_landing_page = TRUE) %>%
    add_text("# Home Page", "Welcome to the dashboard.")
  
  # Page 2: Text + callout
  about <- create_page("About") %>%
    add_text("## About Us") %>%
    add_callout("This is a note", type = "note")
  
  my_dashboard <- create_dashboard(
    title = "Multi-Content Dashboard",
    output_dir = temp_dir,
    warn_before_overwrite = FALSE
  ) %>%
    add_pages(home, about)
  
  html <- .render_dashboard_preview_html(my_dashboard)
  
  # Both page tabs should be present
  expect_true(grepl("Home", html))
  expect_true(grepl("About", html))
  
  # Content should be present
  expect_true(grepl("Welcome", html) || grepl("Home Page", html))
})

# -----------------------------------------------------------------------------
# Test 7: Preview function works for page_object
# -----------------------------------------------------------------------------

test_that("preview works for page_object with text", {
  page <- create_page("Test Page") %>%
    add_text("# Hello World", "This is a paragraph.")
  
  html_path <- preview(page, open = FALSE, quarto = FALSE)
  
  expect_true(file.exists(html_path))
  html <- paste(readLines(html_path, warn = FALSE), collapse = "\n")
  expect_true(grepl("Hello World", html))
  expect_true(grepl("paragraph", html))
})

# -----------------------------------------------------------------------------
# Test 8: Page content items are correctly passed to dashboard
# -----------------------------------------------------------------------------

test_that("page content items flow correctly through add_pages", {
  temp_dir <- tempfile("dashboard_test_")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Create page with text
  home <- create_page("Home", is_landing_page = TRUE) %>%
    add_text("# Welcome Text")
  
  # Verify page has the item with content_block class
  expect_equal(length(home$.items), 1)
  expect_true(inherits(home$.items[[1]], "content_block"))
  
  my_dashboard <- create_dashboard(
    title = "Test",
    output_dir = temp_dir,
    warn_before_overwrite = FALSE
  ) %>%
    add_pages(home)
  
  # The dashboard should have the Home page
  expect_true("Home" %in% names(my_dashboard$pages))
  
  # The page in the dashboard should have content_blocks
  stored_page <- my_dashboard$pages[["Home"]]
  expect_true(!is.null(stored_page$content_blocks) || !is.null(stored_page$text))
})

} # end covr CI skip
