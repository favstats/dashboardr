# Add Page to Dashboard (Alias)

Convenient alias for
[`add_dashboard_page`](https://favstats.github.io/dashboardr/reference/add_dashboard_page.md).
Adds a new page to a dashboard project.

## Usage

``` r
add_page(
  proj,
  name,
  data = NULL,
  data_path = NULL,
  template = NULL,
  params = list(),
  visualizations = NULL,
  content = NULL,
  text = NULL,
  icon = NULL,
  is_landing_page = FALSE,
  tabset_theme = NULL,
  tabset_colors = NULL,
  navbar_align = c("left", "right"),
  overlay = FALSE,
  overlay_theme = c("light", "glass", "dark", "accent"),
  overlay_text = "Loading",
  overlay_duration = 2200,
  lazy_load_charts = NULL,
  lazy_load_margin = NULL,
  lazy_load_tabs = NULL,
  lazy_debug = NULL,
  pagination_separator = NULL,
  time_var = NULL
)
```

## Arguments

- proj:

  Dashboard project object created by
  [`create_dashboard`](https://favstats.github.io/dashboardr/reference/create_dashboard.md).

- ...:

  All arguments passed to
  [`add_dashboard_page`](https://favstats.github.io/dashboardr/reference/add_dashboard_page.md).

## Value

Modified dashboard project with the new page added.

## See also

[`add_dashboard_page`](https://favstats.github.io/dashboardr/reference/add_dashboard_page.md)
for full parameter documentation.
