test_that("enable_modals returns HTML tags", {
  result <- enable_modals()
  
  expect_s3_class(result, "shiny.tag.list")
  expect_length(result, 2)  # CSS and JS
})

test_that("modal_link creates correct HTML", {
  link <- modal_link("Click me", "modal1")
  
  expect_s3_class(link, "shiny.tag")
  expect_equal(link$name, "a")
  expect_equal(link$attribs$href, "#modal1")  # Modern approach uses href with modal ID
  expect_equal(as.character(link$children[[1]]), "Click me")
})

test_that("modal_link with custom class", {
  link <- modal_link("Button", "modal2", class = "btn btn-primary")
  
  expect_equal(link$attribs$class, "btn btn-primary")
})

test_that("modal_content creates hidden div with correct ID", {
  content <- modal_content(
    modal_id = "test-modal",
    title = "Test Title",
    text = "Test content"
  )
  
  expect_s3_class(content, "shiny.tag")
  expect_equal(content$name, "div")
  expect_equal(content$attribs$id, "test-modal")
  expect_equal(content$attribs$class, "modal-content")
  expect_equal(content$attribs$style, "display:none;")
})

test_that("modal_content with image and text", {
  content <- modal_content(
    modal_id = "img-modal",
    title = "Chart",
    image = "chart.png",
    text = "Description"
  )
  
  # Should have content
  expect_true(length(content$children) > 0)
  expect_equal(content$attribs$id, "img-modal")
})

test_that("quick_modal is deprecated - use add_modal() instead", {
  skip("quick_modal() is deprecated in favor of add_modal()")
})

test_that("modal_content with custom HTML", {
  content <- modal_content(
    modal_id = "custom",
    htmltools::tags$h2("Custom"),
    htmltools::tags$p("Paragraph")
  )
  
  expect_s3_class(content, "shiny.tag")
  expect_equal(content$attribs$id, "custom")
})

test_that("modal assets exist", {
  modal_css <- system.file("assets", "modal.css", package = "dashboardr")
  modal_js <- system.file("assets", "modal.js", package = "dashboardr")
  
  expect_true(file.exists(modal_css))
  expect_true(file.exists(modal_js))
})

test_that("modal assets are valid files", {
  modal_css <- system.file("assets", "modal.css", package = "dashboardr")
  modal_js <- system.file("assets", "modal.js", package = "dashboardr")
  
  # Check files are not empty
  css_content <- readLines(modal_css)
  js_content <- readLines(modal_js)
  
  expect_true(length(css_content) > 0)
  expect_true(length(js_content) > 0)
  
  # Check for key content
  expect_true(any(grepl("dashboardr-modal", css_content)))
  expect_true(any(grepl("data-modal", js_content)))
})

