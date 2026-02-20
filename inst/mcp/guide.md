# dashboardr API Guide

Build interactive HTML dashboards from R. dashboardr generates Quarto
projects with Highcharts visualisations, interactive filters, and
conditional visibility — all without writing JavaScript.

## Quick Start

```r
library(dashboardr)
library(dplyr)

data <- mtcars %>% mutate(cyl_label = paste(cyl, "cylinders"))

# LAYER 1: Content — what to show
charts <- create_content(data = data, type = "bar") %>%
  add_viz(x_var = "cyl_label", title = "Cylinders", tabgroup = "overview") %>%
  add_viz(x_var = "gear", title = "Gears", tabgroup = "overview")

# LAYER 2: Page — where content lives
home <- create_page("Home", is_landing_page = TRUE) %>%
  add_text("# Welcome", "", "Explore the mtcars dataset.")

analysis <- create_page("Analysis", data = data) %>%
  add_content(charts)

# LAYER 3: Dashboard — final output
create_dashboard(title = "Car Explorer", output_dir = "my_dashboard") %>%
  add_pages(home, analysis) %>%
  generate_dashboard(render = TRUE, open = "browser")
```

## Three-Layer Architecture

Everything in dashboardr follows three composable layers:

```
Content  →  Page  →  Dashboard
(what)      (where)   (output)
```

### Layer 1: Content (`create_content` / `create_viz`)

A content collection holds one or more visualisations, tables, or text
blocks that share a dataset and chart type.

```r
charts <- create_content(data = my_data, type = "bar") %>%
  add_viz(x_var = "category", title = "Chart 1", tabgroup = "tab1") %>%
  add_viz(x_var = "group", title = "Chart 2", tabgroup = "tab1")
```

- `type` maps to a `viz_*()` function: "bar" → `viz_bar()`, "stackedbar" → `viz_stackedbar()`, etc.
- `tabgroup` groups charts into tabbed panels (same tabgroup = same panel).
- Parameters from the `viz_*()` function can be passed through `add_viz()`.

### Layer 2: Page (`create_page`)

Pages hold content collections, inputs, text, metrics, and layout elements.

```r
page <- create_page("Analysis", data = data) %>%
  add_input(input_id = "filter1", label = "Filter", choices = c("A", "B")) %>%
  add_content(charts) %>%
  add_text("## Notes", "", "Some explanatory text.")
```

- `is_landing_page = TRUE` makes a text-only landing page (no data needed).
- `add_sidebar()` / `end_sidebar()` puts inputs in a sidebar panel.

### Layer 3: Dashboard (`create_dashboard`)

The dashboard object collects pages, sets theme, and generates files.

```r
create_dashboard(
  title = "My Dashboard",
  output_dir = "output_folder",
  theme = "flatly",
  custom_css = "custom.css"
) %>%
  add_pages(page1, page2, page3) %>%
  generate_dashboard(render = TRUE)
```

## Chart Types

All chart types use the same pattern: `create_content(data, type = "...") %>% add_viz(...)`.

| Type | Function | Use Case | Key Params |
|------|----------|----------|------------|
| `bar` | `viz_bar()` | Counts, %, means | `x_var`, `group_var`, `bar_type`, `horizontal` |
| `stackedbar` | `viz_stackedbar()` | Likert scales, crosstabs | `x_var`, `stack_var` or `x_vars`, `percent` |
| `histogram` | `viz_histogram()` | Distributions | `x_var`, `bins`, `group_var` |
| `density` | `viz_density()` | Kernel density | `x_var`, `group_var` |
| `boxplot` | `viz_boxplot()` | Distribution comparison | `x_var`, `y_var`, `group_var` |
| `timeline` | `viz_timeline()` | Time series | `x_var`, `y_var`, `group_var` |
| `scatter` | `viz_scatter()` | Relationships | `x_var`, `y_var`, `group_var`, `size_var` |
| `heatmap` | `viz_heatmap()` | Matrices, correlations | `x_var`, `y_var`, `value_var` |
| `pie` | `viz_pie()` | Proportions | `x_var`, `donut` |
| `treemap` | `viz_treemap()` | Hierarchical data | `x_var`, `value_var`, `group_var` |
| `lollipop` | `viz_lollipop()` | Ranked values | `x_var`, `value_var`, `sort_by_value` |
| `dumbbell` | `viz_dumbbell()` | Two-point comparison | `x_var`, `value_var`, `group_var` |
| `funnel` | `viz_funnel()` | Sequential stages | `x_var`, `value_var` |
| `waffle` | `viz_waffle()` | Square pie charts | `x_var`, `value_var` |
| `sankey` | `viz_sankey()` | Flow diagrams | `from_var`, `to_var`, `value_var` |
| `map` | `viz_map()` | Choropleth maps | `location_var`, `value_var`, `map_type` |
| `gauge` | `viz_gauge()` | KPI gauges | `value`, `min`, `max` |

