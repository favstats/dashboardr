# Tests for viz_collection.R — lightweight, covr-safe
# Targets: create_viz, add_viz, combine_content, add_vizzes, validate_specs,
#          set_tabgroup_labels, spec_viz, print methods, + operator
library(testthat)

# --- create_viz ---

test_that("create_viz returns viz_collection", {
  vc <- create_viz()
  expect_s3_class(vc, "viz_collection")
  expect_equal(length(vc$items), 0)
})

test_that("create_viz with data", {
  vc <- create_viz(data = mtcars)
  expect_true(is.data.frame(vc$data))
})

test_that("create_viz with tabgroup_labels", {
  vc <- create_viz(tabgroup_labels = list("t1" = "Tab 1", "t2" = "Tab 2"))
  expect_equal(vc$tabgroup_labels[["t1"]], "Tab 1")
})

test_that("create_viz with shared_first_level FALSE", {
  vc <- create_viz(shared_first_level = FALSE)
  expect_false(vc$shared_first_level)
})

test_that("create_viz with default parameters", {
  vc <- create_viz(data = mtcars, x_var = "mpg", color_palette = c("red", "blue"))
  expect_equal(vc$defaults$x_var, "mpg")
  expect_equal(vc$defaults$color_palette, c("red", "blue"))
})

# --- add_viz.default ---

test_that("add_viz basic bar", {
  vc <- create_viz(data = mtcars) |>
    add_viz(type = "bar", x_var = "cyl")
  expect_equal(length(vc$items), 1)
  expect_equal(vc$items[[1]]$viz_type, "bar")
})

test_that("add_viz with title and tabgroup", {
  vc <- create_viz(data = mtcars) |>
    add_viz(type = "histogram", x_var = "mpg", title = "MPG Dist",
            tabgroup = "Overview")
  expect_equal(vc$items[[1]]$title, "MPG Dist")
  expect_true(!is.null(vc$items[[1]]$tabgroup))
})

test_that("add_viz with text parameters", {
  vc <- create_viz(data = mtcars) |>
    add_viz(type = "bar", x_var = "cyl",
            text = "Chart description",
            text_before_viz = "Before the chart",
            text_after_viz = "After the chart")
  expect_equal(vc$items[[1]]$text, "Chart description")
  expect_equal(vc$items[[1]]$text_before_viz, "Before the chart")
})

test_that("add_viz with height", {
  vc <- create_viz(data = mtcars) |>
    add_viz(type = "bar", x_var = "cyl", height = 600)
  expect_equal(vc$items[[1]]$height, 600)
})

test_that("add_viz multiple specs", {
  vc <- create_viz(data = mtcars) |>
    add_viz(type = "bar", x_var = "cyl") |>
    add_viz(type = "histogram", x_var = "mpg") |>
    add_viz(type = "pie", x_var = "gear")
  expect_equal(length(vc$items), 3)
})

test_that("add_viz with different tabgroups", {
  vc <- create_viz(data = mtcars) |>
    add_viz(type = "bar", x_var = "cyl", tabgroup = "Tab A") |>
    add_viz(type = "bar", x_var = "gear", tabgroup = "Tab B")
  expect_equal(length(vc$items), 2)
})

test_that("add_viz with nested tabgroup (slash notation)", {
  vc <- create_viz(data = mtcars) |>
    add_viz(type = "bar", x_var = "cyl", tabgroup = "Main/Sub")
  expect_equal(length(vc$items), 1)
})

test_that("add_viz with drop_na_vars", {
  vc <- create_viz(data = mtcars) |>
    add_viz(type = "bar", x_var = "cyl", drop_na_vars = TRUE)
  expect_true(vc$items[[1]]$drop_na_vars)
})

test_that("add_viz with filter", {
  vc <- create_viz(data = mtcars) |>
    add_viz(type = "bar", x_var = "cyl", filter = ~ cyl > 4)
  expect_true(!is.null(vc$items[[1]]$filter))
})

test_that("add_viz with per-viz data", {
  sub_data <- mtcars[mtcars$cyl == 4, ]
  vc <- create_viz() |>
    add_viz(type = "bar", x_var = "cyl", data = sub_data)
  expect_true(vc$items[[1]]$data_is_dataframe)
})

test_that("add_viz inherits defaults from create_viz", {
  vc <- create_viz(data = mtcars, color_palette = c("#ff0000")) |>
    add_viz(type = "bar", x_var = "cyl")
  expect_equal(vc$items[[1]]$color_palette, c("#ff0000"))
})

test_that("add_viz with show_when formula", {
  vc <- create_viz(data = mtcars) |>
    add_viz(type = "bar", x_var = "cyl", show_when = ~ country == "US")
  expect_true(!is.null(vc$items[[1]]$show_when))
})

# --- combine_content / + operator ---

test_that("combine_content two collections", {
  vc1 <- create_viz(data = mtcars) |>
    add_viz(type = "bar", x_var = "cyl")
  vc2 <- create_viz(data = iris) |>
    add_viz(type = "histogram", x_var = "Sepal.Length")
  combined <- combine_content(vc1, vc2)
  expect_equal(length(combined$items), 2)
})

