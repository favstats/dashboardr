library(testthat)

test_that("viz content renders across configured backends", {
  skip_if_not_installed("yaml")
  matrix <- fm_get_matrix()

  for (backend in matrix$backends) {
    content <- fm_make_viz_content(backend = backend, tabgroup = TRUE, show_when = TRUE)
    files <- fm_generate_dashboard_files(content, backend = backend, page_name = paste("Viz", backend))

    expect_true(any(grepl("show_when_open\\(", files$qmd_lines)), info = backend)
    expect_true(any(grepl("tabset", files$qmd_lines, fixed = TRUE)) || any(grepl("### Row", files$qmd_lines, fixed = TRUE)), info = backend)

    if (!identical(backend, "highcharter")) {
      pat <- sprintf('backend = "%s"', backend)
      expect_true(any(grepl(pat, files$qmd_lines, fixed = TRUE)), info = backend)
    }

    unlink(files$output_dir, recursive = TRUE, force = TRUE)
  }
})

test_that("matrix level controls scenario breadth", {
  pr <- fm_generate_scenarios(level = "pr")
  nightly <- fm_generate_scenarios(level = "nightly")

  expect_gte(length(nightly), length(pr))
  expect_true(any(grepl("^base-", vapply(pr, `[[`, character(1), "id"))))
})
