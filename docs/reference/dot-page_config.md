# Page configuration and dependency loader

Outputs chart-container CSS/JS for reflow and, when feature flags are
supplied, loads all page-level CSS/JS dependencies (accessibility,
inputs, modals, sidebar, chart export) in a single call.

## Usage

``` r
.page_config(
  accessibility = TRUE,
  inputs = FALSE,
  linked = FALSE,
  show_when = FALSE,
  url_params = FALSE,
  modals = FALSE,
  chart_export = FALSE,
  sidebar = FALSE
)
```

## Arguments

- accessibility:

  Logical; include accessibility CSS/JS (default TRUE).

- inputs:

  Logical; include input filter CSS/JS.

- linked:

  Logical; include linked-input script (only when `inputs = TRUE`).

- show_when:

  Logical; include show_when script.

- url_params:

  Logical; include URL-params script (only when `inputs = TRUE`).

- modals:

  Logical; include modal CSS/JS.

- chart_export:

  Logical; enable Highcharts export buttons.

- sidebar:

  Logical; include sidebar CSS/JS.

## Value

An
[`htmltools::tagList`](https://rstudio.github.io/htmltools/reference/tagList.html)
of HTML tags (rendered via `results='asis'`).
