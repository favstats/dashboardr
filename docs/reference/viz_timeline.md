# Create a Timeline Chart

Creates interactive timeline visualizations showing changes in survey
responses over time, or simple line charts for pre-aggregated time
series data. Supports multiple chart types including stacked areas, line
charts, and diverging bar charts.

## Usage

``` r
viz_timeline(
  data,
  time_var,
  y_var,
  group_var = NULL,
  agg = c("percentage", "mean", "sum", "none"),
  chart_type = "line",
  title = NULL,
  subtitle = NULL,
  x_label = NULL,
  y_label = NULL,
  y_max = NULL,
  y_min = NULL,
  color_palette = NULL,
  y_levels = NULL,
  y_breaks = NULL,
  y_bin_labels = NULL,
  y_map_values = NULL,
  y_filter = NULL,
  y_filter_combine = TRUE,
  y_filter_label = NULL,
  time_breaks = NULL,
  time_bin_labels = NULL,
  weight_var = NULL,
  include_na = FALSE,
  na_label_y = "(Missing)",
  na_label_group = "(Missing)",
  tooltip = NULL,
  tooltip_prefix = "",
  tooltip_suffix = "",
  group_order = NULL,
  cross_tab_filter_vars = NULL,
  title_map = NULL,
  legend_position = NULL,
  backend = "highcharter"
)
```

## Arguments

- data:

  A data frame containing time series data.

- time_var:

  Character string. Name of the time variable (e.g., "year", "wave").

- y_var:

  Character string. Name of the response/value variable.

- group_var:

  Optional character string. Name of grouping variable for separate
  series (e.g., "country", "gender"). Creates separate lines/areas for
  each group.

- agg:

  Character string specifying aggregation method:

  - `"percentage"` (default): Count responses and calculate percentages
    per time period. Use for survey data with categorical responses.

  - `"mean"`: Calculate mean of y_var per time period (and group if
    specified).

  - `"sum"`: Calculate sum of y_var per time period (and group if
    specified).

  - `"none"`: Use values directly without aggregation. Use for
    pre-aggregated data where each row represents one observation per
    time/group combination.

- chart_type:

  Character string. Type of chart: "line" (default) or "stacked_area".

- title:

  Optional main title for the chart.

- subtitle:

  Optional subtitle for the chart.

- x_label:

  Optional character string. Label for the x-axis. Defaults to time_var
  name.

- y_label:

  Optional character string. Label for the y-axis. Defaults to
  "Percentage" for `agg = "percentage"`, or y_var name for other modes.

- y_max:

  Optional numeric value. Maximum value for the Y-axis.

- y_min:

  Optional numeric value. Minimum value for the Y-axis.

- color_palette:

  Optional character vector of color hex codes for the series.

- y_levels:

  Optional character vector specifying order of response categories.

- y_breaks:

  Optional numeric vector for binning numeric response values (e.g.,
  `c(0, 2.5, 5, 7)` to create bins 0-2.5, 2.5-5, 5-7).

- y_bin_labels:

  Optional character vector of labels for response bins (e.g.,
  `c("Low (1-2)", "Medium (3-5)", "High (6-7)")`).

- y_map_values:

  Optional named list to rename response values for display (e.g.,
  `list("1" = "Correct", "0" = "Incorrect")`). Applied to legend labels
  and data.

- y_filter:

  Optional numeric or character vector specifying which response values
  to include. For numeric responses, use a range like `5:7` to show only
  values 5, 6, and 7. For categorical responses, use category names like
  `c("Agree", "Strongly Agree")`. Applied BEFORE binning (filters raw
  values first, then bins the filtered data).

- y_filter_combine:

  Logical. When `y_filter` is used, should filtered values be combined
  into a single percentage? Defaults to `TRUE` (show combined % of all
  filtered values). Set to `FALSE` to show separate lines for each
  filtered value.

- y_filter_label:

  Character string. Custom label for the filtered responses in the
  legend. Only used when `y_filter` and `y_filter_combine = TRUE`. If
  `NULL` (default) and `group_var` is provided, shows only group names
  in legend (e.g., "AgeGroup1"). If `NULL` and no `group_var`, uses
  auto-generated label (e.g., "5-7" for `y_filter = 5:7`).

- time_breaks:

  Optional numeric vector for binning continuous time variables.

- time_bin_labels:

  Optional character vector of labels for time bins.

- weight_var:

  Optional string. Name of a weight variable for weighted calculations.

- include_na:

  Logical. If TRUE, NA values are included as explicit categories.
  Default FALSE.

- na_label_y:

  Character string. Label for NA values in the response variable.
  Default "(Missing)".

- na_label_group:

  Character string. Label for NA values in the group variable. Default
  "(Missing)".

- tooltip:

  A tooltip configuration created with
  [`tooltip()`](https://favstats.github.io/dashboardr/reference/tooltip.md),
  OR a format string with {placeholders}. Available placeholders: `{x}`,
  `{y}`, `{value}`, `{series}`, `{percent}`. See
  [`tooltip`](https://favstats.github.io/dashboardr/reference/tooltip.md)
  for full customization options.

- tooltip_prefix:

  Optional string prepended to values in tooltip.

- tooltip_suffix:

  Optional string appended to values in tooltip.

- group_order:

  Optional character vector specifying display order of group levels.

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

A highcharter plot object.

## Examples

``` r
if (FALSE) { # \dontrun{
# Load GSS data
data(gss_all)

# Basic timeline - confidence in institutions over time
plot1 <- viz_timeline(
  data = gss_all,
  time_var = "year",
  y_var = "confinan",
  title = "Confidence in Financial Institutions Over Time",
  y_max = 100
)
plot1

# Line chart by gender
plot2 <- viz_timeline(
  data = gss_all,
  time_var = "year",
  y_var = "happy",
  group_var = "sex",
  chart_type = "line",
  title = "Happiness Trends by Gender",
  y_levels = c("very happy", "pretty happy", "not too happy")
)
plot2

# Show only high responses (5-7 on a 1-7 scale) - COMBINED
plot3 <- viz_timeline(
  data = survey_data,
  time_var = "wave",
  y_var = "agreement",
  group_var = "age_group",
  chart_type = "line",
  y_filter = 5:7,
  title = "% High Agreement (5-7) Over Time"
)
plot3
} # }
```
