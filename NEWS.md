# dashboardr 0.5.2

## Metric Card Redesign (Issue #15)

`add_metric()` / `html_metric()` now renders as a modern KPI card with centered text, gradient background, and bold value display — matching the `preview()` style. Previously, `generate_dashboard()` and `preview()` produced different metric visuals.

### New Parameters

- **`gradient`**: Controls gradient background. `TRUE` (default) uses the default purple gradient. Pass a color name or hex (e.g., `gradient = "red"`, `gradient = "#cb333b"`) to auto-generate a gradient from that color. `FALSE` for a plain flat card.
- **`gradient_intensity`**: Controls how dramatic the gradient shift is (0–1, default 0.45). `0` = flat, `1` = maximum contrast. For dark colors, controls how much lighter the gradient start is; for light colors, controls how much darker the end is.
- **`color`**: Now serves as the base color for gradient generation when `gradient` is active (instead of a left-border accent). With `gradient = FALSE`, it becomes a solid background color.

### Layout Fixes

- **`add_layout_row()` metrics in preview**: Layout containers (`add_layout_column()` / `add_layout_row()`) now render correctly in `preview()`. Previously, items inside layout rows were silently dropped. Row items now display side-by-side via CSS flex.

---

# dashboardr 0.5.1

## New Features

### Deferred Charts

- `deferred_charts = TRUE` in `create_dashboard()`: Only renders initially visible charts; others become lightweight JSON placeholders that load on demand when revealed by `show_when`. Dramatically reduces initial page load time for dashboards with many hidden chart states.

### Cross-Tab Asset Mode

- `cross_tab_data_mode = "asset"` in `create_dashboard()`: Writes cross-tab data to external `.json` files instead of inlining in HTML. Reduces HTML file size for dashboards with many filtered charts.
- `min_cell_size` parameter for privacy protection — suppresses cross-tab rows where cell count is below the threshold.
- `rds_bundle_threshold` parameter bundles generated datasets into a single `.rds` file for large dashboards.

### Input Enhancements

- **Icons on inputs**: `icons` parameter on `add_input()`, `render_input()`, and internal radio/button group generators. Supports Iconify icon names (e.g., `"ph:calendar"`) rendered before option text.
- **show_when on inputs**: `show_when` parameter on `add_input()` wraps the input in a conditional visibility container, enabling inputs that appear/disappear based on other filter selections.
- **Linked inputs outside sidebar**: `add_linked_inputs()` now works in content collections and input rows, not just sidebars.

### Page Slugs

- `slug` parameter on `add_dashboard_page()` / `add_page()` for custom page filenames, overriding the default name-based slug.

### Timeline Data Labels

- `data_labels_enabled` parameter on `viz_timeline()` to display data point values directly on the chart.

### Multi-Backend Viz Improvements

- Enhanced `viz_boxplot`, `viz_scatter`, `viz_pie`, `viz_stackedbar`, and `viz_timeline` with improved cross-tab support and backend-specific rendering.

## Bug Fixes

- Fixed show_when re-evaluation after button group clicks (standard `change` event dispatch in `input_filter.js`).
- Fixed custom CSS not loading in published dashboards (copy to publish dir + resources in `_quarto.yml`).

## Documentation & Packaging

- Fixed all code/documentation mismatches (added `@param` entries for new parameters).
- Fixed vignette errors: replaced `devtools::load_all()` with `library(dashboardr)` in 10 vignettes; added `purl = FALSE` to 7 documentation-only vignettes.
- Updated `.Rbuildignore` to exclude demo output directories, `.quarto` dirs, `vignettes/lib/`, and `.DS_Store` files.
- Added `globalVariables()` entries for NSE columns in `viz_boxplot` and `viz_scatter`.
- R CMD check clean (0 errors, 0 warnings).

---

# dashboardr 0.5.0

## New Features

### Standalone HTML Export

