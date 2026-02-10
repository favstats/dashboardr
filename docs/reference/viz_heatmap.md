# Create a Heatmap

This function creates a heatmap for bivariate data, visualizing the
relationship between two categorical variables and a numeric value using
color intensity. It handles ordered factors, ensures all combinations
are plotted, and allows for extensive customization. It also includes
robust handling of missing values (NA) by allowing them to be displayed
as explicit categories.

## Usage

``` r
viz_heatmap(
  data,
  x_var,
  y_var,
  value_var,
  title = NULL,
  subtitle = NULL,
  x_label = NULL,
  y_label = NULL,
  value_label = NULL,
  tooltip = NULL,
  tooltip_prefix = "",
  tooltip_suffix = "",
  x_tooltip_suffix = "",
  y_tooltip_suffix = "",
  x_tooltip_prefix = "",
  y_tooltip_prefix = "",
  x_order = NULL,
  y_order = NULL,
  x_order_by = NULL,
  y_order_by = NULL,
  color_min = NULL,
  color_max = NULL,
  color_palette = c("#FFFFFF", "#7CB5EC"),
  na_color = "transparent",
  data_labels_enabled = TRUE,
  label_decimals = 1,
  tooltip_labels_format = NULL,
  include_na = FALSE,
  na_label_x = "(Missing)",
  na_label_y = "(Missing)",
  x_map_values = NULL,
  y_map_values = NULL,
  agg_fun = mean,
  weight_var = NULL,
  pre_aggregated = FALSE,
  legend_position = NULL,
  backend = "highcharter"
)
```

## Arguments

- data:

  A data frame containing the variables to plot.

- x_var:

  String. Name of the column for the X-axis categories.

- y_var:

  String. Name of the column for the Y-axis categories.

- value_var:

  String. Name of the numeric column whose values will determine the
  color intensity.

- title:

  Optional string. Main chart title.

- subtitle:

  Optional string. Chart subtitle.

- x_label:

  Optional string. X-axis label. Defaults to `x_var`.

- y_label:

  Optional string. Y-axis label. Defaults to `y_var`.

- value_label:

  Optional string. Label for the color axis. Defaults to `value_var`.

