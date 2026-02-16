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
  preview = NULL,
  show_progress = TRUE,
  quiet = FALSE,
  standalone = FALSE
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

  Whether to use incremental builds (default: FALSE). When TRUE, skips
  regenerating QMD files for unchanged pages and skips Quarto rendering
  if nothing changed. Uses MD5 hashing to detect changes.

- preview:

  Optional character vector of page names to generate. When specified,
  only the listed pages will be generated, skipping all others. Useful
  for quick testing of specific pages without waiting for the entire
  dashboard to generate. Page names are case-insensitive. If a page name
  doesn't exist, the function will suggest alternatives based on typo
  detection. Default: NULL (generates all pages).

- show_progress:

  Whether to display custom progress indicators (default: TRUE). When
  TRUE, shows a beautiful progress display with timing information,
  progress bars, and visual indicators for each generation stage. Set to
  FALSE for minimal output.

- quiet:

  Whether to suppress all output (default: FALSE). When TRUE, completely
  silences all messages, progress indicators, and Quarto rendering
  output. Useful for scripts and automated workflows. Overrides
  show_progress.

- standalone:

  Whether to embed all resources (CSS, JS, images, fonts) into a single
  self-contained HTML file (default: FALSE). When TRUE, sets Quarto's
  `embed-resources: true` so the output HTML can be shared without a web
  server. Implies `render = TRUE`.

## Value

Invisibly returns the project object with build_info attached

## Examples

``` r
if (FALSE) { # \dontrun{
# Generate and render dashboard
dashboard %>% generate_dashboard(render = TRUE, open = "browser")

# Generate without rendering (faster for quick iterations)
dashboard %>% generate_dashboard(render = FALSE)

# Incremental builds (skip unchanged pages)
dashboard %>% generate_dashboard(render = TRUE, incremental = TRUE)

# Preview specific page
dashboard %>% generate_dashboard(preview = "Analysis")

# Quiet mode for scripts
dashboard %>% generate_dashboard(render = FALSE, quiet = TRUE)

# Standalone HTML (single file, all resources embedded)
dashboard %>% generate_dashboard(standalone = TRUE)
} # }
```
