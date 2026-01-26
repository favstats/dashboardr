# dashboardr Comprehensive Cheat Sheet

## The Core Pattern

```r
# 1. Create visualizations
viz <- create_viz(type = "histogram", color_palette = c("#3498DB"), ...) %>%
  add_viz(x_var = "column_name", title = "Title", tabgroup = "tab_name")

# 2. Create dashboard
dashboard <- create_dashboard(title = "My Dashboard", output_dir = "folder") %>%
  apply_theme(theme_modern()) %>%
  add_page("Page Name", data = my_data, visualizations = viz)

# 3. Generate
generate_dashboard(dashboard, render = TRUE, open = "browser")
```

---

## Visualization Types

| Type | Key Parameters |
|------|----------------|
| `histogram` | `x_var`, `bins`, `bin_breaks`, `bin_labels`, `histogram_type` |
| `bar` | `x_var`, `horizontal`, `bar_type`, `group_var` |
| `stackedbar` | `x_var`, `stack_var`, `stacked_type`, `stack_breaks`, `stack_bin_labels` |
| `stackedbars` | `questions`, `question_labels`, (same stack params) |
| `timeline` | `time_var`, `response_var`, `group_var`, `chart_type`, `response_filter` |
| `heatmap` | `x_var`, `y_var`, `value_var`, `agg_fun` |
| `treemap` | `x_var`, `size_var`, `color_var` |
| `scatter` | `x_var`, `y_var`, `group_var` |

---

## Common Visualization Parameters

```r
add_viz(
  # Required
  x_var = "column",             # Variable to plot
  
  # Titles
  title = "Chart Title",
  subtitle = "Subtitle",
  
  # Organization
  tabgroup = "section/sub",     # Tab hierarchy
  title_tabset = "Tab Label",   # Custom tab name
  
  # Data handling
  filter = ~ column == "val",   # Data filter (formula!)
  weight_var = "weights",       # Survey weights
  drop_na_vars = TRUE,          # Remove NA rows
  
  # Styling
  color_palette = c("#...", "#..."),
  x_label = "X Axis Label",
  y_label = "Y Axis Label"
)
```

---

## Tabgroups

```r
# Single level
tabgroup = "demographics"

# Nested (use / for hierarchy)
tabgroup = "analysis/demographics/age"
tabgroup = "survey/wave1/questions"

# Custom labels with icons
set_tabgroup_labels(list(
  demographics = "{{< iconify ph:users-fill >}} Demographics",
  feedback = "{{< iconify ph:heart-fill >}} Feedback"
))
```

---

## Filters

```r
# Single condition
filter = ~ department == "Sales"
filter = ~ age > 30
filter = ~ year >= 2020

# Multiple conditions (AND)
filter = ~ department == "Sales" & age > 30

# Multiple values (OR using %in%)
filter = ~ department %in% c("Sales", "Marketing")

# Complex
filter = ~ (age >= 18 & age <= 35) | senior == TRUE
```

**⚠️ Always use `~` before the condition!**

---

## Histogram Specific

```r
add_viz(
  type = "histogram",
  x_var = "age",
  bins = 20,                     # Number of bins
  histogram_type = "count",      # "count" or "percent"
  
  # Custom binning
  bin_breaks = c(18, 30, 45, 60, Inf),
  bin_labels = c("18-29", "30-44", "45-59", "60+")
  # Note: labels must be length(breaks) - 1
)
```

---

## Bar Chart Specific

```r
add_viz(
  type = "bar",
  x_var = "category",
  horizontal = TRUE,             # Horizontal bars
  bar_type = "percent",          # "count" or "percent"
  group_var = "wave"             # For grouped bars
)
```

---

## Stacked Bar Specific

```r
add_viz(
  type = "stackedbar",
  x_var = "department",          # Categories
  stack_var = "satisfaction",    # What to stack
  stacked_type = "percent",      # "percent" or "counts"
  horizontal = TRUE,
  stack_breaks = c(0.5, 1.5, 2.5, 3.5, 4.5, 5.5),
  stack_bin_labels = c("1", "2", "3", "4", "5"),
  color_palette = c("#E74C3C", "#E67E22", "#F1C40F", "#2ECC71", "#27AE60")
)
```

---

## Stacked Bars (Multiple Questions)

```r
add_viz(
  type = "stackedbars",
  questions = c("q1", "q2", "q3"),
  question_labels = c("Trust", "Value", "Recommend"),
  stacked_type = "percent",
  horizontal = TRUE,
  stack_breaks = c(0.5, 1.5, 2.5, 3.5, 4.5, 5.5),
  stack_bin_labels = c("SD", "D", "N", "A", "SA")
)
```

