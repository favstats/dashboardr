
<!-- README.md is generated from README.Rmd. Please edit that file -->

# dashboardr <img src="man/figures/logo.svg" align="right" height="139" alt="" />

<!-- badges: start -->

[![Lifecycle:
maturing](https://img.shields.io/badge/lifecycle-maturing-blue.svg)](https://lifecycle.r-lib.org/articles/stages.html#maturing)
[![R-CMD-check](https://github.com/favstats/dashboardr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/favstats/dashboardr/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/favstats/dashboardr/graph/badge.svg)](https://app.codecov.io/gh/favstats/dashboardr)
[![R-Universe](https://favstats.r-universe.dev/badges/dashboardr)](https://favstats.r-universe.dev/dashboardr)
[![GitHub
stars](https://img.shields.io/github/stars/favstats/dashboardr?style=social)](https://github.com/favstats/dashboardr)
[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
<!-- badges: end -->

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
| **Content** | What to show (charts, text) | `create_content()`, `add_viz()`, `add_text()` |
| **Page** | Where content lives | `create_page()`, `add_content()` |
| **Dashboard** | Final output + config | `create_dashboard()`, `add_pages()` |

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

| Function            | Description           | Use Case                        |
|---------------------|-----------------------|---------------------------------|
| `viz_bar()`         | Bar charts            | Category comparisons            |
| `viz_histogram()`   | Distributions         | Age, income, scores             |
| `viz_stackedbar()`  | Stacked bars          | Likert scales, compositions     |
| `viz_stackedbars()` | Multiple stacked bars | Survey question batteries       |
| `viz_timeline()`    | Time series           | Trends over time                |
| `viz_heatmap()`     | 2D heatmap            | Correlations, matrices          |
| `viz_scatter()`     | Scatter plots         | Relationships between variables |
| `viz_treemap()`     | Treemaps              | Hierarchical proportions        |
| `viz_map()`         | Choropleth maps       | Geographic data                 |

## Function Overview

dashboardr uses consistent naming so you always know what a function
does:

| Prefix | Purpose | Examples |
|----|----|----|
| `create_*` | **Create containers** - Start a new dashboard, page, or content collection | `create_dashboard()`, `create_page()`, `create_content()` |
| `add_*` | **Add to containers** - Insert visualizations, text, pages, or content | `add_viz()`, `add_text()`, `add_page()`, `add_content()` |
| `viz_*` | **Build visualizations** - Create individual charts (bar, histogram, timeline, etc.) | `viz_bar()`, `viz_histogram()`, `viz_timeline()` |
| `set_*` | **Modify properties** - Change settings like tab labels | `set_tabgroup_labels()` |
| `generate_*` | **Produce output** - Create Quarto files and render to HTML | `generate_dashboard()` |
| `theme_*` | **Apply styling** - Set visual themes | `theme_modern()`, `theme_clean()` |
| `combine_*` | **Merge collections** - Join multiple content collections | `combine_content()`, `combine_viz()` |
| `preview()` | **Quick look** - See content without generating files | `preview()` |

### The Typical Pattern

``` r
# 1. CREATE a container
create_content(data = my_data, type = "bar") %>%
  # 2. ADD elements to it
  add_viz(x_var = "category", title = "My Chart") %>%
  add_text("## Summary", "Key findings here.")
```

## Documentation

| Topic                    | Resource                            |
|--------------------------|-------------------------------------|
| Getting started          | `vignette("getting-started")`       |
| Content & visualizations | `vignette("content-collections")`   |
| Pages                    | `vignette("pages")`                 |
| Dashboards               | `vignette("dashboards")`            |
| Advanced features        | `vignette("advanced-features")`     |
| Publishing               | `vignette("publishing_dashboards")` |

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

MIT License - see [LICENSE.md](LICENSE.md)
