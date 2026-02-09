# Tests for viz_generation.R internal functions — lightweight, covr-safe
# These test code-generation helpers that produce strings (no HTML rendering)
library(testthat)

# Access internal functions
.split_by_pagination <- dashboardr:::.split_by_pagination

# --- .split_by_pagination ---

test_that(".split_by_pagination with no pagination markers", {
  specs <- list(
    list(type = "viz", viz_type = "bar", x_var = "cyl"),
    list(type = "viz", viz_type = "pie", x_var = "gear")
  )
  result <- .split_by_pagination(specs)
  expect_equal(length(result), 1)
  expect_equal(length(result[[1]]$items), 2)
  expect_null(result[[1]]$pagination_after)
})

test_that(".split_by_pagination with one pagination break", {
  specs <- list(
    list(type = "viz", viz_type = "bar", x_var = "cyl"),
    list(pagination_break = TRUE),
    list(type = "viz", viz_type = "pie", x_var = "gear")
  )
  result <- .split_by_pagination(specs)
  expect_equal(length(result), 2)
  expect_equal(length(result[[1]]$items), 1)
  expect_true(!is.null(result[[1]]$pagination_after))
  expect_equal(length(result[[2]]$items), 1)
  expect_null(result[[2]]$pagination_after)
})

test_that(".split_by_pagination with multiple breaks", {
  specs <- list(
    list(type = "viz", viz_type = "bar"),
    list(pagination_break = TRUE),
    list(type = "viz", viz_type = "pie"),
    list(pagination_break = TRUE),
    list(type = "viz", viz_type = "scatter")
  )
  result <- .split_by_pagination(specs)
  expect_equal(length(result), 3)
})

test_that(".split_by_pagination empty specs", {
  result <- .split_by_pagination(list())
  expect_equal(length(result), 0)
})

test_that(".split_by_pagination consecutive breaks (no items between)", {
  specs <- list(
    list(type = "viz", viz_type = "bar"),
    list(pagination_break = TRUE),
    list(pagination_break = TRUE),
    list(type = "viz", viz_type = "pie")
  )
  result <- .split_by_pagination(specs)
  # First section has 1 item + pagination_after
  expect_equal(length(result[[1]]$items), 1)
})

# --- .generate_viz_from_specs ---

test_that(".generate_viz_from_specs generates code for basic viz", {
  .generate_viz_from_specs <- dashboardr:::.generate_viz_from_specs
  specs <- list(
    list(type = "viz", viz_type = "bar", x_var = "cyl", data_path = "data.rds")
  )
  result <- .generate_viz_from_specs(specs)
  expect_true(is.character(result))
  expect_true(length(result) > 0)
})

test_that(".generate_viz_from_specs skips pagination markers", {
  .generate_viz_from_specs <- dashboardr:::.generate_viz_from_specs
  specs <- list(
    list(type = "viz", viz_type = "bar", x_var = "cyl", data_path = "data.rds"),
    list(pagination_break = TRUE),
    list(type = "viz", viz_type = "pie", x_var = "gear", data_path = "data.rds")
  )
  result <- .generate_viz_from_specs(specs)
  expect_true(is.character(result))
})

test_that(".generate_viz_from_specs handles content blocks", {
  .generate_viz_from_specs <- dashboardr:::.generate_viz_from_specs
  specs <- list(
    list(type = "text", content = "Hello world"),
    list(type = "divider", style = "default")
  )
  result <- .generate_viz_from_specs(specs)
  expect_true(is.character(result))
})

test_that(".generate_viz_from_specs with lazy loading", {
  .generate_viz_from_specs <- dashboardr:::.generate_viz_from_specs
  specs <- list(
    list(type = "viz", viz_type = "bar", x_var = "cyl", data_path = "data.rds")
  )
  result <- .generate_viz_from_specs(specs, lazy_load_charts = TRUE)
  expect_true(is.character(result))
})

