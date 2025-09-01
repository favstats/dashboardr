#' Create Dashboard Tutorial Template
#'
#' @param data Data frame to visualize
#' @param output_dir Directory to save dashboard
#' @param dashboard_name Name of the dashboard file
#' @param render Logical. If TRUE (default), renders the Quarto document to HTML
#' @export
create_dashboard <- function(data,
                             output_dir = "dashboard_output",
                             dashboard_name = "tutorial_dashboard",
                             render = TRUE) {

  # Create output directory
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  # Get template path
  template_path <- system.file("quarto", "dashboard_template.qmd",
                               package = "dashboardr")

  if (!file.exists(template_path) || template_path == "") {
    stop("Tutorial template not found. Make sure inst/quarto/dashboard_template.qmd exists.")
  }

  # Define target file path
  target_file <- file.path(output_dir, paste0(dashboard_name, ".qmd"))

  # Copy template
  file.copy(template_path, target_file, overwrite = TRUE)

  # Save data for template to use
  saveRDS(data, file.path(output_dir, "dashboard_data.rds"))

  # Render the dashboard
  if (render) {
    if (requireNamespace("quarto", quietly = TRUE)) {
      quarto::quarto_render(target_file)
      html_file <- file.path(output_dir, paste0(dashboard_name, ".html"))
      message("✅ Dashboard tutorial created and rendered!")
      message("📄 Quarto template: ", target_file)
      message("🌐 HTML output: ", html_file)
      message("💡 Edit the .qmd file and re-render to customize your dashboard")
    } else {
      message("❌ Quarto package not available. Install with: install.packages('quarto')")
      message("📄 Template created at: ", target_file)
      message("🔧 Run manually: quarto render ", target_file)
    }
  } else {
    message("📄 Tutorial template created at: ", target_file)
    message("🔧 To render: quarto render ", target_file)
  }

  invisible(target_file)
}
