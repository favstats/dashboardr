# Render a sparkline card

Render a sparkline card

## Usage

``` r
render_sparkline_card(
  data,
  x_var,
  y_var = NULL,
  value = NULL,
  subtitle = "",
  agg = "count",
  line_color = "#2b74ff",
  bg_color = "#ffffff",
  text_color = "#111827",
  height = 130,
  smooth = 0.6,
  area_opacity = 0.18,
  filter_expr = NULL,
  value_prefix = "",
  value_suffix = "",
  connect_group = NULL,
  backend = "echarts4r"
)
```

## Arguments

- data:

  Data frame (page data)

- x_var:

  X variable name

- y_var:

  Y variable name (NULL for count/cumcount)

- value:

  Main value to display (auto-computed if NULL)

- subtitle:

  Subtitle text

- agg:

  Aggregation: "count", "cumcount", "sum", "cumsum", "mean"

- line_color:

  Line color

- bg_color:

  Background color

- text_color:

  Text color

- height:

  Sparkline height in pixels

- smooth:

  Smoothing factor

- area_opacity:

  Area fill opacity

- filter_expr:

  Optional filter expression string

- value_prefix:

  Prefix for displayed value

- value_suffix:

  Suffix for displayed value

- backend:

  Chart backend
