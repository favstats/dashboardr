# Create Bar Chart

Creates horizontal or vertical bar charts showing counts or percentages.
Supports simple bars or grouped bars (when `group_var` is provided).

## Usage

``` r
create_bar(
  data,
  x_var,
  group_var = NULL,
  title = NULL,
  subtitle = NULL,
  x_label = NULL,
  y_label = NULL,
  horizontal = TRUE,
  bar_type = "percent",
  color_palette = NULL,
  group_order = NULL,
  x_order = NULL,
  sort_by_value = FALSE,
  sort_desc = TRUE,
  x_breaks = NULL,
  x_bin_labels = NULL,
  include_na = FALSE,
  na_label = "Missing",
  weight_var = NULL,
  tooltip_prefix = "",
  tooltip_suffix = "",
  x_tooltip_suffix = ""
)
```

## Arguments

- data:

  A data frame containing the survey data.

- x_var:

  Character string. Name of the categorical variable for the x-axis.

- group_var:

  Optional character string. Name of grouping variable to create
  separate bars (e.g., score ranges, categories). Creates
  grouped/clustered bars.

- title:

  Optional main title for the chart.

- subtitle:

  Optional subtitle for the chart.

- x_label:

  Optional label for the x-axis. Defaults to `x_var` name.

- y_label:

  Optional label for the y-axis.

- horizontal:

  Logical. If `TRUE`, creates horizontal bars. Defaults to `TRUE`.

- bar_type:

  Character string. Type of bar chart: "count" or "percent". Defaults to
  "percent".

- color_palette:

  Optional character vector of colors for the bars.

- group_order:

  Optional character vector specifying the order of groups (for
  `group_var`).

- x_order:

  Optional character vector specifying the order of x categories.

- sort_by_value:

  Logical. If `TRUE`, sort categories by their value (highest on top for
  horizontal bars).

- sort_desc:

  Logical. If `sort_by_value = TRUE`, sort descending (default) or
  ascending.

- x_breaks:

  Optional numeric vector for binning continuous x variables.

- x_bin_labels:

  Optional character vector of labels for x bins.

- include_na:

  Logical. Whether to include NA values as a separate category. Defaults
  to `FALSE`.

- na_label:

  Character string. Label for NA category if `include_na = TRUE`.
  Defaults to "Missing".

- weight_var:

  Optional character string. Name of a weight variable to use for
  weighted aggregation. When provided, counts are computed as the sum of
  weights instead of simple counts.

- tooltip_prefix:

  Optional string prepended to tooltip values.

- tooltip_suffix:

  Optional string appended to tooltip values.

- x_tooltip_suffix:

  Optional string appended to x-axis values in tooltips.

## Value

A highcharter plot object.

## Examples

``` r
# Simple bar chart showing distribution
plot1 <- create_bar(
  data = survey_data,
  x_var = "category",
  horizontal = TRUE,
  bar_type = "percent"
)
#> Error: object 'survey_data' not found
plot1
#> Error: object 'plot1' not found

# Grouped bars - like the user's image!
plot2 <- create_bar(
  data = survey_data,
  x_var = "question",           # "Knowledge Score"
  group_var = "score_range",    # "Low (1-9)", "Middle (10-19)", "High (20-29)"
  horizontal = TRUE,
  bar_type = "percent",
  color_palette = c("#D2691E", "#4682B4", "#228B22"),
  group_order = c("Low (1-9)", "Middle (10-19)", "High (20-29)")
)
#> Error: object 'survey_data' not found
plot2
#> Error: object 'plot2' not found
```
