# Create an Histogram

This function creates a histogram for survey data. It handles raw
(unaggregated) data, counting the occurences of categories, supporting
ordered factors, allowing numerical x-axis variables to be binned into
custom groups, and enables renaming of categorical values for display.
It can also handle SPSS (.sav) columns automatically.

## Usage

``` r
viz_histogram(
  data,
  x_var,
  y_var = NULL,
  title = NULL,
  subtitle = NULL,
  x_label = NULL,
  y_label = NULL,
  histogram_type = c("count", "percent"),
  tooltip = NULL,
  tooltip_prefix = "",
  tooltip_suffix = "",
  x_tooltip_suffix = "",
  bins = NULL,
  bin_breaks = NULL,
  bin_labels = NULL,
  include_na = FALSE,
  na_label = "(Missing)",
  color_palette = NULL,
  x_map_values = NULL,
  x_order = NULL,
  weight_var = NULL,
  data_labels_enabled = TRUE
)
```

## Arguments

- data:

  A data frame containing the variable to plot.

- x_var:

  String. Name of the column to histogram (numeric or categorical).

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

- tooltip:

  A tooltip configuration created with
  [`tooltip()`](https://favstats.github.io/dashboardr/reference/tooltip.md),
  OR a format string with {placeholders}. Available placeholders:
  `{category}`, `{value}`, `{percent}`. For simple cases, use
  `tooltip_prefix` and `tooltip_suffix` instead. See
  [`tooltip`](https://favstats.github.io/dashboardr/reference/tooltip.md)
  for full customization options.

- tooltip_prefix:

  Optional string prepended in the tooltip (simple customization).

- tooltip_suffix:

  Optional string appended in the tooltip (simple customization).

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

  Logical. If TRUE, NA values are shown as explicit categories in the
  visualization. If FALSE (default), rows with NA in the x variable are
  excluded. Default FALSE.

- na_label:

  String. Label to display for NA values when `include_na = TRUE`.
  Default "(Missing)".

- color_palette:

  Optional string or vector of colors for the bars.

- x_map_values:

  Optional named list to recode raw `x_var` values before binning (e.g.,
  `list("1" = "Male", "2" = "Female")`).

- x_order:

  Optional character vector to order the factor levels of the binned
  variable.

- weight_var:

  Optional string. Name of a weight variable to use for weighted
  aggregation. When provided, counts are computed as the sum of weights
  instead of simple counts.

- data_labels_enabled:

  Logical. If TRUE, show value labels on bars. Default TRUE.

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

data(gss_panel20)
#> Warning: data set 'gss_panel20' not found

# Example 1: Basic histogram of age distribution
plot1 <- viz_histogram(
  data = gss_panel20,
  x_var = "age",
  title = "Age Distribution in GSS Data (2010+)",
  subtitle = "General Social Survey respondents",
  x_label = "Age (years)",
  y_label = "Number of Respondents",
  bins = 15,
  color_palette = "steelblue"
)
#> Error: object 'gss_panel20' not found
plot1
#> Error: object 'plot1' not found

# Example 2: Education levels with custom labels (excluding NAs)
education_map <- list("0" = "Less than High School",
                     "1" = "High School",
                     "2" = "Associate/Junior College",
                     "3" = "Bachelor's",
                     "4" = "Graduate"
                     )

plot2 <- viz_histogram(
 data = gss_panel20,
 x_var = "degree",
 title = "Educational Attainment Distribution",
 subtitle = "GSS respondents 2010-present (NAs excluded)",
 x_label = "Highest Degree Completed",
 y_label = "Count",
 histogram_type = "count",
 x_map_values = education_map,
 color_palette = "pink",
 include_na = FALSE  # Exclude missing values
)
#> Error: object 'gss_panel20' not found
plot2
#> Error: object 'plot2' not found

# Example 3: Including NA values with custom label
plot3 <- viz_histogram(
  data = gss_panel20,
  x_var = "degree",
  title = "Educational Attainment Distribution (Including Missing Data)",
  subtitle = "GSS respondents 2010-present",
  x_label = "Highest Degree Completed",
  x_order = education_order,
  include_na = TRUE,  # Show NAs as explicit category
  na_label = "Not Reported"  # Custom label for NAs
)
#> Error: object 'gss_panel20' not found
plot3
#> Error: object 'plot3' not found

# Example 4: Age binning with custom breaks
age_breaks <- c(18, 30, 45, 60, 75, Inf)
age_labels <- c("18-29", "30-44", "45-59", "60-74", "75+")

plot5 <- viz_histogram(
  data = gss_panel20,
  x_var = "age",
  title = "Age Groups in GSS Sample",
  subtitle = "Custom age categories",
  x_label = "Age Group",
  y_label = "Number of Respondents",
  bin_breaks = age_breaks,
  bin_labels = age_labels,
  tooltip_prefix = "Count: ",
  x_tooltip_suffix = " years old",
  color_palette = "seagreen"
)
#> Error: object 'gss_panel20' not found
plot5
#> Error: object 'plot5' not found


```