test_that(".generate_viz_from_specs does not wrap viz calls by default", {
  .generate_viz_from_specs <- dashboardr:::.generate_viz_from_specs
  specs <- list(
    list(type = "viz", viz_type = "bar", x_var = "cyl", data_path = "data.rds")
  )
  result <- .generate_viz_from_specs(specs)
  expect_false(any(grepl("result <- tryCatch\\(\\{", result)))
})

test_that(".generate_viz_from_specs wraps viz calls when contextual_viz_errors is TRUE", {
  .generate_viz_from_specs <- dashboardr:::.generate_viz_from_specs
  specs <- list(
    list(type = "viz", viz_type = "bar", x_var = "cyl", data_path = "data.rds")
  )
  result <- .generate_viz_from_specs(specs, contextual_viz_errors = TRUE)
  expect_true(any(grepl("result <- tryCatch\\(\\{", result)))
  expect_true(any(grepl("Visualization failed \\('", result)))
})

test_that(".generate_viz_from_specs dashboard layout defaults to one chart per row", {
  .generate_viz_from_specs <- dashboardr:::.generate_viz_from_specs
  specs <- list(
    list(type = "viz", viz_type = "bar", x_var = "cyl", data_path = "data.rds", title = "A"),
    list(type = "viz", viz_type = "pie", x_var = "gear", data_path = "data.rds", title = "B")
  )
  result <- .generate_viz_from_specs(specs, dashboard_layout = TRUE, heading_level = 4)
  row_markers <- sum(grepl("^### Row$", result))
  expect_equal(row_markers, 2)
})

# --- viz_processing: .process_visualizations ---

test_that(".process_visualizations with viz_collection", {
  .process_visualizations <- dashboardr:::.process_visualizations
  vc <- create_viz(data = mtcars) |>
    add_viz(type = "bar", x_var = "cyl") |>
    add_viz(type = "pie", x_var = "gear")
  result <- .process_visualizations(vc, data_path = "test.rds")
  expect_true(is.list(result))
})

test_that(".process_visualizations with empty collection returns NULL", {
  .process_visualizations <- dashboardr:::.process_visualizations
  vc <- create_viz()
  result <- .process_visualizations(vc, data_path = "test.rds")
  expect_null(result)
})

test_that(".process_visualizations with tabgroups", {
  .process_visualizations <- dashboardr:::.process_visualizations
  vc <- create_viz(data = mtcars) |>
    add_viz(type = "bar", x_var = "cyl", tabgroup = "Tab1") |>
    add_viz(type = "pie", x_var = "gear", tabgroup = "Tab2")
  result <- .process_visualizations(vc, data_path = "test.rds")
  expect_true(is.list(result))
})

test_that(".process_visualizations with tabgroup_labels", {
  .process_visualizations <- dashboardr:::.process_visualizations
  vc <- create_viz(data = mtcars,
                   tabgroup_labels = list("Tab1" = "First Tab")) |>
    add_viz(type = "bar", x_var = "cyl", tabgroup = "Tab1")
  result <- .process_visualizations(vc, data_path = "test.rds",
                                      tabgroup_labels = list("Tab1" = "First Tab"))
  expect_true(is.list(result))
})

test_that(".process_visualizations with plain list", {
  .process_visualizations <- dashboardr:::.process_visualizations
  specs <- list(
    list(type = "viz", viz_type = "bar", x_var = "cyl")
  )
  result <- .process_visualizations(specs, data_path = "test.rds")
  expect_true(is.list(result))
})

test_that(".process_visualizations attaches data_path", {
  .process_visualizations <- dashboardr:::.process_visualizations
  specs <- list(
    list(type = "viz", viz_type = "bar", x_var = "cyl")
  )
  result <- .process_visualizations(specs, data_path = "my_data.rds")
  # The result should have data_path attached to specs
  expect_true(is.list(result))
})
