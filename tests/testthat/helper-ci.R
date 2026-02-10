# Helper: skip slow / memory-heavy tests when running under covr on CI
# covr instruments every line, so generating full dashboards with many
# highcharter widgets can exceed the 7 GB memory limit on GitHub Actions.

skip_on_covr_ci <- function() {
  if (identical(Sys.getenv("DASHBOARDR_COVR_CI"), "true")) {
    testthat::skip("Skipping memory-intensive test under covr on CI")
  }
}

# Helper: find Quarto binary, including RStudio-bundled path.
# Ensures Quarto is discoverable even when running outside RStudio
# (e.g. terminal devtools::test()) where RStudio doesn't add its
# bundled Quarto to PATH.
.find_quarto <- function() {
  # 1. Check PATH
  q <- Sys.which("quarto")
  if (nzchar(q)) return(q)


  # 2. Check quarto R package
  if (requireNamespace("quarto", quietly = TRUE)) {
    qp <- quarto::quarto_path()
    if (!is.null(qp) && nzchar(qp) && file.exists(qp)) return(qp)
  }

  # 3. Check RStudio-bundled Quarto (macOS)
  rstudio_quarto <- "/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto"
  if (file.exists(rstudio_quarto)) return(rstudio_quarto)

  # 4. Not found
  return("")
}

skip_if_no_quarto <- function() {
  qpath <- .find_quarto()
  if (!nzchar(qpath)) {
    testthat::skip("Quarto not available")
  }
  # Ensure Quarto is on PATH for child processes (e.g. quarto render)
  quarto_dir <- dirname(qpath)
  current_path <- Sys.getenv("PATH")
  if (!grepl(quarto_dir, current_path, fixed = TRUE)) {
    Sys.setenv(PATH = paste(quarto_dir, current_path, sep = ":"))
  }
  invisible(qpath)
}
