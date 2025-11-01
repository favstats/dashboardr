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
  time_breaks = NULL,
  time_bin_labels = NULL
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
plot1 <- create_timeline_(
           data = gss_all,
           time_var = "year",
           response_var = "confinan",
           title = "Confidence in Financial Institutions Over Time",
           y_max = 100
           )
#> Error in create_timeline_(data = gss_all, time_var = "year", response_var = "confinan",     title = "Confidence in Financial Institutions Over Time",     y_max = 100): could not find function "create_timeline_"
plot1
#> Error: object 'plot1' not found

# Line chart by gender
plot2 <- create_timeline_fixed(
   data = gss_all,
   time_var = "year",
   response_var = "happy",
   group_var = "sex",
   chart_type = "line",
   title = "Happiness Trends by Gender",
   response_levels = c("very happy", "pretty happy", "not too happy")
)
#> Error in create_timeline_fixed(data = gss_all, time_var = "year", response_var = "happy",     group_var = "sex", chart_type = "line", title = "Happiness Trends by Gender",     response_levels = c("very happy", "pretty happy", "not too happy")): could not find function "create_timeline_fixed"
plot2
#> Error: object 'plot2' not found
```