test_that("combine_content with empty collections", {
  vc1 <- create_viz()
  vc2 <- create_viz(data = mtcars) |>
    add_viz(type = "bar", x_var = "cyl")
  combined <- combine_content(vc1, vc2)
  expect_equal(length(combined$items), 1)
})

test_that("combine_content no arguments", {
  result <- combine_content()
  expect_s3_class(result, "viz_collection")
  expect_equal(length(result$items), 0)
})

test_that("+ operator combines viz collections", {
  vc1 <- create_viz(data = mtcars) |>
    add_viz(type = "bar", x_var = "cyl")
  vc2 <- create_viz(data = mtcars) |>
    add_viz(type = "pie", x_var = "gear")
  combined <- vc1 + vc2
  expect_equal(length(combined$items), 2)
})

test_that("+ operator chains three collections", {
  vc1 <- create_viz() |> add_text("A")
  vc2 <- create_viz() |> add_text("B")
  vc3 <- create_viz() |> add_text("C")
  combined <- vc1 + vc2 + vc3
  expect_equal(length(combined$items), 3)
})

test_that("combine_content preserves tabgroup_labels", {
  vc1 <- create_viz(tabgroup_labels = list("t1" = "First"))
  vc2 <- create_viz(tabgroup_labels = list("t2" = "Second"))
  combined <- combine_content(vc1, vc2)
  expect_true("t1" %in% names(combined$tabgroup_labels) ||
              "t2" %in% names(combined$tabgroup_labels))
})

# --- set_tabgroup_labels ---

test_that("set_tabgroup_labels updates labels", {
  vc <- create_viz() |>
    add_viz(type = "bar", x_var = "cyl", tabgroup = "grp1") |>
    set_tabgroup_labels(grp1 = "Group One")
  expect_equal(vc$tabgroup_labels[["grp1"]], "Group One")
})

test_that("set_tabgroup_labels multiple labels", {
  vc <- create_viz() |>
    set_tabgroup_labels(a = "Alpha", b = "Beta", c = "Gamma")
  expect_equal(vc$tabgroup_labels[["a"]], "Alpha")
  expect_equal(vc$tabgroup_labels[["c"]], "Gamma")
})

# --- spec_viz ---

test_that("spec_viz creates a viz spec", {
  s <- spec_viz(type = "bar", x_var = "cyl")
  expect_true(is.list(s))
})

# --- add_vizzes ---

test_that("add_vizzes expands vector parameters", {
  vc <- create_viz(data = mtcars) |>
    add_vizzes(type = "histogram", x_var = c("mpg", "hp", "wt"))
  expect_equal(length(vc$items), 3)
})

test_that("add_vizzes with tabgroup", {
  vc <- create_viz(data = mtcars) |>
    add_vizzes(type = "bar", x_var = c("cyl", "gear"), tabgroup = "Cars")
  expect_equal(length(vc$items), 2)
})

# --- validate_specs ---

test_that("validate_specs on valid collection", {
  vc <- create_viz(data = mtcars) |>
    add_viz(type = "bar", x_var = "cyl")
  result <- validate_specs(vc)
  # Should return something -- either TRUE or a list of issues
  expect_true(!is.null(result))
})

test_that("validate_specs on empty collection", {
  vc <- create_viz()
  result <- validate_specs(vc)
  expect_true(!is.null(result))
})

# --- print.viz_collection ---

test_that("print.viz_collection works", {
  vc <- create_viz(data = mtcars) |>
    add_viz(type = "bar", x_var = "cyl") |>
    add_viz(type = "pie", x_var = "gear")
  # Just check it doesn't error
  expect_output(print(vc))
})

test_that("print.viz_collection with text items", {
  vc <- create_viz() |>
    add_text("Hello") |>
    add_divider()
  expect_output(print(vc))
})

test_that("print.viz_collection with tabgroups", {
  vc <- create_viz(data = mtcars) |>
    add_viz(type = "bar", x_var = "cyl", tabgroup = "A") |>
    add_viz(type = "bar", x_var = "gear", tabgroup = "B")
  expect_output(print(vc))
})

# --- add_pagination ---

test_that("add_pagination adds pagination break", {
  vc <- create_viz(data = mtcars) |>
    add_viz(type = "bar", x_var = "cyl") |>
    add_pagination() |>
    add_viz(type = "pie", x_var = "gear")
  # Should have 3 items (viz, pagination, viz)
  expect_equal(length(vc$items), 3)
})

# --- Mixed content and viz pipeline ---

test_that("mixed viz and content pipeline", {
  vc <- create_viz(data = mtcars) |>
    add_text("# Analysis") |>
    add_viz(type = "bar", x_var = "cyl") |>
    add_divider() |>
    add_viz(type = "histogram", x_var = "mpg") |>
    add_text("## Conclusion")
  expect_equal(length(vc$items), 5)
})

test_that("viz collection with content blocks", {
  vc <- create_viz(data = mtcars) |>
    add_text("Introduction text") |>
    add_callout("Warning: preliminary data", type = "warning") |>
    add_viz(type = "bar", x_var = "cyl", title = "Cylinders") |>
    add_code("summary(mtcars)") |>
    add_spacer() |>
    add_quote("Data drives decisions")
  expect_equal(length(vc$items), 6)
})
