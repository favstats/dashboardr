#' Create a dashboard from the bundled Quarto extension (and render it)
#'
#' This installs the package's Quarto extension into `./_extensions/<ext_name>`,
#' creates `<output_dir>/<dashboard_name>.qmd` from the template, saves the data
#' as `dashboard_data.rds`, and optionally renders the HTML.
#'
#' Expected package layout (installed):
#'   inst/extdata/_extensions/<ext_name>/{_extension.yml, template.qmd, header.tex?}
#'   inst/quarto/dashboard_template.qmd   # fallback if extension template missing
#'
#' @param data A data object saved as `dashboard_data.rds` for the template.
#' @param output_dir Output directory for the dashboard files.
#' @param dashboard_name Base name for the .qmd/.html.
#' @param render If TRUE, render the dashboard after creating files.
#' @param ext_name Name of the bundled extension directory under inst/extdata/_extensions/.
#' @export
create_dashboard <- function(data,
                             output_dir = "dashboard_output",
                             dashboard_name = "tutorial_dashboard",
                             render = FALSE,
                             ext_name = "dashboardr") {

  # --- 1) Ensure output dir exists ------------------------------------------------
  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

  # --- 2) Try to locate bundled extension inside the *installed* package ----------
  ext_src_dir <- system.file(file.path("extdata", "_extensions", ext_name),
                             package = "dashboardr")

  # Destination for installed extension in the *current working directory*
  dest_root <- "_extensions"
  dest_dir  <- file.path(dest_root, ext_name)

  # --- 3) Install the extension into ./_extensions/<ext_name> if available -------
  if (nzchar(ext_src_dir) && dir.exists(ext_src_dir)) {
    if (!dir.exists(dest_root)) {
      dir.create(dest_root)
      message("Created '_extensions' folder")
    }
    if (!dir.exists(dest_dir)) dir.create(dest_dir, recursive = TRUE)

    ok <- file.copy(from = ext_src_dir,
                    to   = dest_root,
                    overwrite = TRUE, recursive = TRUE, copy.mode = TRUE)

    if (!ok || !dir.exists(dest_dir)) {
      warning("Extension copy seems to have failed. Proceeding with fallback template if available.")
    } else {
      # Optional friendly metadata
      ext_yml_path <- file.path(dest_dir, "_extension.yml")
      if (file.exists(ext_yml_path)) {
        ext_yml <- readLines(ext_yml_path, warn = FALSE)
        ext_ver <- sub("^version:\\s*", "", ext_yml[grepl("^version:", ext_yml)][1]) %||% "?"
        ext_nm  <- sub("^title:\\s*",   "", ext_yml[grepl("^title:",   ext_yml)][1]) %||% ext_name
        message(sprintf("%s v%s installed to '%s'.", ext_nm, ext_ver, dest_dir))
      } else {
        message(sprintf("Installed extension '%s' (no _extension.yml found for metadata).", ext_name))
      }
    }
  } else {
    message("Bundled extension not found in installed package; will try fallback template.")
  }

  # --- 4) Choose the template: extension first, fallback second -------------------
  ext_template <- file.path(dest_dir, "template.qmd")

  if (file.exists(ext_template)) {
    template_path <- ext_template
  } else {
    stop(
      "No template found.\n"
    )
  }

  # --- 5) Create the .qmd and companion files ------------------------------------
  target_file <- file.path(output_dir, paste0(dashboard_name, ".qmd"))
  ok <- file.copy(template_path, target_file, overwrite = TRUE)
  if (!ok) stop("Failed to copy template to: ", target_file)

  # Save data for the template to load (e.g., via readRDS('dashboard_data.rds'))
  saveRDS(data, file.path(output_dir, "dashboard_data.rds"))

  # --- 6) Render (optional) -------------------------------------------------------
  if (render) {
    if (requireNamespace("quarto", quietly = TRUE)) {
      quarto::quarto_render(target_file)
      html_file <- file.path(output_dir, paste0(dashboard_name, ".html"))
      message("✅ Dashboard created and rendered")
      message("📄 Qmd:  ", target_file)
      message("🌐 HTML: ", html_file)
      message("💡 Edit the .qmd and re-render to customize your dashboard.")
    } else {
      message("❌ Package 'quarto' not available: install.packages('quarto')")
      message("📄 Template created at: ", target_file)
      message("🔧 Render manually with: quarto render ", shQuote(target_file))
    }
  } else {
    message("📄 Template created at: ", target_file)
    message("🔧 To render later: quarto render ", shQuote(target_file))
  }

  invisible(target_file)
}
