library(testthat)

normalize_lines <- function(x) {
  x <- gsub("\\r$", "", x)
  x
}

test_that("minimal project _quarto.yml matches golden fixture", {
  out_dir <- tempfile("golden-check-")

  proj <- create_dashboard(
    output_dir = out_dir,
    title = "Golden Dashboard",
    allow_inside_pkg = TRUE,
    theme = "cosmo"
  )

  page <- create_page("Home", is_landing_page = TRUE) %>%
    add_text("# Hello", "This is a golden fixture.")

  proj <- proj %>% add_pages(page)
  generate_dashboard(proj, render = FALSE, quiet = TRUE)

  got <- normalize_lines(readLines(file.path(out_dir, "_quarto.yml"), warn = FALSE))
  expected <- normalize_lines(readLines(test_path("golden", "quarto_minimal.yml"), warn = FALSE))

  expect_identical(got, expected)
})

test_that("minimal project index.qmd matches golden fixture", {
  out_dir <- tempfile("golden-check-")

  proj <- create_dashboard(
    output_dir = out_dir,
    title = "Golden Dashboard",
    allow_inside_pkg = TRUE,
    theme = "cosmo"
  )

  page <- create_page("Home", is_landing_page = TRUE) %>%
    add_text("# Hello", "This is a golden fixture.")

  proj <- proj %>% add_pages(page)
  generate_dashboard(proj, render = FALSE, quiet = TRUE)

  got <- normalize_lines(readLines(file.path(out_dir, "index.qmd"), warn = FALSE))
  expected <- normalize_lines(readLines(test_path("golden", "index_minimal.qmd"), warn = FALSE))

  expect_identical(got, expected)
})
