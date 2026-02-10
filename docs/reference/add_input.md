# Add an interactive input filter

Adds an input widget that filters Highcharts visualizations on the page.
Supports various input types: dropdowns, checkboxes, radio buttons,
switches, sliders, text search, number inputs, and button groups.

## Usage

``` r
add_input(
  content,
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
  min = 0,
  max = 100,
  step = 1,
  value = NULL,
  default_value = NULL,
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
  disabled = FALSE,
  add_all = FALSE,
  add_all_label = "All",
  mt = NULL,
  mr = NULL,
  mb = NULL,
  ml = NULL,
  tabgroup = NULL,
  .linked_parent_id = NULL,
  .options_by_parent = NULL
)
```

## Arguments

- content:

  Content collection object or input_row_container

- input_id:

  Unique ID for this input widget

- label:

  Optional label displayed above the input

- type:

  Input type: "select_multiple" (default), "select_single", "checkbox",
  "radio", "switch", "slider", "text", "number", or "button_group"

- filter_var:

  The variable name to filter by (matches Highcharts series names). This
  should match the `group_var` used in your visualization.

- options:

  Character vector of options to display. If NULL, uses `options_from`.
  Required for select, checkbox, radio, and button_group types. Can also
  be a named list for grouped options in selects (e.g.,
  `list("Europe" = c("Germany", "France"), "Asia" = c("China", "Japan"))`).

- options_from:

  Column name in page data to auto-populate options from. Only used if
  `options` is NULL.

- default_selected:

  Character vector of initially selected values. If NULL, all options
  are selected by default (for select/checkbox) or first option (for
  radio/button_group).

- placeholder:

  Placeholder text when nothing is selected (for selects/text)

- width:

  CSS width for the input (default: "300px")

- min:

  Minimum value (for slider/number types)

- max:

  Maximum value (for slider/number types)

- step:

  Step increment (for slider/number types)

- value:

  Initial value (for slider/switch/text/number types)

- default_value:

  Default value for the input (alias for value, used for reset)

- show_value:

  Whether to show current value (for slider, default TRUE)

- inline:

  Whether to display options inline (for checkbox/radio, default TRUE)

- stacked:

  Whether to stack options vertically (for checkbox/radio). Default
  FALSE.

- stacked_align:

  Alignment when stacked: "center" (default), "left", or "right"

- group_align:

  Alignment for option groups: "left" (default), "center", or "right"

- ncol:

  Number of columns for grid layout of options

- nrow:

  Number of rows for grid layout of options

- columns:

  Column configuration for grid layout

- toggle_series:

  For switch type: name of the series to toggle visibility on/off

- override:

  For switch type: if TRUE, the switch overrides other filters for this
  series

- labels:

  Custom labels for slider ticks (character vector). The first and last
  labels are shown at the min/max positions.

- size:

  Size variant: "sm" (small), "md" (medium, default), or "lg" (large)

- help:

  Help text displayed below the input

- disabled:

  Whether the input is disabled (default FALSE)

- add_all:

  Whether to add an "All" option (default FALSE)

- add_all_label:

  Label for the "All" option (default "All")

- mt:

  Margin top (CSS value, e.g., "10px")

- mr:

  Margin right (CSS value)

- mb:

  Margin bottom (CSS value)

- ml:

  Margin left (CSS value)

- tabgroup:

  Optional tabgroup for organizing content

- .linked_parent_id:

  Internal. ID of linked parent input for cascading inputs

- .options_by_parent:

  Internal. Named list mapping parent values to child options

## Value

Updated content_collection or input_row_container

## Examples

``` r
if (FALSE) { # \dontrun{
# Dropdown (multi-select)
content <- create_content() %>%
  add_input(
    input_id = "country_filter",
    label = "Select Countries:",
    type = "select_multiple",
    filter_var = "country",
    options_from = "country",
    help = "Select one or more countries to compare"
  )

# Grouped select options
content <- create_content() %>%
  add_input(
    input_id = "country_filter",
    label = "Select Countries:",
    type = "select_multiple",
    filter_var = "country",
    options = list(
      "Europe" = c("Germany", "France", "UK"),
      "Asia" = c("China", "Japan", "India")
    )
  )

# Checkbox group
content <- create_content() %>%
  add_input(
    input_id = "metrics",
    label = "Metrics:",
    type = "checkbox",
    filter_var = "metric",
    options = c("Revenue", "Users", "Growth"),
    inline = TRUE
  )

# Radio buttons
content <- create_content() %>%
  add_input(
    input_id = "chart_type",
    label = "Chart Type:",
    type = "radio",
    filter_var = "chart_type",
    options = c("Line", "Bar", "Area")
  )

# Switch/toggle to show/hide a specific series
content <- create_content() %>%
  add_input(
    input_id = "show_average",
    label = "Show Global Average",
    type = "switch",
    filter_var = "country",
    toggle_series = "Global Average",  # Name of the series to toggle
    override = TRUE,                   # Don't let other filters hide this series
    value = TRUE                       # Start with switch ON
  )

# Slider with custom labels
content <- create_content() %>%
  add_input(
    input_id = "decade_filter",
    label = "Decade:",
    type = "slider",
    filter_var = "decade",
    min = 1,
    max = 6,
    step = 1,
    value = 1,
    labels = c("1970s", "1980s", "1990s", "2000s", "2010s", "2020s")
  )

# Text search input
content <- create_content() %>%
  add_input(
    input_id = "search",
    label = "Search:",
    type = "text",
    filter_var = "name",
    placeholder = "Type to search...",
    size = "lg"
  )

# Button group (segmented control)
content <- create_content() %>%
  add_input(
    input_id = "period",
    label = "Time Period:",
    type = "button_group",
    filter_var = "period",
    options = c("Day", "Week", "Month", "Year")
  )
} # }
```
