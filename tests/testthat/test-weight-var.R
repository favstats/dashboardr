test_that("viz_histogram accepts weight_var parameter", {
  data <- data.frame(
    x = c(1, 2, 3, 1, 2, 3),
    weight = c(1, 2, 3, 1, 2, 3)
  )
  
  viz <- create_viz(type = "histogram", x_var = "x", weight_var = "weight") %>%
    add_viz(title = "Weighted Histogram")
  
  expect_s3_class(viz, "viz_collection")
  expect_equal(viz$items[[1]]$weight_var, "weight")
})

test_that("viz_bar accepts weight_var parameter", {
  data <- data.frame(
    category = c("A", "B", "A", "B"),
    weight = c(1, 2, 1, 2)
  )
  
  viz <- create_viz(type = "bar", x_var = "category", weight_var = "weight") %>%
    add_viz(title = "Weighted Bar")
  
  expect_s3_class(viz, "viz_collection")
  expect_equal(viz$items[[1]]$weight_var, "weight")
})

test_that("viz_stackedbar accepts weight_var parameter", {
  data <- data.frame(
    response = c(1, 2, 3, 1, 2, 3),
    group = c("A", "A", "A", "B", "B", "B"),
    weight = c(1, 2, 3, 1, 2, 3)
  )
  
  viz <- create_viz(
    type = "stackedbar", 
    x_var = "response",
    stack_var = "group",
    weight_var = "weight"
  ) %>%
    add_viz(title = "Weighted Stacked Bar")
  
  expect_s3_class(viz, "viz_collection")
  expect_equal(viz$items[[1]]$weight_var, "weight")
})

test_that("viz_timeline accepts weight_var parameter", {
  data <- data.frame(
    time = c(1, 2, 3, 1, 2, 3),
    response = c(1, 2, 3, 1, 2, 3),
    weight = c(1, 2, 3, 1, 2, 3)
  )
  
  viz <- create_viz(
    type = "timeline",
    time_var = "time",
    y_var = "response",
    weight_var = "weight"
  ) %>%
    add_viz(title = "Weighted Timeline")
  
  expect_s3_class(viz, "viz_collection")
  expect_equal(viz$items[[1]]$weight_var, "weight")
})

test_that("viz_heatmap accepts weight_var parameter", {
  data <- data.frame(
    x = c("A", "B", "A", "B"),
    y = c("X", "X", "Y", "Y"),
    value = c(1, 2, 3, 4),
    weight = c(1, 2, 1, 2)
  )
  
  viz <- create_viz(
    type = "heatmap",
    x_var = "x",
    y_var = "y",
    value_var = "value",
    weight_var = "weight"
  ) %>%
    add_viz(title = "Weighted Heatmap")
  
  expect_s3_class(viz, "viz_collection")
  expect_equal(viz$items[[1]]$weight_var, "weight")
})

test_that("weight_var defaults to NULL when not specified", {
  data <- data.frame(x = 1:10)
  
  viz <- create_viz(type = "histogram", x_var = "x") %>%
    add_viz(title = "Unweighted")
  
  expect_true(is.null(viz$items[[1]]$weight_var))
})

test_that("weight_var can be set via create_viz defaults", {
  data <- data.frame(
    x = c(1, 2, 3, 1, 2, 3),
    weight = c(1, 2, 3, 1, 2, 3)
  )
  
  viz <- create_viz(type = "histogram", x_var = "x", weight_var = "weight") %>%
    add_viz(title = "Viz 1") %>%
    add_viz(title = "Viz 2")
  
  expect_equal(viz$items[[1]]$weight_var, "weight")
  expect_equal(viz$items[[2]]$weight_var, "weight")
})

test_that("weight_var can be overridden in add_viz", {
  data <- data.frame(
    x = c(1, 2, 3),
    weight1 = c(1, 1, 1),
    weight2 = c(2, 2, 2)
  )
  
  viz <- create_viz(type = "histogram", x_var = "x", weight_var = "weight1") %>%
    add_viz(title = "Default weight") %>%
    add_viz(title = "Override weight", weight_var = "weight2")
  
  expect_equal(viz$items[[1]]$weight_var, "weight1")
  expect_equal(viz$items[[2]]$weight_var, "weight2")
})

