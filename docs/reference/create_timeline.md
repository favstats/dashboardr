# Create a Timeline Chart

Creates interactive timeline visualizations showing changes in survey
responses over time. Supports multiple chart types including stacked
areas, line charts, and diverging bar charts.

## Usage

``` r
create_timeline(
  data,
  time_var,
  response_var,
  group_var = NULL,
  chart_type = "stacked_area",
  title = NULL,
  y_max = NULL,
  response_levels = NULL,
  response_breaks = NULL,
  response_bin_labels = NULL,
  response_filter = NULL,
  response_filter_combine = TRUE,
  response_filter_label = NULL,
  time_breaks = NULL,
  time_bin_labels = NULL,
  weight_var = NULL
)
```

## Arguments

- data:

  A data frame containing survey data with time and response variables.

- time_var:

  Character string. Name of the time variable (e.g., "year", "wave").

- response_var:

  Character string. Name of the response variable containing Likert
  responses.

- group_var:

  Optional character string. Name of grouping variable for separate
  series (e.g., "gender", "education"). Creates separate lines/areas for
  each group.

- chart_type:

  Character string. Type of chart: "stacked_area" or "line".

- title:

  Optional main title for the chart.

- y_max:

  Optional numeric value. Maximum value for the Y-axis.

- response_levels:

  Optional character vector specifying order of response categories.

- response_breaks:

  Optional numeric vector for binning numeric response values (e.g.,
  `c(0, 2.5, 5, 7)` to create bins 0-2.5, 2.5-5, 5-7).

- response_bin_labels:

  Optional character vector of labels for response bins (e.g.,
  `c("Low (1-2)", "Medium (3-5)", "High (6-7)")`).

- response_filter:

  Optional numeric or character vector specifying which response values
  to include. For numeric responses, use a range like `5:7` to show only
  values 5, 6, and 7. For categorical responses, use category names like
  `c("Agree", "Strongly Agree")`. Applied BEFORE binning (filters raw
  values first, then bins the filtered data).

- response_filter_combine:

  Logical. When `response_filter` is used, should filtered values be
  combined into a single percentage? Defaults to `TRUE` (show combined %
  of all filtered values). Set to `FALSE` to show separate lines for
  each filtered value.

- response_filter_label:

  Character string. Custom label for the filtered responses in the
  legend. Only used when `response_filter` and
  `response_filter_combine = TRUE`. If `NULL` (default) and `group_var`
  is provided, shows only group names in legend (e.g., "AgeGroup1"). If
  `NULL` and no `group_var`, uses auto-generated label (e.g., "5-7" for
  `response_filter = 5:7`).

- time_breaks:

  Optional numeric vector for binning continuous time variables.

- time_bin_labels:

  Optional character vector of labels for time bins.

## Value

A highcharter plot object.

## Examples

``` r
# Load GSS data
data(gss_all)
#> Warning: data set ‘gss_all’ not found

# Basic timeline - confidence in institutions over time
plot1 <- create_timeline(
           data = gss_all,
           time_var = "year",
           response_var = "confinan",
           title = "Confidence in Financial Institutions Over Time",
           y_max = 100
           )
#> Error: object 'gss_all' not found
plot1
#> Error: object 'plot1' not found

# Line chart by gender
plot2 <- create_timeline(
   data = gss_all,
   time_var = "year",
   response_var = "happy",
   group_var = "sex",
   chart_type = "line",
   title = "Happiness Trends by Gender",
   response_levels = c("very happy", "pretty happy", "not too happy")
)
#> Error: object 'gss_all' not found
plot2
#> Error: object 'plot2' not found

# Show only high responses (5-7 on a 1-7 scale) - COMBINED
plot3 <- create_timeline(
   data = survey_data,
   time_var = "wave",
   response_var = "agreement",  # 1-7 scale
   group_var = "age_group",
   chart_type = "line",
   response_filter = 5:7,  # Show combined % who responded 5-7
   title = "% High Agreement (5-7) Over Time"
)
#> Error: object 'survey_data' not found
plot3
#> Error: object 'plot3' not found

# Custom legend label
plot4 <- create_timeline(
   data = survey_data,
   time_var = "wave",
   response_var = "agreement",
   group_var = "age_group",
   chart_type = "line",
   response_filter = 5:7,
   response_filter_label = "High Agreement",  # Custom label instead of "5-7"
   title = "High Agreement Trends"
)
#> Error: object 'survey_data' not found
plot4
#> Error: object 'plot4' not found

# Show individual filtered values (not combined)
plot5 <- create_timeline(
   data = survey_data,
   time_var = "wave",
   response_var = "agreement",
   chart_type = "line",
   response_filter = 5:7,
   response_filter_combine = FALSE,  # Show separate lines for 5, 6, 7
   title = "Individual High Responses"
)
#> Error: object 'survey_data' not found
plot5
#> Error: object 'plot5' not found
```
