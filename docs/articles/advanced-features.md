# Advanced Features in dashboardr

## Introduction

This vignette covers advanced features in `dashboardr` that enable you
to create sophisticated, data-rich dashboards with minimal code.

``` r
library(dashboardr)
library(dplyr)
```

## Defaults System

The defaults system allows you to set common parameters once and reuse
them across multiple visualizations.

### Basic Defaults

``` r
# Set defaults in create_viz()
viz <- create_viz(
  type = "histogram",
  x_var = "value",
  bins = 30,
  color = "steelblue"
) %>%
  add_viz(title = "Chart 1") %>%
  add_viz(title = "Chart 2") %>%
  add_viz(title = "Chart 3")

# All three charts inherit: type, x_var, bins, color
```

### Overriding Defaults

``` r
viz <- create_viz(
  type = "histogram",
  bins = 20,
  color = "steelblue"
) %>%
  add_viz(x_var = "age", title = "Age (default colors)") %>%
  add_viz(x_var = "income", title = "Income (custom)", color = "red", bins = 40)
```

### Complex Defaults

Perfect for survey data with multiple similar questions:

``` r
survey_viz <- create_viz(
  type = "stackedbars",
  questions = c("q1", "q2", "q3", "q4", "q5"),
  question_labels = c("Question 1", "Question 2", "Question 3", "Question 4", "Question 5"),
  stacked_type = "percent",
  horizontal = TRUE,
  stack_breaks = c(0.5, 2.5, 4.5),
  stack_bin_labels = c("Disagree", "Neutral", "Agree"),
  color_palette = c("#E74C3C", "#95A5A6", "#27AE60")
) %>%
  add_viz(title = "Wave 1", filter = ~ wave == 1) %>%
  add_viz(title = "Wave 2", filter = ~ wave == 2) %>%
  add_viz(title = "Wave 3", filter = ~ wave == 3)
```

## Filters

Apply row-level filters to individual visualizations.

### Basic Filtering

``` r
viz <- create_viz(
  type = "histogram",
  x_var = "score"
) %>%
  add_viz(title = "All Data") %>%
  add_viz(title = "High Scores Only", filter = ~ score > 75) %>%
  add_viz(title = "Recent Only", filter = ~ year >= 2020)
```

### Complex Filters

``` r
viz <- create_viz(type = "stackedbar", x_var = "question", stack_var = "response") %>%
  add_viz(
    title = "Young Adults",
    filter = ~ age >= 18 & age <= 35 & country %in% c("US", "UK", "CA")
  )
```

### Combining Filters with Defaults

``` r
viz <- create_viz(
  type = "timeline",
  time_var = "year",
  response_var = "satisfaction",
  chart_type = "line"
) %>%
  add_viz(title = "Product A", filter = ~ product == "A") %>%
  add_viz(title = "Product B", filter = ~ product == "B") %>%
  add_viz(title = "Product C", filter = ~ product == "C")
```

## Multi-Dataset Support

Work with multiple datasets in a single dashboard.

### Named Datasets

``` r
dashboard <- create_dashboard(
  title = "Multi-Dataset Dashboard",
  output_dir = "multi_data"
) %>%
  add_page(
    "Analysis",
    data = list(
      sales = sales_data,
      customers = customer_data,
      products = product_data
    ),
    visualizations = viz,
    is_landing_page = TRUE
  )
```

### Viz-Specific Datasets

``` r
viz <- create_viz() %>%
  add_viz(
    type = "histogram",
    x_var = "revenue",
    data = "sales",
    title = "Revenue Distribution"
  ) %>%
  add_viz(
    type = "bar",
    x_var = "category",
    data = "products",
    title = "Product Categories"
  ) %>%
  add_viz(
    type = "timeline",
    time_var = "date",
    response_var = "count",
    data = "customers",
    title = "Customer Growth"
  )
```

### Filters with Multi-Dataset

