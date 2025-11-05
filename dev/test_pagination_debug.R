# Debug pagination generation
devtools::load_all()

vizzes <- create_viz() %>%
  add_viz(type = "bar", x_var = "cyl", title = "Chart 1") %>%
  add_pagination(anchor = "section2", button_text = "Load More Charts") %>%
  add_viz(type = "histogram", x_var = "mpg", title = "Chart 2") %>%
  add_pagination(anchor = "section3", button_text = "Load Final") %>%
  add_viz(type = "bar", x_var = "gear", title = "Chart 3")

proj <- create_dashboard("debug_pagination") %>%
  add_page("Test", data = mtcars, visualizations = vizzes)

result <- generate_dashboard(proj, render = FALSE, open = FALSE)

cat("\nGenerated output dir:", result$output_dir, "\n")
qmd_path <- normalizePath(file.path(result$output_dir, "test.qmd"), mustWork = FALSE)
cat("QMD file path:", qmd_path, "\n")
cat("File exists:", file.exists(qmd_path), "\n")

if (file.exists(qmd_path)) {
  qmd <- readLines(qmd_path)
  cat("\n=== First 100 lines of generated QMD ===\n")
  cat(qmd[1:min(100, length(qmd))], sep = "\n")
  
  cat("\n\n=== Checking for pagination elements ===\n")
  cat("Has #section2:", any(grepl("#section2", qmd, fixed = TRUE)), "\n")
  cat("Has #section3:", any(grepl("#section3", qmd, fixed = TRUE)), "\n")
  cat("Has pagination-load-btn:", any(grepl("pagination-load-btn", qmd)), "\n")
  cat("Has paginated-section:", any(grepl("paginated-section", qmd)), "\n")
  cat("Count of Load More buttons:", sum(grepl("pagination-load-btn", qmd)), "\n")
} else {
  cat("ERROR: QMD file was not generated!\n")
}

