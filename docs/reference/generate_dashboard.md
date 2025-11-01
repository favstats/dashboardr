# Generate all dashboard files

Writes out all .qmd files, \_quarto.yml, and optionally renders the
dashboard to HTML using Quarto.

## Usage

``` r
generate_dashboard(proj, render = TRUE, open = "browser")
```

## Arguments

- proj:

  A dashboard_project object

- render:

  Whether to render to HTML (requires Quarto CLI)

- open:

  How to open the result: "browser", "viewer", or FALSE

## Value

Invisibly returns the project object

## Examples

``` r
if (FALSE) { # \dontrun{
dashboard %>% generate_dashboard(render = TRUE, open = "browser")
} # }
```
