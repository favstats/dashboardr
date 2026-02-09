library(testthat)

test_that("pairwise scenario selection is complete and deterministic by level", {
  skip_if_not_installed("yaml")

  pr_a <- fm_generate_scenarios(level = "pr")
  pr_b <- fm_generate_scenarios(level = "pr")

  expect_identical(
    vapply(pr_a, `[[`, character(1), "id"),
    vapply(pr_b, `[[`, character(1), "id")
  )

  pr_meta <- attr(pr_a, "pairwise_meta")
  expect_true(!is.null(pr_meta))
  expect_gt(pr_meta$total_candidates, 0L)
  expect_true(pr_meta$selected_candidates > 0L)
  expect_identical(pr_meta$uncovered_pair_tokens, 0L)

  nightly <- fm_generate_scenarios(level = "nightly")
  nightly_meta <- attr(nightly, "pairwise_meta")
  expect_true(!is.null(nightly_meta))
  expect_identical(nightly_meta$uncovered_pair_tokens, 0L)
  expect_gte(nightly_meta$selected_candidates, pr_meta$selected_candidates)
})

test_that("generated combo scenarios produce stable files across feature dimensions", {
  skip_if_not_installed("yaml")

  level <- fm_matrix_level()
  scenarios <- fm_generate_scenarios(level = level)
  combo <- scenarios[grepl("^combo-", vapply(scenarios, `[[`, character(1), "id"))]
  max_to_run <- if (identical(level, "nightly")) 36L else 18L
  combo <- combo[seq_len(min(length(combo), max_to_run))]

  ran <- 0L
  for (sc in combo) {
    pkgs <- fm_required_packages(sc$content_type, sc$backend)
    if (!fm_have_packages(pkgs)) next

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
      fm_generate_dashboard_files(content, backend = sc$backend, page_name = paste("Scenario", sc$id))
    )

    expect_true(file.exists(files$qmd_path), info = sc$id)
    expect_true(file.exists(files$yml_path), info = sc$id)

    if (isTRUE(sc$show_when)) {
      expect_true(any(grepl("show_when_open\\(", files$qmd_lines)), info = sc$id)
    }
    if (isTRUE(sc$filter_vars)) {
      expect_true(any(grepl("filter_vars\\s*=", files$qmd_lines)), info = sc$id)
    }

    unlink(files$output_dir, recursive = TRUE, force = TRUE)
    ran <- ran + 1L
  }

  expect_gte(ran, if (identical(level, "nightly")) 8L else 4L)
})
