# Process tooltip configuration for a chart

Internal function that converts tooltip parameters into the appropriate
Highcharts tooltip configuration. Handles the 3-tier priority system.

## Usage

``` r
.process_tooltip_config(
  tooltip = NULL,
  tooltip_prefix = NULL,
  tooltip_suffix = NULL,
  x_tooltip_suffix = NULL,
  chart_type = "bar",
  context = list()
)
```

## Arguments

- tooltip:

  A dashboardr_tooltip object, a format string, or NULL

- tooltip_prefix:

  Legacy prefix parameter

- tooltip_suffix:

  Legacy suffix parameter

- x_tooltip_suffix:

  Legacy x suffix parameter

- chart_type:

  Character identifying the chart type

- context:

  Named list with chart-specific context (labels, data info, etc.)

## Value

A list with 'formatter_js' (JavaScript function string) and 'options'
(list of hc_tooltip options)
