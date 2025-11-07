test_that("add_text works standalone", {
  text_block <- add_text("Hello world")
  expect_s3_class(text_block, "content_block")
  expect_equal(text_block$type, "text")
  expect_equal(text_block$content, "Hello world")
})

test_that("add_text works with viz_collection", {
  viz <- create_viz(type = "histogram") %>%
    add_viz(x_var = "mpg") %>%
    add_text("Some text")
  
  expect_s3_class(viz, "content_collection")
  expect_length(viz$items, 2)
  expect_s3_class(viz$items[[2]], "content_block")
  expect_equal(viz$items[[2]]$type, "text")
})

test_that("add_text works with content_collection", {
  content <- create_content() %>%
    add_text("First line") %>%
    add_text("Second line")
  
  expect_s3_class(content, "content_collection")
  expect_length(content$items, 2)
})

test_that("add_accordion works after add_text", {
  content <- create_viz() %>%
    add_viz(type = "histogram", x_var = "mpg") %>%
    add_text("Introduction") %>%
    add_accordion("Details", text = "More info")
  
  expect_s3_class(content, "content_collection")
  expect_length(content$items, 3)
  expect_equal(content$items[[3]]$type, "accordion")
})

test_that("add_accordion works with viz_collection directly", {
  # This should convert viz_collection to content_collection
  content <- create_viz(type = "histogram") %>%
    add_viz(x_var = "mpg") %>%
    add_accordion("Details", text = "More info")
  
  expect_s3_class(content, "content_collection")
  expect_length(content$items, 2)
  expect_equal(content$items[[2]]$type, "accordion")
})

test_that("text argument in add_viz works", {
  viz <- create_viz(type = "histogram") %>%
    add_viz(
      x_var = "mpg",
      text = "Chart description",
      text_position = "above"
    )
  
  expect_equal(viz$items[[1]]$text, "Chart description")
  expect_equal(viz$items[[1]]$text_position, "above")
})

test_that("add_card works with viz_collection", {
  content <- create_viz() %>%
    add_viz(type = "histogram", x_var = "mpg") %>%
    add_card(text = "Card content", title = "Card Title")
  
  expect_s3_class(content, "content_collection")
  expect_equal(content$items[[2]]$type, "card")
})

test_that("add_callout works with viz_collection", {
  content <- create_viz() %>%
    add_viz(type = "histogram", x_var = "mpg") %>%
    add_callout(text = "Important note", type = "warning")
  
  expect_s3_class(content, "content_collection")
  expect_equal(content$items[[2]]$type, "callout")
})

test_that("add_divider works with viz_collection", {
  content <- create_viz() %>%
    add_viz(type = "histogram", x_var = "mpg") %>%
    add_divider()
  
  expect_s3_class(content, "content_collection")
  expect_equal(content$items[[2]]$type, "divider")
})

test_that("add_code works with viz_collection", {
  content <- create_viz() %>%
    add_viz(type = "histogram", x_var = "mpg") %>%
    add_code("x <- 1", language = "r")
  
  expect_s3_class(content, "content_collection")
  expect_equal(content$items[[2]]$type, "code")
})

test_that("add_spacer works with viz_collection", {
  content <- create_viz() %>%
    add_viz(type = "histogram", x_var = "mpg") %>%
    add_spacer(height = "3rem")
  
  expect_s3_class(content, "content_collection")
  expect_equal(content$items[[2]]$type, "spacer")
})

test_that("add_image works with viz_collection", {
  content <- create_viz() %>%
    add_viz(type = "histogram", x_var = "mpg") %>%
    add_image(src = "test.png", alt = "Test image")
  
  expect_s3_class(content, "content_collection")
  expect_equal(content$items[[2]]$type, "image")
})

test_that("mixed content works in complex pipeline", {
  # This mimics the user's example
  content <- create_viz(type = "histogram") %>%
    add_viz(x_var = "hp", title = "Horsepower", tabgroup = "overview") %>%
    add_text("*HI!*") %>%
    add_accordion("Details", text = "More info") %>%
    add_viz(
      type = "histogram",
      x_var = "mpg",
      text = "Additional chart",
      text_position = "above",
      tabgroup = "overview"
    )
  
  expect_s3_class(content, "content_collection")
  # Should have: viz_collection, text, accordion, viz spec
  expect_gte(length(content$items), 4)
})

