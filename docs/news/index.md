# Changelog

## dashboardr 0.2.0

### Bug Fixes

#### Pagination Fix

- **Fixed
  [`add_pagination()`](https://favstats.github.io/dashboardr/reference/add_pagination.md)
  duplicating content across all pages**: When using the `+` operator to
  add visualizations to a page, the `viz_embedded_in_content` flag
  caused `.generate_default_page_content()` to use the original full
  `content_blocks` instead of the correctly-split paginated
  `visualizations`. Each paginated page now correctly contains only its
  designated content section.

#### Tabgroup Improvements

- **Fixed `shared_first_level` behavior for nested tabgroups**: The
  `shared_first_level` feature (which wraps multiple top-level tabgroups
  into a single shared tabset) is now automatically disabled when any of
  the top-level tabgroups contain nested children. This prevents
  redundant wrapper tabsets when using deeply nested tabgroup structures
  like `category/wave/breakdown`.

------------------------------------------------------------------------

## dashboardr 0.1.0

### Unified Stacked Bar Chart Function

[`viz_stackedbar()`](https://favstats.github.io/dashboardr/reference/viz_stackedbar.md)
is now a unified function that supports **two modes**:

**Mode 1: Grouped/Crosstab** (use `x_var` + `stack_var`)

``` r
# Show how one variable breaks down by another
viz_stackedbar(data, x_var = "education", stack_var = "gender")
```

**Mode 2: Multi-Variable/Battery** (use `x_vars`)

``` r
# Compare multiple survey questions side-by-side
viz_stackedbar(data, x_vars = c("q1", "q2", "q3"))
```

This eliminates confusion between
[`viz_stackedbar()`](https://favstats.github.io/dashboardr/reference/viz_stackedbar.md)
and
[`viz_stackedbars()`](https://favstats.github.io/dashboardr/reference/viz_stackedbars.md) -
you now only need to remember one function! The function automatically
detects which mode to use based on the parameters you provide.

**Migration from
[`viz_stackedbars()`](https://favstats.github.io/dashboardr/reference/viz_stackedbars.md):**
Simply change the function name - all parameters work the same way:

``` r
# Old way (still works, shows deprecation notice)
viz_stackedbars(data, x_vars = c("q1", "q2", "q3"))

# New preferred way
viz_stackedbar(data, x_vars = c("q1", "q2", "q3"))
```

The
[`viz_stackedbars()`](https://favstats.github.io/dashboardr/reference/viz_stackedbars.md)
function is soft-deprecated and will continue to work, but we recommend
using
[`viz_stackedbar()`](https://favstats.github.io/dashboardr/reference/viz_stackedbar.md)
for all new code.

### Breaking Changes

#### Visualization Function Renaming

All `create_*` visualization functions have been renamed to `viz_*` for
clarity and to distinguish them from dashboard-level creation functions:

| Old Name | New Name |
|----|----|
| [`create_histogram()`](https://favstats.github.io/dashboardr/reference/deprecated-viz.md) | [`viz_histogram()`](https://favstats.github.io/dashboardr/reference/viz_histogram.md) |
| [`create_bar()`](https://favstats.github.io/dashboardr/reference/deprecated-viz.md) | [`viz_bar()`](https://favstats.github.io/dashboardr/reference/viz_bar.md) |
| [`create_stackedbar()`](https://favstats.github.io/dashboardr/reference/deprecated-viz.md) | [`viz_stackedbar()`](https://favstats.github.io/dashboardr/reference/viz_stackedbar.md) |
| [`create_stackedbars()`](https://favstats.github.io/dashboardr/reference/deprecated-viz.md) | [`viz_stackedbars()`](https://favstats.github.io/dashboardr/reference/viz_stackedbars.md) |
| [`create_timeline()`](https://favstats.github.io/dashboardr/reference/deprecated-viz.md) | [`viz_timeline()`](https://favstats.github.io/dashboardr/reference/viz_timeline.md) |
| [`create_heatmap()`](https://favstats.github.io/dashboardr/reference/deprecated-viz.md) | [`viz_heatmap()`](https://favstats.github.io/dashboardr/reference/viz_heatmap.md) |
| [`create_scatter()`](https://favstats.github.io/dashboardr/reference/deprecated-viz.md) | [`viz_scatter()`](https://favstats.github.io/dashboardr/reference/viz_scatter.md) |
| [`create_map()`](https://favstats.github.io/dashboardr/reference/deprecated-viz.md) | [`viz_map()`](https://favstats.github.io/dashboardr/reference/viz_map.md) |
| [`create_treemap()`](https://favstats.github.io/dashboardr/reference/deprecated-viz.md) | [`viz_treemap()`](https://favstats.github.io/dashboardr/reference/viz_treemap.md) |

The old function names are deprecated and will show a warning when used.
They will be removed in a future version.

**Migration:** Simply replace `create_` with `viz_` in your code.

#### Timeline Parameter Renaming

Timeline chart parameters have been renamed for consistency with other
visualization types:

| Old Name                  | New Name           |
|---------------------------|--------------------|
| `response_var`            | `y_var`            |
| `response_filter`         | `y_filter`         |
| `response_filter_combine` | `y_filter_combine` |
| `response_filter_label`   | `y_filter_label`   |
| `response_levels`         | `y_levels`         |
| `response_breaks`         | `y_breaks`         |
| `response_bin_labels`     | `y_bin_labels`     |

### New Features

#### Error Bars Support in Bar Charts

[`viz_bar()`](https://favstats.github.io/dashboardr/reference/viz_bar.md)
now supports error bars for displaying uncertainty in mean values:

- New `value_var` parameter: When provided, bars show the mean of this
  variable per category (instead of counts)
- New `error_bars` parameter: Choose from “none” (default), “sd”
  (standard deviation), “se” (standard error), or “ci” (confidence
  interval)
- New `ci_level` parameter: Set confidence level for CI (default 0.95
  for 95% CI)
- Customizable appearance via `error_bar_color` and `error_bar_width`
  parameters
- Works with both simple and grouped bar charts

Example usage:

``` r
# Bar chart with means and 95% CI
viz_bar(
  data = mtcars,
  x_var = "cyl",
  value_var = "mpg",
  error_bars = "ci",
  title = "Mean MPG by Cylinders"
)

# Grouped bars with standard error
viz_bar(
  data = mtcars,
  x_var = "cyl",
  group_var = "am",
  value_var = "mpg",
  error_bars = "se"
)
```

#### Early Validation for Visualizations

- [`preview()`](https://favstats.github.io/dashboardr/reference/preview.md)
  now automatically validates all visualization specs before rendering,
  catching missing required parameters (like `stack_var` for stacked bar
  charts) and invalid column names early with helpful error messages
- New
  [`validate_specs()`](https://favstats.github.io/dashboardr/reference/validate_specs.md)
  function for manual validation of content collections
- `print(collection, check = TRUE)` validates specs while viewing the
  structure

#### New Visualization Types

- [`viz_density()`](https://favstats.github.io/dashboardr/reference/viz_density.md):
  Create kernel density estimate plots for visualizing continuous
  distributions. Supports grouped densities, adjustable bandwidth, rug
  marks, and weighted estimation.
- [`viz_boxplot()`](https://favstats.github.io/dashboardr/reference/viz_boxplot.md):
  Create interactive box-and-whisker plots. Supports grouped boxplots,
  horizontal orientation, outlier display, and weighted percentiles.

#### Histogram Improvements

- Fixed handling of character-numeric values (e.g., “25”, “30”) - now
  correctly converted to numeric for binning
- Improved default bin labels to show readable ranges (e.g., “18-29”
  instead of “\[18,30)”)
- Added `data_labels_enabled` parameter to control display of value
  labels on bars

#### Data Labels Control

- Added `data_labels_enabled` parameter to
  [`viz_histogram()`](https://favstats.github.io/dashboardr/reference/viz_histogram.md),
  [`viz_bar()`](https://favstats.github.io/dashboardr/reference/viz_bar.md),
  [`viz_stackedbar()`](https://favstats.github.io/dashboardr/reference/viz_stackedbar.md),
  and
  [`viz_stackedbars()`](https://favstats.github.io/dashboardr/reference/viz_stackedbars.md) -
  allows hiding value labels on bars for cleaner visualizations
- Renamed `show_labels` to `data_labels_enabled` in
  [`viz_treemap()`](https://favstats.github.io/dashboardr/reference/viz_treemap.md)
  for consistency (old parameter still works with deprecation warning)
- [`viz_heatmap()`](https://favstats.github.io/dashboardr/reference/viz_heatmap.md)
  already had `data_labels_enabled` - now all viz functions use the same
  parameter name

#### Documentation

- Added new visualization vignettes: `density_vignette`,
  `boxplot_vignette`, `histogram_vignette`, `scatter_vignette`,
  `treemap_vignette`, `map_vignette`
- Interactive inputs demo and documentation in
  [`vignette("advanced-features")`](https://favstats.github.io/dashboardr/articles/advanced-features.md)
- Improved cross-references between vignettes

### Bug Fixes

- Fixed Unicode/emoji rendering issues in console output
- Fixed nested tabgroup rendering in
  [`preview()`](https://favstats.github.io/dashboardr/reference/preview.md)
- Fixed parameter mapping for `stackedbars` visualization type
