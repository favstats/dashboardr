#!/usr/bin/env Rscript
#' Rebuild Script for dashboardr
#'
#' Runs the iterative rebuild workflow:
#' 1. Document (devtools::document)
#' 2. Build pkgdown site
#' 3. Run all demos
#'
#' Usage: Rscript dev/rebuild.R [--skip-demos] [--skip-pkgdown]

args <- commandArgs(trailingOnly = TRUE)
skip_demos <- "--skip-demos" %in% args
skip_pkgdown <- "--skip-pkgdown" %in% args

cli::cli_h1("dashboardr Rebuild")
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

# Step 1: Document
success <- run_step("Documenting package", {
  devtools::document()
  TRUE
})
if (!success) {
  cli::cli_alert_danger("Aborting rebuild due to documentation failure")
  quit(status = 1)
}

# Step 2: Build pkgdown site
if (!skip_pkgdown) {
  success <- run_step("Building pkgdown site", {
    pkgdown::build_site()
    TRUE
  })
  if (!success) {
    cli::cli_alert_danger("Aborting rebuild due to pkgdown failure")
    quit(status = 1)
  }
} else {
  cli::cli_alert_warning("Skipping pkgdown (--skip-pkgdown)")
}

# Step 3: Run demos
if (!skip_demos) {
  success <- run_step("Building all demos", {
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

# Summary
total_time <- round(as.numeric(difftime(Sys.time(), start_time, units = "mins")), 1)
cli::cli_h1("Rebuild complete!")
cli::cli_alert_success("Total time: {total_time} minutes")
