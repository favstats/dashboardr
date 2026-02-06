# --------------------------------------------------------------------------
# Function: create_dashboard
# --------------------------------------------------------------------------
#' Create a dashboard (old version)
#'
#' @param data A data.frame or a named list of data.frames (for multi-page site).
#' @param output_dir Directory for output (site directory).
#' @param dashboard_name Name for the dashboard (used when `site = FALSE`).
#' @param site If TRUE, scaffold a website with index + dashboards.
#' @param render If TRUE, render HTML with Quarto immediately.
#' @param title Title for the dashboard/site.
#' @param open If TRUE, open the rendered HTML in your browser (forces render).
#' @keywords internal
#' @export
create_dashboard_old <- function(data,
                             output_dir = "dashboard_output",
                             dashboard_name = "dashboard",
                             site = FALSE,
                             render = FALSE,
                             title = "Dashboard Site",
                             open = FALSE) {

  # If user wants to open, ensure we render
  if (open && !render) render <- TRUE

  if (site) {
    .create_dashboard_site(data, output_dir, title, render, open)
  } else {
    .create_dashboard_page(data, output_dir, dashboard_name, render, open)
  }
}

# Internal: single-page builder (renders a single .qmd)
.create_dashboard_page <- function(data, output_dir, dashboard_name, render, open) {
  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

  # Save data next to the page
  saveRDS(data, file.path(output_dir, "dashboard_data.rds"))

  # Locate template
  template_path <- system.file("extdata/templates/template.qmd", package = "dashboardr")
  if (template_path == "" || !file.exists(template_path)) {
    stop("\u274c Could not find 'template.qmd' in dashboardr (inst/extdata/templates).")
  }

  # Copy to target .qmd
  target_file <- file.path(output_dir, paste0(dashboard_name, ".qmd"))
  if (!file.copy(template_path, target_file, overwrite = TRUE)) {
    stop("\u274c Failed to copy template to: ", target_file)
  }

  # Render the .qmd
  if (render && requireNamespace("quarto", quietly = TRUE)) {
    owd <- setwd(normalizePath(output_dir)); on.exit(setwd(owd), add = TRUE)
    quarto::quarto_render(basename(target_file), as_job = FALSE)
    message("\u2705 Dashboard rendered: ", target_file)

    # Open the resulting HTML if requested
    if (open) {
      html_path <- file.path(output_dir, paste0(dashboard_name, ".html"))
      if (file.exists(html_path)) utils::browseURL(normalizePath(html_path))
    }
  } else {
    message("\U0001f4c4 Page created: ", target_file)
  }

  invisible(target_file)
}

# Internal: site builder (renders the project)
.create_dashboard_site <- function(data, output_dir, title, render, open) {
  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

  # Always write a clean _quarto.yml (idempotent)
  quarto_yml <- file.path(output_dir, "_quarto.yml")
  writeLines(c(
    "project:",
    "  type: website",
    "  output-dir: docs",
    "",
    "website:",
    paste0("  title: \"", title, "\""),
    "  navbar:",
    "    left:",
    "      - href: index.qmd",
    "        text: \"Home\""
  ), quarto_yml)

  # Landing page (don't overwrite if customized)
  index_qmd <- file.path(output_dir, "index.qmd")
  if (!file.exists(index_qmd)) {
    writeLines(c(
      "---",
      paste0("title: \"", title, "\""),
      "format: html",
      "---",
      "",
      "# Welcome",
      "",
      "This is the landing page."
    ), index_qmd)
  }

  # Generate dashboards and add to navbar
  if (is.list(data) && !is.data.frame(data)) {
    for (nm in names(data)) {
      .create_dashboard_page(data[[nm]], output_dir, nm, render = FALSE, open = FALSE)
      cat(
        sprintf("      - href: %s.qmd\n        text: \"%s\"\n", nm, nm),
        file = quarto_yml, append = TRUE
      )
    }
  } else {
    .create_dashboard_page(data, output_dir, "dashboard", render = FALSE, open = FALSE)
    cat("      - href: dashboard.qmd\n        text: \"Dashboard\"\n",
        file = quarto_yml, append = TRUE)
  }

  # Render the project from within the project directory
  if (render && requireNamespace("quarto", quietly = TRUE)) {
    proj_dir <- normalizePath(output_dir)
    owd <- setwd(proj_dir); on.exit(setwd(owd), add = TRUE)
    quarto::quarto_render(".", as_job = FALSE)
    message("\u2705 Dashboard site rendered at: ", file.path(output_dir, "docs"))

    # Open the site home if requested
    if (open) {
      index_html <- file.path(output_dir, "docs", "index.html")
      if (file.exists(index_html)) utils::browseURL(normalizePath(index_html))
    }
  } else {
    message("\U0001f4c2 Dashboard site initialized at: ", output_dir)
  }

  invisible(output_dir)
}
