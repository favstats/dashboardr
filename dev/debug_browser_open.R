#!/usr/bin/env Rscript
# Debug why open = "browser" isn't working

devtools::load_all(".")

# Create simple test data
data <- data.frame(x = rnorm(100))

# Create simple visualization
viz <- create_viz(type = "histogram", x_var = "x") %>%
  add_viz(title = "Test")

# Create dashboard
dashboard <- create_dashboard(
  "test_browser_open",
  "Test Browser Open"
) %>%
  add_page("Home", data = data, visualizations = viz, is_landing_page = TRUE)

# Test 1: Generate with render = TRUE, open = "browser"
cat("\n=== TEST 1: render = TRUE, open = 'browser' ===\n")
result <- generate_dashboard(dashboard, render = TRUE, open = "browser", show_progress = FALSE)
cat("\n")

# Check if index.html exists
index_path <- file.path("/Users/favstats/Dropbox/postdoc/test_browser_open", "docs", "index.html")
cat("Index file exists:", file.exists(index_path), "\n")
cat("Index path:", index_path, "\n")

if (file.exists(index_path)) {
  cat("\n✅ index.html exists - browseURL should have been called\n")
} else {
  cat("\n❌ index.html does NOT exist - this is the problem\n")
  
  # Check what's in docs/
  docs_dir <- file.path("/Users/favstats/Dropbox/postdoc/test_browser_open", "docs")
  if (dir.exists(docs_dir)) {
    html_files <- list.files(docs_dir, pattern = "\\.html$")
    cat("HTML files in docs/:", paste(html_files, collapse = ", "), "\n")
  } else {
    cat("docs/ directory doesn't exist\n")
  }
}

cat("\n=== Checking if browseURL works at all ===\n")
cat("About to call browseURL manually...\n")
if (file.exists(index_path)) {
  cat("Calling: utils::browseURL('", index_path, "')\n", sep = "")
  utils::browseURL(index_path)
  cat("✓ browseURL called successfully\n")
}

