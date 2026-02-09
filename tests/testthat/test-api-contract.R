library(testthat)

parse_namespace_exports <- function(path) {
  lines <- readLines(path, warn = FALSE)
  exports <- grep("^export\\(", lines, value = TRUE)
  exports <- sub("^export\\((.*)\\)$", "\\1", exports)
  exports <- gsub('^"|"$', "", exports)
  sort(exports)
}

test_that("namespace exports stay aligned with NAMESPACE", {
  repo_root <- normalizePath(file.path(test_path(), "..", ".."), winslash = "/", mustWork = TRUE)
  ns_path <- file.path(repo_root, "NAMESPACE")
  expect_setequal(getNamespaceExports("dashboardr"), parse_namespace_exports(ns_path))
})

test_that("core public API remains available", {
  core_exports <- c(
    "create_dashboard", "create_page", "create_content",
    "add_viz", "generate_dashboard", "preview"
  )
  expect_true(all(core_exports %in% getNamespaceExports("dashboardr")))
})

test_that("key function signatures/defaults remain stable", {
  # create_content
  expect_identical(names(formals(create_content)), c("data", "tabgroup_labels", "shared_first_level", "..."))

  # create_page
  expect_identical(
    names(formals(create_page)),
    c(
      "name", "data", "data_path", "type", "color_palette", "icon", "is_landing_page",
      "navbar_align", "tabset_theme", "tabset_colors", "overlay", "overlay_theme",
      "overlay_text", "overlay_duration", "lazy_load_charts", "lazy_load_margin",
      "lazy_load_tabs", "lazy_debug", "pagination_separator", "time_var", "weight_var",
      "filter", "drop_na_vars", "shared_first_level", "..."
    )
  )

  # create_dashboard (subset + key defaults)
  cd <- formals(create_dashboard)
  expect_gte(length(cd), 90)
  expect_identical(cd$output_dir, "site")
  expect_identical(cd$title, "Dashboard")
  expect_identical(cd$tabset_theme, "minimal")
  expect_identical(cd$lazy_load_charts, FALSE)
  expect_identical(cd$backend, "highcharter")
  expect_identical(cd$allow_inside_pkg, FALSE)

  # add_viz
  expect_identical(
    names(formals(add_viz)),
    c(
      "x", "type", "...", "tabgroup", "title", "title_tabset", "text", "icon",
      "text_position", "text_before_tabset", "text_after_tabset", "text_before_viz",
      "text_after_viz", "height", "filter", "data", "drop_na_vars", "show_when"
    )
  )

  # generate_dashboard
  expect_identical(
    names(formals(generate_dashboard)),
    c("proj", "render", "open", "incremental", "preview", "show_progress", "quiet")
  )
  expect_identical(formals(generate_dashboard)$render, TRUE)
  expect_identical(formals(generate_dashboard)$open, "browser")

  # preview
  expect_identical(
    names(formals(preview)),
    c("collection", "title", "open", "clean", "quarto", "theme", "path", "page", "debug", "output")
  )
  expect_identical(formals(preview)$title, "Preview")
  expect_identical(formals(preview)$open, TRUE)
})
