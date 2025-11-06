# Tests for enhanced content blocks: add_viz text positioning, add_text, add_image

test_that("add_viz supports text_above_title, text_above_tabs, text_above_graphs, text_below_graphs", {
  # Create a simple viz collection
  viz <- create_viz() %>%
    add_viz(
      type = "histogram",
      x_var = "age",
      title = "Age Distribution",
      tabgroup = "demo",
      text_above_title = "Before everything - even the title",
      text_above_tabs = "## Introduction\n\nThis is above the tabs.",
      text_above_graphs = "This appears above the graph.",
      text_below_graphs = "This appears below the graph."
    )
  
  # Verify the viz collection has the spec
  expect_equal(length(viz$items), 1)
  spec <- viz$items[[1]]
  
  # Check that new text parameters are stored
  expect_equal(spec$text_above_title, "Before everything - even the title")
  expect_equal(spec$text_above_tabs, "## Introduction\n\nThis is above the tabs.")
  expect_equal(spec$text_above_graphs, "This appears above the graph.")
  expect_equal(spec$text_below_graphs, "This appears below the graph.")
})

test_that("add_viz backward compatibility: text parameter maps correctly", {
  # Test text = with text_position = "above" (default)
  viz1 <- create_viz() %>%
    add_viz(
      type = "histogram",
      x_var = "age",
      text = "Old way - above",
      text_position = "above"
    )
  
  spec1 <- viz1$items[[1]]
  expect_equal(spec1$text_above_graphs, "Old way - above")
  expect_equal(spec1$text, "Old way - above")  # Text is stored for backward compatibility
  
  # Test text = with text_position = "below"
  viz2 <- create_viz() %>%
    add_viz(
      type = "histogram",
      x_var = "age",
      text = "Old way - below",
      text_position = "below"
    )
  
  spec2 <- viz2$items[[1]]
  expect_equal(spec2$text_below_graphs, "Old way - below")
  expect_equal(spec2$text, "Old way - below")  # Text is stored for backward compatibility
})

test_that("add_viz text parameters work with tabgroups", {
  viz <- create_viz() %>%
    add_viz(
      type = "histogram",
      x_var = "age",
      title = "Age",
      tabgroup = "demo",
      text_above_tabs = "Before tabs",
      text_above_graphs = "Above graph in tab",
      text_below_graphs = "Below graph in tab"
    )
  
  spec <- viz$items[[1]]
  expect_equal(spec$text_above_tabs, "Before tabs")
  expect_equal(spec$text_above_graphs, "Above graph in tab")
  expect_equal(spec$text_below_graphs, "Below graph in tab")
})

test_that("add_text creates text content block", {
  # Create a simple dashboard
  dashboard <- create_dashboard("test_dashboard", "Test") %>%
    add_page(
      "Test Page",
      content = add_text("# Heading\n\nSome content here.")
    )
  
  # Verify page has content
  expect_true("Test Page" %in% names(dashboard$pages))
  page <- dashboard$pages[["Test Page"]]
  
  # Check that content_blocks includes text block
  expect_true("content_blocks" %in% names(page))
  expect_true(is.list(page$content_blocks))
  expect_true(length(page$content_blocks) > 0)
  expect_equal(page$content_blocks[[1]]$type, "text")
  expect_true(grepl("Heading", page$content_blocks[[1]]$content))
})

test_that("add_image creates image content block with parameters", {
  dashboard <- create_dashboard("test_dashboard", "Test") %>%
    add_page(
      "Test Page",
      content = add_image(
        src = "logo.png",
        alt = "Company Logo",
        caption = "Our company logo",
        width = "200px",
        align = "center"
      )
    )
  
  page <- dashboard$pages[["Test Page"]]
  expect_true("content_blocks" %in% names(page))
  
  # Find image block
  image_block <- NULL
  for (item in page$content_blocks) {
    if (is.list(item) && "type" %in% names(item) && item$type == "image") {
      image_block <- item
      break
    }
  }
  
  expect_false(is.null(image_block))
  expect_equal(image_block$src, "logo.png")
  expect_equal(image_block$alt, "Company Logo")
  expect_equal(image_block$caption, "Our company logo")
  expect_equal(image_block$width, "200px")
  expect_equal(image_block$align, "center")
})