``` r
viz <- create_viz() %>%
  add_viz(
    type = "histogram",
    x_var = "amount",
    data = "sales",
    filter = ~ region == "North",
    title = "North Region Sales"
  ) %>%
  add_viz(
    type = "histogram",
    x_var = "amount",
    data = "sales",
    filter = ~ region == "South",
    title = "South Region Sales"
  )
```

## Vectorized Visualization Creation

Use
[`add_vizzes()`](https://favstats.github.io/dashboardr/reference/add_vizzes.md)
to create multiple similar visualizations efficiently.

### Basic Expansion

``` r
viz <- create_viz(
  type = "histogram",
  x_var = "value"
) %>%
  add_vizzes(
    title = c("Wave 1", "Wave 2", "Wave 3"),
    filter = list(~ wave == 1, ~ wave == 2, ~ wave == 3)
  )

# Creates 3 visualizations automatically!
```

### Template-Based Tabgroups

``` r
viz <- create_viz(
  type = "stackedbar",
  x_var = "question",
  stack_var = "response"
) %>%
  add_vizzes(
    title = c("Age", "Gender", "Education"),
    .tabgroup_template = "demographics/{title}",
    .title_template = "By {title}"
  )

# Creates nested tabs: demographics/Age, demographics/Gender, demographics/Education
```

### Parallel Expansion

``` r
viz <- create_viz(type = "histogram") %>%
  add_vizzes(
    x_var = c("age", "income", "satisfaction"),
    title = c("Age Distribution", "Income Levels", "Satisfaction Scores"),
    bins = c(20, 30, 15)
  )

# All vectors must be same length!
```

## Nested Tabgroups

Create hierarchical tab structures for complex dashboards.

### Two-Level Nesting

``` r
viz <- create_viz(
  type = "stackedbar",
  x_var = "question",
  stack_var = "response"
) %>%
  # Level 1: Wave
  add_viz(title = "Overview", tabgroup = "survey", filter = ~ wave == 1) %>%
  # Level 2: Demographics under Wave 1
  add_viz(title = "By Age", tabgroup = "survey/age", filter = ~ wave == 1) %>%
  add_viz(title = "By Gender", tabgroup = "survey/gender", filter = ~ wave == 1)
```

### Three-Level Nesting

``` r
viz <- create_viz(
  type = "stackedbar",
  x_var = "item",
  stack_var = "response",
  stacked_type = "percent"
) %>%
  # survey -> wave1 -> age -> item1
  add_viz(tabgroup = "survey/wave1/age/item1", filter = ~ wave == 1) %>%
  add_viz(tabgroup = "survey/wave1/age/item2", filter = ~ wave == 1) %>%
  add_viz(tabgroup = "survey/wave1/age/item3", filter = ~ wave == 1) %>%
  # survey -> wave1 -> gender -> items
  add_viz(tabgroup = "survey/wave1/gender/item1", filter = ~ wave == 1) %>%
  add_viz(tabgroup = "survey/wave1/gender/item2", filter = ~ wave == 1) %>%
  # survey -> wave2 -> age -> items
  add_viz(tabgroup = "survey/wave2/age/item1", filter = ~ wave == 2) %>%
  add_viz(tabgroup = "survey/wave2/age/item2", filter = ~ wave == 2)
```

### Custom Tab Labels

``` r
viz <- viz %>%
  set_tabgroup_labels(list(
    survey = "📊 Survey Results",
    wave1 = "Wave 1 (2023)",
    wave2 = "Wave 2 (2024)",
    age = "By Age Group",
    gender = "By Gender",
    item1 = "Question 1",
    item2 = "Question 2",
    item3 = "Question 3"
  ))
```

## Timeline-Specific Features

### Response Binning

``` r
create_viz(
  type = "timeline",
  time_var = "year",
  response_var = "score",
  response_breaks = c(0, 3, 7),
  response_bin_labels = c("Low (1-3)", "High (4-7)")
) %>%
  add_viz(title = "Score Trends")
```

### Response Filtering

``` r
# Show only high scores as a percentage of total
create_viz(
  type = "timeline",
  time_var = "year",
  response_var = "satisfaction",
  response_filter = 5:7,  # Only scores 5-7
  response_filter_combine = TRUE,
  response_filter_label = "Satisfied (5-7)"
) %>%
  add_viz(title = "Satisfaction Trends")
```

### Combined with Groups

``` r
create_viz(
  type = "timeline",
  time_var = "year",
  response_var = "score",
  group_var = "age_group",
  response_filter = 5:7,
  response_filter_combine = TRUE,
  response_filter_label = ""  # Empty = show only group names
) %>%
  add_viz(title = "High Scores by Age")
```

## Data Cleaning Features

### Automatic NA Removal

``` r
viz <- create_viz(
  type = "stackedbar",
  x_var = "question",
  stack_var = "response"
) %>%
  add_viz(
    title = "Clean Data",
    drop_na_vars = TRUE  # Removes rows with NA in question or response
  )
```

Works with all relevant variables:

``` r
# Histogram: drops NA in x_var
# Stackedbar: drops NA in x_var AND stack_var
# Timeline: drops NA in time_var, response_var, AND group_var
# Heatmap: drops NA in x_var, y_var, AND value_var
```

## Combining Collections

Merge visualization collections with
[`combine_viz()`](https://favstats.github.io/dashboardr/reference/combine_viz.md)
or `+`:

``` r
viz1 <- create_viz(type = "histogram", x_var = "age") %>%
  add_viz(title = "Age Distribution")

viz2 <- create_viz(type = "histogram", x_var = "income") %>%
  add_viz(title = "Income Distribution")

# Method 1
combined <- combine_viz(viz1, viz2)

# Method 2 (equivalent)
combined <- viz1 + viz2
```

## Real-World Example

Putting it all together:

``` r
# Survey data with multiple waves and demographics
survey_viz <- create_viz(
  type = "stackedbars",
  questions = paste0("Q", 1:10),
  question_labels = paste("Question", 1:10),
  stacked_type = "percent",
  horizontal = TRUE,
  stack_breaks = c(0.5, 2.5, 4.5),
  stack_bin_labels = c("Disagree", "Neutral", "Agree"),
  color_palette = c("#E74C3C", "#95A5A6", "#27AE60"),
  drop_na_vars = TRUE
) %>%
  # Wave 1 - Overall
  add_viz(title = "Overall", tabgroup = "survey/wave1", filter = ~ wave == 1) %>%
  # Wave 1 - By demographics
  add_vizzes(
    .tabgroup_template = "survey/wave1/{demographic}",
    demographic = c("age", "gender", "education"),
    title = c("By Age", "By Gender", "By Education")
  ) %>%
  # Wave 2 - Overall
  add_viz(title = "Overall", tabgroup = "survey/wave2", filter = ~ wave == 2) %>%
  # Wave 2 - By demographics  
  add_vizzes(
    .tabgroup_template = "survey/wave2/{demographic}",
    demographic = c("age", "gender", "education"),
    title = c("By Age", "By Gender", "By Education")
  ) %>%
  # Custom labels
  set_tabgroup_labels(list(
    survey = "📊 Survey Results",
    wave1 = "Wave 1 (January 2024)",
    wave2 = "Wave 2 (June 2024)",
    age = "Age Groups",
    gender = "Gender",
    education = "Education Level"
  ))

# Create dashboard
dashboard <- create_dashboard(
  title = "Survey Dashboard",
  output_dir = "survey_dashboard",
  tabset_theme = "modern"
) %>%
  add_page(
    "Results",
    data = survey_data,
    visualizations = survey_viz,
    is_landing_page = TRUE,
    overlay = TRUE,
    overlay_text = "Loading survey results..."
  )

generate_dashboard(dashboard)
```

## Performance Optimization

When working with large dashboards or iterating during development,
these performance features can dramatically speed up your workflow.

### Preview Mode

Generate only specific pages for rapid testing and iteration:

``` r
# Generate only one page
generate_dashboard(dashboard, preview = "Analysis")

# Generate multiple specific pages
generate_dashboard(dashboard, preview = c("Demographics", "Results"))
```

**Benefits:** - **10-50x faster** for large dashboards - Perfect for
testing changes to specific pages - Works with visualizations, data, and
all page features

**Use cases:** - Quick iteration during development - Testing
visualization tweaks - Debugging specific pages - CI/CD pipelines (test
specific pages in parallel)

### Incremental Builds

Skip regenerating unchanged pages on subsequent builds:

``` r
# First build - generates all pages
result1 <- generate_dashboard(dashboard, incremental = TRUE)

# Make changes to one page
# Second build - only regenerates changed pages
result2 <- generate_dashboard(dashboard, incremental = TRUE)

# Check what was rebuilt
result2$build_info$regenerated  # Changed pages
result2$build_info$skipped      # Unchanged pages
```

**How it works:** - Tracks content hashes of each page - Only
regenerates pages with changed content - Automatically detects changes
to data, visualizations, text, etc.

**Performance:** - First build: Normal speed - Subsequent builds: Only
changed pages (often \< 1 second!)

### Maximum Speed: Combine Both!

For the ultimate development speed, combine preview mode with
incremental builds:

``` r
# Work on a specific page with incremental optimization
generate_dashboard(dashboard, 
                  preview = "Analysis",
                  incremental = TRUE)
```

**Result:** Sub-second builds! 🚀

**Perfect for:** - Large dashboards (20+ pages) - Iterative
visualization refinement - Dashboards with expensive computations -
Quick preview/test cycles

### Performance Best Practices

``` r
# 1. Use preview mode during development
generate_dashboard(dashboard, preview = "WorkInProgress")

# 2. Enable incremental for iterative work
generate_dashboard(dashboard, incremental = TRUE)

# 3. Combine for maximum speed
generate_dashboard(dashboard, preview = "WorkInProgress", incremental = TRUE)

# 4. Full build for final output
generate_dashboard(dashboard, render = TRUE, open = "browser")
```

**Typical speed-ups:** - 5-page dashboard: ~5 seconds → ~1 second (5x) -
20-page dashboard: ~30 seconds → ~2 seconds (15x)  
- 50-page dashboard: ~2 minutes → ~5 seconds (24x)

## Advanced Navigation

Create sophisticated navigation structures with dropdown menus and
custom layouts.

### Dropdown Menus

Organize related pages into dropdown menus in the navbar:

``` r
# Create a dropdown menu
reports_menu <- navbar_menu(
  text = "Reports",
  pages = c("Monthly", "Quarterly", "Annual"),
  icon = "ph:file-text"
)

dashboard <- create_dashboard(
  title = "Business Dashboard",
  output_dir = "business_dashboard"
) %>%
  add_navbar_section(reports_menu) %>%
  add_page("Home", text = "Welcome", is_landing_page = TRUE) %>%
  add_page("Monthly", data = monthly_data, visualizations = monthly_viz) %>%
  add_page("Quarterly", data = quarterly_data, visualizations = quarterly_viz) %>%
  add_page("Annual", data = annual_data, visualizations = annual_viz)

generate_dashboard(dashboard)
```

**Multiple menus:**

``` r
# Create multiple dropdown menus
reports_menu <- navbar_menu(
  text = "Reports",
  pages = c("Monthly", "Quarterly", "Annual"),
  icon = "ph:file-text"
)

analysis_menu <- navbar_menu(
  text = "Analysis",
  pages = c("Demographics", "Trends", "Correlations"),
  icon = "ph:chart-line"
)

dashboard <- create_dashboard(...) %>%
  add_navbar_section(reports_menu) %>%
  add_navbar_section(analysis_menu) %>%
  # Add all pages...
  add_page("Monthly", ...) %>%
  add_page("Quarterly", ...) %>%
  add_page("Demographics", ...) %>%
  add_page("Trends", ...)
```

### Navbar Alignment

Control the position of pages in the navbar:

``` r
dashboard <- create_dashboard(...) %>%
  # Left-aligned pages (default)
  add_page("Home", ..., navbar_align = "left") %>%
  add_page("Analysis", ..., navbar_align = "left") %>%
  
  # Right-aligned pages
  add_page("About", ..., navbar_align = "right") %>%
  add_page("Contact", ..., navbar_align = "right")

generate_dashboard(dashboard)
```

**Typical pattern:** - Left: Main content pages (Home, Analysis,
Reports) - Right: Meta pages (About, Help, Settings)

### Loading Overlays

Add loading overlays to pages with heavy visualizations or data
processing:

``` r
dashboard <- create_dashboard(...) %>%
  add_page(
    "Heavy Analysis",
    data = large_dataset,
    visualizations = complex_viz,
    overlay = TRUE,
    overlay_theme = "glass",  # Options: light, glass, dark, accent
    overlay_text = "Loading analysis..."
  )
```

**Overlay themes:** - `"light"` - Light background (default) -
`"glass"` - Glassmorphism effect - `"dark"` - Dark background -
`"accent"` - Matches dashboard accent color

**When to use:** - Pages with 5+ visualizations - Large datasets (\>
10MB) - Complex computations - Shiny integration

### Complete Navigation Example

Combining all navigation features:

``` r
# Create dropdown menus
data_menu <- navbar_menu(
  text = "Data Views",
  pages = c("Overview", "Detailed", "Comparison"),
  icon = "ph:database"
)

# Create dashboard with advanced navigation
dashboard <- create_dashboard(
  title = "Advanced Dashboard",
  output_dir = "advanced_dashboard",
  tabset_theme = "modern"
) %>%
  # Landing page (left)
  add_page(
    "Home",
    text = "Welcome to the dashboard",
    is_landing_page = TRUE,
    navbar_align = "left"
  ) %>%
  
  # Dropdown menu pages
  add_navbar_section(data_menu) %>%
  add_page(
    "Overview",
    data = summary_data,
    visualizations = overview_viz
  ) %>%
  add_page(
    "Detailed",
    data = full_data,
    visualizations = detailed_viz,
    overlay = TRUE,
    overlay_text = "Loading detailed analysis..."
  ) %>%
  add_page(
    "Comparison",
    data = comparison_data,
    visualizations = comparison_viz
  ) %>%
  
  # Regular page (left)
  add_page(
    "Custom Analysis",
    data = custom_data,
    visualizations = custom_viz,
    navbar_align = "left"
  ) %>%
  
  # Meta pages (right)
  add_page(
    "About",
    text = "Dashboard information and methodology",
    navbar_align = "right"
  )

# Generate with performance features
generate_dashboard(dashboard, incremental = TRUE)
```

## See Also

- [`vignette("getting-started")`](https://favstats.github.io/dashboardr/articles/getting-started.md) -
  Basic dashboard creation
- [`?create_viz`](https://favstats.github.io/dashboardr/reference/create_viz.md) -
  Visualization creation
- [`?add_vizzes`](https://favstats.github.io/dashboardr/reference/add_vizzes.md) -
  Vectorized visualization creation
- [`?set_tabgroup_labels`](https://favstats.github.io/dashboardr/reference/set_tabgroup_labels.md) -
  Custom tab labels
- [`?generate_dashboard`](https://favstats.github.io/dashboardr/reference/generate_dashboard.md) -
  Generation options (preview, incremental)
- [`?navbar_menu`](https://favstats.github.io/dashboardr/reference/navbar_menu.md) -
  Dropdown menu creation
