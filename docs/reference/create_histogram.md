# Create an Histogram

This function creates a histogram for survey data. It handles raw
(unaggregated) data, counting the occurences of categories, supporting
ordered factors, allowing numerical x-axis variables to be binned into
custom groups, and enables renaming of categorical values for display.
It can also handle SPSS (.sav) columns automatically.

## Usage

``` r
create_histogram(
  data,
  x_var,
  y_var = NULL,
  title = NULL,
  subtitle = NULL,
  x_label = NULL,
  y_label = NULL,
  histogram_type = c("count", "percent"),
  tooltip_prefix = "",
  tooltip_suffix = "",
  x_tooltip_suffix = "",
  bins = NULL,
  bin_breaks = NULL,
  bin_labels = NULL,
  include_na = FALSE,
  na_label = "(Missing)",
  color = NULL,
  x_map_values = NULL,
  x_order = NULL
)
```

## Arguments

- data:

  A data frame containing the variable to plot.

- x_var:

  String. Name of the numeric column to histogram.

- y_var:

  Optional string. Name of a pre-computed count column. If supplied, the
  function skips counting and uses this column as y.

- title:

  Optional string. Main chart title.

- subtitle:

  Optional string. Chart subtitle.

- x_label:

  Optional string. X-axis label. Defaults to `x_var`.

- y_label:

  Optional string. Y-axis label. Defaults to "Count" or "Percentage".

- histogram_type:

  One of "count" or "percent". Default "count".

- tooltip_prefix:

  Optional string prepended in the tooltip.

- tooltip_suffix:

  Optional string appended in the tooltip.

- x_tooltip_suffix:

  Optional string appended to x value in tooltip.

- bins:

  Optional integer. Number of bins to compute via
  [`hist()`](https://rdrr.io/r/graphics/hist.html).

- bin_breaks:

  Optional numeric vector of cut points.

- bin_labels:

  Optional character vector of labels for the bins. Must be length
  `length(breaks)-1`.

- include_na:

  Logical. If TRUE, treats NA as explicit category.

- na_label:

  Optional string. Custom label for NA values. Defaults to "(Missing)".

- color:

  Optional string or vector of colors for the bars.

- x_map_values:

  Optional named list to recode raw `x_var` values before binning.

- x_order:

  Optional character vector to order the factor levels of the binned
  variable.

## Value

A `highcharter` histogram (column) plot object.

## Details

This function performs the following steps:

1.  **Input validation:** Checks that `data` is a data frame and `x_var`
    (and `y_var` if given) exist.

2.  **Haven-labelled handling:** If `x_var` is of class
    `"haven_labelled"`, converts it to numeric.

3.  **Value mapping:** If `x_map_values` is provided, recodes raw values
    before any binning.

4.  **Binning:**

    - If `bins` is set (and `bin_breaks` is `NULL`), computes breaks via
      [`hist()`](https://rdrr.io/r/graphics/hist.html).

    - If `bin_breaks` is provided, cuts `x_var` into categories, using
      `bin_labels` if supplied.

    - Otherwise uses the raw `x_var` values.

5.  **Factor and NA handling:** Converts the plotting variable to a
    factor; if `include_na = TRUE`, adds an explicit "(NA)" level.
    Applies `x_order` if given.

6.  **Aggregation:**

    - If `y_var` is `NULL`, counts occurrences of each factor level.

    - Otherwise renames `y_var` to `n` and skips counting.

7.  **Chart construction:** Builds a `highcharter` column chart of `n`
    vs. the factor levels.

8.  **Customization:**

    - Applies `title`, `subtitle`, axis labels.

    - Sets stacking mode (for percent vs. count), data labels format.

    - Defines a JS `tooltip.formatter` using `tooltip_prefix`,
      `tooltip_suffix`, and `x_tooltip_suffix`.

    - Applies custom `color` if provided.

## Examples

``` r
#We will work with data from the GSS. The GSS dataset (`gssr`) is a dependency of
#our `dashboardr` package.

#Filter to recent years and select relevant variables
#TODO: some of the examples look off for example plot 4 and 5
gss_recent <- gss_all %>%
  filter(year >= 2010) %>%
  select(age, degree, happy, sex, race, year)
#> Error in select(., age, degree, happy, sex, race, year): could not find function "select"

# Example 1: Basic histogram of age distribution
plot1 <- create_histogram(
  data = gss_recent,
  x_var = "age",
  title = "Age Distribution in GSS Data (2010+)",
  subtitle = "General Social Survey respondents",
  x_label = "Age (years)",
  y_label = "Number of Respondents",
  bins = 15,
  color = "hotpink"
)
#> Error: object 'gss_recent' not found
plot1
#> Error: object 'plot1' not found

# Example 2: Education levels with custom mapping and ordering
# First check the unique values
# unique(gss_recent$degree) # "Lt High School", "High School", "Junior College", "Bachelor", "Graduate"

education_order <- c("Lt High School", "High School", "Junior College", "Bachelor", "Graduate")

plot2 <- create_histogram(
  data = gss_recent,
  x_var = "degree",
  title = "Educational Attainment Distribution",
  subtitle = "GSS respondents 2010-present",
  x_label = "Highest Degree Completed",
  y_label = "Count",
  histogram_type = "count",
  x_order = education_order,
  include_na = TRUE,
)
#> Error: object 'gss_recent' not found
plot2
#> Error: object 'plot2' not found

# Example 3: Happiness levels as percentages with custom labels
happiness_map <- list(
  "Very Happy" = "Very Happy!",
  "Pretty Happy" = "Pretty Happy",
  "Not Too Happy" = "Not Too Happy :|"
)

plot3 <- create_histogram(
  data = gss_recent,
  x_var = "happy",
  title = "Self-Reported Happiness Levels",
  subtitle = "Percentage distribution among GSS respondents",
  x_label = "Happiness Level",
  y_label = "Percentage of Respondents",
  histogram_type = "percent",
  x_map_values = happiness_map,
  tooltip_suffix = "%",
  include_na = TRUE,
  na_label = "No Response",
)
#> Error: object 'gss_recent' not found
plot3
#> Error: object 'plot3' not found

# Example 4: Age binning with custom breaks and labels
age_breaks <- c(18, 30, 45, 60, 75, Inf)
age_labels <- c("18-29", "30-44", "45-59", "60-74", "75+")

plot4 <- create_histogram(
  data = gss_recent,
  x_var = "age",
  title = "Age Groups in GSS Sample",
  subtitle = "Custom age categories",
  x_label = "Age Group",
  y_label = "Number of Respondents",
  bin_breaks = age_breaks,
  bin_labels = age_labels,
  tooltip_prefix = "Count: ",
  x_tooltip_suffix = " years old",
  color = "seagreen1"
)
#> Error: object 'gss_recent' not found
plot4
#> Error: object 'plot4' not found

# Example 5: Using pre-aggregated data
# Create aggregated data first
race_counts <- gss_recent %>%
  count(race, name = "respondent_count") %>%
  filter(!is.na(race))
#> Error in count(., race, name = "respondent_count"): could not find function "count"

plot5 <- create_histogram(
  data = race_counts,
  x_var = "race",
  y_var = "respondent_count",  # Use pre-computed counts
  title = "Racial Distribution in GSS Sample",
  subtitle = "Based on pre-aggregated data",
  x_label = "Race/Ethnicity",
  y_label = "Number of Respondents",
)
#> Error: object 'race_counts' not found
plot5
#> Error: object 'plot5' not found

```