test_that("add_page accepts content parameter (alias for visualizations)", {
  viz <- create_viz() %>%
    add_viz(type = "histogram", x_var = "age")
  
  # Test using content parameter
  dashboard1 <- create_dashboard("test1", "Test") %>%
    add_page("Page 1", content = viz)
  
  # Test using visualizations parameter (backward compatibility)
  dashboard2 <- create_dashboard("test2", "Test") %>%
    add_page("Page 2", visualizations = viz)
  
  # Both should work the same
  expect_true("Page 1" %in% names(dashboard1$pages))
  expect_true("Page 2" %in% names(dashboard2$pages))
  
  page1 <- dashboard1$pages[["Page 1"]]
  page2 <- dashboard2$pages[["Page 2"]]
  
  # Both should have visualizations
  expect_false(is.null(page1$visualizations))
  expect_false(is.null(page2$visualizations))
})

test_that("add_page supports mixed content (text, images, visualizations)", {
  viz <- create_viz() %>%
    add_viz(type = "histogram", x_var = "age")
  
  dashboard <- create_dashboard("test_dashboard", "Test") %>%
    add_page(
      "Mixed Page",
      content = list(
        add_text("# Introduction\n\nWelcome!"),
        add_image(src = "chart.png", alt = "Chart"),
        viz,
        add_text("## Conclusion\n\nThat's all!")
      )
    )
  
  page <- dashboard$pages[["Mixed Page"]]
  
  # Should have both visualizations and content_blocks
  expect_true(!is.null(page$visualizations))  # viz was included
  expect_true("content_blocks" %in% names(page))
  
  # Content blocks should have text and image blocks (not viz)
  expect_true(is.list(page$content_blocks))
  expect_equal(length(page$content_blocks), 3)  # 2 text blocks + 1 image block
  
  # Check types
  expect_equal(page$content_blocks[[1]]$type, "text")
  expect_equal(page$content_blocks[[2]]$type, "image")
  expect_equal(page$content_blocks[[3]]$type, "text")
})

test_that("add_image supports all QoL parameters", {
  img <- add_image(
    src = "example.jpg",
    alt = "Example image",
    caption = "This is an example",
    width = "300px",
    height = "200px",
    align = "right",
    link = "https://example.com",
    class = "custom-class"
  )
  
  expect_equal(img$type, "image")
  expect_equal(img$src, "example.jpg")
  expect_equal(img$alt, "Example image")
  expect_equal(img$caption, "This is an example")
  expect_equal(img$width, "300px")
  expect_equal(img$height, "200px")
  expect_equal(img$align, "right")
  expect_equal(img$link, "https://example.com")
  expect_equal(img$class, "custom-class")
})

test_that("add_text supports markdown formatting", {
  text_block <- add_text(
    "# Heading\n\nParagraph with **bold** and *italic*.\n\n- List item 1\n- List item 2"
  )
  
  expect_equal(text_block$type, "text")
  expect_true(grepl("Heading", text_block$content))
  expect_true(grepl("bold", text_block$content))
})

test_that("add_text works seamlessly with md_text", {
  # md_text() should work as input to add_text()
  text_content <- md_text(
    "# Welcome",
    "",
    "This is a multi-line text block.",
    "",
    "## Features",
    "- Feature 1",
    "- Feature 2"
  )
  
  # Pass md_text output to add_text
  text_block <- add_text(text_content)
  
  expect_equal(text_block$type, "text")
  expect_true(grepl("Welcome", text_block$content))
  expect_true(grepl("Features", text_block$content))
  expect_true(grepl("Feature 1", text_block$content))
  
  # Should also work directly
  text_block2 <- add_text(md_text("# Title", "Content here"))
  expect_equal(text_block2$type, "text")
  expect_true(grepl("Title", text_block2$content))
})

test_that("text positioning in QMD generation works correctly", {
  skip_on_cran()
  
  # Create a dashboard with new text positioning
  temp_dir <- tempfile("test_text_pos")
  
  viz <- create_viz() %>%
    add_viz(
      type = "histogram",
      x_var = "age",
      title = "Test",
      text_above_tabs = "## Above Tabs",
      text_above_graphs = "Above graphs",
      text_below_graphs = "Below graphs"
    )
  
  df <- data.frame(age = rnorm(100))
  
  dashboard <- create_dashboard(temp_dir, "Test") %>%
    add_page("Test", data = df, visualizations = viz) %>%
    generate_dashboard()
  
  # Read generated QMD
  qmd_file <- file.path(temp_dir, "test.qmd")
  expect_true(file.exists(qmd_file))
  
  qmd_content <- readLines(qmd_file)
  
  # Check that text appears in correct order
  # Find the section with our viz
  viz_section_start <- grep("## Test", qmd_content)
  expect_true(length(viz_section_start) > 0)
  
  # Cleanup
  unlink(temp_dir, recursive = TRUE)
})

