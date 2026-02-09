library(testthat)

test_that("layout API lifecycle works for content collections", {
  content <- create_content() %>%
    add_layout_column(width = 70, class = "main-col") %>%
    add_layout_row(class = "top-row") %>%
    add_text("### Inside row") %>%
    end_layout_row() %>%
    end_layout_column()

  expect_s3_class(content, "content_collection")
  expect_equal(length(content$items), 1)
  expect_equal(content$items[[1]]$type, "layout_column")
  expect_equal(content$items[[1]]$width, 70)
  expect_equal(content$items[[1]]$class, "main-col")
  expect_equal(content$items[[1]]$items[[1]]$type, "layout_row")
})

test_that("layout API validates nesting and end targets", {
  expect_error(add_layout_row(create_content()), "layout_column_container")
  expect_error(end_layout_row(create_content()), "layout_row_container")
  expect_error(end_layout_column(create_content()), "layout_column_container")

  col <- create_content() %>% add_layout_column()
  row <- col %>% add_layout_row()

  expect_error(end_layout_column(row$parent_column), "end_layout_row")
})

test_that("manual layout renders Column/Row markers in generated QMD", {
  temp_dir <- tempfile("layout_qmd_")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  content <- create_content() %>%
    add_layout_column(width = 100, class = "manual-col") %>%
    add_layout_row(class = "manual-row") %>%
      add_viz(type = "bar", x_var = "cyl", title = "Cylinders") %>%
    end_layout_row() %>%
  end_layout_column()

  proj <- create_dashboard(output_dir = temp_dir, title = "Layout render") %>%
    add_page("Layout", data = mtcars, content = content)

  expect_no_error(generate_dashboard(proj, render = FALSE, open = FALSE, quiet = TRUE))

  qmd_path <- file.path(temp_dir, "layout.qmd")
  expect_true(file.exists(qmd_path))

  qmd_lines <- readLines(qmd_path, warn = FALSE)
  expect_true(any(grepl("^## Column", qmd_lines)))
  expect_true(any(grepl("^### Row", qmd_lines)))
})

test_that("manual layout row rejects tabgroup/pagination markers", {
  temp_dir <- tempfile("layout_invalid_")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  invalid_content <- create_content() %>%
    add_layout_column() %>%
    add_layout_row() %>%
      add_viz(type = "bar", x_var = "cyl", tabgroup = "TabA", title = "Invalid tabgroup in row") %>%
    end_layout_row() %>%
  end_layout_column()

  proj <- create_dashboard(output_dir = temp_dir, title = "Layout invalid") %>%
    add_page("Invalid", data = mtcars, content = invalid_content)

  expect_error(
    generate_dashboard(proj, render = FALSE, open = FALSE, quiet = TRUE),
    "Manual layout rows do not support tabgroup"
  )
})

test_that("sidebar pages with manual layout do not emit extra auto column wrappers", {
  temp_dir <- tempfile("layout_sidebar_manual_")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  content <- create_content() %>%
    add_sidebar(position = "left", width = "280px", title = "Filters") %>%
    add_input(
      input_id = "region",
      label = "Region",
      type = "checkbox",
      filter_var = "cyl",
      options = sort(unique(mtcars$cyl)),
      default_selected = sort(unique(mtcars$cyl))
    ) %>%
    end_sidebar() %>%
    add_layout_column(class = "manual-col") %>%
    add_layout_row(class = "manual-row") %>%
    add_viz(type = "bar", x_var = "cyl", title = "Cylinders") %>%
    end_layout_row() %>%
    end_layout_column()

  proj <- create_dashboard(output_dir = temp_dir, title = "Layout sidebar") %>%
    add_page("Layout", data = mtcars, content = content)

  expect_no_error(generate_dashboard(proj, render = FALSE, open = FALSE, quiet = TRUE))

  qmd_path <- file.path(temp_dir, "layout.qmd")
  expect_true(file.exists(qmd_path))

  qmd_lines <- readLines(qmd_path, warn = FALSE)
  manual_columns <- grep("^## Column \\{\\.manual-col\\}", qmd_lines)
  auto_columns <- grep("^## Column$", qmd_lines)

  expect_length(manual_columns, 1)
  expect_length(auto_columns, 0)
})
