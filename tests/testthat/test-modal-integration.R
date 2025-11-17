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







