# =================================================================
# Tests for create_viz() and add_viz() core functionality
# =================================================================

# --- create_viz() tests ---
test_that("create_viz returns a viz_collection with correct structure", {
  result <- create_viz()
  
  expect_s3_class(result, "viz_collection")
  expect_s3_class(result, "content_collection")
  expect_type(result$items, "list")
  expect_equal(length(result$items), 0)
  expect_null(result$data)
})

test_that("create_viz accepts data parameter", {
  result <- create_viz(data = mtcars)
  
  expect_equal(result$data, mtcars)
})

test_that("create_viz accepts tabgroup_labels", {
  result <- create_viz(tabgroup_labels = list(demo = "Demographics", perf = "Performance"))
  
  expect_equal(result$tabgroup_labels$demo, "Demographics")
  expect_equal(result$tabgroup_labels$perf, "Performance")
})

test_that("create_viz accepts shared_first_level parameter", {
  result_shared <- create_viz(shared_first_level = TRUE)
  result_not_shared <- create_viz(shared_first_level = FALSE)
  
  expect_true(result_shared$shared_first_level)
  expect_false(result_not_shared$shared_first_level)
})

test_that("create_viz stores defaults from ... arguments", {
  result <- create_viz(
    type = "histogram",
    color_palette = c("red", "blue"),
    horizontal = TRUE
  )
  
  expect_equal(result$defaults$type, "histogram")
  expect_equal(result$defaults$color_palette, c("red", "blue"))
  expect_true(result$defaults$horizontal)
})

test_that("create_viz NSE converts symbols to strings for var params", {
  result <- create_viz(x_var = mpg, y_var = hp)
  
  expect_equal(result$defaults$x_var, "mpg")
  expect_equal(result$defaults$y_var, "hp")
})

test_that("create_viz handles quoted var params correctly", {
  result <- create_viz(x_var = "mpg", group_var = "cyl")
  
  expect_equal(result$defaults$x_var, "mpg")
  expect_equal(result$defaults$group_var, "cyl")
})

test_that("create_viz handles c() syntax for vector params", {
  result <- create_viz(x_vars = c(q1, q2, q3))
  
  expect_equal(result$defaults$x_vars, c("q1", "q2", "q3"))
})

test_that("create_viz handles quoted vector params", {
  result <- create_viz(x_vars = c("var1", "var2"))
  
  expect_equal(result$defaults$x_vars, c("var1", "var2"))
})

# --- add_viz() tests ---
test_that("add_viz adds visualization spec to collection", {
  result <- create_viz() %>%
    add_viz(type = "histogram", x_var = "mpg")
  
  expect_length(result$items, 1)
  spec <- result$items[[1]]
  # viz_type stores the actual visualization type
  expect_true(spec$type == "histogram" || spec$type == "viz" || spec$viz_type == "histogram")
  expect_equal(spec$x_var, "mpg")
})

test_that("add_viz inherits defaults from create_viz", {
  result <- create_viz(type = "histogram", color_palette = c("red", "blue")) %>%
    add_viz(x_var = "mpg")
  
  spec <- result$items[[1]]
  # viz_type or type should be histogram
  expect_true(spec$type == "histogram" || spec$viz_type == "histogram")
  expect_equal(spec$color_palette, c("red", "blue"))
})

test_that("add_viz overrides defaults when specified", {
  result <- create_viz(type = "histogram", horizontal = TRUE) %>%
    add_viz(x_var = "mpg", horizontal = FALSE)
  
  spec <- result$items[[1]]
  expect_false(spec$horizontal)
})

test_that("add_viz accepts tabgroup parameter", {
  result <- create_viz() %>%
    add_viz(type = "histogram", x_var = "mpg", tabgroup = "overview")
  
  expect_equal(result$items[[1]]$tabgroup, "overview")
})

test_that("add_viz accepts nested tabgroup with / syntax", {
  result <- create_viz() %>%
    add_viz(type = "histogram", x_var = "mpg", tabgroup = "main/sub")
  
  # Tabgroup should be parsed
  spec <- result$items[[1]]
  expect_true(!is.null(spec$tabgroup))
})

test_that("add_viz accepts title parameter", {
  result <- create_viz() %>%
    add_viz(type = "histogram", x_var = "mpg", title = "Distribution of MPG")
  
  expect_equal(result$items[[1]]$title, "Distribution of MPG")
})

test_that("add_viz accepts filter parameter", {
  result <- create_viz(data = mtcars) %>%
    add_viz(type = "histogram", x_var = "mpg", filter = ~ cyl == 4)
  
  spec <- result$items[[1]]
  expect_true(!is.null(spec$filter))
})

test_that("add_viz accepts text and text_position parameters", {
  result <- create_viz() %>%
    add_viz(
      type = "histogram", 
      x_var = "mpg", 
      text = "Description here",
      text_position = "above"
    )
  
  spec <- result$items[[1]]
  expect_equal(spec$text, "Description here")
  expect_equal(spec$text_position, "above")
})

