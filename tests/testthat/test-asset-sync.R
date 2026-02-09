library(testthat)

hash_file <- function(path) {
  unname(tools::md5sum(path))
}

test_that("managed asset mirrors stay in sync with inst/assets", {
  repo_root <- normalizePath(file.path(test_path(), "..", ".."), winslash = "/", mustWork = TRUE)
  root_path <- function(...) file.path(repo_root, ...)

  mirrors <- list(
    "dev/showwhen/assets" = c(
      "choices.min.css", "choices.min.js", "filter_hook.js", "input_filter.css",
      "input_filter.js", "linked_inputs.js", "modal.css", "modal.js",
      "pagination.css", "show_when.js", "sidebar.css", "tab-scroll-fix.js"
    ),
    "dev/showwhen/docs/assets" = c(
      "choices.min.css", "choices.min.js", "filter_hook.js", "input_filter.css",
      "input_filter.js", "linked_inputs.js", "modal.css", "modal.js",
      "pagination.css", "show_when.js", "sidebar.css", "tab-scroll-fix.js"
    ),
    "inst/tutorial_dashboard/assets" = c("modal.css", "modal.js", "pagination.css")
  )

  for (mirror in names(mirrors)) {
    for (fname in mirrors[[mirror]]) {
      canonical <- root_path("inst", "assets", fname)
      mirrored <- root_path(mirror, fname)

      expect_true(file.exists(canonical), info = canonical)
      expect_true(file.exists(mirrored), info = mirrored)
      expect_identical(hash_file(canonical), hash_file(mirrored),
                       info = paste("Drift detected for", fname, "in", mirror))
    }
  }
})
