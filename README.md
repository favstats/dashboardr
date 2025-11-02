
<!-- README.md is generated from README.Rmd. Please edit that file -->

# dashboardr <img src="man/figures/logo.svg" align="right" height="139" alt="" />

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/dashboardr)](https://CRAN.R-project.org/package=dashboardr)
<!-- badges: end -->

**dashboardr** makes it easy to create beautiful, interactive [Quarto
dashboards](https://quarto.org/docs/dashboards/) in R with minimal code.
Perfect for survey data, analytics reports, and data storytelling.

## ✨ Features

- 🎨 **6 Built-in Themes** - Modern, minimal, pills, classic, underline,
  segmented
- 📊 **Rich Visualizations** - Histograms, timelines, stacked bars,
  heatmaps, bar charts
- 🎯 **Smart Defaults** - Set parameters once, reuse everywhere
- 🔍 **Advanced Filtering** - Row-level filters for each visualization
- 📚 **Multi-Dataset Support** - Work with multiple datasets seamlessly
- 🎭 **Nested Tabgroups** - Create hierarchical tab structures
- ⚡ **Vectorized Creation** - Generate multiple visualizations
  efficiently
- 🎬 **Loading Overlays** - 4 animated themes
- 🧭 **Flexible Navigation** - Navbar menus, dropdown menus, icons
- 📱 **Responsive Design** - Works on all screen sizes

## Installation

``` r
# install.packages("pak")
pak::pak("favstats/dashboardr")
```

## Core Workflow: Data → Visualizations → Dashboard

Creating a dashboard follows a simple three-step pattern:

### Step 1: Build Visualizations

Use `create_viz()` to set shared defaults, then `add_viz()` for each chart:

```r
library(dashboardr)

# Set defaults once (type, colors, etc.)
my_viz <- create_viz(
  type = "histogram",           # All charts will be histograms
  color_palette = c("#3498DB"),  # All charts use this color
  bins = 30                      # All charts use 30 bins
) %>%
  # Add individual visualizations
  add_viz(
    x_var = "age",              # What to plot
    title = "Age Distribution",  # Chart title
    tabgroup = "overview"        # Which tab group
  ) %>%
  add_viz(
    x_var = "income",
    title = "Income Distribution",
    tabgroup = "overview",
    bins = 50  # Override: this one uses 50 bins
  )

# See what you built
print(my_viz)
#> 📊 VISUALIZATION COLLECTION
#> Total visualizations: 2
#> STRUCTURE:
#> └─ 📁 overview
#>    ├─ 📉 HISTOGRAM: Age Distribution
#>    └─ 📉 HISTOGRAM: Income Distribution
```

**Key concepts:**
- `create_viz()`: Sets defaults that apply to all visualizations
- `add_viz()`: Adds one visualization, can override any default
- `tabgroup`: Organizes visualizations into tabs (e.g., "overview", "demographics/age")
- `print()`: Shows the structure before generating

### Step 2: Build Dashboard Structure

Use `create_dashboard()` to configure, then `add_page()` for each page:

```r
dashboard <- create_dashboard(
  title = "Employee Survey Dashboard",
  output_dir = "my_first_dashboard",
  tabset_theme = "modern"  # Tab styling
) %>%
  # Landing page with text
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
  # Analysis page with data + visualizations
  add_page(
    "Analysis",
    data = survey_data,        # Your data
    visualizations = my_viz,    # The viz you created above
    icon = "ph:chart-line"      # Optional icon
  )

# See the dashboard structure
print(dashboard)
```

**Key concepts:**
- `create_dashboard()`: Sets dashboard-level options (title, theme, output location)
- `add_page()`: Adds a page to the navbar
- `md_text()`: Creates markdown text blocks (headings, paragraphs, etc.)
- `data`: Attaches your dataset to a page (available to all visualizations on that page)
- `is_landing_page`: Makes this the default page users see first

### Step 3: Generate HTML

Use `generate_dashboard()` to create the actual dashboard:

```r
# Generate QMD files only (fast, for development)
generate_dashboard(dashboard, render = FALSE)

# Generate QMD files AND render to HTML (slower, for final output)
generate_dashboard(dashboard, render = TRUE)

# Generate + render + open in browser
generate_dashboard(dashboard, render = TRUE, open = "browser")
```

**Key concepts:**
- `render = FALSE`: Only creates Quarto files (.qmd), doesn't run Quarto
- `render = TRUE`: Creates files AND renders to HTML (requires Quarto CLI)
- `open = "browser"`: Opens the dashboard in your browser after rendering

### Complete Example

```r
library(dashboardr)
library(dplyr)

# Your data
data <- mtcars %>%
  mutate(cyl_label = paste(cyl, "cylinders"))

# Step 1: Visualizations
viz <- create_viz(type = "histogram") %>%
  add_viz(x_var = "mpg", title = "MPG", tabgroup = "overview") %>%
  add_viz(x_var = "hp", title = "Horsepower", tabgroup = "overview")

# Step 2: Dashboard
dashboard <- create_dashboard(
  title = "Car Dashboard",
  output_dir = "my_dashboard"
) %>%
  add_page("Home", text = md_text("# Welcome!"), is_landing_page = TRUE) %>%
  add_page("Charts", data = data, visualizations = viz)

# Step 3: Generate
generate_dashboard(dashboard, render = TRUE, open = "browser")
```

That's it! You now have a complete interactive dashboard.

### Composing Visualizations with `+`

You can combine visualization collections using the `+` operator (like ggplot2):

```r
# Create separate collections for different topics
demographics <- create_viz(type = "histogram") %>%
  add_viz(x_var = "age", title = "Age", tabgroup = "demographics")

feedback <- create_viz(type = "histogram") %>%
  add_viz(x_var = "satisfaction", title = "Satisfaction", tabgroup = "feedback")

# Combine them!
combined <- demographics + feedback

print(combined)
#> 📊 VISUALIZATION COLLECTION
#> Total visualizations: 2
#> STRUCTURE:
#> ├─ 📁 demographics
#> │  └─ 📉 HISTOGRAM: Age
#> └─ 📁 feedback
#>    └─ 📉 HISTOGRAM: Satisfaction
```

**When to use `+`:**
- Organize complex dashboards into logical modules
- Combine visualizations from different scripts/team members
- Keep related visualizations grouped together in your code

## 🎯 Try the Live Demos!

Want to see dashboardr in action? We include two built-in demo dashboards:

### Tutorial Dashboard - Perfect for Learning

```r
# Run the tutorial dashboard (requires 'gssr' package)
tutorial_dashboard()
```

The tutorial dashboard demonstrates:

- ✅ Basic stacked bar charts and heatmaps
- ✅ Tabset grouping for organizing visualizations
- ✅ Standalone charts without tabsets
- ✅ Text-only pages
- ✅ Icons throughout

**Output:** Opens in your browser automatically!

### Showcase Dashboard - Full Feature Demo

```r
# Run the comprehensive showcase dashboard
showcase_dashboard()
```

The showcase dashboard includes:

- ✅ Multiple tabset groups (Demographics, Politics, Social Issues)
- ✅ 9 different visualizations across 5 pages
- ✅ Card layouts with images
- ✅ Mixed content pages (text + visualizations)
- ✅ All advanced features in one place

**See the full demo guide:** [Live Demos Vignette](https://favstats.github.io/dashboardr/articles/demos.html)

## Key Features

### 🎯 Smart Defaults

Set common parameters once and reuse them:

``` r
viz <- create_viz(
  type = "stackedbars",
  questions = paste0("Q", 1:5),
  stacked_type = "percent",
  horizontal = TRUE,
  color_palette = c("#E74C3C", "#95A5A6", "#27AE60")
) %>%
  add_viz(title = "Wave 1", filter = ~ wave == 1) %>%
  add_viz(title = "Wave 2", filter = ~ wave == 2) %>%
  add_viz(title = "Wave 3", filter = ~ wave == 3)
```

### ⚡ Vectorized Creation

Create multiple visualizations efficiently:

``` r
viz <- create_viz(
  type = "bar",
  horizontal = TRUE,
  bar_type = "percent"
) %>%
  add_vizzes(
    x_var = paste0("question_", 1:10),
    title = paste("Question", 1:10),
    .tabgroup_template = "survey/{title}"
  )
# Creates 10 visualizations with one call!
```

### 🎭 Nested Tabgroups

Create hierarchical structures:

``` r
viz <- create_viz(
  type = "stackedbar",
  x_var = "response",
  stack_var = "category"
) %>%
  # Wave 1 tabs
  add_viz(title = "Overall", tabgroup = "survey/wave1", filter = ~ wave == 1) %>%
  add_viz(title = "By Age", tabgroup = "survey/wave1/age", filter = ~ wave == 1) %>%
  add_viz(title = "By Gender", tabgroup = "survey/wave1/gender", filter = ~ wave == 1) %>%
  # Wave 2 tabs
  add_viz(title = "Overall", tabgroup = "survey/wave2", filter = ~ wave == 2) %>%
  add_viz(title = "By Age", tabgroup = "survey/wave2/age", filter = ~ wave == 2) %>%
  add_viz(title = "By Gender", tabgroup = "survey/wave2/gender", filter = ~ wave == 2) %>%
  # Custom labels
  set_tabgroup_labels(list(
    survey = "📊 Survey Results",
    wave1 = "Wave 1 (2024)",
    wave2 = "Wave 2 (2025)"
  ))
```

### 📚 Multi-Dataset Support

``` r
dashboard %>%
  add_page(
    "Analysis",
    data = list(
      sales = sales_data,
      customers = customer_data,
      products = product_data
    ),
    visualizations = viz
  )
```

### 🎬 Loading Overlays

``` r
dashboard %>%
  add_page(
    "Reports",
    data = large_dataset,
    visualizations = viz,
    overlay = TRUE,
    overlay_theme = "glass",
    overlay_text = "Loading reports..."
  )
```

## Visualization Types

| Function | Description | Use Case |
|----|----|----|
| `create_histogram()` | Distribution visualization | Age, income, scores |
| `create_bar()` | Grouped/clustered bars | Category comparisons |
| `create_stackedbar()` | Single stacked bar | Likert scales, compositions |
| `create_stackedbars()` | Multiple stacked bars | Multiple questions |
| `create_timeline()` | Time series | Trends over time |
| `create_heatmap()` | 2D heatmap | Correlations, matrices |

## Themes

Choose from 6 built-in themes:

- **modern** - Clean, centered tabs with subtle shadows
- **minimal** - Simple, flat design
- **pills** - Rounded pill-shaped tabs
- **classic** - Traditional tabbed interface
- **underline** - Underlined active tabs
- **segmented** - Segmented control style

``` r
dashboard <- create_dashboard(
  title = "My Dashboard",
  output_dir = "output",
  tabset_theme = "modern",
  tabset_colors = list(
    active_bg = "#3498DB",
    active_text = "#FFFFFF"
  )
)
```

## Documentation

- **Getting Started**: `vignette("getting-started")`
- **Advanced Features**: `vignette("advanced-features")`
- **Specific Visualizations**:
  - `vignette("bar_vignette")`
  - `vignette("timeline_vignette")`
  - `vignette("stackedbar_vignette")`
  - `vignette("stackedbars_vignette")`
  - `vignette("heatmap_vignette")`

## Examples

Check out the demo scripts in the package:

``` r
# View available demos
list.files(system.file("demo", package = "dashboardr"))

# Run a demo
source(system.file("demo/demo_add_vizzes_dashboard.R", package = "dashboardr"))
```

## Real-World Use Cases

- 📊 **Survey Analysis** - Visualize Likert-scale responses across waves
- 📈 **Business Analytics** - Track KPIs over time by department
- 🎓 **Academic Research** - Present study results interactively
- 💼 **Consulting Reports** - Create client-ready dashboards
- 📱 **Data Journalism** - Build interactive data stories

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see [LICENSE.md](LICENSE.md) for details.

## Citation

``` r
citation("dashboardr")
```
