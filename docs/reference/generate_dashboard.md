# Generate all dashboard files

Writes out all .qmd files, \_quarto.yml, and optionally renders the
dashboard to HTML using Quarto. Supports incremental builds to skip
unchanged pages and preview mode to generate only specific pages.

## Usage

``` r
generate_dashboard(
  proj,
  render = TRUE,
  open = "browser",
  incremental = FALSE,
  preview = NULL
)
```

## Arguments

- proj:

  A dashboard_project object

- render:

  Whether to render to HTML (requires Quarto CLI)

- open:

  How to open the result: "browser", "viewer", or FALSE

- incremental:

  Whether to use incremental builds (default: FALSE). When TRUE, only
  regenerates pages that have changed since the last build.

- preview:

  Optional character vector of page names to generate. When specified,
  only the listed pages will be generated, skipping all others. Useful
  for quick testing of specific pages without waiting for the entire
  dashboard to generate. Page names are case-insensitive. If a page name
  doesn't exist, the function will suggest alternatives based on typo
  detection. Default: NULL (generates all pages).

## Value

Invisibly returns the project object with build_info attached

## Examples

``` r
if (FALSE) { # \dontrun{
# Standard generation
dashboard %>% generate_dashboard(render = TRUE, open = "browser")

# Incremental build (faster for subsequent builds)
dashboard %>% generate_dashboard(render = TRUE, incremental = TRUE)

# Preview mode - generate only specific pages
dashboard %>% generate_dashboard(preview = "Analysis")
dashboard %>% generate_dashboard(preview = c("Home", "Analysis"))

# Combine preview with incremental for maximum speed
dashboard %>% generate_dashboard(preview = "Analysis", incremental = TRUE)
} # }
```
