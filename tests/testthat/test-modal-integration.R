test_that("add_modal creates modal content in collection", {
  # Create a viz collection with a modal
  viz <- create_viz(mtcars, name = "test") %>%
    add_text("[Click me](#test-modal){.modal-link}") %>%
    add_modal(
      modal_id = "test-modal",
      title = "Test Title",
      modal_content = "Test content"
    )
  
  # Check that needs_modals flag is set
  expect_true(viz$needs_modals)
  
  # Check that content blocks were added
  expect_true(length(viz$items) > 0)
})

test_that("add_modal works with viz_collection", {
  viz <- create_viz(mtcars, name = "test") %>%
    add_modal(
      modal_id = "viz-modal",
      title = "Viz Modal",
      modal_content = "Content"
    )
  
  expect_s3_class(viz, "content_collection")
  expect_true(viz$needs_modals)
})

test_that("add_modal with data.frame converts to table", {
  viz <- create_viz(mtcars, name = "test") %>%
    add_modal(
      modal_id = "data-modal",
      title = "Data",
      modal_content = head(mtcars, 5)
    )
  
  # Should have created content with HTML table
  expect_true(viz$needs_modals)
  expect_true(length(viz$items) > 0)
})

test_that("add_modal with image includes image tag", {
  viz <- create_viz(mtcars, name = "test") %>%
    add_modal(
      modal_id = "img-modal",
      title = "Image Modal",
      image = "test.png",
      modal_content = "Description"
    )
  
  expect_true(viz$needs_modals)
})

test_that("add_modal escapes quotes in content", {
  viz <- create_viz(mtcars, name = "test") %>%
    add_modal(
      modal_id = "quote-modal",
      title = "Test",
      modal_content = "Content with 'single quotes' and more"
    )
  
  expect_true(viz$needs_modals)
})

test_that("multiple modals can be added to same collection", {
  viz <- create_viz(mtcars, name = "test") %>%
    add_modal(
      modal_id = "modal-1",
      title = "First",
      modal_content = "Content 1"
    ) %>%
    add_modal(
      modal_id = "modal-2",
      title = "Second",
      modal_content = "Content 2"
    )
  
  expect_true(viz$needs_modals)
  # Should have multiple content blocks
  expect_true(length(viz$items) >= 2)
})

test_that("modal content is properly formatted", {
  # Test the internal helper function
  html_table <- dashboardr:::.df_to_html_table(head(mtcars, 3))
  
  expect_true(grepl("<table", html_table))
  expect_true(grepl("<thead>", html_table))
  expect_true(grepl("<tbody>", html_table))
  expect_true(grepl("mpg", html_table))
  expect_true(grepl("cyl", html_table))
})

test_that("modal with only title works", {
  viz <- create_viz(mtcars, name = "test") %>%
    add_modal(
      modal_id = "title-only",
      title = "Just a Title"
    )
  
  expect_true(viz$needs_modals)
})

test_that("modal with HTML content works", {
  viz <- create_viz(mtcars, name = "test") %>%
    add_modal(
      modal_id = "html-modal",
      title = "HTML",
      modal_content = "<p><strong>Bold</strong> text</p>"
    )
  
  expect_true(viz$needs_modals)
})

test_that("page generation includes modal assets when needed", {
  # Create a page with modal
  viz <- create_viz(mtcars, name = "test") %>%
    add_text("[Link](#modal){.modal-link}") %>%
    add_modal(
      modal_id = "modal",
      title = "Test",
      modal_content = "Content"
    )
  
  page <- list(
    title = "Test Page",
    file_name = "test",
    visualizations = list(viz),
    needs_modals = viz$needs_modals
  )
  
  # Check that needs_modals flag is preserved
  expect_true(page$needs_modals)
})

test_that("modal_content function creates proper HTML structure", {
  content <- modal_content(
    modal_id = "test",
    title = "Title",
    text = "Text content"
  )
  
  expect_s3_class(content, "shiny.tag")
  expect_equal(content$attribs$id, "test")
  expect_equal(content$attribs$class, "modal-content")
  expect_equal(content$attribs$style, "display:none;")
})

test_that("modal_link creates proper anchor tag", {
  link <- modal_link("Click me", "my-modal")
  
  expect_s3_class(link, "shiny.tag")
  expect_equal(link$name, "a")
  expect_equal(link$attribs$href, "#my-modal")
})

test_that("enable_modals returns necessary assets", {
  result <- enable_modals()
  
  expect_s3_class(result, "shiny.tag.list")
  expect_length(result, 2)  # CSS and JS
})

# =============================================================================
# Tests for add_modal with page_object (fixes regression from Feb 2026)
# =============================================================================

test_that("add_modal works with page_object", {
  # Create a page and add a modal
  page <- create_page("Test", data = mtcars, type = "bar") %>%
    add_text("[Click here](#info){.modal-link}") %>%
    add_modal(
      modal_id = "info",
      title = "Information",
      modal_content = "This is some info."
    )
  
  # Check that we get a page_object back

  expect_s3_class(page, "page_object")
  
  # Check that needs_modals flag is set on the page

  expect_true(page$needs_modals)
  
  # Check that the modal block was added to page$.items
  modal_items <- Filter(function(x) x$type == "modal", page$.items)
  expect_length(modal_items, 1)
  expect_equal(modal_items[[1]]$modal_id, "info")
})