---

## Timeline Specific

```r
add_viz(
  type = "timeline",
  time_var = "year",
  response_var = "satisfaction",
  group_var = "department",       # Multiple lines
  chart_type = "line",            # "line", "area", "stacked_area"
  
  # Response filtering
  response_filter = c(4, 5),
  response_filter_combine = TRUE,
  response_filter_label = "High Satisfaction",
  
  # Time binning
  time_breaks = c(1970, 1980, 1990, 2000),
  time_bin_labels = c("1970s", "1980s", "1990s")
)
```

---

## Dashboard Configuration

```r
create_dashboard(
  # Required
  title = "Dashboard Title",
  output_dir = "output_folder",
  
  # Styling
  theme = "flatly",               # Bootswatch theme
  tabset_theme = "modern",        # Tab style
  tabset_colors = list(
    active_bg = "#3498DB",
    active_text = "#FFFFFF"
  ),
  
  # Features
  search = TRUE,
  breadcrumbs = TRUE,
  page_navigation = TRUE,
  back_to_top = TRUE,
  
  # Metadata
  author = "Name",
  description = "Description",
  date = "2024-01-15",
  page_footer = "© 2024 Org",
  
  # Social
  github = "https://github.com/...",
  twitter = "https://twitter.com/...",
  
  # Analytics
  plausible = "yourdomain.com"
)
```

---

## Page Options

```r
add_page(
  name = "Page Name",
  data = my_data,                  # Attach data
  visualizations = viz,            # Attach charts
  
  # Appearance
  icon = "ph:chart-line",
  navbar_align = "right",
  is_landing_page = TRUE,
  
  # Performance
  overlay = TRUE,
  overlay_theme = "glass",         # "glass", "light", "dark"
  overlay_duration = 1.5,
  lazy_load_charts = TRUE,
  lazy_load_tabs = TRUE,
  
  # Content
  text = md_text(...)
)
```

---

## Themes

### Built-in Theme Functions

```r
apply_theme(theme_modern())       # Tech look (blue default)
apply_theme(theme_modern("purple"))
apply_theme(theme_modern("green"))
apply_theme(theme_modern("orange"))
apply_theme(theme_modern("white"))

apply_theme(theme_academic())     # Clean academic
apply_theme(theme_academic(accent_color = "#8B0000"))

apply_theme(theme_clean())        # Ultra-minimal
apply_theme(theme_ascor())        # UvA/ASCoR branding
apply_theme(theme_uva())          # Same as ascor
```

### Override Parameters

```r
apply_theme(
  theme_modern(),
  mainfont = "Inter",
  fontsize = "18px",
  fontcolor = "#1f2937",
  navbar_bg_color = "#8B0000",
  navbar_text_color = "#FFFFFF",
  linkcolor = "#3498DB",
  max_width = "1400px",
  margin_left = "3rem"
)
```

---

## Content Types

| Function | Purpose | Example |
|----------|---------|---------|
| `add_viz()` | Visualization | `add_viz(type = "bar", x_var = "x")` |
| `add_text()` | Markdown text | `add_text("# Heading", "", "Paragraph")` |
| `add_callout()` | Note/tip/warning | `add_callout("Text", type = "note")` |
| `add_image()` | Image | `add_image(src = "img.png", alt = "desc")` |
| `add_accordion()` | Collapsible | `add_accordion("Title", text = "Content")` |
| `add_card()` | Card box | `add_card(text = "Content", title = "Title")` |
| `add_value_box()` | KPI metric | See below |
| `add_spacer()` | Vertical space | `add_spacer(height = "2rem")` |
| `add_divider()` | Horizontal line | `add_divider()` |
| `add_code()` | Code block | `add_code("print(x)", language = "r")` |
| `add_quote()` | Blockquote | `add_quote("Quote", attribution = "Author")` |
| `add_table()` | Data frame | `add_table(df)` |
| `add_gt()` | GT table | `add_gt(gt_object)` |
| `add_DT()` | DT datatable | `add_DT(df)` |
| `add_html()` | Raw HTML | `add_html("<div>...</div>")` |

---

## Value Boxes

```r
content <- create_content() %>%
  add_value_box_row() %>%
    add_value_box(
      title = "Metric Name",
      value = "1,234",
      logo_text = "📊",
      bg_color = "#3498DB"
    ) %>%
    add_value_box(
      title = "Another",
      value = "85%",
      logo_text = "📈",
      bg_color = "#27AE60"
    ) %>%
  end_value_box_row()
```

