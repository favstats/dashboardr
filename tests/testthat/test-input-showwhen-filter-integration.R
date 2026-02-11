library(testthat)

test_that("add_filter creates expected input metadata", {
  content <- create_content(data = mtcars) |>
    add_filter(filter_var = "cyl", type = "checkbox")

  expect_true(length(content$items) >= 1)
  input <- content$items[[1]]
  expect_identical(input$type, "input")
  expect_identical(input$input_id, "cyl_filter")
  expect_identical(input$filter_var, "cyl")
})

test_that("add_plotly and add_leaflet validate input classes", {
  expect_error(add_plotly(create_content(), plot = mtcars), "plot must be a plotly object")
  expect_error(add_leaflet(create_content(), map = mtcars), "map must be a leaflet object")
})

test_that("add_leaflet rejects filter_vars consistently with matrix policy", {
  exp <- fm_unsupported_expectation("leaflet_filter_vars_unsupported")
  skip_if_not_installed("leaflet")

  m <- leaflet::leaflet() |>
    leaflet::addTiles()

  expect_error(
    add_leaflet(create_content(data = mtcars), map = m, filter_vars = "cyl"),
    exp$message
  )
})

test_that("add_plotly and add_leaflet wrappers add widget blocks when packages exist", {
  if (requireNamespace("plotly", quietly = TRUE)) {
    p <- plotly::plot_ly(mtcars, x = ~wt, y = ~mpg)
    content_plotly <- create_content(data = mtcars) |>
      add_plotly(plot = p, tabgroup = "widgets/plotly", show_when = ~ cyl == 6, filter_vars = "cyl")
    expect_identical(content_plotly$items[[1]]$type, "widget")
    expect_identical(content_plotly$items[[1]]$widget_class, "plotly")
  }

  if (requireNamespace("leaflet", quietly = TRUE)) {
    m <- leaflet::leaflet() |>
      leaflet::addTiles()
    content_leaflet <- create_content(data = mtcars) |>
      add_leaflet(map = m, tabgroup = "widgets/leaflet", show_when = ~ cyl == 6)
    expect_identical(content_leaflet$items[[1]]$type, "widget")
    expect_identical(content_leaflet$items[[1]]$widget_class, "leaflet")
  }
})

test_that("add_widget supports tabgroup/show_when and filter_vars", {
  if (!requireNamespace("plotly", quietly = TRUE)) {
    skip("plotly not installed")
  }

  widget <- plotly::plot_ly(mtcars, x = ~wt, y = ~mpg)
  content <- create_content(data = mtcars) |>
    add_widget(
      widget = widget,
      tabgroup = "widgets/main",
      show_when = ~ cyl == 6,
      filter_vars = "cyl"
    )

  block <- content$items[[length(content$items)]]
  expect_identical(block$type, "widget")
  expect_identical(block$widget_class, "plotly")
  expect_identical(block$filter_vars, "cyl")
  expect_true(inherits(block$show_when, "formula"))
})

test_that("add_reset_button renders expected attributes", {
  out <- add_reset_button(targets = c("a", "b"), label = "Reset", size = "sm")
  txt <- as.character(out)
  expect_true(grepl('data-targets="a,b"', txt, fixed = TRUE))
  expect_true(grepl("Reset", txt, fixed = TRUE))
})

test_that("show_when and filter_vars survive generation together", {
  skip_on_covr_ci()
  temp_dir <- tempfile("showwhen_filter_matrix_")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  content <- create_content(data = mtcars) |>
    add_sidebar(position = "left", title = "Filters") |>
    add_filter(filter_var = "cyl", type = "checkbox") |>
    end_sidebar() |>
    add_table(head(mtcars), filter_vars = "cyl", show_when = ~ cyl == 6) |>
    add_viz(type = "bar", x_var = "cyl", show_when = ~ cyl == 6, title = "Cyl")

  proj <- create_dashboard(output_dir = temp_dir, title = "integration", allow_inside_pkg = TRUE, backend = "plotly") |>
    add_page("Integration", data = mtcars, content = content)

  expect_no_error(generate_dashboard(proj, render = FALSE, open = FALSE, quiet = TRUE))

  qmd <- readLines(file.path(temp_dir, "integration.qmd"), warn = FALSE)
  expect_true(any(grepl("show_when_open\\(", qmd)))
  expect_true(any(grepl("filter_vars\\s*=", qmd)))
})

test_that("layout_row/layout_column can host show_when and filter-aware blocks", {
  skip_on_covr_ci()
  temp_dir <- tempfile("showwhen_layout_matrix_")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  content <- create_content(data = mtcars) |>
    add_layout_column(class = "combo-col") |>
    add_layout_row(class = "combo-row", show_when = ~ cyl == 6) |>
    add_table(head(mtcars), filter_vars = "cyl") |>
    end_layout_row() |>
    end_layout_column()

  proj <- create_dashboard(output_dir = temp_dir, title = "layout combo", allow_inside_pkg = TRUE) |>
    add_page("Layout Combo", data = mtcars, content = content)

  expect_no_error(generate_dashboard(proj, render = FALSE, open = FALSE, quiet = TRUE))

  qmd <- readLines(file.path(temp_dir, "layout_combo.qmd"), warn = FALSE)
  expect_true(any(grepl("^## Column", qmd)))
  expect_true(any(grepl("^### Row", qmd)))
  expect_true(any(grepl("show_when_open\\(", qmd)))
  expect_true(any(grepl("filter_vars\\s*=", qmd)))
})

test_that("add_plotly tabgroup inside manual layout row is rejected", {
  skip_on_covr_ci()
  exp <- fm_unsupported_expectation("manual_layout_row_tabgroup_child")
  skip_if_not_installed("plotly")

  temp_dir <- tempfile("plotly_layout_row_guard_")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  p <- plotly::plot_ly(mtcars, x = ~wt, y = ~mpg)
  content <- create_content(data = mtcars) |>
    add_layout_column() |>
    add_layout_row() |>
    add_plotly(plot = p, tabgroup = "bad/tab") |>
    end_layout_row() |>
    end_layout_column()

  proj <- create_dashboard(output_dir = temp_dir, title = "plotly guard", allow_inside_pkg = TRUE, backend = "plotly") |>
    add_page("Layout Guard", data = mtcars, content = content)

  expect_error(
    generate_dashboard(proj, render = FALSE, open = FALSE, quiet = TRUE),
    exp$message
  )
})

test_that("add_reset_button markup survives content rendering path", {
  skip_on_covr_ci()
  temp_dir <- tempfile("reset_button_render_")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  reset_html <- as.character(add_reset_button(targets = c("cyl_filter", "dep_filter"), label = "Reset all"))

  content <- create_content(data = mtcars) |>
    add_sidebar(position = "left", title = "Filters") |>
    add_filter(filter_var = "cyl", type = "checkbox") |>
    end_sidebar() |>
    add_input(input_id = "dep_filter", filter_var = "cyl", options = sort(unique(mtcars$cyl))) |>
    add_html(reset_html)

  proj <- create_dashboard(output_dir = temp_dir, title = "reset button", allow_inside_pkg = TRUE) |>
    add_page("Reset", data = mtcars, content = content)

  expect_no_error(generate_dashboard(proj, render = FALSE, open = FALSE, quiet = TRUE))

  qmd <- readLines(file.path(temp_dir, "reset.qmd"), warn = FALSE)
  expect_true(any(grepl("dashboardr-reset-button", qmd, fixed = TRUE)))
  expect_true(any(grepl('data-targets="cyl_filter,dep_filter"', qmd, fixed = TRUE)))
})
