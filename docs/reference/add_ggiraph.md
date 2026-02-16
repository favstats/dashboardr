# Add a ggiraph interactive plot to the dashboard

Convenience wrapper around
[`add_widget`](https://favstats.github.io/dashboardr/reference/add_widget.md)
for ggiraph objects.

## Usage

``` r
add_ggiraph(
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

  A girafe object (created with
  [`ggiraph::girafe()`](https://davidgohel.github.io/ggiraph/reference/girafe.html))

- title:

  Optional title displayed above the plot

- height:

  Optional CSS height

- tabgroup:

  Optional tabgroup for organizing content

- filter_vars:

  Not supported for ggiraph widgets.

- show_when:

  One-sided formula controlling conditional display based on input
  values.

## Value

Updated content object
