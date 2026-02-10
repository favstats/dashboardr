# Create a Waffle Chart

Creates an interactive waffle (square pie) chart using highcharter.
Waffle charts display proportional data as a grid of colored squares,
providing an intuitive alternative to pie charts.

## Usage

``` r
viz_waffle(
  data,
  x_var,
  y_var = NULL,
  title = NULL,
  subtitle = NULL,
  total = 100,
  rows = 10,
  color_palette = NULL,
  x_order = NULL,
  data_labels_enabled = FALSE,
  show_in_legend = TRUE,
  weight_var = NULL,
  border_color = "white",
  border_width = 1,
  tooltip = NULL,
  tooltip_prefix = "",
  tooltip_suffix = "",
  height = 400,
  backend = "highcharter"
)
```

## Arguments

- data:

  A data frame containing the data.

- x_var:

  Character string. Name of the categorical variable (category labels).

- y_var:

  Optional character string. Name of a numeric column with
  pre-aggregated values (counts or percentages). If NULL, counts are
  computed from the data.

- title:

  Optional main title for the chart.

- subtitle:

  Optional subtitle for the chart.

- total:

  Numeric. Total number of squares in the waffle grid. Default 100. Each
  square represents `total_value / total` of the data.

- rows:

  Numeric. Number of rows in the waffle grid. Default 10.

- color_palette:

  Optional character vector of colors for the categories.

- x_order:

  Optional character vector specifying the order of categories.

- data_labels_enabled:

  Logical. If TRUE, show category labels. Default FALSE (legend is shown
  instead).

- show_in_legend:

  Logical. If TRUE (default), show a legend.

- weight_var:

  Optional character string. Name of weight variable.

- border_color:

  Character string. Color of the square borders. Default "white".

- border_width:

  Numeric. Width of square borders in pixels. Default 1.

- tooltip:

  A tooltip configuration created with
  [`tooltip()`](https://favstats.github.io/dashboardr/reference/tooltip.md).

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
  category = c("Agree", "Neutral", "Disagree"),
  count = c(45, 30, 25)
)
viz_waffle(df, x_var = "category", y_var = "count",
           title = "Survey Responses", total = 100)
} # }
```
