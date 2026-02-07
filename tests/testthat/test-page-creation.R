# Test page creation functions

test_that("create_page creates a page_object", {
  page <- create_page("Test Page")
  expect_s3_class(page, "page_object")
  expect_equal(page$name, "Test Page")
})

# =========================================
# Tests for direct add_viz on pages
# =========================================

test_that("add_viz works directly on page_object", {
  page <- create_page("Test", data = mtcars, type = "bar") %>%
    add_viz(x_var = "cyl", title = "Cylinders") %>%
    add_viz(x_var = "gear", title = "Gears")
  
  expect_length(page$.items, 2)
  expect_equal(page$.items[[1]]$x_var, "cyl")
  expect_equal(page$.items[[1]]$title, "Cylinders")
  expect_equal(page$.items[[2]]$x_var, "gear")
})

test_that("page viz inherits default type from create_page", {
  page <- create_page("Test", data = mtcars, type = "histogram") %>%
    add_viz(x_var = "mpg", title = "MPG")
  
  expect_equal(page$.items[[1]]$viz_type, "histogram")
})

test_that("add_viz on page can override default type", {
  page <- create_page("Test", data = mtcars, type = "bar") %>%
    add_viz(x_var = "cyl", title = "Cylinders") %>%
    add_viz(x_var = "mpg", title = "MPG", type = "histogram")
  
  expect_equal(page$.items[[1]]$viz_type, "bar")
  expect_equal(page$.items[[2]]$viz_type, "histogram")
})

test_that("add_text works on page_object", {
  page <- create_page("Test") %>%
    add_text("# Hello", "", "World")
  
  expect_length(page$.items, 1)
  expect_equal(page$.items[[1]]$type, "text")
})

test_that("add_callout works on page_object", {
  page <- create_page("Test") %>%
    add_callout("Important note", type = "warning")
  
  expect_length(page$.items, 1)
  expect_equal(page$.items[[1]]$type, "callout")
  expect_equal(page$.items[[1]]$callout_type, "warning")
})

test_that("add_text on landing page appears in generated QMD", {
  # This test ensures page$.items (from add_text.page_object) are included in output
  output_dir <- tempfile("test_landing_text_")
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)
  
  home <- create_page("Home", is_landing_page = TRUE) %>%
    add_text("# Welcome to the Dashboard", "", 
             "This is a test landing page with custom text.")
  
  about <- create_page("About") %>%
    add_text("## About This Project", "",
             "Created for testing purposes.")
  
  dashboard <- create_dashboard(title = "Test", output_dir = output_dir) %>%
    add_pages(home, about)
  
  result <- generate_dashboard(dashboard, render = FALSE, open = FALSE)
  
  # Check landing page (index.qmd)
  index_file <- file.path(output_dir, "index.qmd")
  expect_true(file.exists(index_file), "Landing page should be generated")
  index_content <- paste(readLines(index_file), collapse = "\n")
  expect_true(grepl("Welcome to the Dashboard", index_content), 
              "Landing page should contain add_text content")
  expect_true(grepl("test landing page with custom text", index_content),
              "Landing page should contain all text lines")
  
  # Check about page
  about_file <- file.path(output_dir, "about.qmd")
  expect_true(file.exists(about_file), "About page should be generated")
  about_content <- paste(readLines(about_file), collapse = "\n")
  expect_true(grepl("About This Project", about_content),
              "About page should contain add_text content")
})

test_that("page with direct viz converts correctly to dashboard", {
  page <- create_page("Test", data = mtcars, type = "bar") %>%
    add_viz(x_var = "cyl", title = "Cylinders") %>%
    add_viz(x_var = "gear", title = "Gears")
  
  dashboard <- create_dashboard(title = "Test", output_dir = tempdir()) %>%
    add_pages(page)
  
  expect_length(dashboard$pages, 1)
})

test_that("page inherits color_palette default", {
  page <- create_page("Test", data = mtcars, type = "bar", color_palette = c("#FF0000")) %>%
    add_viz(x_var = "cyl", title = "Cylinders")
  
  expect_equal(page$.items[[1]]$color_palette, c("#FF0000"))
})

test_that("mixed content: direct viz and add_content work together", {
  viz <- create_viz(type = "histogram") %>%
    add_viz(x_var = "mpg", title = "MPG Histogram")
  
  page <- create_page("Test", data = mtcars, type = "bar") %>%
    add_viz(x_var = "cyl", title = "Cylinders") %>%
    add_content(viz)
  
  expect_length(page$.items, 1)  # Direct items
  expect_length(page$content, 1)  # External content
})

