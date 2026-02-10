# Add a leaflet map to the dashboard

Convenience wrapper around
[`add_widget`](https://favstats.github.io/dashboardr/reference/add_widget.md)
for leaflet objects.

## Usage

``` r
add_leaflet(
  content,
  map,
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

- map:

  A leaflet object (created with
  [`leaflet::leaflet()`](https://rstudio.github.io/leaflet/reference/leaflet.html))

- title:

  Optional title displayed above the map

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
