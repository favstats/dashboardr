# Test combine_content data merging behavior

test_that("combine_content with same data deduplicates to single dataset", {
  df <- data.frame(x = 1:10, y = letters[1:10])
  
  c1 <- create_content(data = df) %>%
    add_viz(type = "histogram", x_var = "x", tabgroup = "tab1")
  
  c2 <- create_content(data = df) %>%
    add_viz(type = "histogram", x_var = "x", tabgroup = "tab2")
  
  combined <- c1 + c2
  
  # Should have single dataset (deduplicated), not a named list

  expect_true(is.data.frame(combined$data))
  expect_equal(nrow(combined$data), 10)
  
  # Viz items should NOT have data attribute (single dataset mode uses "data" default)
  expect_null(combined$items[[1]][["data"]])
  expect_null(combined$items[[2]][["data"]])
  
  # Should have 2 viz items
  expect_equal(length(combined$items), 2)
})

test_that("combine_content with different data creates multi-dataset", {
  df1 <- data.frame(x = 1:10, y = letters[1:10])
  df2 <- data.frame(x = 11:20, y = letters[11:20])
  
  c1 <- create_content(data = df1) %>%
    add_viz(type = "histogram", x_var = "x", tabgroup = "dataset1")
  
  c2 <- create_content(data = df2) %>%
    add_viz(type = "histogram", x_var = "x", tabgroup = "dataset2")
  
  combined <- c1 + c2
  
  # Should have named list of datasets
  expect_true(is.list(combined$data))
  expect_false(is.data.frame(combined$data))
  expect_equal(length(combined$data), 2)
  expect_true("data_1" %in% names(combined$data))
  expect_true("data_2" %in% names(combined$data))
  
  # Verify data integrity
  expect_equal(nrow(combined$data$data_1), 10)
  expect_equal(nrow(combined$data$data_2), 10)
  expect_equal(combined$data$data_1$x[1], 1)
  expect_equal(combined$data$data_2$x[1], 11)
  
  # Viz items should have data attribute pointing to their source
  expect_equal(combined$items[[1]][["data"]], "data_1")
  expect_equal(combined$items[[2]][["data"]], "data_2")
})

test_that("combine_content with data + no data uses available dataset", {
  df <- data.frame(x = 1:10, y = letters[1:10])
  
  c1 <- create_content(data = df) %>%
    add_viz(type = "histogram", x_var = "x", tabgroup = "with_data")
  
  c2 <- create_content() %>%  # No data
    add_viz(type = "histogram", x_var = "x", tabgroup = "no_data")
  
  combined <- c1 + c2
  
  # Should have single dataset (only c1 had data)
  expect_true(is.data.frame(combined$data))
  expect_equal(nrow(combined$data), 10)
  
  # Both viz items should have no data attribute (single dataset mode)
  expect_null(combined$items[[1]][["data"]])
  expect_null(combined$items[[2]][["data"]])
})

test_that("combine_content with no data + data uses available dataset", {
  df <- data.frame(x = 1:10, y = letters[1:10])
  
  c1 <- create_content() %>%  # No data
    add_viz(type = "histogram", x_var = "x", tabgroup = "no_data")
  
  c2 <- create_content(data = df) %>%
    add_viz(type = "histogram", x_var = "x", tabgroup = "with_data")
  
  combined <- c1 + c2
  
  # Should have single dataset (only c2 had data)
  expect_true(is.data.frame(combined$data))
  expect_equal(nrow(combined$data), 10)
  
  # Both viz items should have no data attribute (single dataset mode)
  expect_null(combined$items[[1]][["data"]])
  expect_null(combined$items[[2]][["data"]])
})

test_that("combine_content with neither having data results in NULL data", {
  c1 <- create_content() %>%
    add_viz(type = "histogram", x_var = "x", tabgroup = "tab1")
  
  c2 <- create_content() %>%
    add_viz(type = "histogram", x_var = "x", tabgroup = "tab2")
  
  combined <- c1 + c2
  
  expect_null(combined$data)
  expect_equal(length(combined$items), 2)
})

test_that("combine_content with three different datasets works", {
  df1 <- data.frame(a = 1:5)
  df2 <- data.frame(b = 6:10)
  df3 <- data.frame(c = 11:15)
  
  c1 <- create_content(data = df1) %>%
    add_viz(type = "histogram", x_var = "a")
  
  c2 <- create_content(data = df2) %>%
    add_viz(type = "histogram", x_var = "b")
  
  c3 <- create_content(data = df3) %>%
    add_viz(type = "histogram", x_var = "c")
  
  combined <- c1 + c2 + c3
  
  # Should have 3 datasets
  expect_equal(length(combined$data), 3)
  expect_true("data_1" %in% names(combined$data))
  expect_true("data_2" %in% names(combined$data))
  expect_true("data_3" %in% names(combined$data))
  
  # Each viz should point to its source dataset
  expect_equal(combined$items[[1]][["data"]], "data_1")
  expect_equal(combined$items[[2]][["data"]], "data_2")
  expect_equal(combined$items[[3]][["data"]], "data_3")
})

test_that("combine_content preserves explicit viz data attribute", {
  df1 <- data.frame(x = 1:10)
  df2 <- data.frame(y = 11:20)
  
  # Viz explicitly specifies which dataset to use
  c1 <- create_content(data = df1) %>%
    add_viz(type = "histogram", x_var = "x", data = "custom_name")
  
  c2 <- create_content(data = df2) %>%
    add_viz(type = "histogram", x_var = "y")
  
  combined <- c1 + c2
  
  # First viz should keep its explicit data attribute
  expect_equal(combined$items[[1]][["data"]], "custom_name")
  # Second viz gets auto-assigned
  expect_equal(combined$items[[2]][["data"]], "data_2")
})

test_that("combine_content with mix of collections deduplicates identical data", {
  df <- data.frame(x = 1:10, y = letters[1:10])
  df_different <- data.frame(x = 100:110)
  
  c1 <- create_content(data = df) %>%
    add_viz(type = "histogram", x_var = "x")
  
  c2 <- create_content(data = df) %>%  # Same data as c1
    add_viz(type = "histogram", x_var = "y")
  
  c3 <- create_content(data = df_different) %>%
    add_viz(type = "histogram", x_var = "x")
  
  combined <- c1 + c2 + c3
  
  # Should have 2 unique datasets (df was deduplicated)
  expect_equal(length(combined$data), 2)
  
  # First two vizzes should point to same dataset
  expect_equal(combined$items[[1]][["data"]], combined$items[[2]][["data"]])
  # Third viz should point to different dataset
  expect_false(combined$items[[1]][["data"]] == combined$items[[3]][["data"]])
})