## Interactive Inputs and Filtering

### Client-side data filtering

Inputs filter chart data when the input's `input_id` matches a `filter_var`
on a chart, **and** that `filter_var` is an actual column in the data.

```r
# Chart declares it can be filtered by the "trans" column
charts <- create_content(data = data, type = "bar") %>%
  add_viz(x_var = "cyl", title = "Cylinders", filter_var = "trans")

# Input with matching input_id filters the chart data
page <- create_page("Cars", data = data) %>%
  add_input(input_id = "trans", label = "Transmission",
            choices = c("Automatic", "Manual"), type = "dropdown") %>%
  add_content(charts)
```

### Input types

- `type = "dropdown"` — dropdown select
- `type = "radio"` — radio buttons
- `type = "button_group"` — horizontal button group
- `type = "checkbox"` — checkboxes (multi-select)

### Input layout

```r
# Inline inputs (horizontal, centered)
add_input(..., inline = TRUE, group_align = "center", width = "100%")

# Input rows (multiple inputs side by side)
page %>%
  add_input_row() %>%
    add_input(input_id = "a", ...) %>%
    add_input(input_id = "b", ...) %>%
  end_input_row()

# add_all = TRUE prepends an "All" option (shows unfiltered data)
add_input(input_id = "age", choices = c("Young", "Old"), add_all = TRUE)
```

### Reset button

```r
page %>% add_reset_button()
```

## Conditional Visibility (show_when)

Show or hide content based on input selections. Uses R formulas that are
evaluated client-side as JavaScript.

```r
# Show chart only when topic == "economy"
add_viz(x_var = "q1", title = "Economy", show_when = ~ topic == "economy")

# Compound AND
add_viz(..., show_when = ~ topic == "economy" & view == "wave1")

# Compound OR
add_viz(..., show_when = ~ topic == "economy" | topic == "health")

# Also works on inputs
add_input(..., show_when = ~ demo == "age")
```

**Key rule**: `show_when` references the `filter_var` name, not the `input_id`.

When `filter_var` does NOT match a data column, it creates a JS variable
for `show_when` conditions only (no data filtering). This is useful for
topic selectors and view toggles.

## Sidebar Layout

```r
page <- create_page("Analysis", data = data) %>%
  add_sidebar() %>%
    add_input(input_id = "filter1", ...) %>%
    add_reset_button() %>%
  end_sidebar() %>%
  add_content(charts)
```

## Value Boxes / Metrics

```r
page %>%
  add_value_box_row() %>%
    add_value_box(title = "Total", value = 100, icon = "mdi:chart-bar",
                  color = "#2196F3") %>%
    add_value_box(title = "Average", value = 42.5, icon = "mdi:target",
                  color = "#4CAF50") %>%
  end_value_box_row()
```

## Custom Layout

```r
page %>%
  add_layout_column(width = 8) %>%
    add_content(main_charts) %>%
  end_layout_column() %>%
  add_layout_column(width = 4) %>%
    add_text("## Info") %>%
  end_layout_column()
```

Column widths use Bootstrap's 12-column grid (e.g., 8 + 4 = 12).

## Tables

