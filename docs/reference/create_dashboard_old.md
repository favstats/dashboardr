# Create a dashboard (old version)

Create a dashboard (old version)

## Usage

``` r
create_dashboard_old(
  data,
  output_dir = "dashboard_output",
  dashboard_name = "dashboard",
  site = FALSE,
  render = FALSE,
  title = "Dashboard Site",
  open = FALSE
)
```

## Arguments

- data:

  A data.frame or a named list of data.frames (for multi-page site).

- output_dir:

  Directory for output (site directory).

- dashboard_name:

  Name for the dashboard (used when `site = FALSE`).

- site:

  If TRUE, scaffold a website with index + dashboards.

- render:

  If TRUE, render HTML with Quarto immediately.

- title:

  Title for the dashboard/site.

- open:

  If TRUE, open the rendered HTML in your browser (forces render).
