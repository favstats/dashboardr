# Changelog

## dashboardr (development version)

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

- Added new visualization vignettes: `histogram_vignette`,
  `scatter_vignette`, `treemap_vignette`, `map_vignette`
- Interactive inputs demo and documentation in
  [`vignette("advanced-features")`](https://favstats.github.io/dashboardr/articles/advanced-features.md)
- Improved cross-references between vignettes

### Bug Fixes

- Fixed Unicode/emoji rendering issues in console output
- Fixed nested tabgroup rendering in
  [`preview()`](https://favstats.github.io/dashboardr/reference/preview.md)
- Fixed parameter mapping for `stackedbars` visualization type
