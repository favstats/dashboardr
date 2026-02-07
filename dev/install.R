## Helper function
install_if_missing <- function(pkgs) {
  missing <- pkgs[!pkgs %in% rownames(installed.packages())]
  if (length(missing) > 0) {
    install.packages(missing)
  }
}

## Core tools for package development
core_pkgs <- c(
  "devtools",
  "usethis",
  "roxygen2",
  "testthat",
  "pkgdown",
  "fs",
  "cli",
  "glue"
)

install_if_missing(core_pkgs)

## Data handling and visualization
data_pkgs <- c(
  "tidyverse",
  "here",
  "janitor",
  "lubridate"
)

install_if_missing(data_pkgs)

## dashboardr from GitHub (only if missing)
if (!"dashboardr" %in% rownames(installed.packages())) {
  if (!"devtools" %in% rownames(installed.packages())) {
    install.packages("devtools")
  }
  devtools::install_github("favstats/dashboardr")
}

## Quick check
pkgs <- c(
  core_pkgs,
  data_pkgs,
  "dashboardr"
)

invisible(lapply(pkgs, library, character.only = TRUE))