- `generate_dashboard(standalone = TRUE)`: Generate a single self-contained HTML file with all CSS, JavaScript, images, and fonts embedded inline. The resulting file can be shared via email or file transfer without a web server.

### New Vignettes

- **Customizing Visualizations**: Comprehensive guide to color palettes, tooltips, legends, data labels, axis formatting, error bars, sorting, and backend options — with GSS data examples.
- **Date Inputs**: Using `type = "date"` and `type = "daterange"` for time-based filtering.
- **URL Parameters**: Shareable dashboard links with pre-set filter state via `enable_url_params()`.
- **Accessibility**: WCAG 2.1 AA features including skip-to-content, focus indicators, modal focus trapping, keyboard tab navigation, ARIA live regions, and reduced motion support via `enable_accessibility()`.

### Enhanced Metric Cards

- `html_metric()` / `add_metric()` gain `bg_color`, `text_color`, `value_prefix`, `value_suffix`, and `border_radius` parameters for richer styling, similar to `add_value_box()`.

### Layout Row Styling

- `add_layout_row()` gains a `style` parameter for inline CSS on the row wrapper (e.g. `style = "text-align: center;"`). Applied to `layout-ncol` divs in non-dashboard mode and `### Row` attributes in dashboard mode.

### HTML Helper Functions

- New exported helpers: `html_spacer()`, `html_divider()`, `html_card()`, `html_accordion()`, `html_iframe()`, `html_badge()`, `html_metric()`.

## Bug Fixes

### Layout Row Metrics (Issue #15)

- **Fixed**: Metrics inside `add_layout_row()` / `end_layout_row()` now render side-by-side as expected, consistent with `add_value_box_row()` behavior.
- **Fixed**: `text_color` on metric cards now properly applies to title and subtitle text (Bootstrap `text-muted` class was overriding the inherited color).

## Internal

- Viz type registry (`R/viz_registry.R`) replaces hardcoded switch dispatch in `R/viz_generation.R`.
- Raw HTML in generated QMD replaced with clean R function calls.
- R CMD check clean (0 errors, 0 warnings).

# dashboardr 0.4.2

## New Features

### Widget Convenience Wrappers

New exported convenience functions for embedding charts from alternative backends:

- `add_echarts()`: Embed an echarts4r chart directly into a dashboard page.
- `add_ggiraph()`: Embed a ggiraph interactive plot directly into a dashboard page.
- `add_ggplot()`: Embed a static ggplot2 plot, rendered via Quarto's knitr graphics device with optional `height`/`width` control.

### MCP Server for LLM Assistants

- `dashboardr_mcp_server()`: Launch an MCP (Model Context Protocol) server that exposes dashboardr documentation, function reference, example code, and visualization guides to LLM-powered coding assistants (Claude Desktop, Claude Code, Cursor, VS Code Copilot). Requires optional packages `ellmer` + `mcptools` (or `mcpr` as fallback).

## Bug Fixes

### Content Tabgroups (Issue #14)

- **Fixed**: The `tabgroup` argument is now correctly applied to all content block types (`add_text`, `add_card`, `add_reactable`, and other content types), not just visualizations. Previously, `tabgroup` had no effect for non-viz content. Standalone content blocks, items inside content collections, and items added directly to pages via `add_text()` / `add_card()` / etc. now all respect `tabgroup` and render in their respective tabs.

### CI Stability

- **Fixed**: GitHub Actions coverage and R CMD check workflows were failing with exit code 143 (OOM kill). Added `skip_on_covr_ci()` to feature-matrix and generation-heavy tests that were running under covr instrumentation without memory guards. Added memory diagnostics and `timeout-minutes` to workflows for better failure reporting.

# dashboardr 0.4.1

## Bug Fixes

### Content Tabgroups (Issue #14)

