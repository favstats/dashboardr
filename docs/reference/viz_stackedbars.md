# Stacked Bar Charts for Multiple Variables (Legacy)

soft-deprecated

This function has been superseded by
[`viz_stackedbar`](https://favstats.github.io/dashboardr/reference/viz_stackedbar.md),
which now supports both single-variable crosstabs and multi-variable
comparisons through a unified interface.

**Migration:** Replace `viz_stackedbars(data, x_vars = ...)` with
`viz_stackedbar(data, x_vars = ...)`. All parameters work the same way.

## Usage

``` r
viz_stackedbars(
  data,
  x_vars,
  x_var_labels = NULL,
  response_levels = NULL,
  title = NULL,
  subtitle = NULL,
  x_label = NULL,
  y_label = NULL,
  stack_label = NULL,
  stacked_type = c("normal", "percent", "counts"),
  tooltip = NULL,
  tooltip_prefix = "",
  tooltip_suffix = "",
  x_tooltip_suffix = "",
  color_palette = NULL,
  stack_order = NULL,
  x_order = NULL,
  include_na = FALSE,
  na_label_x = "(Missing)",
  na_label_stack = "(Missing)",
  x_breaks = NULL,
  x_bin_labels = NULL,
  x_map_values = NULL,
  stack_breaks = NULL,
  stack_bin_labels = NULL,
  stack_map_values = NULL,
  show_var_tooltip = TRUE,
  horizontal = FALSE,
  weight_var = NULL,
  data_labels_enabled = TRUE
)
```

## Arguments

- data:

  A data frame containing the survey data.

- x_vars:

  Character vector of column names to pivot (the variables to compare).

- x_var_labels:

  Optional character vector of display labels for the variables. Must be
  the same length as `x_vars`. If `NULL`, column names are used as
  labels.

- response_levels:

  Optional character vector of factor levels for the response categories
  (e.g. `c("Strongly Disagree", ..., "Strongly Agree")`).

- title:

  Optional string. Main chart title.

- subtitle:

  Optional string. Chart subtitle.

- x_label:

  Optional string. X-axis label. Defaults to empty in crosstab mode or
  "Variable" in multi-variable mode.

- y_label:

  Optional string. Y-axis label. Defaults to "Count" or "Percentage".

- stack_label:

  Optional string. Title for the stack legend. Set to NULL, NA, FALSE,
  or "" to hide the legend title.

- stacked_type:

  One of "normal", "counts" (both show raw counts), or "percent" (100%
  stacked). Defaults to "counts".

- tooltip:

  A tooltip configuration created with
  [`tooltip()`](https://favstats.github.io/dashboardr/reference/tooltip.md),
  OR a format string with {placeholders}. Available placeholders:
  `{category}`, `{value}`, `{series}`, `{percent}`.

- tooltip_prefix:

  Optional string prepended to tooltip values.

- tooltip_suffix:

  Optional string appended to tooltip values.

- x_tooltip_suffix:

  Optional string appended to x-axis values in tooltips.

- color_palette:

  Optional character vector of colors for the stacks.

- stack_order:

  Optional character vector specifying order of stack levels.

- x_order:

  Optional character vector specifying order of x-axis levels.

- include_na:

  Logical. If TRUE, NA values are shown as explicit categories. If FALSE
  (default), rows with NA are excluded.

- na_label_x:

  String. Label for NA values on x-axis. Default "(Missing)".

- na_label_stack:

  String. Label for NA values in stacks. Default "(Missing)".

- x_breaks:

  Optional numeric vector of cut points for binning `x_var`.

- x_bin_labels:

  Optional character vector of labels for `x_breaks` bins.

- x_map_values:

  Optional named list to remap x-axis values for display.

- stack_breaks:

  Optional numeric vector of cut points for binning stack variable.

- stack_bin_labels:

  Optional character vector of labels for `stack_breaks` bins.

- stack_map_values:

  Optional named list to remap stack values for display.

- show_var_tooltip:

  Logical. If `TRUE`, shows custom tooltip with variable labels.

- horizontal:

  Logical. If TRUE, creates horizontal bars. Default FALSE.

- weight_var:

  Optional string. Name of a weight variable for weighted counts.

- data_labels_enabled:

  Logical. If TRUE, show value labels on bars. Default TRUE.

## Value

A `highcharter` stacked bar chart object.

## See also

[`viz_stackedbar`](https://favstats.github.io/dashboardr/reference/viz_stackedbar.md)
for the unified function

## Examples

``` r
# The old way (still works):
# viz_stackedbars(data, x_vars = c("q1", "q2", "q3"))

# The new preferred way:
# viz_stackedbar(data, x_vars = c("q1", "q2", "q3"))
```