- tooltip:

  A tooltip configuration created with
  [`tooltip()`](https://favstats.github.io/dashboardr/reference/tooltip.md),
  OR a format string with {placeholders}. Available placeholders: `{x}`,
  `{y}`, `{value}`, `{name}`. See
  [`tooltip`](https://favstats.github.io/dashboardr/reference/tooltip.md)
  for full customization options.

- tooltip_prefix:

  Optional string prepended in the tooltip value (simple customization).

- tooltip_suffix:

  Optional string appended in the tooltip value (simple customization).

- x_tooltip_suffix:

  Optional string appended to x value in tooltip.

- y_tooltip_suffix:

  Optional string appended to y value in tooltip.

- x_tooltip_prefix:

  Optional string prepended to x value in tooltip.

- y_tooltip_prefix:

  Optional string prepended to y value in tooltip.

- x_order:

  Optional character vector to order the factor levels of `x_var`.
  Alternatively, use `x_order_by` to order by aggregated values.

- y_order:

  Optional character vector to order the factor levels of `y_var`.
  Alternatively, use `y_order_by` to order by aggregated values.

- x_order_by:

  Optional. Order x-axis categories by aggregated value. Can be "asc"
  (ascending), "desc" (descending), or NULL (default, no reordering).
  When set, categories are sorted by their mean value across all y
  categories.

- y_order_by:

  Optional. Order y-axis categories by aggregated value. Can be "asc"
  (ascending), "desc" (descending), or NULL (default, no reordering).
  When set, categories are sorted by their mean value across all x
  categories.

- color_min:

  Optional numeric. Minimum value for the color axis. If NULL, defaults
  to data min.

- color_max:

  Optional numeric. Maximum value for the color axis. If NULL, defaults
  to data max.

- color_palette:

  Optional character vector of colors for the color gradient. Example:
  `c("#FFFFFF", "#7CB5EC")` for white to light blue. Can also be a
  single color for gradient start.

- na_color:

  Optional string. Color for NA values in `value_var` cells. Default
  "transparent".

- data_labels_enabled:

  Logical. If TRUE, display data labels on each cell. Default TRUE.

- label_decimals:

  Integer. Number of decimal places for data labels and tooltips.
  Default is 1. Set to 0 for whole numbers, 2 for two decimal places,
  etc. Ignored if `tooltip_labels_format` is explicitly provided.

- tooltip_labels_format:

  Optional string. Format for data labels. Default NULL (auto-generated
  from `label_decimals`). If provided, overrides `label_decimals`.

- include_na:

  Logical. If TRUE, treats NA values in `x_var` or `y_var` as explicit
  categories using `na_label_x` and `na_label_y`. If FALSE (default),
  rows with NA in `x_var` or `y_var` are excluded from aggregation.

- na_label_x:

  Optional string. Custom label for NA values in `x_var`. Defaults to
  "(Missing)".

- na_label_y:

  Optional string. Custom label for NA values in `y_var`. Defaults to
  "(Missing)".

- x_map_values:

  Optional named list to recode x_var values for display.

- y_map_values:

  Optional named list to recode y_var values for display.

- agg_fun:

  Function to aggregate duplicate x/y combinations. Default is `mean`.
  Note: If `weight_var` is provided, weighted mean is used instead and
  this parameter is ignored.

- weight_var:

  Optional string. Name of a weight variable to use for weighted mean
  aggregation. When provided, the function uses
  [`weighted.mean()`](https://rdrr.io/r/stats/weighted.mean.html)
  instead of the `agg_fun` parameter.

- pre_aggregated:

  Logical. If TRUE, skips aggregation and uses `value_var` directly. Use
  this when your data is already aggregated (one row per x/y
  combination). Default is FALSE.

- legend_position:

  Position of the legend ("top", "bottom", "left", "right", "none")

- backend:

  Rendering backend: "highcharter" (default), "plotly", "echarts4r", or
  "ggiraph".

## Value

A `highcharter` heatmap object.

## Details

This function performs the following steps:

1.  **Input validation:** Checks `data`, `x_var`, `y_var`, and
    `value_var`.

2.  **Data Preparation:**

    - Handles `haven_labelled` columns by converting them to factors.

    - Applies value mapping if `x_map_values` or `y_map_values` (new
      parameter) are provided.

    - Processes NA values in `x_var` and `y_var`: if
      `include_na = TRUE`, NAs are converted to a specified label;
      otherwise, rows with NAs in these variables are filtered out.

    - Converts `x_var` and `y_var` to factors and applies `x_order` and
      `y_order`.

    - If `weight_var` is provided, uses
      [`weighted.mean()`](https://rdrr.io/r/stats/weighted.mean.html)
      for aggregation; otherwise uses `agg_fun` (default
      [`mean()`](https://rdrr.io/r/base/mean.html)).

    - Uses
      [`tidyr::complete`](https://tidyr.tidyverse.org/reference/complete.html)
      to ensure all `x_var`/`y_var` combinations are present, filling
      missing `value_var` with `NA_real_` (which will appear as
      `na_color` in the heatmap).

3.  **Chart Construction:**

    - Initializes a `highchart` object.

    - Configures `title`, `subtitle`, axis labels.

    - Sets up `hc_colorAxis` based on `color_min`, `color_max`, and
      `color_palette`.

    - Adds the heatmap series using `hc_add_series`, mapping `x_var`,
      `y_var`, and `value_var`.

    - Customizes `plotOptions` for heatmap, including data labels and
      `nullColor`.

4.  **Tooltip Customization:** Defines a JavaScript `tooltip.formatter`
    for detailed hover information.

## Examples

``` r
if (FALSE) { # \dontrun{
# Load the dataset
data(gss_panel20)

# Example 1: Basic heatmap - no mapped values or other customization
viz_heatmap(
  data = gss_panel20,
  x_var = "degree_1a",
  y_var = "sex_1a",
  value_var = "age_1a",
  title = "Average Age by Education and Sex",
  x_label = "Education Level",
  y_label = "Sex",
  value_label = "Mean Age"
)


# Example 2: Heatmap With Custom Variable Mapping and Colors

region_map <- list("1" = "New England",
"2" = "Mid-Atlantic",
"3" = "East North Central",
"4" = "West North Central",
"5" = "South Atlantic",
"6" = "Deep South",
"7" = "West South Central",
"8" = "Mountain",
"9" = "West Coast"
)
sex_map <- list("1" = "Male",
               "2" = "Female")

viz_heatmap(
  data = gss_panel20,
  x_var = "region_1a",
  y_var = "sex_1a",
  value_var = "satfin_1a",
  x_map_values = region_map,
  y_map_values = sex_map,
  value_label = "Satisfaction",
  x_label = "U.S. Region",
  y_label = "Gender",
  title = "Satisfaction with Financial Situation",
  subtitle = "Per U.S. Region and Gender",
  color_palette = c("#f7fbff", "darkgreen"),
  color_min = 1,
  color_max = 3
)


# Example 3: Handling missing categories explicitly

edu_map = list("0" = "less than high school",
"1" =  "high school",
"2" = "associate/junior college",
"3" = "bachelor's",
"4" = "graduate")

viz_heatmap(
data = gss_panel20,
x_var = "region_1a",
y_var = "degree_1a",
value_var = "income_1a",
x_map_values = region_map,
y_map_values = edu_map,
color_min = 8,
color_max = 12,
value_label = "Income",
x_label = "U.S. Region",
y_label = "Education",
include_na = TRUE,
na_label_x = "Region Missing",
na_label_y = "Degree Missing",
na_color = "grey",
title = "Average Income by Region and Education (Including Missing)"
)


# Example 4: Custom order of education levels and relabeling of sex
viz_heatmap(
data = gss_panel20,
x_var = "degree_1a",
y_var = "sex_1a",
value_var = "income_1a",
x_map_values = edu_map,
x_order = c("less than high school", "high school", "associate/junior college",
"bachelor's", "graduate"),
y_map_values = sex_map,
y_label = "Gender",
x_label = "Education Level",
value_label = "Income Level",
title = "Average Income by Education Level and Sex",
subtitle = "Custom order and relabeled categories",
color_palette = c("#ffffe0", "#31a354")
)
} # }
```
