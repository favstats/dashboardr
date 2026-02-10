# Add a generic htmlwidget to the dashboard

Embed any htmlwidget object (plotly, leaflet, echarts4r, DT, etc.)
directly into a dashboard page. The widget will be rendered as-is.

## Usage

``` r
add_widget(
  content,
  widget,
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

- widget:

  An htmlwidget object

- title:

  Optional title displayed above the widget

- height:

  Optional CSS height (e.g., "400px", "50vh")

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
