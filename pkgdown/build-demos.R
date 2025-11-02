#!/usr/bin/env Rscript
# Build demo dashboards for pkgdown site
# This script generates tutorial and showcase dashboards
# and places them in the pkgdown docs folder

cat("Building demo dashboards for pkgdown site...\n\n")

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

# Create output directory for demos
demo_dir <- "../docs/live-demos"
if (!dir.exists(demo_dir)) {
  dir.create(demo_dir, recursive = TRUE)
}

cat("📊 Generating Tutorial Dashboard...\n")
# QMD files go to live-demos/tutorial, Quarto renders HTML to live-demos/tutorial/docs
tutorial_dashboard(directory = file.path(demo_dir, "tutorial"))

cat("📊 Generating Showcase Dashboard...\n")
# QMD files go to live-demos/showcase, Quarto renders HTML to live-demos/showcase/docs
showcase_dashboard(directory = file.path(demo_dir, "showcase"))

cat("✨ Demo dashboard generation complete!\n")
cat("   Tutorial: docs/live-demos/tutorial/docs/index.html\n")
cat("   Showcase: docs/live-demos/showcase/docs/index.html\n")
