# Create a Stacked Bar Chart

This function creates a stacked barchart for survey data. It handles raw
(unaggregated) data, counting the occurrences of categories, supporting
ordered factors, allowing numerical x-axis and stacked variables to be
binned into custom groups, and enables renaming of categorical values
for display. It can also handle SPSS (.sav) columns automatically.

## Usage

``` r
create_stackedbar(
  data,
  x_var,
  y_var = NULL,
  stack_var,
  title = NULL,
  subtitle = NULL,
  x_label = NULL,
  y_label = NULL,
  stack_label = NULL,
  stacked_type = c("counts", "percent"),
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
  weight_var = NULL
)
```

## Arguments

- data:

  A data frame containing the raw survey data (e.g., one row per
  respondent).

- x_var:

  The name of the column to be plotted on the X-axis (as a string). This
  typically represents a demographic variable or a question.

- y_var:

  Optional. The name of the column that already contains the counts or
  values for the y-axis (as a string). If `NULL` (default), the function
  will internally count the occurrences of `x_var` and `stack_var`. Only
  provide this if your `data` is already aggregated.

- stack_var:

  The name of the column whose unique values will define the stacks
  within each bar (as a string). This is often a Likert scale, an
  agreement level, or another categorical response.

- title:

  Optional. The main title of the chart (as a string).

- subtitle:

  Optional. A subtitle for the chart (as a string).

- x_label:

  Optional. The label for the X-axis (as a string). Defaults to `x_var`
  or `x_var (Binned)`.

- y_label:

  Optional. The label for the Y-axis (as a string). Defaults to "Number
  of Respondents" or "Percentage of Respondents".

- stack_label:

  Optional. The title for the stack legend (as a string). Set to NULL,
  NA, FALSE, or "" to hide the legend title completely. If not provided,
  no title is shown.

- stacked_type:

  Optional. The type of stacking. Can be "counts" (counts) or "percent"
  (100% stacked). Defaults to "counts".

- tooltip_prefix:

  Optional. A string to prepend to values in tooltips.

- tooltip_suffix:

  Optional. A string to append to values in tooltips.

- x_tooltip_suffix:

  Optional. A string to append to x-axis values in tooltips.

- color_palette:

  Optional. A character vector of colors to use for the stacks. If NULL,
  highcharter's default palette is used. Consider ordering colors to
  match `stack_order`.

- stack_order:

  Optional. A character vector specifying the desired order of the
  `stack_var` levels. This is crucial for ordinal scales (e.g., Likert
  1-7). If NULL, default factor order or alphabetical will be used.
  Levels not found in data will be ignored.

- x_order:

  Optional. A character vector specifying the desired order of the
  `x_var` levels. If NULL, default factor order or alphabetical will be
  used.

- include_na:

  Logical. If TRUE, explicit NA categories will be shown in counts for
  `x_var` and `stack_var`. If FALSE (default), rows with NA in `x_var`
  or `stack_var` are dropped.

- na_label_x:

  Optional string. Custom label for NA values in x_var. Defaults to
  "(Missing)".

- na_label_stack:

  Optional string. Custom label for NA values in stack_var. Defaults to
  "(Missing)".

- x_breaks:

  Optional. A numeric vector of cut points for `x_var` if it is a
  continuous variable and you want to bin it. e.g.,
  `c(16, 24, 33, 42, 51, 60, Inf)`.

- x_bin_labels:

  Optional. A character vector of labels for the bins created by
  `x_breaks`. Must be one less than the number of breaks (or same if Inf
  is last break).

- x_map_values:

  Optional. A named list (e.g., `list("1" = "Female", "2" = "Male")`) to
  rename values within `x_var` for display. Original values should be
  names, new labels should be values.

- stack_breaks:

  Optional. A numeric vector of cut points for `stack_var` if it is a
  continuous variable and you want to bin it.

- stack_bin_labels:

  Optional. A character vector of labels for the bins created by
  `stack_breaks`. Must be one less than the number of breaks (or same if
  Inf is last break).

- stack_map_values:

  Optional. A named list (e.g.,
  `list("1" = "Strongly Disagree", "7" = "Strongly Agree")`) to rename
  values within `stack_var` for display.

- horizontal:

  Logical. If `TRUE`, creates a horizontal bar chart (bars extend from
  left to right). If `FALSE` (default), creates a vertical column chart
  (bars extend from bottom to top). Note: When horizontal = TRUE, the
  stack order is automatically reversed so that the visual order of the
  stacks matches the legend order.

