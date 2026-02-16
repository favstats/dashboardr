# dashboardr

**dashboardr** lets you build interactive HTML dashboards from R using a
simple, composable grammar. Think of it like building with Lego blocks:

- **No web development needed** - just R code
- **Interactive charts** powered by Highcharts
- **Beautiful themes** from Bootswatch
- **Flexible layouts** with tabs, pages, and navigation

## Installation

``` r
# From R-Universe (recommended — includes pre-built binaries)
install.packages("dashboardr",
  repos = c("https://favstats.r-universe.dev", "https://cloud.r-project.org"))

# Or from GitHub
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

## Community Gallery

Browse dashboards built with dashboardr by the community:

**[View the Gallery →](https://favstats.github.io/dashboardr/gallery/)**

Built something with dashboardr? **[Submit your
dashboard](https://github.com/favstats/dashboardr/issues/new?labels=gallery-submission&title=%5BGallery%5D+My+Dashboard)**
to the gallery and share it with the community!

## Live Demos

See dashboardr in action:

| Demo | Description |
|----|----|
| [**Showcase Dashboard**](https://favstats.github.io/dashboardr/live-demos/showcase/) | Advanced features: value boxes, multi-page layouts, themed charts |
| [**Tutorial Dashboard**](https://favstats.github.io/dashboardr/live-demos/tutorial/) | Beginner-friendly introduction to core features |
| [**GSS Explorer**](https://favstats.github.io/dashboardr/live-demos/sidebar-gss/explorer.html) | Sidebar dashboard with cascading filters |
| [**DigIQ Monitor**](https://www.digiqmonitor.nl/) | Real-world production dashboard for Dutch digital competence |

## Contributing

Contributions welcome! Please submit a Pull Request.

**Share your dashboard** — Add it to the [Community
Gallery](https://favstats.github.io/dashboardr/gallery/) by [opening a
Gallery
submission](https://github.com/favstats/dashboardr/issues/new?labels=gallery-submission&title=%5BGallery%5D+My+Dashboard).

## LLM Support

dashboardr includes a built-in [MCP
server](https://modelcontextprotocol.io/) that gives AI coding
assistants full access to dashboardr documentation, function help, and
runnable examples. Works with Claude Code, Claude Desktop, VS Code
Copilot, Cursor, and any MCP-compatible client.

### Setup

First, install the optional dependencies:

``` r
install.packages(c("ellmer", "mcptools"))
```

Then configure your client:

**Claude Code:**

``` bash
claude mcp add dashboardr -- Rscript -e "dashboardr::dashboardr_mcp_server()"
```

**Claude Desktop** (`claude_desktop_config.json`):

``` json
{
  "mcpServers": {
    "dashboardr": {
      "command": "Rscript",
      "args": ["-e", "dashboardr::dashboardr_mcp_server()"]
    }
  }
}
```

**VS Code / Cursor** (`.vscode/mcp.json` or Cursor equivalent):

``` json
{
  "mcp": {
    "servers": {
      "dashboardr": {
        "type": "stdio",
        "command": "Rscript",
        "args": ["-e", "dashboardr::dashboardr_mcp_server()"]
      }
    }
  }
}
```

### Available Tools

| Tool | Description |
|----|----|
| `dashboardr_guide` | Full package guide — architecture, API overview, quick start |
| `dashboardr_function_help` | Look up help for any exported function |
| `dashboardr_list_functions` | List functions by category (viz, content, input, layout, …) |
| `dashboardr_example` | Get runnable example code for common patterns |
| `dashboardr_viz_types` | Quick reference of all visualization types and parameters |

## License

MIT License - see
[LICENSE.md](https://favstats.github.io/dashboardr/LICENSE.md)
