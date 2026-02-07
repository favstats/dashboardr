# Build Gallery Demo Dashboard
# Run from package root: source("pkgdown/build-gallery-demo.R")
#
# This script:
#   1. Copies gallery/ → docs/gallery/ (so GitHub Pages serves the Vue SPA)
#   2. Builds a dashboardr wrapper dashboard at docs/live-demos/gallery/
#      with a full-viewport iframe embedding the Vue app

library(dashboardr)

cat("🖼️  Building Gallery Demo Dashboard...\n\n")

# ============================================================
# Find package root and set output directories
# ============================================================
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
  stop("Could not find package root. Run from package directory.")
}

pkg_root <- find_pkg_root()
gallery_src    <- file.path(pkg_root, "gallery")
gallery_dest   <- file.path(pkg_root, "docs", "gallery")
demo_dir       <- file.path(pkg_root, "docs", "live-demos", "gallery")

cat("   Package root:", pkg_root, "\n")
cat("   Gallery src :", gallery_src, "\n")
cat("   Gallery dest:", gallery_dest, "\n")
cat("   Demo dir    :", demo_dir, "\n\n")

# ============================================================
# Step 1: Copy gallery/ → docs/gallery/
# ============================================================
cat("   📂 Copying gallery/ → docs/gallery/ ...\n")

if (dir.exists(gallery_dest)) {
  unlink(gallery_dest, recursive = TRUE)
}
dir.create(gallery_dest, recursive = TRUE, showWarnings = FALSE)

gallery_files <- list.files(gallery_src, full.names = TRUE)
file.copy(gallery_files, gallery_dest, overwrite = TRUE, recursive = TRUE)

cat("   ✅ Copied", length(gallery_files), "file(s) to docs/gallery/\n\n")

# ============================================================
# Step 2: Build dashboardr wrapper dashboard with iframe
# ============================================================
cat("   📊 Building dashboardr wrapper with iframe ...\n")

if (dir.exists(demo_dir)) {
  unlink(demo_dir, recursive = TRUE)
}
dir.create(demo_dir, recursive = TRUE, showWarnings = FALSE)

# Create a single-page dashboard with a full-viewport iframe
gallery_page <- create_page(
  "Gallery",
  icon = "ph:images-fill"
) %>%
  add_iframe(
    src = "../../gallery/index.html",
    height = "calc(100vh - 80px)",
    style = "border: none; width: 100%;"
  )

dashboard <- create_dashboard(
  title = "Community Gallery",
  output_dir = demo_dir,
  theme = "flatly",
  allow_inside_pkg = TRUE
) %>%
  add_pages(gallery_page)

# Generate
result <- tryCatch(
  generate_dashboard(dashboard, render = TRUE, open = FALSE),
  error = function(e) {
    cat("   ⚠️  generate_dashboard error:", e$message, "\n")
    NULL
  }
)

# Check for HTML and move if in docs/ subdirectory
html_locations <- c(
  file.path(demo_dir, "index.html"),
  file.path(demo_dir, "docs", "index.html")
)

html_found <- FALSE
for (loc in html_locations) {
  if (file.exists(loc)) {
    cat("   ✅ Gallery demo HTML found at:", loc, "\n")
    html_found <- TRUE

    if (grepl("/docs/index.html$", loc)) {
      docs_dir <- dirname(loc)
      files_to_move <- list.files(docs_dir, full.names = TRUE)
      for (f in files_to_move) {
        file.copy(f, demo_dir, recursive = TRUE, overwrite = TRUE)
      }
      unlink(docs_dir, recursive = TRUE)
      cat("   📁 Moved HTML files to root of output_dir\n")
    }
    break
  }
}

if (!html_found) {
  cat("   ⚠️  QMD files created but HTML not rendered\n")
  cat("   📁 To render manually: cd", demo_dir, "&& quarto render .\n")
}

cat("\n   🔗 Live URLs (after deploying to GitHub Pages):\n")
cat("   Vue SPA:  https://favstats.github.io/dashboardr/gallery/index.html\n")
cat("   Wrapper:  https://favstats.github.io/dashboardr/live-demos/gallery/index.html\n")
