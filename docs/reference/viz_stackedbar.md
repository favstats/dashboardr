# Create a Stacked Bar Chart

A unified function for creating stacked bar charts that supports two
modes:

**Mode 1: Grouped/Crosstab Mode** (use `x_var` + `stack_var`)

Creates a stacked bar chart from long/tidy data where one column
provides the x-axis categories and another column provides the stack
segments. This is ideal for cross-tabulating responses by demographic
groups.

**Mode 2: Multi-Variable/Battery Mode** (use `x_vars`)

Creates a stacked bar chart from wide data where multiple columns become
the x-axis bars, and their values become the stacks. This is ideal for
comparing response distributions across multiple survey questions.

The function automatically detects which mode to use based on the
parameters provided.

## Usage

``` r
viz_stackedbar(
  data,
  x_var = NULL,
  y_var = NULL,
  stack_var = NULL,
  x_vars = NULL,
  x_var_labels = NULL,
  response_levels = NULL,
  show_var_tooltip = TRUE,
  title = NULL,
  subtitle = NULL,
  x_label = NULL,
  y_label = NULL,
  stack_label = NULL,
  stacked_type = c("counts", "percent", "normal"),
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
  horizontal = FALSE,
  weight_var = NULL,
  data_labels_enabled = TRUE,
  label_decimals = NULL,
  cross_tab_filter_vars = NULL,
  title_map = NULL,
  legend_position = NULL,
  backend = "highcharter"
)
```

## Arguments

- data:

  A data frame containing the survey data.

- x_var:

  String. Name of the column for X-axis categories (Mode 1:
  Grouped/Crosstab). Use this together with `stack_var` for
  crosstab-style charts.

- y_var:

  Optional string. Name of a pre-computed count column. If NULL
  (default), the function counts occurrences.

- stack_var:

  String. Name of the column whose values define the stacks. Required
  when using `x_var`.

- x_vars:

  Character vector of column names to compare (Mode 2:
  Multi-Variable/Battery). Each column becomes a bar on the x-axis, and
  the values within each column become the stacks. Use this for
  comparing multiple survey questions with the same response scale.

- x_var_labels:

  Optional character vector of display labels for the variables. Must be
  the same length as `x_vars`. If NULL, column names are used.

- response_levels:

  Optional character vector of factor levels for the response categories
  (e.g., `c("Strongly Disagree", ..., "Strongly Agree")`). This sets the
  order of the stacks in multi-variable mode.

- show_var_tooltip:

  Logical. If TRUE (default), shows enhanced tooltips with variable
  labels in multi-variable mode.

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

- horizontal:

  Logical. If TRUE, creates horizontal bars. Default FALSE.

- weight_var:

  Optional string. Name of a weight variable for weighted counts.

- data_labels_enabled:

  Logical. If TRUE, show value labels on bars. Default TRUE.

- label_decimals:

  Optional integer. Number of decimal places for data labels. When NULL
  (default), uses smart defaults: 0 for counts, 1 for percent. Set
  explicitly to override (e.g., `label_decimals = 2`).

- cross_tab_filter_vars:

  Character vector. Variables for cross-tab filtering (typically
  auto-detected from sidebar inputs).

- title_map:

  Named list mapping variable names to custom display titles for dynamic
  title updates when filtering by cross-tab variables.

- legend_position:

  Position of the legend ("top", "bottom", "left", "right", "none")

- backend:

  Rendering backend: "highcharter" (default), "plotly", "echarts4r", or
  "ggiraph".

## Value

An interactive `highcharter` bar chart plot object.

## Details

**Choosing the Right Mode:**

Use **Mode 1** (`x_var` + `stack_var`) when you want to:

- Show how one variable breaks down by another (e.g., education by
  gender)

- Create a cross-tabulation visualization

- Your data is already in long/tidy format

Use **Mode 2** (`x_vars`) when you want to:

- Compare response distributions across multiple survey questions

- Visualize a Likert scale battery

- Your questions share the same response categories

- Your data is in wide format (one column per question)

**Data Handling Features:**

- Automatically handles `haven_labelled` columns from SPSS/Stata/SAS

- Supports value mapping to rename categories for display

- Supports binning of continuous variables

- Handles missing values explicitly or implicitly

## See also

[`viz_bar`](https://favstats.github.io/dashboardr/reference/viz_bar.md)
for simple (non-stacked) bar charts

## Examples

``` r
if (FALSE) { # \dontrun{
library(gssr)
data(gss_panel20)

# MODE 1: Grouped/Crosstab - One variable broken down by another

# Example 1: Education by Gender (counts)
plot1 <- viz_stackedbar(
  data = gss_panel20,
  x_var = "degree_1a",
  stack_var = "sex_1a",
  title = "Educational Attainment by Gender",
  x_label = "Highest Degree",
  stack_label = "Gender"
)

# Example 2: Happiness by Education (percentages)
plot2 <- viz_stackedbar(
  data = gss_panel20,
  x_var = "degree_1a",
  stack_var = "happy_1a",
  title = "Happiness by Education Level",
  stacked_type = "percent",
  tooltip_suffix = "%"
)

# MODE 2: Multi-Variable/Battery - Compare multiple questions

# Example 3: Compare multiple attitude questions
plot3 <- viz_stackedbar(
  data = gss_panel20,
  x_vars = c("trust_1a", "fair_1a", "helpful_1a"),
  x_var_labels = c("Trust Others", "Others Are Fair",
    "Others Are Helpful"),
  title = "Social Trust Battery",
  stacked_type = "percent",
  tooltip_suffix = "%"
)

# Example 4: Single question horizontal (compact display)
plot4 <- viz_stackedbar(
  data = gss_panel20,
  x_vars = "happy_1a",
  title = "General Happiness",
  stacked_type = "percent",
  horizontal = TRUE
)
} # }
```
