# Create a Heatmap

This function creates a heatmap for bivariate data, visualizing the
relationship between two categorical variables and a numeric value using
color intensity. It handles ordered factors, ensures all combinations
are plotted, and allows for extensive customization. It also includes
robust handling of missing values (NA) by allowing them to be displayed
as explicit categories.

## Usage

``` r
create_heatmap(
  data,
  x_var,
  y_var,
  value_var,
  title = NULL,
  subtitle = NULL,
  x_label = NULL,
  y_label = NULL,
  value_label = NULL,
  tooltip_prefix = "",
  tooltip_suffix = "",
  x_tooltip_suffix = "",
  y_tooltip_suffix = "",
  x_tooltip_prefix = "",
  y_tooltip_prefix = "",
  x_order = NULL,
  y_order = NULL,
  color_min = NULL,
  color_max = NULL,
  color_palette = c("#FFFFFF", "#7CB5EC"),
  na_color = "transparent",
  data_labels_enabled = TRUE,
  tooltip_labels_format = "{point.value}",
  include_na = FALSE,
  na_label_x = "(Missing)",
  na_label_y = "(Missing)",
  x_map_values = NULL,
  y_map_values = NULL,
  agg_fun = mean,
  weight_var = NULL
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

- tooltip_prefix:

  Optional string prepended in the tooltip value.

- tooltip_suffix:

  Optional string appended in the tooltip value.

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

- y_order:

  Optional character vector to order the factor levels of `y_var`.

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

- tooltip_labels_format:

  Optional string. Format for data labels. Default "point.value".

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
#TODO: something is off here so will comment out for now
# Example 1: Average Age by Education and Gender
# Let's create a heatmap showing the average age across education levels and gender.
# We will use the GSS dataset from 2020

# Step 1: Prepare data for heatmap
#age_education_data <- gss_clean %>%
#   filter(!is.na(degree_3), !is.na(sex_3), !is.na(age_3)) %>%
#   group_by(degree_3, sex_3) %>%
#   summarise(avg_age = mean(age_3, na.rm = TRUE), .groups = 'drop')

# Step 2: Create basic heatmap
# plot1 <- create_heatmap(
#   data = age_education_data,
#   x_var = "degree_3",
#   y_var = "sex_3",
#   value_var = "avg_age",
#   title = "Average Age by Education Level and Gender",
#   subtitle = "GSS Panel 2020 - Wave 3",
#   x_label = "Education Level",
#   y_label = "Gender",
#   value_label = "Average Age",
#   color_palette = c("#ffffff", "#2E86AB")
# )

plot1
#> Error: object 'plot1' not found
```
