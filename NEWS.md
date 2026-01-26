# dashboardr (development version)

## Breaking Changes

### Visualization Function Renaming

All `create_*` visualization functions have been renamed to `viz_*` for clarity and to
distinguish them from dashboard-level creation functions:

| Old Name | New Name |
|----------|----------|
| `create_histogram()` | `viz_histogram()` |
| `create_bar()` | `viz_bar()` |
| `create_stackedbar()` | `viz_stackedbar()` |
| `create_stackedbars()` | `viz_stackedbars()` |
| `create_timeline()` | `viz_timeline()` |
| `create_heatmap()` | `viz_heatmap()` |
| `create_scatter()` | `viz_scatter()` |
| `create_map()` | `viz_map()` |
| `create_treemap()` | `viz_treemap()` |

The old function names are deprecated and will show a warning when used.
They will be removed in a future version.

**Migration:** Simply replace `create_` with `viz_` in your code.

### Timeline Parameter Renaming

Timeline chart parameters have been renamed for consistency with other visualization types:

| Old Name | New Name |
|----------|----------|
| `response_var` | `y_var` |
| `response_filter` | `y_filter` |
| `response_filter_combine` | `y_filter_combine` |
| `response_filter_label` | `y_filter_label` |
| `response_levels` | `y_levels` |
| `response_breaks` | `y_breaks` |
| `response_bin_labels` | `y_bin_labels` |

## New Features

- Added new visualization vignettes: `histogram_vignette`, `scatter_vignette`, 
  `treemap_vignette`, `map_vignette`
- Interactive inputs demo and documentation in `vignette("advanced-features")`
- Improved cross-references between vignettes

## Bug Fixes
  
- Fixed Unicode/emoji rendering issues in console output
- Fixed nested tabgroup rendering in `preview()`
- Fixed parameter mapping for `stackedbars` visualization type