- **Fixed**: The `tabgroup` argument is now correctly applied to all content block types (`add_text`, `add_card`, `add_reactable`, and other content types), not just visualizations. Previously, `tabgroup` had no effect for non-viz content. Standalone content blocks, items inside content collections, and items added directly to pages via `add_text()` / `add_card()` / etc. now all respect `tabgroup` and render in their respective tabs.

# dashboardr 0.4.0

## Bug Fixes

### Cross-Tab Stacked Bar Labels (Critical)

- **Fixed**: Stacked bar data labels showed full floating-point precision (e.g. `61.53846153846154`) when charts were rebuilt client-side via cross-tab filtering. The R-side rounding was correct, but the JavaScript `_rebuildStackedBarEcharts`, `_rebuildStackedBarPlotly`, and `_rebuildStackedBarSeries` (Highcharts) functions recomputed percentages from raw counts without rounding. All three JS rebuild paths now round to the configured `label_decimals` (default: 1 for percent, 0 for count).
- **New**: `labelDecimals` is now passed from R to the JS cross-tab config so client-side rebuilds respect the same decimal precision as the initial R render.
- **New**: Labels on very small bar segments (< 5% of their stack) are now automatically hidden across all backends (echarts4r, Highcharts, Plotly, ggiraph) to avoid visual clutter.

### Quarto Discovery

- **Fixed**: `preview(quarto = TRUE)` and `.install_iconify_extension()` now use `.find_quarto_path()` which searches PATH, the `quarto` R package, and the RStudio-bundled Quarto location. Previously, only `Sys.which("quarto")` was used, causing failures in environments where Quarto was installed but not on PATH.

### Documentation & Tests

- Documented `legend_position` parameter across all 10 visualization functions.
- Added `.color` to `globalVariables()` to suppress R CMD check note.
- Marked `sparkline_card` functions as `@keywords internal` to fix pkgdown reference index.
- Fixed all empty `testthat` tests and resolved Quarto detection skips.

## New Features

### Multi-Backend Chart Support

All 17 visualization functions now support a `backend` parameter for rendering with different charting libraries. The default backend remains `"highcharter"` for full backward compatibility.

Supported backends: `"highcharter"` (default), `"plotly"`, `"echarts4r"`, `"ggiraph"`.

```r
# Per-chart backend selection
viz_bar(data, x_var = "category", backend = "plotly")
viz_timeline(data, time_var = "year", y_var = "value", backend = "echarts4r")

# Dashboard-wide backend (applies to all charts)
create_dashboard(title = "My Dashboard", backend = "plotly")
```

Alternative backends are optional dependencies (in `Suggests`). Install only what you need:
```r
install.packages(c("plotly", "echarts4r", "ggiraph"))
```

### Widget Embedding

New functions for embedding arbitrary htmlwidgets in dashboards:

- `add_widget()`: Embed any htmlwidget object directly
- `add_plotly()`: Convenience wrapper for plotly objects
- `add_leaflet()`: Convenience wrapper for leaflet maps

```r
library(plotly)
my_plot <- plot_ly(mtcars, x = ~wt, y = ~mpg, type = "scatter", mode = "markers")
collection <- content_collection() + add_plotly(my_plot, title = "Weight vs MPG")
```

---

# dashboardr 0.3.0

## New Features

### Community Gallery

- Added a Community Gallery showcasing dashboardr dashboards, hosted as a Vue.js SPA at `gallery/index.html`.
- Users can submit their own dashboards via a GitHub issue template.
- Gallery is prominently featured in the pkgdown site navbar, README, getting-started vignette, and demos vignette.

### About Pages for Demo Dashboards

- All demo dashboards (inputs, sidebar, sidebar-gss, overlay, and all 6 tabset themes) now include an About page with a description of demonstrated features, example usage code, and a direct link to the source code on GitHub.

## Bug Fixes

### Input Filtering

