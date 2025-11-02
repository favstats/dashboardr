# Getting Started with dashboardr

## Introduction: A Grammar of Dashboards

Just as `ggplot2` revolutionized data visualization by providing a
**grammar of graphics**, `dashboardr` provides a **grammar of
dashboards** for organizing and presenting your analyses.

### What is a Grammar?

A grammar provides:

- **Building blocks** - Fundamental components you can combine
- **Composition rules** - How components fit together
- **Layering** - Build complex structures from simple pieces
- **Consistency** - Predictable behavior across contexts

### dashboardr’s Grammar

`dashboardr` gives you a grammar with these core components:

1.  **Data** - What you’re visualizing
2.  **Visualizations** - How you show it (histograms, timelines, etc.)
3.  **Hierarchy** - How you organize it (automatic nesting via
    tabgroups)
4.  **Layout** - How you arrange it (pages, cards, rows)
5.  **Navigation** - How users explore it (navbar, sidebar, tabs)
6.  **Styling** - How it looks (themes, colors, icons)

By combining these elements through a **fluent piping interface**, you
can build complex dashboards that are both powerful and maintainable.

``` r
library(dashboardr)
#> Error in get(paste0(generic, ".", class), envir = get_method_env()) : 
#>   object 'type_sum.accel' not found
library(dplyr)
```

## Installation

``` r
# Install from GitHub
# devtools::install_github("yourusername/dashboardr")
```

## The Power of Print: Visualizing Structure

**One of dashboardr’s unique features:** When you print a visualization
object, it shows you the **tree structure** it will create. This makes
the hierarchy visible and debuggable!

Let’s see this in action:

``` r
# Create some sample data
survey_data <- data.frame(
  age = sample(18:80, 300, replace = TRUE),
  income = rnorm(300, mean = 50000, sd = 15000),
  satisfaction = sample(1:5, 300, replace = TRUE),
  department = sample(c("Sales", "Engineering", "Marketing"), 300, replace = TRUE),
  wave = sample(1:2, 300, replace = TRUE)
)

# Create a simple visualization collection
viz <- create_viz(type = "histogram") %>%
  add_viz(
    x_var = "age",
    tabgroup = "demographics",
    title = "Age Distribution"
  ) %>%
  add_viz(
    x_var = "income",
    tabgroup = "demographics",
    title = "Income Distribution"
  ) %>%
  add_viz(
    x_var = "satisfaction",
    tabgroup = "feedback",
    title = "Satisfaction Scores"
  )

# Print it to see the tree structure!
print(viz)
#> 
#> ╔══════════════════════════════════════════════════════════════════════════
#> ║ 📊 VISUALIZATION COLLECTION
#> ╠══════════════════════════════════════════════════════════════════════════
#> ║ Total visualizations: 3
#> ║
#> ║ STRUCTURE:
#> ║ ├─ 📁 demographics
#> ║ │  ├─ 📉 HISTOGRAM: Age Distribution
#> ║ │  └─ 📉 HISTOGRAM: Income Distribution
#> ║ └─ 📁 feedback
#> ║    └─ 📉 HISTOGRAM: Satisfaction Scores
#> ╚══════════════════════════════════════════════════════════════════════════
```

**See the hierarchy?** dashboardr automatically organized your
visualizations into a tree based on the `tabgroup` parameter. This tree
determines the tab structure in your final dashboard.

### Nested Hierarchies

You can create deeper nesting using `/` in tabgroup paths:

