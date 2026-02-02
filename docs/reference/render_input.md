# Render an input widget

Creates HTML for various input widgets that filter Highcharts
visualizations.

## Usage

``` r
render_input(
  input_id,
  label = NULL,
  type = c("select_multiple", "select_single", "checkbox", "radio", "switch", "slider",
    "text", "number", "button_group"),
  filter_var,
  options = NULL,
  options_from = NULL,
  default_selected = NULL,
  placeholder = "Select...",
  width = "300px",
  align = c("center", "left", "right"),
  min = 0,
  max = 100,
  step = 1,
  value = NULL,
  show_value = TRUE,
  inline = TRUE,
  stacked = FALSE,
  stacked_align = c("center", "left", "right"),
  group_align = c("left", "center", "right"),
  ncol = NULL,
  nrow = NULL,
  columns = NULL,
  toggle_series = NULL,
  override = FALSE,
  labels = NULL,
  size = c("md", "sm", "lg"),
  help = NULL,
  disabled = FALSE
)
```

## Arguments

- input_id:

  Unique ID for this input widget

- label:

  Optional label displayed above the input

- type:

  Input type: "select_multiple", "select_single", "checkbox", "radio",
  "switch", "slider", "text", "number", or "button_group"

- filter_var:

  The variable name to filter by (matches Highcharts series names)

- options:

  Character vector of options to display (for
  select/checkbox/radio/button_group). Can also be a named list for
  grouped options in selects.

- options_from:

  Column name in page data to auto-populate options from

- default_selected:

  Character vector of initially selected values

- placeholder:

  Placeholder text when nothing is selected (for selects/text)

- width:

  CSS width for the input

- align:

  Alignment: "center", "left", or "right"

- min:

  Minimum value (for slider/number)

- max:

  Maximum value (for slider/number)

- step:

  Step increment (for slider/number)

- value:

  Initial value (for slider/switch/text/number)

- show_value:

  Whether to show the current value (for slider)

- inline:

  Whether to display options inline (for checkbox/radio)

- toggle_series:

  For switch type: name of the series to toggle on/off

- override:

  For switch type: if TRUE, switch overrides other filters for this
  series

- labels:

  Custom labels for slider ticks (character vector)

- size:

  Size variant: "sm", "md" (default), or "lg"

- help:

  Help text displayed below the input

- disabled:

  Whether the input is disabled

## Value

HTML output (invisible)