---

## Interactive Inputs

```r
content <- create_content() %>%
  add_input_row(style = "boxed", align = "center") %>%
    add_input(
      input_id = "my_filter",
      label = "Select Options",
      type = "select_multiple",    # See types below
      filter_var = "column_name",  # Must match group_var
      options = c("A", "B", "C"),
      default_selected = c("A", "B"),
      width = "300px"
    ) %>%
  end_input_row()
```

### Input Types

| Type | Description |
|------|-------------|
| `select_multiple` | Multi-select dropdown |
| `select_single` | Single-select dropdown |
| `checkbox` | Checkbox group |
| `radio` | Radio buttons |
| `switch` | Toggle switch |
| `slider` | Range slider |
| `text` | Text input |
| `button_group` | Segmented buttons |

### Switch for Toggle Series

```r
add_input(
  input_id = "show_avg",
  label = "Show Average",
  type = "switch",
  filter_var = "group",
  toggle_series = "Average",    # Series name to toggle
  override = TRUE,              # Don't let other filters affect it
  value = TRUE                  # Start ON
)
```

### Slider with Custom Labels

```r
add_input(
  input_id = "year",
  type = "slider",
  filter_var = "year_num",
  min = 1, max = 5, step = 1, value = 1,
  labels = c("2020", "2021", "2022", "2023", "2024")
)
```

---

## Combining Visualizations

```r
# Using + operator
combined <- viz1 + viz2 + viz3

# Using combine_viz()
combined <- viz1 %>% 
  combine_viz(viz2) %>%
  combine_viz(viz3)

# With pagination (page breaks)
combined <- viz1 %>%
  combine_viz(viz2) %>%
  add_pagination() %>%
  combine_viz(viz3)
```

---

## Vectorized Creation

```r
viz <- create_viz(type = "bar") %>%
  add_vizzes(
    x_var = paste0("q", 1:10),
    title = paste("Question", 1:10),
    .tabgroup_template = "survey/{title}"
  )
# Creates 10 visualizations at once!
```

---

## Icons

### Format: `"set:icon-name"`

**Popular Sets:**
- Phosphor (`ph:`): `ph:house-fill`, `ph:chart-bar-fill`, `ph:users-fill`
- Bootstrap (`bi:`): `bi:graph-up`, `bi:people-fill`
- Font Awesome (`fa:`): `fa:chart-bar`, `fa:users`
- Material Design (`mdi:`): `mdi:chart-line`

**In code:**
```r
# Page icons
add_page("Home", icon = "ph:house-fill")

# In text
md_text("## Features {{< iconify ph:sparkle-fill >}}")

# In tab labels
set_tabgroup_labels(list(
  overview = "{{< iconify ph:chart-bar-fill >}} Overview"
))
```

**Browse:** https://icon-sets.iconify.design/

---

## md_text() Helper

```r
text = md_text(
  "# Heading",
  "",                              # Blank line = paragraph break
  "Paragraph with **bold** and *italic*.",
  "",
  "## Subheading",
  "",
  "- Bullet 1",
  "- Bullet 2",
  "",
  "1. Numbered",
  "2. List",
  "",
  "[Link](https://...)",
  "",
  "{{< iconify ph:check-circle-fill >}} With icon"
)
```

---

## Publishing

```r
# First time (creates repo, enables GitHub Pages)
publish_dashboard(message = "Initial commit")

# Updates
generate_dashboard(dashboard, render = TRUE)
update_dashboard(message = "Updated charts")
```

**Your URL:** `https://USERNAME.github.io/REPO-NAME/`

---

## Debugging Checklist

| Problem | Solution |
|---------|----------|
| Variable not found | Check `names(data)` matches `x_var` |
| Filter not working | Use `~ condition` syntax |
| Tabs in wrong order | Reorder `add_viz()` calls |
| NA values breaking charts | Use `drop_na_vars = TRUE` |
| Wrong number of bin labels | `length(labels) = length(breaks) - 1` |
| Dashboard not rendering | Check Quarto installed: `quarto --version` |

### Always Print!
```r
print(viz)        # See visualization structure
print(dashboard)  # See dashboard structure
```

---

## Quick Reference URLs

- Package docs: https://favstats.github.io/dashboardr/
- Icons: https://icon-sets.iconify.design/
- Bootswatch themes: https://bootswatch.com/
- Color palettes: https://colorbrewer2.org/
- Function help: `?create_dashboard`, `?add_viz`
