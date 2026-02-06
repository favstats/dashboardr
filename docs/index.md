# dashboardr

**dashboardr** lets you build interactive HTML dashboards from R using a
simple, composable grammar. Think of it like building with Lego blocks:

- **No web development needed** - just R code
- **Interactive charts** powered by Highcharts
- **Beautiful themes** from Bootswatch
- **Flexible layouts** with tabs, pages, and navigation

## Installation

``` r
# install.packages("pak")
pak::pak("favstats/dashboardr")
```

### Optional: Install gssr for tutorials

The tutorials and demos use the `gssr` package (General Social Survey
data). Install it from r-universe:

``` r
install.packages('gssr', repos = c('https://kjhealy.r-universe.dev', 'https://cloud.r-project.org'))

# Also recommended: install gssrdoc for documentation
install.packages('gssrdoc', repos = c('https://kjhealy.r-universe.dev', 'https://cloud.r-project.org'))
```

## The Three Layers

Just as ggplot2 builds plots from layers, dashboardr builds dashboards
from three layers:

| Layer | Purpose | Key Functions |
|----|----|----|
| **Content** | What to show (charts, text) | [`create_content()`](https://favstats.github.io/dashboardr/reference/create_content.md), [`add_viz()`](https://favstats.github.io/dashboardr/reference/add_viz.md), [`add_text()`](https://favstats.github.io/dashboardr/reference/add_text.md) |
| **Page** | Where content lives | [`create_page()`](https://favstats.github.io/dashboardr/reference/create_page.md), [`add_content()`](https://favstats.github.io/dashboardr/reference/add_content.md) |
| **Dashboard** | Final output + config | [`create_dashboard()`](https://favstats.github.io/dashboardr/reference/create_dashboard.md), [`add_pages()`](https://favstats.github.io/dashboardr/reference/add_pages.md) |

Each layer flows into the next using pipes (`%>%`).

## Quick Start

``` r
library(dashboardr)
library(dplyr)

# Prepare data
data <- mtcars %>% mutate(cyl_label = paste(cyl, "cylinders"))

# LAYER 1: Content - what to show
charts <- create_content(data = data, type = "bar") %>%
add_viz(x_var = "cyl_label", title = "Cylinders", tabgroup = "overview") %>%
  add_viz(x_var = "gear", title = "Gears", tabgroup = "overview")

# LAYER 2: Pages - where content lives
home <- create_page("Home", is_landing_page = TRUE) %>%
  add_text("# Car Dashboard", "", "Explore the mtcars dataset.")

analysis <- create_page("Analysis", data = data) %>%
  add_content(charts)

# LAYER 3: Dashboard - final output
create_dashboard(
  title = "Car Explorer",
  output_dir = "my_dashboard",
  theme = "flatly"
) %>%
  add_pages(home, analysis) %>%
  generate_dashboard(render = TRUE, open = "browser")
```

That’s it! A complete interactive dashboard.

## Visualization Types

| Function | Description | Use Case |
|----|----|----|
| [`viz_bar()`](https://favstats.github.io/dashboardr/reference/viz_bar.md) | Bar charts | Category comparisons |
| [`viz_histogram()`](https://favstats.github.io/dashboardr/reference/viz_histogram.md) | Distributions | Age, income, scores |
| [`viz_stackedbar()`](https://favstats.github.io/dashboardr/reference/viz_stackedbar.md) | Stacked bars | Likert scales, compositions |
| [`viz_stackedbars()`](https://favstats.github.io/dashboardr/reference/viz_stackedbars.md) | Multiple stacked bars | Survey question batteries |
| [`viz_timeline()`](https://favstats.github.io/dashboardr/reference/viz_timeline.md) | Time series | Trends over time |
| [`viz_heatmap()`](https://favstats.github.io/dashboardr/reference/viz_heatmap.md) | 2D heatmap | Correlations, matrices |
| [`viz_scatter()`](https://favstats.github.io/dashboardr/reference/viz_scatter.md) | Scatter plots | Relationships between variables |
| [`viz_treemap()`](https://favstats.github.io/dashboardr/reference/viz_treemap.md) | Treemaps | Hierarchical proportions |
| [`viz_map()`](https://favstats.github.io/dashboardr/reference/viz_map.md) | Choropleth maps | Geographic data |

## Function Overview

dashboardr uses consistent naming so you always know what a function
does:

| Prefix | Purpose | Examples |
|----|----|----|
| `create_*` | **Create containers** - Start a new dashboard, page, or content collection | [`create_dashboard()`](https://favstats.github.io/dashboardr/reference/create_dashboard.md), [`create_page()`](https://favstats.github.io/dashboardr/reference/create_page.md), [`create_content()`](https://favstats.github.io/dashboardr/reference/create_content.md) |
| `add_*` | **Add to containers** - Insert visualizations, text, pages, or content | [`add_viz()`](https://favstats.github.io/dashboardr/reference/add_viz.md), [`add_text()`](https://favstats.github.io/dashboardr/reference/add_text.md), [`add_page()`](https://favstats.github.io/dashboardr/reference/add_page.md), [`add_content()`](https://favstats.github.io/dashboardr/reference/add_content.md) |
| `viz_*` | **Build visualizations** - Create individual charts (bar, histogram, timeline, etc.) | [`viz_bar()`](https://favstats.github.io/dashboardr/reference/viz_bar.md), [`viz_histogram()`](https://favstats.github.io/dashboardr/reference/viz_histogram.md), [`viz_timeline()`](https://favstats.github.io/dashboardr/reference/viz_timeline.md) |
| `set_*` | **Modify properties** - Change settings like tab labels | [`set_tabgroup_labels()`](https://favstats.github.io/dashboardr/reference/set_tabgroup_labels.md) |
| `generate_*` | **Produce output** - Create Quarto files and render to HTML | [`generate_dashboard()`](https://favstats.github.io/dashboardr/reference/generate_dashboard.md) |
| `theme_*` | **Apply styling** - Set visual themes | [`theme_modern()`](https://favstats.github.io/dashboardr/reference/theme_modern.md), [`theme_clean()`](https://favstats.github.io/dashboardr/reference/theme_clean.md) |
| `combine_*` | **Merge collections** - Join multiple content collections | [`combine_content()`](https://favstats.github.io/dashboardr/reference/combine_content.md), [`combine_viz()`](https://favstats.github.io/dashboardr/reference/combine_viz.md) |
| [`preview()`](https://favstats.github.io/dashboardr/reference/preview.md) | **Quick look** - See content without generating files | [`preview()`](https://favstats.github.io/dashboardr/reference/preview.md) |

### The Typical Pattern

``` r
# 1. CREATE a container
create_content(data = my_data, type = "bar") %>%
  # 2. ADD elements to it
  add_viz(x_var = "category", title = "My Chart") %>%
  add_text("## Summary", "Key findings here.")
```

## Documentation

| Topic | Resource |
|----|----|
| Getting started | [`vignette("getting-started")`](https://favstats.github.io/dashboardr/articles/getting-started.md) |
| Content & visualizations | [`vignette("content-collections")`](https://favstats.github.io/dashboardr/articles/content-collections.md) |
| Pages | [`vignette("pages")`](https://favstats.github.io/dashboardr/articles/pages.md) |
| Dashboards | [`vignette("dashboards")`](https://favstats.github.io/dashboardr/articles/dashboards.md) |
| Advanced features | [`vignette("advanced-features")`](https://favstats.github.io/dashboardr/articles/advanced-features.md) |
| Publishing | [`vignette("publishing_dashboards")`](https://favstats.github.io/dashboardr/articles/publishing_dashboards.md) |

## Live Demos

See dashboardr in action:

1.  [**Tutorial
    Dashboard**](https://favstats.github.io/dashboardr/live-demos/tutorial/docs/index.html) -
    Beginner-friendly demo
2.  [**Showcase
    Dashboard**](https://favstats.github.io/dashboardr/live-demos/showcase/docs/index.html) -
    Advanced features

Both use real data from the General Social Survey (GSS).

### Real-World Dashboard

- [**DigIQ Monitor**](https://www.digiqmonitor.nl/) - The first public
  dashboard built with dashboardr! Digital competence insights for Dutch
  citizens, featuring 11 dimensions, multilingual support, and paginated
  visualizations.

## Contributing

Contributions welcome! Please submit a Pull Request.

## License

MIT License - see
[LICENSE.md](https://favstats.github.io/dashboardr/LICENSE.md)
