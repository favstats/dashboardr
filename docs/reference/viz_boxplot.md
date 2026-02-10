# Create a Box Plot

Creates an interactive box plot using highcharter. Supports grouped
boxplots, horizontal orientation, outlier display, and weighted
percentile calculations.

## Usage

``` r
viz_boxplot(
  data,
  y_var,
  x_var = NULL,
  title = NULL,
  subtitle = NULL,
  x_label = NULL,
  y_label = NULL,
  color_palette = NULL,
  show_outliers = TRUE,
  horizontal = FALSE,
  weight_var = NULL,
  x_order = NULL,
  x_map_values = NULL,
  include_na = FALSE,
  na_label = "(Missing)",
  tooltip = NULL,
  tooltip_prefix = "",
  tooltip_suffix = "",
  legend_position = NULL,
  backend = "highcharter"
)
```

## Arguments

- data:

  A data frame containing the variable to plot.

- y_var:

  String. Name of the numeric column for the boxplot.

- x_var:

  Optional string. Name of a grouping variable for multiple boxes.

- title:

  Optional string. Main chart title.

- subtitle:

  Optional string. Chart subtitle.

- x_label:

  Optional string. X-axis label. Defaults to `x_var`.

- y_label:

  Optional string. Y-axis label. Defaults to `y_var`.

- color_palette:

  Optional character vector of colors for the boxes.

- show_outliers:

  Logical. If TRUE, show outlier points. Default TRUE.

- horizontal:

  Logical. If TRUE, flip chart orientation. Default FALSE.

- weight_var:

  Optional string. Name of a weight variable for weighted percentile
  calculations.

- x_order:

  Optional character vector specifying the order of x categories.

- x_map_values:

  Optional named list to recode `x_var` values (e.g.,
  `list("1" = "Male", "2" = "Female")`).

- include_na:

  Logical. If TRUE, include NA groups as explicit category. Default
  FALSE.

- na_label:

  String. Label for NA group when `include_na = TRUE`. Default
  "(Missing)".

- tooltip:

  A tooltip configuration created with
  [`tooltip()`](https://favstats.github.io/dashboardr/reference/tooltip.md),
  OR a format string with {placeholders}. Boxplot-specific placeholders:
  `{category}`, `{high}`, `{q3}`, `{median}`, `{q1}`, `{low}`. See
  [`tooltip`](https://favstats.github.io/dashboardr/reference/tooltip.md)
  for full customization options.

- tooltip_prefix:

  Optional string prepended to values in tooltip.

- tooltip_suffix:

  Optional string appended to values in tooltip.

- legend_position:

  Position of the legend ("top", "bottom", "left", "right", "none")

- backend:

  Rendering backend: "highcharter" (default), "plotly", "echarts4r", or
  "ggiraph".

## Value

A `highcharter` boxplot object.

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic boxplot
data(gss_panel20)

# Example 1: Simple boxplot of age
plot1 <- viz_boxplot(
  data = gss_panel20,
  y_var = "age",
  title = "Age Distribution"
)
plot1

# Example 2: Boxplot by education level
plot2 <- viz_boxplot(
  data = gss_panel20,
  y_var = "age",
  x_var = "degree",
  title = "Age Distribution by Education",
  x_label = "Highest Degree",
  y_label = "Age (years)"
)
plot2

# Example 3: Horizontal boxplot without outliers
plot3 <- viz_boxplot(
  data = gss_panel20,
  y_var = "age",
  x_var = "sex",
  title = "Age by Sex",
  horizontal = TRUE,
  show_outliers = FALSE
)
plot3
} # }
```
