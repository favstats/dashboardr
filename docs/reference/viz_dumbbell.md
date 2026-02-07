# Create a Dumbbell Chart

Creates an interactive dumbbell (dot plot range) chart using
highcharter. Dumbbell charts show the difference between two values per
category, useful for before/after comparisons, ranges, or gaps.

## Usage

``` r
viz_dumbbell(
  data,
  x_var,
  low_var,
  high_var,
  title = NULL,
  subtitle = NULL,
  x_label = NULL,
  y_label = NULL,
  horizontal = TRUE,
  low_label = "Low",
  high_label = "High",
  low_color = "#E15759",
  high_color = "#4E79A7",
  connector_color = "#999999",
  connector_width = 2,
  dot_size = 6,
  x_order = NULL,
  sort_by_gap = FALSE,
  sort_desc = TRUE,
  data_labels_enabled = FALSE,
  color_palette = NULL,
  tooltip = NULL,
  tooltip_prefix = "",
  tooltip_suffix = ""
)
```

## Arguments

- data:

  A data frame containing the data.

- x_var:

  Character string. Name of the categorical variable (category labels).

- low_var:

  Character string. Name of the numeric column for the lower value.

- high_var:

  Character string. Name of the numeric column for the higher value.

- title:

  Optional main title for the chart.

- subtitle:

  Optional subtitle for the chart.

- x_label:

  Optional label for the category axis.

- y_label:

  Optional label for the value axis.

- horizontal:

  Logical. If TRUE (default), creates horizontal dumbbells.

- low_label:

  Character string. Label for the low-value series. Default "Low".

- high_label:

  Character string. Label for the high-value series. Default "High".

- low_color:

  Character string. Color for the low-value dots. Default "#E15759".

- high_color:

  Character string. Color for the high-value dots. Default "#4E79A7".

- connector_color:

  Character string. Color for the connecting line. Default "#999999".

- connector_width:

  Numeric. Width of the connecting line in pixels. Default 2.

- dot_size:

  Numeric. Radius of the dots in pixels. Default 6.

- x_order:

  Optional character vector specifying the order of categories.

- sort_by_gap:

  Logical. If TRUE, sort by the gap between high and low values. Default
  FALSE.

- sort_desc:

  Logical. Sort direction. Default TRUE (largest gap first).

- data_labels_enabled:

  Logical. If TRUE, show value labels. Default FALSE.

- color_palette:

  Optional named vector of two colors: c(low = "...", high = "...").

- tooltip:

  A tooltip configuration created with
  [`tooltip()`](https://favstats.github.io/dashboardr/reference/tooltip.md),
  OR a format string with {placeholders}.

- tooltip_prefix:

  Optional string prepended to tooltip values.

- tooltip_suffix:

  Optional string appended to tooltip values.

## Value

A highcharter plot object.

## Examples

``` r
if (FALSE) { # \dontrun{
df <- data.frame(
  country = c("US", "UK", "DE", "FR"),
  score_2020 = c(65, 58, 72, 60),
  score_2024 = c(78, 65, 75, 70)
)
viz_dumbbell(df, x_var = "country",
             low_var = "score_2020", high_var = "score_2024",
             low_label = "2020", high_label = "2024",
             title = "Score Changes 2020-2024")
} # }
```
