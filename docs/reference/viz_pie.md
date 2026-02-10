# Create a Pie or Donut Chart

Creates an interactive pie or donut chart using highcharter. Pie charts
show proportional data as slices of a circle. Donut charts are pie
charts with a hollow center.

## Usage

``` r
viz_pie(
  data,
  x_var,
  y_var = NULL,
  title = NULL,
  subtitle = NULL,
  inner_size = "0%",
  color_palette = NULL,
  x_order = NULL,
  sort_by_value = FALSE,
  data_labels_enabled = TRUE,
  data_labels_format = "{point.name}: {point.percentage:.1f}%",
  show_in_legend = TRUE,
  weight_var = NULL,
  include_na = FALSE,
  na_label = "(Missing)",
  tooltip = NULL,
  tooltip_prefix = "",
  tooltip_suffix = "",
  center_text = NULL,
  legend_position = NULL,
  backend = "highcharter"
)
```

## Arguments

- data:

  A data frame containing the data.

- x_var:

  Character string. Name of the categorical variable (slice labels).

- y_var:

  Optional character string. Name of a numeric column with
  pre-aggregated values. When provided, skips counting and uses these
  values directly.

- title:

  Optional main title for the chart.

- subtitle:

  Optional subtitle for the chart.

- inner_size:

  Character string. Size of the inner hole as percentage (e.g., "50%").
  Set to "0%" for a standard pie chart (default), or "40%"-"70%" for a
  donut chart.

- color_palette:

  Optional character vector of colors for the slices.

- x_order:

  Optional character vector specifying the order of slices.

- sort_by_value:

  Logical. If TRUE, sort slices by value (largest first). Default FALSE.

- data_labels_enabled:

  Logical. If TRUE (default), show labels on slices.

- data_labels_format:

  Character string. Format for data labels. Default shows name and
  percentage: "{point.name}: {point.percentage:.1f}%".

- show_in_legend:

  Logical. If TRUE (default), show a legend.

- weight_var:

  Optional character string. Name of a weight variable for weighted
  counts.

- include_na:

  Logical. Whether to include NA as a category. Default FALSE.

- na_label:

  Character string. Label for the NA category. Default "(Missing)".

- tooltip:

  A tooltip configuration created with
  [`tooltip()`](https://favstats.github.io/dashboardr/reference/tooltip.md),
  OR a format string with {placeholders}. Available placeholders:
  `{name}`, `{value}`, `{percent}`. See
  [`tooltip`](https://favstats.github.io/dashboardr/reference/tooltip.md)
  for full customization options.

- tooltip_prefix:

  Optional string prepended to tooltip values.

- tooltip_suffix:

  Optional string appended to tooltip values.

- center_text:

  Optional character string. Text to display in the center of a donut
  chart. Only visible when inner_size \> "0%".

- legend_position:

  Position of the legend ("top", "bottom", "left", "right", "none")

- backend:

  Rendering backend: "highcharter" (default), "plotly", "echarts4r", or
  "ggiraph".

## Value

A highcharter plot object.

## Examples

``` r
if (FALSE) { # \dontrun{
# Simple pie chart
viz_pie(mtcars, x_var = "cyl", title = "Cars by Cylinders")

# Donut chart
viz_pie(mtcars, x_var = "cyl", inner_size = "50%", title = "Donut Chart")

# Pre-aggregated data
df <- data.frame(category = c("A", "B", "C"), count = c(40, 35, 25))
viz_pie(df, x_var = "category", y_var = "count")
} # }
```
