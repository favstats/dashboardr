#!/usr/bin/env Rscript
#' Release Script for dashboardr
#'
#' This script runs the full release workflow:
#' 1. Run tests
#' 2. Build pkgdown site
#' 3. Run all demos
#' 4. Commit and push changes
#'
#' Usage: Rscript scripts/release.R [--skip-tests] [--skip-demos] [--no-push]

args <- commandArgs(trailingOnly = TRUE)
skip_tests <- "--skip-tests" %in% args
skip_demos <- "--skip-demos" %in% args
no_push <- "--no-push" %in% args

cli::cli_h1("dashboardr Release Script")
start_time <- Sys.time()

# Helper to run a step with timing
run_step <- function(name, expr) {
  cli::cli_h2(name)
  step_start <- Sys.time()
  result <- tryCatch(expr, error = function(e) {
    cli::cli_alert_danger("Failed: {e$message}")
    return(FALSE)
  })
  elapsed <- round(as.numeric(difftime(Sys.time(), step_start, units = "secs")), 1)
  if (isFALSE(result)) {
    cli::cli_alert_danger("{name} failed after {elapsed}s")
    return(FALSE)
  }
  cli::cli_alert_success("{name} completed in {elapsed}s")
  return(TRUE)
}

# Step 1: Run tests
if (!skip_tests) {
  success <- run_step("Running tests", {
    results <- devtools::test()
    # Check for failures
    failed <- sum(as.data.frame(results)$failed)
    if (failed > 0) {
      cli::cli_alert_danger("{failed} test(s) failed")
      FALSE
    } else {
      TRUE
    }
  })
  if (!success) {
    cli::cli_alert_danger("Aborting release due to test failures")
    quit(status = 1)
  }
} else {
  cli::cli_alert_warning("Skipping tests (--skip-tests)")
}

# Step 2: Build pkgdown site
success <- run_step("Building pkgdown site", {
  pkgdown::build_site()
  TRUE
})
if (!success) {
  cli::cli_alert_danger("Aborting release due to pkgdown failure")
  quit(status = 1)
}

# Step 3: Run demos
if (!skip_demos) {
  success <- run_step("Running demos", {
    demo_script <- file.path("pkgdown", "build-all-demos.R")
    if (file.exists(demo_script)) {
      source(demo_script, local = new.env())
    } else {
      cli::cli_alert_warning("Demo script not found: {demo_script}")
    }
    TRUE
  })
} else {
  cli::cli_alert_warning("Skipping demos (--skip-demos)")
}

# Step 4: Commit and push
if (!no_push) {
  success <- run_step("Committing and pushing", {
    # Check for changes
    status <- system("git status --porcelain", intern = TRUE)
    if (length(status) > 0) {
      system("git add -A")
      system('git commit -m "Update pkgdown site"')
    }
    system("git push origin main")
    TRUE
  })
} else {
  cli::cli_alert_warning("Skipping push (--no-push)")
}

# Summary
total_time <- round(as.numeric(difftime(Sys.time(), start_time, units = "mins")), 1)
cli::cli_h1("Release complete!")
cli::cli_alert_success("Total time: {total_time} minutes")