test_that("content_collection can be used in dashboard with 'content' parameter", {
  skip_on_cran()
  skip_if_not_installed("withr")
  
  withr::with_tempdir({
    data <- mtcars
    
    content <- create_viz(type = "histogram") %>%
      add_viz(x_var = "mpg") %>%
      add_text("## Analysis Results") %>%
      add_accordion("Methodology", text = "We used standard methods")
    
    dashboard <- create_dashboard(
      title = "Test",
      output_dir = "test_dash",
      allow_inside_pkg = TRUE
    ) %>%
      add_page(
        "Test",
        data = data,
        content = content  # Use content parameter for content_collection
      )
    
    expect_s3_class(dashboard, "dashboard_project")
    
    # Try to generate (just files, no render)
    expect_no_error(generate_dashboard(dashboard, render = FALSE, quiet = TRUE))
  })
})

test_that("content_collection can be used in dashboard with 'visualizations' parameter", {
  skip_on_cran()
  skip_if_not_installed("withr")
  
  withr::with_tempdir({
    data <- mtcars
    
    viz <- create_viz(type = "histogram") %>%
      add_viz(x_var = "mpg") %>%
      add_text("## Analysis Results") %>%
      add_accordion("Methodology", text = "We used standard methods")
    
    dashboard <- create_dashboard(
      title = "Test",
      output_dir = "test_dash",
      allow_inside_pkg = TRUE
    ) %>%
      add_page(
        "Test",
        data = data,
        visualizations = viz  # Use visualizations parameter (backward compatibility)
      )
    
    expect_s3_class(dashboard, "dashboard_project")
    
    # Try to generate (just files, no render)
    expect_no_error(generate_dashboard(dashboard, render = FALSE, quiet = TRUE))
  })
})

test_that("text parameters in add_viz are preserved", {
  viz <- create_viz(type = "histogram") %>%
    add_viz(
      x_var = "mpg",
      text = md_text("Line 1", "Line 2"),
      text_position = "below",
      tabgroup = "test"
    )
  
  expect_equal(viz$items[[1]]$text, "Line 1\nLine 2")
  expect_equal(viz$items[[1]]$text_position, "below")
})

# Test that tabgroup_labels are preserved in unified content system
test_that("set_tabgroup_labels works with unified content system", {
  viz <- create_viz(type = "histogram") %>%
    add_viz(x_var = "mpg", tabgroup = "demographics") %>%
    add_viz(x_var = "hp", tabgroup = "performance") %>%
    add_text("## Analysis") %>%
    set_tabgroup_labels(
      demographics = "{{< iconify ph:users-fill >}} Demographics",
      performance = "{{< iconify ph:gauge-fill >}} Performance"
    )
  
  # Labels should be stored in the collection
  expect_equal(viz$tabgroup_labels$demographics, "{{< iconify ph:users-fill >}} Demographics")
  expect_equal(viz$tabgroup_labels$performance, "{{< iconify ph:gauge-fill >}} Performance")
  
  # Create dashboard and check labels are preserved
  temp_dir <- tempdir()
  dashboard <- create_dashboard("test_labels", temp_dir, allow_inside_pkg = TRUE) %>%
    add_page("Analysis", data = mtcars, content = viz)
  
  # Generate dashboard
  suppressMessages(generate_dashboard(dashboard, render = FALSE, quiet = TRUE))
  
  # Check QMD file contains the icon shortcodes
  qmd_file <- file.path(dashboard$output_dir, "analysis.qmd")
  expect_true(file.exists(qmd_file))
  
  qmd_content <- readLines(qmd_file)
  expect_true(any(grepl("ph:users-fill", qmd_content)))
  expect_true(any(grepl("ph:gauge-fill", qmd_content)))
  expect_true(any(grepl("Demographics", qmd_content)))
  expect_true(any(grepl("Performance", qmd_content)))
  
  # Clean up
  unlink(dashboard$output_dir, recursive = TRUE)
})
