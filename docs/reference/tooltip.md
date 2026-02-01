# Create a Tooltip Configuration

Creates a tooltip configuration object for use with dashboardr
visualization functions. This provides a unified way to customize
tooltips across all chart types with full access to Highcharts tooltip
options.

## Usage

``` r
tooltip(
  format = NULL,
  prefix = NULL,
  suffix = NULL,
  header = NULL,
  shared = FALSE,
  style = NULL,
  backgroundColor = NULL,
  borderColor = NULL,
  borderRadius = NULL,
  borderWidth = NULL,
  shadow = TRUE,
  enabled = TRUE,
  followPointer = NULL,
  outside = NULL,
  ...
)
```

## Arguments

- format:

  Character. Format string with {placeholders}. Available placeholders
  vary by chart type:

  - `{value}` - Primary value (all charts)

  - `{category}` - X-axis category (bar, histogram, stackedbar)

  - `{x}` - X value (scatter, heatmap)

  - `{y}` - Y value (scatter, heatmap)

  - `{name}` - Point/series name (all charts)

  - `{series}` - Series name (grouped charts)

  - `{percent}` - Percentage (percent-type charts)

- prefix:

  Character. Text prepended to the value. Shortcut for simple
  customization.

- suffix:

  Character. Text appended to the value. Shortcut for simple
  customization.

- header:

  Character or FALSE. Header format string, or FALSE to hide the header.

- shared:

  Logical. If TRUE, shows a shared tooltip for all series at the same
  x-value. Default is FALSE.

- style:

  Named list. CSS styles for the tooltip text, e.g.,
  `list(fontSize = "14px", fontWeight = "bold")`.

- backgroundColor:

  Character. Background color for the tooltip (e.g., "#f5f5f5").

- borderColor:

  Character. Border color for the tooltip.

- borderRadius:

  Numeric. Corner radius in pixels.

- borderWidth:

  Numeric. Border width in pixels.

- shadow:

  Logical. Whether to show a shadow behind the tooltip. Default is TRUE.

- enabled:

  Logical. Whether tooltips are enabled. Default is TRUE.

- followPointer:

  Logical. Whether the tooltip should follow the mouse pointer.

- outside:

  Logical. Whether to render the tooltip outside the chart SVG.

- ...:

  Additional Highcharts tooltip options passed directly to hc_tooltip().

## Value

A `dashboardr_tooltip` object that can be passed to any viz\_\*
function's `tooltip` parameter.

## See also

[`viz_bar`](https://favstats.github.io/dashboardr/reference/viz_bar.md),
[`viz_scatter`](https://favstats.github.io/dashboardr/reference/viz_scatter.md),
[`viz_histogram`](https://favstats.github.io/dashboardr/reference/viz_histogram.md)

## Examples

``` r
# Simple suffix
tooltip(suffix = "%")
#> <dashboardr_tooltip>
#>   suffix: % 

# Custom format string
tooltip(format = "{category}: {value} respondents")
#> <dashboardr_tooltip>
#>   format: {category}: {value} respondents 

# Full styling
tooltip(
  format = "<b>{category}</b><br/>Count: {value}",
  backgroundColor = "#f5f5f5",
  borderColor = "#999",
  borderRadius = 8,
  style = list(fontSize = "14px")
)
#> <dashboardr_tooltip>
#>   format: <b>{category}</b><br/>Count: {value} 
#>   style: fontSize = 14px 
#> 
#>   backgroundColor: #f5f5f5 
#>   borderColor: #999 
#>   borderRadius: 8 px

# Shared tooltip for grouped charts
tooltip(shared = TRUE, format = "{series}: {value}")
#> <dashboardr_tooltip>
#>   format: {series}: {value} 
#>   shared: TRUE
```