``` r
# Create nested structure
nested_viz <- create_viz(type = "histogram") %>%
  add_viz(
    x_var = "age",
    tabgroup = "analysis/demographics/age",
    title = "Age"
  ) %>%
  add_viz(
    x_var = "income",
    tabgroup = "analysis/demographics/income",
    title = "Income"
  ) %>%
  add_viz(
    x_var = "satisfaction",
    tabgroup = "analysis/feedback/overall",
    title = "Overall Satisfaction"
  )

# Print to see the nested tree!
print(nested_viz)
#> 
#> ╔══════════════════════════════════════════════════════════════════════════
#> ║ 📊 VISUALIZATION COLLECTION
#> ╠══════════════════════════════════════════════════════════════════════════
#> ║ Total visualizations: 3
#> ║
#> ║ STRUCTURE:
#> ║ └─ 📁 analysis
#> ║    ├─ 📁 demographics
#> ║    │  ├─ 📁 age
#> ║    │  │  └─ 📉 HISTOGRAM: Age
#> ║    │  └─ 📁 income
#> ║    │     └─ 📉 HISTOGRAM: Income
#> ║    └─ 📁 feedback
#> ║       └─ 📁 overall
#> ║          └─ 📉 HISTOGRAM: Overall Satisfaction
#> ╚══════════════════════════════════════════════════════════════════════════
```

**The tree shows exactly what your dashboard will look like!** Each
level becomes a tab, automatically organized.

## Core Workflow

Creating a dashboard involves three steps:

1.  **Create visualizations** with `create_viz() %>% add_viz()`
2.  **Build dashboard project** with `create_dashboard() %>% add_page()`
3.  **Generate output** with
    [`generate_dashboard()`](https://favstats.github.io/dashboardr/reference/generate_dashboard.md)

### Step 1: Create Visualizations

``` r
# Use defaults to avoid repetition
my_viz <- create_viz(
  type = "histogram",           # Default type
  color_palette = c("#3498DB"),  # Default color
  bins = 30                      # Default bins
) %>%
  add_viz(
    x_var = "age",
    title = "Age Distribution",
    tabgroup = "overview"
  ) %>%
  add_viz(
    x_var = "income",
    title = "Income Distribution",
    tabgroup = "overview",
    bins = 50  # Override default bins
  )

# See the structure
print(my_viz)
#> 
#> ╔══════════════════════════════════════════════════════════════════════════
#> ║ 📊 VISUALIZATION COLLECTION
#> ╠══════════════════════════════════════════════════════════════════════════
#> ║ Total visualizations: 2
#> ║
#> ║ STRUCTURE:
#> ║ └─ 📁 overview
#> ║    ├─ 📉 HISTOGRAM: Age Distribution
#> ║    └─ 📉 HISTOGRAM: Income Distribution
#> ╚══════════════════════════════════════════════════════════════════════════
```

### Step 2: Build Dashboard

``` r
dashboard <- create_dashboard(
  title = "Employee Survey Dashboard",
  output_dir = "my_first_dashboard",
  tabset_theme = "modern"
) %>%
  add_page(
    "Home",
    text = md_text(
      "# Welcome!",
      "",
      "This dashboard presents employee survey results.",
      "",
      "Navigate using the tabs above to explore different analyses."
    ),
    is_landing_page = TRUE
  ) %>%
  add_page(
    "Analysis",
    data = survey_data,
    visualizations = my_viz,
    icon = "ph:chart-line"
  )

# Print to see dashboard structure
print(dashboard)
```

### Step 3: Generate

``` r
# Generate without rendering (faster for development)
generate_dashboard(dashboard, render = FALSE)

# Generate and open in browser when ready
generate_dashboard(dashboard, render = TRUE, open = "browser")
```

## Composing Visualizations: The + Operator

You can combine visualization collections using the `+` operator (like
ggplot2!):

``` r
# Create separate collections
demographics <- create_viz(type = "histogram") %>%
  add_viz(x_var = "age", title = "Age", tabgroup = "demographics")

feedback <- create_viz(type = "histogram") %>%
  add_viz(x_var = "satisfaction", title = "Satisfaction", tabgroup = "feedback")

# Combine them!
combined <- demographics + feedback

print(combined)
#> 
#> ╔══════════════════════════════════════════════════════════════════════════
#> ║ 📊 VISUALIZATION COLLECTION
#> ╠══════════════════════════════════════════════════════════════════════════
#> ║ Total visualizations: 2
#> ║
#> ║ STRUCTURE:
#> ║ ├─ 📁 demographics
#> ║ │  └─ 📉 HISTOGRAM: Age
#> ║ └─ 📁 feedback
#> ║    └─ 📉 HISTOGRAM: Satisfaction
#> ╚══════════════════════════════════════════════════════════════════════════
```

This makes it easy to organize complex dashboards into logical modules.

## Defaults and Overrides

Set common parameters once, override when needed:

``` r
# Set defaults that apply to all visualizations
viz_with_defaults <- create_viz(
  type = "histogram",
  color_palette = c("#E74C3C"),  # Default: red
  bins = 20,                      # Default: 20 bins
  title_align = "center"          # Default: centered titles
) %>%
  add_viz(
    x_var = "age",
    title = "Age (uses defaults)"
  ) %>%
  add_viz(
    x_var = "income",
    title = "Income (custom bins)",
    bins = 40,  # Override bins
    color_palette = c("#2ECC71")  # Override color
  )

print(viz_with_defaults)
#> 
#> ╔══════════════════════════════════════════════════════════════════════════
#> ║ 📊 VISUALIZATION COLLECTION
#> ╠══════════════════════════════════════════════════════════════════════════
#> ║ Total visualizations: 2
#> ║
#> ║ STRUCTURE:
#> ║ └─ 📁 (no tabgroup)
#> ║    ├─ 📉 HISTOGRAM: Age (uses defaults)
#> ║    └─ 📉 HISTOGRAM: Income (custom bins)
#> ╚══════════════════════════════════════════════════════════════════════════
```

This is especially powerful for surveys with many similar questions!

## Filter-Aware Grouping

dashboardr automatically groups visualizations by their filters:

``` r
# Create visualizations with filters
filtered_viz <- create_viz(type = "histogram") %>%
  add_viz(
    x_var = "age",
    title = "Age Distribution",
    filter = ~ wave == 1,
    tabgroup = "analysis"
  ) %>%
  add_viz(
    x_var = "age",
    title = "Age Distribution",
    filter = ~ wave == 2,
    tabgroup = "analysis"
  )

# dashboardr automatically creates "Wave 1" and "Wave 2" tabs!
print(filtered_viz)
#> 
#> ╔══════════════════════════════════════════════════════════════════════════
#> ║ 📊 VISUALIZATION COLLECTION
#> ╠══════════════════════════════════════════════════════════════════════════
#> ║ Total visualizations: 2
#> ║
#> ║ STRUCTURE:
#> ║ └─ 📁 analysis
#> ║    ├─ 📉 HISTOGRAM: Age Distribution [filtered]
#> ║    └─ 📉 HISTOGRAM: Age Distribution [filtered]
#> ╚══════════════════════════════════════════════════════════════════════════
```

See how it organized by filter? No manual grouping needed!

## Visualization Types

### Histogram

``` r
create_viz(type = "histogram") %>%
  add_viz(
    x_var = "age",
    title = "Age Distribution",
    bins = 30,
    color_palette = c("#3498DB")
  )
```

### Stacked Bar

``` r
create_viz(type = "stackedbar") %>%
  add_viz(
    x_var = "department",
    stack_var = "satisfaction",
    title = "Satisfaction by Department",
    stacked_type = "percent",  # or "counts"
    horizontal = TRUE
  )
```

### Timeline

``` r
create_viz(type = "timeline") %>%
  add_viz(
    time_var = "year",
    response_var = "score",
    title = "Trends Over Time",
    chart_type = "line",  # or "area"
    group_var = "category"  # Optional grouping
  )
```

### Bar Chart (Grouped)

``` r
create_viz(type = "bar") %>%
  add_viz(
    x_var = "department",
    group_var = "wave",
    title = "Department Sizes by Wave",
    horizontal = TRUE,
    bar_type = "percent"  # or "count"
  )
```

### Heatmap

``` r
create_viz(type = "heatmap") %>%
  add_viz(
    x_var = "department",
    y_var = "satisfaction",
    value_var = "score",
    title = "Satisfaction Heatmap",
    agg_fun = "mean"  # or "sum", "count", etc.
  )
```

## Styling and Themes

### Built-in Tabset Themes

Choose from 6 professionally designed themes:

``` r
dashboard <- create_dashboard(
  title = "Styled Dashboard",
  output_dir = "styled",
  tabset_theme = "modern"  
  # Options: modern, minimal, pills, classic, underline, segmented
)
```

**Themes:**

- **modern** - Clean, centered tabs with subtle shadows
- **minimal** - Simple, understated design
- **pills** - Rounded pill-shaped tabs
- **classic** - Traditional tab appearance
- **underline** - Bottom-underline active indicator
- **segmented** - Segmented control style

### Custom Colors

``` r
dashboard <- create_dashboard(
  title = "Custom Colors",
  output_dir = "custom",
  tabset_theme = "modern",
  tabset_colors = list(
    active_bg = "#3498DB",      # Active tab background
    active_text = "#FFFFFF",    # Active tab text
    inactive_bg = "#ECF0F1",    # Inactive tab background
    inactive_text = "#7F8C8D",  # Inactive tab text
    hover_bg = "#BDC3C7"        # Hover background
  )
)
```

### Custom Tab Labels

Add icons and custom text to your tabs:

``` r
viz <- create_viz() %>%
  add_viz(
    type = "histogram",
    x_var = "age",
    tabgroup = "demo"
  ) %>%
  set_tabgroup_labels(list(
    demo = "📊 Demographics"  # Icon + label
  ))
```

## Navigation Features

### Navbar Alignment

``` r
dashboard %>%
  add_page("Home", text = "Home", is_landing_page = TRUE) %>%
  add_page("About", text = "About", navbar_align = "right")
```

### Dropdown Menus

``` r
dashboard$navbar_sections <- list(
  navbar_menu(
    text = "Reports",
    pages = c("Monthly", "Quarterly", "Annual"),
    icon = "ph:file-text"
  )
)
```

### Sidebar Groups

For many related pages, use sidebars:

``` r
# Create sidebar group
dashboard$sidebar_groups <- list(
  sidebar_group(
    id = "analysis",
    title = "Analysis",
    pages = c("Overview", "Detailed", "Trends")
  )
)

# Link from navbar
dashboard$navbar_sections <- list(
  navbar_section(
    text = "Analysis",
    sidebar_id = "analysis",
    icon = "ph:chart-line"
  )
)
```

## Advanced Features

### Loading Overlay

Add a loading animation to pages:

``` r
add_page(
  "Analysis",
  data = large_dataset,
  visualizations = viz,
  overlay = TRUE,
  overlay_theme = "glass",  # or "light", "dark"
  overlay_text = "Loading analysis..."
)
```

### Drop NA Values

Automatically remove rows with NA values:

``` r
add_viz(
  type = "histogram",
  x_var = "age",
  drop_na_vars = TRUE  # Removes rows where age is NA
)
```

### Weighted Visualizations

Use survey weights or other weighting variables:

``` r
create_viz(
  type = "histogram",
  weight_var = "survey_weight"  # Apply weights
) %>%
  add_viz(x_var = "age", title = "Weighted Age Distribution")
```

### Multiple Visualizations at Once

Use
[`add_vizzes()`](https://favstats.github.io/dashboardr/reference/add_vizzes.md)
to expand vector parameters:

``` r
questions <- c("q1", "q2", "q3")
labels <- c("Question 1", "Question 2", "Question 3")

viz <- create_viz(type = "stackedbar") %>%
  add_vizzes(
    x_var = questions,  # Expands to 3 visualizations
    title = labels,
    tabgroup = "survey"
  )

# Creates one viz for each question!
print(viz)
```

## Performance Tips

For faster iteration during development:

``` r
# Skip rendering during development (just generate QMD files)
generate_dashboard(dashboard, render = FALSE)

# Only render when you want to see the final HTML
generate_dashboard(dashboard, render = TRUE, open = "browser")
```

Quarto’s internal caching makes subsequent renders faster automatically.

## Helpful Error Messages

`dashboardr` provides clear error messages with suggestions:

### Typo in Visualization Type

``` r
# Oops, typo!
add_viz(type = "histogra", x_var = "age")

# Error: Unknown type 'histogra'
# ℹ Did you mean 'histogram'?
# ℹ Available: histogram, bar, stackedbar, timeline, heatmap
```

### Missing Required Parameter

``` r
# Forgot x_var
create_histogram(data, title = "My Chart")

# Error: 'x_var' parameter is required
# ℹ Example: create_histogram(data, x_var = "age")
```

### Typo in Theme

``` r
# Typo in theme name
create_dashboard(..., tabset_theme = "modrn")

# Error: Unknown theme 'modrn'
# ℹ Did you mean 'modern'?
# ℹ Available: modern, minimal, pills, classic, underline, segmented
```

## Debugging Your Dashboard

### Print Everything!

The print methods show you exactly what’s being built:

``` r
# Print visualizations to see tree structure
print(my_viz)

# Print dashboard to see pages and data
print(dashboard)

# After generation, check the summary
dashboard_result <- generate_dashboard(dashboard)
# Shows: pages generated, data files, rendering time
```

### Common Issues

#### Visualization Not Showing

``` r
# Check variable names
names(my_data)

# Check for NA values
summary(my_data$x_var)

# Use drop_na_vars if needed
add_viz(x_var = "age", drop_na_vars = TRUE)
```

#### Tabs in Wrong Order

``` r
# Tabs appear in the order you call add_viz()
# To change order, change the order of add_viz() calls

# Check the structure
print(viz)  # See the tree!

# Use set_tabgroup_labels for custom names
viz %>% set_tabgroup_labels(list(
  tab1 = "First Tab",
  tab2 = "Second Tab"
))
```

## Next Steps

- **Advanced Features**: See
  [`vignette("advanced-features")`](https://favstats.github.io/dashboardr/articles/advanced-features.md)
  for complex hierarchies, multi-dataset support, and more
- **Visualization Details**: See individual vignettes for detailed
  parameters:
  - [`vignette("timeline_vignette")`](https://favstats.github.io/dashboardr/articles/timeline_vignette.md)
  - [`vignette("stackedbar_vignette")`](https://favstats.github.io/dashboardr/articles/stackedbar_vignette.md)
  - [`vignette("heatmap_vignette")`](https://favstats.github.io/dashboardr/articles/heatmap_vignette.md)
  - [`vignette("bar_vignette")`](https://favstats.github.io/dashboardr/articles/bar_vignette.md)

## The Grammar in Action

Let’s put it all together with a complete example:

``` r
# 1. DATA - What we're visualizing
data <- survey_data

# 2. VISUALIZATIONS - How we show it
viz <- create_viz(
  type = "histogram",
  color_palette = c("#3498DB")
) %>%
  add_viz(x_var = "age", tabgroup = "demographics", title = "Age") %>%
  add_viz(x_var = "income", tabgroup = "demographics", title = "Income") %>%
  add_viz(x_var = "satisfaction", tabgroup = "feedback", title = "Satisfaction")

# 3. HIERARCHY - How we organize it (automatic from tabgroups!)
print(viz)  # See the tree!

# 4. LAYOUT - How we arrange it
dashboard <- create_dashboard(
  title = "Survey Dashboard",
  output_dir = "survey_dashboard"
) %>%
  add_page("Home", text = "Welcome!", is_landing_page = TRUE) %>%
  add_page("Analysis", data = data, visualizations = viz)

# 5. STYLING - How it looks
dashboard$tabset_theme <- "modern"
dashboard$tabset_colors <- list(active_bg = "#3498DB")

# 6. GENERATE - Bring it all together
generate_dashboard(dashboard, render = TRUE, open = "browser")
```

**This is the grammar of dashboards in action!** Composable,
declarative, and powerful.

## Getting Help

``` r
# Function documentation
?create_dashboard
?add_viz
?generate_dashboard

# Package overview
help(package = "dashboardr")

# See all vignettes
vignette(package = "dashboardr")
```

------------------------------------------------------------------------

**Happy dashboard building!** 🎉

Remember: **Print your objects to see the structure!** It’s the key to
understanding how dashboardr builds your dashboards.