## Value

An interactive `highcharter` bar chart plot object.

## Details

This function performs the following steps:

1.  **Input Validation:** Checks if the provided `data` is a data frame
    and if `x_var` and `stack_var` columns exist.

2.  **Data Copy:** Creates a mutable copy of the input `data` to perform
    transformations without affecting the original.

3.  **Handle 'haven_labelled' Columns:** If `haven` package is
    available, it detects if `x_var` or `stack_var` are of class
    `haven_labelled` (common for data imported from SPSS/Stata/SAS). If
    so, it converts them to standard R factors, using their underlying
    numeric values as levels (e.g., a '1' that was labeled "Male" will
    become a factor level "1"). This ensures `recode` can operate
    correctly.

4.  **Apply Value Mapping (`x_map_values`, `stack_map_values`):** If
    provided, `x_map_values` and `stack_map_values` (named lists, e.g.,
    `list("1"="Male")`) are used to rename the values in `x_var` and
    `stack_var` respectively. This is useful for converting numeric
    codes or abbreviations into descriptive labels. If the column is a
    factor, it's temporarily converted to character to ensure
    [`dplyr::recode`](https://dplyr.tidyverse.org/reference/recode.html)
    works reliably on the values.

5.  **Handle Binning (`x_breaks`, `x_bin_labels`, `stack_breaks`,
    `stack_bin_labels`):**

    - If `x_var` (or `stack_var`) is numeric and corresponding `_breaks`
      are provided, the function uses
      [`base::cut()`](https://rdrr.io/r/base/cut.html) to discretize the
      numeric variable into bins.

    - `_bin_labels` can be supplied to give custom names to these bins
      (e.g., "18-24" instead of "(17,25\]"). If not provided,
      [`cut()`](https://rdrr.io/r/base/cut.html) generates default
      labels.

    - A temporary column (e.g., `.x_var_binned`) is created to hold the
      binned values, and this temporary column is then used for
      plotting.

6.  **Data Aggregation and Final Factor Handling:**

    - The data is transformed using
      [`dplyr::mutate`](https://dplyr.tidyverse.org/reference/mutate.html)
      to ensure `x_var` and `stack_var` (or their binned versions) are
      treated as factors. If `include_na = TRUE`, missing values are
      converted into an explicit "(NA)" factor level.

    - [`dplyr::count()`](https://dplyr.tidyverse.org/reference/count.html)
      is then used to aggregate the data, counting occurrences for each
      unique combination of `x_var` and `stack_var`. This creates the
      `n` column required for `highcharter`.

7.  **Apply Custom Ordering (`x_order`, `stack_order`):** If provided,
    `x_order` and `stack_order` are used to set the display order of the
    factor levels for the X-axis and stack categories, respectively.
    This is essential for ordinal scales (e.g., Likert scales) or custom
    desired sorting. Levels not found in the order vector are appended
    at the end.

8.  **Highcharter Chart Generation:** The aggregated `plot_data` is
    passed to
    [`highcharter::hchart()`](https://jkunst.com/highcharter/reference/hchart.html)
    to create the base stacked column chart.

9.  **Chart Customization:** Titles, subtitles, axis labels, stacking
    type (counts vs. percent), data labels, legend titles, tooltips, and
    custom color palettes are applied based on the function's arguments.

10. **Return Value:** The function returns a `highcharter` plot object,
    which can be printed directly to display the interactive chart.

## Examples

``` r
# We will be using data from GSS for these examples.
# Make sure you have the data loaded:
data(gss_all)
#> Warning: data set 'gss_all' not found

# Filter to recent years and select relevant variables
gss_recent <- gss_all %>%
  filter(year >= 2010) %>%
  select(age, degree, happy, sex, race, year, polviews, attend)
#> Error in select(., age, degree, happy, sex, race, year, polviews, attend): could not find function "select"

# Example 1: Basic stacked bar - Education by Gender
education_order <- c("Lt High School", "High School", "Junior College", "Bachelor", "Graduate")

plot1 <- create_stackedbar(
  data = gss_recent,
  x_var = "degree",
  stack_var = "sex",
  title = "Educational Attainment by Gender",
  subtitle = "GSS respondents 2010-present",
  x_label = "Highest Degree Completed",
  y_label = "Number of Respondents",
  stack_label = "Gender",
  x_order = education_order,
)
#> Error: object 'gss_recent' not found
plot1
#> Error: object 'plot1' not found

# Example 2: Percentage stacked - Happiness by Education Level
plot2 <- create_stackedbar(
  data = gss_recent,
  x_var = "degree",
  stack_var = "happy",
  title = "Happiness Distribution Across Education Levels",
  subtitle = "Percentage breakdown within each education category",
  x_label = "Education Level",
  y_label = "Percentage of Respondents",
  stack_label = "Happiness Level",
  stacked_type = "percent",
  x_order = education_order,
  stack_order = c("Very Happy", "Pretty Happy", "Not Too Happy"),
  tooltip_suffix = "%",
  color_palette = c("turquoise", "slateblue", "steelblue")
)
#> Error: object 'gss_recent' not found
plot2
#> Error: object 'plot2' not found

# Example 3: Age binning with political views
age_breaks <- c(18, 30, 45, 60, 75, Inf)
age_labels <- c("18-29", "30-44", "45-59", "60-74", "75+")

# Map political views to shorter labels
polviews_map <- list(
  "Extremely Liberal" = "Ext Liberal",
  "Liberal" = "Liberal",
  "Slightly Liberal" = "Sl Liberal",
  "Moderate" = "Moderate",
  "Slightly Conservative" = "Sl Conservative",
  "Conservative" = "Conservative",
  "Extremely Conservative" = "Ext Conservative"
)

plot3 <- create_stackedbar(
  data = gss_recent,
  x_var = "age",
  stack_var = "polviews",
  title = "Political Views by Age Group",
  subtitle = "Distribution of political ideology across age cohorts",
  x_label = "Age Group",
  stack_label = "Political Views",
  x_breaks = age_breaks,
  x_bin_labels = age_labels,
  stack_map_values = polviews_map,
  stacked_type = "percent",
  tooltip_suffix = "%",
  x_tooltip_suffix = " years",
)
#> Error: object 'gss_recent' not found
plot3
#> Error: object 'plot3' not found

# Example 4: Including NA values with custom labels
plot4 <- create_stackedbar(
  data = gss_recent,
  x_var = "race",
  stack_var = "attend",
  title = "Religious Attendance by Race/Ethnicity",
  subtitle = "Including non-responses as explicit category",
  x_label = "Race/Ethnicity",
  stack_label = "Religious Attendance",
  include_na = TRUE,
  na_label_x = "Not Specified",
  na_label_stack = "No Answer",
  stacked_type = "percent",
  tooltip_suffix = "%"
)
#> Error: object 'gss_recent' not found
plot4
#> Error: object 'plot4' not found

# Example 5: Using pre-aggregated data
# Create aggregated data first
education_gender_counts <- gss_recent %>%
  filter(!is.na(degree) & !is.na(sex)) %>%
  count(degree, sex, name = "respondent_count") %>%
  mutate(degree = factor(degree, levels = education_order))
#> Error in mutate(., degree = factor(degree, levels = education_order)): could not find function "mutate"

plot5 <- create_stackedbar(
  data = education_gender_counts,
  x_var = "degree",
  y_var = "respondent_count",  # Use pre-computed counts
  stack_var = "sex",
  title = "Education by Gender (Pre-aggregated Data)",
  subtitle = "Using pre-computed counts",
  x_label = "Education Level",
  y_label = "Number of Respondents",
  stack_label = "Gender",
)
#> Error: object 'education_gender_counts' not found
plot5
#> Error: object 'plot5' not found

# Example 6: Complex mapping with custom ordering
# Map sex to more descriptive labels
sex_map <- list("Male" = "Men", "Female" = "Women")

plot6 <- create_stackedbar(
  data = gss_recent,
  x_var = "happy",
  stack_var = "sex",
  title = "Gender Distribution Across Happiness Levels",
  subtitle = "With custom gender labels and happiness ordering",
  x_label = "Self-Reported Happiness",
  stack_label = "Gender",
  x_order = c("Very Happy", "Pretty Happy", "Not Too Happy"),
  stack_map_values = sex_map,
  stack_order = c("Women", "Men"),
  stacked_type = "counts",
  tooltip_prefix = "Count: ",
)
#> Error: object 'gss_recent' not found
plot6
#> Error: object 'plot6' not found

```
