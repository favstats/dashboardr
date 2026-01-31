#!/usr/bin/env Rscript
# =============================================================================
# Build All Demo Dashboards for pkgdown Site
# =============================================================================
# This master script generates all live demo dashboards:
#   - Tutorial Dashboard (basic features)
#   - Showcase Dashboard (comprehensive example)
#   - Tabset Theme Dashboards (6 themes: pills, modern, minimal, classic, underline, segmented)
#   - Inputs Dashboard (interactive widgets focus)
#   - Overlay Dashboard (loading themes focus)
#
# Run from package root: Rscript pkgdown/build-all-demos.R
#                    or: source("pkgdown/build-all-demos.R")
# =============================================================================

cat("═══════════════════════════════════════════════════════════════════════════\n")
cat("  Building All Demo Dashboards for dashboardr\n")
cat("═══════════════════════════════════════════════════════════════════════════\n\n")

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
cat("📁 Package root:", pkg_root, "\n\n")

# Change to package root to ensure consistent paths
original_wd <- getwd()
setwd(pkg_root)
on.exit(setwd(original_wd))

# Check required packages
required_pkgs <- c("dashboardr", "dplyr", "gssr", "haven", "tidyr")
missing_pkgs <- required_pkgs[!sapply(required_pkgs, requireNamespace, quietly = TRUE)]

if (length(missing_pkgs) > 0) {
  cat("❌ Missing required packages:", paste(missing_pkgs, collapse = ", "), "\n")
  cat("   Install with: install.packages(c('", paste(missing_pkgs, collapse = "', '"), "'))\n")
  quit(status = 1)
}

# Load packages
suppressPackageStartupMessages({
  library(dashboardr)
  library(dplyr)
  library(gssr)
  library(haven)
  library(tidyr)
})

# Track results
results <- list()

# Helper to check if HTML exists
check_html <- function(dir) {
  locations <- c(
    file.path(dir, "index.html"),
    file.path(dir, "docs", "index.html")
  )
  for (loc in locations) {
    if (file.exists(loc)) return(TRUE)
  }
  return(FALSE)
}

# -----------------------------------------------------------------------------
# 1. Tutorial Dashboard
# -----------------------------------------------------------------------------
cat("\n📊 [1/5] Building Tutorial Dashboard...\n")
tryCatch({
  tutorial_dir <- file.path(pkg_root, "docs", "live-demos", "tutorial")
  if (dir.exists(tutorial_dir)) unlink(tutorial_dir, recursive = TRUE)
  dir.create(tutorial_dir, recursive = TRUE, showWarnings = FALSE)
  
  tutorial_dashboard(directory = tutorial_dir, open = FALSE)
  
  if (check_html(tutorial_dir)) {
    results$tutorial <- "✅ Success"
    cat("   ✅ Tutorial dashboard created\n")
  } else {
    results$tutorial <- "⚠️  QMD only (needs Quarto)"
    cat("   ⚠️  QMD created, needs Quarto render\n")
  }
}, error = function(e) {
  results$tutorial <<- paste("❌", e$message)
  cat("   ❌ Error:", e$message, "\n")
})

# -----------------------------------------------------------------------------
# 2. Showcase Dashboard
# -----------------------------------------------------------------------------
cat("\n📊 [2/5] Building Showcase Dashboard...\n")
tryCatch({
  showcase_dir <- file.path(pkg_root, "docs", "live-demos", "showcase")
  if (dir.exists(showcase_dir)) unlink(showcase_dir, recursive = TRUE)
  dir.create(showcase_dir, recursive = TRUE, showWarnings = FALSE)
  
  showcase_dashboard(directory = showcase_dir, open = FALSE)
  
  if (check_html(showcase_dir)) {
    results$showcase <- "✅ Success"
    cat("   ✅ Showcase dashboard created\n")
  } else {
    results$showcase <- "⚠️  QMD only (needs Quarto)"
    cat("   ⚠️  QMD created, needs Quarto render\n")
  }
}, error = function(e) {
  results$showcase <<- paste("❌", e$message)
  cat("   ❌ Error:", e$message, "\n")
})

