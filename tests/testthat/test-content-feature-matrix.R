library(testthat)

test_that("feature matrix lists all registered content types with required flags", {
  skip_if_not_installed("yaml")

  matrix <- fm_get_matrix()
  matrix_types <- names(matrix$content_types)
  registry_types <- dashboardr:::.content_block_types()

  expect_setequal(matrix_types, registry_types)

  required_flags <- c(
    "supports_tabgroup",
    "supports_show_when",
    "supports_filter_vars",
    "supports_sidebar",
    "supports_manual_layout_row",
    "supports_input_dependency"
  )

  for (type in matrix_types) {
    info <- matrix$content_types[[type]]
    for (flag in required_flags) {
      expect_true(!is.null(info[[flag]]), info = paste(type, "missing", flag))
      expect_true(is.logical(info[[flag]]), info = paste(type, flag, "must be logical"))
      expect_length(info[[flag]], 1)
    }
  }
})

test_that("generated scenarios are deterministic and cover all content types", {
  skip_if_not_installed("yaml")

  s1 <- fm_generate_scenarios(level = "pr")
  s2 <- fm_generate_scenarios(level = "pr")

  expect_identical(vapply(s1, `[[`, character(1), "id"), vapply(s2, `[[`, character(1), "id"))

  scenario_types <- unique(vapply(s1, `[[`, character(1), "content_type"))
  expect_setequal(scenario_types, fm_content_types())

  m1 <- attr(s1, "pairwise_meta")
  m2 <- attr(s2, "pairwise_meta")
  expect_identical(m1, m2)
  expect_equal(m1$uncovered_pair_tokens, 0L)
  expect_true(m1$selected_candidates > 0L)
})

test_that("matrix lists explicit unsupported combinations", {
  skip_if_not_installed("yaml")

  ids <- vapply(fm_get_matrix()$unsupported_combinations, `[[`, character(1), "id")
  expect_setequal(
    ids,
    c(
      "manual_layout_row_tabgroup_child",
      "manual_layout_row_pagination_child",
      "widget_filter_vars_girafe",
      "widget_filter_vars_unsupported_widget",
      "leaflet_filter_vars_unsupported"
    )
  )
})

test_that("base scenarios generate dashboard files for runnable content types", {
  skip_if_not_installed("yaml")

  scenarios <- fm_generate_scenarios(level = "pr")
  base <- scenarios[grepl("^base-", vapply(scenarios, `[[`, character(1), "id"))]

  ran <- 0L
  for (sc in base) {
    pkgs <- fm_required_packages(sc$content_type, sc$backend)
    if (!fm_have_packages(pkgs)) {
      next
    }

    content <- suppressWarnings(
      fm_make_content_for_type(
        type = sc$content_type,
        backend = sc$backend,
        show_when = sc$show_when,
        tabgroup = sc$tabgroup,
        filter_vars = sc$filter_vars,
        sidebar = sc$sidebar,
        input_dependency = sc$input_dependency
      )
    )

    files <- suppressWarnings(
      fm_generate_dashboard_files(content, backend = sc$backend, page_name = paste("Matrix", sc$content_type))
    )

    expect_true(file.exists(files$qmd_path), info = sc$id)
    expect_true(file.exists(files$yml_path), info = sc$id)
    unlink(files$output_dir, recursive = TRUE, force = TRUE)
    ran <- ran + 1L
  }

  expect_gte(ran, 10L)
})