- **Select inputs**: Fixed `filterVars` JSON serialization — single-element character vectors (e.g., `c("country")`) were serialized as a string instead of an array, causing the JavaScript to iterate over individual characters instead of matching filter values.
- **Slider inputs**: Slider filters were collected but never passed to `rebuildFromCrossTab()`, so labeled sliders had no effect on cross-tab charts. Sliders now correctly filter data by label position.
- **Switch inputs**: Switch-toggled series (e.g., "Global Average" with `override = TRUE`) were invisible because cross-tab data filtering excluded them. Override series data is now preserved during filtering, and switch visibility is applied after cross-tab rebuild.

---

# dashboardr 0.2.1

## New Features

### Sidebar Dashboards with Cross-Tab Filtering

New sidebar-based dashboard pattern with client-side cross-tab filtering. Sidebar radio/checkbox inputs dynamically filter and rebuild Highcharts visualizations (stacked bars and timelines) without server round-trips.

- **`show_when`**: Conditionally show/hide visualizations based on sidebar input values. Uses formula syntax (e.g., `show_when = ~ time_period == "Over Time"`). Hidden elements fully collapse in layout, including empty `bslib-grid` containers.

- **`title_map`**: Dynamic chart titles that interpolate sidebar input values. Uses `{placeholder}` syntax in titles with a simple named-vector mapping. Auto-detects which input to read from — no manual wiring needed.
  ```r
  title_map = list(key_response = c("Marijuana" = "Legal", "Gun Control" = "Favor"))
  ```

- **`group_order`** (timeline): Control the order of series in timeline charts. Pass a character vector to enforce consistent series/legend ordering across chart types.

- **Named `color_palette`**: Pass a named character vector to `color_palette` to assign fixed colors per series name, ensuring consistent colors across stacked bars and timelines.
  ```r
  color_palette = c("Male" = "#F28E2B", "Female" = "#E15759", "White" = "#EDC948")
  ```
  Unnamed vectors still work as positional color cycles (backwards compatible).

### Stacked Bar Enhancements

- `viz_stackedbar()` now supports `title_map` for dynamic title interpolation, matching timeline functionality.
- Named `color_palette` resolves colors by stack-level name, not just position.

### Timeline Enhancements

- `viz_timeline()` now supports `group_order` for explicit series ordering.
- Named `color_palette` assigns colors per group name, preserved during client-side filter rebuilds.
- `title_map` with auto-detection of the relevant sidebar input.

### Client-Side Filtering (JS)

- Stacked bar and timeline charts embed cross-tab data and config as HTML attributes, enabling instant client-side rebuilds when sidebar inputs change.
- Color maps (`colorMap`) and group order (`groupOrder`) are embedded in chart config and respected during JS rebuilds.
- Dynamic title interpolation via `titleTemplate` and `titleLookups` in the chart config.

## Bug Fixes

- Fixed C stack overflow when serializing `haven_labelled` columns in cross-tab data.
- Fixed `.serialize_arg()` to correctly preserve names in named character vectors.
- Fixed empty `bslib-grid` containers still occupying space when their children are hidden by `show_when` (now uses `!important` CSS class).
- Fixed dynamic title `{placeholder}` not interpolating due to chart ID matching mismatch in JS.

## Demo

- New **GSS Explorer** sidebar demo (`dev/demo_sidebar_dashboard.R`) showcasing all new features: sidebar inputs, conditional visibility, dynamic titles, cross-tab filtering, named color palettes, and consistent series ordering.

---

# dashboardr 0.2.0

## Bug Fixes

### Pagination Fix

- **Fixed `add_pagination()` duplicating content across all pages**: When using the `+` operator to add visualizations to a page, the `viz_embedded_in_content` flag caused `.generate_default_page_content()` to use the original full `content_blocks` instead of the correctly-split paginated `visualizations`. Each paginated page now correctly contains only its designated content section.

### Tabgroup Improvements