# -----------------------------------------------------------------------------
# 3. Tabset Theme Dashboards (6 themes)
# -----------------------------------------------------------------------------
cat("\n📊 [3/5] Building Tabset Theme Dashboards (6 themes)...\n")
tryCatch({
  source(file.path(pkg_root, "pkgdown", "build-tabsets-demo.R"), local = TRUE)
  
  # Check if any tabset themes were created
  tabsets_base <- file.path(pkg_root, "docs", "live-demos", "tabsets")
  themes <- c("pills", "modern", "minimal", "classic", "underline", "segmented")
  success_count <- sum(sapply(themes, function(t) check_html(file.path(tabsets_base, t))))
  
  if (success_count == 6) {
    results$tabsets <- "✅ All 6 themes"
  } else if (success_count > 0) {
    results$tabsets <- paste0("⚠️  ", success_count, "/6 themes")
  } else {
    results$tabsets <- "⚠️  QMD only (needs Quarto)"
  }
}, error = function(e) {
  results$tabsets <<- paste("❌", e$message)
  cat("   ❌ Error:", e$message, "\n")
})

# -----------------------------------------------------------------------------
# 4. Inputs Dashboard
# -----------------------------------------------------------------------------
cat("\n📊 [4/5] Building Inputs Dashboard...\n")
tryCatch({
  source(file.path(pkg_root, "pkgdown", "build-inputs-demo.R"), local = TRUE)
  
  inputs_dir <- file.path(pkg_root, "docs", "live-demos", "inputs")
  if (check_html(inputs_dir)) {
    results$inputs <- "✅ Success"
  } else {
    results$inputs <- "⚠️  QMD only (needs Quarto)"
  }
}, error = function(e) {
  results$inputs <<- paste("❌", e$message)
  cat("   ❌ Error:", e$message, "\n")
})

# -----------------------------------------------------------------------------
# 5. Overlay Dashboard
# -----------------------------------------------------------------------------
cat("\n📊 [5/5] Building Overlay Dashboard...\n")
tryCatch({
  source(file.path(pkg_root, "pkgdown", "build-overlay-demo.R"), local = TRUE)
  
  overlay_dir <- file.path(pkg_root, "docs", "live-demos", "overlay")
  if (check_html(overlay_dir)) {
    results$overlay <- "✅ Success"
  } else {
    results$overlay <- "⚠️  QMD only (needs Quarto)"
  }
}, error = function(e) {
  results$overlay <<- paste("❌", e$message)
  cat("   ❌ Error:", e$message, "\n")
})

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
cat("\n═══════════════════════════════════════════════════════════════════════════\n")
cat("  Build Summary\n")
cat("═══════════════════════════════════════════════════════════════════════════\n\n")

cat("Demo Dashboard      Status\n")
cat("─────────────────   ──────────────────────────────────────\n")
cat(sprintf("Tutorial            %s\n", results$tutorial %||% "Not run"))
cat(sprintf("Showcase            %s\n", results$showcase %||% "Not run"))
cat(sprintf("Tabset Themes       %s\n", results$tabsets %||% "Not run"))
cat(sprintf("Inputs              %s\n", results$inputs %||% "Not run"))
cat(sprintf("Overlay             %s\n", results$overlay %||% "Not run"))

cat("\n📁 Output location:", file.path(pkg_root, "docs", "live-demos"), "\n")

# Check if any need Quarto rendering
needs_quarto <- any(grepl("QMD only", unlist(results)))
if (needs_quarto) {
  cat("\n⚠️  Some demos need Quarto rendering. To render manually:\n")
  cat("   cd docs/live-demos/<demo> && quarto render .\n")
}

cat("\n🔗 Live URLs (after deploying to GitHub Pages):\n")
cat("   https://favstats.github.io/dashboardr/live-demos/tutorial/index.html\n")
cat("   https://favstats.github.io/dashboardr/live-demos/showcase/index.html\n")
cat("   Tabset Themes:\n")
for (theme in c("pills", "modern", "minimal", "classic", "underline", "segmented")) {
  cat("     https://favstats.github.io/dashboardr/live-demos/tabsets/", theme, "/index.html\n", sep = "")
}
cat("   https://favstats.github.io/dashboardr/live-demos/inputs/index.html\n")
cat("   https://favstats.github.io/dashboardr/live-demos/overlay/index.html\n")
