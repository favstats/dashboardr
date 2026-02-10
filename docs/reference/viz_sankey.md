# Create a Sankey Diagram

Creates an interactive Sankey (alluvial flow) diagram using highcharter.
Sankey diagrams show flows between nodes, where the width of each link
is proportional to the flow quantity.

## Usage

``` r
viz_sankey(
  data,
  from_var,
  to_var,
  value_var,
  title = NULL,
  subtitle = NULL,
  color_palette = NULL,
  node_width = 20,
  node_padding = 10,
  link_opacity = 0.5,
  data_labels_enabled = TRUE,
  curvature = 0.33,
  tooltip = NULL,
  tooltip_prefix = "",
  tooltip_suffix = "",
  height = 400,
  backend = "highcharter"
)
```

## Arguments

- data:

  A data frame containing the flow data.

- from_var:

  Character string. Name of the column with source node names.

- to_var:

  Character string. Name of the column with target node names.

- value_var:

  Character string. Name of the numeric column with flow values/weights.

- title:

  Optional main title for the chart.

- subtitle:

  Optional subtitle for the chart.

- color_palette:

  Optional character vector of colors for the nodes.

- node_width:

  Numeric. Width of the node rectangles in pixels. Default 20.

- node_padding:

  Numeric. Vertical padding between nodes in pixels. Default 10.

- link_opacity:

  Numeric. Opacity of the flow links (0-1). Default 0.5.

- data_labels_enabled:

  Logical. If TRUE (default), show labels on nodes.

- curvature:

  Numeric. Curvature factor for links (0-1). Default 0.33.

- tooltip:

  A tooltip configuration created with
  [`tooltip()`](https://favstats.github.io/dashboardr/reference/tooltip.md),
  OR a format string.

- tooltip_prefix:

  Optional string prepended to tooltip values.

- tooltip_suffix:

  Optional string appended to tooltip values.

- height:

  Numeric. Chart height in pixels. Default 400.

- backend:

  Rendering backend: "highcharter" (default), "plotly", "echarts4r", or
  "ggiraph".

## Value

A highcharter plot object.

## Examples

``` r
if (FALSE) { # \dontrun{
df <- data.frame(
  from = c("A", "A", "B", "B"),
  to = c("X", "Y", "X", "Y"),
  flow = c(30, 20, 10, 40)
)
viz_sankey(df, from_var = "from", to_var = "to", value_var = "flow",
           title = "Flow Diagram")
} # }
```
