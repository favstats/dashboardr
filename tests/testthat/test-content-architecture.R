# Tests for unified content architecture
# content_collection is the main container
# viz is just one type of content block

test_that("create_content creates a content_collection", {
  content <- create_content()
  expect_s3_class(content, "content_collection")
  expect_true(is.list(content$items))
  expect_equal(length(content$items), 0)
})

test_that("create_viz is an alias for create_content", {
  content1 <- create_content()
  content2 <- create_viz()
  expect_equal(class(content1), class(content2))
})

test_that("add_viz adds visualization blocks to content_collection", {
  content <- create_content() %>%
    add_viz(type = "histogram", x_var = "age", title = "Age Distribution")
  
  expect_s3_class(content, "content_collection")
  expect_equal(length(content$items), 1)
  expect_equal(content$items[[1]]$type, "viz")
  expect_equal(content$items[[1]]$viz_type, "histogram")
  expect_equal(content$items[[1]]$title, "Age Distribution")
})

test_that("add_text adds text blocks to content_collection", {
  content <- create_content() %>%
    add_text("# Welcome")
  
  expect_s3_class(content, "content_collection")
  expect_equal(length(content$items), 1)
  expect_equal(content$items[[1]]$type, "text")
  expect_true(grepl("Welcome", content$items[[1]]$content))
})

test_that("add_image adds image blocks to content_collection", {
  content <- create_content() %>%
    add_image(src = "logo.png", alt = "Logo")
  
  expect_s3_class(content, "content_collection")
  expect_equal(length(content$items), 1)
  expect_equal(content$items[[1]]$type, "image")
  expect_equal(content$items[[1]]$src, "logo.png")
})

test_that("content can be mixed in any order", {
  content <- create_content() %>%
    add_text("# Introduction") %>%
    add_viz(type = "bar", x_var = "category") %>%
    add_image(src = "chart.png", alt = "Chart") %>%
    add_text("# Conclusion") %>%
    add_viz(type = "histogram", x_var = "age")
  
  expect_s3_class(content, "content_collection")
  expect_equal(length(content$items), 5)
  expect_equal(content$items[[1]]$type, "text")
  expect_equal(content$items[[2]]$type, "viz")
  expect_equal(content$items[[3]]$type, "image")
  expect_equal(content$items[[4]]$type, "text")
  expect_equal(content$items[[5]]$type, "viz")
})

test_that("multiple viz blocks are stored as separate items", {
  content <- create_content() %>%
    add_viz(type = "histogram", x_var = "age", tabgroup = "demo") %>%
    add_viz(type = "bar", x_var = "gender", tabgroup = "demo")
  
  expect_s3_class(content, "content_collection")
  expect_equal(length(content$items), 2)
  expect_equal(content$items[[1]]$type, "viz")
  expect_equal(content$items[[2]]$type, "viz")
  expect_equal(content$items[[1]]$tabgroup, "demo")
  expect_equal(content$items[[2]]$tabgroup, "demo")
})

# Tests for new content types

test_that("add_callout creates callout block", {
  content <- create_content() %>%
    add_callout("Important information", type = "warning")
  
  expect_s3_class(content, "content_collection")
  expect_equal(length(content$items), 1)
  expect_equal(content$items[[1]]$type, "callout")
  expect_equal(content$items[[1]]$callout_type, "warning")
  expect_true(grepl("Important", content$items[[1]]$content))
})

test_that("add_callout validates type parameter", {
  expect_error(
    create_content() %>% add_callout("Text", type = "invalid"),
    "'arg' should be one of"
  )
})

test_that("add_divider creates divider block", {
  content <- create_content() %>%
    add_text("Section 1") %>%
    add_divider() %>%
    add_text("Section 2")
  
  expect_s3_class(content, "content_collection")
  expect_equal(length(content$items), 3)
  expect_equal(content$items[[2]]$type, "divider")
})

test_that("add_code creates code block with language", {
  content <- create_content() %>%
    add_code("print('hello')", language = "python")
  
  expect_s3_class(content, "content_collection")
  expect_equal(length(content$items), 1)
  expect_equal(content$items[[1]]$type, "code")
  expect_equal(content$items[[1]]$language, "python")
  expect_true(grepl("print", content$items[[1]]$code))
})

test_that("add_spacer creates spacer with height", {
  content <- create_content() %>%
    add_spacer(height = "3rem")
  
  expect_s3_class(content, "content_collection")
  expect_equal(length(content$items), 1)
  expect_equal(content$items[[1]]$type, "spacer")
  expect_equal(content$items[[1]]$height, "3rem")
})

test_that("add_gt creates gt table block", {
  skip_if_not_installed("gt")
  
  content <- create_content() %>%
    add_gt(gt::gt(mtcars[1:5, 1:3]), caption = "Motor Trend Data")
  
  expect_s3_class(content, "content_collection")
  expect_equal(length(content$items), 1)
  expect_equal(content$items[[1]]$type, "gt")
  expect_true(!is.null(content$items[[1]]$gt_object))
})

test_that("add_reactable creates reactable table block", {
  skip_if_not_installed("reactable")
  
  content <- create_content() %>%
    add_reactable(reactable::reactable(mtcars[1:5, 1:3]))
  
  expect_s3_class(content, "content_collection")
  expect_equal(length(content$items), 1)
  expect_equal(content$items[[1]]$type, "reactable")
  expect_true(!is.null(content$items[[1]]$reactable_object))
})

test_that("add_video creates video block", {
  content <- create_content() %>%
    add_video(url = "demo.mp4", caption = "Demo video")
  
  expect_s3_class(content, "content_collection")
  expect_equal(length(content$items), 1)
  expect_equal(content$items[[1]]$type, "video")
  expect_equal(content$items[[1]]$url, "demo.mp4")
})

test_that("add_iframe creates iframe block", {
  content <- create_content() %>%
    add_iframe(url = "https://example.com", height = "500px")
  
  expect_s3_class(content, "content_collection")
  expect_equal(length(content$items), 1)
  expect_equal(content$items[[1]]$type, "iframe")
  expect_equal(content$items[[1]]$url, "https://example.com")
  expect_equal(content$items[[1]]$height, "500px")
})

test_that("add_accordion creates collapsible section", {
  content <- create_content() %>%
    add_accordion(title = "Details", text = "Hidden content here")
  
  expect_s3_class(content, "content_collection")
  expect_equal(length(content$items), 1)
  expect_equal(content$items[[1]]$type, "accordion")
  expect_equal(content$items[[1]]$title, "Details")
})

test_that("add_card creates card block", {
  content <- create_content() %>%
    add_card(title = "Summary", text = "Card content")
  
  expect_s3_class(content, "content_collection")
  expect_equal(length(content$items), 1)
  expect_equal(content$items[[1]]$type, "card")
  expect_equal(content$items[[1]]$title, "Summary")
})

# Test backward compatibility
test_that("existing viz_collection code still works", {
  # Old style: create_viz() for visualizations only
  viz <- create_viz() %>%
    add_viz(type = "histogram", x_var = "age") %>%
    add_viz(type = "bar", x_var = "gender")
  
  expect_s3_class(viz, "content_collection")
  expect_equal(length(viz$items), 2)
  expect_equal(viz$items[[1]]$type, "viz")
  expect_equal(viz$items[[2]]$type, "viz")
})