- **Fixed `shared_first_level` behavior for nested tabgroups**: The `shared_first_level` feature (which wraps multiple top-level tabgroups into a single shared tabset) is now automatically disabled when any of the top-level tabgroups contain nested children. This prevents redundant wrapper tabsets when using deeply nested tabgroup structures like `category/wave/breakdown`.

---

# dashboardr 0.1.0

## Unified Stacked Bar Chart Function

`viz_stackedbar()` is now a unified function that supports **two modes**:

**Mode 1: Grouped/Crosstab** (use `x_var` + `stack_var`)
```r
# Show how one variable breaks down by another
viz_stackedbar(data, x_var = "education", stack_var = "gender")
```

**Mode 2: Multi-Variable/Battery** (use `x_vars`)
```r
# Compare multiple survey questions side-by-side
viz_stackedbar(data, x_vars = c("q1", "q2", "q3"))
```

This eliminates confusion between `viz_stackedbar()` and `viz_stackedbars()` - you now only need to remember one function! The function automatically detects which mode to use based on the parameters you provide.

**Migration from `viz_stackedbars()`:** Simply change the function name - all parameters work the same way:
```r
# Old way (still works, shows deprecation notice)
viz_stackedbars(data, x_vars = c("q1", "q2", "q3"))

# New preferred way
viz_stackedbar(data, x_vars = c("q1", "q2", "q3"))
```

The `viz_stackedbars()` function is soft-deprecated and will continue to work, but we recommend using `viz_stackedbar()` for all new code.

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

### Error Bars Support in Bar Charts

`viz_bar()` now supports error bars for displaying uncertainty in mean values:

- New `value_var` parameter: When provided, bars show the mean of this variable per category (instead of counts)
- New `error_bars` parameter: Choose from "none" (default), "sd" (standard deviation), "se" (standard error), or "ci" (confidence interval)
- New `ci_level` parameter: Set confidence level for CI (default 0.95 for 95% CI)
- Customizable appearance via `error_bar_color` and `error_bar_width` parameters
- Works with both simple and grouped bar charts

Example usage:
```r
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

### Early Validation for Visualizations

- `preview()` now automatically validates all visualization specs before rendering, catching missing required parameters (like `stack_var` for stacked bar charts) and invalid column names early with helpful error messages
- New `validate_specs()` function for manual validation of content collections
- `print(collection, check = TRUE)` validates specs while viewing the structure

### New Visualization Types

- `viz_density()`: Create kernel density estimate plots for visualizing continuous distributions. Supports grouped densities, adjustable bandwidth, rug marks, and weighted estimation.
- `viz_boxplot()`: Create interactive box-and-whisker plots. Supports grouped boxplots, horizontal orientation, outlier display, and weighted percentiles.

### Histogram Improvements

- Fixed handling of character-numeric values (e.g., "25", "30") - now correctly converted to numeric for binning
- Improved default bin labels to show readable ranges (e.g., "18-29" instead of "[18,30)")
- Added `data_labels_enabled` parameter to control display of value labels on bars

### Data Labels Control

- Added `data_labels_enabled` parameter to `viz_histogram()`, `viz_bar()`, `viz_stackedbar()`, and `viz_stackedbars()` - allows hiding value labels on bars for cleaner visualizations
- Renamed `show_labels` to `data_labels_enabled` in `viz_treemap()` for consistency (old parameter still works with deprecation warning)
- `viz_heatmap()` already had `data_labels_enabled` - now all viz functions use the same parameter name

### Documentation

- Added new visualization vignettes: `density_vignette`, `boxplot_vignette`, `histogram_vignette`, `scatter_vignette`, `treemap_vignette`, `map_vignette`
- Interactive inputs demo and documentation in `vignette("advanced-features")`
- Improved cross-references between vignettes

## Bug Fixes
  
- Fixed Unicode/emoji rendering issues in console output
- Fixed nested tabgroup rendering in `preview()`
- Fixed parameter mapping for `stackedbars` visualization type
