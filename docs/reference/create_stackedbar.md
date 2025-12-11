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

  A data frame containing the raw survey data (one row per respondent).

- x_var:

  String. Name of the column for the X-axis categories.

- y_var:

  Optional string. Name of a pre-computed count column. If NULL
  (default), the function counts occurrences.

- stack_var:

  String. Name of the column whose values define the stacks.

- title:

  Optional string. Main chart title.

- subtitle:

  Optional string. Chart subtitle.

- x_label:

  Optional string. X-axis label. Defaults to `x_var`.

- y_label:

  Optional string. Y-axis label. Defaults to "Number of Respondents" or
  "Percentage of Respondents".

- stack_label:

  Optional string. Title for the stack legend. Defaults to `stack_var`.

- stacked_type:

  One of "counts" or "percent" (100% stacked). Default "normal".

- tooltip_prefix:

  Optional string prepended to tooltip values.

- tooltip_suffix:

  Optional string appended to tooltip values.

- x_tooltip_suffix:

  Optional string appended to x-axis values in tooltips.

- color_palette:

  Optional character vector of colors for the stacks.

- stack_order:

  Optional character vector specifying order of `stack_var` levels.

- x_order:

  Optional character vector specifying order of `x_var` levels.

- include_na:

  Logical. If TRUE, NA values in both `x_var` and `stack_var` are shown
  as explicit categories. If FALSE (default), rows with NA in either
  variable are excluded. Default FALSE.

- na_label_x:

  String. Label for NA values in `x_var` when `include_na = TRUE`.
  Default "(Missing)".

- na_label_stack:

  String. Label for NA values in `stack_var` when `include_na = TRUE`.
  Default "(Missing)".

- x_breaks:

  Optional numeric vector of cut points for binning `x_var`.

- x_bin_labels:

  Optional character vector of labels for `x_breaks` bins.

- x_map_values:

  Optional named list to remap `x_var` values for display.

- stack_breaks:

  Optional numeric vector of cut points for binning `stack_var`.

- stack_bin_labels:

  Optional character vector of labels for `stack_breaks` bins.

- stack_map_values:

  Optional named list to remap `stack_var` values for display.

- horizontal:

  Logical. If TRUE, creates horizontal bars. Default FALSE.

- weight_var:

  Optional string. Name of a weight variable to use for weighted
  aggregation. When provided, counts are replaced with weighted sums
  using this variable.

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

    - If `weight_var` is provided, weighted sums are calculated for each
      combination of `x_var` and `stack_var` using
      `sum(weight_var, na.rm = TRUE)`. Otherwise,
      [`dplyr::count()`](https://dplyr.tidyverse.org/reference/count.html)
      is used to count occurrences for each unique combination. This
      creates the `n` column required for `highcharter`.

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