test_that("create_page accepts all parameters", {
  page <- create_page(
    "Analysis",
    data = mtcars,
    icon = "ph:chart-line",
    is_landing_page = TRUE,
    navbar_align = "right"
  )
  
  expect_equal(page$name, "Analysis")
  expect_equal(page$data, mtcars)
  expect_equal(page$icon, "ph:chart-line")
  expect_true(page$is_landing_page)
  expect_equal(page$navbar_align, "right")
})

test_that("create_page requires a name", {
  expect_error(create_page(), "'name' is required")
  expect_error(create_page(NULL), "'name' is required")
})

test_that("create_page allows empty name for pageless dashboards", {
  page <- create_page("")
  expect_equal(page$name, ".pageless")
  expect_false(page$show_in_nav)
})

test_that("add_content adds content to a page", {
  viz <- create_viz(type = "bar") %>%
    add_viz(x_var = "cyl", title = "Cylinders")
  
  page <- create_page("Test") %>%
    add_content(viz)
  
  expect_length(page$content, 1)
  expect_s3_class(page$content[[1]], "content_collection")
})

test_that("add_content can add multiple content collections", {
  viz1 <- create_viz(type = "bar") %>%
    add_viz(x_var = "cyl", title = "Cylinders")
  
  viz2 <- create_viz(type = "histogram") %>%
    add_viz(x_var = "mpg", title = "MPG")
  
  page <- create_page("Test") %>%
    add_content(viz1) %>%
    add_content(viz2)
  
  expect_length(page$content, 2)
})

test_that("add_content requires a page_object", {
  viz <- create_viz(type = "bar")
  expect_error(add_content("not a page", viz), "'page' must be a page_object")
})

test_that("add_content requires a content collection", {
  page <- create_page("Test")
  expect_error(add_content(page, "not content"), "must be a content collection")
})

test_that("add_pages adds pages to a dashboard", {
  page1 <- create_page("Home", is_landing_page = TRUE)
  page2 <- create_page("Analysis", data = mtcars)
  
  dashboard <- create_dashboard(title = "Test", output_dir = tempdir()) %>%
    add_pages(page1, page2)
  
  expect_length(dashboard$pages, 2)
  expect_equal(dashboard$pages[[1]]$name, "Home")
  expect_equal(dashboard$pages[[2]]$name, "Analysis")
})

test_that("add_pages accepts a list of pages", {
  pages <- list(
    create_page("Home", is_landing_page = TRUE),
    create_page("Analysis")
  )
  
  dashboard <- create_dashboard(title = "Test", output_dir = tempdir()) %>%
    add_pages(pages)
  
  expect_length(dashboard$pages, 2)
})

test_that("add_pages requires page_objects", {
  dashboard <- create_dashboard(title = "Test", output_dir = tempdir())
  expect_error(add_pages(dashboard, "not a page"), "must be page_objects")
})

test_that("add_page accepts page_objects directly", {
  page <- create_page("Home", is_landing_page = TRUE)
  
  dashboard <- create_dashboard(title = "Test", output_dir = tempdir()) %>%
    add_page(page)
  
  expect_length(dashboard$pages, 1)
  expect_equal(dashboard$pages[[1]]$name, "Home")
})

test_that("page with content gets properly converted", {
  viz <- create_viz(type = "bar") %>%
    add_viz(x_var = "cyl", title = "Cylinders", tabgroup = "overview")
  
  page <- create_page("Analysis", data = mtcars) %>%
    add_content(viz)
  
  dashboard <- create_dashboard(title = "Test", output_dir = tempdir()) %>%
    add_pages(page)
  
  # Page should have visualizations
  expect_length(dashboard$pages, 1)
  expect_true(!is.null(dashboard$pages[[1]]$visualizations) || 
              !is.null(dashboard$pages[[1]]$content_blocks))
})

test_that("print.page_object works", {
  page <- create_page("Test", data = mtcars, icon = "ph:chart-line")
  
  output <- capture.output(print(page))
  expect_true(any(grepl("Page:", output)))
  expect_true(any(grepl("Test", output)))
  expect_true(any(grepl("rows", output)))  # Data info shows "X rows x Y cols"
})
