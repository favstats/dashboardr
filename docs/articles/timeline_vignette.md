# Getting Started With \`create_timeline()\`

## Introduction

The
[`create_timeline()`](https://favstats.github.io/dashboardr/reference/create_timeline.md)
function creates interactive timeline visualizations for survey data,
particularly useful for showing changes in Likert-type responses over
time. Furthermore, the function has been designed to handle SPSS (.sav)
data as well, which makes it very handy for researchers who are
accustomed to working with social science data in this format.

This vignette demonstrates how to use the function with the General
Social Survey (GSS) data. Because we are working with data over time, we
will use the `gss_all` data set. This is a large data set, so it might
take a while to load.

## Setup

First, let’s load the required packages and define the function:

``` r
library(dplyr)
library(highcharter)
library(stringr)
library(haven)
library(dashboardr)
library(gssr)

# Load GSS data
data(gss_all)
```

## Example 1: Basic Stacked Area Chart

Let’s start with a simple stacked area chart showing confidence in
financial institutions over time:

``` r
plot1 <- create_timeline(
  data = gss_all,
  time_var = "year",
  response_var = "confinan",
  chart_type = "stacked_area",
  title = "Confidence in Financial Institutions Over Time",
  y_max = 100
)

plot1
```

This chart shows how public confidence in financial institutions has
changed from the 1970s to recent years, with each colored area
representing a different level of confidence.

## Example 2: Line Chart with Grouping

Now let’s create a line chart showing happiness trends by gender:

``` r
plot2 <- create_timeline(
  data = gss_all,
  time_var = "year",
  response_var = "happy",
  group_var = "sex",
  chart_type = "line",
  title = "Happiness Trends by Gender",
  response_levels = c("very happy", "pretty happy", "not too happy")
)

plot2
```

This line chart displays separate lines for each combination of
happiness level and gender, allowing us to compare trends between men
and women over time.

## Example 3: Time Binning

For data spanning many years, we can bin the time variable into decades:

``` r
plot3 <- create_timeline(
  data = gss_all,
  time_var = "year",
  response_var = "satfin",
  chart_type = "stacked_area",
  title = "Financial Satisfaction by Decade",
  time_breaks = c(1970, 1980, 1990, 2000, 2010, 2020),
  time_bin_labels = c("1970s", "1980s", "1990s", "2000s", "2010s"),
  y_max = 100
)

plot3
```

This approach is useful when you want to show broader trends across time
periods rather than year-by-year changes.

## Example 4: Controlling Response Order

You can control the order of response categories to ensure logical
ordering:

``` r
plot4 <- create_timeline(
  data = gss_all,
  time_var = "year",
  response_var = "health",
  chart_type = "stacked_area",
  title = "Self-Reported Health Over Time",
  response_levels = c("poor", "fair", "good", "excellent"),
  y_max = 100
)

plot4
```

By specifying `response_levels`, we ensure that health categories are
ordered from worst to best, making the chart more intuitive to read.

## Tips for Using the Function

### 1. Check Your Data First

Before creating charts, it’s helpful to examine your data:

``` r
# Check available variables
names(gss_all)[1:20]
#>  [1] "year"     "id"       "wrkstat"  "hrs1"     "hrs2"     "evwork"  
#>  [7] "occ"      "prestige" "wrkslf"   "wrkgovt"  "commute"  "industry"
#> [13] "occ80"    "prestg80" "indus80"  "indus07"  "occonet"  "found"   
#> [19] "occ10"    "occindv"

# Check response levels for a variable
gss_all %>%
  select(happy) %>%
  filter(!is.na(happy)) %>%
  mutate(happy = haven::as_factor(happy, levels = "labels")) %>%
  count(happy)
#> # A tibble: 3 × 2
#>   happy             n
#>   <fct>         <int>
#> 1 very happy    21069
#> 2 pretty happy  39705
#> 3 not too happy 10095
```

### 2. Handle Missing Data

The function automatically filters out missing values, but you should be
aware of how much data is being excluded:

``` r
# Check data availability
gss_all %>%
  summarise(
    total_rows = n(),
    year_missing = sum(is.na(year)),
    happy_missing = sum(is.na(happy)),
    both_available = sum(!is.na(year) & !is.na(happy))
  )
#> # A tibble: 1 × 4
#>   total_rows year_missing happy_missing both_available
#>        <int>        <int>         <int>          <int>
#> 1      75699            0          4830          70869
```

### 3. Interactive Features

The resulting charts are interactive Highcharts objects that support:

- **Hovering** over data points to see exact values
- **Clicking legend items** to show/hide series
- **Zooming and panning** for detailed exploration
- **Exporting** charts as images or data

## Advanced Features

### Response Binning

Bin numeric responses into categories for clearer visualization:

``` r
# Bin responses into positive/neutral/negative
plot5 <- create_timeline(
  data = gss_all,
  time_var = "year",
  response_var = "satfin",  # Financial satisfaction (1-3 scale)
  chart_type = "stacked_area",
  title = "Financial Satisfaction (Binned)",
  response_breaks = c(0.5, 1.5, 2.5, 3.5),
  response_bin_labels = c("Not satisfied", "More or less", "Satisfied"),
  y_max = 100
)

plot5
```

**When to use:** - Simplify complex response scales - Group similar
responses together - Create more interpretable categories

### Response Filtering

Focus on specific response values:

``` r
# Show only "very happy" and "pretty happy" responses
plot6 <- create_timeline(
  data = gss_all,
  time_var = "year",
  response_var = "happy",
  chart_type = "line",
  title = "Positive Happiness Trends",
  response_filter = c("very happy", "pretty happy")
)

plot6
```

For numeric scales, use range notation:

``` r
# Show only top-box scores (5-7 on 1-7 scale)
create_timeline(
  data = survey_data,
  time_var = "wave",
  response_var = "satisfaction",
  response_filter = 5:7,
  response_filter_combine = TRUE,
  response_filter_label = "Top 3 Box (5-7)"
)
```

**Parameters:** - `response_filter`: Which values to include -
`response_filter_combine`: Combine filtered values into single line
(default: FALSE) - `response_filter_label`: Custom label when combined
(default: auto-generated)

**Calculation Note:** When `response_filter_combine = TRUE`, percentages
are calculated out of the *total* responses (not just filtered ones),
showing the true proportion of top-box scores.

### Combining Filters with Groups

Show filtered responses across multiple groups:

``` r
# Top-box satisfaction by age group
create_timeline(
  data = survey_data,
  time_var = "year",
  response_var = "satisfaction",
  group_var = "age_group",
  response_filter = 5:7,
  response_filter_combine = TRUE,
  response_filter_label = "Highly Satisfied",
  title = "High Satisfaction by Age Group"
)
```

This creates separate lines for each age group, all showing only the
highly satisfied responses.

## Integration with Dashboards

The
[`create_timeline()`](https://favstats.github.io/dashboardr/reference/create_timeline.md)
function works seamlessly with `dashboardr`:

``` r
library(dashboardr)

# Create multiple timeline visualizations
timeline_viz <- create_viz() %>%
  add_viz(
    type = "timeline",
    time_var = "year",
    response_var = "happy",
    chart_type = "line",
    title = "Happiness Trends",
    tabgroup = "trends"
  ) %>%
  add_viz(
    type = "timeline",
    time_var = "year",
    response_var = "satfin",
    chart_type = "stacked_area",
    title = "Financial Satisfaction",
    tabgroup = "trends"
  )

# Create dashboard
dashboard <- create_dashboard(
  title = "GSS Trends Dashboard",
  output_dir = "gss_dashboard"
) %>%
  add_page(
    "Trends",
    data = gss_all,
    visualizations = timeline_viz,
    is_landing_page = TRUE
  )

generate_dashboard(dashboard)
```

### Comparative Analysis with Filters

Use dashboard filters to compare different time periods or demographics:

``` r
# Compare trends across different demographics
timeline_viz <- create_viz(
  type = "timeline",
  time_var = "year",
  response_var = "happy",
  chart_type = "line"
) %>%
  add_viz(title = "All Respondents") %>%
  add_viz(title = "Men", filter = ~ sex == "male") %>%
  add_viz(title = "Women", filter = ~ sex == "female") %>%
  add_viz(title = "Young Adults", filter = ~ age >= 18 & age <= 35)

dashboard <- create_dashboard(...) %>%
  add_page("Happiness Analysis", 
           data = gss_all, 
           visualizations = timeline_viz)

generate_dashboard(dashboard)
```

This creates separate tabs for each filtered view, making it easy to
compare trends across groups.

## Conclusion

The
[`create_timeline()`](https://favstats.github.io/dashboardr/reference/create_timeline.md)
function provides a flexible way to visualize survey data trends over
time. The function handles the data processing and creates interactive
visualizations that are perfect for exploring temporal patterns in
survey responses.

The function is especially well-suited for:

- **Longitudinal survey analysis**
- **Public opinion research**
- **Social trend visualization**
- **Comparative analysis across groups**
- **Interactive reporting and dashboards**

This vignette provides a comprehensive guide to using your function with
real GSS data, including practical examples and tips for effective
usage.
