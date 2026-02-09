library(testthat)

test_that("matrix backend list matches supported backend values", {
  skip_if_not_installed("yaml")
  matrix <- fm_get_matrix()
  expect_identical(matrix$backends, c("highcharter", "plotly", "echarts4r", "ggiraph"))
})

test_that("add_widget enforces filter_vars backend constraints", {
  skip_if_not_installed("yaml")
  exp_unsupported <- fm_unsupported_expectation("widget_filter_vars_unsupported_widget")
  exp_girafe <- fm_unsupported_expectation("widget_filter_vars_girafe")

  content <- create_content(data = mtcars)

  fake_widget <- structure(list(x = list()), class = c("not_supported", "htmlwidget"))
  expect_error(
    add_widget(content, fake_widget, filter_vars = "cyl"),
    exp_unsupported$message
  )

  if (requireNamespace("ggiraph", quietly = TRUE) && requireNamespace("ggplot2", quietly = TRUE)) {
    p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, tooltip = rownames(mtcars), data_id = rownames(mtcars))) +
      ggplot2::geom_point()
    girafe_widget <- ggiraph::girafe(ggobj = p)

    expect_error(
      add_widget(content, girafe_widget, filter_vars = "cyl"),
      exp_girafe$message
    )
  }
})

test_that("backend injection appears for non-highcharter viz generation", {
  for (backend in c("plotly", "echarts4r", "ggiraph")) {
    content <- fm_make_viz_content(backend = backend, tabgroup = FALSE, show_when = FALSE)
    files <- fm_generate_dashboard_files(content, backend = backend, page_name = paste("Backend", backend))

    pat <- sprintf('backend = "%s"', backend)
    expect_true(any(grepl(pat, files$qmd_lines, fixed = TRUE)), info = backend)

    unlink(files$output_dir, recursive = TRUE, force = TRUE)
  }
})
