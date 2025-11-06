test_that("is_content recognizes both class types", {
  viz <- create_viz()
  content <- create_content()
  
  expect_true(is_content(viz))
  expect_true(is_content(content))
  expect_false(is_content(list()))
  expect_false(is_content("string"))
  expect_false(is_content(NULL))
  expect_false(is_content(data.frame()))
})

test_that("is_content_block recognizes content blocks", {
  # Create a content block by using add_text in standalone mode
  block <- add_text(NULL, "Test text")
  
  expect_true(is_content_block(block))
  expect_false(is_content_block(create_viz()))
  expect_false(is_content_block(list()))
  expect_false(is_content_block("string"))
  expect_false(is_content_block(NULL))
})

test_that("is_any_content recognizes both collections and blocks", {
  viz <- create_viz()
  content <- create_content()
  block <- add_text(NULL, "Test text")
  
  expect_true(is_any_content(viz))
  expect_true(is_any_content(content))
  expect_true(is_any_content(block))
  expect_false(is_any_content(list()))
  expect_false(is_any_content("string"))
  expect_false(is_any_content(NULL))
})

test_that("helper functions work with piped content", {
  # Create a piped content collection
  piped <- create_viz() %>%
    add_viz(type = "histogram", x_var = "mpg") %>%
    add_text("Some text")
  
  expect_true(is_content(piped))
  expect_false(is_content_block(piped))
  expect_true(is_any_content(piped))
})

test_that("helper functions are consistent with class structure", {
  # All viz_collection objects should also be content_collection
  viz <- create_viz()
  
  expect_s3_class(viz, "viz_collection")
  expect_s3_class(viz, "content_collection")
  expect_true(is_content(viz))
})

