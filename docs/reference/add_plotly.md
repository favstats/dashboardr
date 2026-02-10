# Add a plotly chart to the dashboard

Convenience wrapper around
[`add_widget`](https://favstats.github.io/dashboardr/reference/add_widget.md)
for plotly objects.

## Usage

``` r
add_plotly(
  content,
  plot,
  title = NULL,
  height = NULL,
  tabgroup = NULL,
  filter_vars = NULL,
  show_when = NULL
)
```

## Arguments

- content:

  A content_collection, page_object, or dashboard_project

- plot:

  A plotly object (created with
  [`plotly::plot_ly()`](https://rdrr.io/pkg/plotly/man/plot_ly.html) or
  [`plotly::ggplotly()`](https://rdrr.io/pkg/plotly/man/ggplotly.html))

- title:

  Optional title displayed above the chart

- height:

  Optional CSS height

- tabgroup:

  Optional tabgroup for organizing content

- filter_vars:

  Optional character vector of input filter variables to apply to this
  block.

- show_when:

  One-sided formula controlling conditional display based on input
  values.

## Value

Updated content object
