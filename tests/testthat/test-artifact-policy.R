library(testthat)

test_that("artifact policy guard scripts exist", {
  repo_root <- normalizePath(file.path(test_path(), "..", ".."), winslash = "/", mustWork = TRUE)
  expect_true(file.exists(file.path(repo_root, "scripts", "check_artifacts.R")))
  expect_true(file.exists(file.path(repo_root, "scripts", "sync_assets.R")))
})

test_that("sync_assets check mode passes", {
  repo_root <- normalizePath(file.path(test_path(), "..", ".."), winslash = "/", mustWork = TRUE)
  old_wd <- setwd(repo_root)
  on.exit(setwd(old_wd), add = TRUE)

  out <- system2("Rscript", c("scripts/sync_assets.R", "--check"), stdout = TRUE, stderr = TRUE)
  status <- attr(out, "status")
  if (is.null(status)) status <- 0
  expect_equal(as.integer(status), 0L, info = paste(out, collapse = "\n"))
})

test_that(".gitignore contains non-canonical generated output rules", {
  repo_root <- normalizePath(file.path(test_path(), "..", ".."), winslash = "/", mustWork = TRUE)
  lines <- readLines(file.path(repo_root, ".gitignore"), warn = FALSE)

  expected_rules <- c(
    "^22222/$",
    "^here/$",
    "^here_hc/$",
    "^here_plotly/$",
    "^dev/\\*\\*/docs/$",
    "^dev/\\*\\*/site_libs/$",
    "^dev/\\*\\*/\\.quarto/$"
  )

  for (rule in expected_rules) {
    expect_true(any(grepl(rule, lines)), info = paste("Missing rule:", rule))
  }

  # Canonical publish dir must stay trackable.
  expect_false(any(grepl("^docs/$", lines)))
})
