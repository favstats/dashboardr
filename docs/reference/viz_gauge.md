# Create a Gauge or Bullet Chart

Creates an interactive gauge (speedometer) or bullet chart using
highcharter. Gauges show a single value against a scale, ideal for KPIs
and scores.

## Usage

``` r
viz_gauge(
  data = NULL,
  value = NULL,
  value_var = NULL,
  min = 0,
  max = 100,
  title = NULL,
  subtitle = NULL,
  gauge_type = "solid",
  bands = NULL,
  inner_radius = "60%",
  rounded = TRUE,
  data_labels_format = "{y}",
  data_labels_style = NULL,
  color = "#4E79A7",
  background_color = "#e6e6e6",
  target = NULL,
  target_color = "#333333",
  height = 300,
  backend = "highcharter"
)
```

## Arguments

- data:

  Optional data frame. If provided, `value_var` is used to extract the
  value.

- value:

  Numeric. The value to display on the gauge. Used when `data` is NULL.

- value_var:

  Optional character string. Column name in `data` to use as the value.
  The mean/first value is extracted.

- min:

  Numeric. Minimum value of the gauge scale. Default 0.

- max:

  Numeric. Maximum value of the gauge scale. Default 100.

- title:

  Optional main title for the chart.

- subtitle:

  Optional subtitle for the chart.

- gauge_type:

  Character string. Type of gauge: "solid" (default) or "activity".
  "solid" creates a solid gauge (filled arc). "activity" creates an
  activity-style gauge.

- bands:

  Optional list of band definitions for color zones. Each band is a list
  with: `from`, `to`, `color`, and optionally `label`. Example:
  `list(list(from = 0, to = 50, color = "red"), list(from = 50, to = 100, color = "green"))`.

- inner_radius:

  Character string. Inner radius of the gauge arc as percentage. Default
  "60%". Increase for thinner arc, decrease for thicker.

- rounded:

  Logical. If TRUE (default), use rounded ends on the gauge arc.

- data_labels_format:

  Character string. Format for the center label. Default "{y}". Use
  "{y}%" for percentage, "\${y}" for currency, etc.

- data_labels_style:

  Optional list of CSS styles for the center label. Default: large bold
  text.

- color:

  Character string. Color of the gauge fill. Default "#4E79A7". Ignored
  if `bands` are specified (band colors are used instead).

- background_color:

  Character string. Color of the gauge background track. Default
  "#e6e6e6".

- target:

  Optional numeric. Target/goal value to show as a marker on the gauge.

- target_color:

  Character string. Color of the target marker. Default "#333333".

- height:

  Numeric. Chart height in pixels. Default 300.

- backend:

  Rendering backend: "highcharter" (default), "plotly", "echarts4r", or
  "ggiraph".

## Value

A highcharter plot object.

## Examples

``` r
if (FALSE) { # \dontrun{
# Simple gauge
viz_gauge(value = 73, title = "Completion Rate", data_labels_format = "{y}%")

# Gauge with color bands
viz_gauge(value = 65, min = 0, max = 100,
          bands = list(
            list(from = 0, to = 40, color = "#E15759"),
            list(from = 40, to = 70, color = "#F28E2B"),
            list(from = 70, to = 100, color = "#59A14F")
          ),
          title = "Performance Score")

# From data
viz_gauge(data = mtcars, value_var = "mpg", min = 10, max = 35,
          title = "Average MPG")
} # }
```