```r
# Simple HTML table
create_content(data = df) %>% add_table(title = "Data")

# Interactive reactable
create_content(data = df) %>% add_reactable(title = "Interactive")

# Publication-quality gt
create_content(data = df) %>% add_gt(title = "Formatted")

# DataTables (DT)
create_content(data = df) %>% add_DT(title = "Searchable")
```

## Themes

```r
create_dashboard(..., theme = "flatly")                 # Bootswatch theme
create_dashboard(...) %>% apply_theme(theme_modern())    # Built-in theme
create_dashboard(...) %>% apply_theme(theme_clean())     # Minimal theme
create_dashboard(...) %>% apply_theme(theme_academic())  # Professional
```

Custom CSS via `custom_css = "my_styles.css"` in `create_dashboard()`.

## Modals

```r
content <- create_content(data = data, type = "bar") %>%
  add_viz(x_var = "category", title = "Chart") %>%
  add_modal(id = "info", title = "About", body = "Methodology details...")
```

## Multi-Page Navigation

```r
create_dashboard(title = "My App", output_dir = "output") %>%
  add_pages(
    create_page("Home", is_landing_page = TRUE) %>% add_text("# Welcome"),
    create_page("Analysis", data = data) %>% add_content(charts),
    create_page("About") %>% add_text("# About this project")
  ) %>%
  generate_dashboard(render = TRUE)
```

Pages appear as navbar tabs. Use `navbar_section()` and `navbar_menu()`
for grouped/dropdown navigation.

## Function Index

### Dashboard
- `create_dashboard()` — Create dashboard project
- `add_page()` / `add_pages()` — Add page(s) to dashboard
- `generate_dashboard()` — Generate files and optionally render
- `publish_dashboard()` / `update_dashboard()` — GitHub Pages publishing

### Page
- `create_page()` — Create a page
- `add_content()` — Add content collection(s)
- `add_text()` — Add markdown text
- `add_callout()` — Add callout box
- `add_pagination()` — Add pagination break

### Content
- `create_content()` / `create_viz()` — Create content collection
- `add_viz()` / `add_vizzes()` — Add visualisation(s)
- `combine_content()` — Combine collections
- `preview()` — Preview any dashboardr object
- `set_tabgroup_labels()` — Set tab display labels

### Inputs
- `add_input()` — Add interactive filter
- `add_input_row()` / `end_input_row()` — Group inputs horizontally
- `add_reset_button()` — Reset all filters
- `add_linked_inputs()` — Cascading parent-child dropdowns
- `show_when_open()` / `show_when_close()` — Conditional wrappers
- `add_sidebar()` / `end_sidebar()` — Sidebar panel

### Layout
- `add_layout_column()` / `end_layout_column()` — Manual columns
- `add_layout_row()` / `end_layout_row()` — Manual rows
- `navbar_section()` / `navbar_menu()` — Navigation groups

### Tables
- `add_table()` — HTML table
- `add_gt()` — gt table
- `add_reactable()` — reactable table
- `add_DT()` — DT datatable

### Metrics
- `add_value_box()` / `add_value_box_row()` — Value boxes
- `add_metric()` — Metric box
- `add_sparkline_card()` — Sparkline metric

### Content Blocks
- `add_image()`, `add_divider()`, `add_code()`, `add_card()`
- `add_accordion()`, `add_spacer()`, `add_html()`, `add_quote()`, `add_badge()`

### Embeds
- `add_widget()`, `add_plotly()`, `add_leaflet()`, `add_iframe()`, `add_video()`

### Themes
- `apply_theme()`, `theme_modern()`, `theme_clean()`, `theme_academic()`

## Tips

- Use `tabgroup` to group charts into tabs within a page.
- Set `width = "100%"` on inline inputs — the default 300px is too narrow.
- `filter_var` matching a data column = actual filtering; not matching = show_when variable only.
- `show_when` must reference the `filter_var` name, not the `input_id`.
- Use `add_all = TRUE` on filter inputs to include an "All" default option.
- `preview()` works on content, pages, and dashboards for quick testing.
