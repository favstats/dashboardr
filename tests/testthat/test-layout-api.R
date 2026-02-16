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

test_that("non-dashboard layout suppresses Column/Row headings in generated QMD", {
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
  # Non-dashboard mode: no ## Column or ### Row headings
  expect_false(any(grepl("^## Column", qmd_lines)))
  expect_false(any(grepl("^### Row", qmd_lines)))
  # Width div should be present
  expect_true(any(grepl("style=.width:100%", qmd_lines)))
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

test_that("metrics in layout row generate layout-ncol wrapper in non-dashboard mode", {
  temp_dir <- tempfile("layout_metrics_")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  content <- create_content() %>%
    add_layout_column() %>%
    add_layout_row() %>%
      add_metric(value = 42, title = "Users") %>%
      add_metric(value = 88, title = "Score") %>%
    end_layout_row() %>%
    end_layout_column()

  proj <- create_dashboard(output_dir = temp_dir, title = "Metric layout") %>%
    add_page("Metrics", data = mtcars, content = content)

  expect_no_error(generate_dashboard(proj, render = FALSE, open = FALSE, quiet = TRUE))

  qmd_path <- file.path(temp_dir, "metrics.qmd")
  expect_true(file.exists(qmd_path))

  qmd_lines <- readLines(qmd_path, warn = FALSE)
  # Should have layout-ncol=2 wrapper for 2 metrics
  expect_true(any(grepl("layout-ncol=2", qmd_lines)))
  # Should NOT have ### Row heading
  expect_false(any(grepl("^### Row", qmd_lines)))
})

test_that("single item in layout row does NOT generate layout-ncol wrapper", {
  temp_dir <- tempfile("layout_single_")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  content <- create_content() %>%
    add_layout_column() %>%
    add_layout_row() %>%
      add_metric(value = 42, title = "Users") %>%
    end_layout_row() %>%
    end_layout_column()

  proj <- create_dashboard(output_dir = temp_dir, title = "Single layout") %>%
    add_page("Single", data = mtcars, content = content)

  expect_no_error(generate_dashboard(proj, render = FALSE, open = FALSE, quiet = TRUE))

  qmd_path <- file.path(temp_dir, "single.qmd")
  expect_true(file.exists(qmd_path))

  qmd_lines <- readLines(qmd_path, warn = FALSE)
  # No layout-ncol for single item
  expect_false(any(grepl("layout-ncol", qmd_lines)))
})

test_that("layout row in dashboard mode (with sidebar) still generates ### Row", {
  temp_dir <- tempfile("layout_dashboard_row_")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  content <- create_content() %>%
    add_sidebar(position = "left", width = "280px", title = "Filters") %>%
    add_input(
      input_id = "filter1",
      label = "Filter",
      type = "checkbox",
      filter_var = "cyl",
      options = sort(unique(mtcars$cyl)),
      default_selected = sort(unique(mtcars$cyl))
    ) %>%
    end_sidebar() %>%
    add_layout_column(class = "main-col") %>%
    add_layout_row() %>%
      add_metric(value = 42, title = "Users") %>%
      add_metric(value = 88, title = "Score") %>%
    end_layout_row() %>%
    end_layout_column()

  proj <- create_dashboard(output_dir = temp_dir, title = "Dashboard layout") %>%
    add_page("Dashboard", data = mtcars, content = content)

  expect_no_error(generate_dashboard(proj, render = FALSE, open = FALSE, quiet = TRUE))

  qmd_path <- file.path(temp_dir, "dashboard.qmd")
  expect_true(file.exists(qmd_path))

  qmd_lines <- readLines(qmd_path, warn = FALSE)
  # Dashboard mode: should have ## Column and ### Row headings
  expect_true(any(grepl("^## Column", qmd_lines)))
  expect_true(any(grepl("^### Row", qmd_lines)))
  # Should NOT have layout-ncol
  expect_false(any(grepl("layout-ncol", qmd_lines)))
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