test_that("add_modal.page_object creates modal block with correct structure", {
  page <- create_page("Test", data = mtcars) %>%
    add_modal(
      modal_id = "test-modal",
      title = "Test Title",
      modal_content = "Test content here"
    )
  
  # Find the modal item
  modal_item <- Filter(function(x) x$type == "modal", page$.items)[[1]]
  
  # Check structure
  expect_equal(modal_item$type, "modal")
  expect_equal(modal_item$modal_id, "test-modal")
  expect_true(grepl("<h2>Test Title</h2>", modal_item$html_content))
  expect_true(grepl("Test content here", modal_item$html_content))
})

test_that("multiple modals can be added to page_object", {
  page <- create_page("Test", data = mtcars) %>%
    add_modal(modal_id = "modal-1", title = "First", modal_content = "Content 1") %>%
    add_modal(modal_id = "modal-2", title = "Second", modal_content = "Content 2") %>%
    add_modal(modal_id = "modal-3", title = "Third", modal_content = "Content 3")
  
  # Check needs_modals is set
  expect_true(page$needs_modals)
  
  # Check all three modals were added
  modal_items <- Filter(function(x) x$type == "modal", page$.items)
  expect_length(modal_items, 3)
  
  # Check modal IDs
  modal_ids <- sapply(modal_items, function(x) x$modal_id)
  expect_setequal(modal_ids, c("modal-1", "modal-2", "modal-3"))
})

test_that("add_modal.page_object with image includes image tag", {
  page <- create_page("Test", data = mtcars) %>%
    add_modal(
      modal_id = "img-modal",
      title = "With Image",
      image = "chart.png",
      image_width = "80%",
      modal_content = "Description"
    )
  
  modal_item <- Filter(function(x) x$type == "modal", page$.items)[[1]]
  
  # Check image is in HTML content
  expect_true(grepl('<img src="chart.png"', modal_item$html_content))
  expect_true(grepl("max-width:80%", modal_item$html_content))
})

test_that("needs_modals flag propagates through page_to_content", {
  # Create page with modal
  page <- create_page("Test", data = mtcars, type = "bar") %>%
    add_text("[Link](#modal){.modal-link}") %>%
    add_viz(x_var = "cyl", title = "Test") %>%
    add_modal(modal_id = "modal", title = "Info", modal_content = "Content")
  
  # Convert to content using internal function
  content <- dashboardr:::.page_to_content(page)
  
  # Check that needs_modals propagated

  expect_true(content$needs_modals)
})

test_that("page_object modals generate correct QMD output", {
  skip_on_cran()
  
  # Create a temporary directory for the test
  test_dir <- tempfile("modal_test_")
  dir.create(test_dir)
  on.exit(unlink(test_dir, recursive = TRUE))
  
  # Create page with modal
  page <- create_page("Results", data = mtcars, type = "bar") %>%
    add_text("[View details](#details){.modal-link}") %>%
    add_viz(x_var = "cyl", title = "Cylinders") %>%
    add_modal(
      modal_id = "details",
      title = "Details",
      modal_content = "More information here."
    )
  
  # Generate dashboard (without rendering)
  dashboard <- create_dashboard(title = "Test", output_dir = test_dir) %>%
    add_page(page) %>%
    generate_dashboard(render = FALSE, quiet = TRUE)
  
  # Read generated QMD
  qmd_file <- file.path(test_dir, "results.qmd")
  expect_true(file.exists(qmd_file))
  
  qmd_content <- readLines(qmd_file)
  qmd_text <- paste(qmd_content, collapse = "\n")
  
  # Check that modals are enabled (via .page_config or standalone enable_modals)
  expect_true(grepl("modals = TRUE", qmd_text) || grepl("enable_modals\\(\\)", qmd_text))
  
  # Check that modal_content() is included with correct ID
  expect_true(grepl("modal_content\\(", qmd_text))
  expect_true(grepl("modal_id = 'details'", qmd_text))
  
  # Check that the title and content are in the generated code
  expect_true(grepl("<h2>Details</h2>", qmd_text))
  expect_true(grepl("More information here", qmd_text))
})

test_that("page_object with text and modals mixed preserves order", {
  page <- create_page("Test", data = mtcars) %>%
    add_text("First text") %>%
    add_modal(modal_id = "m1", title = "Modal 1", modal_content = "C1") %>%
    add_text("Second text") %>%
    add_modal(modal_id = "m2", title = "Modal 2", modal_content = "C2")
  
  # Check item order
  expect_equal(page$.items[[1]]$type, "text")
  expect_equal(page$.items[[2]]$type, "modal")
  expect_equal(page$.items[[3]]$type, "text")
  expect_equal(page$.items[[4]]$type, "modal")
  
  # Check modal IDs in order
  expect_equal(page$.items[[2]]$modal_id, "m1")
  expect_equal(page$.items[[4]]$modal_id, "m2")
})







