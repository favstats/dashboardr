# Build Gallery for pkgdown Site
# Run from package root: source("pkgdown/build-gallery-demo.R")
#
# This script copies gallery/ → docs/gallery/ so GitHub Pages
# serves the Vue SPA directly (no dashboardr wrapper needed).

cat("🖼️  Building Community Gallery...\n\n")

# ============================================================
# Find package root
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
gallery_src  <- file.path(pkg_root, "gallery")
gallery_dest <- file.path(pkg_root, "docs", "gallery")

cat("   Package root :", pkg_root, "\n")
cat("   Gallery src  :", gallery_src, "\n")
cat("   Gallery dest :", gallery_dest, "\n\n")

# ============================================================
# Copy gallery/ → docs/gallery/
# ============================================================
cat("   📂 Copying gallery/ → docs/gallery/ ...\n")

if (dir.exists(gallery_dest)) {
  unlink(gallery_dest, recursive = TRUE)
}
dir.create(gallery_dest, recursive = TRUE, showWarnings = FALSE)

# Copy all files and subdirectories (e.g. screenshots/)
gallery_files <- list.files(gallery_src, full.names = TRUE)
file.copy(gallery_files, gallery_dest, overwrite = TRUE, recursive = TRUE)

cat("   ✅ Copied", length(gallery_files), "item(s) to docs/gallery/\n")

# Verify
if (file.exists(file.path(gallery_dest, "index.html"))) {
  cat("   ✅ Gallery index.html present\n")
} else {
  cat("   ⚠️  index.html not found in gallery destination\n")
}

if (file.exists(file.path(gallery_dest, "dashboards.json"))) {
  dashboards <- jsonlite::fromJSON(file.path(gallery_dest, "dashboards.json"))
  cat("   ✅", nrow(dashboards), "dashboards in gallery\n")
}

cat("\n   🔗 Live URL (after deploying to GitHub Pages):\n")
cat("   https://favstats.github.io/dashboardr/gallery/\n")
