library(testthat)

read_golden <- function(path) {
  readLines(test_path("golden", "feature_matrix", path), warn = FALSE)
}

test_that("feature-matrix structural fragments match golden fixtures", {
  skip_on_covr_ci()
  temp_dir <- tempfile("golden_matrix_")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  content <- create_content(data = mtcars) |>
    add_sidebar(position = "left", title = "Filters") |>
    add_filter(filter_var = "cyl", type = "checkbox") |>
    end_sidebar() |>
    add_layout_column(class = "gold-col") |>
    add_layout_row(class = "gold-row", show_when = ~ cyl == 6) |>
    add_table(head(mtcars), filter_vars = "cyl") |>
    end_layout_row() |>
    end_layout_column() |>
    add_viz(type = "bar", x_var = "cyl", title = "Cyl", tabgroup = "gold/tab")

  proj <- create_dashboard(
    output_dir = temp_dir,
    title = "Golden Matrix",
    allow_inside_pkg = TRUE,
    backend = "plotly"
  ) |>
    add_page("Matrix Golden", data = mtcars, content = content)

  generate_dashboard(proj, render = FALSE, open = FALSE, quiet = TRUE)

  qmd <- readLines(file.path(temp_dir, "matrix_golden.qmd"), warn = FALSE)
  yml <- readLines(file.path(temp_dir, "_quarto.yml"), warn = FALSE)

  got_qmd <- fm_extract_qmd_fragments(qmd)
  got_yml <- fm_extract_yml_fragments(yml)

  expect_identical(got_qmd, read_golden("qmd_fragments.txt"))
  expect_identical(got_yml, read_golden("quarto_fragments.txt"))
})