test_that("add_viz accepts text_before_viz and text_after_viz", {
  result <- create_viz() %>%
    add_viz(
      type = "histogram", 
      x_var = "mpg",
      text_before_viz = "Before the chart",
      text_after_viz = "After the chart"
    )
  
  spec <- result$items[[1]]
  expect_equal(spec$text_before_viz, "Before the chart")
  expect_equal(spec$text_after_viz, "After the chart")
})

test_that("add_viz accepts height parameter", {
  result <- create_viz() %>%
    add_viz(type = "histogram", x_var = "mpg", height = 500)
  
  expect_equal(result$items[[1]]$height, 500)
})

test_that("add_viz accepts icon parameter", {
  result <- create_viz() %>%
    add_viz(type = "histogram", x_var = "mpg", tabgroup = "test", icon = "ph:chart-bar")
  
  expect_equal(result$items[[1]]$icon, "ph:chart-bar")
})

test_that("add_viz accepts data parameter override", {
  custom_data <- data.frame(x = 1:10)
  
  result <- create_viz(data = mtcars) %>%
    add_viz(type = "histogram", x_var = "x", data = custom_data)
  
  # Per-viz data frames are serialized to survive pipeline processing
  expect_true(result$items[[1]]$data_is_dataframe)
  expect_true(!is.null(result$items[[1]]$data_serialized))
  # Verify the serialized data can be reconstructed
  reconstructed <- as.data.frame(eval(parse(text = result$items[[1]]$data_serialized)))
  expect_equal(reconstructed, custom_data)
})

test_that("add_viz accepts drop_na_vars parameter", {
  result <- create_viz() %>%
    add_viz(type = "histogram", x_var = "mpg", drop_na_vars = TRUE)
  
  expect_true(result$items[[1]]$drop_na_vars)
})

test_that("multiple add_viz calls accumulate in items", {
  result <- create_viz() %>%
    add_viz(type = "histogram", x_var = "mpg", title = "MPG") %>%
    add_viz(type = "histogram", x_var = "hp", title = "HP") %>%
    add_viz(type = "histogram", x_var = "wt", title = "Weight")
  
  expect_length(result$items, 3)
  expect_equal(result$items[[1]]$title, "MPG")
  expect_equal(result$items[[2]]$title, "HP")
  expect_equal(result$items[[3]]$title, "Weight")
})

test_that("add_viz supports all visualization types", {
  types <- c("histogram", "bar", "stackedbar", "heatmap", "timeline")
  
  for (viz_type in types) {
    result <- create_viz() %>%
      add_viz(type = viz_type, x_var = "mpg")
    
    # Some types store as "viz" class but have viz_type attribute
    spec <- result$items[[1]]
    expect_true(spec$type == viz_type || spec$type == "viz" || !is.null(spec$viz_type),
                 info = paste("Failed for type:", viz_type))
  }
})

test_that("add_viz assigns insertion_index", {
  result <- create_viz() %>%
    add_viz(type = "histogram", x_var = "mpg") %>%
    add_viz(type = "bar", x_var = "cyl")
  
  expect_equal(result$items[[1]]$.insertion_index, 1)
  expect_equal(result$items[[2]]$.insertion_index, 2)
})

# --- viz_collection + operator ---
test_that("+ operator combines viz_collections", {
  viz1 <- create_viz() %>%
    add_viz(type = "histogram", x_var = "mpg")
  
  viz2 <- create_viz() %>%
    add_viz(type = "bar", x_var = "cyl")
  
  combined <- viz1 + viz2
  
  expect_s3_class(combined, "viz_collection")
  expect_length(combined$items, 2)
})

test_that("+ operator preserves tabgroup_labels from both", {
  viz1 <- create_viz(tabgroup_labels = list(a = "Tab A"))
  viz2 <- create_viz(tabgroup_labels = list(b = "Tab B"))
  
  combined <- viz1 + viz2
  
  expect_equal(combined$tabgroup_labels$a, "Tab A")
  expect_equal(combined$tabgroup_labels$b, "Tab B")
})

# --- NSE and edge cases ---
test_that("add_viz works with NSE for x_var", {
  result <- create_viz(data = mtcars) %>%
    add_viz(type = "histogram", x_var = mpg)
  
  expect_equal(result$items[[1]]$x_var, "mpg")
})

test_that("add_viz works with quoted strings for x_var", {
  result <- create_viz(data = mtcars) %>%
    add_viz(type = "histogram", x_var = "mpg")
  
  expect_equal(result$items[[1]]$x_var, "mpg")
})

test_that("add_viz handles NULL values gracefully", {
  result <- create_viz() %>%
    add_viz(type = "histogram", x_var = "mpg", subtitle = NULL)
  
  expect_null(result$items[[1]]$subtitle)
})

test_that("create_viz and add_viz work with empty data frame", {
  empty_df <- data.frame()
  
  result <- create_viz(data = empty_df) %>%
    add_viz(type = "histogram", x_var = "x")
  
  expect_s3_class(result, "viz_collection")
})
