library(testthat)

test_that("manual layout row rejects tabgroup child markers", {
  exp <- fm_unsupported_expectation("manual_layout_row_tabgroup_child")

  temp_dir <- tempfile("layout_tabgroup_matrix_")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  content <- create_content() |>
    add_layout_column() |>
    add_layout_row() |>
    add_viz(type = "bar", x_var = "cyl", tabgroup = "bad/tab", title = "Bad") |>
    end_layout_row() |>
    end_layout_column()

  proj <- create_dashboard(output_dir = temp_dir, title = "layout tabgroup", allow_inside_pkg = TRUE) |>
    add_page("Layout", data = mtcars, content = content)

  expect_error(
    generate_dashboard(proj, render = FALSE, open = FALSE, quiet = TRUE),
    exp$message
  )
})

test_that("manual layout row rejects pagination markers", {
  exp <- fm_unsupported_expectation("manual_layout_row_pagination_child")

  temp_dir <- tempfile("layout_pagination_matrix_")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  content <- create_content() |>
    add_layout_column() |>
    add_layout_row() |>
    add_text("Before") |>
    add_pagination() |>
    add_text("After") |>
    end_layout_row() |>
    end_layout_column()

  proj <- create_dashboard(output_dir = temp_dir, title = "layout pagination", allow_inside_pkg = TRUE) |>
    add_page("Layout", data = mtcars, content = content)

  expect_error(
    generate_dashboard(proj, render = FALSE, open = FALSE, quiet = TRUE),
    exp$message
  )
})

test_that("sidebar + manual layout + show_when render required structure", {
  temp_dir <- tempfile("layout_sidebar_matrix_")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  content <- create_content(data = mtcars) |>
    add_sidebar(position = "left", title = "Filters") |>
    add_filter(filter_var = "cyl", type = "checkbox") |>
    end_sidebar() |>
    add_layout_column(class = "matrix-col") |>
    add_layout_row(class = "matrix-row", show_when = ~ cyl == 6) |>
    add_table(head(mtcars), filter_vars = "cyl") |>
    end_layout_row() |>
    end_layout_column()

  proj <- create_dashboard(output_dir = temp_dir, title = "layout sidebar", allow_inside_pkg = TRUE, backend = "plotly") |>
    add_page("Layout", data = mtcars, content = content)

  expect_no_error(generate_dashboard(proj, render = FALSE, open = FALSE, quiet = TRUE))

  qmd <- readLines(file.path(temp_dir, "layout.qmd"), warn = FALSE)
  expect_true(any(grepl("^## Column", qmd)))
  expect_true(any(grepl("^### Row", qmd)))
  expect_true(any(grepl("show_when_open\\(", qmd)))
})
