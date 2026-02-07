# Helper: skip slow / memory-heavy tests when running under covr on CI
# covr instruments every line, so generating full dashboards with many
# highcharter widgets can exceed the 7 GB memory limit on GitHub Actions.

skip_on_covr_ci <- function() {
  if (identical(Sys.getenv("DASHBOARDR_COVR_CI"), "true")) {
    testthat::skip("Skipping memory-intensive test under covr on CI")
  }
}
