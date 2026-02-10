# Create a Density Plot

Creates an interactive kernel density estimate plot using highcharter.
Supports grouped densities, weighted kernel density estimation, and
customization options.

## Usage

``` r
viz_density(
  data,
  x_var,
  group_var = NULL,
  title = NULL,
  subtitle = NULL,
  x_label = NULL,
  y_label = NULL,
  color_palette = NULL,
  fill_opacity = 0.3,
  show_rug = FALSE,
  bandwidth = NULL,
  weight_var = NULL,
  group_order = NULL,
  include_na = FALSE,
  na_label = "(Missing)",
  tooltip = NULL,
  tooltip_suffix = "",
  legend_position = NULL,
  backend = "highcharter"
)
```

## Arguments

- data:

  A data frame containing the variable to plot.

- x_var:

  String. Name of the numeric column for density estimation.

- group_var:

  Optional string. Name of a grouping variable for multiple overlaid
  densities.

- title:

  Optional string. Main chart title.

- subtitle:

  Optional string. Chart subtitle.

- x_label:

  Optional string. X-axis label. Defaults to `x_var`.

- y_label:

  Optional string. Y-axis label. Defaults to "Density".

- color_palette:

  Optional character vector of colors for the density curves.

- fill_opacity:

  Numeric between 0 and 1. Fill transparency. Default 0.3.

- show_rug:

  Logical. If TRUE, show rug marks at the bottom. Default FALSE.

- bandwidth:

  Optional numeric. Kernel bandwidth. If NULL (default), uses R's
  default bandwidth selection.

- weight_var:

  Optional string. Name of a weight variable for weighted density
  estimation.

- group_order:

  Optional character vector specifying the order of groups.

- include_na:

  Logical. If TRUE, include NA groups as explicit category. Default
  FALSE.

- na_label:

  String. Label for NA group when `include_na = TRUE`. Default
  "(Missing)".

- tooltip:

  A tooltip configuration created with
  [`tooltip()`](https://favstats.github.io/dashboardr/reference/tooltip.md),
  OR a format string with {placeholders}. Available placeholders: `{x}`,
  `{y}`, `{value}`, `{series}`. See
  [`tooltip`](https://favstats.github.io/dashboardr/reference/tooltip.md)
  for full customization options.

- tooltip_suffix:

  Optional string appended to density values in tooltip (simple
  customization).

- legend_position:

  Position of the legend ("top", "bottom", "left", "right", "none")

- backend:

  Rendering backend: "highcharter" (default), "plotly", "echarts4r", or
  "ggiraph".

## Value

A `highcharter` density plot object.

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic density plot
data(gss_panel20)

# Example 1: Simple density of age
plot1 <- viz_density(
  data = gss_panel20,
  x_var = "age",
  title = "Age Distribution",
  x_label = "Age (years)"
)
plot1

# Example 2: Grouped densities by sex
plot2 <- viz_density(
  data = gss_panel20,
  x_var = "age",
  group_var = "sex",
  title = "Age Distribution by Sex",
  x_label = "Age (years)",
  color_palette = c("#3498DB", "#E74C3C")
)
plot2

# Example 3: Customized density with rug marks
plot3 <- viz_density(
  data = gss_panel20,
  x_var = "age",
  title = "Age Distribution",
  fill_opacity = 0.5,
  show_rug = TRUE,
  bandwidth = 3
)
plot3
} # }
```
