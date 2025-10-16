tutorial_dashboard <- function() {
  # Get template directory from package
  template_dir <- system.file("extdata", "templates",
                              package = "dashboardr", mustWork = TRUE)

  # Create temp working directory
  work_dir <- file.path(tempdir(), "dashboard_site")
  if (dir.exists(work_dir)) unlink(work_dir, recursive = TRUE)
  dir.create(work_dir, recursive = TRUE)

  # Copy all template files
  file.copy(
    from = list.files(template_dir, full.names = TRUE),
    to = work_dir,
    recursive = TRUE
  )

  # Render the site
  result <- system2(
    "quarto",
    args = c("render", shQuote(work_dir)),
    stdout = TRUE,
    stderr = TRUE
  )

  # Check for output
  index_path <- file.path(work_dir, "_site", "index.html")

  if (!file.exists(index_path)) {
    cat("Quarto output:\n")
    cat(result, sep = "\n")
    stop("Rendering failed - no index.html created", call. = FALSE)
  }

  # Open in browser
  utils::browseURL(normalizePath(index_path))
  message("Dashboard opened successfully!")

  invisible(index_path)
}
