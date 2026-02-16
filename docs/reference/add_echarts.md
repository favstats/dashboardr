# Add an echarts4r chart to the dashboard

Convenience wrapper around
[`add_widget`](https://favstats.github.io/dashboardr/reference/add_widget.md)
for echarts4r objects.

## Usage

``` r
add_echarts(
  content,
  chart,
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

- chart:

  An echarts4r object (created with
  [`echarts4r::e_charts()`](http://echarts4r.john-coene.com/reference/init.md))

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
