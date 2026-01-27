#!/usr/bin/env Rscript
# Build Tutorial & Showcase Demo Dashboards for pkgdown site
# Run from package root: source("pkgdown/build-demos.R")

cat("📊 Building Tutorial & Showcase Dashboards...\n\n")

# Load package
suppressPackageStartupMessages({
  library(dashboardr)
  library(dplyr)
})

# Check if gssr is available
if (!requireNamespace("gssr", quietly = TRUE)) {
  cat("⚠️  'gssr' package not found. Demo dashboards will not be generated.\n")
  cat("   Install with: install.packages('gssr')\n")
  quit(status = 0)
}

# Find package root
find_pkg_root <- function() {
  dir <- getwd()
  for (i in 1:10) {
    if (file.exists(file.path(dir, "DESCRIPTION"))) {
      return(dir)
    }
    parent <- dirname(dir)
    if (parent == dir) break
    dir <- parent
  }
  if (requireNamespace("here", quietly = TRUE)) {
    return(here::here())
  }
  stop("Could not find package root. Please run from the package directory.")
}

pkg_root <- find_pkg_root()
cat("   Package root:", pkg_root, "\n")

tutorial_dir <- file.path(pkg_root, "docs", "live-demos", "tutorial")
showcase_dir <- file.path(pkg_root, "docs", "live-demos", "showcase")

# Clean up old directories
if (dir.exists(tutorial_dir)) unlink(tutorial_dir, recursive = TRUE)
if (dir.exists(showcase_dir)) unlink(showcase_dir, recursive = TRUE)
dir.create(tutorial_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(showcase_dir, recursive = TRUE, showWarnings = FALSE)

cat("📊 Generating Tutorial Dashboard...\n")
tryCatch({
  tutorial_dashboard(directory = tutorial_dir, open = FALSE)
  if (file.exists(file.path(tutorial_dir, "index.html")) || 
      file.exists(file.path(tutorial_dir, "docs", "index.html"))) {
    cat("   ✅ Tutorial created\n")
  } else {
    cat("   ⚠️  QMD created, needs Quarto render\n")
  }
}, error = function(e) {
  cat("   ❌ Error:", e$message, "\n")
})

cat("📊 Generating Showcase Dashboard...\n")
tryCatch({
  showcase_dashboard(directory = showcase_dir, open = FALSE)
  if (file.exists(file.path(showcase_dir, "index.html")) ||
      file.exists(file.path(showcase_dir, "docs", "index.html"))) {
    cat("   ✅ Showcase created\n")
  } else {
    cat("   ⚠️  QMD created, needs Quarto render\n")
  }
}, error = function(e) {
  cat("   ❌ Error:", e$message, "\n")
})

cat("\n✨ Tutorial & Showcase generation complete!\n")
